/**
 *Submitted for verification at Arbiscan on 2022-08-30
*/

// SPDX-License-Identifier: MIT

interface IERC20Bound {
  function unbind(address _addresses) external;

  function isUnbound(address _addr) external view returns (bool);
}

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

pragma solidity ^0.8.4;

contract ERC20Bound is IERC20Bound, ManagerModifier {
  //=======================================
  // Mappings
  //=======================================
  mapping(address => bool) public unbound;

  //=======================================
  // Events
  //=======================================
  event Unbounded(address addr);
  event Bounded(address addr);

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // External
  //=======================================
  function isUnbound(address _addr) external view override returns (bool) {
    return unbound[_addr] == true;
  }

  function unbind(address _address) external override onlyBinder {
    unbound[_address] = true;

    emit Unbounded(_address);
  }
}