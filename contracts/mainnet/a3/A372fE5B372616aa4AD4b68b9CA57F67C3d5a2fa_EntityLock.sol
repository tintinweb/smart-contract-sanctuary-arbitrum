// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./ILockStorage.sol";
import "../Manager/ManagerModifier.sol";

error LockTimeExceeded(uint lockTime, uint maxLockDuration);
error AlreadyLocked(address entityAddress, uint entityId, uint256 currentLockTimestamp);

contract EntityLock is ManagerModifier, ILockStorage {
  uint public maxLockDuration;

  mapping(address => mapping(uint256 => uint64)) public entityLockTimestamp;

  constructor(address _manager) ManagerModifier(_manager) {
    maxLockDuration = 7 days;
  }

  event Locked(address entityAddress, uint entityId, uint lockTimestamp);

  function lockEntity(
    address entityAddress,
    uint entityId,
    uint _lockDuration
  ) external onlyManager {
    if (maxLockDuration > _lockDuration) {
      revert LockTimeExceeded(_lockDuration, maxLockDuration);
    }
    uint currentLockTime = entityLockTimestamp[entityAddress][entityId];
    uint newLockTime = block.timestamp + _lockDuration;
    if (currentLockTime > newLockTime) {
      revert AlreadyLocked(entityAddress, entityId, currentLockTime);
    }

    entityLockTimestamp[entityAddress][entityId] = uint64(newLockTime);
    emit Locked(entityAddress, entityId, newLockTime);
  }

  function lockEntityBatch(
    address[] calldata _entityAddresses,
    uint[] calldata _entityIds,
    uint _lockDuration
  ) external onlyManager {
    if (maxLockDuration > _lockDuration) {
      revert LockTimeExceeded(_lockDuration, maxLockDuration);
    }

    uint currentLockTime;
    uint newLockTime = block.timestamp + _lockDuration;
    for (uint i = 0; i < _entityAddresses.length; i++) {
      currentLockTime = entityLockTimestamp[_entityAddresses[i]][_entityIds[i]];
      if (currentLockTime > newLockTime) {
        revert AlreadyLocked(_entityAddresses[i], _entityIds[i], currentLockTime);
      }

      entityLockTimestamp[_entityAddresses[i]][_entityIds[i]] = uint64(newLockTime);
      emit Locked(_entityAddresses[i], _entityIds[i], newLockTime);
    }
  }

  function isLocked(
    address entityAddress,
    uint entityId
  ) external view returns (bool locked, uint lockedUntil) {
    lockedUntil = entityLockTimestamp[entityAddress][entityId];
    if (lockedUntil > block.timestamp) {
      locked = true;
    }
  }

  function isLockedBatch(
    address _entityAddress,
    uint[] calldata _entityIds
  )
    external
    view
    returns (bool locked, address lockedAddress, uint lockedEntityId, uint lockedUntil)
  {
    for (uint i = 0; i < _entityIds.length; i++) {
      lockedUntil = entityLockTimestamp[_entityAddress][_entityIds[i]];
      if (lockedUntil > block.timestamp) {
        locked = true;
        lockedAddress = _entityAddress;
        lockedEntityId = _entityIds[i];
        return (locked, lockedAddress, lockedEntityId, lockedUntil);
      }
    }
    lockedUntil = 0;
  }

  function isLockedBatch(
    address[] calldata _entityAddresses,
    uint[] calldata _entityIds
  )
    external
    view
    returns (bool locked, address lockedAddress, uint lockedEntityId, uint lockedUntil)
  {
    for (uint i = 0; i < _entityAddresses.length; i++) {
      lockedUntil = entityLockTimestamp[_entityAddresses[i]][_entityIds[i]];
      if (lockedUntil > block.timestamp) {
        locked = true;
        lockedAddress = _entityAddresses[i];
        lockedEntityId = _entityIds[i];
        return (locked, lockedAddress, lockedEntityId, lockedUntil);
      }
    }
    lockedUntil = 0;
  }

  function updateMaxLockTime(uint _maxLockDuration) external onlyAdmin {
    maxLockDuration = _maxLockDuration;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface ILockStorage {
  function lockEntity(address entityAddress, uint entityId, uint lockUntilTimestamp) external;

  function lockEntityBatch(
    address[] calldata _entityAddresses,
    uint[] calldata _entityIds,
    uint _lockDuration
  ) external;

  function isLocked(
    address entityAddress,
    uint entityId
  ) external view returns (bool locked, uint lockedUntil);

  function isLockedBatch(
    address _entityAddresses,
    uint[] calldata _entityIds
  )
    external
    view
    returns (bool locked, address lockedAddress, uint lockedEntityId, uint lockedUntil);

  function isLockedBatch(
    address[] calldata _entityAddresses,
    uint[] calldata _entityIds
  )
    external
    view
    returns (bool locked, address lockedAddress, uint lockedEntityId, uint lockedUntil);
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