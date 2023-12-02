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

interface IProductivity {
  // All time Productivity
  function currentProductivity(uint256 _realmId) external returns (int);

  function currentProductivityBatch(
    uint[] calldata _realmIds
  ) external returns (int[] memory result);

  function previousEpochsProductivityTotals(
    uint _realmId
  ) external view returns (int total, int gains, int spending);

  function previousEpochsProductivityTotalsBatch(
    uint[] calldata _realmIds
  ) external view returns (int[] memory total, int[] memory gains, int[] memory spending);

  function change(uint256 _realmId, int _delta, bool _includeInTotals) external;

  function changeBatch(
    uint256[] calldata _tokenIds,
    int[] calldata _deltas,
    bool _includeInTotals
  ) external;

  function changeBatch(uint256[] calldata _tokenIds, int _delta, bool _includeInTotals) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./IProductivity.sol";
import "../lib/FloatingPointConstants.sol";
import "../Utils/Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../Utils/EpochConfigurable.sol";

struct ProductivityUpkeepConfig {
  int dailyProductivityGain;
  int maintenanceCap;
  int maintenanceCapTax;
  uint daysToEquilibrium;
  int equilibriumProductivity;
  uint maxEpochsStorage;
}

contract Productivity is IProductivity, EpochConfigurable, Pausable {
  error InsufficientProductivity(uint realmId, int productivity, int delta);

  event ProductivityChanged(uint realmId, int delta, bool includedInTotals);

  ProductivityUpkeepConfig public UPKEEP_CONFIG;
  address public REALM;
  uint public immutable DEPLOYMENT_TIMESTAMP;

  // realmId -> timestamp
  mapping(uint => uint) public lastUpkeepTimestampMapping;
  // realmId -> productivity
  mapping(uint => int64) public currentProductivityStorage;
  // realmId -> epoch%movingAverageDays -> productivity
  mapping(uint => int64[]) public pastEpochProductivityStorage;
  // realm -> epoch %movingAverageDays -> spent productivity
  mapping(uint => int64[]) public productivitySpendingStorage;
  // realm -> epoch %movingAverageDays -> gained productivity
  mapping(uint => int64[]) public externalProductivityGainsStorage;

  event ProductivityEpochEnded(uint realmId, uint epoch, int productivity);

  constructor(address _manager, address _realm) EpochConfigurable(_manager, 1 days, 0 hours) {
    REALM = _realm;
    UPKEEP_CONFIG.maintenanceCapTax = 20 * SIGNED_DECIMAL_POINT;
    UPKEEP_CONFIG.maintenanceCap = 600 * SIGNED_DECIMAL_POINT;
    UPKEEP_CONFIG.dailyProductivityGain = 200 * SIGNED_DECIMAL_POINT;
    UPKEEP_CONFIG.equilibriumProductivity = 1600 * SIGNED_DECIMAL_POINT;
    UPKEEP_CONFIG.daysToEquilibrium = 30;
    UPKEEP_CONFIG.maxEpochsStorage = 5;
    DEPLOYMENT_TIMESTAMP = block.timestamp;
  }

  function lastRealmUpkeepEpoch(uint realmId) public view returns (uint result) {
    result = lastUpkeepTimestampMapping[realmId];
    if (result < DEPLOYMENT_TIMESTAMP) {
      result = DEPLOYMENT_TIMESTAMP - 1 days;
    }
    result = epochAtTimestamp(result);
  }

  function currentProductivity(uint _realmId) public returns (int result) {
    result = currentProductivityStorage[_realmId];
    uint lastUpkeepEpoch = lastRealmUpkeepEpoch(_realmId);
    uint currentEpoch = currentEpoch();
    if (lastUpkeepEpoch < currentEpoch) {
      int upkeep = _calculateUpkeep(_realmId, result, currentEpoch, currentEpoch - lastUpkeepEpoch);
      currentProductivityStorage[_realmId] += int64(upkeep);
      result += upkeep;
      lastUpkeepTimestampMapping[_realmId] = block.timestamp;
    }
  }

  function previousEpochsProductivityTotals(
    uint _realmId
  ) public view returns (int total, int gains, int spending) {
    int64[] storage pastEpochsStorage = pastEpochProductivityStorage[_realmId];
    int64[] storage gainsStorage = externalProductivityGainsStorage[_realmId];
    int64[] storage spendingStorage = productivitySpendingStorage[_realmId];
    for (uint i = 0; i < UPKEEP_CONFIG.maxEpochsStorage; i++) {
      if (pastEpochsStorage.length > i) {
        total += int(pastEpochsStorage[i]);
      }
      if (gainsStorage.length > i) {
        gains += int(gainsStorage[i]);
      }
      if (spendingStorage.length > i) {
        spending += int(spendingStorage[i]);
      }
    }
  }

  function previousEpochsProductivityTotalsBatch(
    uint[] calldata _realmIds
  ) public view returns (int[] memory total, int[] memory gains, int[] memory spending) {
    total = new int[](_realmIds.length);
    gains = new int[](_realmIds.length);
    spending = new int[](_realmIds.length);

    for (uint i = 0; i < _realmIds.length; i++) {
      (total[i], gains[i], spending[i]) = previousEpochsProductivityTotals(_realmIds[i]);
    }
  }

  function currentProductivityBatch(
    uint[] calldata _realmIds
  ) public returns (int[] memory result) {
    uint currentEpoch = currentEpoch();
    result = new int[](_realmIds.length);
    int upkeep;
    for (uint i = 0; i < _realmIds.length; i++) {
      result[i] = currentProductivityStorage[_realmIds[i]];
      uint lastUpkeepEpoch = lastRealmUpkeepEpoch(_realmIds[i]);
      if (lastUpkeepEpoch < currentEpoch) {
        upkeep = _calculateUpkeep(
          _realmIds[i],
          result[i],
          currentEpoch,
          currentEpoch - lastUpkeepEpoch
        );
        currentProductivityStorage[_realmIds[i]] += int64(upkeep);
        result[i] += upkeep;
        lastUpkeepTimestampMapping[_realmIds[i]] = block.timestamp;
      }
    }
  }

  function change(
    uint256 _realmId,
    int _delta,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    int realmProductivity = currentProductivity(_realmId);
    if (_delta < 0 && realmProductivity + _delta < 0) {
      revert InsufficientProductivity(_realmId, realmProductivity, _delta);
    }
    realmProductivity += _delta;
    currentProductivityStorage[_realmId] = int64(realmProductivity);
    emit ProductivityChanged(_realmId, _delta, _includeInTotals);
    if (_includeInTotals) {
      if (_delta > 0) {
        externalProductivityGainsStorage[_realmId][
          currentEpoch() % UPKEEP_CONFIG.maxEpochsStorage
        ] += int64(_delta);
      } else if (_delta < 0) {
        productivitySpendingStorage[_realmId][
          currentEpoch() % UPKEEP_CONFIG.maxEpochsStorage
        ] += int64(_delta);
      }
    }
  }

  function changeBatch(
    uint256[] calldata _tokenIds,
    int[] calldata _deltas,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    int[] memory productivity = currentProductivityBatch(_tokenIds);
    for (uint i = 0; i < _tokenIds.length; i++) {
      if (_deltas[i] < 0 && productivity[i] + _deltas[i] < 0) {
        revert InsufficientProductivity(_tokenIds[i], productivity[i], _deltas[i]);
      }
      productivity[i] += _deltas[i];
      currentProductivityStorage[_tokenIds[i]] = int64(productivity[i]);
      emit ProductivityChanged(_tokenIds[i], _deltas[i], _includeInTotals);
      if (_includeInTotals) {
        if (_deltas[i] > 0) {
          externalProductivityGainsStorage[_tokenIds[i]][
            this.currentEpoch() % UPKEEP_CONFIG.maxEpochsStorage
          ] += int64(_deltas[i]);
        } else if (_deltas[i] < 0) {
          productivitySpendingStorage[_tokenIds[i]][
            this.currentEpoch() % UPKEEP_CONFIG.maxEpochsStorage
          ] += int64(_deltas[i]);
        }
      }
    }
  }

  function changeBatch(
    uint256[] calldata _tokenIds,
    int _delta,
    bool _includeInTotals
  ) external onlyManager whenNotPaused {
    int[] memory productivity = currentProductivityBatch(_tokenIds);
    for (uint i = 0; i < _tokenIds.length; i++) {
      if (_delta < 0 && productivity[i] + _delta < 0) {
        revert InsufficientProductivity(_tokenIds[i], productivity[i], _delta);
      }
      productivity[i] += _delta;
      currentProductivityStorage[_tokenIds[i]] = int64(productivity[i]);
      emit ProductivityChanged(_tokenIds[i], _delta, _includeInTotals);
      if (_includeInTotals) {
        if (_delta > 0) {
          externalProductivityGainsStorage[_tokenIds[i]][
            this.currentEpoch() % UPKEEP_CONFIG.maxEpochsStorage
          ] += int64(_delta);
        } else if (_delta < 0) {
          productivitySpendingStorage[_tokenIds[i]][
            this.currentEpoch() % UPKEEP_CONFIG.maxEpochsStorage
          ] += int64(_delta);
        }
      }
    }
  }

  function _calculateUpkeep(
    uint _realmId,
    int _currentProductivity,
    uint _currentEpoch,
    uint _epochsPassed
  ) internal returns (int) {
    int64[] storage epochEndProductivities = pastEpochProductivityStorage[_realmId];
    int64[] storage realmSpendingStorages = productivitySpendingStorage[_realmId];
    int64[] storage realmExternalGainsStorages = externalProductivityGainsStorage[_realmId];
    while (epochEndProductivities.length < UPKEEP_CONFIG.maxEpochsStorage) {
      epochEndProductivities.push(0);
      realmSpendingStorages.push(0);
      realmExternalGainsStorages.push(0);
    }

    if (_epochsPassed == 0) {
      return 0;
    }
    if (_epochsPassed >= UPKEEP_CONFIG.daysToEquilibrium) {
      return UPKEEP_CONFIG.equilibriumProductivity - _currentProductivity;
    }

    uint processingEpoch;
    int processingEpochProductivity = _currentProductivity;

    for (uint i = 0; i < _epochsPassed; i++) {
      epochEndProductivities[processingEpoch % UPKEEP_CONFIG.maxEpochsStorage] = int64(
        processingEpochProductivity
      );
      realmSpendingStorages[(processingEpoch + 1) % UPKEEP_CONFIG.maxEpochsStorage] = 0;
      realmExternalGainsStorages[(processingEpoch + 1) % UPKEEP_CONFIG.maxEpochsStorage] = 0;

      processingEpoch = _currentEpoch - _epochsPassed + i;
      if (processingEpochProductivity > UPKEEP_CONFIG.maintenanceCap) {
        processingEpochProductivity -=
          ((processingEpochProductivity - UPKEEP_CONFIG.maintenanceCap) *
            UPKEEP_CONFIG.maintenanceCapTax) /
          SIGNED_ONE_HUNDRED;
      }
      processingEpochProductivity += UPKEEP_CONFIG.dailyProductivityGain;

      emit ProductivityEpochEnded(_realmId, processingEpoch, processingEpochProductivity);
    }

    return processingEpochProductivity - _currentProductivity;
  }

  function updateConfig(ProductivityUpkeepConfig calldata config) external onlyAdmin {
    UPKEEP_CONFIG.dailyProductivityGain = config.dailyProductivityGain;
    UPKEEP_CONFIG.maintenanceCap = config.maintenanceCap;
    UPKEEP_CONFIG.maintenanceCapTax = config.maintenanceCapTax;
    UPKEEP_CONFIG.equilibriumProductivity = config.equilibriumProductivity;
    UPKEEP_CONFIG.daysToEquilibrium = config.daysToEquilibrium;
    UPKEEP_CONFIG.maxEpochsStorage = config.maxEpochsStorage;
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