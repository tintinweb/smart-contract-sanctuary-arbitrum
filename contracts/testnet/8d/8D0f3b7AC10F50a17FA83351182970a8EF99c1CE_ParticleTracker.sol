// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/ManagerModifier.sol";

contract ParticleTracker is ManagerModifier {
  //=======================================
  // Struct
  //=======================================
  struct Explorer {
    uint256 realmId;
    bool flag;
  }

  //=======================================
  // Mappings
  //=======================================
  mapping(address => mapping(uint256 => uint256)) public timer;
  mapping(address => mapping(uint256 => Explorer)) public explorers;
  mapping(uint256 => uint256) public explorerCount;

  //=======================================
  // Events
  //=======================================
  event Captured(address addr, uint256 adventurerId);
  event ExplorerAdded(uint256 realmId, address addr, uint256 adventurerId);
  event ExplorerRemoved(uint256 realmId, address addr, uint256 adventurerId);

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // External
  //=======================================
  function currentRealm(address _addr, uint256 _adventurerId)
    external
    view
    returns (uint256, bool)
  {
    Explorer storage explorer = explorers[_addr][_adventurerId];

    return (explorer.realmId, explorer.flag);
  }

  function getExplorerCount(uint256 _realmId) external view returns (uint256) {
    return explorerCount[_realmId];
  }

  function addExplorer(
    uint256 _realmId,
    address _addr,
    uint256 _adventurerId
  ) external onlyManager {
    // Store where adventurer is exploring
    Explorer storage explorer = explorers[_addr][_adventurerId];
    explorer.realmId = _realmId;
    explorer.flag = true;

    // Add to explorer count
    explorerCount[_realmId]++;

    emit ExplorerAdded(_realmId, _addr, _adventurerId);
  }

  function removeExplorer(
    uint256 _realmId,
    address _addr,
    uint256 _adventurerId
  ) external onlyManager {
    // Remove explorer
    Explorer storage explorer = explorers[_addr][_adventurerId];
    explorer.realmId = 0;
    explorer.flag = false;

    // Remove to explorer count
    explorerCount[_realmId]--;

    emit ExplorerRemoved(_realmId, _addr, _adventurerId);
  }

  function setTimer(address _addr, uint256 _adventurerId) external onlyManager {
    timer[_addr][_adventurerId] = block.timestamp;

    emit Captured(_addr, _adventurerId);
  }
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

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}