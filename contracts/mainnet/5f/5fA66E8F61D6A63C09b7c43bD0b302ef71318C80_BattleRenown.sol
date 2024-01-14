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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../lib/SigmoidFunction.sol";

struct BattlePowerScan {
  uint256 probability;
  int256 attackerBase;
  int256 attackerFinal;
  uint256 attackerLevel;
  int256 opponentBase;
  int256 opponentFinal;
  uint256 opponentLevel;
}

enum DataType {
  BASE,
  ADVANCED,
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
  StatAffinity affinity;
}

struct PeripheralMultiplicativeBonus {
  DataType baseStatType;
  uint32 baseStatId;
  DataType bonusType;
  uint32 bonusId;
  uint32 value;
  PeripheralRestriction[] restrictions;
}

struct StatAffinity {
  bool enabled;
  uint16[6] baseStats;
  int24[6] coefficient;
  RangeConfig sigmoidRange;
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
  ) external returns (int256 battlePower, uint256 level);

  function scanBattlePower(
    uint _fightEpoch,
    address _adventurerAddr,
    uint256 _adventurerId,
    address _opponentAddr,
    uint256 _opponentId,
    uint256[] calldata _params
  ) external returns (BattlePowerScan memory);

  function invalidateCache(address _adventurerAddr, uint256 _adventurerId) external;

  function invalidateCaches(
    address[] calldata _adventurerAddr,
    uint256[] calldata _adventurerId
  ) external;
}

import "./IBattlePowerScouter.sol";

struct FightData {
  address advAddress;
  uint256 advTokenId;
  address oppAddress;
  uint256 oppTokenId;
  uint256[] params;
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
  uint256[][] params;
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
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./FloatingPointConstants.sol";

struct RangeConfig {
  int24 leftCurveX;
  int24 mid;
  int24 rightCurveX;
}

struct SigmoidConfig {
  int24 shiftY;
  CurveConfig leftCurve;
  CurveConfig rightCurve;
}

struct CurveConfig {
  bool ascending;
  int24 rangeY;
  int24 yAdjustment;
  int24 steepness;
  int24 steepnessCoefficient;
}

library SigmoidFunction {
  function calculate(
    SigmoidConfig memory config,
    RangeConfig memory range,
    int x
  ) internal pure returns (int) {
    if (x >= range.mid) {
      return
        _calculateCurve(config.rightCurve, int(range.rightCurveX), x - int(range.mid), -1) +
        config.shiftY;
    } else {
      return
        _calculateCurve(config.leftCurve, (range.leftCurveX), int(range.mid) - x, 1) +
        config.shiftY;
    }
  }

  function _calculateCurve(
    CurveConfig memory config,
    int rangeX,
    int x,
    int sign
  ) internal pure returns (int) {
    if (!config.ascending) {
      sign *= -1;
    }
    return
      config.yAdjustment +
      ((SIGNED_ONE_HUNDRED +
        ((sign *
          ((rangeX * SIGNED_ONE_HUNDRED_SQUARE) /
            (rangeX * SIGNED_ONE_HUNDRED + x * int(config.steepness)) -
            SIGNED_ONE_HUNDRED)) * int(config.steepnessCoefficient)) /
        SIGNED_ONE_HUNDRED) * int(config.rangeY)) /
      SIGNED_ONE_HUNDRED;
  }
}

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
import "../Utils/Epoch.sol";
import "../Battle/IBattleVersusV3.sol";
import "../Utils/EpochConfigurable.sol";
import "./IBattleRenown.sol";

int constant TWO = 2;

struct DiminishingReturns {
  uint16 winCounter;
  uint16 lossCounter;
  uint16 epochHash;
}

// Contract responsible for calculating battle renown
contract BattleRenown is IBattleRenown, ManagerModifier {
  error RenownDifferenceExceeded(
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    int256 _adventurerRenown,
    int256 _opponentRenown
  );

  // Diminishing returns
  // Battle epoch -> address -> tokenId -> battle outcome -> number of battles
  mapping(address => mapping(uint256 => DiminishingReturns)) public opponentDiminishingReturns;

  IRenown public immutable RENOWN;

  int public immutable K_BASELINE = 60000;

  constructor(address _manager, address _renownStorage) ManagerModifier(_manager) {
    RENOWN = IRenown(_renownStorage);
  }

  function getRenown(
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    uint256 _level
  ) external onlyManager returns (int renown) {
    renown = RENOWN.currentRenown(_adventurerAddress, _adventurerTokenId, _level);
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
    int temp;

    (int adventurerRenown, int opponentRenown) = _getBattleRenowns(
      _adventurerAddress,
      _adventurerTokenId,
      _fightResult.adventurerLevel,
      _opponentAddress,
      _opponentTokenId,
      _fightResult.opponentLevel
    );

    if (
      adventurerRenown < opponentRenown / TWO ||
      (adventurerRenown > TWO * opponentRenown &&
        int(ONE_HUNDRED * _fightResult.adventurerLevel) > TWO * opponentRenown)
    ) {
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

  function _getBattleRenowns(
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    uint256 _adventurerLevel,
    address _opponentAddress,
    uint256 _opponentTokenId,
    uint256 _opponentLevel
  ) internal returns (int adventurerRenown, int opponentRenown) {
    (adventurerRenown, opponentRenown) = RENOWN.currentRenowns(
      _adventurerAddress,
      _adventurerTokenId,
      _adventurerLevel,
      _opponentAddress,
      _opponentTokenId,
      _opponentLevel
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
      uint opponentRenownBaseLevel = fightResult.opponentLevel <= fightResult.adventurerLevel
        ? fightResult.opponentLevel
        : fightResult.adventurerLevel;
      temp = _calculateRenownChange(
        _opponentAddress,
        _opponentTokenId,
        ONE_HUNDRED - fightResult.probability,
        _opponentRenown,
        opponentRenownBaseLevel,
        _adventurerRenown,
        temp,
        !adventurerWon,
        fightResult.rounds
      );
      renownDelta.opponent += temp;
    }

    // Never fall below 0
    temp = renownDelta.adventurer + _adventurerRenown;
    if (renownDelta.adventurer < 0 && temp < 0) {
      // initialize with a miniature amount of renown
      renownDelta.adventurer = -int(_adventurerRenown) + 100;
    }

    if (renownDelta.adventurer != 0) {
      RENOWN.change(
        _adventurerAddress,
        _adventurerTokenId,
        fightResult.adventurerLevel,
        renownDelta.adventurer
      );
    }

    // Never fall below 0
    temp = renownDelta.opponent + _opponentRenown;
    if (renownDelta.opponent < 0 && temp < 0) {
      // initialize with a miniature amount of renown
      renownDelta.opponent = -int(_opponentRenown) + 100;
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
    ];

    if (uint256(opponentBattles.epochHash) != (_battleEpoch % type(uint16).max)) {
      opponentBattles.epochHash = uint8(_battleEpoch % type(uint16).max);
      opponentBattles.winCounter = 0;
      opponentBattles.lossCounter = 0;
    }

    uint counter = _battleResult ? opponentBattles.winCounter++ : opponentBattles.lossCounter++;
    if (counter > 20) {
      counter = 20;
    }

    multiplier = 50000;
    for (uint16 i = 0; i < counter; i++) {
      multiplier = (multiplier * 90000) / SIGNED_ONE_HUNDRED;
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

    // Adjust ELO based on probabilities
    delta = (adventurerWon ? SIGNED_ONE_HUNDRED : SIGNED_ZERO);
    delta =
      (calcBase * (delta - calculateRenownWinProbability(_adventurerRenown, _opponentRenown))) /
      SIGNED_ONE_HUNDRED;
    delta = (delta * _multiplier) / SIGNED_ONE_HUNDRED;
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

import "../Manager/ManagerModifier.sol";
import "./IRenown.sol";
import "../lib/FloatingPointConstants.sol";
import "../Utils/Epoch.sol";
import "../Battle/IBattleVersusV3.sol";
import "../Utils/EpochConfigurable.sol";

struct RenownDelta {
  int adventurer;
  int opponent;
}

interface IBattleRenown {
  function getRenown(
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    uint256 _level
  ) external returns (int renown);

  function updateRenown(
    uint256 _battleEpoch,
    address _adventurerAddress,
    uint256 _adventurerTokenId,
    address _opponentAddress,
    uint256 _opponentTokenId,
    FightResult calldata _fightResult
  ) external returns (RenownDelta memory result);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRenown {
  event RenownInitialized(address adventurerAddress, uint adventurerId, uint level, int baseAmount);
  event RenownChange(address adventurerAddress, uint adventurerId, uint level, int delta);

  // All time Renown
  function currentRenown(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _level
  ) external view returns (int);

  function currentRenowns(
    address _tokenAddress1,
    uint256 _tokenId1,
    uint _level1,
    address _tokenAddress2,
    uint256 _tokenId2,
    uint _level2
  ) external view returns (int, int);

  function currentRenownBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels
  ) external view returns (int[] memory);

  function forceInitIfNeeded(
    address _tokenAddress,
    uint256 _tokenId,
    uint _level
  ) external returns (int);

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