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

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "../interfaces/IChildGaugeFactory.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract ChildGauge is ReentrancyGuard {
    event Deposit(address indexed provider, uint256 value);
    event Withdraw(address indexed provider, uint256 value);
    event UpdateLiquidityLimit(
        address user,
        uint256 originalBalance,
        uint256 originalSupply,
        uint256 workingBalance,
        uint256 workingSupply,
        uint256 votingBalance,
        uint256 votingTotal
    );
    event SetPermit2Address(address oldAddress, address newAddress);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event AddReward(address indexed sender, address indexed rewardToken, address indexed distributorAddress);
    event ChangeRewardDistributor(
        address sender,
        address indexed rewardToken,
        address indexed newDistributorAddress,
        address oldDistributorAddress
    );

    uint256 private constant _MAX_REWARDS = 8;
    uint256 internal constant _TOKENLESS_PRODUCTION = 40;
    uint256 internal constant _WEEK = 86400 * 7;

    // permit2 contract
    address public permit2Address;

    address public immutable ltToken;
    address public  factory;

    string public name;
    string public symbol;
    uint256 public decimals = 18;

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    // pool lp token
    address public lpToken;

    address public votingEscrow;
    mapping(address => uint256) public workingBalances;
    uint256 public workingSupply;

    uint256 public period; //modified from "int256 public period" since it never be minus.
    mapping(uint256 => uint256) public periodTimestamp;

    // ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // Units rate * t = already number of coins per address to issue
    mapping(address => uint256) public integrateFraction; //Mintable Token amount (include minted amount)
    mapping(uint256 => uint256) integrateInvSupply;
    mapping(address => uint256) public integrateInvSupplyOf;
    mapping(address => uint256) public integrateCheckpointOf;

    // For tracking external rewards
    uint256 public rewardCount;
    address[_MAX_REWARDS] public rewardTokens;
    mapping(address => Reward) public rewardData;
    // claimant -> default reward receiver
    mapping(address => address) public rewardsReceiver;
    // reward token -> claiming address -> integral
    mapping(address => mapping(address => uint256)) public rewardIntegralFor;
    // user -> [uint128 claimable amount][uint128 claimed amount]
    mapping(address => mapping(address => uint256)) public claimData;

//    bool public isKilled;
    mapping(uint256 => uint256) public inflationRate;

    struct Reward {
        address token;
        address distributor;
        uint256 periodFinish;
        uint256 rate;
        uint256 lastUpdate;
        uint256 integral;
    }

    // Claim pending rewards and checkpoint rewards for a user
    struct CheckPointRewardsVars {
        uint256 userBalance;
        address receiver;
        uint256 _rewardCount;
        address token;
        uint256 integral;
        uint256 lastUpdate;
        uint256 duration;
    }

    constructor(address _ltToken, address _permit2Address) {
        require(_ltToken != address(0), "CE000");
        factory = address(0xdead);
        ltToken = _ltToken;
        permit2Address = _permit2Address;
    }

    function initialize(address _lpToken) external {
        require(_lpToken != address(0), "CE000");
        require(factory == address(0), "GP002");

        factory = msg.sender;
        lpToken = _lpToken;
        votingEscrow = IChildGaugeFactory(factory).votingEscrow();
        periodTimestamp[0] = block.timestamp;

        string memory _symbol = IERC20Metadata(_lpToken).symbol();
        name = string.concat("hope.money ", _symbol, " Gauge Deposit");
        symbol = string.concat(_symbol, "-gauge");
    }

    /***
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external {
        require((msg.sender == factory), "GP000");
        address oldAddress = permit2Address;
        permit2Address = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }

    /***
     * @notice Checkpoint a user calculating their LT entitlement
     * @param _user User address
     */
    function _checkpoint(address _user) internal {
        uint256 _period = period;
        uint256 _periodTime = periodTimestamp[_period];
        uint256 _integrateInvSupply = integrateInvSupply[_period];

        if (block.timestamp > _periodTime) {
            uint256 _workSupply = workingSupply;
            uint256 _prevWeekTime = _periodTime;
            uint256 _weekTime = Math.min((_periodTime + _WEEK) / _WEEK * _WEEK, block.timestamp);

            for (uint256 i; i < 256; i++) {
                uint256 dt = _weekTime - _prevWeekTime;
                if (_workSupply != 0) {
                    // we don't have to worry about crossing inflation epochs
                    // and if we miss any weeks, those weeks inflation rates will be 0 for sure
                    // but that means no one interacted with the gauge for that long
                    _integrateInvSupply += inflationRate[_prevWeekTime / _WEEK] * 10 ** 18 * dt / _workSupply;
                }
                if (_weekTime == block.timestamp) {
                    break;
                }
                _prevWeekTime = _weekTime;
                _weekTime = Math.min(_weekTime + _WEEK, block.timestamp);
            }
        }

        // check LT balance and increase weekly inflation rate by delta for the rest of the week
        uint256 ltBalance = IERC20Metadata(ltToken).balanceOf(address(this));
        if (ltBalance != 0) {
            uint256 currentWeek = block.timestamp / _WEEK;
            inflationRate[currentWeek] += ltBalance / ((currentWeek + 1) * _WEEK - block.timestamp);
            TransferHelper.doTransferOut(ltToken, factory, ltBalance);
        }

        _period += 1;
        period = _period;
        periodTimestamp[period] = block.timestamp;
        integrateInvSupply[period] = _integrateInvSupply;
        uint256 _workingBalance = workingBalances[_user];
        integrateFraction[_user] += _workingBalance * (_integrateInvSupply - integrateInvSupplyOf[_user]) / 10 ** 18;
        integrateInvSupplyOf[_user] = _integrateInvSupply;
        integrateCheckpointOf[_user] = block.timestamp;
    }

    /***
     * @notice Calculate limits which depend on the amount of lp Token per-user.
     *        Effectively it calculates working balances to apply amplification
     *        of LT production by LT
     * @param _user The user address
     * @param _l User's amount of liquidity (LP tokens)
     * @param _L Total amount of liquidity (LP tokens)
     */
    function _updateLiquidityLimit(address _addr, uint256 _l, uint256 _L) internal {
        uint256 _lim = _l * _TOKENLESS_PRODUCTION / 100;
        uint256 _votingBalance = IERC20Metadata(votingEscrow).balanceOf(_addr);
        uint256 _votingTotal = IERC20Metadata(votingEscrow).totalSupply();
        if (votingEscrow != address(0)) {
            if (_votingTotal > 0) {
                // 0.4 * _l + 0.6 * _L * balance / total
                _lim += (_L * _votingBalance * (100 - _TOKENLESS_PRODUCTION)) / _votingTotal / 100;
            }
        }
        _lim = Math.min(_l, _lim);

        uint256 _oldBal = workingBalances[_addr];
        workingBalances[_addr] = _lim;
        uint256 _workingSupply = workingSupply + _lim - _oldBal;
        workingSupply = _workingSupply;

        emit UpdateLiquidityLimit(_addr, _l, _L, _lim, _workingSupply, _votingBalance, _votingTotal);
    }

    function _checkpointRewards(address _user, uint256 _totalSupply, bool _claim, address _receiver) internal {
        CheckPointRewardsVars memory vars;
        vars.userBalance = 0;
        vars.receiver = _receiver;
        if (_user != address(0)) {
            vars.userBalance = balanceOf[_user];
            if (_claim && _receiver == address(0)) {
                // if receiver is not explicitly declared, check if a default receiver is set
                vars.receiver = rewardsReceiver[_user];
                if (vars.receiver == address(0)) {
                    // if no default receiver is set, direct claims to the user
                    vars.receiver = _user;
                }
            }
        }

        vars._rewardCount = rewardCount;
        for (uint256 i = 0; i < _MAX_REWARDS; i++) {
            if (i == vars._rewardCount) {
                break;
            }
            vars.token = rewardTokens[i];

            vars.integral = rewardData[vars.token].integral;
            vars.lastUpdate = Math.min(block.timestamp, rewardData[vars.token].periodFinish);
            vars.duration = vars.lastUpdate - rewardData[vars.token].lastUpdate;
            if (vars.duration != 0) {
                rewardData[vars.token].lastUpdate = vars.lastUpdate;
                if (_totalSupply != 0) {
                    vars.integral += (vars.duration * rewardData[vars.token].rate * 10 ** 18) / _totalSupply;
                    rewardData[vars.token].integral = vars.integral;
                }
            }

            if (_user != address(0)) {
                uint256 _integralFor = rewardIntegralFor[vars.token][_user];
                uint256 newClaimable = 0;

                if (_integralFor < vars.integral) {
                    rewardIntegralFor[vars.token][_user] = vars.integral;
                    newClaimable = (vars.userBalance * (vars.integral - _integralFor)) / 10 ** 18;
                }

                uint256 _claimData = claimData[_user][vars.token];
                uint256 totalClaimable = (_claimData >> 128) + newClaimable;
                // shift(claim_data, -128)
                if (totalClaimable > 0) {
                    uint256 totalClaimed = _claimData % 2 ** 128;
                    if (_claim) {
                        claimData[_user][vars.token] = totalClaimed + totalClaimable;
                        TransferHelper.doTransferOut(vars.token, vars.receiver, totalClaimable);
                    } else if (newClaimable > 0) {
                        claimData[_user][vars.token] = totalClaimed + (totalClaimable << 128);
                    }
                }
            }
        }
    }


    function _transfer(address _from, address _to, uint256 _value) internal {
        _checkpoint(_from);
        _checkpoint(_to);
        if (_value != 0) {
            uint256 _totalSupply = totalSupply;
            bool isRewards = rewardCount != 0;
            if (isRewards) {
                _checkpointRewards(_from, _totalSupply, false, address(0));
            }
            uint256 newBalance = balanceOf[_from] - _value;
            balanceOf[_from] = newBalance;
            _updateLiquidityLimit(_from, newBalance, _totalSupply);

            if (isRewards) {
                _checkpointRewards(_to, _totalSupply, false, address(0));
            }
            newBalance = balanceOf[_to] + _value;
            balanceOf[_to] = newBalance;
            _updateLiquidityLimit(_to, newBalance, _totalSupply);
        }
        emit Transfer(_from, _to, _value);
    }

    /**
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _addr Address to deposit for
     */
    function _deposit(
        uint256 _value,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature,
        address _addr,
        bool _claimRewards_
    ) private {
        _checkpoint(_addr);

        if (_value != 0) {
            bool isRewards = rewardCount != 0;
            uint256 _totalSupply = totalSupply;
            if (isRewards) {
                _checkpointRewards(_addr, _totalSupply, _claimRewards_, address(0));
            }

            _totalSupply += _value;
            uint256 newBalance = balanceOf[_addr] + _value;
            balanceOf[_addr] = newBalance;
            totalSupply = _totalSupply;

            _updateLiquidityLimit(_addr, newBalance, _totalSupply);

            TransferHelper.doTransferIn(permit2Address, lpToken, _value, msg.sender, _nonce, _deadline, _signature);
        }

        emit Deposit(_addr, _value);
        emit Transfer(address(0), _addr, _value);
    }

    /**
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     */
    function deposit(uint256 _value, uint256 _nonce, uint256 _deadline, bytes memory _signature) external nonReentrant {
        _deposit(_value, _nonce, _deadline, _signature, msg.sender, false);
    }

    /**
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _addr Address to deposit for
     */
    function deposit(uint256 _value, uint256 _nonce, uint256 _deadline, bytes memory _signature, address _addr) external nonReentrant {
        _deposit(_value, _nonce, _deadline, _signature, _addr, false);
    }

    /**
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _addr Address to deposit for
     * @param _claimRewards_ receiver
     */
    function deposit(
        uint256 _value,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature,
        address _addr,
        bool _claimRewards_
    ) external nonReentrant {
        _deposit(_value, _nonce, _deadline, _signature, _addr, _claimRewards_);
    }

    /**
     * @notice Withdraw `_value` LP tokens
     * @dev Withdrawing also claims pending reward tokens
     * @param _value Number of tokens to withdraw
     */
    function _withdraw(uint256 _value, bool _claimRewards_) private {
        _checkpoint(msg.sender);

        if (_value != 0) {
            bool isRewards = rewardCount != 0;
            uint256 _totalSupply = totalSupply;
            if (isRewards) {
                _checkpointRewards(msg.sender, _totalSupply, _claimRewards_, address(0));
            }

            _totalSupply -= _value;
            uint256 newBalance = balanceOf[msg.sender] - _value;
            balanceOf[msg.sender] = newBalance;
            totalSupply = _totalSupply;

            _updateLiquidityLimit(msg.sender, newBalance, _totalSupply);

            TransferHelper.doTransferOut(lpToken, msg.sender, _value);
        }

        emit Withdraw(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }

    function withdraw(uint256 _value) external nonReentrant {
        _withdraw(_value, false);
    }

    function withdraw(uint256 _value, bool _claimRewards_) external nonReentrant {
        _withdraw(_value, _claimRewards_);
    }

    /**
     * @notice Transfer token for a specified address
     * @dev Transferring claims pending reward tokens for the sender and receiver
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) external nonReentrant returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @notice Transfer tokens from one address to another.
    * @dev Transferring claims pending reward tokens for the sender and receiver
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) external nonReentrant returns (bool) {
        uint256 _allowance = allowance[_from][msg.sender];
        if (_allowance != type(uint256).max) {
            allowance[_from][msg.sender] = _allowance - _value;
        }

        _transfer(_from, _to, _value);
        return true;
    }

    /***
    * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "CE000");
        require(spender != address(0), "CE000");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /***
     * @notice Approve the passed address to transfer the specified amount of
            tokens on behalf of msg.sender
     * @dev Beware that changing an allowance via this method brings the risk
         that someone may use both the old and new allowance by unfortunate
         transaction ordering. This may be mitigated with the use of
         {incraseAllowance} and {decreaseAllowance}.
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will transfer the funds
     * @param _value The amount of tokens that may be transferred
     * @return bool success
    */
    function approve(address _spender, uint256 _value) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, _spender, _value);
        return true;
    }

    /***
     * @notice Increase the allowance granted to `_spender` by the caller
     * @dev This is alternative to {approve} that can be used as a mitigation for the potential race condition
     * @param _spender The address which will transfer the funds
     * @param _addedValue The amount of to increase the allowance
     * @return bool success
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, _spender, allowance[owner][_spender] + _addedValue);
        return true;
    }

    /***
     * @notice Decrease the allowance granted to `_spender` by the caller
     * @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
     * @param _spender The address which will transfer the funds
     * @param _subtractedValue The amount of to decrease the allowance
     * @return bool success
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance[owner][_spender];
        require(currentAllowance >= _subtractedValue, "GP003");
        unchecked {
            _approve(owner, _spender, currentAllowance - _subtractedValue);
        }
        return true;
    }

    /***
     * @notice Record a checkpoint for `_addr`
     * @param _addr User address
     * @return bool success
     */
    function userCheckpoint(address _addr) external returns (bool) {
        require((msg.sender == _addr) || (msg.sender == factory), "GP000");
        _checkpoint(_addr);
        _updateLiquidityLimit(_addr, balanceOf[_addr], totalSupply);
        return true;
    }

    /***
     * @notice Get the number of claimable tokens per user
     * @dev This function should be manually changed to "view" in the ABI
     * @return uint256 number of claimable tokens per user
     */
    function claimableTokens(address _addr) external returns (uint256) {
        _checkpoint(_addr);
        return (integrateFraction[_addr] - IChildGaugeFactory(factory).minted(_addr, address(this)));
    }

    /***
     * @notice Get the number of already-claimed reward tokens for a user
     * @param _addr Account to get reward amount for
     * @param _token Token to get reward amount for
     * @return uint256 Total amount of `_token` already claimed by `_addr`
     */
    function claimedReward(address _addr, address _token) external view returns (uint256) {
        return claimData[_addr][_token] % 2 ** 128;
    }

    /***
     * @notice Get the number of claimable reward tokens for a user
     * @param _user Account to get reward amount for
     * @param _reward_token Token to get reward amount for
     * @return uint256 Claimable reward token amount
     */
    function claimableReward(address _user, address _reward_token) external view returns (uint256) {
        uint256 integral = rewardData[_reward_token].integral;
        uint256 _totalSupply = totalSupply;
        if (_totalSupply != 0) {
            uint256 lastUpdate = Math.min(block.timestamp, rewardData[_reward_token].periodFinish);
            uint256 duration = lastUpdate - rewardData[_reward_token].lastUpdate;
            integral += ((duration * rewardData[_reward_token].rate * 10 ** 18) / _totalSupply);
        }

        uint256 integralFor = rewardIntegralFor[_reward_token][_user];
        uint256 newClaimable = (balanceOf[_user] * (integral - integralFor)) / 10 ** 18;

        return (claimData[_user][_reward_token] >> 128) + newClaimable;
    }

    /***
     * @notice Set the default reward receiver for the caller.
     * @dev When set to ZERO_ADDRESS, rewards are sent to the caller
     * @param _receiver Receiver address for any rewards claimed via `claim_rewards`
     */
    function setRewardsReceiver(address _receiver) external {
        rewardsReceiver[msg.sender] = _receiver;
    }

    /***
     * @notice Claim available reward tokens for `_addr`
     * @param _addr Address to claim for
     * @param _receiver Address to transfer rewards to - if set to
                     ZERO_ADDRESS, uses the default reward receiver
                     for the caller
     */
    function _claimRewards(address _addr, address _receiver) private {
        if (_receiver != address(0)) {
            require(_addr == msg.sender, "GP011");
            // dev: cannot redirect when claiming for another user
        }
        _checkpointRewards(_addr, totalSupply, true, _receiver);
    }

    function claimRewards() external nonReentrant {
        _claimRewards(msg.sender, address(0));
    }

    function claimRewards(address _addr) external nonReentrant {
        _claimRewards(_addr, address(0));
    }

    function claimRewards(address _addr, address _receiver) external nonReentrant {
        _claimRewards(_addr, _receiver);
    }

    /**
     * @notice Set the active reward contract
     */
    function addReward(address _rewardToken, address _distributor) external {
        require(msg.sender == IChildGaugeFactory(factory).owner());
        uint256 _rewardCount = rewardCount;
        require(_rewardCount < _MAX_REWARDS, "GP004");
        require(rewardData[_rewardToken].distributor == address(0), "GP005");
        rewardData[_rewardToken].distributor = _distributor;
        rewardTokens[_rewardCount] = _rewardToken;
        rewardCount = _rewardCount + 1;
        emit AddReward(msg.sender, _rewardToken, _distributor);
    }

    function setRewardDistributor(address _rewardToken, address _distributor) external {
        address currentDistributor = rewardData[_rewardToken].distributor;
        require(msg.sender == currentDistributor || msg.sender == IChildGaugeFactory(factory).owner(), "GP006");
        require(currentDistributor != address(0), "GP007");
        require(_distributor != address(0), "GP008");
        rewardData[_rewardToken].distributor = _distributor;
        emit ChangeRewardDistributor(msg.sender, _rewardToken, _distributor, currentDistributor);
    }

    function depositRewardToken(address _rewardToken, uint256 _amount) external payable nonReentrant {
        require(msg.sender == rewardData[_rewardToken].distributor, "GP009");

        _checkpointRewards(address(0), totalSupply, false, address(0));

        uint256 spendAmount = TransferHelper.doTransferFrom(_rewardToken, msg.sender, address(this), _amount);

        uint256 periodFinish = rewardData[_rewardToken].periodFinish;
        if (block.timestamp >= periodFinish) {
            rewardData[_rewardToken].rate = spendAmount / _WEEK;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardData[_rewardToken].rate;
            rewardData[_rewardToken].rate = (spendAmount + leftover) / _WEEK;
        }

        rewardData[_rewardToken].lastUpdate = block.timestamp;
        rewardData[_rewardToken].periodFinish = block.timestamp + _WEEK;
    }

    /***
     * @notice Update the voting escrow contract in storage
     */
    function updateVotingEscrow() external {
        votingEscrow = IChildGaugeFactory(factory).votingEscrow();
    }

    function integrateCheckpoint() external view returns (uint256) {
        return periodTimestamp[period];
    }

//    /***
//     * @notice Set the killed status for this contract
//     * @dev When killed, the gauge always yields a rate of 0 and so cannot mint LT
//     * @param _is_killed Killed status to set
//     */
//    function setKilled(bool _isKilled) external onlyOwner {
//        require(msg.sender == IChildGaugeFactory(factory).owner());
//        isKilled = _isKilled;
//    }


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IChildGaugeFactory {

    function owner() external view returns (address);

    function votingEscrow() external view returns (address);

    function minted(address _user, address _gauge) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

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

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IPermit2 {
    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IPermit2.sol";

library TransferHelper {
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferFrom(address tokenAddress, address from, address to, uint256 amount) internal returns(uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(to);
        safeTransferFrom(token, from, to, amount);
        uint256 balanceAfter = token.balanceOf(to);
        uint256 actualAmount = balanceAfter - balanceBefore;
        assert(actualAmount <= amount);
        return actualAmount;
    }

    /**
     * @dev transfer with permit2
     */
    function doTransferIn(
        address permit2Address,
        address tokenAddress,
        uint256 _value,
        address from,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal returns (uint256) {
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({token: tokenAddress, amount: _value}),
            nonce: nonce,
            deadline: deadline
        });
        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: address(this),
            requestedAmount: _value
        });
        // Read from storage once
        IERC20 token = IERC20(permit.permitted.token);
        uint256 balanceBefore = token.balanceOf(transferDetails.to);
        if (nonce == 0 && deadline == 0) {
            safeTransferFrom(token, from, transferDetails.to, transferDetails.requestedAmount);
        } else {
            IPermit2(permit2Address).permitTransferFrom(permit, transferDetails, from, signature);
        }
        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(permit.permitted.token).balanceOf(address(this));
        uint256 actualAmount = balanceAfter - balanceBefore;
        assert(actualAmount <= transferDetails.requestedAmount);
        
        return actualAmount;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferOut(address tokenAddress, address to, uint256 amount) internal returns(uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(to);
        safeTransfer(token, to, amount);
        uint256 balanceAfter = token.balanceOf(to);
        uint256 actualAmount = balanceAfter - balanceBefore;
        assert(actualAmount <= amount);
        return actualAmount;
    }

    function doApprove(address tokenAddress, address to, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        safeApprove(token, to, amount);
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}