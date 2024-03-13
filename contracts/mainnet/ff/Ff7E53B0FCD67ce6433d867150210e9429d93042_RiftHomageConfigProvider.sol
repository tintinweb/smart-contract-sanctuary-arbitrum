// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
uint256 constant ROUNDING_ADJUSTER = DECIMAL_POINT - 1;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
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

  modifier onlyConfigManager() {
    require(MANAGER.isManager(msg.sender, 4), "Manager: Not config manager");
    _;
  }

  modifier onlyTokenSpender() {
    require(MANAGER.isManager(msg.sender, 5), "Manager: Not token spender");
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

struct RiftHomageConfigStruct {
  uint[4] structureId;
  uint[4] realmTokenCost;
  uint[4] voidTokenCost;
  uint[4] durabilityLossPercentage;
  uint[4] structureAnimaCapacity;
}

interface IRiftHomageConfigProvider {
  function config() external view returns (RiftHomageConfigStruct memory);

  function animaCapacityPerStructure() external view returns (uint[7] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../Utils/Epoch.sol";
import "./IRiftHomageConfigProvider.sol";

contract RiftHomageConfigProvider is
  ManagerModifier,
  IRiftHomageConfigProvider
{
  RiftHomageConfigStruct private CONFIG;

  uint[7] public STRUCTURES_CAPACITY;

  uint public MIN_DURABILITY_LOSS;
  uint public MAX_DURABILITY_LOSS;

  uint public MIN_TOKEN_COST;

  constructor(address _manager) ManagerModifier(_manager) {
    MIN_DURABILITY_LOSS = 1;
    MAX_DURABILITY_LOSS = 100_000;
    MIN_TOKEN_COST = 1 ether;
  }

  function config() external view returns (RiftHomageConfigStruct memory) {
    return CONFIG;
  }

  function animaCapacityPerStructure() external view returns (uint[7] memory) {
    return STRUCTURES_CAPACITY;
  }

  function updateConfig(
    RiftHomageConfigStruct calldata _config
  ) external onlyConfigManager {
    CONFIG = _config;
    for (uint i = 0; i < 7; i++) {
      STRUCTURES_CAPACITY[i] = 0;
    }
    for (uint i = 0; i < 4; i++) {
      if (
        _config.durabilityLossPercentage[i] < MIN_DURABILITY_LOSS ||
        _config.durabilityLossPercentage[i] > MAX_DURABILITY_LOSS
      ) {
        revert("Invalid durability loss");
      }
      STRUCTURES_CAPACITY[_config.structureId[i]] = _config
        .structureAnimaCapacity[i];
    }
  }

  function updateConfigRanges(
    uint _minDurabilityLoss,
    uint _maxDurabilityLoss,
    uint _minTokenCost
  ) external onlyAdmin {
    MIN_DURABILITY_LOSS = _minDurabilityLoss;
    MAX_DURABILITY_LOSS = _maxDurabilityLoss;
    MIN_TOKEN_COST = _minTokenCost;
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Unlicensed

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

  // Converts a given epoch to a timestamp at the start of the epoch
  function epochToTimestamp(
    uint256 _epoch,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = _epoch * ((_config >> 64) & MASK_64);
    if (result > 0) {
      result -= (_config & MASK_64);
    }
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