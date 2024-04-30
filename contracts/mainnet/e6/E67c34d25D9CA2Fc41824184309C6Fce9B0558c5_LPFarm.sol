// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

interface IOsakCollector {
  function withdrawFees() external;
}

/**
 * @title LPFarm
 * @dev Manages staking and distribution of rewards for liquidity provider (LP) tokens. It facilitates
 * the staking of LP tokens, allowing users to earn rewards derived from bridge fees collected and
 * distributed by the OsakCollector. This contract retrieves these fees and streams them to stakers
 * over a defined reward period, initially set to 7 days.
 *
 * Functionalities include:
 * - Staking and withdrawing LP tokens.
 * - Claiming rewards based on the user's stake percentage.
 * - Automatic retrieval and distribution of fees collected by OsakCollector.
 * - Configurable parameters for reward and epoch durations
 *
 * Rewards Calculation:
 * - Dynamic reward updates based on the collected fees and the current total stake.
 * - Secure transfer and calculation mechanisms to ensure accurate reward allocation.
 *
 */

contract LPFarm is Ownable, ReentrancyGuard {
  uint256 public constant PRECISION = 10**20;

  uint256 public rewardDuration = 7 days;
  uint256 public epochDuration = 6 days;
  uint256 public rewardsPerSecond;
  uint256 public nextFeeRetrieval;
  uint256 public claimableBalance;
  uint256 public rewardsPerStake;
  uint256 public rewardEndTime;
  uint256 public totalStaked;
  uint256 public updatedAt;

  IOsakCollector public osakCollectorFees;
  IERC20 public stakingToken;
  IERC20 public rewardToken;

  struct Stake {
    uint256 excluded;
    uint256 amount;
  }

  struct UserInfo {
    uint256 stakingTokenBalance;
    uint256 userAllocatedAmount;
    uint256 userStakedAmount;
    uint256 rewardsPerSecond;
    uint256 nextFeeRetrieval;
    uint256 rewardsPerStake;
    uint256 rewardEndTime;
    uint256 totalStaked;
  }

  mapping(address => Stake) public stakes;

  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardClaimed(address indexed user, uint256 reward);
  event OsakCollectorFeesUpdated(IOsakCollector osakCollectorFees);
  event EpochDurationUpdated(uint256 duration);
  event RewardDurationUpdated(uint256 duration);
  event RewardsUpdated(uint256 rewardsPerSecond);
  event StakingTokenSet(address stakingTokenAddress);

  /**
   * @dev Constructor for LPFarm contract initializing staking and reward tokens, and osakCollector fees interface.
   * @param _stakingToken Address of the staking token contract
   * @param _rewardToken Address of the reward token contract
   * @param _osakCollectorFees Address of the osakCollector fees contract
   */
  constructor(IERC20 _stakingToken, IERC20 _rewardToken, IOsakCollector _osakCollectorFees) {
    osakCollectorFees = _osakCollectorFees;
    rewardToken = _rewardToken;
    stakingToken = _stakingToken;
  }

  /**
   * @dev Returns user info, including staking balance and rewards info.
   * @param user The address of the user to retrieve info for
   * @return UserInfo struct containing detailed user information
   */
  function getInfo(address user) public view returns (UserInfo memory) {
    uint256 userAllocatedAmount;
    uint256 stakingTokenBalance;
    uint256 userStakedAmount;

    if (user != address(0)) {
      stakingTokenBalance = stakingToken.balanceOf(user);
      userAllocatedAmount = allocatedAmount(user);
      userStakedAmount = stakes[user].amount;
    }

    return UserInfo({
      userAllocatedAmount: userAllocatedAmount,
      stakingTokenBalance: stakingTokenBalance,
      userStakedAmount: userStakedAmount,
      rewardsPerSecond: rewardsPerSecond,
      nextFeeRetrieval: nextFeeRetrieval,
      rewardsPerStake: rewardsPerStake,
      rewardEndTime: rewardEndTime,
      totalStaked: totalStaked
    });
  }

  /**
  * @dev Sets the staking token address
  * @param _stakingToken The address of the staking token contract
  */
  function setStakingToken(IERC20 _stakingToken) external onlyOwner {
    require(address(stakingToken) == address(0), 'Staking token is already set');

    stakingToken = _stakingToken;
    emit StakingTokenSet(address(_stakingToken));
  }

  /**
  * @dev Sets the osakCollector fees contract address.
  * @param _osakCollectorFees The address of the new osakCollector fees contract
  */
  function setOsakCollectorFees(IOsakCollector _osakCollectorFees) external onlyOwner {
    osakCollectorFees = _osakCollectorFees;
    emit OsakCollectorFeesUpdated(_osakCollectorFees);
  }

  /**
  * @dev Sets the epoch duration.
  * @param _epochDuration The new epoch duration in seconds
  */
  function setEpochDuration(uint256 _epochDuration) external onlyOwner {
    require(_epochDuration <= 2 weeks, "Epcoh duration must be less than 2 weeks");
    require(_epochDuration > 1 days, "Epcoh duration must be greater than 1 day");

    epochDuration = _epochDuration;
    emit EpochDurationUpdated(_epochDuration);
  }

  /**
  * @dev Sets the reward duration.
  * @param _rewardDuration The new reward duration in seconds
  */
  function setRewardDuration(uint256 _rewardDuration) external onlyOwner {
    require(_rewardDuration <= 2 weeks, "Reward duration must be less than 2 weeks");
    require(_rewardDuration > 1 days, "Reward duration must not be 1 day");

    rewardDuration = _rewardDuration;
    emit RewardDurationUpdated(_rewardDuration);
  }

  /**
  * @dev Stakes a specified amount of tokens.
  * @param amount The amount of tokens to stake
  */
  function stake(uint256 amount) external {
    stakeFor(msg.sender, amount);
  }

  /**
  * @dev Stakes a specified amount of tokens on behalf of another address.
  * @param user The address on whose behalf to stake
  * @param amount The amount of tokens to stake
  */
  function stakeFor(address user, uint256 amount) public nonReentrant {
    require(amount > 0, "Cannot stake 0");

    // Always taking from the msg.sender.
    // stakeFor is intended for a zap function, in which the stakingTokens
    // would come from the zap contract.
    stakingToken.transferFrom(msg.sender, address(this), amount);

    bool isFirstStake = totalStaked == 0;
    _claim(user);

    totalStaked += amount;
    stakes[user].amount += amount;

    if (isFirstStake) _retrieveAndReward();
    emit Staked(user, amount);
  }

  /**
  * @dev Withdraws staked tokens.
  * @param amount The amount of tokens to withdraw
  */
  function withdraw(uint256 amount) external nonReentrant {
    require(amount <= stakes[msg.sender].amount, "Withdraw amount exceeds balance");

    _claim(msg.sender);
    totalStaked -= amount;
    stakes[msg.sender].amount -= amount;
    stakingToken.transfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  /**
  * @dev Claims the accumulated rewards for the caller.
  */
  function claim() external nonReentrant {
    _claim(msg.sender);
  }

  /**
  * @dev Internal function to handle the claiming process for rewards.
  * @param user The user who is claiming their rewards
  */
  function _claim(address user) internal {
    uint256 reward = allocatedAmount(user) / PRECISION;

    if (block.timestamp >= nextFeeRetrieval && totalStaked > 0)
      _retrieveAndReward();
    else updateRewards();

    claimableBalance -= reward;

    stakes[user].excluded = rewardsPerStake;
		if (reward > 0) {
			rewardToken.transfer(user, reward);
			emit RewardClaimed(user, reward);
		}
  }

  /**
  * @dev External function to trigger the reward retrieval and distribution.
  */
  function retrieveAndReward() external nonReentrant {
    require(totalStaked > 0, "Can not update rewards until users have staked");
    if (rewardsPerSecond != 0)
      require(block.timestamp >= nextFeeRetrieval, "Cannot update rewards yet");

    _retrieveAndReward();
  }

  /**
  * @dev Internal function to update the rewards for the entire pool.
  */
  function updateRewards() internal {
    if (totalStaked == 0) return;
    uint256 currentAllocation = currentAllocationPeriod() * rewardsPerSecond;
    rewardsPerStake += currentAllocation / totalStaked;
    claimableBalance += currentAllocation / PRECISION;
    updatedAt = block.timestamp;
    emit RewardsUpdated(rewardsPerSecond);
  }

  /**
  * @dev Internal function to retrieve external fees and update the reward rate.
  */
  function _retrieveAndReward() internal {
    nextFeeRetrieval = block.timestamp + epochDuration;

    try osakCollectorFees.withdrawFees() { } catch { }
    uint256 balance = rewardToken.balanceOf(address(this));

    updateRewards();

    rewardsPerSecond = PRECISION * (balance - claimableBalance) / rewardDuration;
    rewardEndTime = rewardDuration + block.timestamp;
  }

  /**
   * @dev Calculates the allocated amount of rewards for a user.
   * @param user The user for whom to calculate the allocated rewards
   * @return The amount of allocated rewards for the user
   */
  function allocatedAmount(address user) public view returns (uint256) {
    if (totalStaked == 0) return 0;
    uint256 currentAllocation = currentAllocationPeriod() * rewardsPerSecond * stakes[user].amount / totalStaked;
    uint256 previousAllocation = stakes[user].amount * (rewardsPerStake - stakes[user].excluded);

    return (previousAllocation + currentAllocation);
  }

  /**
   * @dev Calculates the current allocation period based on the last update time and current time.
   * @return The number of seconds in the current allocation period
   */
  function currentAllocationPeriod() public view returns (uint256) {
    if (rewardEndTime <= updatedAt) return 0;

		return Math.min(rewardEndTime, block.timestamp) - updatedAt;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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