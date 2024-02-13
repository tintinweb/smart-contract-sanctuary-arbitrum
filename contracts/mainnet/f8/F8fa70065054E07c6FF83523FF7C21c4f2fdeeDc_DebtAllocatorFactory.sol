/**
 *Submitted for verification at Arbiscan.io on 2024-02-08
*/

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.18;

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

interface IVault is IERC4626 {
    // STRATEGY EVENTS
    event StrategyChanged(address indexed strategy, uint256 change_type);
    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 current_debt,
        uint256 protocol_fees,
        uint256 total_fees,
        uint256 total_refunds
    );
    // DEBT MANAGEMENT EVENTS
    event DebtUpdated(
        address indexed strategy,
        uint256 current_debt,
        uint256 new_debt
    );
    // ROLE UPDATES
    event RoleSet(address indexed account, uint256 role);
    event RoleStatusChanged(uint256 role, uint256 status);
    event UpdateRoleManager(address indexed role_manager);

    event UpdateAccountant(address indexed accountant);
    event UpdateDefaultQueue(address[] new_default_queue);
    event UpdateUseDefaultQueue(bool use_default_queue);
    event UpdatedMaxDebtForStrategy(
        address indexed sender,
        address indexed strategy,
        uint256 new_debt
    );
    event UpdateDepositLimit(uint256 deposit_limit);
    event UpdateMinimumTotalIdle(uint256 minimum_total_idle);
    event UpdateProfitMaxUnlockTime(uint256 profit_max_unlock_time);
    event DebtPurchased(address indexed strategy, uint256 amount);
    event Shutdown();

    struct StrategyParams {
        uint256 activation;
        uint256 last_report;
        uint256 current_debt;
        uint256 max_debt;
    }

    function FACTORY() external view returns (uint256);

    function strategies(address) external view returns (StrategyParams memory);

    function default_queue(uint256) external view returns (address);

    function use_default_queue() external view returns (bool);

    function total_supply() external view returns (uint256);

    function minimum_total_idle() external view returns (uint256);

    function deposit_limit() external view returns (uint256);

    function deposit_limit_module() external view returns (address);

    function withdraw_limit_module() external view returns (address);

    function accountant() external view returns (address);

    function roles(address) external view returns (uint256);

    function open_roles(uint256) external view returns (bool);

    function role_manager() external view returns (address);

    function future_role_manager() external view returns (address);

    function isShutdown() external view returns (bool);

    function nonces(address) external view returns (uint256);

    function set_accountant(address new_accountant) external;

    function set_default_queue(address[] memory new_default_queue) external;

    function set_use_default_queue(bool) external;

    function set_deposit_limit(uint256 deposit_limit) external;

    function set_deposit_limit_module(
        address new_deposit_limit_module
    ) external;

    function set_withdraw_limit_module(
        address new_withdraw_limit_module
    ) external;

    function set_minimum_total_idle(uint256 minimum_total_idle) external;

    function setProfitMaxUnlockTime(
        uint256 new_profit_max_unlock_time
    ) external;

    function set_role(address account, uint256 role) external;

    function add_role(address account, uint256 role) external;

    function remove_role(address account, uint256 role) external;

    function set_open_role(uint256 role) external;

    function close_open_role(uint256 role) external;

    function transfer_role_manager(address role_manager) external;

    function accept_role_manager() external;

    function unlockedShares() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function get_default_queue() external view returns (address[] memory);

    function process_report(
        address strategy
    ) external returns (uint256, uint256);

    function buy_debt(address strategy, uint256 amount) external;

    function add_strategy(address new_strategy) external;

    function revoke_strategy(address strategy) external;

    function force_revoke_strategy(address strategy) external;

    function update_max_debt_for_strategy(
        address strategy,
        uint256 new_max_debt
    ) external;

    function update_debt(
        address strategy,
        uint256 target_debt
    ) external returns (uint256);

    function shutdown_vault() external;

    function totalIdle() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function apiVersion() external view returns (string memory);

    function assess_share_of_unrealised_losses(
        address strategy,
        uint256 assets_needed
    ) external view returns (uint256);

    function profitMaxUnlockTime() external view returns (uint256);

    function fullProfitUnlockDate() external view returns (uint256);

    function profitUnlockingRate() external view returns (uint256);

    function lastProfitUpdate() external view returns (uint256);

    //// NON-STANDARD ERC-4626 FUNCTIONS \\\\

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 max_loss
    ) external returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 max_loss,
        address[] memory strategies
    ) external returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 max_loss
    ) external returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 max_loss,
        address[] memory strategies
    ) external returns (uint256);

    function maxWithdraw(
        address owner,
        uint256 max_loss
    ) external view returns (uint256);

    function maxWithdraw(
        address owner,
        uint256 max_loss,
        address[] memory strategies
    ) external view returns (uint256);

    function maxRedeem(
        address owner,
        uint256 max_loss
    ) external view returns (uint256);

    function maxRedeem(
        address owner,
        uint256 max_loss,
        address[] memory strategies
    ) external view returns (uint256);

    //// NON-STANDARD ERC-20 FUNCTIONS \\\\

    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);
}

/**
 * @title YearnV3 Debt Allocator
 * @author yearn.finance
 * @notice
 *  This Debt Allocator is meant to be used alongside
 *  a Yearn V3 vault to provide the needed triggers for a keeper
 *  to perform automated debt updates for the vaults strategies.
 *
 *  Each allocator contract will serve one Vault and each strategy
 *  that should be managed by this allocator will need to be added
 *  manually by setting a `targetRatio` and `maxRatio`.
 *
 *  The allocator aims to allocate debt between the strategies
 *  based on their set target ratios. Which are denominated in basis
 *  points and represent the percent of total assets that specific
 *  strategy should hold.
 *
 *  The trigger will attempt to allocate up to the `maxRatio` when
 *  the strategy has `minimumChange` amount less than the `targetRatio`.
 *  And will pull funds from the strategy when it has `minimumChange`
 *  more than its `maxRatio`.
 */
contract DebtAllocator {
    /// @notice An event emitted when a strategies debt ratios are Updated.
    event UpdateStrategyDebtRatio(
        address indexed strategy,
        uint256 newTargetRatio,
        uint256 newMaxRatio,
        uint256 newTotalDebtRatio
    );

    /// @notice An event emitted when a strategy is added or removed.
    event StrategyChanged(address indexed strategy, Status status);

    /// @notice An event emitted when the minimum time to wait is updated.
    event UpdateMinimumWait(uint256 newMinimumWait);

    /// @notice An event emitted when the minimum change is updated.
    event UpdateMinimumChange(uint256 newMinimumChange);

    /// @notice An event emitted when a keeper is added or removed.
    event UpdateManager(address indexed manager, bool allowed);

    /// @notice An event emitted when the max debt update loss is updated.
    event UpdateMaxDebtUpdateLoss(uint256 newMaxDebtUpdateLoss);

    /// @notice Status when a strategy is added or removed from the allocator.
    enum Status {
        NULL,
        ADDED,
        REMOVED
    }

    /// @notice Struct for each strategies info.
    struct Config {
        // Flag to set when a strategy is added.
        bool added;
        // The ideal percent in Basis Points the strategy should have.
        uint16 targetRatio;
        // The max percent of assets the strategy should hold.
        uint16 maxRatio;
        // Timestamp of the last time debt was updated.
        // The debt updates must be done through this allocator
        // for this to be used.
        uint96 lastUpdate;
        // We have an extra 120 bits in the slot.
        // So we declare the variable in the struct so it can be
        // used if this contract is inherited.
        uint120 open;
    }

    /// @notice Make sure the caller is governance.
    modifier onlyGovernance() {
        _isGovernance();
        _;
    }

    /// @notice Make sure the caller is governance or a manager.
    modifier onlyManagers() {
        _isManager();
        _;
    }

    /// @notice Make sure the caller is a keeper
    modifier onlyKeepers() {
        _isKeeper();
        _;
    }

    /// @notice Check the Factories governance address.
    function _isGovernance() internal view virtual {
        require(
            msg.sender == DebtAllocatorFactory(factory).governance(),
            "!governance"
        );
    }

    /// @notice Check is either factories governance or local manager.
    function _isManager() internal view virtual {
        require(
            managers[msg.sender] ||
                msg.sender == DebtAllocatorFactory(factory).governance(),
            "!manager"
        );
    }

    /// @notice Check is one of the allowed keepers.
    function _isKeeper() internal view virtual {
        require(DebtAllocatorFactory(factory).keepers(msg.sender), "!keeper");
    }

    uint256 internal constant MAX_BPS = 10_000;

    /// @notice Address to get permissioned roles from.
    address public immutable factory;

    /// @notice Address of the vault this serves as allocator for.
    address public vault;

    /// @notice Time to wait between debt updates in seconds.
    uint256 public minimumWait;

    /// @notice The minimum amount denominated in asset that will
    // need to be moved to trigger a debt update.
    uint256 public minimumChange;

    /// @notice Total debt ratio currently allocated in basis points.
    // Can't be more than 10_000.
    uint256 public totalDebtRatio;

    /// @notice Max loss to accept on debt updates in basis points.
    uint256 public maxDebtUpdateLoss;

    /// @notice Mapping of addresses that are allowed to update debt ratios.
    mapping(address => bool) public managers;

    /// @notice Mapping of strategy => its config.
    mapping(address => Config) internal _configs;

    constructor(address _vault, uint256 _minimumChange) {
        // Set the factory to retrieve roles from. Will be the same for all clones so can use immutable.
        factory = msg.sender;

        // Initialize original version.
        initialize(_vault, _minimumChange);
    }

    /**
     * @notice Initializes the debt allocator.
     * @dev Should be called atomically after cloning.
     * @param _vault Address of the vault this allocates debt for.
     * @param _minimumChange The minimum in asset that must be moved.
     */
    function initialize(address _vault, uint256 _minimumChange) public virtual {
        require(address(vault) == address(0), "!initialized");

        // Set initial variables.
        vault = _vault;
        minimumChange = _minimumChange;

        // Default max loss on debt updates to 1 BP.
        maxDebtUpdateLoss = 1;
    }

    /**
     * @notice Debt update wrapper for the vault.
     * @dev This can be used if a minimum time between debt updates
     *   is desired to be used for the trigger and to enforce a max loss.
     *
     *   This contract must have the DEBT_MANAGER role assigned to them.
     *
     *   The function signature matches the vault so no update to the
     *   call data is required.
     *
     *   This will also run checks on losses realized during debt
     *   updates to assure decreases did not realize profits outside
     *   of the allowed range.
     */
    function update_debt(
        address _strategy,
        uint256 _targetDebt
    ) public virtual onlyKeepers {
        IVault _vault = IVault(vault);

        // If going to 0 record full balance first.
        if (_targetDebt == 0) {
            _vault.process_report(_strategy);
        }

        // Cache initial values in case of loss.
        uint256 initialDebt = _vault.strategies(_strategy).current_debt;
        uint256 initialAssets = _vault.totalAssets();
        _vault.update_debt(_strategy, _targetDebt);
        uint256 afterAssets = _vault.totalAssets();

        // If a loss was realized.
        if (afterAssets < initialAssets) {
            // Make sure its within the range.
            require(
                initialAssets - afterAssets <=
                    (initialDebt * maxDebtUpdateLoss) / MAX_BPS,
                "too much loss"
            );
        }

        // Update the last time the strategies debt was updated.
        _configs[_strategy].lastUpdate = uint96(block.timestamp);
    }

    /**
     * @notice Check if a strategy's debt should be updated.
     * @dev This should be called by a keeper to decide if a strategies
     * debt should be updated and if so by how much.
     *
     * @param _strategy Address of the strategy to check.
     * @return . Bool representing if the debt should be updated.
     * @return . Calldata if `true` or reason if `false`.
     */
    function shouldUpdateDebt(
        address _strategy
    ) public view virtual returns (bool, bytes memory) {
        // Get the strategy specific debt config.
        Config memory config = getConfig(_strategy);

        // Make sure the strategy has been added to the allocator.
        if (!config.added) return (false, bytes("!added"));

        // Check the base fee isn't too high.
        if (!DebtAllocatorFactory(factory).isCurrentBaseFeeAcceptable()) {
            return (false, bytes("Base Fee"));
        }

        // Cache the vault variable.
        IVault _vault = IVault(vault);
        // Retrieve the strategy specific parameters.
        IVault.StrategyParams memory params = _vault.strategies(_strategy);
        // Make sure its an active strategy.
        require(params.activation != 0, "!active");

        if (block.timestamp - config.lastUpdate <= minimumWait) {
            return (false, bytes("min wait"));
        }

        uint256 vaultAssets = _vault.totalAssets();

        // Get the target debt for the strategy based on vault assets.
        uint256 targetDebt = Math.min(
            (vaultAssets * config.targetRatio) / MAX_BPS,
            // Make sure it is not more than the max allowed.
            params.max_debt
        );

        // Get the max debt we would want the strategy to have.
        uint256 maxDebt = Math.min(
            (vaultAssets * config.maxRatio) / MAX_BPS,
            // Make sure it is not more than the max allowed.
            params.max_debt
        );

        // If we need to add more.
        if (targetDebt > params.current_debt) {
            uint256 currentIdle = _vault.totalIdle();
            uint256 minIdle = _vault.minimum_total_idle();

            // We can't add more than the available idle.
            if (minIdle >= currentIdle) {
                return (false, bytes("No Idle"));
            }

            // Add up to the max if possible
            uint256 toAdd = Math.min(
                maxDebt - params.current_debt,
                // Can't take more than is available.
                Math.min(
                    currentIdle - minIdle,
                    IVault(_strategy).maxDeposit(vault)
                )
            );

            // If the amount to add is over our threshold.
            if (toAdd > minimumChange) {
                // Return true and the calldata.
                return (
                    true,
                    abi.encodeCall(
                        _vault.update_debt,
                        (_strategy, params.current_debt + toAdd)
                    )
                );
            }
            // If current debt is greater than our max.
        } else if (maxDebt < params.current_debt) {
            uint256 toPull = params.current_debt - targetDebt;

            uint256 currentIdle = _vault.totalIdle();
            uint256 minIdle = _vault.minimum_total_idle();
            if (minIdle > currentIdle) {
                // Pull at least the amount needed for minIdle.
                toPull = Math.max(toPull, minIdle - currentIdle);
            }

            // Find out by how much. Aim for the target.
            toPull = Math.min(
                toPull,
                // Account for the current liquidity constraints.
                // Use max redeem to match vault logic.
                IVault(_strategy).convertToAssets(
                    IVault(_strategy).maxRedeem(address(_vault))
                )
            );

            // Check if it's over the threshold.
            if (toPull > minimumChange) {
                // Can't lower debt if there are unrealised losses.
                if (
                    _vault.assess_share_of_unrealised_losses(
                        _strategy,
                        params.current_debt
                    ) != 0
                ) {
                    return (false, bytes("unrealised loss"));
                }

                // If so return true and the calldata.
                return (
                    true,
                    abi.encodeCall(
                        _vault.update_debt,
                        (_strategy, params.current_debt - toPull)
                    )
                );
            }
        }

        // Either no change or below our minimumChange.
        return (false, bytes("Below Min"));
    }

    /**
     * @notice Increase a strategies target debt ratio.
     * @dev `setStrategyDebtRatio` functions will do all needed checks.
     * @param _strategy The address of the strategy to increase the debt ratio for.
     * @param _increase The amount in Basis Points to increase it.
     */
    function increaseStrategyDebtRatio(
        address _strategy,
        uint256 _increase
    ) external virtual {
        uint256 _currentRatio = getConfig(_strategy).targetRatio;
        setStrategyDebtRatio(_strategy, _currentRatio + _increase);
    }

    /**
     * @notice Decrease a strategies target debt ratio.
     * @param _strategy The address of the strategy to decrease the debt ratio for.
     * @param _decrease The amount in Basis Points to decrease it.
     */
    function decreaseStrategyDebtRatio(
        address _strategy,
        uint256 _decrease
    ) external virtual {
        uint256 _currentRatio = getConfig(_strategy).targetRatio;
        setStrategyDebtRatio(_strategy, _currentRatio - _decrease);
    }

    /**
     * @notice Sets a new target debt ratio for a strategy.
     * @dev This will default to a 20% increase for max debt.
     *
     * @param _strategy Address of the strategy to set.
     * @param _targetRatio Amount in Basis points to allocate.
     */
    function setStrategyDebtRatio(
        address _strategy,
        uint256 _targetRatio
    ) public virtual {
        uint256 maxRatio = Math.min((_targetRatio * 12_000) / MAX_BPS, MAX_BPS);
        setStrategyDebtRatio(_strategy, _targetRatio, maxRatio);
    }

    /**
     * @notice Sets a new target debt ratio for a strategy.
     * @dev A `minimumChange` for that strategy must be set first.
     * This is to prevent debt from being updated too frequently.
     *
     * @param _strategy Address of the strategy to set.
     * @param _targetRatio Amount in Basis points to allocate.
     * @param _maxRatio Max ratio to give on debt increases.
     */
    function setStrategyDebtRatio(
        address _strategy,
        uint256 _targetRatio,
        uint256 _maxRatio
    ) public virtual onlyManagers {
        // Make sure a minimumChange has been set.
        require(minimumChange != 0, "!minimum");
        // Cannot be more than 100%.
        require(_maxRatio <= MAX_BPS, "max too high");
        // Max cannot be lower than the target.
        require(_maxRatio >= _targetRatio, "max ratio");

        // Get the current config.
        Config memory config = getConfig(_strategy);

        // Set added flag if not set yet.
        if (!config.added) {
            config.added = true;
            emit StrategyChanged(_strategy, Status.ADDED);
        }

        // Get what will be the new total debt ratio.
        uint256 newTotalDebtRatio = totalDebtRatio -
            config.targetRatio +
            _targetRatio;

        // Make sure it is under 100% allocated
        require(newTotalDebtRatio <= MAX_BPS, "ratio too high");

        // Update local config.
        config.targetRatio = uint16(_targetRatio);
        config.maxRatio = uint16(_maxRatio);

        // Write to storage.
        _configs[_strategy] = config;
        totalDebtRatio = newTotalDebtRatio;

        emit UpdateStrategyDebtRatio(
            _strategy,
            _targetRatio,
            _maxRatio,
            newTotalDebtRatio
        );
    }

    /**
     * @notice Remove a strategy from this debt allocator.
     * @dev Will delete the full config for the strategy
     * @param _strategy Address of the address ro remove.
     */
    function removeStrategy(address _strategy) external virtual onlyManagers {
        Config memory config = getConfig(_strategy);
        require(config.added, "!added");

        uint256 target = config.targetRatio;

        // Remove any debt ratio the strategy holds.
        if (target != 0) {
            totalDebtRatio -= target;
            emit UpdateStrategyDebtRatio(_strategy, 0, 0, totalDebtRatio);
        }

        // Remove the full config including the `added` flag.
        delete _configs[_strategy];

        // Emit Event.
        emit StrategyChanged(_strategy, Status.REMOVED);
    }

    /**
     * @notice Set the minimum change variable for a strategy.
     * @dev This is the minimum amount of debt to be
     * added or pulled for it to trigger an update.
     *
     * @param _minimumChange The new minimum to set for the strategy.
     */
    function setMinimumChange(
        uint256 _minimumChange
    ) external virtual onlyGovernance {
        require(_minimumChange > 0, "zero");
        // Set the new minimum.
        minimumChange = _minimumChange;

        emit UpdateMinimumChange(_minimumChange);
    }

    /**
     * @notice Set the max loss in Basis points to allow on debt updates.
     * @dev Withdrawing during debt updates use {redeem} which allows for 100% loss.
     *      This can be used to assure a loss is not realized on redeem outside the tolerance.
     * @param _maxDebtUpdateLoss The max loss to accept on debt updates.
     */
    function setMaxDebtUpdateLoss(
        uint256 _maxDebtUpdateLoss
    ) external virtual onlyGovernance {
        require(_maxDebtUpdateLoss <= MAX_BPS, "higher than max");
        maxDebtUpdateLoss = _maxDebtUpdateLoss;

        emit UpdateMaxDebtUpdateLoss(_maxDebtUpdateLoss);
    }

    /**
     * @notice Set the minimum time to wait before re-updating a strategies debt.
     * @dev This is only enforced per strategy.
     * @param _minimumWait The minimum time in seconds to wait.
     */
    function setMinimumWait(
        uint256 _minimumWait
    ) external virtual onlyGovernance {
        minimumWait = _minimumWait;

        emit UpdateMinimumWait(_minimumWait);
    }

    /**
     * @notice Set if a manager can update ratios.
     * @param _address The address to set mapping for.
     * @param _allowed If the address can call {update_debt}.
     */
    function setManager(
        address _address,
        bool _allowed
    ) external virtual onlyGovernance {
        managers[_address] = _allowed;

        emit UpdateManager(_address, _allowed);
    }

    /**
     * @notice Get a strategies full config.
     * @dev Used for customizations by inheriting the contract.
     * @param _strategy Address of the strategy.
     * @return The strategies current Config.
     */
    function getConfig(
        address _strategy
    ) public view virtual returns (Config memory) {
        return _configs[_strategy];
    }

    /**
     * @notice Get a strategies target debt ratio.
     * @param _strategy Address of the strategy.
     * @return The strategies current targetRatio.
     */
    function getStrategyTargetRatio(
        address _strategy
    ) external view virtual returns (uint256) {
        return getConfig(_strategy).targetRatio;
    }

    /**
     * @notice Get a strategies max debt ratio.
     * @param _strategy Address of the strategy.
     * @return The strategies current maxRatio.
     */
    function getStrategyMaxRatio(
        address _strategy
    ) external view virtual returns (uint256) {
        return getConfig(_strategy).maxRatio;
    }
}

contract Clonable {
    /// @notice Set to the address to auto clone from.
    address public original;

    /**
     * @notice Clone the contracts default `original` contract.
     * @return Address of the new Minimal Proxy clone.
     */
    function _clone() internal virtual returns (address) {
        return _clone(original);
    }

    /**
     * @notice Clone any `_original` contract.
     * @return _newContract Address of the new Minimal Proxy clone.
     */
    function _clone(
        address _original
    ) internal virtual returns (address _newContract) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(_original);
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            _newContract := create(0, clone_code, 0x37)
        }
    }
}

contract Governance {
    /// @notice Emitted when the governance address is updated.
    event GovernanceTransferred(
        address indexed previousGovernance,
        address indexed newGovernance
    );

    modifier onlyGovernance() {
        _checkGovernance();
        _;
    }

    /// @notice Checks if the msg sender is the governance.
    function _checkGovernance() internal view virtual {
        require(governance == msg.sender, "!governance");
    }

    /// @notice Address that can set the default base fee and provider
    address public governance;

    constructor(address _governance) {
        governance = _governance;

        emit GovernanceTransferred(address(0), _governance);
    }

    /**
     * @notice Sets a new address as the governance of the contract.
     * @dev Throws if the caller is not current governance.
     * @param _newGovernance The new governance address.
     */
    function transferGovernance(
        address _newGovernance
    ) external virtual onlyGovernance {
        require(_newGovernance != address(0), "ZERO ADDRESS");
        address oldGovernance = governance;
        governance = _newGovernance;

        emit GovernanceTransferred(oldGovernance, _newGovernance);
    }
}

/**
 * @title YearnV3  Debt Allocator Factory
 * @author yearn.finance
 * @notice
 *  Factory to deploy a debt allocator for a YearnV3 vault.
 */
contract DebtAllocatorFactory is Governance, Clonable {
    /// @notice Revert message for when a debt allocator already exists.
    error AlreadyDeployed(address _allocator);

    /// @notice An event emitted when a keeper is added or removed.
    event UpdateKeeper(address indexed keeper, bool allowed);

    /// @notice An event emitted when the max base fee is updated.
    event UpdateMaxAcceptableBaseFee(uint256 newMaxAcceptableBaseFee);

    /// @notice An event emitted when a new debt allocator is added or deployed.
    event NewDebtAllocator(address indexed allocator, address indexed vault);

    /// @notice Max the chains base fee can be during debt update.
    // Will default to max uint256 and need to be set to be used.
    uint256 public maxAcceptableBaseFee;

    /// @notice Mapping of addresses that are allowed to update debt.
    mapping(address => bool) public keepers;

    constructor(address _governance) Governance(_governance) {
        // Deploy a dummy allocator as the original.
        original = address(new DebtAllocator(address(1), 0));

        // Default max base fee to uint max.
        maxAcceptableBaseFee = type(uint256).max;

        // Default to allow governance to be a keeper.
        keepers[_governance] = true;
        emit UpdateKeeper(_governance, true);
    }

    /**
     * @notice Clones a new debt allocator.
     * @dev defaults to msg.sender as the governance role and 0
     *  for the `minimumChange`.
     *
     * @param _vault The vault for the allocator to be hooked to.
     * @return Address of the new debt allocator
     */
    function newDebtAllocator(
        address _vault
    ) external virtual returns (address) {
        return newDebtAllocator(_vault, 0);
    }

    /**
     * @notice Clones a new debt allocator.
     * @param _vault The vault for the allocator to be hooked to.
     * @param _minimumChange The minimum amount needed to trigger debt update.
     * @return newAllocator Address of the new debt allocator
     */
    function newDebtAllocator(
        address _vault,
        uint256 _minimumChange
    ) public virtual returns (address newAllocator) {
        // Clone new allocator off the original.
        newAllocator = _clone();

        // Initialize the new allocator.
        DebtAllocator(newAllocator).initialize(_vault, _minimumChange);

        // Emit event.
        emit NewDebtAllocator(newAllocator, _vault);
    }

    /**
     * @notice Set the max acceptable base fee.
     * @dev This defaults to max uint256 and will need to
     * be set for it to be used.
     *
     * Is denominated in gwei. So 50gwei would be set as 50e9.
     *
     * @param _maxAcceptableBaseFee The new max base fee.
     */
    function setMaxAcceptableBaseFee(
        uint256 _maxAcceptableBaseFee
    ) external virtual onlyGovernance {
        maxAcceptableBaseFee = _maxAcceptableBaseFee;

        emit UpdateMaxAcceptableBaseFee(_maxAcceptableBaseFee);
    }

    /**
     * @notice Set if a keeper can update debt.
     * @param _address The address to set mapping for.
     * @param _allowed If the address can call {update_debt}.
     */
    function setKeeper(
        address _address,
        bool _allowed
    ) external virtual onlyGovernance {
        keepers[_address] = _allowed;

        emit UpdateKeeper(_address, _allowed);
    }

    /**
     * @notice Returns wether or not the current base fee is acceptable
     *   based on the `maxAcceptableBaseFee`.
     * @return . If the current base fee is acceptable.
     */
    function isCurrentBaseFeeAcceptable() external view virtual returns (bool) {
        return maxAcceptableBaseFee >= block.basefee;
    }
}