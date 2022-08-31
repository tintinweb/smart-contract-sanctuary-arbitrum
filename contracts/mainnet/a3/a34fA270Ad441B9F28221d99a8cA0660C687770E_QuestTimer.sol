/**
 *Submitted for verification at Arbiscan on 2022-08-31
*/

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

contract QuestTimer is ManagerModifier {
  //=======================================
  // Mappings
  //=======================================
  mapping(address => mapping(uint256 => uint256)) public timer;

  //=======================================
  // Uints
  //=======================================
  uint256 public offset;

  //=======================================
  // Events
  //=======================================
  event TimerSet(
    address addr,
    uint256 adventurerId,
    uint256 questCount,
    uint256 _hours,
    uint256 offset,
    uint256 timerSetTo
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager, uint256 _offset) ManagerModifier(_manager) {
    offset = _offset;
  }

  //=======================================
  // External
  //=======================================
  function set(
    address _addr,
    uint256 _adventurerId,
    uint256 _questCount,
    uint256 _hours
  ) external onlyManager {
    require(
      timer[_addr][_adventurerId] <= block.timestamp,
      "QuestTimer: Can't quest yet"
    );

    timer[_addr][_adventurerId] =
      block.timestamp +
      (_hours * _questCount * 3600) -
      offset;

    emit TimerSet(
      _addr,
      _adventurerId,
      _questCount,
      _hours,
      offset,
      timer[_addr][_adventurerId]
    );
  }

  function canQuest(address _addr, uint256 _adventurerId)
    external
    view
    returns (bool)
  {
    return timer[_addr][_adventurerId] <= block.timestamp;
  }

  //=======================================
  // Admin
  //=======================================
  function updateOffset(uint256 _offset) external onlyAdmin {
    offset = _offset;
  }
}