// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ChainAutomationBase} from "../bases/ChainAutomationBase.sol";
import {IRainbowRoad} from "../interfaces/IRainbowRoad.sol";
import {IChainlinkDataFeedHandler} from "../interfaces/IChainlinkDataFeedHandler.sol";

/**
 * Automation to push Chainlink Dat Feed data to other chains
 */
contract ChainlinkDataFeedPublisher is ChainAutomationBase
{
    IChainlinkDataFeedHandler chainlinkDataFeedHandler;
    mapping(uint256 => mapping(string => bool)) public isDataFeedActive;
    mapping(uint256 => string[]) public chainsDataFeeds;
    
    error ChainDataFeedDoesNotExist(uint256 chainId, string dataFeedName);
    error DuplicateChainDataFeed(uint256 chainId, string dataFeedName);
    
    constructor(address _rainbowRoad, address _chainlinkDataFeedHandler) ChainAutomationBase(_rainbowRoad)
    {
        require(_chainlinkDataFeedHandler != address(0), 'Chainlink Data Feed Handler cannot be zero address');
        chainlinkDataFeedHandler = IChainlinkDataFeedHandler(_chainlinkDataFeedHandler);
        authorized[address(this)] = true;
    }
    
    function setChainlinkDataFeedHandler(address _chainlinkDataFeedHandler) external onlyAdmins
    {
        require(_chainlinkDataFeedHandler != address(0), 'Chainlink Data Feed Handler cannot be zero address');
        chainlinkDataFeedHandler = IChainlinkDataFeedHandler(_chainlinkDataFeedHandler);
    }
    
    function addChainDataFeed(uint256 chainId, string calldata dataFeedName) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        if(this.chainDataFeedExists(chainId, dataFeedName)) {
            revert DuplicateChainDataFeed({chainId: chainId, dataFeedName: dataFeedName});
        }
        
        chainsDataFeeds[chainId].push(dataFeedName);
        isDataFeedActive[chainId][dataFeedName] = true;
    }
    
    function chainDataFeedExists(uint256 chainId, string memory dataFeedName) public view returns (bool)
    {
        string[] memory chainDataFeeds = chainsDataFeeds[chainId];
        for(uint i = 0; i < chainDataFeeds.length; i++) {
            if(Strings.equal(chainDataFeeds[i], dataFeedName)) {
                return true;
            }
        }
        
        return false;
    }
    
    function enableChainDataFeed(uint256 chainId, string calldata dataFeedName) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        if(!this.chainDataFeedExists(chainId, dataFeedName)) {
            revert ChainDataFeedDoesNotExist({chainId: chainId, dataFeedName: dataFeedName});
        }
        
        require(!isDataFeedActive[chainId][dataFeedName], 'Data Feed for chain already enabled');
        
        isDataFeedActive[chainId][dataFeedName] = true;
    }
    
    function disableChainDataFeed(uint256 chainId, string calldata dataFeedName) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        if(!this.chainDataFeedExists(chainId, dataFeedName)) {
            revert ChainDataFeedDoesNotExist({chainId: chainId, dataFeedName: dataFeedName});
        }
        
        require(isDataFeedActive[chainId][dataFeedName], 'Data Feed for chain already disabled');
        
        isDataFeedActive[chainId][dataFeedName] = false;
    }
    
    function runForChain(uint256 chainId) public override onlyAuthorized
    {
        string[] memory chainDataFeeds = chainsDataFeeds[chainId];
        for(uint256 i = 0; i < chainDataFeeds.length; i++) {
            
            if(isDataFeedActive[chainId][chainDataFeeds[i]]) {
                bytes memory payload = chainlinkDataFeedHandler.encodePayload(chainDataFeeds[i]);
                try this.run(chainId, 'chainlink_data_feed', payload) {
                    
                } catch {
                    emit ChainRunErrorProcessing(chains[i], isActive[chains[i]]);
                }
            } else {
                
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Provides set of properties, functions, and modifiers to help with 
 * security and access control of extending contracts
 */
contract ArcBase is Ownable2Step, Pausable, ReentrancyGuard
{
    function pause() public onlyOwner
    {
        _pause();
    }
    
    function unpause() public onlyOwner
    {
        _unpause();
    }

    function withdrawNative(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        require(sent, 'Unable to withdraw');
    }

    function withdrawToken(address beneficiary, address token) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {ArcBase} from "./ArcBase.sol";
import {IRainbowRoad} from "../interfaces/IRainbowRoad.sol";

/**
 * Extends the ArcBase contract to provide
 * for interactions with the Rainbow Road
 */
contract ArcBaseWithRainbowRoad is ArcBase
{
    IRainbowRoad public rainbowRoad;
    
    constructor(address _rainbowRoad)
    {
        require(_rainbowRoad != address(0), 'Rainbow Road cannot be zero address');
        rainbowRoad = IRainbowRoad(_rainbowRoad);
    }
    
    function setRainbowRoad(address _rainbowRoad) external onlyOwner
    {
        require(_rainbowRoad != address(0), 'Rainbow Road cannot be zero address');
        rainbowRoad = IRainbowRoad(_rainbowRoad);
    }
    
    /// @dev Only calls from the Rainbow Road are accepted.
    modifier onlyRainbowRoad() 
    {
        require(msg.sender == address(rainbowRoad), 'Must be called by Rainbow Road');
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ArcBaseWithRainbowRoad} from "./ArcBaseWithRainbowRoad.sol";
import {IAdminAxelarSender} from "../interfaces/IAdminAxelarSender.sol";
import {IAdminChainlinkSender} from "../interfaces/IAdminChainlinkSender.sol";
import {IAdminLayerZeroSender} from "../interfaces/IAdminLayerZeroSender.sol";
import {IRainbowRoad} from "../interfaces/IRainbowRoad.sol";

/**
 * Base automation for executing actions on other chains
 */
abstract contract ChainAutomationBase is ArcBaseWithRainbowRoad
{
    enum Providers {
        Axelar,
        Chainlink,
        LayerZero
    }
    
    address public axelarSender;
    address public chainlinkSender;
    address public layerZeroSender;
    
    uint256[] public chains;
    mapping(address => bool) public admins;
    mapping(address => bool) public authorized;
    mapping(uint256 => bool) public isActive;
    mapping(uint256 => Providers) public providers;
    
    mapping(uint256 => address) public axelarReceiver;
    mapping(uint256 => address) public chainlinkReceiver;
    mapping(uint256 => address) public layerZeroReceiver;
    
    mapping(uint256 => string) public axelarSelectorIds;
    mapping(uint256 => uint64) public chainlinkSelectorIds;
    mapping(uint256 => uint16) public layerZeroSelectorIds;
    
    error ChainIdDoesNotExist(uint256 chainId);
    error DuplicateChainId(uint256 chainId);
    error ReceiverNotSet(uint256 chainId, Providers provider);
    
    event ChainRunErrorProcessing(uint256 chainId, bool isActive);
    event ChainNotActive(uint256 chainId, bool isActive);
    event ChainRunSuccess(uint256 chainId, bool isActive, Providers provider);
    
    constructor(address _rainbowRoad) ArcBaseWithRainbowRoad(_rainbowRoad)
    {
        admins[msg.sender] = true;
        authorized[msg.sender] = true;
        
        axelarSender = address(0);
        chainlinkSender = address(0);
        layerZeroSender = address(0);
    }
    
    function chainIdExists(uint256 chainId) public view returns (bool)
    {
        for(uint i = 0; i < chains.length; i++) {
            if(chains[i] == chainId) {
                return true;
            }
        }
        
        return false;
    }
    
    function addChain(uint256 chainId, Providers provider, string calldata axelarChainSelectorId, uint64 chainlinkChainSelectorId, uint16 layerZeroChainSelectorId) external onlyAdmins
    {
        if(this.chainIdExists(chainId)) {
            revert DuplicateChainId({chainId: chainId});
        }
        
        chains.push(chainId);
        isActive[chainId] = true;
        providers[chainId] = provider;
        axelarSelectorIds[chainId] = axelarChainSelectorId;
        chainlinkSelectorIds[chainId] = chainlinkChainSelectorId;
        layerZeroSelectorIds[chainId] = layerZeroChainSelectorId;
    }
    
    function setProviders(uint256 chainId, Providers provider) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        providers[chainId] = provider;
    }
    
    function setAxelarReceiver(uint256 chainId, address receiver) external onlyAdmins
    {
        require(receiver != address(0), 'Receiver cannot be zero address');
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        axelarReceiver[chainId] = receiver;
    }
    
    function setChainlinkReceiver(uint256 chainId, address receiver) external onlyAdmins
    {
        require(receiver != address(0), 'Receiver cannot be zero address');
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        chainlinkReceiver[chainId] = receiver;
    }
    
    function setLayerZeroReceiver(uint256 chainId, address receiver) external onlyAdmins
    {
        require(receiver != address(0), 'Receiver cannot be zero address');
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        layerZeroReceiver[chainId] = receiver;
    }
    
    function setAxelarSender(address sender) external onlyAdmins
    {
        require(sender != address(0), 'Sender cannot be zero address');
        axelarSender = sender;
    }
    
    function setChainlinkSender(address sender) external onlyAdmins
    {
        require(sender != address(0), 'Sender cannot be zero address');
        chainlinkSender = sender;
    }
    
    function setLayerZeroSender(address sender) external onlyAdmins
    {
        require(sender != address(0), 'Sender cannot be zero address');
        layerZeroSender = sender;
    }
    
    function setAxelarChainSelectorId(uint256 chainId, string calldata selectorId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        axelarSelectorIds[chainId] = selectorId;
    }
    
    function setChainlinkChainSelectorId(uint256 chainId, uint64 selectorId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        chainlinkSelectorIds[chainId] = selectorId;
    }
    
    function setLayerZeroChainSelectorId(uint256 chainId, uint16 selectorId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        layerZeroSelectorIds[chainId] = selectorId;
    }
    
    function enableAdmin(address admin) external onlyOwner
    {
        require(admin != address(0), 'Admin cannot be zero address');
        require(!admins[admin], 'Admin is enabled');
        admins[admin] = true;
    }
    
    function disableAdmin(address admin) external onlyOwner
    {
        require(admin != address(0), 'Admin cannot be zero address');
        require(admins[admin], 'Admin is disabled');
        admins[admin] = false;
    }
    
    function enableAuthorized(address _authorized) external onlyOwner
    {
        require(_authorized != address(0), 'Authorized cannot be zero address');
        require(!authorized[_authorized], 'Authorized is enabled');
        authorized[_authorized] = true;
    }
    
    function disableAuthorized(address _authorized) external onlyOwner
    {
        require(_authorized != address(0), 'Authorized cannot be zero address');
        require(authorized[_authorized], 'Admin is disabled');
        authorized[_authorized] = false;
    }
    
    function enableChain(uint256 chainId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        require(!isActive[chainId], 'Chain already enabled');
        
        isActive[chainId] = true;
    }
    
    function disableChain(uint256 chainId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        require(isActive[chainId], 'Chain already disabled');
        
        isActive[chainId] = false;
    }
    
    function runForChains() external virtual onlyAuthorized
    {
        for(uint256 i = 0; i < chains.length; i++) {
            try this.runForChain(chains[i]) {
                
            } catch {
                emit ChainRunErrorProcessing(chains[i], isActive[chains[i]]);
            }
        }
    }
    
    function runForChain(uint256 chainId) public virtual;
    
    function run(uint256 chainId, string memory action, bytes memory payload) public onlyAuthorized
    {
        if(isActive[chainId]) {
            
            Providers provider = providers[chainId];
            
            IERC20(address(rainbowRoad.arc())).approve(address(rainbowRoad), rainbowRoad.sendFee());
            
            address receiver;
            if(provider == Providers.Axelar) {
                
                receiver = axelarReceiver[chainId];
                if(receiver == address(0)) {
                    revert ReceiverNotSet({chainId: chainId, provider: provider});
                }
                
                IAdminAxelarSender(axelarSender).send(
                    axelarSelectorIds[chainId], 
                    receiver,
                    action, 
                    payload
                );
            } else if(provider == Providers.Chainlink) {
                
                receiver = chainlinkReceiver[chainId];
                if(receiver == address(0)) {
                    revert ReceiverNotSet({chainId: chainId, provider: provider});
                }
                
                IAdminChainlinkSender(chainlinkSender).send(
                    chainlinkSelectorIds[chainId], 
                    receiver,
                    action, 
                    payload
                );
            } else {
                
                receiver = layerZeroReceiver[chainId];
                if(receiver == address(0)) {
                    revert ReceiverNotSet({chainId: chainId, provider: provider});
                }
                
                IAdminLayerZeroSender(layerZeroSender).send(
                    layerZeroSelectorIds[chainId], 
                    receiver,
                    action, 
                    payload
                );
            }

            emit ChainRunSuccess(chainId, isActive[chainId], provider);
        } else {
            emit ChainNotActive(chainId, isActive[chainId]);
        }
    }
    
    /// @dev Only calls from the enabled admins are accepted.
    modifier onlyAdmins() 
    {
        require(admins[msg.sender], 'Invalid admin');
        _;
    }
    
    /// @dev Only calls from the authorized are accepted.
    modifier onlyAuthorized() 
    {
        require(authorized[msg.sender], "Not authorized");
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAdminAxelarSender {
    function send(string calldata destinationChainSelector, address messageReceiver, address actionRecipient, string calldata action, bytes calldata payload) external;
    function send(string calldata destinationChainSelector, address messageReceiver, string calldata action, bytes calldata payload) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAdminChainlinkSender {
    function send(uint64 destinationChainSelector, address messageReceiver, address actionRecipient, string calldata action, bytes calldata payload) external;
    function send(uint64 destinationChainSelector, address messageReceiver, string calldata action, bytes calldata payload) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAdminLayerZeroSender {
    function send(uint16 destinationChainSelector, address messageReceiver, address actionRecipient, string calldata action, bytes calldata payload) external;
    function send(uint16 destinationChainSelector, address messageReceiver, string calldata action, bytes calldata payload) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IArc {
    function burn(uint amount) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IHandler} from "../interfaces/IHandler.sol";

interface IChainlinkDataFeedHandler is IHandler {
    function whitelistingFee() external returns (uint256);
    function chargeWhitelistingFee() external returns (bool);
    function encodePayload(string calldata dataFeedName) view external returns (bytes memory payload);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IHandler {
    function handleReceive(address target, bytes calldata payload) external;
    function handleSend(address target, bytes calldata payload) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IArc} from "./IArc.sol";

interface IRainbowRoad {
    
    function acceptTeam() external;
    function actionHandlers(string calldata action) external view returns (address);
    function arc() external view returns (IArc);
    function blockToken(address tokenAddress) external;
    function disableFeeManager(address feeManager) external;
    function disableOpenTokenWhitelisting() external;
    function disableReceiver(address receiver) external;
    function disableSender(address sender) external;
    function disableSendFeeBurn() external;
    function disableSendFeeCharge() external;
    function disableWhitelistingFeeBurn() external;
    function disableWhitelistingFeeCharge() external;
    function enableFeeManager(address feeManager) external;
    function enableOpenTokenWhitelisting() external;
    function enableReceiver(address receiver) external;
    function enableSendFeeBurn() external;
    function enableSender(address sender) external;
    function enableSendFeeCharge() external;
    function enableWhitelistingFeeBurn() external;
    function enableWhitelistingFeeCharge() external;
    function sendFee() external view returns (uint256);
    function whitelistingFee() external view returns (uint256);
    function chargeSendFee() external view returns (bool);
    function chargeWhitelistingFee() external view returns (bool);
    function burnSendFee() external view returns (bool);
    function burnWhitelistingFee() external view returns (bool);
    function openTokenWhitelisting() external view returns (bool);
    function config(string calldata configName) external view returns (bytes memory);
    function blockedTokens(address tokenAddress) external view returns (bool);
    function feeManagers(address feeManager) external view returns (bool);
    function receiveAction(string calldata action, address to, bytes calldata payload) external;
    function sendAction(string calldata action, address from, bytes calldata payload) external;
    function setActionHandler(string memory action, address handler) external;
    function setArc(address _arc) external;
    function setSendFee(uint256 _fee) external;
    function setTeam(address _team) external;
    function setTeamRate(uint256 _teamRate) external;
    function setToken(string calldata tokenSymbol, address tokenAddress) external;
    function setWhitelistingFee(uint256 _fee) external;
    function team() external view returns (address);
    function teamRate() external view returns (uint256);
    function tokens(string calldata tokenSymbol) external view returns (address);
    function MAX_TEAM_RATE() external view returns (uint256);
    function receivers(address receiver) external view returns (bool);
    function senders(address sender) external view returns (bool);
    function unblockToken(address tokenAddress) external;
    function whitelist(address tokenAddress) external;
}