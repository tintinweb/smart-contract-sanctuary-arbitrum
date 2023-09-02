// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IGovernanceStakingPool } from "./interface/IGovernanceStakingPool.sol";
import { Math } from "vesta-core/math/Math.sol";
import { IBoostVsta } from "./interface/IBoostVsta.sol";
import { IGaugesManager } from "./interface/IGaugesManager.sol";
import { SingleRewardStaking, Reward } from "./SingleRewardStaking.sol";
import { Shareable } from "vesta-core/reward/Shareable.sol";
import { IStakedBVsta } from "./interface/IStakedBVsta.sol";

contract GovernanceStakingPool is IGovernanceStakingPool, SingleRewardStaking, Shareable {
  address public vsta;
  IGaugesManager public gaugeManager;

  mapping(address => uint256) internal highestStaked;
  mapping(address => uint256) internal boostVstaPenalty;
  mapping(address => uint256) internal lastBoostVstaBalanceEmitted;
  mapping(address => uint256) internal rewardsEmitted;

  uint256 public compoundedRewards;

  modifier onlyBoostVsta() {
    if (msg.sender != rewardToken) revert InvalidPermission();
    _;
  }

  function setUp(
    address _owner,
    address _depositToken,
    address _boostVsta,
    address _vsta,
    address _gaugeManager,
    uint64 _rewardsDuration
  ) external initializer {
    __BASE_STAKING_INIT(_depositToken, _boostVsta, _rewardsDuration);
    vsta = _vsta;
    gaugeManager = IGaugesManager(_gaugeManager);

    _transferOwnership(_owner);
  }

  function _updateRewardsEmitted(address _user) internal {
    _updateCompound(_user);
    uint256 currentBVstaBalance = earned(_user);

    if (currentBVstaBalance == 0) return;

    rewardsEmitted[_user] += (currentBVstaBalance - lastBoostVstaBalanceEmitted[_user]);
    lastBoostVstaBalanceEmitted[_user] = currentBVstaBalance;
  }

  function _updateCompound(address _user) internal {
    compoundedRewards += IStakedBVsta(rewardToken).compound();

    if (totalWeight > 0) {
      share += Math.rdiv(_crop(), totalWeight);
    }

    uint256 last = crops[_user];
    uint256 curr = Math.rmul(userShares[_user], share);

    if (curr > last) {
      compoundedRewards -= curr - last;
    }

    stock = compoundedRewards;
  }

  function _crop() internal view override returns (uint256) {
    return compoundedRewards - stock;
  }

  function stakeOnBehalf(address _user, uint256 _amount) external {
    _stake(_user, _amount);
  }

  function stake(uint256 _amount) external override {
    _stake(msg.sender, _amount);
  }

  function _stake(address _user, uint256 _amount) internal override {
    _updateRewardsEmitted(_user);

    uint256 newShare = 1e18;
    if (totalWeight > 0) {
      newShare = Math.mulDiv(totalWeight, _amount, totalStakedAmount);
    }

    super._stake(_user, _amount);

    uint256 highestStake = highestStaked[_user];
    uint256 currentStake = stakedAmount[_user];

    if (highestStake > currentStake) {
      boostVstaPenalty[_user] -=
        Math.mulDiv(boostVstaPenalty[_user], _amount, highestStake);
    } else {
      highestStaked[_user] = currentStake;
      boostVstaPenalty[_user] = 0;
    }

    gaugeManager.updateUserBoosts(_user);
    _addShare(_user, newShare);
  }

  function withdraw(uint256 _amount) external override {
    if (stakedAmount[msg.sender] == 0) revert NoStakeBalance();

    _updateRewardsEmitted(msg.sender);

    uint256 maxBalance = stakedAmount[msg.sender];
    _amount = Math.min(_amount, maxBalance);

    uint256 rewardsGiven = rewardsEmitted[msg.sender];

    if (_amount == maxBalance) {
      boostVstaPenalty[msg.sender] = rewardsGiven;
    } else {
      boostVstaPenalty[msg.sender] +=
        Math.mulDiv(rewardsGiven - boostVstaPenalty[msg.sender], _amount, maxBalance);
    }

    uint256 newShare = 0;
    uint256 userNewStakeBalance = maxBalance - _amount;

    if (totalWeight > 0 && userNewStakeBalance > 0) {
      newShare = Math.mulDiv(totalWeight, userNewStakeBalance, totalStakedAmount);
    }

    super._withdraw(msg.sender, _amount);
    gaugeManager.updateUserBoosts(msg.sender);

    _partialExitShare(msg.sender, newShare);
  }

  function claimRewards(address _user) external override {
    _claimRewards(_user);
  }

  function _claimRewards(address _user) internal override {
    _updateRewardsEmitted(_user);
    super._claimRewards(_user);

    lastBoostVstaBalanceEmitted[_user] = 0;

    uint256 userStakeBalance = stakedAmount[_user];
    if (totalWeight == 0 || userStakeBalance == 0) return;

    uint256 newShare = Math.mulDiv(totalWeight, userStakeBalance, totalStakedAmount);
    _partialExitShare(_user, newShare);
  }

  function exit() external override {
    if (stakedAmount[msg.sender] == 0) revert NoStakeBalance();

    _updateRewardsEmitted(msg.sender);
    super._exitStake(msg.sender);

    boostVstaPenalty[msg.sender] = rewardsEmitted[msg.sender];
    gaugeManager.updateUserBoosts(msg.sender);

    _exitShare(msg.sender);
  }

  function notifyRewardAmount(uint128 _reward) external onlyOwner {
    _notifyRewardAmount(_reward, vsta);
  }

  function _notifyRewardAmount(uint128 _reward, address _sendingToken) internal override {
    super._notifyRewardAmount(_reward, _sendingToken);
    IBoostVsta(rewardToken).convertVsta(_reward);
  }

  function onVest(address _user, uint256 _vestedAmount) external onlyBoostVsta {
    _updateRewardsEmitted(_user);

    uint256 emitted = rewardsEmitted[_user];
    _vestedAmount = Math.min(_vestedAmount, emitted);

    emitted -= _vestedAmount;
    rewardsEmitted[_user] = emitted;

    if (boostVstaPenalty[_user] > emitted) {
      boostVstaPenalty[_user] = emitted;
    }
  }

  function getPenaltyDetails(address _user)
    external
    view
    override
    returns (uint256 activeAmount_, uint256 rewardsEmitted_)
  {
    rewardsEmitted_ =
      (rewardsEmitted[_user] + earned(_user)) - lastBoostVstaBalanceEmitted[_user];

    activeAmount_ = rewardsEmitted_ - boostVstaPenalty[_user];

    return (activeAmount_, rewardsEmitted_);
  }

  function earned(address _user) public view override returns (uint256) {
    uint256 nextShare = share;
    uint256 upcomingReward = IStakedBVsta(rewardToken).getPendingReward(address(this));
    uint256 nextCrops = (compoundedRewards + upcomingReward) - stock;

    if (totalWeight > 0) {
      nextShare += Math.rdiv(nextCrops, totalWeight);
    }

    uint256 last = crops[_user];
    uint256 curr = Math.rmul(userShares[_user], nextShare);

    uint256 compoundReward = 0;
    if (curr > last) {
      compoundReward = curr - last;
    }

    return super.earned(_user) + compoundReward;
  }

  function getHighestStake(address _user) external view returns (uint256) {
    return highestStaked[_user];
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { IEmitter } from "./IEmitter.sol";

interface IGovernanceStakingPool is IEmitter {
  error NoStakeBalance();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Math {
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a : _b;
    }

    function getAbsoluteDifference(uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256)
    {
        return (_a >= _b) ? (_a - _b) : (_b - _a);
    }

    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }

    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y - 1)) / y;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * WAD) / y;
    }

    function wdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = divup((x * WAD), y);
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / RAY;
    }

    function rmulup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = divup((x * y), RAY);
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mulDiv(x, RAY, y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { EBoostVsta, Vesting } from "../event/EBoostVsta.sol";

interface IBoostVsta is EBoostVsta {
  /**
   * convertVsta allows someone to convert their VSTA to bVSTA. The converted vsta aren't included in any penalty system
   * @param _amount Amount of VSTA to convert to BVSTA
   */
  function convertVsta(uint256 _amount) external;

  /**
   * Vest allows to creating a vesting schedule. This is used to convert bVSTA back to VSTA. The unlocks is done linearly over (by default) a year
   * @param _unaffectedBalance how much to vest from the "convertVsta" & bVSTA's reward system's balance
   * @param _singleEmitter how much to vest from the VSTA Pool Reward
   * @param _lpEmitter how much to vest from the VSTA-ETH Pool Reward
   * @dev If the amount put in the parameters is higher than the actual balance, it will automatically scale down to the balance.
   */
  function vest(uint256 _unaffectedBalance, uint256 _singleEmitter, uint256 _lpEmitter)
    external;

  /**
   * unvestById allows the user to unvest a shedule by its id. That will automatically claims the unvested VSTA and give back the bVSTA to the user.
   * @param _id id of the vesting schedule
   */
  function unvestById(uint256 _id) external;

  /**
   * claim the unvested vsta from a vesting schedule
   * @param _id vesting schedule id
   */
  function claim(uint256 _id) external;

  /**
   * claimBatch the unvested vsta from multiple vesting schedules
   * @param _ids vesting schedule ids
   */
  function claimBatch(uint256[] calldata _ids) external;

  /**
   * claimAll the unvested vsta from all vesting schedules
   */
  function claimAll() external;

  /**
   * getPendingClaimable returns how much vsta is pending to be claimed from the vesting
   * @param _user address of the user
   * @return totalClaimable_ total vsta that can be claimed
   */
  function getPendingClaimable(address _user)
    external
    view
    returns (uint256 totalClaimable_);

  /**
   * getPenaltyDetails returns how much bVSTA are active from the user's wallet.
   * @param _user address of the user
   * @return activeBVsta_ total active BVSTA
   * @return userBalance_ total user's BVSTA balance
   */
  function getPenaltyDetails(address _user)
    external
    view
    returns (uint256 activeBVsta_, uint256 userBalance_);

  /**
   * getTotalVested returns the total of bVSTA vested
   * @param _user address of the user
   */
  function getTotalVested(address _user) external view returns (uint256 totalVested_);

  /**
   * getAllVesting get All vesting schedules
   * @param _user address of the user
   */
  function getAllVesting(address _user) external view returns (Vesting[] memory);

  /**
   * getActiveVestingIds get All active vesting schedule ids
   * @param _user address of the user
   */
  function getActiveVestingIds(address _user) external view returns (uint256[] memory);

  /**
   * getUnaffectedBalance get the total of unaffected balance
   * @param _user address of the user
   */
  function getUnaffectedBalance(address _user) external view returns (uint256);

  /**
   * getEmittedVestingBalances get how much bVSTA was vested from each emitters (pools)
   * @param _user address of the user
   * @return vestingSingle_ amount vested from singleStaking
   * @return vestingLp_ amount vested from LPStaking
   */
  function getEmittedVestingBalances(address _user)
    external
    view
    returns (uint256 vestingSingle_, uint256 vestingLp_);

  /**
   * getVestingDetail get full detail of a vesting schedule
   * @param _user address of the user
   * @param _id id of the vesting schedule
   */
  function getVestingDetail(address _user, uint256 _id)
    external
    view
    returns (Vesting memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { EGaugesManager } from "../event/EGaugesManager.sol";

interface IGaugesManager is EGaugesManager {
  /**
   * stakeAndSetBoostGauge Stake And Boost a gauge
   * @param _gauge address of the gauge
   * @param _stakeAmount amount to stake
   * @param _boostAmount amount to boost
   */
  function stakeAndSetBoostGauge(
    address _gauge,
    uint256 _stakeAmount,
    uint256 _boostAmount
  ) external;

  /**
   * Stake in a gauge
   * @param _gauge adress of the gauge
   * @param _amount amount to stake
   * @dev The user needs to give approval to the `_gauge` otherwise the transfer will fail
   */
  function stakeInGauge(address _gauge, uint256 _amount) external;

  /**
   * withdrawFromGauge unstake from a gauge
   * @param _gauge address of the gauge
   * @param _amount amount to unstake
   */
  function withdrawFromGauge(address _gauge, uint256 _amount) external;

  /**
   * exitFromGauge exit from a gauge
   * @param _gauge address of the gauge
   */
  function exitFromGauge(address _gauge) external;

  /**
   * boostGauge allows the user to boost the reward of a specific gauge
   * @param _gauge address of the gauge
   * @param _amount amount to boost
   */
  function boostGauge(address _gauge, uint256 _amount) external;

  /**
   * unboostGauge allows the user to unboost a specific gauge
   * @param _gauge address of the gauge
   * @param _amount amount to withdraw
   */
  function unboostGauge(address _gauge, uint256 _amount) external;

  /**
   * updateUserBoosts triggers a refresh on the user's boost after a withdraw or deposit.
   * @param _user address of the user
   * @dev There is no point for a user to call this function, this is mainly for the protocol logic
   */
  function updateUserBoosts(address _user) external;

  /**
   * distributeRewardToGauges start a new distribution period on all gauges
   * @param _tokens addresses of reward tokens
   * @param _amounts amounts by token to give as reward
   * @dev can only be called by the distributor
   */
  function distributeRewardToGauges(address[] memory _tokens, uint256[] memory _amounts)
    external;

  /**
   * isGauge Check if the address is a vesta gauge
   * @param _gauge address of gauge
   */
  function isGauge(address _gauge) external view returns (bool);

  /**
   * isGaugeDisabled check if the gauge is enabled or disabled. A disabled gauge will stop receive reward from `distributeRewardToGauges`
   * @param _gauge address of gauge
   */
  function isGaugeDisabled(address _gauge) external view returns (bool);

  /**
   * isGaugeDeleted check if the gauge has been deleted
   * @param _gauge address of gauge
   */
  function isGaugeDeleted(address _gauge) external view returns (bool);

  /**
   * getUserAllocationToGauge get how much a user is allocating their boosting to a gauge
   * @param _user address of the user
   * @param _gauge address of the gauge
   * @return boost_ amount of bVSTA allocated to the gauge
   */
  function getUserAllocationToGauge(address _user, address _gauge)
    external
    view
    returns (uint256);

  /**
   * getAllocatedAmount returns how much user's bVSTA is allocated in the boosting system
   * @param _user address of the user
   */
  function getAllocatedAmount(address _user) external view returns (uint256);
}

pragma solidity ^0.8.20;

import { TokenTransferrer } from "vesta-core/token/TokenTransferrer.sol";
import { BaseVesta } from "vesta-core/BaseVesta.sol";
import { Math } from "vesta-core/math/Math.sol";
import { Reward } from "./model/SingleRewardStakingModel.sol";
import { ISingleRewardStaking } from "./interface/ISingleRewardStaking.sol";

abstract contract SingleRewardStaking is
  ISingleRewardStaking,
  TokenTransferrer,
  BaseVesta
{
  Reward internal rewardData;
  address public depositToken;
  address public rewardToken;
  uint256 public totalStakedAmount;

  mapping(address => uint256) internal userRewardPerTokenPaid;
  mapping(address => uint256) internal rewards;
  mapping(address => uint256) internal stakedAmount;

  function __BASE_STAKING_INIT(
    address _depositToken,
    address _rewardToken,
    uint64 _rewardsDuration
  ) internal onlyInitializing {
    __BASE_VESTA_INIT();
    depositToken = _depositToken;
    rewardToken = _rewardToken;
    rewardData.rewardsDuration = _rewardsDuration;
  }

  function _updateReward(address _account) internal {
    Reward storage tokenRewardData = rewardData;
    tokenRewardData.rewardPerTokenStored = _rewardPerToken();
    tokenRewardData.lastUpdateTime = uint128(getLastTimeRewardApplicable());

    if (_account != address(0)) {
      rewards[_account] = earned(_account);
      userRewardPerTokenPaid[_account] = tokenRewardData.rewardPerTokenStored;
    }
  }

  function _stake(address _user, uint256 _amount) internal virtual notZero(_amount) {
    _updateReward(_user);

    stakedAmount[_user] += _amount;
    totalStakedAmount += _amount;

    _performTokenTransferFrom(depositToken, msg.sender, address(this), _amount);

    emit Staked(_user, _amount);
  }

  function _withdraw(address _user, uint256 _amount) internal virtual notZero(_amount) {
    _updateReward(_user);

    stakedAmount[_user] -= _amount;
    totalStakedAmount -= _amount;

    _performTokenTransfer(depositToken, _user, _amount);

    emit Withdrawn(_user, _amount);
  }

  function _exitStake(address _user) internal virtual {
    _claimRewards(_user);

    uint256 currentAmount = stakedAmount[_user];
    totalStakedAmount -= currentAmount;
    stakedAmount[_user] = 0;

    _performTokenTransfer(depositToken, _user, currentAmount);

    emit Withdrawn(_user, currentAmount);
  }

  function _claimRewards(address _user) internal virtual {
    _updateReward(_user);

    uint256 reward = rewards[_user];
    if (reward == 0) return;

    rewards[_user] = 0;
    _performTokenTransfer(rewardToken, _user, reward);
    emit RewardPaid(_user, reward);
  }

  function _notifyRewardAmount(uint128 _reward, address _sendingToken) internal virtual {
    _updateReward(address(0));

    Reward storage tokenRewardData = rewardData;
    uint256 endPeriod = tokenRewardData.periodFinish;
    uint256 duration = tokenRewardData.rewardsDuration;

    tokenRewardData.rewardPerTokenStored = _rewardPerToken();

    if (block.timestamp >= endPeriod) {
      tokenRewardData.rewardRatePerSecond = Math.mulDiv(_reward, Math.RAY, duration);
    } else {
      uint256 remaining = endPeriod - block.timestamp;
      uint256 leftover =
        Math.mulDiv(remaining, tokenRewardData.rewardRatePerSecond, Math.RAY);

      tokenRewardData.rewardRatePerSecond =
        Math.mulDiv((_reward + leftover), Math.RAY, duration);
    }

    tokenRewardData.lastUpdateTime = uint128(block.timestamp);
    tokenRewardData.periodFinish = uint64(block.timestamp + duration);

    _performTokenTransferFrom(_sendingToken, msg.sender, address(this), _reward);
    emit RewardAdded(_reward);
  }

  function setRewardsDuration(uint64 _rewardsDuration)
    external
    notZero(_rewardsDuration)
    onlyOwner
  {
    if (block.timestamp <= rewardData.periodFinish) {
      revert RewardPeriodStillActive();
    }

    rewardData.rewardsDuration = _rewardsDuration;

    emit RewardsDurationUpdated(_rewardsDuration);
  }

  function getDepositBalance(address _user) external view override returns (uint256) {
    return stakedAmount[_user];
  }

  function getLastTimeRewardApplicable() public view override returns (uint256) {
    return Math.min(block.timestamp, rewardData.periodFinish);
  }

  function earned(address _account) public view virtual override returns (uint256) {
    uint256 userPerToken = _rewardPerToken() - userRewardPerTokenPaid[_account];
    return Math.mulDiv(stakedAmount[_account], userPerToken, Math.RAY) + rewards[_account];
  }

  function rewardPerToken() external view override returns (uint256) {
    return _rewardPerToken();
  }

  function _rewardPerToken() internal view virtual returns (uint256) {
    Reward memory tokenRewardData = rewardData;

    if (totalStakedAmount == 0) {
      return tokenRewardData.rewardPerTokenStored;
    }
    return tokenRewardData.rewardPerTokenStored
      + Math.mulDiv(
        (getLastTimeRewardApplicable() - tokenRewardData.lastUpdateTime),
        tokenRewardData.rewardRatePerSecond,
        totalStakedAmount
      );
  }

  function getRewardData() external view returns (Reward memory) {
    return rewardData;
  }

  function getRewardForDuration() external view override returns (uint256) {
    return
      Math.mulDiv(rewardData.rewardRatePerSecond, rewardData.rewardsDuration, Math.RAY);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IShareable } from "./interface/IShareable.sol";
import { Math } from "../math/Math.sol";

/**
 * You can seek the test/reward/Shareable.t.sol file to have an example of how to use it.
 */
abstract contract Shareable is IShareable {
    uint256 public share; // crops per gem    [ray]
    uint256 public stock; // crop balance     [wad]
    uint256 public totalWeight; // [wad]

    //User => Value
    mapping(address => uint256) internal crops; // [wad]
    mapping(address => uint256) internal userShares; // [wad]

    uint256[49] private __gap;

    function _crop() internal virtual returns (uint256);

    function _addShare(address _wallet, uint256 _value) internal virtual {
        if (_value > 0) {
            uint256 wad = Math.wdiv(_value, netAssetsPerShareWAD());
            require(int256(wad) > 0);

            totalWeight += wad;
            userShares[_wallet] += wad;
        }
        crops[_wallet] = Math.rmulup(userShares[_wallet], share);
        emit ShareUpdated(_wallet, _value);
    }

    function _partialExitShare(address _wallet, uint256 _newShare) internal virtual {
        _deleteShare(_wallet);
        _addShare(_wallet, _newShare);
    }

    function _exitShare(address _wallet) internal virtual {
        _deleteShare(_wallet);
        emit ShareUpdated(_wallet, 0);
    }

    function _deleteShare(address _wallet) private {
        uint256 value = userShares[_wallet];

        if (value > 0) {
            uint256 wad = Math.wdivup(value, netAssetsPerShareWAD());

            require(int256(wad) > 0);

            totalWeight -= wad;
            userShares[_wallet] -= wad;
        }

        crops[_wallet] = Math.rmulup(userShares[_wallet], share);
    }

    function netAssetsPerShareWAD() public view override returns (uint256) {
        return (totalWeight == 0) ? Math.WAD : Math.wdiv(totalWeight, totalWeight);
    }

    function getCropsOf(address _target) external view override returns (uint256) {
        return crops[_target];
    }

    function getShareOf(address owner) public view override returns (uint256) {
        return userShares[owner];
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { EStakedBVsta } from "../event/EStakedBVsta.sol";

interface IStakedBVsta is EStakedBVsta {
  /**
   * compound the reward from governance staking.
   * @dev this is not needed by the user, this is mainly to simulate an auto-compound from LP & Single Staking
   */
  function compound() external returns (uint256 received_);

  /**
   * getPendingReward get how much reward is pending
   * @param _user address of the user
   * @return rewards_ amount of rewarding pending to be claimed
   * @dev the pending reward is already included in "balanceOf" since bVSTA auto-compound itself
   */
  function getPendingReward(address _user) external view returns (uint256 rewards_);

  /**
   * getRewardLeft how much bVSTA is left in the pool.
   * @return rewardLeft amount left in the pool
   */
  function getRewardLeft() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IEmitter {
  /**
   * onVest is called when the user claims, we have to update the penalty system so we do not count them anymore
   * @param _user address of the user
   * @param _vestedAmount amount vesting by the user
   * @dev only bVSTA contract can call this function
   */
  function onVest(address _user, uint256 _vestedAmount) external;

  /**
   *
   * @param _user address of the user
   * @return activeBVsta_ total active from this emitter
   * @return totalEmitted_ total emitted by this emitter to the user
   */
  function getPenaltyDetails(address _user)
    external
    view
    returns (uint256 activeBVsta_, uint256 totalEmitted_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Vesting } from "../model/BoostVstaModel.sol";

interface EBoostVsta {
  event ConvertedBVsta(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);
  event VestingCreated(address indexed user, Vesting schedule);
  event VestingFinished(address indexed user, uint256 indexed id);
  event Unvest(address indexed user, uint256 amount);

  error ExceedBalance();
  error VestingNotFound();
  error VestingEnded();
  error OnlyEmitters();
  error VestingAmountIsZero();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface EGaugesManager {
  error InsufficientBVsta();
  error DistributionNotFinished();
  error GaugeNotFound();
  error NoStatusChange();
  error NoActiveOrBoostedGauge();
  error FailedToDeployGauge();

  event UserActiveBoostChanged(
    address indexed user, address indexed gauge, uint256 activeBoost
  );
  event DeployedGauge(address indexed gauge);
  event UserGaugeBoostChanged(
    address indexed user, address indexed gauge, uint256 boostValue
  );
  event RewardsDistributed(address indexed token, uint256 amount);
  event GaugeDeleted(address indexed gauge);
  event GaugeStatusChanged(address indexed gauge, bool isDisabled);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TokenTransferrerConstants.sol";
import { TokenTransferrerErrors } from "./TokenTransferrerErrors.sol";
import { IERC20 } from "./interface/IERC20.sol";
import { IERC20Callback } from "./interface/IERC20Callback.sol";

/**
 * @title TokenTransferrer
 * @custom:source https://github.com/ProjectOpenSea/seaport
 * @dev Modified version of Seaport.
 */
abstract contract TokenTransferrer is TokenTransferrerErrors {
    function _performTokenTransfer(address token, address to, uint256 amount)
        internal
        returns (bool)
    {
        if (token == address(0)) {
            (bool success,) = to.call{ value: amount }(new bytes(0));

            return success;
        }

        address from = address(this);

        // Utilize assembly to perform an optimized ERC20 token transfer.
        assembly {
            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data into memory, starting with function selector.
            mstore(ERC20_transfer_sig_ptr, ERC20_transfer_signature)
            mstore(ERC20_transfer_to_ptr, to)
            mstore(ERC20_transfer_amount_ptr, amount)

            // Make call & copy up to 32 bytes of return data to scratch space.
            // Scratch space does not need to be cleared ahead of time, as the
            // subsequent check will ensure that either at least a full word of
            // return data is received (in which case it will be overwritten) or
            // that no data is received (in which case scratch space will be
            // ignored) on a successful call to the given token.
            let callStatus :=
                call(
                    gas(), token, 0, ERC20_transfer_sig_ptr, ERC20_transfer_length, 0, OneWord
                )

            // Determine whether transfer was successful using status & result.
            let success :=
                and(
                    // Set success to whether the call reverted, if not check it
                    // either returned exactly 1 (can't just be non-zero data), or
                    // had no return data.
                    or(
                        and(eq(mload(0), 1), gt(returndatasize(), 31)),
                        iszero(returndatasize())
                    ),
                    callStatus
                )

            // Handle cases where either the transfer failed or no data was
            // returned. Group these, as most transfers will succeed with data.
            // Equivalent to `or(iszero(success), iszero(returndatasize()))`
            // but after it's inverted for JUMPI this expression is cheaper.
            if iszero(and(success, iszero(iszero(returndatasize())))) {
                // If the token has no code or the transfer failed: Equivalent
                // to `or(iszero(success), iszero(extcodesize(token)))` but
                // after it's inverted for JUMPI this expression is cheaper.
                if iszero(and(iszero(iszero(extcodesize(token))), success)) {
                    // If the transfer failed:
                    if iszero(success) {
                        // If it was due to a revert:
                        if iszero(callStatus) {
                            // If it returned a message, bubble it up as long as
                            // sufficient gas remains to do so:
                            if returndatasize() {
                                // Ensure that sufficient gas is available to
                                // copy returndata while expanding memory where
                                // necessary. Start by computing the word size
                                // of returndata and allocated memory. Round up
                                // to the nearest full word.
                                let returnDataWords :=
                                    div(add(returndatasize(), AlmostOneWord), OneWord)

                                // Note: use the free memory pointer in place of
                                // msize() to work around a Yul warning that
                                // prevents accessing msize directly when the IR
                                // pipeline is activated.
                                let msizeWords := div(memPointer, OneWord)

                                // Next, compute the cost of the returndatacopy.
                                let cost := mul(CostPerWord, returnDataWords)

                                // Then, compute cost of new memory allocation.
                                if gt(returnDataWords, msizeWords) {
                                    cost :=
                                        add(
                                            cost,
                                            add(
                                                mul(
                                                    sub(returnDataWords, msizeWords),
                                                    CostPerWord
                                                ),
                                                div(
                                                    sub(
                                                        mul(returnDataWords, returnDataWords),
                                                        mul(msizeWords, msizeWords)
                                                    ),
                                                    MemoryExpansionCoefficient
                                                )
                                            )
                                        )
                                }

                                // Finally, add a small constant and compare to
                                // gas remaining; bubble up the revert data if
                                // enough gas is still available.
                                if lt(add(cost, ExtraGasBuffer), gas()) {
                                    // Copy returndata to memory; overwrite
                                    // existing memory.
                                    returndatacopy(0, 0, returndatasize())

                                    // Revert, specifying memory region with
                                    // copied returndata.
                                    revert(0, returndatasize())
                                }
                            }

                            // Otherwise revert with a generic error message.
                            mstore(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_signature
                            )
                            mstore(TokenTransferGenericFailure_error_token_ptr, token)
                            mstore(TokenTransferGenericFailure_error_from_ptr, from)
                            mstore(TokenTransferGenericFailure_error_to_ptr, to)
                            mstore(TokenTransferGenericFailure_error_id_ptr, 0)
                            mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                            revert(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_length
                            )
                        }

                        // Otherwise revert with a message about the token
                        // returning false or non-compliant return values.
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_signature
                        )
                        mstore(BadReturnValueFromERC20OnTransfer_error_token_ptr, token)
                        mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
                        mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
                        mstore(BadReturnValueFromERC20OnTransfer_error_amount_ptr, amount)
                        revert(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_length
                        )
                    }

                    // Otherwise, revert with error about token not having code:
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Otherwise, the token just returned no data despite the call
                // having succeeded; no need to optimize for this as it's not
                // technically ERC20 compliant.
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }

        return true;
    }

    function _performTokenTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        // Utilize assembly to perform an optimized ERC20 token transfer.
        assembly {
            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data into memory, starting with function selector.
            mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
            mstore(ERC20_transferFrom_from_ptr, from)
            mstore(ERC20_transferFrom_to_ptr, to)
            mstore(ERC20_transferFrom_amount_ptr, amount)

            // Make call & copy up to 32 bytes of return data to scratch space.
            // Scratch space does not need to be cleared ahead of time, as the
            // subsequent check will ensure that either at least a full word of
            // return data is received (in which case it will be overwritten) or
            // that no data is received (in which case scratch space will be
            // ignored) on a successful call to the given token.
            let callStatus :=
                call(
                    gas(),
                    token,
                    0,
                    ERC20_transferFrom_sig_ptr,
                    ERC20_transferFrom_length,
                    0,
                    OneWord
                )

            // Determine whether transfer was successful using status & result.
            let success :=
                and(
                    // Set success to whether the call reverted, if not check it
                    // either returned exactly 1 (can't just be non-zero data), or
                    // had no return data.
                    or(
                        and(eq(mload(0), 1), gt(returndatasize(), 31)),
                        iszero(returndatasize())
                    ),
                    callStatus
                )

            // Handle cases where either the transfer failed or no data was
            // returned. Group these, as most transfers will succeed with data.
            // Equivalent to `or(iszero(success), iszero(returndatasize()))`
            // but after it's inverted for JUMPI this expression is cheaper.
            if iszero(and(success, iszero(iszero(returndatasize())))) {
                // If the token has no code or the transfer failed: Equivalent
                // to `or(iszero(success), iszero(extcodesize(token)))` but
                // after it's inverted for JUMPI this expression is cheaper.
                if iszero(and(iszero(iszero(extcodesize(token))), success)) {
                    // If the transfer failed:
                    if iszero(success) {
                        // If it was due to a revert:
                        if iszero(callStatus) {
                            // If it returned a message, bubble it up as long as
                            // sufficient gas remains to do so:
                            if returndatasize() {
                                // Ensure that sufficient gas is available to
                                // copy returndata while expanding memory where
                                // necessary. Start by computing the word size
                                // of returndata and allocated memory. Round up
                                // to the nearest full word.
                                let returnDataWords :=
                                    div(add(returndatasize(), AlmostOneWord), OneWord)

                                // Note: use the free memory pointer in place of
                                // msize() to work around a Yul warning that
                                // prevents accessing msize directly when the IR
                                // pipeline is activated.
                                let msizeWords := div(memPointer, OneWord)

                                // Next, compute the cost of the returndatacopy.
                                let cost := mul(CostPerWord, returnDataWords)

                                // Then, compute cost of new memory allocation.
                                if gt(returnDataWords, msizeWords) {
                                    cost :=
                                        add(
                                            cost,
                                            add(
                                                mul(
                                                    sub(returnDataWords, msizeWords),
                                                    CostPerWord
                                                ),
                                                div(
                                                    sub(
                                                        mul(returnDataWords, returnDataWords),
                                                        mul(msizeWords, msizeWords)
                                                    ),
                                                    MemoryExpansionCoefficient
                                                )
                                            )
                                        )
                                }

                                // Finally, add a small constant and compare to
                                // gas remaining; bubble up the revert data if
                                // enough gas is still available.
                                if lt(add(cost, ExtraGasBuffer), gas()) {
                                    // Copy returndata to memory; overwrite
                                    // existing memory.
                                    returndatacopy(0, 0, returndatasize())

                                    // Revert, specifying memory region with
                                    // copied returndata.
                                    revert(0, returndatasize())
                                }
                            }

                            // Otherwise revert with a generic error message.
                            mstore(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_signature
                            )
                            mstore(TokenTransferGenericFailure_error_token_ptr, token)
                            mstore(TokenTransferGenericFailure_error_from_ptr, from)
                            mstore(TokenTransferGenericFailure_error_to_ptr, to)
                            mstore(TokenTransferGenericFailure_error_id_ptr, 0)
                            mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                            revert(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_length
                            )
                        }

                        // Otherwise revert with a message about the token
                        // returning false or non-compliant return values.
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_signature
                        )
                        mstore(BadReturnValueFromERC20OnTransfer_error_token_ptr, token)
                        mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
                        mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
                        mstore(BadReturnValueFromERC20OnTransfer_error_amount_ptr, amount)
                        revert(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_length
                        )
                    }

                    // Otherwise, revert with error about token not having code:
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Otherwise, the token just returned no data despite the call
                // having succeeded; no need to optimize for this as it's not
                // technically ERC20 compliant.
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /**
     * @notice SanitizeAmount allows to convert an 1e18 value to the token decimals
     * 		@dev only supports 18 and lower
     * 		@param token The contract address of the token
     * 		@param value The value you want to sanitize
     */
    function _sanitizeValue(address token, uint256 value)
        internal
        view
        returns (uint256)
    {
        if (token == address(0) || value == 0) return value;

        (bool success, bytes memory data) =
            token.staticcall(abi.encodeWithSignature("decimals()"));

        if (!success) return value;

        uint8 decimals = abi.decode(data, (uint8));

        if (decimals < 18) {
            return value / (10 ** (18 - decimals));
        }

        return value;
    }

    function _tryPerformMaxApprove(address _token, address _to) internal {
        if (IERC20(_token).allowance(address(this), _to) == type(uint256).max) {
            return;
        }

        _performApprove(_token, _to, type(uint256).max);
    }

    function _performApprove(address _token, address _spender, uint256 _value) internal {
        IERC20(_token).approve(_spender, _value);
    }

    function _balanceOf(address _token, address _of) internal view returns (uint256) {
        return IERC20(_token).balanceOf(_of);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IBaseVesta.sol";
import "./vendor/OwnableUpgradeable.sol";

/**
 * @title BaseVesta
 * @notice Inherited by most of our contracts. It has a permission system & reentrency protection inside it.
 * @dev Binary Roles Recommended Slots
 * 0x01  |  0x10
 * 0x02  |  0x20
 * 0x04  |  0x40
 * 0x08  |  0x80
 *
 * Don't use other slots unless you are familiar with bitewise operations
 */

abstract contract BaseVesta is IBaseVesta, OwnableUpgradeable {
    address internal constant RESERVED_ETH_ADDRESS = address(0);
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint256 internal constant DECIMAL_PRECISION = 1e18;
    address internal SELF;

    bool private reentrencyStatus;

    mapping(address => bytes1) internal permissions;

    uint256[49] private __gap;

    modifier onlyContract(address _address) {
        if (_address.code.length == 0) revert InvalidContract();
        _;
    }

    modifier onlyContracts(address _address, address _address2) {
        if (_address.code.length == 0 || _address2.code.length == 0) {
            revert InvalidContract();
        }
        _;
    }

    modifier onlyValidAddress(address _address) {
        if (_address == address(0)) {
            revert InvalidAddress();
        }

        _;
    }

    modifier nonReentrant() {
        if (reentrencyStatus) revert NonReentrancy();
        reentrencyStatus = true;
        _;
        reentrencyStatus = false;
    }

    modifier hasPermission(bytes1 access) {
        if (permissions[msg.sender] & access == 0) revert InvalidPermission();
        _;
    }

    modifier hasPermissionOrOwner(bytes1 access) {
        if (permissions[msg.sender] & access == 0 && msg.sender != owner()) {
            revert InvalidPermission();
        }

        _;
    }

    modifier notZero(uint256 _amount) {
        if (_amount == 0) revert NumberIsZero();
        _;
    }

    function __BASE_VESTA_INIT() internal onlyInitializing {
        __Ownable_init();
        SELF = address(this);
    }

    function setPermission(address _address, bytes1 _permission)
        external
        override
        onlyOwner
    {
        _setPermission(_address, _permission);
    }

    function _clearPermission(address _address) internal virtual {
        _setPermission(_address, 0x00);
    }

    function _setPermission(address _address, bytes1 _permission) internal virtual {
        permissions[_address] = _permission;
        emit PermissionChanged(_address, _permission);
    }

    function getPermissionLevel(address _address)
        external
        view
        override
        returns (bytes1)
    {
        return permissions[_address];
    }

    function hasPermissionLevel(address _address, bytes1 accessLevel)
        public
        view
        override
        returns (bool)
    {
        return permissions[_address] & accessLevel != 0;
    }

    /**
     * @notice _sanitizeMsgValueWithParam is for multi-token payable function.
     * 	@dev msg.value should be set to zero if the token used isn't a native token.
     * 		address(0) is reserved for Native Chain Token.
     * 		if fails, it will reverts with SanitizeMsgValueFailed
     * 	@return sanitizeValue which is the sanitize value you should use in your code.
     */
    function _sanitizeMsgValueWithParam(address _token, uint256 _paramValue)
        internal
        view
        returns (uint256)
    {
        if (RESERVED_ETH_ADDRESS == _token) {
            return msg.value;
        } else if (msg.value == 0) {
            return _paramValue;
        }

        revert SanitizeMsgValueFailed();
    }

    function isContract(address _address) internal view returns (bool) {
        return _address.code.length > 0;
    }
}

pragma solidity >=0.8.0;

struct Reward {
  uint64 rewardsDuration;
  uint64 periodFinish;
  uint128 lastUpdateTime;
  uint256 rewardRatePerSecond;
  uint256 rewardPerTokenStored;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { ESingleRewardStaking } from "../event/ESingleRewardStaking.sol";

/// @title ISingleRewardStaking
/// @notice Staking contract with one deposit token and reward token
interface ISingleRewardStaking is ESingleRewardStaking {
  /// @notice Stakes deposit tokens
  /// @param _amount of tokens
  function stake(uint256 _amount) external;

  /// @notice Withdraws deposit tokens
  /// @param _amount of tokens
  function withdraw(uint256 _amount) external;

  /// @notice Claims all pending rewards
  /// @param _user address
  function claimRewards(address _user) external;

  /// @notice Claims all pending rewards and then withdraws all staked deposit tokens
  function exit() external;

  /// @notice Returns the deposit balance of a user
  /// @param _user address of user
  /// @return uint256 amount staked
  function getDepositBalance(address _user) external view returns (uint256);

  /// @notice Returns the last timestamp in which rewards are applicable.
  /// @return uint256 timestamp
  function getLastTimeRewardApplicable() external view returns (uint256);

  /// @notice Returns the amount of rewards given per deposit token. Constantly increasing.
  /// @return uint256 amount of rewards per token
  function rewardPerToken() external view returns (uint256);

  /// @notice Returns the amount of rewards a user has earned
  /// @param _account user address
  /// @return uint256 amount of rewards
  function earned(address _account) external view returns (uint256);

  /// @notice Returns the amount of rewards over the whole duration period
  /// @return uint256 amount of rewards
  function getRewardForDuration() external view returns (uint256);

  /// @notice notifyRewardAmount trigger another period of reward
  /// @param _reward amount of reward for the new period
  function notifyRewardAmount(uint128 _reward) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IShareable {
    event ShareUpdated(address indexed user, uint256 share);
    event Flee();
    event Tack(address indexed src, address indexed dst, uint256 wad);

    function netAssetsPerShareWAD() external view returns (uint256);

    function getCropsOf(address _target) external view returns (uint256);

    function getShareOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface EStakedBVsta {
  error RewardPeriodStillActive();
  error CannotExitWhenBoostVstaLocked();
  error NumberIsZero();

  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardsRefilled(uint256 amount);
  event RewardsDurationUpdated(uint256 rewardDuration);
  event StakingIndexUpdated(uint256 stakingIndex);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Vesting {
  uint256 amountFromUnaffected;
  uint128 amountFromEmitterSingle;
  uint128 amountFromEmitterLp;
  uint128 totalClaimedUnaffected;
  uint128 totalClaimedEmitterSingle;
  uint128 totalClaimedEmitterLp;
  uint128 lastTimeClaimed;
  uint128 startTime;
  uint128 endTime;
}

struct Reward {
  uint64 rewardsDuration;
  uint64 periodFinish;
  uint128 lastUpdateTime;
  uint256 rewardRatePerSecond;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.14/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

uint256 constant AlmostOneWord = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;
uint256 constant Slot0xC0 = 0xc0;

// abi.encodeWithSignature("transferFrom(address,address,uint256)")
uint256 constant ERC20_transferFrom_signature =
    (0x23b872dd00000000000000000000000000000000000000000000000000000000);
uint256 constant ERC20_transferFrom_sig_ptr = 0x0;
uint256 constant ERC20_transferFrom_from_ptr = 0x04;
uint256 constant ERC20_transferFrom_to_ptr = 0x24;
uint256 constant ERC20_transferFrom_amount_ptr = 0x44;
uint256 constant ERC20_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("transfer(address,uint256)")
uint256 constant ERC20_transfer_signature =
    (0xa9059cbb00000000000000000000000000000000000000000000000000000000);

uint256 constant ERC20_transfer_sig_ptr = 0x0;
uint256 constant ERC20_transfer_to_ptr = 0x04;
uint256 constant ERC20_transfer_amount_ptr = 0x24;
uint256 constant ERC20_transfer_length = 0x44; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("NoContract(address)")
uint256 constant NoContract_error_signature =
    (0x5f15d67200000000000000000000000000000000000000000000000000000000);
uint256 constant NoContract_error_sig_ptr = 0x0;
uint256 constant NoContract_error_token_ptr = 0x4;
uint256 constant NoContract_error_length = 0x24; // 4 + 32 == 36

// abi.encodeWithSignature(
//     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
// )
uint256 constant TokenTransferGenericFailure_error_signature =
    (0xf486bc8700000000000000000000000000000000000000000000000000000000);
uint256 constant TokenTransferGenericFailure_error_sig_ptr = 0x0;
uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x4;
uint256 constant TokenTransferGenericFailure_error_from_ptr = 0x24;
uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x44;
uint256 constant TokenTransferGenericFailure_error_id_ptr = 0x64;
uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0x84;

// 4 + 32 * 5 == 164
uint256 constant TokenTransferGenericFailure_error_length = 0xa4;

// abi.encodeWithSignature(
//     "BadReturnValueFromERC20OnTransfer(address,address,address,uint256)"
// )
uint256 constant BadReturnValueFromERC20OnTransfer_error_signature =
    (0x9889192300000000000000000000000000000000000000000000000000000000);
uint256 constant BadReturnValueFromERC20OnTransfer_error_sig_ptr = 0x0;
uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x4;
uint256 constant BadReturnValueFromERC20OnTransfer_error_from_ptr = 0x24;
uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x44;
uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x64;

// 4 + 32 * 4 == 132
uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x84;

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 3;
uint256 constant MemoryExpansionCoefficient = 0x200;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title TokenTransferrerErrors
 */
interface TokenTransferrerErrors {
    error ErrorTransferETH(address caller, address to, uint256 value);

    /**
     * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
     *      transfer reverts.
     *
     * @param token      The token for which the transfer was attempted.
     * @param from       The source of the attempted transfer.
     * @param to         The recipient of the attempted transfer.
     * @param identifier The identifier for the attempted transfer.
     * @param amount     The amount for the attempted transfer.
     */
    error TokenTransferGenericFailure(
        address token, address from, address to, uint256 identifier, uint256 amount
    );

    /**
     * @dev Revert with an error when an ERC20 token transfer returns a falsey
     *      value.
     *
     * @param token      The token for which the ERC20 transfer was attempted.
     * @param from       The source of the attempted ERC20 transfer.
     * @param to         The recipient of the attempted ERC20 transfer.
     * @param amount     The amount for the attempted ERC20 transfer.
     */
    error BadReturnValueFromERC20OnTransfer(
        address token, address from, address to, uint256 amount
    );

    /**
     * @dev Revert with an error when an account being called as an assumed
     *      contract does not have code and returns no data.
     *
     * @param account The account that should contain code.
     */
    error NoContract(address account);

    /**
     * @dev Revert if the {_to} callback is the same as the souce (address(this))
     */
    error SelfCallbackTransfer();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20Callback {
    /// @notice receiveERC20 should be used as the "receive" callback of native token but for erc20
    /// @dev Be sure to limit the access of this call.
    /// @param _token transfered token
    /// @param _value The value of the transfer
    function receiveERC20(address _token, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBaseVesta {
    error NonReentrancy();
    error InvalidPermission();
    error InvalidAddress();
    error CannotBeNativeChainToken();
    error InvalidContract();
    error NumberIsZero();
    error SanitizeMsgValueFailed();

    event PermissionChanged(address indexed _address, bytes1 newPermission);

    /**
     * @notice setPermission to an address so they have access to specific functions.
     * 	@dev can add multiple permission by using | between them
     * 	@param _address the address that will receive the permissions
     * 	@param _permission the bytes permission(s)
     */
    function setPermission(address _address, bytes1 _permission) external;

    /**
     * @notice get the permission level on an address
     * 	@param _address the address you want to check the permission on
     * 	@return accessLevel the bytes code of the address permission
     */
    function getPermissionLevel(address _address) external view returns (bytes1);

    /**
     * @notice Verify if an address has specific permissions
     * 	@param _address the address you want to check
     * 	@param _accessLevel the access level you want to verify on
     * 	@return hasAccess return true if the address has access
     */
    function hasPermissionLevel(address _address, bytes1 _accessLevel)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ESingleRewardStaking {
  error RewardPeriodStillActive();

  event RewardAdded(uint256 _reward);
  event Staked(address indexed _user, uint256 _amount);
  event Withdrawn(address indexed _user, uint256 _amount);
  event RewardPaid(address indexed _user, uint256 _reward);
  event RewardsDurationUpdated(uint256 _newDuration);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

import "./Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing { }

    function __Context_init_unchained() internal onlyInitializing { }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
            (isTopLevelCall && _initialized < 1)
                || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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