// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IAovTranscendenceTimer.sol";

import "../Manager/ManagerModifier.sol";

contract AovTranscendenceTimer is IAovTranscendenceTimer, ManagerModifier {
  //=======================================
  // Mappings
  //=======================================
  mapping(address => mapping(uint256 => uint256)) public timer;

  //=======================================
  // Events
  //=======================================
  event TimerSet(
    address addr,
    uint256 adventurerId,
    uint256 _hours,
    uint256 timerSetTo
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // External
  //=======================================
  function set(
    address _addr,
    uint256 _adventurerId,
    uint256 _hours
  ) external override onlyManager {
    require(
      timer[_addr][_adventurerId] <= block.timestamp,
      "AovTranscendenceTimer: Can't transcend yet"
    );

    timer[_addr][_adventurerId] = block.timestamp + (_hours * 3600);

    emit TimerSet(_addr, _adventurerId, _hours, timer[_addr][_adventurerId]);
  }

  function canTranscend(address _addr, uint256 _adventurerId)
    external
    view
    override
    returns (bool)
  {
    return timer[_addr][_adventurerId] <= block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAovTranscendenceTimer {
  function set(
    address _addr,
    uint256 _adventurerId,
    uint256 _hours
  ) external;

  function canTranscend(address _addr, uint256 _adventurerId)
    external
    view
    returns (bool);
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