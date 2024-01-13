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

import "./IRarityItemBattleUtilityData.sol";
import "../Manager/ManagerModifier.sol"; // SPDX-License-Identifier: Unlicensed

contract RarityItemBattleUtilityData is ManagerModifier, IRarityItemBattleUtilityData {
  mapping(uint256 => BattleUtility) public rarityItemUtility;

  constructor(address _manager) ManagerModifier(_manager) {}

  function rarityItemUtilityBatch(
    uint256[] calldata _ids
  ) external view returns (BattleUtility[] memory result) {
    result = new BattleUtility[](_ids.length);
    for (uint i = 0; i < _ids.length; i++) {
      result[i] = rarityItemUtility[_ids[i]];
    }
  }

  function rarityItemUtilitySingle(
    uint256 _id
  ) external view returns (BattleUtility memory result) {
    result = rarityItemUtility[_id];
  }

  function levelAdjustment(uint256 _peripheralId) external view returns (LevelAdjustment memory) {
    return rarityItemUtility[_peripheralId].adjustment;
  }

  function additiveBonuses(
    uint256 _peripheralId
  ) external view returns (PeripheralAdditiveBonus[] memory) {
    return rarityItemUtility[_peripheralId].additiveBonuses;
  }

  function multiplicativeBonuses(
    uint256 _peripheralId
  ) external view returns (PeripheralMultiplicativeBonus[] memory) {
    return rarityItemUtility[_peripheralId].multiplicativeBonuses;
  }

  //=======================================
  // Admin
  //=======================================
  function updateUtility(
    uint256[] calldata _itemIds,
    BattleUtility[] calldata _utilities
  ) external onlyAdmin {
    require(_itemIds.length == _utilities.length);

    for (uint i = 0; i < _itemIds.length; i++) {
      require(_itemIds[i] != 0);
      rarityItemUtility[_itemIds[i]] = _utilities[i];
    }
  }
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