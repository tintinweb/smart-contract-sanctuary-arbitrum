// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAMM {
    function swapExactInput(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256);

    function swap(
        address tokenA,
        address tokenB,
        uint256 amountIn,
        uint256 amountOutMin,
        address poolAddress
    ) external returns (uint256);

    function buySweep(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256);

    function sellSweep(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256);

    function sequencer() external view returns (address);

    function pool() external view returns (address);

    function getTWAPrice() external view returns (uint256 twaPrice);

    function getPrice() external view returns (uint256 price);
    
    function getRate() external view returns (uint256 rate);

    function getPositions(uint256) external view returns (uint256 usdxAmount, uint256 sweepAmount, uint256 lp);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IBalancerGauge {
    function claim_rewards() external;
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function balanceOf(address _address) external view returns(uint256 _balance);
}

interface IBalancerVault {
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;
    function exitPool(bytes32 poolId, address sender, address recipient, ExitPoolRequest memory request) external payable;
    function getPoolTokens(bytes32 poolId) external view returns (IAsset[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external returns (uint256 amountOut);
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerPool is IERC20Metadata {
    function getPoolId() external view returns (bytes32);
    function getVault() external view returns (address);
    function getRate() external view returns (uint256);
    function getTokenRate(address) external view returns (uint256);
    function getScalingFactors() external view returns (uint256[] memory);
    function getAmplificationParameter() external view returns (uint256, bool, uint256);
}

struct SingleSwap {
   bytes32 poolId;
   SwapKind kind;
   IAsset assetIn;
   IAsset assetOut;
   uint256 amount;
   bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

interface IComposableStablePoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 amplificationParameter,
        IRateProvider[] memory rateProviders,
        uint256[] memory tokenRateCacheDurations,
        bool exemptFromYieldProtocolFeeFlag,
        uint256 swapFeePercentage,
        address owner,
        bytes32 salt
    ) external returns(address poolAddress);
}

interface IRateProvider {
    function getRate() external view returns (uint256);
}

enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT }
enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT, EXACT_BPT_IN_FOR_ALL_TOKENS_OUT }
enum SwapKind { GIVEN_IN, GIVEN_OUT }

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ======================== BalancerMarketMaker.sol ===================
// ====================================================================

/**
 * @title Balancer Stable/Stable Pool Market Maker
 * @dev Implementation:
 * Increases and decreases the liquidity
 */

import { Stabilizer, TransferHelper, ISweep } from "../Stabilizer/Stabilizer.sol";
import { IBalancerPool, IBalancerVault, IAsset, JoinKind, ExitKind } from "../Assets/Interfaces/Balancer/IBalancer.sol";

contract BalancerMarketMaker is Stabilizer {

    error BadAddress();
    error BadSlippage();

    event LiquidityAdded(uint256 usdxAmount, uint256 sweepAmount);
    event LiquidityRemoved(uint256 usdxAmount, uint256 sweepAmount);
    event SweepPurchased(uint256 sweeAmount);

    IBalancerPool public pool;
    IBalancerVault public vault;

    bytes32 public poolId;
    IAsset[] public poolAssets;

    uint8 public sweepIndex;
    uint8 public usdxIndex;
    uint8 public bptIndex;

    uint32 public slippage; 

    uint24 private constant PRECISION = 1e6;

    constructor(
        string memory _name,
        address _sweep,
        address _usdx,
        address _oracleUsdx,
        address _poolAddress,
        address _borrower
    ) Stabilizer(_name, _sweep, _usdx, _oracleUsdx, _borrower) {
        slippage = 5000; // 0.5%
        pool = IBalancerPool(_poolAddress);
        vault = IBalancerVault(pool.getVault()); 
        poolId = pool.getPoolId();
        (poolAssets, , ) = vault.getPoolTokens(poolId);
        sweepIndex = findAssetIndex(address(sweep), poolAssets);
        usdxIndex = findAssetIndex(address(usdx), poolAssets);
        bptIndex = findAssetIndex(address(pool), poolAssets);
    }

    /* ========== Views ========== */

    /**
     * @notice Gets the asset price of AMM
     * @return the amm usdx amount
     */
    function assetValue() public view override returns (uint256) {    
        uint256 bpt = pool.balanceOf(address(this));
        uint256 rate = pool.getRate();

        uint256 usdcAmount = (bpt * rate * (10 ** usdx.decimals())) / (10 ** (pool.decimals() * 2));

        return _oracleUsdxToUsd(usdcAmount);
    }

    function getBuyPrice() public view returns (uint256) {
        uint256 targetPrice = sweep.targetPrice();
        return targetPrice + ((sweep.arbSpread() * targetPrice) / PRECISION);
    }

    /* ========== Actions ========== */

    function buySweep(uint256 usdxAmount) external nonReentrant returns (uint256 sweepAmount) {
        sweepAmount = (_oracleUsdxToUsd(usdxAmount) * (10 ** sweep.decimals())) / getBuyPrice();

        _borrow(sweepAmount * 2);
        _addLiquidity(usdxAmount, sweepAmount);

        TransferHelper.safeTransfer(address(sweep), msg.sender, sweepAmount);

        emit SweepPurchased(usdxAmount);
    }

    function initPool(uint256 usdxAmount, uint256 sweepAmount) external nonReentrant onlyBorrower {
        address self = address(this);

        TransferHelper.safeTransferFrom(address(usdx), msg.sender, self, usdxAmount);
        TransferHelper.safeApprove(address(usdx), address(vault), usdxAmount);
        TransferHelper.safeApprove(address(sweep), address(vault), sweepAmount);

        if(sweep.isMintingAllowed()){
            _borrow(sweepAmount);
        } else {
            TransferHelper.safeTransferFrom(address(sweep), msg.sender, self, sweepAmount);
        }

        uint256[] memory amounts = new uint256[](3);
        amounts[bptIndex] = 2**112;
        amounts[usdxIndex] = usdxAmount;
        amounts[sweepIndex] = sweepAmount;

        bytes memory userData = abi.encode(JoinKind.INIT, amounts);

        IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(poolAssets, amounts, userData, false);
        vault.joinPool(poolId, self, self, request);
    }

    function _addLiquidity(uint256 usdxAmount, uint256 sweepAmount) internal {
        address self = address(this);

        TransferHelper.safeTransferFrom(address(usdx), msg.sender, self, usdxAmount);
        TransferHelper.safeApprove(address(usdx), address(vault), usdxAmount);
        TransferHelper.safeApprove(address(sweep), address(vault), sweepAmount);
        
        uint256[] memory amounts = new uint256[](3);
        amounts[usdxIndex] = usdxAmount;
        amounts[sweepIndex] = sweepAmount;

        uint256[] memory userDataAmounts = new uint256[](2);
        userDataAmounts[0] = (sweepIndex > usdxIndex) ? usdxAmount : sweepAmount;
        userDataAmounts[1] = (sweepIndex > usdxIndex) ? sweepAmount : usdxAmount;

        uint256 usdxMin = usdxAmount * pool.getTokenRate(address(usdx)) / (10 ** usdx.decimals());
        uint256 sweepMin = sweepAmount * pool.getTokenRate(address(sweep)) / (10 ** sweep.decimals());
        uint256 minTotalAmountOut = (usdxMin + sweepMin) * (PRECISION - slippage) / PRECISION;

        bytes memory userData = abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, userDataAmounts, minTotalAmountOut);

        IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(poolAssets, amounts, userData, false);
        vault.joinPool(poolId, self, self, request);
    }

    function addLiquidity(uint256 usdxAmount, uint256 sweepAmount) external nonReentrant onlyBorrower {
        address self = address(this);

        if(sweep.isMintingAllowed()){
            if(sweepAmount > 0) _borrow(sweepAmount);
        } else {
            TransferHelper.safeTransferFrom(address(sweep), msg.sender, self, sweepAmount);
        }

        _addLiquidity(usdxAmount, sweepAmount);

        emit LiquidityAdded(usdxAmount, sweepAmount);
    }

    function removeLiquidity(uint256 usdxAmount, uint256 sweepAmount) external nonReentrant onlyBorrower {
        address self = address(this);

        uint256 usdxMax = usdxAmount * pool.getTokenRate(address(usdx)) / (10**usdx.decimals());
        uint256 sweepMax = sweepAmount * pool.getTokenRate(address(sweep)) / (10**sweep.decimals());
        uint256 maxAmountIn = (usdxMax + sweepMax) * (PRECISION + slippage) / PRECISION;

        uint256[] memory amounts = new uint256[](3);
        amounts[usdxIndex] = usdxAmount;
        amounts[sweepIndex] = sweepAmount;

        uint256[] memory userDataAmounts = new uint256[](2);
        userDataAmounts[0] = (sweepIndex > usdxIndex) ? usdxAmount : sweepAmount;
        userDataAmounts[1] = (sweepIndex > usdxIndex) ? sweepAmount : usdxAmount;

        bytes memory userData = abi.encode(ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT, userDataAmounts, maxAmountIn);

        IBalancerVault.ExitPoolRequest memory request = IBalancerVault.ExitPoolRequest(poolAssets, amounts, userData, false);
        vault.exitPool(poolId, self, self, request);

        if(sweepAmount > 0) _repay(sweepAmount);

        emit LiquidityRemoved(usdxAmount, sweepAmount);
    }

    function setSlippage(uint32 newSlippage) external nonReentrant onlyBorrower {
        if(newSlippage > PRECISION) revert BadSlippage();
        slippage = newSlippage;
    }

    function findAssetIndex(address asset, IAsset[] memory assets) internal pure returns (uint8) {
        for (uint8 i = 0; i < assets.length; i++) {
            if ( address(assets[i]) == asset ) return i;
        }
        revert BadAddress();
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

// ==========================================================
// ======================= Owned.sol ========================
// ==========================================================

import "../Sweep/ISweep.sol";

contract Owned {
    ISweep public immutable sweep;

    // Errors
    error NotGovernance();
    error NotMultisigOrGov();
    error ZeroAddressDetected();

    constructor(address _sweep) {
        if(_sweep == address(0)) revert ZeroAddressDetected();

        sweep = ISweep(_sweep);
    }

    modifier onlyGov() {
        if (msg.sender != sweep.owner()) revert NotGovernance();
        _;
    }

    modifier onlyMultisigOrGov() {
        if (msg.sender != sweep.fastMultisig() && msg.sender != sweep.owner())
            revert NotMultisigOrGov();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IPriceFeed {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

library ChainlinkLibrary {
    uint8 constant USD_DECIMALS = 6;

    function getDecimals(IPriceFeed oracle) internal view returns (uint8) {
        return oracle.decimals();
    }

    function getPrice(IPriceFeed oracle) internal view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = oracle.latestRoundData();
        require(answeredInRound >= roundID, "Old data");
        require(timeStamp > 0, "Round not complete");

        return uint256(price);
    }

    function getPrice(
        IPriceFeed oracle,
        IPriceFeed sequencerOracle,
        uint256 frequency
    ) internal view returns (uint256) {
        if (address(sequencerOracle) != address(0))
            checkUptime(sequencerOracle);

        (uint256 roundId, int256 price, , uint256 updatedAt, ) = oracle
            .latestRoundData();
        require(price > 0 && roundId != 0 && updatedAt != 0, "Invalid Price");
        if (frequency > 0)
            require(block.timestamp - updatedAt <= frequency, "Stale Price");

        return uint256(price);
    }

    function checkUptime(IPriceFeed sequencerOracle) internal view {
        (, int256 answer, uint256 startedAt, , ) = sequencerOracle
            .latestRoundData();
        require(answer <= 0, "Sequencer Down"); // 0: Sequencer is up, 1: Sequencer is down
        require(block.timestamp - startedAt > 1 hours, "Grace Period Not Over");
    }

    function convertTokenToToken(
        uint256 amount0,
        uint8 token0Decimals,
        uint8 token1Decimals,
        IPriceFeed oracle0,
        IPriceFeed oracle1
    ) internal view returns (uint256 amount1) {
        uint256 price0 = getPrice(oracle0);
        uint256 price1 = getPrice(oracle1);
        amount1 =
            (amount0 * price0 * (10 ** token1Decimals)) /
            (price1 * (10 ** token0Decimals));
    }

    function convertTokenToUsd(
        uint256 amount,
        uint8 tokenDecimals,
        IPriceFeed oracle
    ) internal view returns (uint256 amountUsd) {
        uint8 decimals = getDecimals(oracle);
        uint256 price = getPrice(oracle);

        amountUsd =
            (amount * price * (10 ** USD_DECIMALS)) /
            10 ** (decimals + tokenDecimals);
    }

    function convertUsdToToken(
        uint256 amountUsd,
        uint256 tokenDecimals,
        IPriceFeed oracle
    ) internal view returns (uint256 amount) {
        uint8 decimals = getDecimals(oracle);
        uint256 price = getPrice(oracle);

        amount =
            (amountUsd * 10 ** (decimals + tokenDecimals)) /
            (price * (10 ** USD_DECIMALS));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

library OvnMath {
    uint256 constant BASIS_DENOMINATOR = 1e6;

    function abs(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? (x - y) : (y - x);
    }

    function addBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * (BASIS_DENOMINATOR + basisPoints)) / BASIS_DENOMINATOR;
    }

    function reverseAddBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * BASIS_DENOMINATOR) / (BASIS_DENOMINATOR + basisPoints);
    }

    function subBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * (BASIS_DENOMINATOR - basisPoints)) / BASIS_DENOMINATOR;
    }

    function reverseSubBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * BASIS_DENOMINATOR) / (BASIS_DENOMINATOR - basisPoints);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ====================== Stabilizer.sol ==============================
// ====================================================================

/**
 * @title Stabilizer
 * @dev Implementation:
 * Allows to take debt by minting sweep and repaying by burning sweep
 * Allows to buy and sell sweep in an AMM
 * Allows auto invest according the borrower configuration
 * Allows auto repays by the balancer to control sweep price
 * Allow liquidate the Asset when is defaulted
 * Repayments made by burning sweep
 * EquityRatio = Junior / (Junior + Senior)
 */

import "../AMM/IAMM.sol";
import "../Common/Owned.sol";
import "../Libraries/Chainlink.sol";
import "../Libraries/OvnMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Stabilizer is Owned, Pausable, ReentrancyGuard {
    using Math for uint256;

    IERC20Metadata public usdx;
    IPriceFeed public oracleUsdx;

    // Variables
    string public name;
    address public borrower;
    int256 public minEquityRatio; // Minimum Equity Ratio. 10000 is 1%
    uint256 public sweepBorrowed;
    uint256 public loanLimit;

    uint256 public callTime;
    uint256 public callDelay; // 86400 is 1 day
    uint256 public callAmount;

    uint256 public spreadFee; // 10000 is 1%
    uint256 public spreadDate;
    string public link;

    int256 public autoInvestMinRatio; // 10000 is 1%
    uint256 public autoInvestMinAmount;
    bool public autoInvestEnabled;

    bool public settingsEnabled;

    uint256 public startingTime;
    uint256 public startingPrice;
    uint256 public decreaseFactor; // 10000 is 1%
    uint256 public minLiquidationRatio; // 100000 is 10%
    bool public auctionAllowed;

    // Constants for various precisions
    uint256 private constant DAY_SECONDS = 60 * 60 * 24; // seconds of Day
    uint256 private constant DAYS_ONE_YEAR = 365; // days of Year
    uint256 private constant PRECISION = 1e6;
    uint256 private constant ORACLE_FREQUENCY = 1 days;

    /* ========== Events ========== */

    event Borrowed(uint256 indexed sweepAmount);
    event Repaid(uint256 indexed sweepAmount);
    event Withdrawn(address indexed token, uint256 indexed amount);
    event PayFee(uint256 indexed sweepAmount);
    event Bought(uint256 indexed sweepAmount);
    event Sold(uint256 indexed sweepAmount);
    event BoughtSWEEP(uint256 indexed sweepAmount);
    event SoldSWEEP(uint256 indexed usdxAmount);
    event LoanLimitChanged(uint256 loanLimit);
    event Proposed(address indexed borrower);
    event Rejected(address indexed borrower);
    event SweepBorrowedChanged(uint256 indexed sweepAmount);

    event Liquidated(address indexed user);

    event AutoCalled(uint256 indexed sweepAmount);
    event AutoInvested(uint256 indexed sweepAmount);
    event CallCancelled(uint256 indexed sweepAmount);

    event ConfigurationChanged(
        int256 indexed minEquityRatio,
        uint256 indexed spreadFee,
        uint256 loanLimit,
        uint256 decreaseFactor,
        uint256 callDelay,
        int256 autoInvestMinRatio,
        uint256 autoInvestMinAmount,
        uint256 minLiquidationRatio,
        bool autoInvestEnabled,
        bool _auctionAllowed,
        string url
    );

    /* ========== Errors ========== */

    error NotBorrower();
    error NotBalancer();
    error NotSweep();
    error SettingsDisabled();
    error OverZero();
    error AssetDefaulted();
    error AuctionNotActive();
    error ActionNotAllowed();
    error InvalidMinter();
    error NotEnoughBalance();
    error EquityRatioExcessed();
    error InvalidToken();
    error SpreadNotEnough();
    error NotDefaulted();
    error NotAutoInvest();
    error NotAutoInvestMinAmount();
    error NotAutoInvestMinRatio();

    /* ========== Modifies ========== */

    modifier onlyBorrower() {
        _onlyBorrower();
        _;
    }

    modifier onlySettingsEnabled() {
        _onlySettingsEnabled();
        _;
    }

    modifier validAmount(uint256 amount) {
        _validAmount(amount);
        _;
    }

    constructor(
        string memory _name,
        address _sweep,
        address _usdx,
        address _oracleUsdx,
        address _borrower
    ) Owned(_sweep) {
        if (_borrower == address(0)) revert ZeroAddressDetected();
        name = _name;
        usdx = IERC20Metadata(_usdx);
        oracleUsdx = IPriceFeed(_oracleUsdx);
        borrower = _borrower;
        settingsEnabled = true;
    }

    /* ========== Views ========== */

    /**
     * @notice Defaulted
     * @return bool that tells if stabilizer is in default.
     */
    function isDefaulted() public view returns (bool) {
        return
            (callDelay > 0 && callAmount > 0 && block.timestamp > callTime) ||
            (sweepBorrowed > 0 && getEquityRatio() < minEquityRatio);
    }

    /**
     * @notice Get Equity Ratio
     * @return the current equity ratio based in the internal storage.
     * @dev this value have a precision of 6 decimals.
     */
    function getEquityRatio() public view returns (int256) {
        uint256 totalValue = currentValue();

        if (totalValue == 0) {
            if (sweepBorrowed > 0) return -1e6;
            else return 0;
        }

        uint256 seniorTrancheInUsd = sweep.convertToUSD(sweepBorrowed);
        // 1e6 are decimals of the percentage result
        int256 equityRatio = ((int256(totalValue) - int256(seniorTrancheInUsd)) * 1e6) / int256(totalValue);

        if (equityRatio < -1e6) equityRatio = -1e6;
        return equityRatio;
    }

    /**
     * @notice Get Spread Amount
     * fee = borrow_amount * spread_ratio * (time / time_per_year)
     * @return uint256 calculated spread amount.
     */
    function accruedFee() public view returns (uint256) {
        if (sweepBorrowed > 0) {
            uint256 period = (block.timestamp - spreadDate) / DAY_SECONDS;
            return
                (sweepBorrowed * spreadFee * period) /
                (DAYS_ONE_YEAR * PRECISION);
        }

        return 0;
    }

    /**
     * @notice Get Debt Amount
     * debt = borrow_amount + spread fee
     * @return uint256 calculated debt amount.
     */
    function getDebt() public view returns (uint256) {
        return sweepBorrowed + accruedFee();
    }

    /**
     * @notice Get Current Value
     * value = sweep balance + usdx balance
     * @return uint256.
     */
    function currentValue() public view returns (uint256) {
        (uint256 usdxBalance, uint256 sweepBalance) = _balances();
        uint256 sweepInUsd = sweep.convertToUSD(sweepBalance);
        uint256 usdxInUsd = _oracleUsdxToUsd(usdxBalance);
        uint256 accruedFeeInUSD = sweep.convertToUSD(accruedFee());

        return assetValue() + usdxInUsd + sweepInUsd - accruedFeeInUSD;
    }

    /**
     * @notice Get AMM from Sweep
     * @return address.
     */
    function amm() public view virtual returns (IAMM) {
        return IAMM(sweep.amm());
    }

    /**
     * @notice Get Junior Tranche Value
     * @return int256 calculated junior tranche amount.
     */
    function getJuniorTrancheValue() external view returns (int256) {
        uint256 seniorTrancheInUSD = sweep.convertToUSD(sweepBorrowed);
        uint256 totalValue = currentValue();

        return int256(totalValue) - int256(seniorTrancheInUSD);
    }

    /**
     * @notice Returns the SWEEP required to liquidate the stabilizer in the auction.
     * @return auctionPrice
     */
    function getAuctionAmount() public view returns (uint256) {
        uint256 minPrice = sweepBorrowed * (PRECISION - minLiquidationRatio) / PRECISION;
        uint256 timeElapsed = (block.timestamp - startingTime) / 5 minutes;
        uint256 ratio = timeElapsed * decreaseFactor;

        if(ratio > PRECISION) return minPrice;

        uint256 decreaseRatio = PRECISION - ratio;
        uint256 auctionPrice = (startingPrice * decreaseRatio) / PRECISION;

        return minPrice > auctionPrice ? minPrice : auctionPrice;
    }

    /* ========== Settings ========== */

    /**
     * @notice Pause
     * @dev Stops investment actions.
     */
    function pause() external onlyMultisigOrGov {
        _pause();
    }

    /**
     * @notice Unpause
     * @dev Start investment actions.
     */
    function unpause() external onlyMultisigOrGov {
        _unpause();
    }

    /**
     * @notice Configure intial settings
     * @param _minEquityRatio The minimum equity ratio can be negative.
     * @param _spreadFee The fee that the protocol will get for providing the loan when the stabilizer takes debt
     * @param _loanLimit How much debt a Stabilizer can take in SWEEP.
     * @param _decreaseFactor A percentage that will be discounted from the price as time passes from the auction start.
     * @param _callDelay Time in seconds after AutoCall until the Stabilizer gets defaulted if the debt is not paid in that period
     * @param _autoInvestMinRatio Minimum equity ratio that should be kept to allow the execution of an auto invest
     * @param _autoInvestMinAmount Minimum amount to be invested to allow the execution of an auto invest
     * @param _autoInvestEnabled Represents if an auto invest execution is allowed or not
     * @param _auctionAllowed Represents if an auction is allowed or not
     * @param _url A URL link to a Web page that describes the borrower and the asset
     * @dev Sets the initial configuration of the Stabilizer.
     * This configuration will be analyzed by the protocol and if accepted,
     * used to include the Stabilizer in the minter's whitelist of Sweep.
     * The minimum equity ratio can not be less than 1%
     */
    function configure(
        int256 _minEquityRatio,
        uint256 _spreadFee,
        uint256 _loanLimit,
        uint256 _decreaseFactor,
        uint256 _callDelay,
        int256 _autoInvestMinRatio,
        uint256 _autoInvestMinAmount,
        uint256 _minLiquidationRatio,
        bool _autoInvestEnabled,
        bool _auctionAllowed,
        string calldata _url
    ) external onlyBorrower onlySettingsEnabled {
        minEquityRatio = _minEquityRatio;
        spreadFee = _spreadFee;
        loanLimit = _loanLimit;
        decreaseFactor = _decreaseFactor;
        callDelay = _callDelay;
        autoInvestMinRatio = _autoInvestMinRatio;
        autoInvestMinAmount = _autoInvestMinAmount;
        minLiquidationRatio = _minLiquidationRatio;
        autoInvestEnabled = _autoInvestEnabled;
        auctionAllowed = _auctionAllowed;
        link = _url;

        emit ConfigurationChanged(
            _minEquityRatio,
            _spreadFee,
            _loanLimit,
            decreaseFactor,
            _callDelay,
            _autoInvestMinRatio,
            _autoInvestMinAmount,
            _minLiquidationRatio,
            _autoInvestEnabled,
            _auctionAllowed,
            _url
        );
    }

    /**
     * @notice Changes the account that control the global configuration to the protocol/governance admin
     * @dev after disable settings by admin
     * the protocol will evaluate adding the stabilizer to the minter list.
     */
    function propose() external onlyBorrower {
        settingsEnabled = false;

        emit Proposed(borrower);
    }

    /**
     * @notice Changes the account that control the global configuration to the borrower
     * @dev after enable settings for the borrower
     * he/she should edit the values to align to the protocol requirements
     */
    function reject() external onlyGov {
        settingsEnabled = true;

        emit Rejected(borrower);
    }

    /* ========== Actions ========== */

    /**
     * @notice Borrows Sweep
     * Asks the stabilizer to mint a certain amount of sweep token.
     * @param sweepAmount.
     * @dev Increases the sweepBorrowed (senior tranche).
     */
    function borrow(
        uint256 sweepAmount
    )
        public
        onlyBorrower
        whenNotPaused
        validAmount(sweepAmount)
        nonReentrant
    {
        _borrow(sweepAmount);

        if (getEquityRatio() < minEquityRatio) {
            revert EquityRatioExcessed();
        }
    }

    /**
     * @notice Repays Sweep
     * Burns the sweep amount to reduce the debt (senior tranche).
     * @param sweepAmount Amount to be burnt by Sweep.
     * @dev Decreases the sweep borrowed.
     */
    function repay(uint256 sweepAmount) external onlyBorrower nonReentrant {
        _repay(sweepAmount);
    }

    /**
     * @notice Pay the spread to the treasury
     */
    function payFee() external onlyBorrower nonReentrant {
        uint256 spreadAmount = accruedFee();
        spreadDate = block.timestamp;

        uint256 sweepBalance = sweep.balanceOf(address(this));

        if (spreadAmount > sweepBalance) revert SpreadNotEnough();

        if (spreadAmount > 0) {
            TransferHelper.safeTransfer(
                address(sweep),
                sweep.treasury(),
                spreadAmount
            );

            emit PayFee(spreadAmount);
        }
    }

    /**
     * @notice Set Loan Limit.
     * @param newLoanLimit.
     * @dev How much debt an Stabilizer can take in SWEEP.
     */
    function setLoanLimit(uint256 newLoanLimit) external {
        if (msg.sender != sweep.balancer()) revert NotBalancer();
        loanLimit = newLoanLimit;

        emit LoanLimitChanged(newLoanLimit);
    }

    /**
     * @notice Update Sweep Borrowed Amount.
     * @param amount.
     */
    function updateSweepBorrowed(uint256 amount) external {
        if (msg.sender != address(sweep)) revert NotSweep();
        sweepBorrowed = amount;

        emit SweepBorrowedChanged(amount);
    }

    /**
     * @notice Auto Call.
     * @param sweepAmount to repay.
     * @dev Strategy:
     * 1) repays debt with SWEEP balance
     * 2) repays remaining debt by divesting
     * 3) repays remaining debt by buying on SWEEP in the AMM
     */
    function autoCall(
        uint256 sweepAmount,
        uint256,
        uint256 slippage
    ) external nonReentrant {
        if (msg.sender != sweep.balancer()) revert NotBalancer();
        (uint256 usdxBalance, uint256 sweepBalance) = _balances();
        uint256 repayAmount = sweepAmount.min(sweepBorrowed);

        if (callDelay > 0) {
            callTime = block.timestamp + callDelay;
            callAmount = repayAmount;
        }

        if (sweepBalance < repayAmount) {
            uint256 missingSweep = repayAmount - sweepBalance;
            uint256 sweepInUsd = sweep.convertToUSD(missingSweep);
            uint256 missingUsdx = _oracleUsdToUsdx(sweepInUsd);

            if (missingUsdx > usdxBalance) {
                _divest(missingUsdx - usdxBalance, slippage);
            }

            if (usdx.balanceOf(address(this)) > 0) {
                _buy(missingUsdx, slippage);
            }
        }

        if (sweep.balanceOf(address(this)) > 0 && repayAmount > 0) {
            _repay(repayAmount);
        }

        emit AutoCalled(sweepAmount);
    }

    /**
     * @notice Cancel Call
     * @dev Cancels the auto call request by clearing variables for an asset
     * that has a callDelay: meaning that it does not autorepay.
     */
    function cancelCall() external {
        if (msg.sender != sweep.balancer()) revert NotBalancer();
        callAmount = 0;
        callTime = 0;
        emit CallCancelled(callAmount);
    }

    /**
     * @notice Auto Invest.
     * @param sweepAmount to mint.
     * @param slippage.
     */
    function autoInvest(
        uint256 sweepAmount,
        uint256,
        uint256 slippage
    ) external nonReentrant {
        if (msg.sender != sweep.balancer()) revert NotBalancer();
        if (!autoInvestEnabled) revert NotAutoInvest();
        if (sweepAmount < autoInvestMinAmount) revert NotAutoInvestMinAmount();

        _borrow(sweepAmount);
        uint256 usdxAmount = _sell(sweepAmount, slippage);
        _invest(usdxAmount, 0, slippage);

        if (getEquityRatio() < autoInvestMinRatio){
            revert NotAutoInvestMinRatio();
        }

        emit AutoInvested(sweepAmount);
    }

    /**
     * @notice Buy
     * Buys sweep amount from the stabilizer's balance to the AMM (swaps USDX to SWEEP).
     * @param usdxAmount Amount to be changed in the AMM.
     * @param slippage Minimum amount out.
     * @dev Increases the sweep balance and decrease usdx balance.
     */
    function buySweepOnAMM(
        uint256 usdxAmount,
        uint256 slippage
    )
        external
        onlyBorrower
        whenNotPaused
        nonReentrant
        returns (uint256 sweepAmount)
    {
        sweepAmount = _buy(usdxAmount, slippage);
        emit Bought(sweepAmount);
    }

    /**
     * @notice Sell Sweep
     * Sells sweep amount from the stabilizer's balance to the AMM (swaps SWEEP to USDX).
     * @param sweepAmount.
     * @param slippage Minimum amount out.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function sellSweepOnAMM(
        uint256 sweepAmount,
        uint256 slippage
    )
        external
        onlyBorrower
        whenNotPaused
        nonReentrant
        returns (uint256 usdxAmount)
    {
        usdxAmount = _sell(sweepAmount, slippage);
        emit Sold(sweepAmount);
    }

    /**
     * @notice Buy Sweep with Stabilizer
     * Buys sweep amount from the stabilizer's balance to the Borrower (swaps USDX to SWEEP).
     * @param usdxAmount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function swapUsdxToSweep(uint256 usdxAmount)
        public onlyBorrower whenNotPaused validAmount(usdxAmount) nonReentrant
        returns (uint256 sweepAmount)

    {
        uint256 usdxInUsd = _oracleUsdxToUsd(usdxAmount);
        sweepAmount = sweep.convertToSWEEP(usdxInUsd);
        uint256 sweepBalance = sweep.balanceOf(address(this));
        if (sweepAmount > sweepBalance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(usdx),
            msg.sender,
            address(this),
            usdxAmount
        );
        TransferHelper.safeTransfer(address(sweep), msg.sender, sweepAmount);

        emit BoughtSWEEP(sweepAmount);
    }

    /**
     * @notice Sell Sweep with Stabilizer
     * Sells sweep amount to the stabilizer (swaps SWEEP to USDX).
     * @param sweepAmount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function swapSweepToUsdx(uint256 sweepAmount)
        public onlyBorrower whenNotPaused validAmount(sweepAmount) nonReentrant
        returns (uint256 usdxAmount)
    {
        uint256 sweepInUsd = sweep.convertToUSD(sweepAmount);
        usdxAmount = _oracleUsdToUsdx(sweepInUsd);
        uint256 usdxBalance = usdx.balanceOf(address(this));

        if (usdxAmount > usdxBalance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(address(sweep), msg.sender, address(this), sweepAmount);
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdxAmount);

        emit SoldSWEEP(usdxAmount);
    }

    function oneStepInvest(uint256 sweepAmount, uint256 slippage, bool useAMM) 
        external onlyBorrower whenNotPaused validAmount(sweepAmount) nonReentrant
        returns(uint256 usdxAmount)
    {
        _borrow(sweepAmount);
        
        if(useAMM){
            usdxAmount = _sell(sweepAmount, slippage);
        } else {
            usdxAmount = swapSweepToUsdx(sweepAmount);
        }

        _invest(usdxAmount, 0, slippage);

        if (getEquityRatio() < minEquityRatio){
            revert EquityRatioExcessed();
        }
    }

    function oneStepDivest(uint256 usdxAmount, uint256 slippage, bool useAMM)
        external onlyBorrower whenNotPaused validAmount(usdxAmount) nonReentrant
        returns(uint256 sweepAmount)
    {
        _divest(usdxAmount, slippage);

        if(useAMM){
            sweepAmount = _buy(usdxAmount, slippage);
        } else {
            sweepAmount = swapUsdxToSweep(usdxAmount);
        }

        _repay(sweepAmount);
    }

    /**
     * @notice Withdraw SWEEP
     * Takes out sweep balance if the new equity ratio is higher than the minimum equity ratio.
     * @param token.
     * @param amount.
     * @dev Decreases the sweep balance.
     */
    function withdraw(address token, uint256 amount) 
        external onlyBorrower whenNotPaused validAmount(amount) nonReentrant
    {    
        if (amount > IERC20Metadata(token).balanceOf(address(this)))
            revert NotEnoughBalance();

        TransferHelper.safeTransfer(token, msg.sender, amount);

        if (sweepBorrowed > 0 && getEquityRatio() < minEquityRatio) {
            revert EquityRatioExcessed();
        }

        emit Withdrawn(token, amount);
    }

    /**
     * @notice Start auction
     * Initiates a dutch auction for liquidation.
     */
    function startAuction() external nonReentrant {
        if (!isDefaulted()) revert NotDefaulted();
        if(!auctionAllowed || startingPrice > 0) revert ActionNotAllowed();

        startingTime = block.timestamp;
        uint256 minEquity = (PRECISION - uint256(minEquityRatio));
        startingPrice = getDebt() * PRECISION / minEquity;
    }

    /**
     * @notice Buy auction
     * Allows a user to participate in the auction by buying assets
     */
    function buyAuction() external nonReentrant {
        if(startingTime == 0) revert AuctionNotActive();
        uint256 debt = getAuctionAmount();
        address token = _getToken();
        _liquidate(token, debt);
    }

    /* ========== Internals ========== */

    function assetValue() public view virtual returns (uint256) { return 0; }

    /**
     * @notice Invest To Asset.
     */
    function _invest(uint256, uint256, uint256) internal virtual {}

    /**
     * @notice Divest From Asset.
     */
    function _divest(uint256, uint256) internal virtual returns (uint256) {}

    /**
     * @notice Get asset address to liquidate.
     */
    function _getToken() internal view virtual returns (address) {}

    /**
     * @notice Stop the auction.
     */
    function _stopAuction() internal {
        startingTime = 0;
        startingPrice = 0;
    }

    /**
     * @notice Liquidates
     * A liquidator repays the debt in sweep and gets the same value
     * of the assets that the stabilizer holds at a discount
     */
    function _liquidate(
        address token,
        uint256 debt
    ) internal {
        if (!isDefaulted()) revert NotDefaulted();
        address self = address(this);
        uint256 usdxBalance = usdx.balanceOf(self);
        uint256 tokenBalance = IERC20Metadata(token).balanceOf(self);
        uint256 sweepBalance = sweep.balanceOf(self);
        if(debt > sweepBalance) {
            // Takes SWEEP from the liquidator and repays debt
            TransferHelper.safeTransferFrom(
                address(sweep),
                msg.sender,
                self,
                debt - sweepBalance
            );
        }

        // Gives all the assets to the liquidator
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdxBalance);
        TransferHelper.safeTransfer(token, msg.sender, tokenBalance);

        _repay(debt);

        emit Liquidated(msg.sender);
    }

    function _buy(
        uint256 usdxAmount, 
        uint256 slippage
    ) internal returns (uint256 sweepAmount) {
        uint256 usdxBalance = usdx.balanceOf(address(this));
        usdxAmount = usdxAmount.min(usdxBalance);
        if (usdxAmount == 0) revert NotEnoughBalance();

        sweepAmount = sweep.convertToSWEEP(_oracleUsdxToUsd(usdxAmount));
        uint256 minAmountOut = OvnMath.subBasisPoints(sweepAmount, slippage);

        IAMM _amm = amm();
        TransferHelper.safeApprove(address(usdx), address(_amm), usdxAmount);
        sweepAmount = _amm.buySweep(
            address(usdx),
            usdxAmount,
            minAmountOut
        );

        return sweepAmount;
    }

    function _sell(
        uint256 sweepAmount,
        uint256 slippage
    ) internal returns (uint256 usdxAmount) {
        uint256 sweepBalance = sweep.balanceOf(address(this));
        sweepAmount = sweepAmount.min(sweepBalance);
        if (sweepAmount == 0) revert NotEnoughBalance();

        usdxAmount = _oracleUsdToUsdx(sweep.convertToUSD(sweepAmount));
        uint256 minAmountOut = OvnMath.subBasisPoints(usdxAmount, slippage);

        IAMM _amm = amm();
        TransferHelper.safeApprove(address(sweep), address(_amm), sweepAmount);
        usdxAmount = _amm.sellSweep(
            address(usdx),
            sweepAmount,
            minAmountOut
        );

        return usdxAmount;
    }

    function _borrow(uint256 sweepAmount) internal {
        if (!sweep.isValidMinter(address(this))) revert InvalidMinter();
        uint256 sweepAvailable = loanLimit - sweepBorrowed;
        if (sweepAvailable < sweepAmount) revert NotEnoughBalance();

        uint256 spreadAmount = accruedFee();
        sweep.mint(sweepAmount);
        sweepBorrowed += sweepAmount;
        spreadDate = block.timestamp;

        if (spreadAmount > 0) {
            TransferHelper.safeTransfer(
                address(sweep),
                sweep.treasury(),
                spreadAmount
            );
            emit PayFee(spreadAmount);
        }

        emit Borrowed(sweepAmount);
    }

    function _repay(uint256 sweepAmount) internal {
        uint256 sweepBalance = sweep.balanceOf(address(this));
        sweepAmount = sweepAmount.min(sweepBalance);

        if (sweepAmount == 0) revert NotEnoughBalance();

        callAmount = (callAmount > sweepAmount)
            ? (callAmount - sweepAmount)
            : 0;

        if (callDelay > 0 && callAmount == 0) callTime = 0;

        uint256 spreadAmount = accruedFee();
        spreadDate = block.timestamp;

        sweepAmount = sweepAmount - spreadAmount;
        if (sweepBorrowed < sweepAmount) {
            sweepAmount = sweepBorrowed;
            sweepBorrowed = 0;
        } else {
            sweepBorrowed -= sweepAmount;
        }

        TransferHelper.safeTransfer(
            address(sweep),
            sweep.treasury(),
            spreadAmount
        );

        TransferHelper.safeApprove(address(sweep), address(this), sweepAmount);
        sweep.burn(sweepAmount);

        emit Repaid(sweepAmount);
        if(!isDefaulted()) _stopAuction();
    }

    

    /**
     * @notice Get Balances of the usdx and SWEEP.
     **/
    function _balances()
        internal
        view
        returns (uint256 usdxBalance, uint256 sweepBalance)
    {
        usdxBalance = usdx.balanceOf(address(this));
        sweepBalance = sweep.balanceOf(address(this));
    }

    function _onlyBorrower() internal view {
        if (msg.sender != borrower) revert NotBorrower();
    }

    function _onlySettingsEnabled() internal view {
        if (!settingsEnabled) revert SettingsDisabled();
    }

    function _validAmount(uint256 amount) internal pure {
        if (amount == 0) revert OverZero();
    }

    function _oracleUsdxToUsd(
        uint256 usdxAmount
    ) internal view returns (uint256) {
        return
            ChainlinkLibrary.convertTokenToUsd(
                usdxAmount,
                usdx.decimals(),
                oracleUsdx
            );
    }

    function _oracleUsdToUsdx(
        uint256 usdAmount
    ) internal view returns (uint256) {
        return
            ChainlinkLibrary.convertUsdToToken(
                usdAmount,
                usdx.decimals(),
                oracleUsdx
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface ISweep {
    struct Minter {
        uint256 maxAmount;
        uint256 mintedAmount;
        bool isListed;
        bool isEnabled;
    }

    function isMintingAllowed() external view returns (bool);

    function DEFAULT_ADMIN_ADDRESS() external view returns (address);

    function balancer() external view returns (address);

    function treasury() external view returns (address);

    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function isValidMinter(address) external view returns (bool);

    function amm() external view returns (address);

    function ammPrice() external view returns (uint256);

    function twaPrice() external view returns (uint256);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function fastMultisig() external view returns (address);

    function burn(uint256 amount) external;

    function mint(uint256 amount) external;

    function minters(address minterAaddress) external returns (Minter memory);

    function minterAddresses(uint256 index) external view returns (address);

    function getMinters() external view returns (address[] memory);

    function targetPrice() external view returns (uint256);

    function interestRate() external view returns (int256);

    function periodStart() external view returns (uint256);

    function stepValue() external view returns (int256);

    function arbSpread() external view returns (uint256);

    function refreshInterestRate(int256 newInterestRate, uint256 newPeriodStart) external;

    function setTargetPrice(
        uint256 currentTargetPrice,
        uint256 nextTargetPrice
    ) external;

    function setInterestRate(
        int256 currentInterestRate,
        int256 nextInterestRate
    ) external;

    function setPeriodStart(
        uint256 currentPeriodStart,
        uint256 nextPeriodStart
    ) external;

    function startNewPeriod() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function convertToUSD(uint256 amount) external view returns (uint256);

    function convertToSWEEP(uint256 amount) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}