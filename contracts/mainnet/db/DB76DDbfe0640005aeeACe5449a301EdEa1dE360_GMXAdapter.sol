/**
 *Submitted for verification at Arbiscan on 2023-07-27
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// File @openzeppelin/contracts/interfaces/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}


// File contracts/adapters/gmx/interfaces/IGmxAdapter.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxAdapter {
    /// @notice Swaps tokens along the route determined by the path
    /// @dev The input token is Vault's underlying
    /// @param path An array of token address to swap through
    /// @param amountIn The amount of input tokens
    /// @param minOut The minimum amount of output tokens that must be received
    /// @return boughtAmount Amount of the bought tokens
    function buy(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut
    ) external returns (uint256 boughtAmount);

    /// @notice Sells back part of  bought tokens along the route
    /// @dev The output token is Vault's underlying
    /// @param path An array of token address to swap through
    /// @param amountIn The amount of input tokens
    /// @param minOut The minimum amount of output tokens (vault't underlying) that must be received
    /// @return amount of the bought tokens
    function sell(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut
    ) external returns (uint256 amount);

    /// @notice Sells all specified tokens for Vault's underlying
    /// @dev Can be executed only by trader
    /// @param path An array of token address to swap through
    /// @param minOut The minimum amount of output tokens that must be received
    function close(
        address[] memory path,
        uint256 minOut
    ) external returns (uint256);

    /// @notice Sells all specified tokens for Vault's underlying
    /// @dev Can be executed by anyone with delay
    /// @param path An array of token address to swap through
    /// @param minOut The minimum amount of output tokens that must be received
    function forceClose(
        address[] memory path,
        uint256 minOut
    ) external returns (uint256);

    /// @notice Creates leverage long or short position order at GMX
    /// @dev Calls createIncreasePosition() in GMXPositionRouter
    function leveragePosition() external returns (uint256);

    /// @notice Create order for closing/decreasing position at GMX
    /// @dev Calls createDecreasePosition() in GMXPositionRouter
    function closePosition() external returns (uint256);

    /// @notice Create order for closing position at GMX
    /// @dev Calls createDecreasePosition() in GMXPositionRouter
    ///      Can be executed by any user
    /// @param positionId Position index for vault
    function forceClosePosition(uint256 positionId) external returns (uint256);

    /// @notice Returns data for open position
    // todo
    function getPosition(uint256) external view returns (uint256[] memory);

    struct AdapterOperation {
        uint8 operationId;
        bytes data;
    }

    /// @notice Checks if operations are allowed on adapter
    /// @param traderOperations Array of suggested trader operations
    /// @return Returns 'true' if operation is allowed on adapter
    function isOperationAllowed(
        AdapterOperation[] memory traderOperations
    ) external view returns (bool);

    /// @notice Executes array of trader operations
    /// @param traderOperations Array of trader operations
    /// @return Returns 'true' if all trades completed with success
    function executeOperation(
        AdapterOperation[] memory traderOperations
    ) external returns (bool);
}


// File contracts/adapters/gmx/interfaces/IGmxOrderBook.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxOrderBook {
    struct IncreaseOrder {
        address account;
        address purchaseToken;
        uint256 purchaseTokenAmount;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    struct DecreaseOrder {
        address account;
        address collateralToken;
        uint256 collateralDelta;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    function minExecutionFee() external view returns (uint256);

    function increaseOrdersIndex(
        address orderCreator
    ) external view returns (uint256);

    function increaseOrders(
        address orderCreator,
        uint256 index
    ) external view returns (IncreaseOrder memory);

    function decreaseOrdersIndex(
        address orderCreator
    ) external view returns (uint256);

    function decreaseOrders(
        address orderCreator,
        uint256 index
    ) external view returns (DecreaseOrder memory);

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function cancelSwapOrder(uint256 _orderIndex) external;

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    function executeDecreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function executeIncreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;
}

interface IGmxOrderBookReader {
    function getIncreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);

    function getDecreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);

    function getSwapOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);
}


// File contracts/adapters/gmx/interfaces/IGmxReader.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxReader {
    function getMaxAmountIn(
        address _vault,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256);

    function getAmountOut(
        address _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256, uint256);

    function getPositions(
        address _vault,
        address _account,
        address[] memory _collateralTokens,
        address[] memory _indexTokens,
        bool[] memory _isLong
    ) external view returns (uint256[] memory);

    function getTokenBalances(
        address _account,
        address[] memory _tokens
    ) external view returns (uint256[] memory);
}


// File contracts/adapters/gmx/interfaces/IGmxRouter.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    function increasePositionRequests(
        bytes32 requestKey
    ) external view returns (IncreasePositionRequest memory);

    struct DecreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function decreasePositionRequests(
        bytes32 requestKey
    ) external view returns (DecreasePositionRequest memory);

    /// @notice Returns current account's increase position index
    function increasePositionsIndex(
        address account
    ) external view returns (uint256);

    /// @notice Returns current account's decrease position index
    function decreasePositionsIndex(
        address positionRequester
    ) external view returns (uint256);

    /// @notice Returns request key
    function getRequestKey(
        address account,
        uint256 index
    ) external view returns (bytes32);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external returns (bytes32);

    function cancelIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function cancelDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function minExecutionFee() external view returns (uint256);
}

interface IGmxRouter {
    function approvedPlugins(
        address user,
        address plugin
    ) external view returns (bool);

    function approvePlugin(address plugin) external;

    function denyPlugin(address plugin) external;

    function swap(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut,
        address receiver
    ) external;

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;
}


// File contracts/adapters/gmx/interfaces/IGmxVault.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxVault {
    function whitelistedTokens(address token) external view returns (bool);

    function stableTokens(address token) external view returns (bool);

    function shortableTokens(address token) external view returns (bool);

    function getMaxPrice(address indexToken) external view returns (uint256);

    function getMinPrice(address indexToken) external view returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function isLeverageEnabled() external view returns (bool);

    function guaranteedUsd(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);
}


// File contracts/interfaces/IAdapter.sol

//  MIT

pragma solidity >=0.8.0;

interface IAdapter {
    struct AdapterOperation {
        // id to identify what type of operation the adapter should do
        // this is a generic operation
        uint8 operationId;
        // signatura of the funcion
        // abi.encodeWithSignature
        bytes data;
    }

    // receives the operation to perform in the adapter and the ratio to scale whatever needed
    // answers if the operation was successfull
    function executeOperation(
        bool,
        address,
        address,
        uint256,
        AdapterOperation memory
    ) external returns (bool, uint256);
}


// File contracts/interfaces/IPlatformAdapter.sol

//  MIT

pragma solidity >=0.8.0;

interface IPlatformAdapter {
    struct TradeOperation {
        uint8 platformId;
        uint8 actionId;
        bytes data;
    }

    error InvalidOperation(uint8 platformId, uint8 actionId);

    function createTrade(
        TradeOperation memory tradeOperation
    ) external returns (bytes memory);

    function totalAssets() external view returns (uint256);
}


// File contracts/interfaces/IBaseVault.sol

//  MIT

pragma solidity >=0.8.0;

interface IBaseVault {
    function underlyingTokenAddress() external view returns (address);

    function contractsFactoryAddress() external view returns (address);

    function currentRound() external view returns (uint256);

    function afterRoundBalance() external view returns (uint256);

    function getGmxShortCollaterals() external view returns (address[] memory);

    function getGmxShortIndexTokens() external view returns (address[] memory);

    function getAllowedTradeTokens() external view returns (address[] memory);
}


// File contracts/interfaces/ITraderWallet.sol

//  MIT

pragma solidity >=0.8.0;


interface ITraderWallet is IBaseVault {
    function vaultAddress() external view returns (address);

    function traderAddress() external view returns (address);

    function cumulativePendingDeposits() external view returns (uint256);

    function cumulativePendingWithdrawals() external view returns (uint256);

    function lastRolloverTimestamp() external view returns (uint256);

    function gmxShortPairs(address, address) external view returns (bool);

    function gmxShortCollaterals(uint256) external view returns (address);

    function gmxShortIndexTokens(uint256) external view returns (address);

    function initialize(
        address underlyingTokenAddress,
        address traderAddress,
        address ownerAddress
    ) external;

    function setVaultAddress(address vaultAddress) external;

    function setTraderAddress(address traderAddress) external;

    function addGmxShortPairs(
        address[] calldata collateralTokens,
        address[] calldata indexTokens
    ) external;

    function addAllowedTradeTokens(address[] calldata tokens) external;

    function removeAllowedTradeToken(address token) external;

    function addProtocolToUse(uint256 protocolId) external;

    function removeProtocolToUse(uint256 protocolId) external;

    function traderDeposit(uint256 amount) external;

    function withdrawRequest(uint256 amount) external;

    function setAdapterAllowanceOnToken(
        uint256 protocolId,
        address tokenAddress,
        bool revoke
    ) external;

    function rollover() external;

    function executeOnProtocol(
        uint256 protocolId,
        IAdapter.AdapterOperation memory traderOperation,
        bool replicate
    ) external;

    function getAdapterAddressPerProtocol(
        uint256 protocolId
    ) external view returns (address);

    function isAllowedTradeToken(address token) external view returns (bool);

    function allowedTradeTokensLength() external view returns (uint256);

    function allowedTradeTokensAt(
        uint256 index
    ) external view returns (address);

    function isTraderSelectedProtocol(
        uint256 protocolId
    ) external view returns (bool);

    function traderSelectedProtocolIdsLength() external view returns (uint256);

    function traderSelectedProtocolIdsAt(
        uint256 index
    ) external view returns (uint256);

    function getTraderSelectedProtocolIds()
        external
        view
        returns (uint256[] memory);

    function getContractValuation() external view returns (uint256);
}


// File contracts/adapters/gmx/GMXAdapter.sol

//  MIT

pragma solidity 0.8.19;










// import "hardhat/console.sol";

library GMXAdapter {
    using MathUpgradeable for uint256;

    address internal constant gmxRouter =
        0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;
    address internal constant gmxPositionRouter =
        0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868;
    IGmxVault internal constant gmxVault =
        IGmxVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    address internal constant gmxOrderBook =
        0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB;
    address internal constant gmxOrderBookReader =
        0xa27C20A7CF0e1C68C0460706bB674f98F362Bc21;
    address internal constant gmxReader =
        0x22199a49A999c351eF7927602CFB187ec3cae489;

    /// @notice The ratio denominator between traderWallet and usersVault
    uint256 private constant ratioDenominator = 1e18;

    /// @notice The slippage allowance for swap in the position
    uint256 public constant slippage = 1e17; // 10%

    struct IncreaseOrderLocalVars {
        address[] path;
        uint256 amountIn;
        address indexToken;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
    }

    event CreateIncreasePosition(address sender, bytes32 requestKey);
    event CreateDecreasePosition(address sender, bytes32 requestKey);

    error AddressZero();
    error InsufficientEtherBalance();
    error InvalidOperationId();
    error CreateSwapOrderFail();
    error CreateIncreasePositionFail(string);
    error CreateDecreasePositionFail(string);
    error CreateIncreasePositionOrderFail(string);
    error CreateDecreasePositionOrderFail(string);
    error NotSupportedTokens(address, address);
    error TooManyOrders();

    /// @notice Gives approve to operate with gmxPositionRouter
    /// @dev Needs to be called from wallet and vault in initialization
    function __initApproveGmxPlugin() external {
        IGmxRouter(gmxRouter).approvePlugin(gmxPositionRouter);
        IGmxRouter(gmxRouter).approvePlugin(gmxOrderBook);
    }

    /// @notice Executes operation with external protocol
    /// @param ratio Scaling ratio to
    /// @param traderOperation Encoded operation data
    /// @return bool 'true' if the operation completed successfully
    function executeOperation(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        IAdapter.AdapterOperation memory traderOperation
    ) external returns (bool, uint256) {
        if (uint256(traderOperation.operationId) == 0) {
            return
                _increasePosition(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 1) {
            return
                _decreasePosition(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 2) {
            return
                _createIncreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 3) {
            return
                _updateIncreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 4) {
            return _cancelIncreaseOrder(isTraderWallet, traderOperation.data);
        } else if (traderOperation.operationId == 5) {
            return
                _createDecreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 6) {
            return
                _updateDecreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 7) {
            return _cancelDecreaseOrder(isTraderWallet, traderOperation.data);
        }
        revert InvalidOperationId();
    }

    /*
    @notice Opens new or increases the size of an existing position
    @param tradeData must contain parameters:
        path:       [collateralToken] or [tokenIn, collateralToken] if a swap is needed
        indexToken: the address of the token to long or short
        amountIn:   the amount of tokenIn to deposit as collateral
        minOut:     the min amount of collateralToken to swap for (can be zero if no swap is required)
        sizeDelta:  the USD value of the change in position size  (scaled 1e30)
        isLong:     whether to long or short position

    Additional params for increasing position
        executionFee:   can be set to PositionRouter.minExecutionFee
        referralCode:   referral code for affiliate rewards and rebates
        callbackTarget: an optional callback contract (note: has gas limit)
        acceptablePrice: the USD value of the max (for longs) or min (for shorts) index price acceptable when executing
    @return bool - Returns 'true' if position was created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _increasePosition(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            address[] memory path,
            address indexToken,
            uint256 amountIn,
            uint256 minOut,
            uint256 sizeDelta,
            bool isLong
        ) = abi.decode(
                tradeData,
                (address[], address, uint256, uint256, uint256, bool)
            );

        if (isTraderWallet) {
            // only one check is enough
            address collateralToken = path[path.length - 1];
            if (
                !_validateTradeTokens(
                    traderWallet,
                    collateralToken,
                    indexToken,
                    isLong
                )
            ) {
                revert NotSupportedTokens(collateralToken, indexToken);
            }
            // calculate ratio for UserVault based on balances of tokenIn (path[0])
            uint256 traderBalance = IERC20(path[0]).balanceOf(traderWallet);
            uint256 vaultBalance = IERC20(path[0]).balanceOf(usersVault);
            ratio_ = vaultBalance.mulDiv(
                ratioDenominator,
                traderBalance,
                MathUpgradeable.Rounding.Down
            );
        } else {
            // scaling for Vault execution
            amountIn = (amountIn * ratio) / ratioDenominator;
            uint256 amountInAvailable = IERC20(path[0]).balanceOf(
                address(this)
            );
            if (amountInAvailable < amountIn) amountIn = amountInAvailable;
            sizeDelta = (sizeDelta * ratio) / ratioDenominator;
            minOut = (minOut * ratio) / (ratioDenominator + slippage); // decreased due to price impact
        }

        _checkUpdateAllowance(path[0], address(gmxRouter), amountIn);
        uint256 executionFee = IGmxPositionRouter(gmxPositionRouter)
            .minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        uint256 acceptablePrice;
        if (isLong) {
            acceptablePrice = gmxVault.getMaxPrice(indexToken);
        } else {
            acceptablePrice = gmxVault.getMinPrice(indexToken);
        }

        (bool success, bytes memory data) = gmxPositionRouter.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxPositionRouter.createIncreasePosition.selector,
                path,
                indexToken,
                amountIn,
                minOut,
                sizeDelta,
                isLong,
                acceptablePrice,
                executionFee,
                0, // referralCode
                address(0) // callbackTarget
            )
        );

        if (!success) {
            revert CreateIncreasePositionFail(_getRevertMsg(data));
        }
        emit CreateIncreasePosition(address(this), bytes32(data));
        return (true, ratio_);
    }

    /*
    @notice Closes or decreases an existing position
    @param tradeData must contain parameters:
        path:            [collateralToken] or [collateralToken, tokenOut] if a swap is needed
        indexToken:      the address of the token that was longed (or shorted)
        collateralDelta: the amount of collateral in USD value to withdraw (doesn't matter when position is completely closing)
        sizeDelta:       the USD value of the change in position size (scaled to 1e30)
        isLong:          whether the position is a long or short
        minOut:          the min output token amount (can be zero if no swap is required)

    Additional params for increasing position
        receiver:       the address to receive the withdrawn tokens
        acceptablePrice: the USD value of the max (for longs) or min (for shorts) index price acceptable when executing
        executionFee:   can be set to PositionRouter.minExecutionFee
        withdrawETH:    only applicable if WETH will be withdrawn, the WETH will be unwrapped to ETH if this is set to true
        callbackTarget: an optional callback contract (note: has gas limit)
    @return bool - Returns 'true' if position was created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _decreasePosition(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            address[] memory path,
            address indexToken,
            uint256 collateralDelta,
            uint256 sizeDelta,
            bool isLong,
            uint256 minOut
        ) = abi.decode(
                tradeData,
                (address[], address, uint256, uint256, bool, uint256)
            );
        uint256 executionFee = IGmxPositionRouter(gmxPositionRouter)
            .minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        if (isTraderWallet) {
            // calculate ratio for UserVault based on size of opened position
            uint256 traderSize = _getPosition(
                traderWallet,
                path[0],
                indexToken,
                isLong
            )[0];
            uint256 vaultSize = _getPosition(
                usersVault,
                path[0],
                indexToken,
                isLong
            )[0];
            ratio_ = vaultSize.mulDiv(
                ratioDenominator,
                traderSize,
                MathUpgradeable.Rounding.Up
            );
        } else {
            // scaling for Vault
            uint256[] memory vaultPosition = _getPosition(
                usersVault,
                path[0],
                indexToken,
                isLong
            );
            uint256 positionSize = vaultPosition[0];
            uint256 positionCollateral = vaultPosition[1];

            sizeDelta = (sizeDelta * ratio) / ratioDenominator; // most important for closing
            if (sizeDelta > positionSize) sizeDelta = positionSize;
            collateralDelta = (collateralDelta * ratio) / ratioDenominator;
            if (collateralDelta > positionCollateral)
                collateralDelta = positionCollateral;

            minOut = (minOut * ratio) / (ratioDenominator + slippage); // decreased due to price impact
        }

        uint256 acceptablePrice;
        if (isLong) {
            acceptablePrice = gmxVault.getMinPrice(indexToken);
        } else {
            acceptablePrice = gmxVault.getMaxPrice(indexToken);
        }

        (bool success, bytes memory data) = gmxPositionRouter.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxPositionRouter.createDecreasePosition.selector,
                path,
                indexToken,
                collateralDelta,
                sizeDelta,
                isLong,
                address(this), // receiver
                acceptablePrice,
                minOut,
                executionFee,
                false, // withdrawETH
                address(0) // callbackTarget
            )
        );

        if (!success) {
            revert CreateDecreasePositionFail(_getRevertMsg(data));
        }
        emit CreateDecreasePosition(address(this), bytes32(data));
        return (true, ratio_);
    }

    /// /// /// ///
    /// Orders
    /// /// /// ///

    /*
    @notice Creates new order to open or increase position
    @param tradeData must contain parameters:
        path:            [collateralToken] or [tokenIn, collateralToken] if a swap is needed
        amountIn:        the amount of tokenIn to deposit as collateral
        indexToken:      the address of the token to long or short
        minOut:          the min amount of collateralToken to swap for (can be zero if no swap is required)
        sizeDelta:       the USD value of the change in position size  (scaled 1e30)
        isLong:          whether to long or short position
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for creating new Long order
            in terms of Short position:
                'false' for creating new Short order

    Additional params for increasing position
        collateralToken: the collateral token (must be path[path.length-1] )
        executionFee:   can be set to OrderBook.minExecutionFee
        shouldWrap:     true if 'tokenIn' is native and should be wrapped
    @return bool - Returns 'true' if order was successfully created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _createIncreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        IncreaseOrderLocalVars memory vars;
        (
            vars.path,
            vars.amountIn,
            vars.indexToken,
            vars.minOut,
            vars.sizeDelta,
            vars.isLong,
            vars.triggerPrice,
            vars.triggerAboveThreshold
        ) = abi.decode(
            tradeData,
            (address[], uint256, address, uint256, uint256, bool, uint256, bool)
        );
        uint256 executionFee = IGmxOrderBook(gmxOrderBook).minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();
        address collateralToken = vars.path[vars.path.length - 1];

        if (isTraderWallet) {
            // only one check is enough
            if (
                !_validateTradeTokens(
                    traderWallet,
                    collateralToken,
                    vars.indexToken,
                    vars.isLong
                )
            ) {
                revert NotSupportedTokens(collateralToken, vars.indexToken);
            }
            if (!_validateIncreaseOrder(traderWallet)) {
                revert TooManyOrders();
            }

            // calculate ratio for UserVault based on balances of tokenIn (path[0])
            uint256 traderBalance = IERC20(vars.path[0]).balanceOf(
                traderWallet
            );
            uint256 vaultBalance = IERC20(vars.path[0]).balanceOf(usersVault);
            ratio_ = vaultBalance.mulDiv(
                ratioDenominator,
                traderBalance,
                MathUpgradeable.Rounding.Up
            );
        } else {
            if (!_validateIncreaseOrder(usersVault)) {
                revert TooManyOrders();
            }
            // scaling for Vault execution
            vars.amountIn = (vars.amountIn * ratio) / ratioDenominator;
            uint256 amountInAvailable = IERC20(vars.path[0]).balanceOf(
                address(this)
            );
            if (amountInAvailable < vars.amountIn)
                vars.amountIn = amountInAvailable;
            vars.sizeDelta = (vars.sizeDelta * ratio) / ratioDenominator;
            vars.minOut = (vars.minOut * ratio) / (ratioDenominator + slippage); // decreased due to price impact
        }

        _checkUpdateAllowance(vars.path[0], address(gmxRouter), vars.amountIn);

        (bool success, bytes memory data) = gmxOrderBook.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxOrderBook.createIncreaseOrder.selector,
                vars.path,
                vars.amountIn,
                vars.indexToken,
                vars.minOut,
                vars.sizeDelta,
                collateralToken,
                vars.isLong,
                vars.triggerPrice,
                vars.triggerAboveThreshold,
                executionFee,
                false // 'shouldWrap'
            )
        );

        if (!success) {
            revert CreateIncreasePositionOrderFail(_getRevertMsg(data));
        }
        return (true, ratio_);
    }

    /*
    @notice Updates exist increase order
    @param tradeData must contain parameters:
        orderIndexes:   the array with Wallet and Vault indexes of the exist order indexes to update
                        [0, 1]: 0 - Wallet, 1 - Vault
        sizeDelta:       the USD value of the change in position size  (scaled 1e30)
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for creating new Long order
            in terms of Short position:
                'false' for creating new Short order

    @return bool - Returns 'true' if order was successfully updated
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _updateIncreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            uint256[] memory orderIndexes,
            uint256 sizeDelta,
            uint256 triggerPrice,
            bool triggerAboveThreshold
        ) = abi.decode(tradeData, (uint256[], uint256, uint256, bool));

        uint256 orderIndex;

        if (isTraderWallet) {
            // calculate ratio for UserVault based on sizes of current orders
            IGmxOrderBook.IncreaseOrder memory walletOrder = _getIncreaseOrder(
                traderWallet,
                orderIndexes[0]
            );
            IGmxOrderBook.IncreaseOrder memory vaultOrder = _getIncreaseOrder(
                usersVault,
                orderIndexes[1]
            );
            ratio_ = vaultOrder.sizeDelta.mulDiv(
                ratioDenominator,
                walletOrder.sizeDelta,
                MathUpgradeable.Rounding.Down
            );

            orderIndex = orderIndexes[0]; // first for traderWallet, second for usersVault
        } else {
            // scaling for Vault execution
            sizeDelta = (sizeDelta * ratio) / ratioDenominator;
            orderIndex = orderIndexes[1]; // first for traderWallet, second for usersVault
        }

        IGmxOrderBook(gmxOrderBook).updateIncreaseOrder(
            orderIndex,
            sizeDelta,
            triggerPrice,
            triggerAboveThreshold
        );
        return (true, ratio_);
    }

    /*
    @notice Cancels exist increase order
    @param isTraderWallet The flag, 'true' if caller is TraderWallet (and it will calculate ratio for UsersVault)
    @param tradeData must contain parameters:
        orderIndexes:  the array with Wallet and Vault indexes of the exist orders to update
    @return bool - Returns 'true' if order was canceled
    @return ratio_ - Unused value
    */
    function _cancelIncreaseOrder(
        bool isTraderWallet,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        uint256[] memory orderIndexes = abi.decode(tradeData, (uint256[]));

        // default trader Wallet value
        uint256 orderIndex;
        if (isTraderWallet) {
            // value for Wallet
            orderIndex = orderIndexes[0];
        } else {
            // value for Vault
            orderIndex = orderIndexes[1];
        }

        IGmxOrderBook(gmxOrderBook).cancelIncreaseOrder(orderIndex);
        return (true, ratio_);
    }

    /*
    @notice Creates new order to close or decrease position
            Also can be used to create (partial) stop-loss or take-profit orders
    @param tradeData must contain parameters:
        indexToken:      the address of the token that was longed (or shorted)
        sizeDelta:       the USD value of the change in position size (scaled to 1e30)
        collateralToken: the collateral token address
        collateralDelta: the amount of collateral in USD value to withdraw (scaled to 1e30)
        isLong:          whether the position is a long or short
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for take-profit orders, 'false' for stop-loss orders
            in terms of Short position:
                'false' for take-profit orders', true' for stop-loss orders
    @return bool - Returns 'true' if order was successfully created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _createDecreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            address indexToken,
            uint256 sizeDelta,
            address collateralToken,
            uint256 collateralDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold
        ) = abi.decode(
                tradeData,
                (address, uint256, address, uint256, bool, uint256, bool)
            );

        // for decrease order gmx requires strict: 'msg.value > minExecutionFee'
        // thats why we need to add 1
        uint256 executionFee = IGmxOrderBook(gmxOrderBook).minExecutionFee() +
            1;
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        if (isTraderWallet) {
            // calculate ratio for UserVault based on size of opened position
            uint256 traderSize = _getPosition(
                traderWallet,
                collateralToken,
                indexToken,
                isLong
            )[0];
            uint256 vaultSize = _getPosition(
                usersVault,
                collateralToken,
                indexToken,
                isLong
            )[0];
            ratio_ = vaultSize.mulDiv(
                ratioDenominator,
                traderSize,
                MathUpgradeable.Rounding.Up
            );
        } else {
            // scaling for Vault
            uint256[] memory vaultPosition = _getPosition(
                usersVault,
                collateralToken,
                indexToken,
                isLong
            );
            uint256 positionSize = vaultPosition[0];
            uint256 positionCollateral = vaultPosition[1];

            // rounding Up and then check amounts
            sizeDelta = sizeDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            ); // value important for closing
            if (sizeDelta > positionSize) sizeDelta = positionSize;
            collateralDelta = collateralDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            );
            if (collateralDelta > positionCollateral)
                collateralDelta = positionCollateral;
        }

        (bool success, bytes memory data) = gmxOrderBook.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxOrderBook.createDecreaseOrder.selector,
                indexToken,
                sizeDelta,
                collateralToken,
                collateralDelta,
                isLong,
                triggerPrice,
                triggerAboveThreshold
            )
        );

        if (!success) {
            revert CreateDecreasePositionOrderFail(_getRevertMsg(data));
        }
        return (true, ratio_);
    }

    /*
    @notice Updates exist decrease order
    @param tradeData must contain parameters:
        orderIndexes:   the array with Wallet and Vault indexes of the exist order indexes to update
                        [0, 1]: 0 - Wallet, 1 - Vault
        collateralDelta: the amount of collateral in USD value to withdraw (scaled to 1e30)
        sizeDelta:       the USD value of the change in position size  (scaled 1e30)
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for take-profit orders, 'false' for stop-loss orders
            in terms of Short position:
                'false' for take-profit orders', true' for stop-loss orders

    @return bool - Returns 'true' if order was successfully updated
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _updateDecreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            uint256[] memory orderIndexes,
            uint256 collateralDelta,
            uint256 sizeDelta,
            uint256 triggerPrice,
            bool triggerAboveThreshold
        ) = abi.decode(tradeData, (uint256[], uint256, uint256, uint256, bool));

        uint256 orderIndex;

        if (isTraderWallet) {
            // calculate ratio for UserVault based on sizes of current orders
            IGmxOrderBook.DecreaseOrder memory walletOrder = _getDecreaseOrder(
                traderWallet,
                orderIndexes[0]
            );
            IGmxOrderBook.DecreaseOrder memory vaultOrder = _getDecreaseOrder(
                usersVault,
                orderIndexes[1]
            );
            ratio_ = vaultOrder.sizeDelta.mulDiv(
                ratioDenominator,
                walletOrder.sizeDelta,
                MathUpgradeable.Rounding.Up
            );

            orderIndex = orderIndexes[0]; // first for traderWallet, second for usersVault
        } else {
            // scaling for Vault execution
            // get current position
            IGmxOrderBook.DecreaseOrder memory vaultOrder = _getDecreaseOrder(
                usersVault,
                orderIndexes[1]
            );
            // rounding Up and then check amounts
            sizeDelta = sizeDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            ); // value important for closing
            if (sizeDelta > vaultOrder.sizeDelta)
                sizeDelta = vaultOrder.sizeDelta;
            collateralDelta = collateralDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            );
            if (collateralDelta > vaultOrder.collateralDelta)
                collateralDelta = vaultOrder.collateralDelta;

            orderIndex = orderIndexes[1]; // first for traderWallet, second for usersVault
        }

        IGmxOrderBook(gmxOrderBook).updateDecreaseOrder(
            orderIndex,
            collateralDelta,
            sizeDelta,
            triggerPrice,
            triggerAboveThreshold
        );
        return (true, ratio_);
    }

    /*
        @notice Cancels exist decrease order
        @param isTraderWallet The flag, 'true' if caller is TraderWallet (and it will calculate ratio for UsersVault)
        @param tradeData must contain parameters:
            orderIndexes:      the array with Wallet and Vault indexes of the exist orders to update
        @return bool - Returns 'true' if order was canceled
        @return ratio_ - Unused value
    */
    function _cancelDecreaseOrder(
        bool isTraderWallet,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        uint256[] memory orderIndexes = abi.decode(tradeData, (uint256[]));

        // default trader Wallet value
        uint256 orderIndex;
        if (isTraderWallet) {
            // value for Wallet
            orderIndex = orderIndexes[0];
        } else {
            // value for Vault
            orderIndex = orderIndexes[1];
        }

        IGmxOrderBook(gmxOrderBook).cancelDecreaseOrder(orderIndex);
        return (true, ratio_);
    }

    function _validateTradeTokens(
        address traderWallet,
        address collateralToken,
        address indexToken,
        bool isLong
    ) internal view returns (bool) {
        if (isLong) {
            address[] memory allowedTradeTokens = ITraderWallet(traderWallet)
                .getAllowedTradeTokens();
            for (uint256 i; i < allowedTradeTokens.length; ) {
                if (allowedTradeTokens[i] == indexToken) return true;
                unchecked {
                    ++i;
                }
            }
        } else {
            if (
                !ITraderWallet(traderWallet).gmxShortPairs(
                    collateralToken,
                    indexToken
                )
            ) {
                return false;
            }
            return true;
        }
        return false;
    }

    /// @dev account can't keep more than 10 orders because of expensive valuation
    ///      For gas saving check only oldest tenth order
    function _validateIncreaseOrder(
        address account
    ) internal view returns (bool) {
        uint256 latestIndex = IGmxOrderBook(gmxOrderBook).increaseOrdersIndex(
            account
        );
        if (latestIndex >= 10) {
            uint256 tenthIndex = latestIndex - 10;
            IGmxOrderBook.IncreaseOrder memory order = IGmxOrderBook(
                gmxOrderBook
            ).increaseOrders(account, tenthIndex);
            if (order.account != address(0)) {
                return false;
            }
        }
        return true;
    }

    /// @notice Updates allowance amount for token
    function _checkUpdateAllowance(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spender) < amount) {
            IERC20(token).approve(spender, amount);
        }
    }

    /// @notice Helper function to track revers in call()
    function _getRevertMsg(
        bytes memory _returnData
    ) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _getPosition(
        address account,
        address collateralToken,
        address indexToken,
        bool isLong
    ) internal view returns (uint256[] memory) {
        address[] memory collaterals = new address[](1);
        collaterals[0] = collateralToken;
        address[] memory indexTokens = new address[](1);
        indexTokens[0] = indexToken;
        bool[] memory isLongs = new bool[](1);
        isLongs[0] = isLong;

        return
            IGmxReader(gmxReader).getPositions(
                address(gmxVault),
                account,
                collaterals,
                indexTokens,
                isLongs
            );
    }

    function _getIncreaseOrder(
        address account,
        uint256 index
    ) internal view returns (IGmxOrderBook.IncreaseOrder memory) {
        return IGmxOrderBook(gmxOrderBook).increaseOrders(account, index);
    }

    function _getDecreaseOrder(
        address account,
        uint256 index
    ) internal view returns (IGmxOrderBook.DecreaseOrder memory) {
        return IGmxOrderBook(gmxOrderBook).decreaseOrders(account, index);
    }

    function emergencyDecreasePosition(
        address[] calldata path,
        address indexToken,
        uint256 sizeDelta,
        bool isLong
    ) external {
        uint256 executionFee = IGmxPositionRouter(gmxPositionRouter)
            .minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();
        uint256 acceptablePrice;
        if (isLong) {
            acceptablePrice = gmxVault.getMinPrice(indexToken);
        } else {
            acceptablePrice = gmxVault.getMaxPrice(indexToken);
        }

        (bool success, bytes memory data) = gmxPositionRouter.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxPositionRouter.createDecreasePosition.selector,
                path,
                indexToken,
                0, // collateralDelta
                sizeDelta,
                isLong,
                address(this), // receiver
                acceptablePrice,
                0, // minOut
                executionFee,
                false, // withdrawETH
                address(0) // callbackTarget
            )
        );
        if (!success) {
            revert CreateDecreasePositionFail(_getRevertMsg(data));
        }
        emit CreateDecreasePosition(address(this), bytes32(data));
    }
}