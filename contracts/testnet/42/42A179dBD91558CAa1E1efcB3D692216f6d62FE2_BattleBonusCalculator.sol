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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "./IAdventurerRenownBonusCalculator.sol";

int256 constant WEEKLY_BATTLE_RENOWN_PER_LEVEL = 100000;

contract BattleBonusCalculator is IAdventurerRenownBonusCalculator {
  function calculateBonus(
    address adventurerAddress,
    uint256 adventurerTokenId,
    uint256 level
  ) external pure returns (int) {
    return (int(level) * WEEKLY_BATTLE_RENOWN_PER_LEVEL);
  }

  function calculateBonusBatch(
    address[] calldata _adventurerAddresses,
    uint256[] calldata _adventurerTokenIds,
    uint256[] calldata _levels
  ) external pure returns (int[] memory result) {
    result = new int[](_adventurerAddresses.length);
    for (uint i = 0; i < result.length; i++) {
      result[i] = (int(_levels[i]) * WEEKLY_BATTLE_RENOWN_PER_LEVEL);
    }
    return result;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IAdventurerRenownBonusCalculator {
  function calculateBonus(
    address adventurerAddress,
    uint256 adventurerTokenId,
    uint256 level
  ) external view returns (int);

  function calculateBonusBatch(
    address[] calldata adventurerAddress,
    uint256[] calldata adventurerTokenId,
    uint256[] calldata level
  ) external view returns (int[] memory);
}