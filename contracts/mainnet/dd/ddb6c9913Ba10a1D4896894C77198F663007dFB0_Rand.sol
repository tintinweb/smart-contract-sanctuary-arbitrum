// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isManager(address addr, uint256 resourceId)
    external
    view
    returns (bool);

  function isAdmin(address addr) external view returns (bool);
}

contract Rand {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Variables
  //=======================================
  uint256 private count = 100;

  //=======================================
  // Mappings
  //=======================================
  mapping(uint256 => uint256) private seeds;

  //=======================================
  // MODIFIER
  //=======================================
  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not a manager");
    _;
  }

  modifier onlyAdmin() {
    // Check if admin
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // External
  //=======================================
  function retrieve(uint256 _salt) external view onlyManager returns (uint256) {
    return seeds[_salt % count];
  }

  //=======================================
  // Admin
  //=======================================
  function setSeed(uint256 _index, uint256[] calldata _seeds)
    external
    onlyAdmin
  {
    uint256 i = 0;
    for (; i < _seeds.length; i++) {
      seeds[_index] = _seeds[i];
      _index++;
    }
  }

  function setCount(uint256 _count) external onlyAdmin {
    count = _count;
  }
}