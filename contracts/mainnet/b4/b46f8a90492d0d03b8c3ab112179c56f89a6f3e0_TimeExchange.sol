// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./ITimeToken.sol";
import "./ITimeIsUp.sol";

contract TimeExchange {

    using Math for uint256;

    uint256 private constant FACTOR = 10 ** 18;

    uint256 public constant FEE = 60;
    address public constant DEVELOPER_ADDRESS = 0x731591207791A93fB0Ec481186fb086E16A7d6D0;
    address public immutable timeAddress;
    address public immutable tupAddress;

    mapping (address => uint256) private _currentBlock;
    
    constructor(address time, address tup) {
        timeAddress = time;
        tupAddress = tup;
    }

    receive() external payable {
    }

    fallback() external payable {
        require(msg.data.length == 0);
    }

    /// @notice Modifier to make a function runs only once per block
    modifier onlyOncePerBlock() {
        require(block.number != _currentBlock[tx.origin], "Time Exchange: you cannot perform this operation again in this block");
        _;
        _currentBlock[tx.origin] = block.number;
    }

    /// @notice Swaps native currency for another token
    /// @dev Please refer this function is called by swap() function
    /// @param tokenTo The address of the token to be swapped
    /// @param amount The native currency amount to be swapped
    function _swapFromNativeToToken(address tokenTo, uint256 amount) private {
        IERC20 token = IERC20(tokenTo);
        uint256 comission = amount.mulDiv(FEE, 10_000);
        amount -= comission;
        payable(tokenTo).call{value: amount}("");
        payable(DEVELOPER_ADDRESS).call{value: comission / 2}("");
        ITimeIsUp(payable(tupAddress)).receiveProfit{value: comission / 2}();
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /// @notice Swaps token for native currency
    /// @dev Please refer this function is called by swap() function
    /// @param tokenFrom The address of the token to be swapped
    /// @param amount The token amount to be swapped
    function _swapFromTokenToNative(address tokenFrom, uint256 amount) private {
        IERC20 token = IERC20(tokenFrom);
        token.transferFrom(msg.sender, address(this), amount);
        uint256 balanceBefore = address(this).balance;
        token.transfer(tokenFrom, amount);
        uint256 balanceAfter = address(this).balance - balanceBefore;
        uint256 comission = balanceAfter.mulDiv(FEE, 10_000);
        balanceAfter -= comission;
        payable(msg.sender).call{value: balanceAfter}("");
        payable(DEVELOPER_ADDRESS).call{value: comission / 2}("");
        ITimeIsUp(payable(tupAddress)).receiveProfit{value: comission / 2}();
    }

    /// @notice Swaps a token for another token
    /// @dev Please refer this function is called by swap() function
    /// @param tokenFrom The address of the token to be swapped
    /// @param tokenTo The address of the token to be swapped
    /// @param amount The token amount to be swapped
    function _swapFromTokenToToken(address tokenFrom, address tokenTo, uint256 amount) private {
        IERC20 tokenFrom_ = IERC20(tokenFrom);
        IERC20 tokenTo_ = IERC20(tokenTo);
        tokenFrom_.transferFrom(msg.sender, address(this), amount);
        uint256 balanceBefore = address(this).balance;
        tokenFrom_.transfer(tokenFrom, amount);
        uint256 balanceAfter = address(this).balance - balanceBefore;
        uint256 comission = balanceAfter.mulDiv(FEE, 10_000);
        balanceAfter -= comission;
        payable(tokenTo).call{value: balanceAfter}("");
        payable(DEVELOPER_ADDRESS).call{value: comission / 2}("");
        ITimeIsUp(payable(tupAddress)).receiveProfit{value: comission / 2}();
        tokenTo_.transfer(msg.sender, tokenTo_.balanceOf(address(this)));
    }

    /// @notice Query the price of native currency in terms of an informed token
    /// @dev Please refer this function is called by queryPrice() function and it is only for viewing
    /// @param tokenTo The address of the token to be queried
    /// @param amount The native currency amount to be queried
    /// @return price The price of tokens to be obtained given some native currency amount
    function _queryPriceFromNativeToToken(address tokenTo, uint256 amount) private view returns (uint256) {
        uint256 price;
        if (tokenTo == timeAddress) 
            price = ITimeToken(payable(tokenTo)).swapPriceNative(amount);
        else
            price = ITimeIsUp(payable(tokenTo)).queryPriceNative(amount);
        return price;
    }

    /// @notice Query the price of an informed token in terms of native currency
    /// @dev Please refer this function is called by queryPrice() function and it is only for viewing
    /// @param tokenFrom The address of the token to be queried
    /// @param amount The token amount to be queried
    /// @return price The price of native currency to be obtained given some token amount
    function _queryPriceFromTokenToNative(address tokenFrom, uint256 amount) private view returns (uint256) {
        uint256 price;
        if (tokenFrom == timeAddress) 
            price = ITimeToken(payable(tokenFrom)).swapPriceTimeInverse(amount);
        else
            price = ITimeIsUp(payable(tokenFrom)).queryPriceInverse(amount);
        return price;
    }

    /// @notice Query the price of an informed token in terms of another informed token
    /// @dev Please refer this function is called by queryPrice() function and it is only for viewing
    /// @param tokenFrom The address of the token to be queried
    /// @param tokenTo The address of the token to be queried
    /// @param amount The token amount to be queried
    /// @return priceTo The price of tokens to be obtained given some another token amount
    /// @return nativeAmount The amount in native currency obtained from the query
    function _queryPriceFromTokenToToken(address tokenFrom, address tokenTo, uint256 amount) private view returns (uint256 priceTo, uint256 nativeAmount) {
        uint256 priceFrom = _queryPriceFromTokenToNative(tokenFrom, amount);
        nativeAmount = amount.mulDiv(priceFrom, FACTOR);
        if (tokenTo == timeAddress)
            priceTo = ITimeToken(payable(tokenTo)).swapPriceNative(nativeAmount);
        else 
            priceTo = ITimeIsUp(payable(tokenTo)).queryPriceNative(nativeAmount);
        return (priceTo, nativeAmount);
    }

    /// @notice Clean the contract if it has any exceeding token or native amount
    /// @dev It should pass the tokenToClean contract address
    /// @param tokenToClean The address of token contract
    function clean(address tokenToClean) public {
        if (address(this).balance > 0)
            payable(DEVELOPER_ADDRESS).call{value: address(this).balance}("");
        if (tokenToClean != address(0))
            if (IERC20(tokenToClean).balanceOf(address(this)) > 0)
                IERC20(tokenToClean).transfer(DEVELOPER_ADDRESS, IERC20(tokenToClean).balanceOf(address(this)));
    }

    /// @notice Swaps token or native currency for another token or native currency
    /// @dev It should inform address(0) as tokenFrom or tokenTo when considering native currency
    /// @param tokenFrom The address of the token to be swapped
    /// @param tokenTo The address of the token to be swapped
    /// @param amount The token or native currency amount to be swapped
    function swap(address tokenFrom, address tokenTo, uint256 amount) external payable onlyOncePerBlock {
        if (tokenFrom == address(0)) {
            require(tokenTo != address(0) && (tokenTo == timeAddress || tokenTo == tupAddress), "Time Exchange: unallowed token");
            require(msg.value > 0, "Time Exchange: please inform the amount to swap");
            _swapFromNativeToToken(tokenTo, msg.value);
            clean(tokenFrom);
            clean(tokenTo);
        } else if (tokenTo == address(0)) {
            require(amount > 0, "Time Exchange: please inform the amount to swap");
            require(tokenFrom == timeAddress || tokenFrom == tupAddress, "Time Exchange: unallowed token");
            require(IERC20(tokenFrom).allowance(msg.sender, address(this)) >= amount, "Time Exchange: please approve the amount to swap");
            _swapFromTokenToNative(tokenFrom, amount);
            clean(tokenFrom);
            clean(tokenTo);
        } else {
            require(amount > 0, "Time Exchange: please inform the amount to swap");
            require(tokenTo == timeAddress || tokenTo == tupAddress, "Time Exchange: unallowed token");
            require(tokenFrom == timeAddress || tokenFrom == tupAddress, "Time Exchange: unallowed token");
            require(IERC20(tokenFrom).allowance(msg.sender, address(this)) >= amount, "Time Exchange: please approve the amount to swap");
            _swapFromTokenToToken(tokenFrom, tokenTo, amount);
            clean(tokenFrom);
            clean(tokenTo);
        }
    }

    /// @notice Query the price of token or native currency in terms of another token or native currency
    /// @dev It should inform address(0) as tokenFrom or tokenTo when considering native currency
    /// @param tokenFrom The address of the token to be queried
    /// @param tokenTo The address of the token to be queried
    /// @param amount The token or native currency amount to be queried
    function queryPrice(address tokenFrom, address tokenTo, uint256 amount) external view returns (uint256, uint256) {
        if (tokenFrom == address(0)) {
            require(tokenTo != address(0) && (tokenTo == timeAddress || tokenTo == tupAddress), "Time Exchange: unallowed token");
            return (_queryPriceFromNativeToToken(tokenTo, amount), 0);
        } else if (tokenTo == address(0)) {
            require(tokenFrom == timeAddress || tokenFrom == tupAddress, "Time Exchange: unallowed token");
            return (_queryPriceFromTokenToNative(tokenFrom, amount), 0);
        } else {
            require(tokenTo == timeAddress || tokenTo == tupAddress, "Time Exchange: unallowed token");
            require(tokenFrom == timeAddress || tokenFrom == tupAddress, "Time Exchange: unallowed token");
            return _queryPriceFromTokenToToken(tokenFrom, tokenTo, amount);
        }        
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

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
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            uint256 twos = denominator & (0 - denominator);
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITimeToken {
    function DEVELOPER_ADDRESS() external view returns (address);
    function BASE_FEE() external view returns (uint256);
    function COMISSION_RATE() external view returns (uint256);
    function SHARE_RATE() external view returns (uint256);
    function TIME_BASE_LIQUIDITY() external view returns (uint256);
    function TIME_BASE_FEE() external view returns (uint256);
    function TOLERANCE() external view returns (uint256);
    function dividendPerToken() external view returns (uint256);
    function firstBlock() external view returns (uint256);
    function isMiningAllowed(address account) external view returns (bool);
    function liquidityFactorNative() external view returns (uint256);
    function liquidityFactorTime() external view returns (uint256);
    function numberOfHolders() external view returns (uint256);
    function numberOfMiners() external view returns (uint256);
    function sharedBalance() external view returns (uint256);
    function poolBalance() external view returns (uint256);
    function totalMinted() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    function averageMiningRate() external view returns (uint256);
    function donateEth() external payable;
    function enableMining() external payable;
    function enableMiningWithTimeToken() external;
    function fee() external view returns (uint256);
    function feeInTime() external view returns (uint256);
    function mining() external;
    function saveTime() external payable returns (bool success);
    function spendTime(uint256 timeAmount) external returns (bool success);
    function swapPriceNative(uint256 amountNative) external view returns (uint256);
    function swapPriceTimeInverse(uint256 amountTime) external view returns (uint256);
    function accountShareBalance(address account) external view returns (uint256);
    function withdrawableShareBalance(address account) external view returns (uint256);
    function withdrawShare() external;
    receive() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITimeIsUp {
    function FLASH_MINT_FEE() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function accountShareBalance(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function mint(uint256 timeAmount) external payable;
    function queryAmountExternalLP(uint256 amountNative) external view returns (uint256);
    function queryAmountInternalLP(uint256 amountNative) external view returns (uint256);
    function queryAmountOptimal(uint256 amountNative) external view returns (uint256);
    function queryNativeAmount(uint256 d2Amount) external view returns (uint256);
    function queryNativeFromTimeAmount(uint256 timeAmount) external view returns (uint256);
    function queryPriceNative(uint256 amountNative) external view returns (uint256);
    function queryPriceInverse(uint256 d2Amount) external view returns (uint256);
    function queryRate() external view returns (uint256);
    function queryPublicReward() external view returns (uint256);
    function returnNative() external payable returns (bool);
    function splitSharesWithReward() external;
    function buy() external payable returns (bool success);
    function sell(uint256 d2Amount) external returns (bool success);
    function flashMint(uint256 d2AmountToBorrow, bytes calldata data) external;
    function payFlashMintFee() external payable;
    function poolBalance() external view returns (uint256);
    function toBeShared() external view returns (uint256);
    function receiveProfit() external payable;
}