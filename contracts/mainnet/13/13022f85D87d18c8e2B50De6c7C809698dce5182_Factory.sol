// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IFactory.sol";

import "./OrderBook.sol";

/// @title Canonical factory
/// @notice Deploys order book and manages ownership
contract Factory is IFactory {
    using Counters for Counters.Counter;

    address public override owner;
    address public router;
    Counters.Counter private _orderBookIdCounter;

    mapping(address => mapping(address => address))
        private orderBooksByTokenPair;
    mapping(uint8 => address) private orderBooksById;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "Owner address can not be zero");
        owner = _owner;
    }

    /// @inheritdoc IFactory
    function setRouter(address routerAddress) external override onlyOwner {
        require(router == address(0), "Router address is already set");
        require(routerAddress != address(0), "Router address can not be zero");
        router = routerAddress;
    }

    /// inheritdoc IFactory
    function setOwner(address _owner) external override onlyOwner {
        require(_owner != address(0), "New owner address can not be zero");
        owner = _owner;
        emit OwnerChanged(_owner);
    }

    /// @inheritdoc IFactory
    function getOrderBookFromTokenPair(
        address token0,
        address token1
    ) external view override returns (address) {
        return orderBooksByTokenPair[token0][token1];
    }

    /// @notice Returns the address of the order book for the given order book id
    /// @param orderBookId The id of the order book to lookup
    /// @return orderBookAddress The address of the order book
    function getOrderBookFromId(
        uint8 orderBookId
    ) external view override returns (address) {
        return orderBooksById[orderBookId];
    }

    /// @inheritdoc IFactory
    function getOrderBookDetailsFromTokenPair(
        address _token0,
        address _token1
    )
        external
        view
        override
        returns (
            uint8 orderBookId,
            address orderBookAddress,
            address token0,
            address token1,
            uint128 sizeTick,
            uint128 priceTick
        )
    {
        orderBookAddress = orderBooksByTokenPair[_token0][_token1];
        if (orderBookAddress != address(0)) {
            IOrderBook orderBook = IOrderBook(orderBookAddress);
            orderBookId = orderBook.orderBookId();
            token0 = _token0;
            token1 = _token1;
            sizeTick = orderBook.sizeTick();
            priceTick = orderBook.priceTick();
        }
    }

    /// @inheritdoc IFactory
    function getOrderBookDetailsFromId(
        uint8 _orderBookId
    )
        external
        view
        override
        returns (
            uint8 orderBookId,
            address orderBookAddress,
            address token0,
            address token1,
            uint128 sizeTick,
            uint128 priceTick
        )
    {
        orderBookAddress = orderBooksById[_orderBookId];
        if (orderBookAddress != address(0)) {
            IOrderBook orderBook = IOrderBook(orderBookAddress);
            orderBookId = _orderBookId;
            token0 = address(orderBook.token0());
            token1 = address(orderBook.token1());
            sizeTick = orderBook.sizeTick();
            priceTick = orderBook.priceTick();
        }
    }

    // @inheritdoc IFactory
    function createOrderBook(
        address token0,
        address token1,
        uint8 logSizeTick,
        uint8 logPriceTick
    ) external override onlyOwner returns (address orderBookAddress) {
        require(
            token0 != token1,
            "Can not create order book for the same token pair"
        );
        require(token0 != address(0), "Token0 address can not be zero");
        require(token1 != address(0), "Token1 address can not be zero");
        require(router != address(0), "Router address is not set");

        require(
            orderBooksByTokenPair[token0][token1] == address(0),
            "Order book already exists"
        );
        require(
            orderBooksByTokenPair[token1][token0] == address(0),
            "Order book already exists with different token order"
        );
        uint8 orderBookId = uint8(_orderBookIdCounter.current());

        orderBookAddress = address(
            new OrderBook(
                orderBookId,
                token0,
                token1,
                router,
                logSizeTick,
                logPriceTick
            )
        );

        orderBooksByTokenPair[token0][token1] = orderBookAddress;
        orderBooksById[orderBookId] = orderBookAddress;
        _orderBookIdCounter.increment();
        require(
            _orderBookIdCounter.current() < 1 << 8,
            "Can not create order book"
        );

        emit OrderBookCreated(
            orderBookId,
            orderBookAddress,
            token0,
            token1,
            logSizeTick,
            logPriceTick
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title OrderFillCallback interface
/// @notice Callback for updating token balances
interface IBalanceChangeCallback {
    /// @notice Transfer tokens from the contract to the user
    /// @param tokenToTransfer The token to transfer
    /// @param to The user to transfer to
    /// @param amount The amount to transfer
    /// @param orderBookId Id of caller the order book
    function addBalanceCallback(
        IERC20Metadata tokenToTransfer,
        address to,
        uint256 amount,
        uint8 orderBookId
    ) external;

    /// @notice Transfer tokens from the user to the contract
    /// @param tokenToTransferFrom The token to transfer from
    /// @param from The user to transfer from
    /// @param amount The amount to transfer
    /// @param orderBookId Id of caller the order book
    function subtractBalanceCallback(
        IERC20Metadata tokenToTransferFrom,
        address from,
        uint256 amount,
        uint8 orderBookId
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Factory Interface
/// @notice The Factory facilitates creation of order books
interface IFactory {
    /// @notice Event emitted when an order book is created
    /// @param orderBookId The id of the order book
    /// @param orderBookAddress The address of the created orderBook
    /// @param token0 The base token of the orderBook
    /// @param token1 The quote token of the orderBook
    /// @param logSizeTick Log10 of base token tick
    /// amount0 % 10**logSizeTick = 0 should be satisfied
    /// @param logPriceTick Log10 of price tick amount1 * dec0 % amount = 0
    /// and amount1 * dec0 / amount0 % 10**logPriceTick = 0 should be satisfied
    event OrderBookCreated(
        uint8 orderBookId,
        address orderBookAddress,
        address token0,
        address token1,
        uint8 logSizeTick,
        uint8 logPriceTick
    );

    /// @notice Event emitted when the owner is changed
    /// @param owner Address of the new owner
    event OwnerChanged(address owner);

    /// @notice Returns the current owner of the factory
    /// @return owner The address of the factory owner
    function owner() external view returns (address);

    /// @notice Set the router address for the factory. The router address
    /// can only be set once
    /// @param routerAddress The address of the router
    function setRouter(address routerAddress) external;

    /// @notice Set the owner of the factory
    /// @param _owner The address of the new owner
    function setOwner(address _owner) external;

    /// @notice Returns the address of the order book for a given token pair,
    /// or address 0 if it does not exist
    /// @dev token0 and token1 may be passed in either order
    /// @param token0 The contract address the first token
    /// @param token1 The contract address the second token
    /// @return orderBookAddress The address of the order book
    function getOrderBookFromTokenPair(address token0, address token1)
        external
        view
        returns (address);

    /// @notice Returns the address of the order book for the given order book id
    /// @param orderBookId The id of the order book to lookup
    /// @return orderBookAddress The address of the order book
    function getOrderBookFromId(uint8 orderBookId)
        external
        view
        returns (address);

    /// @notice Returns the details of the order book for a given token pair
    /// @param token0 The first token of the order book
    /// @param token1 The second token of the order book
    /// @return orderBookId The id of the order book
    /// @return orderBookAddress The address of the order book
    /// @return token0 The base token of the order book
    /// @return token1 The quote token of the order book
    /// @return sizeTick The size tick of the order book
    /// @return priceTick The price tick of the order book
    function getOrderBookDetailsFromTokenPair(address token0, address token1)
        external
        view
        returns (
            uint8,
            address,
            address,
            address,
            uint128,
            uint128
        );

    /// @notice Returns the details of the order book for a given order book id
    /// @param orderBookId The id of the order book to lookup
    /// @return orderBookId The id of the order book
    /// @return orderBookAddress The address of the order book
    /// @return token0 The base token of the order book
    /// @return token1 The quote token of the order book
    /// @return sizeTick The size tick of the order book
    /// @return priceTick The price tick of the order book
    function getOrderBookDetailsFromId(uint8 orderBookId)
        external
        view
        returns (
            uint8,
            address,
            address,
            address,
            uint128,
            uint128
        );

    /// @notice Creates a orderBook for the given two tokens
    /// @dev token0 and token1 may be passed in either order
    /// @param token0 The contract address the first token
    /// @param token1 The contract address the second token
    /// @param logSizeTick Log10 of base token tick
    /// amount0 % 10**logSizeTick = 0 should be satisfied
    /// @param logPriceTick Log10 of price tick amount1 * dec0 % amount = 0
    /// and amount1 * dec0 / amount0 % 10**logPriceTick = 0 should be satisfied
    /// @return orderBookAddress The address of the newly created orderBook
    function createOrderBook(
        address token0,
        address token1,
        uint8 logSizeTick,
        uint8 logPriceTick
    ) external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../library/LinkedList.sol";

/// @title Order Book Interface
/// @notice An order book facilitates placing limit and market orders to trade
/// two assets which conform to the ERC20 specification. token0 is the asset
/// traded in the order book, and token1 is the asset paid/received for trading
/// token0
interface IOrderBook {
    /// @notice Create a limit order in the order book. The order will be
    /// filled by existing orders if there is a price overlap. If the order
    /// is not fully filled, it will be added to the order book
    /// @param amount0Base The amount of token0 in the limit order in terms
    /// of number of sizeTicks. The actual amount of token0 in the order will
    /// be amount0Base * sizeTick.
    /// @param priceBase The price of the token0 in terms of token1 and size
    /// and price ticks. The actual amount of token1 in the order will be
    /// priceBase * amount0Base * priceTick * sizeTick / dec0
    /// @param isAsk Whether the order is an ask order. isAsk = true means
    /// the order sells token0 for token1
    /// @param from The address of the order sender
    /// @param hintId Where to insert the order in the order book. Meant to
    /// be calculated off-chain using the getMockIndexToInsert function
    /// @return id The id of the order
    function createLimitOrder(
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        address from,
        uint32 hintId
    ) external returns (uint32);

    /// @notice Cancel an existing limit order in the order book. Refunds the
    /// remaining tokens in the order to the owner
    /// @param id The id of the order to cancel
    /// @param from The address of the order sender
    /// @return isCanceled Whether the order was successfully canceled
    function cancelLimitOrder(uint32 id, address from) external returns (bool);

    /// @notice Create a market order in the order book. The order will be
    /// filled by existing orders if there is a price overlap. If the order
    /// is not fully filled, it will NOT be added to the order book
    /// @param amount0Base The amount of token0 in the limit order in terms
    /// of number of sizeTicks. The actual amount of token0 in the order will
    /// be amount0Base * sizeTick
    /// @param priceBase The price of the token0 in terms of token1 and size
    /// and price ticks. The actual amount of token1 in the order will be
    /// priceBase * amount0Base * priceTick * sizeTick / dec0
    /// @param isAsk Whether the order is an ask order. isAsk = true means
    /// the order sells token0 for token1
    /// @param from The address of the order sender
    function createMarketOrder(
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        address from
    ) external;

    /// @notice Get the order details of all limit orders in the order book.
    /// Each returned list contains the details of ask orders first, followed
    /// by bid orders
    /// @return id The ids of the orders
    /// @return owner The addresses of the orders' owners
    /// @return amount0 The amount of token0 remaining in the orders
    /// @return amount1 The amount of token1 remaining in the orders
    /// @return isAsk Whether each order is an ask order
    function getLimitOrders()
        external
        view
        returns (
            uint32[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        );

    /// @notice Get the order details of the ask order with the lowest price
    /// in the order book
    /// @return bestAsk LimitOrder data struct of the best ask order
    function getBestAsk() external view returns (LimitOrder memory);

    /// @notice Get the order details of the bid order with the highest price
    /// in the order book
    /// @return bestBid LimitOrder data struct of the best bid order
    function getBestBid() external view returns (LimitOrder memory);

    /// @notice Return whether an order is active
    /// @param id The id of the order
    /// @return isActive True if the order is active, false otherwise
    function isOrderActive(uint32 id) external view returns (bool);

    /// @notice Return whether an order is an ask order or not, fails if order is not active
    /// @param id The id of the order
    /// @return isActive True if the order is an ask order, false otherwise
    function isAskOrder(uint32 id) external view returns (bool);

    /// @notice Find the order id to the left of where the new order
    /// should be inserted. Meant to be used off-chain to find the
    /// hintId for the createLimitOrder functions
    /// @param amount0 The amount of token0 in the new order
    /// @param amount1 The amount of token1 in the new order
    /// @param isAsk Whether the new order is an ask order
    /// @return hintId The id of the order to the left of where the new order
    /// should be inserted
    function getMockIndexToInsert(
        uint256 amount0,
        uint256 amount1,
        bool isAsk
    ) external view returns (uint32);

    /// @notice Id of the order book
    /// @return orderBookId The unique identifier of an order book
    function orderBookId() external view returns (uint8);

    /// @notice The base token
    /// @return token0 The base token contract
    function token0() external view returns (IERC20Metadata);

    /// @notice The quote token
    /// @return token1 The quote token contract
    function token1() external view returns (IERC20Metadata);

    /// @notice The sizeTick of the order book
    /// @return sizeTick The sizeTick of the order book
    function sizeTick() external view returns (uint128);

    /// @notice The priceTick of the order book
    /// @return priceTick The priceTick of the order book
    function priceTick() external view returns (uint128);

    /// @notice The priceMultiplier of the order book
    /// @return priceMultiplier The priceMultiplier of the order book
    function priceMultiplier() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";

library FullMath {
    /// @notice Returns a*b/denominator, throws if remainder is not 0
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        require(denominator != 0, "Can not divide with 0");
        uint256 remainder = 0;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        require(remainder == 0, "Divison has a positive remainder");
        return Math.mulDiv(a, b, denominator);
    }

    /// @notice Returns true if a*b < c*d
    function mulCompare(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) internal pure returns (bool result) {
        uint256 prod0; // Least significant 256 bits of the product a*b
        uint256 prod1; // Most significant 256 bits of the product a*b
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        uint256 prod2; // Least significant 256 bits of the product c*d
        uint256 prod3; // Most significant 256 bits of the product c*d
        assembly {
            let mm := mulmod(c, d, not(0))
            prod2 := mul(c, d)
            prod3 := sub(sub(mm, prod2), lt(mm, prod2))
        }

        if (prod1 < prod3) return true;
        if (prod3 < prod1) return false;
        if (prod0 < prod2) return true;
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./FullMath.sol";

/// @notice Struct containing limit order data
struct LimitOrder {
    uint32 id;
    address owner;
    uint256 amount0;
    uint256 amount1;
}

/// @notice Struct for linked list node
/// @dev Each order id is mapped to a Node in the linked list
struct Node {
    uint32 prev;
    uint32 next;
    bool active;
}

/// @notice Struct for linked list sorted by price in non-decreasing order.
/// Used to store ask limit orders in the order book.
/// @dev Each order id is mapped to a Node and a LimitOrder
struct MinLinkedList {
    mapping(uint32 => Node) list;
    mapping(uint32 => LimitOrder) idToLimitOrder;
}

/// @notice Struct for linked list sorted in non-increasing order
/// Used to store bid limit orders in the order book.
/// @dev Each order id is mapped to a Node and a Limit Order
struct MaxLinkedList {
    mapping(uint32 => Node) list;
    mapping(uint32 => LimitOrder) idToLimitOrder;
}

/// @title MinLinkedListLib
/// @notice Library for linked list sorted in non-decreasing order
/// @dev Order ids 0 and 1 are special values. The first node of the
/// linked list has order id 0 and the last node has order id 1.
/// Order 0 should be initalized (in OrderBook.sol) with the lowest
/// possible price, and order 1 should be initialized with the highest
library MinLinkedListLib {
    /// @notice Comparison function for linked list. Returns true
    /// if the price of order id0 is strictly less than the price of order id1
    function compare(
        MinLinkedList storage listData,
        uint32 id0,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                listData.idToLimitOrder[id0].amount1,
                listData.idToLimitOrder[id1].amount0,
                listData.idToLimitOrder[id1].amount1,
                listData.idToLimitOrder[id0].amount0
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted
    /// @param orderId The order id to insert
    /// @param hintId The order id to start searching from
    function findIndexToInsert(
        MinLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) internal view returns (uint32) {
        // No element in the linked list can have next = 0, it means hintId is not in the linked list
        require(listData.list[hintId].next != 0, "Invalid hint id");

        while (!listData.list[hintId].active) {
            hintId = listData.list[hintId].next;
        }

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.
        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (compare(listData, orderId, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!compare(listData, orderId, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }

    /// @notice Inserts an order id into the linked list in sorted order
    /// @param orderId The order id to insert
    /// @param hintId The order id to begin searching for the position to
    /// insert the new order. Can be 0, 1, or the id of an actual order
    function insert(
        MinLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) public {
        uint32 indexToInsert = findIndexToInsert(listData, orderId, hintId);

        uint32 next = listData.list[indexToInsert].next;
        listData.list[orderId] = Node({
            prev: indexToInsert,
            next: next,
            active: true
        });
        listData.list[indexToInsert].next = orderId;
        listData.list[next].prev = orderId;
    }

    /// @notice Remove an order id from the linked list
    /// @dev Updates the linked list but does not delete the order id from
    /// the idToLimitOrder mapping
    /// @param orderId The order id to remove
    function erase(MinLinkedList storage listData, uint32 orderId) public {
        require(orderId > 1, "Cannot erase dummy orders");
        require(
            listData.list[orderId].active,
            "Cannot cancel an already inactive order"
        );

        uint32 prev = listData.list[orderId].prev;
        uint32 next = listData.list[orderId].next;

        listData.list[prev].next = next;
        listData.list[next].prev = prev;
        listData.list[orderId].active = false;
    }

    /// @notice Get the first order id in the linked list. Since the linked
    /// list is sorted, this gets the order id with the lowest price, if all
    /// the orders are dummy orders, returns 1
    /// @dev Order id 0 is a dummy value and should not be returned
    function getFirstNode(MinLinkedList storage listData)
        internal
        view
        returns (uint32)
    {
        return listData.list[0].next;
    }

    /// @notice Get the LimitOrder data struct for the first order
    function getTopLimitOrder(MinLinkedList storage listData)
        public
        view
        returns (LimitOrder storage)
    {
        require(!isEmpty(listData), "Book side is empty");
        return listData.idToLimitOrder[getFirstNode(listData)];
    }

    /// @notice Returns true if the linked list has no orders
    /// @dev Order id 0 and 1 are dummy values, so the linked list
    /// is empty if those are the only two orders
    function isEmpty(MinLinkedList storage listData)
        public
        view
        returns (bool)
    {
        return getFirstNode(listData) == 1;
    }

    /// @notice Returns the number of orders in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the number of
    /// orders does not include them
    function size(MinLinkedList storage listData) public view returns (uint32) {
        uint32 listSize = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) ++listSize;
        return listSize;
    }

    /// @notice Returns a list of LimitOrder data structs for each
    /// order in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the returned list
    /// does not include them
    function getOrders(MinLinkedList storage listData)
        public
        view
        returns (LimitOrder[] memory orders)
    {
        orders = new LimitOrder[](size(listData));
        uint32 i = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) {
            orders[i] = listData.idToLimitOrder[pointer];
            ++i;
        }
    }

    /// @notice Comparison function for linked list. Returns true if the
    /// price of amount0 to amount1 is less than the price of order id1
    function mockCompare(
        MinLinkedList storage listData,
        uint256 amount0,
        uint256 amount1,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                amount1,
                listData.idToLimitOrder[id1].amount0,
                listData.idToLimitOrder[id1].amount1,
                amount0
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted. Meant to be used off-chain to find the
    /// hintId for the insert function
    /// @param amount0 The amount of token0 in the new order
    /// @param amount1 The amount of token1 in the new order
    function getMockIndexToInsert(
        MinLinkedList storage listData,
        uint256 amount0,
        uint256 amount1
    ) public view returns (uint32) {
        uint32 hintId = 0;

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.
        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (mockCompare(listData, amount0, amount1, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!mockCompare(listData, amount0, amount1, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }
}

/// @title MaxLinkedListLib
/// @notice Library for linked list sorted in non-increasing order
/// @dev Order ids 0 and 1 are special values. The first node of the
/// linked list has order id 0 and the last node has order id 1.
/// Order 0 should be initalized (in OrderBook.sol) with the highest
/// possible price, and order 1 should be initialized with the lowest
library MaxLinkedListLib {
    /// @notice Comparison function for linked list. Returns true
    /// if the price of order id0 is strictly greater than the price of order id1
    function compare(
        MaxLinkedList storage listData,
        uint32 id0,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                listData.idToLimitOrder[id1].amount1,
                listData.idToLimitOrder[id0].amount0,
                listData.idToLimitOrder[id1].amount0,
                listData.idToLimitOrder[id0].amount1
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted
    /// @param orderId The order id to insert
    /// @param hintId The order id to start searching from
    function findIndexToInsert(
        MaxLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) internal view returns (uint32) {
        // No element in the linked list can have next = 0, it means hintId is not in the linked list
        require(listData.list[hintId].next != 0, "Invalid hint id");

        while (!listData.list[hintId].active) {
            hintId = listData.list[hintId].next;
        }

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.
        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (compare(listData, orderId, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!compare(listData, orderId, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }

    /// @notice Inserts an order id into the linked list in sorted order
    /// @param orderId The order id to insert
    /// @param hintId The order id to begin searching for the position to
    /// insert the new order. Can be 0, 1, or the id of an actual order
    function insert(
        MaxLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) public {
        uint32 indexToInsert = findIndexToInsert(listData, orderId, hintId);

        uint32 next = listData.list[indexToInsert].next;
        listData.list[orderId] = Node({
            prev: indexToInsert,
            next: next,
            active: true
        });
        listData.list[indexToInsert].next = orderId;
        listData.list[next].prev = orderId;
    }

    /// @notice Remove an order id from the linked list
    /// @dev Updates the linked list but does not delete the order id from
    /// the idToLimitOrder mapping
    /// @param orderId The order id to remove
    function erase(MaxLinkedList storage listData, uint32 orderId) public {
        require(orderId > 1, "Cannot erase dummy orders");
        require(
            listData.list[orderId].active,
            "Cannot cancel an already inactive order"
        );

        uint32 prev = listData.list[orderId].prev;
        uint32 next = listData.list[orderId].next;

        listData.list[prev].next = next;
        listData.list[next].prev = prev;
        listData.list[orderId].active = false;
    }

    /// @notice Get the first order id in the linked list. Since the linked
    /// list is sorted, this gets the order id with the highest price, if all
    /// the orders are dummy orders, returns 1
    /// @dev Order id 0 is a dummy value and should not be returned
    function getFirstNode(MaxLinkedList storage listData)
        internal
        view
        returns (uint32)
    {
        return listData.list[0].next;
    }

    /// @notice Get the LimitOrder data struct for the first order
    function getTopLimitOrder(MaxLinkedList storage listData)
        public
        view
        returns (LimitOrder storage)
    {
        require(!isEmpty(listData), "Book side is empty");
        return listData.idToLimitOrder[getFirstNode(listData)];
    }

    /// @notice Returns true if the linked list has no orders
    /// @dev Order id 0 and 1 are dummy values, so the linked list
    /// is empty if those are the only two orders
    function isEmpty(MaxLinkedList storage listData)
        public
        view
        returns (bool)
    {
        return getFirstNode(listData) == 1;
    }

    /// @notice Returns the number of orders in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the number of
    /// orders does not include them
    function size(MaxLinkedList storage listData) public view returns (uint32) {
        uint32 listSize = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) ++listSize;
        return listSize;
    }

    /// @notice Returns a list of LimitOrder data structs for each
    /// order in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the returned list
    /// does not include them
    function getOrders(MaxLinkedList storage listData)
        public
        view
        returns (LimitOrder[] memory orders)
    {
        orders = new LimitOrder[](size(listData));
        uint32 i = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) {
            orders[i] = listData.idToLimitOrder[pointer];
            ++i;
        }
    }

    /// @notice Comparison function for linked list. Returns true if the
    /// price of amount0 to amount1 is greater than the price of order id1
    function mockCompare(
        MaxLinkedList storage listData,
        uint256 amount0,
        uint256 amount1,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                listData.idToLimitOrder[id1].amount1,
                amount0,
                listData.idToLimitOrder[id1].amount0,
                amount1
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted. Meant to be used off-chain to find the
    /// hintId for the insert function
    /// @param amount0 The amount of token0 in the new order
    /// @param amount1 The amount of token1 in the new order
    function getMockIndexToInsert(
        MaxLinkedList storage listData,
        uint256 amount0,
        uint256 amount1
    ) public view returns (uint32) {
        uint32 hintId = 0;

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.

        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (mockCompare(listData, amount0, amount1, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!mockCompare(listData, amount0, amount1, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IOrderBook.sol";
import "./interfaces/IBalanceChangeCallback.sol";

import "./library/FullMath.sol";

/// @title Order Book
contract OrderBook is IOrderBook {
    using Counters for Counters.Counter;
    using MinLinkedListLib for MinLinkedList;
    using MaxLinkedListLib for MaxLinkedList;
    /// Linked list of ask orders sorted by orders with the lowest prices
    /// coming first
    MinLinkedList ask;
    /// Linked list of bid orders sorted by orders with the highest prices
    /// coming first
    MaxLinkedList bid;
    /// The order id of the last order created
    Counters.Counter private _orderIdCounter;

    /// @notice The address of the router for this order book
    address public immutable routerAddress;
    IBalanceChangeCallback public immutable balanceChangeCallback;

    uint8 public immutable orderBookId;
    IERC20Metadata public immutable token0;
    IERC20Metadata public immutable token1;
    uint128 public immutable sizeTick;
    uint128 public immutable priceTick;
    uint128 public immutable priceMultiplier;

    /// @notice Emitted whenever a limit order is created
    event LimitOrderCreated(
        uint32 indexed id,
        address indexed owner,
        uint256 amount0,
        uint256 amount1,
        bool isAsk
    );

    /// @notice Emitted whenever a limit order is canceled
    event LimitOrderCanceled(
        uint32 indexed id,
        address indexed owner,
        uint256 amount0,
        uint256 amount1,
        bool isAsk
    );

    /// @notice Emitted whenever a market order is created
    event MarketOrderCreated(
        uint32 indexed id,
        address indexed owner,
        uint256 amount0,
        uint256 amount1,
        bool isAsk
    );

    /// @notice Emitted whenever a swap between two orders occurs. This
    /// happens when orders are being filled
    event Swap(
        uint256 amount0,
        uint256 amount1,
        uint32 indexed askId,
        address askOwner,
        uint32 indexed bidId,
        address bidOwner
    );

    function checkIsRouter() private view {
        require(
            msg.sender == routerAddress,
            "Only the router contract can call this function"
        );
    }

    modifier onlyRouter() {
        checkIsRouter();
        _;
    }

    constructor(
        uint8 _orderBookId,
        address token0Address,
        address token1Address,
        address _routerAddress,
        uint8 logSizeTick,
        uint8 logPriceTick
    ) {
        token0 = IERC20Metadata(token0Address);
        token1 = IERC20Metadata(token1Address);
        orderBookId = _orderBookId;
        routerAddress = _routerAddress;
        balanceChangeCallback = IBalanceChangeCallback(_routerAddress);

        require(10 ** logSizeTick < 1 << 128, "logSizeTick is too big");
        require(10 ** logPriceTick < 1 << 128, "logPriceTick is too big");
        sizeTick = uint128(10 ** logSizeTick);
        priceTick = uint128(10 ** logPriceTick);

        require(
            logSizeTick + logPriceTick >= token0.decimals(),
            "Invalid size and price tick combination"
        );
        uint256 priceMultiplierCheck = FullMath.mulDiv(
            priceTick,
            sizeTick,
            10 ** (token0.decimals())
        );
        require(priceMultiplierCheck < 1 << 128, "priceMultiplier is too big");
        priceMultiplier = uint128(priceMultiplierCheck);

        setupOrderBook();
    }

    function setupOrderBook() internal {
        ask.list[0] = Node({prev: 0, next: 1, active: true});
        ask.list[1] = Node({prev: 0, next: 1, active: true});
        // Order id 0 is a dummy value and has the lowest possible price
        // in the ask linked list
        ask.idToLimitOrder[0] = LimitOrder({
            id: 0,
            owner: address(0),
            amount0: 1,
            amount1: 0
        });
        // Order id 1 is a dummy value and has the highest possible price
        // in the ask linked list
        ask.idToLimitOrder[1] = LimitOrder({
            id: 1,
            owner: address(0),
            amount0: 0,
            amount1: 1
        });

        bid.list[0] = Node({prev: 0, next: 1, active: true});
        bid.list[1] = Node({prev: 0, next: 1, active: true});
        // Order id 0 is a dummy value and has the highest possible price
        // in the bid linked list
        bid.idToLimitOrder[0] = LimitOrder({
            id: 0,
            owner: address(0),
            amount0: 0,
            amount1: 1
        });
        // Order id 1 is a dummy value and has the lowest possible price
        // in the bid linked list
        bid.idToLimitOrder[1] = LimitOrder({
            id: 1,
            owner: address(0),
            amount0: 1,
            amount1: 0
        });

        // Id's 0 and 1 are used for dummy orders, thus first actual order should have id 2
        _orderIdCounter.increment();
        _orderIdCounter.increment();
    }

    /// @notice Transfers tokens to sell (base or quote token) to the router contract depending on the size
    /// Matches the new order with existing orders in the order book if there are price overlaps
    /// Does not insert the remaining order into the order book post matching
    /// If limit order caller should insert the remaining order to order book
    /// If market order caller should refund remaining tokens in the remaining order
    /// @param order The limit order to fill
    /// @param isAsk Whether the order is an ask order
    /// @param from The address of the order sender
    function matchOrder(
        LimitOrder memory order,
        bool isAsk,
        address from
    ) private {
        uint256 filledAmount0 = 0;
        uint256 filledAmount1 = 0;

        uint32 index;

        if (isAsk) {
            balanceChangeCallback.subtractBalanceCallback(
                token0,
                from,
                order.amount0,
                orderBookId
            );

            bool atLeastOneFullSwap = false;

            index = bid.getFirstNode();
            while (index != 1 && order.amount0 > 0) {
                LimitOrder storage bestBid = bid.idToLimitOrder[index];
                (
                    uint256 swapAmount0,
                    uint256 swapAmount1
                ) = getLimitOrderSwapAmounts(order, bestBid, isAsk);
                // Since the linked list is sorted, if there is no price
                // overlap on the current order, there will be no price
                // overlap on the later orders
                if (swapAmount0 == 0 || swapAmount1 == 0) break;

                emit Swap(
                    swapAmount0,
                    swapAmount1,
                    order.id,
                    from,
                    bestBid.id,
                    bestBid.owner
                );

                balanceChangeCallback.addBalanceCallback(
                    token0,
                    bestBid.owner,
                    swapAmount0,
                    orderBookId
                );
                filledAmount0 = filledAmount0 + swapAmount0;
                filledAmount1 = filledAmount1 + swapAmount1;

                order.amount1 = order.amount1 - (
                    FullMath.mulDiv(order.amount1, swapAmount0, order.amount0)
                );
                order.amount0 = order.amount0 - swapAmount0;

                if (bestBid.amount0 == swapAmount0) {
                    // Remove the best bid from the order book if it is fully
                    // filled
                    atLeastOneFullSwap = true;
                    bid.list[index].active = false;
                    delete bid.idToLimitOrder[bestBid.id];
                } else {
                    // Update the best bid if it is partially filled
                    bestBid.amount0 = bestBid.amount0 - swapAmount0;
                    bestBid.amount1 = bestBid.amount1 - swapAmount1;
                    break;
                }

                index = bid.list[index].next;
            }
            if (atLeastOneFullSwap) {
                bid.list[index].prev = 0;
                bid.list[0].next = index;
            }

            if (filledAmount1 > 0) {
                balanceChangeCallback.addBalanceCallback(
                    token1,
                    from,
                    filledAmount1,
                    orderBookId
                );
            }
        } else {
            uint256 firstAmount1 = order.amount1;
            balanceChangeCallback.subtractBalanceCallback(
                token1,
                from,
                order.amount1,
                orderBookId
            );

            bool atLeastOneFullSwap = false;

            index = ask.getFirstNode();
            while (index != 1 && order.amount1 > 0) {
                LimitOrder storage bestAsk = ask.idToLimitOrder[index];
                (
                    uint256 swapAmount0,
                    uint256 swapAmount1
                ) = getLimitOrderSwapAmounts(order, bestAsk, isAsk);
                // Since the linked list is sorted, if there is no price
                // overlap on the current order, there will be no price
                // overlap on the later orders
                if (swapAmount0 == 0 || swapAmount1 == 0) break;

                emit Swap(
                    swapAmount0,
                    swapAmount1,
                    bestAsk.id,
                    bestAsk.owner,
                    order.id,
                    from
                );

                balanceChangeCallback.addBalanceCallback(
                    token1,
                    bestAsk.owner,
                    swapAmount1,
                    orderBookId
                );
                filledAmount0 = filledAmount0 + swapAmount0;
                filledAmount1 = filledAmount1 + swapAmount1;

                order.amount1 = order.amount1 - (
                    FullMath.mulDiv(order.amount1, swapAmount0, order.amount0)
                );
                order.amount0 = order.amount0 - swapAmount0;

                if (bestAsk.amount0 == swapAmount0) {
                    // Remove the best ask from the order book if it is fully
                    // filled
                    atLeastOneFullSwap = true;
                    ask.list[index].active = false;
                    delete ask.idToLimitOrder[bestAsk.id];
                } else {
                    // Update the best ask if it is partially filled
                    bestAsk.amount0 = bestAsk.amount0 - swapAmount0;
                    bestAsk.amount1 = bestAsk.amount1 - swapAmount1;
                    break;
                }

                index = ask.list[index].next;
            }
            if (atLeastOneFullSwap) {
                ask.list[index].prev = 0;
                ask.list[0].next = index;
            }

            // The buy/sell sizes are determined by baseToken amount, and for bid orders users deposit quoteToken
            // After running the initial matching, filledAmount0 will be the amount of bought baseToken
            // and filledAmount1 will be the amount of sold quoteToken
            // Initially user pays filledAmount0 * price amount of quoteToken
            // Since the matching happens on maker price, we need to refund the quoteToken amount that is not used in matching
            uint256 refundAmount1 = firstAmount1 - order.amount1 - filledAmount1;

            if (refundAmount1 > 0) {
                balanceChangeCallback.addBalanceCallback(
                    token1,
                    from,
                    refundAmount1,
                    orderBookId
                );
            }

            if (filledAmount0 > 0) {
                balanceChangeCallback.addBalanceCallback(
                    token0,
                    from,
                    filledAmount0,
                    orderBookId
                );
            }
        }
    }

    /// @inheritdoc IOrderBook
    function createLimitOrder(
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        address from,
        uint32 hintId
    ) external override onlyRouter returns (uint32 newOrderId) {
        require(hintId < _orderIdCounter.current(), "Invalid hint id");
        require(amount0Base > 0, "Invalid size");
        require(priceBase > 0, "Invalid price");
        uint256 amount0 = uint256(amount0Base) * sizeTick;
        uint256 amount1 = uint256(priceBase) * amount0Base * priceMultiplier;
        require(
            _orderIdCounter.current() < 1 << 32,
            "New order id exceeds limit"
        );
        newOrderId = uint32(_orderIdCounter.current());
        _orderIdCounter.increment();

        LimitOrder memory newOrder = LimitOrder(
            newOrderId,
            from,
            amount0,
            amount1
        );

        emit LimitOrderCreated(
            newOrderId,
            from,
            newOrder.amount0,
            newOrder.amount1,
            isAsk
        );

        matchOrder(newOrder, isAsk, from);

        // If the order is not fully filled, insert it into the order book
        if (isAsk) {
            if (newOrder.amount0 > 0) {
                ask.idToLimitOrder[newOrderId] = newOrder;
                ask.insert(newOrderId, hintId);
            }
        } else {
            if (newOrder.amount0 > 0) {
                bid.idToLimitOrder[newOrderId] = newOrder;
                bid.insert(newOrderId, hintId);
            }
        }
    }

    /// @inheritdoc IOrderBook
    function cancelLimitOrder(
        uint32 id,
        address from
    ) external override onlyRouter returns (bool) {
        if (!isOrderActive(id)) {
            return false;
        }

        LimitOrder memory order;
        bool isAsk = isAskOrder(id);
        if (isAsk) {
            order = ask.idToLimitOrder[id];
            require(
                order.owner == from,
                "The caller should be the owner of the order"
            );
            balanceChangeCallback.addBalanceCallback(
                token0,
                from,
                ask.idToLimitOrder[id].amount0,
                orderBookId
            );
            ask.erase(id);
            delete ask.idToLimitOrder[id];
        } else {
            order = bid.idToLimitOrder[id];
            require(
                order.owner == from,
                "The caller should be the owner of the order"
            );
            balanceChangeCallback.addBalanceCallback(
                token1,
                from,
                bid.idToLimitOrder[id].amount1,
                orderBookId
            );
            bid.erase(id);
            delete bid.idToLimitOrder[id];
        }

        emit LimitOrderCanceled(id, from, order.amount0, order.amount1, isAsk);
        return true;
    }

    /// @inheritdoc IOrderBook
    function createMarketOrder(
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        address from
    ) external override onlyRouter {
        require(amount0Base > 0, "Invalid size");
        require(priceBase > 0, "Invalid price");
        uint256 amount0 = uint256(amount0Base) * sizeTick;
        uint256 amount1 = uint256(priceBase) * amount0Base * priceMultiplier;

        require(
            _orderIdCounter.current() < 1 << 32,
            "New order id exceeds limit"
        );
        uint32 newOrderId = uint32(_orderIdCounter.current());
        _orderIdCounter.increment();

        LimitOrder memory newOrder = LimitOrder(
            newOrderId,
            from,
            amount0,
            amount1
        );

        emit MarketOrderCreated(
            newOrderId,
            from,
            newOrder.amount0,
            newOrder.amount1,
            isAsk
        );

        matchOrder(newOrder, isAsk, from);

        // If the order is not fully filled, refund the remaining deposited amount
        if (isAsk) {
            balanceChangeCallback.addBalanceCallback(
                token0,
                from,
                newOrder.amount0,
                orderBookId
            );
        } else {
            balanceChangeCallback.addBalanceCallback(
                token1,
                from,
                newOrder.amount1,
                orderBookId
            );
        }
    }

    /// @notice Return the minimum between two uints
    /// @return min The minimum of the two uints
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    /// @notice Get the amount of token0 and token1 to traded between
    /// two orders
    /// @param takerOrder The order taking liquidity from the order book
    /// @param makerOrder The order which already exists in the order book
    /// providing liquidity
    /// @param isTakerAsk Whether the takerOrder is an ask order. If the takerOrder
    /// is an ask order, then the makerOrder must be a bid order and vice versa
    /// @return amount0 The amount of token0 to be traded
    /// @return amount1 The amount of token1 to be traded
    function getLimitOrderSwapAmounts(
        LimitOrder memory takerOrder,
        LimitOrder memory makerOrder,
        bool isTakerAsk
    ) internal pure returns (uint256, uint256) {
        // Default is 0 if there is no price overlap
        uint256 amount0Return = 0;
        uint256 amount1Return = 0;

        // If the takerOrder is an ask, and the makerOrder price is at least
        // the takerOrder's price, then the takerOrder can be filled
        // If the takerOrder is a bid, and the makerOrder price is at most
        // the takerOrder's price, then the takerOrder can be filled
        if (
            (isTakerAsk &&
                !FullMath.mulCompare(
                    takerOrder.amount0,
                    makerOrder.amount1,
                    makerOrder.amount0,
                    takerOrder.amount1
                )) ||
            (!isTakerAsk &&
                !FullMath.mulCompare(
                    makerOrder.amount0,
                    takerOrder.amount1,
                    takerOrder.amount0,
                    makerOrder.amount1
                ))
        ) {
            amount0Return = min(takerOrder.amount0, makerOrder.amount0);
            // The price traded at is the makerOrder's price
            amount1Return = FullMath.mulDiv(
                amount0Return,
                makerOrder.amount1,
                makerOrder.amount0
            );
        }

        return (amount0Return, amount1Return);
    }

    /// @inheritdoc IOrderBook
    function getLimitOrders()
        external
        view
        override
        onlyRouter
        returns (
            uint32[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        LimitOrder[] memory asks = ask.getOrders();
        LimitOrder[] memory bids = bid.getOrders();

        uint32[] memory ids = new uint32[](asks.length + bids.length);
        address[] memory owners = new address[](asks.length + bids.length);
        uint256[] memory amount0s = new uint256[](asks.length + bids.length);
        uint256[] memory amount1s = new uint256[](asks.length + bids.length);
        bool[] memory isAsks = new bool[](asks.length + bids.length);

        for (uint32 i = 0; i < asks.length; i++) {
            ids[i] = asks[i].id;
            owners[i] = asks[i].owner;
            amount0s[i] = asks[i].amount0;
            amount1s[i] = asks[i].amount1;
            isAsks[i] = true;
        }

        for (uint32 i = 0; i < bids.length; i++) {
            ids[asks.length + i] = bids[i].id;
            owners[asks.length + i] = bids[i].owner;
            amount0s[asks.length + i] = bids[i].amount0;
            amount1s[asks.length + i] = bids[i].amount1;
            isAsks[asks.length + i] = false;
        }

        return (ids, owners, amount0s, amount1s, isAsks);
    }

    /// @inheritdoc IOrderBook
    function getBestAsk()
        external
        view
        override
        onlyRouter
        returns (LimitOrder memory)
    {
        return ask.getTopLimitOrder();
    }

    /// @inheritdoc IOrderBook
    function getBestBid()
        external
        view
        override
        onlyRouter
        returns (LimitOrder memory)
    {
        return bid.getTopLimitOrder();
    }

    /// @inheritdoc IOrderBook
    function isOrderActive(
        uint32 id
    ) public view override onlyRouter returns (bool) {
        return ask.list[id].active || bid.list[id].active;
    }

    /// @inheritdoc IOrderBook
    function isAskOrder(uint32 id) public view returns (bool) {
        require(
            ask.idToLimitOrder[id].owner != address(0) ||
                bid.idToLimitOrder[id].owner != address(0),
            "Given order does not exist"
        );
        return ask.idToLimitOrder[id].owner != address(0);
    }

    /// @inheritdoc IOrderBook
    function getMockIndexToInsert(
        uint256 amount0,
        uint256 amount1,
        bool isAsk
    ) external view override returns (uint32) {
        require(amount0 > 0, "Amount0 must be greater than 0");
        if (isAsk) {
            return ask.getMockIndexToInsert(amount0, amount1);
        } else {
            return bid.getMockIndexToInsert(amount0, amount1);
        }
    }
}