// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/ManagerModifier.sol";

contract ParticleTracker is ManagerModifier {
  //=======================================
  // Mappings
  //=======================================
  mapping(address => mapping(uint256 => uint256)) public timer;
  mapping(address => mapping(uint256 => uint256)) public explorers;
  mapping(uint256 => uint256) public explorerCount;

  //=======================================
  // Events
  //=======================================
  event Captured(address _address, uint256 adventurerId);

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
    returns (uint256)
  {
    return explorers[_addr][_adventurerId];
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
    explorers[_addr][_adventurerId] = _realmId;

    // Add to explorer count
    explorerCount[_realmId]++;
  }

  function removeExplorer(
    uint256 _realmId,
    address _addr,
    uint256 _adventurerId
  ) external onlyManager {
    // Remove explorer
    explorers[_addr][_adventurerId] = 0;

    // Remove to explorer count
    explorerCount[_realmId]--;
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