// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStructure {
  function add(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external;

  function remove(
    uint256 _realmId,
    uint256 _type,
    uint256 _amount
  ) external;
}

interface ICities {
  function totalCities(uint256 _realmId) external returns (uint256);
}

interface IFarms {
  function totalFarms(uint256 _realmId) external returns (uint256);
}

interface IAquariums {
  function count(uint256 _realmId) external returns (uint256);
}

interface IManager {
  function isAdmin(address addr) external view returns (bool);
}

contract Migrate {
  //=======================================
  // Immutables
  //=======================================
  ICities public immutable CITIES;
  IFarms public immutable FARMS;
  IAquariums public immutable AQUARIUMS;
  IManager public immutable MANAGER;
  IStructure public immutable STRUCTURE;

  //=======================================
  // EVENTS
  //=======================================
  event Migrated(
    uint256 realmId,
    uint256 cities,
    uint256 farms,
    uint256 aquariums
  );

  //=======================================
  // MODIFIER
  //=======================================
  modifier onlyAdmin() {
    // Check if admin
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _cities,
    address _farms,
    address _aquairums,
    address _manager,
    address _structure
  ) {
    CITIES = ICities(_cities);
    FARMS = IFarms(_farms);
    AQUARIUMS = IAquariums(_aquairums);
    MANAGER = IManager(_manager);
    STRUCTURE = IStructure(_structure);
  }

  function add(uint256[] calldata _realmIds) external onlyAdmin {
    uint256 j = 0;
    for (; j < _realmIds.length; j++) {
      uint256 realmId = _realmIds[j];

      uint256 c = CITIES.totalCities(realmId);
      uint256 f = FARMS.totalFarms(realmId);
      uint256 a = AQUARIUMS.count(realmId);

      // City
      STRUCTURE.add(realmId, 0, c);
      // Farm
      STRUCTURE.add(realmId, 1, f);
      // Aquarium
      STRUCTURE.add(realmId, 2, a);

      emit Migrated(realmId, c, f, a);
    }
  }

  function sub(uint256[] calldata _realmIds) external onlyAdmin {
    uint256 j = 0;
    for (; j < _realmIds.length; j++) {
      uint256 realmId = _realmIds[j];

      // City
      STRUCTURE.remove(realmId, 0, CITIES.totalCities(realmId));
      // Farm
      STRUCTURE.remove(realmId, 1, FARMS.totalFarms(realmId));
      // Aquarium
      STRUCTURE.remove(realmId, 2, AQUARIUMS.count(realmId));
    }
  }
}