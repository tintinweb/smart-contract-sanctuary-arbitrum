// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";
import { GmxStorageGetters } from "./GmxStorageGetters.sol";
import { GmxMarketGetters } from "./GmxMarketGetters.sol";
import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";
import { IGmxV2DataStore } from "../interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2OrderTypes
} from "../../../lib/gmx/interfaces/external/IGmxV2OrderTypes.sol";
import {
    PositionStoreUtils
} from "../../../lib/gmx/position/PositionStoreUtils.sol";
import { Pricing } from "./Pricing.sol";
import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import { IMarketConfiguration } from "../interfaces/IMarketConfiguration.sol";
import { Constants } from "../../../libraries/Constants.sol";
import { PercentMath } from "../../../libraries/PercentMath.sol";
import { OrderStoreUtils } from "../../../lib/gmx/order/OrderStoreUtils.sol";
import { GmxFrfStrategyErrors } from "../GmxFrfStrategyErrors.sol";
import { OrderValidation } from "./OrderValidation.sol";
import {
    IGmxFrfStrategyAccount
} from "../interfaces/IGmxFrfStrategyAccount.sol";
import { DeltaConvergenceMath } from "./DeltaConvergenceMath.sol";

/**
 * @title ClaimLogic
 * @author GoldLink
 *
 * @dev Logic for handling collateral and funding fee claims for a given account.
 */
library ClaimLogic {
    // ============ External Functions ============

    /**
     * @notice Claims collateral in a given market in the event a collateral stipend is issued to an account. When collateral is locked in a claim due to high price impact,
     * the GMX team reviews the case and determines whether or not collateral can be claimed based on if the cause of the price impact was malicious or not. If collateral is locked in a claim,
     * it is impossible to determine its value until the GMX team decides on the refund, which can take up to 14 days. As a result, an account that causes a collateral claim can be liquidated due to
     * this loss in value. To account for this, the timestamp of the most recent liquidation is recorded for an account. If, when providing the `timeKey` for the collateral claim, the timestamp
     * of the claim falls before the most recent liquidation, then the claimed funds are sent to the Goldlink claims distribution account to properly distribute the funds.
     * This logic is in place to ensure that if collateral is locked in a claim, resulting in an account liquidation, the borrower cannot later claim these assets. Collateral
     * claims should rarely occur due to Goldlink's maximum slippage configuration, but are still possible in the event GMX changes the maximum price impact threshold.
     */
    function claimCollateral(
        IGmxFrfStrategyManager manager,
        address market,
        address asset,
        uint256 timeKey,
        uint256 lastLiquidationTimestamp
    ) external {
        uint256 divisor = GmxStorageGetters.getClaimableCollateralTimeDivisor(
            manager.gmxV2DataStore()
        );
        // This is the floored timestamp of when collateral lock-up occurred due to excessive price impact.
        // Due to the underestimate, it is possible (but extremely unlikely) that collateral could erroneously
        // be allocated to the distributor account, when it should have been allocated to the strategy account.
        uint256 initialClaimTimestamp = timeKey * divisor;

        address recipient = address(this);

        if (initialClaimTimestamp <= lastLiquidationTimestamp) {
            recipient = manager.COLLATERAL_CLAIM_DISTRIBUTOR();
        }

        address[] memory markets = new address[](1);
        address[] memory assets = new address[](1);
        uint256[] memory timeKeys = new uint256[](1);

        markets[0] = market;
        assets[0] = asset;
        timeKeys[0] = timeKey;

        // This function will transfer the claimable collateral to the reciever in the event that claimable collateral exists for the given (market, asset, timekey).
        // The function will revert if no such collateral exists.
        manager.gmxV2ExchangeRouter().claimCollateral(
            markets,
            assets,
            timeKeys,
            recipient
        );
    }

    /**
     * @notice Helper method to claim funding fees in a specified market. Claims both long and short funding fees.
     * This method does not impact `unsettled` funding fees.
     * @param manager The configuration manager for the strategy.
     * @param market  The market to claim fees in.
     */
    function claimFundingFeesInMarket(
        IGmxFrfStrategyManager manager,
        address market
    ) external {
        (address shortToken, address longToken) = GmxMarketGetters
            .getMarketTokens(manager.gmxV2DataStore(), market);

        address[] memory markets = new address[](2);
        address[] memory assets = new address[](2);

        markets[0] = market;
        markets[1] = market;

        assets[0] = shortToken;
        assets[1] = longToken;

        claimFundingFees(manager, markets, assets);
    }

    // ============ Public Functions ============

    /**
     * @notice Claim funding fees in all markets for an account.
     * @param manager         The configuration manager for the strategy.
     * @param markets         List of markets to claim funding fees in. Must be in the same order as `tokens`.
     * @param tokens          List of tokens to claim funding fees in. Must be in the same order as `markets`.
     * @return claimedAmounts The amounts of funding fees claimed in each market and for each token, aligned with the indicies of the original input arrays.
     */
    function claimFundingFees(
        IGmxFrfStrategyManager manager,
        address[] memory markets,
        address[] memory tokens
    ) public returns (uint256[] memory claimedAmounts) {
        return
            manager.gmxV2ExchangeRouter().claimFundingFees(
                markets,
                tokens,
                address(this)
            );
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IMarketConfiguration } from "./IMarketConfiguration.sol";
import { IDeploymentConfiguration } from "./IDeploymentConfiguration.sol";
import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";

/**
 * @title IGmxFrfStrategyManager
 * @author GoldLink
 *
 * @dev Interface for manager contract for configuration vars.
 */
interface IGmxFrfStrategyManager is
    IMarketConfiguration,
    IDeploymentConfiguration,
    IChainlinkAdapter
{}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Keys } from "../../../lib/gmx/keys/Keys.sol";
import { IGmxV2DataStore } from "../interfaces/gmx/IGmxV2DataStore.sol";

/**
 * @title GmxStorageGetters
 * @author GoldLink
 *
 * @dev Library for getting values directly from Gmx's `datastore` contract.
 */
library GmxStorageGetters {
    // ============ Internal Functions ============

    /**
     * @notice Get claimable collateral time divisor.
     * @param dataStore                       The data store the time divisor in in.
     * @return claimableCollateralTimeDivisor The time divisor for calculating the initial claim timestamp.
     */
    function getClaimableCollateralTimeDivisor(
        IGmxV2DataStore dataStore
    ) internal view returns (uint256 claimableCollateralTimeDivisor) {
        return dataStore.getUint(Keys.CLAIMABLE_COLLATERAL_TIME_DIVISOR);
    }

    /**
     * @notice Get account claimable collateral.
     * @param dataStore            The data store the claimable collateral is registered in.
     * @param market               The market the claimable collateral is for.
     * @param token                The token associated with the account's claimable collateral.
     * @param timeKey              The time key for the claimable collateral.
     * @param account              The account that has claimable collateral.
     * @return claimableCollateral The claimable collateral an account has for a market.
     */
    function getAccountClaimableCollateral(
        IGmxV2DataStore dataStore,
        address market,
        address token,
        uint256 timeKey,
        address account
    ) internal view returns (uint256 claimableCollateral) {
        bytes32 key = Keys.claimableCollateralAmountKey(
            market,
            token,
            timeKey,
            account
        );

        return dataStore.getUint(key);
    }

    /**
     * @notice Get claimable funding fees.
     * @param token                 The token associated with the account's claimable funding fees.
     * @param market                The market the claimable funding fees are for.
     * @param account               The account that has claimable funding fees.
     * @return claimableFundingFees The claimable funding fees an account has for a market.
     */
    function getClaimableFundingFees(
        IGmxV2DataStore dataStore,
        address market,
        address token,
        address account
    ) internal view returns (uint256 claimableFundingFees) {
        bytes32 key = Keys.claimableFundingAmountKey(market, token, account);

        return dataStore.getUint(key);
    }

    /**
     * @notice Get saved callback contract an account has for a market.
     * @param dataStore              The data store the saved callback contractl is in.
     * @param market                 The market the saved callback contract is for.
     * @param account                The account that has the saved callback contract.
     * @return savedCallbackContract The address of the saved callback contract.
     */
    function getSavedCallbackContract(
        IGmxV2DataStore dataStore,
        address account,
        address market
    ) internal view returns (address savedCallbackContract) {
        bytes32 key = Keys.savedCallbackContract(account, market);

        return dataStore.getAddress(key);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2DataStore } from "../interfaces/gmx/IGmxV2DataStore.sol";
import { IGmxV2MarketTypes } from "../interfaces/gmx/IGmxV2MarketTypes.sol";

/**
 * @title GmxMarketGetters
 * @author GoldLink
 *
 * @dev Library for getting values directly for gmx markets.
 */
library GmxMarketGetters {
    // ============ Constants ============

    bytes32 internal constant MARKET_SALT =
        keccak256(abi.encode("MARKET_SALT"));
    bytes32 internal constant MARKET_KEY = keccak256(abi.encode("MARKET_KEY"));
    bytes32 internal constant MARKET_TOKEN =
        keccak256(abi.encode("MARKET_TOKEN"));
    bytes32 internal constant INDEX_TOKEN =
        keccak256(abi.encode("INDEX_TOKEN"));
    bytes32 internal constant LONG_TOKEN = keccak256(abi.encode("LONG_TOKEN"));
    bytes32 internal constant SHORT_TOKEN =
        keccak256(abi.encode("SHORT_TOKEN"));

    // ============ Internal Functions ============

    /**
     * @notice Get the market token for a given market.
     * @param dataStore    The data store being queried for the market token.
     * @param market       The market whose token is being fetched.
     * @return marketToken The token for the market.
     */
    function getMarketToken(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address marketToken) {
        return
            dataStore.getAddress(keccak256(abi.encode(market, MARKET_TOKEN)));
    }

    /**
     * @notice Get the index token for a given market.
     * @param dataStore   The data store being queried for the index token.
     * @param market      The market whose index token is being fetched.
     * @return indexToken The token for the index for a given market.
     */
    function getIndexToken(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address indexToken) {
        return dataStore.getAddress(keccak256(abi.encode(market, INDEX_TOKEN)));
    }

    /**
     * @notice Get the long token for a given market.
     * @param dataStore  The data store being queried for the long token.
     * @param market     The market whose long token is being fetched.
     * @return longToken The token for the long asset for a given market.
     */
    function getLongToken(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address longToken) {
        return dataStore.getAddress(keccak256(abi.encode(market, LONG_TOKEN)));
    }

    /**
     * @notice Get the short token for a given market.
     * @param dataStore   The data store being queried for the short token.
     * @param market      The market whose short token is being fetched.
     * @return shortToken The token for the short asset for a given market.
     */
    function getShortToken(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address shortToken) {
        return dataStore.getAddress(keccak256(abi.encode(market, SHORT_TOKEN)));
    }

    /**
     * @notice Get the short and long tokens for a given market.
     * @param dataStore   The data store being queried for the short and long tokens.
     * @param market      The market whose short and long tokens are being fetched.
     * @return shortToken The token for the short asset for a given market.
     * @return longToken  The token for the long asset for a given market.
     */
    function getMarketTokens(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address shortToken, address longToken) {
        return (
            getShortToken(dataStore, market),
            getLongToken(dataStore, market)
        );
    }

    /**
     * @notice Get the market information for a given market.
     * @param dataStore The data store being queried for the market information.
     * @param market    The market whose market information is being fetched.
     * @return props    The properties of a specific market.
     */
    function getMarket(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (IGmxV2MarketTypes.Props memory props) {
        return
            IGmxV2MarketTypes.Props(
                getMarketToken(dataStore, market),
                getIndexToken(dataStore, market),
                getLongToken(dataStore, market),
                getShortToken(dataStore, market)
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IChainlinkAggregatorV3 } from "./external/IChainlinkAggregatorV3.sol";

/**
 * @title IChainlinkAdapter
 * @author GoldLink
 *
 * @dev Oracle registry interface for registering and retrieving price feeds for assets using chainlink oracles.
 */
interface IChainlinkAdapter {
    // ============ Structs ============

    /// @dev Struct to hold the configuration for an oracle.
    struct OracleConfiguration {
        // The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
        uint256 validPriceDuration;
        // The address of the chainlink oracle to fetch prices from.
        IChainlinkAggregatorV3 oracle;
    }

    // ============ Events ============

    /// @notice Emitted when registering an oracle for an asset.
    /// @param asset              The address of the asset whose price oracle is beig set.
    /// @param oracle             The address of the price oracle for the asset.
    /// @param validPriceDuration The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
    event AssetOracleRegistered(
        address indexed asset,
        IChainlinkAggregatorV3 indexed oracle,
        uint256 validPriceDuration
    );

    /// @notice Emitted when removing a price oracle for an asset.
    /// @param asset The asset whose price oracle is being removed.
    event AssetOracleRemoved(address indexed asset);

    // ============ External Functions ============

    /// @dev Get the price of an asset.
    function getAssetPrice(
        address asset
    ) external view returns (uint256 price, uint256 oracleDecimals);

    /// @dev Get the oracle registered for a specific asset.
    function getAssetOracle(
        address asset
    ) external view returns (IChainlinkAggregatorV3 oracle);

    /// @dev Get the oracle configuration for a specific asset.
    function getAssetOracleConfiguration(
        address asset
    )
        external
        view
        returns (IChainlinkAggregatorV3 oracle, uint256 validPriceDuration);

    /// @dev Get all assets registered with oracles in this adapter.
    function getRegisteredAssets()
        external
        view
        returns (address[] memory registeredAssets);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IGmxV2DataStore
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's Datastore.
 * Contract this is an interface for can be found here: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/data/DataStore.sol
 */
interface IGmxV2DataStore {
    // ============ External Functions ============

    function getAddress(bytes32 key) external view returns (address);

    function getUint(bytes32 key) external view returns (uint256);

    function getBool(bytes32 key) external view returns (bool);

    function getBytes32Count(bytes32 setKey) external view returns (uint256);

    function getBytes32ValuesAt(
        bytes32 setKey,
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory);

    function containsBytes32(
        bytes32 setKey,
        bytes32 value
    ) external view returns (bool);

    function getAddressArray(
        bytes32 key
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified from: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/order/Order.sol
// Modified as follows:
// - Removed all logic
// - Added additional order structs

pragma solidity ^0.8.0;

interface IGmxV2OrderTypes {
    enum OrderType {
        MarketSwap,
        LimitSwap,
        MarketIncrease,
        LimitIncrease,
        MarketDecrease,
        LimitDecrease,
        StopLossDecrease,
        Liquidation
    }

    enum SecondaryOrderType {
        None,
        Adl
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }

    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Borrowed from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/position/PositionStoreUtils.sol
// Modified as follows:
// - Removed setters
// - added additional getters

pragma solidity ^0.8.0;

import { Keys } from "../keys/Keys.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";

import { Position } from "./Position.sol";
import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";

library PositionStoreUtils {
    using Position for IGmxV2PositionTypes.Props;

    // ============ Constants ============

    bytes32 public constant ACCOUNT = keccak256(abi.encode("ACCOUNT"));
    bytes32 public constant MARKET = keccak256(abi.encode("MARKET"));
    bytes32 public constant COLLATERAL_TOKEN =
        keccak256(abi.encode("COLLATERAL_TOKEN"));

    bytes32 public constant SIZE_IN_USD = keccak256(abi.encode("SIZE_IN_USD"));
    bytes32 public constant SIZE_IN_TOKENS =
        keccak256(abi.encode("SIZE_IN_TOKENS"));
    bytes32 public constant COLLATERAL_AMOUNT =
        keccak256(abi.encode("COLLATERAL_AMOUNT"));
    bytes32 public constant BORROWING_FACTOR =
        keccak256(abi.encode("BORROWING_FACTOR"));
    bytes32 public constant FUNDING_FEE_AMOUNT_PER_SIZE =
        keccak256(abi.encode("FUNDING_FEE_AMOUNT_PER_SIZE"));
    bytes32 public constant LONG_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE =
        keccak256(abi.encode("LONG_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE"));
    bytes32 public constant SHORT_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE =
        keccak256(abi.encode("SHORT_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE"));
    bytes32 public constant INCREASED_AT_BLOCK =
        keccak256(abi.encode("INCREASED_AT_BLOCK"));
    bytes32 public constant DECREASED_AT_BLOCK =
        keccak256(abi.encode("DECREASED_AT_BLOCK"));

    bytes32 public constant IS_LONG = keccak256(abi.encode("IS_LONG"));

    // ============ Internal Functions ============

    function get(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (IGmxV2PositionTypes.Props memory) {
        IGmxV2PositionTypes.Props memory position;
        if (!dataStore.containsBytes32(Keys.POSITION_LIST, key)) {
            return position;
        }

        position.setAccount(
            dataStore.getAddress(keccak256(abi.encode(key, ACCOUNT)))
        );

        position.setMarket(
            dataStore.getAddress(keccak256(abi.encode(key, MARKET)))
        );

        position.setCollateralToken(
            dataStore.getAddress(keccak256(abi.encode(key, COLLATERAL_TOKEN)))
        );

        position.setSizeInUsd(
            dataStore.getUint(keccak256(abi.encode(key, SIZE_IN_USD)))
        );

        position.setSizeInTokens(
            dataStore.getUint(keccak256(abi.encode(key, SIZE_IN_TOKENS)))
        );

        position.setCollateralAmount(
            dataStore.getUint(keccak256(abi.encode(key, COLLATERAL_AMOUNT)))
        );

        position.setBorrowingFactor(
            dataStore.getUint(keccak256(abi.encode(key, BORROWING_FACTOR)))
        );

        position.setFundingFeeAmountPerSize(
            dataStore.getUint(
                keccak256(abi.encode(key, FUNDING_FEE_AMOUNT_PER_SIZE))
            )
        );

        position.setLongTokenClaimableFundingAmountPerSize(
            dataStore.getUint(
                keccak256(
                    abi.encode(
                        key,
                        LONG_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE
                    )
                )
            )
        );

        position.setShortTokenClaimableFundingAmountPerSize(
            dataStore.getUint(
                keccak256(
                    abi.encode(
                        key,
                        SHORT_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE
                    )
                )
            )
        );

        position.setIncreasedAtBlock(
            dataStore.getUint(keccak256(abi.encode(key, INCREASED_AT_BLOCK)))
        );

        position.setDecreasedAtBlock(
            dataStore.getUint(keccak256(abi.encode(key, DECREASED_AT_BLOCK)))
        );

        position.setIsLong(
            dataStore.getBool(keccak256(abi.encode(key, IS_LONG)))
        );

        return position;
    }

    function getPositionCount(
        IGmxV2DataStore dataStore
    ) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.POSITION_LIST);
    }

    function getPositionKeys(
        IGmxV2DataStore dataStore,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        return dataStore.getBytes32ValuesAt(Keys.POSITION_LIST, start, end);
    }

    function getAccountPositionCount(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.accountPositionListKey(account));
    }

    function getAccountPositionKeys(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        return
            dataStore.getBytes32ValuesAt(
                Keys.accountPositionListKey(account),
                start,
                end
            );
    }

    function getAccountPositionKeys(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (bytes32[] memory keys) {
        uint256 positionCount = getAccountPositionCount(dataStore, account);

        return getAccountPositionKeys(dataStore, account, 0, positionCount);
    }

    function getAccountPositions(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (IGmxV2PositionTypes.Props[] memory positions) {
        bytes32[] memory keys = getAccountPositionKeys(dataStore, account);

        positions = new IGmxV2PositionTypes.Props[](keys.length);

        uint256 keysLength = keys.length;
        for (uint256 i = 0; i < keysLength; ++i) {
            positions[i] = get(dataStore, keys[i]);
        }
    }

    function getPositionKey(
        address account,
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        bytes32 key = keccak256(
            abi.encode(account, market, collateralToken, isLong)
        );

        return key;
    }

    function getPositionMarket(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (address) {
        return dataStore.getAddress(keccak256(abi.encode(key, MARKET)));
    }

    function getPositionSizeUsd(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encode(key, SIZE_IN_USD)));
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";

/**
 * @title Pricing
 * @author GoldLink
 *
 * @dev Library for price conversion for getting the GMX price and USDC price.
 * The internal GMX account system uses 30 decimals to represent USD prices per unit of the underlying token.
 * Example from the GMX documentation:
 * The price of ETH is 5000, and ETH has 18 decimals.
 * The price of one unit of ETH is 5000 / (10 ^ 18), 5 * (10 ^ -15).
 * To handle the decimals, multiply the value by (10 ^ 30).
 * Price would be stored as 5000 / (10 ^ 18) * (10 ^ 30) => 5000 * (10 ^ 12).
 * To read more, see GMX's documentation on oracle prices: https://github.com/gmx-io/gmx-synthetics?tab=readme-ov-file#oracle-prices
 */
library Pricing {
    // ============ Constants ============

    /// @dev The number of decimals used to represent USD within GMX.
    uint256 internal constant USD_DECIMALS = 30;

    // ============ Internal Functions ============

    /**
     * @notice Get the value of an ERC20 token in USD.
     * @param oracle      The `IGmxFrfStrategyManager` to use for the valuation.
     * @param asset       The address of the ERC20 token to evaluate. The asset must have a valid oracle registered within the `IChainlinkAdapter`.
     * @param tokenAmount The token amount to get the valuation for.
     * @return assetValue The value of the token amount in USD.
     */
    function getTokenValueUSD(
        IGmxFrfStrategyManager oracle,
        address asset,
        uint256 tokenAmount
    ) internal view returns (uint256 assetValue) {
        // Exit early if the token amount is 0.
        if (tokenAmount == 0) {
            return 0;
        }

        // Query the oracle for the price of the asset.
        uint256 assetPrice = getUnitTokenPriceUSD(oracle, asset);

        return getTokenValueUSD(tokenAmount, assetPrice);
    }

    /**
     * @notice Get the value of an ERC20 token in USD.
     * @param  tokenAmount The token amount to get the valuation for.
     * @param  price       The price of the token in USD. (1 USD = 1e30).
     * @return assetValue  The value of the token amount in USD.
     * @dev The provided  `IChainlinkAdapter` MUST have a price precision of 30.
     */
    function getTokenValueUSD(
        uint256 tokenAmount,
        uint256 price
    ) internal pure returns (uint256 assetValue) {
        // Per the GMX documentation, the value of a token in terms of USD is simply calculated via multiplication.
        // This is because the USD price already inherently accounts for the decimals of the token.
        return price * tokenAmount;
    }

    /**
     * @notice Gets the price of a given token per unit in USD. USD is represented with 30 decimals of precision.
     * @param oracle      The `IChainlinkAdapter` to use for pricing this token.
     * @param token       The address of the ERC20 token to evaluate. The asset must have a valid oracle registered within the `IChainlinkAdapter`.
     * @return assetValue The value of the token amount in USD.
     */
    function getUnitTokenPriceUSD(
        IGmxFrfStrategyManager oracle,
        address token
    ) internal view returns (uint256) {
        (uint256 price, uint256 oracleDecimals) = oracle.getAssetPrice(token);

        // The total decimals that the price is represented with, which includes both the oracle's
        // decimals and the token's decimals.
        uint256 totalPriceDecimals = oracleDecimals + getAssetDecimals(token);

        // The offset in decimals between the USD price and the the both the oracle's decimals and the token's decimals.
        uint256 decimalOffset = Math.max(USD_DECIMALS, totalPriceDecimals) -
            Math.min(USD_DECIMALS, totalPriceDecimals);

        return
            (USD_DECIMALS >= totalPriceDecimals)
                ? price * (10 ** decimalOffset)
                : price / (10 ** decimalOffset);
    }

    /**
     * @notice Get the amount of a token that is equivalent to a given USD amount based on `token's` current oracle price.
     * @param oracle       The `IChainlinkAdapter` to use for querying the oracle price for this token.
     * @param token        The token address for the token to quote `usdAmount` in.
     * @param usdAmount    The amount in USD to convert to tokens. (1 usd = 1^30)
     * @return tokenAmount The amount of `token` equivalent to `usdAmount` based on the current `oracle` price.
     */
    function getTokenAmountForUSD(
        IGmxFrfStrategyManager oracle,
        address token,
        uint256 usdAmount
    ) internal view returns (uint256) {
        uint256 assetPrice = getUnitTokenPriceUSD(oracle, token);

        // As defined per the GMX documentation, the value of a token in terms of USD is simply calculated via division.
        return usdAmount / assetPrice;
    }

    /**
     * @notice Fetch decimals for an asset.
     * @param token     The token to get the decimals for.
     * @return decimals The decimals of the token.
     */
    function getAssetDecimals(
        address token
    ) internal view returns (uint256 decimals) {
        return IERC20Metadata(token).decimals();
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";
import { IGmxV2MarketTypes } from "./IGmxV2MarketTypes.sol";

/**
 * @title IGmxV2PositionTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's position types. A few structs are the same as GMX but a number are
 * added.
 * Adapted from these three files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/position/Position.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/pricing/PositionPricingUtils.sol
 */
interface IGmxV2PositionTypes {
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }

    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    struct Flags {
        bool isLong;
    }

    struct PositionInfo {
        IGmxV2PositionTypes.Props position;
        PositionFees fees;
        IGmxV2PriceTypes.ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 uncappedBasePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    struct GetPositionFeesParams {
        address dataStore;
        address referralStorage;
        IGmxV2PositionTypes.Props position;
        IGmxV2PriceTypes.Props collateralTokenPrice;
        bool forPositiveImpact;
        address longToken;
        address shortToken;
        uint256 sizeDeltaUsd;
        address uiFeeReceiver;
    }

    struct GetPriceImpactUsdParams {
        address dataStore;
        IGmxV2MarketTypes.Props market;
        int256 usdDelta;
        bool isLong;
    }

    struct OpenInterestParams {
        uint256 longOpenInterest;
        uint256 shortOpenInterest;
        uint256 nextLongOpenInterest;
        uint256 nextShortOpenInterest;
    }

    struct PositionFees {
        PositionReferralFees referral;
        PositionFundingFees funding;
        PositionBorrowingFees borrowing;
        PositionUiFees ui;
        IGmxV2PriceTypes.Props collateralTokenPrice;
        uint256 positionFeeFactor;
        uint256 protocolFeeAmount;
        uint256 positionFeeReceiverFactor;
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 positionFeeAmountForPool;
        uint256 positionFeeAmount;
        uint256 totalCostAmountExcludingFunding;
        uint256 totalCostAmount;
    }

    struct PositionReferralFees {
        bytes32 referralCode;
        address affiliate;
        address trader;
        uint256 totalRebateFactor;
        uint256 traderDiscountFactor;
        uint256 totalRebateAmount;
        uint256 traderDiscountAmount;
        uint256 affiliateRewardAmount;
    }

    struct PositionBorrowingFees {
        uint256 borrowingFeeUsd;
        uint256 borrowingFeeAmount;
        uint256 borrowingFeeReceiverFactor;
        uint256 borrowingFeeAmountForFeeReceiver;
    }

    struct PositionFundingFees {
        uint256 fundingFeeAmount;
        uint256 claimableLongTokenAmount;
        uint256 claimableShortTokenAmount;
        uint256 latestFundingFeeAmountPerSize;
        uint256 latestLongTokenClaimableFundingAmountPerSize;
        uint256 latestShortTokenClaimableFundingAmountPerSize;
    }

    struct PositionUiFees {
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";

/**
 * @title IMarketConfiguration
 * @author GoldLink
 *
 * @dev Manages the configuration of markets for the GmxV2 funding rate farming strategy.
 */
interface IMarketConfiguration {
    // ============ Structs ============

    /// @dev Parameters for pricing an order.
    struct OrderPricingParameters {
        // The maximum swap slippage percentage for this market. The value is computed using the oracle price as a reference.
        uint256 maxSwapSlippagePercent;
        // The maximum slippage percentage for this market. The value is computed using the oracle price as a reference.
        uint256 maxPositionSlippagePercent;
        // The minimum order size in USD for this market.
        uint256 minOrderSizeUsd;
        // The maximum order size in USD for this market.
        uint256 maxOrderSizeUsd;
        // Whether or not increase orders are enabled.
        bool increaseEnabled;
    }

    /// @dev Parameters for unwinding an order.
    struct UnwindParameters {
        // The minimum amount of delta the position is allowed to have before it can be rebalanced.
        uint256 maxDeltaProportion;
        // The minimum size of a token sale rebalance required. This is used to prevent dust orders from preventing rebalancing of a position via unwinding a position from occuring.
        uint256 minSwapRebalanceSize;
        // The maximum amount of leverage a position is allowed to have.
        uint256 maxPositionLeverage;
        // The fee rate that pays rebalancers for purchasing additional assets to match the short position.
        uint256 unwindFee;
    }

    /// @dev Parameters shared across order types for a market.
    struct SharedOrderParameters {
        // The callback gas limit for all orders.
        uint256 callbackGasLimit;
        // The execution fee buffer percentage required for placing an order.
        uint256 executionFeeBufferPercent;
        // The referral code to use for all orders.
        bytes32 referralCode;
        // The ui fee receiver used for all orders.
        address uiFeeReceiver;
        // The `withdrawalBufferPercentage` for all accounts.
        uint256 withdrawalBufferPercentage;
    }

    /// @dev Parameters for a position established on GMX through the strategy.
    struct PositionParameters {
        // The minimum position size in USD for this market, in order to prevent
        // dust orders from needing to be liquidated. This implies that if a position is partially closed,
        // the value of the position after the partial close must be greater than this value.
        uint256 minPositionSizeUsd;
        // The maximum position size in USD for this market.
        uint256 maxPositionSizeUsd;
    }

    /// @dev Object containing all parameters for a market.
    struct MarketConfiguration {
        // The order pricing parameters for the market.
        OrderPricingParameters orderPricingParameters;
        // The shared order parameters for the market.
        SharedOrderParameters sharedOrderParameters;
        // The position parameters for the market.
        PositionParameters positionParameters;
        // The unwind parameters for the market.
        UnwindParameters unwindParameters;
    }

    // ============ Events ============

    /// @notice Emitted when setting the configuration for a market.
    /// @param market             The address of the market whose configuration is being updated.
    /// @param marketParameters   The updated market parameters for the market.
    /// @param positionParameters The updated position parameters for the market.
    /// @param unwindParameters   The updated unwind parameters for the market.
    event MarketConfigurationSet(
        address indexed market,
        OrderPricingParameters marketParameters,
        PositionParameters positionParameters,
        UnwindParameters unwindParameters
    );

    /// @notice Emitted when setting the asset liquidation fee.
    /// @param asset                    The asset whose liquidation fee percent is being set.
    /// @param newLiquidationFeePercent The new liquidation fee percent for the asset.
    event AssetLiquidationFeeSet(
        address indexed asset,
        uint256 newLiquidationFeePercent
    );

    /// @notice Emitted when setting the liquidation order timeout deadline.
    /// @param newLiquidationOrderTimeoutDeadline The window after which a liquidation order
    /// can be canceled.
    event LiquidationOrderTimeoutDeadlineSet(
        uint256 newLiquidationOrderTimeoutDeadline
    );

    /// @notice Emitted when setting the callback gas limit.
    /// @param newCallbackGasLimit The gas limit on any callback made from the strategy.
    event CallbackGasLimitSet(uint256 newCallbackGasLimit);

    /// @notice Emitted when setting the execution fee buffer percent.
    /// @param newExecutionFeeBufferPercent The percentage of the initially calculated execution fee that needs to be provided additionally
    /// to prevent orders from failing execution.
    event ExecutionFeeBufferPercentSet(uint256 newExecutionFeeBufferPercent);

    /// @notice Emitted when setting the referral code.
    /// @param newReferralCode The code applied to all orders for the strategy, tying orders back to
    /// this protocol.
    event ReferralCodeSet(bytes32 newReferralCode);

    /// @notice Emitted when setting the ui fee receiver.
    /// @param newUiFeeReceiver The fee paid to the UI, this protocol for placing orders.
    event UiFeeReceiverSet(address newUiFeeReceiver);

    /// @notice Emitted when setting the withdrawal buffer percentage.
    /// @param newWithdrawalBufferPercentage The new withdrawal buffer percentage that was set.
    event WithdrawalBufferPercentageSet(uint256 newWithdrawalBufferPercentage);

    // ============ External Functions ============

    /// @dev Set a market for the GMX FRF strategy.
    function setMarket(
        address market,
        IChainlinkAdapter.OracleConfiguration memory oracleConfig,
        OrderPricingParameters memory marketParameters,
        PositionParameters memory positionParameters,
        UnwindParameters memory unwindParameters,
        uint256 longTokenLiquidationFeePercent
    ) external;

    /// @dev Update the oracle for USDC.
    function updateUsdcOracle(
        IChainlinkAdapter.OracleConfiguration calldata strategyAssetOracleConfig
    ) external;

    /// @dev Disable increase orders in a market.
    function disableMarketIncreases(address marketAddress) external;

    /// @dev Set the asset liquidation fee percentage for an asset.
    function setAssetLiquidationFee(
        address asset,
        uint256 newLiquidationFeePercent
    ) external;

    /// @dev Set the asset liquidation timeout for an asset. The time that must
    /// pass before a liquidated order can be cancelled.
    function setLiquidationOrderTimeoutDeadline(
        uint256 newLiquidationOrderTimeoutDeadline
    ) external;

    /// @dev Set the callback gas limit.
    function setCallbackGasLimit(uint256 newCallbackGasLimit) external;

    /// @dev Set the execution fee buffer percent.
    function setExecutionFeeBufferPercent(
        uint256 newExecutionFeeBufferPercent
    ) external;

    /// @dev Set the referral code for all trades made through the GMX Frf strategy.
    function setReferralCode(bytes32 newReferralCode) external;

    /// @dev Set the address of the UI fee receiver.
    function setUiFeeReceiver(address newUiFeeReceiver) external;

    /// @dev Set the buffer on the account value that must be maintained to withdraw profit
    /// with an active loan.
    function setWithdrawalBufferPercentage(
        uint256 newWithdrawalBufferPercentage
    ) external;

    /// @dev Get if a market is approved for the GMX FRF strategy.
    function isApprovedMarket(address market) external view returns (bool);

    /// @dev Get the config that dictates parameters for unwinding an order.
    function getMarketUnwindConfiguration(
        address market
    ) external view returns (UnwindParameters memory);

    /// @dev Get the config for a specific market.
    function getMarketConfiguration(
        address market
    ) external view returns (MarketConfiguration memory);

    /// @dev Get the list of available markets for the GMX FRF strategy.
    function getAvailableMarkets() external view returns (address[] memory);

    /// @dev Get the asset liquidation fee percent.
    function getAssetLiquidationFeePercent(
        address asset
    ) external view returns (uint256);

    /// @dev Get the liquidation order timeout deadline.
    function getLiquidationOrderTimeoutDeadline()
        external
        view
        returns (uint256);

    /// @dev Get the callback gas limit.
    function getCallbackGasLimit() external view returns (uint256);

    /// @dev Get the execution fee buffer percent.
    function getExecutionFeeBufferPercent() external view returns (uint256);

    /// @dev Get the referral code.
    function getReferralCode() external view returns (bytes32);

    /// @dev Get the UI fee receiver
    function getUiFeeReceiver() external view returns (address);

    /// @dev Get profit withdraw buffer percent.
    function getProfitWithdrawalBufferPercent() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title Constants
 * @author GoldLink
 *
 * @dev Core constants for the GoldLink Protocol.
 */
library Constants {
    ///
    /// COMMON
    ///
    /// @dev ONE_HUNDRED_PERCENT is one WAD.
    uint256 internal constant ONE_HUNDRED_PERCENT = 1e18;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;
}

// SPDX-License-Identifier: AGPL-3.0

import { Constants } from "./Constants.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

pragma solidity 0.8.20;

/**
 * @title PercentMath
 * @author GoldLink
 *
 * @dev Library for calculating percentages and fractions from percentages.
 * Meant to handle getting fractions in WAD and fraction values from percentages.
 */
library PercentMath {
    using Math for uint256;

    // ============ Internal Functions ============

    /**
     * @notice Implements percent to fraction, deriving a fraction from a percentage.
     * @dev The percentage was calculated with WAD precision.
     * @dev Rounds down.
     * @param whole          The total value.
     * @param percentage     The percent of the whole to derive from.
     * @return fractionValue The value of the fraction.
     */
    function percentToFraction(
        uint256 whole,
        uint256 percentage
    ) internal pure returns (uint256 fractionValue) {
        return whole.mulDiv(percentage, Constants.ONE_HUNDRED_PERCENT);
    }

    /**
     * @notice Implements percent to fraction ceil, deriving a fraction from
     * the ceiling of a percentage.
     * @dev The percentage was calculated with WAD precision.
     * @dev Rounds up.
     * @param whole          The total value.
     * @param percentage     The percent of the whole to derive from.
     * @return fractionValue The value of the fraction.
     */
    function percentToFractionCeil(
        uint256 whole,
        uint256 percentage
    ) internal pure returns (uint256 fractionValue) {
        return
            whole.mulDiv(
                percentage,
                Constants.ONE_HUNDRED_PERCENT,
                Math.Rounding.Ceil
            );
    }

    /**
     * @notice Implements fraction to percent, deriving the percent of the whole
     * that a fraction is.
     * @dev The percentage is calculated with WAD precision.
     * @dev Rounds down.
     * @param fraction    The fraction value.
     * @param whole       The whole value.
     * @return percentage The percent of the whole the `fraction` represents.
     */
    function fractionToPercent(
        uint256 fraction,
        uint256 whole
    ) internal pure returns (uint256 percentage) {
        return fraction.mulDiv(Constants.ONE_HUNDRED_PERCENT, whole);
    }

    /**
     * @notice Implements fraction to percent ceil, deriving the percent of the whole
     * that a fraction is.
     * @dev The percentage is calculated with WAD precision.
     * @dev Rounds up.
     * @param fraction    The fraction value.
     * @param whole       The whole value.
     * @return percentage The percent of the whole the `fraction` represents.
     */
    function fractionToPercentCeil(
        uint256 fraction,
        uint256 whole
    ) internal pure returns (uint256 percentage) {
        return
            fraction.mulDiv(
                Constants.ONE_HUNDRED_PERCENT,
                whole,
                Math.Rounding.Ceil
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Borrowed from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/order/OrderStoreUtils.sol
// Modified as follows:
// - GoldLink types
// - set functions removed
// - additional getters like getting keys for storage values

pragma solidity ^0.8.0;

import { Keys } from "../keys/Keys.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import { IGmxV2OrderTypes } from "../interfaces/external/IGmxV2OrderTypes.sol";
import { Order } from "./Order.sol";

library OrderStoreUtils {
    using Order for IGmxV2OrderTypes.Props;

    // ============ Constants ============

    bytes32 public constant ACCOUNT = keccak256(abi.encode("ACCOUNT"));
    bytes32 public constant RECEIVER = keccak256(abi.encode("RECEIVER"));
    bytes32 public constant CALLBACK_CONTRACT =
        keccak256(abi.encode("CALLBACK_CONTRACT"));
    bytes32 public constant UI_FEE_RECEIVER =
        keccak256(abi.encode("UI_FEE_RECEIVER"));
    bytes32 public constant MARKET = keccak256(abi.encode("MARKET"));
    bytes32 public constant INITIAL_COLLATERAL_TOKEN =
        keccak256(abi.encode("INITIAL_COLLATERAL_TOKEN"));
    bytes32 public constant SWAP_PATH = keccak256(abi.encode("SWAP_PATH"));

    bytes32 public constant ORDER_TYPE = keccak256(abi.encode("ORDER_TYPE"));
    bytes32 public constant DECREASE_POSITION_SWAP_TYPE =
        keccak256(abi.encode("DECREASE_POSITION_SWAP_TYPE"));
    bytes32 public constant SIZE_DELTA_USD =
        keccak256(abi.encode("SIZE_DELTA_USD"));
    bytes32 public constant INITIAL_COLLATERAL_DELTA_AMOUNT =
        keccak256(abi.encode("INITIAL_COLLATERAL_DELTA_AMOUNT"));
    bytes32 public constant TRIGGER_PRICE =
        keccak256(abi.encode("TRIGGER_PRICE"));
    bytes32 public constant ACCEPTABLE_PRICE =
        keccak256(abi.encode("ACCEPTABLE_PRICE"));
    bytes32 public constant EXECUTION_FEE =
        keccak256(abi.encode("EXECUTION_FEE"));
    bytes32 public constant CALLBACK_GAS_LIMIT =
        keccak256(abi.encode("CALLBACK_GAS_LIMIT"));
    bytes32 public constant MIN_OUTPUT_AMOUNT =
        keccak256(abi.encode("MIN_OUTPUT_AMOUNT"));
    bytes32 public constant UPDATED_AT_BLOCK =
        keccak256(abi.encode("UPDATED_AT_BLOCK"));

    bytes32 public constant IS_LONG = keccak256(abi.encode("IS_LONG"));
    bytes32 public constant SHOULD_UNWRAP_NATIVE_TOKEN =
        keccak256(abi.encode("SHOULD_UNWRAP_NATIVE_TOKEN"));
    bytes32 public constant IS_FROZEN = keccak256(abi.encode("IS_FROZEN"));

    // ============ Internal Functions ============

    function get(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (IGmxV2OrderTypes.Props memory) {
        IGmxV2OrderTypes.Props memory order;
        if (!dataStore.containsBytes32(Keys.ORDER_LIST, key)) {
            return order;
        }

        order.setAccount(
            dataStore.getAddress(keccak256(abi.encode(key, ACCOUNT)))
        );

        order.setReceiver(
            dataStore.getAddress(keccak256(abi.encode(key, RECEIVER)))
        );

        order.setCallbackContract(
            dataStore.getAddress(keccak256(abi.encode(key, CALLBACK_CONTRACT)))
        );

        order.setUiFeeReceiver(
            dataStore.getAddress(keccak256(abi.encode(key, UI_FEE_RECEIVER)))
        );

        order.setMarket(
            dataStore.getAddress(keccak256(abi.encode(key, MARKET)))
        );

        order.setInitialCollateralToken(
            dataStore.getAddress(
                keccak256(abi.encode(key, INITIAL_COLLATERAL_TOKEN))
            )
        );

        order.setSwapPath(
            dataStore.getAddressArray(keccak256(abi.encode(key, SWAP_PATH)))
        );

        order.setOrderType(
            IGmxV2OrderTypes.OrderType(
                dataStore.getUint(keccak256(abi.encode(key, ORDER_TYPE)))
            )
        );

        order.setDecreasePositionSwapType(
            IGmxV2OrderTypes.DecreasePositionSwapType(
                dataStore.getUint(
                    keccak256(abi.encode(key, DECREASE_POSITION_SWAP_TYPE))
                )
            )
        );

        order.setSizeDeltaUsd(
            dataStore.getUint(keccak256(abi.encode(key, SIZE_DELTA_USD)))
        );

        order.setInitialCollateralDeltaAmount(
            dataStore.getUint(
                keccak256(abi.encode(key, INITIAL_COLLATERAL_DELTA_AMOUNT))
            )
        );

        order.setTriggerPrice(
            dataStore.getUint(keccak256(abi.encode(key, TRIGGER_PRICE)))
        );

        order.setAcceptablePrice(
            dataStore.getUint(keccak256(abi.encode(key, ACCEPTABLE_PRICE)))
        );

        order.setExecutionFee(
            dataStore.getUint(keccak256(abi.encode(key, EXECUTION_FEE)))
        );

        order.setCallbackGasLimit(
            dataStore.getUint(keccak256(abi.encode(key, CALLBACK_GAS_LIMIT)))
        );

        order.setMinOutputAmount(
            dataStore.getUint(keccak256(abi.encode(key, MIN_OUTPUT_AMOUNT)))
        );

        order.setUpdatedAtBlock(
            dataStore.getUint(keccak256(abi.encode(key, UPDATED_AT_BLOCK)))
        );

        order.setIsLong(dataStore.getBool(keccak256(abi.encode(key, IS_LONG))));

        order.setShouldUnwrapNativeToken(
            dataStore.getBool(
                keccak256(abi.encode(key, SHOULD_UNWRAP_NATIVE_TOKEN))
            )
        );

        order.setIsFrozen(
            dataStore.getBool(keccak256(abi.encode(key, IS_FROZEN)))
        );

        return order;
    }

    function getOrderMarket(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (address) {
        return dataStore.getAddress(keccak256(abi.encode(key, MARKET)));
    }

    function getOrderCount(
        IGmxV2DataStore dataStore
    ) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.ORDER_LIST);
    }

    function getOrderKeys(
        IGmxV2DataStore dataStore,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        return dataStore.getBytes32ValuesAt(Keys.ORDER_LIST, start, end);
    }

    function getAccountOrderCount(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.accountOrderListKey(account));
    }

    function getAccountOrderKeys(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        return
            dataStore.getBytes32ValuesAt(
                Keys.accountOrderListKey(account),
                start,
                end
            );
    }

    function getAccountOrderKeys(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (bytes32[] memory) {
        uint256 orderCount = getAccountOrderCount(dataStore, account);

        return getAccountOrderKeys(dataStore, account, 0, orderCount);
    }

    function getAccountOrders(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (IGmxV2OrderTypes.Props[] memory) {
        bytes32[] memory keys = getAccountOrderKeys(dataStore, account);

        IGmxV2OrderTypes.Props[] memory orders = new IGmxV2OrderTypes.Props[](
            keys.length
        );

        uint256 keysLength = keys.length;
        for (uint256 i = 0; i < keysLength; ++i) {
            orders[i] = get(dataStore, keys[i]);
        }

        return orders;
    }

    function getOrderInMarket(
        IGmxV2DataStore dataStore,
        address account,
        address market
    )
        internal
        view
        returns (IGmxV2OrderTypes.Props memory order, bytes32 orderId)
    {
        bytes32[] memory keys = getAccountOrderKeys(dataStore, account);

        uint256 keysLength = keys.length;
        for (uint256 i = 0; i < keysLength; ++i) {
            address orderMarket = getOrderMarket(dataStore, keys[i]);

            if (orderMarket != market) continue;

            return (get(dataStore, keys[i]), keys[i]);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title GmxFrfStrategyErrors
 * @author GoldLink
 *
 * @dev Gmx Delta Neutral Errors library for GMX related interactions.
 */
library GmxFrfStrategyErrors {
    //
    // COMMON
    //
    string internal constant ZERO_ADDRESS_IS_NOT_ALLOWED =
        "Zero address is not allowed.";
    string
        internal constant TOO_MUCH_NATIVE_TOKEN_SPENT_IN_MULTICALL_EXECUTION =
        "Too much native token spent in multicall transaction.";
    string internal constant MSG_VALUE_LESS_THAN_PROVIDED_EXECUTION_FEE =
        "Msg value less than provided execution fee.";
    string internal constant NESTED_MULTICALLS_ARE_NOT_ALLOWED =
        "Nested multicalls are not allowed.";

    //
    // Deployment Configuration Manager
    //
    string
        internal constant DEPLOYMENT_CONFIGURATION_MANAGER_INVALID_DEPLOYMENT_ADDRESS =
        "DeploymentConfigurationManager: Invalid deployment address.";

    //
    // GMX Delta Neutral Funding Rate Farming Manager
    //
    string internal constant CANNOT_ADD_SEPERATE_MARKET_WITH_SAME_LONG_TOKEN =
        "GmxFrfStrategyManager: Cannot add seperate market with same long token.";
    string
        internal constant GMX_FRF_STRATEGY_MANAGER_LONG_TOKEN_DOES_NOT_HAVE_AN_ORACLE =
        "GmxFrfStrategyManager: Long token does not have an oracle.";
    string internal constant GMX_FRF_STRATEGY_MANAGER_MARKET_DOES_NOT_EXIST =
        "GmxFrfStrategyManager: Market does not exist.";
    string
        internal constant GMX_FRF_STRATEGY_MANAGER_SHORT_TOKEN_DOES_NOT_HAVE_AN_ORACLE =
        "GmxFrfStrategyManager: Short token does not have an oracle.";
    string internal constant GMX_FRF_STRATEGY_MANAGER_SHORT_TOKEN_MUST_BE_USDC =
        "GmxFrfStrategyManager: Short token for market must be usdc.";
    string internal constant LONG_TOKEN_CANT_BE_USDC =
        "GmxFrfStrategyManager: Long token can't be usdc.";
    string internal constant MARKET_CAN_ONLY_BE_DISABLED_IN_DECREASE_ONLY_MODE =
        "GmxFrfStrategyManager: Market can only be disabled in decrease only mode.";
    string internal constant MARKETS_COUNT_CANNOT_EXCEED_MAXIMUM =
        "GmxFrfStrategyManager: Market count cannot exceed maximum.";
    string internal constant MARKET_INCREASES_ARE_ALREADY_DISABLED =
        "GmxFrfStrategyManager: Market increases are already disabled.";
    string internal constant MARKET_IS_NOT_ENABLED =
        "GmxFrfStrategyManager: Market is not enabled.";

    //
    // GMX V2 Adapter
    //
    string
        internal constant GMX_V2_ADAPTER_MAX_SLIPPAGE_MUST_BE_LT_100_PERCENT =
        "GmxV2Adapter: Maximum slippage must be less than 100%.";
    string internal constant GMX_V2_ADAPTER_MINIMUM_SLIPPAGE_MUST_BE_LT_MAX =
        "GmxV2Adapter: Minimum slippage must be less than maximum slippage.";

    //
    // Liquidation Management
    //
    string
        internal constant LIQUIDATION_MANAGEMENT_AVAILABLE_TOKEN_BALANCE_MUST_BE_CLEARED_BEFORE_REBALANCING =
        "LiquidationManagement: Available token balance must be cleared before rebalancing.";
    string
        internal constant LIQUIDATION_MANAGEMENT_NO_ASSETS_EXIST_IN_THIS_MARKET_TO_REBALANCE =
        "LiquidationManagement: No assets exist in this market to rebalance.";
    string
        internal constant LIQUIDATION_MANAGEMENT_POSITION_DELTA_IS_NOT_SUFFICIENT_FOR_SWAP_REBALANCE =
        "LiquidationManagement: Position delta is not sufficient for swap rebalance.";
    string
        internal constant LIQUIDATION_MANAGEMENT_POSITION_IS_WITHIN_MAX_DEVIATION =
        "LiquidationManagement: Position is within max deviation.";
    string
        internal constant LIQUIDATION_MANAGEMENT_POSITION_IS_WITHIN_MAX_LEVERAGE =
        "LiquidationManagement: Position is within max leverage.";
    string
        internal constant LIQUIDATION_MANAGEMENT_REBALANCE_AMOUNT_LEAVE_TOO_LITTLE_REMAINING_ASSETS =
        "LiquidationManagement: Rebalance amount leaves too little remaining assets.";

    //
    // Swap Callback Logic
    //
    string
        internal constant SWAP_CALLBACK_LOGIC_CALLBACK_ADDRESS_MUST_NOT_HAVE_GMX_CONTROLLER_ROLE =
        "SwapCallbackLogic: Callback address must not have GMX controller role.";
    string internal constant SWAP_CALLBACK_LOGIC_CANNOT_SWAP_USDC =
        "SwapCallbackLogic: Cannot swap USDC.";
    string internal constant SWAP_CALLBACK_LOGIC_INSUFFICIENT_USDC_RETURNED =
        "SwapCallbackLogic: Insufficient USDC returned.";
    string
        internal constant SWAP_CALLBACK_LOGIC_NO_BALANCE_AFTER_SLIPPAGE_APPLIED =
        "SwapCallbackLogic: No balance after slippage applied.";

    //
    // Order Management
    //
    string internal constant ORDER_MANAGEMENT_INVALID_FEE_REFUND_RECIPIENT =
        "OrderManagement: Invalid fee refund recipient.";
    string
        internal constant ORDER_MANAGEMENT_LIQUIDATION_ORDER_CANNOT_BE_CANCELLED_YET =
        "OrderManagement: Liquidation order cannot be cancelled yet.";
    string internal constant ORDER_MANAGEMENT_ORDER_MUST_BE_FOR_THIS_ACCOUNT =
        "OrderManagement: Order must be for this account.";

    //
    // Order Validation
    //
    string
        internal constant ORDER_VALIDATION_ACCEPTABLE_PRICE_IS_NOT_WITHIN_SLIPPAGE_BOUNDS =
        "OrderValidation: Acceptable price is not within slippage bounds.";
    string internal constant ORDER_VALIDATION_DECREASE_AMOUNT_CANNOT_BE_ZERO =
        "OrderValidation: Decrease amount cannot be zero.";
    string internal constant ORDER_VALIDATION_DECREASE_AMOUNT_IS_TOO_LARGE =
        "OrderValidation: Decrease amount is too large.";
    string
        internal constant ORDER_VALIDATION_EXECUTION_PRICE_NOT_WITHIN_SLIPPAGE_RANGE =
        "OrderValidation: Execution price not within slippage range.";
    string
        internal constant ORDER_VALIDATION_INITIAL_COLLATERAL_BALANCE_IS_TOO_LOW =
        "OrderValidation: Initial collateral balance is too low.";
    string internal constant ORDER_VALIDATION_MARKET_HAS_PENDING_ORDERS =
        "OrderValidation: Market has pending orders.";
    string internal constant ORDER_VALIDATION_ORDER_TYPE_IS_DISABLED =
        "OrderValidation: Order type is disabled.";
    string internal constant ORDER_VALIDATION_ORDER_SIZE_IS_TOO_LARGE =
        "OrderValidation: Order size is too large.";
    string internal constant ORDER_VALIDATION_ORDER_SIZE_IS_TOO_SMALL =
        "OrderValidation: Order size is too small.";
    string internal constant ORDER_VALIDATION_POSITION_DOES_NOT_EXIST =
        "OrderValidation: Position does not exist.";
    string
        internal constant ORDER_VALIDATION_POSITION_NOT_OWNED_BY_THIS_ACCOUNT =
        "OrderValidation: Position not owned by this account.";
    string internal constant ORDER_VALIDATION_POSITION_SIZE_IS_TOO_LARGE =
        "OrderValidation: Position size is too large.";
    string internal constant ORDER_VALIDATION_POSITION_SIZE_IS_TOO_SMALL =
        "OrderValidation: Position size is too small.";
    string
        internal constant ORDER_VALIDATION_PROVIDED_EXECUTION_FEE_IS_TOO_LOW =
        "OrderValidation: Provided execution fee is too low.";
    string internal constant ORDER_VALIDATION_SWAP_SLIPPAGE_IS_TOO_HGIH =
        "OrderValidation: Swap slippage is too high.";

    //
    // Gmx Funding Rate Farming
    //
    string internal constant GMX_FRF_STRATEGY_MARKET_DOES_NOT_EXIST =
        "GmxFrfStrategyAccount: Market does not exist.";
    string
        internal constant GMX_FRF_STRATEGY_ORDER_CALLBACK_RECEIVER_CALLER_MUST_HAVE_CONTROLLER_ROLE =
        "GmxFrfStrategyAccount: Caller must have controller role.";

    //
    // Gmx V2 Order Callback Receiver
    //
    string
        internal constant GMX_V2_ORDER_CALLBACK_RECEIVER_CALLER_MUST_HAVE_CONTROLLER_ROLE =
        "GmxV2OrderCallbackReceiver: Caller must have controller role.";

    //
    // Market Configuration Manager
    //
    string
        internal constant ASSET_LIQUIDATION_FEE_CANNOT_BE_GREATER_THAN_MAXIMUM =
        "MarketConfigurationManager: Asset liquidation fee cannot be greater than maximum.";
    string internal constant ASSET_ORACLE_COUNT_CANNOT_EXCEED_MAXIMUM =
        "MarketConfigurationManager: Asset oracle count cannot exceed maximum.";
    string
        internal constant CANNOT_SET_MAX_POSITION_SLIPPAGE_BELOW_MINIMUM_VALUE =
        "MarketConfigurationManager: Cannot set maxPositionSlippagePercent below the minimum value.";
    string
        internal constant CANNOT_SET_THE_CALLBACK_GAS_LIMIT_ABOVE_THE_MAXIMUM =
        "MarketConfigurationManager: Cannot set the callback gas limit above the maximum.";
    string internal constant CANNOT_SET_MAX_SWAP_SLIPPAGE_BELOW_MINIMUM_VALUE =
        "MarketConfigurationManager: Cannot set maxSwapSlippagePercent below minimum value.";
    string
        internal constant CANNOT_SET_THE_EXECUTION_FEE_BUFFER_ABOVE_THE_MAXIMUM =
        "MarketConfigurationManager: Cannot set the execution fee buffer above the maximum.";
    string
        internal constant MARKET_CONFIGURATION_MANAGER_MIN_ORDER_SIZE_MUST_BE_LESS_THAN_OR_EQUAL_TO_MAX_ORDER_SIZE =
        "MarketConfigurationManager: Min order size must be less than or equal to max order size.";
    string
        internal constant MARKET_CONFIGURATION_MANAGER_MIN_POSITION_SIZE_MUST_BE_LESS_THAN_OR_EQUAL_TO_MAX_POSITION_SIZE =
        "MarketConfigurationManager: Min position size must be less than or equal to max position size.";
    string
        internal constant MAX_DELTA_PROPORTION_IS_BELOW_THE_MINIMUM_REQUIRED_VALUE =
        "MarketConfigurationManager: MaxDeltaProportion is below the minimum required value.";
    string
        internal constant MAX_POSITION_LEVERAGE_IS_BELOW_THE_MINIMUM_REQUIRED_VALUE =
        "MarketConfigurationManager: MaxPositionLeverage is below the minimum required value.";
    string internal constant UNWIND_FEE_IS_ABOVE_THE_MAXIMUM_ALLOWED_VALUE =
        "MarketConfigurationManager: UnwindFee is above the maximum allowed value.";
    string
        internal constant WITHDRAWAL_BUFFER_PERCENTAGE_MUST_BE_GREATER_THAN_THE_MINIMUM =
        "MarketConfigurationManager: WithdrawalBufferPercentage must be greater than the minimum.";
    //
    // Withdrawal Logic Errors
    //
    string
        internal constant CANNOT_WITHDRAW_BELOW_THE_ACCOUNTS_LOAN_VALUE_WITH_BUFFER_APPLIED =
        "WithdrawalLogic: Cannot withdraw to below the account's loan value with buffer applied.";
    string
        internal constant CANNOT_WITHDRAW_FROM_MARKET_IF_ACCOUNT_MARKET_DELTA_IS_SHORT =
        "WithdrawalLogic: Cannot withdraw from market if account's market delta is short.";
    string internal constant CANNOT_WITHDRAW_MORE_TOKENS_THAN_ACCOUNT_BALANCE =
        "WithdrawalLogic: Cannot withdraw more tokens than account balance.";
    string
        internal constant REQUESTED_WITHDRAWAL_AMOUNT_EXCEEDS_CURRENT_DELTA_DIFFERENCE =
        "WithdrawalLogic: Requested amount exceeds current delta difference.";
    string
        internal constant WITHDRAWAL_BRINGS_ACCOUNT_BELOW_MINIMUM_OPEN_HEALTH_SCORE =
        "WithdrawalLogic: Withdrawal brings account below minimum open health score.";
    string internal constant WITHDRAWAL_VALUE_CANNOT_BE_GTE_ACCOUNT_VALUE =
        "WithdrawalLogic: Withdrawal value cannot be gte to account value.";
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2OrderTypes
} from "../../../lib/gmx/interfaces/external/IGmxV2OrderTypes.sol";
import { GasUtils } from "../../../lib/gmx/gas/GasUtils.sol";
import { OrderStoreUtils } from "../../../lib/gmx/order/OrderStoreUtils.sol";
import {
    PositionStoreUtils
} from "../../../lib/gmx/position/PositionStoreUtils.sol";
import {
    GmxMarketGetters
} from "../../../strategies/gmxFrf/libraries/GmxMarketGetters.sol";
import { PercentMath } from "../../../libraries/PercentMath.sol";
import { GmxFrfStrategyErrors } from "../GmxFrfStrategyErrors.sol";

/**
 * @title OrderValidation
 * @author GoldLink
 *
 * @dev Library for validating new orders.
 */
library OrderValidation {
    using PercentMath for uint256;

    // ============ Internal Functions ============

    /**
     * @notice Validate that an account `address(this)` has no pending orders for a market.
     * @param dataStore The data store that pending orders would be registered in.
     * @param market    The market pending orders are being checked in.
     */
    function validateNoPendingOrdersInMarket(
        IGmxV2DataStore dataStore,
        address market
    ) internal view {
        bytes32[] memory orderKeys = OrderStoreUtils.getAccountOrderKeys(
            dataStore,
            address(this)
        );

        uint256 orderKeysLength = orderKeys.length;
        for (uint256 i = 0; i < orderKeysLength; ++i) {
            address orderMarket = OrderStoreUtils.getOrderMarket(
                dataStore,
                orderKeys[i]
            );

            require(
                orderMarket != market,
                GmxFrfStrategyErrors.ORDER_VALIDATION_MARKET_HAS_PENDING_ORDERS
            );
        }
    }

    /**
     * @notice Validate the provided execution fee will cover the minimum fee for the execution.
     * @param dataStore                    The data store storage information relevant to the transaction
     * is being queried from.
     * @param orderType                    The type of order being placed.
     * @param swapPathLength               The length of the swap path.
     * @param callbackGasLimit             The gas limit on the callback for the transaction.
     * @param executionFeeBufferPercentage The buffer on the minimum provided limit to account for
     * a higher execution fee than expected.
     * @param gasPrice                     The gas price multiplier for the gas limit with buffer.
     * @param providedExecutionFee         The execution fee provided for the transaction.
     */
    function validateExecutionFee(
        IGmxV2DataStore dataStore,
        IGmxV2OrderTypes.OrderType orderType,
        uint256 swapPathLength,
        uint256 callbackGasLimit,
        uint256 executionFeeBufferPercentage,
        uint256 gasPrice,
        uint256 providedExecutionFee
    ) internal view {
        // Estimate gas limit for order type.
        uint256 calculatedGasLimit;
        if (orderType == IGmxV2OrderTypes.OrderType.MarketIncrease) {
            calculatedGasLimit = GasUtils.estimateExecuteIncreaseOrderGasLimit(
                dataStore,
                swapPathLength,
                callbackGasLimit
            );
        } else if (orderType == IGmxV2OrderTypes.OrderType.MarketDecrease) {
            calculatedGasLimit = GasUtils.estimateExecuteDecreaseOrderGasLimit(
                dataStore,
                swapPathLength,
                callbackGasLimit
            );
        } else {
            calculatedGasLimit = GasUtils.estimateExecuteSwapOrderGasLimit(
                dataStore,
                swapPathLength,
                callbackGasLimit
            );
        }

        // Get the minimum provided limit given the execution fee buffer.
        uint256 minimumProvidedLimit = calculatedGasLimit +
            calculatedGasLimit.percentToFraction(executionFeeBufferPercentage);

        // Get the fee for the provided limit.
        uint256 minimumProvidedFee = gasPrice * minimumProvidedLimit;

        require(
            providedExecutionFee >= minimumProvidedFee,
            GmxFrfStrategyErrors
                .ORDER_VALIDATION_PROVIDED_EXECUTION_FEE_IS_TOO_LOW
        );
    }

    /**
     * @notice Validate that an account `address(this)` has a position for a market.
     * @param dataStore The data store that position would be registered in.
     * @param market    The market the position is being checked in.
     */
    function validatePositionExists(
        IGmxV2DataStore dataStore,
        address market
    ) internal view {
        bytes32 key = PositionStoreUtils.getPositionKey(
            address(this),
            market,
            GmxMarketGetters.getLongToken(dataStore, market),
            false
        );
        uint256 positionSizeUsd = PositionStoreUtils.getPositionSizeUsd(
            dataStore,
            key
        );

        require(
            positionSizeUsd != 0,
            GmxFrfStrategyErrors.ORDER_VALIDATION_POSITION_DOES_NOT_EXIST
        );
    }

    /**
     * @notice Validate that the order type is enabled for the market.
     * @param ordersEnabled If the order type is enabled.
     */
    function validateOrdersEnabled(bool ordersEnabled) internal pure {
        require(
            ordersEnabled,
            GmxFrfStrategyErrors.ORDER_VALIDATION_ORDER_TYPE_IS_DISABLED
        );
    }

    /**
     * @notice Validate increase price is above minimum acceptable price.
     * @param executionPrice         The price that the order would be executed at.
     * @param minimumAcceptablePrice The minimum price allowed for executing the order.
     */
    function validateIncreaseOrderPrice(
        uint256 executionPrice,
        uint256 minimumAcceptablePrice
    ) internal pure {
        require(
            executionPrice >= minimumAcceptablePrice,
            GmxFrfStrategyErrors
                .ORDER_VALIDATION_EXECUTION_PRICE_NOT_WITHIN_SLIPPAGE_RANGE
        );
    }

    /**
     * @notice Validate decrease price is below minimum acceptable price.
     * @param executionPrice     The price that the order would be executed at.
     * @param maxAcceptablePrice The max price allowed for executing the order.
     */
    function validateDecreaseOrderPrice(
        uint256 executionPrice,
        uint256 maxAcceptablePrice
    ) internal pure {
        require(
            executionPrice <= maxAcceptablePrice,
            GmxFrfStrategyErrors
                .ORDER_VALIDATION_ACCEPTABLE_PRICE_IS_NOT_WITHIN_SLIPPAGE_BOUNDS
        );
    }

    /**
     * @notice Valide the order size is within the acceptable range for the market.
     * @param minOrderSizeUSD The minimum size in USD that the order can be.
     * @param maxOrderSizeUSD The max size in USD that the order can be.
     * @param orderSizeUSD    The size of the order in USD.
     */
    function validateOrderSize(
        uint256 minOrderSizeUSD,
        uint256 maxOrderSizeUSD,
        uint256 orderSizeUSD
    ) internal pure {
        require(
            orderSizeUSD >= minOrderSizeUSD,
            GmxFrfStrategyErrors.ORDER_VALIDATION_ORDER_SIZE_IS_TOO_SMALL
        );

        require(
            orderSizeUSD <= maxOrderSizeUSD,
            GmxFrfStrategyErrors.ORDER_VALIDATION_ORDER_SIZE_IS_TOO_LARGE
        );
    }

    /**
     * @notice Valide the position size is within the acceptable range for the market.
     * @param minPositionSizeUsd The minimum size in USD that the position can be.
     * @param maxPositionSizeUsd The max size in USD that the position can be.
     * @param positionSizeUsd    The size of the position in USD.
     */
    function validatePositionSize(
        uint256 minPositionSizeUsd,
        uint256 maxPositionSizeUsd,
        uint256 positionSizeUsd
    ) internal pure {
        require(
            positionSizeUsd == 0 || positionSizeUsd >= minPositionSizeUsd,
            GmxFrfStrategyErrors.ORDER_VALIDATION_POSITION_SIZE_IS_TOO_SMALL
        );

        require(
            positionSizeUsd <= maxPositionSizeUsd,
            GmxFrfStrategyErrors.ORDER_VALIDATION_POSITION_SIZE_IS_TOO_LARGE
        );
    }

    /**
     * @notice Validate the swap slippage, that the estimated output is greater than
     * or equal to the minimum output.
     * @param estimatedOutput The estimated output after swap slippage.
     * @param minimumOutput   The minimum output allowed after swap slippage.
     */
    function validateSwapSlippage(
        uint256 estimatedOutput,
        uint256 minimumOutput
    ) internal pure {
        require(
            estimatedOutput >= minimumOutput,
            GmxFrfStrategyErrors.ORDER_VALIDATION_SWAP_SLIPPAGE_IS_TOO_HGIH
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IStrategyAccount } from "../../../interfaces/IStrategyAccount.sol";
import {
    IGmxV2OrderTypes
} from "../../../lib/gmx/interfaces/external/IGmxV2OrderTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import { WithdrawalLogic } from "../libraries/WithdrawalLogic.sol";

/**
 * @title IGmxFrfStrategyAccount
 * @author GoldLink
 *
 * @dev Interface for interacting with a Gmx Funding rate farming strategy account.
 */
interface IGmxFrfStrategyAccount is IStrategyAccount {
    // ============ Events ============

    /// @notice Emitted when creating an increase order.
    /// @param market   The market the order was created in.
    /// @param order    The order that was created via GMX.
    /// @param orderKey The key identifying the order.
    event CreateIncreaseOrder(
        address indexed market,
        IGmxV2OrderTypes.CreateOrderParams order,
        bytes32 orderKey
    );

    /// @notice Emitted when creating a decrease order.
    /// @param market   The market the order was created in.
    /// @param order    The order that was created via GMX.
    /// @param orderKey The key identifying the order.
    event CreateDecreaseOrder(
        address indexed market,
        IGmxV2OrderTypes.CreateOrderParams order,
        bytes32 orderKey
    );

    /// @notice Emitted when canceling an order.
    /// @param orderKey The key identifying the order.
    event CancelOrder(bytes32 orderKey);

    /// @notice Emitted when claiming funding fees.
    /// @param markets The markets funding fees were claimed for.
    /// @param assets  The assets the funding fees were claimed for.
    /// @param assets  The amounts claimed for each (market, asset) pairing.
    event ClaimFundingFees(
        address[] markets,
        address[] assets,
        uint256[] claimedAmounts
    );

    /// @notice Emitted when claiming collateral.
    /// @param market  The market collateral was claimed for.
    /// @param asset   The asset the collateral was claimed for.
    /// @param timeKey The time key the collateral was claimed for.
    event ClaimCollateral(address market, address asset, uint256 timeKey);

    /// @notice Emitted when assets are liquidated.
    /// @param liquidator The address of the account that initiated the liquidation and thus recieves the rebalance fee.
    /// @param asset      The asset that was liquidated.
    /// @param asset      The asset that was liquidated.
    /// @param usdcAmountIn The amount of assets recieved from the liquidation      The asset that was liquidated.
    event LiquidateAssets(
        address indexed liquidator,
        address indexed asset,
        uint256 amount,
        uint256 usdcAmountIn
    );

    /// @notice Emitted when a liquidation order is created in a market.
    /// @param liquidator The address of the account that initiated the liquidation and thus recieves the rebalance fee.
    /// @param market     The market the order was created in.
    /// @param order      The order that was created via GMX.
    /// @param orderKey   The key identifying the order.
    event LiquidatePosition(
        address indexed liquidator,
        address indexed market,
        IGmxV2OrderTypes.CreateOrderParams order,
        bytes32 orderKey
    );

    /// @notice Emitted when a position is releveraged.
    /// @param rebalancer The address of the account that initiated the rebalance and thus recieves the rebalance fee.
    /// @param market     The market the position is in.
    /// @param order      The order that was created via GMX.
    /// @param orderKey   The key identifying the order.
    event ReleveragePosition(
        address indexed rebalancer,
        address indexed market,
        IGmxV2OrderTypes.CreateOrderParams order,
        bytes32 orderKey
    );

    /// @notice Emitted when a position is swap rebalanced.
    /// @param rebalancer      The address of the account that initiated the rebalance and thus recieves the rebalance fee.
    /// @param market          The market the position is in.
    /// @param rebalanceAmount The amount of the `asset` that left the contract.
    /// @param usdcAmountIn    The amount of USDC recieved after the rebalance is complete.
    event SwapRebalancePosition(
        address indexed rebalancer,
        address indexed market,
        uint256 rebalanceAmount,
        uint256 usdcAmountIn
    );

    /// @notice Emitted when a position is rebalanced.
    /// @param rebalancer The address of the account that initiated the rebalance and thus recieves the rebalance fee.
    /// @param market     The market the position is in.
    /// @param order   The order that was created via GMX.
    /// @param orderKey   The key identifying the order.
    event RebalancePosition(
        address indexed rebalancer,
        address indexed market,
        IGmxV2OrderTypes.CreateOrderParams order,
        bytes32 orderKey
    );

    /// @notice Emitted when excess profit is withdrawn from a strategy account.
    /// @param market    The market being withdrawn from.
    /// @param recipient The address that assets were sent to.
    /// @param amount    The amount of the `shortToken` being withdrawn.
    event WithdrawProfit(
        address indexed market,
        address indexed recipient,
        uint256 amount
    );

    /// @notice Emitted when long token assets are swapped for USDC by the strategy account owner.
    /// @param asset          The asset being swapped for.
    /// @param assetAmountOut The amount of the `asset` that left the contract.
    /// @param usdcAmountIn   The amount of USDC recieved after the swap is complete.
    event SwapAssets(
        address indexed asset,
        uint256 assetAmountOut,
        uint256 usdcAmountIn
    );

    /// @notice Emitted when the `AfterOrderExecution` callback method is hit.
    /// @param orderKey The key for the order.
    event OrderExecuted(bytes32 orderKey);

    /// @notice Emitted when the `AfterOrderExecution` callback method is hit.
    /// @param orderKey The key for the order.
    event OrderCancelled(bytes32 orderKey);

    // ============ Structs ============

    /// @dev The configuration for callbacks made through this strategy.
    struct CallbackConfig {
        // The address of the callback contract.
        address callback;
        // The address that the tokens should be sent to. In many cases it is more gas efficient for
        // the GoldLink Protocol to send tokens directly.
        address receiever;
        // The maximum tokens exchanged during the callback.
        uint256 tokenAmountMax;
    }

    // ============ External Functions ============

    /// @dev Create an order to increase a position's size. The account must have `collateralAmount` USDC in their account. Ensures delta neutrality on creation. Non-atomic.
    function executeCreateIncreaseOrder(
        address market,
        uint256 collateralAmount,
        uint256 executionFee
    )
        external
        payable
        returns (
            IGmxV2OrderTypes.CreateOrderParams memory order,
            bytes32 oderKey
        );

    /// @dev Create an order to decrease a position's size. Non-atomic.
    function executeCreateDecreaseOrder(
        address market,
        uint256 sizeDeltaUsd,
        uint256 executionFee
    )
        external
        payable
        returns (
            IGmxV2OrderTypes.CreateOrderParams memory order,
            bytes32 orderKey
        );

    /// @dev Cancels an order in a given market. Does not apply to liquidation orders.
    function executeCancelOrder(bytes32 orderKey) external;

    /// @dev Claim funding fees for the provided markets and assets. Fees are locked in the contract until the loan is repaid or they are used as collateral.
    function executeClaimFundingFees(
        address[] memory markets,
        address[] memory assets
    ) external;

    /// @dev Withdraw profit from a given market. Can only withdraw long tokens.
    function executeWithdrawProfit(
        WithdrawalLogic.WithdrawProfitParams memory params
    ) external;

    /// @dev Claim collateral in the event of a GMX collateral lock-up.
    function executeClaimCollateral(
        address market,
        address asset,
        uint256 timeKey
    ) external;

    /// @dev Atomically liquidate assets. can be called by anyone when an accounts `liquidationStatus` is `ACTIVE`. Caller recieves a fee for their service.
    function executeLiquidateAssets(
        address asset,
        uint256 amount,
        address callback,
        address receiever,
        bytes memory data
    ) external;

    /// @dev Liquidate a position by creating an order to reduce the position's size.  Non-atomic.
    function executeLiquidatePosition(
        address market,
        uint256 sizeDeltaUsd,
        uint256 executionFee
    )
        external
        payable
        returns (
            IGmxV2OrderTypes.CreateOrderParams memory order,
            bytes32 orderKey
        );

    /// @dev Releverage a position.
    function executeReleveragePosition(
        address market,
        uint256 sizeDeltaUSD,
        uint256 executionFee
    )
        external
        payable
        returns (
            IGmxV2OrderTypes.CreateOrderParams memory order,
            bytes32 orderKey
        );

    /// @dev Rebalanec a position with
    function executeSwapRebalance(
        address market,
        IGmxFrfStrategyAccount.CallbackConfig memory callbackConfig,
        bytes memory data
    ) external;

    /// @dev Rebalance a position that is outside of the configured delta range. Callable by anyone. The caller recieves a fee for their service.  Non-atomic.
    function executeRebalancePosition(
        address market,
        uint256 executionFee
    )
        external
        payable
        returns (
            IGmxV2OrderTypes.CreateOrderParams memory order,
            bytes32 orderKey
        );

    /// @dev Allows the account owner to sell assets for USDC in order to repay theirloan.
    function executeSwapAssets(
        address market,
        uint256 longTokenAmountOut,
        address callback,
        address receiver,
        bytes memory data
    ) external;

    /// @dev Call multiple methods in a single transaction without the need of a contract.
    function multicall(
        bytes[] calldata data
    ) external payable returns (bytes[] memory results);

    // ============ Public Functions ============

    /// @dev Get the value of the account in terms of USDC.
    function getAccountValue()
        external
        view
        returns (uint256 strategyAssetValue);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";

import { PercentMath } from "../../../libraries/PercentMath.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2Reader
} from "../../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2PriceTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PriceTypes.sol";
import {
    IGmxV2MarketTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2MarketTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import {
    PositionStoreUtils
} from "../../../lib/gmx/position/PositionStoreUtils.sol";
import {
    IGmxV2ReferralStorage
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";
import {
    PositionStoreUtils
} from "../../../lib/gmx/position/PositionStoreUtils.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";
import {
    GmxStorageGetters
} from "../../../strategies/gmxFrf/libraries/GmxStorageGetters.sol";
import {
    GmxMarketGetters
} from "../../../strategies/gmxFrf/libraries/GmxMarketGetters.sol";
import { IMarketConfiguration } from "../interfaces/IMarketConfiguration.sol";
import { Pricing } from "./Pricing.sol";

/**
 * @title DeltaConvergenceMath
 * @author GoldLink
 *
 * @dev Math and checks library for validating position delta.
 */
library DeltaConvergenceMath {
    using PercentMath for uint256;

    // ============ Structs ============

    struct DeltaCalculationParameters {
        address marketAddress;
        address account;
        uint256 shortTokenPrice;
        uint256 longTokenPrice;
        address uiFeeReceiver;
        IGmxV2MarketTypes.Props market;
    }

    struct DecreasePositionResult {
        uint256 positionSizeNextUsd;
        uint256 estimatedOutputUsd;
        uint256 collateralToRemove;
        uint256 executionPrice;
    }

    struct IncreasePositionResult {
        uint256 sizeDeltaUsd;
        uint256 executionPrice;
        uint256 positionSizeNextUsd;
        uint256 swapOutputTokens;
        uint256 swapOutputMarkedToMarket;
    }

    struct PositionTokenBreakdown {
        uint256 tokensShort;
        uint256 tokensLong;
        uint256 accountBalanceLongTokens;
        uint256 claimableLongTokens;
        uint256 unsettledLongTokens;
        uint256 collateralLongTokens;
        uint256 fundingAndBorrowFeesLongTokens;
        uint256 leverage;
        IGmxV2PositionTypes.PositionInfo positionInfo;
    }

    // ============ Internal Functions ============

    /**
     * @notice Get the value of a position in terms of USD. The `valueUSD` reflects the value that could be extracted from the position if it were liquidated right away,
     * and thus accounts for the price impact of closing the position.
     * @param manager    The manager that controls the strategy and maintains configuration state.
     * @param account    The account to get the position value for.
     * @param market     The market the position is for.
     * @return valueUSD  The expected value of the position after closing the position given at the current market prices and GMX pool state.
     */
    function getPositionValueUSD(
        IGmxFrfStrategyManager manager,
        address account,
        address market
    ) internal view returns (uint256 valueUSD) {
        // Passing true for `useMaxSizeDelta` because the cost of exiting the entire positon must be considered
        // (due to price impact and fees) in order properly account the estimated value.
        IGmxV2PositionTypes.PositionInfo memory positionInfo = _getPositionInfo(
            manager,
            account,
            market,
            0,
            true
        );

        (address shortToken, address longToken) = GmxMarketGetters
            .getMarketTokens(manager.gmxV2DataStore(), market);

        uint256 shortTokenPrice = Pricing.getUnitTokenPriceUSD(
            manager,
            shortToken
        );

        uint256 longTokenPrice = Pricing.getUnitTokenPriceUSD(
            manager,
            longToken
        );

        return
            getPositionValueUSD(positionInfo, shortTokenPrice, longTokenPrice);
    }

    /**
     * @notice Get the value of a position in terms of USD. The `valueUSD` reflects the value that could be extracted from the position if it were liquidated right away,
     * and thus accounts for the price impact of closing the position.
     * @param positionInfo    The position information, which is queried from GMX via the `Reader.getPositionInfo` function.
     * @param shortTokenPrice The price of the short token.
     * @param longTokenPrice  The price of the long token.
     * @return valueUSD       The expected value of the position after closing the position given at the current market prices and GMX pool state. This value can only be considered an estimate,
     * as asset prices can change in between the time the value is calculated and when the GMX keeper actually executes the order. Furthermore, price impact can change during this period,
     * as other state changing actions can effect the GMX pool, resulting in a different price impact values.
     */
    function getPositionValueUSD(
        IGmxV2PositionTypes.PositionInfo memory positionInfo,
        uint256 shortTokenPrice,
        uint256 longTokenPrice
    ) internal pure returns (uint256 valueUSD) {
        // The value of a position is made up of the following fields:
        // 1. The value of the collateral.
        // 2. The value of unsettled positive funding fees, which consist of both shortTokens and longTokens.
        // 3. The loss of value due to borrowing fees and negative fees, which consist strictly of the `collateralToken.` At the time of decreasing the position, this value is offset by profit if possible,
        // however, this is not accounted for in the PnL.
        // 4. The PnL, which is a signed integer representing the profit or loss of the position.
        // 5. The loss due to the price impact of closing the position, which is ultimately included in the `positionPnlIncludingPriceImpactUsd` field.
        // 6. The loss due to the price impact of swapping the collateral token into USDC.

        // It is important to also not the values that may be related to the position but are not included in the value of the position.
        // 1. The unclaimed, settled funding fees are not included in the value of a position because, once settled, they are inherently seperate and can be atomically claimed.
        //    Furthermore, they are not "locked" in the position and can be though of as an auxiliary token balance.
        // 2. The value of the ERC20 tokens in the account. These do not relate to the position that is held on GMX and therefore are factored into the value of the account separately.

        // This accounts for the value of the unsettled short token funding fees.
        valueUSD += Pricing.getTokenValueUSD(
            positionInfo.fees.funding.claimableShortTokenAmount,
            shortTokenPrice
        );

        // The amount of collateral tokens initially held in the position, before accounting for fees, is just the collateral token amount plus the unclaimed funding fees.
        // These are all measured in terms of the longToken of the GMX market, which is also always the token that Goldlink uses to collateralize the position.
        uint256 collateralTokenHeldInPosition = positionInfo
            .position
            .numbers
            .collateralAmount +
            positionInfo.fees.funding.claimableLongTokenAmount;

        // The cost is measured in terms of the collateral token, which includes the GMX borrowing fees and negative funding fees.
        // Therefore, subtract the cost from the collateral tokens to recieve the net amount of collateral tokens held in the position.
        collateralTokenHeldInPosition -= Math.min(
            collateralTokenHeldInPosition,
            positionInfo.fees.totalCostAmount
        );

        // This accounts for the value of the collateral, the unsettled long token funding fees, the negative funding fee amount, the borrowing fees, the UI fee,
        // and the positive impact of the referral bonus.
        valueUSD += Pricing.getTokenValueUSD(
            collateralTokenHeldInPosition,
            longTokenPrice
        );

        // The absolute value of the pnl in terms of USD. This also includes the price impact of closing the position,
        // which can either increase or decrease the value of the position. It is important to include the price impact because for large positions,
        // liquidation may result in high slippage, which can result in the loss of lender funds. In order to trigger liquidations for these positions early, including the price impact
        // in the calculation of the position value is necessary.
        uint256 absPnlAfterPriceImpactUSD = SignedMath.abs(
            positionInfo.pnlAfterPriceImpactUsd
        );

        return
            (positionInfo.pnlAfterPriceImpactUsd < 0)
                ? valueUSD - Math.min(absPnlAfterPriceImpactUSD, valueUSD)
                : valueUSD + absPnlAfterPriceImpactUSD;
    }

    /**
     * @notice Get the market delta for an account, which gives a breakdown of the position encompassed by `market`.
     * @param manager         The configuration manager for the strategy.
     * @param account         The account to get the market delta for.
     * @param sizeDeltaUsd    The size delta to evaluate based off.
     * @param useMaxSizeDelta Whether to use the max size delta.
     */
    function getAccountMarketDelta(
        IGmxFrfStrategyManager manager,
        address account,
        address market,
        uint256 sizeDeltaUsd,
        bool useMaxSizeDelta
    ) internal view returns (PositionTokenBreakdown memory breakdown) {
        // If the market is not approved, then there is zero delta.
        if (!manager.isApprovedMarket(market)) {
            return breakdown;
        }

        // Get the long token for the market.
        (, address longToken) = GmxMarketGetters.getMarketTokens(
            manager.gmxV2DataStore(),
            market
        );

        breakdown.accountBalanceLongTokens = IERC20(longToken).balanceOf(
            account
        );
        breakdown.tokensLong += breakdown.accountBalanceLongTokens;

        // Claimable funding fees are considered as long tokens.
        breakdown.claimableLongTokens += GmxStorageGetters
            .getClaimableFundingFees(
                manager.gmxV2DataStore(),
                market,
                longToken,
                account
            );

        breakdown.tokensLong += breakdown.claimableLongTokens;

        // Get the position information.
        breakdown.positionInfo = _getPositionInfo(
            manager,
            account,
            market,
            sizeDeltaUsd,
            useMaxSizeDelta
        );

        // Position collateral.
        breakdown.collateralLongTokens = breakdown
            .positionInfo
            .position
            .numbers
            .collateralAmount;
        breakdown.tokensLong += breakdown.collateralLongTokens;

        // Unclaimed funding fees.
        breakdown.unsettledLongTokens = breakdown
            .positionInfo
            .fees
            .funding
            .fundingFeeAmount;
        breakdown.tokensLong += breakdown.unsettledLongTokens;

        // Position size.
        breakdown.tokensShort += breakdown
            .positionInfo
            .position
            .numbers
            .sizeInTokens;

        breakdown.fundingAndBorrowFeesLongTokens =
            breakdown.positionInfo.fees.funding.fundingFeeAmount +
            breakdown.positionInfo.fees.borrowing.borrowingFeeAmount;

        // This should not normally happen, but it can in the event that someone checks for the delta
        // of a position before a GMX keeper liquidates the underwater position.

        breakdown.tokensLong -= Math.min(
            breakdown.fundingAndBorrowFeesLongTokens,
            breakdown.tokensLong
        );

        breakdown.leverage = _getLeverage(manager, market, breakdown);

        return breakdown;
    }

    function getIncreaseOrderValues(
        IGmxFrfStrategyManager manager,
        uint256 initialCollateralDeltaAmount,
        DeltaCalculationParameters memory values
    ) internal view returns (IncreasePositionResult memory result) {
        // First we need to see if an active position exists, because `getPositionInfo` will revert if it does not exist.
        IGmxV2MarketTypes.MarketPrices memory prices = _makeMarketPrices(
            values.shortTokenPrice,
            values.longTokenPrice
        );

        // We need to figure out the expected swap output given the initial collateral delta amount.
        (result.swapOutputTokens, , ) = manager.gmxV2Reader().getSwapAmountOut(
            manager.gmxV2DataStore(),
            values.market,
            prices,
            values.market.shortToken,
            initialCollateralDeltaAmount,
            values.uiFeeReceiver
        );

        bytes32 positionKey = PositionStoreUtils.getPositionKey(
            values.account,
            values.marketAddress,
            values.market.longToken,
            false
        );

        // Get position information if one already exists.
        IGmxV2PositionTypes.PositionInfo memory info;
        if (
            PositionStoreUtils.getPositionSizeUsd(
                manager.gmxV2DataStore(),
                positionKey
            ) != 0
        ) {
            info = manager.gmxV2Reader().getPositionInfo(
                manager.gmxV2DataStore(),
                manager.gmxV2ReferralStorage(),
                positionKey,
                prices,
                0,
                values.uiFeeReceiver,
                true
            );
        }

        uint256 collateralAfterSwapTokens = info
            .position
            .numbers
            .collateralAmount +
            result.swapOutputTokens -
            info.fees.funding.fundingFeeAmount -
            info.fees.borrowing.borrowingFeeAmount;

        uint256 sizeDeltaEstimate = getIncreaseSizeDelta(
            info.position.numbers.sizeInTokens,
            collateralAfterSwapTokens,
            values.longTokenPrice
        );

        // Estimate the execution price with the estimated size delta.
        IGmxV2PriceTypes.ExecutionPriceResult memory executionPrices = manager
            .gmxV2Reader()
            .getExecutionPrice(
                manager.gmxV2DataStore(),
                values.marketAddress,
                IGmxV2PriceTypes.Props(
                    values.longTokenPrice,
                    values.longTokenPrice
                ),
                info.position.numbers.sizeInUsd,
                info.position.numbers.sizeInTokens,
                int256(sizeDeltaEstimate),
                false
            );

        // Recompute size delta using the execution price.
        result.sizeDeltaUsd = getIncreaseSizeDelta(
            info.position.numbers.sizeInTokens,
            collateralAfterSwapTokens,
            executionPrices.executionPrice
        );

        result.positionSizeNextUsd =
            info.position.numbers.sizeInUsd +
            result.sizeDeltaUsd;

        result.executionPrice = executionPrices.executionPrice;

        result.swapOutputMarkedToMarket = Math.mulDiv(
            initialCollateralDeltaAmount,
            values.shortTokenPrice,
            values.longTokenPrice
        );

        return result;
    }

    function getDecreaseOrderValues(
        IGmxFrfStrategyManager manager,
        uint256 sizeDeltaUsd,
        DeltaCalculationParameters memory values
    ) internal view returns (DecreasePositionResult memory result) {
        PositionTokenBreakdown memory breakdown = getAccountMarketDelta(
            manager,
            values.account,
            values.marketAddress,
            sizeDeltaUsd,
            false
        );

        // The total cost amount is equal to the sum of the fees associated with the decrease, in terms of the collateral token.
        // This accounts for negative funding fees, borrowing fees,
        uint256 collateralLostInDecrease = breakdown
            .positionInfo
            .fees
            .totalCostAmount;

        {
            uint256 profitInCollateralToken = SignedMath.abs(
                breakdown.positionInfo.pnlAfterPriceImpactUsd
            ) / values.longTokenPrice;

            if (breakdown.positionInfo.pnlAfterPriceImpactUsd > 0) {
                collateralLostInDecrease -= Math.min(
                    collateralLostInDecrease,
                    profitInCollateralToken
                ); // Offset the loss in collateral with position profits.
            } else {
                collateralLostInDecrease += profitInCollateralToken; // adding because this variable is meant to represent a net loss in collateral.
            }
        }

        uint256 sizeDeltaActual = Math.min(
            sizeDeltaUsd,
            breakdown.positionInfo.position.numbers.sizeInUsd
        );

        result.positionSizeNextUsd =
            breakdown.positionInfo.position.numbers.sizeInUsd -
            sizeDeltaActual;

        uint256 shortTokensAfterDecrease;

        {
            uint256 proportionalDecrease = sizeDeltaActual.fractionToPercent(
                breakdown.positionInfo.position.numbers.sizeInUsd
            );

            shortTokensAfterDecrease =
                breakdown.tokensShort -
                breakdown
                    .positionInfo
                    .position
                    .numbers
                    .sizeInTokens
                    .percentToFraction(proportionalDecrease);
        }

        uint256 longTokensAfterDecrease = breakdown.tokensLong -
            collateralLostInDecrease;

        // This is the difference in long vs short tokens currently.
        uint256 imbalance = Math.max(
            shortTokensAfterDecrease,
            longTokensAfterDecrease
        ) - Math.min(shortTokensAfterDecrease, longTokensAfterDecrease);

        if (shortTokensAfterDecrease < longTokensAfterDecrease) {
            // We need to remove long tokens equivalent to the imbalance to make the position delta neutral.
            // However, it is possible that there are a significant number of long tokens in the contract that are impacting the imbalance.
            // If this is the case, then if we were to simply remove the imbalance, it can result in a position with very high leverage. Therefore, we will simply remove
            // the minimum of `collateralAmount - collateralLostInDecrease` the difference in the longCollateral and shortTokens. The rest of the delta imbalance can be left to rebalancers.
            uint256 remainingCollateral = breakdown
                .positionInfo
                .position
                .numbers
                .collateralAmount - collateralLostInDecrease;

            if (remainingCollateral > shortTokensAfterDecrease) {
                result.collateralToRemove = Math.min(
                    remainingCollateral - shortTokensAfterDecrease,
                    imbalance
                );
            }
        }

        if (result.collateralToRemove != 0) {
            (uint256 expectedSwapOutput, , ) = manager
                .gmxV2Reader()
                .getSwapAmountOut(
                    manager.gmxV2DataStore(),
                    values.market,
                    _makeMarketPrices(
                        values.shortTokenPrice,
                        values.longTokenPrice
                    ),
                    values.market.longToken,
                    result.collateralToRemove,
                    values.uiFeeReceiver
                );

            result.estimatedOutputUsd =
                expectedSwapOutput *
                values.shortTokenPrice;
        }

        if (breakdown.positionInfo.pnlAfterPriceImpactUsd > 0) {
            result.estimatedOutputUsd += SignedMath.abs(
                breakdown.positionInfo.pnlAfterPriceImpactUsd
            );
        }

        result.executionPrice = breakdown
            .positionInfo
            .executionPriceResult
            .executionPrice;
    }

    /**
     * @notice Get prices of a short and long token.
     * @param manager          The IGmxFrfStrategyManager of the strategy.
     * @param shortToken       The short token whose price is being queried.
     * @param longToken        The long token whose price is being queried.
     * @return shortTokenPrice The price of the short token.
     * @return longTokenPrice  The price of the long token.
     */
    function getMarketPrices(
        IGmxFrfStrategyManager manager,
        address shortToken,
        address longToken
    ) internal view returns (uint256 shortTokenPrice, uint256 longTokenPrice) {
        shortTokenPrice = Pricing.getUnitTokenPriceUSD(manager, shortToken);

        longTokenPrice = Pricing.getUnitTokenPriceUSD(manager, longToken);

        return (shortTokenPrice, longTokenPrice);
    }

    function getIncreaseSizeDelta(
        uint256 currentShortPositionSizeTokens,
        uint256 collateralAfterSwapTokens,
        uint256 executionPrice
    ) internal pure returns (uint256) {
        if (collateralAfterSwapTokens < currentShortPositionSizeTokens) {
            return 0;
        }

        uint256 diff = collateralAfterSwapTokens -
            currentShortPositionSizeTokens;

        return diff * executionPrice;
    }

    /**
     * @notice Get delta proportion, the proportion of the position that is directional.
     * @param shortPositionSizeTokens The size of the short position.
     * @param longPositionSizeTokens  The size of the long position.
     * @return proportion             The proportion of the position that is directional.
     * @return isShort                If the direction is short.
     */
    function getDeltaProportion(
        uint256 shortPositionSizeTokens,
        uint256 longPositionSizeTokens
    ) internal pure returns (uint256 proportion, bool isShort) {
        // Get the direction of the position.
        isShort = shortPositionSizeTokens > longPositionSizeTokens;

        // Get the proportion of the position that is directional.
        proportion = (isShort)
            ? shortPositionSizeTokens.fractionToPercent(longPositionSizeTokens)
            : longPositionSizeTokens.fractionToPercent(shortPositionSizeTokens);
    }

    // ============ Private Functions ============

    function _getLeverage(
        IGmxFrfStrategyManager manager,
        address market,
        PositionTokenBreakdown memory breakdown
    ) private view returns (uint256 leverage) {
        if (breakdown.positionInfo.position.numbers.sizeInUsd == 0) {
            // Position with 0 size has 0 leverage.
            return 0;
        }

        // The important part here is the position info, not the tokens held in the account. The leverage of the position as GMX sees it is as follows:
        // Short Position Size: Fixed number in terms of USD representing the size of the short. This only changes when you increase or decrease the size, and is not affected by changes in price.
        // Collateral in tokens is gotten by fetching the position `collateralAmount` and subtracting the `totalCostAmount` from that.

        uint256 collateralInTokens = breakdown
            .positionInfo
            .position
            .numbers
            .collateralAmount - breakdown.positionInfo.fees.totalCostAmount;

        uint256 longTokenPrice = Pricing.getUnitTokenPriceUSD(
            manager,
            GmxMarketGetters.getLongToken(manager.gmxV2DataStore(), market)
        );

        // Only negative price impact contributes to the collateral value, positive price impact is not considered when a position is being liquidated.
        if (breakdown.positionInfo.executionPriceResult.priceImpactUsd < 0) {
            collateralInTokens -=
                uint256(
                    -breakdown.positionInfo.executionPriceResult.priceImpactUsd
                ) /
                longTokenPrice;
        }

        // The absolute value of the pnl in tokens.
        uint256 absPnlTokens = SignedMath.abs(
            breakdown.positionInfo.basePnlUsd
        ) / longTokenPrice;

        if (breakdown.positionInfo.basePnlUsd < 0) {
            collateralInTokens -= Math.min(absPnlTokens, collateralInTokens);
        } else {
            collateralInTokens += absPnlTokens;
        }

        if (collateralInTokens == 0) {
            return type(uint256).max;
        }

        // Make sure to convert collateral tokens back to USD.
        leverage = breakdown
            .positionInfo
            .position
            .numbers
            .sizeInUsd
            .fractionToPercent(collateralInTokens * longTokenPrice);

        return leverage;
    }

    function _makeMarketPrices(
        uint256 shortTokenPrice,
        uint256 longTokenPrice
    ) private pure returns (IGmxV2MarketTypes.MarketPrices memory) {
        return
            IGmxV2MarketTypes.MarketPrices(
                IGmxV2PriceTypes.Props(longTokenPrice, longTokenPrice),
                IGmxV2PriceTypes.Props(longTokenPrice, longTokenPrice),
                IGmxV2PriceTypes.Props(shortTokenPrice, shortTokenPrice)
            );
    }

    function _makeMarketPrices(
        IGmxFrfStrategyManager manager,
        address shortToken,
        address longToken
    ) private view returns (IGmxV2MarketTypes.MarketPrices memory) {
        (uint256 shortTokenPrice, uint256 longTokenPrice) = getMarketPrices(
            manager,
            shortToken,
            longToken
        );

        return _makeMarketPrices(shortTokenPrice, longTokenPrice);
    }

    function _getPositionInfo(
        IGmxFrfStrategyManager manager,
        address account,
        address market,
        uint256 sizeDeltaUsd,
        bool useMaxSizeDelta
    ) private view returns (IGmxV2PositionTypes.PositionInfo memory position) {
        (address shortToken, address longToken) = GmxMarketGetters
            .getMarketTokens(manager.gmxV2DataStore(), market);

        // Key is just the hash of the account, market, collateral token and a boolean representing whether or not the position is long.
        // Since the strategy only allows short positions, the position is always short and thus we pass in false to get the position key.
        // Furthermore, since a short position can only be hedged properly with the long token of a market, which the strategy enforces,
        // the long token is always the collateral token.
        bytes32 positionKey = PositionStoreUtils.getPositionKey(
            account,
            market,
            longToken,
            false
        );

        // If no position exists, then there are no values to consider. Furthermore, this prevents `Reader.getPositionInfo` from reverting.
        if (
            PositionStoreUtils.getPositionSizeUsd(
                manager.gmxV2DataStore(),
                positionKey
            ) == 0
        ) {
            return position;
        }

        position = manager.gmxV2Reader().getPositionInfo(
            manager.gmxV2DataStore(),
            manager.gmxV2ReferralStorage(),
            positionKey,
            _makeMarketPrices(manager, shortToken, longToken),
            sizeDeltaUsd,
            manager.getUiFeeReceiver(),
            useMaxSizeDelta
        );

        return position;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    IWrappedNativeToken
} from "../../../adapters/shared/interfaces/IWrappedNativeToken.sol";
import {
    IGmxV2ExchangeRouter
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ExchangeRouter.sol";
import {
    IGmxV2Reader
} from "../../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2RoleStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2RoleStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";
import { ISwapCallbackRelayer } from "./ISwapCallbackRelayer.sol";

/**
 * @title IDeploymentConfiguration
 * @author GoldLink
 *
 * @dev Actions that can be performed by the GMX V2 Adapter Controller.
 */
interface IDeploymentConfiguration {
    // ============ Structs ============

    struct Deployments {
        IGmxV2ExchangeRouter exchangeRouter;
        address orderVault;
        IGmxV2Reader reader;
        IGmxV2DataStore dataStore;
        IGmxV2RoleStore roleStore;
        IGmxV2ReferralStorage referralStorage;
    }

    // ============ Events ============

    /// @notice Emitted when setting the exchange router.
    /// @param exchangeRouter The address of the exhcange router being set.
    event ExchangeRouterSet(address exchangeRouter);

    /// @notice Emitted when setting the order vault.
    /// @param orderVault The address of the order vault being set.
    event OrderVaultSet(address orderVault);

    /// @notice Emitted when setting the reader.
    /// @param reader The address of the reader being set.
    event ReaderSet(address reader);

    /// @notice Emitted when setting the data store.
    /// @param dataStore The address of the data store being set.
    event DataStoreSet(address dataStore);

    /// @notice Emitted when setting the role store.
    /// @param roleStore The address of the role store being set.
    event RoleStoreSet(address roleStore);

    /// @notice Emitted when setting the referral storage.
    /// @param referralStorage The address of the referral storage being set.
    event ReferralStorageSet(address referralStorage);

    // ============ External Functions ============

    /// @dev Set the exchange router for the strategy.
    function setExchangeRouter(IGmxV2ExchangeRouter exchangeRouter) external;

    /// @dev Set the order vault for the strategy.
    function setOrderVault(address orderVault) external;

    /// @dev Set the reader for the strategy.
    function setReader(IGmxV2Reader reader) external;

    /// @dev Set the data store for the strategy.
    function setDataStore(IGmxV2DataStore dataStore) external;

    /// @dev Set the role store for the strategy.
    function setRoleStore(IGmxV2RoleStore roleStore) external;

    /// @dev Set the referral storage for the strategy.
    function setReferralStorage(IGmxV2ReferralStorage referralStorage) external;

    /// @dev Get the configured Gmx V2 `ExchangeRouter` deployment address.
    function gmxV2ExchangeRouter() external view returns (IGmxV2ExchangeRouter);

    /// @dev Get the configured Gmx V2 `OrderVault` deployment address.
    function gmxV2OrderVault() external view returns (address);

    /// @dev Get the configured Gmx V2 `Reader` deployment address.
    function gmxV2Reader() external view returns (IGmxV2Reader);

    /// @dev Get the configured Gmx V2 `DataStore` deployment address.
    function gmxV2DataStore() external view returns (IGmxV2DataStore);

    /// @dev Get the configured Gmx V2 `RoleStore` deployment address.
    function gmxV2RoleStore() external view returns (IGmxV2RoleStore);

    /// @dev Get the configured Gmx V2 `ReferralStorage` deployment address.
    function gmxV2ReferralStorage()
        external
        view
        returns (IGmxV2ReferralStorage);

    /// @dev Get the usdc deployment address.
    function USDC() external view returns (IERC20);

    /// @dev Get the wrapped native token deployment address.
    function WRAPPED_NATIVE_TOKEN() external view returns (IWrappedNativeToken);

    /// @dev The collateral claim distributor.
    function COLLATERAL_CLAIM_DISTRIBUTOR() external view returns (address);

    /// @dev Get the wrapped native token deployment address.
    function SWAP_CALLBACK_RELAYER()
        external
        view
        returns (ISwapCallbackRelayer);
}

// SPDX-License-Identifier: BUSL-1.1

// Taken directly from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/data/Keys.sol

pragma solidity ^0.8.0;

library Keys {
    // ============ Constants ============

    // @dev key for the address of the wrapped native token
    bytes32 public constant WNT = keccak256(abi.encode("WNT"));
    // @dev key for the nonce value used in NonceUtils
    bytes32 public constant NONCE = keccak256(abi.encode("NONCE"));

    // @dev for sending received fees
    bytes32 public constant FEE_RECEIVER =
        keccak256(abi.encode("FEE_RECEIVER"));

    // @dev for holding tokens that could not be sent out
    bytes32 public constant HOLDING_ADDRESS =
        keccak256(abi.encode("HOLDING_ADDRESS"));

    // @dev key for in strict price feed mode
    bytes32 public constant IN_STRICT_PRICE_FEED_MODE =
        keccak256(abi.encode("IN_STRICT_PRICE_FEED_MODE"));

    // @dev key for the minimum gas for execution error
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS =
        keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS"));

    // @dev key for the minimum gas that should be forwarded for execution error handling
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD =
        keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD"));

    // @dev key for the min additional gas for execution
    bytes32 public constant MIN_ADDITIONAL_GAS_FOR_EXECUTION =
        keccak256(abi.encode("MIN_ADDITIONAL_GAS_FOR_EXECUTION"));

    // @dev for a global reentrancy guard
    bytes32 public constant REENTRANCY_GUARD_STATUS =
        keccak256(abi.encode("REENTRANCY_GUARD_STATUS"));

    // @dev key for deposit fees
    bytes32 public constant DEPOSIT_FEE_TYPE =
        keccak256(abi.encode("DEPOSIT_FEE_TYPE"));
    // @dev key for withdrawal fees
    bytes32 public constant WITHDRAWAL_FEE_TYPE =
        keccak256(abi.encode("WITHDRAWAL_FEE_TYPE"));
    // @dev key for swap fees
    bytes32 public constant SWAP_FEE_TYPE =
        keccak256(abi.encode("SWAP_FEE_TYPE"));
    // @dev key for position fees
    bytes32 public constant POSITION_FEE_TYPE =
        keccak256(abi.encode("POSITION_FEE_TYPE"));
    // @dev key for ui deposit fees
    bytes32 public constant UI_DEPOSIT_FEE_TYPE =
        keccak256(abi.encode("UI_DEPOSIT_FEE_TYPE"));
    // @dev key for ui withdrawal fees
    bytes32 public constant UI_WITHDRAWAL_FEE_TYPE =
        keccak256(abi.encode("UI_WITHDRAWAL_FEE_TYPE"));
    // @dev key for ui swap fees
    bytes32 public constant UI_SWAP_FEE_TYPE =
        keccak256(abi.encode("UI_SWAP_FEE_TYPE"));
    // @dev key for ui position fees
    bytes32 public constant UI_POSITION_FEE_TYPE =
        keccak256(abi.encode("UI_POSITION_FEE_TYPE"));

    // @dev key for ui fee factor
    bytes32 public constant UI_FEE_FACTOR =
        keccak256(abi.encode("UI_FEE_FACTOR"));
    // @dev key for max ui fee receiver factor
    bytes32 public constant MAX_UI_FEE_FACTOR =
        keccak256(abi.encode("MAX_UI_FEE_FACTOR"));

    // @dev key for the claimable fee amount
    bytes32 public constant CLAIMABLE_FEE_AMOUNT =
        keccak256(abi.encode("CLAIMABLE_FEE_AMOUNT"));
    // @dev key for the claimable ui fee amount
    bytes32 public constant CLAIMABLE_UI_FEE_AMOUNT =
        keccak256(abi.encode("CLAIMABLE_UI_FEE_AMOUNT"));

    // @dev key for the market list
    bytes32 public constant MARKET_LIST = keccak256(abi.encode("MARKET_LIST"));

    // @dev key for the fee batch list
    bytes32 public constant FEE_BATCH_LIST =
        keccak256(abi.encode("FEE_BATCH_LIST"));

    // @dev key for the deposit list
    bytes32 public constant DEPOSIT_LIST =
        keccak256(abi.encode("DEPOSIT_LIST"));
    // @dev key for the account deposit list
    bytes32 public constant ACCOUNT_DEPOSIT_LIST =
        keccak256(abi.encode("ACCOUNT_DEPOSIT_LIST"));

    // @dev key for the withdrawal list
    bytes32 public constant WITHDRAWAL_LIST =
        keccak256(abi.encode("WITHDRAWAL_LIST"));
    // @dev key for the account withdrawal list
    bytes32 public constant ACCOUNT_WITHDRAWAL_LIST =
        keccak256(abi.encode("ACCOUNT_WITHDRAWAL_LIST"));

    // @dev key for the position list
    bytes32 public constant POSITION_LIST =
        keccak256(abi.encode("POSITION_LIST"));
    // @dev key for the account position list
    bytes32 public constant ACCOUNT_POSITION_LIST =
        keccak256(abi.encode("ACCOUNT_POSITION_LIST"));

    // @dev key for the order list
    bytes32 public constant ORDER_LIST = keccak256(abi.encode("ORDER_LIST"));
    // @dev key for the account order list
    bytes32 public constant ACCOUNT_ORDER_LIST =
        keccak256(abi.encode("ACCOUNT_ORDER_LIST"));

    // @dev key for the subaccount list
    bytes32 public constant SUBACCOUNT_LIST =
        keccak256(abi.encode("SUBACCOUNT_LIST"));

    // @dev key for is market disabled
    bytes32 public constant IS_MARKET_DISABLED =
        keccak256(abi.encode("IS_MARKET_DISABLED"));

    // @dev key for the max swap path length allowed
    bytes32 public constant MAX_SWAP_PATH_LENGTH =
        keccak256(abi.encode("MAX_SWAP_PATH_LENGTH"));
    // @dev key used to store markets observed in a swap path, to ensure that a swap path contains unique markets
    bytes32 public constant SWAP_PATH_MARKET_FLAG =
        keccak256(abi.encode("SWAP_PATH_MARKET_FLAG"));
    // @dev key used to store the min market tokens for the first deposit for a market
    bytes32 public constant MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT =
        keccak256(abi.encode("MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT"));

    // @dev key for whether the create deposit feature is disabled
    bytes32 public constant CREATE_DEPOSIT_FEATURE_DISABLED =
        keccak256(abi.encode("CREATE_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the cancel deposit feature is disabled
    bytes32 public constant CANCEL_DEPOSIT_FEATURE_DISABLED =
        keccak256(abi.encode("CANCEL_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the execute deposit feature is disabled
    bytes32 public constant EXECUTE_DEPOSIT_FEATURE_DISABLED =
        keccak256(abi.encode("EXECUTE_DEPOSIT_FEATURE_DISABLED"));

    // @dev key for whether the create withdrawal feature is disabled
    bytes32 public constant CREATE_WITHDRAWAL_FEATURE_DISABLED =
        keccak256(abi.encode("CREATE_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the cancel withdrawal feature is disabled
    bytes32 public constant CANCEL_WITHDRAWAL_FEATURE_DISABLED =
        keccak256(abi.encode("CANCEL_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the execute withdrawal feature is disabled
    bytes32 public constant EXECUTE_WITHDRAWAL_FEATURE_DISABLED =
        keccak256(abi.encode("EXECUTE_WITHDRAWAL_FEATURE_DISABLED"));

    // @dev key for whether the create order feature is disabled
    bytes32 public constant CREATE_ORDER_FEATURE_DISABLED =
        keccak256(abi.encode("CREATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute order feature is disabled
    bytes32 public constant EXECUTE_ORDER_FEATURE_DISABLED =
        keccak256(abi.encode("EXECUTE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute adl feature is disabled
    // for liquidations, it can be disabled by using the EXECUTE_ORDER_FEATURE_DISABLED key with the Liquidation
    // order type, ADL orders have a MarketDecrease order type, so a separate key is needed to disable it
    bytes32 public constant EXECUTE_ADL_FEATURE_DISABLED =
        keccak256(abi.encode("EXECUTE_ADL_FEATURE_DISABLED"));
    // @dev key for whether the update order feature is disabled
    bytes32 public constant UPDATE_ORDER_FEATURE_DISABLED =
        keccak256(abi.encode("UPDATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the cancel order feature is disabled
    bytes32 public constant CANCEL_ORDER_FEATURE_DISABLED =
        keccak256(abi.encode("CANCEL_ORDER_FEATURE_DISABLED"));

    // @dev key for whether the claim funding fees feature is disabled
    bytes32 public constant CLAIM_FUNDING_FEES_FEATURE_DISABLED =
        keccak256(abi.encode("CLAIM_FUNDING_FEES_FEATURE_DISABLED"));
    // @dev key for whether the claim collateral feature is disabled
    bytes32 public constant CLAIM_COLLATERAL_FEATURE_DISABLED =
        keccak256(abi.encode("CLAIM_COLLATERAL_FEATURE_DISABLED"));
    // @dev key for whether the claim affiliate rewards feature is disabled
    bytes32 public constant CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED =
        keccak256(abi.encode("CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED"));
    // @dev key for whether the claim ui fees feature is disabled
    bytes32 public constant CLAIM_UI_FEES_FEATURE_DISABLED =
        keccak256(abi.encode("CLAIM_UI_FEES_FEATURE_DISABLED"));
    // @dev key for whether the subaccount feature is disabled
    bytes32 public constant SUBACCOUNT_FEATURE_DISABLED =
        keccak256(abi.encode("SUBACCOUNT_FEATURE_DISABLED"));

    // @dev key for the minimum required oracle signers for an oracle observation
    bytes32 public constant MIN_ORACLE_SIGNERS =
        keccak256(abi.encode("MIN_ORACLE_SIGNERS"));
    // @dev key for the minimum block confirmations before blockhash can be excluded for oracle signature validation
    bytes32 public constant MIN_ORACLE_BLOCK_CONFIRMATIONS =
        keccak256(abi.encode("MIN_ORACLE_BLOCK_CONFIRMATIONS"));
    // @dev key for the maximum usable oracle price age in seconds
    bytes32 public constant MAX_ORACLE_PRICE_AGE =
        keccak256(abi.encode("MAX_ORACLE_PRICE_AGE"));
    // @dev key for the maximum oracle price deviation factor from the ref price
    bytes32 public constant MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR =
        keccak256(abi.encode("MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR"));
    // @dev key for the percentage amount of position fees to be received
    bytes32 public constant POSITION_FEE_RECEIVER_FACTOR =
        keccak256(abi.encode("POSITION_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of swap fees to be received
    bytes32 public constant SWAP_FEE_RECEIVER_FACTOR =
        keccak256(abi.encode("SWAP_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of borrowing fees to be received
    bytes32 public constant BORROWING_FEE_RECEIVER_FACTOR =
        keccak256(abi.encode("BORROWING_FEE_RECEIVER_FACTOR"));

    // @dev key for the base gas limit used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_BASE_AMOUNT =
        keccak256(abi.encode("ESTIMATED_GAS_FEE_BASE_AMOUNT"));
    // @dev key for the multiplier used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR =
        keccak256(abi.encode("ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the base gas limit used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_BASE_AMOUNT =
        keccak256(abi.encode("EXECUTION_GAS_FEE_BASE_AMOUNT"));
    // @dev key for the multiplier used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_MULTIPLIER_FACTOR =
        keccak256(abi.encode("EXECUTION_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the estimated gas limit for deposits
    bytes32 public constant DEPOSIT_GAS_LIMIT =
        keccak256(abi.encode("DEPOSIT_GAS_LIMIT"));
    // @dev key for the estimated gas limit for withdrawals
    bytes32 public constant WITHDRAWAL_GAS_LIMIT =
        keccak256(abi.encode("WITHDRAWAL_GAS_LIMIT"));
    // @dev key for the estimated gas limit for single swaps
    bytes32 public constant SINGLE_SWAP_GAS_LIMIT =
        keccak256(abi.encode("SINGLE_SWAP_GAS_LIMIT"));
    // @dev key for the estimated gas limit for increase orders
    bytes32 public constant INCREASE_ORDER_GAS_LIMIT =
        keccak256(abi.encode("INCREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for decrease orders
    bytes32 public constant DECREASE_ORDER_GAS_LIMIT =
        keccak256(abi.encode("DECREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for swap orders
    bytes32 public constant SWAP_ORDER_GAS_LIMIT =
        keccak256(abi.encode("SWAP_ORDER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for token transfers
    bytes32 public constant TOKEN_TRANSFER_GAS_LIMIT =
        keccak256(abi.encode("TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for native token transfers
    bytes32 public constant NATIVE_TOKEN_TRANSFER_GAS_LIMIT =
        keccak256(abi.encode("NATIVE_TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the maximum request block age, after which the request will be considered expired
    bytes32 public constant REQUEST_EXPIRATION_BLOCK_AGE =
        keccak256(abi.encode("REQUEST_EXPIRATION_BLOCK_AGE"));

    bytes32 public constant MAX_CALLBACK_GAS_LIMIT =
        keccak256(abi.encode("MAX_CALLBACK_GAS_LIMIT"));
    bytes32 public constant SAVED_CALLBACK_CONTRACT =
        keccak256(abi.encode("SAVED_CALLBACK_CONTRACT"));

    // @dev key for the min collateral factor
    bytes32 public constant MIN_COLLATERAL_FACTOR =
        keccak256(abi.encode("MIN_COLLATERAL_FACTOR"));
    // @dev key for the min collateral factor for open interest multiplier
    bytes32 public constant MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER =
        keccak256(
            abi.encode("MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER")
        );
    // @dev key for the min allowed collateral in USD
    bytes32 public constant MIN_COLLATERAL_USD =
        keccak256(abi.encode("MIN_COLLATERAL_USD"));
    // @dev key for the min allowed position size in USD
    bytes32 public constant MIN_POSITION_SIZE_USD =
        keccak256(abi.encode("MIN_POSITION_SIZE_USD"));

    // @dev key for the virtual id of tokens
    bytes32 public constant VIRTUAL_TOKEN_ID =
        keccak256(abi.encode("VIRTUAL_TOKEN_ID"));
    // @dev key for the virtual id of markets
    bytes32 public constant VIRTUAL_MARKET_ID =
        keccak256(abi.encode("VIRTUAL_MARKET_ID"));
    // @dev key for the virtual inventory for swaps
    bytes32 public constant VIRTUAL_INVENTORY_FOR_SWAPS =
        keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_SWAPS"));
    // @dev key for the virtual inventory for positions
    bytes32 public constant VIRTUAL_INVENTORY_FOR_POSITIONS =
        keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_POSITIONS"));

    // @dev key for the position impact factor
    bytes32 public constant POSITION_IMPACT_FACTOR =
        keccak256(abi.encode("POSITION_IMPACT_FACTOR"));
    // @dev key for the position impact exponent factor
    bytes32 public constant POSITION_IMPACT_EXPONENT_FACTOR =
        keccak256(abi.encode("POSITION_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the max decrease position impact factor
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR =
        keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR"));
    // @dev key for the max position impact factor for liquidations
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS =
        keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS"));
    // @dev key for the position fee factor
    bytes32 public constant POSITION_FEE_FACTOR =
        keccak256(abi.encode("POSITION_FEE_FACTOR"));
    // @dev key for the swap impact factor
    bytes32 public constant SWAP_IMPACT_FACTOR =
        keccak256(abi.encode("SWAP_IMPACT_FACTOR"));
    // @dev key for the swap impact exponent factor
    bytes32 public constant SWAP_IMPACT_EXPONENT_FACTOR =
        keccak256(abi.encode("SWAP_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the swap fee factor
    bytes32 public constant SWAP_FEE_FACTOR =
        keccak256(abi.encode("SWAP_FEE_FACTOR"));
    // @dev key for the oracle type
    bytes32 public constant ORACLE_TYPE = keccak256(abi.encode("ORACLE_TYPE"));
    // @dev key for open interest
    bytes32 public constant OPEN_INTEREST =
        keccak256(abi.encode("OPEN_INTEREST"));
    // @dev key for open interest in tokens
    bytes32 public constant OPEN_INTEREST_IN_TOKENS =
        keccak256(abi.encode("OPEN_INTEREST_IN_TOKENS"));
    // @dev key for collateral sum for a market
    bytes32 public constant COLLATERAL_SUM =
        keccak256(abi.encode("COLLATERAL_SUM"));
    // @dev key for pool amount
    bytes32 public constant POOL_AMOUNT = keccak256(abi.encode("POOL_AMOUNT"));
    // @dev key for max pool amount
    bytes32 public constant MAX_POOL_AMOUNT =
        keccak256(abi.encode("MAX_POOL_AMOUNT"));
    // @dev key for max pool amount for deposit
    bytes32 public constant MAX_POOL_AMOUNT_FOR_DEPOSIT =
        keccak256(abi.encode("MAX_POOL_AMOUNT_FOR_DEPOSIT"));
    // @dev key for max open interest
    bytes32 public constant MAX_OPEN_INTEREST =
        keccak256(abi.encode("MAX_OPEN_INTEREST"));
    // @dev key for position impact pool amount
    bytes32 public constant POSITION_IMPACT_POOL_AMOUNT =
        keccak256(abi.encode("POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for min position impact pool amount
    bytes32 public constant MIN_POSITION_IMPACT_POOL_AMOUNT =
        keccak256(abi.encode("MIN_POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for position impact pool distribution rate
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTION_RATE =
        keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTION_RATE"));
    // @dev key for position impact pool distributed at
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTED_AT =
        keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTED_AT"));
    // @dev key for swap impact pool amount
    bytes32 public constant SWAP_IMPACT_POOL_AMOUNT =
        keccak256(abi.encode("SWAP_IMPACT_POOL_AMOUNT"));
    // @dev key for price feed
    bytes32 public constant PRICE_FEED = keccak256(abi.encode("PRICE_FEED"));
    // @dev key for price feed multiplier
    bytes32 public constant PRICE_FEED_MULTIPLIER =
        keccak256(abi.encode("PRICE_FEED_MULTIPLIER"));
    // @dev key for price feed heartbeat
    bytes32 public constant PRICE_FEED_HEARTBEAT_DURATION =
        keccak256(abi.encode("PRICE_FEED_HEARTBEAT_DURATION"));
    // @dev key for realtime feed id
    bytes32 public constant REALTIME_FEED_ID =
        keccak256(abi.encode("REALTIME_FEED_ID"));
    // @dev key for realtime feed multipler
    bytes32 public constant REALTIME_FEED_MULTIPLIER =
        keccak256(abi.encode("REALTIME_FEED_MULTIPLIER"));
    // @dev key for stable price
    bytes32 public constant STABLE_PRICE =
        keccak256(abi.encode("STABLE_PRICE"));
    // @dev key for reserve factor
    bytes32 public constant RESERVE_FACTOR =
        keccak256(abi.encode("RESERVE_FACTOR"));
    // @dev key for open interest reserve factor
    bytes32 public constant OPEN_INTEREST_RESERVE_FACTOR =
        keccak256(abi.encode("OPEN_INTEREST_RESERVE_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR =
        keccak256(abi.encode("MAX_PNL_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_TRADERS =
        keccak256(abi.encode("MAX_PNL_FACTOR_FOR_TRADERS"));
    // @dev key for max pnl factor for adl
    bytes32 public constant MAX_PNL_FACTOR_FOR_ADL =
        keccak256(abi.encode("MAX_PNL_FACTOR_FOR_ADL"));
    // @dev key for min pnl factor for adl
    bytes32 public constant MIN_PNL_FACTOR_AFTER_ADL =
        keccak256(abi.encode("MIN_PNL_FACTOR_AFTER_ADL"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_DEPOSITS =
        keccak256(abi.encode("MAX_PNL_FACTOR_FOR_DEPOSITS"));
    // @dev key for max pnl factor for withdrawals
    bytes32 public constant MAX_PNL_FACTOR_FOR_WITHDRAWALS =
        keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS"));
    // @dev key for latest ADL block
    bytes32 public constant LATEST_ADL_BLOCK =
        keccak256(abi.encode("LATEST_ADL_BLOCK"));
    // @dev key for whether ADL is enabled
    bytes32 public constant IS_ADL_ENABLED =
        keccak256(abi.encode("IS_ADL_ENABLED"));
    // @dev key for funding factor
    bytes32 public constant FUNDING_FACTOR =
        keccak256(abi.encode("FUNDING_FACTOR"));
    // @dev key for funding exponent factor
    bytes32 public constant FUNDING_EXPONENT_FACTOR =
        keccak256(abi.encode("FUNDING_EXPONENT_FACTOR"));
    // @dev key for saved funding factor
    bytes32 public constant SAVED_FUNDING_FACTOR_PER_SECOND =
        keccak256(abi.encode("SAVED_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for funding increase factor
    bytes32 public constant FUNDING_INCREASE_FACTOR_PER_SECOND =
        keccak256(abi.encode("FUNDING_INCREASE_FACTOR_PER_SECOND"));
    // @dev key for funding decrease factor
    bytes32 public constant FUNDING_DECREASE_FACTOR_PER_SECOND =
        keccak256(abi.encode("FUNDING_DECREASE_FACTOR_PER_SECOND"));
    // @dev key for min funding factor
    bytes32 public constant MIN_FUNDING_FACTOR_PER_SECOND =
        keccak256(abi.encode("MIN_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for max funding factor
    bytes32 public constant MAX_FUNDING_FACTOR_PER_SECOND =
        keccak256(abi.encode("MAX_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for threshold for stable funding
    bytes32 public constant THRESHOLD_FOR_STABLE_FUNDING =
        keccak256(abi.encode("THRESHOLD_FOR_STABLE_FUNDING"));
    // @dev key for threshold for decrease funding
    bytes32 public constant THRESHOLD_FOR_DECREASE_FUNDING =
        keccak256(abi.encode("THRESHOLD_FOR_DECREASE_FUNDING"));
    // @dev key for funding fee amount per size
    bytes32 public constant FUNDING_FEE_AMOUNT_PER_SIZE =
        keccak256(abi.encode("FUNDING_FEE_AMOUNT_PER_SIZE"));
    // @dev key for claimable funding amount per size
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT_PER_SIZE =
        keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT_PER_SIZE"));
    // @dev key for when funding was last updated at
    bytes32 public constant FUNDING_UPDATED_AT =
        keccak256(abi.encode("FUNDING_UPDATED_AT"));
    // @dev key for claimable funding amount
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT =
        keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT"));
    // @dev key for claimable collateral amount
    bytes32 public constant CLAIMABLE_COLLATERAL_AMOUNT =
        keccak256(abi.encode("CLAIMABLE_COLLATERAL_AMOUNT"));
    // @dev key for claimable collateral factor
    bytes32 public constant CLAIMABLE_COLLATERAL_FACTOR =
        keccak256(abi.encode("CLAIMABLE_COLLATERAL_FACTOR"));
    // @dev key for claimable collateral time divisor
    bytes32 public constant CLAIMABLE_COLLATERAL_TIME_DIVISOR =
        keccak256(abi.encode("CLAIMABLE_COLLATERAL_TIME_DIVISOR"));
    // @dev key for claimed collateral amount
    bytes32 public constant CLAIMED_COLLATERAL_AMOUNT =
        keccak256(abi.encode("CLAIMED_COLLATERAL_AMOUNT"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_FACTOR =
        keccak256(abi.encode("BORROWING_FACTOR"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_EXPONENT_FACTOR =
        keccak256(abi.encode("BORROWING_EXPONENT_FACTOR"));
    // @dev key for skipping the borrowing factor for the smaller side
    bytes32 public constant SKIP_BORROWING_FEE_FOR_SMALLER_SIDE =
        keccak256(abi.encode("SKIP_BORROWING_FEE_FOR_SMALLER_SIDE"));
    // @dev key for cumulative borrowing factor
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR =
        keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR"));
    // @dev key for when the cumulative borrowing factor was last updated at
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR_UPDATED_AT =
        keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR_UPDATED_AT"));
    // @dev key for total borrowing amount
    bytes32 public constant TOTAL_BORROWING =
        keccak256(abi.encode("TOTAL_BORROWING"));
    // @dev key for affiliate reward
    bytes32 public constant AFFILIATE_REWARD =
        keccak256(abi.encode("AFFILIATE_REWARD"));
    // @dev key for max allowed subaccount action count
    bytes32 public constant MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT =
        keccak256(abi.encode("MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount action count
    bytes32 public constant SUBACCOUNT_ACTION_COUNT =
        keccak256(abi.encode("SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount auto top up amount
    bytes32 public constant SUBACCOUNT_AUTO_TOP_UP_AMOUNT =
        keccak256(abi.encode("SUBACCOUNT_AUTO_TOP_UP_AMOUNT"));
    // @dev key for subaccount order action
    bytes32 public constant SUBACCOUNT_ORDER_ACTION =
        keccak256(abi.encode("SUBACCOUNT_ORDER_ACTION"));
    // @dev key for fee distributor swap order token index
    bytes32 public constant FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX =
        keccak256(abi.encode("FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX"));
    // @dev key for fee distributor swap fee batch
    bytes32 public constant FEE_DISTRIBUTOR_SWAP_FEE_BATCH =
        keccak256(abi.encode("FEE_DISTRIBUTOR_SWAP_FEE_BATCH"));

    // @dev constant for user initiated cancel reason
    string public constant USER_INITIATED_CANCEL = "USER_INITIATED_CANCEL";

    // ============ Internal Functions ============

    // @dev key for the account deposit list
    // @param account the account for the list
    function accountDepositListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_DEPOSIT_LIST, account));
    }

    // @dev key for the account withdrawal list
    // @param account the account for the list
    function accountWithdrawalListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_WITHDRAWAL_LIST, account));
    }

    // @dev key for the account position list
    // @param account the account for the list
    function accountPositionListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_POSITION_LIST, account));
    }

    // @dev key for the account order list
    // @param account the account for the list
    function accountOrderListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_ORDER_LIST, account));
    }

    // @dev key for the subaccount list
    // @param account the account for the list
    function subaccountListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SUBACCOUNT_LIST, account));
    }

    // @dev key for the claimable fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    function claimableFeeAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount for account
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(
        address market,
        address token,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token, account)
            );
    }

    // @dev key for deposit gas limit
    // @param singleToken whether a single token or pair tokens are being deposited
    // @return key for deposit gas limit
    function depositGasLimitKey(
        bool singleToken
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(DEPOSIT_GAS_LIMIT, singleToken));
    }

    // @dev key for withdrawal gas limit
    // @return key for withdrawal gas limit
    function withdrawalGasLimitKey() internal pure returns (bytes32) {
        return keccak256(abi.encode(WITHDRAWAL_GAS_LIMIT));
    }

    // @dev key for single swap gas limit
    // @return key for single swap gas limit
    function singleSwapGasLimitKey() internal pure returns (bytes32) {
        return SINGLE_SWAP_GAS_LIMIT;
    }

    // @dev key for increase order gas limit
    // @return key for increase order gas limit
    function increaseOrderGasLimitKey() internal pure returns (bytes32) {
        return INCREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for decrease order gas limit
    // @return key for decrease order gas limit
    function decreaseOrderGasLimitKey() internal pure returns (bytes32) {
        return DECREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for swap order gas limit
    // @return key for swap order gas limit
    function swapOrderGasLimitKey() internal pure returns (bytes32) {
        return SWAP_ORDER_GAS_LIMIT;
    }

    function swapPathMarketFlagKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SWAP_PATH_MARKET_FLAG, market));
    }

    // @dev key for whether create deposit is disabled
    // @param the create deposit module
    // @return key for whether create deposit is disabled
    function createDepositFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CREATE_DEPOSIT_FEATURE_DISABLED, module));
    }

    // @dev key for whether cancel deposit is disabled
    // @param the cancel deposit module
    // @return key for whether cancel deposit is disabled
    function cancelDepositFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CANCEL_DEPOSIT_FEATURE_DISABLED, module));
    }

    // @dev key for whether execute deposit is disabled
    // @param the execute deposit module
    // @return key for whether execute deposit is disabled
    function executeDepositFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(EXECUTE_DEPOSIT_FEATURE_DISABLED, module));
    }

    // @dev key for whether create withdrawal is disabled
    // @param the create withdrawal module
    // @return key for whether create withdrawal is disabled
    function createWithdrawalFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CREATE_WITHDRAWAL_FEATURE_DISABLED, module));
    }

    // @dev key for whether cancel withdrawal is disabled
    // @param the cancel withdrawal module
    // @return key for whether cancel withdrawal is disabled
    function cancelWithdrawalFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CANCEL_WITHDRAWAL_FEATURE_DISABLED, module));
    }

    // @dev key for whether execute withdrawal is disabled
    // @param the execute withdrawal module
    // @return key for whether execute withdrawal is disabled
    function executeWithdrawalFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(EXECUTE_WITHDRAWAL_FEATURE_DISABLED, module));
    }

    // @dev key for whether create order is disabled
    // @param the create order module
    // @return key for whether create order is disabled
    function createOrderFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CREATE_ORDER_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether execute order is disabled
    // @param the execute order module
    // @return key for whether execute order is disabled
    function executeOrderFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(EXECUTE_ORDER_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether execute adl is disabled
    // @param the execute adl module
    // @return key for whether execute adl is disabled
    function executeAdlFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(EXECUTE_ADL_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether update order is disabled
    // @param the update order module
    // @return key for whether update order is disabled
    function updateOrderFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(UPDATE_ORDER_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether cancel order is disabled
    // @param the cancel order module
    // @return key for whether cancel order is disabled
    function cancelOrderFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CANCEL_ORDER_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether claim funding fees is disabled
    // @param the claim funding fees module
    function claimFundingFeesFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CLAIM_FUNDING_FEES_FEATURE_DISABLED, module));
    }

    // @dev key for whether claim colltareral is disabled
    // @param the claim funding fees module
    function claimCollateralFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIM_COLLATERAL_FEATURE_DISABLED, module));
    }

    // @dev key for whether claim affiliate rewards is disabled
    // @param the claim affiliate rewards module
    function claimAffiliateRewardsFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED, module)
            );
    }

    // @dev key for whether claim ui fees is disabled
    // @param the claim ui fees module
    function claimUiFeesFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIM_UI_FEES_FEATURE_DISABLED, module));
    }

    // @dev key for whether subaccounts are disabled
    // @param the subaccount module
    function subaccountFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SUBACCOUNT_FEATURE_DISABLED, module));
    }

    // @dev key for ui fee factor
    // @param account the fee receiver account
    // @return key for ui fee factor
    function uiFeeFactorKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(UI_FEE_FACTOR, account));
    }

    // @dev key for gas to forward for token transfer
    // @param the token to check
    // @return key for gas to forward for token transfer
    function tokenTransferGasLimit(
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(TOKEN_TRANSFER_GAS_LIMIT, token));
    }

    // @dev the default callback contract
    // @param account the user's account
    // @param market the address of the market
    // @param callbackContract the callback contract
    function savedCallbackContract(
        address account,
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SAVED_CALLBACK_CONTRACT, account, market));
    }

    // @dev the min collateral factor key
    // @param the market for the min collateral factor
    function minCollateralFactorKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MIN_COLLATERAL_FACTOR, market));
    }

    // @dev the min collateral factor for open interest multiplier key
    // @param the market for the factor
    function minCollateralFactorForOpenInterestMultiplierKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER,
                    market,
                    isLong
                )
            );
    }

    // @dev the key for the virtual token id
    // @param the token to get the virtual id for
    function virtualTokenIdKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(VIRTUAL_TOKEN_ID, token));
    }

    // @dev the key for the virtual market id
    // @param the market to get the virtual id for
    function virtualMarketIdKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(VIRTUAL_MARKET_ID, market));
    }

    // @dev the key for the virtual inventory for positions
    // @param the virtualTokenId the virtual token id
    function virtualInventoryForPositionsKey(
        bytes32 virtualTokenId
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(VIRTUAL_INVENTORY_FOR_POSITIONS, virtualTokenId)
            );
    }

    // @dev the key for the virtual inventory for swaps
    // @param the virtualMarketId the virtual market id
    // @param the token to check the inventory for
    function virtualInventoryForSwapsKey(
        bytes32 virtualMarketId,
        bool isLongToken
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    VIRTUAL_INVENTORY_FOR_SWAPS,
                    virtualMarketId,
                    isLongToken
                )
            );
    }

    // @dev key for position impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for position impact factor
    function positionImpactFactorKey(
        address market,
        bool isPositive
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(POSITION_IMPACT_FACTOR, market, isPositive));
    }

    // @dev key for position impact exponent factor
    // @param market the market address to check
    // @return key for position impact exponent factor
    function positionImpactExponentFactorKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(POSITION_IMPACT_EXPONENT_FACTOR, market));
    }

    // @dev key for the max position impact factor
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorKey(
        address market,
        bool isPositive
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(MAX_POSITION_IMPACT_FACTOR, market, isPositive)
            );
    }

    // @dev key for the max position impact factor for liquidations
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorForLiquidationsKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS, market)
            );
    }

    // @dev key for position fee factor
    // @param market the market address to check
    // @param forPositiveImpact whether the fee is for an action that has a positive price impact
    // @return key for position fee factor
    function positionFeeFactorKey(
        address market,
        bool forPositiveImpact
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(POSITION_FEE_FACTOR, market, forPositiveImpact)
            );
    }

    // @dev key for swap impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for swap impact factor
    function swapImpactFactorKey(
        address market,
        bool isPositive
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SWAP_IMPACT_FACTOR, market, isPositive));
    }

    // @dev key for swap impact exponent factor
    // @param market the market address to check
    // @return key for swap impact exponent factor
    function swapImpactExponentFactorKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SWAP_IMPACT_EXPONENT_FACTOR, market));
    }

    // @dev key for swap fee factor
    // @param market the market address to check
    // @return key for swap fee factor
    function swapFeeFactorKey(
        address market,
        bool forPositiveImpact
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(SWAP_FEE_FACTOR, market, forPositiveImpact));
    }

    // @dev key for oracle type
    // @param token the token to check
    // @return key for oracle type
    function oracleTypeKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(ORACLE_TYPE, token));
    }

    // @dev key for open interest
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest
    function openInterestKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(OPEN_INTEREST, market, collateralToken, isLong)
            );
    }

    // @dev key for open interest in tokens
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest in tokens
    function openInterestInTokensKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    OPEN_INTEREST_IN_TOKENS,
                    market,
                    collateralToken,
                    isLong
                )
            );
    }

    // @dev key for collateral sum for a market
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for collateral sum
    function collateralSumKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(COLLATERAL_SUM, market, collateralToken, isLong)
            );
    }

    // @dev key for amount of tokens in a market's pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's pool
    function poolAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(POOL_AMOUNT, market, token));
    }

    // @dev the key for the max amount of pool tokens
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MAX_POOL_AMOUNT, market, token));
    }

    // @dev the key for the max amount of pool tokens for deposits
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolAmountForDepositKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(MAX_POOL_AMOUNT_FOR_DEPOSIT, market, token));
    }

    // @dev the key for the max open interest
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function maxOpenInterestKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MAX_OPEN_INTEREST, market, isLong));
    }

    // @dev key for amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for amount of tokens in a market's position impact pool
    function positionImpactPoolAmountKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(POSITION_IMPACT_POOL_AMOUNT, market));
    }

    // @dev key for min amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for min amount of tokens in a market's position impact pool
    function minPositionImpactPoolAmountKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MIN_POSITION_IMPACT_POOL_AMOUNT, market));
    }

    // @dev key for position impact pool distribution rate
    // @param market the market to check
    // @return key for position impact pool distribution rate
    function positionImpactPoolDistributionRateKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(POSITION_IMPACT_POOL_DISTRIBUTION_RATE, market)
            );
    }

    // @dev key for position impact pool distributed at
    // @param market the market to check
    // @return key for position impact pool distributed at
    function positionImpactPoolDistributedAtKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(POSITION_IMPACT_POOL_DISTRIBUTED_AT, market));
    }

    // @dev key for amount of tokens in a market's swap impact pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's swap impact pool
    function swapImpactPoolAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SWAP_IMPACT_POOL_AMOUNT, market, token));
    }

    // @dev key for reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for reserve factor
    function reserveFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(RESERVE_FACTOR, market, isLong));
    }

    // @dev key for open interest reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for open interest reserve factor
    function openInterestReserveFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(OPEN_INTEREST_RESERVE_FACTOR, market, isLong));
    }

    // @dev key for max pnl factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for max pnl factor
    function maxPnlFactorKey(
        bytes32 pnlFactorType,
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(MAX_PNL_FACTOR, pnlFactorType, market, isLong)
            );
    }

    // @dev the key for min PnL factor after ADL
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function minPnlFactorAfterAdlKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MIN_PNL_FACTOR_AFTER_ADL, market, isLong));
    }

    // @dev key for latest adl block
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for latest adl block
    function latestAdlBlockKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(LATEST_ADL_BLOCK, market, isLong));
    }

    // @dev key for whether adl is enabled
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for whether adl is enabled
    function isAdlEnabledKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(IS_ADL_ENABLED, market, isLong));
    }

    // @dev key for funding factor
    // @param market the market to check
    // @return key for funding factor
    function fundingFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(FUNDING_FACTOR, market));
    }

    // @dev the key for funding exponent
    // @param market the market for the pool
    function fundingExponentFactorKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(FUNDING_EXPONENT_FACTOR, market));
    }

    // @dev the key for saved funding factor
    // @param market the market for the pool
    function savedFundingFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SAVED_FUNDING_FACTOR_PER_SECOND, market));
    }

    // @dev the key for funding increase factor
    // @param market the market for the pool
    function fundingIncreaseFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(FUNDING_INCREASE_FACTOR_PER_SECOND, market));
    }

    // @dev the key for funding decrease factor
    // @param market the market for the pool
    function fundingDecreaseFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(FUNDING_DECREASE_FACTOR_PER_SECOND, market));
    }

    // @dev the key for min funding factor
    // @param market the market for the pool
    function minFundingFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MIN_FUNDING_FACTOR_PER_SECOND, market));
    }

    // @dev the key for max funding factor
    // @param market the market for the pool
    function maxFundingFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MAX_FUNDING_FACTOR_PER_SECOND, market));
    }

    // @dev the key for threshold for stable funding
    // @param market the market for the pool
    function thresholdForStableFundingKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(THRESHOLD_FOR_STABLE_FUNDING, market));
    }

    // @dev the key for threshold for decreasing funding
    // @param market the market for the pool
    function thresholdForDecreaseFundingKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(THRESHOLD_FOR_DECREASE_FUNDING, market));
    }

    // @dev key for funding fee amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for funding fee amount per size
    function fundingFeeAmountPerSizeKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    FUNDING_FEE_AMOUNT_PER_SIZE,
                    market,
                    collateralToken,
                    isLong
                )
            );
    }

    // @dev key for claimabel funding amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for claimable funding amount per size
    function claimableFundingAmountPerSizeKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIMABLE_FUNDING_AMOUNT_PER_SIZE,
                    market,
                    collateralToken,
                    isLong
                )
            );
    }

    // @dev key for when funding was last updated
    // @param market the market to check
    // @return key for when funding was last updated
    function fundingUpdatedAtKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(FUNDING_UPDATED_AT, market));
    }

    // @dev key for claimable funding amount
    // @param market the market to check
    // @param token the token to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_FUNDING_AMOUNT, market, token));
    }

    // @dev key for claimable funding amount by account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(
        address market,
        address token,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CLAIMABLE_FUNDING_AMOUNT, market, token, account)
            );
    }

    // @dev key for claimable collateral amount
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CLAIMABLE_COLLATERAL_AMOUNT, market, token));
    }

    // @dev key for claimable collateral amount for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(
        address market,
        address token,
        uint256 timeKey,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIMABLE_COLLATERAL_AMOUNT,
                    market,
                    token,
                    timeKey,
                    account
                )
            );
    }

    // @dev key for claimable collateral factor for a timeKey
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(
        address market,
        address token,
        uint256 timeKey
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CLAIMABLE_COLLATERAL_FACTOR, market, token, timeKey)
            );
    }

    // @dev key for claimable collateral factor for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(
        address market,
        address token,
        uint256 timeKey,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIMABLE_COLLATERAL_FACTOR,
                    market,
                    token,
                    timeKey,
                    account
                )
            );
    }

    // @dev key for claimable collateral factor
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimedCollateralAmountKey(
        address market,
        address token,
        uint256 timeKey,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIMED_COLLATERAL_AMOUNT,
                    market,
                    token,
                    timeKey,
                    account
                )
            );
    }

    // @dev key for borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for borrowing factor
    function borrowingFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(BORROWING_FACTOR, market, isLong));
    }

    // @dev the key for borrowing exponent
    // @param market the market for the pool
    // @param isLong whether to get the key for the long or short side
    function borrowingExponentFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(BORROWING_EXPONENT_FACTOR, market, isLong));
    }

    // @dev key for cumulative borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor
    function cumulativeBorrowingFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CUMULATIVE_BORROWING_FACTOR, market, isLong));
    }

    // @dev key for cumulative borrowing factor updated at
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor updated at
    function cumulativeBorrowingFactorUpdatedAtKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CUMULATIVE_BORROWING_FACTOR_UPDATED_AT,
                    market,
                    isLong
                )
            );
    }

    // @dev key for total borrowing amount
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for total borrowing amount
    function totalBorrowingKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(TOTAL_BORROWING, market, isLong));
    }

    // @dev key for affiliate reward amount
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(AFFILIATE_REWARD, market, token));
    }

    function maxAllowedSubaccountActionCountKey(
        address account,
        address subaccount,
        bytes32 actionType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT,
                    account,
                    subaccount,
                    actionType
                )
            );
    }

    function subaccountActionCountKey(
        address account,
        address subaccount,
        bytes32 actionType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SUBACCOUNT_ACTION_COUNT,
                    account,
                    subaccount,
                    actionType
                )
            );
    }

    function subaccountAutoTopUpAmountKey(
        address account,
        address subaccount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(SUBACCOUNT_AUTO_TOP_UP_AMOUNT, account, subaccount)
            );
    }

    // @dev key for affiliate reward amount for an account
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(
        address market,
        address token,
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(AFFILIATE_REWARD, market, token, account));
    }

    // @dev key for is market disabled
    // @param market the market to check
    // @return key for is market disabled
    function isMarketDisabledKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(IS_MARKET_DISABLED, market));
    }

    // @dev key for min market tokens for first deposit
    // @param market the market to check
    // @return key for min market tokens for first deposit
    function minMarketTokensForFirstDepositKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT, market));
    }

    // @dev key for price feed address
    // @param token the token to get the key for
    // @return key for price feed address
    function priceFeedKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(PRICE_FEED, token));
    }

    // @dev key for realtime feed ID
    // @param token the token to get the key for
    // @return key for realtime feed ID
    function realtimeFeedIdKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(REALTIME_FEED_ID, token));
    }

    // @dev key for realtime feed multiplier
    // @param token the token to get the key for
    // @return key for realtime feed multiplier
    function realtimeFeedMultiplierKey(
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(REALTIME_FEED_MULTIPLIER, token));
    }

    // @dev key for price feed multiplier
    // @param token the token to get the key for
    // @return key for price feed multiplier
    function priceFeedMultiplierKey(
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(PRICE_FEED_MULTIPLIER, token));
    }

    function priceFeedHeartbeatDurationKey(
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(PRICE_FEED_HEARTBEAT_DURATION, token));
    }

    // @dev key for stable price value
    // @param token the token to get the key for
    // @return key for stable price value
    function stablePriceKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(STABLE_PRICE, token));
    }

    // @dev key for fee distributor swap token index
    // @param orderKey the swap order key
    // @return key for fee distributor swap token index
    function feeDistributorSwapTokenIndexKey(
        bytes32 orderKey
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX, orderKey));
    }

    // @dev key for fee distributor swap fee batch key
    // @param orderKey the swap order key
    // @return key for fee distributor swap fee batch key
    function feeDistributorSwapFeeBatchKey(
        bytes32 orderKey
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_DISTRIBUTOR_SWAP_FEE_BATCH, orderKey));
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";

/**
 * @title IGmxV2EventUtilsTypes
 * @author GoldLink
 *
 * Types used by Gmx V2 for market information.
 * Adapted from these four files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/Market.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/MarketUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/MarketPoolValueInfo.sol
 */
interface IGmxV2MarketTypes {
    // ============ Enums ============

    enum FundingRateChangeType {
        NoChange,
        Increase,
        Decrease
    }

    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }

    struct MarketPrices {
        IGmxV2PriceTypes.Props indexTokenPrice;
        IGmxV2PriceTypes.Props longTokenPrice;
        IGmxV2PriceTypes.Props shortTokenPrice;
    }

    struct CollateralType {
        uint256 longToken;
        uint256 shortToken;
    }

    struct PositionType {
        CollateralType long;
        CollateralType short;
    }

    struct VirtualInventory {
        uint256 virtualPoolAmountForLongToken;
        uint256 virtualPoolAmountForShortToken;
        int256 virtualInventoryForPositions;
    }

    struct MarketInfo {
        IGmxV2MarketTypes.Props market;
        uint256 borrowingFactorPerSecondForLongs;
        uint256 borrowingFactorPerSecondForShorts;
        BaseFundingValues baseFunding;
        GetNextFundingAmountPerSizeResult nextFunding;
        VirtualInventory virtualInventory;
        bool isDisabled;
    }

    struct BaseFundingValues {
        PositionType fundingFeeAmountPerSize;
        PositionType claimableFundingAmountPerSize;
    }

    struct GetNextFundingAmountPerSizeResult {
        bool longsPayShorts;
        uint256 fundingFactorPerSecond;
        int256 nextSavedFundingFactorPerSecond;
        PositionType fundingFeeAmountPerSizeDelta;
        PositionType claimableFundingAmountPerSizeDelta;
    }

    struct PoolValueInfo {
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
}

// SPDX-License-Identifier: MIT
//
// Adapted from https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.8.20;

interface IChainlinkAggregatorV3 {
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

// SPDX-License-Identifier: BUSL-1.1

// Borrowed from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/position/Position.sol
// Modified as follows:
// - GoldLink types
// - removed structs

pragma solidity ^0.8.0;

import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";

library Position {
    // ============ Internal Functions ============

    function account(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.account;
    }

    function setAccount(
        IGmxV2PositionTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.account = value;
    }

    function market(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.market;
    }

    function setMarket(
        IGmxV2PositionTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.market = value;
    }

    function collateralToken(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.collateralToken;
    }

    function setCollateralToken(
        IGmxV2PositionTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.collateralToken = value;
    }

    function sizeInUsd(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.sizeInUsd;
    }

    function setSizeInUsd(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.sizeInUsd = value;
    }

    function sizeInTokens(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.sizeInTokens;
    }

    function setSizeInTokens(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.sizeInTokens = value;
    }

    function collateralAmount(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.collateralAmount;
    }

    function setCollateralAmount(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.collateralAmount = value;
    }

    function borrowingFactor(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.borrowingFactor;
    }

    function setBorrowingFactor(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.borrowingFactor = value;
    }

    function fundingFeeAmountPerSize(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.fundingFeeAmountPerSize;
    }

    function setFundingFeeAmountPerSize(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.fundingFeeAmountPerSize = value;
    }

    function longTokenClaimableFundingAmountPerSize(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.longTokenClaimableFundingAmountPerSize;
    }

    function setLongTokenClaimableFundingAmountPerSize(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.longTokenClaimableFundingAmountPerSize = value;
    }

    function shortTokenClaimableFundingAmountPerSize(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.shortTokenClaimableFundingAmountPerSize;
    }

    function setShortTokenClaimableFundingAmountPerSize(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.shortTokenClaimableFundingAmountPerSize = value;
    }

    function increasedAtBlock(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.increasedAtBlock;
    }

    function setIncreasedAtBlock(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.increasedAtBlock = value;
    }

    function decreasedAtBlock(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.decreasedAtBlock;
    }

    function setDecreasedAtBlock(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.decreasedAtBlock = value;
    }

    function isLong(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (bool) {
        return props.flags.isLong;
    }

    function setIsLong(
        IGmxV2PositionTypes.Props memory props,
        bool value
    ) internal pure {
        props.flags.isLong = value;
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PositionTypes } from "./IGmxV2PositionTypes.sol";
import { IGmxV2MarketTypes } from "./IGmxV2MarketTypes.sol";

/**
 * @title IGmxV2PriceTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's Prices, removes all logic from GMX contract and adds additional
 * structs.
 * The structs here come from three files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/price/Price.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderPricingUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/pricing/SwapPricingUtils.sol
 */
interface IGmxV2PriceTypes {
    struct Props {
        uint256 min;
        uint256 max;
    }

    struct ExecutionPriceResult {
        int256 priceImpactUsd;
        uint256 priceImpactDiffUsd;
        uint256 executionPrice;
    }

    struct PositionInfo {
        IGmxV2PositionTypes.Props position;
        IGmxV2PositionTypes.PositionFees fees;
        ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    struct GetPositionInfoCache {
        IGmxV2MarketTypes.Props market;
        Props collateralTokenPrice;
        uint256 pendingBorrowingFeeUsd;
        int256 latestLongTokenFundingAmountPerSize;
        int256 latestShortTokenFundingAmountPerSize;
    }

    struct SwapFees {
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 amountAfterFees;
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified version of https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/gas/GasUtils.sol
// Modified as follows:
// - Copied exactly from GMX V2 with structs removed and touch removed

pragma solidity ^0.8.0;

import { IGmxV2OrderTypes } from "../interfaces/external/IGmxV2OrderTypes.sol";

library Order {
    // ============ Internal Functions ============

    // @dev set the order account
    // @param props Props
    // @param value the value to set to
    function setAccount(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.account = value;
    }

    // @dev the order receiver
    // @param props Props
    // @return the order receiver
    function receiver(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.receiver;
    }

    // @dev set the order receiver
    // @param props Props
    // @param value the value to set to
    function setReceiver(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.receiver = value;
    }

    // @dev the order callbackContract
    // @param props Props
    // @return the order callbackContract
    function callbackContract(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.callbackContract;
    }

    // @dev set the order callbackContract
    // @param props Props
    // @param value the value to set to
    function setCallbackContract(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.callbackContract = value;
    }

    // @dev the order market
    // @param props Props
    // @return the order market
    function market(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.market;
    }

    // @dev set the order market
    // @param props Props
    // @param value the value to set to
    function setMarket(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.market = value;
    }

    // @dev the order initialCollateralToken
    // @param props Props
    // @return the order initialCollateralToken
    function initialCollateralToken(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.initialCollateralToken;
    }

    // @dev set the order initialCollateralToken
    // @param props Props
    // @param value the value to set to
    function setInitialCollateralToken(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.initialCollateralToken = value;
    }

    // @dev the order uiFeeReceiver
    // @param props Props
    // @return the order uiFeeReceiver
    function uiFeeReceiver(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.uiFeeReceiver;
    }

    // @dev set the order uiFeeReceiver
    // @param props Props
    // @param value the value to set to
    function setUiFeeReceiver(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.uiFeeReceiver = value;
    }

    // @dev the order swapPath
    // @param props Props
    // @return the order swapPath
    function swapPath(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address[] memory) {
        return props.addresses.swapPath;
    }

    // @dev set the order swapPath
    // @param props Props
    // @param value the value to set to
    function setSwapPath(
        IGmxV2OrderTypes.Props memory props,
        address[] memory value
    ) internal pure {
        props.addresses.swapPath = value;
    }

    // @dev the order type
    // @param props Props
    // @return the order type
    function orderType(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (IGmxV2OrderTypes.OrderType) {
        return props.numbers.orderType;
    }

    // @dev set the order type
    // @param props Props
    // @param value the value to set to
    function setOrderType(
        IGmxV2OrderTypes.Props memory props,
        IGmxV2OrderTypes.OrderType value
    ) internal pure {
        props.numbers.orderType = value;
    }

    function decreasePositionSwapType(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (IGmxV2OrderTypes.DecreasePositionSwapType) {
        return props.numbers.decreasePositionSwapType;
    }

    function setDecreasePositionSwapType(
        IGmxV2OrderTypes.Props memory props,
        IGmxV2OrderTypes.DecreasePositionSwapType value
    ) internal pure {
        props.numbers.decreasePositionSwapType = value;
    }

    // @dev the order sizeDeltaUsd
    // @param props Props
    // @return the order sizeDeltaUsd
    function sizeDeltaUsd(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.sizeDeltaUsd;
    }

    // @dev set the order sizeDeltaUsd
    // @param props Props
    // @param value the value to set to
    function setSizeDeltaUsd(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.sizeDeltaUsd = value;
    }

    // @dev the order initialCollateralDeltaAmount
    // @param props Props
    // @return the order initialCollateralDeltaAmount
    function initialCollateralDeltaAmount(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.initialCollateralDeltaAmount;
    }

    // @dev set the order initialCollateralDeltaAmount
    // @param props Props
    // @param value the value to set to
    function setInitialCollateralDeltaAmount(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.initialCollateralDeltaAmount = value;
    }

    // @dev the order triggerPrice
    // @param props Props
    // @return the order triggerPrice
    function triggerPrice(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.triggerPrice;
    }

    // @dev set the order triggerPrice
    // @param props Props
    // @param value the value to set to
    function setTriggerPrice(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.triggerPrice = value;
    }

    // @dev the order acceptablePrice
    // @param props Props
    // @return the order acceptablePrice
    function acceptablePrice(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.acceptablePrice;
    }

    // @dev set the order acceptablePrice
    // @param props Props
    // @param value the value to set to
    function setAcceptablePrice(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.acceptablePrice = value;
    }

    // @dev set the order executionFee
    // @param props Props
    // @param value the value to set to
    function setExecutionFee(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.executionFee = value;
    }

    // @dev the order executionFee
    // @param props Props
    // @return the order executionFee
    function executionFee(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.executionFee;
    }

    // @dev the order callbackGasLimit
    // @param props Props
    // @return the order callbackGasLimit
    function callbackGasLimit(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.callbackGasLimit;
    }

    // @dev set the order callbackGasLimit
    // @param props Props
    // @param value the value to set to
    function setCallbackGasLimit(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.callbackGasLimit = value;
    }

    // @dev the order minOutputAmount
    // @param props Props
    // @return the order minOutputAmount
    function minOutputAmount(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.minOutputAmount;
    }

    // @dev set the order minOutputAmount
    // @param props Props
    // @param value the value to set to
    function setMinOutputAmount(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.minOutputAmount = value;
    }

    // @dev the order updatedAtBlock
    // @param props Props
    // @return the order updatedAtBlock
    function updatedAtBlock(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.updatedAtBlock;
    }

    // @dev set the order updatedAtBlock
    // @param props Props
    // @param value the value to set to
    function setUpdatedAtBlock(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.updatedAtBlock = value;
    }

    // @dev whether the order is for a long or short
    // @param props Props
    // @return whether the order is for a long or short
    function isLong(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (bool) {
        return props.flags.isLong;
    }

    // @dev set whether the order is for a long or short
    // @param props Props
    // @param value the value to set to
    function setIsLong(
        IGmxV2OrderTypes.Props memory props,
        bool value
    ) internal pure {
        props.flags.isLong = value;
    }

    // @dev whether to unwrap the native token before transfers to the user
    // @param props Props
    // @return whether to unwrap the native token before transfers to the user
    function shouldUnwrapNativeToken(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (bool) {
        return props.flags.shouldUnwrapNativeToken;
    }

    // @dev set whether the native token should be unwrapped before being
    // transferred to the receiver
    // @param props Props
    // @param value the value to set to
    function setShouldUnwrapNativeToken(
        IGmxV2OrderTypes.Props memory props,
        bool value
    ) internal pure {
        props.flags.shouldUnwrapNativeToken = value;
    }

    // @dev whether the order is frozen
    // @param props Props
    // @return whether the order is frozen
    function isFrozen(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (bool) {
        return props.flags.isFrozen;
    }

    // @dev set whether the order is frozen
    // transferred to the receiver
    // @param props Props
    // @param value the value to set to
    function setIsFrozen(
        IGmxV2OrderTypes.Props memory props,
        bool value
    ) internal pure {
        props.flags.isFrozen = value;
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified version of https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/gas/GasUtils.sol
// Modified as follows:
// - Removed all logic except order gas limit functions.

pragma solidity ^0.8.0;

import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import { Keys } from "../keys/Keys.sol";

library GasUtils {
    // ============ Internal Functions ============

    // @dev the estimated gas limit for increase orders
    // @param dataStore DataStore
    // @param order the order to estimate the gas limit for
    function estimateExecuteIncreaseOrderGasLimit(
        IGmxV2DataStore dataStore,
        uint256 swapPathLength,
        uint256 callbackGasLimit
    ) internal view returns (uint256) {
        uint256 gasPerSwap = dataStore.getUint(Keys.singleSwapGasLimitKey());
        return
            dataStore.getUint(Keys.increaseOrderGasLimitKey()) +
            gasPerSwap *
            swapPathLength +
            callbackGasLimit;
    }

    // @dev the estimated gas limit for decrease orders
    // @param dataStore DataStore
    // @param order the order to estimate the gas limit for
    function estimateExecuteDecreaseOrderGasLimit(
        IGmxV2DataStore dataStore,
        uint256 swapPathLength,
        uint256 callbackGasLimit
    ) internal view returns (uint256) {
        uint256 gasPerSwap = dataStore.getUint(Keys.singleSwapGasLimitKey());
        uint256 swapCount = swapPathLength;

        return
            dataStore.getUint(Keys.decreaseOrderGasLimitKey()) +
            gasPerSwap *
            swapCount +
            callbackGasLimit;
    }

    // @dev the estimated gas limit for swap orders
    // @param dataStore DataStore
    // @param order the order to estimate the gas limit for
    function estimateExecuteSwapOrderGasLimit(
        IGmxV2DataStore dataStore,
        uint256 swapPathLength,
        uint256 callbackGasLimit
    ) internal view returns (uint256) {
        uint256 gasPerSwap = dataStore.getUint(Keys.singleSwapGasLimitKey());
        return
            dataStore.getUint(Keys.swapOrderGasLimitKey()) +
            gasPerSwap *
            swapPathLength +
            callbackGasLimit;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IStrategyBank } from "./IStrategyBank.sol";
import { IStrategyController } from "./IStrategyController.sol";

/**
 * @title IStrategyAccount
 * @author GoldLink
 *
 * @dev Base interface for the strategy account.
 */
interface IStrategyAccount {
    // ============ Enums ============

    /// @dev The liquidation status of an account, if a multi-step liquidation is actively
    /// occurring or not.
    enum LiquidationStatus {
        // The account is not actively in a multi-step liquidation state.
        INACTIVE,
        // The account is actively in a multi-step liquidation state.
        ACTIVE
    }

    // ============ Events ============

    /// @notice Emitted when a liquidation is initiated.
    /// @param accountValue The value of the account, in terms of the `strategyAsset`, that was
    /// used to determine if the account was liquidatable.
    event InitiateLiquidation(uint256 accountValue);

    /// @notice Emitted when a liquidation is processed, which can occur once an account has been fully liquidated.
    /// @param executor The address of the executor that processed the liquidation, and the reciever of the execution premium.
    /// @param strategyAssetsBeforeLiquidation The amount of `strategyAsset` in the account before liquidation.
    /// @param strategyAssetsAfterLiquidation The amount of `strategyAsset` in the account after liquidation.
    event ProcessLiquidation(
        address indexed executor,
        uint256 strategyAssetsBeforeLiquidation,
        uint256 strategyAssetsAfterLiquidation
    );

    /// @notice Emitted when native assets are withdrawn.
    /// @param receiver The address the assets were sent to.
    /// @param amount   The amount of tokens sent.
    event WithdrawNativeAsset(address indexed receiver, uint256 amount);

    /// @notice Emitted when ERC-20 assets are withdrawn.
    /// @param receiver The address the assets were sent to.
    /// @param token    The ERC-20 token that was withdrawn.
    /// @param amount   The amount of tokens sent.
    event WithdrawErc20Asset(
        address indexed receiver,
        IERC20 indexed token,
        uint256 amount
    );

    // ============ External Functions ============

    /// @dev Initialize the account.
    function initialize(
        address owner,
        IStrategyController strategyController
    ) external;

    /// @dev Execute a borrow against the `strategyBank`.
    function executeBorrow(uint256 loan) external returns (uint256 loanNow);

    /// @dev Execute repaying a loan for an existing strategy bank.
    function executeRepayLoan(
        uint256 repayAmount
    ) external returns (uint256 loanNow);

    /// @dev Execute withdrawing collateral for an existing strategy bank.
    function executeWithdrawCollateral(
        address onBehalfOf,
        uint256 collateral,
        bool useSoftWithdrawal
    ) external returns (uint256 collateralNow);

    /// @dev Execute add collateral for the strategy account.
    function executeAddCollateral(
        uint256 collateral
    ) external returns (uint256 collateralNow);

    /// @dev Initiates an account liquidation, checking to make sure that the account's health score puts it in the liquidable range.
    function executeInitiateLiquidation() external;

    /// @dev Processes a liquidation, checking to make sure that all assets have been liquidated, and then notifying the `StrategyBank` of the liquidated asset's for accounting purposes.
    function executeProcessLiquidation()
        external
        returns (uint256 premium, uint256 loanLoss);

    /// @dev Get the positional value of the strategy account.
    function getAccountValue() external view returns (uint256);

    /// @dev Get the owner of this strategy account.
    function getOwner() external view returns (address owner);

    /// @dev Get the liquidation status of the account.
    function getAccountLiquidationStatus()
        external
        view
        returns (LiquidationStatus status);

    /// @dev Get address of strategy bank.
    function STRATEGY_BANK() external view returns (IStrategyBank strategyBank);

    /// @dev Get the GoldLink protocol asset.
    function STRATEGY_ASSET() external view returns (IERC20 strategyAsset);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";
import { GmxStorageGetters } from "./GmxStorageGetters.sol";
import { GmxMarketGetters } from "./GmxMarketGetters.sol";
import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";
import { IGmxV2DataStore } from "../interfaces/gmx/IGmxV2DataStore.sol";
import { IStrategyBank } from "../../../interfaces/IStrategyBank.sol";
import { DeltaConvergenceMath } from "./DeltaConvergenceMath.sol";
import { AccountGetters } from "./AccountGetters.sol";
import { Pricing } from "./Pricing.sol";
import {
    StrategyBankHelpers
} from "../../../libraries/StrategyBankHelpers.sol";
import { PercentMath } from "../../../libraries/PercentMath.sol";
import { GmxFrfStrategyErrors } from "../GmxFrfStrategyErrors.sol";
import { SwapCallbackLogic } from "./SwapCallbackLogic.sol";

/**
 * @title WithdrawalLogic
 * @author GoldLink
 *
 * @dev Logic for managing profit withdrawals.
 */
library WithdrawalLogic {
    using PercentMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Structs ============

    struct WithdrawProfitParams {
        address market;
        uint256 amount;
        address recipient;
    }

    // ============ External Functions ============

    /**
     * @notice Withdraw profit from the account up to the configured profit margin. When withdrawing profit,
     * the value of the account should never go below the value of the account's `loan` + `minWithdrawalBufferPercent`.
     * @param manager   The configuration manager for the strategy.
     * @param account   The account that is attempting to withdraw profit.
     * @param params    Withdrawal related parameters.
     */
    function withdrawProfit(
        IGmxFrfStrategyManager manager,
        IStrategyBank bank,
        address account,
        WithdrawProfitParams memory params
    ) external {
        // Return early if amount is 0.
        if (params.amount == 0) {
            return;
        }

        // Make sure that the delta of the position is respected when removing assets from the account.
        verifyMarketAssetRemoval(
            manager,
            params.market,
            account,
            params.amount
        );

        address asset = GmxMarketGetters.getLongToken(
            manager.gmxV2DataStore(),
            params.market
        );

        // At this point, it is known that the withdrawal respects the delta of the position. However,
        // the account's value must be checked against its loan and remaining collateral to ensure that the withdrawn funds do not
        // result in a value that is less than the account's loan times the configured `withdrawalBufferPercent`.

        {
            // The first step to verify the account's solvency for a withdrawal is to compute the current value of the account in terms of USDC.
            uint256 accountValueUSDC = AccountGetters.getAccountValueUsdc(
                manager,
                account
            );

            // In order to withdraw profits, the account's value after the withdrawal must be above the minimum open health score.
            uint256 withdrawalValueUSD = Pricing.getTokenValueUSD(
                manager,
                asset,
                params.amount
            );

            uint256 withdrawalValueUSDC = Pricing.getTokenAmountForUSD(
                manager,
                address(manager.USDC()),
                withdrawalValueUSD
            );

            // To make sure that the value of the withdrawal does not exceed the account value. This also prevents underflow causing a revert without
            // proper cause in the subtraction below.
            require(
                withdrawalValueUSDC < accountValueUSDC,
                GmxFrfStrategyErrors
                    .WITHDRAWAL_VALUE_CANNOT_BE_GTE_ACCOUNT_VALUE
            );

            // Make sure to get the holdings after paying interest. Interest accrued must be considered when checking the health score.
            IStrategyBank.StrategyAccountHoldings memory holdings = bank
                .getStrategyAccountHoldingsAfterPayingInterest(account);

            uint256 withdrawalBuffer = manager
                .getProfitWithdrawalBufferPercent();

            // The value of the account less the withdrawn value must be greater than the account's loan. If this were not the case,
            // you could open a loan above the minimum open health score and withdraw assets.
            // Note: The manager prevents the `withdrawalBuffer` from being less than 100%, so its impossible to divide by zero here.
            require(
                accountValueUSDC - withdrawalValueUSDC >
                    holdings.loan.percentToFraction(withdrawalBuffer),
                GmxFrfStrategyErrors
                    .CANNOT_WITHDRAW_BELOW_THE_ACCOUNTS_LOAN_VALUE_WITH_BUFFER_APPLIED
            );

            // Get the health score of the account after the withdrawal has been accounted for to ensure it abides by the strategy's minimum open health
            // score requirements.
            uint256 healthScore = StrategyBankHelpers.getHealthScore(
                holdings,
                accountValueUSDC - withdrawalValueUSDC
            );

            require(
                healthScore >= bank.minimumOpenHealthScore_(),
                GmxFrfStrategyErrors
                    .WITHDRAWAL_BRINGS_ACCOUNT_BELOW_MINIMUM_OPEN_HEALTH_SCORE
            );
        }

        // Since all checks pass, withdraw the funds.
        IERC20(asset).safeTransfer(params.recipient, params.amount);
    }

    /**
     * @notice Swap tokens for USDC, allowing an account to use funding fees paid in longTokens
     * to repay their loan.
     * @param manager            The configuration manager for the strategy.
     * @param market             The market to swap the `longToken` of for USDC.
     * @param account            The strategy account address that is swapping tokens.
     * @param longTokenAmountOut The amount of the `market.longToken` to sell for USDC.
     * @param callback           The address of the callback handler. This address must be a smart contract that implements the
     * `ISwapCallbackHandler` interface.
     * @param receiver           The address that the `longToken` should be sent to.
     * @param data               Data passed through to the callback contract.
     */
    function swapTokensForUSDC(
        IGmxFrfStrategyManager manager,
        address market,
        address account,
        uint256 longTokenAmountOut,
        address callback,
        address receiver,
        bytes memory data
    ) external returns (uint256 amountReceived) {
        // Return early if amount is zero.
        if (longTokenAmountOut == 0) {
            return 0;
        }

        // Make sure that the delta of the account's positions is respected.
        verifyMarketAssetRemoval(manager, market, account, longTokenAmountOut);

        address longToken = GmxMarketGetters.getLongToken(
            manager.gmxV2DataStore(),
            market
        );

        // Need to get the market configuration in order to pass in the proper `maxSlippageAmount` to the swap callback handler.
        IGmxFrfStrategyManager.MarketConfiguration memory marketConfig = manager
            .getMarketConfiguration(market);

        // Execute the callback, returning the amount of USDC that was received by the contract.
        return
            SwapCallbackLogic.handleSwapCallback(
                manager,
                longToken,
                longTokenAmountOut,
                marketConfig.orderPricingParameters.maxSwapSlippagePercent,
                callback,
                receiver,
                data
            );
    }

    // ============ Public Functions ============

    /**
     * @notice Verify that reducing the amount of `market.longToken` from the account's holdings
     * will not increase the directional risk of a strategy account.
     * @param manager             The configuration manager for the strategy.
     * @param market              The market to swap the `longToken` of for USDC.
     * @param account             The strategy account address that `longTokens` are being removed from.
     * @param tokenAmountRemoving The amount of the `market.longToken` that is being removed from the account.
     */
    function verifyMarketAssetRemoval(
        IGmxFrfStrategyManager manager,
        address market,
        address account,
        uint256 tokenAmountRemoving
    ) public view {
        // Return early if amount is 0.
        if (tokenAmountRemoving == 0) {
            return;
        }

        // First, we get the position information (if it exists). We do this because we need to make sure that the delta of the position is respected when withdrawing profit.
        DeltaConvergenceMath.PositionTokenBreakdown
            memory breakdown = DeltaConvergenceMath.getAccountMarketDelta(
                manager,
                account,
                market,
                0,
                true
            );

        // Make sure the requested withdrawal amount does not exceed the current long token balance of the account.
        require(
            breakdown.accountBalanceLongTokens >= tokenAmountRemoving,
            GmxFrfStrategyErrors
                .CANNOT_WITHDRAW_MORE_TOKENS_THAN_ACCOUNT_BALANCE
        );

        {
            // Check to make sure the position's delta is long (more long tokens then short). This prevents the below subtraction from reverting due to underflow.
            require(
                breakdown.tokensShort < breakdown.tokensLong,
                GmxFrfStrategyErrors
                    .CANNOT_WITHDRAW_FROM_MARKET_IF_ACCOUNT_MARKET_DELTA_IS_SHORT
            );

            // The maximum amount that can be withdrawn is the amount that perfectly aligns the position's delta.
            uint256 difference = breakdown.tokensLong - breakdown.tokensShort;

            // Check to make sure that the amount of tokens being removed is less than the difference in the
            // sizeInTokens of the account's long position - short position.
            require(
                tokenAmountRemoving <= difference,
                GmxFrfStrategyErrors
                    .REQUESTED_WITHDRAWAL_AMOUNT_EXCEEDS_CURRENT_DELTA_DIFFERENCE
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified version of https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/Reader.sol
// Modified as follows:
// - Using GoldLink types

pragma solidity ^0.8.0;

import {
    IGmxV2MarketTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2MarketTypes.sol";
import {
    IGmxV2PriceTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PriceTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import { IGmxV2OrderTypes } from "./IGmxV2OrderTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import {
    IGmxV2DataStore
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";

interface IGmxV2Reader {
    function getMarket(
        IGmxV2DataStore dataStore,
        address key
    ) external view returns (IGmxV2MarketTypes.Props memory);

    function getMarketBySalt(
        IGmxV2DataStore dataStore,
        bytes32 salt
    ) external view returns (IGmxV2MarketTypes.Props memory);

    function getPosition(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) external view returns (IGmxV2PositionTypes.Props memory);

    function getOrder(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) external view returns (IGmxV2OrderTypes.Props memory);

    function getPositionPnlUsd(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        bytes32 positionKey,
        uint256 sizeDeltaUsd
    ) external view returns (int256, int256, uint256);

    function getAccountPositions(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2PositionTypes.Props[] memory);

    function getAccountPositionInfoList(
        IGmxV2DataStore dataStore,
        IGmxV2ReferralStorage referralStorage,
        bytes32[] memory positionKeys,
        IGmxV2MarketTypes.MarketPrices[] memory prices,
        address uiFeeReceiver
    ) external view returns (IGmxV2PositionTypes.PositionInfo[] memory);

    function getPositionInfo(
        IGmxV2DataStore dataStore,
        IGmxV2ReferralStorage referralStorage,
        bytes32 positionKey,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 sizeDeltaUsd,
        address uiFeeReceiver,
        bool usePositionSizeAsSizeDeltaUsd
    ) external view returns (IGmxV2PositionTypes.PositionInfo memory);

    function getAccountOrders(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2OrderTypes.Props[] memory);

    function getMarkets(
        IGmxV2DataStore dataStore,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2MarketTypes.Props[] memory);

    function getMarketInfoList(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.MarketPrices[] memory marketPricesList,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2MarketTypes.MarketInfo[] memory);

    function getMarketInfo(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.MarketPrices memory prices,
        address marketKey
    ) external view returns (IGmxV2MarketTypes.MarketInfo memory);

    function getMarketTokenPrice(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        IGmxV2PriceTypes.Props memory longTokenPrice,
        IGmxV2PriceTypes.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, IGmxV2MarketTypes.PoolValueInfo memory);

    function getNetPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool maximize
    ) external view returns (int256);

    function getPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getOpenInterestWithPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getPnlToPoolFactor(
        IGmxV2DataStore dataStore,
        address marketAddress,
        IGmxV2MarketTypes.MarketPrices memory prices,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getSwapAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        address tokenIn,
        uint256 amountIn,
        address uiFeeReceiver
    )
        external
        view
        returns (uint256, int256, IGmxV2PriceTypes.SwapFees memory fees);

    function getExecutionPrice(
        IGmxV2DataStore dataStore,
        address marketKey,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        uint256 positionSizeInUsd,
        uint256 positionSizeInTokens,
        int256 sizeDeltaUsd,
        bool isLong
    ) external view returns (IGmxV2PriceTypes.ExecutionPriceResult memory);

    function getSwapPriceImpact(
        IGmxV2DataStore dataStore,
        address marketKey,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        IGmxV2PriceTypes.Props memory tokenInPrice,
        IGmxV2PriceTypes.Props memory tokenOutPrice
    ) external view returns (int256, int256);

    function getAdlState(
        IGmxV2DataStore dataStore,
        address market,
        bool isLong,
        IGmxV2MarketTypes.MarketPrices memory prices
    ) external view returns (uint256, bool, int256, uint256);

    function getDepositAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 longTokenAmount,
        uint256 shortTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256);

    function getWithdrawalAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 marketTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

interface IGmxV2ReferralStorage {}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWrappedNativeToken
 * @author GoldLink
 *
 * @dev Interface for wrapping native network tokens.
 */
interface IWrappedNativeToken is IERC20 {
    // ============ External Functions ============

    /// @dev Deposit ETH into contract for wrapped tokens.
    function deposit() external payable;

    /// @dev Withdraw ETH by burning wrapped tokens.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    IGmxV2OrderTypes
} from "../../../../lib/gmx/interfaces/external/IGmxV2OrderTypes.sol";
import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";

/**
 * @title IGmxV2EventUtilsTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's ExchangeRouter.
 * Contract this is an interface for can be found here: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/router/ExchangeRouter.sol
 */
interface IGmxV2ExchangeRouter {
    struct SimulatePricesParams {
        address[] primaryTokens;
        IGmxV2PriceTypes.Props[] primaryPrices;
    }

    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);

    function sendWnt(address receiver, uint256 amount) external payable;

    function sendTokens(
        address token,
        address receiver,
        uint256 amount
    ) external payable;

    function sendNativeToken(address receiver, uint256 amount) external payable;

    function setSavedCallbackContract(
        address market,
        address callbackContract
    ) external payable;

    function cancelWithdrawal(bytes32 key) external payable;

    function createOrder(
        IGmxV2OrderTypes.CreateOrderParams calldata params
    ) external payable returns (bytes32);

    function updateOrder(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice,
        uint256 minOutputAmount
    ) external payable;

    function cancelOrder(bytes32 key) external payable;

    function simulateExecuteOrder(
        bytes32 key,
        SimulatePricesParams memory simulatedOracleParams
    ) external payable;

    function claimFundingFees(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);

    function claimCollateral(
        address[] memory markets,
        address[] memory tokens,
        uint256[] memory timeKeys,
        address receiver
    ) external payable returns (uint256[] memory);

    function setUiFeeFactor(uint256 uiFeeFactor) external payable;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IGmxV2RoleStore
 * @author GoldLink
 *
 * @dev Interface for the GMX role store.
 * Adapted from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/role/RoleStore.sol
 */
interface IGmxV2RoleStore {
    function hasRole(
        address account,
        bytes32 roleKey
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { ISwapCallbackHandler } from "./ISwapCallbackHandler.sol";

/**
 * @title ISwapCallbackRelayer
 * @author GoldLink
 *
 * @dev Serves as a middle man for executing the swapCallback function in order to
 * prevent any issues that arise due to signature collisions and the msg.sender context
 * of a strategyAccount.
 */
interface ISwapCallbackRelayer {
    // ============ External Functions ============

    /// @dev Relay a swap callback on behalf of another address.
    function relaySwapCallback(
        address callbackHandler,
        uint256 tokensToLiquidate,
        uint256 expectedUsdc,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IStrategyReserve } from "./IStrategyReserve.sol";
import { IStrategyAccountDeployer } from "./IStrategyAccountDeployer.sol";

/**
 * @title IStrategyBank
 * @author GoldLink
 *
 * @dev Base interface for the strategy bank.
 */
interface IStrategyBank {
    // ============ Structs ============

    /// @dev Parameters for the strategy bank being created.
    struct BankParameters {
        // The minimum health score a strategy account can actively take on.
        uint256 minimumOpenHealthScore;
        // The health score at which point a strategy account becomes liquidatable.
        uint256 liquidatableHealthScore;
        // The executor premium for executing a completed liquidation.
        uint256 executorPremium;
        // The insurance premium for repaying a loan.
        uint256 insurancePremium;
        // The insurance premium for liquidations, slightly higher than the
        // `INSURANCE_PREMIUM`.
        uint256 liquidationInsurancePremium;
        // The minimum active balance of collateral a strategy account can have.
        uint256 minimumCollateralBalance;
        // The strategy account deployer that deploys new strategy accounts for borrowers.
        IStrategyAccountDeployer strategyAccountDeployer;
    }

    /// @dev Strategy account assets and liabilities representing value in the strategy.
    struct StrategyAccountHoldings {
        // Collateral funds.
        uint256 collateral;
        // Loan capital outstanding.
        uint256 loan;
        // Last interest index for the strategy account.
        uint256 interestIndexLast;
    }

    // ============ Events ============

    /// @notice Emitted when updating the minimum open health score.
    /// @param newMinimumOpenHealthScore The new minimum open health score.
    event UpdateMinimumOpenHealthScore(uint256 newMinimumOpenHealthScore);

    /// @notice Emitted when getting interest and taking insurance before any
    /// reserve state-changing action.
    /// @param totalRequested       The total requested by the strategy reserve and insurance.
    /// @param fromCollateral       The amount of the request that was taken from collateral.
    /// @param interestAndInsurance The interest and insurance paid by this bank. Will be less
    /// than requested if there is not enough collateral + insurance to pay.
    event GetInterestAndTakeInsurance(
        uint256 totalRequested,
        uint256 fromCollateral,
        uint256 interestAndInsurance
    );

    /// @notice Emitted when liquidating a loan.
    /// @param liquidator      The address that performed the liquidation and is
    /// receiving the premium.
    /// @param strategyAccount The address of the strategy account.
    /// @param loanLoss        The loss being sent to lenders.
    /// @param premium         The amount of funds paid to the liquidator from the strategy.
    event LiquidateLoan(
        address indexed liquidator,
        address indexed strategyAccount,
        uint256 loanLoss,
        uint256 premium
    );

    /// @notice Emitted when adding collateral for a strategy account.
    /// @param sender          The address adding collateral.
    /// @param strategyAccount The strategy account address the collateral is for.
    /// @param collateral      The amount of collateral being put up for the loan.
    event AddCollateral(
        address indexed sender,
        address indexed strategyAccount,
        uint256 collateral
    );

    /// @notice Emitted when borrowing funds for a strategy account.
    /// @param strategyAccount The address of the strategy account borrowing funds.
    /// @param loan            The size of the loan to borrow.
    event BorrowFunds(address indexed strategyAccount, uint256 loan);

    /// @notice Emitted when repaying a loan for a strategy account.
    /// @param strategyAccount The address of the strategy account paying back
    /// the loan.
    /// @param repayAmount     The loan assets being repaid.
    /// @param collateralUsed  The collateral used to repay part of the loan if loss occured.
    event RepayLoan(
        address indexed strategyAccount,
        uint256 repayAmount,
        uint256 collateralUsed
    );

    /// @notice Emitted when withdrawing collateral.
    /// @param strategyAccount The address maintaining the strategy account's holdings.
    /// @param onBehalfOf      The address receiving the collateral.
    /// @param collateral      The collateral being withdrawn from the strategy bank.
    event WithdrawCollateral(
        address indexed strategyAccount,
        address indexed onBehalfOf,
        uint256 collateral
    );

    /// @notice Emitted when a strategy account is opened.
    /// @param strategyAccount The address of the strategy account.
    /// @param owner           The address of the strategy account owner.
    event OpenAccount(address indexed strategyAccount, address indexed owner);

    // ============ External Functions ============

    /// @dev Update the minimum open health score for the strategy bank.
    function updateMinimumOpenHealthScore(
        uint256 newMinimumOpenHealthScore
    ) external;

    /// @dev Delegates reentrancy locking to the bank, only callable by valid strategy accounts.
    function acquireLock() external;

    /// @dev Delegates reentrancy unlocking to the bank, only callable by valid strategy accounts.
    function releaseLock() external;

    /// @dev Get interest from this contract for `msg.sender` which must
    /// be the `StrategyReserve` to then transfer out of this contract.
    function getInterestAndTakeInsurance(
        uint256 totalRequested
    ) external returns (uint256 interestToPay);

    /// @dev Processes a strategy account liquidation.
    function processLiquidation(
        address liquidator,
        uint256 availableAccountAssets
    ) external returns (uint256 premium, uint256 loanLoss);

    /// @dev Add collateral for a strategy account into the strategy bank.
    function addCollateral(
        address provider,
        uint256 collateral
    ) external returns (uint256 collateralNow);

    /// @dev Borrow funds from the `StrategyReserve` into the strategy bank.
    function borrowFunds(uint256 loan) external returns (uint256 loanNow);

    /// @dev Repay loaned funds for a holdings.
    function repayLoan(
        uint256 repayAmount,
        uint256 accountValue
    ) external returns (uint256 loanNow);

    /// @dev Withdraw collateral from the strategy bank.
    function withdrawCollateral(
        address onBehalfOf,
        uint256 requestedWithdraw,
        bool useSoftWithdrawal
    ) external returns (uint256 collateralNow);

    /// @dev Open a new strategy account associated with `owner`.
    function executeOpenAccount(
        address owner
    ) external returns (address strategyAccount);

    /// @dev The strategy account deployer that deploys new strategy accounts for borrowers.
    function STRATEGY_ACCOUNT_DEPLOYER()
        external
        view
        returns (IStrategyAccountDeployer strategyAccountDeployer);

    /// @dev Strategy reserve address.
    function STRATEGY_RESERVE()
        external
        view
        returns (IStrategyReserve strategyReserve);

    /// @dev The asset that this strategy uses for lending accounting.
    function STRATEGY_ASSET() external view returns (IERC20 strategyAsset);

    /// @dev Get the minimum open health score.
    function minimumOpenHealthScore_()
        external
        view
        returns (uint256 minimumOpenHealthScore);

    /// @dev Get the liquidatable health score.
    function LIQUIDATABLE_HEALTH_SCORE()
        external
        view
        returns (uint256 liquidatableHealthScore);

    /// @dev Get the executor premium.
    function EXECUTOR_PREMIUM() external view returns (uint256 executorPremium);

    /// @dev Get the liquidation premium.
    function LIQUIDATION_INSURANCE_PREMIUM()
        external
        view
        returns (uint256 liquidationInsurancePremium);

    /// @dev Get the insurance premium.
    function INSURANCE_PREMIUM()
        external
        view
        returns (uint256 insurancePremium);

    /// @dev Get the total collateral deposited.
    function totalCollateral_() external view returns (uint256 totalCollateral);

    /// @dev Get a strategy account's holdings.
    function getStrategyAccountHoldings(
        address strategyAccount
    )
        external
        view
        returns (StrategyAccountHoldings memory strategyAccountHoldings);

    /// @dev Get withdrawable collateral such that it can be taken out while
    /// `minimumOpenHealthScore_` is still respected.
    function getWithdrawableCollateral(
        address strategyAccount
    ) external view returns (uint256 withdrawableCollateral);

    /// @dev Check if a position is liquidatable.
    function isAccountLiquidatable(
        address strategyAccount,
        uint256 positionValue
    ) external view returns (bool isLiquidatable);

    /// @dev Get strategy account's holdings after interest is paid.
    function getStrategyAccountHoldingsAfterPayingInterest(
        address strategyAccount
    ) external view returns (StrategyAccountHoldings memory holdings);

    /// @dev Get list of strategy accounts within two provided indicies.
    function getStrategyAccounts(
        uint256 startIndex,
        uint256 stopIndex
    ) external view returns (address[] memory accounts);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IStrategyAccountDeployer } from "./IStrategyAccountDeployer.sol";
import { IStrategyBank } from "./IStrategyBank.sol";
import { IStrategyReserve } from "./IStrategyReserve.sol";

/**
 * @title IStrategyController
 * @author GoldLink
 *
 * @dev Interface for the `StrategyController`, which manages strategy-wide pausing, reentrancy and acts as a registry for the core strategy contracts.
 */
interface IStrategyController {
    // ============ External Functions ============

    /// @dev Aquire a strategy wide lock, preventing reentrancy across the entire strategy. Callers must unlock after.
    function acquireStrategyLock() external;

    /// @dev Release a strategy lock.
    function releaseStrategyLock() external;

    /// @dev Pauses the strategy, preventing it from taking any new actions. Only callable by the owner.
    function pause() external;

    /// @dev Unpauses the strategy. Only callable by the owner.
    function unpause() external;

    /// @dev Get the address of the `StrategyAccountDeployer` associated with this strategy.
    function STRATEGY_ACCOUNT_DEPLOYER()
        external
        view
        returns (IStrategyAccountDeployer deployer);

    /// @dev Get the address of the `StrategyAsset` associated with this strategy.
    function STRATEGY_ASSET() external view returns (IERC20 asset);

    /// @dev Get the address of the `StrategyBank` associated with this strategy.
    function STRATEGY_BANK() external view returns (IStrategyBank bank);

    /// @dev Get the address of the `StrategyReserve` associated with this strategy.
    function STRATEGY_RESERVE()
        external
        view
        returns (IStrategyReserve reserve);

    /// @dev Return if paused.
    function isPaused() external view returns (bool currentlyPaused);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import {
    IGmxV2PriceTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PriceTypes.sol";
import {
    GmxMarketGetters
} from "../../../strategies/gmxFrf/libraries/GmxMarketGetters.sol";
import {
    IGmxV2Reader
} from "../../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2OrderTypes
} from "../../../lib/gmx/interfaces/external/IGmxV2OrderTypes.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2MarketTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2MarketTypes.sol";
import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";
import { IMarketConfiguration } from "../interfaces/IMarketConfiguration.sol";
import { PercentMath } from "../../../libraries/PercentMath.sol";
import {
    PositionStoreUtils
} from "../../../lib/gmx/position/PositionStoreUtils.sol";
import { OrderStoreUtils } from "../../../lib/gmx/order/OrderStoreUtils.sol";
import { Pricing } from "../libraries/Pricing.sol";
import { DeltaConvergenceMath } from "../libraries/DeltaConvergenceMath.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";
import { Order } from "../../../lib/gmx/order/Order.sol";
import { GmxStorageGetters } from "./GmxStorageGetters.sol";

/**
 * @title AccountGetters
 * @author GoldLink
 *
 * @dev Manages all orders that flow through this account. This includes order execution,
 * cancellation, and freezing. This is required because the
 */
library AccountGetters {
    using PercentMath for uint256;
    using Order for IGmxV2OrderTypes.Props;

    // ============ External Functions ============

    /**
     * @notice Get the total value of the account in terms of USDC.
     * @param manager             The configuration manager for the strategy.
     * @param account             The account to get the value of
     * @return strategyAssetValue The value of a position in terms of USDC.
     */
    function getAccountValueUsdc(
        IGmxFrfStrategyManager manager,
        address account
    ) external view returns (uint256 strategyAssetValue) {
        // First we get the value in USD, since our oracles are priced in USD. Then
        // we can use the USDC oracle price to get the value in USDC.
        uint256 valueUSD = 0;

        // Add the value of ERC-20 tokens held by this account. We do not count native tokens
        // since this can be misleading in cases where liquidators are paying an execution fee.
        valueUSD += _getAccountTokenValueUSD(manager, account);
        // Get the value of all positions that currently exist.
        valueUSD += getAccountPositionsValueUSD(manager, account);
        // Get the values of the orders that are currently active. This only applies to increase orders,
        // because the value of decreases orders is reflected in the position.
        valueUSD += getAccountOrdersValueUSD(manager, account);
        // Get the value of all settled funding fees.
        valueUSD += getSettledFundingFeesValueUSD(manager, account);

        // Since the strategy asset is USDC, return the value of these assets in terms of USDC. This converts from USD -> USDC.
        // This is neccesary for borrower accounting to function properly, as the bank is unware of GMX-specific USD.
        return
            Pricing.getTokenAmountForUSD(
                manager,
                address(manager.USDC()),
                valueUSD
            );
    }

    /**
     * @notice Implements is liquidation finished, validating:
     * 1. There are no pending orders for the account.
     * 2. There are no open positions for the account.
     * 3. There are no unclaimed funding fees for the acocunt.
     * 4. The long token balance of this account is below the dust threshold for the market.
     * @param manager   The configuration manager for the strategy.
     * @param account   The account to check whether the liquidation is finished.
     * @return finished If the liquidation is finished and the `StrategyBank` can now execute
     * the liquidation, returning funds to lenders.
     */
    function isLiquidationFinished(
        IGmxFrfStrategyManager manager,
        address account
    ) external view returns (bool) {
        IGmxV2DataStore dataStore = manager.gmxV2DataStore();

        {
            // Check to make sure there are zero pending orders. This is important in the event that the borrower had an active order, and before
            // the keeper finishes executed the order, a liquidation was both initiated and processed.
            uint256 orderCount = OrderStoreUtils.getAccountOrderCount(
                dataStore,
                account
            );
            if (orderCount != 0) {
                return false;
            }
        }

        // All positions must be liquidated before the liquidation is finished. If an account is allowed to repay its debts while still having active positions,
        // then lenders may not recieve all of their funds back.
        uint256 positionCount = PositionStoreUtils.getAccountPositionCount(
            dataStore,
            account
        );
        if (positionCount != 0) {
            return false;
        }

        // Get all available markets to check funding fees for.
        address[] memory markets = manager.getAvailableMarkets();

        uint256 marketsLength = markets.length;
        for (uint256 i = 0; i < marketsLength; ++i) {
            (address shortToken, address longToken) = GmxMarketGetters
                .getMarketTokens(dataStore, markets[i]);

            // If there are unclaimed short tokens that are owed to the account, these must be claimed as they can directly be paid back to lenders
            // and therefore must be accounted for in the liquidation process. The `minimumSwapRebalanceSize` is not used here because external actors cannot
            // force unclaimed funding fees to be non zero.
            uint256 unclaimedShortTokens = GmxStorageGetters
                .getClaimableFundingFees(
                    dataStore,
                    markets[i],
                    shortToken,
                    account
                );
            if (unclaimedShortTokens != 0) {
                return false;
            }

            uint256 unclaimedLongTokens = GmxStorageGetters
                .getClaimableFundingFees(
                    dataStore,
                    markets[i],
                    longToken,
                    account
                );

            IMarketConfiguration.UnwindParameters memory unwindConfig = manager
                .getMarketUnwindConfiguration(markets[i]);

            // It would be possible to prevent liquidation by continuously sending tokens to the account, so we use the configured "dust threshold" to
            // determine if the tokens held by the account have any meaningful value. The two are combined because otherwise this may result in forcing a liquidator
            // to claim funding fees, just to have the `minSwapRebalanceSize` check to pass.
            if (
                IERC20(longToken).balanceOf(account) + unclaimedLongTokens >=
                unwindConfig.minSwapRebalanceSize
            ) {
                return false;
            }
        }

        // Since there are no remaining positions, no remaining orders,  and the token balances of the account + unclaimed funding fees
        // are below the minimum swap rebalance size, the liquidation is finished.
        return true;
    }

    // ============ Public Functions ============

    /**
     * @notice Get account orders value USD, the USD value of all account orders. The value of an order only relates to the actual assets associated with it, not
     * the size of the order itself. This implies the only orders that have a value > 0 are increase orders, because the initial collateral is locked into the order.
     * Decrease orders have zero value because the value they produce is accounted for in the position pnl/collateral value.
     * @param manager     The configuration manager for the strategy.
     * @param account     The account to get the orders value for.
     * @return totalValue The USD value of all account orders.
     */
    function getAccountOrdersValueUSD(
        IGmxFrfStrategyManager manager,
        address account
    ) public view returns (uint256 totalValue) {
        // Get the keys of all account orders.
        bytes32[] memory accountOrderKeys = OrderStoreUtils.getAccountOrderKeys(
            manager.gmxV2DataStore(),
            account
        );

        // Iterate through all account orders and sum `totalValue`.
        uint256 accountOrderKeysLength = accountOrderKeys.length;
        for (uint256 i = 0; i < accountOrderKeysLength; ++i) {
            totalValue += getOrderValueUSD(manager, accountOrderKeys[i]);
        }

        return totalValue;
    }

    /**
     * @notice Get the order associated with `orderId` 's value in terms of USD. The value of any non-increase order is 0, and the value of an increase order is simply the value
     * of the initial collateral.
     * @param manager        The configuration manager for the strategy.
     * @param orderId        The id of the order to get the value of in USD.
     * @return orderValueUSD The value of the order in USD.
     */
    function getOrderValueUSD(
        IGmxFrfStrategyManager manager,
        bytes32 orderId
    ) public view returns (uint256 orderValueUSD) {
        IGmxV2DataStore dataStore = manager.gmxV2DataStore();

        IGmxV2OrderTypes.Props memory order = OrderStoreUtils.get(
            dataStore,
            orderId
        );

        // If an increase order exists and has not yet been executed, include the value in the account's value,
        // since the order will contain a portion of the USDC that the account is entitled to. Otherwise, the value of the order
        // is 0.
        if (order.orderType() != IGmxV2OrderTypes.OrderType.MarketIncrease) {
            return 0;
        }

        // If an order exists and has not yet been executed, the best we can do to get the value of
        // the order is to get the value of the initial collateral.
        return
            Pricing.getTokenValueUSD(
                manager,
                order.addresses.initialCollateralToken,
                order.numbers.initialCollateralDeltaAmount
            );
    }

    /**
     * @notice Get the value of all positions in USD for an account.
     * @param manager     The configuration manager for the strategy.
     * @param account     The account of to value positions for.
     * @return totalValue The value of all positions in USD for this account.
     */
    function getAccountPositionsValueUSD(
        IGmxFrfStrategyManager manager,
        address account
    ) public view returns (uint256 totalValue) {
        // Get all possible markets this account can have a position in.
        address[] memory availableMarkets = manager.getAvailableMarkets();

        // Iterate over all positions for this account and add value of each position.
        uint256 availableMarketsLength = availableMarkets.length;
        for (uint256 i = 0; i < availableMarketsLength; ++i) {
            totalValue += getPositionValue(
                manager,
                account,
                availableMarkets[i]
            );
        }

        return totalValue;
    }

    /**
     * @notice Get the value of a position in USD.
     * @param manager   The configuration manager for the strategy.
     * @param account   The account the get the position in `market`'s value for.
     * @param market    The market to get the value of the position for.
     * @return valueUSD The value of the position in USD.
     */
    function getPositionValue(
        IGmxFrfStrategyManager manager,
        address account,
        address market
    ) public view returns (uint256 valueUSD) {
        return
            DeltaConvergenceMath.getPositionValueUSD(manager, account, market);
    }

    /**
     * @notice Get the value of all account claims in terms of USD. This calculates the value of all unclaimed, settled funding fees for the account.
     * This method does NOT include the value of collateral claims, as collateral claims cannot be indexed on chain.
     * @param manager   The configuration manager for the strategy.
     * @param account   The account to get the claimable funding fees value for.
     * @return valueUSD The value of all funding fees in USD for the account.
     */
    function getSettledFundingFeesValueUSD(
        IGmxFrfStrategyManager manager,
        address account
    ) public view returns (uint256 valueUSD) {
        address[] memory availableMarkets = manager.getAvailableMarkets();
        IGmxV2DataStore dataStore = manager.gmxV2DataStore();

        // Iterate through all available markets and sum claimable fees.
        // If there is no position, `valueUSD` will be zero.
        uint256 availableMarketsLength = availableMarkets.length;
        for (uint256 i = 0; i < availableMarketsLength; ++i) {
            address market = availableMarkets[i];

            (address shortToken, address longToken) = GmxMarketGetters
                .getMarketTokens(dataStore, market);

            // This returns the total of the unclaimed, settled funding fees. These are positive funding fees that are accrued when a position is decreased.
            // It is important to note that these are only a subset of the position's total funding fees, as there exist unclaimed fees that must also be
            // accounted for within the position.
            (
                uint256 shortFeesClaimable,
                uint256 longFeesClaimable
            ) = getSettledFundingFees(
                    dataStore,
                    account,
                    availableMarkets[i],
                    shortToken,
                    longToken
                );

            // Short and long funding fees earned by the position are not claimable until they
            // are settled. Settlement occurs when the position size is decreased, which can occur in
            // `executeDecreasePosition`, `executeSettleFundingFees`, `executeLiquidatePosition`, `executeReleveragePosition`,
            // and `executeRebalancePosition`. Settlement is triggered any time the position size is decreased.  Once fees are settled,
            // they can be claimed by the account immediately and do not require keeper execution.
            valueUSD += Pricing.getTokenValueUSD(
                manager,
                shortToken,
                shortFeesClaimable
            );

            valueUSD += Pricing.getTokenValueUSD(
                manager,
                longToken,
                longFeesClaimable
            );
        }
    }

    /**
     * @notice Get the settked funding fees for an account for a specific market. These are funding fees
     * that have yet to be claimed by the account, but have already been settled.
     * @param dataStore                The data store to fetch claimable fees from.
     * @param account                  The account to check claimable funding fees for.
     * @param market                   The market the fees are for.
     * @param shortToken               The short token for the market to check claimable fees for.
     * @param longToken                The long token for the market to check claimable fees for.
     * @return shortTokenAmountSettled The amount of settled short token fees owed to this account.
     * @return longTokenAmountSettled  The amount of settled long token fees owed to this account.
     */
    function getSettledFundingFees(
        IGmxV2DataStore dataStore,
        address account,
        address market,
        address shortToken,
        address longToken
    )
        public
        view
        returns (
            uint256 shortTokenAmountSettled,
            uint256 longTokenAmountSettled
        )
    {
        // Get short and long amount claimable.
        shortTokenAmountSettled = GmxStorageGetters.getClaimableFundingFees(
            dataStore,
            market,
            shortToken,
            account
        );
        longTokenAmountSettled = GmxStorageGetters.getClaimableFundingFees(
            dataStore,
            market,
            longToken,
            account
        );

        return (shortTokenAmountSettled, longTokenAmountSettled);
    }

    // ============ Private Functions ============

    /**
     * @notice Calculates the valuation of all ERC20 assets in an account.
     * @param manager       The `GmxFrfStrategyManager` to use.
     * @param account       The account to calculate the valuation for.
     * @return accountValue The total value of the account in USD.
     */
    function _getAccountTokenValueUSD(
        IGmxFrfStrategyManager manager,
        address account
    ) private view returns (uint256 accountValue) {
        // Load in all registered assets.
        address[] memory assets = manager.getRegisteredAssets();

        // Iterate through all registered assets and sum account value.
        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i < assetsLength; ++i) {
            address asset = assets[i];

            // Get the balance of the asset in the account.
            uint256 assetBalance = IERC20(asset).balanceOf(account);

            // Increase total account value by asset value in USD.
            accountValue += Pricing.getTokenValueUSD(
                manager,
                asset,
                assetBalance
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IStrategyBank } from "../interfaces/IStrategyBank.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Constants } from "./Constants.sol";
import { PercentMath } from "./PercentMath.sol";

/**
 * @title StrategyBankHelpers
 * @author GoldLink
 *
 * @dev Library for strategy bank helpers.
 */
library StrategyBankHelpers {
    using PercentMath for uint256;

    // ============ Internal Functions ============

    /**
     * @notice Implements get adjusted collateral, decreasing for loss and interest owed.
     * @param holdings            The holdings being evaluated.
     * @param loanValue           The value of the loan assets at present.
     * @return adjustedCollateral The value of the collateral after adjustments.
     */
    function getAdjustedCollateral(
        IStrategyBank.StrategyAccountHoldings memory holdings,
        uint256 loanValue
    ) internal pure returns (uint256 adjustedCollateral) {
        uint256 loss = holdings.loan - Math.min(holdings.loan, loanValue);

        // Adjust collateral for loss, either down for `assetChange` or to zero.
        return holdings.collateral - Math.min(holdings.collateral, loss);
    }

    /**
     * @notice Implements get health score, calculating the current health score
     * for a strategy account's holdings.
     * @param holdings     The strategy account holdings to get health score of.
     * @param loanValue    The value of the loan assets at present.
     * @return healthScore The health score of the provided holdings.
     */
    function getHealthScore(
        IStrategyBank.StrategyAccountHoldings memory holdings,
        uint256 loanValue
    ) internal pure returns (uint256 healthScore) {
        // Handle case where loan is 0 and health score is necessarily 1e18.
        if (holdings.loan == 0) {
            return Constants.ONE_HUNDRED_PERCENT;
        }

        // Get the adjusted collateral after profit, loss and interest.
        uint256 adjustedCollateral = getAdjustedCollateral(holdings, loanValue);

        // Return health score as a ratio of `(collateral - loss - interest)`
        // to loan. This is then multiplied by 1e18.
        return adjustedCollateral.fractionToPercentCeil(holdings.loan);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { GmxFrfStrategyErrors } from "../GmxFrfStrategyErrors.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";
import { ISwapCallbackRelayer } from "../interfaces/ISwapCallbackRelayer.sol";
import { Pricing } from "./Pricing.sol";
import { PercentMath } from "../../../libraries/PercentMath.sol";

/**
 * @title SwapCallbackLogic
 * @author GoldLink
 * @dev Library for handling swap callback functions.
 */
library SwapCallbackLogic {
    using SafeERC20 for IERC20;
    using PercentMath for uint256;

    // ============ External Functions ============

    /**
     * @notice Handle the accounting for an atomic asset swap, used for selling off spot assets.
     * @param asset              The asset being swapped. If the asset does not have a valid oracle, the call will revert.
     * @param amount             The amount of `asset` that should be sent to the `tokenReciever`.
     * @param maxSlippagePercent The maximum slippage percent allowed during the callback's execution.
     * @param callback           The callback that will be called to handle the swap. This must implement the `ISwapCallbackHandler` interface and return the expected USDC amount
     * after execution finishes.
     * @param tokenReceiever    The address that should recieve the `asset` being swapped.
     * @param data              Data passed through to the callback contract.
     * @return usdcAmountIn     The amount of USDC received back after the callback.
     */
    function handleSwapCallback(
        IGmxFrfStrategyManager manager,
        address asset,
        uint256 amount,
        uint256 maxSlippagePercent,
        address callback,
        address tokenReceiever,
        bytes memory data
    ) public returns (uint256 usdcAmountIn) {
        IERC20 usdc = manager.USDC();

        // Cannot swap from USDC, as this is our target asset.
        require(
            asset != address(usdc),
            GmxFrfStrategyErrors.SWAP_CALLBACK_LOGIC_CANNOT_SWAP_USDC
        );

        // Get the value of the tokens being swapped. This is important so we can evaluate the equivalent in terms of USDC.
        uint256 valueToken = Pricing.getTokenValueUSD(manager, asset, amount);

        // Get the value of the tokens being swapped in terms of USDC.
        // Accounts for cases where USDC depegs, possibly resulting in it being impossible to fill an order assuming the price is $1.
        uint256 valueInUsdc = Pricing.getTokenAmountForUSD(
            manager,
            address(usdc),
            valueToken
        );

        // Account for slippage to determine the minimum amount of USDC that should be recieved after the callback function's
        // execution is complete.
        uint256 minimumUSDCRecieved = valueInUsdc -
            valueInUsdc.percentToFraction(maxSlippagePercent);

        // Expected USDC must be greater than zero, otherwise this would allow stealing assets from the contract when rounding down.
        require(
            minimumUSDCRecieved > 0,
            GmxFrfStrategyErrors
                .SWAP_CALLBACK_LOGIC_NO_BALANCE_AFTER_SLIPPAGE_APPLIED
        );

        // Get the balance of USDC before the swap. This is used to determine the change in the balance of USDC to check if at least `expectedUSDC` was paid back.
        uint256 balanceUSDCBefore = usdc.balanceOf(address(this));

        // Transfer the tokens to the specified reciever.
        IERC20(asset).safeTransfer(tokenReceiever, amount);

        // Enter the callback, handing over execution the callback through the `SWAP_CALLBACK_RELAYER`.
        manager.SWAP_CALLBACK_RELAYER().relaySwapCallback(
            callback,
            amount,
            minimumUSDCRecieved,
            data
        );

        usdcAmountIn = usdc.balanceOf(address(this)) - balanceUSDCBefore;

        // Check to make sure the minimum amount of assets, which was calculated above using the `maxSlippagePercent`,
        // was returned to the contract.
        require(
            usdcAmountIn >= minimumUSDCRecieved,
            GmxFrfStrategyErrors.SWAP_CALLBACK_LOGIC_INSUFFICIENT_USDC_RETURNED
        );

        return usdcAmountIn;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title ISwapCallbackHandler
 * @author GoldLink
 *
 * @dev Interfaces that implents the `handleSwapCallback` function, which allows
 * atomic swaps of spot assets for the purpose of liquidations and user profit swaps.
 */
interface ISwapCallbackHandler {
    // ============ External Functions ============

    /// @dev Handle a swap callback.
    function handleSwapCallback(
        uint256 tokensToLiquidate,
        uint256 expectedUsdc,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import { IInterestRateModel } from "./IInterestRateModel.sol";
import { IStrategyBank } from "./IStrategyBank.sol";

/**
 * @title IStrategyReserve
 * @author GoldLink
 *
 * @dev Interface for the strategy reserve, GoldLink custom ERC4626.
 */
interface IStrategyReserve is IERC4626, IInterestRateModel {
    // ============ Structs ============

    // @dev Parameters for the reserve to create.
    struct ReserveParameters {
        // The maximum total value allowed in the reserve to be lent.
        uint256 totalValueLockedCap;
        // The reserve's interest rate model.
        InterestRateModelParameters interestRateModel;
        // The name of the ERC20 minted by this vault.
        string erc20Name;
        // The symbol for the ERC20 minted by this vault.
        string erc20Symbol;
    }

    // ============ Events ============

    /// @notice Emitted when the TVL cap is updated. This the maximum
    /// capital lenders can deposit in the reserve.
    /// @param newTotalValueLockedCap The new TVL cap for the reserve.
    event TotalValueLockedCapUpdated(uint256 newTotalValueLockedCap);

    /// @notice Emitted when the balance of the `StrategyReserve` is synced.
    /// @param newBalance The new balance of the reserve after syncing.
    event BalanceSynced(uint256 newBalance);

    /// @notice Emitted when assets are borrowed from the reserve.
    /// @param borrowAmount The amount of assets borrowed by the strategy bank.
    event BorrowAssets(uint256 borrowAmount);

    /// @notice Emitted when assets are repaid to the reserve.
    /// @param initialLoan  The repay amount expected from the strategy bank.
    /// @param returnedLoan The repay amount provided by the strategy bank.
    event Repay(uint256 initialLoan, uint256 returnedLoan);

    // ============ External Functions ============

    /// @dev Update the reserve TVL cap, modifying how many assets can be lent.
    function updateReserveTVLCap(uint256 newTotalValueLockedCap) external;

    /// @dev Borrow assets from the reserve.
    function borrowAssets(
        address strategyAccount,
        uint256 borrowAmount
    ) external;

    /// @dev Register that borrowed funds were repaid.
    function repay(uint256 initialLoan, uint256 returnedLoan) external;

    /// @dev Settle global lender interest and calculate new interest owed
    ///  by a borrower, given their previous loan amount and cached index.
    function settleInterest(
        uint256 loanBefore,
        uint256 interestIndexLast
    ) external returns (uint256 interestOwed, uint256 interestIndexNow);

    /// @dev The strategy bank that can borrow form this reserve.
    function STRATEGY_BANK() external view returns (IStrategyBank strategyBank);

    /// @dev Get the TVL cap for the `StrategyReserve`.
    function tvlCap_() external view returns (uint256 totalValueLockedCap);

    /// @dev Get the utilized assets in the `StrategyReserve`.
    function utilizedAssets_() external view returns (uint256 utilizedAssets);

    /// @dev Calculate new interest owed by a borrower, given their previous
    ///  loan amount and cached index. Does not modify state.
    function settleInterestView(
        uint256 loanBefore,
        uint256 interestIndexLast
    ) external view returns (uint256 interestOwed, uint256 interestIndexNow);

    /// @dev The amount of assets currently available to borrow.
    function availableToBorrow() external view returns (uint256 assets);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IStrategyController } from "./IStrategyController.sol";

/**
 * @title IStrategyAccountDeployer
 * @author GoldLink
 *
 * @dev Interface for deploying strategy accounts.
 */
interface IStrategyAccountDeployer {
    // ============ External Functions ============

    /// @dev Deploy a new strategy account for the `owner`.
    function deployAccount(
        address owner,
        IStrategyController strategyController
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";
import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
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
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

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
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IInterestRateModel
 * @author GoldLink
 *
 * @dev Interface for an interest rate model, responsible for maintaining the
 * cumulative interest index over time.
 */
interface IInterestRateModel {
    // ============ Structs ============

    /// @dev Parameters for an interest rate model.
    struct InterestRateModelParameters {
        // Optimal utilization as a fraction of one WAD (representing 100%).
        uint256 optimalUtilization;
        // Base (i.e. minimum) interest rate a the simple (non-compounded) APR,
        // denominated in WAD.
        uint256 baseInterestRate;
        // The slope at which the interest rate increases with utilization
        // below the optimal point. Denominated in units of:
        // rate per 100% utilization, as WAD.
        uint256 rateSlope1;
        // The slope at which the interest rate increases with utilization
        // after the optimal point. Denominated in units of:
        // rate per 100% utilization, as WAD.
        uint256 rateSlope2;
    }

    // ============ Events ============

    /// @notice Emitted when updating the interest rate model.
    /// @param optimalUtilization The optimal utilization after updating the model.
    /// @param baseInterestRate   The base interest rate after updating the model.
    /// @param rateSlope1         The rate slope one after updating the model.
    /// @param rateSlope2         The rate slope two after updating the model.
    event ModelUpdated(
        uint256 optimalUtilization,
        uint256 baseInterestRate,
        uint256 rateSlope1,
        uint256 rateSlope2
    );

    /// @notice Emitted when interest is settled, updating the cumulative
    ///  interest index and/or the associated timestamp.
    /// @param timestamp               The block timestamp of the index update.
    /// @param cumulativeInterestIndex The new cumulative interest index after updating.
    event InterestSettled(uint256 timestamp, uint256 cumulativeInterestIndex);
}