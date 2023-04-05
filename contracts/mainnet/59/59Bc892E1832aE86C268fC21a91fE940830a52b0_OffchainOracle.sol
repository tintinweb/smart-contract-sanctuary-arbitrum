// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOracle {
    error ConnectorShouldBeNone();
    error PoolNotFound();
    error PoolWithConnectorNotFound();

    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector) external view returns (uint256 rate, uint256 weight);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrapper {
    error NotSupportedToken();
    error NotAddedMarket();
    error NotRemovedMarket();

    function wrap(IERC20 token) external view returns (IERC20 wrappedToken, uint256 rate);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library Sqrt {
    function sqrt(uint y) internal pure returns (uint z) {
        unchecked {
            if (y > 3) {
                z = y;
                uint x = y / 2 + 1;
                while (x < z) {
                    z = x;
                    x = (y / x + x) / 2;
                }
            } else if (y != 0) {
                z = 1;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IWrapper.sol";

contract MultiWrapper is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    error WrapperAlreadyAdded();
    error UnknownWrapper();

    event WrapperAdded(IWrapper connector);
    event WrapperRemoved(IWrapper connector);

    EnumerableSet.AddressSet private _wrappers;

    constructor(IWrapper[] memory existingWrappers) {
        unchecked {
            for (uint256 i = 0; i < existingWrappers.length; i++) {
                if(!_wrappers.add(address(existingWrappers[i]))) revert WrapperAlreadyAdded();
                emit WrapperAdded(existingWrappers[i]);
            }
        }
    }

    function wrappers() external view returns (IWrapper[] memory allWrappers) {
        allWrappers = new IWrapper[](_wrappers.length());
        unchecked {
            for (uint256 i = 0; i < allWrappers.length; i++) {
                allWrappers[i] = IWrapper(address(uint160(uint256(_wrappers._inner._values[i]))));
            }
        }
    }

    function addWrapper(IWrapper wrapper) external onlyOwner {
        if(!_wrappers.add(address(wrapper))) revert WrapperAlreadyAdded();
        emit WrapperAdded(wrapper);
    }

    function removeWrapper(IWrapper wrapper) external onlyOwner {
        if(!_wrappers.remove(address(wrapper))) revert UnknownWrapper();
        emit WrapperRemoved(wrapper);
    }

    function getWrappedTokens(IERC20 token) external view returns (IERC20[] memory wrappedTokens, uint256[] memory rates) {
        unchecked {
            IERC20[] memory memWrappedTokens = new IERC20[](20);
            uint256[] memory memRates = new uint256[](20);
            uint256 len = 0;
            for (uint256 i = 0; i < _wrappers._inner._values.length; i++) {
                try IWrapper(address(uint160(uint256(_wrappers._inner._values[i])))).wrap(token) returns (IERC20 wrappedToken, uint256 rate) {
                    memWrappedTokens[len] = wrappedToken;
                    memRates[len] = rate;
                    len += 1;
                    for (uint256 j = 0; j < _wrappers._inner._values.length; j++) {
                        if (i != j) {
                            try IWrapper(address(uint160(uint256(_wrappers._inner._values[j])))).wrap(wrappedToken) returns (IERC20 wrappedToken2, uint256 rate2) {
                                bool used = false;
                                for (uint256 k = 0; k < len; k++) {
                                    if (wrappedToken2 == memWrappedTokens[k]) {
                                        used = true;
                                        break;
                                    }
                                }
                                if (!used) {
                                    memWrappedTokens[len] = wrappedToken2;
                                    memRates[len] = rate.mul(rate2).div(1e18);
                                    len += 1;
                                }
                            } catch { continue; }
                        }
                    }
                } catch { continue; }
            }
            wrappedTokens = new IERC20[](len + 1);
            rates = new uint256[](len + 1);
            for (uint256 i = 0; i < len; i++) {
                wrappedTokens[i] = memWrappedTokens[i];
                rates[i] = memRates[i];
            }
            wrappedTokens[len] = token;
            rates[len] = 1e18;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IWrapper.sol";
import "./MultiWrapper.sol";
import "./libraries/Sqrt.sol";

contract OffchainOracle is Ownable {
    using SafeMath for uint256;
    using Sqrt for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    error ArraysLengthMismatch();
    error OracleAlreadyAdded();
    error ConnectorAlreadyAdded();
    error InvalidOracleTokenKind();
    error UnknownOracle();
    error UnknownConnector();
    error SameTokens();
    error TooBigThreshold();

    enum OracleType { WETH, ETH, WETH_ETH }

    event OracleAdded(IOracle oracle, OracleType oracleType);
    event OracleRemoved(IOracle oracle, OracleType oracleType);
    event ConnectorAdded(IERC20 connector);
    event ConnectorRemoved(IERC20 connector);
    event MultiWrapperUpdated(MultiWrapper multiWrapper);

    struct OraclePrice {
        uint256 rate;
        uint256 weight;
    }

    EnumerableSet.AddressSet private _wethOracles;
    EnumerableSet.AddressSet private _ethOracles;
    EnumerableSet.AddressSet private _connectors;
    MultiWrapper public multiWrapper;

    IERC20 private constant _BASE = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private immutable _wBase;

    constructor(MultiWrapper _multiWrapper, IOracle[] memory existingOracles, OracleType[] memory oracleTypes, IERC20[] memory existingConnectors, IERC20 wBase) {
        unchecked {
            if(existingOracles.length != oracleTypes.length) revert ArraysLengthMismatch();
            multiWrapper = _multiWrapper;
            emit MultiWrapperUpdated(_multiWrapper);
            for (uint256 i = 0; i < existingOracles.length; i++) {
                if (oracleTypes[i] == OracleType.WETH) {
                    if(!_wethOracles.add(address(existingOracles[i]))) revert OracleAlreadyAdded();
                } else if (oracleTypes[i] == OracleType.ETH) {
                    if(!_ethOracles.add(address(existingOracles[i]))) revert OracleAlreadyAdded();
                } else if (oracleTypes[i] == OracleType.WETH_ETH) {
                    if(!_wethOracles.add(address(existingOracles[i]))) revert OracleAlreadyAdded();
                    if(!_ethOracles.add(address(existingOracles[i]))) revert OracleAlreadyAdded();
                } else {
                    revert InvalidOracleTokenKind();
                }
                emit OracleAdded(existingOracles[i], oracleTypes[i]);
            }
            for (uint256 i = 0; i < existingConnectors.length; i++) {
                if(!_connectors.add(address(existingConnectors[i]))) revert ConnectorAlreadyAdded();
                emit ConnectorAdded(existingConnectors[i]);
            }
            _wBase = wBase;
        }
    }

    /**
    * @notice Returns all registered oracles along with their corresponding oracle types.
    * @return allOracles An array of all registered oracles
    * @return oracleTypes An array of the corresponding types for each oracle
    */
    function oracles() public view returns (IOracle[] memory allOracles, OracleType[] memory oracleTypes) {
        unchecked {
            IOracle[] memory oraclesBuffer = new IOracle[](_wethOracles._inner._values.length + _ethOracles._inner._values.length);
            OracleType[] memory oracleTypesBuffer = new OracleType[](oraclesBuffer.length);
            for (uint256 i = 0; i < _wethOracles._inner._values.length; i++) {
                oraclesBuffer[i] = IOracle(address(uint160(uint256(_wethOracles._inner._values[i]))));
                oracleTypesBuffer[i] = OracleType.WETH;
            }

            uint256 actualItemsCount = _wethOracles._inner._values.length;

            for (uint256 i = 0; i < _ethOracles._inner._values.length; i++) {
                OracleType kind = OracleType.ETH;
                uint256 oracleIndex = actualItemsCount;
                IOracle oracle = IOracle(address(uint160(uint256(_ethOracles._inner._values[i]))));
                for (uint j = 0; j < oraclesBuffer.length; j++) {
                    if (oraclesBuffer[j] == oracle) {
                        oracleIndex = j;
                        kind = OracleType.WETH_ETH;
                        break;
                    }
                }
                if (kind == OracleType.ETH) {
                    actualItemsCount++;
                }
                oraclesBuffer[oracleIndex] = oracle;
                oracleTypesBuffer[oracleIndex] = kind;
            }

            allOracles = new IOracle[](actualItemsCount);
            oracleTypes = new OracleType[](actualItemsCount);
            for (uint256 i = 0; i < actualItemsCount; i++) {
                allOracles[i] = oraclesBuffer[i];
                oracleTypes[i] = oracleTypesBuffer[i];
            }
        }
    }

    /**
    * @notice Returns an array of all registered connectors.
    * @return allConnectors An array of all registered connectors
    */
    function connectors() external view returns (IERC20[] memory allConnectors) {
        unchecked {
            allConnectors = new IERC20[](_connectors.length());
            for (uint256 i = 0; i < allConnectors.length; i++) {
                allConnectors[i] = IERC20(address(uint160(uint256(_connectors._inner._values[i]))));
            }
        }
    }

    /**
    * @notice Sets the MultiWrapper contract address.
    * @param _multiWrapper The address of the MultiWrapper contract
    */
    function setMultiWrapper(MultiWrapper _multiWrapper) external onlyOwner {
        multiWrapper = _multiWrapper;
        emit MultiWrapperUpdated(_multiWrapper);
    }

    /**
    * @notice Adds a new oracle to the registry with the given oracle type.
    * @param oracle The address of the new oracle to add
    * @param oracleKind The type of the new oracle
    */
    function addOracle(IOracle oracle, OracleType oracleKind) external onlyOwner {
        if (oracleKind == OracleType.WETH) {
            if(!_wethOracles.add(address(oracle))) revert OracleAlreadyAdded();
        } else if (oracleKind == OracleType.ETH) {
            if(!_ethOracles.add(address(oracle))) revert OracleAlreadyAdded();
        } else if (oracleKind == OracleType.WETH_ETH) {
            if(!_wethOracles.add(address(oracle))) revert OracleAlreadyAdded();
            if(!_ethOracles.add(address(oracle))) revert OracleAlreadyAdded();
        } else {
            revert InvalidOracleTokenKind();
        }
        emit OracleAdded(oracle, oracleKind);
    }

    /**
    * @notice Removes an oracle from the registry with the given oracle type.
    * @param oracle The address of the oracle to remove
    * @param oracleKind The type of the oracle to remove
    */
    function removeOracle(IOracle oracle, OracleType oracleKind) external onlyOwner {
        if (oracleKind == OracleType.WETH) {
            if(!_wethOracles.remove(address(oracle))) revert UnknownOracle();
        } else if (oracleKind == OracleType.ETH) {
            if(!_ethOracles.remove(address(oracle))) revert UnknownOracle();
        } else if (oracleKind == OracleType.WETH_ETH) {
            if(!_wethOracles.remove(address(oracle))) revert UnknownOracle();
            if(!_ethOracles.remove(address(oracle))) revert UnknownOracle();
        } else {
            revert InvalidOracleTokenKind();
        }
        emit OracleRemoved(oracle, oracleKind);
    }

    /**
    * @notice Adds a new connector to the registry.
    * @param connector The address of the new connector to add
    */
    function addConnector(IERC20 connector) external onlyOwner {
        if(!_connectors.add(address(connector))) revert ConnectorAlreadyAdded();
        emit ConnectorAdded(connector);
    }

    /**
    * @notice Removes a connector from the registry.
    * @param connector The address of the connector to remove
    */
    function removeConnector(IERC20 connector) external onlyOwner {
        if(!_connectors.remove(address(connector))) revert UnknownConnector();
        emit ConnectorRemoved(connector);
    }

    /**
    * WARNING!
    *    Usage of the dex oracle on chain is highly discouraged!
    *    getRate function can be easily manipulated inside transaction!
    * @notice Returns the weighted rate between two tokens using default connectors, with the option to filter out rates below a certain threshold.
    * @param srcToken The source token
    * @param dstToken The destination token
    * @param useWrappers Boolean flag to use or not use token wrappers
    * @return weightedRate weighted rate between the two tokens
    */
    function getRate(
        IERC20 srcToken,
        IERC20 dstToken,
        bool useWrappers
    ) external view returns (uint256 weightedRate) {
        return getRateWithCustomConnectors(srcToken, dstToken, useWrappers, new IERC20[](0), 0);
    }

    /**
    * WARNING!
    *    Usage of the dex oracle on chain is highly discouraged!
    *    getRate function can be easily manipulated inside transaction!
    * @notice Returns the weighted rate between two tokens using default connectors, with the option to filter out rates below a certain threshold.
    * @param srcToken The source token
    * @param dstToken The destination token
    * @param useWrappers Boolean flag to use or not use token wrappers
    * @param thresholdFilter The threshold percentage (from 0 to 100) used to filter out rates below the threshold
    * @return weightedRate weighted rate between the two tokens
    */
    function getRateWithThreshold(
        IERC20 srcToken,
        IERC20 dstToken,
        bool useWrappers,
        uint256 thresholdFilter
    ) external view returns (uint256 weightedRate) {
        return getRateWithCustomConnectors(srcToken, dstToken, useWrappers, new IERC20[](0), thresholdFilter);
    }

    /**
    * WARNING!
    *    Usage of the dex oracle on chain is highly discouraged!
    *    getRate function can be easily manipulated inside transaction!
    * @notice Returns the weighted rate between two tokens using custom connectors, with the option to filter out rates below a certain threshold.
    * @param srcToken The source token
    * @param dstToken The destination token
    * @param useWrappers Boolean flag to use or not use token wrappers
    * @param customConnectors An array of custom connectors to use
    * @param thresholdFilter The threshold percentage (from 0 to 100) used to filter out rates below the threshold
    * @return weightedRate The weighted rate between the two tokens
    */
    function getRateWithCustomConnectors(
        IERC20 srcToken,
        IERC20 dstToken,
        bool useWrappers,
        IERC20[] memory customConnectors,
        uint256 thresholdFilter
    ) public view returns (uint256 weightedRate) {
        if(srcToken == dstToken) revert SameTokens();
        if(thresholdFilter >= 100) revert TooBigThreshold();
        (IOracle[] memory allOracles, ) = oracles();
        (IERC20[] memory wrappedSrcTokens, uint256[] memory srcRates) = _getWrappedTokens(srcToken, useWrappers);
        (IERC20[] memory wrappedDstTokens, uint256[] memory dstRates) = _getWrappedTokens(dstToken, useWrappers);
        IERC20[][2] memory allConnectors = _getAllConnectors(customConnectors);

        uint256 maxArrLength = wrappedSrcTokens.length * wrappedDstTokens.length * (allConnectors[0].length + allConnectors[1].length) * allOracles.length;
        OraclePrice[] memory oraclePrices;
        // Memory allocation in assembly to avoid array zeroing
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            oraclePrices := mload(0x40)
            mstore(0x40, add(oraclePrices, add(0x20, mul(maxArrLength, 0x40))))
            mstore(oraclePrices, maxArrLength)
        }

        uint256 oracleIndex;
        uint256 maxOracleWeight;

        unchecked {
            for (uint256 k1 = 0; k1 < wrappedSrcTokens.length; k1++) {
                for (uint256 k2 = 0; k2 < wrappedDstTokens.length; k2++) {
                    if (wrappedSrcTokens[k1] == wrappedDstTokens[k2]) {
                        return srcRates[k1].mul(dstRates[k2]).div(1e18);
                    }
                    for (uint256 k3 = 0; k3 < 2; k3++) {
                        for (uint256 j = 0; j < allConnectors[k3].length; j++) {
                            IERC20 connector = allConnectors[k3][j];
                            if (connector == wrappedSrcTokens[k1] || connector == wrappedDstTokens[k2]) {
                                continue;
                            }
                            for (uint256 i = 0; i < allOracles.length; i++) {
                                (OraclePrice memory oraclePrice) = _getRateImpl(allOracles[i], wrappedSrcTokens[k1], srcRates[k1], wrappedDstTokens[k2], dstRates[k2], connector);
                                if (oraclePrice.weight > 0) {
                                    oraclePrices[oracleIndex] = oraclePrice;
                                    oracleIndex++;
                                    if (oraclePrice.weight > maxOracleWeight) {
                                        maxOracleWeight = oraclePrice.weight;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
                mstore(oraclePrices, oracleIndex)
            }

            uint256 totalWeight;

            for (uint256 i = 0; i < oraclePrices.length; i++) {
                if (oraclePrices[i].weight * 100 < maxOracleWeight * thresholdFilter) {
                    continue;
                }
                weightedRate += (oraclePrices[i].rate * oraclePrices[i].weight);
                totalWeight += oraclePrices[i].weight;
            }

            if (totalWeight > 0) {
                weightedRate = weightedRate / totalWeight;
            }
        }
    }

    /**
    * WARNING!
    *    Usage of the dex oracle on chain is highly discouraged!
    *    getRate function can be easily manipulated inside transaction!
    * @notice The same as `getRate` but checks against `ETH` and `WETH` only
    */
    function getRateToEth(IERC20 srcToken, bool useSrcWrappers) external view returns (uint256 weightedRate) {
        return getRateToEthWithCustomConnectors(srcToken, useSrcWrappers, new IERC20[](0), 0);
    }

    /**
    * WARNING!
    *    Usage of the dex oracle on chain is highly discouraged!
    *    getRate function can be easily manipulated inside transaction!
    * @notice The same as `getRate` but checks against `ETH` and `WETH` only
    */
    function getRateToEthWithThreshold(IERC20 srcToken, bool useSrcWrappers, uint256 thresholdFilter) external view returns (uint256 weightedRate) {
        return getRateToEthWithCustomConnectors(srcToken, useSrcWrappers, new IERC20[](0), thresholdFilter);
    }

    /**
    * WARNING!
    *    Usage of the dex oracle on chain is highly discouraged!
    *    getRate function can be easily manipulated inside transaction!
    * @notice The same as `getRateWithCustomConnectors` but checks against `ETH` and `WETH` only
    */
    function getRateToEthWithCustomConnectors(IERC20 srcToken, bool useSrcWrappers, IERC20[] memory customConnectors, uint256 thresholdFilter) public view returns (uint256 weightedRate) {
        if(thresholdFilter >= 100) revert TooBigThreshold();
        (IERC20[] memory wrappedSrcTokens, uint256[] memory srcRates) = _getWrappedTokens(srcToken, useSrcWrappers);
        IERC20[2] memory wrappedDstTokens = [_BASE, _wBase];
        bytes32[][2] memory wrappedOracles = [_ethOracles._inner._values, _wethOracles._inner._values];
        IERC20[][2] memory allConnectors = _getAllConnectors(customConnectors);

        uint256 maxArrLength = wrappedSrcTokens.length * wrappedDstTokens.length * (allConnectors[0].length + allConnectors[1].length) * (wrappedOracles[0].length + wrappedOracles[1].length);
        OraclePrice[] memory oraclePrices;
        // Memory allocation in assembly to avoid array zeroing
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            oraclePrices := mload(0x40)
            mstore(0x40, add(oraclePrices, mul(maxArrLength, 0x40)))
            mstore(oraclePrices, maxArrLength)
        }

        uint256 oracleIndex;
        uint256 maxOracleWeight;

        unchecked {
            for (uint256 k1 = 0; k1 < wrappedSrcTokens.length; k1++) {
                for (uint256 k2 = 0; k2 < wrappedDstTokens.length; k2++) {
                    if (wrappedSrcTokens[k1] == wrappedDstTokens[k2]) {
                        return srcRates[k1];
                    }
                    for (uint256 k3 = 0; k3 < 2; k3++) {
                        for (uint256 j = 0; j < allConnectors[k3].length; j++) {
                            IERC20 connector = allConnectors[k3][j];
                            if (connector == wrappedSrcTokens[k1] || connector == wrappedDstTokens[k2]) {
                                continue;
                            }
                            for (uint256 i = 0; i < wrappedOracles[k2].length; i++) {
                                (OraclePrice memory oraclePrice) = _getRateImpl(IOracle(address(uint160(uint256(wrappedOracles[k2][i])))), wrappedSrcTokens[k1], srcRates[k1], wrappedDstTokens[k2], 1e18, connector);
                                if (oraclePrice.weight > 0) {
                                    oraclePrices[oracleIndex] = oraclePrice;
                                    oracleIndex++;
                                    if (oraclePrice.weight > maxOracleWeight) {
                                        maxOracleWeight = oraclePrice.weight;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
                mstore(oraclePrices, oracleIndex)
            }

            uint256 totalWeight;

            for (uint256 i = 0; i < oracleIndex; i++) {
                if (oraclePrices[i].weight < maxOracleWeight * thresholdFilter / 100) {
                    continue;
                }
                weightedRate += (oraclePrices[i].rate * oraclePrices[i].weight);
                totalWeight += oraclePrices[i].weight;
            }

            if (totalWeight > 0) {
                weightedRate = weightedRate / totalWeight;
            }
        }
    }

    function _getWrappedTokens(IERC20 token, bool useWrappers) internal view returns (IERC20[] memory wrappedTokens, uint256[] memory rates) {
        if (useWrappers) {
            return multiWrapper.getWrappedTokens(token);
        }

        wrappedTokens = new IERC20[](1);
        wrappedTokens[0] = token;
        rates = new uint256[](1);
        rates[0] = uint256(1e18);
    }

    function _getAllConnectors(IERC20[] memory customConnectors) internal view returns (IERC20[][2] memory allConnectors) {
        IERC20[] memory connectorsZero;
        bytes32[] memory rawConnectors = _connectors._inner._values;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            connectorsZero := rawConnectors
        }
        allConnectors[0] = connectorsZero;
        allConnectors[1] = customConnectors;
    }

    function _getRateImpl(IOracle oracle, IERC20 srcToken, uint256 srcTokenRate, IERC20 dstToken, uint256 dstTokenRate, IERC20 connector) private view returns (OraclePrice memory oraclePrice) {
        try oracle.getRate(srcToken, dstToken, connector) returns (uint256 rate, uint256 weight) {
            oraclePrice = OraclePrice(rate * srcTokenRate * dstTokenRate / 1e36, weight);
        } catch {}  // solhint-disable-line no-empty-blocks
    }
}