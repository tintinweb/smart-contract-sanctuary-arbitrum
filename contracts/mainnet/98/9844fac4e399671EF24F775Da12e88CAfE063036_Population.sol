/**
 *Submitted for verification at Arbiscan on 2022-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBatchStaker {
  function stakeBatchFor(
    address _staker,
    address _addr,
    uint256 _realmId,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function unstakeBatchFor(
    address _staker,
    address _addr,
    uint256 _realmId,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function hasStaked(
    uint256 _realmId,
    address _addr,
    uint256 _id,
    uint256 _count
  ) external view returns (bool);

  function stakerBalance(
    uint256 _realmId,
    address _addr,
    uint256 _id
  ) external view returns (uint256);
}

interface IPopulation {
  function getPopulation(uint256 _realmId) external view returns (uint256);
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

contract Population is IPopulation, ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IBatchStaker public immutable BATCH_STAKER;
  address public immutable CITY;

  //=======================================
  // Mappings
  //=======================================
  uint256[7] public population;

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _manager,
    address _batchStaker,
    address _city,
    uint256[7] memory _population
  ) ManagerModifier(_manager) {
    BATCH_STAKER = IBatchStaker(_batchStaker);
    CITY = _city;

    population = _population;
  }

  //=======================================
  // External
  //=======================================
  function getPopulation(uint256 _realmId)
    external
    view
    override
    returns (uint256)
  {
    return
      (BATCH_STAKER.stakerBalance(_realmId, address(CITY), 0) * population[0]) +
      (BATCH_STAKER.stakerBalance(_realmId, address(CITY), 1) * population[1]) +
      (BATCH_STAKER.stakerBalance(_realmId, address(CITY), 2) * population[2]) +
      (BATCH_STAKER.stakerBalance(_realmId, address(CITY), 3) * population[3]) +
      (BATCH_STAKER.stakerBalance(_realmId, address(CITY), 4) * population[4]) +
      (BATCH_STAKER.stakerBalance(_realmId, address(CITY), 5) * population[5]) +
      (BATCH_STAKER.stakerBalance(_realmId, address(CITY), 6) * population[6]);
  }

  //=======================================
  // Admin
  //=======================================
  function updatePopulation(uint256[7] calldata _population)
    external
    onlyAdmin
  {
    population = _population;
  }
}