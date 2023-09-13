// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CommonKeno.sol";
import "../../helpers/InternalRNG.sol";

// import "forge-std/Test.sol";

contract Keno is CommonSoloKeno, InternalRNG/*, Test*/ {
  uint256 public constant amountNumbers = 40;
  uint256 public constant amountUniqueDraws = 10;
  uint256 internal immutable minWagerValue;

  // amount of picks => multiplier of amount numbers correct[0-10]
  mapping(uint256 => uint256[11]) internal multipliers_;
  mapping(uint256 => uint256) internal houseEdges_;

  constructor(IRandomizerRouter _router, uint256 _minWagerValue) CommonSoloKeno(_router) {
    // Pre defined multipliers_
    // picks => []amount corect
    //  multipliers_[9][6] -> multiplier for 9 picks and 6 correct
    multipliers_[1] = [40, 240, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    multipliers_[2] = [0, 160, 500, 0, 0, 0, 0, 0, 0, 0, 0];
    multipliers_[3] = [0, 0, 220, 5000, 0, 0, 0, 0, 0, 0, 0];
    multipliers_[4] = [0, 0, 150, 900, 1e4, 0, 0, 0, 0, 0, 0];
    multipliers_[5] = [0, 0, 140, 300, 1400, 4 * 1e4, 0, 0, 0, 0, 0];
    multipliers_[6] = [0, 0, 0, 300, 800, 15 * 1e3, 7 * 1e4, 0, 0, 0, 0];
    multipliers_[7] = [0, 0, 0, 200, 600, 2500, 4 * 1e4, 8 * 1e4, 0, 0, 0];
    multipliers_[8] = [0, 0, 0, 200, 300, 1000, 6500, 4 * 1e4, 9 * 1e4, 0, 0];
    multipliers_[9] = [0, 0, 0, 200, 230, 400, 900, 1e4, 5 * 1e4, 1e5, 0];
    multipliers_[10] = [
      0 /** 10 picks, 0 correct */,
      0,
      0,
      130,
      200,
      400,
      700,
      2500,
      1e4,
      5 * 1e4,
      1e5 /** 10 picks, 10 correct */
    ];

    // Pre defined houseEdges_
    houseEdges_[0] = 0;
    houseEdges_[1] = 100;
    houseEdges_[2] = 96;
    houseEdges_[3] = 92;
    houseEdges_[4] = 95;
    houseEdges_[5] = 86;
    houseEdges_[6] = 96;
    houseEdges_[7] = 86;
    houseEdges_[8] = 100;
    houseEdges_[9] = 77;
    houseEdges_[10] = 97;

    minWagerValue = _minWagerValue;
  }

  function checkWagerValue(uint256 _wager, address _token) internal {
    uint256 dollarValue_ = _computeDollarValue(_token, _wager);
    require(dollarValue_ >= minWagerValue, "Keno: wager is too small");

    // console.log(dollarValue_ / 1e28);
    // console.log(vaultManager.getMaxWager() / 1e28);

    require(dollarValue_ <= vaultManager.getMaxWager(), "Keno: wager is too big");
  }

  /*==================================================== Functions ===========================================================*/

  function updateMultipliers_(
    uint256 _picks,
    uint256[10] memory _multipliers,
    uint64 _houseEdge
  ) external onlyGovernance {
    require(_multipliers.length == 10, "Keno: insufficient _multipliers_ length");
    multipliers_[_picks] = _multipliers;
    houseEdges_[_picks] = _houseEdge;
  }

  function getHouseEdge(Game memory _game) public view override returns (uint64 edge_) {
    edge_ = uint64(houseEdges_[_game.gameData.length]);
  }

  function getMultipliersOfPick(
    uint256 _picks
  ) public view returns (uint256[11] memory multiplierArray_) {
    multiplierArray_ = multipliers_[_picks];
  }

  function getMultiplier(
    uint256 _picks,
    uint256 _correct
  ) public view returns (uint256 multiplierOfGame_) {
    multiplierOfGame_ = multipliers_[_picks][_correct];
  }

  function calcReward(
    uint256 _picks,
    uint256 _correct,
    uint256 _wager
  ) internal view returns (uint256 reward_) {
    uint256 multiplier = multipliers_[_picks][_correct];
    unchecked {
      reward_ = (_wager * multiplier) / 1e2;
    }
  }

  function houseEdges(uint32 _picks) external view returns (uint64 houseEdge_) {
    houseEdge_ = uint64(houseEdges_[_picks]);
  }

  /**
   * @notice function that takes the vrf randomness and returns the keno result numbers
   * @dev in keno no drawn number can be repeated, therefor we use Fisher - Yates shuffle of a 40 numbers array
   * @param _randoms the random value of the vrf
   */
  function getResultNumbers(
    uint256 _randoms
  ) internal pure override returns (uint256[] memory resultNumbers_) {
    uint256[] memory allNumbersArray_ = new uint256[](amountNumbers);
    resultNumbers_ = new uint256[](10);

    unchecked {
      // Initialize an array with values from 1 to 40
      for (uint256 i = 0; i < amountNumbers; ++i) {
        allNumbersArray_[i] = i + 1;
      }

      // Perform a Fisher-Yates shuffle to randomize the array
      for (uint256 y = 39; y >= 1; --y) {
        uint256 value_ = uint256(keccak256(abi.encodePacked(_randoms, y))) % (y + 1);
        (allNumbersArray_[y], allNumbersArray_[value_]) = (
          allNumbersArray_[value_],
          allNumbersArray_[y]
        );
      }

      // Select the first 10 numbers from the shuffled array
      for (uint256 x = 0; x < amountUniqueDraws; ++x) {
        resultNumbers_[x] = allNumbersArray_[x];
      }
    }

    return resultNumbers_;
  }

  /**
   *
   * @param _randomNumbers array with random numbers
   * @param _playerChoices array with player number choices
   * @param _wager wager amount of the player
   */
  function _checkHowMuchCorrect(
    uint256[] memory _randomNumbers,
    uint32[] memory _playerChoices,
    uint256 _wager
  ) internal view returns (uint256 reward_) {
    require(_randomNumbers.length == amountUniqueDraws, "Keno: _random  must be of length 10");
    require(_playerChoices.length <= amountUniqueDraws, "Keno: _random invalid length");

    bool[amountNumbers] memory exists_;
    unchecked {
      // Create a boolean array that can handle up to 100 values
      for (uint i = 0; i < _randomNumbers.length; i++) {
        // Subtract one because array indices are 0-based
        exists_[_randomNumbers[i] - 1] = true;
      }
    }

    uint256 amountCorrect_;

    unchecked {
      // Check overlaps / correct numbers ->  amountCorrect_
      amountCorrect_ = 0;
      for (uint x = 0; x < _playerChoices.length; x++) {
        if (exists_[_playerChoices[x] - 1]) {
          amountCorrect_++;
        }
      }
    }

    reward_ = calcReward(_playerChoices.length, amountCorrect_, _wager);
  }

  /**
   * @param _game game data struct
   * @param _randoms array with random values
   * @param _stopGain stopgain amount
   * @param _stopLoss stoploss amount
   * @return payout_ total payout amount of all rounds combined
   * @return playedGameCount_ count of played games_
   * @return payouts_ array with payouts per round
   */
  function play(
    uint256 _requestId,
    Game memory _game,
    uint256[] memory _randoms,
    uint128 _stopGain,
    uint128 _stopLoss
  )
    internal
    override
    returns (uint256 payout_, uint256 playedGameCount_, uint256[] memory payouts_)
  {
    payouts_ = new uint[](_game.count);
    playedGameCount_ = uint256(_game.count);
    uint32[] memory choices_ = new uint32[](_game.gameData.length);
    choices_ = _game.gameData;

    for (uint256 i = 0; i < playedGameCount_; ++i) {
      // convert the random value to the result numbers (10 picks, between 1-40, no repeats)
      uint256[] memory resultNumbers_ = getResultNumbers(_randoms[i]);
      // check how much correct numbers the player has
      uint256 reward_ = _checkHowMuchCorrect(resultNumbers_, choices_, _game.wager);
      payouts_[i] = reward_;
      unchecked {
        payout_ += reward_;
      }
      if (i == 0) {
        gameDraws_[_requestId].firstDraw = [
          uint32(resultNumbers_[0]),
          uint32(resultNumbers_[2]),
          uint32(resultNumbers_[1]),
          uint32(resultNumbers_[3]),
          uint32(resultNumbers_[4]),
          uint32(resultNumbers_[5]),
          uint32(resultNumbers_[6]),
          uint32(resultNumbers_[7]),
          uint32(resultNumbers_[8]),
          uint32(resultNumbers_[9])
        ];
      } else if (i == 1) {
        gameDraws_[_requestId].secondDraw = [
          uint32(resultNumbers_[0]),
          uint32(resultNumbers_[1]),
          uint32(resultNumbers_[2]),
          uint32(resultNumbers_[3]),
          uint32(resultNumbers_[4]),
          uint32(resultNumbers_[5]),
          uint32(resultNumbers_[6]),
          uint32(resultNumbers_[7]),
          uint32(resultNumbers_[8]),
          uint32(resultNumbers_[9])
        ];
      } else if (i == 2) {
        gameDraws_[_requestId].thirdDraw = [
          uint32(resultNumbers_[0]),
          uint32(resultNumbers_[1]),
          uint32(resultNumbers_[2]),
          uint32(resultNumbers_[3]),
          uint32(resultNumbers_[4]),
          uint32(resultNumbers_[5]),
          uint32(resultNumbers_[6]),
          uint32(resultNumbers_[7]),
          uint32(resultNumbers_[8]),
          uint32(resultNumbers_[9])
        ];
      } else {
        revert("Keno: Can't play more than 3 games_");
      }
      emit KenoResult(_game.player, i, _requestId, resultNumbers_);
      if (shouldStop(payout_, (i + 1) * _game.wager, _stopGain, _stopLoss)) {
        playedGameCount_ = i + 1;
        break;
      }
    }
  }

  /**
   * @notice function that checks if the players choice is valid
   * @dev in Keno player needs to chose between 1 and 10 numbers
   * @dev player cannot chose the same number multiple times
   * @param _gameData the chosen numbers of the player
   */
  function _processPlayerChoice(uint32[] memory _gameData) internal pure {
    uint256 length_ = _gameData.length;
    require(length_ != 0, "Keno: Can't choose less than 1 number");
    require(length_ <= 10, "Keno: Can't choose more than 10 numbers");
    bool[40] memory exists;

    unchecked {
      // can't choose more than 10 numbers
      for (uint256 i = 0; i < length_; ++i) {
        require(_gameData[i] != 0, "Keno: Choice 0 isn't allowed");
        require(_gameData[i] <= 40, "Keno: Choice larger as 40 isn't allowed");
        // Subtract one because array indices are 0-based
        if (exists[_gameData[i] - 1]) {
          // This value is a duplicate
          revert("Keno: Number not available/alreadychosen");
        }
        exists[_gameData[i] - 1] = true;
      }
    }
  }

  /**
   * @param _wager wager amount in token per game round
   * @param _count max amount of games_ rounds to play
   * @param _stopGain take profit amount in token
   * @param _stopLoss stoploss amount in token
   * @param _gameData array with number choices
   * @param _token token address of wager
   */
  function bet(
    uint128 _wager,
    uint8 _count,
    uint128 _stopGain,
    uint128 _stopLoss,
    uint32[] memory _gameData,
    address _token
  ) external {
    _bet(_wager, _count, _stopGain, _stopLoss, _gameData, _token);
  }

  function _bet(
    uint128 _wager,
    uint8 _count,
    uint128 _stopGain,
    uint128 _stopLoss,
    uint32[] memory _gameData,
    address _token
  ) internal {
    require(_count != 0, "Keno: Game count null");
    require(_count <= maxGameCount, "Keno: Game count out-range");
    checkWagerValue(_wager, _token);
    _processPlayerChoice(_gameData);
    _create(_wager, _count, _stopGain, _stopLoss, _gameData, _token);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../core/Core.sol";

abstract contract CommonSoloKeno is Core {
  /*==================================================== Events =============================================================*/

  event Created(address indexed player, uint256 indexed requestId, uint256 wager, address token);

  event KenoResult(
    address indexed player,
    uint256 roundIndex,
    uint256 requestId,
    uint256[] resultNumbers
  );

  event GameRefunded(address indexed player, uint256 indexed requestId, uint256 totalRefunded);

  /**
   * @param player address of the player
   * @param requestId vrf request id of the game
   * @param wager amount of the wager PER GAME ROUND
   * @param won bool if the player won the game (net positive result if multiple rounds where played)
   * @param payout net payout amount to player (if any)
   * @param playedGameCount amount of game rounds played
   * @param payouts array of payouts for each game round
   */
  event Settled(
    address indexed player,
    uint256 requestId,
    address token,
    uint256 wager,
    uint256 wagerWithMultiplier,
    bool won,
    uint256 payout,
    uint32 playedGameCount,
    uint256[] payouts
  );

  /*==================================================== State Variables ====================================================*/

  struct Game {
    uint8 count;
    uint128 wager;
    uint32 startTime;
    bool gameCompleted;
    uint32[] gameData;
    address player;
    address token;
  }

  struct GameDraws {
    uint32[10] firstDraw;
    uint32[10] secondDraw;
    uint32[10] thirdDraw;
  }

  struct Options {
    uint128 stopGain;
    uint128 stopLoss;
  }

  // maximum selectable game count
  uint256 public constant maxGameCount = 3;
  // cooldown duration to refund
  uint256 public refundCooldown = 2 hours; // default value
  // stores all games_
  mapping(uint256 => Game) internal games_;
  // stores randomizer request ids game pair
  mapping(uint256 => Options) internal options_;
  // mapping(uint256 => bool) public completedGames;
  mapping(uint256 => GameDraws) internal gameDraws_;

  constructor(IRandomizerRouter _router) Core(_router) {}

  function returnGameInfo(uint256 _requestId) external view returns (Game memory) {
    return games_[_requestId];
  }

  function returnOptionsInfo(uint256 _requestId) external view returns (Options memory) {
    return options_[_requestId];
  }

  function updateRefundCooldown(uint256 _refundCooldown) external onlyRole(DEFAULT_ADMIN_ROLE) {
    refundCooldown = _refundCooldown;
  }

  function getFirstDrawResult(uint256 _requestId) external view returns (uint32[10] memory) {
    return gameDraws_[_requestId].firstDraw;
  }

  function getSecondDrawResult(uint256 _requestId) external view returns (uint32[10] memory) {
    return gameDraws_[_requestId].secondDraw;
  }

  function getThirdDrawResult(uint256 _requestId) external view returns (uint32[10] memory) {
    return gameDraws_[_requestId].thirdDraw;
  }

  function getAllDrawResults(
    uint256 _requestId
  )
    external
    view
    returns (
      uint32[10] memory firstDraw_,
      uint32[10] memory secondDraw_,
      uint32[10] memory thirdDraw_
    )
  {
    firstDraw_ = gameDraws_[_requestId].firstDraw;
    secondDraw_ = gameDraws_[_requestId].secondDraw;
    thirdDraw_ = gameDraws_[_requestId].thirdDraw;
  }

  function shouldStop(
    uint256 _total,
    uint256 _wager,
    uint256 _stopGain,
    uint256 _stopLoss
  ) public pure returns (bool stop_) {
    if (_stopGain != 0 && _total > _wager) {
      stop_ = _total - _wager >= _stopGain; // total gain >= stop gain
    } else if (_stopLoss != 0 && _wager > _total) {
      stop_ = _wager - _total >= _stopLoss; // total loss >= stop loss
    }
  }

  function calcWager(
    uint256 _count,
    uint256 _usedCount,
    uint256 _wager
  ) internal pure returns (uint256 usedWager_, uint256 unusedWager_) {
    unchecked {
      // cannot underflow because _usedCount <= _count
      uint256 totalWager = _count * _wager;
      usedWager_ = _usedCount * _wager;
      unusedWager_ = totalWager - usedWager_;
    }
  }

  function refundGame(uint256 _requestId) external nonReentrant {
    Game memory game_ = games_[_requestId];
    require(game_.player == _msgSender(), "Only player");
    require(!game_.gameCompleted, "Keno: Game is completed - not refundable");
    require(game_.startTime + refundCooldown < block.timestamp, "Game is not refundable yet");
    _refundGame(_requestId);
  }

  function refundGameByTeam(uint256 _requestId) external nonReentrant onlyTeam {
    Game memory game_ = games_[_requestId];
    require(!game_.gameCompleted, "Keno: Game is completed - not refundable");
    require(game_.startTime + refundCooldown < block.timestamp, "Keno: Game is not refundable yet");
    _refundGame(_requestId);
  }

  function _refundGame(uint256 _requestId) internal {
    Game memory _game = games_[_requestId];
    uint256 totalRefund_ = _game.wager * _game.count;
    vaultManager.refund(_game.token, totalRefund_, 0, _game.player);
    games_[_requestId].gameCompleted = true;
    emit GameRefunded(_game.player, _requestId, totalRefund_);
  }

  function shareEscrow(
    Game memory _game,
    uint256 _playedGameCount,
    uint256 _payout,
    uint256 _random
  ) internal virtual returns (bool, uint256) {
    (uint256 usedWager_, uint256 unusedWager_) = calcWager(
      _game.count,
      _playedGameCount,
      _game.wager
    );
    vaultManager.setReferralReward(_game.token, _game.player, usedWager_, getHouseEdge(_game));

    uint256 wagerWithMultiplier_ = (_computeMultiplier(_random) * usedWager_) / 1e3;
    vaultManager.mintVestedWINR(_game.token, wagerWithMultiplier_, _game.player);

    _hasLuckyStrike(_random, _game.player, _game.token, usedWager_);

    if (unusedWager_ != 0) {
      vaultManager.payback(_game.token, _game.player, unusedWager_);
    }

    // calculates the loss of user if its not zero transfers to Vault
    if (_payout == 0) {
      vaultManager.payin(_game.token, usedWager_);
    } else {
      vaultManager.payout(_game.token, _game.player, usedWager_, _payout);
    }

    // The used wager is the zero point. if the payout is above the wager, player wins
    return (_payout > usedWager_, wagerWithMultiplier_);
  }

  function getResultNumbers(uint256 _randoms) internal virtual returns (uint256[] memory numbers_);

  function getHouseEdge(Game memory _game) public view virtual returns (uint64 edge_);

  /**
   * @param _game Game struct with game info
   * @param _resultNumbers drawn random numbers by vrf
   * @param _stopGain stop gain (take profit) in token
   * @param _stopLoss stop loss amount in token
   * @return payout_ total payout amount in token
   * @return playedGameCount_ total amount of games_ played
   * @return payouts_ payout amount per round in token
   */
  function play(
    uint256 _requestId,
    Game memory _game,
    uint256[] memory _resultNumbers,
    uint128 _stopGain,
    uint128 _stopLoss
  ) internal virtual returns (uint256 payout_, uint256 playedGameCount_, uint256[] memory payouts_);

  function randomizerFulfill(
    uint256 _requestId,
    uint256[] calldata _randoms
  ) internal override nonReentrant {
    Game memory game_ = games_[_requestId];
    // this is an inverted whenNotCompleted(_requestId) flow - saves on gas
    require(!game_.gameCompleted, "Keno: Game is completed - not refundable");

    games_[_requestId].gameCompleted = true;

    require(game_.player != address(0), "Keno: Game is not created");
    Options memory options__ = options_[_requestId];
    (uint256 payout_, uint256 playedGameCount_, uint256[] memory payouts_) = play(
      _requestId,
      game_,
      _randoms,
      options__.stopGain,
      options__.stopLoss
    );
    (bool won_, uint256 wagerWithMultiplier_) = shareEscrow(
      game_,
      playedGameCount_,
      payout_,
      _randoms[0]
    );

    emit Settled(
      game_.player,
      _requestId,
      game_.token,
      game_.wager,
      wagerWithMultiplier_,
      won_,
      payout_,
      uint32(playedGameCount_),
      payouts_
    );
  }

  /**
   * @notice creates a new game
   * @param _wager amount bet in each game
   * @param _count max amount of games_
   * @param _stopGain take profit amount in token
   * @param _stopLoss stop loss amount in token
   * @param _gameData picked numbers for keno game
   * @param _token address of the token
   */
  function _create(
    uint128 _wager,
    uint8 _count,
    uint128 _stopGain,
    uint128 _stopLoss,
    uint32[] memory _gameData,
    address _token
  ) internal whenNotPaused nonReentrant {
    address player_ = _msgSender();

    // escrows total wager to Vault Manager
    vaultManager.escrow(_token, player_, _count * _wager);

    uint256 requestId_ = _requestRandom(_count);

    games_[requestId_] = Game(
      _count,
      _wager,
      uint32(block.timestamp),
      false,
      _gameData,
      player_,
      _token
    );

    if (_stopGain != 0 || _stopLoss != 0) {
      options_[requestId_] = Options(_stopGain, _stopLoss);
    }

    emit Created(player_, requestId_, _wager, _token);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Number.sol";

abstract contract InternalRNG is NumberHelper {
  /*==================================================== State Variables ====================================================*/

  uint32 private randNonce;

  /*==================================================== FUNCTIONS ===========================================================*/

  function getRandom(uint256 _seed, uint32 _nonce) internal pure returns (uint) {
    return uint(keccak256(abi.encodePacked(_seed, _nonce)));
  }

  function _getRandomNumbers(
    uint256 _seed,
    uint32 _length,
    uint32 _mod
  ) internal returns (uint256[] memory) {
    uint256[] memory randoms_ = new uint[](_length);
    uint32 randNonce_ = randNonce;
    uint32 index_ = 1;

    randoms_[0] = modNumber(_seed, _mod);

    while (index_ != _length) {
      randoms_[index_] = modNumber(getRandom(_seed, randNonce_ + index_), _mod);

      index_++;
    }

    randNonce += index_;

    return randoms_;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./LuckyStrikeRouter.sol";
import "../../interfaces/core/IVaultManager.sol";
import "../helpers/RandomizerConsumer.sol";
import "../helpers/Access.sol";
import "../helpers/Number.sol";

abstract contract Core is
  Pausable,
  Access,
  ReentrancyGuard,
  NumberHelper,
  RandomizerConsumer,
  LuckyStrikeRouter
{
  /*==================================================== Events ==========================================================*/

  event VaultManagerChange(address vaultManager);
  event LuckyStrikeMasterChange(address masterStrike);

  /*==================================================== Modifiers ==========================================================*/

  modifier isWagerAcceptable(address _token, uint256 _wager) {
    uint256 dollarValue_ = _computeDollarValue(_token, _wager);
    require(dollarValue_ >= vaultManager.getMinWager(address(this)), "GAME: Wager too low");
    require(dollarValue_ <= vaultManager.getMaxWager(), "GAME: Wager too high");
    _;
  }

  /// @notice used to calculate precise decimals
  uint256 public constant PRECISION = 1e18;
  /// @notice used to calculate Referral Rewards
  uint32 public constant BASIS_POINTS = 1e4;
  /// @notice Vault manager address
  IVaultManager public vaultManager;

  uint16 public constant ALPHA = 999; // 0.999

  int24 public constant SIGMA_1 = 100; // 0.1
  int24 public constant MEAN_1 = 600; // 0.6

  int24 public constant SIGMA_2 = 10000; // 10
  int24 public constant MEAN_2 = 100000; // 100

  mapping(address => uint256) private decimalsOfToken;

  constructor(IRandomizerRouter _router) RandomizerConsumer(_router) {}

  function setVaultManager(IVaultManager _vaultManager) external onlyGovernance {
    vaultManager = _vaultManager;

    emit VaultManagerChange(address(_vaultManager));
  }

  function setLuckyStrikeMaster(ILuckyStrikeMaster _masterStrike) external onlyGovernance {
    masterStrike = _masterStrike;

    emit LuckyStrikeMasterChange(address(_masterStrike));
  }

  function pause() external onlyTeam {
    _pause();
  }

  function unpause() external onlyTeam {
    _unpause();
  }

  /**
   * @notice internal function that checks in the player has won the lucky strike jackpot
   * @param _randomness random number from the randomizer / vrf
   * @param _player address of the player that has wagered
   * @param _token address of the token the player has wagered
   * @param _usedWager amount of the token the player has wagered
   */
  function _hasLuckyStrike(
    uint256 _randomness,
    address _player,
    address _token,
    uint256 _usedWager
  ) internal returns (bool hasWon_) {
    if (_hasLuckyStrikeCheck(_randomness, _computeDollarValue(_token, _usedWager))) {
      uint256 wonAmount_ = _processLuckyStrike(_player);
      emit LuckyStrike(_player, wonAmount_, true /** true */);
      return true;
    } else {
      emit LuckyStrike(_player, 0, false /** flase */);
      return false;
    }
  }

  /// @notice function to compute jackpot multiplier
  function _computeMultiplier(uint256 _random) internal pure returns (uint256) {
    int256 _sumOfRandoms = int256(_generateRandom(_random)) - 6000;
    _random = (_random % 1000) + 1;

    uint256 multiplier;
    unchecked {
      if (_random >= ALPHA) {
        multiplier = uint256((SIGMA_2 * _sumOfRandoms) / 1e3 + MEAN_2);
      } else {
        multiplier = uint256((SIGMA_1 * _sumOfRandoms) / 1e3 + MEAN_1);
      }
    }

    return _clamp(multiplier, 100, 100000);
  }

  function _clamp(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// @param _random random number that comes from vrf
  /// @notice function to generate 12 random numbers and sum them up
  function _generateRandom(uint256 _random) internal pure returns (uint256 sumOfRandoms_) {
    unchecked {
      uint256 factor = 1;
      for (uint256 i = 0; i < 12; ++i) {
        sumOfRandoms_ += (_random / factor) % 1000;
        factor *= 1000;
      }
    }
    return sumOfRandoms_;
  }

  function _computeDollarValue(
    address _token,
    uint256 _wager
  ) internal returns (uint256 _wagerInDollar) {
    unchecked {
      _wagerInDollar = ((_wager * vaultManager.getPrice(_token))) / (10 ** _getDecimals(_token));
    }
  }

  function _getDecimals(address _token) internal returns (uint256) {
    uint256 decimals_ = decimalsOfToken[_token];
    if (decimals_ == 0) {
      decimalsOfToken[_token] = IERC20Metadata(_token).decimals();
      return decimalsOfToken[_token];
    } else {
      return decimals_;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract NumberHelper {
  function modNumber(uint256 _number, uint32 _mod) internal pure returns (uint256 modded_) {
    unchecked {
      modded_ = _mod > 0 ? _number % _mod : _number;
    }
  }

  function modNumbers(
    uint256[] memory _numbers,
    uint32 _mod
  ) internal pure returns (uint256[] memory modNumbers_) {
    modNumbers_ = new uint[](_numbers.length);
    unchecked {
      for (uint256 i = 0; i < _numbers.length; i++) {
        modNumbers_[i] = modNumber(_numbers[i], _mod);
      }
    }
    return modNumbers_;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/core/ILuckyStrikeMaster.sol";

abstract contract LuckyStrikeRouter {
  event LuckyStrike(address indexed player, uint256 wonAmount, bool won);

  ILuckyStrikeMaster public masterStrike;

  function _hasLuckyStrikeCheck(
    uint256 _randomness,
    uint256 _usdWager
  ) internal view returns (bool hasWon_) {
    hasWon_ = masterStrike.hasLuckyStrike(_randomness, _usdWager);
  }

  function _processLuckyStrike(address _player) internal returns (uint256 wonAmount_) {
    wonAmount_ = masterStrike.processLuckyStrike(_player);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/vault/IFeeCollector.sol";
import "../../interfaces/vault/IVault.sol";

/// @dev This contract designed to easing token transfers broadcasting information between contracts
interface IVaultManager {
  function vault() external view returns (IVault);

  function wlp() external view returns (IERC20);
  function BASIS_POINTS() external view returns (uint32);

  function feeCollector() external view returns (IFeeCollector);

  function getMaxWager() external view returns (uint256);

  function getMinWager(address _game) external view returns (uint256);

  function getWhitelistedTokens() external view returns (address[] memory whitelistedTokenList_);

  function refund(address _token, uint256 _amount, uint256 _vWINRAmount, address _player) external;

  /// @notice escrow tokens into the manager
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function escrow(address _token, address _sender, uint256 _amount) external;

  /// @notice function that assign reward of referral
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _player holder of tokens
  /// @param _amount the amount of token
  /// @param _houseEdge edge percent of game eg. 1000 = 10.00
  function setReferralReward(
    address _token,
    address _player,
    uint256 _amount,
    uint64 _houseEdge
  ) external returns (uint256 referralReward_);

  /// @notice function that remove reward of referral
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _player holder of tokens
  /// @param _amount the amount of token
  function removeReferralReward(address _token, address _player, uint256 _amount, uint64 _houseEdge) external;

  /// @notice release some amount of escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient holder of tokens
  /// @param _amount the amount of token
  function payback(address _token, address _recipient, uint256 _amount) external;

  /// @notice lets vault get wager amount from escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _amount the amount of token
  function getEscrowedTokens(address _token, uint256 _amount) external;

  /// @notice lets vault get wager amount from escrowed tokens
  function payout(
    address _token,
    address _recipient,
    uint256 _escrowAmount,
    uint256 _totalAmount
  ) external;

  /// @notice lets vault get wager amount from escrowed tokens
  function payin(address _token, uint256 _escrowAmount) external;

  /// @notice transfers any whitelisted token into here
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function transferIn(address _token, address _sender, uint256 _amount) external;

  /// @notice transfers any whitelisted token to recipient
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient of tokens
  /// @param _amount the amount of token
  function transferOut(address _token, address _recipient, uint256 _amount) external;

  /// @notice used to mint vWINR to recipient
  /// @param _input currency of payment
  /// @param _amount of wager
  /// @param _recipient recipient of vWINR
  function mintVestedWINR(
    address _input,
    uint256 _amount,
    address _recipient
  ) external returns (uint256 vWINRAmount_);

  /// @notice used to transfer player's token to WLP
  /// @param _input currency of payment
  /// @param _amount convert token amount
  /// @param _sender sender of token
  /// @param _recipient recipient of WLP
  function deposit(
    address _input,
    uint256 _amount,
    address _sender,
    address _recipient
  ) external returns (uint256);

  function getPrice(address _token) external view returns (uint256 _price);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Access.sol";
import "../../interfaces/randomizer/providers/supra/ISupraRouter.sol";
import "../../interfaces/randomizer/IRandomizerRouter.sol";
import "../../interfaces/randomizer/IRandomizerConsumer.sol";
import "./Number.sol";

abstract contract RandomizerConsumer is Access, IRandomizerConsumer {
  /*==================================================== Modifiers ===========================================================*/

  modifier onlyRandomizer() {
    require(hasRole(RANDOMIZER_ROLE, _msgSender()), "RC: Not randomizer");
    _;
  }

  /*==================================================== State Variables ====================================================*/

  /// @notice minimum confirmation blocks
  uint256 public minConfirmations = 3;
  /// @notice router address
  IRandomizerRouter public randomizerRouter;
  /// @notice Randomizer ROLE as Bytes32
  bytes32 public constant RANDOMIZER_ROLE = bytes32(keccak256("RANDOMIZER"));

  /*==================================================== FUNCTIONS ===========================================================*/

  constructor(IRandomizerRouter _randomizerRouter) {
    changeRandomizerRouter(_randomizerRouter);
  }

  /*==================================================== Configuration Functions ====================================================*/

  function changeRandomizerRouter(IRandomizerRouter _randomizerRouter) public onlyGovernance {
    randomizerRouter = _randomizerRouter;
    grantRole(RANDOMIZER_ROLE, address(_randomizerRouter));
  }

  function setMinConfirmations(uint16 _minConfirmations) external onlyGovernance {
    minConfirmations = _minConfirmations;
  }

  /*==================================================== Randomizer Functions ====================================================*/

  function randomizerFulfill(uint256 _requestId, uint256[] calldata _rngList) internal virtual;

  function randomizerCallback(
    uint256 _requestId,
    uint256[] calldata _rngList
  ) external onlyRandomizer {
    randomizerFulfill(_requestId, _rngList);
  }

  function _requestRandom(uint8 _count) internal returns (uint256 requestId_) {
    requestId_ = randomizerRouter.request(_count, minConfirmations);
  }

  function _requestScheduledRandom(
    uint8 _count,
    uint256 targetTime
  ) internal returns (uint256 requestId_) {
    requestId_ = randomizerRouter.scheduledRequest(_count, targetTime);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Access is AccessControl {
  /*==================================================== Modifiers ==========================================================*/

  modifier onlyGovernance() virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ACC: Not governance");
    _;
  }

  modifier onlyTeam() virtual {
    require(hasRole(TEAM_ROLE, _msgSender()), "GAME: Not team");
    _;
  }

  /*==================================================== State Variables ====================================================*/

  bytes32 public constant TEAM_ROLE = bytes32(keccak256("TEAM"));

  /*==================================================== Functions ===========================================================*/

  constructor()  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILuckyStrikeMaster {
  event LuckyStrikePayout(address indexed player, uint256 wonAmount);
  event DeleteTokenFromWhitelist(address indexed token);
  event TokenAddedToWhitelist(address indexed token);
  event SyncTokens();
  event GameRemoved(address indexed game);
  event GameAdded(address indexed game);
  event DeleteAllWhitelistedTokens();
  event LuckyStrike(address indexed player, uint256 wonAmount, bool won);
  event WithdrawByGovernance(address indexed token, uint256 amount);

  function withdrawTokenByGovernance(address _token, uint256 _amount) external;

  function hasLuckyStrike(
    uint256 _randomness,
    uint256 _wagerUSD
  ) external view returns (bool hasWon_);

  function valueOfLuckyStrikeJackpot() external view returns (uint256 valueTotal_);

  function processLuckyStrike(address _player) external returns (uint256 wonAmount_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFeeCollector {
  function calcFee(uint256 _amount) external view returns (uint256);

  function onIncreaseFee(address _token) external;

  function onVolumeIncrease(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
  function getReserve() external view returns (uint256);

  function getWlpValue() external view returns (uint256);

  function payout(
    address _wagerAsset,
    address _escrowAddress,
    uint256 _escrowAmount,
    address _recipient,
    uint256 _totalAmount
  ) external;

  function payoutNoEscrow(address _wagerAsset, address _recipient, uint256 _totalAmount) external;

  function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

  function deposit(address _token, address _receiver) external returns (uint256);

  function withdraw(address _token, address _receiver) external;

  function payinWagerFee(address _tokenIn) external;

  function wagerFeeReserves(address _token) external view returns (uint256);

  function allWhitelistedTokensLength() external view returns (uint256);

  function allWhitelistedTokens(uint256) external view returns (address);

  function getMinPrice(address _token) external view returns (uint256);

  function payinPoolProfits(address _tokenIn) external;

  function tokenToUsdMin(
    address _tokenToPrice,
    uint256 _tokenAmount
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5 <0.9.0;

interface ISupraRouter { 
	function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, address _clientWalletAddress) external returns(uint256);
    function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed, address _clientWalletAddress) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRandomizerRouter {
  function request(uint32 count, uint256 _minConfirmations) external returns (uint256);
  function scheduledRequest(uint32 _count, uint256 targetTime) external returns (uint256);
  function response(uint256 _requestId, uint256[] calldata _rngList) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRandomizerConsumer {
  function randomizerCallback(uint256 _requestId, uint256[] calldata _rngList) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}