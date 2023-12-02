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

import "./IRarityItemBattleUtilityData.sol";
import "../Manager/ManagerModifier.sol"; // SPDX-License-Identifier: MIT

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