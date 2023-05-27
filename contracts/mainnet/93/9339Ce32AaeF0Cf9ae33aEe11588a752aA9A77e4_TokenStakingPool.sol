/**
 *Submitted for verification at Arbiscan on 2023-05-27
*/

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/staking.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;





contract TokenStakingPool is Ownable {
    using SafeMath for uint256;
    using Math for uint256;
    IERC20Metadata public rewardToken;
    IERC20Metadata public stakedToken;

    bool public hasMaximumStake;
    bool public isInitialized = false;
    bool public poolIsOpen = false;
    bool public withdrawTimerStatus = false;
    bool public depositEnabled = false;
    bool public withdrawEnabled = false;
    bool public compoundEnabled = false;
    bool public emergencyWithdrawEnabled = false;
    bool public hasMinimumStake = false;
    bool private isExecuting = false;
    bool private isSameToken = false;

    uint256 public totalUsersInStaking = 0;
    uint256 public poolRewardsBalance = 0;
    uint256 public minimumStake = 0;
    uint256 public rewardPerStake = 0;
    uint256 public endBlock = 0;
    uint256 public startBlock = 0;
    uint256 public lastRewardBlock = 0;
    uint256 public maximumStake = 0;
    uint256 public rewardPerBlock = 0;
    uint256 public stakeLockTime = 0;
    uint256 public compoundLockTime = 0;
    uint256 public rewardScalingFactor = 0;
    uint256 public totalValueStaked = 0;
    uint256 public totalUsersRewards = 0;
    uint256 public emergencyWithdrawFeePercentage = 0;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lockTime;
    }

    struct InfoView {
        uint256 maximumAllowedStake;
        uint256 minimumAllowedStake;
        bool poolIsActive;
        bool depositEnabled;
        bool withdrawEnabled;
        bool compoundEnabled;
        uint256 numberOfStakers;
        uint256 emergencyWithdrawFeePercentage;
        uint256 apy;
        uint8 decimals;
        bool userLockTimeReached;
        uint256 userLockTime;
        uint256 userPendingRewards;
        uint256 userTotalStakes;
        uint256 userBalance;
        uint256 totalValueStaked;
    }

    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PoolFundAdded(uint256 amount);
    event PoolFundRemoved(uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);

    constructor() {}

    function initialize(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _maximumStake
    ) external onlyOwner {
        require(!isInitialized, "this pool has already been initialized");

        uint256 _startBlock = block.number; // Get the current block number
        uint256 _endBlock = startBlock + (10 * 365 * 24 * 60 * 60) / 15; // Calculate the end block 10 years later
        uint256 _lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;

        isInitialized = true;
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        emergencyWithdrawFeePercentage = 5;
        stakeLockTime = 30 days;
        compoundLockTime = 10 days;
        startBlock = _startBlock;
        endBlock = _endBlock;
        lastRewardBlock = _lastRewardBlock;
        isSameToken = stakedToken == rewardToken;

        if (_maximumStake > 0) {
            hasMaximumStake = true;
            maximumStake = _maximumStake;
        }

        uint256 rewardTokenDecimals = uint256(rewardToken.decimals());
        rewardPerBlock = _rewardPerBlock.mul(10**rewardTokenDecimals);

        rewardScalingFactor = 1e24;
    }

    function enablePool() external onlyOwner {
        poolIsOpen = true;
        depositEnabled = true;
        withdrawEnabled = true;
        compoundEnabled = true;
        withdrawTimerStatus = true;
        emergencyWithdrawEnabled = true;
    }

    function setPoolIsOpen(bool _status) external onlyOwner {
        require(poolIsOpen != _status, "pool availability is already same status");
        poolIsOpen = _status;
    }

    function setWithdrawStatus(bool _status) external onlyOwner {
        require(withdrawEnabled != _status, "pool withdrawal is already same status");
        withdrawEnabled = _status;
    }

    function setCompoundStatus(bool _status) external onlyOwner {
        require(compoundEnabled != _status, "pool compounding is already same status");
        compoundEnabled = _status;
    }

    function setEmergencyWithdrawStatus(bool _status) external onlyOwner {
        require(emergencyWithdrawEnabled != _status, "pool emergency withdrawal is already same status");
        emergencyWithdrawEnabled = _status;
    }

    function setDepositStatus(bool _status) external onlyOwner {
        require(depositEnabled != _status, "pool deposit is already same status");
        depositEnabled = _status;
    }

    function setEmergencyWithdrawFeePercentage(uint256 _fee) external onlyOwner {
        require(emergencyWithdrawFeePercentage <= 30, "maximum emergency withdrawal fee allowed is 30%");
        emergencyWithdrawFeePercentage = _fee;
    }

    function setMinimumStake(uint256 _amount) external onlyOwner {
        require(minimumStake != _amount, "pool already has same minimum deposit amount");
        hasMinimumStake = _amount > 0;
        minimumStake = _amount;
    }

    function setwithdrawTimerStatus(bool _status) external onlyOwner {
        require(withdrawTimerStatus != _status, "pool withdrawal timer is already same status");
        withdrawTimerStatus = _status;
    }

    function setLockTime(uint256 _depositLockDays, uint256 _compoundLockDays) external onlyOwner {
        if (_depositLockDays != 1) {
            stakeLockTime = _depositLockDays * 1 days;
        }
        if (_compoundLockDays != 1) {
            compoundLockTime = _compoundLockDays * 1 days;
        }
        require(stakeLockTime <= 90 days, "max staked token lock time is 90 days");
        require(compoundLockTime <= 10 days, "max compounded token lock time is 10 days");
    }
    
    function setMaximumStake(uint256 _amount) external onlyOwner {
        hasMaximumStake = _amount > 0;
        maximumStake = _amount;
    }

    function setRewardPerBlock(uint256 _amount) external onlyOwner {
        uint256 rewardTokenDecimals = uint256(rewardToken.decimals());
        rewardPerBlock = _amount * 10**(rewardTokenDecimals);
    }

    function setStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        startBlock = _startBlock;
        endBlock = _endBlock;
        lastRewardBlock = startBlock;
    }

    function stopReward() external onlyOwner {
        endBlock = block.number;
    }

    function startReward() external onlyOwner {
        uint256 _endBlock = startBlock + (10 * 365 * 24 * 60 * 60) / 15; // Calculate the end block 10 years later
        endBlock = _endBlock;
    }

    function approveTokenTransfer(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(rewardToken.approve(address(this), _amount), "Failed to approve tokens");
    }

    function addRewards(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");

        require(
            rewardToken.allowance(address(msg.sender), address(this)) >= _amount,
            "You must approve the transfer of funds before adding them to the pool"
        );

        require(
            rewardToken.transferFrom(address(msg.sender), address(this), _amount),
            "Unable to transfer funds"
        );
        
        poolRewardsBalance += _amount;
        emit PoolFundAdded(_amount);
    }

    function removeRewards(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(rewardToken.transfer(address(msg.sender), _amount), "Unable to transfer funds");
        poolRewardsBalance -= _amount;

        emit PoolFundRemoved(_amount);
    }

    function deposit(uint256 _amount) external {
        require(!isExecuting, "function currently being executed");
        require(poolIsOpen, "pool is not yet open for deposits");
        require(depositEnabled, "deposits are currently disabled");
        require(_amount > 0, "amount must be greater than 0");

        isExecuting = true;

        UserInfo storage user = userInfo[msg.sender];

        if (hasMinimumStake) {
            require(_amount >= minimumStake, "amount is below the minimum staking limit");
        }

        if (hasMaximumStake) {
            require(user.amount + _amount <= maximumStake, "amount exceeds the maximum staking limit");
        }

        updatePool();

        if (user.amount > 0) { //If user has has old stakings
            
            uint256 pendingRewards = user.amount.mul(rewardPerStake).div(rewardScalingFactor) - user.rewardDebt;

            if (pendingRewards > 0) {
                totalUsersRewards += pendingRewards;
                poolRewardsBalance -= pendingRewards;
                rewardToken.transfer(address(msg.sender), pendingRewards);
                emit ClaimReward(msg.sender, pendingRewards);
            }
        } else {
            totalUsersInStaking += 1;
        }

        user.amount += _amount;
        totalValueStaked += _amount;
        stakedToken.transferFrom(address(msg.sender), address(this), _amount);
        
        user.rewardDebt = (user.amount.mul(rewardPerStake)).div(rewardScalingFactor);

        user.lockTime = block.timestamp + stakeLockTime;
        isExecuting = false;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(!isExecuting, "function currently being executed");
        require(poolIsOpen, "pool is not yet open for withdrawals");
        require(withdrawEnabled, "withdrawals are currently disabled");
        require(_amount > 0, "amount must be greater than 0");

        isExecuting = true;

        UserInfo storage user = userInfo[msg.sender];

        require(user.amount >= _amount, "You have insufficient amount in the pool to withdraw");

        if(withdrawTimerStatus) {
            require(block.timestamp >= user.lockTime, "locking period has not expired");
        }

        updatePool();

        uint256 pendingRewards = user.amount.mul(rewardPerStake).div(rewardScalingFactor) - user.rewardDebt;

        user.amount = user.amount - _amount;
        totalValueStaked -= _amount;
        stakedToken.transfer(address(msg.sender), _amount);
        
        if (pendingRewards > 0) {
            totalUsersRewards += pendingRewards;
            poolRewardsBalance -= pendingRewards;
            rewardToken.transfer(address(msg.sender), pendingRewards);
            emit ClaimReward(msg.sender, pendingRewards);
        }

        user.rewardDebt = (user.amount.mul(rewardPerStake)).div(rewardScalingFactor);
        
        if (user.amount == 0) {
            user.lockTime = 0;
            totalUsersInStaking -= 1;
        }

        isExecuting = false;
        emit Withdraw(msg.sender, _amount);
    }

    function compound() external returns(uint256 pendingRewards){
        require(!isExecuting, "function currently being executed");
        require(poolIsOpen, "pool is not yet open for compounding");
        require(isSameToken, "cannot compound if reward token is not the same as staked token");
        require(compoundEnabled, "compounding is currently disabled");
        
        isExecuting = true;
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount > 0, "you don't have anything to compound here ooo");

        updatePool();

        pendingRewards = user.amount.mul(rewardPerStake).div(rewardScalingFactor) - user.rewardDebt;

        if(pendingRewards > 0) {
            totalUsersRewards += pendingRewards;
            poolRewardsBalance -= pendingRewards;
            totalValueStaked += pendingRewards;
            user.amount = user.amount + pendingRewards;
            user.rewardDebt = user.amount.mul(rewardPerStake).div(rewardScalingFactor);
            if (user.lockTime < block.timestamp) {
                user.lockTime = block.timestamp.add(compoundLockTime);
            } else {
                user.lockTime += compoundLockTime;
            }
            emit Compound(msg.sender, pendingRewards);
        }

        isExecuting = false;
        return pendingRewards;
    }

    function emergencyWithdraw() external {
        require(!isExecuting, "function currently being executed");
        require(poolIsOpen, "pool is not yet open for withdrawals");
        require(emergencyWithdrawEnabled, "emergency withdrawals are currently disabled");

        isExecuting = true;

        UserInfo storage user = userInfo[msg.sender];

        uint256 fee = (user.amount * emergencyWithdrawFeePercentage) / 100;
        uint256 amountToTransfer = user.amount - fee;

        require(user.amount > 0 && amountToTransfer > 0, "you have insufficient amount in the pool to withdraw");

        totalValueStaked -= user.amount;
        totalUsersInStaking -= 1;
        if(isSameToken) {
            poolRewardsBalance += fee;
        } else {
            stakedToken.transfer(owner(), fee);
        }
        
        stakedToken.transfer(address(msg.sender), amountToTransfer);

        user.amount = 0;
        user.rewardDebt = 0;
        user.lockTime = 0;

        isExecuting = false;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    function getPendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply;

        if(isSameToken) {
            stakedTokenSupply = stakedToken.balanceOf(address(this)) - poolRewardsBalance;
        } else {
            stakedTokenSupply = stakedToken.balanceOf(address(this));
        }

        uint256 adjustedTokenPerShare = rewardPerStake;
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 numberOfBlocksPassed = _getNumberOfBlocksPassed(lastRewardBlock, block.number);
            uint256 accumulatedRewards = numberOfBlocksPassed.mul(rewardPerBlock);
            adjustedTokenPerShare = rewardPerStake.add(accumulatedRewards.mul(rewardScalingFactor).div(stakedTokenSupply));
        }

        return user.amount.mul(adjustedTokenPerShare).div(rewardScalingFactor) - user.rewardDebt;
    }

    function getTotalUserStake (address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.amount;
    }

    function updatePool() internal {
        if (block.number <= lastRewardBlock) { 
            return;
        }

        if (totalValueStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 numberOfBlocksPassed = _getNumberOfBlocksPassed(lastRewardBlock, block.number);
        uint256 accumulatedRewards = numberOfBlocksPassed.mul(rewardPerBlock);

        rewardPerStake = rewardPerStake.add(accumulatedRewards.mul(rewardScalingFactor).div(totalValueStaked));
        lastRewardBlock = block.number;
    }

    function getRewardPerStake() public view returns (uint256 , uint256, uint256) {

        uint256 numberOfBlocksPassed = _getNumberOfBlocksPassed(lastRewardBlock, block.number);
        uint256 accumulatedRewards = numberOfBlocksPassed * rewardPerBlock;

        uint256 _rewardPerStake = rewardPerStake.add(accumulatedRewards.mul(rewardScalingFactor).div(totalValueStaked));
        
        return (numberOfBlocksPassed, accumulatedRewards, _rewardPerStake);
    }

    function getBlockData() public view returns(uint blockNumber, uint blockTime) {
        blockNumber = block.number;
        blockTime = block.timestamp;
        return (blockNumber, blockTime);
    }

    function _getNumberOfBlocksPassed(uint256 _from_block, uint256 _to_block) internal view returns (uint256) {
        if (_to_block <= endBlock) {
            return _to_block.sub(_from_block);
        } else if (_from_block >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from_block);
        }
    }

    function calculateAPY() internal view returns (uint256) {
        uint256 totalStaked = totalValueStaked;
        uint256 totalRewards = poolRewardsBalance;

        if (totalStaked == 0) {
            return 0;
        }

        uint256 blocksPassed = (block.number > startBlock) ? (block.number - startBlock) : 0;
        uint256 rewardsSinceStartBlock = rewardPerBlock.mul(blocksPassed);
        uint256 totalRewardsIncludingStartBlock = totalRewards.add(rewardsSinceStartBlock);
        
        uint256 apy = (totalRewardsIncludingStartBlock.mul(100)).div(totalStaked);
        return apy;
    }

    function checkUserLockTimeReached (address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_user];
        bool lockTimeReached = block.timestamp >= user.lockTime;
        return lockTimeReached;
    }

    function getUserLockTime (address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.lockTime;
    }

    function getStakingPoolInfo(address _user) public returns (InfoView memory) {
        updatePool();

        return InfoView({
            maximumAllowedStake: maximumStake,
            minimumAllowedStake: minimumStake,
            poolIsActive: poolIsOpen,
            depositEnabled: depositEnabled,
            withdrawEnabled: withdrawEnabled,
            compoundEnabled: compoundEnabled,
            numberOfStakers: totalUsersInStaking,
            emergencyWithdrawFeePercentage: emergencyWithdrawFeePercentage,
            userLockTime: getUserLockTime(address(_user)),
            userLockTimeReached: checkUserLockTimeReached(address(_user)),
            userPendingRewards: getPendingReward(address(_user)),
            userTotalStakes: getTotalUserStake(address(_user)),
            userBalance: stakedToken.balanceOf(address(_user)),
            totalValueStaked: totalValueStaked,
            decimals: stakedToken.decimals(),
            apy: calculateAPY()
        });
    }
}