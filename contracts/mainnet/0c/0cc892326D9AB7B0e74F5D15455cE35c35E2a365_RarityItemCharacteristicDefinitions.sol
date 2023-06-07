// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library traits {
  // List of Adventurer traits
  // Not using an enum for future proofing and we already have some non-character
  // traits that have the same int values like Realm resources, etc
  uint256 public constant ADVENTURER_TRAIT_LEVEL = 0;
  uint256 public constant ADVENTURER_TRAIT_XP = 1;
  uint256 public constant ADVENTURER_TRAIT_STRENGTH = 2;
  uint256 public constant ADVENTURER_TRAIT_DEXTERITY = 3;
  uint256 public constant ADVENTURER_TRAIT_CONSTITUTION = 4;
  uint256 public constant ADVENTURER_TRAIT_INTELLIGENCE = 5;
  uint256 public constant ADVENTURER_TRAIT_WISDOM = 6;
  uint256 public constant ADVENTURER_TRAIT_CHARISMA = 7;
  uint256 public constant ADVENTURER_TRAIT_HP = 8;

  function traitNames() public pure returns (string[9] memory) {
    return [
      "Level",
      "XP",
      "Strength",
      "Dexterity",
      "Constitution",
      "Intelligence",
      "Wisdom",
      "Charisma",
      "HP"
    ];
  }

  function traitName(uint256 traitId) public pure returns (string memory) {
    return traitNames()[traitId];
  }

  struct TraitBonus {
    uint256 traitId;
    uint256 traitValue;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRarityItemCharacteristicDefinitions {
  function characteristicCount() external view returns (uint16);

  function characteristicNames(
    uint16 _characteristic
  ) external view returns (string memory);

  function getCharacteristicValues(
    uint16 _characteristic,
    uint16 _id
  ) external view returns (string memory);

  function characteristicValuesCount(
    uint16 _characteristic
  ) external view returns (uint16);

  function allCharacteristicValues(
    uint16 _characteristic
  ) external view returns (string[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "./RarityItemConstants.sol";
import "../Adventurer/TraitConstants.sol";
import "./IRarityItemCharacteristicDefinitions.sol";

contract RarityItemCharacteristicDefinitions is
  IRarityItemCharacteristicDefinitions,
  ManagerModifier
{
  //=======================================
  // Strings
  //=======================================
  string[] public characteristics;
  string[][] public characteristicValues;

  //=======================================
  // Item characteristics
  //=======================================
  string[] public ITEM_CHARACTERISTICS = [
    "Rarity",
    "Slot",
    "Type",
    "Subtype",
    "Prefix",
    "Suffix"
  ];

  //=======================================
  // Item rarities
  //=======================================
  string[] public ITEM_RARITIES = [
    "",
    "Common",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Exotic"
  ];

  //=======================================
  // Item slots
  //=======================================
  string[] public ITEM_SLOTS = ["", "Head", "Chest", "Hand", "Accessory"];

  //=======================================
  // Item types
  //=======================================
  string[] public ITEM_CATEGORIES = [
    "",
    "Headgear",
    "Armor",
    "Apparel",
    "Jewelry",
    "Weapon"
  ];

  //=======================================
  // Item subtypes
  //=======================================
  string[] public ITEM_TYPES = [
    "Longsword",
    "Claymore",
    "Morning Star",
    "Dagger",
    "Trident",
    "Mace",
    "Spear",
    "Axe",
    "Hammer",
    "Tomahawk",
    "Visor",
    "Necklace",
    "Amulet",
    "Pendant",
    "Earrings",
    "Glasses",
    "Mask",
    "Helmet",
    "Cloak",
    "Ring",
    "Gloves",
    "Body Armor"
  ];

  //=======================================
  // Prefix / suffix definitions
  //=======================================
  string[] public ITEM_PREFIXES = [
    // 0 - NO PREFIX
    "",
    "Faceless",
    "Rumored",
    "Eminent",
    "Fabled"
  ];

  string[] public ITEM_SUFFIXES = [""];

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {
    // Characteristic names
    characteristics = ITEM_CHARACTERISTICS;

    // Set initial characteristics values
    characteristicValues = new string[][](6);
    characteristicValues[ITEM_CHARACTERISTIC_RARITY] = ITEM_RARITIES;
    characteristicValues[ITEM_CHARACTERISTIC_SLOT] = ITEM_SLOTS;
    characteristicValues[ITEM_CHARACTERISTIC_CATEGORY] = ITEM_CATEGORIES;
    characteristicValues[ITEM_CHARACTERISTIC_TYPE] = ITEM_TYPES;
    characteristicValues[ITEM_CHARACTERISTIC_PREFIX] = ITEM_PREFIXES;
    characteristicValues[ITEM_CHARACTERISTIC_SUFFIX] = ITEM_SUFFIXES;
  }

  //=======================================
  // External
  //=======================================
  function characteristicNames(
    uint16 _characteristic
  ) external view returns (string memory) {
    return characteristics[_characteristic];
  }

  function getCharacteristicValues(
    uint16 _characteristic,
    uint16 _id
  ) external view returns (string memory) {
    return characteristicValues[_characteristic][_id];
  }

  function characteristicValuesCount(
    uint16 _characteristic
  ) external view returns (uint16) {
    return uint16(characteristicValues[_characteristic].length);
  }

  function allCharacteristicValues(
    uint16 _characteristic
  ) external view returns (string[] memory) {
    return characteristicValues[_characteristic];
  }

  function characteristicCount() external view returns (uint16) {
    return uint16(characteristics.length);
  }

  function updateCharacteristicValues(
    uint16 _characteristic,
    string[] memory _newValues
  ) external onlyAdmin {
    characteristicValues[_characteristic] = _newValues;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

string constant ITEM_COLLECTION_NAME = "Realm Rarity items";
string constant ITEM_COLLECTION_DESCRIPTION = "Rarity items description";

//================================================
// Item-related constants, characteristics
//================================================

uint16 constant ITEM_CHARACTERISTIC_RARITY = 0;
uint16 constant ITEM_CHARACTERISTIC_SLOT = 1;
// "Weapon" slot could have "Heavy Weapon", "Magic Weapon", "Ranged Weapon"
uint16 constant ITEM_CHARACTERISTIC_CATEGORY = 2;
// Specific items in a given slot+category
// Heavy Weapon would be "Mallet" or "Great Axe", ranged weapon would be "Bow", "Crossbow", "Rifle"
uint16 constant ITEM_CHARACTERISTIC_TYPE = 3;
uint16 constant ITEM_CHARACTERISTIC_PREFIX = 4;
uint16 constant ITEM_CHARACTERISTIC_SUFFIX = 5;

uint16 constant ITEM_SLOT_HEAD = 1;
uint16 constant ITEM_SLOT_CHEST = 2;
uint16 constant ITEM_SLOT_HAND = 3;
uint16 constant ITEM_SLOT_JEWELRY = 4;

uint16 constant ITEM_TYPE_HEADGEAR = 1;
uint16 constant ITEM_TYPE_ARMOR = 2;
uint16 constant ITEM_TYPE_APPAREL = 3;
uint16 constant ITEM_TYPE_JEWELRY = 4;
uint16 constant ITEM_TYPE_WEAPON = 5;

uint16 constant ITEM_RARITY_COMMON = 1;
uint16 constant ITEM_RARITY_RARE = 2;
uint16 constant ITEM_RARITY_EPIC = 3;
uint16 constant ITEM_RARITY_LEGENDARY = 4;
uint16 constant ITEM_RARITY_MYTHIC = 5;
uint16 constant ITEM_RARITY_EXOTIC = 6;

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