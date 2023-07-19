// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CommonBaccarat.sol";
import "../../helpers/InternalRNG.sol";

contract Baccarat is CommonSoloBaccarat, InternalRNG {
  uint256 public constant multiplierTie = 900;
  uint256 public constant multiplierBanker = 195;
  uint256 public constant multiplierPlayer = 200;
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
    false, // 0
    false, // 1
    true, // 2
    true, // 3
    true, // 4
    true, // 5
    true, // 6
    true, // 7
    false, // 8
    false // 9
  ];

  bool[10] internal bankerPuntoFive = [
    false, // 0
    false, // 1
    false, // 2
    false, // 3
    true, // 4
    true, // 5
    true, // 6
    true, // 7
    false, // 8
    false // 9
  ];

  bool[10] internal bankerPuntoSix = [
    false, // 0
    false, // 1
    false, // 2
    false, // 3
    false, // 4
    false, // 5
    true, // 6
    true, // 7
    false, // 8
    false // 9
  ];

  constructor(IRandomizerRouter _router) CommonSoloBaccarat(_router) {}

  function getResultNumbers(
    uint256 _randoms
  ) internal pure override returns (uint256[6] memory topCards_) {
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
    } else {
      return BaccaratResult.UNDECIDED;
    }
  }

  function _calculateWinnings(
    BaccaratResult result_,
    Bet memory _betInfo
  ) internal pure returns (uint256 payout_) {
    uint256 betAmount_;
    unchecked {
      if (result_ == BaccaratResult.DRAW) {
        betAmount_ = _chip2TokenDecimals(
          _betInfo.tieWinsInChips,
          _betInfo.decimals,
          _betInfo.tokenPrice
        );
        payout_ = (betAmount_ * multiplierTie) / 1e2;
      } else if (result_ == BaccaratResult.PLAYER_WINS) {
        betAmount_ = _chip2TokenDecimals(
          _betInfo.playerWinsInChips,
          _betInfo.decimals,
          _betInfo.tokenPrice
        );
        payout_ = (betAmount_ * multiplierPlayer) / 1e2;
      } else {
        // the banker must have won
        betAmount_ = _chip2TokenDecimals(
          _betInfo.bankWinsInChips,
          _betInfo.decimals,
          _betInfo.tokenPrice
        );
        payout_ = (betAmount_ * multiplierBanker) / 1e2;
      }
    }
    return payout_;
  }

  function play(
    uint256 _requestId,
    Bet memory _betInfo,
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

    Hand memory playerHand_ = Hand({
      hasThirdCard: false,
      firstCard: uint8(topCards_[0]),
      secondCard: uint8(topCards_[2]),
      thirdCard: uint8(topCards_[4])
    });

    Hand memory bankerHand_ = Hand({
      hasThirdCard: false,
      firstCard: uint8(topCards_[1]),
      secondCard: uint8(topCards_[3]),
      thirdCard: uint8(topCards_[5])
    });

    // if either banker or players punto is 8 or 9, the game is over and no more cards are dealt (for either hands)
    if (_checkImmediateWinner(playerCount_ % 10, bankCount_ % 10) != BaccaratResult.UNDECIDED) {
      // game ended, either player or banker ahve 8 or 9, calculate potential payout for the game
      payout_ = _calculateWinnings(_checkWinner(playerCount_ % 10, bankCount_ % 10), _betInfo);
      emit HandFinalized(games_[_requestId].player, _requestId, playerHand_, bankerHand_);
      games_[_requestId].bankerHand = bankerHand_;
      games_[_requestId].playerHand = playerHand_;
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
      playerHand_.hasThirdCard = true;
    } else {
      // the player stands (no third card) so player has 6 or 7, check if the bank gets a third card according to the rules
      if ((bankCount_ % 10) < 6) {
        // bank punto is 1,2,3,4,5 -> bank gets third card
        unchecked {
          bankCount_ += _scaleValueToPunto(topCards_[5]);
        }
        // register that bank has gotten third card
        bankerHand_.hasThirdCard = true;
      }
      // game is over, calculate payout
      payout_ = _calculateWinnings(_checkWinner(playerCount_ % 10, bankCount_ % 10), _betInfo);
      emit HandFinalized(games_[_requestId].player, _requestId, playerHand_, bankerHand_);
      games_[_requestId].bankerHand = bankerHand_;
      games_[_requestId].playerHand = playerHand_;
      return payout_;
    }

    // note if we are here it is still possible that the player has 2 or 3 cards, the bank certainly has only 2 cards at this point

    // when bank has punto 7, no new card for banker, game ends
    // note this is a bit redundant code because this is also in the schema? but it is a good check
    if ((bankCount_ % 10) == 7) {
      bankerHand_.hasThirdCard = false;
      // emit HandFinalized(games_[_requestId].player, _requestId, playerHand_, bankerHand_);
      emit HandFinalized(games_[_requestId].player, _requestId, playerHand_, bankerHand_);

      payout_ = _calculateWinnings(_checkWinner(playerCount_ % 10, bankCount_ % 10), _betInfo);
      games_[_requestId].bankerHand = bankerHand_;
      games_[_requestId].playerHand = playerHand_;
      return payout_;
    }

    // if player has a thrid card, and the banker not yet, the bank will get a third card depending on the third drawn card of the player and the bankers total punto
    if (playerHand_.hasThirdCard && !bankerHand_.hasThirdCard) {
      // check if bank gets third card (according to the specific mapping for this stage of the hand)
      bool thirdCard_ = _doesBankerGetThirdCard(_scaleValueToPunto(topCards_[4]), bankCount_ % 10);
      if (thirdCard_) {
        // banker gets third card
        unchecked {
          bankCount_ += _scaleValueToPunto(topCards_[5]);
        }
        // register that bank has gotten third card
        bankerHand_.hasThirdCard = true;
      }
    }

    games_[_requestId].bankerHand = bankerHand_;
    games_[_requestId].playerHand = playerHand_;

    emit HandFinalized(games_[_requestId].player, _requestId, playerHand_, bankerHand_);

    // calculate how much the payout is (in tokens)
    payout_ = _calculateWinnings(_checkWinner(playerCount_ % 10, bankCount_ % 10), _betInfo);

    return payout_;
  }

  /**
   * @notice returns if the bank gets a third card
   * @param _thirdCard the third card of the player (amount of points/puntos)
   * @param _puntoBanker how much puntos the banker has with the first two cards
   * @return thirdCard_ if the bank gets a third card. true = third card, false = no third card
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

  /**
   * @notice internal function that checks if bet is allowed and does chip to token conversion
   * @param _tieWinsChips amount of chips wagered on tie
   * @param _bankWinsChips amount of chips wagered on banker win
   * @param _playerWinsChips amount of chips wagered on player win
   * @param _token address of the token wagered
   * @return betInfo_ bet info struct
   * @return wagerAmount_ amount of tokens wagered
   */
  function _checkWagerReturn(
    uint24 _tieWinsChips,
    uint24 _bankWinsChips,
    uint24 _playerWinsChips,
    address _token
  ) internal returns (Bet memory betInfo_, uint256 wagerAmount_) {
    uint256 totalWagerChips_ = uint256(_tieWinsChips + _bankWinsChips + _playerWinsChips);
    uint256 price_ = vaultManager.getPrice(_token);
    (uint256 tokenAmount_, uint256 dollarValue_) = _chip2Token(totalWagerChips_, _token, price_);
    require(dollarValue_ <= vaultManager.getMaxWager(), "Baccarat: wager is too big");
    require(dollarValue_ >= minWagerAmount, "Baccarat: Wager too low");
    betInfo_ = Bet({
      gameCompleted: false,
      tokenPrice: uint144(price_),
      totalWagerInChips: uint24(totalWagerChips_),
      tieWinsInChips: uint24(_tieWinsChips),
      bankWinsInChips: uint24(_bankWinsChips),
      playerWinsInChips: uint24(_playerWinsChips),
      decimals: uint8(_getDecimals(_token))
    });
    return (betInfo_, tokenAmount_);
  }

  /**
   * @notice main betting function for baccarat
   * @param _tieWins amount chips wagered on tie
   * @param _bankWins amount chips wagered on banker win
   * @param _playerWins amount chips wagered on player win
   * @param _token address of the token wagered
   */
  function bet(uint24 _tieWins, uint24 _bankWins, uint24 _playerWins, address _token) external {
    _bet(_tieWins, _bankWins, _playerWins, _token);
  }

  function _bet(uint24 _tieWins, uint24 _bankWins, uint24 _playerWins, address _token) internal {
    (Bet memory bet_, uint256 wagerAmout_) = _checkWagerReturn(
      _tieWins,
      _bankWins,
      _playerWins,
      _token
    );
    _create(bet_, wagerAmout_, _token);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../core/Core.sol";

abstract contract CommonSoloBaccarat is Core {
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

  event HandFinalized(address indexed player, uint256 requestId, Hand playerHand, Hand bankerHand);

  event GameRefunded(address indexed player, uint256 indexed requestId, uint256 totalRefunded);

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
    bool gameCompleted;
    uint144 tokenPrice;
    uint24 totalWagerInChips;
    uint24 tieWinsInChips;
    uint24 bankWinsInChips;
    uint24 playerWinsInChips;
    uint8 decimals;
  }

  struct BaccaratGame {
    address player;
    address token;
    uint32 startTime;
    Bet bet;
    Hand playerHand;
    Hand bankerHand;
  }

  uint32 public refundCooldown = 2 hours; // default value

  mapping(uint256 => BaccaratGame) internal games_;

  mapping(address => uint256) private decimalsOfToken;

  // minWagerAmount 1$
  uint256 public constant minWagerAmount = 1e30;

  constructor(IRandomizerRouter _router) Core(_router) {}

  function updateRefundCooldown(uint32 _refundCooldown) external onlyRole(DEFAULT_ADMIN_ROLE) {
    refundCooldown = _refundCooldown;
  }

  function games(uint256 _requestId) external view returns (BaccaratGame memory) {
    return games_[_requestId];
  }

  function refundGame(uint256 _requestId) external nonReentrant {
    BaccaratGame memory game_ = games_[_requestId];
    require(game_.player == _msgSender(), "Baccarat: Only player can request refund");
    require(!game_.bet.gameCompleted, "Baccarat: Game is completed - not refundable");
    require(
      game_.startTime + refundCooldown < block.timestamp,
      "Baccarat: Game is not refundable yet"
    );
    _refundGame(_requestId);
  }

  function refundGameByTeam(uint256 _requestId) external nonReentrant onlyTeam {
    BaccaratGame memory game_ = games_[_requestId];
    require(!game_.bet.gameCompleted, "Baccarat: Game is completed - not refundable");
    require(
      game_.startTime + refundCooldown < block.timestamp,
      "Baccarat: Game is not refundable yet"
    );
    _refundGame(_requestId);
  }

  function _refundGame(uint256 _requestId) internal {
    BaccaratGame memory _game = games_[_requestId];

    games_[_requestId].bet.gameCompleted = true;

    (uint256 _tokenAmount, ) = _chip2Token(
      _game.bet.totalWagerInChips,
      _game.token,
      _game.bet.tokenPrice
    );

    vaultManager.refund(_game.token, _tokenAmount, 0, _game.player);

    emit GameRefunded(_game.player, _requestId, _tokenAmount);
  }

  function shareEscrow(
    BaccaratGame memory _game,
    uint256 _payoutInTokens
  ) internal virtual returns (bool hasWon_, uint256 totalWager_) {
    (totalWager_, ) = _chip2Token(_game.bet.totalWagerInChips, _game.token, _game.bet.tokenPrice);

    vaultManager.setReferralReward(_game.token, _game.player, totalWager_, getHouseEdge());
    vaultManager.mintVestedWINR(_game.token, totalWager_, _game.player);

    /// @notice calculates the loss of user if its not zero transfers to Vault
    if (_payoutInTokens == 0) {
      vaultManager.payin(_game.token, totalWager_);
    } else {
      vaultManager.payout(_game.token, _game.player, totalWager_, _payoutInTokens);
    }

    /// @notice The used wager is the zero point. if the payout is above the wager, player wins
    hasWon_ = _payoutInTokens > totalWager_;

    return (hasWon_, totalWager_);
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

  function _getDecimals(address _token) internal returns (uint256 decimals_) {
    if (decimalsOfToken[_token] == 0) {
      decimalsOfToken[_token] = IERC20Metadata(_token).decimals();
      return decimalsOfToken[_token];
    } else {
      return decimalsOfToken[_token];
    }
  }

  /**
   * @notice returns the amount of tokens and the dollar value of a certain amount of chips in a game
   * @param _chips amount of chips
   * @param _token token address
   * @param _price usd price of the token (scaled 1e30)
   * @return tokenAmount_ amount of tokens that the chips are worth
   * @return dollarValue_ dollar value of the chips
   */
  function _chip2Token(
    uint256 _chips,
    address _token,
    uint256 _price
  ) internal returns (uint256 tokenAmount_, uint256 dollarValue_) {
    uint256 decimals_ = _getDecimals(_token);
    unchecked {
      tokenAmount_ = ((_chips * (10 ** (30 + decimals_)))) / _price;
      dollarValue_ = (tokenAmount_ * _price) / (10 ** decimals_);
    }
    return (tokenAmount_, dollarValue_);
  }

  /**
   *
   * @param _chips amount of chips
   * @param _decimals decimals of token
   * @param _price price of token (scaled 1e30)
   */
  function _chip2TokenDecimals(
    uint256 _chips,
    uint256 _decimals,
    uint256 _price
  ) internal pure returns (uint256 tokenAmount_) {
    unchecked {
      tokenAmount_ = ((_chips * (10 ** (30 + _decimals)))) / _price;
    }
    return tokenAmount_;
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

    require(!game_.bet.gameCompleted, "Baccarat: Game is completed");

    games_[_requestId].bet.gameCompleted = true;

    uint256 payout_ = play(_requestId, game_.bet, _randoms[0]);

    (bool hasWon_, uint256 totalWager_) = shareEscrow(game_, payout_);

    emit Settled(game_.player, _requestId, game_.token, totalWager_, hasWon_, payout_);
  }

  function _create(
    Bet memory _betInfo,
    uint256 _wagerAmount,
    address _token
  ) internal whenNotPaused nonReentrant {
    address player_ = _msgSender();

    vaultManager.escrow(_token, player_, _wagerAmount);

    uint256 requestId_ = _requestRandom(1);

    games_[requestId_] = BaccaratGame(
      player_,
      _token,
      uint32(block.timestamp),
      _betInfo,
      Hand(false, 0, 0, 0),
      Hand(false, 0, 0, 0)
    );

    emit Created(player_, requestId_, _wagerAmount, _token);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
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
                        Strings.toHexString(uint160(account), 20),
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRandomizerConsumer {
  function randomizerCallback(uint256 _requestId, uint256[] calldata _rngList) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRandomizerRouter {
  function request(uint32 count, uint256 _minConfirmations) external returns (uint256);
  function scheduledRequest(uint32 _count, uint256 targetTime) external returns (uint256);
  function response(uint256 _requestId, uint256[] calldata _rngList) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5 <0.9.0;

interface ISupraRouter { 
	function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, address _clientWalletAddress) external returns(uint256);
    function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed, address _clientWalletAddress) external returns(uint256);
}