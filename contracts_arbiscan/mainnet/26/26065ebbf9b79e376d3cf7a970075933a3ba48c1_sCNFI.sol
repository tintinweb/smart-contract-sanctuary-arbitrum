// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {
  StakingControllerTemplate
} from '../staking/StakingControllerTemplate.sol';
import { StakingControllerLib } from '../staking/StakingControllerLib.sol';
import {
  MathUpgradeable as Math
} from '@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol';
import {
  SafeMathUpgradeable
} from '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import { ComputeCyclesHeldLib } from '../staking/ComputeCyclesHeldLib.sol';
import {
  UpdateRedeemableImplLib
} from '../staking/UpdateRedeemableImplLib.sol';
import { GetDisplayTierImplLib } from '../staking/GetDisplayTierImplLib.sol';
import {
  CalculateRewardsImplLib
} from '../staking/CalculateRewardsImplLib.sol';

contract Viewer is StakingControllerTemplate {
  using SafeMathUpgradeable for *;

  function render(address caller)
    public
    view
    returns (
      StakingControllerLib.Tier memory tier,
      StakingControllerLib.EncodeableCycle memory retCycle,
      StakingControllerLib.ReturnStats memory returnstats,
      StakingControllerLib.DailyUser memory dailyUser,
      StakingControllerLib.Tier[] memory _tiers,
      uint256 currentTier
    )
  {
    StakingControllerLib.Cycle storage _cycle;
    uint256 lastSeenCycle;
    StakingControllerLib.DetermineMultiplierLocals memory locals;
    if (caller != address(0x0)) {
      dailyUser = isolate.dailyUsers[caller];
      _tiers = new StakingControllerLib.Tier[](isolate.tiersLength);
      for (uint256 i = 1; i < isolate.tiersLength; i++) {
        _tiers[i] = isolate.tiers[i];
      }
      tier = isolate.tiers[dailyUser.commitment];
      _cycle = isolate.cycles[isolate.currentCycle];

      {
        returnstats.staked = isolate.sCnfi.balanceOf(caller);
        returnstats.lockCommitment = dailyUser.commitment;
      }
      lastSeenCycle = isolate.currentCycle;

      returnstats.cycleChange = dailyUser.cyclesHeld;
      StakingControllerLib.UserWeightChanges storage _weightChange =
        isolate.weightChanges[caller];
      returnstats.totalCyclesSeen = _weightChange.totalCyclesSeen;

      locals.tierIndex = Math.max(dailyUser.commitment, dailyUser.currentTier);
      locals.tier = isolate.tiers[locals.tierIndex];
      {
        locals.scnfiBalance = isolate.sCnfi.balanceOf(caller);
      }
      {
        returnstats.currentCnfiBalance = isolate.cnfi.balanceOf(caller);
        currentTier = GetDisplayTierImplLib._getDisplayTier(
          isolate,
          Math.max(dailyUser.currentTier, dailyUser.commitment),
          returnstats.staked
        );
        returnstats.redeemable = dailyUser.redeemable;
        (, returnstats.bonuses) = CalculateRewardsImplLib._computeRewards(
          isolate,
          caller
        );
      }
    }
    _cycle = isolate.cycles[isolate.currentCycle];
    retCycle = StakingControllerLib.EncodeableCycle(
      _cycle.totalWeight,
      _cycle.totalRawWeight,
      _cycle.pCnfiToken,
      _cycle.reserved,
      _cycle.day,
      _cycle.canUnstake,
      lastSeenCycle,
      isolate.currentCycle
    );

    {
      returnstats.totalStakedInProtocol = isolate.sCnfi.totalSupply();
    }
    returnstats.cnfiReleasedPerDay = isolate.inflateBy;
    returnstats.basePenalty = isolate.baseUnstakePenalty;
    returnstats.commitmentViolationPenalty = isolate.commitmentViolationPenalty;
    returnstats.totalWeight = isolate.totalWeight;
    return (locals.tier, retCycle, returnstats, dailyUser, _tiers, currentTier);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import {StakingControllerLib} from "./StakingControllerLib.sol";
import {
    SafeMathUpgradeable
} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ViewExecutor} from "../util/ViewExecutor.sol";

contract StakingControllerTemplate is OwnableUpgradeable {
    using SafeMathUpgradeable for *;
    StakingControllerLib.Isolate isolate;

    function currentCycle() public view returns (uint256 cycle) {
        cycle = isolate.currentCycle;
    }

    function commitmentViolationPenalty()
        public
        view
        returns (uint256 penalty)
    {
        penalty = isolate.commitmentViolationPenalty;
    }

    function dailyBonusesAccrued(address user)
        public
        view
        returns (uint256 amount)
    {
        amount = isolate.dailyBonusesAccrued[user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { CNFITreasury } from "../treasury/CNFITreasury.sol";
import { ICNFI } from "../interfaces/ICNFI.sol";
import { pCNFI } from "../token/pCNFI.sol";
import { sCNFI } from "../token/sCNFI.sol";

contract StakingControllerLib {
    struct Isolate {
      uint256 currentCycle;
      CNFITreasury cnfiTreasury;
      ICNFI cnfi;
      sCNFI sCnfi;
      pCNFI pCnfi;
      uint256 nextCycleTime;
      uint256 cycleInterval;
      uint256 nextTimestamp;
      uint256 inflateBy;
      uint256 inflatepcnfiBy;
      uint256 rewardInterval;
      uint256 tiersLength;
      uint256 baseUnstakePenalty;
      uint256 commitmentViolationPenalty;
      uint256 totalWeight;
      uint256 lastTotalWeight;
      uint256 cumulativeTotalWeight;
      mapping(uint256 => StakingControllerLib.Cycle) cycles;
      mapping(uint256 => StakingControllerLib.Tier) tiers;
      mapping(address => uint256) lockCommitments;
      mapping(address => uint256) bonusesAccrued;
      mapping(address => uint256) dailyBonusesAccrued;
      mapping(address => StakingControllerLib.UserWeightChanges) weightChanges;
      mapping(address => StakingControllerLib.DailyUser) dailyUsers;
      uint256[] inflateByChanged;
      mapping(uint256 => StakingControllerLib.InflateByChanged) inflateByValues;
      address pCnfiImplementation;
      uint256 currentDay;
    }
    struct User {
        uint256 currentWeight;
        uint256 minimumWeight;
        uint256 dailyWeight;
        uint256 multiplier;
        uint256 redeemable;
        uint256 daysClaimed;
        uint256 start;
        bool seen;
        uint256 currentTier;
        uint256 cyclesHeld;
    }
    struct DailyUser {
        uint256 multiplier;
        uint256 cycleEnd;
        uint256 cyclesHeld;
        uint256 redeemable;
        uint256 start;
        uint256 weight;
        uint256 claimed;
        uint256 commitment;
        uint256 lastDaySeen;
        uint256 cumulativeTotalWeight;
        uint256 cumulativeRewardWeight;
        uint256 lastTotalWeight;
        uint256 currentTier;
    }
    struct DetermineMultiplierLocals {
        uint256 scnfiBalance;
        uint256 minimum;
        uint256 tierIndex;
        Tier tier;
        uint256 cyclesHeld;
        uint256 multiplier;
    }
    struct DetermineRewardLocals {
        uint256 lastDaySeen;
        uint256 redeemable;
        uint256 totalWeight;
        uint256 multiplier;
        uint256 weight;
        uint256 rawWeight;
        uint256 totalRawWeight;
    }
    struct ReturnStats {
        uint256 lockCommitment;
        uint256 totalStakedInProtocol;
        uint256 cnfiReleasedPerDay;
        uint256 staked;
        uint256 currentCnfiBalance;
        uint256 unstakePenalty;
        uint256 redeemable;
        uint256 bonuses;
        uint256 apy;
        uint256 commitmentViolationPenalty;
        uint256 basePenalty;
        uint256 totalWeight;
        uint256 cycleChange;
        uint256 totalCyclesSeen;
    }
    struct Cycle {
        uint256 totalWeight;
        uint256 totalRawWeight;
        address pCnfiToken;
        uint256 reserved;
        uint256 day;
        uint256 inflateBy;
        mapping(address => User) users;
        mapping(uint256 => uint256) cnfiRewards;
        mapping(uint256 => uint256) pcnfiRewards;
        bool canUnstake;
    }
    struct Tier {
        uint256 multiplier;
        uint256 minimum;
        uint256 cycles;
    }
    struct EncodeableCycle {
        uint256 totalWeight;
        uint256 totalRawWeight;
        address pCnfiToken;
        uint256 reserved;
        uint256 day;
        bool canUnstake;
        uint256 lastCycleSeen;
        uint256 currentCycle;
    }
    struct UpdateLocals {
        uint256 multiplier;
        uint256 weight;
        uint256 prevMul;
        uint256 prevRes;
        uint256 prevRawRes;
        uint256 nextRes;
        uint256 nextRawRes;
    }
    struct RecalculateLocals {
        uint256 currentWeight;
        uint256 previousMultiplier;
        uint256 previousMinimumWeight;
        uint256 previousTotalWeight;
        uint256 totalInflated;
        uint256 daysToRedeem;
        uint256 previousRedeemable;
        uint256 amt;
        uint256 bonus;
        uint256 minimumWeight;
        uint256 multiplier;
        uint256 currentTotalWeight;
    }
    struct InflateByChanged {
        uint256 totalWeight;
        uint256 previousAmount;
    }
    struct DetermineInflateLocals {
        uint256 totalWeight;
        uint256 lastDaySeen;
        uint256 dayDifference;
        InflateByChanged changed;
        uint256 tempRedeemable;
        uint256 redeemable;
        uint256 daysToClaim;
        uint256 lastDayInEpoch;
        uint256 dayChanged;
        uint256 tempBonus;
        uint256 lastDayChanged;
    }
    struct UserWeightChanges {
        mapping(uint256 => uint256) changes;
        uint256 totalCyclesSeen;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {
  SafeMathUpgradeable
} from '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';

library ComputeCyclesHeldLib {
  using SafeMathUpgradeable for *;

  function _computeCyclesHeld(
    uint256 cycleEnd,
    uint256 interval,
    uint256 _cyclesHeld,
    uint256 currentTimestamp
  ) internal pure returns (uint256 newCycleEnd, uint256 newCyclesHeld) {
    if (cycleEnd == 0) cycleEnd = currentTimestamp.add(interval);
    if (cycleEnd > currentTimestamp) return (cycleEnd, _cyclesHeld);
    uint256 additionalCycles = currentTimestamp.sub(cycleEnd).div(interval);
    newCyclesHeld = _cyclesHeld.add(1).add(additionalCycles);
    newCycleEnd = cycleEnd.add(interval.mul(additionalCycles.add(1)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {
  SafeMathUpgradeable
} from '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import { StakingControllerLib } from './StakingControllerLib.sol';
import {
  MathUpgradeable as Math
} from '@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol';
import { UpdateToLastImplLib } from './UpdateToLastImplLib.sol';
import { sCNFI } from '../token/sCNFI.sol';
import { ComputeCyclesHeldLib } from './ComputeCyclesHeldLib.sol';
import { BancorFormulaLib } from '../math/BancorFormulaLib.sol';


library UpdateRedeemableImplLib {
  using SafeMathUpgradeable for *;
  using BancorFormulaLib for *;

  function _updateCumulativeRewards(
    StakingControllerLib.Isolate storage isolate,
    address _user
  ) internal {
    StakingControllerLib.DailyUser storage user = isolate.dailyUsers[_user];
    if (user.multiplier == 0) user.multiplier = uint256(1 ether);
    if (isolate.currentDay > user.lastDaySeen) {
      user.cumulativeRewardWeight = user.cumulativeRewardWeight.add(
        isolate.currentDay.sub(user.lastDaySeen).mul(user.weight)
      );
    } else user.cumulativeRewardWeight = 0;
  }

  function _updateRedeemable(
    StakingControllerLib.Isolate storage isolate,
    StakingControllerLib.DailyUser storage user,
    uint256 multiplier
  ) internal view returns (uint256 redeemable, uint256 bonuses) {
    StakingControllerLib.DetermineInflateLocals memory locals;
    locals.lastDayInEpoch = isolate.currentDay - 1;
    locals.lastDayChanged = user.lastDaySeen;
    if (locals.lastDayChanged < isolate.currentDay) {
      locals.dayDifference = isolate.currentDay.sub(locals.lastDayChanged);
      /*
            locals.totalWeight = isolate.cumulativeTotalWeight.sub(
                user.cumulativeTotalWeight
            );
            if (locals.totalWeight == 0) return (0, 0);
*/

      uint256 denominator =
        Math.max(
          Math.min(
            isolate.cumulativeTotalWeight.sub(user.cumulativeTotalWeight),
            Math.max(Math.max(isolate.totalWeight, isolate.lastTotalWeight), user.lastTotalWeight).mul(locals.dayDifference)
          ),
          uint256(1 ether)
        );
    
      redeemable = locals
        .dayDifference
        .mul(isolate.inflateBy)
        .mul(user.cumulativeRewardWeight)
        .div(denominator);

      if (multiplier > uint256(1 ether))
        bonuses = redeemable.mul(multiplier.sub(uint256(1 ether))).div(
          multiplier
        );
      else bonuses = 0;
    }
  }

  function _determineMultiplier(
    StakingControllerLib.Isolate storage isolate,
    bool penaltyChange,
    address user,
    uint256 currentBalance
  ) internal returns (uint256 multiplier, uint256 amountToBurn) {
    StakingControllerLib.DetermineMultiplierLocals memory locals;
    StakingControllerLib.User storage currentUser =
      isolate.cycles[isolate.currentCycle].users[user];
    locals.minimum = uint256(~0);
    locals.tierIndex = isolate.lockCommitments[user];
    locals.tier = isolate.tiers[locals.tierIndex];
    locals.cyclesHeld = 0;
    locals.multiplier = locals.tierIndex == 0
      ? 1 ether
      : locals.tier.multiplier;
    for (uint256 i = isolate.currentCycle; i > 0; i--) {
      StakingControllerLib.Cycle storage cycle = isolate.cycles[i];
      StakingControllerLib.User storage _user = cycle.users[user];
      locals.minimum = Math.min(locals.minimum, _user.minimumWeight);
      currentUser.cyclesHeld = locals.cyclesHeld;
      currentUser.currentTier = locals.tierIndex;
      if (locals.minimum < locals.tier.minimum) {
        if (
          isolate.lockCommitments[user] == locals.tierIndex && penaltyChange
        ) {
          uint256 bonus = isolate.bonusesAccrued[user];
          amountToBurn = Math.min(bonus, currentBalance);

          if (amountToBurn > 0) {
            isolate.bonusesAccrued[user] = 0;
            isolate.lockCommitments[user] = 0;
            currentUser.currentTier = 0;
            currentUser.cyclesHeld = 0;
          }
        }
        return (locals.multiplier, amountToBurn);
      }
      locals.cyclesHeld++;
      if (locals.tierIndex == 0) {
        locals.tierIndex++;
        if (locals.tierIndex > isolate.tiersLength)
          return (locals.multiplier, amountToBurn);
        locals.tier = isolate.tiers[locals.tierIndex];
      }
      if (locals.cyclesHeld == locals.tier.cycles) {
        locals.multiplier = locals.tier.multiplier;
        locals.tierIndex++;

        isolate.lockCommitments[user] = 0;
        isolate.bonusesAccrued[user] = 0;
        if (locals.tierIndex > isolate.tiersLength)
          return (locals.multiplier, amountToBurn);
        locals.tier = isolate.tiers[locals.tierIndex];
      }
    }
    return (locals.multiplier, amountToBurn);
  }

  function _updateDailyStatsToLast(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 weight,
    bool penalize,
    bool init
  ) internal returns (uint256 redeemable, uint256 bonuses) {
    StakingControllerLib.DailyUser storage user = isolate.dailyUsers[sender];
    StakingControllerLib.UserWeightChanges storage weightChange =
      isolate.weightChanges[sender];
    if (user.start == 0) init = true;
    {
      uint256 cycleChange = user.cyclesHeld;
      (user.cycleEnd, user.cyclesHeld) = ComputeCyclesHeldLib
        ._computeCyclesHeld(
        user.cycleEnd,
        isolate.cycleInterval,
        user.cyclesHeld,
        block.timestamp
      );
      if (user.cyclesHeld > 0 && user.cyclesHeld > cycleChange) {
        uint256 baseWeight = isolate.sCnfi.balanceOf(sender);
        for (uint256 i = user.cyclesHeld; i > cycleChange; i--) {
          weightChange.changes[i] = baseWeight;
        }
        weightChange.totalCyclesSeen = user.cyclesHeld;
      }
    }
    if (penalize || init) {
      weightChange.changes[user.cyclesHeld] = weight;
      user.start = block.timestamp;
    }
    uint256 multiplier = _determineDailyMultiplier(isolate, sender);
    
    if (init) user.multiplier = multiplier;
    if (user.lastDaySeen < isolate.currentDay) {
      (redeemable, bonuses) = _updateRedeemable(isolate, user, multiplier);
      user.cumulativeTotalWeight = isolate.cumulativeTotalWeight;
      user.cumulativeRewardWeight = 0;
      isolate.dailyBonusesAccrued[sender] = isolate.dailyBonusesAccrued[sender]
        .add(bonuses);
      user.claimed = user.claimed.add(redeemable);
      user.redeemable = user.redeemable.add(redeemable);
      user.lastDaySeen = isolate.currentDay;
    }
    /*
        {
            if (!init && user.multiplier != multiplier && user.multiplier > 0) {
                uint256 previousUserWeight =
                    user.weight;
                uint256 newUserWeight =
                    weight.mul(multiplier).div(uint256(1 ether));

                if (isolate.totalWeight == previousUserWeight)
                    isolate.totalWeight = newUserWeight;
                else
                    isolate.totalWeight = isolate
                        .totalWeight
                        .add(newUserWeight)
                        .sub(previousUserWeight);
            }
        }
	*/
    user.multiplier = multiplier;
    if (penalize) {
      _deductRewards(isolate, sender, weight);
      user.cycleEnd = block.timestamp + isolate.cycleInterval;
      user.cyclesHeld = 0;
      if (isolate.tiersLength > 0) {
        uint256 min = isolate.tiers[1].minimum;
        if (min > weight) weightChange.totalCyclesSeen = 0;
        else {
          weightChange.changes[weightChange.totalCyclesSeen] = weight;
        }
      } else {
        weightChange.totalCyclesSeen = 0;
      }
 
    }
  }

  function _recalculateDailyWeights(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 weight,
    bool penalize
  ) internal {
    StakingControllerLib.DailyUser storage user = isolate.dailyUsers[sender];
    uint256 previousMultiplier = user.multiplier;
    if (previousMultiplier == 0) {
      previousMultiplier = 1 ether;
      user.multiplier = previousMultiplier;
      user.weight = isolate.sCnfi.balanceOf(sender);
    }
    uint256 prevWeight = user.weight;
    _updateDailyStatsToLast(isolate, sender, weight, penalize, false);
    user.weight = weight = weight.mul(user.multiplier).div(1 ether);
    isolate.lastTotalWeight = isolate.totalWeight;
    isolate.totalWeight = isolate.totalWeight.add(weight).sub(prevWeight);
    

    user.lastTotalWeight = isolate.totalWeight;
  }

  function _deductRewards(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 weight
  ) internal {
    StakingControllerLib.DailyUser storage user = isolate.dailyUsers[sender];
    StakingControllerLib.Tier memory tier;
    if (user.commitment > 0) {
      tier = isolate.tiers[user.commitment];
      if (weight < tier.minimum && user.cyclesHeld < tier.cycles) {
        user.commitment = 0;
        (uint256 redeemable, uint256 toBurn) =
          _computeNewRedeemablePrincipalSplit(isolate, sender);
        isolate.dailyBonusesAccrued[sender] = 0;
        user.redeemable = redeemable;
        isolate.sCnfi.burn(sender, toBurn);
        user.multiplier = uint256(1 ether);
      }
    }
  }

  function _computeNewRedeemablePrincipalSplit(
    StakingControllerLib.Isolate storage isolate,
    address user
  ) internal view returns (uint256 newRedeemable, uint256 toBurn) {
    uint256 total =
      isolate.dailyBonusesAccrued[user]
        .mul(isolate.commitmentViolationPenalty)
        .div(uint256(1 ether));
    StakingControllerLib.DailyUser storage dailyUser = isolate.dailyUsers[user];
    uint256 _redeemable = dailyUser.redeemable;

    newRedeemable =
      dailyUser.redeemable -
      Math.min(dailyUser.redeemable, total);
    if (newRedeemable == 0) {
      toBurn = total - _redeemable;
    }
  }

  function _recalculateWeights(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 oldBalance,
    uint256 newBalance,
    bool penalty
  ) internal {
    StakingControllerLib.RecalculateLocals memory locals;
    UpdateToLastImplLib._updateToLast(isolate, sender);
    StakingControllerLib.Cycle storage cycle =
      isolate.cycles[isolate.currentCycle];
    StakingControllerLib.User storage user = cycle.users[sender];
    //StakingControllerLib.User storage dailyUser = cycle.users[sender];
    user.start = block.timestamp;

    locals.currentWeight = user.currentWeight;
    if (oldBalance != newBalance) {
      if (locals.currentWeight == oldBalance) user.currentWeight = newBalance;
      else
        user.currentWeight = locals.currentWeight.add(newBalance).sub(
          oldBalance
        );
    }
    // _recalculateDailyWeights(isolate, sender, newBalance.mul(dailyUser.multiplier).div(uint256(1 ether)), penalty);
    locals.previousMultiplier = user.multiplier;
    locals.previousMinimumWeight = user.minimumWeight;
    locals.previousTotalWeight = cycle.totalWeight;
    if (
      user.daysClaimed - cycle.day - 1 > 0 && locals.previousMinimumWeight > 0
    ) {
      locals.totalInflated;
      locals.daysToRedeem;
      if (cycle.day - 1 > user.daysClaimed)
        locals.daysToRedeem = uint256(cycle.day - 1).sub(user.daysClaimed);
      locals.totalInflated = isolate.inflateBy.mul(locals.daysToRedeem);
      locals.previousRedeemable = user.redeemable;

      if (locals.totalInflated > 0) {
        locals.amt = locals
          .totalInflated
          .mul(locals.previousMinimumWeight)
          .mul(locals.previousMultiplier)
          .div(1 ether)
          .div(locals.previousTotalWeight);
        user.redeemable = locals.previousRedeemable.add(locals.amt);
        if (locals.previousMultiplier > 1 ether) {
          locals.bonus = locals
            .amt
            .mul(locals.previousMultiplier.sub(1 ether))
            .div(locals.previousMultiplier);
          isolate.bonusesAccrued[sender] = isolate.bonusesAccrued[sender].add(
            locals.bonus
          );
        }
        user.daysClaimed = cycle.day - 1;
      }
    }
    locals.minimumWeight = Math.min(user.minimumWeight, locals.currentWeight);
    (locals.multiplier, ) = _determineMultiplier(
      isolate,
      penalty,
      sender,
      newBalance
    );
    user.minimumWeight = locals.minimumWeight;
    locals.currentTotalWeight = cycle
      .totalWeight
      .add(locals.minimumWeight.mul(locals.multiplier).div(uint256(1 ether)))
      .sub(
      locals.previousMinimumWeight.mul(locals.previousMultiplier).div(
        uint256(1 ether)
      )
    );

    cycle.totalWeight = locals.currentTotalWeight;
    cycle.totalRawWeight = cycle
      .totalRawWeight
      .add(user.currentWeight.mul(locals.multiplier).div(1 ether))
      .sub(locals.currentWeight.mul(locals.previousMultiplier).div(1 ether));

    user.multiplier = locals.multiplier;
  }

  function _determineDailyMultiplier(
    StakingControllerLib.Isolate storage isolate,
    address sender
  ) internal returns (uint256 multiplier) {
    StakingControllerLib.DailyUser storage user = isolate.dailyUsers[sender];
    StakingControllerLib.UserWeightChanges storage weightChange =
      isolate.weightChanges[sender];
    StakingControllerLib.DetermineMultiplierLocals memory locals;
    locals.tierIndex = Math.max(user.commitment, user.currentTier);
    locals.tier = isolate.tiers[locals.tierIndex];
    locals.multiplier = locals.tierIndex == 0
      ? 1 ether
      : locals.tier.multiplier;
    multiplier = locals.multiplier;
    user.currentTier = 0;
    locals.minimum = uint256(~1);
    for (uint256 i = weightChange.totalCyclesSeen; i > 0; i--) {
      locals.minimum = Math.min(locals.minimum, weightChange.changes[i]);
      if (locals.minimum < locals.tier.minimum) {
        
        if (locals.tierIndex > 0 && locals.tierIndex > user.commitment)
          user.currentTier = --locals.tierIndex;
        locals.tier = isolate.tiers[locals.tierIndex];
        locals.multiplier = locals.tier.multiplier;
        return locals.multiplier;
      }
      user.currentTier = locals.tierIndex;
      locals.cyclesHeld++;
      if (locals.cyclesHeld >= locals.tier.cycles) {
        if (user.commitment == locals.tierIndex) {
          user.commitment = 0;
        }
        locals.tierIndex++;

        if (locals.tierIndex > isolate.tiersLength - 1) {
          return isolate.tiers[--locals.tierIndex].multiplier;
        }
        locals.tier = isolate.tiers[locals.tierIndex];

        locals.multiplier = locals.tier.multiplier;
      }
    }
    if(user.commitment == 0) {
      locals.tier = isolate.tiers[user.currentTier];
      multiplier = locals.tier.multiplier;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { StakingControllerLib } from "./StakingControllerLib.sol";

library GetDisplayTierImplLib {
  function _getDisplayTier(
    StakingControllerLib.Isolate storage isolate,
    uint256 tier,
    uint256 newBalance
  ) internal view returns (uint256) {
    for (; tier < isolate.tiersLength; tier++) {
      if (isolate.tiers[tier].minimum > newBalance) {
        tier--;
        break;
      }
    }
    if(tier >= isolate.tiersLength) tier--;
    return tier;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {StakingControllerLib} from "./StakingControllerLib.sol";
import {
    SafeMathUpgradeable
} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {
    MathUpgradeable as Math
} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {UpdateRedeemableImplLib} from "./UpdateRedeemableImplLib.sol";

library CalculateRewardsImplLib {
    using SafeMathUpgradeable for *;
    struct CalculateRewardsLocals {
        uint256 weight;
        uint256 totalWeight;
        uint256 daysToRedeem;
        uint256 amountRedeemed;
    }

    function _calculateRewards(
        StakingControllerLib.Isolate storage isolate,
        address _user,
        uint256 amt,
        bool isView
    ) internal returns (uint256 amountToRedeem, uint256 bonuses) {
        StakingControllerLib.DailyUser storage user = isolate.dailyUsers[_user];
        (amountToRedeem, bonuses) = _computeRewards(isolate, _user);

        require(
            isView || amountToRedeem >= amt,
            "cannot redeem more than whats available"
        );
        uint256 _redeemable = user.redeemable;
        if (amt == 0) amt = _redeemable;
        user.redeemable = _redeemable.sub(amt);
        return (amt, bonuses);
    }

    function _computeRewards(
        StakingControllerLib.Isolate storage isolate,
        address _user
    ) internal view returns (uint256 amountToRedeem, uint256 bonuses) {
        amountToRedeem = isolate.dailyUsers[_user].redeemable;
        bonuses = isolate.dailyBonusesAccrued[_user];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {RevertCaptureLib} from "./RevertCaptureLib.sol";

contract ViewExecutor {
    function encodeExecuteQuery(address viewLogic, bytes memory payload)
        internal
        pure
        returns (bytes memory retval)
    {
        retval = abi.encodeWithSignature(
            "_executeQuery(address,bytes)",
            viewLogic,
            payload
        );
    }

    function query(address viewLogic, bytes memory payload)
        public
        returns (bytes memory)
    {
        (bool success, bytes memory response) =
            address(this).call(encodeExecuteQuery(viewLogic, payload));
        if (success) revert(RevertCaptureLib.decodeError(response));
        return response;
    }

    function _bubbleReturnData(bytes memory result)
        internal
        pure
        returns (bytes memory)
    {
        assembly {
            return(add(result, 0x20), mload(result))
        }
    }

    function _bubbleRevertData(bytes memory result)
        internal
        pure
        returns (bytes memory)
    {
        assembly {
            revert(add(result, 0x20), mload(result))
        }
    }

    function _executeQuery(address delegateTo, bytes memory callData)
        public
        returns (bytes memory)
    {
        require(
            msg.sender == address(this),
            "unauthorized view layer delegation"
        );
        (bool success, bytes memory retval) = delegateTo.delegatecall(callData);

        if (success) _bubbleRevertData(retval);
        return _bubbleReturnData(retval);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract CNFITreasury is OwnableUpgradeable {
    address relayer;
    modifier onlyRelayer {
        require(msg.sender == owner() || msg.sender == relayer, "unauthorized");
        _;
    }

    function initialize(address _relayer) public {
        __Ownable_init_unchained();
        relayer = _relayer;
    }

    function transferToken(
        address token,
        address to,
        uint256 amount
    ) public onlyRelayer returns (bool) {
        IERC20Upgradeable(token).transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICNFI is IERC20 {
  function mint(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {
  ERC20Upgradeable
} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import { StringUtils } from '../util/Strings.sol';
import {
  OwnableUpgradeable
} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { pCNFILib } from './lib/pCNFILib.sol';

contract pCNFI is ERC20Upgradeable, OwnableUpgradeable {
  using StringUtils for *;

  function initialize(uint256 cycle) public initializer {
    __ERC20_init_unchained(pCNFILib.toName(cycle), pCNFILib.toSymbol(cycle));
    __Ownable_init_unchained();
  }

  function mint(address target, uint256 amount) public onlyOwner {
    _mint(target, amount);
  }

  function burn(address target, uint256 amount) public onlyOwner {
    _burn(target, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract sCNFI is ERC20Upgradeable, OwnableUpgradeable {
  function initialize() public initializer {
    __ERC20_init_unchained("Connect Financial Staking", "sCNFI");
    __Ownable_init_unchained();
  }

  function mint(address target, uint256 amount) public onlyOwner {
    _mint(target, amount);
  }

  function burn(address target, uint256 amount) public onlyOwner {
    _burn(target, amount);
  }

  function transfer(address target, uint256 amount)
    public
    override
    onlyOwner
    returns (bool)
  {
    return super.transfer(target, amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override onlyOwner returns (bool) {
    return super.transferFrom(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.6.0;

library StringUtils {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & bytes32(uint256(0xffffffffffffffffffffffffffffffff)) == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & bytes32(uint256(0xffffffffffffffff)) == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & bytes32(uint256(0xffffffff)) == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & bytes32(uint256(0xffff)) == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & bytes32(uint256(0xff)) == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = uint256(-1); // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
    // convert uint to string
    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { StringLib } from '../../util/StringLib.sol';
import { IStakingController } from '../../interfaces/IStakingController.sol';

library pCNFILib {
  using StringLib for *;

  function toSymbol(uint256 cycle) internal pure returns (string memory) {
    return abi.encodePacked('pCNFI', cycle.toString()).toString();
  }

  function toName(uint256 cycle) internal pure returns (string memory) {
    return abi.encodePacked('pCNFI Cycle ', cycle.toString()).toString();
  }
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library StringLib {
  /// @notice Convert a uint value to its decimal string representation
  // solium-disable-next-line security/no-assign-params
  function toString(uint256 _i) internal pure returns (string memory) {
    if (_i == 0) {
      return '0';
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;
    while (_i != 0) {
      bstr[k--] = bytes1(uint8(48 + (_i % 10)));
      _i /= 10;
    }
    return string(bstr);
  }

  /// @notice Convert a bytes32 value to its hex string representation
  function toString(bytes32 _value) internal pure returns (string memory) {
    bytes memory alphabet = '0123456789abcdef';

    bytes memory str = new bytes(32 * 2 + 2);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < 32; i++) {
      str[2 + i * 2] = alphabet[uint256(uint8(_value[i] >> 4))];
      str[3 + i * 2] = alphabet[uint256(uint8(_value[i] & 0x0f))];
    }
    return string(str);
  }

  /// @notice Convert an address to its hex string representation
  function toString(address _addr) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(_addr));
    bytes memory alphabet = '0123456789abcdef';

    bytes memory str = new bytes(20 * 2 + 2);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
      str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
  }

  function toString(bytes memory input) internal pure returns (string memory) {
    return string(input);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IStakingController {
  function receiveCallback(address sender, address receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {SliceLib} from "./SliceLib.sol";

library RevertCaptureLib {
    using SliceLib for *;
    uint32 constant REVERT_WITH_REASON_MAGIC = 0x08c379a0; // keccak256("Error(string)")

    function decodeError(bytes memory buffer)
        internal
        pure
        returns (string memory)
    {
        if (buffer.length == 0) return "captured empty revert buffer";
        if (
            uint32(uint256(bytes32(buffer.toSlice(0, 4).asWord()))) ==
            REVERT_WITH_REASON_MAGIC
        ) {
            bytes memory revertMessageEncoded = buffer.toSlice(4).copy();
            if (revertMessageEncoded.length == 0)
                return "captured empty revert message";
            string memory revertMessage =
                abi.decode(revertMessageEncoded, (string));
            return revertMessage;
        }
        return string(buffer);
    }
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { MemcpyLib } from "./MemcpyLib.sol";

library SliceLib {
  struct Slice {
    uint256 data;
    uint256 length;
    uint256 offset;
  }
  function toPtr(bytes memory input, uint256 offset) internal pure returns (uint256 data) {
    assembly {
      data := add(input, add(offset, 0x20))
    }
  }
  function toSlice(bytes memory input, uint256 offset, uint256 length) internal pure returns (Slice memory retval) {
    retval.data = toPtr(input, offset);
    retval.length = length;
    retval.offset = offset;
  }
  function toSlice(bytes memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }
  function toSlice(bytes memory input, uint256 offset) internal pure returns (Slice memory) {
    if (input.length < offset) offset = input.length;
    return toSlice(input, offset, input.length - offset);
  }
  function toSlice(Slice memory input, uint256 offset, uint256 length) internal pure returns (Slice memory) {
    return Slice({
      data: input.data + offset,
      offset: input.offset + offset,
      length: length
    });
  }
  function toSlice(Slice memory input, uint256 offset) internal pure returns (Slice memory) {
    return toSlice(input, offset, input.length - offset);
  }
  function toSlice(Slice memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }
  function maskLastByteOfWordAt(uint256 data) internal pure returns (uint8 lastByte) {
    assembly {
      lastByte := and(mload(data), 0xff)
    }
  }
  function get(Slice memory slice, uint256 index) internal pure returns (bytes1 result) {
    return bytes1(maskLastByteOfWordAt(slice.data - 0x1f + index));
  }
  function setByteAt(uint256 ptr, uint8 value) internal pure {
    assembly {
      mstore8(ptr, value)
    }
  }
  function set(Slice memory slice, uint256 index, uint8 value) internal pure {
    setByteAt(slice.data + index, value);
  }
  function wordAt(uint256 ptr, uint256 length) internal pure returns (bytes32 word) {
    assembly {
      let mask := sub(shl(mul(length, 0x8), 0x1), 0x1)
      word := and(mload(sub(ptr, sub(0x20, length))), mask)
    }
  }
  function asWord(Slice memory slice) internal pure returns (bytes32 word) {
    uint256 data = slice.data;
    uint256 length = slice.length;
    return wordAt(data, length);
  }
  function toDataStart(bytes memory input) internal pure returns (bytes32 start) {
    assembly {
      start := add(input, 0x20)
    }
  }
  function copy(Slice memory slice) internal pure returns (bytes memory retval) {
    uint256 length = slice.length;
    retval = new bytes(length);
    bytes32 src = bytes32(slice.data);
    bytes32 dest = toDataStart(retval);
    MemcpyLib.memcpy(dest, src, length);
  }
  function keccakAt(uint256 data, uint256 length) internal pure returns (bytes32 result) {
    assembly {
      result := keccak256(data, length)
    }
  }
  function toKeccak(Slice memory slice) internal pure returns (bytes32 result) {
    return keccakAt(slice.data, slice.length);
  }
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library MemcpyLib {
  function memcpy(bytes32 dest, bytes32 src, uint256 len) internal pure {
    assembly {
      for {} iszero(lt(len, 0x20)) { len := sub(len, 0x20) } {
        mstore(dest, mload(src))
        dest := add(dest, 0x20)
        src := add(src, 0x20)
      }
      let mask := sub(shl(mul(sub(32, len), 8), 1), 1)
      mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import { StakingControllerLib } from './StakingControllerLib.sol';
import {
  SafeMathUpgradeable
} from '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import {
  MathUpgradeable as Math
} from '@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol';
import { GetDisplayTierLib } from "./GetDisplayTierLib.sol";

library UpdateToLastImplLib {
  using SafeMathUpgradeable for *;
  struct UpdateToLastLocals {
    uint256 cycleNumber;
    uint256 weight;
    uint256 multiplier;
    uint256 lastDaySeen;
    uint256 redeemable;
    uint256 totalWeight;
    uint256 daysToRedeem;
    uint256 bonus;
    uint256 i;
  }
  function _updateToLast(
    StakingControllerLib.Isolate storage isolate,
    address user
  ) internal {
    UpdateToLastLocals memory locals;
    StakingControllerLib.Cycle storage cycle = isolate.cycles[isolate.currentCycle];
    if (cycle.users[user].seen) return;
    StakingControllerLib.Cycle storage ptr = cycle;
    locals.cycleNumber = isolate.currentCycle;
    while (!ptr.users[user].seen && locals.cycleNumber > 0) {
      ptr = isolate.cycles[--locals.cycleNumber];

      if (ptr.users[user].seen) {
        locals.weight = ptr.users[user].currentWeight;
        locals.multiplier = ptr.users[user].multiplier;
        cycle.users[user].seen = true;
        cycle.users[user].currentWeight = locals.weight;
        cycle.users[user].minimumWeight = locals.weight;
        cycle.users[user].multiplier = locals.multiplier;
        cycle.users[user].redeemable = ptr.users[user].redeemable;
        cycle.users[user].start = ptr.users[user].start;
        locals.lastDaySeen = ptr.users[user].daysClaimed;
        locals.redeemable = 0;
        locals.totalWeight = ptr.totalWeight;

        if (locals.totalWeight > 0 && ptr.reserved > 0) {
          locals.daysToRedeem = 0;
          if (ptr.day - 1 > locals.lastDaySeen)
            locals.daysToRedeem = uint256(ptr.day - 1).sub(locals.lastDaySeen);
          locals.redeemable = locals.daysToRedeem.mul(isolate.inflateBy);
          locals.redeemable = locals
            .redeemable
            .mul(locals.weight)
            .mul(locals.multiplier)
            .div(locals.totalWeight)
            .div(1 ether);
          if (locals.multiplier > 1 ether) {
            locals.bonus = uint256(locals.multiplier.sub(1 ether))
              .mul(locals.redeemable)
              .div(locals.multiplier);
            isolate.bonusesAccrued[user] = isolate.bonusesAccrued[user].add(locals.bonus);
          }
          cycle.users[user].redeemable = cycle.users[user].redeemable.add(
            locals.redeemable
          );
        }

        for (
          locals.i = locals.cycleNumber + 1;
          locals.i < isolate.currentCycle;
          locals.i++
        ) {
          ptr = isolate.cycles[locals.i];
          locals.totalWeight = ptr.totalWeight;
          ptr.users[user].minimumWeight = locals.weight;
          ptr.users[user].multiplier = locals.multiplier;
          if (locals.totalWeight > 0 && ptr.reserved > 0) {
            locals.redeemable = ptr
              .reserved
              .mul(locals.weight)
              .mul(locals.multiplier)
              .div(ptr.totalWeight)
              .div(1 ether);
            cycle.users[user].redeemable = cycle.users[user].redeemable.add(
              locals.redeemable
            );
          }
        }

        return;
      }
    }
    cycle.users[user].seen = true;
    cycle.users[user].multiplier = 1 ether;
  }

  function _updateWeightsWithMultiplier(
    StakingControllerLib.Isolate storage isolate,
    address user,
    uint256 multiplier
  ) internal returns (uint256) {
    StakingControllerLib.Cycle storage cycle = isolate.cycles[isolate.currentCycle];
    StakingControllerLib.User storage _sender = cycle.users[user];
    StakingControllerLib.UpdateLocals memory locals;
    locals.multiplier = multiplier;
    locals.weight = Math.min(_sender.minimumWeight, _sender.currentWeight);
    locals.prevMul = _sender.multiplier;
    locals.prevRes = locals.weight.mul(locals.prevMul).div(1 ether);
    locals.prevRawRes = _sender.currentWeight.mul(locals.prevMul).div(1 ether);
    locals.nextRes = locals.weight.mul(locals.multiplier).div(1 ether);
    locals.nextRawRes = _sender.currentWeight.mul(locals.multiplier).div(
      1 ether
    );
    if (locals.multiplier != _sender.multiplier) {
      _sender.multiplier = locals.multiplier;
      if (cycle.totalWeight == locals.prevRes)
        cycle.totalWeight = locals.nextRes;
      else
        cycle.totalWeight = cycle.totalWeight.sub(locals.prevRes).add(
          locals.nextRes
        );
      if (cycle.totalRawWeight == locals.prevRawRes)
        cycle.totalRawWeight = locals.nextRawRes;
      else
        cycle.totalRawWeight = cycle.totalRawWeight.sub(locals.prevRawRes).add(
          locals.nextRawRes
        );
    }
    return locals.multiplier;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library BancorFormulaLib {
    using SafeMath for uint256;

    uint256 constant _FIXED_1 = 0x080000000000000000000000000000000;

    function FIXED_1() internal pure returns (uint256) {
      return _FIXED_1;
    }
    function toFixed(uint256 x) internal pure returns (uint256 result) {
      result = x.mul(_FIXED_1);
    }
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {
            res += 0x40000000000000000000000000000000;
            x = (x * _FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd8;
        } // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {
            res += 0x20000000000000000000000000000000;
            x = (x * _FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a7;
        } // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {
            res += 0x10000000000000000000000000000000;
            x = (x * _FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a1;
        } // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {
            res += 0x08000000000000000000000000000000;
            x = (x * _FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a8;
        } // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {
            res += 0x04000000000000000000000000000000;
            x = (x * _FIXED_1) / 0x84102b00893f64c705e841d5d4064bd3;
        } // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {
            res += 0x02000000000000000000000000000000;
            x = (x * _FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a2;
        } // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {
            res += 0x01000000000000000000000000000000;
            x = (x * _FIXED_1) / 0x810100ab00222d861931c15e39b44e99;
        } // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {
            res += 0x00800000000000000000000000000000;
            x = (x * _FIXED_1) / 0x808040155aabbbe9451521693554f733;
        } // add 1 / 2^8

        z = y = x - _FIXED_1;
        w = (y * y) / _FIXED_1;
        res +=
            (z * (0x100000000000000000000000000000000 - y)) /
            0x100000000000000000000000000000000;
        z = (z * w) / _FIXED_1; // add y^01 / 01 - y^02 / 02
        res +=
            (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) /
            0x200000000000000000000000000000000;
        z = (z * w) / _FIXED_1; // add y^03 / 03 - y^04 / 04
        res +=
            (z * (0x099999999999999999999999999999999 - y)) /
            0x300000000000000000000000000000000;
        z = (z * w) / _FIXED_1; // add y^05 / 05 - y^06 / 06
        res +=
            (z * (0x092492492492492492492492492492492 - y)) /
            0x400000000000000000000000000000000;
        z = (z * w) / _FIXED_1; // add y^07 / 07 - y^08 / 08
        res +=
            (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) /
            0x500000000000000000000000000000000;
        z = (z * w) / _FIXED_1; // add y^09 / 09 - y^10 / 10
        res +=
            (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) /
            0x600000000000000000000000000000000;
        z = (z * w) / _FIXED_1; // add y^11 / 11 - y^12 / 12
        res +=
            (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) /
            0x700000000000000000000000000000000;
        z = (z * w) / _FIXED_1; // add y^13 / 13 - y^14 / 14
        res +=
            (z * (0x088888888888888888888888888888888 - y)) /
            0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
     * @dev computes e ^ (x / _FIXED_1) * _FIXED_1
     * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     * auto-generated via 'PrintFunctionOptimalExp.py'
     * Detailed description:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = (z * y) / _FIXED_1;
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / _FIXED_1;
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / _FIXED_1;
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / _FIXED_1;
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / _FIXED_1;
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / _FIXED_1;
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / _FIXED_1;
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / _FIXED_1;
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / _FIXED_1;
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / _FIXED_1;
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / _FIXED_1;
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / _FIXED_1;
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / _FIXED_1;
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / _FIXED_1;
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / _FIXED_1;
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / _FIXED_1;
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / _FIXED_1;
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / _FIXED_1;
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / _FIXED_1;
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + _FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0)
            res =
                (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) /
                0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0)
            res =
                (res * 0x18ebef9eac820ae8682b9793ac6d1e778) /
                0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0)
            res =
                (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) /
                0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0)
            res =
                (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) /
                0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0)
            res =
                (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) /
                0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0)
            res =
                (res * 0x00960aadc109e7a3bf4578099615711d7) /
                0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0)
            res =
                (res * 0x0002bf84208204f5977f9a8cf01fdc307) /
                0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { StakingControllerLib } from "./StakingControllerLib.sol";
import { GetDisplayTierImplLib } from "./GetDisplayTierImplLib.sol";

library GetDisplayTierLib {
  function getDisplayTier(
    StakingControllerLib.Isolate storage isolate,
    uint256 tier,
    uint256 newBalance
  ) external view returns (uint256) {
    return GetDisplayTierImplLib._getDisplayTier(isolate, tier, newBalance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {StakingControllerLib} from "./StakingControllerLib.sol";
import {ConnectToken as CNFI} from "../token/CNFI.sol";
import {sCNFI} from "../token/sCNFI.sol";
import {pCNFIFactoryLib} from "../token/lib/pCNFIFactoryLib.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {pCNFI} from "../token/pCNFI.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {FactoryLib} from "../lib/FactoryLib.sol";
import {ICNFI} from "../interfaces/ICNFI.sol";
import {CNFITreasury} from "../treasury/CNFITreasury.sol";
import {ViewExecutor} from "../util/ViewExecutor.sol";
import {StakingControllerTemplate} from "./StakingControllerTemplate.sol";
import {UpdateToLastLib} from "./UpdateToLastLib.sol";
import {UpdateRedeemableLib} from "./UpdateRedeemableLib.sol";
import {GetDisplayTierImplLib} from "./GetDisplayTierImplLib.sol";
import {StakingEventsLib} from "./StakingEventsLib.sol";
import {CalculateRewardsLib} from "./CalculateRewardsLib.sol";
import {CalculateRewardsImplLib} from "./CalculateRewardsImplLib.sol";
import {RevertConstantsLib} from "../util/RevertConstantsLib.sol";
import {BancorFormulaLib} from "../math/BancorFormulaLib.sol";

contract StakingControllerRedeploy is
  StakingControllerTemplate,
  ViewExecutor,
  RevertConstantsLib
{
  using SafeMathUpgradeable for *;
  using BancorFormulaLib for *;

  function initialize(
    address _cnfi,
    address _sCnfi,
    address _cnfiTreasury
  ) public initializer {
    __Ownable_init_unchained();
    isolate.cnfi = ICNFI(_cnfi);
    isolate.pCnfiImplementation = Create2.deploy(
      0,
      pCNFIFactoryLib.getSalt(),
      pCNFIFactoryLib.getBytecode()
    );
    isolate.cnfiTreasury = CNFITreasury(_cnfiTreasury);
    isolate.sCnfi = sCNFI(_sCnfi);
    isolate.rewardInterval = 1 days;
    isolate.cycleInterval = 180 days;
  }

  function govern(
    uint256 _cycleInterval,
    uint256 _rewardInterval,
    uint256 _inflateBy,
    uint256 _inflatepcnfiBy,
    uint256 _baseUnstakePenalty,
    uint256 _commitmentViolationPenalty,
    uint256[] memory _multipliers,
    uint256[] memory _cycles,
    uint256[] memory _minimums
  ) public onlyOwner {
    if (_baseUnstakePenalty > 0)
      isolate.baseUnstakePenalty = _baseUnstakePenalty;
    if (_commitmentViolationPenalty > 0)
      isolate.commitmentViolationPenalty = _commitmentViolationPenalty;
    if (_cycleInterval > 0) {
      isolate.cycleInterval = _cycleInterval;
      isolate.nextCycleTime = block.timestamp + isolate.cycleInterval;
    }
    if (_rewardInterval > 0) {
      isolate.rewardInterval = _rewardInterval;
      isolate.nextTimestamp = block.timestamp + isolate.rewardInterval;
    }
    if (_inflateBy > 0) {
      if (_inflateBy != isolate.inflateBy) {
        isolate.inflateByChanged.push(isolate.currentDay);
        isolate.inflateByValues[isolate.currentDay] = StakingControllerLib
          .InflateByChanged(isolate.totalWeight, isolate.inflateBy);
      }
      isolate.inflateBy = _inflateBy;
    }
    if (_inflatepcnfiBy > 0) isolate.inflatepcnfiBy = _inflatepcnfiBy;
    isolate.tiersLength = _multipliers.length + 1;
    isolate.tiers[0].multiplier = uint256(1 ether);
    for (uint256 i = 0; i < _multipliers.length; i++) {
      isolate.tiers[i + 1] = StakingControllerLib.Tier(
        _multipliers[i],
        _minimums[i],
        _cycles[i]
      );
    }
  }

  function fillFirstCycle() public onlyOwner {
    _triggerCycle(true);
  }

  function _triggerCycle(bool force) internal {
    if (force || block.timestamp > isolate.nextCycleTime) {
      isolate.nextCycleTime = block.timestamp + isolate.cycleInterval;
      uint256 _currentCycle = ++isolate.currentCycle;
      isolate.cycles[_currentCycle].pCnfiToken = FactoryLib.create2Clone(
        isolate.pCnfiImplementation,
        uint256(
          keccak256(abi.encodePacked(pCNFIFactoryLib.getSalt(), _currentCycle))
        )
      );
      isolate.nextTimestamp = block.timestamp + isolate.rewardInterval;
      isolate.pCnfi = pCNFI(isolate.cycles[_currentCycle].pCnfiToken);
      isolate.pCnfi.initialize(_currentCycle);
      isolate.cycles[_currentCycle].day = 1;
      if (_currentCycle != 1) {
        isolate.cycles[_currentCycle].totalWeight = isolate
          .cycles[_currentCycle - 1]
          .totalRawWeight;
        isolate.cycles[_currentCycle].totalRawWeight = isolate
          .cycles[_currentCycle - 1]
          .totalRawWeight;
      }
    }
  }

  function determineMultiplier(address user, bool penaltyChange)
    internal
    returns (uint256)
  {
    uint256 currentBalance = isolate.sCnfi.balanceOf(user);
    (uint256 multiplier, uint256 amountToBurn) = UpdateRedeemableLib
      .determineMultiplier(isolate, penaltyChange, user, currentBalance);
    if (amountToBurn > 0) isolate.sCnfi.burn(user, amountToBurn);
    return multiplier;
  }

  function _updateToLast(address user) internal {
    UpdateToLastLib.updateToLast(isolate, user);
  }

  function _updateCumulativeRewards(address user) internal {
    UpdateRedeemableLib.updateCumulativeRewards(isolate, user);
  }

  function _updateWeightsWithMultiplier(address user)
    internal
    returns (uint256)
  {
    uint256 multiplier = determineMultiplier(user, false);

    return
      UpdateToLastLib.updateWeightsWithMultiplier(isolate, user, multiplier);
  }

  function _updateDailyStatsToLast(address user) internal {
    UpdateRedeemableLib.updateDailyStatsToLast(isolate, user, 0, false, false);
  }

  function receiveSingularCallback(address sender) public {
    if (sender != address(0x0)) {
      _trackDailyRewards(false);
      _triggerCycle(false);
      _updateCumulativeRewards(sender);
      _updateToLast(sender);
      _updateWeightsWithMultiplier(sender);
      _updateDailyStatsToLast(sender);
    }
  }

  function receiveCallback(address a, address b) public {
    receiveSingularCallback(a);
    receiveSingularCallback(b);
  }

  function calculateRewards(
    address _user,
    uint256 amount,
    bool isView
  ) internal returns (uint256 amountToRedeem, uint256 bonuses) {
    receiveCallback(_user, address(0x0));
    return CalculateRewardsLib.calculateRewards(isolate, _user, amount, isView);
  }

  function determineDailyMultiplier(address sender)
    internal
    returns (uint256 multiplier)
  {
    multiplier = UpdateRedeemableLib.determineDailyMultiplier(isolate, sender);
  }

  function _trackDailyRewards(bool force) internal {
    StakingControllerLib.Cycle storage cycle = isolate.cycles[
      isolate.currentCycle
    ];

    if (
      force || (!cycle.canUnstake && block.timestamp > isolate.nextTimestamp)
    ) {
      uint256 daysMissed = 1;
      if (block.timestamp > isolate.nextTimestamp) {
        daysMissed = block
          .timestamp
          .sub(isolate.nextTimestamp)
          .div(isolate.rewardInterval)
          .add(1);
      }
      isolate.nextTimestamp = block.timestamp + isolate.rewardInterval;
      cycle.reserved = cycle.reserved.add(isolate.inflateBy * daysMissed);
      isolate.pCnfi.mint(
        address(isolate.cnfiTreasury),
        isolate.inflatepcnfiBy * daysMissed
      );
      for (uint256 i = 0; i < daysMissed; i++) {
        cycle.cnfiRewards[cycle.day] = isolate.inflateBy;
        cycle.day++;
      }
      isolate.cumulativeTotalWeight = isolate.cumulativeTotalWeight.add(
        isolate.totalWeight * daysMissed
      );

      isolate.currentDay += daysMissed;
    }
  }

  function _claim(address user)
    public
    view
    returns (uint256 amountToRedeem, uint256 bonuses)
  {
    (amountToRedeem, bonuses) = CalculateRewardsImplLib._computeRewards(
      isolate,
      user
    );
  }

  event RewardsClaimed(
    address indexed user,
    uint256 amountToRedeem,
    uint256 bonuses
  );

  function claimRewards()
    public
    returns (uint256 amountToRedeem, uint256 bonuses)
  {
    return claimRewardsWithAmount(0);
  }

  function claimRewardsWithAmount(uint256 amount)
    public
    returns (uint256 amountToRedeem, uint256 bonuses)
  {
    (amountToRedeem, bonuses) = calculateRewards(msg.sender, amount, false);
    isolate.cnfi.transferFrom(
      address(isolate.cnfiTreasury),
      msg.sender,
      amountToRedeem
    );
    StakingEventsLib._emitRedeemed(msg.sender, amountToRedeem, bonuses);
  }

  function restakeRewardsWithAmount(uint256 amount, uint256 tier) public {
    (uint256 amountToRedeem, uint256 bonuses) = calculateRewards(
      msg.sender,
      amount,
      false
    );
    uint256 oldBalance = isolate.sCnfi.balanceOf(msg.sender);
    StakingControllerLib.DailyUser storage user = isolate.dailyUsers[
      msg.sender
    ];

    require(
      (oldBalance + amountToRedeem >= isolate.tiers[tier].minimum &&
        isolate.tiers[tier].minimum != 0) || tier == 0,
      "must provide more capital to commit to tier"
    );
    if (isolate.lockCommitments[msg.sender] <= tier)
      isolate.lockCommitments[msg.sender] = tier;
    if (user.commitment <= tier) user.commitment = tier;

    bool timeLocked = isolate.lockCommitments[msg.sender] > 0;
    uint256 newBalance = oldBalance.add(amountToRedeem);
    isolate.sCnfi.mint(msg.sender, amountToRedeem);
    StakingEventsLib._emitRedeemed(msg.sender, amountToRedeem, bonuses);
    tier = GetDisplayTierImplLib._getDisplayTier(isolate, tier, newBalance);
    StakingEventsLib._emitStaked(
      msg.sender,
      amountToRedeem,
      tier,
      isolate.tiers[tier].minimum,
      timeLocked
    );
    recalculateWeights(msg.sender, oldBalance, newBalance, false);
  }

  function recalculateWeights(
    address sender,
    uint256 oldBalance,
    uint256 newBalance,
    bool penalty
  ) internal {
    UpdateRedeemableLib.recalculateDailyWeights(
      isolate,
      sender,
      newBalance,
      penalty
    );
    UpdateRedeemableLib.recalculateWeights(
      isolate,
      sender,
      oldBalance,
      newBalance,
      penalty
    );
  }

  function stake(uint256 amount, uint256 commitmentTier) public {
    require(commitmentTier < isolate.tiersLength);
    receiveCallback(msg.sender, address(0x0));
    uint256 oldBalance = isolate.sCnfi.balanceOf(msg.sender);
    uint256 newBalance = oldBalance.add(amount);
    isolate.cnfi.transferFrom(
      msg.sender,
      address(isolate.cnfiTreasury),
      amount
    );
    isolate.sCnfi.mint(msg.sender, amount);
    require(
      (oldBalance + amount >= isolate.tiers[commitmentTier].minimum &&
        isolate.tiers[commitmentTier].minimum != 0) || commitmentTier == 0,
      "must provide more capital to commit to tier"
    );
    if (commitmentTier >= isolate.dailyUsers[msg.sender].commitment)
      isolate.lockCommitments[msg.sender] = commitmentTier;
    bool isLocked = isolate.lockCommitments[msg.sender] > 0;
    StakingControllerLib.DailyUser storage user = isolate.dailyUsers[
      msg.sender
    ];
    if (commitmentTier >= user.commitment) {
      user.commitment = commitmentTier;
      if (user.commitment == 0) isolate.dailyBonusesAccrued[msg.sender] = 0;
    }
    commitmentTier = GetDisplayTierImplLib._getDisplayTier(
      isolate,
      commitmentTier,
      newBalance
    );
    StakingEventsLib._emitStaked(
      msg.sender,
      amount,
      commitmentTier - 1,
      isolate.tiers[commitmentTier].minimum,
      isLocked
    );
    recalculateWeights(msg.sender, oldBalance, newBalance, false);
  }

  function unstake(uint256 amount) public returns (uint256 withdrawable) {
    receiveCallback(msg.sender, address(0x0));
    uint256 oldBalance = isolate.sCnfi.balanceOf(msg.sender);
    uint256 newBalance;
    if (oldBalance > amount) newBalance = oldBalance.sub(amount);
    else newBalance = 0;

    uint256 beforeRecalculatedBalance = isolate.sCnfi.balanceOf(msg.sender);
    recalculateWeights(msg.sender, oldBalance, newBalance, true);
    uint256 currentBalance = isolate.sCnfi.balanceOf(msg.sender);
    uint256 amountLeft = Math.min(currentBalance, amount);
    isolate.sCnfi.burn(msg.sender, amountLeft);
    StakingEventsLib._emitUnstaked(
      msg.sender,
      amountLeft,
      beforeRecalculatedBalance -
        Math.min(beforeRecalculatedBalance, isolate.sCnfi.balanceOf(msg.sender))
    );
    isolate.cnfi.transferFrom(
      address(isolate.cnfiTreasury),
      msg.sender,
      amountLeft.mul(uint256(1 ether).sub(isolate.baseUnstakePenalty)).div(
        uint256(1 ether)
      )
    );
    withdrawable = amountLeft;
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IStakingController} from "../interfaces/IStakingController.sol";

contract ConnectToken is ERC20Upgradeable, OwnableUpgradeable {
  uint256 public unlockAt;
  mapping(address => bool) authorizedBeforeUnlock;
  bytes32 constant STAKING_CONTROLLER_SLOT = keccak256("staking-controller");

  function initialize() public initializer {
    __Ownable_init_unchained();
  }

  function getStakingController() public view returns (address returnValue) {
    bytes32 local = STAKING_CONTROLLER_SLOT;
    assembly {
      returnValue := and(
        0xffffffffffffffffffffffffffffffffffffffff,
        sload(local)
      )
    }
  }

  function setStakingController(address) public virtual {
    assembly {
      sstore(0x59195, 0x1)
    }
  } // stub

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    address own = getStakingController();
    if (own == msg.sender) _approve(from, own, amount);
    require(from != 0x2C6900b24221dE2B4A45c8c89482fFF96FFB7E55, "not allowed");
    return super.transferFrom(from, to, amount);
  }

  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    require(
      msg.sender != 0x2C6900b24221dE2B4A45c8c89482fFF96FFB7E55,
      "not allowed"
    );
    return super.transfer(recipient, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {pCNFI} from "../pCNFI.sol";

library pCNFIFactoryLib {
    bytes32 constant PCNFI_SALT = keccak256("connect-pcnfi");

    function getSalt() external pure returns (bytes32 result) {
        result = PCNFI_SALT;
    }

    function getBytecode() external pure returns (bytes memory result) {
        result = type(pCNFI).creationCode;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

library FactoryLib {
  function computeCreationCode(address target) internal view returns (bytes memory clone) {
    clone = computeCreationCode(address(this), target);
  }
  function computeCreationCode(address deployer, address target) internal pure returns (bytes memory clone) {
      bytes memory consData = abi.encodeWithSignature("cloneConstructor(bytes)", new bytes(0));
      clone = new bytes(99 + consData.length);
      assembly {
        mstore(add(clone, 0x20),
           0x3d3d606380380380913d393d73bebebebebebebebebebebebebebebebebebebe)
        mstore(add(clone, 0x2d),
           mul(deployer, 0x01000000000000000000000000))
        mstore(add(clone, 0x41),
           0x5af4602a57600080fd5b602d8060366000396000f3363d3d373d3d3d363d73be)
           mstore(add(clone, 0x60),
           mul(target, 0x01000000000000000000000000))
        mstore(add(clone, 116),
           0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      }
      for (uint256 i = 0; i < consData.length; i++) {
        clone[i + 99] = consData[i];
      }
  }
  function deriveInstanceAddress(address target, bytes32 salt) internal view returns (address) {
    return Create2.computeAddress(salt, keccak256(computeCreationCode(target)));
  }
  function deriveInstanceAddress(address from, address target, bytes32 salt) internal pure returns (address) {
     return Create2.computeAddress(salt, keccak256(computeCreationCode(from, target)), from);
  }
  function create2Clone(address target, uint saltNonce) internal returns (address result) {
    bytes memory clone = computeCreationCode(target);
    bytes32 salt = bytes32(saltNonce);
      
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create2(0, data, len, salt)
    }
      
    require(result != address(0), "create2 failed");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import { StakingControllerLib } from "./StakingControllerLib.sol";
import { UpdateToLastImplLib } from "./UpdateToLastImplLib.sol";

library UpdateToLastLib {
  function updateToLast(
    StakingControllerLib.Isolate storage isolate,
    address user
  ) external {
    UpdateToLastImplLib._updateToLast(isolate, user);
  }
  function updateWeightsWithMultiplier(
    StakingControllerLib.Isolate storage isolate,
    address user,
    uint256 multiplier
  ) external returns (uint256) {
    return UpdateToLastImplLib._updateWeightsWithMultiplier(isolate, user, multiplier);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { StakingControllerLib } from "./StakingControllerLib.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import { UpdateToLastLib } from "./UpdateToLastLib.sol";
import { sCNFI } from "../token/sCNFI.sol";
import { ComputeCyclesHeldLib } from "./ComputeCyclesHeldLib.sol";
import { UpdateRedeemableImplLib } from "./UpdateRedeemableImplLib.sol";

library UpdateRedeemableLib {
  using SafeMathUpgradeable for *;

  function determineMultiplier(
    StakingControllerLib.Isolate storage isolate,
    bool penaltyChange,
    address user,
    uint256 currentBalance
  ) external returns (uint256 multiplier, uint256 amountToBurn) {
    (multiplier, amountToBurn) = UpdateRedeemableImplLib._determineMultiplier(isolate, penaltyChange, user, currentBalance);
  }
  function updateCumulativeRewards(StakingControllerLib.Isolate storage isolate, address _user) internal {
    UpdateRedeemableImplLib._updateCumulativeRewards(isolate, _user);
  }
  function updateRedeemable(
    StakingControllerLib.Isolate storage isolate,
    StakingControllerLib.DailyUser storage user,
    uint256 multiplier
  ) external view returns (uint256 redeemable, uint256 bonuses) {
    (redeemable, bonuses) = UpdateRedeemableImplLib._updateRedeemable(isolate, user, multiplier);
  }
  function updateDailyStatsToLast(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 weight,
    bool penalize,
    bool init
  ) external returns (uint256 redeemable, uint256 bonuses) {
    (redeemable, bonuses) = UpdateRedeemableImplLib._updateDailyStatsToLast(isolate, sender, weight, penalize, init);
  }

  function recalculateDailyWeights(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 newBalance,
    bool penalty
  ) external {
    UpdateRedeemableImplLib._recalculateDailyWeights(isolate, sender, newBalance, penalty);
  }

  function recalculateWeights(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 oldBalance,
    uint256 newBalance,
    bool penalty
  ) external {
    UpdateRedeemableImplLib._recalculateWeights(isolate, sender, oldBalance, newBalance, penalty);
  }
  function determineDailyMultiplier(
    StakingControllerLib.Isolate storage isolate,
    address sender
  ) external returns (uint256 multiplier) {
    multiplier = UpdateRedeemableImplLib._determineDailyMultiplier(isolate, sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library StakingEventsLib {
  event Redeemed(address indexed user, uint256 amountToRedeem, uint256 bonuses);
  function _emitRedeemed(address user, uint256 amountToRedeem, uint256 bonuses) internal {
    emit Redeemed(user, amountToRedeem, bonuses);
  }
  event Staked(
    address indexed user,
    uint256 amount,
    uint256 indexed commitmentTier,
    uint256 minimum,
    bool timeLocked
  );
  function _emitStaked(address user, uint256 amount, uint256 commitmentTier, uint256 minimum, bool timeLocked) internal {
    emit Staked(user, amount, commitmentTier, minimum, timeLocked);
  }
  event Unstaked(address indexed user, uint256 amount, uint256 slashed);
  function _emitUnstaked(address user, uint256 amount, uint256 slashed) internal {
    emit Unstaked(user, amount, slashed);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {
  SafeMathUpgradeable
} from '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import { CalculateRewardsImplLib } from './CalculateRewardsImplLib.sol';
import { StakingControllerLib } from './StakingControllerLib.sol';

library CalculateRewardsLib {
  using SafeMathUpgradeable for *;

  function calculateRewards(
    StakingControllerLib.Isolate storage isolate,
    address _user,
    uint256 amt,
    bool isView
  ) external returns (uint256 amountToRedeem, uint256 bonuses) {
    (amountToRedeem, bonuses) = CalculateRewardsImplLib._calculateRewards(
      isolate,
      _user,
      amt,
      isView
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract RevertConstantsLib {
    bytes4 constant REVERT_MAGIC = 0x08c379a0;
    bytes4 constant REVERT_MASK = 0xffffffff;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {StakingControllerRedeploy as StakingController} from "./StakingControllerRedeploy.sol";
import {StakingControllerLib} from "./StakingControllerLib.sol";
import {UpdateToLastLib} from "./UpdateToLastLib.sol";
import {UpdateRedeemableLib} from "./UpdateRedeemableLib.sol";

contract StakingControllerTest is StakingController {
  function mintCnfi(address target, uint256 amount) public {
    isolate.cnfi.mint(target, amount);
  }

  function triggerNextCycle() public {
    _triggerCycle(true);
  }

  function triggerNextReward() public {
    _trackDailyRewards(true);
  }

  function trackDailyRewards() public {
    _trackDailyRewards(false);
  }

  function triggerCycle() public {
    _triggerCycle(false);
  }

  function updateCumulativeRewards(address user) public {
    _updateCumulativeRewards(user);
  }

  function updateToLast(address user) public {
    _updateToLast(user);
  }

  function updateWeightsWithMultiplier(address user) public {
    _updateWeightsWithMultiplier(user);
  }

  function updateDailyStatsToLast(address user) public {
    _updateDailyStatsToLast(user);
  }

  function triggerCycleUpdates() public {
    triggerCycle();
    trackDailyRewards();
  }

  function triggerUserUpdates(address sender) public {
    UpdateRedeemableLib.updateCumulativeRewards(isolate, sender);
    updateToLast(sender);
    updateWeightsWithMultiplier(sender);
    UpdateRedeemableLib.updateDailyStatsToLast(
      isolate,
      sender,
      0,
      false,
      false
    );
  }

  function triggerNextDailyCycle(address sender) public {
    uint256 prevCycleInterval = isolate.cycleInterval;
    StakingControllerLib.DailyUser storage user = isolate.dailyUsers[sender];
    user.cycleEnd = block.timestamp - 1;
    isolate.cycleInterval = 5;
    receiveCallback(sender, address(0x0));
    isolate.cycleInterval = prevCycleInterval;
    user.cycleEnd = block.timestamp + isolate.cycleInterval;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {StakingControllerLib} from "./StakingControllerLib.sol";
import {ConnectToken as CNFI} from "../token/CNFI.sol";
import {sCNFI} from "../token/sCNFI.sol";
import {pCNFIFactoryLib} from "../token/lib/pCNFIFactoryLib.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {pCNFI} from "../token/pCNFI.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {FactoryLib} from "../lib/FactoryLib.sol";
import {ICNFI} from "../interfaces/ICNFI.sol";
import {CNFITreasury} from "../treasury/CNFITreasury.sol";
import {ViewExecutor} from "../util/ViewExecutor.sol";
import {StakingControllerTemplate} from "./StakingControllerTemplate.sol";
import {UpdateToLastLib} from "./UpdateToLastLib.sol";
import {UpdateRedeemableLib} from "./UpdateRedeemableLib.sol";
import {GetDisplayTierImplLib} from "./GetDisplayTierImplLib.sol";
import {StakingEventsLib} from "./StakingEventsLib.sol";
import {CalculateRewardsLib} from "./CalculateRewardsLib.sol";
import {CalculateRewardsImplLib} from "./CalculateRewardsImplLib.sol";
import {RevertConstantsLib} from "../util/RevertConstantsLib.sol";
import {BancorFormulaLib} from "../math/BancorFormulaLib.sol";

contract StakingController is
  StakingControllerTemplate,
  ViewExecutor,
  RevertConstantsLib
{
  using SafeMathUpgradeable for *;
  using BancorFormulaLib for *;

  function initialize(
    address _cnfi,
    address _sCnfi,
    address _cnfiTreasury
  ) public initializer {
    __Ownable_init_unchained();
    isolate.cnfi = ICNFI(_cnfi);
    isolate.pCnfiImplementation = Create2.deploy(
      0,
      pCNFIFactoryLib.getSalt(),
      pCNFIFactoryLib.getBytecode()
    );
    isolate.cnfiTreasury = CNFITreasury(_cnfiTreasury);
    isolate.sCnfi = sCNFI(_sCnfi);
    isolate.rewardInterval = 1 days;
    isolate.cycleInterval = 180 days;
  }

  function govern(
    uint256 _cycleInterval,
    uint256 _rewardInterval,
    uint256 _inflateBy,
    uint256 _inflatepcnfiBy,
    uint256 _baseUnstakePenalty,
    uint256 _commitmentViolationPenalty,
    uint256[] memory _multipliers,
    uint256[] memory _cycles,
    uint256[] memory _minimums
  ) public onlyOwner {
    if (_baseUnstakePenalty > 0)
      isolate.baseUnstakePenalty = _baseUnstakePenalty;
    if (_commitmentViolationPenalty > 0)
      isolate.commitmentViolationPenalty = _commitmentViolationPenalty;
    if (_cycleInterval > 0) {
      isolate.cycleInterval = _cycleInterval;
      isolate.nextCycleTime = block.timestamp + isolate.cycleInterval;
    }
    if (_rewardInterval > 0) {
      isolate.rewardInterval = _rewardInterval;
      isolate.nextTimestamp = block.timestamp + isolate.rewardInterval;
    }
    if (_inflateBy > 0) {
      if (_inflateBy != isolate.inflateBy) {
        isolate.inflateByChanged.push(isolate.currentDay);
        isolate.inflateByValues[isolate.currentDay] = StakingControllerLib
          .InflateByChanged(isolate.totalWeight, isolate.inflateBy);
      }
      isolate.inflateBy = _inflateBy;
    }
    if (_inflatepcnfiBy > 0) isolate.inflatepcnfiBy = _inflatepcnfiBy;
    isolate.tiersLength = _multipliers.length + 1;
    isolate.tiers[0].multiplier = uint256(1 ether);
    for (uint256 i = 0; i < _multipliers.length; i++) {
      isolate.tiers[i + 1] = StakingControllerLib.Tier(
        _multipliers[i],
        _minimums[i],
        _cycles[i]
      );
    }
  }

  function fillFirstCycle() public onlyOwner {
    _triggerCycle(true);
  }

  function _triggerCycle(bool force) internal {
    if (force || block.timestamp > isolate.nextCycleTime) {
      isolate.nextCycleTime = block.timestamp + isolate.cycleInterval;
      uint256 _currentCycle = ++isolate.currentCycle;
      isolate.cycles[_currentCycle].pCnfiToken = FactoryLib.create2Clone(
        isolate.pCnfiImplementation,
        uint256(
          keccak256(abi.encodePacked(pCNFIFactoryLib.getSalt(), _currentCycle))
        )
      );
      isolate.nextTimestamp = block.timestamp + isolate.rewardInterval;
      isolate.pCnfi = pCNFI(isolate.cycles[_currentCycle].pCnfiToken);
      isolate.pCnfi.initialize(_currentCycle);
      isolate.cycles[_currentCycle].day = 1;
      if (_currentCycle != 1) {
        isolate.cycles[_currentCycle].totalWeight = isolate
          .cycles[_currentCycle - 1]
          .totalRawWeight;
        isolate.cycles[_currentCycle].totalRawWeight = isolate
          .cycles[_currentCycle - 1]
          .totalRawWeight;
      }
    }
  }

  function determineMultiplier(address user, bool penaltyChange)
    internal
    returns (uint256)
  {
    uint256 currentBalance = isolate.sCnfi.balanceOf(user);
    (uint256 multiplier, uint256 amountToBurn) = UpdateRedeemableLib
      .determineMultiplier(isolate, penaltyChange, user, currentBalance);
    if (amountToBurn > 0) isolate.sCnfi.burn(user, amountToBurn);
    return multiplier;
  }

  function _updateToLast(address user) internal {
    UpdateToLastLib.updateToLast(isolate, user);
  }

  function _updateCumulativeRewards(address user) internal {
    UpdateRedeemableLib.updateCumulativeRewards(isolate, user);
  }

  function _updateWeightsWithMultiplier(address user)
    internal
    returns (uint256)
  {
    uint256 multiplier = determineMultiplier(user, false);

    return
      UpdateToLastLib.updateWeightsWithMultiplier(isolate, user, multiplier);
  }

  function _updateDailyStatsToLast(address user) internal {
    UpdateRedeemableLib.updateDailyStatsToLast(isolate, user, 0, false, false);
  }

  function receiveSingularCallback(address sender) public {
    if (sender != address(0x0)) {
      _trackDailyRewards(false);
      _triggerCycle(false);
      _updateCumulativeRewards(sender);
      _updateToLast(sender);
      _updateWeightsWithMultiplier(sender);
      _updateDailyStatsToLast(sender);
    }
  }

  function receiveCallback(address a, address b) public {
    receiveSingularCallback(a);
    receiveSingularCallback(b);
  }

  function calculateRewards(
    address _user,
    uint256 amount,
    bool isView
  ) internal returns (uint256 amountToRedeem, uint256 bonuses) {
    receiveCallback(_user, address(0x0));
    return CalculateRewardsLib.calculateRewards(isolate, _user, amount, isView);
  }

  function determineDailyMultiplier(address sender)
    internal
    returns (uint256 multiplier)
  {
    multiplier = UpdateRedeemableLib.determineDailyMultiplier(isolate, sender);
  }

  function _trackDailyRewards(bool force) internal {
    StakingControllerLib.Cycle storage cycle = isolate.cycles[
      isolate.currentCycle
    ];

    if (
      force || (!cycle.canUnstake && block.timestamp > isolate.nextTimestamp)
    ) {
      uint256 daysMissed = 1;
      if (block.timestamp > isolate.nextTimestamp) {
        daysMissed = block
          .timestamp
          .sub(isolate.nextTimestamp)
          .div(isolate.rewardInterval)
          .add(1);
      }
      isolate.nextTimestamp = block.timestamp + isolate.rewardInterval;
      cycle.reserved = cycle.reserved.add(isolate.inflateBy * daysMissed);
      isolate.pCnfi.mint(
        address(isolate.cnfiTreasury),
        isolate.inflatepcnfiBy * daysMissed
      );
      for (uint256 i = 0; i < daysMissed; i++) {
        cycle.cnfiRewards[cycle.day] = isolate.inflateBy;
        cycle.day++;
      }
      isolate.cumulativeTotalWeight = isolate.cumulativeTotalWeight.add(
        isolate.totalWeight * daysMissed
      );

      isolate.currentDay += daysMissed;
    }
  }

  function _claim(address user)
    public
    view
    returns (uint256 amountToRedeem, uint256 bonuses)
  {}

  event RewardsClaimed(
    address indexed user,
    uint256 amountToRedeem,
    uint256 bonuses
  );

  function claimRewards()
    public
    onlyOwner
    returns (uint256 amountToRedeem, uint256 bonuses)
  {}

  function claimRewardsWithAmount(uint256 amount)
    public
    onlyOwner
    returns (uint256 amountToRedeem, uint256 bonuses)
  {}

  function restakeRewardsWithAmount(uint256 amount, uint256 tier)
    public
    onlyOwner
  {}

  function recalculateWeights(
    address sender,
    uint256 oldBalance,
    uint256 newBalance,
    bool penalty
  ) internal {}

  function stake(uint256 amount, uint256 commitmentTier) public {}

  function unstake(uint256 amount) public returns (uint256 withdrawable) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { StakingController } from '../staking/StakingController.sol';
import { StakingControllerLib } from '../staking/StakingControllerLib.sol';
import { ViewExecutor } from '../util/ViewExecutor.sol';
import { Viewer } from './Viewer.sol';
import { RevertCaptureLib } from '../util/RevertCaptureLib.sol';
import { BytesManip } from '../util/Bytes.sol';

contract Query is Viewer {
  using BytesManip for *;

  constructor(address sc, address user) public {
    StakingController(sc).receiveCallback(user, address(0x0));
    address viewLayer = address(new Viewer());
    bytes memory response =
      StakingController(sc).query(
        viewLayer,
        abi.encodeWithSelector(Viewer.render.selector, user)
      );
    bytes memory returnData = abi.encode(response, 0, 0, block.timestamp);
    assembly {
      return(add(0x20, returnData), mload(returnData))
    }
  }

  function decodeResponse()
    public
    returns (
      bytes memory,
      uint256,
      uint256,
      uint256
    )
  {}
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import {Memory} from "./Memory.sol";

library BytesManip {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(
                        add(tempBytes, lengthmod),
                        mul(0x20, iszero(lengthmod))
                    )
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(
                            add(
                                add(_bytes, lengthmod),
                                mul(0x20, iszero(lengthmod))
                            ),
                            _start
                        )
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library Memory {
    // Size of a word, in bytes.
    uint256 internal constant WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint256 internal constant BYTES_HEADER_SIZE = 32;
    // Address of the free memory pointer.
    uint256 internal constant FREE_MEM_PTR = 0x40;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(
        uint256 addr,
        uint256 addr2,
        uint256 len
    ) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'
    function equals(
        uint256 addr,
        uint256 len,
        bytes memory bts
    ) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint256 addr2;
        assembly {
            addr2 := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
        return equals(addr, addr2, len);
    }

    // Allocates 'numBytes' bytes in memory. This will prevent the Solidity compiler
    // from using this area of memory. It will also initialize the area by setting
    // each byte to '0'.
    function allocate(uint256 numBytes) internal pure returns (uint256 addr) {
        // Take the current value of the free memory pointer, and update.
        assembly {
            addr := mload(
                /*FREE_MEM_PTR*/
                0x40
            )
            mstore(
                /*FREE_MEM_PTR*/
                0x40,
                add(addr, numBytes)
            )
        }
        uint256 words = (numBytes + WORD_SIZE - 1) / WORD_SIZE;
        for (uint256 i = 0; i < words; i++) {
            assembly {
                mstore(
                    add(
                        addr,
                        mul(
                            i,
                            /*WORD_SIZE*/
                            32
                        )
                    ),
                    0
                )
            }
        }
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // Returns a memory pointer to the provided bytes array.
    function ptr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly {
            addr := bts
        }
    }

    // Returns a memory pointer to the data portion of the provided bytes array.
    function dataPtr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly {
            addr := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts)
        internal
        pure
        returns (uint256 addr, uint256 len)
    {
        len = bts.length;
        assembly {
            addr := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint256 addr, uint256 len)
        internal
        pure
        returns (bytes memory bts)
    {
        bts = new bytes(len);
        uint256 btsptr;
        assembly {
            btsptr := add(
                bts,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
        copy(addr, btsptr, len);
    }

    // Get the word stored at memory address 'addr' as a 'uint'.
    function toUint(uint256 addr) internal pure returns (uint256 n) {
        assembly {
            n := mload(addr)
        }
    }

    // Get the word stored at memory address 'addr' as a 'bytes32'.
    function toBytes32(uint256 addr) internal pure returns (bytes32 bts) {
        assembly {
            bts := mload(addr)
        }
    }

    /*
    // Get the byte stored at memory address 'addr' as a 'byte'.
    function toByte(uint addr, uint8 index) internal pure returns (byte b) {
        require(index < WORD_SIZE);
        uint8 n;
        assembly {
            n := byte(index, mload(addr))
        }
        b = byte(n);
    }
    */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import { StakingControllerLib } from "./StakingControllerLib.sol";
import { GetDisplayTierImplLib } from "./GetDisplayTierImplLib.sol";
import { UpdateRedeemableImplLib } from "./UpdateRedeemableLib.sol";
import { StakingEventsLib } from "./StakingEventsLib.sol";
import { CalculateRewardsImplLib } from "./CalculateRewardsImplLib.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";

library RestakeRewardsLib {
  using SafeMathUpgradeable for *;
  function restakeRewardsWithAmount(StakingControllerLib.Isolate storage isolate, uint256 amount, uint256 tier) external {
    _restakeRewardsWithAmount(isolate, amount, tier);
  }
  function _restakeRewardsWithAmount(StakingControllerLib.Isolate storage isolate, uint256 amount, uint256 tier) internal {
    (uint256 amountToRedeem, uint256 bonuses) =
      CalculateRewardsImplLib._calculateRewards(isolate, msg.sender, amount, false);
    uint256 oldBalance = isolate.sCnfi.balanceOf(msg.sender);
    StakingControllerLib.DailyUser storage user = isolate.dailyUsers[msg.sender];

    require(
      (oldBalance + amountToRedeem >= isolate.tiers[tier].minimum &&
        isolate.tiers[tier].minimum != 0) || tier == 0,
      'must provide more capital to commit to tier'
    );
    if (isolate.lockCommitments[msg.sender] <= tier) isolate.lockCommitments[msg.sender] = tier;
    if (user.commitment <= tier) user.commitment = tier;

    bool timeLocked = isolate.lockCommitments[msg.sender] > 0;
    uint256 newBalance = oldBalance.add(amountToRedeem);
    isolate.sCnfi.mint(msg.sender, amountToRedeem);
    StakingEventsLib._emitRedeemed(msg.sender, amountToRedeem, bonuses);
    tier = GetDisplayTierImplLib._getDisplayTier(isolate, tier, newBalance);
    StakingEventsLib._emitStaked(
      msg.sender,
      amountToRedeem,
      tier,
      isolate.tiers[tier].minimum,
      timeLocked
    );
    UpdateRedeemableImplLib._recalculateWeights(isolate, msg.sender, oldBalance, newBalance, false);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { sCNFI } from "./sCNFI.sol";

library sCNFIFactoryLib {
  bytes32 constant _SALT = keccak256("StakingController:sCNFI");
  function SALT() internal pure returns (bytes32) {
    return _SALT;
  }
  function getBytecode() external pure returns (bytes memory bytecode) {
    bytecode = type(sCNFI).creationCode;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { StakingControllerTemplate } from "../staking/StakingControllerTemplate.sol";

contract MockView is StakingControllerTemplate {
  function render() public view returns (address) {
    return isolate.pCnfiImplementation;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { MockView } from "./MockView.sol";
import { ViewExecutor } from "../util/ViewExecutor.sol";

contract MockQuery {
  constructor(address sc) public {
    address viewLayer = address(new MockView());
    bytes memory result = ViewExecutor(sc).query(viewLayer, abi.encodeWithSelector(MockView.render.selector));
    (address pCnfi) = abi.decode(result, (address));
    bytes memory response = abi.encode(pCnfi);
    assembly {
      return(add(0x20, response), mload(response))
    }
  }
}

pragma solidity ^0.6.12;
import {aeERC20} from "arb-bridge-peripherals/contracts/tokenbridge/libraries/aeERC20.sol";
import {IArbToken} from "arb-bridge-peripherals/contracts/tokenbridge/arbitrum/IArbToken.sol";

contract ConnectTokenL2 is IArbToken, aeERC20 {
  address public l2Gateway;
  address public override l1Address;
  address private stakingController;

  modifier onlyGateway() {
    require(msg.sender == l2Gateway, "ONLY_l2GATEWAY");
    _;
  }

  function initialize(address _l2Gateway, address _l1Address)
    public
    initializer
  {
    l2Gateway = _l2Gateway;
    l1Address = _l1Address;
    aeERC20._initialize("Connect Financial", "CNFI", uint8(18));
  }

  function setStakingController(address _stakingController) public {
    require(
      stakingController == address(0x0),
      "cannot reset stakingcontroller"
    );
    stakingController = _stakingController;
  }

  function bridgeMint(address account, uint256 amount)
    external
    override
    onlyGateway
  {
    _mint(account, amount);
  }

  function bridgeBurn(address account, uint256 amount)
    external
    override
    onlyGateway
  {
    _burn(account, amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    if (msg.sender == stakingController) _approve(from, msg.sender, amount);
    return super.transferFrom(from, to, amount);
  }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "@openzeppelin/contracts-upgradeable/drafts/ERC20PermitUpgradeable.sol";
import "./TransferAndCallToken.sol";

/// @title Arbitrum extended ERC20
/// @notice The recommended ERC20 implementation for Layer 2 tokens
/// @dev This implements the ERC20 standard with transferAndCall extenstion/affordances
contract aeERC20 is ERC20PermitUpgradeable, TransferAndCallToken {
    using AddressUpgradeable for address;

    constructor() public initializer {
        // this is expected to be used as the logic contract behind a proxy
        // override the constructor if you don't wish to use the initialize method
    }

    function _initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal initializer {
        __ERC20Permit_init(name_);
        __ERC20_init(name_, symbol_);
        _setupDecimals(decimals_);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @title Minimum expected interface for L2 token that interacts with the L2 token bridge (this is the interface necessary
 * for a custom token that interacts with the bridge, see TestArbCustomToken.sol for an example implementation).
 */
pragma solidity ^0.6.11;

interface IArbToken {
    /**
     * @notice should increase token supply by amount, and should (probably) only be callable by the L1 bridge.
     */
    function bridgeMint(address account, uint256 amount) external;

    /**
     * @notice should decrease token supply by amount, and should (probably) only be callable by the L1 bridge.
     */
    function bridgeBurn(address account, uint256 amount) external;

    /**
     * @return address of layer 1 token
     */
    function l1Address() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.5 <0.8.0;

import "../token/ERC20/ERC20Upgradeable.sol";
import "./IERC20PermitUpgradeable.sol";
import "../cryptography/ECDSAUpgradeable.sol";
import "../utils/CountersUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping (address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./ITransferAndCall.sol";

// Implementation from https://github.com/smartcontractkit/LinkToken/blob/master/contracts/v0.6/TransferAndCallToken.sol
/**
 * @notice based on Implementation from https://github.com/smartcontractkit/LinkToken/blob/master/contracts/v0.6/ERC677Token.sol
 * The implementation doesn't return a bool on onTokenTransfer. This is similar to the proposed 677 standard, but still incompatible - thus we don't refer to it as such.
 */
abstract contract TransferAndCallToken is ERC20Upgradeable, ITransferAndCall {
    /**
     * @dev transfer token to a contract address with additional data if the recipient is a contact.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @param _data The extra data to be passed to the receiving contract.
     */
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public virtual override returns (bool success) {
        super.transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

    // PRIVATE

    function contractFallback(
        address _to,
        uint256 _value,
        bytes memory _data
    ) private {
        ITransferAndCallReceiver receiver = ITransferAndCallReceiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMathUpgradeable.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITransferAndCall is IERC20Upgradeable {
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

/**
 * @notice note that implementation of ITransferAndCallReceiver is not expected to return a success bool
 */
interface ITransferAndCallReceiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes memory _data
    ) external;
}