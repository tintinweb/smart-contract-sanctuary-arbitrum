// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";

interface ILastActionMarkerStorage {

    function setActionMarker(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _action,
        uint256 _marker
    ) external;

    function getActionMarker(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _action
    ) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "./ILastActionMarkerStorage.sol";

contract LastActionMarkerStorage is ManagerModifier, ILastActionMarkerStorage {
  //=======================================
  // State variables
  //=======================================

  // Token address -> Token Id -> Action Id -> timestamp/epoch
  mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
    private lastActionMarker;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // Functions
  //=======================================
  function setActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action,
    uint256 _marker
  ) external onlyManager {
    lastActionMarker[_tokenAddress][_tokenId][_action] = _marker;
  }

  function getActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action
  ) external view returns (uint256) {
    return lastActionMarker[_tokenAddress][_tokenId][_action];
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