pragma solidity ^0.8.17;

interface IMaximumDurabilitySource {
  function getMaximumDurability(address _address, uint _token) external view returns (uint32);
}

pragma solidity ^0.8.17;

import "./IMaximumDurabilitySource.sol";
import "../Item/IRarityItemDataStorage.sol";
import "../Item/RarityItemConstants.sol";
import "../lib/FloatingPointConstants.sol";

contract RarityItemDurabilitySource is IMaximumDurabilitySource {
  error UnsupportedItemRarity(uint16 _rarity);

  IRarityItemDataStorage public immutable rarityItemDataStorage;

  constructor(address _rarityItemDataStorage) {
    rarityItemDataStorage = IRarityItemDataStorage(_rarityItemDataStorage);
  }

  function getMaximumDurability(address _address, uint _tokenId) external view returns (uint32) {
    uint16 rarity = rarityItemDataStorage.characteristics(_tokenId, ITEM_CHARACTERISTIC_RARITY);
    if (rarity == ITEM_RARITY_COMMON) {
      return uint32(ONE_HUNDRED / 2);
    }
    if (rarity == ITEM_RARITY_RARE) {
      return uint32(ONE_HUNDRED);
    }
    if (rarity == ITEM_RARITY_EPIC) {
      return 2 * uint32(ONE_HUNDRED);
    }
    if (rarity == ITEM_RARITY_LEGENDARY) {
      return 3 * uint32(ONE_HUNDRED);
    }
    if (rarity == ITEM_RARITY_MYTHIC) {
      return 5 * uint32(ONE_HUNDRED);
    }
    if (rarity == ITEM_RARITY_EXOTIC) {
      return 8 * uint32(ONE_HUNDRED);
    }
    revert UnsupportedItemRarity(rarity);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IItemDataStorage {
  function obtainTokenId(
    uint16[] memory _characteristics
  ) external returns (uint256);

  function characteristics(
    uint256 _tokenId,
    uint16 _characteristicId
  ) external view returns (uint16);

  function characteristics(
    uint256 _tokenId
  ) external view returns (uint16[16] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./IItemDataStorage.sol";

interface IRarityItemDataStorage is IItemDataStorage {
  event RarityItemUpdated(uint256 _tokenId, uint16[] characteristics);

  function getPackedCharacteristics(
    uint256 _tokenId
  ) external view returns (uint256);
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

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10**3;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);
uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;

int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ZERO = 0;