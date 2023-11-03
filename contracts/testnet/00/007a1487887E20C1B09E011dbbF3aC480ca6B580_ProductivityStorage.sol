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

interface IProductivityStorage {
  // Current Epoch
  function currentEpoch() external view returns (uint256);

  function isEpochValid(uint256 _epoch) external view returns (bool);

  // All time Productivity
  function totalLifetimeProductivity(uint256 _tokenId) external view returns (int);

  function lifetimeProductivity(
    uint256 _tokenId,
    uint16 _productivityType
  ) external view returns (int128);

  // Epoch Productivity
  function totalEpochProductivity(uint256 _epoch, uint256 _tokenId) external view returns (int);

  function epochProductivity(
    uint256 _epoch,
    uint256 _tokenId,
    uint16 _productivityType
  ) external view returns (int64);

  // Current Epoch Productivity
  function totalCurrentEpochProductivity(
    uint256 _tokenId
  ) external view returns (int total, uint epoch);

  function currentEpochProductivity(
    uint256 _tokenId,
    uint16 _productivityType
  ) external view returns (int);

  // Updates
  function change(uint256 _tokenId, int _delta, uint16 _productivityType) external;

  function changeBatch(
    uint256[] calldata _tokenId,
    int[] calldata _deltas,
    uint16 _productivityType
  ) external;

  function changeBatch(uint256[] calldata _tokenId, int _delta, uint16 _productivityType) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

uint16 constant PRODUCTIVITY_TYPE_TECH = 0;
//uint16 constant PRODUCTIVITY_TYPE_EARTHEN = 1;
//uint16 constant PRODUCTIVITY_TYPE_NOURISHMENT = 2;
//uint16 constant PRODUCTIVITY_TYPE_AQUATIC = 3;

// increment and update usages in contracts if you add renown types
uint16 constant PRODUCTIVITY_TYPE_COUNT = 1;

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "./IProductivityStorage.sol";
import "./ProductivityConstants.sol";
import "../Utils/Epoch.sol";
import "./IProductivityStorage.sol";

contract ProductivityStorage is ManagerModifier, IProductivityStorage {
  using Epoch for uint256;

  event EpochConfigChange(uint256 EPOCH_DURATION, uint256 EPOCH_OFFSET, uint256 EPOCH_CONFIG);

  event ProductivityChange(uint256 assetId, uint256 epoch, uint16 productivityType, int64 delta);

  uint256 public MAX_PRODUCTIVITY_TYPE = PRODUCTIVITY_TYPE_COUNT;
  uint128 public EPOCH_CONFIG;

  // tokenId -> productivity type -> value
  mapping(uint256 => mapping(uint16 => int128)) public lifetimeProductivity;

  // Epoch -> tokenId -> productivity type -> value
  mapping(uint256 => mapping(uint256 => mapping(uint16 => int64))) public epochProductivity;

  // Epoch -> validity
  mapping(uint256 => bool) public epochValidity;

  // Epoch -> validity list
  uint256[] public validEpochs;

  constructor(address _manager) ManagerModifier(_manager) {
    EPOCH_CONFIG = Epoch.toConfig(7 days, 12 hours);
  }

  function validEpochsLength() public view returns (uint256) {
    return validEpochs.length;
  }

  function isEpochValid(uint256 _epoch) public view returns (bool) {
    return (_epoch == currentEpoch()) || epochValidity[_epoch];
  }

  // All time Productivity
  function totalLifetimeProductivity(uint256 _tokenId) public view returns (int total) {
    mapping(uint16 => int128) storage totalProductivityStorages = lifetimeProductivity[_tokenId];
    for (uint16 i = 0; i < MAX_PRODUCTIVITY_TYPE; i++) {
      total += totalProductivityStorages[i];
    }
  }

  // Epoch productivity
  function totalEpochProductivity(
    uint256 _epoch,
    uint256 _tokenId
  ) public view returns (int total) {
    mapping(uint16 => int64) storage epochProductivityStorages = epochProductivity[_epoch][
      _tokenId
    ];
    for (uint16 i = 0; i < MAX_PRODUCTIVITY_TYPE; i++) {
      total += epochProductivityStorages[i];
    }
  }

  // Current Epoch productivity
  function totalCurrentEpochProductivity(uint256 _tokenId) public view returns (int, uint epoch) {
    epoch = this.currentEpoch();
    return (this.totalEpochProductivity(epoch, _tokenId), epoch);
  }

  function currentEpochProductivity(
    uint256 _tokenId,
    uint16 _productivityType
  ) public view returns (int) {
    return epochProductivity[this.currentEpoch()][_tokenId][_productivityType];
  }

  function currentEpochProductivityAndTotalProductivity(
    uint256 _tokenId,
    uint16 _productivityType
  ) public view returns (int specific, int total) {
    mapping(uint16 => int64) storage epochProductivityStorages = epochProductivity[currentEpoch()][
      _tokenId
    ];
    for (uint16 i = 0; i < MAX_PRODUCTIVITY_TYPE; i++) {
      if (i == _productivityType) {
        specific = epochProductivityStorages[i];
      }
      total += epochProductivityStorages[i];
    }
  }

  // Productivity changes
  function change(uint _tokenId, int _delta, uint16 _productivityType) external onlyManager {
    uint256 nowEpoch = currentEpoch();
    if (validEpochs.length == 0 || nowEpoch != validEpochs[validEpochs.length - 1]) {
      validEpochs.push(nowEpoch);
      epochValidity[nowEpoch] = true;
    }

    lifetimeProductivity[_tokenId][_productivityType] += int128(_delta);
    epochProductivity[nowEpoch][_tokenId][_productivityType] += int64(_delta);

    emit ProductivityChange(_tokenId, nowEpoch, _productivityType, int64(_delta));
  }

  function changeBatch(
    uint256[] calldata _tokenId,
    int[] calldata _delta,
    uint16 _productivityType
  ) external onlyManager {
    uint256 nowEpoch = currentEpoch();
    if (validEpochs.length == 0 || nowEpoch != validEpochs[validEpochs.length - 1]) {
      validEpochs.push(nowEpoch);
      epochValidity[nowEpoch] = true;
    }

    mapping(uint256 => mapping(uint16 => int64)) storage nowEpochProductivity = epochProductivity[
      nowEpoch
    ];

    for (uint16 i = 0; i < _tokenId.length; i++) {
      lifetimeProductivity[_tokenId[i]][_productivityType] += int128(_delta[i]);
      nowEpochProductivity[_tokenId[i]][_productivityType] += int64(_delta[i]);

      emit ProductivityChange(_tokenId[i], nowEpoch, _productivityType, int64(_delta[i]));
    }
  }

  function changeBatch(
    uint256[] calldata _tokenId,
    int _delta,
    uint16 _productivityType
  ) external onlyManager {
    uint256 nowEpoch = currentEpoch();
    if (validEpochs.length == 0 || nowEpoch != validEpochs[validEpochs.length - 1]) {
      validEpochs.push(nowEpoch);
      epochValidity[nowEpoch] = true;
    }

    mapping(uint256 => mapping(uint16 => int64)) storage nowEpochProductivity = epochProductivity[
      nowEpoch
    ];

    for (uint16 i = 0; i < _tokenId.length; i++) {
      lifetimeProductivity[_tokenId[i]][_productivityType] += int128(_delta);
      nowEpochProductivity[_tokenId[i]][_productivityType] += int64(_delta);

      emit ProductivityChange(_tokenId[i], nowEpoch, _productivityType, int64(_delta));
    }
  }

  function unpackEpoch(uint256 _packedEpoch) public pure returns (uint256, uint128) {
    return _packedEpoch.unpack();
  }

  function timestampToEpoch(uint256 _timestamp) public view returns (uint256) {
    return _timestamp.packTimestampToEpoch(EPOCH_CONFIG);
  }

  function currentEpoch() public view returns (uint256) {
    return block.timestamp.packTimestampToEpoch(EPOCH_CONFIG);
  }

  //--------------------------------
  // Admin
  //--------------------------------

  function updateEpochConfig(uint64 _duration, uint64 _offset) external onlyAdmin {
    EPOCH_CONFIG = Epoch.toConfig(_duration, _offset);
    emit EpochConfigChange(_duration, _offset, EPOCH_CONFIG);
  }

  function updateMaxProductivityType(uint256 _maxProductivityType) external onlyAdmin {
    MAX_PRODUCTIVITY_TYPE = _maxProductivityType;
  }
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