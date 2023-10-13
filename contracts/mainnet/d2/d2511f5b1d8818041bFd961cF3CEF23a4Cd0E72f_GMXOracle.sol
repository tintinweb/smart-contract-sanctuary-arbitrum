// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

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
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IChainlinkOracle {
  function consult(address token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address token) external view returns (uint256 price);
  function addTokenPriceFeed(address token, address feed) external;
  function addTokenMaxDelay(address token, uint256 maxDelay) external;
  function addTokenMaxDeviation(address token, uint256 maxDeviation) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ISyntheticReader {
  struct MarketInfo {
    MarketProps market;
    uint256 borrowingFactorPerSecondForLongs;
    uint256 borrowingFactorPerSecondForShorts;
    BaseFundingValues baseFunding;
    GetNextFundingAmountPerSizeResult nextFunding;
    VirtualInventory virtualInventory;
    bool isDisabled;
  }

  struct MarketPrices {
    PriceProps indexTokenPrice;
    PriceProps longTokenPrice;
    PriceProps shortTokenPrice;
  }

  struct MarketProps {
    address marketToken;
    address indexToken;
    address longToken;
    address shortToken;
  }

  struct PriceProps {
      uint256 min;
      uint256 max;
  }

  struct BaseFundingValues {
    PositionType fundingFeeAmountPerSize;
    PositionType claimableFundingAmountPerSize;
  }

  struct VirtualInventory {
    uint256 virtualPoolAmountForLongToken;
    uint256 virtualPoolAmountForShortToken;
    int256 virtualInventoryForPositions;
  }

  struct GetNextFundingAmountPerSizeResult {
    bool longsPayShorts;
    uint256 fundingFactorPerSecond;

    PositionType fundingFeeAmountPerSizeDelta;
    PositionType claimableFundingAmountPerSizeDelta;
  }

  struct PositionType {
    CollateralType long;
    CollateralType short;
  }

  struct CollateralType {
    uint256 longToken;
    uint256 shortToken;
  }

  struct MarketPoolValueInfoProps {
    int256 poolValue;
    int256 longPnl;
    int256 shortPnl;
    int256 netPnl;

    uint256 longTokenAmount;
    uint256 shortTokenAmount;
    uint256 longTokenUsd;
    uint256 shortTokenUsd;

    uint256 totalBorrowingFees;
    uint256 borrowingFeePoolFactor;

    uint256 impactPoolAmount;
  }

  struct SwapFees {
    uint256 feeReceiverAmount;
    uint256 feeAmountForPool;
    uint256 amountAfterFees;

    address uiFeeReceiver;
    uint256 uiFeeReceiverFactor;
    uint256 uiFeeAmount;
  }

  struct ExecutionPriceResult {
    int256 priceImpactUsd;
    uint256 priceImpactDiffUsd;
    uint256 executionPrice;
  }

  function getMarkets(
    address dataStore,
    uint256 start,
    uint256 end
  ) external view returns (MarketProps[] memory);

  function getMarketInfo(
    address dataStore,
    MarketPrices memory prices,
    address marketKey
  ) external view returns (MarketInfo memory);

  function getMarketTokenPrice(
    address dataStore,
    MarketProps memory market,
    PriceProps memory indexTokenPrice,
    PriceProps memory longTokenPrice,
    PriceProps memory shortTokenPrice,
    bytes32 pnlFactorType,
    bool maximize
  ) external view returns (int256, MarketPoolValueInfoProps memory);

  function getSwapAmountOut(
    address dataStore,
    MarketProps memory market,
    MarketPrices memory prices,
    address tokenIn,
    uint256 amountIn,
    address uiFeeReceiver
  ) external view returns (uint256, int256, SwapFees memory fees);

  function getExecutionPrice(
    address dataStore,
    address marketKey,
    PriceProps memory indexTokenPrice,
    uint256 positionSizeInUsd,
    uint256 positionSizeInTokens,
    int256 sizeDeltaUsd,
    bool isLong
  ) external view returns (ExecutionPriceResult memory);

  function getSwapPriceImpact(
    address dataStore,
    address marketKey,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    PriceProps memory tokenInPrice,
    PriceProps memory tokenOutPrice
  ) external view returns (int256, int256);

  function getOpenInterestWithPnl(
    address dataStore,
    MarketProps memory market,
    PriceProps memory indexTokenPrice,
    bool isLong,
    bool maximize
  ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol"; // TEMP
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ISyntheticReader } from "../interfaces/protocols/gmx/ISyntheticReader.sol";
import { IChainlinkOracle } from "../interfaces/oracles/IChainlinkOracle.sol";
import { Errors } from "../utils/Errors.sol";

contract GMXOracle is Ownable {

  /* ========== STATE VARIABLES ========== */

  // GMX DataStore
  address public immutable dataStore;
  // GMX Synthetic Reader
  ISyntheticReader public immutable syntheticReader;
  // Chainlink oracle
  IChainlinkOracle public immutable chainlinkOracle;

  // TEMP
  uint256 public longTokenWeightAdjust = 10000;
  uint256 public lpTokenPriceAdjust = 10000;

  function changeAdjust(
    uint256 _longTokenWeightAdjust,
    uint256 _lpTokenPriceAdjust
  ) external onlyOwner {
    longTokenWeightAdjust = _longTokenWeightAdjust;
    lpTokenPriceAdjust = _lpTokenPriceAdjust;
  }

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param newDataStore Address of GMX DataStore
    * @param newSyntheticReader Address of GMX Synthetic Reader
    * @param newChainlinkOracle Address of Chainlink oracle
  */
  constructor(
    address newDataStore,
    ISyntheticReader newSyntheticReader,
    IChainlinkOracle newChainlinkOracle
  ) Ownable(msg.sender) {
    if (newDataStore == address(0)) revert Errors.ZeroAddressNotAllowed();
    if (address(newSyntheticReader) == address(0)) revert Errors.ZeroAddressNotAllowed();
    if (address(newChainlinkOracle) == address(0)) revert Errors.ZeroAddressNotAllowed();

    dataStore = newDataStore;
    syntheticReader = newSyntheticReader;
    chainlinkOracle = newChainlinkOracle;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * @dev Get amountsOut of either the long or short token based on the amountsIn
    * of either long or short token in the market
    * @param marketToken LP token address
    * @param indexToken Index token address
    * @param longToken Long token address
    * @param shortToken Short token address
    * @param tokenIn TokenIn address
    * @param amountIn Amount of tokenIn, expressed in tokenIn's decimals
    * @return amountsOut Amount of tokenOut within LP (market) to be received, expressed in tokenOut's decimals
  */
  function getAmountsOut(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenIn,
    uint256 amountIn
  ) public view returns (uint256) {
    ISyntheticReader.MarketProps memory _market;
    _market.marketToken = marketToken;
    _market.indexToken = indexToken;
    _market.longToken = longToken;
    _market.shortToken = shortToken;

    ISyntheticReader.PriceProps memory _indexTokenPrice;
    _indexTokenPrice.min = _getTokenPriceMinMaxFormatted(indexToken);
    _indexTokenPrice.max = _getTokenPriceMinMaxFormatted(indexToken);

    ISyntheticReader.PriceProps memory _longTokenPrice;
    _longTokenPrice.min = _getTokenPriceMinMaxFormatted(longToken);
    _longTokenPrice.max = _getTokenPriceMinMaxFormatted(longToken);

    ISyntheticReader.PriceProps memory _shortTokenPrice;
    _shortTokenPrice.min = _getTokenPriceMinMaxFormatted(shortToken);
    _shortTokenPrice.max = _getTokenPriceMinMaxFormatted(shortToken);

    ISyntheticReader.MarketPrices memory _prices;
    _prices.indexTokenPrice = _indexTokenPrice;
    _prices.longTokenPrice = _longTokenPrice;
    _prices.shortTokenPrice = _shortTokenPrice;

    address _uiFeeReceiver = address(0);

    (uint256 _amountsOut,,) = syntheticReader.getSwapAmountOut(
      dataStore,
      _market,
      _prices,
      tokenIn,
      amountIn,
      _uiFeeReceiver
    );

    return _amountsOut;
  }

  /**
    * @dev Helper function to calculate amountIn of either long or short token for swapping for
    * desired amountsOut of long or short token
    * @notice We utilise GMX's getSwapAmountOut() with tokenOut being tokenIn, multiplying
    * the amountsOut value by 1.0015x to account for fees and normal chainlink price feed differential
    * @param marketToken LP token address
    * @param indexToken Index token address
    * @param longToken Long token address
    * @param shortToken Short token address
    * @param tokenOut TokenIn address
    * @param amountsOut Amount of tokenIn, expressed in tokenIn's decimals
    * @return amountsOut Amount of tokenOut within LP (market) to be received, expressed in tokenOut's decimals
  */
  function getAmountsIn(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenOut,
    uint256 amountsOut
  ) public view returns (uint256) {
    return getAmountsOut(
      marketToken,
      indexToken,
      longToken,
      shortToken,
      tokenOut,
      amountsOut
    ) * (1e18 + 15e14) / SAFE_MULTIPLIER;
  }

  /**
    * @dev Get LP (market) token info
    * @param marketToken LP token address
    * @param indexToken Index token address
    * @param longToken Long token address
    * @param shortToken Short token address
    * @param pnlFactorType P&L Factory type in bytes32 hashed string
    * @param maximize Min/max price boolean
    * @return (marketTokenPrice, MarketPoolValueInfoProps MarketInfo)
  */
  function getMarketTokenInfo(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bytes32 pnlFactorType,
    bool maximize
  ) public view returns (int256, ISyntheticReader.MarketPoolValueInfoProps memory) {
    if (address(marketToken) == address(0)) revert Errors.ZeroAddressNotAllowed();
    if (address(indexToken) == address(0)) revert Errors.ZeroAddressNotAllowed();
    if (address(longToken) == address(0)) revert Errors.ZeroAddressNotAllowed();
    if (address(shortToken) == address(0)) revert Errors.ZeroAddressNotAllowed();

    ISyntheticReader.MarketProps memory _market;
    _market.marketToken = marketToken;
    _market.indexToken = indexToken;
    _market.longToken = longToken;
    _market.shortToken = shortToken;

    ISyntheticReader.PriceProps memory _indexTokenPrice;
    _indexTokenPrice.min = _getTokenPriceMinMaxFormatted(indexToken);
    _indexTokenPrice.max = _getTokenPriceMinMaxFormatted(indexToken);

    ISyntheticReader.PriceProps memory _longTokenPrice;
    _longTokenPrice.min = _getTokenPriceMinMaxFormatted(longToken);
    _longTokenPrice.max = _getTokenPriceMinMaxFormatted(longToken);

    ISyntheticReader.PriceProps memory _shortTokenPrice;
    _shortTokenPrice.min = _getTokenPriceMinMaxFormatted(shortToken);
    _shortTokenPrice.max = _getTokenPriceMinMaxFormatted(shortToken);

    return syntheticReader.getMarketTokenPrice(
      dataStore,
      _market,
      _indexTokenPrice,
      _longTokenPrice,
      _shortTokenPrice,
      pnlFactorType,
      maximize
    );

    // return (_marketTokenPrice, _marketInfo);
  }

  /**
    * @dev Get LP (market) token reserves
    * @param marketToken LP token address
    * @param indexToken Index token address
    * @param longToken Long token address
    * @param shortToken Short token address
    * @return (reserveA, reserveB) Reserve amount of longToken and shortToken respectively
  */
  function getLpTokenReserves(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken
  ) public view returns (uint256, uint256) {
    // _pnlFactorType value does not matter in getting token reserves
    bytes32 _pnlFactorType = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_DEPOSITS"));
    // _maximize value does not matter in getting token reserves
    bool _maximize = false;

    (, ISyntheticReader.MarketPoolValueInfoProps memory _marketInfo) = getMarketTokenInfo(
      marketToken,
      indexToken,
      longToken,
      shortToken,
      _pnlFactorType,
      _maximize
    );

    return (
      _marketInfo.longTokenAmount * longTokenWeightAdjust / 10000, // TEMP
      // _marketInfo.longTokenAmount,
      _marketInfo.shortTokenAmount
    );
  }

  /**
    * @dev Get LP (market) token reserves
    * @param marketToken LP token address
    * @param indexToken Index token address
    * @param longToken Long token address
    * @param shortToken Short token address
    * @param isDeposit Boolean for deposit or withdrawal
    * @param maximize Boolean for minimum or maximum price
    * @return marketTokenPrice in 1e18
  */
  function getLpTokenValue(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) public view returns (uint256) {
    bytes32 _pnlFactorType;

    if (isDeposit) {
      _pnlFactorType = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_DEPOSITS"));
    } else {
      _pnlFactorType = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS"));
    }

    (int256 _marketTokenPrice,) = getMarketTokenInfo(
      marketToken,
      indexToken,
      longToken,
      shortToken,
      _pnlFactorType,
      maximize
    );

    // If LP token value is negative, return 0
    if (_marketTokenPrice < 0) {
      return 0;
    } else {
      // Price returned in 1e30, we normalize it to 1e12
      // return uint256(_marketTokenPrice) / 1e12;
      return uint256(_marketTokenPrice) * lpTokenPriceAdjust / 10000 / 1e12;
    }
  }


  /**
    * @dev Get token A and token B's LP token amount required for a given value
    * Used in keeper script to calculate how much LP tokens for given USD value
    * @param givenValue Given value needed, expressed in 1e30
    * @param marketToken LP token address
    * @param indexToken Index token address
    * @param longToken Long token address
    * @param shortToken Short token address
    * @param isDeposit Boolean for deposit or withdrawal
    * @param maximize Boolean for minimum or maximum price
    * @return lpTokenAmount Amount of LP tokens; expressed in 1e18
  */
  function getLpTokenAmount(
    uint256 givenValue,
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) public view returns (uint256) {
    uint256 _lpTokenValue = getLpTokenValue(
      marketToken,
      indexToken,
      longToken,
      shortToken,
      isDeposit,
      maximize
    );

    return givenValue * SAFE_MULTIPLIER / _lpTokenValue;
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * @dev Get token price formatted for GMX mix/max decimals for 1e30 normalization
    * @param token Token address
    * @return tokenPriceMinMaxFormatted in either in 1e12 (if token decimals 18) or 1e24 (if token decimals 6)
  */
  function _getTokenPriceMinMaxFormatted(address token) internal view returns (uint256) {
    uint256 _tokenPriceMinMaxFormatted;

    if (IERC20Metadata(token).decimals() == 18) {
      _tokenPriceMinMaxFormatted = chainlinkOracle.consultIn18Decimals(token) / 1e6;
    } else if (IERC20Metadata(token).decimals() == 6) {
      _tokenPriceMinMaxFormatted = chainlinkOracle.consultIn18Decimals(token) * 1e6;
    }

    return _tokenPriceMinMaxFormatted;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Errors {

  /* ========== AUTHORIZATION ========== */

  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();
  error OnlyBorrowerAllowed();

  /* ========== GENERAL ========== */

  error ZeroAddressNotAllowed();
  error TokenDecimalsMustBeLessThan18();

  /* ========== ORACLE ========== */

  error NoTokenPriceFeedAvailable();
  error FrozenTokenPriceFeed();
  error BrokenTokenPriceFeed();
  error TokenPriceFeedAlreadySet();
  error TokenPriceFeedMaxDelayMustBeGreaterOrEqualToZero();
  error TokenPriceFeedMaxDeviationMustBeGreaterOrEqualToZero();
  error InvalidTokenInLPPool();
  error InvalidReservesInLPPool();
  error OrderAmountOutMustBeGreaterThanZero();
  error SequencerDown();
  error GracePeriodNotOver();

  /* ========== LENDING ========== */

  error InsufficientBorrowAmount();
  error InsufficientRepayAmount();
  error BorrowerAlreadyApproved();
  error BorrowerAlreadyRevoked();
  error InsufficientLendingLiquidity();
  error InsufficientAssetsBalance();
  error InterestRateModelExceeded();

  /* ========== VAULT GENERAL ========== */

  error InvalidExecutionFeeAmount();
  error InsufficientExecutionFeeAmount();
  error InsufficientSlippageAmount();
  error NotAllowedInCurrentVaultStatus();

  /* ========== VAULT DEPOSIT ========== */

  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error OnlyNonNativeDepositToken();
  error InvalidNativeTokenAddress();
  error DepositAndExecutionFeeDoesNotMatchMsgValue();
  error DepositCancellationCallback();

  /* ========== VAULT WITHDRAWAL ========== */

  error EmptyWithdrawAmount();
  error InvalidWithdrawToken();
  error InsufficientWithdrawAmount();
  error InsufficientWithdrawBalance();
  error InsufficientAssetsReceived();
  error WithdrawNotAllowedInSameDepositBlock();
  error WithdrawalCancellationCallback();

  /* ========== VAULT REBALANCE ========== */

  error InvalidDebtRatio();
  error InvalidDelta();
  error InvalidEquity();
  error InsufficientLPTokensMinted();
  error InsufficientLPTokensBurned();
  error InvalidRebalancePreConditions();

  /* ========== VAULT CALLBACKS ========== */

  error InvalidDepositKey();
  error InvalidWithdrawKey();
  error InvalidOrderKey();
  error InvalidCallbackHandler();
  error InvalidRefundeeAddress();
}