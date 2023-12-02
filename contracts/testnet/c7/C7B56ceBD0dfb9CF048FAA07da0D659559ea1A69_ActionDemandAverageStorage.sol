// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../SupplyDemand/AbstractEpochAverageStorage.sol";
import "../Utils/Epoch.sol";
import "./Actions.sol";

contract ActionDemandAverageStorage is ManagerModifier, AbstractEpochAverageStorage {
  using Epoch for uint256;

  mapping(uint => EpochAverageStorageConfig) public AVERAGE_STORAGE_CONFIG;

  constructor(address _manager) ManagerModifier(_manager) {
    ACTION_EPOCH_CONFIG[ACTION_ADVENTURER_VOID_CRAFTING] = Epoch.toConfig(
      DAILY_EPOCH_DURATION,
      DAILY_EPOCH_OFFSET
    );
    ACTION_AVERAGE_STORAGE_CONFIG[ACTION_ADVENTURER_VOID_CRAFTING] = EpochAverageStorageConfig(
      2,
      1,
      3
    ); // EMA3

    ACTION_EPOCH_CONFIG[ACTION_ADVENTURER_REALM_CRAFTING] = Epoch.toConfig(
      DAILY_EPOCH_DURATION,
      DAILY_EPOCH_OFFSET
    );
    ACTION_AVERAGE_STORAGE_CONFIG[ACTION_ADVENTURER_REALM_CRAFTING] = EpochAverageStorageConfig(
      6,
      1,
      7
    ); // EMA7
  }

  // group (action) => config
  mapping(uint => EpochAverageStorageConfig) public ACTION_AVERAGE_STORAGE_CONFIG;

  // group (action) => config
  mapping(uint => uint128) public ACTION_EPOCH_CONFIG;

  // group (action) => epoch => lab id => crafting count
  mapping(uint => mapping(uint => mapping(uint => uint32))) public actionDemand;

  function getDemandBatch(
    uint _action,
    uint[] calldata _subGroups
  ) external returns (uint256[] memory results) {
    return _getValueBatch(_action, _subGroups);
  }

  function getDemandViewBatch(
    uint _action,
    uint[] calldata _subGroups
  ) external view returns (uint256[] memory results) {
    return _getValueViewBatch(_action, _subGroups);
  }

  function getDemandPredictionBatch(
    uint _action,
    uint[] calldata _subGroups
  ) external view returns (uint256[] memory results) {
    return _getPredictionBatch(_action, _subGroups);
  }

  function increaseDemandBatch(
    uint _action,
    uint[] calldata _subGroups,
    uint[] calldata _deltas
  ) external onlyManager {
    uint epoch = _getCurrentEpoch(_action);

    mapping(uint => uint32) storage currentEpochActionStorage = actionDemand[_action][epoch];
    for (uint i = 0; i < _subGroups.length; i++) {
      currentEpochActionStorage[_subGroups[i]] += uint32(_deltas[i]);
    }
  }

  function _getConfig(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (EpochAverageStorageConfig memory) {
    return ACTION_AVERAGE_STORAGE_CONFIG[_group];
  }

  function _getCurrentValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (uint256) {
    return actionDemand[_group][_subGroup][_getCurrentEpoch(_group, _subGroup) - 1];
  }

  // the predicted value is the current weighted average of the current EMA average
  // and the rolling value of actions of current epoch
  // weighted by the time elapsed in the current epoch
  function _getPredictedNextValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (uint256) {
    uint rollingAverage = _getValueView(_group, _subGroup);
    uint currentCounts = actionDemand[_group][_getCurrentEpoch(_group)][_subGroup];

    uint epochCompleteness = Epoch.toEpochCompleteness(
      block.timestamp,
      ACTION_EPOCH_CONFIG[_group]
    );
    return epochCompleteness * rollingAverage + (ONE_HUNDRED - epochCompleteness) * currentCounts;
  }

  function _getCurrentEpoch(uint256 _group) internal view returns (uint256) {
    return Epoch.toEpochNumber(block.timestamp, ACTION_EPOCH_CONFIG[_group]);
  }

  function _getCurrentEpoch(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (uint256) {
    return _getCurrentEpoch(_group);
  }

  function forceUpdateBaseValue(uint _action, uint _subGroup, uint newValue) external onlyAdmin {
    _forceUpdateBaseValue(_action, _subGroup, newValue);
  }

  function updateEpochConfig(
    uint _action,
    uint64 _epochDuration,
    uint64 _epochOffset
  ) external onlyAdmin {
    ACTION_EPOCH_CONFIG[_action] = Epoch.toConfig(_epochDuration, _epochOffset);
  }

  function updateAverageStorageConfig(
    uint _action,
    uint _baseWeight,
    uint _epochWeight
  ) external onlyAdmin {
    ACTION_AVERAGE_STORAGE_CONFIG[_action].baseWeight = _baseWeight;
    ACTION_AVERAGE_STORAGE_CONFIG[_action].epochWeight = _epochWeight;
    ACTION_AVERAGE_STORAGE_CONFIG[_action].totalWeight = _baseWeight + _epochWeight;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint64 constant DAILY_EPOCH_DURATION = 1 days;
uint64 constant DAILY_EPOCH_OFFSET = 0 hours;

uint64 constant HOURLY_EPOCH_DURATION = 1 hours;
uint64 constant NO_OFFSET = 0 hours;

uint256 constant ACTION_LOCK = 101;

uint256 constant ACTION_ADVENTURER_HOMAGE = 1001;
uint256 constant ACTION_ADVENTURER_BATTLE_V3 = 1002;
uint256 constant ACTION_ADVENTURER_COLLECT_EPOCH_REWARDS = 1003;
uint256 constant ACTION_ADVENTURER_VOID_CRAFTING = 1004;
uint256 constant ACTION_ADVENTURER_REALM_CRAFTING = 1005;
uint256 constant ACTION_ADVENTURER_ANIMA_REGENERATION = 1006;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM = 2001;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM = 2002;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM_SHARD = 2011;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM_SHARD = 2012;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL_SHARD = 2021;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL_SHARD = 2022;

uint256 constant ACTION_ARMORY_STAKE_LAB = 2031;
uint256 constant ACTION_ARMORY_UNSTAKE_LAB = 2032;

uint256 constant ACTION_ARMORY_STAKE_COLLECTIBLE = 2041;
uint256 constant ACTION_ARMORY_UNSTAKE_COLLECTIBLE = 2042;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL = 2051;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL = 2052;

uint256 constant ACTION_REALM_COLLECT_COLLECTIBLES = 4001;
uint256 constant ACTION_REALM_BUILD_LAB = 4011;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../lib/FloatingPointConstants.sol";

struct EpochAverageStorageConfig {
  uint256 baseWeight;
  uint256 epochWeight;
  uint256 totalWeight;
}

abstract contract AbstractEpochAverageStorage {
  mapping(uint256 => EpochAverageStorageConfig) public config;
  mapping(uint256 => mapping(uint256 => uint256)) public baseValueEpoch;
  mapping(uint256 => mapping(uint256 => uint256)) public baseValue;

  function _getConfig(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (EpochAverageStorageConfig memory);

  function _getCurrentValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (uint256);

  function _getPredictedNextValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (uint256);

  function _getCurrentEpoch(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (uint256);

  function _predictNextValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view returns (uint256 result) {
    EpochAverageStorageConfig memory cfg = _getConfig(_group, _subGroup);

    result = _getValueView(_group, _subGroup);
    uint256 predictedValue = _getPredictedNextValue(_group, _subGroup);
    result = (result * cfg.baseWeight + predictedValue * cfg.epochWeight) / cfg.totalWeight;
  }

  function _getValue(uint256 _group, uint256 _subGroup) internal returns (uint256 result) {
    uint currentEpoch = _getCurrentEpoch(_group, _subGroup);
    if (currentEpoch == baseValueEpoch[_group][_subGroup]) {
      return baseValue[_group][_subGroup];
    }

    result = _getValueView(_group, _subGroup);
    baseValue[_group][_subGroup] = result;
    baseValueEpoch[_group][_subGroup] = currentEpoch;
  }

  function _getValueView(uint256 _group, uint256 _subGroup) internal view returns (uint256 result) {
    result = baseValue[_group][_subGroup];
    uint256 currentEpoch = _getCurrentEpoch(_group, _subGroup);
    if (currentEpoch == baseValueEpoch[_group][_subGroup]) {
      return baseValue[_group][_subGroup];
    }

    EpochAverageStorageConfig memory cfg = _getConfig(_group, _subGroup);
    result =
      (result * cfg.baseWeight + _getCurrentValue(_group, _subGroup) * cfg.epochWeight) /
      cfg.totalWeight;
  }

  function _getValueBatch(
    uint256 _group,
    uint256[] calldata _subGroups
  ) internal returns (uint256[] memory results) {
    results = new uint256[](_subGroups.length);
    for (uint i = 0; i < _subGroups.length; i++) {
      results[i] = _getValue(_group, _subGroups[i]);
    }
  }

  function _getValueViewBatch(
    uint256 _group,
    uint256[] calldata _subGroups
  ) internal view returns (uint256[] memory results) {
    results = new uint256[](_subGroups.length);
    for (uint i = 0; i < _subGroups.length; i++) {
      results[i] = _getValueView(_group, _subGroups[i]);
    }
  }

  function _getPredictionBatch(
    uint256 _group,
    uint256[] calldata _subGroups
  ) internal view returns (uint256[] memory results) {
    results = new uint256[](_subGroups.length);
    for (uint i = 0; i < _subGroups.length; i++) {
      results[i] = _getPredictedNextValue(_group, _subGroups[i]);
    }
  }

  function _forceUpdateBaseValue(uint _group, uint _subgroup, uint _newValue) internal {
    baseValue[_group][_subgroup] = _newValue;
    baseValueEpoch[_group][_subgroup] = _getCurrentEpoch(_group, _subgroup);
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

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