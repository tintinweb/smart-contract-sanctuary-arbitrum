// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IGlobalActionIdStorage.sol";
import "../Manager/ManagerModifier.sol";

contract GlobalActionIdStorage is IGlobalActionIdStorage, ManagerModifier {

  // Action type => next action id
  mapping(uint256 => uint256) private actionId;

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _manager
  ) ManagerModifier(_manager) {
  }


  function getAndIncrementNextId(uint256 action, uint256 increment) external onlyManager returns (uint256 result) {
    result = actionId[action];
    actionId[action] += increment;
  }

  function getNextId(uint256 action) external view returns (uint256) {
    return actionId[action];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IGlobalActionIdStorage {
  function getAndIncrementNextId(uint256 action, uint increment) external returns (uint256);

  function getNextId(uint256 action) external view returns (uint256);
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