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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../../libraries/Position.sol';
import '../../interfaces/ILiquidationLogic.sol';
import '../../interfaces/IAddressesProvider.sol';
import '../../interfaces/IRoleManager.sol';
import '../../interfaces/IOrderManager.sol';
import '../../interfaces/IPositionManager.sol';
import '../../interfaces/IPool.sol';
import '../../helpers/TradingHelper.sol';
import '../../interfaces/IFeeCollector.sol';

contract LiquidationLogic is ILiquidationLogic {
    using PrecisionUtils for uint256;
    using Math for uint256;
    using Int256Utils for int256;
    using Int256Utils for uint256;
    using Position for Position.Info;

    IAddressesProvider public immutable ADDRESS_PROVIDER;

    IPool public immutable pool;
    IOrderManager public immutable orderManager;
    IPositionManager public immutable positionManager;
    IFeeCollector public immutable feeCollector;
    address public executor;

    constructor(
        IAddressesProvider addressProvider,
        IPool _pool,
        IOrderManager _orderManager,
        IPositionManager _positionManager,
        IFeeCollector _feeCollector
    ) {
        ADDRESS_PROVIDER = addressProvider;
        pool = _pool;
        orderManager = _orderManager;
        positionManager = _positionManager;
        feeCollector = _feeCollector;
    }

    modifier onlyPoolAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender), "opa");
        _;
    }

    modifier onlyExecutorOrSelf() {
        require(msg.sender == executor || msg.sender == address(this), "oe");
        _;
    }

    function updateExecutor(address _executor) external override onlyPoolAdmin {
        address oldAddress = executor;
        executor = _executor;
        emit UpdateExecutorAddress(msg.sender, oldAddress, _executor);
    }

    function liquidationPosition(
        address keeper,
        bytes32 positionKey,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external override onlyExecutorOrSelf {
        Position.Info memory position = positionManager.getPositionByKey(positionKey);
        if (position.positionAmount == 0) {
            emit ZeroPosition(keeper, position.account, position.pairIndex, position.isLong, 'liquidation');
            return;
        }
        IPool.Pair memory pair = pool.getPair(position.pairIndex);
        IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(position.pairIndex);

        uint256 price = TradingHelper.getValidPrice(
            ADDRESS_PROVIDER,
            pair.indexToken,
            tradingConfig
        );

        bool needLiquidate = positionManager.needLiquidation(positionKey, price);
        if (!needLiquidate) {
            return;
        }

        uint256 orderId = orderManager.createOrder(
            TradingTypes.CreateOrderRequest({
                account: position.account,
                pairIndex: position.pairIndex,
                tradeType: TradingTypes.TradeType.MARKET,
                collateral: 0,
                openPrice: price,
                isLong: position.isLong,
                sizeAmount: -(position.positionAmount.safeConvertToInt256()),
                maxSlippage: 0,
                paymentType: TradingTypes.InnerPaymentType.NONE,
                networkFeeAmount: 0,
                data: abi.encode(position.account)
            })
        );

        _executeLiquidationOrder(keeper, orderId, tier, referralsRatio, referralUserRatio, referralOwner);

        emit ExecuteLiquidation(
            positionKey,
            position.account,
            position.pairIndex,
            position.isLong,
            position.collateral,
            position.positionAmount,
            price,
            orderId
        );
    }

    function _executeLiquidationOrder(
        address keeper,
        uint256 orderId,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) private {
        TradingTypes.OrderNetworkFee memory orderNetworkFee;
        TradingTypes.DecreasePositionOrder memory order;
        (order, orderNetworkFee) = orderManager.getDecreaseOrder(orderId, TradingTypes.TradeType.MARKET);
        if (order.account == address(0)) {
            emit InvalidOrder(keeper, orderId, 'zero account');
            return;
        }

        uint256 pairIndex = order.pairIndex;
        IPool.Pair memory pair = pool.getPair(pairIndex);

        Position.Info memory position = positionManager.getPosition(
            order.account,
            pairIndex,
            order.isLong
        );
        if (position.positionAmount == 0) {
            emit ZeroPosition(keeper, position.account, pairIndex, position.isLong, 'liquidation');
            return;
        }

        IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(pairIndex);

        uint256 executionSize = order.sizeAmount - order.executedSize;
        executionSize = Math.min(executionSize, position.positionAmount);

        uint256 executionPrice = TradingHelper.getValidPrice(
            ADDRESS_PROVIDER,
            pair.indexToken,
            tradingConfig
        );

        (bool needADL, ) = positionManager.needADL(
            pairIndex,
            order.isLong,
            executionSize,
            executionPrice
        );
        if (needADL) {
            orderManager.setOrderNeedADL(orderId, order.tradeType, needADL);

            emit ExecuteDecreaseOrder(
                order.account,
                orderId,
                pairIndex,
                order.tradeType,
                order.isLong,
                order.collateral,
                order.sizeAmount,
                order.triggerPrice,
                executionSize,
                executionPrice,
                order.executedSize,
                needADL,
                0,
                0,
                0,
                TradingTypes.InnerPaymentType.NONE,
                0
            );
            return;
        }

        (uint256 tradingFee, int256 fundingFee, int256 pnl) = positionManager.decreasePosition(
            pairIndex,
            order.orderId,
            order.account,
            keeper,
            executionSize,
            order.isLong,
            0,
            feeCollector.getTradingFeeTier(pairIndex, tier),
            referralsRatio,
            referralUserRatio,
            referralOwner,
            executionPrice,
            true
        );

        // add executed size
        order.executedSize += executionSize;

        // remove order
        orderManager.removeDecreaseMarketOrders(orderId);

        emit ExecuteDecreaseOrder(
            order.account,
            orderId,
            pairIndex,
            order.tradeType,
            order.isLong,
            0,
            order.sizeAmount,
            order.triggerPrice,
            executionSize,
            executionPrice,
            order.executedSize,
            needADL,
            pnl,
            tradingFee,
            fundingFee,
            orderNetworkFee.paymentType,
            orderNetworkFee.networkFeeAmount
        );
    }

    function cleanInvalidPositionOrders(
        bytes32[] calldata positionKeys
    ) external override onlyExecutorOrSelf {
        for (uint256 i = 0; i < positionKeys.length; i++) {
            Position.Info memory position = positionManager.getPositionByKey(positionKeys[i]);
            if (position.positionAmount == 0) {
                orderManager.cancelAllPositionOrders(position.account, position.pairIndex, position.isLong);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../libraries/PrecisionUtils.sol";
import "../interfaces/IPool.sol";

library TokenHelper {
    using PrecisionUtils for uint256;
    using SafeMath for uint256;

    function convertIndexAmountToStable(
        IPool.Pair memory pair,
        int256 indexTokenAmount
    ) internal view returns (int256 amount) {
        if (indexTokenAmount == 0) return 0;

        uint8 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();
        return convertTokenAmountTo(pair.indexToken, indexTokenAmount, stableTokenDec);
    }

    function convertIndexAmountToStableWithPrice(
        IPool.Pair memory pair,
        int256 indexTokenAmount,
        uint256 price
    ) internal view returns (int256 amount) {
        if (indexTokenAmount == 0) return 0;

        uint8 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();
        return convertTokenAmountWithPrice(pair.indexToken, indexTokenAmount, stableTokenDec, price);
    }

    function convertTokenAmountWithPrice(
        address token,
        int256 tokenAmount,
        uint8 targetDecimals,
        uint256 price
    ) internal view returns (int256 amount) {
        if (tokenAmount == 0) return 0;

        uint256 tokenDec = uint256(IERC20Metadata(token).decimals());

        uint256 tokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - tokenDec);
        uint256 targetTokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - targetDecimals);

        amount = (tokenAmount * int256(tokenWad)) * int256(price) / int256(targetTokenWad) / int256(PrecisionUtils.PRICE_PRECISION);
    }

    function convertStableAmountToIndex(
        IPool.Pair memory pair,
        int256 stableTokenAmount
    ) internal view returns (int256 amount) {
        if (stableTokenAmount == 0) return 0;

        uint8 indexTokenDec = IERC20Metadata(pair.indexToken).decimals();
        return convertTokenAmountTo(pair.stableToken, stableTokenAmount, indexTokenDec);
    }

    function convertTokenAmountTo(
        address token,
        int256 tokenAmount,
        uint8 targetDecimals
    ) internal view returns (int256 amount) {
        if (tokenAmount == 0) return 0;

        uint256 tokenDec = uint256(IERC20Metadata(token).decimals());

        uint256 tokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - tokenDec);
        uint256 targetTokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - targetDecimals);
        amount = (tokenAmount * int256(tokenWad)) / int256(targetTokenWad);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../libraries/PrecisionUtils.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IOraclePriceFeed.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IBacktracker.sol";
import "../helpers/TokenHelper.sol";
import "../libraries/Int256Utils.sol";

library TradingHelper {
    using PrecisionUtils for uint256;
    using Int256Utils for int256;

    function getValidPrice(
        IAddressesProvider addressesProvider,
        address token,
        IPool.TradingConfig memory tradingConfig
    ) internal view returns (uint256) {
        bool backtracking = IBacktracker(addressesProvider.backtracker()).backtracking();
        if (backtracking) {
            uint64 backtrackRound = IBacktracker(addressesProvider.backtracker()).backtrackRound();
            return IOraclePriceFeed(addressesProvider.priceOracle()).getHistoricalPrice(backtrackRound, token);
        }
        uint256 oraclePrice = IPriceFeed(addressesProvider.priceOracle()).getPriceSafely(token);
        uint256 indexPrice = IPriceFeed(addressesProvider.indexPriceOracle()).getPrice(token);

        uint256 diffP = oraclePrice > indexPrice
            ? oraclePrice - indexPrice
            : indexPrice - oraclePrice;
        diffP = diffP.calculatePercentage(oraclePrice);

        require(diffP <= tradingConfig.maxPriceDeviationP, "exceed max price deviation");
        return oraclePrice;
    }

    function exposureAmountChecker(
        IPool.Vault memory lpVault,
        IPool.Pair memory pair,
        int256 exposedPositions,
        bool isLong,
        uint256 orderSize,
        uint256 executionPrice
    ) internal view returns (uint256 executionSize) {
        executionSize = orderSize;

        uint256 available = maxAvailableLiquidity(lpVault, pair, exposedPositions, isLong, executionPrice);
        if (executionSize > available) {
            executionSize = available;
        }
        return executionSize;
    }

    function maxAvailableLiquidity(
        IPool.Vault memory lpVault,
        IPool.Pair memory pair,
        int256 exposedPositions,
        bool isLong,
        uint256 executionPrice
    ) internal view returns (uint256 amount) {
        if (exposedPositions >= 0) {
            if (isLong) {
                amount = lpVault.indexTotalAmount >= lpVault.indexReservedAmount ?
                    lpVault.indexTotalAmount - lpVault.indexReservedAmount : 0;
            } else {
                int256 availableStable = int256(lpVault.stableTotalAmount) - int256(lpVault.stableReservedAmount);
                int256 stableToIndexAmount = TokenHelper.convertStableAmountToIndex(
                    pair,
                    availableStable
                );
                if (stableToIndexAmount < 0) {
                    if (uint256(exposedPositions) <= stableToIndexAmount.abs().divPrice(executionPrice)) {
                        amount = 0;
                    } else {
                        amount = uint256(exposedPositions) - stableToIndexAmount.abs().divPrice(executionPrice);
                    }
                } else {
                    amount = uint256(exposedPositions) + stableToIndexAmount.abs().divPrice(executionPrice);
                }
            }
        } else {
            if (isLong) {
                int256 availableIndex = int256(lpVault.indexTotalAmount) - int256(lpVault.indexReservedAmount);
                if (availableIndex > 0) {
                    amount = uint256(-exposedPositions) + availableIndex.abs();
                } else {
                    amount = uint256(-exposedPositions) >= availableIndex.abs() ?
                        uint256(-exposedPositions) - availableIndex.abs() : 0;
                }
            } else {
                int256 availableStable = int256(lpVault.stableTotalAmount) - int256(lpVault.stableReservedAmount);
                int256 stableToIndexAmount = TokenHelper.convertStableAmountToIndex(
                    pair,
                    availableStable
                );
                if (stableToIndexAmount < 0) {
                    amount = 0;
                } else {
                    amount = stableToIndexAmount.abs().divPrice(executionPrice);
                }
            }
        }
        return amount;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IAddressesProvider {
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    function WETH() external view returns (address);

    function timelock() external view returns (address);

    function priceOracle() external view returns (address);

    function indexPriceOracle() external view returns (address);

    function fundingRate() external view returns (address);

    function executionLogic() external view returns (address);

    function liquidationLogic() external view returns (address);

    function roleManager() external view returns (address);

    function backtracker() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBacktracker {

    event Backtracking(address account, uint64 round);

    event UnBacktracking(address account);

    event UpdatedExecutorAddress(address sender, address oldAddress, address newAddress);

    function backtracking() external view returns (bool);

    function backtrackRound() external view returns (uint64);

    function enterBacktracking(uint64 _backtrackRound) external;

    function quitBacktracking() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../libraries/TradingTypes.sol';
import '../libraries/Position.sol';

interface IExecution {

    event ExecuteIncreaseOrder(
        address account,
        uint256 orderId,
        uint256 pairIndex,
        TradingTypes.TradeType tradeType,
        bool isLong,
        int256 collateral,
        uint256 orderSize,
        uint256 orderPrice,
        uint256 executionSize,
        uint256 executionPrice,
        uint256 executedSize,
        uint256 tradingFee,
        int256 fundingFee,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    );

    event ExecuteDecreaseOrder(
        address account,
        uint256 orderId,
        uint256 pairIndex,
        TradingTypes.TradeType tradeType,
        bool isLong,
        int256 collateral,
        uint256 orderSize,
        uint256 orderPrice,
        uint256 executionSize,
        uint256 executionPrice,
        uint256 executedSize,
        bool needADL,
        int256 pnl,
        uint256 tradingFee,
        int256 fundingFee,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    );

    event ExecuteAdlOrder(
        uint256[] adlOrderIds,
        bytes32[] adlPositionKeys,
        uint256[] orders
    );

    event ExecuteOrderError(uint256 orderId, string errorMessage);
    event ExecutePositionError(bytes32 positionKey, string errorMessage);

    event InvalidOrder(address sender, uint256 orderId, string message);
    event ZeroPosition(address sender, address account, uint256 pairIndex, bool isLong, string message);

    struct ExecutePosition {
        bytes32 positionKey;
        uint256 sizeAmount;
        uint8 tier;
        uint256 referralsRatio;
        uint256 referralUserRatio;
        address referralOwner;
    }

    struct LiquidatePosition {
        address token;
        bytes updateData;
        uint256 updateFee;
        uint64 backtrackRound;
        bytes32 positionKey;
        uint256 sizeAmount;
        uint8 tier;
        uint256 referralsRatio;
        uint256 referralUserRatio;
        address referralOwner;
    }

    struct PositionOrder {
        address account;
        uint256 pairIndex;
        bool isLong;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPool.sol";
import "../libraries/TradingTypes.sol";
import "./IPositionManager.sol";

interface IFeeCollector {

    event UpdatedTradingFeeTier(
        address sender,
        uint8 tier,
        uint256 oldTakerFee,
        int256 oldMakerFee,
        uint256 newTakerFee,
        int256 newMakerFee
    );

    event UpdateMaxReferralsRatio(uint256 oldRatio, uint256 newRatio);

    event UpdatedStakingPoolAddress(address sender, address oldAddress, address newAddress);
    event UpdatePoolAddress(address sender, address oldAddress, address newAddress);
    event UpdatePledgeAddress(address sender, address oldAddress, address newAddress);

    event UpdatedPositionManagerAddress(address sender, address oldAddress, address newAddress);

    event UpdateExecutionLogicAddress(address sender, address oldAddress, address newAddress);

    event DistributeTradingFeeV2(
        address account,
        uint256 pairIndex,
        uint256 orderId,
        uint256 sizeDelta,
        uint256 regularTradingFee,
        bool isMaker,
        int256 feeRate,
        int256 vipTradingFee,
        uint256 returnAmount,
        uint256 referralsAmount,
        uint256 referralUserAmount,
        address referralOwner,
        int256 lpAmount,
        int256 keeperAmount,
        int256 stakingAmount,
        int256 reservedAmount,
        int256 ecoFundAmount,
        int256 treasuryAmount
    );

    event ClaimedStakingTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedDistributorTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedReferralsTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedUserTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedKeeperTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedKeeperNetworkFee(address account, address claimToken, uint256 amount);

    struct TradingFeeTier {
        int256 makerFee;
        uint256 takerFee;
    }

    function maxReferralsRatio() external view returns (uint256 maxReferenceRatio);

    function stakingTradingFee() external view returns (uint256);
    function stakingTradingFeeDebt() external view returns (uint256);

    function treasuryFee() external view returns (uint256);

    function treasuryFeeDebt() external view returns (uint256);

    function reservedTradingFee() external view returns (int256);

    function ecoFundTradingFee() external view returns (int256);

    function userTradingFee(address _account) external view returns (uint256);

    function keeperTradingFee(address _account) external view returns (int256);

    function referralFee(address _referralOwner) external view returns (uint256);

    function getTradingFeeTier(uint256 pairIndex, uint8 tier) external view returns (TradingFeeTier memory);

    function getRegularTradingFeeTier(uint256 pairIndex) external view returns (TradingFeeTier memory);

    function getKeeperNetworkFee(
        address account,
        TradingTypes.InnerPaymentType paymentType
    ) external view returns (uint256);

    function updateMaxReferralsRatio(uint256 newRatio) external;

    function claimStakingTradingFee() external returns (uint256);

    function claimTreasuryFee() external returns (uint256);

    function claimReferralFee() external returns (uint256);

    function claimUserTradingFee() external returns (uint256);

    function claimKeeperTradingFee() external returns (uint256);

    function claimKeeperNetworkFee(
        TradingTypes.InnerPaymentType paymentType
    ) external returns (uint256);

    struct RescueKeeperNetworkFee {
        address keeper;
        address receiver;
    }

    function rescueKeeperNetworkFee(
        TradingTypes.InnerPaymentType paymentType,
        RescueKeeperNetworkFee[] calldata rescues
    ) external;

    function distributeTradingFee(
        IPool.Pair memory pair,
        address account,
        uint256 orderId,
        address keeper,
        uint256 size,
        uint256 sizeDelta,
        uint256 executionPrice,
        uint256 tradingFee,
        bool isMaker,
        TradingFeeTier memory tradingFeeTier,
        int256 exposureAmount,
        int256 afterExposureAmount,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external returns (int256 lpAmount, int256 vipTradingFee, uint256 givebackFeeAmount);

    function distributeNetworkFee(
        address keeper,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IExecution.sol";

interface ILiquidationLogic is IExecution {

    event ExecuteLiquidation(
        bytes32 positionKey,
        address account,
        uint256 pairIndex,
        bool isLong,
        uint256 collateral,
        uint256 sizeAmount,
        uint256 price,
        uint256 orderId
    );

    event UpdateExecutorAddress(address sender, address oldAddress, address newAddress);

    function updateExecutor(address _executor) external;

    function liquidationPosition(
        address keeper,
        bytes32 positionKey,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external;

    function cleanInvalidPositionOrders(
        bytes32[] calldata positionKeys
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPriceFeed} from "./IPriceFeed.sol";

interface IOraclePriceFeed is IPriceFeed {

    function updateHistoricalPrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64 backtrackRound
    ) external payable;

    function removeHistoricalPrice(
        uint64 backtrackRound,
        address[] calldata tokens
    ) external;

    function getHistoricalPrice(
        uint64 backtrackRound,
        address token
    ) external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../libraries/TradingTypes.sol';

interface IOrderManager {
    event UpdatePositionManager(address oldAddress, address newAddress);
    event CancelOrder(uint256 orderId, TradingTypes.TradeType tradeType, string reason);

    event CreateIncreaseOrder(
        address account,
        uint256 orderId,
        uint256 pairIndex,
        TradingTypes.TradeType tradeType,
        int256 collateral,
        uint256 openPrice,
        bool isLong,
        uint256 sizeAmount,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    );

    event CreateDecreaseOrder(
        address account,
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        int256 collateral,
        uint256 pairIndex,
        uint256 openPrice,
        uint256 sizeAmount,
        bool isLong,
        bool abovePrice,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    );

    event UpdateRouterAddress(address sender, address oldAddress, address newAddress);

    event CancelIncreaseOrder(address account, uint256 orderId, TradingTypes.TradeType tradeType);
    event CancelDecreaseOrder(address account, uint256 orderId, TradingTypes.TradeType tradeType);

    event UpdatedNetworkFee(
        address sender,
        TradingTypes.NetworkFeePaymentType paymentType,
        uint256 pairIndex,
        uint256 basicNetworkFee,
        uint256 discountThreshold,
        uint256 discountedNetworkFee
    );

    struct PositionOrder {
        address account;
        uint256 pairIndex;
        bool isLong;
        bool isIncrease;
        TradingTypes.TradeType tradeType;
        uint256 orderId;
        uint256 sizeAmount;
    }

    struct NetworkFee {
        uint256 basicNetworkFee;
        uint256 discountThreshold;
        uint256 discountedNetworkFee;
    }

    function ordersIndex() external view returns (uint256);

    function getPositionOrders(bytes32 key) external view returns (PositionOrder[] memory);

    function getNetworkFee(TradingTypes.NetworkFeePaymentType paymentType, uint256 pairIndex) external view returns (NetworkFee memory);

    function createOrder(TradingTypes.CreateOrderRequest memory request) external payable returns (uint256 orderId);

    function cancelOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        bool isIncrease,
        string memory reason
    ) external;

    function cancelAllPositionOrders(address account, uint256 pairIndex, bool isLong) external;

    function getIncreaseOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType
    ) external view returns (
        TradingTypes.IncreasePositionOrder memory order,
        TradingTypes.OrderNetworkFee memory orderNetworkFee
    );

    function getDecreaseOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType
    ) external view returns (
        TradingTypes.DecreasePositionOrder memory order,
        TradingTypes.OrderNetworkFee memory orderNetworkFee
    );

    function increaseOrderExecutedSize(
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        bool isIncrease,
        uint256 increaseSize
    ) external;

    function removeOrderFromPosition(PositionOrder memory order) external;

    function removeIncreaseMarketOrders(uint256 orderId) external;

    function removeIncreaseLimitOrders(uint256 orderId) external;

    function removeDecreaseMarketOrders(uint256 orderId) external;

    function removeDecreaseLimitOrders(uint256 orderId) external;

    function setOrderNeedADL(uint256 orderId, TradingTypes.TradeType tradeType, bool needADL) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPool {
    // Events
    event PairAdded(
        address indexed indexToken,
        address indexed stableToken,
        address lpToken,
        uint256 index
    );

    event UpdateTotalAmount(
        uint256 indexed pairIndex,
        int256 indexAmount,
        int256 stableAmount,
        uint256 indexTotalAmount,
        uint256 stableTotalAmount
    );

    event UpdateReserveAmount(
        uint256 indexed pairIndex,
        int256 indexAmount,
        int256 stableAmount,
        uint256 indexReservedAmount,
        uint256 stableReservedAmount
    );

    event UpdateLPProfit(
        uint256 indexed pairIndex,
        address token,
        int256 profit,
        uint256 totalAmount
    );

    event GivebackTradingFee(
        uint256 indexed pairIndex,
        address token,
        uint256 amount
    );

    event UpdateAveragePrice(uint256 indexed pairIndex, uint256 averagePrice);

    event UpdateSpotSwap(address sender, address oldAddress, address newAddress);

    event UpdatePoolView(address sender, address oldAddress, address newAddress);

    event UpdateRouter(address sender, address oldAddress, address newAddress);

    event UpdateRiskReserve(address sender, address oldAddress, address newAddress);

    event UpdateFeeCollector(address sender, address oldAddress, address newAddress);

    event UpdatePositionManager(address sender, address oldAddress, address newAddress);

    event UpdateOrderManager(address sender, address oldAddress, address newAddress);

    event AddStableToken(address sender, address token);

    event RemoveStableToken(address sender, address token);

    event AddLiquidity(
        address indexed recipient,
        uint256 indexed pairIndex,
        uint256 indexAmount,
        uint256 stableAmount,
        uint256 lpAmount,
        uint256 indexFeeAmount,
        uint256 stableFeeAmount,
        address slipToken,
        uint256 slipFeeAmount,
        uint256 lpPrice
    );

    event RemoveLiquidity(
        address indexed recipient,
        uint256 indexed pairIndex,
        uint256 indexAmount,
        uint256 stableAmount,
        uint256 lpAmount,
        uint256 feeAmount,
        uint256 lpPrice
    );

    event ClaimedFee(address sender, address token, uint256 amount);

    struct Vault {
        uint256 indexTotalAmount; // total amount of tokens
        uint256 indexReservedAmount; // amount of tokens reserved for open positions
        uint256 stableTotalAmount;
        uint256 stableReservedAmount;
        uint256 averagePrice;
    }

    struct Pair {
        uint256 pairIndex;
        address indexToken;
        address stableToken;
        address pairToken;
        bool enable;
        uint256 kOfSwap; //Initial k value of liquidity
        uint256 expectIndexTokenP; //   for 100%
        uint256 maxUnbalancedP;
        uint256 unbalancedDiscountRate;
        uint256 addLpFeeP; // Add liquidity fee
        uint256 removeLpFeeP; // remove liquidity fee
    }

    struct TradingConfig {
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 minTradeAmount;
        uint256 maxTradeAmount;
        uint256 maxPositionAmount;
        uint256 maintainMarginRate; // Maintain the margin rate of  for 100%
        uint256 priceSlipP; // Price slip point
        uint256 maxPriceDeviationP; // Maximum offset of index price
    }

    struct TradingFeeConfig {
        uint256 lpFeeDistributeP;
        uint256 stakingFeeDistributeP;
        uint256 keeperFeeDistributeP;
        uint256 treasuryFeeDistributeP;
        uint256 reservedFeeDistributeP;
        uint256 ecoFundFeeDistributeP;
    }

    function pairsIndex() external view returns (uint256);

    function getPairIndex(address indexToken, address stableToken) external view returns (uint256);

    function getPair(uint256) external view returns (Pair memory);

    function getTradingConfig(uint256 _pairIndex) external view returns (TradingConfig memory);

    function getTradingFeeConfig(uint256) external view returns (TradingFeeConfig memory);

    function getVault(uint256 _pairIndex) external view returns (Vault memory vault);

    function transferTokenTo(address token, address to, uint256 amount) external;

    function transferEthTo(address to, uint256 amount) external;

    function transferTokenOrSwap(
        uint256 pairIndex,
        address token,
        address to,
        uint256 amount
    ) external;

    function getLpPnl(
        uint256 _pairIndex,
        bool lpIsLong,
        uint amount,
        uint256 _price
    ) external view returns (int256);

    function lpProfit(
        uint pairIndex,
        address token,
        uint256 price
    ) external view returns (int256);

    function increaseReserveAmount(
        uint256 _pairToken,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external;

    function decreaseReserveAmount(
        uint256 _pairToken,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external;

    function updateAveragePrice(uint256 _pairIndex, uint256 _averagePrice) external;

    function setLPStableProfit(uint256 _pairIndex, int256 _profit) external;

    function givebackTradingFee(
        uint256 pairIndex,
        uint256 amount
    ) external;

    function getAvailableLiquidity(uint256 pairIndex, uint256 price) external view returns(int256 v, int256 u, int256 e);

    function addLiquidity(
        address recipient,
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        bytes calldata data
    ) external returns (uint256 mintAmount, address slipToken, uint256 slipAmount);

    function removeLiquidity(
        address payable _receiver,
        uint256 _pairIndex,
        uint256 _amount,
        bool useETH,
        bytes calldata data
    )
        external
        returns (uint256 receivedIndexAmount, uint256 receivedStableAmount, uint256 feeAmount);

    function claimFee(address token, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import '../libraries/Position.sol';
import "./IFeeCollector.sol";

enum PositionStatus {
    Balance,
    NetLong,
    NetShort
}

interface IPositionManager {
    event UpdateFundingInterval(uint256 oldInterval, uint256 newInterval);

    event UpdatePosition(
        address account,
        bytes32 positionKey,
        uint256 pairIndex,
        uint256 orderId,
        bool isLong,
        uint256 beforCollateral,
        uint256 afterCollateral,
        uint256 price,
        uint256 beforPositionAmount,
        uint256 afterPositionAmount,
        uint256 averagePrice,
        int256 fundFeeTracker,
        int256 pnl
    );

    event UpdatedExecutionLogic(address sender, address oldAddress, address newAddress);

    event UpdatedLiquidationLogic(address sender, address oldAddress, address newAddress);

    event UpdateRouterAddress(address sender, address oldAddress, address newAddress);

    event UpdateFundingRate(uint256 pairIndex, uint price, int256 fundingRate, uint256 lastFundingTime);

    event TakeFundingFeeAddTraderFeeV2(
        address account,
        uint256 pairIndex,
        uint256 orderId,
        uint256 sizeDelta,
        int256 fundingFee,
        uint256 regularTradingFee,
        int256 vipTradingFee,
        uint256 returnAmount,
        int256 lpTradingFee
    );

    event AdjustCollateral(
        address account,
        uint256 pairIndex,
        bool isLong,
        bytes32 positionKey,
        uint256 collateralBefore,
        uint256 collateralAfter
    );

    function getExposedPositions(uint256 pairIndex) external view returns (int256);

    function longTracker(uint256 pairIndex) external view returns (uint256);

    function shortTracker(uint256 pairIndex) external view returns (uint256);

    function getTradingFee(
        uint256 _pairIndex,
        bool _isLong,
        bool _isIncrease,
        uint256 _sizeAmount,
        uint256 price
    ) external view returns (uint256 tradingFee);

    function getFundingFee(
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) external view returns (int256 fundingFee);

    function getCurrentFundingRate(uint256 _pairIndex) external view returns (int256);

    function getNextFundingRate(uint256 _pairIndex, uint256 price) external view returns (int256);

    function getNextFundingRateUpdateTime(uint256 _pairIndex) external view returns (uint256);

    function needADL(
        uint256 pairIndex,
        bool isLong,
        uint256 executionSize,
        uint256 executionPrice
    ) external view returns (bool needADL, uint256 needADLAmount);

    function needLiquidation(
        bytes32 positionKey,
        uint256 price
    ) external view returns (bool);

    function getPosition(
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) external view returns (Position.Info memory);

    function getPositionByKey(bytes32 key) external view returns (Position.Info memory);

    function getPositionKey(address _account, uint256 _pairIndex, bool _isLong) external pure returns (bytes32);

    function increasePosition(
        uint256 _pairIndex,
        uint256 orderId,
        address _account,
        address _keeper,
        uint256 _sizeAmount,
        bool _isLong,
        int256 _collateral,
        IFeeCollector.TradingFeeTier memory tradingFeeTier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        uint256 _price
    ) external returns (uint256 tradingFee, int256 fundingFee);

    function decreasePosition(
        uint256 _pairIndex,
        uint256 orderId,
        address _account,
        address _keeper,
        uint256 _sizeAmount,
        bool _isLong,
        int256 _collateral,
        IFeeCollector.TradingFeeTier memory tradingFeeTier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        uint256 _price,
        bool useRiskReserve
    ) external returns (uint256 tradingFee, int256 fundingFee, int256 pnl);

    function adjustCollateral(uint256 pairIndex, address account, bool isLong, int256 collateral) external;

    function updateFundingRate(uint256 _pairIndex) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceFeed {

    event PriceAgeUpdated(uint256 oldAge, uint256 newAge);

    function getPrice(address token) external view returns (uint256);

    function getPriceSafely(address token) external view returns (uint256);

    function decimals() external pure returns (uint256);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IRoleManager {
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function isAdmin(address) external view returns (bool);

    function isPoolAdmin(address poolAdmin) external view returns (bool);

    function isOperator(address operator) external view returns (bool);

    function isTreasurer(address treasurer) external view returns (bool);

    function isKeeper(address) external view returns (bool);

    function isBlackList(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library Int256Utils {
    using Strings for uint256;

    function abs(int256 a) internal pure returns (uint256) {
        return a >= 0 ? uint256(a) : uint256(-a);
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function safeConvertToInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "Value too large to fit in int256.");
        return int256(value);
    }

    function toString(int256 amount) internal pure returns (string memory) {
        return string.concat(amount >= 0 ? '' : '-', abs(amount).toString());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import '../libraries/PrecisionUtils.sol';
import '../libraries/Int256Utils.sol';
import '../libraries/TradingTypes.sol';
import '../libraries/PositionKey.sol';
import "../interfaces/IPool.sol";
import "../helpers/TokenHelper.sol";

library Position {
    using Int256Utils for int256;
    using Math for uint256;
    using PrecisionUtils for uint256;

    struct Info {
        address account;
        uint256 pairIndex;
        bool isLong;
        uint256 collateral;
        uint256 positionAmount;
        uint256 averagePrice;
        int256 fundingFeeTracker;
    }

    function get(
        mapping(bytes32 => Info) storage self,
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) internal view returns (Position.Info storage position) {
        position = self[PositionKey.getPositionKey(_account, _pairIndex, _isLong)];
    }

    function getPositionByKey(
        mapping(bytes32 => Info) storage self,
        bytes32 key
    ) internal view returns (Position.Info storage position) {
        position = self[key];
    }

    function init(Info storage self, uint256 pairIndex, address account, bool isLong, uint256 oraclePrice) internal {
        self.pairIndex = pairIndex;
        self.account = account;
        self.isLong = isLong;
        self.averagePrice = oraclePrice;
    }

    function getUnrealizedPnl(
        Info memory self,
        IPool.Pair memory pair,
        uint256 _sizeAmount,
        uint256 price
    ) internal view returns (int256 pnl) {
        if (price == self.averagePrice || self.averagePrice == 0 || _sizeAmount == 0) {
            return 0;
        }

        if (self.isLong) {
            if (price > self.averagePrice) {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    int256(_sizeAmount),
                    price - self.averagePrice
                );
            } else {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    -int256(_sizeAmount),
                    self.averagePrice - price
                );
            }
        } else {
            if (self.averagePrice > price) {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    int256(_sizeAmount),
                    self.averagePrice - price
                );
            } else {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    -int256(_sizeAmount),
                    price - self.averagePrice
                );
            }
        }

        return pnl;
    }

    function validLeverage(
        Info memory self,
        IPool.Pair memory pair,
        uint256 price,
        int256 _collateral,
        uint256 _sizeAmount,
        bool _increase,
        uint256 maxLeverage,
        uint256 maxPositionAmount,
        bool simpleVerify,
        int256 fundingFee
    ) internal view returns (uint256, uint256) {
        // only increase collateral
        if (_sizeAmount == 0 && _collateral >= 0) {
            return (self.positionAmount, self.collateral);
        }

        uint256 afterPosition;
        if (_increase) {
            afterPosition = self.positionAmount + _sizeAmount;
        } else {
            afterPosition = self.positionAmount >= _sizeAmount ? self.positionAmount - _sizeAmount : 0;
        }

        if (_increase && afterPosition > maxPositionAmount) {
            revert("exceeds max position");
        }

        int256 availableCollateral = int256(self.collateral) + fundingFee;

        // pnl
        if (!simpleVerify) {
            int256 pnl = getUnrealizedPnl(self, pair, self.positionAmount, price);
            if (!_increase && _sizeAmount > 0 && _sizeAmount < self.positionAmount) {
                if (pnl >= 0) {
                    availableCollateral += getUnrealizedPnl(self, pair, self.positionAmount - _sizeAmount, price);
                } else {
//                    availableCollateral += getUnrealizedPnl(self, pair, _sizeAmount, price);
                    availableCollateral += pnl;
                }
            } else {
                availableCollateral += pnl;
            }
        }

        // adjust collateral
        if (_collateral != 0) {
            availableCollateral += _collateral;
        }
        require(simpleVerify || availableCollateral >= 0, 'collateral not enough');

        if (!simpleVerify && ((_increase && _sizeAmount > 0) || _collateral < 0)) {
            uint256 collateralDec = uint256(IERC20Metadata(pair.stableToken).decimals());
            uint256 tokenDec = uint256(IERC20Metadata(pair.indexToken).decimals());

            uint256 tokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - tokenDec);
            uint256 collateralWad = 10 ** (PrecisionUtils.maxTokenDecimals() - collateralDec);

            uint256 afterPositionD = afterPosition * tokenWad;
            uint256 availableD = (availableCollateral.abs() * maxLeverage * collateralWad).divPrice(price);
            require(afterPositionD <= availableD, 'exceeds max leverage');
        }

        return (afterPosition, availableCollateral.abs());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PositionKey {
    function getPositionKey(address account, uint256 pairIndex, bool isLong) internal pure returns (bytes32) {
        require(pairIndex < 2 ** (96 - 32), "ptl");
        return bytes32(
            uint256(uint160(account)) << 96 | pairIndex << 32 | (isLong ? 1 : 0)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';

library PrecisionUtils {
    uint256 public constant PERCENTAGE = 1e8;
    uint256 public constant PRICE_PRECISION = 1e30;
    uint256 public constant MAX_TOKEN_DECIMALS = 18;

    function mulPrice(uint256 amount, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(amount, price, PRICE_PRECISION);
    }

    function divPrice(uint256 delta, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(delta, PRICE_PRECISION, price);
    }

    function calculatePrice(uint256 delta, uint256 amount) internal pure returns (uint256) {
        return Math.mulDiv(delta, PRICE_PRECISION, amount);
    }

    function mulPercentage(uint256 amount, uint256 _percentage) internal pure returns (uint256) {
        return Math.mulDiv(amount, _percentage, PERCENTAGE);
    }

    function divPercentage(uint256 amount, uint256 _percentage) internal pure returns (uint256) {
        return Math.mulDiv(amount, PERCENTAGE, _percentage);
    }

    function calculatePercentage(uint256 amount0, uint256 amount1) internal pure returns (uint256) {
        return Math.mulDiv(amount0, PERCENTAGE, amount1);
    }

    function percentage() internal pure returns (uint256) {
        return PERCENTAGE;
    }

    function fundingRatePrecision() internal pure returns (uint256) {
        return PERCENTAGE;
    }

    function pricePrecision() internal pure returns (uint256) {
        return PRICE_PRECISION;
    }

    function maxTokenDecimals() internal pure returns (uint256) {
        return MAX_TOKEN_DECIMALS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TradingTypes {
    enum TradeType {
        MARKET,
        LIMIT,
        TP,
        SL
    }

    enum NetworkFeePaymentType {
        ETH,
        COLLATERAL
    }

    struct CreateOrderRequest {
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT 2: TP 3: SL
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 openPrice; // 1e30, price
        bool isLong; // long or short
        int256 sizeAmount; // size
        uint256 maxSlippage;
        InnerPaymentType paymentType;
        uint256 networkFeeAmount;
        bytes data;
    }

    struct OrderWithTpSl {
        uint256 tpPrice; // 1e30, tp price
        uint128 tp; // tp size
        uint256 slPrice; // 1e30, sl price
        uint128 sl; // sl size
    }

    struct IncreasePositionRequest {
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT 2: TP 3: SL
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 openPrice; // 1e30, price
        bool isLong; // long or short
        uint256 sizeAmount; // size
        uint256 maxSlippage;
        NetworkFeePaymentType paymentType;
        uint256 networkFeeAmount;
    }

    struct IncreasePositionWithTpSlRequest {
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT 2: TP 3: SL
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 openPrice; // 1e30, price
        bool isLong; // long or short
        uint128 sizeAmount; // size
        uint256 tpPrice; // 1e30, tp price
        uint128 tp; // tp size
        uint256 slPrice; // 1e30, sl price
        uint128 sl; // sl size
        uint256 maxSlippage;
        NetworkFeePaymentType paymentType; // 1: eth 2: collateral
        uint256 networkFeeAmount;
        uint256 tpNetworkFeeAmount;
        uint256 slNetworkFeeAmount;
    }

    struct DecreasePositionRequest {
        address account;
        uint256 pairIndex;
        TradeType tradeType;
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 triggerPrice; // 1e30, price
        uint256 sizeAmount; // size
        bool isLong;
        uint256 maxSlippage;
        NetworkFeePaymentType paymentType;
        uint256 networkFeeAmount;
    }

    struct CreateTpSlRequest {
        address account;
        uint256 pairIndex; // pair index
        bool isLong;
        uint256 tpPrice; // Stop profit price 1e30
        uint128 tp; // The number of profit stops
        uint256 slPrice; // Stop price 1e30
        uint128 sl; // Stop loss quantity
        NetworkFeePaymentType paymentType;
        uint256 tpNetworkFeeAmount;
        uint256 slNetworkFeeAmount;
    }

    struct IncreasePositionOrder {
        uint256 orderId;
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT
        int256 collateral; // 1e18 Margin amount
        uint256 openPrice; // 1e30 Market acceptable price/Limit opening price
        bool isLong; // Long/short
        uint256 sizeAmount; // Number of positions
        uint256 executedSize;
        uint256 maxSlippage;
        uint256 blockTime;
    }

    struct DecreasePositionOrder {
        uint256 orderId;
        address account;
        uint256 pairIndex;
        TradeType tradeType;
        int256 collateral; // 1e18 Margin amount
        uint256 triggerPrice; // Limit trigger price
        uint256 sizeAmount; // Number of customs documents
        uint256 executedSize;
        uint256 maxSlippage;
        bool isLong;
        bool abovePrice; // Above or below the trigger price
        // market：long: true,  short: false
        //  limit：long: false, short: true
        //     tp：long: false, short: true
        //     sl：long: true,  short: false
        uint256 blockTime;
        bool needADL;
    }

    struct OrderNetworkFee {
        InnerPaymentType paymentType;
        uint256 networkFeeAmount;
    }

    enum InnerPaymentType {
        NONE,
        ETH,
        COLLATERAL
    }

    function convertPaymentType(
        NetworkFeePaymentType paymentType
    ) internal pure returns (InnerPaymentType) {
        if (paymentType == NetworkFeePaymentType.ETH) {
            return InnerPaymentType.ETH;
        } else if (paymentType == NetworkFeePaymentType.COLLATERAL) {
            return InnerPaymentType.COLLATERAL;
        } else {
            revert("Invalid payment type");
        }
    }
}