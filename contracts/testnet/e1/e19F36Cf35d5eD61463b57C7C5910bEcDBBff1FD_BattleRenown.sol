// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct BattlePowerScan {
  int256 attackerBase;
  int256 attackerFinal;
  uint256 attackerLevel;
  int256 opponentBase;
  int256 opponentFinal;
  uint256 opponentLevel;
}

enum DataType {
  BASE,
  AOV,
  EXTENSION,
  ACTIONS
}

struct LevelAdjustment {
  uint32 levelThreshold;
  uint32 adjustmentCoefficient;
  uint32 reverseAdjustmentCoefficient;
}

struct PeripheralRestriction {
  DataType requirementType;
  uint32 requirementId;
  uint32 value;
}

struct PeripheralAdditiveBonus {
  DataType bonusType;
  uint32 bonusId;
  uint32 value;
  PeripheralRestriction[] restrictions;
}

struct PeripheralMultiplicativeBonus {
  DataType baseStatType;
  uint32 baseStatId;
  DataType bonusType;
  uint32 bonusId;
  uint32 value;
  PeripheralRestriction[] restrictions;
}

struct BattleUtility {
  bool enabled;
  LevelAdjustment adjustment;
  PeripheralAdditiveBonus[] additiveBonuses;
  PeripheralMultiplicativeBonus[] multiplicativeBonuses;
}

interface IBattlePowerScouter {
  function baseBattlePower(
    address _adventurerAddr,
    uint256 _adventurerId
  ) external view returns (int256 battlePower, uint256 level);

  function scanBattlePower(
    uint _fightEpoch,
    address _adventurerAddr,
    uint256 _adventurerId,
    address _opponentAddr,
    uint256 _opponentId
  ) external returns (BattlePowerScan memory);

  function invalidateCache(address _adventurerAddr, uint256 _adventurerId) external;

  function invalidateCaches(
    address[] calldata _adventurerAddr,
    uint256[] calldata _adventurerId
  ) external;
}

import "./IBattlePowerScouter.sol";

struct FightData {
  BattlePowerScan scan;
  uint256 attackerRenown;
  uint256 defenderRenown;
}

struct FightRequest {
  address[] advAddresses;
  uint256[] advTokenIds;
  uint256[][] addEquipmentToArmoryIds;
  uint256[][] addEquipmentToArmoryAmounts;
  uint256[][] equipmentIds;
  bytes32[][] advProofs;
  address[] oppAddresses;
  uint256[] oppTokenIds;
  bytes32[][] oppProofs;
  uint256[] slots;
}

struct FightResult {
  uint adventurerLevel;
  int adventurerBp;
  uint opponentLevel;
  int opponentBp;
  uint rounds;
  uint wins;
  uint losses;
  bool overallWin;
  uint[] rolls;
  uint probability;
  uint nextRandomBase;
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

import "../Manager/ManagerModifier.sol";
import "./IRenown.sol";
import "../lib/FloatingPointConstants.sol";
import "./IActivityRenown.sol";
import "../Utils/Epoch.sol";
import "./IAdventurerRenownBonusCalculator.sol";
import "../Battle/IBattleVersusV3.sol";
import "../Utils/EpochConfigurable.sol";

int constant TWO = 2;

struct RenownDelta {
  int adventurer;
  int opponent;
}

struct DiminishingReturns {
  uint8 counter;
  uint8 epochHash;
}

// Contract responsible for calculating battle renown
contract BattleRenown is EpochConfigurable {
  using Epoch for uint256;

  event InitialEpochRenownAdded(
    address adventurerAddress,
    uint adventurerId,
    uint epoch,
    int value
  );

  error RenownDifferenceExceeded(
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    int256 _adventurerRenown,
    int256 _opponentRenown
  );

  // Renown epoch -> address -> tokenId -> reward dispensed
  mapping(uint256 => mapping(address => mapping(uint256 => bool)))
    public initialEpochRenownDispensed;

  // Diminishing returns
  // Battle epoch -> address -> tokenId -> battle outcome -> number of battles
  mapping(address => mapping(uint256 => mapping(bool => DiminishingReturns)))
    public opponentDiminishingReturns;

  IRenown public RENOWN;
  IAdventurerRenownBonusCalculator public STARTING_RENOWN_CALCULATOR;

  int public K_BASELINE = 60000;

  constructor(
    address _manager,
    address _renownStorage,
    address _startingRenownCalculator
  ) EpochConfigurable(_manager, 1 days, 0 hours) {
    RENOWN = IRenown(_renownStorage);
    STARTING_RENOWN_CALCULATOR = IAdventurerRenownBonusCalculator(_startingRenownCalculator);
  }

  function getRenown(
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    uint256 _level
  ) external view returns (int renown, uint epoch) {
    epoch = currentEpoch();
    renown = RENOWN.currentRenown(_adventurerAddress, _adventurerTokenId);

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
    address _opponentAddress,
    uint256 _opponentTokenId,
    FightResult calldata _fightResult
  ) external onlyManager returns (RenownDelta memory result) {
    uint renownEpoch;
    int adventurerRenown;
    int opponentRenown;
    int temp;

    adventurerRenown = RENOWN.currentRenown(_adventurerAddress, _adventurerTokenId);
    opponentRenown = RENOWN.currentRenown(_opponentAddress, _opponentTokenId);

    if (!initialEpochRenownDispensed[renownEpoch][_adventurerAddress][_adventurerTokenId]) {
      temp = STARTING_RENOWN_CALCULATOR.calculateBonus(
        _adventurerAddress,
        _adventurerTokenId,
        _fightResult.adventurerLevel
      );

      RENOWN.change(_adventurerAddress, _adventurerTokenId, _fightResult.adventurerLevel, temp);
      initialEpochRenownDispensed[renownEpoch][_adventurerAddress][_adventurerTokenId] = true;
      adventurerRenown += temp;
      emit InitialEpochRenownAdded(_adventurerAddress, _adventurerTokenId, renownEpoch, temp);
    }

    if (!initialEpochRenownDispensed[renownEpoch][_opponentAddress][_opponentTokenId]) {
      temp = STARTING_RENOWN_CALCULATOR.calculateBonus(
        _opponentAddress,
        _opponentTokenId,
        _fightResult.opponentLevel
      );
      RENOWN.change(_opponentAddress, _opponentTokenId, _fightResult.opponentLevel, temp);
      initialEpochRenownDispensed[renownEpoch][_opponentAddress][_opponentTokenId] = true;
      opponentRenown += temp;
      emit InitialEpochRenownAdded(_opponentAddress, _opponentTokenId, renownEpoch, temp);
    }

    if (adventurerRenown < opponentRenown / TWO || adventurerRenown > TWO * opponentRenown) {
      revert RenownDifferenceExceeded(
        _adventurerAddress,
        _adventurerTokenId,
        adventurerRenown,
        opponentRenown
      );
    }

    return
      _updateRenown(
        _battleEpoch,
        _adventurerAddress,
        _adventurerTokenId,
        adventurerRenown,
        _opponentAddress,
        _opponentTokenId,
        opponentRenown,
        _fightResult
      );
  }

  function _updateRenown(
    uint256 _battleEpoch,
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    int256 _adventurerRenown,
    address _opponentAddress,
    uint256 _opponentTokenId,
    int256 _opponentRenown,
    FightResult calldata fightResult
  ) internal returns (RenownDelta memory renownDelta) {
    int temp;
    bool adventurerWon;
    for (uint i = 0; i < fightResult.rounds; i++) {
      adventurerWon = fightResult.rolls[i] <= fightResult.probability;

      temp = _calculateRenownChange(
        _adventurerAddress,
        _adventurerTokenId,
        fightResult.probability,
        _adventurerRenown,
        fightResult.adventurerLevel,
        _opponentRenown,
        SIGNED_ONE_HUNDRED,
        adventurerWon,
        fightResult.rounds
      );

      // Adjust renown for adventurer
      renownDelta.adventurer += temp;

      temp = _opponentMultiplier(_battleEpoch, _opponentAddress, _opponentTokenId, !adventurerWon);

      // Adjust renown for the opponent
      temp = _calculateRenownChange(
        _opponentAddress,
        _opponentTokenId,
        ONE_HUNDRED - fightResult.probability,
        _opponentRenown,
        fightResult.opponentLevel,
        _adventurerRenown,
        temp,
        !adventurerWon,
        fightResult.rounds
      );
      renownDelta.opponent += temp;
    }

    // Never lose more than half your renown in a single fight
    if (renownDelta.adventurer < -_adventurerRenown / 2) {
      renownDelta.adventurer = -_adventurerRenown / 2;
    }

    if (renownDelta.adventurer != 0) {
      RENOWN.change(
        _adventurerAddress,
        _adventurerTokenId,
        fightResult.adventurerLevel,
        renownDelta.adventurer
      );
    }

    // Never lose more than half your renown in a single fight
    if (renownDelta.opponent < -_opponentRenown / 2) {
      renownDelta.opponent = -_opponentRenown / 2;
    }

    if (renownDelta.opponent != 0) {
      RENOWN.change(
        _opponentAddress,
        _opponentTokenId,
        fightResult.opponentLevel,
        renownDelta.opponent
      );
    }

    return renownDelta;
  }

  function _opponentMultiplier(
    uint256 _battleEpoch,
    address _opponentAddress,
    uint256 _opponentTokenId,
    bool _battleResult
  ) internal returns (int multiplier) {
    DiminishingReturns storage opponentBattles = opponentDiminishingReturns[_opponentAddress][
      _opponentTokenId
    ][_battleResult];

    if (uint256(opponentBattles.epochHash) != (_battleEpoch % type(uint8).max)) {
      opponentBattles.epochHash = uint8(_battleEpoch % type(uint8).max);
      opponentBattles.counter = 0;
    }

    multiplier = 50000;
    for (uint16 i = 0; i < opponentBattles.counter; i++) {
      multiplier = (multiplier * 90000) / SIGNED_ONE_HUNDRED;
    }

    if (opponentBattles.counter < 20) {
      opponentBattles.counter++;
    }
  }

  function _calculateRenownChange(
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    uint _probability,
    int _adventurerRenown,
    uint _adventurerLevel,
    int _opponentRenown,
    int _multiplier,
    bool adventurerWon,
    uint rounds
  ) internal returns (int delta) {
    // ELO calculations
    int calcBase = (K_BASELINE * int(_adventurerLevel)) / int(rounds);

    _adventurerRenown += 1;
    _opponentRenown += 1;

    // disincentivize fighting lower BP opponents by increasing renown loss for fighting harder opponents
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
  }

  function updateKBaseline(int _baseline) external onlyAdmin {
    K_BASELINE = _baseline;
  }

  function calculateRenownWinProbability(
    int _attackerRenown,
    int _defenderRenown
  ) internal pure returns (int result) {
    result += (SIGNED_ONE_HUNDRED * (_attackerRenown)) / (_attackerRenown + _defenderRenown);
    _attackerRenown = (_attackerRenown * _attackerRenown) / SIGNED_DECIMAL_POINT;
    _defenderRenown = (_defenderRenown * _defenderRenown) / SIGNED_DECIMAL_POINT;
    result += 5000 + (int(90000) * (_attackerRenown)) / (_attackerRenown + _defenderRenown);
    result /= 2;
    return result;
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

interface IAdventurerRenownBonusCalculator {
  function calculateBonus(
    address adventurerAddress,
    uint256 adventurerTokenId,
    uint256 level
  ) external view returns (int);

  function calculateBonusBatch(
    address[] calldata adventurerAddress,
    uint256[] calldata adventurerTokenId,
    uint256[] calldata level
  ) external view returns (int[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRenown {
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