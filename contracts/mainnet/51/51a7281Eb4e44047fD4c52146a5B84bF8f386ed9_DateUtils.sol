// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.12;







interface ILoansDeployer {
    function deployLoan(
        uint256 fundingPeriodInDays,
        uint256 newPaymentIntervalInSeconds,
        uint256 loanAmountInPrincipalTokens, 
        uint256 originationFeePercent2Decimals,
        uint256 newAprWithTwoDecimals,
        uint256 initialCollateralRatioWith2Decimals,
        address lenderAddr, 
        address borrowerAddr,
        address newCollateralToken,
        address newPrincipalToken,
        address feesManagerAddr,
        bool allowSeizeCollateral
    ) external returns (address);
}







interface ILenderHookV2 {
    function notifyLoanClosed() external;
    function notifyLoanMatured() external;
    function notifyPrincipalRepayment(uint256 effectiveLoanAmount, uint256 principalRepaid) external;
}










/**
 * @title Defines the interface of a basic pricing oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
interface IBasicPriceOracle {
    function updateTokenPrice (address tokenAddr, uint256 valueInUSD) external;
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external;
    function getTokenPrice (address tokenAddr) external view returns (uint256);
}


interface IOpenTermLoanV3 {
    // State changing functions
    function fundLoan() external;
    function callLoan(uint256 callbackPeriodInHours, uint256 gracePeriodInHours) external;
    function liquidate() external;
    function setFeesOracle(address newFeesOracle) external;
    function changeOracle(IBasicPriceOracle newOracle) external;
    function setFeesCollector(address newFeesCollector) external;
    function proposeNewApr(uint256 newAprWithTwoDecimals) external;
    function acceptApr() external;
    function changeLateFees(uint256 lateInterestFeeWithTwoDecimals, uint256 latePrincipalFeeWithTwoDecimals) external;
    function seizeCollateral(uint256 amount) external;
    function returnCollateral(uint256 depositAmount) external;
    function repay(uint256 paymentAmount) external;
    function changeMaintenanceCollateralRatio(uint256 maintenanceCollateralRatioWith2Decimals) external;

    // Views
    function loanState() external view returns (uint8);
    function getEffectiveLoanAmount() external view returns (uint256);
    function getDebtBoundaries() external view returns (uint256 minPayment, uint256 maxPayment, uint256 netDebtAmount);
    function lender() external view returns (address);
    function interestsRepaid() external view returns (uint256);
    function principalRepaid() external view returns (uint256);
    function getCollateralToken() external view returns (address);
}







abstract contract BaseOwnable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}







library DateUtils {
    // The number of seconds per day
    uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;

    // The number of seconds per hour
    uint256 internal constant SECONDS_PER_HOUR = 60 * 60;

    // The number of seconds per minute
    uint256 internal constant SECONDS_PER_MINUTE = 60;

    // The offset from 01/01/1970
    int256 internal constant OFFSET19700101 = 2440588;

    function timestampToDate(uint256 ts) public pure returns (uint256 year, uint256 month, uint256 day) {
        (year, month, day) = _daysToDate(ts / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function timestampFromDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }

    /**
     * @notice Calculate year/month/day from the number of days since 1970/01/01 using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and adding the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param _days The year
     * @return year The year
     * @return month The month
     * @return day The day
     */
    function _daysToDate (uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        int256 __days = int256(_days);

        int256 x = __days + 68569 + OFFSET19700101;
        int256 n = 4 * x / 146097;
        x = x - (146097 * n + 3) / 4;
        int256 _year = 4000 * (x + 1) / 1461001;
        x = x - 1461 * _year / 4 + 31;
        int256 _month = 80 * x / 2447;
        int256 _day = x - 2447 * _month / 80;
        x = _month / 11;
        _month = _month + 2 - 12 * x;
        _year = 100 * (n - 49) + _year + x;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    /**
     * @notice Calculates the number of days from 1970/01/01 to year/month/day using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and subtracting the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param year The year
     * @param month The month
     * @param day The day
     * @return _days Returns the number of days
     */
    function _daysFromDate (uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970, "Error");
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint256(__days);
    }
}





// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)


/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)




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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)



/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}


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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}




/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 {
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






// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)





/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}




abstract contract BaseReentrancyGuard {
    uint256 internal constant _REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant _REENTRANCY_ENTERED = 2;

    uint256 internal _reentrancyStatus;

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
        require(_reentrancyStatus != _REENTRANCY_ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _REENTRANCY_ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _REENTRANCY_NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyStatus == _REENTRANCY_ENTERED;
    }
}


/**
 * @title Tokenizes a liability per EIP-20.
 * @dev The liability is upgradeable per EIP-1967. Reentrancy checks in place.
 */
abstract contract BaseUpgradeableERC20 is IERC20, Initializable, BaseReentrancyGuard {
    uint8 public decimals;
    string public symbol;
    string public name;

    // The total circulating supply of the token
    uint256 internal _totalSupply;

    // The maximum circulating supply of the token, if any. Set to zero if there is no max limit.
    uint256 internal _maxSupply;

    // The balance of each holder
    mapping(address => uint256) internal _balances;

    // The allowance of each spender, which is set by each owner
    mapping(address => mapping(address => uint256)) internal _allowances;

    /**
     * @notice This event is triggered when the maximum limit for minting tokens is updated.
     * @param prevValue The previous limit
     * @param newValue The new limit
     */
    event OnMaxSupplyChanged(uint256 prevValue, uint256 newValue);

    // --------------------------------------------------------------------------
    // Modifiers
    // --------------------------------------------------------------------------
    /**
     * @notice Indicates if this contract implementation was initialized at the proxy
     * @dev Throws if the contract was not initialized
     */
    modifier onlyIfInitialized() {
        require(_getInitializedVersion() != type(uint8).max, "Contract not initialized yet");
        _;
    }

    // --------------------------------------------------------------------------
    // ERC-20 interface implementation
    // --------------------------------------------------------------------------
    /**
     * @notice Transfers a given amount tokens to the address specified.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return Returns true in case of success.
     */
    function transfer(address to, uint256 value) external override onlyIfInitialized nonReentrant returns (bool) {
        return _executeErc20Transfer(msg.sender, to, value);
    }

    /**
     * @notice Transfer tokens from one address to another.
     * @dev Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     * @return Returns true in case of success.
     */
    function transferFrom(address from, address to, uint256 value) external override onlyIfInitialized nonReentrant returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= value, "Amount exceeds allowance");

        require (_executeErc20Transfer(from, to, value), "Failed to execute transferFrom");

        _approveSpender(from, msg.sender, currentAllowance - value);

        return true;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return Returns true in case of success.
     */
    function approve(address spender, uint256 value) external override onlyIfInitialized nonReentrant returns (bool) {
        _approveSpender(msg.sender, spender, value);
        return true;
    }

    function getInitializedVersion() external view onlyIfInitialized returns (uint8) {
        return _getInitializedVersion();
    }

    /**
     * @notice Gets the total circulating supply of tokens
     * @return The total circulating supply of tokens
     */
    function totalSupply() external view override onlyIfInitialized returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Gets the balance of the address specified.
     * @param addr The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address addr) external view override onlyIfInitialized returns (uint256) {
        return _balances[addr];
    }

    /**
     * @notice Function to check the amount of tokens that an owner allowed to a spender.
     * @param ownerAddr address The address which owns the funds.
     * @param spenderAddr address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address ownerAddr, address spenderAddr) external view override onlyIfInitialized returns (uint256) {
        return _allowances[ownerAddr][spenderAddr];
    }

    function maxSupply() external view onlyIfInitialized returns (uint256) {
        return _maxSupply;
    }

    // --------------------------------------------------------------------------
    // Implementation functions
    // --------------------------------------------------------------------------
    function _executeErc20Transfer(address from, address to, uint256 value) internal virtual returns (bool) {
        // Checks
        require(to != address(0), "non-zero address required");
        require(from != address(0), "non-zero sender required");
        require(value > 0, "Amount cannot be zero");
        require(_balances[from] >= value, "Amount exceeds sender balance");

        // State changes
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;

        // Emit the event per ERC-20
        emit Transfer(from, to, value);

        return true;
    }

    function _approveSpender(address ownerAddr, address spender, uint256 value) internal virtual {
        require(spender != address(0), "non-zero spender required");
        require(ownerAddr != address(0), "non-zero owner required");

        // State changes
        _allowances[ownerAddr][spender] = value;

        // Emit the event
        emit Approval(ownerAddr, spender, value);
    }

    function _spendAllowance (address ownerAddr, address spenderAddr, uint256 amount) internal virtual {
        uint256 currentAllowance = _allowances[ownerAddr][spenderAddr];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approveSpender(ownerAddr, spenderAddr, currentAllowance - amount);
        }
    }

    function _mintErc20(address addr, uint256 amount) internal virtual {
        require(amount > 0, "Invalid amount");
        require(_canMint(amount), "Max supply limit reached");

        _totalSupply += amount;
        _balances[addr] += amount;

        emit Transfer(address(0), addr, amount);
    }

    function _burnErc20(address addr, uint256 amount) internal virtual {
        require(amount > 0, "Invalid amount");
        require(_balances[addr] >= amount, "Burn amount exceeds balance");

        _balances[addr] -= amount;
        _totalSupply -= amount;

        emit Transfer(addr, address(0), amount);
    }

    function _setMaxSupply(uint256 newValue) internal virtual {
        require(newValue > 0 && newValue > _totalSupply, "Invalid max supply");

        uint256 prevValue = _maxSupply;
        _maxSupply = newValue;

        emit OnMaxSupplyChanged(prevValue, newValue);
    }

    // Indicates if we can issue/mint the number of tokens specified.
    function _canMint(uint256 amount) internal view virtual returns (bool) {        
        return _maxSupply - _totalSupply >= amount;
    }
}




abstract contract BasePausableLiability {
    bool public depositsPaused;
    bool public withdrawalsPaused;

    event DepositsPaused();
    event DepositsResumed();
    event WithdrawalsPaused();
    event WithdrawalsResumed();

    // --------------------------------------------------------------------------
    // Modifiers
    // --------------------------------------------------------------------------
    modifier ifDepositsNotPaused() {
        require(!depositsPaused, "Deposits paused");
        _;
    }

    modifier ifWithdrawalsNotPaused() {
        require(!withdrawalsPaused, "Withdrawals paused");
        _;
    }

    // --------------------------------------------------------------------------
    // Implementation functions
    // --------------------------------------------------------------------------
    function _pauseDeposits() internal virtual {
        depositsPaused = true;
        emit DepositsPaused();
    }

    function _resumeDeposits() internal virtual {
        require(depositsPaused, "Deposits already active");
        depositsPaused = false;
        emit DepositsResumed();
    }

    function _pauseWithdrawals() internal virtual {
        withdrawalsPaused = true;
        emit WithdrawalsPaused();
    }

    function _resumeWithdrawals() internal virtual {
        require(withdrawalsPaused, "Withdrawals already active");
        withdrawalsPaused = false;
        emit WithdrawalsResumed();
    }
}


/**
 * @title Represents a liquidity pool. The pool works per ERC-4626 standard. The pool can be paused.
 */
abstract contract BaseUpgradeableERC4626 is IERC4626, BaseUpgradeableERC20, BasePausableLiability {
    using MathUpgradeable for uint256;

    IERC20 internal _underlyingAsset;
    uint256 public maxDepositAmount;
    uint256 public maxWithdrawalAmount;

    // Space reserved for future upgrades
    uint256[30 - 13] private __gap;

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    modifier ifConfigured() {
        require(address(_underlyingAsset) != address(0), "Not configured");
        _;
    }

    modifier ifNotConfigured() {
        require(address(_underlyingAsset) == address(0), "Already configured");
        _;
    }

    // --------------------------------------------------------------------------
    // ERC-4626 interface implementation
    // --------------------------------------------------------------------------
    /**
     * @notice Deposits funds in the pool. Issues LP tokens in exchange for the deposit.
     * @dev Throws if the deposit limit is reached.
     * @param assets The deposit amount, expressed in underlying tokens. For example: USDC, DAI, etc.
     * @param receiver The address that will receive the LP tokens. It is usually the same as a the sender.
     * @return shares The number of LP tokens issued to the receiving address specified.
     */
    function deposit(
        uint256 assets, 
        address receiver
    ) external override onlyIfInitialized nonReentrant ifConfigured ifDepositsNotPaused returns (uint256 shares) {
        require(receiver != address(0) && receiver != address(this), "Invalid receiver");
        require(assets > 0, "Assets amount required");
        require(assets <= maxDeposit(receiver), "Deposit limit reached");

        shares = previewDeposit(assets);
        require(shares > 0, "Shares amount required");

        _deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Issues a specific amount of LP tokens to the receiver specified.
     * @dev Throws if the deposit limit is reached regardless of how many LP tokens you want to mint.
     * @param shares The amount of LP tokens to mint.
     * @param receiver The address of the receiver. It is usually the same as a the sender.
     * @return assets The amount of underlying assets per current ratio
     */
    function mint(
        uint256 shares, 
        address receiver
    ) external override onlyIfInitialized nonReentrant ifConfigured ifDepositsNotPaused returns (uint256 assets) {
        require(receiver != address(0) && receiver != address(this), "Invalid receiver");
        require(shares > 0, "Shares amount required");
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        assets = previewMint(shares);
        require(assets <= maxDeposit(receiver), "Deposit limit reached");

        _deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Gets the underlying asset of the pool.
     * @return Returns the address of the asset.
     */
    function asset() external view override onlyIfInitialized returns (address) {
        return address(_underlyingAsset);
    }

    function totalAssets() external view virtual override onlyIfInitialized ifConfigured returns (uint256) {
        return _getTotalAssets();
    }

    function previewDeposit(uint256 assets) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function previewMint(uint256 shares) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    function previewWithdraw(uint256 assets) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    function previewRedeem(uint256 shares) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function convertToShares(uint256 assets) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function convertToAssets(uint256 shares) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function maxDeposit(address) public view virtual override onlyIfInitialized returns (uint256) {
        return _isVaultHealthy() ? maxDepositAmount : 0;
    }

    function maxMint(address) public view virtual override onlyIfInitialized returns (uint256) {
        return _maxSupply;
    }

    function maxWithdraw(address holderAddr) public view virtual override onlyIfInitialized returns (uint256) {
        return _convertToAssets(_balances[holderAddr], MathUpgradeable.Rounding.Down);
    }

    function maxRedeem(address holderAddr) public view virtual override onlyIfInitialized returns (uint256) {
        return _balances[holderAddr];
    }

    // --------------------------------------------------------------------------
    // Implementation functions
    // --------------------------------------------------------------------------
    function _deposit(
        address callerAddr,
        address receiverAddr,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        uint256 expectedBalanceAfterTransfer = assets + _underlyingAsset.balanceOf(address(this));
        SafeERC20.safeTransferFrom(_underlyingAsset, callerAddr, address(this), assets);
        require(_underlyingAsset.balanceOf(address(this)) == expectedBalanceAfterTransfer, "Balance check failed");

        // Issue (mint) LP tokens to the receiver
        _mintErc20(receiverAddr, shares);

        // Log the ERC-4626 event
        emit Deposit(callerAddr, receiverAddr, assets, shares);
    }

    function _updateIssuanceLimits(
        uint256 newMaxDepositAmount, 
        uint256 newMaxWithdrawalAmount, 
        uint256 newMaxTokenSupply
    ) internal virtual {
        require(newMaxDepositAmount > 0, "Invalid deposit limit");
        require(newMaxWithdrawalAmount > 0, "Invalid withdrawal limit");
        
        _setMaxSupply(newMaxTokenSupply);

        maxDepositAmount = newMaxDepositAmount;
        maxWithdrawalAmount = newMaxWithdrawalAmount;
    }

    // --------------------------------------------------------------------------
    // Inner views
    // --------------------------------------------------------------------------
    function _getTotalAssets() internal view virtual returns (uint256) {
        return _underlyingAsset.balanceOf(address(this)); // _cachedBalance
    }

    function _isVaultHealthy() internal view virtual returns (bool) {
        return _totalSupply == 0 || _getTotalAssets() > 0;
    }

    // Internal conversion function (from assets to shares) to apply when the vault is empty.
    function _initialConvertToShares(uint256 assets, MathUpgradeable.Rounding) internal view virtual returns (uint256 shares) {
        return assets;
    }

    // Internal conversion function (from shares to assets) to apply when the vault is empty.
    function _initialConvertToAssets(uint256 shares, MathUpgradeable.Rounding) internal view virtual returns (uint256) {
        return shares;
    }

    // Internal conversion function (from assets to shares) with support for rounding direction.
    // Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. 
    // That corresponds to a case where any asset would represent an infinite amount of shares.
    function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256) {
        return (assets == 0 || _totalSupply == 0) ? _initialConvertToShares(assets, rounding) : assets.mulDiv(_totalSupply, _getTotalAssets(), rounding);
    }

    // Internal conversion function (from shares to assets) with support for rounding direction.
    function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256) {
        return (_totalSupply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(_getTotalAssets(), _totalSupply, rounding);
    }
}


/**
 * @title Represents a liquidity pool in which withdrawals are time-locked.
 */
abstract contract TimelockedERC4626 is BaseUpgradeableERC4626 {
    uint256 constant internal _TIMESTAMP_MANIPULATION_WINDOW = 5 minutes;

    struct RedeemSummary {
        uint256 shares;
        uint256 assets;
    }

    uint8 public liquidationHour;
    uint256 public lagDuration;

    mapping (bytes32 => RedeemSummary) internal _dailyRequirement;
    mapping (bytes32 => address[]) private _uniqueReceiversPerCluster;
    mapping (bytes32 => mapping(address => uint256)) internal _receiverAmounts;
    mapping (bytes32 => mapping(address => uint256)) internal _burnableAmounts;
    
    /**
     * @notice This event is triggered when a holder requests a withdrawal.
     * @param ownerAddr The address of the holder.
     * @param receiverAddr The address of the receiver.
     * @param shares The amount of shares (LP tokens) to burn.
     * @param assets The amount of underlying assets to transfer.
     * @param year The year component of the scheduled date.
     * @param month The month component of the scheduled date.
     * @param day The day component of the scheduled date.
     */
    event WithdrawalRequested (address ownerAddr, address receiverAddr, uint256 shares, uint256 assets, uint256 year, uint256 month, uint256 day);

    // ----------------------------------------
    // ERC-4626 endpoint overrides
    // ----------------------------------------
    function withdraw(
        uint256, 
        address, 
        address
    ) external override pure returns (uint256) {
        // Revert the call to ERC4626.withdraw(args) in order to stay compatible with the ERC-4626 standard.
        // Per ERC-4626 spec (https://eips.ethereum.org/EIPS/eip-4626):
        // - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
        // - Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed. 
        //   Those methods should be performed separately.
        revert("Withdrawal request required");

        // We could enqueue a withdrawal request from this endpoint, but it wouldn't compatible with the ERC-4626 standard.
        // Likewise, we could process the funds for the receiver sppecified but -again- it wouldn't compatible with the ERC-4626 standard.
        // Hence the tx revert. Provided we revert in all cases, the function becomes pure.
    }

    function redeem(
        uint256, 
        address, 
        address
    ) external override pure returns (uint256) {
        // Revert the call to ERC4626.redeem(args) in order to stay compatible with the ERC-4626 standard.
        // Per ERC-4626 spec (https://eips.ethereum.org/EIPS/eip-4626):
        // - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
        // - Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed. 
        //   Those methods should be performed separately.
        revert("Withdrawal request required");

        // We could enqueue a withdrawal request from this endpoint, but it wouldn't compatible with the ERC-4626 standard.
        // Likewise, we could process the funds for the receiver sppecified but -again- it wouldn't compatible with the ERC-4626 standard.
        // Hence the tx revert. Provided we revert in all cases, the function becomes pure.
    }

    // ----------------------------------------
    // Timelocked ERC-4626 features
    // ----------------------------------------
    /**
     * @notice Requests to redeem a given number of shares from the holder specified.
     * @dev The respective amount of assets will be made available in X hours from now, where "X" is the lag defined by the owner of the pool.
     * @param shares The number of shares to burn.
     * @param receiverAddr The address of the receiver.
     * @param holderAddr The address of the tokens holder.
     * @return Returns a tuple containing (assets, claimableEpoch)
     */
    function requestRedeem(
        uint256 shares, 
        address receiverAddr, 
        address holderAddr
    ) external onlyIfInitialized nonReentrant ifConfigured ifWithdrawalsNotPaused returns (uint256, uint256) {
        // The number of assets the receiver will get at the current price/ratio, per ERC-4626.
        uint256 assets = previewRedeem(shares);

        uint256 claimableEpoch = _registerRedeemRequest(shares, assets, holderAddr, receiverAddr, msg.sender);

        return (assets, claimableEpoch);
    }

    /**
     * @notice Allows any public address to process the scheduled withdrawal requests of the receiver specified.
     * @dev Throws if the receiving address is not the legitimate address you registered via "requestRedeem()"
     * @param year The year component of the claim. It can be a past date.
     * @param month The month component of the claim. It can be a past date.
     * @param day The day component of the claim. It can be a past date.
     * @param receiverIndex The index of the receiver, which can calculated off-chain.
     * @param receiverAddr The address of the legitimate receiver of the funds.
     * @return shares The effective number of shares (LP tokens) that were burnt from the liquidity pool.
     * @return assets The effective amount of underlying assets that were transfered to the receiver.
     */
    function claim(
        uint256 year, 
        uint256 month, 
        uint256 day,
        uint256 receiverIndex,
        address receiverAddr
    ) external onlyIfInitialized nonReentrant ifConfigured returns (uint256, uint256) {
        // This function is provided as a fallback.
        // If -for any reason- a third party does not process the scheduled withdrawals then the 
        // legitimate receiver can claim the respective funds on their own.
        // Thus as a legitimate receiver you can always claim your funds, even if the processing party fails to honor their promise.

        require(receiverAddr != address(0) && receiverAddr != address(this), "Invalid receiver");

        uint256 balanceBefore = IERC20(_underlyingAsset).balanceOf(address(this));
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        uint256 shares = _burnableAmounts[dailyCluster][receiverAddr];
        require(shares > 0, "No shares for receiver");

        uint256 assets = _receiverAmounts[dailyCluster][receiverAddr];
        require(assets > 0, "No assets for receiver");

        // Make sure withdrawals are processed at the expected epoch only.
        require(block.timestamp + _TIMESTAMP_MANIPULATION_WINDOW >= DateUtils.timestampFromDateTime(year, month, day, liquidationHour, 0, 0), "Too early");

        // Make sure the pool has enough balance to cover withdrawals.
        require(balanceBefore >= assets, "Insufficient balance");

        // Internal state changes (trusted)
        _receiverAmounts[dailyCluster][receiverAddr] = 0;
        _burnableAmounts[dailyCluster][receiverAddr] = 0;
        _dailyRequirement[dailyCluster].shares -= shares;
        _dailyRequirement[dailyCluster].assets -= assets;

        _deleteReceiver(dailyCluster, receiverIndex, receiverAddr);

        _burnErc20(address(this), shares);

        SafeERC20.safeTransfer(_underlyingAsset, receiverAddr, assets);

        // Balance check, provided the external asset is untrusted
        require(IERC20(_underlyingAsset).balanceOf(address(this)) == balanceBefore - assets, "Balance check failed");

        return (shares, assets);
    }

    /**
     * @notice Processes all of the withdrawal requests scheduled for the date specified.
     * @dev Throws if the date is earlier than the liquidation/processing hour.
     * @param year The year component of the claim. It can be a past date.
     * @param month The month component of the claim. It can be a past date.
     * @param day The day component of the claim. It can be a past date.
     */
    function processAllClaimsByDate(
        uint256 year, 
        uint256 month, 
        uint256 day
    ) external onlyIfInitialized nonReentrant ifConfigured {
        uint256 balanceBefore = IERC20(_underlyingAsset).balanceOf(address(this));
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));
        uint256 totalLiabilityAmount = _dailyRequirement[dailyCluster].assets;

        // Make sure we have pending requests to process.
        require(totalLiabilityAmount > 0, "Nothing to process");

        // Make sure withdrawals are processed at the expected epoch only.
        require(block.timestamp + _TIMESTAMP_MANIPULATION_WINDOW >= DateUtils.timestampFromDateTime(year, month, day, liquidationHour, 0, 0), "Too early");

        // Make sure the pool has enough balance to cover withdrawals.
        require(balanceBefore >= totalLiabilityAmount, "Insufficient balance");

        // This is the number of unique ERC20 transfers we will need to make in this transaction
        uint256 totalReceiversByDate = _uniqueReceiversPerCluster[dailyCluster].length;

        // Internal state changes (trusted)
        address[] memory receivers = new address[](totalReceiversByDate);
        uint256[] memory amounts = new uint256[](totalReceiversByDate);

        for (uint256 i; i < totalReceiversByDate; i++) {
            address receiverAddr = _uniqueReceiversPerCluster[dailyCluster][i];
            receivers[i] = receiverAddr;
            amounts[i] = _receiverAmounts[dailyCluster][receiverAddr];

            _receiverAmounts[dailyCluster][receiverAddr] = 0;
            _burnableAmounts[dailyCluster][receiverAddr] = 0;
        }

        _burnErc20(address(this), _dailyRequirement[dailyCluster].shares);

        delete _dailyRequirement[dailyCluster];
        delete _uniqueReceiversPerCluster[dailyCluster];

        // Untrusted external calls
        for (uint256 i; i < totalReceiversByDate; i++) {
            SafeERC20.safeTransfer(_underlyingAsset, receivers[i], amounts[i]);
        }

        // Balance check, provided the external asset is untrusted
        require(IERC20(_underlyingAsset).balanceOf(address(this)) == balanceBefore - totalLiabilityAmount, "Balance check failed");
    }

    // ----------------------------------------
    // Views
    // ----------------------------------------
    function getWithdrawalEpoch() external view onlyIfInitialized ifConfigured returns (
        uint256 year, 
        uint256 month, 
        uint256 day,
        uint256 claimableEpoch
    ) {
        (year, month, day) = DateUtils.timestampToDate(block.timestamp + _TIMESTAMP_MANIPULATION_WINDOW + lagDuration);
        claimableEpoch = DateUtils.timestampFromDateTime(year, month, day, liquidationHour, 0, 0);
    }

    /**
     * @notice Gets the funding requirement of the date specified.
     * @param year The year.
     * @param month The month.
     * @param day The day.
     * @return shares The number of shares (LP tokens) that will be burned on the date specified.
     * @return assets The amount of assets that will be transferred on the date specified.
     */
    function getRequirementByDate(
        uint256 year, 
        uint256 month, 
        uint256 day
    ) external view onlyIfInitialized returns (uint256 shares, uint256 assets) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));        
        shares = _dailyRequirement[dailyCluster].shares;
        assets = _dailyRequirement[dailyCluster].assets;
    }

    function getClaimableAmountByReceiver(
        uint256 year, 
        uint256 month, 
        uint256 day,
        address receiverAddr
    ) external view onlyIfInitialized returns (uint256) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));
        return _receiverAmounts[dailyCluster][receiverAddr];
    }

    function getBurnableAmountByReceiver(
        uint256 year, 
        uint256 month, 
        uint256 day,
        address receiverAddr
    ) external view onlyIfInitialized returns (uint256) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        return _burnableAmounts[dailyCluster][receiverAddr];
    }

    function getScheduledTransactionsByDate(
        uint256 year, 
        uint256 month, 
        uint256 day
    ) external view onlyIfInitialized returns (uint256 totalTransactions, uint256 executionEpoch) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        totalTransactions = _uniqueReceiversPerCluster[dailyCluster].length;
        executionEpoch = DateUtils.timestampFromDateTime(year, month, day, liquidationHour, 0, 0);
    }

    /*
    function fromTimestampFromDate(uint256 ts) external pure returns (
        uint256 year, 
        uint256 month, 
        uint256 day
    ) {
        (year, month, day) = DateUtils.timestampToDate(ts);
    }
    */

    function getReceiverIndex(
        uint256 year, 
        uint256 month, 
        uint256 day,
        address receiverAddr
    ) public view returns (uint256) {
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        for (uint256 i; i < _uniqueReceiversPerCluster[dailyCluster].length; i++) {
            if (_uniqueReceiversPerCluster[dailyCluster][i] == receiverAddr) return i;
        }

        return type(uint256).max;
    }

    // ----------------------------------------
    // Inner functions
    // ----------------------------------------
    function _registerRedeemRequest(
        uint256 shares, 
        uint256 assets,
        address holderAddr, 
        address receiverAddr,
        address callerAddr
    ) internal returns (uint256) {
        require(receiverAddr != address(0) && receiverAddr != address(this), "Invalid receiver");
        require(holderAddr != address(0) && holderAddr != address(this), "Invalid holder");
        require(shares > 0, "Shares amount required");
        require(assets > 0, "Assets amount required");
        require(_balances[holderAddr] >= shares, "Insufficient shares");
        require(assets <= maxWithdraw(holderAddr), "Withdrawal limit reached");

        // The time slot (cluster) of the lagged withdrawal
        (uint256 year, uint256 month, uint256 day) = DateUtils.timestampToDate(block.timestamp + _TIMESTAMP_MANIPULATION_WINDOW + lagDuration);

        // The hash of the cluster
        bytes32 dailyCluster = keccak256(abi.encode(year, month, day));

        // The withdrawal will be processed at the following epoch
        uint256 claimableEpoch = DateUtils.timestampFromDateTime(year, month, day, liquidationHour, 0, 0);

        // ERC20 allowance scenario
        if (callerAddr != holderAddr) _spendAllowance(holderAddr, callerAddr, shares);

        // Transfer the shares from the token holder to this contract.
        // We transfer the shares to the liquidity pool in order to avoid fluctuations on the token price.
        // Otherwise, burning shares at this point in time would affect the number of assets (liability) 
        // of future withdrawal requests because the token price would increase.
        _executeErc20Transfer(holderAddr, address(this), shares);

        // Global metrics
        _dailyRequirement[dailyCluster].assets += assets;
        _dailyRequirement[dailyCluster].shares += shares;

        // Unique receivers by date. We will transfer underlying tokens to this receiver shortly.
        if (_receiverAmounts[dailyCluster][receiverAddr] == 0) {
            _uniqueReceiversPerCluster[dailyCluster].push(receiverAddr);
        }

        // Track the amount of underlying assets we are required to transfer to the receiver address specified.
        _receiverAmounts[dailyCluster][receiverAddr] += assets;

        _burnableAmounts[dailyCluster][receiverAddr] += shares;

        emit WithdrawalRequested(holderAddr, receiverAddr, shares, assets, year, month, day);

        return claimableEpoch;
    }

    function _deleteReceiver(bytes32 dailyCluster, uint256 idx, address addr) private {
        require(idx < _uniqueReceiversPerCluster[dailyCluster].length, "Invalid receiver index");
        require(_uniqueReceiversPerCluster[dailyCluster][idx] == addr, "Address/index mismatch");

        uint256 totalReceiversByDate = _uniqueReceiversPerCluster[dailyCluster].length;
        address lastItem = _uniqueReceiversPerCluster[dailyCluster][totalReceiversByDate - 1];

        if (addr != lastItem) {
            _uniqueReceiversPerCluster[dailyCluster][totalReceiversByDate - 1] = _uniqueReceiversPerCluster[dailyCluster][idx];
            _uniqueReceiversPerCluster[dailyCluster][idx] = lastItem;
        }
        
        _uniqueReceiversPerCluster[dailyCluster].pop();
    }
}


/**
 * @title Represents an ownable liquidity pool. The pool is compliant with the ERC-4626 standard.
 */
abstract contract OwnableLiquidityPool is TimelockedERC4626, BaseOwnable {
    /**
     * @notice This event is triggered when the owner runs an emergency withdrawal.
     * @param withdrawalAmount The withdrawal amount.
     * @param tokenAddr The token address.
     * @param destinationAddr The destination address.
     */
    event OnEmergencyWithdraw (uint256 withdrawalAmount, address tokenAddr, address destinationAddr);

    /**
     * @notice Allows the owner of the pool to withdraw the full balance of the token specified.
     * @dev Throws if the caller is not the current owner of the pool. If the asset to withdraw is the underlying asset of the pool then this function pauses deposits and withdrawals automatically.
     * @param token The token to transfer.
     * @param destinationAddr The destination address of the ERC20 transfer.
     */
    function emergencyWithdraw(
        IERC20 token,
        address destinationAddr
    ) external virtual onlyIfInitialized nonReentrant ifConfigured onlyOwner {
        require(destinationAddr != address(0) && destinationAddr != address(this), "Invalid address");

        uint256 currentBalance = token.balanceOf(address(this));
        require(currentBalance > 0, "Insufficient balance");

        if (address(token) == address(_underlyingAsset)) {
            // Automatically pause deposits and withdrawals in order to prevent fluctuations on the price of the LP token
            _pauseDeposits();
            _pauseWithdrawals();
        }

        SafeERC20.safeTransfer(token, destinationAddr, currentBalance);

        emit OnEmergencyWithdraw(currentBalance, address(token), destinationAddr);
    }

    /**
     * @notice Gets the owner of the pool.
     * @return address The address who owns the pool.
     */
    function owner() external view onlyIfInitialized returns (address) {
        return _owner;
    }
}


/**
 * @title Represents an ERC-4626 compliant liquidity pool capable of lending funds on their own.
 * @dev This liquidity pool is ownable by definition.
 */
abstract contract AbstractLender is OwnableLiquidityPool {
    // ---------------------------------------------------------------
    // States of a loan
    // ---------------------------------------------------------------
    uint8 constant internal PREAPPROVED = 1;        // The loan was pre-approved by the lender
    uint8 constant internal FUNDING_REQUIRED = 2;   // The loan was accepted by the borrower. Waiting for the lender to fund the loan.
    uint8 constant internal FUNDED = 3;             // The loan was funded.
    uint8 constant internal ACTIVE = 4;             // The loan is active.
    uint8 constant internal CANCELLED = 5;          // The lender failed to fund the loan and the borrower claimed their collateral.
    uint8 constant internal MATURED = 6;            // The loan matured. It was liquidated by the lender.
    uint8 constant internal CLOSED = 7;             // The loan was closed normally.

    address internal _loansOperator;

    // Space reserved for future upgrades
    uint256[10] private __gap;

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    modifier onlyLoansOperator() {
        require(msg.sender == _loansOperator, "Loans Operator only");
        _;
    }

    // ---------------------------------------------------------------
    // Implementation functions
    // ---------------------------------------------------------------
    /**
     * @notice Changes the oracle that calculates the token prices of the loan specified.
     * @param loanAddr The address of the loan.
     * @param newOracle The new oracle for token prices
     */
    function changeOracle(
        address loanAddr, 
        IBasicPriceOracle newOracle
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).changeOracle(newOracle);
    }

    /**
     * @notice As a lender, this pool proposes a new APR to the borrower of the loan address specified.
     * @param loanAddr The address of the loan.
     * @param newAprWithTwoDecimals The APR proposed by this pool, expressed with 2 decimal places.
     */
    function proposeNewApr(
        address loanAddr, 
        uint256 newAprWithTwoDecimals
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).proposeNewApr(newAprWithTwoDecimals);
    }

    /**
     * @notice Updates the late fees of the loan specified.
     * @param loanAddr The address of the loan.
     * @param lateInterestFeeWithTwoDecimals The late interest fee (percentage) with 2 decimal places.
     * @param latePrincipalFeeWithTwoDecimals The late principal fee (percentage) with 2 decimal places.
     */
    function changeLateFees(
        address loanAddr, 
        uint256 lateInterestFeeWithTwoDecimals, 
        uint256 latePrincipalFeeWithTwoDecimals
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).changeLateFees(lateInterestFeeWithTwoDecimals, latePrincipalFeeWithTwoDecimals);
    }

    /**
     * @notice Updates the maintenance collateral ratio
     * @param loanAddr The address of the loan.
     * @param maintenanceCollateralRatioWith2Decimals The maintenance collateral ratio, if applicable.
     */
    function changeMaintenanceCollateralRatio(
        address loanAddr, 
        uint256 maintenanceCollateralRatioWith2Decimals
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).changeMaintenanceCollateralRatio(maintenanceCollateralRatioWith2Decimals);
    }

    /**
     * @notice Allows the pool to capture a specific amount of collateral.
     * @param loanAddr The address of the loan.
     * @param amount The amount of collateral to seize.
     */
    function seizeCollateral(
        address loanAddr, 
        uint256 amount
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).seizeCollateral(amount);
    }

    /**
     * @notice Allows the pool to redeposit the collateral seized before.
     * @param loanAddr The address of the loan.
     * @param depositAmount The amount of collateral to return to the borrower.
     */
    function returnCollateral(
        address loanAddr, 
        uint256 depositAmount
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);

        address collateralTokenAddr = IOpenTermLoanV3(loanAddr).getCollateralToken();
        SafeERC20.safeApprove(IERC20(collateralTokenAddr), loanAddr, depositAmount);

        IOpenTermLoanV3(loanAddr).returnCollateral(depositAmount);

        SafeERC20.safeApprove(IERC20(collateralTokenAddr), loanAddr, 0);
    }

    /**
     * @notice Calls the loan specified.
     * @param loanAddr The address of the loan.
     * @param callbackPeriodInHours The callback period, measured in hours.
     * @param gracePeriodInHours The grace period, measured in hours.
     */
    function callLoan(
        address loanAddr, 
        uint256 callbackPeriodInHours, 
        uint256 gracePeriodInHours
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).callLoan(callbackPeriodInHours, gracePeriodInHours);
    }

    /**
     * @notice Liquidates the loan specified.
     * @param loanAddr The address of the loan.
     */
    function liquidate(address loanAddr) external onlyIfInitialized ifConfigured onlyLoansOperator {
        _ensureValidLoan(loanAddr);
        IOpenTermLoanV3(loanAddr).liquidate();
    }

    /**
     * @notice The account authorized to manage loans.
     * @return address The address of the loans operator.
     */
    function getLoansOperator() external view onlyIfInitialized returns (address) {
        return _loansOperator;
    }

    // ---------------------------------------------------------------
    // Virtuals
    // ---------------------------------------------------------------
    function fundLoan(address loanAddr) external virtual;
    function _ensureValidLoan(address loanAddr) internal view virtual;
}


/**
 * @title Represents an ERC-4626 lender pool capable of processing hooks on-chain.
 * @dev This contract overrides ERC4626.totalAssets() in order to reflect the exposure to loans.
 */
abstract contract HookableLender is ILenderHookV2, AbstractLender {
    struct LoanDeploymentRecord {
        uint256 effectiveLoanAmount;
        uint256 activeDelta;
        bool isWhitelisted;
    }

    // ---------------------------------------------------------------
    // Storage layout
    // ---------------------------------------------------------------
    uint256 public globalLoansAmount;

    mapping (address => LoanDeploymentRecord) internal _deployedLoans;

    // Space reserved for future upgrades
    uint256[3] private __gap;

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    modifier onlyKnownLoanContract() {
        require(_deployedLoans[msg.sender].isWhitelisted, "Unknown loan");
        _;
    }

    // ---------------------------------------------------------------
    // Hooks implementation
    // ---------------------------------------------------------------
    function notifyLoanMatured() external override onlyIfInitialized nonReentrant ifConfigured onlyKnownLoanContract {
        if (_deployedLoans[msg.sender].activeDelta > 0) globalLoansAmount -= _deployedLoans[msg.sender].activeDelta;
        _deployedLoans[msg.sender].activeDelta = 0;
    }

    function notifyLoanClosed() external override onlyIfInitialized nonReentrant ifConfigured onlyKnownLoanContract {
        if (_deployedLoans[msg.sender].activeDelta > 0) globalLoansAmount -= _deployedLoans[msg.sender].activeDelta;
        _deployedLoans[msg.sender].activeDelta = 0;
    }

    function notifyPrincipalRepayment(
        uint256 effectiveLoanAmount, 
        uint256 principalRepaid
    ) external override onlyIfInitialized nonReentrant ifConfigured onlyKnownLoanContract {
        uint256 newDelta = (principalRepaid < effectiveLoanAmount) ? effectiveLoanAmount - principalRepaid : 0;

        if (_deployedLoans[msg.sender].activeDelta > 0) globalLoansAmount -= _deployedLoans[msg.sender].activeDelta;
        _deployedLoans[msg.sender].activeDelta = newDelta;
        if (newDelta > 0) globalLoansAmount += newDelta;
    }

    function _ensureValidLoan(address loanAddr) internal view override {
        require(_deployedLoans[loanAddr].isWhitelisted, "Invalid loan contract");
    }

    // ---------------------------------------------------------------
    // ERC-4626 overrides
    // ---------------------------------------------------------------
    function _getTotalAssets() internal view virtual override returns (uint256) {
        // [Liquidity] + [the delta of all ACTIVE loans managed by this pool]
        return globalLoansAmount + _underlyingAsset.balanceOf(address(this));
    }
}


/**
 * @title Represents a base lending pool.
 * @dev The pool is capable of deploying and funding loans on their own. It is also capable of receiving hooks on-chain.
 */
abstract contract BaseLendingPool is HookableLender {
    address public loansDeployerAddress;

    // Space reserved for future upgrades
    uint256[10] private __gap;

    /**
     * @notice Deploys a new loan on behalf of this pool.
     * @dev The pool acts as a lender. Throws if the caller is not an authorized sender, or if the pool was not configured.
     * @param fundingPeriodInDays The funding period of the loan, expressed in days.
     * @param newPaymentIntervalInSeconds The funding period of the loan, expressed in days.
     * @param loanAmountInPrincipalTokens The loan amount, expressed in principal currency (say USDC).
     * @param originationFeePercent2Decimals The origination fee of the loan. It is a percentage with 2 decimal places (1% = 100).
     * @param newAprWithTwoDecimals The APR of the loan. It is a percentage with 2 decimal places.
     * @param initialCollateralRatioWith2Decimals The initial collateral ratio of the loan. Zero if the loan is not secured. Greater than zero otherwise.
     * @param borrowerAddr The address of the borrower.
     * @param newCollateralToken The collateral token applicable to the loan, if any. Unsecured loans have no collateral (zero address)
     * @param newPrincipalToken The principal token of the loan.
     * @param feesManagerAddr The address authorized to define the fees collector and fees structure.
     * @param allowSeizeCollateral Indicates if the lender is allowed to seize the collateral deposited by the borrower.
     * @return Returns the address the loan deployed by the pool.
     */
    function deployNewLoan(
        uint256 fundingPeriodInDays,
        uint256 newPaymentIntervalInSeconds,
        uint256 loanAmountInPrincipalTokens, 
        uint256 originationFeePercent2Decimals,
        uint256 newAprWithTwoDecimals,
        uint256 initialCollateralRatioWith2Decimals,
        address borrowerAddr,
        address newCollateralToken,
        address newPrincipalToken,
        address feesManagerAddr,
        bool allowSeizeCollateral
    ) external onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator returns (address) {
        address loanAddr = ILoansDeployer(loansDeployerAddress).deployLoan(
            fundingPeriodInDays, 
            newPaymentIntervalInSeconds, 
            loanAmountInPrincipalTokens, 
            originationFeePercent2Decimals, 
            newAprWithTwoDecimals, 
            initialCollateralRatioWith2Decimals, 
            address(this), 
            borrowerAddr, 
            newCollateralToken, 
            newPrincipalToken, 
            feesManagerAddr, 
            allowSeizeCollateral
        );

        uint256 effectiveLoanAmount = IOpenTermLoanV3(loanAddr).getEffectiveLoanAmount();

        // This should never happen.
        require(!_deployedLoans[loanAddr].isWhitelisted, "Invalid deployment address");

        _deployedLoans[loanAddr] = LoanDeploymentRecord({
            effectiveLoanAmount: effectiveLoanAmount,
            activeDelta: 0,
            isWhitelisted: true
        });

        return loanAddr;
    }

    /**
     * @notice Funds the loan deployed at the address specified.
     * @dev Throws if the loan was not deployed by this pool.
     * @param loanAddr The address of the loan.
     */
    function fundLoan(address loanAddr) external override onlyIfInitialized nonReentrant ifConfigured onlyLoansOperator {
        // Trusted queries
        _ensureValidLoan(loanAddr);
        uint256 effectiveLoanAmount = _deployedLoans[loanAddr].effectiveLoanAmount;

        // Trusted changes
        _deployedLoans[loanAddr].activeDelta = effectiveLoanAmount; // The principal repaid at this point in time is zero
        globalLoansAmount += effectiveLoanAmount; // which is "_deployedLoans[loanAddr].activeDelta"

        // Untrusted changes
        SafeERC20.safeApprove(_underlyingAsset, loanAddr, effectiveLoanAmount);
        IOpenTermLoanV3(loanAddr).fundLoan();
        SafeERC20.safeApprove(_underlyingAsset, loanAddr, uint256(0));

        // Late checks
        require(IOpenTermLoanV3(loanAddr).loanState() == ACTIVE, "Funding check failed");
        require(_underlyingAsset.allowance(address(this), loanAddr) == uint256(0), "Allowance check failed");
    }

    function setLoansDeployerAddress(address newLoansDeployerAddress) external onlyIfInitialized nonReentrant onlyOwner {
        loansDeployerAddress = newLoansDeployerAddress;
    }

    function setLoansOperator(address newLoansOperator) external onlyIfInitialized nonReentrant onlyOwner {
        require(newLoansOperator != _owner, "Owner cannot be operator");
        _loansOperator = newLoansOperator;
    }

    // --------------------------------------------------------------------------
    // Ownership override
    // --------------------------------------------------------------------------
    function _transferOwnership(address newOwner) internal virtual override {
        require(newOwner != address(0) && newOwner != address(this), "Invalid owner");
        require(newOwner != _owner, "Owner already set");
        require(newOwner != _loansOperator, "Owner cannot be operator");
        require(newOwner != loansDeployerAddress, "Owner cannot be deployer");

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @title Represents a lending pool in which all withdrawals are time-locked. The lending pool is fully compliant with the ERC-4626 standard.
 */
contract LendingPool is BaseLendingPool {
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Proxy initialization function.
     * @param newOwner The owner of the lending pool.
     * @param erc20Decimals The number of decimals of the LP token issued by this pool, per ERC20.
     * @param erc20Symbol The token symbol of this pool, per ERC20.
     * @param erc20Name The token name of this pool, per ERC20.
     */
    function initialize(
        address newOwner,
        uint8 erc20Decimals,
        string memory erc20Symbol,
        string memory erc20Name
    ) external initializer {
        _reentrancyStatus = _REENTRANCY_NOT_ENTERED;

        // ERC-20 settings
        decimals = erc20Decimals;
        symbol = erc20Symbol;
        name = erc20Name;

        // Pause deposits and withdrawals until the pool gets configured by the authorized party.
        depositsPaused = true;
        withdrawalsPaused = true;

        _owner = newOwner;
    }

    /**
     * @notice Configures the lending pool.
     * @dev Throws if the caller is not the owner. Deposits and withdrawals are paused until the pool is configured.
     * @param newMaxDepositAmount The maximum deposit amount of assets (say USDC) investors are allowed to deposit in the pool.
     * @param newMaxWithdrawalAmount The maximum withdrawal amount of the pool, expressed in underlying assets (for example: USDC)
     * @param newMaxTokenSupply The maximum supply of LP tokens (liquidity pool tokens)
     * @param newUnderlyingAsset The underlying asset of the liquidity pool (for example: USDC).
     * @param newLoansOperator The address responsible for managing the loans of the pool.
     * @param newLoansDeployerAddress The address of the smart contract you will use for deploying loans on behalf of this pool.
     * @param newProcessingHour The hour (UTC) at which all withdrawal requests will be processed. The value ranges from [0..23]
     */
    function configurePool(
        uint256 newMaxDepositAmount, 
        uint256 newMaxWithdrawalAmount, 
        uint256 newMaxTokenSupply,
        address newUnderlyingAsset,
        address newLoansOperator,
        address newLoansDeployerAddress,
        uint8 newProcessingHour
    ) external onlyIfInitialized nonReentrant ifNotConfigured onlyOwner {
        require(newProcessingHour < 24, "Invalid processing hour"); // Min: 0, Max: 23  (eg: 13 = 1PM)

        _underlyingAsset = IERC20(newUnderlyingAsset);
        _updateIssuanceLimits(newMaxDepositAmount, newMaxWithdrawalAmount, newMaxTokenSupply);

        // Loan management actors
        _loansOperator = newLoansOperator;
        loansDeployerAddress = newLoansDeployerAddress;

        // Timelock settings
        lagDuration = 24 hours;
        liquidationHour = newProcessingHour;

        // Resume deposits and withdrawals
        depositsPaused = false;
        withdrawalsPaused = false;
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     * @dev Throws if the caller is not the current owner. Additional constraints apply.
     * @param newOwner The new owner of this contract.
     */
    function transferOwnership(address newOwner) external onlyIfInitialized nonReentrant onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @notice Updates the processing hour of all withdrawal requests.
     * @dev Throws if the caller is not the owner of the pool. Throws if the pool was not configured.
     * @param newProcessingHour The new hour, which ranges between 0 and 23 (where 23 = 11PM)
     */
    function updateProcessingHour(uint8 newProcessingHour) external onlyIfInitialized nonReentrant ifConfigured onlyOwner {
        require(newProcessingHour < 24, "Invalid processing hour"); // Min: 0, Max: 23  (eg: 13 = 1PM, 14 = 2PM, 11 = 11AM)
        liquidationHour = newProcessingHour;
    }

    /**
     * @notice Updates the issuance and redemption settings of the pool.
     * @dev Throws if the caller is not the owner of the pool. Throws if the pool was not configured.
     * @param newMaxDepositAmount The maximum deposit amount of assets (say USDC) investors are allowed to deposit in the pool.
     * @param newMaxWithdrawalAmount The maximum withdrawal amount of the pool, expressed in underlying assets (for example: USDC)
     * @param newMaxTokenSupply The maximum supply of LP tokens (liquidity pool tokens)
     */
    function updateIssuanceLimits(
        uint256 newMaxDepositAmount, 
        uint256 newMaxWithdrawalAmount, 
        uint256 newMaxTokenSupply
    ) external onlyIfInitialized nonReentrant ifConfigured onlyOwner {
        _updateIssuanceLimits(newMaxDepositAmount, newMaxWithdrawalAmount, newMaxTokenSupply);
    }

    function toggleDepositsAndWithdrawals(bool bDepositsEnabled, bool bWithdrawalsEnabled) external onlyIfInitialized nonReentrant onlyOwner {
        if (bDepositsEnabled) _pauseDeposits();
        else _resumeDeposits();

        if (bWithdrawalsEnabled) _pauseWithdrawals();
        else _resumeWithdrawals();
    }

}