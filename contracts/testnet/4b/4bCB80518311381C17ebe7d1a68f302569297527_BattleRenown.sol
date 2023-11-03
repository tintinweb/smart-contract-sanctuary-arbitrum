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

struct RenownDelta {
  int adventurer;
  int opponent;
}

// Contract responsible for calculating battle renown
contract BattleRenown is ManagerModifier {
  using Epoch for uint256;

  // Renown epoch -> address -> tokenId -> reward dispensed
  mapping(uint256 => mapping(address => mapping(uint256 => bool)))
    public initialEpochRenownDispensed;

  // Diminishing returns
  // Battle epoch -> address -> tokenId -> battle outcome -> number of battles
  mapping(uint256 => mapping(address => mapping(uint256 => mapping(bool => uint16))))
    public opponentDiminishingReturns;

  IRenownStorage public RENOWN_STORAGE;
  IRenownBonusCalculator public STARTING_RENOWN_CALCULATOR;

  int public K_BASELINE = SIGNED_ONE_HUNDRED;

  constructor(
    address _manager,
    address _renownStorage,
    address _startingRenownCalculator
  ) ManagerModifier(_manager) {
    RENOWN_STORAGE = IRenownStorage(_renownStorage);
    STARTING_RENOWN_CALCULATOR = IRenownBonusCalculator(_startingRenownCalculator);
  }

  function getRenown(
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    uint256 _level
  ) external view returns (int renown, uint epoch) {
    epoch = RENOWN_STORAGE.currentEpoch();
    renown = RENOWN_STORAGE.currentEpochRenown(
      _adventurerAddress,
      _adventurerTokenId,
      RENOWN_TYPE_BATTLE
    );

    if (!initialEpochRenownDispensed[epoch][_adventurerAddress][_adventurerTokenId]) {
      renown += STARTING_RENOWN_CALCULATOR.calculateBonus(
        _adventurerAddress,
        _adventurerTokenId,
        _level
      );
    }
  }

  function updateRenown(
    uint256 _battleEpoch,
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    uint256 _adventurerLevel,
    address _opponentAddress,
    uint256 _opponentTokenId,
    uint256 _opponentLevel,
    uint _probability,
    bool _adventurerWon
  ) external onlyManager returns (RenownDelta memory result) {
    uint renownEpoch;
    int adventurerRenown;
    int opponentRenown;
    int temp;

    renownEpoch = RENOWN_STORAGE.currentEpoch();
    adventurerRenown = RENOWN_STORAGE.currentEpochRenown(
      _adventurerAddress,
      _adventurerTokenId,
      RENOWN_TYPE_BATTLE
    );
    opponentRenown = RENOWN_STORAGE.currentEpochRenown(
      _adventurerAddress,
      _adventurerTokenId,
      RENOWN_TYPE_BATTLE
    );

    if (!initialEpochRenownDispensed[renownEpoch][_adventurerAddress][_adventurerTokenId]) {
      temp = STARTING_RENOWN_CALCULATOR.calculateBonus(
        _adventurerAddress,
        _adventurerTokenId,
        _adventurerLevel
      );
      RENOWN_STORAGE.change(_adventurerAddress, _adventurerTokenId, temp, RENOWN_TYPE_BATTLE);
      initialEpochRenownDispensed[renownEpoch][_adventurerAddress][_adventurerTokenId] = true;
      adventurerRenown += temp;
    }

    if (!initialEpochRenownDispensed[renownEpoch][_opponentAddress][_opponentTokenId]) {
      temp = STARTING_RENOWN_CALCULATOR.calculateBonus(
        _opponentAddress,
        _opponentTokenId,
        _opponentLevel
      );
      RENOWN_STORAGE.change(_opponentAddress, _opponentTokenId, temp, RENOWN_TYPE_BATTLE);
      initialEpochRenownDispensed[renownEpoch][_opponentAddress][_opponentTokenId] = true;
      opponentRenown += temp;
    }

    // Adjust renown for adventurer
    result.adventurer = _update(
      _adventurerAddress,
      _adventurerTokenId,
      _probability,
      adventurerRenown,
      _adventurerLevel,
      opponentRenown,
      SIGNED_ONE_HUNDRED,
      _adventurerWon
    );

    temp = _opponentMultiplier(_battleEpoch, _opponentAddress, _opponentTokenId, !_adventurerWon);

    // Adjust renown for the opponent
    result.opponent = _update(
      _opponentAddress,
      _opponentTokenId,
      ONE_HUNDRED - _probability,
      opponentRenown,
      _opponentLevel,
      adventurerRenown,
      temp,
      !_adventurerWon
    );
  }

  function _opponentMultiplier(
    uint256 _battleEpoch,
    address _opponentAddress,
    uint256 _opponentTokenId,
    bool _battleResult
  ) internal returns (int multiplier) {
    uint16 opponentBattles = opponentDiminishingReturns[_battleEpoch][_opponentAddress][
      _opponentTokenId
    ][_battleResult]++;

    multiplier = 50000;
    for (uint16 i = 0; i < opponentBattles; i++) {
      multiplier = (multiplier * 90000) / SIGNED_ONE_HUNDRED;
    }
  }

  function _update(
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    uint _probability,
    int _adventurerRenown,
    uint _adventurerLevel,
    int _opponentRenown,
    int _multiplier,
    bool adventurerWon
  ) internal returns (int delta) {
    // ELO calculations
    int calcBase = K_BASELINE * int(_adventurerLevel);

    _adventurerRenown += 1;
    _opponentRenown += 1;

    // incentivize fighting higher BP opponents by increasing rewards for lower probability fights
    if (adventurerWon && _probability < 50000) {
      calcBase = (calcBase * 150000 - int(_probability)) / SIGNED_ONE_HUNDRED;
    }

    // disincentivize fighting lower BP opponents by increasing renown loss for fighting easier opponents
    if (!adventurerWon && _probability > 50000) {
      calcBase = (calcBase * 50000 + int(_probability)) / SIGNED_ONE_HUNDRED;
    }

    // Adjust ELO based on probabilities
    delta = (adventurerWon ? SIGNED_ONE_HUNDRED : SIGNED_ZERO);
    delta =
      (calcBase * (delta - calculateRenownWinProbability(_adventurerRenown, _opponentRenown))) /
      SIGNED_ONE_HUNDRED;

    delta = (delta * _multiplier) / SIGNED_ONE_HUNDRED;

    if (delta != 0) {
      RENOWN_STORAGE.change(_adventurerAddress, _adventurerTokenId, delta, RENOWN_TYPE_BATTLE);
    }
  }

  function updateKBaseline(int _baseline) external onlyAdmin {
    K_BASELINE = _baseline;
  }

  function calculateRenownWinProbability(
    int _attackerRenown,
    int _defenderRenown
  ) internal pure returns (int) {
    return (SIGNED_ONE_HUNDRED * (_attackerRenown)) / (_attackerRenown + _defenderRenown);
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