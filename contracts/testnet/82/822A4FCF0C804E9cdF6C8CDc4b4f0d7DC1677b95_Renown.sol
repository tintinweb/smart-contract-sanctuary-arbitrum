// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
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

interface IRenown {
  event RenownInitialized(address adventurerAddress, uint adventurerId, uint level, int baseAmount);
  event RenownChange(address adventurerAddress, uint adventurerId, uint level, int delta);

  // All time Renown
  function currentRenown(address _tokenAddress, uint256 _tokenId) external view returns (int);

  function currentRenownBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds
  ) external view returns (int[] memory);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "./IRenown.sol";
import "./RenownConstants.sol";
import "../Utils/Epoch.sol";
import "../Utils/EpochConfigurable.sol";

contract Renown is ManagerModifier, IRenown {
  // token address -> tokenId -> value
  mapping(address => mapping(uint256 => int)) public currentRenown;

  // address -> tokenId -> reward dispensed
  mapping(address => mapping(uint256 => bool)) public initialRenownDispensed;
  int public STARTING_RENOWN_PER_LEVEL;

  constructor(address _manager) ManagerModifier(_manager) {
    STARTING_RENOWN_PER_LEVEL = SIGNED_ONE_HUNDRED;
  }

  function currentRenownBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds
  ) external view returns (int[] memory result) {
    result = new int[](_tokenAddresses.length);
    for (uint i = 0; i < _tokenAddresses.length; i++) {
      result[i] = currentRenown[_tokenAddresses[i]][_tokenIds[i]];
    }
  }

  function change(
    address _tokenAddress,
    uint256 _tokenId,
    uint _level,
    int _delta
  ) public onlyManager {
    _change(_tokenAddress, _tokenId, _level, _delta);
  }

  function changeBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels,
    int[] calldata _deltas
  ) external onlyManager {
    for (uint i = 0; i < _tokenAddresses.length; i++) {
      _change(_tokenAddresses[i], _tokenIds[i], _levels[i], _deltas[i]);
    }
  }

  function changeBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels,
    int _delta
  ) external onlyManager {
    for (uint i = 0; i < _tokenAddresses.length; i++) {
      _change(_tokenAddresses[i], _tokenIds[i], _levels[i], _delta);
    }
  }

  function _change(address _tokenAddress, uint256 _tokenId, uint _level, int _delta) internal {
    if (_delta == 0) {
      return;
    }

    if (!initialRenownDispensed[_tokenAddress][_tokenId]) {
      initialRenownDispensed[_tokenAddress][_tokenId] = true;
      currentRenown[_tokenAddress][_tokenId] = int(_level) * STARTING_RENOWN_PER_LEVEL;
      emit RenownInitialized(
        _tokenAddress,
        _tokenId,
        _level,
        currentRenown[_tokenAddress][_tokenId]
      );
    }

    if (currentRenown[_tokenAddress][_tokenId] + _delta < 0) {
      _delta = -currentRenown[_tokenAddress][_tokenId];
    }

    currentRenown[_tokenAddress][_tokenId] += _delta;
    emit RenownChange(_tokenAddress, _tokenId, _level, _delta);
  }
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