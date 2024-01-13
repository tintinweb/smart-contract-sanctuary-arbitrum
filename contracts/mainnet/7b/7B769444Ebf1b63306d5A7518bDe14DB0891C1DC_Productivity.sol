// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
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
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IProductivity {
  // All time Productivity
  function currentProductivity(uint256 _realmId) external view returns (uint);

  function currentProductivityBatch(
    uint[] calldata _realmIds
  ) external view returns (uint[] memory result);

  function previousEpochsProductivityTotals(
    uint _realmId,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) external view returns (uint gains, uint losses);

  function epochsProductivityTotals(
    uint _realmId,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint gains, uint losses);

  function previousEpochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) external view returns (uint[] memory gains, uint[] memory spending);

  function epochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint[] memory gains, uint[] memory spending);

  function change(uint256 _realmId, int _delta, bool _includeInTotals) external;

  function changeBatch(
    uint256[] calldata _tokenIds,
    int[] calldata _deltas,
    bool _includeInTotals
  ) external;

  function changeBatch(uint256[] calldata _tokenIds, int _delta, bool _includeInTotals) external;

  function increase(uint256 _realmId, uint _delta, bool _includeInTotals) external;

  function increaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _delta,
    bool _includeInTotals
  ) external;

  function increaseBatch(uint256[] calldata _tokenIds, uint _delta, bool _includeInTotals) external;

  function decrease(uint256 _realmId, uint _delta, bool _includeInTotals) external;

  function decreaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _delta,
    bool _includeInTotals
  ) external;

  function decreaseBatch(uint256[] calldata _tokenIds, uint _delta, bool _includeInTotals) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./IProductivity.sol";
import "../lib/FloatingPointConstants.sol";
import "../Utils/Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../Utils/EpochConfigurable.sol";

struct CurrentProductivity {
  uint128 lastEpoch;
}

struct ProductivityDeltas {
  uint32 gains;
  uint32 losses;
}

uint constant STORAGE_PACK_LENGTH = 4;

contract Productivity is IProductivity, EpochConfigurable {
  error InsufficientProductivity(uint realmId, uint productivity, int delta);

  event ProductivityChanged(uint realmId, int delta, uint total, bool includedInTotals);

  address public immutable REALM;

  // realmId -> productivity
  mapping(uint => uint) public currentProductivityStorage;
  // realm -> epoch/4 -> productivity gained/lost per epoch%4
  mapping(uint => mapping(uint => ProductivityDeltas[STORAGE_PACK_LENGTH]))
    public epochProductivityChanges;

  event ProductivityEpochEnded(uint realmId, uint epoch, int productivity);

  constructor(address _manager, address _realm) EpochConfigurable(_manager, 1 days, 0 hours) {
    REALM = _realm;
  }

  function currentProductivity(uint _realmId) public view returns (uint) {
    return uint(currentProductivityStorage[_realmId]);
  }

  function previousEpochsProductivityTotals(
    uint _realmId,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) public view returns (uint gains, uint losses) {
    uint epoch = currentEpoch();
    require(epoch < _numberOfEpochs);

    uint i = _includeCurrentEpoch ? 0 : 1;
    uint storageRef = (epoch - i) / STORAGE_PACK_LENGTH;
    ProductivityDeltas[STORAGE_PACK_LENGTH] storage delta = epochProductivityChanges[_realmId][
      storageRef
    ];
    for (; i < _numberOfEpochs; i++) {
      uint processedEpoch = epoch - i;
      uint storageOffset = processedEpoch % STORAGE_PACK_LENGTH;

      // Check if storage reference needs to be updated (every STORAGE_PACK_LENGTH steps)
      if (processedEpoch != storageRef) {
        storageRef = processedEpoch / STORAGE_PACK_LENGTH;
        delta = epochProductivityChanges[_realmId][storageRef];
      }
      // Aggregate gains and losses

      gains += uint(delta[storageOffset].gains);
      losses += uint(delta[storageOffset].losses);
    }
  }

  function previousEpochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _numberOfEpochs,
    bool _includeCurrentEpoch
  ) public view returns (uint[] memory gains, uint[] memory spending) {
    gains = new uint[](_realmIds.length);
    spending = new uint[](_realmIds.length);

    for (uint i = 0; i < _realmIds.length; i++) {
      (gains[i], spending[i]) = previousEpochsProductivityTotals(
        _realmIds[i],
        _numberOfEpochs,
        _includeCurrentEpoch
      );
    }
  }

  function epochsProductivityTotals(
    uint _realmId,
    uint _startEpoch,
    uint _endEpoch
  ) public view returns (uint gains, uint losses) {
    uint epoch = currentEpoch();

    uint storageRef = _startEpoch / STORAGE_PACK_LENGTH;
    ProductivityDeltas[STORAGE_PACK_LENGTH] storage delta = epochProductivityChanges[_realmId][
      storageRef
    ];
    for (uint processedEpoch = _startEpoch; processedEpoch < _endEpoch; processedEpoch++) {
      // Skip epochs if they didn't occur yet
      if (processedEpoch > epoch) {
        continue;
      }

      uint storageOffset = processedEpoch % STORAGE_PACK_LENGTH;

      // Check if storage reference needs to be updated (every STORAGE_PACK_LENGTH steps)
      if (processedEpoch != storageRef) {
        storageRef = processedEpoch / STORAGE_PACK_LENGTH;
        delta = epochProductivityChanges[_realmId][storageRef];
      }
      // Aggregate gains and losses

      gains += uint(delta[storageOffset].gains);
      losses += uint(delta[storageOffset].losses);
    }
  }

  function epochsProductivityTotalsBatch(
    uint[] calldata _realmIds,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint[] memory gains, uint[] memory spending) {
    gains = new uint[](_realmIds.length);
    spending = new uint[](_realmIds.length);

    for (uint i = 0; i < _realmIds.length; i++) {
      (gains[i], spending[i]) = epochsProductivityTotals(_realmIds[i], _startEpoch, _endEpoch);
    }
  }

  function currentProductivityBatch(
    uint[] calldata _realmIds
  ) public view returns (uint[] memory result) {
    result = new uint[](_realmIds.length);
    for (uint i = 0; i < _realmIds.length; i++) {
      result[i] = currentProductivityStorage[_realmIds[i]];
    }
  }

  function change(
    uint256 _realmId,
    int _delta,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    _changeInternal(currentEpoch(), _realmId, _delta, _includeInTotals);
  }

  function changeBatch(
    uint256[] calldata _tokenIds,
    int[] calldata _deltas,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    uint epoch = currentEpoch();
    for (uint i = 0; i < _tokenIds.length; i++) {
      _changeInternal(epoch, _tokenIds[i], _deltas[i], _includeInTotals);
    }
  }

  function changeBatch(
    uint256[] calldata _tokenIds,
    int _delta,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    uint epoch = currentEpoch();
    for (uint i = 0; i < _tokenIds.length; i++) {
      _changeInternal(epoch, _tokenIds[i], _delta, _includeInTotals);
    }
  }

  function increase(
    uint256 _realmId,
    uint _delta,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    _changeInternal(currentEpoch(), _realmId, int(_delta), _includeInTotals);
  }

  function increaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _deltas,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    uint epoch = currentEpoch();
    for (uint i = 0; i < _tokenIds.length; i++) {
      _changeInternal(epoch, _tokenIds[i], int(_deltas[i]), _includeInTotals);
    }
  }

  function increaseBatch(
    uint256[] calldata _tokenIds,
    uint _delta,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    uint epoch = currentEpoch();
    for (uint i = 0; i < _tokenIds.length; i++) {
      _changeInternal(epoch, _tokenIds[i], int(_delta), _includeInTotals);
    }
  }

  function decrease(
    uint256 _realmId,
    uint _delta,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    _changeInternal(currentEpoch(), _realmId, -int(_delta), _includeInTotals);
  }

  function decreaseBatch(
    uint256[] calldata _tokenIds,
    uint[] calldata _deltas,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    uint epoch = currentEpoch();
    for (uint i = 0; i < _tokenIds.length; i++) {
      _changeInternal(epoch, _tokenIds[i], -int(_deltas[i]), _includeInTotals);
    }
  }

  function decreaseBatch(
    uint256[] calldata _tokenIds,
    uint _delta,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    uint epoch = currentEpoch();
    for (uint i = 0; i < _tokenIds.length; i++) {
      _changeInternal(epoch, _tokenIds[i], -int(_delta), _includeInTotals);
    }
  }

  function _changeInternal(
    uint _epoch,
    uint256 _realmId,
    int _delta,
    bool _includeInTotals
  ) internal {
    if (_delta == 0) {
      return;
    }

    uint realmProductivity = uint(currentProductivityStorage[_realmId]);
    if (_delta < 0 && (int(realmProductivity) + _delta < 0)) {
      revert InsufficientProductivity(_realmId, realmProductivity, _delta);
    }
    realmProductivity = uint(int(realmProductivity) + _delta);
    currentProductivityStorage[_realmId] = realmProductivity;
    emit ProductivityChanged(_realmId, _delta, realmProductivity, _includeInTotals);
    if (_includeInTotals) {
      if (_delta > 0) {
        epochProductivityChanges[_realmId][_epoch / STORAGE_PACK_LENGTH][
          _epoch % STORAGE_PACK_LENGTH
        ].gains += uint32(uint(_delta));
      } else if (_delta < 0) {
        epochProductivityChanges[_realmId][_epoch / STORAGE_PACK_LENGTH][
          _epoch % STORAGE_PACK_LENGTH
        ].losses += uint32(uint(-_delta));
      }
    }
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

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "./IEpochConfigurable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract EpochConfigurable is Pausable, ManagerModifier, IEpochConfigurable {
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

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
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