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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRand {
  function retrieve(uint256 _salt) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IRand.sol";

import "../Manager/ManagerModifier.sol";

contract Rand is IRand, ManagerModifier {
  //=======================================
  // Uints
  //=======================================
  uint256 private count = 100;

  //=======================================
  // Mappings
  //=======================================
  mapping(uint256 => uint256) private seeds;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // External
  //=======================================
  function retrieve(uint256 _salt)
    external
    view
    override
    onlyManager
    returns (uint256)
  {
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