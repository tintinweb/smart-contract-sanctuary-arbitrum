// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/ManagerModifier.sol";

contract BoostStorage is ManagerModifier {
  //=======================================
  // Mappings
  //=======================================
  mapping(address => mapping(uint256 => uint256)) public boosts;
  mapping(address => mapping(uint256 => uint256)) public erc20Boost;

  //=======================================
  // Events
  //=======================================
  event BoostAdded(address owner, uint256 _type, uint256 amount);

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // External
  //=======================================
  function addBoost(
    address _owner,
    uint256 _type,
    uint256 _amount
  ) external onlyManager {
    boosts[_owner][_type] += _amount;

    emit BoostAdded(_owner, _type, _amount);
  }

  function useBoost(
    address _owner,
    uint256 _type,
    uint256 _amount
  ) external onlyManager {
    require(boosts[_owner][_type] >= _amount, "BoostStorage: Not enough boost");

    boosts[_owner][_type] -= _amount;

    emit BoostAdded(_owner, _type, _amount);
  }

  function useERC20Boost(
    address _owner,
    uint256 _type,
    uint256 _amount
  ) external onlyManager {
    require(
      erc20Boost[_owner][_type] >= _amount,
      "BoostStorage: Not enough boost"
    );

    erc20Boost[_owner][_type] -= _amount;

    emit BoostAdded(_owner, _type, _amount);
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