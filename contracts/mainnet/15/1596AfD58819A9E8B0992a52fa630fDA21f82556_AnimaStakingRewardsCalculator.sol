// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IAnima is IERC20, IERC20Metadata {
  function CAP() external view returns (uint256);

  function mintFor(address _for, uint256 _amount) external;

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../lib/FloatingPointConstants.sol";
import "../Utils/Totals.sol";
import "./IAnimaStakingRewardsCalculator.sol";
import "../Anima/IAnima.sol";
import "../Productivity/IProductivity.sol";
import "../ERC20/ITokenMinter.sol";
import "../ERC20/ITokenSpender.sol";
import { EpochConfigurable } from "../Utils/EpochConfigurable.sol";
import "./IAnimaStakingRewardsStorage.sol";
import "../Productivity/IAverageProductivityCalculator.sol";
import "../ERC20/IGlobalTokenMetrics.sol";

uint constant NO_REALM = 10 ** 18;

contract AnimaStakingRewardsCalculator is
  IAnimaStakingRewardsCalculator,
  EpochConfigurable
{
  IAverageProductivityCalculator
    public immutable AVERAGE_PRODUCTIVITY_CALCULATOR;
  IGlobalTokenMetrics public immutable GLOBAL_TOKEN_METRICS;
  IAnimaStakingRewardsStorage public immutable STORAGE;

  uint public PRODUCTIVITY_RATIO;
  uint public EPOCH_AVERAGE_PERIOD = 30;
  uint public TOTAL_BURN_POOL_PERCENTAGE = 10000;

  uint public immutable MAX_STAKER_BONUS = 100_000;
  uint public immutable REALMER_PERCENTAGE = 100_000;

  uint public immutable MAX_REWARDS_PERIOD = 30 days;
  uint public immutable CHAMBER_VESTING = 30 days;
  uint public immutable REALM_STAKE_VESTING = 5 days;

  constructor(
    address _manager,
    address _globalTokenMetrics,
    address _averageProductivityCalculator,
    address _storage
  ) EpochConfigurable(_manager, 1 days, 0 hours) {
    GLOBAL_TOKEN_METRICS = IGlobalTokenMetrics(_globalTokenMetrics);
    AVERAGE_PRODUCTIVITY_CALCULATOR = IAverageProductivityCalculator(
      _averageProductivityCalculator
    );
    STORAGE = IAnimaStakingRewardsStorage(_storage);

    PRODUCTIVITY_RATIO = (5 * (10 ** 18)) / DECIMAL_POINT;
  }

  struct Calc {
    uint epoch;
    uint rewardsPool;
    uint circulatingSupply;
    uint mintedTimespan;
    uint stakedTimespan;
    uint lastStakerCollectedTimespan;
    uint lastRealmerCollectedTimespan;
    uint averageRealmProductivityGains;
    uint realmStakedAnima;
  }

  function currentBaseRewards()
    external
    view
    returns (
      uint stakerRewards,
      uint realmerRewards,
      uint burnRatio,
      uint rewardsPool
    )
  {
    (rewardsPool, burnRatio) = _currentRewardsPool();

    uint circulatingSupply = GLOBAL_TOKEN_METRICS
      .currentAverageInCirculationView(EPOCH_AVERAGE_PERIOD);

    (stakerRewards, realmerRewards, ) = _calculateRewards(
      rewardsPool,
      MAX_REWARDS_PERIOD,
      1 ether,
      0,
      0,
      MAX_REWARDS_PERIOD,
      MAX_REWARDS_PERIOD,
      MAX_REWARDS_PERIOD,
      circulatingSupply
    );
  }

  function baseRewardsAtEpochBatch(
    uint _startEpoch,
    uint _endEpoch
  )
    external
    view
    returns (
      uint[] memory stakerRewards,
      uint[] memory realmerRewards,
      uint[] memory burnRatios,
      uint[] memory rewardPools
    )
  {
    (rewardPools, burnRatios) = _epochRewardsPoolBatch(_startEpoch, _endEpoch);
    uint[] memory circulatingSupplies = GLOBAL_TOKEN_METRICS
      .averageInCirculationBatch(_startEpoch, _endEpoch, EPOCH_AVERAGE_PERIOD);

    stakerRewards = new uint[](rewardPools.length);
    realmerRewards = new uint[](rewardPools.length);
    for (uint i = 0; i < rewardPools.length; i++) {
      (stakerRewards[i], realmerRewards[i], ) = _calculateRewards(
        rewardPools[i],
        MAX_REWARDS_PERIOD,
        1 ether,
        0,
        0,
        MAX_REWARDS_PERIOD,
        MAX_REWARDS_PERIOD,
        MAX_REWARDS_PERIOD,
        circulatingSupplies[i]
      );
    }
  }

  function estimateChamberRewards(
    uint _additionalAnima,
    uint _realmId
  ) external view returns (uint, uint, uint) {
    (
      uint[] memory bonuses,
      uint[] memory rewards,
      uint[] memory stakedAverage
    ) = estimateChamberRewardsBatch(
        _additionalAnima,
        ArrayUtils.toMemoryArray(_realmId, 1)
      );
    return (bonuses[0], rewards[0], stakedAverage[0]);
  }

  function estimateChamberRewardsBatch(
    uint _additionalAnima,
    uint[] memory _realmIds
  )
    public
    view
    returns (
      uint[] memory bonuses,
      uint[] memory rewards,
      uint[] memory stakedAverage
    )
  {
    Calc memory calc;
    calc.epoch = currentEpoch();
    (calc.rewardsPool, ) = _currentRewardsPool();
    calc.circulatingSupply = GLOBAL_TOKEN_METRICS
      .currentAverageInCirculationView(EPOCH_AVERAGE_PERIOD);

    bonuses = new uint[](_realmIds.length);
    rewards = new uint[](_realmIds.length);
    stakedAverage = new uint[](_realmIds.length);

    for (uint i = 0; i < _realmIds.length; i++) {
      calc.averageRealmProductivityGains = _averageRealmProductivity(
        calc.epoch,
        _realmIds[i]
      );
      (calc.realmStakedAnima, stakedAverage[i]) = _stakedAnima(_realmIds[i]);

      bonuses[i] = _calculateStakingBonus(
        calc.averageRealmProductivityGains,
        calc.realmStakedAnima + _additionalAnima,
        MAX_REWARDS_PERIOD
      );
      (rewards[i], , ) = _calculateRewards(
        calc.rewardsPool,
        MAX_REWARDS_PERIOD,
        1 ether,
        calc.averageRealmProductivityGains,
        calc.realmStakedAnima + _additionalAnima,
        MAX_REWARDS_PERIOD,
        MAX_REWARDS_PERIOD,
        MAX_REWARDS_PERIOD,
        calc.circulatingSupply
      );
    }
  }

  function calculateRewardsView(
    uint _animaAmount,
    ChamberRewardsStorage memory _chamberInfo,
    uint256[] calldata _params
  )
    external
    view
    override
    returns (uint256 stakerRewards, uint256 realmerRewards, uint256 vestedStake)
  {
    Calc memory calc;
    calc.epoch = currentEpoch();

    (calc.rewardsPool, ) = _currentRewardsPool();
    calc.circulatingSupply = GLOBAL_TOKEN_METRICS
      .currentAverageInCirculationView(EPOCH_AVERAGE_PERIOD);

    uint _averageRealmProductivityGains = _averageRealmProductivity(
      calc.epoch,
      _chamberInfo.realmId
    );

    _calculateChamberTimes(calc, _chamberInfo);

    (, uint realmStakedAnima) = _stakedAnima(_chamberInfo.realmId);

    (stakerRewards, realmerRewards, vestedStake) = _calculateRewards(
      calc.rewardsPool,
      calc.mintedTimespan,
      _animaAmount,
      _averageRealmProductivityGains,
      realmStakedAnima,
      calc.stakedTimespan,
      calc.lastStakerCollectedTimespan,
      calc.lastRealmerCollectedTimespan,
      calc.circulatingSupply
    );
  }

  function _calculateChamberTimes(
    Calc memory calc,
    ChamberRewardsStorage memory _chamberInfo
  ) internal view {
    calc.mintedTimespan = _calculateElapsedTime(_chamberInfo.mintedAt);
    calc.stakedTimespan = _calculateElapsedTime(_chamberInfo.stakedAt);
    calc.lastStakerCollectedTimespan = _calculateElapsedTime(
      _chamberInfo.lastStakerCollectedAt
    );
    calc.lastRealmerCollectedTimespan = _calculateElapsedTime(
      _chamberInfo.lastRealmerCollectedAt
    );
    if (
      _chamberInfo.lastStakerCollectedAt == 0 ||
      calc.lastStakerCollectedTimespan > calc.mintedTimespan
    ) {
      calc.lastStakerCollectedTimespan = calc.mintedTimespan;
    }
    if (
      _chamberInfo.lastRealmerCollectedAt == 0 ||
      calc.lastRealmerCollectedTimespan > calc.stakedTimespan
    ) {
      calc.lastRealmerCollectedTimespan = calc.stakedTimespan;
    }
  }

  function calculateRewards(
    uint _animaAmount,
    ChamberRewardsStorage memory _chamberInfo,
    uint256[] calldata params
  )
    external
    override
    returns (uint256 stakerRewards, uint256 realmerRewards, uint256 vestedStake)
  {
    Calc memory calc;
    calc.epoch = currentEpoch();

    (calc.rewardsPool, ) = _currentRewardsPool();
    calc.circulatingSupply = GLOBAL_TOKEN_METRICS.currentAverageInCirculation(
      EPOCH_AVERAGE_PERIOD
    );

    uint _averageRealmProductivityGains = _averageRealmProductivity(
      calc.epoch,
      _chamberInfo.realmId
    );

    (, uint realmStakedAnima) = _stakedAnima(_chamberInfo.realmId);

    _calculateChamberTimes(calc, _chamberInfo);
    (stakerRewards, realmerRewards, vestedStake) = _calculateRewards(
      calc.rewardsPool,
      calc.mintedTimespan,
      _animaAmount,
      _averageRealmProductivityGains,
      realmStakedAnima,
      calc.stakedTimespan,
      calc.lastStakerCollectedTimespan,
      calc.lastRealmerCollectedTimespan,
      calc.circulatingSupply
    );
  }

  function _calculateRewards(
    uint _rewardsPool,
    uint _timeSinceChamberMinted,
    uint _animaAmount,
    uint _averageRealmProductivityGains,
    uint _realmStakedAnima,
    uint _timeSinceChamberStaked,
    uint _timeSinceStakerCollected,
    uint _timeSinceRealmerCollected,
    uint _circulatingSupply
  )
    internal
    view
    returns (uint256 stakerRewards, uint256 realmerRewards, uint vestedStake)
  {
    vestedStake = _vestedChamberStake(_timeSinceChamberMinted, _animaAmount);
    uint baseReward = (_rewardsPool * vestedStake) / (_circulatingSupply + 1);

    stakerRewards = baseReward;
    if (_timeSinceChamberStaked > 0) {
      // if staked on a Realm
      uint stakingBonus = _calculateStakingBonus(
        _averageRealmProductivityGains,
        _realmStakedAnima,
        _timeSinceChamberStaked
      );

      stakerRewards = (baseReward * (ONE_HUNDRED + stakingBonus)) / ONE_HUNDRED;
      uint realmerRewardsPercentage = _vestedRealmerPercentage(
        _timeSinceChamberStaked
      );
      realmerRewards = (baseReward * realmerRewardsPercentage) / ONE_HUNDRED;
    }

    return (
      (stakerRewards * _timeSinceStakerCollected) / MAX_REWARDS_PERIOD,
      (realmerRewards * _timeSinceRealmerCollected) / MAX_REWARDS_PERIOD,
      vestedStake
    );
  }

  function _averageRealmProductivity(
    uint _epoch,
    uint _realmId
  ) internal view returns (uint) {
    return
      AVERAGE_PRODUCTIVITY_CALCULATOR.averageRealmProductivityGains(
        _epoch,
        _realmId,
        EPOCH_AVERAGE_PERIOD
      );
  }

  function _currentRewardsPool() internal view returns (uint, uint) {
    (uint ratio, uint burns, ) = GLOBAL_TOKEN_METRICS.currentBurnRatio(
      EPOCH_AVERAGE_PERIOD
    );

    if (ratio > ONE_HUNDRED) {
      ratio = ONE_HUNDRED;
    }
    return (
      (TOTAL_BURN_POOL_PERCENTAGE * ((ratio) * burns)) / ONE_HUNDRED_SQUARE,
      ratio
    );
  }

  function _epochRewardsPool(uint _epoch) internal view returns (uint, uint) {
    (uint burns, uint ratio, ) = GLOBAL_TOKEN_METRICS.burnRatioAtEpoch(
      _epoch,
      EPOCH_AVERAGE_PERIOD
    );

    if (ratio > ONE_HUNDRED) {
      ratio = ONE_HUNDRED;
    }
    return (
      (TOTAL_BURN_POOL_PERCENTAGE * ((ratio) * burns)) / ONE_HUNDRED_SQUARE,
      ratio
    );
  }

  function _epochRewardsPoolBatch(
    uint _startEpoch,
    uint _endEpoch
  ) internal view returns (uint[] memory, uint[] memory) {
    (uint[] memory burns, uint[] memory ratios, ) = GLOBAL_TOKEN_METRICS
      .burnRatiosAtEpochBatch(_startEpoch, _endEpoch, EPOCH_AVERAGE_PERIOD);

    uint[] memory rewardPools = new uint[](_endEpoch - _startEpoch);
    for (uint i = 0; i < rewardPools.length; i++) {
      if (ratios[i] > ONE_HUNDRED) {
        ratios[i] = ONE_HUNDRED;
      }

      rewardPools[i] =
        (TOTAL_BURN_POOL_PERCENTAGE * ((ratios[i]) * burns[i])) /
        ONE_HUNDRED_SQUARE;
    }
    return (rewardPools, ratios);
  }

  function _vestedChamberStake(
    uint _stakedTime,
    uint _stake
  ) internal pure returns (uint) {
    if (_stakedTime > CHAMBER_VESTING) {
      return _stake;
    }
    return (_stake * _stakedTime) / CHAMBER_VESTING;
  }

  function _vestedStakerBonusPercentage(
    uint _stakedTime
  ) internal pure returns (uint) {
    if (_stakedTime == 0) {
      return 0;
    }

    if (_stakedTime > REALM_STAKE_VESTING) {
      return MAX_STAKER_BONUS;
    }
    return (MAX_STAKER_BONUS * _stakedTime) / REALM_STAKE_VESTING;
  }

  function _vestedRealmerPercentage(
    uint _stakedTime
  ) internal pure returns (uint) {
    if (_stakedTime == 0) {
      return 0;
    }

    if (_stakedTime > REALM_STAKE_VESTING) {
      return REALMER_PERCENTAGE;
    }
    return (REALMER_PERCENTAGE * _stakedTime) / REALM_STAKE_VESTING;
  }

  function _stakedAnima(
    uint _realmId
  ) internal view returns (uint current, uint average) {
    int[] memory deltas;
    uint epoch = currentEpoch();
    (current, deltas) = STORAGE.stakedAmountWithDeltas(
      _realmId,
      epoch - EPOCH_AVERAGE_PERIOD,
      epoch
    );
    return (
      current,
      1 + Totals.calculateTotalBasedOnDeltas(current, deltas) / deltas.length
    );
  }

  function _calculateStakingBonus(
    uint _averageRealmProductivityGains,
    uint _realmStakedAnima,
    uint _timeSinceStaked
  ) internal view returns (uint stakingBonus) {
    // max staking bonus
    stakingBonus = _vestedStakerBonusPercentage(_timeSinceStaked);

    stakingBonus =
      (stakingBonus * _averageRealmProductivityGains * PRODUCTIVITY_RATIO) /
      (1 + _realmStakedAnima);

    if (stakingBonus > MAX_STAKER_BONUS) {
      return MAX_STAKER_BONUS;
    }
  }

  function _calculateElapsedTime(uint _timestamp) internal view returns (uint) {
    // never staked/minted/collected
    if (_timestamp == 0) {
      return 0;
    }

    uint timespan = block.timestamp - _timestamp;
    if (timespan > MAX_REWARDS_PERIOD) {
      return MAX_REWARDS_PERIOD;
    }
    return timespan;
  }

  //---------------------------
  // Admin
  //---------------------------

  function updateProductivityRatio(uint _ratio) external onlyAdmin {
    PRODUCTIVITY_RATIO = _ratio;
  }

  function updateEpochAverage(uint _burns) external onlyAdmin {
    EPOCH_AVERAGE_PERIOD = _burns;
  }

  function updateMonthlyPoolPercentage(uint _percentage) external onlyAdmin {
    require(_percentage <= ONE_HUNDRED, "Invalid percentage");
    TOTAL_BURN_POOL_PERCENTAGE = _percentage;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./IAnimaStakingRewardsStorage.sol";

interface IAnimaStakingRewardsCalculator {
  function MAX_REWARDS_PERIOD() external view returns (uint256);

  function currentBaseRewards()
    external
    view
    returns (
      uint stakerRewards,
      uint realmerRewards,
      uint burnRatio,
      uint rewardsPool
    );

  function baseRewardsAtEpochBatch(
    uint startEpoch,
    uint endEpoch
  )
    external
    view
    returns (
      uint[] memory stakerRewards,
      uint[] memory realmerRewards,
      uint[] memory burnRatios,
      uint[] memory rewardPools
    );

  function estimateChamberRewards(
    uint _additionalAnima,
    uint _realmId
  ) external view returns (uint boost, uint rewards, uint stakedAverage);

  function estimateChamberRewardsBatch(
    uint _additionalAnima,
    uint[] calldata _realmId
  )
    external
    view
    returns (
      uint[] memory bonuses,
      uint[] memory rewards,
      uint[] memory stakedAverage
    );

  function calculateRewardsView(
    uint _animaAmount,
    ChamberRewardsStorage memory _chamberInfo,
    uint256[] calldata params
  )
    external
    view
    returns (
      uint256 stakerRewards,
      uint256 realmerRewards,
      uint256 vestedStake
    );

  function calculateRewards(
    uint _animaAmount,
    ChamberRewardsStorage memory _chamberInfo,
    uint256[] calldata params
  )
    external
    returns (
      uint256 stakerRewards,
      uint256 realmerRewards,
      uint256 vestedStake
    );
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

struct ChamberRewardsStorage {
  uint32 realmId;
  uint32 mintedAt;
  uint32 stakedAt;
  uint32 chamberStakedIndex;
  uint32 lastRealmerCollectedAt;
  uint32 lastStakerCollectedAt;
}

struct RealmRewardsStorage {
  uint32 lastCapacityAdjustedAt;
  uint lastCapacityUsed;
}

error ChamberAlreadyStaked(uint _realmId, uint _chamberId);
error ChamberNotStaked(uint _realmId, uint _chamberId);

interface IAnimaStakingRewardsStorage {
  function realmChamberIds(uint _realmId) external view returns (uint[] memory);

  function loadChamberInfo(
    uint256 _chamberId
  ) external view returns (ChamberRewardsStorage memory);

  function loadRealmInfo(
    uint256 _realmId
  ) external view returns (RealmRewardsStorage memory);

  function updateStakingRewards(
    uint256 _chamberId,
    bool _updateStakerTimestamp,
    bool _updateRealmerTimestamp,
    uint256 _lastUsedCapacity
  ) external;

  function stakedAmountWithDeltas(
    uint _realmId,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint current, int[] memory deltas);

  function checkStaked(
    uint256 _chamberId
  ) external view returns (bool, uint256);

  function registerChamberStaked(uint256 _chamberId, uint256 _realmId) external;

  function registerChamberCompound(
    uint256 _chamberId,
    uint _rewardsAmount
  ) external;

  function unregisterChamberStaked(
    uint256 _chamberId,
    uint256 _realmId
  ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IGloballyStakedTokenCalculator {
  function currentGloballyStakedAverage(
    uint _epochSpan
  )
    external
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function globallyStakedAverageView(
    uint _epoch,
    uint _epochSpan,
    bool _includeCurrent
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function globallyStakedAverageBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory rawTotalStaked,
      int[] memory totalStaked,
      uint[] memory circulatingSupply,
      int[] memory effectiveSupply,
      uint[] memory percentage
    );

  function stakedAmountsBatch(
    uint _epochStart,
    uint _epochEnd
  )
    external
    view
    returns (address[] memory stakingAddresses, uint[][] memory stakedAmounts);

  function circulatingSupplyBatch(
    uint _epochStart,
    uint _epochEnd
  ) external view returns (uint[] memory circulatingSupplies);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IGloballyStakedTokenCalculator.sol";
import "../Manager/ManagerModifier.sol";
import "../ERC20/ITokenMinter.sol";
import "../ERC20/ITokenSpender.sol";
import "../Utils/EpochConfigurable.sol";
import "../Utils/Totals.sol";

struct HistoryData {
  uint[] epochs;
  uint[] mints;
  uint[] burns;
  uint[] supply;
  uint[] totalStaked;
  address[] stakingAddresses;
  uint[][] stakedPerAddress;
}

interface IGlobalTokenMetrics {
  function historyMetrics(
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (HistoryData memory result);

  function epochCirculatingBatch(
    uint _epochStart,
    uint _epochEnd
  ) external view returns (uint[] memory);

  function currentAverageInCirculation(uint _epochSpan) external returns (uint);

  function currentAverageInCirculationView(
    uint _epochSpan
  ) external view returns (uint);

  function averageInCirculation(
    uint _epoch,
    uint _epochSpan
  ) external view returns (uint);

  function averageInCirculationBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  ) external view returns (uint[] memory result);

  function currentStakedRatio(
    uint _epochSpan
  )
    external
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function currentStakedRatioView(
    uint _epochSpan
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function stakedRatioAtEpoch(
    uint _epoch,
    uint _epochSpan
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function stakedRatioAtEpochBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory rawTotalStaked,
      int[] memory totalStaked,
      uint[] memory circulatingSupply,
      int[] memory effectiveSupply,
      uint[] memory percentage
    );

  function currentBurnRatio(
    uint _epochSpan
  ) external view returns (uint burnRatio, uint totalBurns, uint totalMints);

  function burnRatioAtEpoch(
    uint _epoch,
    uint _epochSpan
  ) external view returns (uint burnRatio, uint totalBurns, uint totalMints);

  function burnRatiosAtEpochBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory ratios,
      uint[] memory totalBurns,
      uint[] memory totalMints
    );

  function tokenMints(
    uint epochStart,
    uint epochEnd
  ) external view returns (uint[] memory);

  function tokenBurns(
    uint epochStart,
    uint epochEnd
  ) external view returns (uint[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

uint constant MINTER_ADVENTURER_BUCKET = 1;
uint constant MINTER_REALM_BUCKET = 2;
uint constant MINTER_STAKER_BUCKET = 3;

interface ITokenMinter is IEpochConfigurable {
  function getEpochValue(uint _epoch) external view returns (uint);

  function getEpochValueBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint[] memory result);

  function getBucketEpochValueBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint[] memory result);

  function getEpochValueBatchTotal(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint result);

  function getBucketEpochValueBatchTotal(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint result);

  function mint(address _owner, uint _amount, uint _bucket) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

uint constant SPENDER_ADVENTURER_BUCKET = 1;
uint constant SPENDER_REALM_BUCKET = 2;

interface ITokenSpender is IEpochConfigurable {
  function getEpochValue(uint _epoch) external view returns (uint);

  function getEpochValueBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint[] memory result);

  function getBucketEpochValueBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint[] memory result);

  function getEpochValueBatchTotal(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint result);

  function getBucketEpochValueBatchTotal(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint result);

  function spend(address _owner, uint _amount, uint _bucket) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
uint256 constant ROUNDING_ADJUSTER = DECIMAL_POINT - 1;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }

  modifier onlyConfigManager() {
    require(MANAGER.isManager(msg.sender, 4), "Manager: Not config manager");
    _;
  }

  modifier onlyTokenSpender() {
    require(MANAGER.isManager(msg.sender, 5), "Manager: Not token spender");
    _;
  }

  modifier onlyTokenEmitter() {
    require(MANAGER.isManager(msg.sender, 6), "Manager: Not token emitter");
    _;
  }

  modifier onlyPauser() {
    require(
      MANAGER.isAdmin(msg.sender) || MANAGER.isManager(msg.sender, 6),
      "Manager: Not pauser"
    );
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Productivity/IProductivity.sol";
import "../Utils/EpochConfigurable.sol";

interface IAverageProductivityCalculator {
  function currentRealmProductivityGains(
    uint _realmId
  ) external view returns (uint);

  function realmProductivityGains(
    uint _epoch,
    uint _realmId
  ) external view returns (uint);

  function realmProductivityGainsBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _realmId
  ) external view returns (uint[] memory result);

  function currentAverageRealmProductivityGains(
    uint _realmId,
    uint _epochSpan
  ) external view returns (uint);

  function averageRealmProductivityGains(
    uint _epoch,
    uint _realmId,
    uint _epochSpan
  ) external view returns (uint);

  function averageRealmProductivityGainsBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _realmId,
    uint _epochSpan
  ) external view returns (uint[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

interface IProductivity is IEpochConfigurable {
  // All time Productivity
  function currentProductivity(uint256 _realmId) external view returns (uint);

  function currentProductivityBatch(
    uint[] calldata _realmIds
  ) external view returns (uint[] memory result);

  function previousEpochsProductivityTotals(
    uint _realmId,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) external view returns (uint gains, uint losses);

  function epochsProductivityTotals(
    uint _realmId,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint gains, uint losses);

  function previousEpochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) external view returns (uint[] memory gains, uint[] memory spending);

  function epochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint[] memory gains, uint[] memory spending);

  function change(uint256 _realmId, int _delta, bool _includeInTotals) external;

  function changeBatch(
    uint256[] calldata _tokenIds,
    int[] calldata _deltas,
    bool _includeInTotals
  ) external;

  function changeBatch(
    uint256[] calldata _tokenIds,
    int _delta,
    bool _includeInTotals
  ) external;

  function increase(
    uint256 _realmId,
    uint _delta,
    bool _includeInTotals
  ) external;

  function increaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _delta,
    bool _includeInTotals
  ) external;

  function increaseBatch(
    uint256[] calldata _tokenIds,
    uint _delta,
    bool _includeInTotals
  ) external;

  function decrease(
    uint256 _realmId,
    uint _delta,
    bool _includeInTotals
  ) external;

  function decreaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _delta,
    bool _includeInTotals
  ) external;

  function decreaseBatch(
    uint256[] calldata _tokenIds,
    uint _delta,
    bool _includeInTotals
  ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

library ArrayUtils {
  error ArrayLengthMismatch(uint _length1, uint _length2);
  error InvalidArrayOrder(uint index);

  function ensureSameLength(uint _l1, uint _l2) internal pure {
    if (_l1 != _l2) {
      revert ArrayLengthMismatch(_l1, _l2);
    }
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4,
    uint _l5
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
    ensureSameLength(_l1, _l5);
  }

  function checkAddressesForDuplicates(
    address[] memory _tokenAddrs
  ) internal pure {
    address lastAddress;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (lastAddress > _tokenAddrs[i]) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
    }
  }

  function checkForDuplicates(uint[] memory _ids) internal pure {
    uint lastId;
    for (uint i = 0; i < _ids.length; i++) {
      if (lastId > _ids[i]) {
        revert InvalidArrayOrder(i);
      }
      lastId = _ids[i];
    }
  }

  function checkForDuplicates(
    address[] memory _tokenAddrs,
    uint[] memory _tokenIds
  ) internal pure {
    address lastAddress;
    int256 lastTokenId = -1;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (_tokenAddrs[i] > lastAddress) {
        lastTokenId = -1;
      }

      if (_tokenAddrs[i] < lastAddress || int(_tokenIds[i]) <= lastTokenId) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
      lastTokenId = int(_tokenIds[i]);
    }
  }

  function toSingleValueDoubleArray(
    uint[] memory _vals
  ) internal pure returns (uint[][] memory result) {
    result = new uint[][](_vals.length);
    for (uint i = 0; i < _vals.length; i++) {
      result[i] = ArrayUtils.toMemoryArray(_vals[i], 1);
    }
  }

  function toMemoryArray(
    uint _value,
    uint _length
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _value;
    }
  }

  function toMemoryArray(
    uint[] calldata _value
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_value.length);
    for (uint i = 0; i < _value.length; i++) {
      result[i] = _value[i];
    }
  }

  function toMemoryArray(
    address _address,
    uint _length
  ) internal pure returns (address[] memory result) {
    result = new address[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _address;
    }
  }

  function toMemoryArray(
    address[] calldata _addresses
  ) internal pure returns (address[] memory result) {
    result = new address[](_addresses.length);
    for (uint i = 0; i < _addresses.length; i++) {
      result[i] = _addresses[i];
    }
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Unlicensed

import "../lib/FloatingPointConstants.sol";

uint256 constant MASK_128 = ((1 << 128) - 1);
uint128 constant MASK_64 = ((1 << 64) - 1);

library Epoch {
  // Converts a given timestamp to an epoch using the specified duration and offset.
  // Example for battle timers resetting at noon UTC is: _duration = 1 days; _offset = 12 hours;
  function toEpochNumber(
    uint256 _timestamp,
    uint256 _duration,
    uint256 _offset
  ) internal pure returns (uint256) {
    return (_timestamp + _offset) / _duration;
  }

  // Here we assume that _config is a packed _duration (left 64 bits) and _offset (right 64 bits)
  function toEpochNumber(uint256 _timestamp, uint128 _config) internal pure returns (uint256) {
    return (_timestamp + (_config & MASK_64)) / ((_config >> 64) & MASK_64);
  }

  // Returns a value between 0 and ONE_HUNDRED which is the percentage of "completeness" of the epoch
  // result variable is reused for memory efficiency
  function toEpochCompleteness(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = (_config >> 64) & MASK_64;
    result = (ONE_HUNDRED * ((_timestamp + (_config & MASK_64)) % result)) / result;
  }

  // Converts a given epoch to a timestamp at the start of the epoch
  function epochToTimestamp(
    uint256 _epoch,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = _epoch * ((_config >> 64) & MASK_64);
    if (result > 0) {
      result -= (_config & MASK_64);
    }
  }

  // Create a config for the function above
  function toConfig(uint64 _duration, uint64 _offset) internal pure returns (uint128) {
    return (uint128(_duration) << 64) | uint128(_offset);
  }

  // Pack the epoch number with the config into a single uint256 for mappings
  function packEpoch(uint256 _epochNumber, uint128 _config) internal pure returns (uint256) {
    return (uint256(_config) << 128) | uint128(_epochNumber);
  }

  // Convert timestamp to Epoch and pack it with the config into a single uint256 for mappings
  function packTimestampToEpoch(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256) {
    return packEpoch(toEpochNumber(_timestamp, _config), _config);
  }

  // Unpack packedEpoch to epochNumber and config
  function unpack(
    uint256 _packedEpoch
  ) internal pure returns (uint256 epochNumber, uint128 config) {
    config = uint128(_packedEpoch >> 128);
    epochNumber = _packedEpoch & MASK_128;
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "./IEpochConfigurable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract EpochConfigurable is Pausable, ManagerModifier, IEpochConfigurable {
  uint128 public EPOCH_CONFIG;

  constructor(
    address _manager,
    uint64 _epochDuration,
    uint64 _epochOffset
  ) ManagerModifier(_manager) {
    EPOCH_CONFIG = Epoch.toConfig(_epochDuration, _epochOffset);
  }

  function currentEpoch() public view returns (uint) {
    return epochAtTimestamp(block.timestamp);
  }

  function epochAtTimestamp(uint _timestamp) public view returns (uint) {
    return Epoch.toEpochNumber(_timestamp, EPOCH_CONFIG);
  }

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  function updateEpochConfig(uint64 duration, uint64 offset) external onlyAdmin {
    EPOCH_CONFIG = Epoch.toConfig(duration, offset);
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./ArrayUtils.sol";

library Totals {
  /*
   * @dev Calculate the total value of an array of uints
   * @param _values An array of uints
   * @return sum The total value of the array
   */

  function calculateTotal(uint[] memory _values) internal pure returns (uint) {
    return calculateSubTotal(_values, 0, _values.length);
  }

  function calculateSubTotal(
    uint[] memory _values,
    uint _indexStart,
    uint _indexEnd
  ) internal pure returns (uint sum) {
    for (uint i = _indexStart; i < _indexEnd; i++) {
      sum += _values[i];
    }
  }

  function calculateTotalWithNonZeroCount(
    uint[] memory _values
  ) internal pure returns (uint total, uint nonZeroCount) {
    return calculateSubTotalWithNonZeroCount(_values, 0, _values.length);
  }

  function calculateSubTotalWithNonZeroCount(
    uint[] memory _values,
    uint _indexStart,
    uint _indexEnd
  ) internal pure returns (uint total, uint nonZeroCount) {
    for (uint i = _indexStart; i < _indexEnd; i++) {
      if (_values[i] > 0) {
        total += _values[i];
        nonZeroCount++;
      }
    }
  }

  /*
   * @dev Calculate the total value of an the current state and an array of gains, but only if the value is greater than 0 at any given point of time
   * @param _values An array of uints
   * @return sum The total value of the array
   */
  function calculateTotalBasedOnDeltas(
    uint currentValue,
    int[] memory _deltas
  ) internal pure returns (uint sum) {
    int signedCurrent = int(currentValue);
    for (uint i = _deltas.length; i > 0; i--) {
      signedCurrent -= _deltas[i - 1];
      sum += uint(currentValue);
    }
  }

  function calculateTotalBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint sum) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    for (uint i = _gains.length; i > 0; i--) {
      currentValue += _losses[i - 1];
      currentValue -= _gains[i - 1];
      sum += currentValue;
    }
  }

  function calculateAverageBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint sum) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    for (uint i = _gains.length; i > 0; i--) {
      currentValue += _losses[i - 1];
      currentValue -= _gains[i - 1];
      sum += currentValue;
    }
    sum = sum / _gains.length;
  }

  function calculateEachDayValueBasedOnDeltas(
    uint currentValue,
    int[] memory _deltas
  ) internal pure returns (uint[] memory values) {
    values = new uint[](_deltas.length);
    int signedCurrent = int(currentValue);
    for (uint i = _deltas.length; i > 0; i--) {
      signedCurrent -= _deltas[i - 1];
      values[i - 1] = uint(signedCurrent);
    }
  }

  function calculateEachDayValueBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint[] memory values) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    values = new uint[](_gains.length);
    uint signedCurrent = currentValue;
    for (uint i = _gains.length; i > 0; i--) {
      signedCurrent += _losses[i - 1];
      signedCurrent -= _gains[i - 1];
      values[i - 1] = uint(signedCurrent);
    }
  }
}