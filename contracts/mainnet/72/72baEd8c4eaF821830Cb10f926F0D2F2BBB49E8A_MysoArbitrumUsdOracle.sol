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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

library Constants {
    uint256 internal constant YEAR_IN_SECONDS = 365 days;
    uint256 internal constant BASE = 1e18;
    uint256 internal constant MAX_FEE_PER_ANNUM = 0.05e18; // 5% max in base
    uint256 internal constant MAX_SWAP_PROTOCOL_FEE = 0.01e18; // 1% max in base
    uint256 internal constant MAX_TOTAL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MAX_P2POOL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MIN_TIME_BETWEEN_EARLIEST_REPAY_AND_EXPIRY =
        1 days;
    uint256 internal constant MAX_PRICE_UPDATE_TIMESTAMP_DIVERGENCE = 1 days;
    uint256 internal constant SEQUENCER_GRACE_PERIOD = 1 hours;
    uint256 internal constant MIN_UNSUBSCRIBE_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_UNSUBSCRIBE_GRACE_PERIOD = 14 days;
    uint256 internal constant MIN_CONVERSION_GRACE_PERIOD = 1 days;
    uint256 internal constant MIN_REPAYMENT_GRACE_PERIOD = 1 days;
    uint256 internal constant LOAN_EXECUTION_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_CONVERSION_AND_REPAYMENT_GRACE_PERIOD =
        30 days;
    uint256 internal constant MIN_TIME_UNTIL_FIRST_DUE_DATE = 1 days;
    uint256 internal constant MIN_TIME_BETWEEN_DUE_DATES = 7 days;
    uint256 internal constant MIN_WAIT_UNTIL_EARLIEST_UNSUBSCRIBE = 60 seconds;
    uint256 internal constant MAX_ARRANGER_FEE = 0.5e18; // 50% max in base
    uint256 internal constant LOAN_TERMS_UPDATE_COOL_OFF_PERIOD = 15 minutes;
    uint256 internal constant MAX_REPAYMENT_SCHEDULE_LENGTH = 20;
    uint256 internal constant SINGLE_WRAPPER_MIN_MINT = 1000; // in wei
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Errors {
    error UnregisteredVault();
    error InvalidDelegatee();
    error InvalidSender();
    error InvalidFee();
    error InsufficientSendAmount();
    error NoOracle();
    error InvalidOracleAnswer();
    error InvalidOracleDecimals();
    error InvalidOracleVersion();
    error InvalidAddress();
    error InvalidArrayLength();
    error InvalidQuote();
    error OutdatedQuote();
    error InvalidOffChainSignature();
    error InvalidOffChainMerkleProof();
    error InvalidCollUnlock();
    error InvalidAmount();
    error UnknownOnChainQuote();
    error NeitherTokenIsGOHM();
    error NoLpTokens();
    error ZeroReserve();
    error IncorrectGaugeForLpToken();
    error InvalidGaugeIndex();
    error AlreadyStaked();
    error InvalidWithdrawAmount();
    error InvalidBorrower();
    error OutsideValidRepayWindow();
    error InvalidRepayAmount();
    error ReclaimAmountIsZero();
    error UnregisteredGateway();
    error NonWhitelistedOracle();
    error NonWhitelistedCompartment();
    error NonWhitelistedCallback();
    error NonWhitelistedToken();
    error LtvHigherThanMax();
    error InsufficientVaultFunds();
    error InvalidInterestRateFactor();
    error InconsistentUnlockTokenAddresses();
    error InvalidEarliestRepay();
    error InvalidNewMinNumOfSigners();
    error AlreadySigner();
    error InvalidArrayIndex();
    error InvalidSignerRemoveInfo();
    error InvalidSendAmount();
    error TooSmallLoanAmount();
    error DeadlinePassed();
    error WithdrawEntered();
    error DuplicateAddresses();
    error OnChainQuoteAlreadyAdded();
    error OffChainQuoteHasBeenInvalidated();
    error Uninitialized();
    error InvalidRepaymentScheduleLength();
    error FirstDueDateTooCloseOrPassed();
    error InvalidGracePeriod();
    error UnregisteredLoanProposal();
    error NotInSubscriptionPhase();
    error NotInUnsubscriptionPhase();
    error InsufficientBalance();
    error InsufficientFreeSubscriptionSpace();
    error BeforeEarliestUnsubscribe();
    error InconsistentLastLoanTermsUpdateTime();
    error InvalidActionForCurrentStatus();
    error FellShortOfTotalSubscriptionTarget();
    error InvalidRollBackRequest();
    error UnsubscriptionAmountTooLarge();
    error InvalidSubscriptionRange();
    error InvalidMaxTotalSubscriptions();
    error OutsideConversionTimeWindow();
    error OutsideRepaymentTimeWindow();
    error NoDefault();
    error LoanIsFullyRepaid();
    error RepaymentIdxTooLarge();
    error AlreadyClaimed();
    error AlreadyConverted();
    error InvalidDueDates();
    error LoanTokenDueIsZero();
    error WaitForLoanTermsCoolOffPeriod();
    error ZeroConversionAmount();
    error InvalidNewOwnerProposal();
    error CollateralMustBeCompartmentalized();
    error InvalidCompartmentForToken();
    error InvalidSignature();
    error InvalidUpdate();
    error CannotClaimOutdatedStatus();
    error DelegateReducedBalance();
    error FundingPoolAlreadyExists();
    error InvalidLender();
    error NonIncreasingTokenAddrs();
    error NonIncreasingNonFungibleTokenIds();
    error TransferToWrappedTokenFailed();
    error TransferFromWrappedTokenFailed();
    error StateAlreadySet();
    error ReclaimableCollateralAmountZero();
    error InvalidSwap();
    error InvalidUpfrontFee();
    error InvalidOracleTolerance();
    error ReserveRatiosSkewedFromOraclePrice();
    error SequencerDown();
    error GracePeriodNotOver();
    error LoanExpired();
    error NoDsEth();
    error TooShortTwapInterval();
    error TooLongTwapInterval();
    error TwapExceedsThreshold();
    error Reentrancy();
    error TokenNotStuck();
    error InconsistentExpTransferFee();
    error InconsistentExpVaultBalIncrease();
    error DepositLockActive();
    error DisallowedSubscriptionLockup();
    error IncorrectLoanAmount();
    error Disabled();
    error CannotRemintUnlessZeroSupply();
    error TokensStillMissingFromWrapper();
    error OnlyMintFromSingleTokenWrapper();
    error NonMintableTokenState();
    error NoTokensTransferred();
    error TokenAlreadyCountedInWrapper();
    error TokenNotOwnedByWrapper();
    error TokenDoesNotBelongInWrapper(address tokenAddr, uint256 tokenId);
    error InvalidMintAmount();
    error QuoteViolatesPolicy();
    error AlreadyPublished();
    error PolicyAlreadySet();
    error NoPolicyToDelete();
    error InvalidTenorBounds();
    error InvalidLtvBounds();
    error InvalidLoanPerCollBounds();
    error InvalidMinApr();
    error NoPolicy();
    error InvalidMinFee();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IOracle {
    /**
     * @notice function checks oracle validity and calculates collTokenPriceInLoanToken
     * @param collToken address of coll token
     * @param loanToken address of loan token
     * @return collTokenPriceInLoanToken collateral price denominated in loan token
     */
    function getPrice(
        address collToken,
        address loanToken
    ) external view returns (uint256 collTokenPriceInLoanToken);

    /**
     * @notice function checks oracle validity and retrieves prices in base currency unit
     * @param collToken address of coll token
     * @param loanToken address of loan token
     * @return collTokenPriceRaw and loanTokenPriceRaw denominated in base currency unit
     */
    function getRawPrices(
        address collToken,
        address loanToken
    )
        external
        view
        returns (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGLPManager {
    /**
     * @notice gets price of GLP in USD with 30 decimals
     * @param _maximize will pass true
     * @return price of GLP in USD
     */
    function getPrice(bool _maximize) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGTOKEN {
    /**
     * @notice gets amount of underlying token for a given amount of gToken
     * @return amount of underlying token
     */
    function shareToAssetsPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMysoTokenManager {
    /**
     * @notice gets Myso token loan amount from MysoTokenManager
     * @return total Myso loan amount up until now
     */
    function totalMysoLoanAmount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AggregatorV3Interface} from "../../interfaces/oracles/chainlink/AggregatorV3Interface.sol";
import {ChainlinkBase} from "./ChainlinkBase.sol";
import {Constants} from "../../../Constants.sol";
import {Errors} from "../../../Errors.sol";

/**
 * @dev supports oracles which are compatible with v2v3 or v3 interfaces
 */
contract ChainlinkArbitrumSequencerUSD is ChainlinkBase {
    address internal constant SEQUENCER_FEED =
        0xFdB631F5EE196F0ed6FAa767959853A9F217697D; // arbitrum sequencer feed
    uint256 internal constant ARB_USD_BASE_CURRENCY_UNIT = 1e8; // 8 decimals for USD based oracles

    constructor(
        address[] memory _tokenAddrs,
        address[] memory _oracleAddrs
    ) ChainlinkBase(_tokenAddrs, _oracleAddrs, ARB_USD_BASE_CURRENCY_UNIT) {} // solhint-disable no-empty-blocks

    function _checkAndReturnLatestRoundData(
        address oracleAddr
    ) internal view override returns (uint256 tokenPriceRaw) {
        (, int256 answer, uint256 startedAt, , ) = AggregatorV3Interface(
            SEQUENCER_FEED
        ).latestRoundData();
        // check if sequencer is live
        if (answer != 0) {
            revert Errors.SequencerDown();
        }
        // check if last restart was less than or equal grace period length
        if (startedAt + Constants.SEQUENCER_GRACE_PERIOD > block.timestamp) {
            revert Errors.GracePeriodNotOver();
        }
        tokenPriceRaw = super._checkAndReturnLatestRoundData(oracleAddr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AggregatorV3Interface} from "../../interfaces/oracles/chainlink/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Constants} from "../../../Constants.sol";
import {Errors} from "../../../Errors.sol";
import {IOracle} from "../../interfaces/IOracle.sol";

/**
 * @dev supports oracles which are compatible with v2v3 or v3 interfaces
 */
abstract contract ChainlinkBase is IOracle {
    // solhint-disable var-name-mixedcase
    uint256 public immutable BASE_CURRENCY_UNIT;
    mapping(address => address) public oracleAddrs;

    constructor(
        address[] memory _tokenAddrs,
        address[] memory _oracleAddrs,
        uint256 baseCurrencyUnit
    ) {
        uint256 tokenAddrsLength = _tokenAddrs.length;
        if (tokenAddrsLength == 0 || tokenAddrsLength != _oracleAddrs.length) {
            revert Errors.InvalidArrayLength();
        }
        uint8 oracleDecimals;
        uint256 version;
        for (uint256 i; i < tokenAddrsLength; ) {
            if (_tokenAddrs[i] == address(0) || _oracleAddrs[i] == address(0)) {
                revert Errors.InvalidAddress();
            }
            oracleDecimals = AggregatorV3Interface(_oracleAddrs[i]).decimals();
            if (10 ** oracleDecimals != baseCurrencyUnit) {
                revert Errors.InvalidOracleDecimals();
            }
            version = AggregatorV3Interface(_oracleAddrs[i]).version();
            if (version != 4) {
                revert Errors.InvalidOracleVersion();
            }
            oracleAddrs[_tokenAddrs[i]] = _oracleAddrs[i];
            unchecked {
                ++i;
            }
        }
        BASE_CURRENCY_UNIT = baseCurrencyUnit;
    }

    function getPrice(
        address collToken,
        address loanToken
    ) external view virtual returns (uint256 collTokenPriceInLoanToken) {
        (uint256 priceOfCollToken, uint256 priceOfLoanToken) = getRawPrices(
            collToken,
            loanToken
        );
        uint256 loanTokenDecimals = IERC20Metadata(loanToken).decimals();
        collTokenPriceInLoanToken = Math.mulDiv(
            priceOfCollToken,
            10 ** loanTokenDecimals,
            priceOfLoanToken
        );
    }

    function getRawPrices(
        address collToken,
        address loanToken
    )
        public
        view
        virtual
        returns (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw)
    {
        (collTokenPriceRaw, loanTokenPriceRaw) = (
            _getPriceOfToken(collToken),
            _getPriceOfToken(loanToken)
        );
    }

    function _getPriceOfToken(
        address token
    ) internal view virtual returns (uint256 tokenPriceRaw) {
        address oracleAddr = oracleAddrs[token];
        if (oracleAddr == address(0)) {
            revert Errors.NoOracle();
        }
        tokenPriceRaw = _checkAndReturnLatestRoundData(oracleAddr);
    }

    function _checkAndReturnLatestRoundData(
        address oracleAddr
    ) internal view virtual returns (uint256 tokenPriceRaw) {
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = AggregatorV3Interface(oracleAddr).latestRoundData();
        if (
            roundId == 0 ||
            answeredInRound < roundId ||
            answer < 1 ||
            updatedAt > block.timestamp ||
            updatedAt + Constants.MAX_PRICE_UPDATE_TIMESTAMP_DIVERGENCE <
            block.timestamp
        ) {
            revert Errors.InvalidOracleAnswer();
        }
        tokenPriceRaw = uint256(answer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ChainlinkArbitrumSequencerUSD} from "../chainlink/ChainlinkArbitrumSequencerUSD.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMysoTokenManager} from "../../interfaces/oracles/IMysoTokenManager.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {LogExpMath} from "./utils/LogExpMath.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IGLPManager} from "../../interfaces/oracles/IGLPManager.sol";
import {IGTOKEN} from "../../interfaces/oracles/IGTOKEN.sol";

/**
 * @dev supports oracles which are compatible with v2v3 or v3 interfaces
 */
contract MysoArbitrumUsdOracle is ChainlinkArbitrumSequencerUSD, Ownable {
    struct PriceParams {
        // maxPrice is in 8 decimals for chainlink consistency
        uint96 maxPrice;
        // k is in 18 decimals
        // e.g. 8e17 is 0.8 in decimal
        uint96 k;
        // a and b are in terms of 1000
        // e.g. 1770 is 1.77 in decimal
        uint32 a;
        uint32 b;
    }
    // solhint-disable var-name-mixedcase

    address internal constant MYSO = 0x25bA1ED5DEEA9d8e8add565dA069Ed1eDA397C12;
    address internal constant GDAI = 0xd85E038593d7A098614721EaE955EC2022B9B91B;
    address internal constant GUSDC =
        0xd3443ee1e91aF28e5FB858Fbd0D72A63bA8046E0;
    address internal constant GETH = 0x5977A9682D7AF81D347CFc338c61692163a2784C;
    address internal constant GLP = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
    address internal constant ETH_USD_CHAINLINK =
        0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address internal constant DAI_ETH_CHAINLINK =
        0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;
    address internal constant USDC_USD_CHAINLINK =
        0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address internal constant GLP_MANAGER =
        0x3963FfC9dff443c2A94f21b129D429891E32ec18;

    uint256 internal constant MYSO_PRICE_TIME_LOCK = 5 minutes;

    address public mysoTokenManager;

    PriceParams public mysoPriceParams;

    event MysoTokenManagerUpdated(address newMysoTokenManager);

    error NoMyso();

    /**
     * @dev constructor for MysoOracle
     * @param _tokenAddrs array of token addresses
     * @param _oracleAddrs array of oracle addresses
     * @param _owner owner of the contract
     * @param _mysoTokenManager address of myso token manager contract
     * @param _maxPrice max price in 8 decimals
     * @param _k k in 18 decimals
     * @param _a a in terms of 1000
     * @param _b b in terms of 1000
     */
    constructor(
        address[] memory _tokenAddrs,
        address[] memory _oracleAddrs,
        address _owner,
        address _mysoTokenManager,
        uint96 _maxPrice,
        uint96 _k,
        uint32 _a,
        uint32 _b
    ) ChainlinkArbitrumSequencerUSD(_tokenAddrs, _oracleAddrs) Ownable() {
        mysoTokenManager = _mysoTokenManager;
        mysoPriceParams = PriceParams(_maxPrice, _k, _a, _b);
        _transferOwnership(_owner);
    }

    /**
     * @dev updates myso token manager contract address
     * @param _newMysoTokenManager new myso token manager contract address
     */

    function setMysoTokenManager(
        address _newMysoTokenManager
    ) external onlyOwner {
        mysoTokenManager = _newMysoTokenManager;
        emit MysoTokenManagerUpdated(_newMysoTokenManager);
    }

    /**
     * @dev updates myso price params
     * @param _maxPrice max price in 8 decimals
     * @param _k k in 18 decimals
     * @param _a a in terms of 1000
     * @param _b b in terms of 1000
     */
    function setMysoPriceParams(
        uint96 _maxPrice,
        uint96 _k,
        uint32 _a,
        uint32 _b
    ) external onlyOwner {
        mysoPriceParams = PriceParams(_maxPrice, _k, _a, _b);
    }

    function getPrice(
        address collToken,
        address loanToken
    ) external view override returns (uint256 collTokenPriceInLoanToken) {
        (uint256 priceOfCollToken, uint256 priceOfLoanToken) = getRawPrices(
            collToken,
            loanToken
        );
        uint256 loanTokenDecimals = (loanToken == MYSO)
            ? 18
            : IERC20Metadata(loanToken).decimals();
        collTokenPriceInLoanToken =
            (priceOfCollToken * 10 ** loanTokenDecimals) /
            priceOfLoanToken;
    }

    function getRawPrices(
        address collToken,
        address loanToken
    )
        public
        view
        override
        returns (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw)
    {
        // must have at least one token is MYSO to use this oracle
        if (collToken != MYSO && loanToken != MYSO) {
            revert NoMyso();
        }
        (collTokenPriceRaw, loanTokenPriceRaw) = (
            _getPriceOfToken(collToken),
            _getPriceOfToken(loanToken)
        );
    }

    function _getPriceOfToken(
        address token
    ) internal view virtual override returns (uint256 tokenPriceRaw) {
        if (token == MYSO) {
            tokenPriceRaw = _getMysoPriceInUsd();
        } else if (token == GDAI) {
            tokenPriceRaw = _getGTOKENPriceInUsd(GDAI, DAI_ETH_CHAINLINK);
        } else if (token == GUSDC) {
            tokenPriceRaw = _getGTOKENPriceInUsd(GUSDC, USDC_USD_CHAINLINK);
        } else if (token == GETH) {
            tokenPriceRaw = _getGTOKENPriceInUsd(GETH, ETH_USD_CHAINLINK);
        } else if (token == GLP) {
            tokenPriceRaw = IGLPManager(GLP_MANAGER).getPrice(true) / 1e22;
        } else {
            tokenPriceRaw = super._getPriceOfToken(token);
        }
    }

    function _getMysoPriceInUsd()
        internal
        view
        returns (uint256 mysoPriceInUsd)
    {
        uint256 _totalMysoLoanAmount = IMysoTokenManager(mysoTokenManager)
            .totalMysoLoanAmount();
        PriceParams memory params = mysoPriceParams;
        uint256 maxPrice = uint256(params.maxPrice);
        uint256 k = uint256(params.k);
        uint256 a = uint256(params.a);
        uint256 b = uint256(params.b);
        uint256 numerator = k * b;
        uint256 denominator = uint256(
            LogExpMath.exp(
                int256(Math.mulDiv(_totalMysoLoanAmount, a, 1000000000))
            )
        ) + (2 * b - 1000) * 1e15;
        mysoPriceInUsd = maxPrice - Math.mulDiv(numerator, 1e5, denominator);
    }

    function _getGTOKENPriceInUsd(
        address token,
        address chainlinkOracle
    ) internal view returns (uint256 gTokenPriceRaw) {
        uint256 assetsPerGtoken = IGTOKEN(token).shareToAssetsPrice();
        uint256 assetPriceInUsd = _checkAndReturnLatestRoundData(
            chainlinkOracle
        );
        gTokenPriceRaw = Math.mulDiv(assetsPerGtoken, assetPriceInUsd, 1e18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.

    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2 ** 254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 =
        38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        require(
            x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT,
            "INVALID_EXPONENT"
        );

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }
}