// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAdventurerData {
  function initData(
    address[] calldata _addresses,
    uint256[] calldata _ids,
    bytes32[][] calldata _proofs,
    uint256[] calldata _professions,
    uint256[][] calldata _points
  ) external;

  function baseProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function aovProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function extensionProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function createFor(
    address _addr,
    uint256 _id,
    uint256[] calldata _points
  ) external;

  function createFor(address _addr, uint256 _id, uint256 _archetype) external;

  function addToBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function base(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function aov(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function extension(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library traits {
  // Base Ttraits
  // See AdventurerData.sol for details
  uint256 public constant ADV_BASE_TRAIT_XP = 1;
  uint256 public constant ADV_BASE_TRAIT_STRENGTH = 2;
  uint256 public constant ADV_BASE_TRAIT_DEXTERITY = 3;
  uint256 public constant ADV_BASE_TRAIT_CONSTITUTION = 4;
  uint256 public constant ADV_BASE_TRAIT_INTELLIGENCE = 5;
  uint256 public constant ADV_BASE_TRAIT_WISDOM = 6;
  uint256 public constant ADV_BASE_TRAIT_CHARISMA = 7;
  uint256 public constant ADV_BASE_TRAIT_HP = 8;
  uint256 public constant ADV_BASE_TRAIT_HP_USED = 9;

  // AoV Traits
  // See AdventurerData.sol for details
  uint256 public constant ADV_AOV_TRAIT_LEVEL = 0;
  uint256 public constant ADV_AOV_TRAIT_ARCHETYPE = 1;
  uint256 public constant ADV_AOV_TRAIT_CLASS = 2;
  uint256 public constant ADV_AOV_TRAIT_PROFESSION = 3;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "./IRenown.sol";
import "../lib/FloatingPointConstants.sol";
import "./IActivityRenown.sol";
import "../Utils/Epoch.sol";
import "./IAdventurerRenownBonusCalculator.sol";
import "../Adventurer/IAdventurerData.sol";
import "../Adventurer/TraitConstants.sol";
import "../Utils/EpochConfigurable.sol";
import "./IFocus.sol";

// Contract responsible for daily activity rewards
// Since it's being interacted from many sources we're also using it as a storage for the last level of activity
// This will bring gas optimization as we only need 1 iteration, but it's somewhat messy
contract ActivityRenown is EpochConfigurable, IActivityRenown {
  // epoch -> address -> tokenId -> reward dispensed
  mapping(uint256 => mapping(address => mapping(uint256 => bool))) public renownDispensed;

  IAdventurerRenownBonusCalculator public BONUS_CALCULATOR;
  IFocus public immutable FOCUS;
  IRenown public immutable RENOWN;
  IAdventurerData public immutable ADVENTURER_DATA;

  constructor(
    address _manager,
    address _focus,
    address _renownStorage,
    address _bonusCalculator,
    address _adventurerData
  ) EpochConfigurable(_manager, 1 days, 0 hours) {
    FOCUS = IFocus(_focus);
    RENOWN = IRenown(_renownStorage);
    BONUS_CALCULATOR = IAdventurerRenownBonusCalculator(_bonusCalculator);
    ADVENTURER_DATA = IAdventurerData(_adventurerData);
  }

  function markActive(
    address _sender,
    address[] calldata _adventurerAddresses,
    uint256[] calldata _adventurerTokenIds,
    uint256[] calldata _levels
  ) external onlyManager {
    FOCUS.markFocusedBatch(_adventurerAddresses, _adventurerTokenIds);

    int[] memory activityRenownDeltas;

    // prepare storage hashes for gas optimizations
    mapping(address => mapping(uint256 => bool))
      storage currentDayActivityRewards = renownDispensed[currentEpoch()];

    activityRenownDeltas = BONUS_CALCULATOR.calculateBonusBatch(
      _sender,
      _adventurerAddresses,
      _adventurerTokenIds,
      _levels
    );

    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      // Add bonus renown for daily activity
      mapping(uint256 => bool) storage dispensedRenown = currentDayActivityRewards[
        _adventurerAddresses[i]
      ];
      if (dispensedRenown[_adventurerTokenIds[i]]) {
        activityRenownDeltas[i] = 0;
      } else {
        dispensedRenown[_adventurerTokenIds[i]] = true;
      }
    }

    RENOWN.changeBatch(_adventurerAddresses, _adventurerTokenIds, _levels, activityRenownDeltas);
  }

  function updateBonusCalculator(address _bonusCalculator) external onlyAdmin {
    BONUS_CALCULATOR = IAdventurerRenownBonusCalculator(_bonusCalculator);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IActivityRenown {
  function markActive(
    address _sender,
    address[] calldata _adventurerAddresses,
    uint256[] calldata _adventurerTokenIds,
    uint[] calldata levels
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IAdventurerRenownBonusCalculator {
  function calculateBonus(
    address _sender,
    address adventurerAddress,
    uint256 adventurerTokenId,
    uint256 level
  ) external view returns (int);

  function calculateBonusBatch(
    address _sender,
    address[] calldata adventurerAddress,
    uint256[] calldata adventurerTokenId,
    uint256[] calldata level
  ) external view returns (int[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

interface IFocus is IEpochConfigurable {
  error InsufficientFocus(
    address adventurerAddress,
    uint adventurerId,
    int64 spentFocus,
    int64 currentFocus
  );

  function currentFocus(address _adventurerAddress, uint _adventurerId) external view returns (int);

  function currentFocusBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external view returns (int[] memory result);

  function isFocusedThisEpoch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external view returns (bool[] memory result);

  function setCounterBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _newValues
  ) external;

  function setCounterBatchSingleValue(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int64 _newValue
  ) external;

  function addToCounterBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _addValues
  ) external;

  function addToCounterBatchSingleValue(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int64 _addValue
  ) external;

  function markFocusedBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external;

  function spendFocusBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _spendings
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRenown {
  event RenownInitialized(address adventurerAddress, uint adventurerId, uint level, int baseAmount);
  event RenownChange(address adventurerAddress, uint adventurerId, uint level, int delta);

  // All time Renown
  function currentRenown(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _level
  ) external view returns (int);

  function currentRenowns(
    address _tokenAddress1,
    uint256 _tokenId1,
    uint _level1,
    address _tokenAddress2,
    uint256 _tokenId2,
    uint _level2
  ) external view returns (int, int);

  function currentRenownBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels
  ) external view returns (int[] memory);

  function forceInitIfNeeded(
    address _tokenAddress,
    uint256 _tokenId,
    uint _level
  ) external returns (int);

  function change(address _tokenAddress, uint256 _tokenId, uint _level, int _delta) external;

  function changeBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels,
    int[] calldata _deltas
  ) external;

  function changeBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels,
    int _delta
  ) external;
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "../lib/FloatingPointConstants.sol";

uint256 constant MASK_128 = ((1 << 128) - 1);
uint128 constant MASK_64 = ((1 << 64) - 1);

library Epoch {
  // Converts a given timestamp to an epoch using the specified duration and offset.
  // Example for battle timers resetting at noon UTC is: _duration = 1 days; _offset = 12 hours;
  function toEpochNumber(
    uint256 _timestamp,
    uint256 _duration,
    uint256 _offset
  ) internal pure returns (uint256) {
    return (_timestamp + _offset) / _duration;
  }

  // Here we assume that _config is a packed _duration (left 64 bits) and _offset (right 64 bits)
  function toEpochNumber(uint256 _timestamp, uint128 _config) internal pure returns (uint256) {
    return (_timestamp + (_config & MASK_64)) / ((_config >> 64) & MASK_64);
  }

  // Returns a value between 0 and ONE_HUNDRED which is the percentage of "completeness" of the epoch
  // result variable is reused for memory efficiency
  function toEpochCompleteness(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = (_config >> 64) & MASK_64;
    result = (ONE_HUNDRED * ((_timestamp + (_config & MASK_64)) % result)) / result;
  }

  // Create a config for the function above
  function toConfig(uint64 _duration, uint64 _offset) internal pure returns (uint128) {
    return (uint128(_duration) << 64) | uint128(_offset);
  }

  // Pack the epoch number with the config into a single uint256 for mappings
  function packEpoch(uint256 _epochNumber, uint128 _config) internal pure returns (uint256) {
    return (uint256(_config) << 128) | uint128(_epochNumber);
  }

  // Convert timestamp to Epoch and pack it with the config into a single uint256 for mappings
  function packTimestampToEpoch(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256) {
    return packEpoch(toEpochNumber(_timestamp, _config), _config);
  }

  // Unpack packedEpoch to epochNumber and config
  function unpack(
    uint256 _packedEpoch
  ) internal pure returns (uint256 epochNumber, uint128 config) {
    config = uint128(_packedEpoch >> 128);
    epochNumber = _packedEpoch & MASK_128;
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "./IEpochConfigurable.sol";

contract EpochConfigurable is ManagerModifier, IEpochConfigurable {
  uint128 public EPOCH_CONFIG;

  constructor(
    address _manager,
    uint64 _epochDuration,
    uint64 _epochOffset
  ) ManagerModifier(_manager) {
    EPOCH_CONFIG = Epoch.toConfig(_epochDuration, _epochOffset);
  }

  function currentEpoch() public view returns (uint) {
    return epochAtTimestamp(block.timestamp);
  }

  function epochAtTimestamp(uint _timestamp) public view returns (uint) {
    return Epoch.toEpochNumber(_timestamp, EPOCH_CONFIG);
  }

  function updateEpochConfig(uint64 duration, uint64 offset) external onlyAdmin {
    EPOCH_CONFIG = Epoch.toConfig(duration, offset);
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}