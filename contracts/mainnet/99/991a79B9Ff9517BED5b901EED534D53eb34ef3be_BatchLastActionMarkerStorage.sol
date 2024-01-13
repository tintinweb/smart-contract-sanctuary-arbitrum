// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "./ILastActionMarkerStorage.sol";
import "./IBatchLastActionMarkerStorage.sol";

address constant ZERO_ADDRESS = address(0);

contract BatchLastActionMarkerStorage is ManagerModifier, IBatchLastActionMarkerStorage {
  event MarkerUpdated(address _tokenAddress, uint256 _tokenId, uint256 _action, uint256 _marker);

  //=======================================
  // Mappings
  //=======================================
  // Action Id => Token address -> Token Id -> timestamp/epoch
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) private lastActionMarker;

  ILastActionMarkerStorage public LEGACY_STORAGE;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager, address _legacyStorage) ManagerModifier(_manager) {
    LEGACY_STORAGE = ILastActionMarkerStorage(_legacyStorage);
  }

  //=======================================
  // Functions
  //=======================================
  function setActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action,
    uint256 _marker
  ) external onlyManager {
    lastActionMarker[_action][_tokenAddress][_tokenId] = _marker;
  }

  function setActionMarkerMany(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256 _action,
    uint256 _marker
  ) external onlyManager {
    mapping(address => mapping(uint256 => uint256)) storage actionMarkers = lastActionMarker[
      _action
    ];
    for (uint i = 0; i < _tokenAddresses.length; i++) {
      actionMarkers[_tokenAddresses[i]][_tokenIds[i]] = _marker;
    }
  }

  function getActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action
  ) external view returns (uint256 result) {
    result = lastActionMarker[_action][_tokenAddress][_tokenId];
    if (result == 0 && address(LEGACY_STORAGE) != ZERO_ADDRESS) {
      result = LEGACY_STORAGE.getActionMarker(_tokenAddress, _tokenId, _action);
    }
  }

  function getActionMarkerBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256 _action
  ) external view returns (uint256[] memory result) {
    result = new uint256[](_tokenAddresses.length);
    mapping(address => mapping(uint256 => uint256)) storage actionMapping = lastActionMarker[
      _action
    ];
    for (uint i = 0; i < _tokenAddresses.length; i++) {
      result[i] = actionMapping[_tokenAddresses[i]][_tokenIds[i]];
      if (result[i] == 0 && address(LEGACY_STORAGE) != ZERO_ADDRESS) {
        result[i] = LEGACY_STORAGE.getActionMarker(_tokenAddresses[i], _tokenIds[i], _action);
      }
    }
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";

interface IBatchLastActionMarkerStorage {
  function setActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action,
    uint256 _marker
  ) external;

  function setActionMarkerMany(
    address[] calldata _tokenAddress,
    uint256[] calldata _tokenId,
    uint256 _action,
    uint256 _marker
  ) external;

  function getActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action
  ) external view returns (uint256);

  function getActionMarkerBatch(
    address[] calldata _tokenAddress,
    uint256[] calldata _tokenId,
    uint256 _action
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: Unlicensed

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