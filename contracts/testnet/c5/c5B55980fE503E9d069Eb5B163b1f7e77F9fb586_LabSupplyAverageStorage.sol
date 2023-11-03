// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBatchBurnableStructure {
  function burnBatchFor(
    address _from,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../BatchStaker/IBatchBurnableStructure.sol";

interface ILab is IBatchBurnableStructure {
  function totalSupply(uint _tokenId) external view returns (uint256);

  function mintFor(address _for, uint256 _id, uint256 _amount) external;

  function mintBatchFor(
    address _for,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function mintBatchFor(
    address[] calldata _for,
    uint256[][] memory _ids,
    uint256[][] memory _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] calldata ids, uint256[] calldata amounts) external;

  function burnBatch(uint256[][] memory ids, uint256[][] memory amounts) external;

  function burnBatchFor(
    address _for,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function burnFor(address _for, uint256 _id, uint256 _amount) external;

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[][] memory ids,
    uint256[][] memory amounts,
    bytes memory data
  ) external;
}

import "../Manager/ManagerModifier.sol";
import "../SupplyDemand/AbstractEpochAverageStorage.sol";
import "../Utils/Epoch.sol";
import "./ILab.sol";

contract LabSupplyAverageStorage is ManagerModifier, AbstractEpochAverageStorage {
  using Epoch for uint256;

  uint constant LAB_GROUP = 0;

  uint128 public EPOCH_CONFIG;
  EpochAverageStorageConfig public AVERAGE_STORAGE_CONFIG;
  ILab public immutable LAB;

  constructor(address _manager, address _lab) ManagerModifier(_manager) {
    LAB = ILab(_lab);
    EPOCH_CONFIG = Epoch.toConfig(1 days, 0 hours);

    AVERAGE_STORAGE_CONFIG = EpochAverageStorageConfig(4, 1, 5); // EMA5
  }

  function getSupplyBatch(uint256[] calldata _labIds) external returns (uint256[] memory) {
    return _getValueBatch(LAB_GROUP, _labIds);
  }

  function _getConfig(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (EpochAverageStorageConfig memory) {
    return AVERAGE_STORAGE_CONFIG;
  }

  function _getCurrentValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (uint256) {
    return LAB.totalSupply(_subGroup);
  }

  function _getPredictedNextValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (uint256) {
    return LAB.totalSupply(_subGroup);
  }

  function _getCurrentEpoch(
    uint256 _group,
    uint256 _subGroup
  ) internal view override returns (uint256) {
    return Epoch.toEpochNumber(block.timestamp, EPOCH_CONFIG);
  }

  function forceUpdateBaseValue(uint _tokenId, uint newValue) external onlyAdmin {
    _forceUpdateBaseValue(LAB_GROUP, _tokenId, newValue);
  }

  function updateConfig(uint _baseWeight, uint _epochWeight) external onlyAdmin {
    AVERAGE_STORAGE_CONFIG.baseWeight = _baseWeight;
    AVERAGE_STORAGE_CONFIG.epochWeight = _epochWeight;
    AVERAGE_STORAGE_CONFIG.totalWeight = _baseWeight + _epochWeight;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../lib/FloatingPointConstants.sol";

struct EpochAverageStorageConfig {
  uint256 baseWeight;
  uint256 epochWeight;
  uint256 totalWeight;
}

abstract contract AbstractEpochAverageStorage {
  mapping(uint256 => EpochAverageStorageConfig) public config;
  mapping(uint256 => mapping(uint256 => uint256)) public baseValueEpoch;
  mapping(uint256 => mapping(uint256 => uint256)) public baseValue;

  function _getConfig(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (EpochAverageStorageConfig memory);

  function _getCurrentValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (uint256);

  function _getPredictedNextValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (uint256);

  function _getCurrentEpoch(
    uint256 _group,
    uint256 _subGroup
  ) internal view virtual returns (uint256);

  function _predictNextValue(
    uint256 _group,
    uint256 _subGroup
  ) internal view returns (uint256 result) {
    EpochAverageStorageConfig memory cfg = _getConfig(_group, _subGroup);

    result = _getValueView(_group, _subGroup);
    uint256 predictedValue = _getPredictedNextValue(_group, _subGroup);
    result = (result * cfg.baseWeight + predictedValue * cfg.epochWeight) / cfg.totalWeight;
  }

  function _getValue(uint256 _group, uint256 _subGroup) internal returns (uint256 result) {
    uint currentEpoch = _getCurrentEpoch(_group, _subGroup);
    if (currentEpoch == baseValueEpoch[_group][_subGroup]) {
      return baseValue[_group][_subGroup];
    }

    result = _getValueView(_group, _subGroup);
    baseValue[_group][_subGroup] = result;
    baseValueEpoch[_group][_subGroup] = currentEpoch;
  }

  function _getValueView(uint256 _group, uint256 _subGroup) internal view returns (uint256 result) {
    result = baseValue[_group][_subGroup];
    uint256 currentEpoch = _getCurrentEpoch(_group, _subGroup);
    if (currentEpoch == baseValueEpoch[_group][_subGroup]) {
      return baseValue[_group][_subGroup];
    }

    EpochAverageStorageConfig memory cfg = _getConfig(_group, _subGroup);
    result =
      (result * cfg.baseWeight + _getCurrentValue(_group, _subGroup) * cfg.epochWeight) /
      cfg.totalWeight;
  }

  function _getValueBatch(
    uint256 _group,
    uint256[] calldata _subGroups
  ) internal returns (uint256[] memory results) {
    results = new uint256[](_subGroups.length);
    for (uint i = 0; i < _subGroups.length; i++) {
      results[i] = _getValue(_group, _subGroups[i]);
    }
  }

  function _getValueViewBatch(
    uint256 _group,
    uint256[] calldata _subGroups
  ) internal view returns (uint256[] memory results) {
    results = new uint256[](_subGroups.length);
    for (uint i = 0; i < _subGroups.length; i++) {
      results[i] = _getValueView(_group, _subGroups[i]);
    }
  }

  function _getPredictionBatch(
    uint256 _group,
    uint256[] calldata _subGroups
  ) internal view returns (uint256[] memory results) {
    results = new uint256[](_subGroups.length);
    for (uint i = 0; i < _subGroups.length; i++) {
      results[i] = _getPredictedNextValue(_group, _subGroups[i]);
    }
  }

  function _forceUpdateBaseValue(uint _group, uint _subgroup, uint _newValue) internal {
    baseValue[_group][_subgroup] = _newValue;
    baseValueEpoch[_group][_subgroup] = _getCurrentEpoch(_group, _subgroup);
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