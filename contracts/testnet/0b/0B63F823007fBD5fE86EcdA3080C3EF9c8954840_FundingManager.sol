// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, 'Governable: forbidden');
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC4626.sol';

interface IPerpetual {
    struct Position {
        address owner;
        bytes32 productId;
        uint256 margin; // collateral provided for this position
        FixedPoint.Unsigned leverage;
        FixedPoint.Unsigned price; // price when position was increased. weighted average by size
        FixedPoint.Unsigned oraclePrice;
        FixedPoint.Signed funding;
        bytes16 ownerPositionId;
        uint64 timestamp; // last position increase
        bool isLong;
        bool isNextPrice;
    }

    struct ProductParams {
        bytes32 productId;
        FixedPoint.Unsigned maxLeverage;
        FixedPoint.Unsigned fee;
        bool isActive;
        FixedPoint.Unsigned minPriceChange; // min oracle increase % for trader to close with profit
        FixedPoint.Unsigned weight; // share of the max exposure
        uint256 reserve; // Virtual reserve used to calculate slippage
    }

    struct Product {
        bytes32 productId;
        FixedPoint.Unsigned maxLeverage;
        FixedPoint.Unsigned fee;
        bool isActive;
        FixedPoint.Unsigned openInterestLong;
        FixedPoint.Unsigned openInterestShort;
        FixedPoint.Unsigned minPriceChange; // min oracle increase % for trader to close with profit
        FixedPoint.Unsigned weight; // share of the max exposure
        uint256 reserve; // Virtual reserve used to calculate slippage
    }

    struct OpenPositionParams {
        address user;
        bytes16 userPositionId;
        bytes32 productId;
        uint256 margin;
        bool isLong;
        FixedPoint.Unsigned leverage;
    }

    struct ClosePositionParams {
        address user;
        bytes16 userPositionId;
        uint256 margin;
    }

    function distributeVaultReward() external returns (uint256);

    function getPendingVaultReward() external view returns (uint256);

    function openPositions(
        OpenPositionParams[] calldata params
    ) external;

    function closePositions(
        ClosePositionParams[] calldata params
    ) external;

    function getProduct(bytes32 productId) external view returns (Product memory);

    function getPosition(address account, bytes16 accountPositionId) external view returns (Position memory);

    function getMaxExposure(FixedPoint.Unsigned productWeight)
        external
        view
        returns (FixedPoint.Unsigned);
}

interface IDomFiPerp is IPerpetual, IERC20, IERC4626 {}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IFundingManager {
    function updateFunding(bytes32) external;

    function getFunding(bytes32) external view returns (FixedPoint.Signed);

    function getFundingRate(bytes32) external view returns (FixedPoint.Signed);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.8;

/**
 * @title Library for fixed point arithmetic on (u)ints
 */
library FixedPoint {
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_DECIMALS = 18;
    uint256 private constant FP_SCALING_FACTOR = 10**FP_DECIMALS;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    type Unsigned is uint256;

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned) {
        return Unsigned.wrap(a * FP_SCALING_FACTOR);
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) == Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) == Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) > Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) >= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) >= Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) >= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) < Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) <= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) <= Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) <= Unsigned.unwrap(b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) + Unsigned.unwrap(b));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) - Unsigned.unwrap(b));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned b) internal pure returns (Unsigned) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned.wrap(Unsigned.unwrap(a) * Unsigned.unwrap(b) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) * b);
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        uint256 mulRaw = Unsigned.unwrap(a) * Unsigned.unwrap(b);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw % FP_SCALING_FACTOR;
        if (mod != 0) {
            return Unsigned.wrap(mulFloor + 1);
        } else {
            return Unsigned.wrap(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        // Since b is an uint, there is no risk of truncation and we can just mul it normally
        return Unsigned.wrap(Unsigned.unwrap(a) * b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned.wrap(Unsigned.unwrap(a) * FP_SCALING_FACTOR / Unsigned.unwrap(b));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) / b);
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned b) internal pure returns (Unsigned) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        uint256 aScaled = Unsigned.unwrap(a) * FP_SCALING_FACTOR;
        uint256 divFloor = aScaled / Unsigned.unwrap(b);
        uint256 mod = aScaled % Unsigned.unwrap(b);
        if (mod != 0) {
            return Unsigned.wrap(divFloor + 1);
        } else {
            return Unsigned.wrap(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(Unsigned.unwrap(a).div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned a, uint256 b) internal pure returns (Unsigned output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i++) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    type Signed is int256;

    function fromSigned(Signed a) internal pure returns (Unsigned) {
        require(Signed.unwrap(a) >= 0, 'Negative value provided');
        return Unsigned.wrap(uint256(Signed.unwrap(a)));
    }

    function fromUnsigned(Unsigned a) internal pure returns (Signed) {
        require(Unsigned.unwrap(a) <= uint256(type(int256).max), 'Unsigned too large');
        return Signed.wrap(int256(Unsigned.unwrap(a)));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed) {
        return Signed.wrap(a * SFP_SCALING_FACTOR);
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) == Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) == Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) > Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) > Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) > Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) >= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) >= Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) >= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) < Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) < Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) < Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) <= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) <= Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) <= Signed.unwrap(b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.unwrap(a) < Signed.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.unwrap(a) > Signed.unwrap(b) ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) + Signed.unwrap(b));
    }

    /**
     * @notice Adds a `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, int256 b) internal pure returns (Signed) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Adds a `Signed` to an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an Unsigned.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, Unsigned b) internal pure returns (Signed) {
        return add(a, fromUnsigned(b));
    }

    /**
     * @notice Adds a `Signed` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, uint256 b) internal pure returns (Signed) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) - Signed.unwrap(b));
    }

    /**
     * @notice Subtracts an unscaled int256 from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, int256 b) internal pure returns (Signed) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Unsigned.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, Unsigned b) internal pure returns (Signed) {
        return sub(a, fromUnsigned(b));
    }

    /**
     * @notice Subtracts an unscaled uint256 from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, uint256 b) internal pure returns (Signed) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts a `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed b) internal pure returns (Signed) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, Signed b) internal pure returns (Signed) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed.wrap(Signed.unwrap(a) * Signed.unwrap(b) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, int256 b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) * b);
    }

    /**
     * @notice Multiplies a `Signed` and `Unsigned`, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Unsigned.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, Unsigned b) internal pure returns (Signed) {
        return mul(a, fromUnsigned(b));
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, uint256 b) internal pure returns (Signed) {
        return mul(a, fromUnscaledUint(b));
    }

    function neg(Signed a) internal pure returns (Signed) {
        return mul(a, -1);
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed a, Signed b) internal pure returns (Signed) {
        int256 mulRaw = Signed.unwrap(a) * Signed.unwrap(b);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed.wrap(mulTowardsZero + valueToAdd);
        } else {
            return Signed.wrap(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed a, int256 b) internal pure returns (Signed) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed.wrap(Signed.unwrap(a) * b);
    }

    /**
     * @notice Divides one `Signed` by a `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, Signed b) internal pure returns (Signed) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed.wrap(Signed.unwrap(a) * SFP_SCALING_FACTOR / Signed.unwrap(b));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, int256 b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) / b);
    }

    /**
     * @notice Divides one `Signed` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint.Signed numerator.
     * @param b a FixedPoint.Unsigned denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, Unsigned b) internal pure returns (Signed) {
        return div(a, fromUnsigned(b));
    }

    /**
     * @notice Divides one `Signed` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, uint256 b) internal pure returns (Signed) {
        return div(a, fromUnscaledUint(b));
    }

    /**
     * @notice Divides one unscaled int256 by a `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed b) internal pure returns (Signed) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by a `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed a, Signed b) internal pure returns (Signed) {
        int256 aScaled = Signed.unwrap(a) * SFP_SCALING_FACTOR;
        int256 divTowardsZero = aScaled / Signed.unwrap(b);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % Signed.unwrap(b);
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed.wrap(divTowardsZero + valueToAdd);
        } else {
            return Signed.wrap(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed a, int256 b) internal pure returns (Signed) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(Signed.unwrap(a).div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises a `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed a, uint256 b) internal pure returns (Signed output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i++) {
            output = mul(output, a);
        }
    }

    /**
     * @notice Absolute value of a FixedPoint.Signed
     */
    function abs(Signed value) internal pure returns (Unsigned) {
        int256 x = Signed.unwrap(value);
        uint256 raw = (x < 0) ? uint256(-x) : uint256(x);
        return Unsigned.wrap(raw);
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, "truncating" any decimal portion.
     */
    function trunc(FixedPoint.Unsigned value) internal pure returns (uint256) {
        return Unsigned.unwrap(value) / FP_SCALING_FACTOR;
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, "truncating" any decimal portion.
     */
    function trunc(FixedPoint.Signed value) internal pure returns (int256) {
        return Signed.unwrap(value) / SFP_SCALING_FACTOR;
    }

    /**
     * @notice Rounding a FixedPoint.Unsigned down to the nearest integer.
     */
    function floor(FixedPoint.Unsigned value) internal pure returns (FixedPoint.Unsigned) {
        return FixedPoint.fromUnscaledUint(trunc(value));
    }

    /**
     * @notice Round a FixedPoint.Unsigned up to the nearest integer.
     */
    function ceil(FixedPoint.Unsigned value) internal pure returns (FixedPoint.Unsigned) {
        FixedPoint.Unsigned iPart = floor(value);
        FixedPoint.Unsigned fPart = sub(value, iPart);
        if (Unsigned.unwrap(fPart) > 0) {
            return add(iPart, fromUnscaledUint(1));
        } else {
            return iPart;
        }
    }

    /**
     * @notice Given a uint with a certain number of decimal places, normalize it to a FixedPoint
     * @param value uint256, e.g. 10000000 wei USDC
     * @param decimals uint8 number of decimals to interpret `value` as, e.g. 6
     * @return output FixedPoint.Unsigned, e.g. (10.000000)
     */
    function fromScalar(uint256 value, uint8 decimals) internal pure returns (FixedPoint.Unsigned) {
        require(decimals <= FP_DECIMALS, 'FixedPoint: max decimals');
        return div(fromUnscaledUint(value), 10**decimals);
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, rounding up any decimal portion.
     */
    function roundUp(FixedPoint.Unsigned value) internal pure returns (uint256) {
        return trunc(ceil(value));
    }

    /**
     * @notice Round a trader's PnL in favor of liquidity providers
     */
    function roundTraderPnl(FixedPoint.Signed value) internal pure returns (FixedPoint.Signed) {
        if (Signed.unwrap(value) >= 0) {
            // If the P/L is a trader gain/value loss, then fractional dust gained for the trader should be reduced
            FixedPoint.Unsigned pnl = fromSigned(value);
            return fromUnsigned(floor(pnl));
        } else {
            // If the P/L is a trader loss/vault gain, then fractional dust lost should be magnified towards the trader
            return neg(fromUnsigned(ceil(abs(value))));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SignedSafeMath.sol';
import '../interfaces/perp/IDomFiPerp.sol';
import '../interfaces/perp/IFundingManager.sol';
import '../access/Governable.sol';
import '../lib/FixedPoint.sol';

/** @title Funding manager for Domination Finance levered perpetuals
 * Funding is continuously computed and applied when positions are touched.
 * Rates intended to incentivize even long/short orders (minimizing LP exposure)
 * and collect fees for LPs.
 *
 * Cumulative funding, the integral of funding rate, is tracked per product.
 * Given a position with timestamp and historical cum funding, we can compute
 * how much they owe (or receive).
 */
contract FundingManager is Governable, IFundingManager {
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for FixedPoint.Signed;

    IDomFiPerp public domFiPerp;
    address public owner;

    FixedPoint.Unsigned public maxFundingRate = FixedPoint.fromUnscaledUint(10); // 10% per year
    FixedPoint.Unsigned public minFundingMultiplier = FixedPoint.fromUnscaledUint(2); // 2% per year
    mapping(bytes32 => FixedPoint.Unsigned) public fundingMultipliers; // fundingRate when exposure is at maximum, %/yr
    mapping(bytes32 => FixedPoint.Signed) private cumulativeFundings;
    mapping(bytes32 => uint64) public lastUpdateTimes;

    event FundingUpdated(
        bytes32 productId,
        FixedPoint.Signed fundingRate,
        FixedPoint.Signed fundingChange,
        FixedPoint.Signed cumulativeFunding
    );
    event DomFiPerpSet(IDomFiPerp domFiPerp);
    event MinFundingMultiplierSet(FixedPoint.Unsigned minFundingMultiplier);
    event FundingMultiplierSet(bytes32 productId, FixedPoint.Unsigned fundingMultiplier);
    event MaxFundingRateSet(FixedPoint.Unsigned maxFundingRate);
    event UpdateOwner(address owner);

    constructor() {
        owner = msg.sender;
    }

    /** @notice integrate current funding rate since last update and update cumulative sum
        @param _productId product to update
     */
    function updateFunding(bytes32 _productId) external override {
        require(msg.sender == address(domFiPerp), 'FundingManager: !domFiPerp');
        if (lastUpdateTimes[_productId] == 0) {
            lastUpdateTimes[_productId] = uint64(block.timestamp);
            return;
        }

        FixedPoint.Signed fundingRate = getFundingRate(_productId);
        FixedPoint.Signed fundingChange = fundingRate
            .mul(uint64(block.timestamp) - lastUpdateTimes[_productId])
            .div(int(365 days));

        cumulativeFundings[_productId] = cumulativeFundings[_productId].add(fundingChange);

        lastUpdateTimes[_productId] = uint64(block.timestamp);
        emit FundingUpdated(_productId, fundingRate, fundingChange, cumulativeFundings[_productId]);
    }

    /** @notice get funding rate for the given product
        @param _productId product to get funding rate for
        @return fundingRate % per year charged for long and paid to short orders
     */
    function getFundingRate(bytes32 _productId) public view override returns (FixedPoint.Signed fundingRate) {
        IDomFiPerp.Product memory product = domFiPerp.getProduct(_productId);
        FixedPoint.Unsigned maxExposure = domFiPerp.getMaxExposure(product.weight);
        FixedPoint.Unsigned fundingMultiplier = FixedPoint.max(fundingMultipliers[_productId], minFundingMultiplier);

        return
            FixedPoint.min(
                FixedPoint.fromUnsigned(maxFundingRate), // TODO: fix this lol
                FixedPoint
                    .fromUnsigned(product.openInterestLong)
                    .sub(product.openInterestShort)
                    .mul(fundingMultiplier)
                    .div(maxExposure)
            );
    }

    function getFunding(bytes32 _productId) external view override returns (FixedPoint.Signed) {
        return cumulativeFundings[_productId];
    }

    function setDomFiPerp(IDomFiPerp _domFiPerp) external onlyOwner {
        domFiPerp = _domFiPerp;
        emit DomFiPerpSet(_domFiPerp);
    }

    function setMinFundingMultiplier(FixedPoint.Unsigned _minFundingMultiplier) external onlyOwner {
        minFundingMultiplier = _minFundingMultiplier;
        emit MinFundingMultiplierSet(_minFundingMultiplier);
    }

    function setFundingMultiplier(bytes32 _productId, FixedPoint.Unsigned _fundingMultiplier) external onlyOwner {
        fundingMultipliers[_productId] = _fundingMultiplier;
        emit FundingMultiplierSet(_productId, _fundingMultiplier);
    }

    function setMaxFundingRate(FixedPoint.Unsigned _maxFundingRate) external onlyOwner {
        maxFundingRate = _maxFundingRate;
        emit MaxFundingRateSet(_maxFundingRate);
    }

    function setOwner(address _owner) external onlyGov {
        owner = _owner;
        emit UpdateOwner(_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'FundingManager: !owner');
        _;
    }
}