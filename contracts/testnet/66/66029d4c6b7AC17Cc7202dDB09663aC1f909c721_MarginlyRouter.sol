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
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import './RouterStorage.sol';

struct AdapterCallbackData {
  address payer;
  address tokenIn;
  uint256 dexIndex;
}

abstract contract AdapterCallback is RouterStorage {
  /// @inheritdoc IMarginlyRouter
  function adapterCallback(address recipient, uint256 amount, bytes calldata _data) external {
    AdapterCallbackData memory data = abi.decode(_data, (AdapterCallbackData));
    require(msg.sender == adapters[data.dexIndex]);
    TransferHelper.safeTransferFrom(data.tokenIn, data.payer, recipient, amount);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../interfaces/IMarginlyAdapter.sol';
import '../interfaces/IMarginlyRouter.sol';

struct AdapterInput {
  uint256 dexIndex;
  address adapter;
}

abstract contract RouterStorage is IMarginlyRouter, Ownable {
  error UnknownDex();

  mapping(uint256 => address) public adapters;

  constructor(AdapterInput[] memory _adapters) {
    AdapterInput memory input;
    for (uint256 i; i < _adapters.length; ++i) {
      input = _adapters[i];
      adapters[input.dexIndex] = input.adapter;
    }
  }

  function addDexAdapters(AdapterInput[] calldata _adapters) external onlyOwner {
    AdapterInput memory input;
    for (uint256 i; i < _adapters.length; ++i) {
      input = _adapters[i];
      adapters[input.dexIndex] = input.adapter;
    }
  }

  function getAdapterSafe(uint256 dexIndex) internal view returns (IMarginlyAdapter) {
    address adapterAddress = adapters[dexIndex];
    if (adapterAddress == address(0)) revert UnknownDex();
    return IMarginlyAdapter(adapterAddress);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMarginlyAdapter {
  error InsufficientAmount();
  error TooMuchRequested();
  error NotSupported();

  /// @notice swap with exact input
  /// @param recipient recipient of amountOut of tokenOut
  /// @param tokenIn address of a token to swap on dex
  /// @param tokenOut address of a token to receive from dex
  /// @param amountIn exact amount of tokenIn to swap
  /// @param minAmountOut minimal amount of tokenOut to receive
  /// @param data data for AdapterCallback
  function swapExactInput(
    address recipient,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    bytes calldata data
  ) external returns (uint256 amountOut);

  /// @notice swap with exact output
  /// @param recipient recipient of amountOut of tokenOut
  /// @param tokenIn address of a token to swap on dex
  /// @param tokenOut address of a token to receive from dex
  /// @param maxAmountIn maximal amount of tokenIn to swap
  /// @param amountOut exact amount of tokenOut to receive
  /// @param data data for AdapterCallback
  function swapExactOutput(
    address recipient,
    address tokenIn,
    address tokenOut,
    uint256 maxAmountIn,
    uint256 amountOut,
    bytes calldata data
  ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '../abstract/AdapterCallback.sol';
import '../abstract/RouterStorage.sol';

interface IMarginlyRouter {
  /// @notice Emitted when swap with zero input or output was called
  error ZeroAmount();
  /// @notice Emitted if balance difference doesn't equal amountOut
  error WrongAmountOut();

  /// @notice Emitted when swap happened
  /// @param isExactInput true if swapExactInput, false if swapExactOutput
  /// @param dexIndex index of the dex used for swap
  /// @param receiver swap result receiver
  /// @param tokenIn address of a token swapped on dex
  /// @param tokenOut address of a token received from dex
  /// @param amountIn amount of tokenIn swapped
  /// @param amountOut amount of tokenOut received
  event Swap(
    bool isExactInput,
    uint256 dexIndex,
    address indexed receiver,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  /// @notice swap with exact input
  /// @param swapCalldata calldata for multiple swaps
  /// @param tokenIn address of a token to swap on dex
  /// @param tokenOut address of a token to receive from dex
  /// @param amountIn exact amount of tokenIn to swap
  /// @param minAmountOut minimal amount of tokenOut to receive
  /// @param amountOut resulting amount of tokenOut output
  function swapExactInput(
    uint256 swapCalldata,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut
  ) external returns (uint256 amountOut);

  /// @notice swap with exact output
  /// @param swapCalldata calldata for multiple swaps
  /// @param tokenIn address of a token to swap on dex
  /// @param tokenOut address of a token to receive from dex
  /// @param maxAmountIn maximal amount of tokenIn to swap
  /// @param amountOut exact amount of tokenOut to receive
  /// @param amountIn resulting amount of tokenIn input
  function swapExactOutput(
    uint256 swapCalldata,
    address tokenIn,
    address tokenOut,
    uint256 maxAmountIn,
    uint256 amountOut
  ) external returns (uint256 amountIn);

  /// @notice this function can be called by known adapters only
  /// @param recipient to whom transfer the tokens from swap initiator
  /// @param amount amount of tokens to transfer
  /// @param data callback data with transfer details and info to verify sender
  function adapterCallback(address recipient, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';

library SwapsDecoder {
  struct SwapInfo {
    uint16 dexIndex;
    uint256 dexAmountIn;
    uint256 dexAmountOut;
  }

  error WrongSwapsNumber();
  error WrongSwapRatios();

  uint256 constant MASK = 4194303; // 2^22 - 1
  uint256 constant SWAP_NUMBER_MASK = 15; // 2^4 - 1
  uint256 internal constant ONE = 32768; // 2^15

  /// @dev encodedSwaps param structure:
  /// @dev last 4 bits: total number of swaps
  /// @dev then swaps as groups of 22 bits
  /// @dev the first 6 out of 22 bits represent dexIndex
  /// @dev the rest 16 out of 22 bits represent swap ratio
  function decodeSwapInfo(
    uint256 encodedSwaps,
    uint256 amountIn,
    uint256 amountOut
  ) internal pure returns (SwapInfo[] memory swapInfos) {
    unchecked {
      // default value
      if (encodedSwaps == 0) {
        swapInfos = new SwapInfo[](1);
        swapInfos[0] = SwapInfo({dexIndex: 0, dexAmountIn: amountIn, dexAmountOut: amountOut});
        return swapInfos;
      }

      uint256 swapsNumber = encodedSwaps & SWAP_NUMBER_MASK;
      if (swapsNumber == 0) revert WrongSwapsNumber();
      swapInfos = new SwapInfo[](swapsNumber);
      encodedSwaps >>= 4;

      uint16 swapRatiosSum;
      uint256 totalAmountIn;
      uint256 totalAmountOut;
      for (uint256 swap; swap < swapsNumber; ++swap) {
        uint256 swapInfo = encodedSwaps & MASK;
        uint16 swapRatio = uint16(swapInfo);
        swapRatiosSum += swapRatio;
        encodedSwaps >>= 22;

        bool isLastSwap = swap + 1 == swapsNumber;
        uint256 dexAmountIn = isLastSwap ? amountIn - totalAmountIn : Math.mulDiv(amountIn, swapRatio, ONE);
        totalAmountIn += dexAmountIn;
        uint256 dexAmountOut = isLastSwap ? amountOut - totalAmountOut : Math.mulDiv(amountOut, swapRatio, ONE);
        totalAmountOut += dexAmountOut;

        swapInfos[swap] = SwapInfo({
          dexIndex: uint16(swapInfo >> 16),
          dexAmountIn: dexAmountIn,
          dexAmountOut: dexAmountOut
        });
      }

      if (swapRatiosSum != ONE) revert WrongSwapRatios();
      if (encodedSwaps != 0) revert WrongSwapsNumber();
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import './abstract/AdapterCallback.sol';
import './abstract/RouterStorage.sol';
import './interfaces/IMarginlyRouter.sol';
import './interfaces/IMarginlyAdapter.sol';
import './libraries/SwapsDecoder.sol';

contract MarginlyRouter is RouterStorage, AdapterCallback {
  constructor(AdapterInput[] memory _adapters) RouterStorage(_adapters) {}

  /// @inheritdoc IMarginlyRouter
  function swapExactInput(
    uint256 swapCalldata,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut
  ) external returns (uint256 amountOut) {
    if (amountIn == 0) revert ZeroAmount();

    uint256 balanceBefore = IERC20(tokenOut).balanceOf(msg.sender);

    SwapsDecoder.SwapInfo[] memory swapInfos = SwapsDecoder.decodeSwapInfo(swapCalldata, amountIn, minAmountOut);

    for (uint256 i; i < swapInfos.length; ++i) {
      SwapsDecoder.SwapInfo memory swapInfo = swapInfos[i];
      uint256 dexIndex = swapInfo.dexIndex;
      uint256 dexAmountIn = swapInfo.dexAmountIn;

      bytes memory data = abi.encode(AdapterCallbackData({payer: msg.sender, tokenIn: tokenIn, dexIndex: dexIndex}));
      uint256 dexAmountOut = getAdapterSafe(dexIndex).swapExactInput(
        msg.sender,
        tokenIn,
        tokenOut,
        dexAmountIn,
        swapInfo.dexAmountOut,
        data
      );

      amountOut += dexAmountOut;
      emit Swap(true, dexIndex, msg.sender, tokenIn, tokenOut, dexAmountIn, dexAmountOut);
    }

    if (amountOut != IERC20(tokenOut).balanceOf(msg.sender) - balanceBefore) revert WrongAmountOut();
  }

  /// @inheritdoc IMarginlyRouter
  function swapExactOutput(
    uint256 swapCalldata,
    address tokenIn,
    address tokenOut,
    uint256 maxAmountIn,
    uint256 amountOut
  ) external returns (uint256 amountIn) {
    if (amountOut == 0) revert ZeroAmount();

    uint256 balanceBefore = IERC20(tokenOut).balanceOf(msg.sender);

    SwapsDecoder.SwapInfo[] memory swapInfos = SwapsDecoder.decodeSwapInfo(swapCalldata, maxAmountIn, amountOut);

    for (uint256 i; i < swapInfos.length; ++i) {
      SwapsDecoder.SwapInfo memory swapInfo = swapInfos[i];
      uint256 dexIndex = swapInfo.dexIndex;
      uint256 dexAmountOut = swapInfo.dexAmountOut;

      bytes memory data = abi.encode(AdapterCallbackData({payer: msg.sender, tokenIn: tokenIn, dexIndex: dexIndex}));
      uint256 dexAmountIn = getAdapterSafe(dexIndex).swapExactOutput(
        msg.sender,
        tokenIn,
        tokenOut,
        swapInfo.dexAmountIn,
        dexAmountOut,
        data
      );

      amountIn += dexAmountIn;
      emit Swap(false, dexIndex, msg.sender, tokenIn, tokenOut, dexAmountIn, dexAmountOut);
    }

    if (amountOut != IERC20(tokenOut).balanceOf(msg.sender) - balanceBefore) revert WrongAmountOut();
  }
}