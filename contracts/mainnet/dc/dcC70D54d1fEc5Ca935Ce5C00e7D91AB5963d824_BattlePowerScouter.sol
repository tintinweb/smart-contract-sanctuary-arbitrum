// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAdventurerData {
  function initData(
    address[] calldata _addresses,
    uint256[] calldata _ids,
    bytes32[][] calldata _proofs,
    uint256[] calldata _professions,
    uint256[][] calldata _points
  ) external;

  function baseProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function aovProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function extensionProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function createFor(
    address _addr,
    uint256 _id,
    uint256[] calldata _points
  ) external;

  function createFor(address _addr, uint256 _id, uint256 _archetype) external;

  function addToBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function base(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function aov(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function extension(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

uint constant ADVENTURER_DATA_BASE = 0;
uint constant ADVENTURER_DATA_AOV = 1;
uint constant ADVENTURER_DATA_EXTENSION = 2;

interface IBatchAdventurerData {
  function add(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external;

  function update(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function updateRaw(address _addr, uint256 _id, uint256 _type, uint24[10] calldata _val) external;

  function updateBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external;

  function updateBatchRaw(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint24[10][] calldata _val
  ) external;

  function remove(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function removeBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external;

  function get(address _addr, uint256 _id, uint256 _type, uint256 _prop) external returns (uint256);

  function getRaw(address _addr, uint256 _id, uint256 _type) external returns (uint24[10] memory);

  function getMulti(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256[] calldata _prop
  ) external returns (uint256[] memory result);

  function getBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop
  ) external returns (uint256[] memory);

  function getBatchMulti(
    address[] calldata _addrs,
    uint256[] calldata _ids,
    uint256 _type,
    uint256[] calldata _props
  ) external returns (uint256[][] memory);

  function getRawBatch(
    address[] calldata _addrs,
    uint256[] calldata _ids,
    uint256 _type
  ) external returns (uint24[10][] memory result);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library traits {
  uint256 public constant ADV_TRAIT_GROUP_BASE = 0;

  // Base, _type = 0
  uint256 public constant ADV_TRAIT_BASE_LEVEL = 0;
  uint256 public constant ADV_TRAIT_BASE_XP = 1;
  uint256 public constant ADV_TRAIT_BASE_STRENGTH = 2;
  uint256 public constant ADV_TRAIT_BASE_DEXTERITY = 3;
  uint256 public constant ADV_TRAIT_BASE_CONSTITUTION = 4;
  uint256 public constant ADV_TRAIT_BASE_INTELLIGENCE = 5;
  uint256 public constant ADV_TRAIT_BASE_WISDOM = 6;
  uint256 public constant ADV_TRAIT_BASE_CHARISMA = 7;
  uint256 public constant ADV_TRAIT_BASE_CLASS = 8;

  uint256 public constant ADV_TRAIT_GROUP_ADVANCED = 1;
  // Advanced, _type = 1
  uint256 public constant ADV_TRAIT_ADVANCED_ARCHETYPE = 0;
  uint256 public constant ADV_TRAIT_ADVANCED_PROFESSION = 1;
  uint256 public constant ADV_TRAIT_ADVANCED_TRAINING_POINTS = 2;

  // Base Ttraits
  // See AdventurerData.sol for details
  uint256 public constant LEGACY_ADV_BASE_TRAIT_XP = 0;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_XP_BROKEN = 1;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_STRENGTH = 2;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_DEXTERITY = 3;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_CONSTITUTION = 4;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_INTELLIGENCE = 5;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_WISDOM = 6;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_CHARISMA = 7;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_HP = 8;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_HP_USED = 9;

  // AoV Traits
  // See AdventurerData.sol for details
  uint256 public constant LEGACY_ADV_AOV_TRAIT_LEVEL = 0;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_ARCHETYPE = 1;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_CLASS = 2;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_PROFESSION = 3;

  function baseTraitNames() public pure returns (string[10] memory) {
    return [
      "Level",
      "XP",
      "Strength",
      "Dexterity",
      "Constitution",
      "Intelligence",
      "Wisdom",
      "Charisma",
      "Class",
      ""
    ];
  }

  function advancedTraitNames() public pure returns (string[2] memory) {
    return ["Archetype", "Profession"];
  }

  function baseTraitName(uint256 traitId) public pure returns (string memory) {
    return baseTraitNames()[traitId];
  }

  function advancedTraitName(uint256 traitId) public pure returns (string memory) {
    return advancedTraitNames()[traitId];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IAdventurerEquipment {
  function equip(
    address _adventurerAddr,
    uint256 _adventurerId,
    uint256[] calldata _slots,
    uint256[] calldata _equipment
  ) external;

  function equipBatch(
    address[] calldata _adventurerAddrs,
    uint256[] calldata _adventurerIds,
    uint256[] calldata _slots,
    uint256[][] calldata _equipmentIds
  ) external;

  function getEquippedBatch(
    address[] calldata _adventurerAddrs,
    uint256[] calldata _adventurerIds
  ) external view returns (uint256[][] memory);

  function getEquipped(
    address _adventurerAddr,
    uint256 _adventurerId
  ) external view returns (uint256[] memory);
}

import "./IBattlePowerScouter.sol";
import "../Adventurer/IAdventurerData.sol";
import "../Adventurer/TraitConstants.sol";
import "../lib/SigmoidFunction.sol";
import "../AdventurerEquipment/IAdventurerEquipment.sol";
import "../Item/IRarityItemBattleUtilityData.sol";
import "../Item/RarityItemActionUtilityConstants.sol";
import "../Manager/ManagerModifier.sol";
import "../Adventurer/IBatchAdventurerData.sol";

uint256 constant BATTLE_BONUS_TYPE_BP_ID = 1;

struct ScouterCache {
  // we don't care about 256 -> 32 overflow here, in fact it's a method to save storage gas
  uint32 epochNumber;
  // realistically we won't hit 32-bit max anytime soon and this contract
  // is easily upgradable if this somehow happens in a few years
  int32 battlePower;
  // realistically we won't hit 16-bit max anytime soon and this contract
  uint16 level;
  bool stale;
}

struct ScouterData {
  uint256 battlePower;
  uint24[10] stats;
  uint256 baseLevel;
  uint256 adjustedLevel;
  uint256[] equipment;
  BattleUtility[] classUtility;
  BattleUtility[] peripheralUtility;
  uint[] mastery;
  PeripheralAdditiveBonus currentAdditive;
  PeripheralMultiplicativeBonus currentMultiplicative;
}

contract BattlePowerScouter is IBattlePowerScouter, ManagerModifier {
  event BattlePowerChanged(address adventurerAddress, uint adventurerTokenId, int battlePower);

  IBatchAdventurerData public adventurerData;
  IAdventurerEquipment public adventurerEquipmentData;
  IRarityItemBattleUtilityData public rarityItemUtilityData;

  mapping(address => mapping(uint256 => ScouterCache)) private battlePowerCache;

  mapping(uint256 => BattleUtility[]) private classBonuses;

  SigmoidConfig private statBoostConfig;

  constructor(
    address _manager,
    address _data,
    address _adventurerEquipment,
    address _rarityItemUtilityData
  ) ManagerModifier(_manager) {
    adventurerData = IBatchAdventurerData(_data);
    adventurerEquipmentData = IAdventurerEquipment(_adventurerEquipment);
    rarityItemUtilityData = IRarityItemBattleUtilityData(_rarityItemUtilityData);
    statBoostConfig.shiftY = 50000;
    statBoostConfig.leftCurve.ascending = true;
    statBoostConfig.leftCurve.yAdjustment = 0;
    statBoostConfig.leftCurve.rangeY = 50000;
    statBoostConfig.leftCurve.steepness = 400000;
    statBoostConfig.leftCurve.steepnessCoefficient = 125000;
    statBoostConfig.rightCurve.ascending = true;
    statBoostConfig.rightCurve.yAdjustment = -50000;
    statBoostConfig.rightCurve.rangeY = 100000;
    statBoostConfig.rightCurve.steepness = 200000;
    statBoostConfig.rightCurve.steepnessCoefficient = 150000;
  }

  // Most naive initial implementation
  function scanBattlePower(
    uint _fightEpoch,
    address _adventurerAddr,
    uint256 _adventurerId,
    address _opponentAddr,
    uint256 _opponentId,
    uint256[] calldata _params
  ) external onlyManager returns (BattlePowerScan memory) {
    BattlePowerScan memory scan;
    (scan.attackerBase, scan.attackerLevel) = _obtainBaseBattlePower(
      _fightEpoch,
      _adventurerAddr,
      _adventurerId,
      true
    );
    scan.attackerFinal = scan.attackerBase;

    (scan.opponentBase, scan.opponentLevel) = _obtainBaseBattlePower(
      _fightEpoch,
      _opponentAddr,
      _opponentId,
      false
    );
    scan.opponentFinal = scan.opponentBase;
    scan.probability = _calculateProbability(scan.attackerFinal, scan.opponentFinal);
    return scan;
  }

  function baseBattlePower(
    address _adventurerAddr,
    uint256 _adventurerId
  ) public returns (int256, uint256) {
    ScouterData memory data;
    data.stats = adventurerData.getRaw(_adventurerAddr, _adventurerId, traits.ADV_TRAIT_GROUP_BASE);
    data.classUtility = classBonuses[data.stats[traits.ADV_TRAIT_BASE_CLASS]];
    data.baseLevel = data.stats[traits.ADV_TRAIT_BASE_LEVEL];
    data.adjustedLevel = DECIMAL_POINT * data.baseLevel;

    data.equipment = adventurerEquipmentData.getEquipped(_adventurerAddr, _adventurerId);
    data.peripheralUtility = rarityItemUtilityData.rarityItemUtilityBatch(data.equipment);

    _calculateMastery(data);
    // First calculate additive bonuses
    _calculateAdditives(data);
    // Second calculate non-bp multiplicative bonuses
    _calculateMultiplicatives(data);
    // Third calculate final battle power
    _calculateBp(data);

    for (uint i = traits.ADV_TRAIT_BASE_STRENGTH; i < traits.ADV_TRAIT_BASE_CLASS; i++) {
      data.battlePower += data.stats[i] * DECIMAL_POINT;
    }

    data.battlePower += 20 * data.adjustedLevel;
    return (int256(data.battlePower), data.baseLevel);
  }

  function _calculateMastery(ScouterData memory data) internal view {
    // Additive bonuses
    data.mastery = new uint[](data.equipment.length);
    for (uint i = 0; i < data.equipment.length; i++) {
      if (!data.peripheralUtility[i].enabled) {
        data.mastery[i] = 0;
        continue;
      }
      LevelAdjustment memory adjustment = data.peripheralUtility[i].adjustment;

      if (data.baseLevel == adjustment.levelThreshold) {
        data.mastery[i] = ONE_HUNDRED;
      } else if (data.baseLevel < adjustment.levelThreshold) {
        uint diff = adjustment.levelThreshold - data.baseLevel;
        data.mastery[i] =
          ONE_HUNDRED -
          (ONE_HUNDRED * diff) /
          (diff + adjustment.reverseAdjustmentCoefficient);
      } else {
        uint diff = data.baseLevel - adjustment.levelThreshold;
        data.mastery[i] =
          ONE_HUNDRED +
          (ONE_HUNDRED * diff) /
          (diff + adjustment.adjustmentCoefficient);
      }
    }
  }

  function _calculateAdditives(ScouterData memory data) internal view {
    _calculateAdditives(data, data.classUtility);
    _calculateAdditives(data, data.peripheralUtility);
  }

  function _calculateAdditives(
    ScouterData memory data,
    BattleUtility[] memory battleUtility
  ) internal view {
    SigmoidConfig memory cfg = statBoostConfig;
    // Additive bonuses
    for (uint i = 0; i < battleUtility.length; i++) {
      if (!battleUtility[i].enabled) {
        continue;
      }
      for (uint j = 0; j < battleUtility[i].additiveBonuses.length; j++) {
        data.currentAdditive = battleUtility[i].additiveBonuses[j];
        if (!_verifyRestrictions(data.currentAdditive.restrictions, data)) {
          continue;
        }

        if (data.currentAdditive.bonusType == DataType.BASE) {
          data.stats[data.currentAdditive.bonusId] += uint24(
            _adjustMastery(data.currentAdditive.value, data.mastery[i]) / DECIMAL_POINT
          );
        }
      }
    }
  }

  function _calculateMultiplicatives(ScouterData memory data) internal view {
    _calculateMultiplicatives(data, data.classUtility);
    _calculateMultiplicatives(data, data.peripheralUtility);
  }

  function _calculateMultiplicatives(
    ScouterData memory data,
    BattleUtility[] memory battleUtility
  ) internal view {
    // First pass for stats and levels
    for (uint i = 0; i < battleUtility.length; i++) {
      if (!battleUtility[i].enabled) {
        continue;
      }
      for (uint j = 0; j < battleUtility[i].multiplicativeBonuses.length; j++) {
        data.currentMultiplicative = battleUtility[i].multiplicativeBonuses[j];
        if (
          data.currentMultiplicative.bonusType == DataType.BASE &&
          _verifyRestrictions(data.currentMultiplicative.restrictions, data)
        ) {
          data.stats[data.currentMultiplicative.bonusId] += uint24(
            _multiplicativeBonusValue(
              data.currentMultiplicative,
              data.stats,
              data.adjustedLevel,
              data.battlePower,
              data.mastery[i]
            )
          );
        }
      }
    }
  }

  function _calculateBp(ScouterData memory data) internal view {
    _calculateBp(data, data.classUtility);
    _calculateBp(data, data.peripheralUtility);
  }

  function _calculateBp(
    ScouterData memory data,
    BattleUtility[] memory battleUtility
  ) internal view {
    // Seconds pass for battle power bonus

    SigmoidConfig memory cfg = statBoostConfig;
    for (uint i = 0; i < battleUtility.length; i++) {
      if (!battleUtility[i].enabled) {
        continue;
      }
      for (uint j = 0; j < battleUtility[i].additiveBonuses.length; j++) {
        data.currentAdditive = battleUtility[i].additiveBonuses[j];
        if (!_verifyRestrictions(data.currentAdditive.restrictions, data)) {
          continue;
        }
        if (
          data.currentAdditive.bonusType == DataType.ACTIONS &&
          data.currentAdditive.bonusId == ActionsUtility.BATTLE_POWER
        ) {
          uint temp = _adjustAffinity(
            data.currentAdditive.value,
            data.stats,
            data.currentAdditive.affinity,
            cfg
          );
          data.battlePower += _adjustMastery(temp, data.mastery[i]);
        }
      }
    }

    for (uint i = 0; i < battleUtility.length; i++) {
      for (uint j = 0; j < battleUtility[i].multiplicativeBonuses.length; j++) {
        data.currentMultiplicative = battleUtility[i].multiplicativeBonuses[j];

        if (
          data.currentMultiplicative.bonusType == DataType.ACTIONS &&
          data.currentMultiplicative.bonusId == ActionsUtility.BATTLE_POWER &&
          _verifyRestrictions(data.currentMultiplicative.restrictions, data)
        ) {
          data.battlePower += _multiplicativeBonusValue(
            data.currentMultiplicative,
            data.stats,
            data.adjustedLevel,
            data.battlePower,
            data.mastery[i]
          );
        }
      }
    }
  }

  function _adjustAffinity(
    uint256 _value,
    uint24[10] memory _stats,
    StatAffinity memory _affinity,
    SigmoidConfig memory _sigmoid
  ) internal pure returns (uint256) {
    if (!_affinity.enabled) {
      return _value;
    }

    int base;
    for (uint i = 0; i < 6; i++) {
      // The array is fixed length for storage savings, but we should stop on first "empty" slot
      if (_affinity.coefficient[i] == 0) {
        break;
      }
      base += int(uint(_stats[_affinity.baseStats[i]])) * int(_affinity.coefficient[i]);
    }

    base = (base) / SIGNED_ONE_HUNDRED;

    return
      uint(SigmoidFunction.calculate(_sigmoid, _affinity.sigmoidRange, base) * int(_value)) /
      ONE_HUNDRED;
  }

  function _adjustMastery(uint256 _value, uint256 _mastery) internal pure returns (uint256) {
    return (_value * _mastery) / ONE_HUNDRED;
  }

  function _verifyRestrictions(
    PeripheralRestriction[] memory _restrictions,
    ScouterData memory data
  ) internal pure returns (bool) {
    PeripheralRestriction memory restriction;
    for (uint i = 0; i < _restrictions.length; i++) {
      restriction = _restrictions[i];
      if (
        restriction.requirementType == DataType.BASE &&
        uint(data.stats[restriction.requirementId]) < restriction.value
      ) {
        return false;
      }
    }
    return true;
  }

  function _obtainBaseBattlePower(
    uint _fightEpoch,
    address _adventurerAddr,
    uint256 _adventurerId,
    bool ignoreCache
  ) internal returns (int battlePower, uint level) {
    ScouterCache storage cache = battlePowerCache[_adventurerAddr][_adventurerId];
    if (ignoreCache || cache.battlePower <= 0 || cache.stale || cache.epochNumber != _fightEpoch) {
      (battlePower, level) = baseBattlePower(_adventurerAddr, _adventurerId);
      cache.battlePower = int32(battlePower);
      cache.level = uint16(level);
      cache.stale = false;
      emit BattlePowerChanged(_adventurerAddr, _adventurerId, battlePower);
    } else {
      battlePower = int(cache.battlePower);
      level = uint(cache.level);
    }
  }

  function _multiplicativeBonusValue(
    PeripheralMultiplicativeBonus memory _bonus,
    uint24[10] memory _stats,
    uint256 _level,
    uint256 _bp,
    uint256 _mastery
  ) internal pure returns (uint256 value) {
    if (_bonus.baseStatType == DataType.BASE) {
      value = uint(_stats[_bonus.baseStatId]) * DECIMAL_POINT;
    } else if (
      _bonus.baseStatType == DataType.ACTIONS && _bonus.baseStatId == BATTLE_BONUS_TYPE_BP_ID
    ) {
      value = _bp;
    }
    value = _adjustMastery((value * uint256(_bonus.value)) / ONE_HUNDRED, _mastery);
  }

  function _calculateProbability(
    int256 _attackerBp,
    int256 _opponentBp
  ) internal pure returns (uint256 result) {
    _attackerBp += 1;
    _opponentBp += 1;
    result += uint((SIGNED_ONE_HUNDRED * (_attackerBp)) / (_attackerBp + _opponentBp));
    _attackerBp = (_attackerBp * _attackerBp);
    _opponentBp = (_opponentBp * _opponentBp);
    result += 5000 + uint((int(90000) * (_attackerBp)) / (_attackerBp + _opponentBp));
    result /= 2;
    return result;
  }

  function invalidateCache(address _adventurerAddr, uint256 _adventurerId) external onlyManager {
    battlePowerCache[_adventurerAddr][_adventurerId].stale = true;
  }

  function invalidateCaches(
    address[] calldata _adventurerAddrs,
    uint256[] calldata _adventurerIds
  ) external onlyManager {
    for (uint i = 0; i < _adventurerAddrs.length; i++) {
      battlePowerCache[_adventurerAddrs[i]][_adventurerIds[i]].stale = true;
    }
  }

  function configureClassBonus(uint _class, BattleUtility calldata _utility) external onlyAdmin {
    while (classBonuses[_class].length > 0) {
      classBonuses[_class].pop();
    }
    classBonuses[_class].push(_utility);
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../lib/SigmoidFunction.sol";

struct BattlePowerScan {
  uint256 probability;
  int256 attackerBase;
  int256 attackerFinal;
  uint256 attackerLevel;
  int256 opponentBase;
  int256 opponentFinal;
  uint256 opponentLevel;
}

enum DataType {
  BASE,
  ADVANCED,
  EXTENSION,
  ACTIONS
}

struct LevelAdjustment {
  uint32 levelThreshold;
  uint32 adjustmentCoefficient;
  uint32 reverseAdjustmentCoefficient;
}

struct PeripheralRestriction {
  DataType requirementType;
  uint32 requirementId;
  uint32 value;
}

struct PeripheralAdditiveBonus {
  DataType bonusType;
  uint32 bonusId;
  uint32 value;
  PeripheralRestriction[] restrictions;
  StatAffinity affinity;
}

struct PeripheralMultiplicativeBonus {
  DataType baseStatType;
  uint32 baseStatId;
  DataType bonusType;
  uint32 bonusId;
  uint32 value;
  PeripheralRestriction[] restrictions;
}

struct StatAffinity {
  bool enabled;
  uint16[6] baseStats;
  int24[6] coefficient;
  RangeConfig sigmoidRange;
}

struct BattleUtility {
  bool enabled;
  LevelAdjustment adjustment;
  PeripheralAdditiveBonus[] additiveBonuses;
  PeripheralMultiplicativeBonus[] multiplicativeBonuses;
}

interface IBattlePowerScouter {
  function baseBattlePower(
    address _adventurerAddr,
    uint256 _adventurerId
  ) external returns (int256 battlePower, uint256 level);

  function scanBattlePower(
    uint _fightEpoch,
    address _adventurerAddr,
    uint256 _adventurerId,
    address _opponentAddr,
    uint256 _opponentId,
    uint256[] calldata _params
  ) external returns (BattlePowerScan memory);

  function invalidateCache(address _adventurerAddr, uint256 _adventurerId) external;

  function invalidateCaches(
    address[] calldata _adventurerAddr,
    uint256[] calldata _adventurerId
  ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Battle/IBattlePowerScouter.sol";

interface IRarityItemBattleUtilityData {
  function rarityItemUtilityBatch(
    uint256[] calldata _ids
  ) external view returns (BattleUtility[] memory result);

  function rarityItemUtilitySingle(
    uint256 _peripheralId
  ) external view returns (BattleUtility memory);

  function levelAdjustment(uint256 _peripheralId) external view returns (LevelAdjustment memory);

  function additiveBonuses(
    uint256 _peripheralId
  ) external view returns (PeripheralAdditiveBonus[] memory);

  function multiplicativeBonuses(
    uint256 _peripheralId
  ) external view returns (PeripheralMultiplicativeBonus[] memory);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

// List of action-specific bonuses
library ActionsUtility {
  uint internal constant BATTLE_POWER = 1;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./FloatingPointConstants.sol";

struct RangeConfig {
  int24 leftCurveX;
  int24 mid;
  int24 rightCurveX;
}

struct SigmoidConfig {
  int24 shiftY;
  CurveConfig leftCurve;
  CurveConfig rightCurve;
}

struct CurveConfig {
  bool ascending;
  int24 rangeY;
  int24 yAdjustment;
  int24 steepness;
  int24 steepnessCoefficient;
}

library SigmoidFunction {
  function calculate(
    SigmoidConfig memory config,
    RangeConfig memory range,
    int x
  ) internal pure returns (int) {
    if (x >= range.mid) {
      return
        _calculateCurve(config.rightCurve, int(range.rightCurveX), x - int(range.mid), -1) +
        config.shiftY;
    } else {
      return
        _calculateCurve(config.leftCurve, (range.leftCurveX), int(range.mid) - x, 1) +
        config.shiftY;
    }
  }

  function _calculateCurve(
    CurveConfig memory config,
    int rangeX,
    int x,
    int sign
  ) internal pure returns (int) {
    if (!config.ascending) {
      sign *= -1;
    }
    return
      config.yAdjustment +
      ((SIGNED_ONE_HUNDRED +
        ((sign *
          ((rangeX * SIGNED_ONE_HUNDRED_SQUARE) /
            (rangeX * SIGNED_ONE_HUNDRED + x * int(config.steepness)) -
            SIGNED_ONE_HUNDRED)) * int(config.steepnessCoefficient)) /
        SIGNED_ONE_HUNDRED) * int(config.rangeY)) /
      SIGNED_ONE_HUNDRED;
  }
}

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