// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CommonBaccarat.sol";
import "../../helpers/InternalRNG.sol";

// import "forge-std/Test.sol";

contract Baccarat is CommonSoloBaccarat, InternalRNG {
  uint256 public constant multiplierTie = 900;
  uint256 public constant multiplierBanker = 200;
  uint256 public constant multiplierPlayer = 195;
  uint64 public constant houseEdge = 98; // note we can just use uin256 because it uses a strorage slot anyway

  enum BaccaratResult {
    UNDECIDED,
    PLAYER_WINS,
    BANK_WINS,
    DRAW
  }

  // player has third card, rules banker for third card
  bool[10] internal bankerPuntoThree = [
    true,
    true /** banker has 3 points, player draws ace, 3rd card for banker */,
    true,
    true,
    true,
    true,
    true,
    true,
    false,
    true
  ];

  bool[10] internal bankerPuntoFour = [
    false /** banker has 4 points, player draws 10 point card, no 3rd card for banker */,
    false,
    true,
    true,
    true,
    true,
    true,
    false,
    false
  ];
  bool[10] internal bankerPuntoFive = [
    false,
    false,
    true,
    true /** banker has 5 points, player draws a 3 point card, third card for banker */,
    true,
    true,
    true,
    false,
    false
  ];
  bool[10] internal bankerPuntoSix = [
    false,
    false,
    false,
    false,
    false,
    true,
    true,
    false,
    false /** banker has 6 points, player draws 9 point card, no third card draw */
  ];

  constructor(IRandomizerRouter _router) CommonSoloBaccarat(_router) {}

  function getResultNumbers(
    uint256 _randoms
  ) internal override returns (uint256[6] memory topCards_) {
    // uint8[] memory allNumbersDecks_ = new uint8[](312);
    uint256[312] memory allNumbersDecks_;

    uint256 index_ = 0;

    unchecked {
      // Loop for 6 decks
      for (uint256 i = 0; i < 6; ++i) {
        for (uint256 t = 0; t < 4; ++t) {
          // 14 different types of cards in each deck
          for (uint256 x = 1; x <= 13; ++x) {
            // console.log("index_ %s", index_);
            allNumbersDecks_[index_] = x;
            index_++;
          }
        }
      }
    }

    // allNumbersDecks_ represents a deck of 6 cards, with 1 being the Ace, and 13 the king, it currently contains 312 numbers perfectly sorted per number.

    unchecked {
      // Perform a Fisher-Yates shuffle to randomize the array/deck
      for (uint256 y = 311; y >= 1; --y) {
        uint256 value_ = uint256(keccak256(abi.encodePacked(_randoms, y))) % (y + 1);
        (allNumbersDecks_[y], allNumbersDecks_[value_]) = (
          allNumbersDecks_[value_],
          allNumbersDecks_[y]
        );
      }
    }

    unchecked {
      // Select the first 6 cards from the shuffled deck (from the top)
      for (uint256 x = 0; x < 6; ++x) {
        uint256 value_ = allNumbersDecks_[x];
        // note this is uncommented, but previously we converted the card value to the amount of points, so this if statement would turn 10 and the face cards to 0 puntos
        topCards_[x] = value_;
      }
    }

    return topCards_;
  }

  function _scaleValueToPunto(uint256 _value) internal pure returns (uint256) {
    if (_value >= 10) {
      return 0;
    }
    return _value;
  }

  function getHouseEdge() public pure override returns (uint64 edge_) {
    edge_ = houseEdge;
  }

  /**
   * @notice Calculates the punto total for the player hand
   * @param _game the game struct to calculate the punto for
   */
  function calculatePlayerPuntoTotal(
    BaccaratGame memory _game
  ) public pure returns (uint256 total_) {
    // the player hand has a third card (according to the rules)
    if (_game.playerHand.hasThirdCard) {
      total_ =
        (_scaleValueToPunto(_game.playerHand.firstCard) +
          _scaleValueToPunto(_game.playerHand.secondCard) +
          _scaleValueToPunto(_game.playerHand.thirdCard)) %
        10;
    } else {
      // the dealt third card is not included in the calculation
      total_ =
        (_scaleValueToPunto(_game.playerHand.firstCard) +
          _scaleValueToPunto(_game.playerHand.secondCard)) %
        10;
    }
  }

  /**
   * @notice Calculates the punto total for the banker hand
   * @param _game the game struct to calculate the punto for
   */
  function calculateBankerPuntoTotal(
    BaccaratGame memory _game
  ) public pure returns (uint256 total_) {
    // the banker hand has a third card (according to the rules)
    if (_game.bankerHand.hasThirdCard) {
      total_ =
        (_scaleValueToPunto(_game.bankerHand.firstCard) +
          _scaleValueToPunto(_game.bankerHand.secondCard) +
          _scaleValueToPunto(_game.bankerHand.thirdCard)) %
        10;
      // the banker hand does not have a third card (according to the rules)
    } else {
      // the dealt third card is not included in the calculation
      total_ =
        (_scaleValueToPunto(_game.bankerHand.firstCard) +
          _scaleValueToPunto(_game.bankerHand.secondCard)) %
        10;
    }
  }

  /**
   * @notice returns who has won a certain game
   * @param _requestId the requestId of the game to check the winner for
   */
  function whoIsWinner(uint256 _requestId) public view returns (BaccaratResult result_) {
    BaccaratGame memory game_ = games_[_requestId];
    uint256 playerTotal_ = calculatePlayerPuntoTotal(game_);
    uint256 bankTotal_ = calculateBankerPuntoTotal(game_);
    return _checkWinner(playerTotal_, bankTotal_);
  }

  /**
   * @notice returns the player punto for a certain game
   * @param _requestId the requestId of the game to check the player punto for
   * @return playerPunto_ the player punto for the game
   */
  function getPlayerPunto(uint256 _requestId) public view returns (uint256 playerPunto_) {
    BaccaratGame memory game_ = games_[_requestId];
    playerPunto_ = calculatePlayerPuntoTotal(game_);
  }

  /**
   * @notice returns the banker punto for a certain game
   * @param _requestId the requestId of the game to check the banker punto for
   * @return bankerPunto_ the banker punto for the game
   */
  function getBankerPunto(uint256 _requestId) public view returns (uint256 bankerPunto_) {
    BaccaratGame memory game_ = games_[_requestId];
    bankerPunto_ = calculateBankerPuntoTotal(game_);
  }

  /**
   * @param _playerTotal amount punto for player
   * @param _bankTotal amount punto for banker
   */
  function _checkWinner(
    uint256 _playerTotal,
    uint256 _bankTotal
  ) internal pure returns (BaccaratResult result_) {
    if (_playerTotal == _bankTotal) {
      return BaccaratResult.DRAW;
    } else if (_playerTotal > _bankTotal) {
      return BaccaratResult.PLAYER_WINS;
    } else {
      return BaccaratResult.BANK_WINS;
    }
  }

  /**
   * @param _playerTotal amount punto for player
   * @param _bankTotal amount punto for banker
   */
  function _checkImmediateWinner(
    uint256 _playerTotal,
    uint256 _bankTotal
  ) internal pure returns (BaccaratResult result_) {
    if (_playerTotal > 7 || _bankTotal > 7) {
      // either bank or player have 8 or 9 (higher than 7)
      if (_playerTotal == _bankTotal) {
        // both bank and player have 8 or 9, its a draw
        return BaccaratResult.DRAW;
      } else if (_playerTotal > _bankTotal) {
        return BaccaratResult.PLAYER_WINS;
      } else {
        return BaccaratResult.BANK_WINS;
      }
    }
  }

  function _calculateWinnings(
    BaccaratResult result_,
    Bet memory _bet
  ) internal pure returns (uint256 payout_) {
    uint256 betAmount_;
    unchecked {
      if (result_ == BaccaratResult.DRAW) {
        betAmount_ = chip2TokenDecimals(_bet.tieWins, _bet.decimals, _bet.tokenPrice * 1e18);
        payout_ = (betAmount_ * multiplierTie) / 1e2;
      } else if (result_ == BaccaratResult.PLAYER_WINS) {
        betAmount_ = chip2TokenDecimals(_bet.playerWins, _bet.decimals, _bet.tokenPrice * 1e18);
        payout_ = (betAmount_ * multiplierBanker) / 1e2;
      } else if (result_ == BaccaratResult.BANK_WINS) {
        betAmount_ = chip2TokenDecimals(_bet.bankWins, _bet.decimals, _bet.tokenPrice * 1e18);
        payout_ = (betAmount_ * multiplierPlayer) / 1e2;
      } else {
        revert("Baccarat: invalid state");
        payout_ = 0;
      }
    }
  }

  function play(
    uint256 _requestId,
    Bet memory _bet,
    uint256 _random
  ) internal override returns (uint256 payout_) {
    // shuffle 6 decks, take 6 first cards (random Fisher-Yates shuffle)
    uint256[6] memory topCards_ = getResultNumbers(_random);

    // deal top card to player, and the next to the bank, then the next to the player, then the next to the bank
    uint256 playerCount_;
    uint256 bankCount_;

    unchecked {
      playerCount_ = _scaleValueToPunto(topCards_[0]) + _scaleValueToPunto(topCards_[2]);
      bankCount_ = _scaleValueToPunto(topCards_[1]) + _scaleValueToPunto(topCards_[3]);
    }

    // deal the cards to the player and banker
    BothHands memory hands_ = BothHands(
      Hand(false, uint8(topCards_[0]), uint8(topCards_[2]), uint8(topCards_[4])), // deal player hand
      Hand(false, uint8(topCards_[1]), uint8(topCards_[3]), uint8(topCards_[5])) // deal banker hand
    );

    // if either banker or players punto is 8 or 9, the game is over and no more cards are dealt (for either hands)
    if (_checkImmediateWinner(playerCount_ % 10, bankCount_ % 10) != BaccaratResult.UNDECIDED) {
      // game ended, either player or banker ahve 8 or 9, calculate potential payout for the game
      payout_ = _calculateWinnings(_checkWinner(playerCount_ % 10, bankCount_ % 10), _bet);
      emit HandFinalized(games_[_requestId].player, _requestId, hands_);
      games_[_requestId].bankerHand = hands_.bankerHand;
      games_[_requestId].playerHand = hands_.playerHand;
      return payout_;
    }

    // neither the banker or the player has 8 or 9, game continues

    // first check if player gets third card based on the first two cards of the player

    // if player has 6 or 7 points, no third card for player
    if ((playerCount_ % 10) < 6) {
      // player punto is 1,2,3,4,5 -> player gets third card
      unchecked {
        playerCount_ += _scaleValueToPunto(topCards_[4]);
      }
      // register that player has gotten third card
      hands_.playerHand.hasThirdCard = true;
    } else {
      // the player stands (no third card) so player has 6 or 7, check if the bank gets a third card according to the rules
      if ((bankCount_ % 10) < 6) {
        // bank punto is 1,2,3,4,5 -> bank gets third card
        unchecked {
          bankCount_ += _scaleValueToPunto(topCards_[5]);
        }
        // register that bank has gotten third card
        hands_.bankerHand.hasThirdCard = true;
      }
      // game is over, calculate payout
      payout_ = _calculateWinnings(_checkWinner(playerCount_ % 10, bankCount_ % 10), _bet);
      emit HandFinalized(games_[_requestId].player, _requestId, hands_);
      games_[_requestId].bankerHand = hands_.bankerHand;
      games_[_requestId].playerHand = hands_.playerHand;
      return payout_;
    }

    // note if we are here it is still possible that the player has 2 or 3 cards, the bank certainly has only 2 cards at this point

    // when bank has punto 7, no new card for banker, game ends
    // note this is a bit redundant code because this is also in the schema? but it is a good check
    if ((bankCount_ % 10) == 7) {
      // console.log("bank has 7 points, no third card, game over");
      hands_.bankerHand.hasThirdCard = false;
      emit HandFinalized(games_[_requestId].player, _requestId, hands_);
      payout_ = _calculateWinnings(_checkWinner(playerCount_ % 10, bankCount_ % 10), _bet);
      games_[_requestId].bankerHand = hands_.bankerHand;
      games_[_requestId].playerHand = hands_.playerHand;
      return payout_;
    }

    // if player has a thrid card, and the banker not yet, the bank will get a third card depending on the third drawn card of the player and the bankers total punto
    if (hands_.playerHand.hasThirdCard && !hands_.bankerHand.hasThirdCard) {
      // check if bank gets third card (according to the specific mapping for this stage of the hand)
      bool thirdCard_ = _doesBankerGetThirdCard(_scaleValueToPunto(topCards_[4]), bankCount_ % 10);
      if (thirdCard_) {
        // banker gets third card
        unchecked {
          bankCount_ += _scaleValueToPunto(topCards_[5]);
        }
        // register that bank has gotten third card
        hands_.bankerHand.hasThirdCard = true;
      }
    }

    games_[_requestId].bankerHand = hands_.bankerHand;
    games_[_requestId].playerHand = hands_.playerHand;

    emit HandFinalized(games_[_requestId].player, _requestId, hands_);

    // calculate how much the payout is
    payout_ = _calculateWinnings(_checkWinner(playerCount_ % 10, bankCount_ % 10), _bet);

    return payout_;
  }

  function isPlayerRebetPossible(address _player) external view returns (bool) {
    return previousGameOfPlayer[_player] != 0;
  }

  function previousPlayerChoicesRebet(
    address _player
  ) external view returns (uint128 tieWins_, uint128 bankWins_, uint128 playerWins_) {
    uint256 requestId_ = previousGameOfPlayer[_player];
    require(requestId_ != 0, "Baccarat: No previous game found");
    BaccaratGame memory game_ = games_[requestId_];
    tieWins_ = game_.bet.tieWins;
    bankWins_ = game_.bet.bankWins;
    playerWins_ = game_.bet.playerWins;
  }

  function rebet() external {
    uint256 requestId_ = previousGameOfPlayer[msg.sender];
    require(requestId_ != 0, "Baccarat: No previous game found");
    BaccaratGame memory game_ = games_[requestId_];
    _bet(game_.bet.tieWins, game_.bet.bankWins, game_.bet.playerWins, game_.token);
  }

  /**
   * @notice returns if the bank gets a third card
   * @param _thirdCard the third card of the player (amount of points/puntos)
   * @param _puntoBanker how much puntos the banker has with the first two cards
   * @return thirdCard_ if the bank gets a third card. true = third card, false = no third card
   *
   */
  function _doesBankerGetThirdCard(
    uint256 _thirdCard,
    uint256 _puntoBanker
  ) internal view returns (bool thirdCard_) {
    if (_puntoBanker < 3) {
      return true;
    } else if (_puntoBanker == 3) {
      return bankerPuntoThree[_thirdCard];
    } else if (_puntoBanker == 4) {
      return bankerPuntoFour[_thirdCard];
    } else if (_puntoBanker == 5) {
      return bankerPuntoFive[_thirdCard];
    } else if (_puntoBanker == 6) {
      return bankerPuntoSix[_thirdCard];
    } else {
      require(_puntoBanker == 7, "Baccarat: Punto cannot be higher than 7.");
      return false;
    }
  }

  // internal function that checks the bet
  function _checkWagerReturn(
    uint128 _tieWinsChips,
    uint128 _bankWinsChips,
    uint128 _playerWinsChips,
    address _token
  ) internal returns (Bet memory) {
    uint128 totalWagerChips_ = uint128(_tieWinsChips + _bankWinsChips + _playerWinsChips);
    uint256 dollarValue_ = chip2Token(totalWagerChips_, _token, vaultManager.getPrice(_token));
    require(dollarValue_ >= minWagerAmount, "Baccarat: Wager too low");
    return
      Bet({
        tokenPrice: uint96(vaultManager.getPrice(_token) / 1e18),
        totalWager: uint32(totalWagerChips_),
        tieWins: uint32(_tieWinsChips),
        bankWins: uint32(_bankWinsChips),
        playerWins: uint32(_playerWinsChips),
        decimals: uint16(_getDecimals(_token))
      });
  }

  /**
   * @notice main betting function for baccarat
   * @param _tieWins amount chips wagered on tie
   * @param _bankWins amount chips wagered on banker win
   * @param _playerWins amount chips wagered on player win
   * @param _token address of the token wagered
   */
  function bet(uint128 _tieWins, uint128 _bankWins, uint128 _playerWins, address _token) external {
    _bet(_tieWins, _bankWins, _playerWins, _token);
  }

  function _bet(uint128 _tieWins, uint128 _bankWins, uint128 _playerWins, address _token) internal {
    _create(_checkWagerReturn(_tieWins, _bankWins, _playerWins, _token), _token);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../core/Core.sol";

// import "forge-std/Test.sol";

abstract contract CommonSoloBaccarat is Core {
  /*==================================================== Events =============================================================*/

  event Created(
    address indexed player,
    uint256 indexed requestId,
    uint256 totalWager,
    address token
  );

  event Settled(
    address indexed player,
    uint256 requestId,
    address token,
    uint256 wager,
    bool won,
    uint256 payout
  );

  event HandFinalized(address indexed player, uint256 requestId, BothHands hands);

  struct BothHands {
    Hand playerHand;
    Hand bankerHand;
  }

  struct Hand {
    bool hasThirdCard;
    uint8 firstCard;
    uint8 secondCard;
    uint8 thirdCard;
  }

  struct Bet {
    uint96 tokenPrice;
    uint32 totalWager;
    uint32 tieWins;
    uint32 bankWins;
    uint32 playerWins;
    uint16 decimals;
  }

  // struct Bet {
  //   uint128 tokenPrice;
  //   uint128 totalWager;
  //   uint128 tieWins;
  //   uint128 bankWins;
  //   uint128 playerWins;
  //   uint16 decimals;
  // }

  struct BaccaratGame {
    address player;
    address token;
    uint32 startTime;
    Bet bet;
    Hand playerHand;
    Hand bankerHand;
  }

  /// @notice cooldown duration to refund
  uint32 public refundCooldown = 2 hours; // default value
  /// @notice stores all games_
  mapping(uint256 => BaccaratGame) internal games_;
  /// @notice stores randomizer request ids game pair

  // playerAddress => requestId VRF
  mapping(address => uint256) internal previousGameOfPlayer;

  mapping(address => uint256) private decimalsOfToken;

  // minWagerAmount to be confiugered here
  uint256 public constant minWagerAmount = 1e2;

  /*==================================================== Functions ===========================================================*/

  constructor(IRandomizerRouter _router) Core(_router) {}

  function updateRefundCooldown(uint32 _refundCooldown) external onlyRole(DEFAULT_ADMIN_ROLE) {
    refundCooldown = _refundCooldown;
  }

  function games(uint256 _requestId) external view returns (BaccaratGame memory) {
    return games_[_requestId];
  }

  function refundGame(uint256 _requestId) external nonReentrant {
    BaccaratGame memory game_ = games_[_requestId];
    require(game_.player == _msgSender(), "Only player");
    require(
      game_.startTime + refundCooldown < block.timestamp,
      "Baccarat: Game is not refundable yet"
    );
    _whenGameNotCompleted(_requestId, game_.player);
    _refundGame(_requestId);
  }

  function refundGameByTeam(uint256 _requestId) external nonReentrant onlyTeam {
    BaccaratGame memory game_ = games_[_requestId];
    require(
      game_.startTime + refundCooldown < block.timestamp,
      "Baccarat: Game is not refundable yet"
    );
    _whenGameNotCompleted(_requestId, game_.player);
    _refundGame(_requestId);
  }

  function _refundGame(uint256 _requestId) internal {
    BaccaratGame memory _game = games_[_requestId];

    vaultManager.refund(_game.token, _game.bet.totalWager, 0, _game.player);
    delete games_[_requestId];
  }

  function shareEscrow(
    BaccaratGame memory _game,
    uint256,
    uint256 _payout
  ) internal virtual returns (bool) {
    uint128 totalWager_ = _game.bet.totalWager;

    /// @notice sets referral reward if player has referee
    // note setReferralReward is concommented! todo add a mock for referral reward!
    vaultManager.setReferralReward(_game.token, _game.player, totalWager_, getHouseEdge());
    vaultManager.mintVestedWINR(_game.token, totalWager_, _game.player);

    /// @notice calculates the loss of user if its not zero transfers to Vault
    if (_payout == 0) {
      vaultManager.payin(_game.token, totalWager_);
    } else {
      vaultManager.payout(_game.token, _game.player, totalWager_, _payout);
    }

    /// @notice The used wager is the zero point. if the payout is above the wager, player wins
    return _payout > totalWager_;
  }

  // function that returns the game data struct
  function getGameData(uint256 _requestId) external view returns (BaccaratGame memory) {
    return games_[_requestId];
  }

  function getBankerHand(uint256 _requestId) external view returns (Hand memory) {
    return games_[_requestId].bankerHand;
  }

  function getPlayerHand(uint256 _requestId) external view returns (Hand memory) {
    return games_[_requestId].playerHand;
  }

  function getResultNumbers(
    uint256 _randoms
  ) internal virtual returns (uint256[6] memory topCards_);

  function getHouseEdge() public view virtual returns (uint64 edge_);

  function _whenGameNotCompleted(uint256 _requestId, address _player) internal {
    // this is an inverted whenNotCompleted(_requestId) flow - saves on gas
    require(previousGameOfPlayer[_player] != _requestId, "Baccarat: Game is already played");
    // this is an inverted whenNotCompleted(_requestId) flow - saves on gas
    previousGameOfPlayer[_player] = _requestId;
  }

  function _getDecimals(address _token) internal returns (uint256 decimals_) {
    if (decimalsOfToken[_token] == 0) {
      decimalsOfToken[_token] = IERC20Metadata(_token).decimals();
      return decimalsOfToken[_token];
    } else {
      return decimalsOfToken[_token];
    }
  }

  function chip2Token(uint256 _chips, address _token, uint256 _price) public returns (uint256) {
    return ((_chips * (10 ** (30 + _getDecimals(_token))))) / _price;
  }

  function chip2TokenDecimals(
    uint256 _chips,
    uint256 _decimals,
    uint256 _price
  ) public pure returns (uint256) {
    return ((_chips * (10 ** (30 + _decimals)))) / _price;
  }

  function play(
    uint256 _requestId,
    Bet memory _bet,
    uint256 _random
  ) internal virtual returns (uint256 payout_);

  function randomizerFulfill(
    uint256 _requestId,
    uint256[] calldata _randoms
  ) internal override nonReentrant {
    BaccaratGame memory game_ = games_[_requestId];
    require(game_.player != address(0), "Baccarat: Game is not created");

    previousGameOfPlayer[game_.player] = _requestId;

    uint256 payout_ = play(_requestId, game_.bet, _randoms[0]);

    emit Settled(
      game_.player,
      _requestId,
      game_.token,
      game_.bet.totalWager,
      shareEscrow(game_, 1, payout_),
      payout_
    );
  }

  function _create(Bet memory _bet, address _token) internal whenNotPaused nonReentrant {
    address player_ = _msgSender();

    vaultManager.escrow(_token, player_, _bet.totalWager);

    uint256 requestId_ = _requestRandom(1);

    games_[requestId_] = BaccaratGame(
      player_,
      _token,
      uint32(block.timestamp),
      _bet,
      Hand(false, 0, 0, 0),
      Hand(false, 0, 0, 0)
    );

    emit Created(player_, requestId_, _bet.totalWager, _token);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Number.sol";

abstract contract InternalRNG is NumberHelper {
  /*==================================================== State Variables ====================================================*/

  uint32 private randNonce;

  /*==================================================== FUNCTIONS ===========================================================*/

  function getRandom(uint256 _seed, uint32 _nonce) internal returns(uint) {
    return uint(keccak256(abi.encodePacked(_seed, _nonce)));
  }

  function _getRandomNumbers(
    uint256 _seed, 
    uint32 _length, 
    uint32 _mod) internal returns (uint256[] memory) {
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
import "../../interfaces/core/IVaultManager.sol";
import "../helpers/RandomizerConsumer.sol";
import "../helpers/Access.sol";
import "../helpers/Number.sol";

abstract contract Core is Pausable, Access, ReentrancyGuard, NumberHelper, RandomizerConsumer {
  /*==================================================== Events ==========================================================*/

  event VaultManagerChange(address vaultManager);

  /*==================================================== Modifiers ==========================================================*/

  modifier isWagerAcceptable(address _token, uint256 _wager) {
    uint256 dollarValue_ = _computeDollarValue(_token, _wager);
    require(dollarValue_ >= vaultManager.getMinWager(address(this)), "GAME: Wager too low");
    require(dollarValue_ <= vaultManager.getMaxWager(), "GAME: Wager too high");
    _;
  }

  /*==================================================== State Variables ====================================================*/

  /// @notice used to calculate precise decimals
  uint256 public constant PRECISION = 1e18;
  /// @notice used to calculate Referral Rewards
  uint32 public constant BASIS_POINTS = 1e4;
  /// @notice Vault manager address
  IVaultManager public vaultManager;

  /*==================================================== Functions ===========================================================*/

  constructor(IRandomizerRouter _router) RandomizerConsumer(_router) {}

  function setVaultManager(IVaultManager _vaultManager) external onlyGovernance {
    vaultManager = _vaultManager;

    emit VaultManagerChange(address(_vaultManager));
  }

  function pause() external onlyTeam {
    _pause();
  }

  function unpause() external onlyTeam {
    _unpause();
  }

  function _computeDollarValue(
    address _token,
    uint256 _wager
  ) public view returns (uint256 _wagerInDollar) {
    _wagerInDollar = ((_wager * vaultManager.getPrice(_token))) / (10 ** IERC20Metadata(_token).decimals());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract NumberHelper {
  function modNumber(uint256 _number, uint32 _mod) internal pure returns (uint256) {
    return _mod > 0 ? _number % _mod : _number;
  }

  function modNumbers(uint256[] memory _numbers, uint32 _mod) internal pure returns (uint256[] memory) {
    uint256[] memory modNumbers_ = new uint[](_numbers.length);

    for (uint256 i = 0; i < _numbers.length; i++) {
      modNumbers_[i] = modNumber(_numbers[i], _mod);
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

  function getMinPrice(address _token) external view returns (uint256);

  function payout(
    address _wagerAsset,
    address _escrowAddress,
    uint256 _escrowAmount,
    address _recipient,
    uint256 _totalAmount
  ) external;

  function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

  function deposit(address _token, address _receiver) external returns (uint256);

  function withdraw(address _token, address _receiver) external;
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