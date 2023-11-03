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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "./IRenownStorage.sol";
import "./RenownConstants.sol";
import "../Utils/Epoch.sol";

contract RenownStorage is ManagerModifier, IRenownStorage {
  using Epoch for uint256;

  event EpochConfigChange(uint256 EPOCH_DURATION, uint256 EPOCH_OFFSET, uint256 EPOCH_CONFIG);

  event RenownChange(
    address adventurerAddress,
    uint adventurerId,
    uint epoch,
    uint renownType,
    int delta
  );

  uint256 public MAX_RENOWN_TYPE = RENOWN_TYPE_COUNT;
  uint128 public EPOCH_CONFIG;

  // token address -> tokenId -> renown type -> value
  mapping(address => mapping(uint256 => mapping(uint16 => int128))) public lifetimeRenown;

  // Epoch -> token address -> tokenId -> renown type -> value
  mapping(uint256 => mapping(address => mapping(uint256 => mapping(uint16 => int64))))
    public epochRenown;

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

  // All time Renown
  function totalLifetimeRenown(
    address _tokenAddress,
    uint256 _tokenId
  ) public view returns (int total) {
    mapping(uint16 => int128) storage totalRenownStorages = lifetimeRenown[_tokenAddress][_tokenId];
    for (uint16 i = 0; i < MAX_RENOWN_TYPE; i++) {
      total += totalRenownStorages[i];
    }
  }

  // Epoch renown
  function totalEpochRenown(
    uint256 _epoch,
    address _tokenAddress,
    uint256 _tokenId
  ) public view returns (int total) {
    mapping(uint16 => int64) storage epochRenownStorages = epochRenown[_epoch][_tokenAddress][
      _tokenId
    ];
    for (uint16 i = 0; i < MAX_RENOWN_TYPE; i++) {
      total += epochRenownStorages[i];
    }
  }

  // Current Epoch renown
  function totalCurrentEpochRenown(
    address _tokenAddress,
    uint256 _tokenId
  ) public view returns (int, uint epoch) {
    epoch = this.currentEpoch();
    return (this.totalEpochRenown(epoch, _tokenAddress, _tokenId), epoch);
  }

  function currentEpochRenown(
    address _tokenAddress,
    uint256 _tokenId,
    uint16 _renownType
  ) public view returns (int) {
    return epochRenown[this.currentEpoch()][_tokenAddress][_tokenId][_renownType];
  }

  function currentEpochRenownAndTotalRenown(
    address _tokenAddress,
    uint256 _tokenId,
    uint16 _renownType
  ) public view returns (int specific, int total) {
    mapping(uint16 => int64) storage epochRenownStorages = epochRenown[currentEpoch()][
      _tokenAddress
    ][_tokenId];
    for (uint16 i = 0; i < MAX_RENOWN_TYPE; i++) {
      if (i == _renownType) {
        specific = epochRenownStorages[i];
      }
      total += epochRenownStorages[i];
    }
  }

  // Renown changes
  function change(
    address _tokenAddress,
    uint _tokenId,
    int _delta,
    uint16 _renownType
  ) external onlyManager {
    uint256 nowEpoch = currentEpoch();
    if (validEpochs.length == 0 || nowEpoch != validEpochs[validEpochs.length - 1]) {
      validEpochs.push(nowEpoch);
      epochValidity[nowEpoch] = true;
    }

    lifetimeRenown[_tokenAddress][_tokenId][_renownType] += int128(_delta);
    epochRenown[nowEpoch][_tokenAddress][_tokenId][_renownType] += int64(_delta);

    emit RenownChange(_tokenAddress, _tokenId, nowEpoch, _renownType, int64(_delta));
  }

  function changeMany(
    address[] calldata _tokenAddress,
    uint256[] calldata _tokenId,
    int[] calldata _delta,
    uint16 _renownType
  ) external onlyManager {
    uint256 nowEpoch = currentEpoch();
    if (validEpochs.length == 0 || nowEpoch != validEpochs[validEpochs.length - 1]) {
      validEpochs.push(nowEpoch);
      epochValidity[nowEpoch] = true;
    }

    mapping(address => mapping(uint256 => mapping(uint16 => int64)))
      storage nowEpochRenown = epochRenown[nowEpoch];

    for (uint16 i = 0; i < _tokenAddress.length; i++) {
      lifetimeRenown[_tokenAddress[i]][_tokenId[i]][_renownType] += int128(_delta[i]);
      nowEpochRenown[_tokenAddress[i]][_tokenId[i]][_renownType] += int64(_delta[i]);

      emit RenownChange(_tokenAddress[i], _tokenId[i], nowEpoch, _renownType, int64(_delta[i]));
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

  function getLastValidEpochs(
    uint count,
    bool skipCurrent
  ) external view returns (uint256[] memory result) {
    if (count > validEpochs.length) {
      count = validEpochs.length;
    }

    result = new uint256[](count);
    uint offset = 0;
    if (
      skipCurrent &&
      validEpochs.length != 0 &&
      currentEpoch() == validEpochs[validEpochs.length - 1]
    ) {
      offset = 1;
    }

    for (uint i = 0; i < count; i++) {
      result[i] = validEpochs[validEpochs.length - 1 - i - offset];
    }
  }

  //--------------------------------
  // Admin
  //--------------------------------

  function updateEpochConfig(uint64 _duration, uint64 _offset) external onlyAdmin {
    EPOCH_CONFIG = Epoch.toConfig(_duration, _offset);
    emit EpochConfigChange(_duration, _offset, EPOCH_CONFIG);
  }

  function updateMaxRenownType(uint256 _maxRenownType) external onlyAdmin {
    MAX_RENOWN_TYPE = _maxRenownType;
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