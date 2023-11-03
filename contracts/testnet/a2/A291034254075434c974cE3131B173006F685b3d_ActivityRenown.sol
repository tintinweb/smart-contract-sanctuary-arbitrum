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

uint256 constant DECIMAL_POINT = 10**3;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);
uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;

int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
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
import "./IRenownStorage.sol";
import "./RenownConstants.sol";
import "../lib/FloatingPointConstants.sol";
import "./IActivityRenown.sol";
import "../Utils/Epoch.sol";
import "./IRenownBonusCalculator.sol";
import "../Adventurer/IAdventurerData.sol";
import "../Adventurer/TraitConstants.sol";

uint256 constant TWO = 2 * DECIMAL_POINT;

struct ActivityConfig {
  uint256 activityReward;
}

struct CalculationMemory {
  address adventurerAddress;
  uint256 adventurerTokenId;
  uint256 activityEpoch;
  uint256 renownEpoch;
}

// Contract responsible for daily activity rewards
// Since it's being interacted from many sources we're also using it as a storage for the last level of activity
// This will bring gas optimization as we only need 1 iteration, but it's somewhat messy
contract ActivityRenown is ManagerModifier, IActivityRenown {
  using Epoch for uint256;

  mapping(uint256 => ActivityConfig) private activityConfig;

  // Weekly Renown epoch -> address -> tokenId -> level mapping
  mapping(uint256 => mapping(address => mapping(uint256 => uint32))) public lastActionLevel;

  // Daily renown epoch -> address -> tokenId -> reward dispensed
  mapping(uint256 => mapping(address => mapping(uint256 => bool))) public renownDispensed;

  // We dispense daily rewards for activity
  uint128 private ACTIVITY_REWARDS_EPOCH_CONFIG = Epoch.toConfig(1 days, 12 hours);

  IRenownStorage public RENOWN_STORAGE;
  IRenownBonusCalculator public BONUS_CALCULATOR;
  IAdventurerData public immutable ADVENTURER_DATA;

  constructor(
    address _manager,
    address _renownStorage,
    address _bonusCalculator,
    address _adventurerData
  ) ManagerModifier(_manager) {
    RENOWN_STORAGE = IRenownStorage(_renownStorage);
    BONUS_CALCULATOR = IRenownBonusCalculator(_bonusCalculator);
    ADVENTURER_DATA = IAdventurerData(_adventurerData);
  }

  function lastActionLevelBatch(
    uint256 _epoch,
    address[] calldata _adventurerAddress,
    uint256[] calldata _adventurerToken
  ) external view returns (uint32[] memory result) {
    result = new uint32[](_adventurerAddress.length);
    mapping(address => mapping(uint256 => uint32)) storage epochLevels = lastActionLevel[_epoch];
    for (uint i = 0; i < _adventurerAddress.length; i++) {
      result[i] = epochLevels[_adventurerAddress[i]][_adventurerToken[i]];
    }
  }

  function markActive(
    address[] calldata _adventurerAddresses,
    uint256[] calldata _adventurerTokenIds
  ) external onlyManager returns (uint[] memory levels) {
    CalculationMemory memory calcMemory;
    calcMemory.renownEpoch = RENOWN_STORAGE.currentEpoch();
    calcMemory.activityEpoch = block.timestamp.packTimestampToEpoch(ACTIVITY_REWARDS_EPOCH_CONFIG);

    // prepare storage hashes for gas optimizations
    mapping(address => mapping(uint256 => uint32)) storage currentEpochLevels = lastActionLevel[
      calcMemory.renownEpoch
    ];
    mapping(address => mapping(uint256 => bool))
      storage currentDayActivityRewards = renownDispensed[calcMemory.activityEpoch];

    levels = new uint[](_adventurerAddresses.length);
    int[] memory activityRenownDeltas = new int[](_adventurerAddresses.length);
    // For each adventurer set the level of the last activity
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      calcMemory.adventurerAddress = _adventurerAddresses[i];
      calcMemory.adventurerTokenId = _adventurerTokenIds[i];
      mapping(uint256 => uint32) storage storedLevels = currentEpochLevels[
        calcMemory.adventurerAddress
      ];

      if (storedLevels[calcMemory.adventurerTokenId] == 0) {
        storedLevels[calcMemory.adventurerTokenId] = uint32(
          ADVENTURER_DATA.aov(
            calcMemory.adventurerAddress,
            calcMemory.adventurerTokenId,
            traits.ADV_AOV_TRAIT_LEVEL
          )
        );
      }
      levels[i] = uint256(storedLevels[calcMemory.adventurerTokenId]);

      // Add bonus renown for daily activity
      mapping(uint256 => bool) storage dispensedRenown = currentDayActivityRewards[
        calcMemory.adventurerAddress
      ];
      if (!dispensedRenown[calcMemory.adventurerTokenId]) {
        activityRenownDeltas[i] = BONUS_CALCULATOR.calculateBonus(
          calcMemory.adventurerAddress,
          calcMemory.adventurerTokenId,
          levels[i]
        );
        dispensedRenown[calcMemory.adventurerTokenId] = true;
      }
    }

    RENOWN_STORAGE.changeMany(
      _adventurerAddresses,
      _adventurerTokenIds,
      activityRenownDeltas,
      RENOWN_TYPE_ACTIVITY
    );
  }

  function updateBonusCalculator(address _bonusCalculator) external onlyAdmin {
    BONUS_CALCULATOR = IRenownBonusCalculator(_bonusCalculator);
  }

  function updateEpochConfig(uint64 _duration, uint64 _offset) external onlyAdmin {
    ACTIVITY_REWARDS_EPOCH_CONFIG = Epoch.toConfig(_duration, _offset);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IActivityRenown {
  function markActive(
    address[] calldata _adventurerAddresses,
    uint256[] calldata _adventurerTokenIds
  ) external returns (uint[] memory levels);

  function lastActionLevel(
    uint256 _epoch,
    address _adventurerAddress,
    uint256 _adventurerToken
  ) external view returns (uint32);

  function lastActionLevelBatch(
    uint256 _epoch,
    address[] calldata _adventurerAddress,
    uint256[] calldata _adventurerToken
  ) external view returns (uint32[] memory);

  function renownDispensed(
    uint256 _epoch,
    address _adventurerAddress,
    uint256 _adventurerToken
  ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRenownBonusCalculator {
  function calculateBonus(
    address adventurerAddress,
    uint256 adventurerTokenId,
    uint256 level
  ) external pure returns (int);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRenownStorage {
  // Current Epoch
  function currentEpoch() external view returns (uint256);

  // Descending epochs from the current epoch in descending order
  function getLastValidEpochs(
    uint count,
    bool skipCurrent
  ) external view returns (uint256[] memory);

  function isEpochValid(uint256 _epoch) external view returns (bool);

  // All time Renown
  function totalLifetimeRenown(address _tokenAddress, uint256 _tokenId) external view returns (int);

  function lifetimeRenown(
    address _tokenAddress,
    uint256 _tokenId,
    uint16 _renownType
  ) external view returns (int128);

  // Epoch Renown
  function totalEpochRenown(
    uint256 _epoch,
    address _tokenAddress,
    uint256 _tokenId
  ) external view returns (int);

  function epochRenown(
    uint256 _epoch,
    address _tokenAddress,
    uint256 _tokenId,
    uint16 _renownType
  ) external view returns (int64);

  // Current Epoch Renown
  function totalCurrentEpochRenown(
    address _tokenAddress,
    uint256 _tokenId
  ) external view returns (int total, uint epoch);

  function currentEpochRenown(
    address _tokenAddress,
    uint256 _tokenId,
    uint16 _renownType
  ) external view returns (int);

  // Updates
  function change(address _tokenAddress, uint256 _tokenId, int _delta, uint16 _renownType) external;

  function changeMany(
    address[] calldata _tokenAddress,
    uint256[] calldata _tokenId,
    int[] calldata _deltas,
    uint16 _renownType
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

uint16 constant RENOWN_TYPE_ACTIVITY = 0;
uint16 constant RENOWN_TYPE_BATTLE = 1;

// increment and update usages in contracts if you add renown types
uint16 constant RENOWN_TYPE_COUNT = 2;

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