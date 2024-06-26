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

  modifier onlyConfigManager() {
    require(MANAGER.isManager(msg.sender, 4), "Manager: Not config manager");
    _;
  }

  modifier onlyTokenSpender() {
    require(MANAGER.isManager(msg.sender, 5), "Manager: Not token spender");
    _;
  }

  modifier onlyTokenEmitter() {
    require(MANAGER.isManager(msg.sender, 6), "Manager: Not token emitter");
    _;
  }

  modifier onlyPauser() {
    require(
      MANAGER.isAdmin(msg.sender) || MANAGER.isManager(msg.sender, 6),
      "Manager: Not pauser"
    );
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomStructureBurnerStorage {
  function getPartialBurn(
    address _structureAddress,
    uint _structureId
  ) external view returns (uint);

  function getPartialBurns(
    address _structureAddress,
    uint[] calldata _structureIds
  ) external view returns (uint[] memory);

  function setPartialBurn(
    address _structureAddress,
    uint _structureId,
    uint _loss
  ) external;

  function addPartialBurn(
    address _structureAddress,
    uint _structureId,
    uint _delta
  ) external;

  function subtractPartialBurn(
    address _structureAddress,
    uint _structureId,
    uint _delta
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import { IRandomStructureBurnerStorage } from "./IRandomStructureBurnerStorage.sol";

error InvalidDurabilityLoss(
  address structureAddress,
  uint structureId,
  uint256 current,
  uint256 delta
);

contract RandomStructureBurnerStorage is
  ManagerModifier,
  IRandomStructureBurnerStorage
{
  mapping(address => mapping(uint => uint)) public PARTIAL_BURNS;

  constructor(address _manager) ManagerModifier(_manager) {}

  function getPartialBurn(
    address _structureAddress,
    uint _structureId
  ) external view returns (uint) {
    return PARTIAL_BURNS[_structureAddress][_structureId];
  }

  function getPartialBurns(
    address _structureAddress,
    uint[] calldata _structureIds
  ) external view returns (uint[] memory) {
    uint[] memory result = new uint[](_structureIds.length);
    for (uint i = 0; i < _structureIds.length; i++) {
      result[i] = PARTIAL_BURNS[_structureAddress][_structureIds[i]];
    }
    return result;
  }

  function setPartialBurn(
    address _structureAddress,
    uint _structureId,
    uint _loss
  ) external onlyManager {
    PARTIAL_BURNS[_structureAddress][_structureId] = _loss;
  }

  function addPartialBurn(
    address _structureAddress,
    uint _structureId,
    uint _delta
  ) external onlyManager {
    PARTIAL_BURNS[_structureAddress][_structureId] += _delta;
  }

  function subtractPartialBurn(
    address _structureAddress,
    uint _structureId,
    uint _delta
  ) external onlyManager {
    uint current = PARTIAL_BURNS[_structureAddress][_structureId];
    if (current >= _delta) {
      current -= _delta;
    } else {
      current = 0;
    }
    PARTIAL_BURNS[_structureAddress][_structureId] = current;
  }
}