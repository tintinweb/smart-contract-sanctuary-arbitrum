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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library traits {
  // Base Ttraits
  // See AdventurerData.sol for details
  uint256 public constant ADV_BASE_TRAIT_XP = 1;
  uint256 public constant ADV_BASE_TRAIT_STRENGTH = 2;
  uint256 public constant ADV_BASE_TRAIT_DEXTERITY = 3;
  uint256 public constant ADV_BASE_TRAIT_CONSTITUTION = 4;
  uint256 public constant ADV_BASE_TRAIT_INTELLIGENCE = 5;
  uint256 public constant ADV_BASE_TRAIT_WISDOM = 6;
  uint256 public constant ADV_BASE_TRAIT_CHARISMA = 7;
  uint256 public constant ADV_BASE_TRAIT_HP = 8;
  uint256 public constant ADV_BASE_TRAIT_HP_USED = 9;

  // AoV Traits
  // See AdventurerData.sol for details
  uint256 public constant ADV_AOV_TRAIT_LEVEL = 0;
  uint256 public constant ADV_AOV_TRAIT_ARCHETYPE = 1;
  uint256 public constant ADV_AOV_TRAIT_CLASS = 2;
  uint256 public constant ADV_AOV_TRAIT_PROFESSION = 3;

  function traitNames() public pure returns (string[9] memory) {
    return [
      "Level",
      "XP",
      "Strength",
      "Dexterity",
      "Constitution",
      "Intelligence",
      "Wisdom",
      "Charisma",
      "HP"
    ];
  }

  function traitName(uint256 traitId) public pure returns (string memory) {
    return traitNames()[traitId];
  }

  struct TraitBonus {
    uint256 traitId;
    uint256 traitValue;
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
import "../lib/FloatingPointConstants.sol";
import "../AdventurerEquipment/IAdventurerEquipment.sol";
import "../Item/IRarityItemBattleUtilityData.sol";
import "../Item/RarityItemActionUtilityConstants.sol";
import "../Manager/ManagerModifier.sol";

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
  uint256[] stats;
  uint256 baseLevel;
  uint256 class;
  uint256 adjustedLevel;
  uint256[] equipment;
  BattleUtility[] classUtility;
  BattleUtility[] peripheralUtility;
  uint[] mastery;
  PeripheralAdditiveBonus currentAdditive;
  PeripheralMultiplicativeBonus currentMultiplicative;
}

uint256 constant BASE_STAT_OFFSET = traits.ADV_BASE_TRAIT_STRENGTH;

contract BattlePowerScouter is IBattlePowerScouter, ManagerModifier {
  event BattlePowerChanged(address adventurerAddress, uint adventurerTokenId, int battlePower);

  IAdventurerData public adventurerData;
  IAdventurerEquipment public adventurerEquipmentData;
  IRarityItemBattleUtilityData public rarityItemUtilityData;

  mapping(address => mapping(uint256 => ScouterCache)) private battlePowerCache;

  mapping(uint256 => BattleUtility[]) private classBonuses;

  constructor(
    address _manager,
    address _data,
    address _adventurerEquipment,
    address _rarityItemUtilityData
  ) ManagerModifier(_manager) {
    adventurerData = IAdventurerData(_data);
    adventurerEquipmentData = IAdventurerEquipment(_adventurerEquipment);
    rarityItemUtilityData = IRarityItemBattleUtilityData(_rarityItemUtilityData);
  }

  // Most naive initial implementation
  function scanBattlePower(
    uint _fightEpoch,
    address _adventurerAddr,
    uint256 _adventurerId,
    address _opponentAddr,
    uint256 _opponentId
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
    return scan;
  }

  function baseBattlePower(
    address _adventurerAddr,
    uint256 _adventurerId
  ) public view returns (int256, uint256) {
    ScouterData memory data;
    data.stats = adventurerData.baseProperties(
      _adventurerAddr,
      _adventurerId,
      traits.ADV_BASE_TRAIT_STRENGTH,
      traits.ADV_BASE_TRAIT_CHARISMA
    );
    data.baseLevel = adventurerData.aov(_adventurerAddr, _adventurerId, traits.ADV_AOV_TRAIT_LEVEL);
    data.class = adventurerData.aov(_adventurerAddr, _adventurerId, traits.ADV_AOV_TRAIT_CLASS);
    data.classUtility = classBonuses[data.class];
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

    for (uint i = 0; i < data.stats.length; i++) {
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
    // Additive bonuses
    for (uint i = 0; i < battleUtility.length; i++) {
      if (!battleUtility[i].enabled) {
        continue;
      }
      for (uint j = 0; j < battleUtility[i].additiveBonuses.length; j++) {
        data.currentAdditive = battleUtility[i].additiveBonuses[j];
        if (!_verifyRestrictions(data.currentAdditive.restrictions, data.stats, data.baseLevel)) {
          continue;
        }

        if (data.currentAdditive.bonusType == DataType.BASE) {
          data.stats[data.currentAdditive.bonusId - BASE_STAT_OFFSET] +=
            _adjustMastery(data.currentAdditive.value, data.mastery[i]) /
            DECIMAL_POINT;
        } else if (
          data.currentAdditive.bonusType == DataType.AOV &&
          data.currentAdditive.bonusId == traits.ADV_AOV_TRAIT_LEVEL
        ) {
          data.adjustedLevel += _adjustMastery(data.currentAdditive.value, data.mastery[i]);
        } else if (
          data.currentAdditive.bonusType == DataType.ACTIONS &&
          data.currentAdditive.bonusId == ActionsUtility.BATTLE_POWER
        ) {
          data.battlePower += _adjustMastery(data.currentAdditive.value, data.mastery[i]);
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
          _verifyRestrictions(data.currentMultiplicative.restrictions, data.stats, data.baseLevel)
        ) {
          data.stats[
            data.currentMultiplicative.bonusId - BASE_STAT_OFFSET
          ] += _multiplicativeBonusValue(
            data.currentMultiplicative,
            data.stats,
            data.adjustedLevel,
            data.battlePower,
            data.mastery[i]
          );
        } else if (
          data.currentMultiplicative.bonusType == DataType.AOV &&
          data.currentMultiplicative.bonusId == traits.ADV_AOV_TRAIT_LEVEL &&
          _verifyRestrictions(data.currentMultiplicative.restrictions, data.stats, data.baseLevel)
        ) {
          data.adjustedLevel += _multiplicativeBonusValue(
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

  function _calculateBp(ScouterData memory data) internal view {
    _calculateBp(data, data.classUtility);

    _calculateBp(data, data.peripheralUtility);
  }

  function _calculateBp(
    ScouterData memory data,
    BattleUtility[] memory battleUtility
  ) internal view {
    // Seconds pass for battle power bonus
    for (uint i = 0; i < battleUtility.length; i++) {
      for (uint j = 0; j < battleUtility[i].multiplicativeBonuses.length; j++) {
        data.currentMultiplicative = battleUtility[i].multiplicativeBonuses[j];

        if (
          data.currentMultiplicative.bonusType == DataType.ACTIONS &&
          data.currentMultiplicative.bonusId == ActionsUtility.BATTLE_POWER &&
          _verifyRestrictions(data.currentMultiplicative.restrictions, data.stats, data.baseLevel)
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

  function _adjustMastery(uint256 _value, uint256 _mastery) internal pure returns (uint256) {
    return (_value * _mastery) / ONE_HUNDRED;
  }

  function _verifyRestrictions(
    PeripheralRestriction[] memory _restrictions,
    uint[] memory stats,
    uint level
  ) internal pure returns (bool) {
    PeripheralRestriction memory restriction;
    for (uint i = 0; i < _restrictions.length; i++) {
      restriction = _restrictions[i];
      if (
        restriction.requirementType == DataType.AOV &&
        restriction.requirementId == traits.ADV_AOV_TRAIT_LEVEL &&
        level < restriction.value
      ) {
        return false;
      } else if (
        restriction.requirementType == DataType.BASE &&
        stats[restriction.requirementId] < restriction.value
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
    uint256[] memory _stats,
    uint256 _level,
    uint256 _bp,
    uint256 _mastery
  ) internal pure returns (uint256 value) {
    if (_bonus.baseStatType == DataType.BASE) {
      value = _stats[_bonus.baseStatId - BASE_STAT_OFFSET] * DECIMAL_POINT;
    } else if (
      _bonus.baseStatType == DataType.AOV && _bonus.baseStatId == traits.ADV_AOV_TRAIT_LEVEL
    ) {
      value = _level;
    } else if (
      _bonus.baseStatType == DataType.ACTIONS && _bonus.baseStatId == BATTLE_BONUS_TYPE_BP_ID
    ) {
      value = _bp;
    }
    value = _adjustMastery((value * uint256(_bonus.value)) / ONE_HUNDRED, _mastery);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct BattlePowerScan {
  int256 attackerBase;
  int256 attackerFinal;
  uint256 attackerLevel;
  int256 opponentBase;
  int256 opponentFinal;
  uint256 opponentLevel;
}

enum DataType {
  BASE,
  AOV,
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
}

struct PeripheralMultiplicativeBonus {
  DataType baseStatType;
  uint32 baseStatId;
  DataType bonusType;
  uint32 bonusId;
  uint32 value;
  PeripheralRestriction[] restrictions;
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
  ) external view returns (int256 battlePower, uint256 level);

  function scanBattlePower(
    uint _fightEpoch,
    address _adventurerAddr,
    uint256 _adventurerId,
    address _opponentAddr,
    uint256 _opponentId
  ) external returns (BattlePowerScan memory);

  function invalidateCache(address _adventurerAddr, uint256 _adventurerId) external;

  function invalidateCaches(
    address[] calldata _adventurerAddr,
    uint256[] calldata _adventurerId
  ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// List of action-specific bonuses
library ActionsUtility {
  uint constant internal BATTLE_POWER = 1;
}

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