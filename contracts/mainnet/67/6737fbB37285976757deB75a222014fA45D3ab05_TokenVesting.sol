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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

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
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
pragma solidity ^0.8.0;

interface IChef {
  function IS_CONSENSUS_CHEF() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokenVesting.sol";

interface ICSS is IERC20 {
  function cap() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function MINTER_ROLE() external view returns (bytes32);
  function safeMint(address, uint256) external returns (uint256);
  function hasRole(bytes32 role, address account) external view returns (bool);
  function tokenVesting() external view returns (ITokenVesting);
  function rescueTokens(IERC20[] calldata tokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenVesting {
  function IS_CONSENSUS_VESTING() external view returns (bool);
  function teamWallet() external view returns (address);
  function marketingWallet() external view returns (address);
  function emitToken() external;
}

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#G5J?7!~~~::::::::::::::::~^^^:::::^:[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@#GY7~:.                                    [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@#P?^.                                          [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@#Y!.                    [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@&P!.                       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@&Y:                          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@&Y:                      .::^~^7YYYYYYYYYYYYYYYYYYYYYYYYY#@@@@@@@@@@@@@
@@@@@@@@P:                  .^7YPB#&@@@&.                         [email protected]@@@@@@@@@@@@
@@@@@@&7                 :?P#@@@@@@@@@@&.                         [email protected]@@@@@@@@@@@@
@@@@@B:               .7G&@@@@@@@@@&#BBP.                         [email protected]@@@@@@@@@@@@
@@@@G.              .J#@@@@@@@&GJ!^:.                             [email protected]@@@@@@@@@@@@
@@@G.              7#@@@@@@#5~.                                   [email protected]@@@@@@@@@@@@
@@#.             :[email protected]@@@@@#?.                                      [email protected]@@@@@@@@@@@@
@@~             :#@@@@@@J.       .~JPGBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@@@@@@@@@
@5             .#@@@@@&~       !P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@~             [email protected]@@@@&^      ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
B             [email protected]@@@@@7      ^&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
5             [email protected]@@@@#      .#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Y   ..     .. P#####5      [email protected]@@@@@@@@@@@@@@@@@@@@@@@&##########################&
@############B:    .       [email protected]@@@@@@@@@@@@@@@@@@@@@@@5            ..            7
@@@@@@@@@@@@@@:            .#@@@@@@@@@@@@@@@@@@@@@@@~                          7
@@@@@@@@@@@@@@J             ~&@@@@@@@@@@@@@@@@@@@@@?       ......              5
@@@@@@@@@@@@@@#.             ^[email protected]@@@@@@@@@@@@@@@@@#!      .G#####G.            .#
@@@@@@@@@@@@@@@P               !P&@@@@@@@@@@@@@G7.      :[email protected]@@@@@~             [email protected]
@@@@@@@@@@@@@@@@5                :!JPG####BPY7:        7#@@@@@&!             :#@
@@@@@@@@@@@@@@@@@P:                   ....           [email protected]@@@@@#~              [email protected]@
@@@@@@@@@@@@@@@@@@#!                             .^J#@@@@@@@Y.              [email protected]@@
@@@@@@@@@@@@@@@@@@@@G~                      .^!JP#@@@@@@@&5^               [email protected]@@@
@@@@@@@@@@@@@@@@@@@@@@G7.               ?BB#&@@@@@@@@@@#J:                [email protected]@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&P7:            [email protected]@@@@@@@@@&GJ~.                ^[email protected]@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B5?~:.      [email protected]@@@&#G5?~.                  [email protected]@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BGP5YJ~~~^^..                      ?#@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.                         [email protected]@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.                       ^Y&@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.                    ^[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.                :!5#@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.         ..^!JP#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&~::^~!7?5PB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ICSS.sol";
import "./interfaces/IChef.sol";

/**
 * @title TokenVesting
 * @author Consensus party
 * @notice This contract serves as a locker for Consensus Token (CSS) {ICSS}.
 *
 * Constant settings:
 * - TEAM_PERCENT: 7% of the unlocked supply allocated for team members and advisors.
 * - MARKETING_PERCENT: 2% of the unlocked supply allocated for marketing and promotion.
 * - COMMUNITY_PERCENT: 91% of the unlocked supply allocated for liquidity and community.
 *
 * This contract has ability to mint the unlocked token supply, with specific percentages reserved for
 * various purposes. The tokens will be locked and gradually released over time to their respective
 * beneficiaries according to the terms specified in the vesting schedule.
 */
contract TokenVesting is Ownable2Step, ReentrancyGuard {
  struct Emission {
    uint256 startTime;
    uint256 estimatedEndTime;
    uint256 unlockTokensPerSec;
    uint256 lastUnlockedTime;
    uint256 lockingAmount;
  }

  event EmitToken(uint256 duration, uint256 liqAmount, uint256 locking);
  event SetEmission(uint256 startTime, uint256 endTime, uint256 unlockTokensPerSec, uint256 locking);
  event SetTeamAddress(address teamAddress);
  event SetMarketingAddress(address marketingAddress);

  bool public constant IS_CONSENSUS_VESTING = true;

  uint256 public constant MAX_PERCENT = 100_00;
  uint256 public constant TEAM_PERCENT = 7_00;
  uint256 public constant MARKETING_PERCENT = 2_00;
  uint256 public constant COMMUNITY_PERCENT = 91_00;

  ICSS public immutable cssToken;
  address public teamWallet;
  address public marketingWallet;

  Emission private _emission;

  /**
   * @param token Address of the CSS token
   * @param teamAddr Address of team
   * @param marketingAddr Marketing address
   */
  constructor(address admin, ICSS token, address teamAddr, address marketingAddr) {
    _transferOwnership(admin);
    cssToken = token;
    teamWallet = teamAddr;
    marketingWallet = marketingAddr;
    assert(MAX_PERCENT == TEAM_PERCENT + MARKETING_PERCENT + COMMUNITY_PERCENT);
    emit SetTeamAddress(teamAddr);
    emit SetMarketingAddress(marketingAddr);
  }

  fallback() external payable {}
  receive() external payable {}

  /**
   * @dev Rescues funds in case some tokens are unexpectedly transferred to CSS.
   *
   * @param tokens the token addresses.
   */
  function rescueTokens(IERC20[] calldata tokens, address payable to) external onlyOwner {
    cssToken.rescueTokens(tokens);
    uint256 ethBalance = address(this).balance;
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 balance = tokens[i].balanceOf(address(this));
      require(tokens[i].transfer(to, balance), "CSSToken: transfer failed");
    }

    if (ethBalance > 0) {
      (bool success,) = to.call{value: ethBalance}(new bytes(0));
      require(success, "TokenVesting: cannot withdraw");
    }
  }

  /**
   * @param chefs Address list of the chefs.
   */
  function addChefs(IChef[] calldata chefs) external onlyOwner {
    for (uint256 i = 0; i < chefs.length; i++) {
      require(chefs[i].IS_CONSENSUS_CHEF(), "TokenVesting: incorrect chef");
      cssToken.approve(address(chefs[i]), type(uint256).max);
    }
  }

  /**
   * @param chefs Address list of the chefs.
   */
  function removeChefs(IChef[] calldata chefs) external onlyOwner {
    for (uint256 i = 0; i < chefs.length; i++) {
      cssToken.approve(address(chefs[i]), 0);
    }
  }

  /**
   * @dev Set team address.
   *
   * Emits a {SetTeamAddress} event .
   *
   * @param teamAddr Address of team
   */
  function setTeamAddress(address teamAddr) external onlyOwner {
    teamWallet = teamAddr;
    emit SetTeamAddress(teamAddr);
  }

  /**
   * @dev Set team address.
   *
   * Emits a {SetMarketingAddress} event .
   *
   * @param marketingAddr Marketing address
   */
  function setMarketingAddress(address marketingAddr) external onlyOwner {
    marketingWallet = marketingAddr;
    emit SetMarketingAddress(marketingAddr);
  }

  /**
   * @dev Getter for emission.
   */
  function getEmission() public view returns (Emission memory) {
    return _emission;
  }

  /**
   * @dev Unlocks the token.
   *
   * Emits a {EmitToken} event.
   */
  function emitToken() public nonReentrant {
    if (block.timestamp <= _emission.lastUnlockedTime || _emission.lockingAmount == 0) {
      return;
    }

    uint256 duration = Math.min(block.timestamp, _emission.estimatedEndTime) - _emission.lastUnlockedTime;
    uint256 amount = duration * _emission.unlockTokensPerSec;
    uint256 liq;

    if (amount > 0) {
      cssToken.safeMint(teamWallet, amount * TEAM_PERCENT / MAX_PERCENT);
      cssToken.safeMint(marketingWallet, amount * MARKETING_PERCENT / MAX_PERCENT);
      liq = cssToken.safeMint(address(this), amount * COMMUNITY_PERCENT / MAX_PERCENT);
    }

    uint256 cap = cssToken.cap();
    uint256 totalSupply = cssToken.totalSupply();
    uint256 locking = cap > totalSupply ? cap - totalSupply : 0;
    _sync(locking);
    emit EmitToken(duration, liq, _emission.lockingAmount);
  }

  /**
   * @dev Sets emission for the current token `cssToken`.
   *
   * Emits a {SetEmission} event.
   *
   * Requirements:
   *
   * - the duration is at least 5 min.
   * - the start time is at least from now.
   * - this contract must have the `MINTER_ROLE` of token.
   *
   * @param startTime the timestamp to start emit token
   * @param duration the duration to emit token
   */
  function setEmission(uint256 startTime, uint256 duration) public onlyOwner {
    require(startTime >= block.timestamp && duration >= 5 minutes, "MasterChef: invalid timestamp");
    require(address(cssToken.tokenVesting()) == address(this), "MasterChef: must set token vesting for CSS");

    uint256 locking = cssToken.cap() - cssToken.totalSupply();
    uint256 unlockTokensPerSec = locking / duration;

    _emission.startTime = startTime;
    _emission.unlockTokensPerSec = unlockTokensPerSec;
    if (unlockTokensPerSec * duration < locking) duration++;
    _emission.estimatedEndTime = startTime + duration;
    _emission.lastUnlockedTime = startTime;
    _emission.lockingAmount = locking;
    emit SetEmission(startTime, _emission.estimatedEndTime, _emission.unlockTokensPerSec, locking);
  }

  /**
   * @dev See {TokenVesting-setEmission}.
   */
  function setEmissionNow(uint256 duration) external {
    setEmission(block.timestamp, duration);
  }

  /**
   * @dev Hook that sync the emission.
   *
   * @param locking the token amount that being locked
   */
  function _sync(uint256 locking) private {
    _emission.lockingAmount = locking;

    if (block.timestamp < _emission.startTime) {
      return;
    } else if (locking == 0) {
      delete _emission.unlockTokensPerSec;
    }

    _emission.lastUnlockedTime = block.timestamp;
  }
}

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#G5J?7!~~~::::::::::::::::~^^^:::::^:[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@#GY7~:.                                    [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@#P?^.                                          [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@#Y!.                    [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@&P!.                       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@&Y:                          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@&Y:                      .::^~^7YYYYYYYYYYYYYYYYYYYYYYYYY#@@@@@@@@@@@@@
@@@@@@@@P:                  .^7YPB#&@@@&.                         [email protected]@@@@@@@@@@@@
@@@@@@&7                 :?P#@@@@@@@@@@&.                         [email protected]@@@@@@@@@@@@
@@@@@B:               .7G&@@@@@@@@@&#BBP.                         [email protected]@@@@@@@@@@@@
@@@@G.              .J#@@@@@@@&GJ!^:.                             [email protected]@@@@@@@@@@@@
@@@G.              7#@@@@@@#5~.                                   [email protected]@@@@@@@@@@@@
@@#.             :[email protected]@@@@@#?.                                      [email protected]@@@@@@@@@@@@
@@~             :#@@@@@@J.       .~JPGBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@@@@@@@@@
@5             .#@@@@@&~       !P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@~             [email protected]@@@@&^      ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
B             [email protected]@@@@@7      ^&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
5             [email protected]@@@@#      .#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Y   ..     .. P#####5      [email protected]@@@@@@@@@@@@@@@@@@@@@@@&##########################&
@############B:    .       [email protected]@@@@@@@@@@@@@@@@@@@@@@@5            ..            7
@@@@@@@@@@@@@@:            .#@@@@@@@@@@@@@@@@@@@@@@@~                          7
@@@@@@@@@@@@@@J             ~&@@@@@@@@@@@@@@@@@@@@@?       ......              5
@@@@@@@@@@@@@@#.             ^[email protected]@@@@@@@@@@@@@@@@@#!      .G#####G.            .#
@@@@@@@@@@@@@@@P               !P&@@@@@@@@@@@@@G7.      :[email protected]@@@@@~             [email protected]
@@@@@@@@@@@@@@@@5                :!JPG####BPY7:        7#@@@@@&!             :#@
@@@@@@@@@@@@@@@@@P:                   ....           [email protected]@@@@@#~              [email protected]@
@@@@@@@@@@@@@@@@@@#!                             .^J#@@@@@@@Y.              [email protected]@@
@@@@@@@@@@@@@@@@@@@@G~                      .^!JP#@@@@@@@&5^               [email protected]@@@
@@@@@@@@@@@@@@@@@@@@@@G7.               ?BB#&@@@@@@@@@@#J:                [email protected]@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&P7:            [email protected]@@@@@@@@@&GJ~.                ^[email protected]@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B5?~:.      [email protected]@@@&#G5?~.                  [email protected]@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BGP5YJ~~~^^..                      ?#@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.                         [email protected]@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.                       ^Y&@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.                    ^[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.                :!5#@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.         ..^!JP#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&~::^~!7?5PB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/