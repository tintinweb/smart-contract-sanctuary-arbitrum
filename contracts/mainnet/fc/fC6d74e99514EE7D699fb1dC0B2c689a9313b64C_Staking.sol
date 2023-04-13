// SPDX-License-Identifier: UNLICENSED
// © Copyright AutoDCA. All Rights Reserved
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Staking is Ownable {
    struct Staker {
        uint256 balance;
        uint256 rewardIndex;
        uint256 pendingReward;
    }
    struct StakerResponse {
        uint256 balance;
        uint256 pendingReward;
        uint256 claimableReward;
    }
    struct Unbonding {
        uint256 amount;
        uint256 endTimestamp;
    }
    struct DistributionSchedule {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
    }

    ISwapRouter public uniswapV3Router;
    address public constant DCA = 0x965F298E4ade51C0b0bB24e3369deB6C7D5b3951;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public totalStakedBalance;
    uint256 public lastDistributed;
    uint256 private constant globalRewardIndexPrecision = 1e24;
    uint256 private globalRewardIndex;
    DistributionSchedule public rewardDistributionSchedule;
    uint256 public unbondingDuration;
    uint256 public feeOnClaiming; // 1e6 precision
    uint256 public collectedFee;
    mapping(address => Staker) public stakers;
    mapping(address => Unbonding) public unbondings;

    event Stake(address tokensFrom, address indexed account, uint256 amount);
    event Claim(address indexed account, uint256 amount);
    event Compound(address indexed account, uint256 amount);
    event Unstake(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event EmergencyWithdraw(IERC20 tokenToWithdraw, uint256 amountToWithdraw);
    event SetUnbondingDuration(uint256 newUnbondingDuration);
    event SetFeeOnClaiming(uint256 newFeeOnClaiming);
    event SetDistributionSchedule(
        DistributionSchedule newRewardDistributionSchedule
    );

    constructor(
        ISwapRouter uniswapV3Router_,
        IERC20 stakingToken_,
        IERC20 rewardToken_,
        uint256 feeOnClaiming_,
        uint256 unbondingDuration_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint256 rewardToDistribute_
    ) {
        uniswapV3Router = uniswapV3Router_;
        stakingToken = stakingToken_;
        rewardToken = rewardToken_;
        require(feeOnClaiming_ <= 200000, "Fee cannot be greater than 20%");
        feeOnClaiming = feeOnClaiming_;
        unbondingDuration = unbondingDuration_;
        rewardDistributionSchedule = DistributionSchedule(
            startTimestamp_,
            endTimestamp_,
            rewardToDistribute_
        );
    }

    function setUnbondingDuration(uint256 unbondingDuration_) public onlyOwner {
        unbondingDuration = unbondingDuration_;
        emit SetUnbondingDuration(unbondingDuration_);
    }

    function setFeeOnClaiming(uint feeOnClaiming_) public onlyOwner {
        require(feeOnClaiming_ <= 200000, "Fee cannot be greater than 20%");
        feeOnClaiming = feeOnClaiming_;
        emit SetFeeOnClaiming(feeOnClaiming_);
    }

    function setDistributionSchedule(
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 rewardToDistribute
    ) public onlyOwner {
        require(startTimestamp < endTimestamp, "Invalid timestamps");
        uint256 _globalRewardIndex = _computeReward();
        lastDistributed = block.timestamp;
        globalRewardIndex = _globalRewardIndex;
        rewardDistributionSchedule = DistributionSchedule(
            startTimestamp,
            endTimestamp,
            rewardToDistribute
        );
        emit SetDistributionSchedule(rewardDistributionSchedule);
    }

    function emergencyWithdraw(
        IERC20 tokenToWithdraw,
        uint256 amountToWithdraw
    ) public onlyOwner {
        tokenToWithdraw.transfer(msg.sender, amountToWithdraw);
        emit EmergencyWithdraw(tokenToWithdraw, amountToWithdraw);
    }

    function stakeFor(uint256 amount, address user) public {
        _stake(amount, user, msg.sender);
    }

    function stake(uint256 amount) public {
        _stake(amount, msg.sender, msg.sender);
    }

    function claim() public {
        Staker storage st = stakers[msg.sender];

        uint256 _globalRewardIndex = _computeReward();
        lastDistributed = block.timestamp;
        globalRewardIndex = _globalRewardIndex;

        uint256 pendingReward_ = _computeStakerReward(
            msg.sender,
            _globalRewardIndex
        );
        require(pendingReward_ > 0, "Nothing to claim");
        st.rewardIndex = _globalRewardIndex;
        st.pendingReward = 0;

        uint256 claimableAmountToTransfer = _computeClaimableReward(
            pendingReward_
        );
        collectedFee += pendingReward_ - claimableAmountToTransfer;
        if (claimableAmountToTransfer > 0) {
            rewardToken.transfer(msg.sender, claimableAmountToTransfer);
        }
        emit Claim(msg.sender, claimableAmountToTransfer);
    }

    function compound(uint256 beliefPrice) public {
        Staker storage st = stakers[msg.sender];

        uint256 _globalRewardIndex = _computeReward();
        lastDistributed = block.timestamp;
        globalRewardIndex = _globalRewardIndex;

        uint256 pendingReward_ = _computeStakerReward(
            msg.sender,
            _globalRewardIndex
        );
        require(pendingReward_ > 0, "Nothing to compound");
        uint256 stakingTokenAmount = _swapForStakingToken(
            pendingReward_,
            beliefPrice
        );
        st.rewardIndex = _globalRewardIndex;
        st.pendingReward = 0;
        st.balance += stakingTokenAmount;

        totalStakedBalance += stakingTokenAmount;
        emit Compound(msg.sender, stakingTokenAmount);
    }

    function unstake(uint256 amountToUnstake) public {
        Staker storage st = stakers[msg.sender];
        require(st.balance > 0, "No staked tokens");

        uint256 _globalRewardIndex = _computeReward();
        lastDistributed = block.timestamp;
        globalRewardIndex = _globalRewardIndex;

        uint256 pendingReward_ = _computeStakerReward(
            msg.sender,
            _globalRewardIndex
        );

        require(
            amountToUnstake <= st.balance,
            "You cannot unstake more then you are staking"
        );

        st.rewardIndex = _globalRewardIndex;
        st.pendingReward = pendingReward_;
        st.balance -= amountToUnstake;

        Unbonding storage un = unbondings[msg.sender];
        un.amount += amountToUnstake;
        un.endTimestamp = block.timestamp + unbondingDuration;

        totalStakedBalance -= amountToUnstake;
        emit Unstake(msg.sender, amountToUnstake);
    }

    function withdraw() public {
        Unbonding storage un = unbondings[msg.sender];
        uint256 amount = un.amount;
        require(amount > 0, "Nothing to withdraw");
        require(
            un.endTimestamp <= block.timestamp,
            "You cannot withraw before unbonding ends"
        );
        delete unbondings[msg.sender];
        stakingToken.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function getStaker(
        address staker
    ) public view returns (StakerResponse memory) {
        Staker memory st = stakers[staker];
        uint256 globalRewardIndex_ = _computeReward();
        uint256 pendingReward_ = _computeStakerReward(
            staker,
            globalRewardIndex_
        );
        StakerResponse memory stakerResponse = StakerResponse({
            balance: st.balance,
            pendingReward: pendingReward_,
            claimableReward: _computeClaimableReward(pendingReward_)
        });

        return stakerResponse;
    }

    function getUnbonding(
        address staker
    ) public view returns (Unbonding memory) {
        return unbondings[staker];
    }

    function _computeClaimableReward(
        uint256 pendingReward
    ) internal view returns (uint256) {
        return ((1e6 - feeOnClaiming) * pendingReward) / 1e6;
    }

    function _computeReward() internal view returns (uint256) {
        if (totalStakedBalance == 0) {
            return globalRewardIndex;
        }

        DistributionSchedule memory schedule = rewardDistributionSchedule;
        if (
            schedule.endTime < lastDistributed ||
            schedule.startTime > block.timestamp
        ) {
            return globalRewardIndex;
        }

        uint256 end = Math.min(schedule.endTime, block.timestamp);
        uint256 start = Math.max(schedule.startTime, lastDistributed);

        uint256 secondsFromLastDistribution = end - start;
        uint256 totalSecondsInDistributionSchedule = schedule.endTime -
            schedule.startTime;

        uint256 rewardDistributedAmount = (schedule.amount *
            secondsFromLastDistribution) / totalSecondsInDistributionSchedule;

        return
            globalRewardIndex +
            ((globalRewardIndexPrecision * rewardDistributedAmount) /
                totalStakedBalance);
    }

    function _computeStakerReward(
        address staker,
        uint256 globalRewardIndex_
    ) internal view returns (uint256) {
        uint256 pendingReward = stakers[staker].balance *
            globalRewardIndex_ -
            stakers[staker].balance *
            stakers[staker].rewardIndex;

        return
            stakers[staker].pendingReward +
            pendingReward /
            globalRewardIndexPrecision;
    }

    function _stake(
        uint256 amount,
        address staker,
        address transferTokensFrom
    ) internal {
        require(amount > 0, "Amount must be greater than 0");

        uint256 balance = stakingToken.balanceOf(transferTokensFrom);
        require(amount <= balance, "Insufficient balance");

        uint256 _globalRewardIndex = _computeReward();
        lastDistributed = block.timestamp;
        globalRewardIndex = _globalRewardIndex;

        Staker storage st = stakers[staker];

        uint256 pendingReward_ = _computeStakerReward(
            staker,
            _globalRewardIndex
        );
        st.rewardIndex = _globalRewardIndex;
        st.pendingReward = pendingReward_;
        st.balance += amount;

        totalStakedBalance += amount;
        stakingToken.transferFrom(transferTokensFrom, address(this), amount);

        emit Stake(transferTokensFrom, staker, amount);
    }

    function _swapForStakingToken(
        uint256 amount,
        uint256 beliefPrice
    ) internal returns (uint256) {
        IERC20(USDC).approve(address(uniswapV3Router), amount);
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(USDC, WETH, DCA),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: (amount * beliefPrice) / 1e6
            });
        uint256 received = uniswapV3Router.exactInput(params);
        return received;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}