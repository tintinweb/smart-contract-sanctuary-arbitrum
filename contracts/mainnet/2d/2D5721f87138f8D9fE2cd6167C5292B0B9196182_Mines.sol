// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./MinesBase.sol";

contract Mines is MinesBase {
  constructor(IRandomizerRouter _router) MinesBase(_router) {}

  /**
   * @dev function to set game multipliers only callable by the governance
   * @dev computes the multipliers with 2% house edge 
   * @param _numMines number of mines to set multipliers for
   */
  function setMultipliers(uint256 _numMines) external onlyGovernance {
    for (uint256 g = 1; g <= 25 - _numMines; g++) {
      uint256 multiplier = 1;
      uint256 divisor = 1;
      for (uint256 f = 0; f < g; f++) {
        multiplier *= (25 - _numMines - f);
        divisor *= (25 - f);
      }
      minesMultipliers[_numMines][g] = (9800 * (10 ** 9)) / ((multiplier * (10 ** 9)) / divisor);
    }
  }

  /**
   * @dev function to view the current mines multipliers
   * @param _numMines number of mines in the game
   * @param _numRevealed cells revealed
   */
  function getMultipliers(
    uint256 _numMines,
    uint256 _numRevealed
  ) public view returns (uint256 multiplier_) {
    multiplier_ = minesMultipliers[_numMines][_numRevealed];
  }

  /**
   * @dev get current game state of player
   * @param _player address of the player that made the bet
   * @return minesState_ current state of player game
   * @return currentPayout_ current payout if player were to end the game
   */
  function getState(
    address _player
  ) external view returns (Game memory minesState_, uint256 currentPayout_) {
    minesState_ = games[_player];
    currentPayout_ = (minesState_.currentMultiplier * minesState_.wager) / BASIS_POINTS;
    return (minesState_, currentPayout_);
  }

  /**
   * @dev Places a bet in the game.
   * @param _wager The amount of the wager.
   * @param _token The address of the token used for the wager.
   * @param _numMines The number of mines to be set in the game.
   * @param _cells An array representing the cells to reveal in the game.
   * @param _isCashout A boolean indicating whether the bet is a cashout or not.
   */
  function bet(
    uint256 _wager,
    address _token,
    uint8 _numMines,
    bool[25] calldata _cells,
    bool _isCashout
  ) external nonReentrant {
    // Ensure that the number of mines is within a valid range
    require(_numMines >= 1 && _numMines <= 24, "Mines: Invalid number of mines");

    // Retrieve the game information for the current player
    Game memory game_ = games[_msgSender()];

    // Ensure that the player is not already in a game
    require(game_.requestId == 0, "Mines: Awaiting random number");
    require(game_.numMines == 0, "Mines: Already in game");

    // Count the number of cells to reveal
    uint32 numCellsToReveal_;
    for (uint8 i = 0; i < 25; i++) {
      if (_cells[i]) {
        numCellsToReveal_++;
      }
    }

    // Get the maximum number of cells that can be revealed based on the number of mines
    uint256 minesMaxReveal_ = minesMaxReveal[_numMines];

    // Ensure that the number of cells to reveal is valid
    require(
      numCellsToReveal_ > 0 && numCellsToReveal_ <= minesMaxReveal_,
      "Mines: Invalid number of cells to reveal"
    );

    // Create a new game and get the request ID
    uint256 _requestId = _create(_numMines, _wager, _token, _isCashout, _cells);

    // Emit an event to indicate that the game has been created
    emit Created(_msgSender(), _wager, _token, _requestId, _numMines);
  }

  /**
   * @dev Ends the player's current game and receives the payout.
   * @dev This function is called by the player.
   * @dev Calls the internal _endGame function.
   */
  function endGame() external nonReentrant {
    _endGame(_msgSender());
  }

  /**
   * @dev Ends the player's current game and receives the payout.
   * @dev This function is called by the team.
   * @dev Calls the internal _endGame function.
   * @dev This function is for emergency use only. For stuck token in vault manager.
   * @param _player The address of the player to end the game for.
   */
  function endGameByTeam(address _player) external onlyTeam nonReentrant {
    Game memory game_ = games[_player];
    require(game_.startTime + endByTeamCooldown < block.timestamp, "Mines: Game not endable yet");
    _endGame(_player);
  }

  /**
   * @dev Ends the player's current game and receives the payout.
   */
  function _endGame(address _player) internal {
    // Retrieve the game information for the current player
    Game memory game_ = games[_player];

    // Ensure that the player is in a game
    require(game_.numMines > 0, "Mines: Not in game");
    require(game_.requestId == 0, "Mines: Awaiting random number");

    // Calculate the payout based on the current multiplier and wager
    uint256 multiplier_ = game_.currentMultiplier;
    uint256 wager_ = game_.wager;
    uint256 payout_ = (multiplier_ * wager_) / BASIS_POINTS;
    address token_ = game_.token;

    // Share the escrow between the player and the contract
    shareEscrow(game_, wager_, payout_);

    // Remove the player's game information
    delete (games[_player]);

    // Emit an event to indicate the end of the game and provide payout details
    emit Settled(_player, wager_, payout_, token_, multiplier_);
  }

  /**
   * @dev Reveals the specified cells in the player's current game.
   * @param _cells An array representing the cells to be revealed.
   * @param _isCashout A boolean indicating whether it is a cashout or not.
   */
  function revealCells(bool[25] calldata _cells, bool _isCashout) external nonReentrant {
    // Retrieve the game information for the current player
    Game storage game = games[_msgSender()];
    // Update the game information with the revealed cells and other details
    game.cellsPicked = _cells;
    game.isCashout = _isCashout;
    game.startTime = block.timestamp;

    // Ensure that the player is in a game
    require(game.numMines > 0, "Mines: Not in game");
    require(game.requestId == 0, "Mines: Awaiting random number");

    // Count the number of cells revealed and to be revealed
    uint32 numCellsRevealed_;
    uint32 numCellsToReveal_;
    for (uint8 i = 0; i < 25; i++) {
      if (_cells[i]) {
        // Ensure that the cell hasn't been already revealed
        require(!game.revealedCells[i], "Mines: Cell already revealed");
        numCellsToReveal_++;
      }
      if (game.revealedCells[i]) {
        numCellsRevealed_++;
      }
    }

    // Ensure that the number of cells to reveal is valid
    require(
      numCellsToReveal_ != 0 &&
        numCellsToReveal_ + numCellsRevealed_ <= minesMaxReveal[game.numMines],
      "Mines: Invalid number of cells to reveal"
    );

    // Request a random number for determining the cell outcomes
    uint256 id = _requestRandom(1);
    gameIds[id] = _msgSender();
    game.requestId = id;
  }

  function randomizerFulfill(uint256 _requestId, uint256[] calldata _randoms) internal override {
    address player_ = gameIds[_requestId];
    delete (gameIds[_requestId]);
    Game storage game_ = games[player_];

    uint256 numberOfRevealedCells_;
    for (uint32 i = 0; i < game_.cellsPicked.length; i++) {
      if (game_.revealedCells[i] == true) {
        numberOfRevealedCells_++;
      }
    }
    uint256 numberOfMinesLeft_ = game_.numMines;
    bool[25] memory mines_;
    bool won_ = true;

    for (uint32 i = 0; i < game_.cellsPicked.length; i++) {
      if (numberOfMinesLeft_ == 0 || 25 - numberOfRevealedCells_ == numberOfMinesLeft_) {
        if (game_.cellsPicked[i]) {
          game_.revealedCells[i] = true;
        }
        continue;
      }
      if (game_.cellsPicked[i]) {
        bool gem = _pickCell(
          player_,
          i,
          25 - numberOfRevealedCells_,
          numberOfMinesLeft_,
          uint256(keccak256(abi.encodePacked(_randoms[0], i)))
        );
        if (gem == false) {
          numberOfMinesLeft_--;
          mines_[i] = true;
          won_ = false;
        }
        numberOfRevealedCells_ += 1;
      }
    }

    if (!won_) {
      if (game_.isCashout == false) {
        emit Reveal(player_, game_.wager, 0, game_.token, mines_, game_.revealedCells, 0);
      } else {
        emit RevealAndCashout(player_, game_.wager, 0, game_.token, mines_, game_.revealedCells, 0);
      }
      emit Settled(player_, game_.wager, 0, game_.token, 0);
      shareEscrow(game_, game_.wager, 0);
      delete (games[player_]);

      return;
    }

    uint256 multiplier_ = minesMultipliers[numberOfMinesLeft_][numberOfRevealedCells_];
    uint256 payout_ = (multiplier_ * game_.wager) / BASIS_POINTS;

    if (game_.isCashout == false) {
      game_.currentMultiplier = uint64(multiplier_);
      game_.requestId = 0;
      emit Reveal(
        player_,
        game_.wager,
        payout_,
        game_.token,
        mines_,
        game_.revealedCells,
        multiplier_
      );
    } else {
      uint256 wager_ = game_.wager;
      address token_ = game_.token;
      emit RevealAndCashout(
        player_,
        wager_,
        payout_,
        token_,
        mines_,
        game_.revealedCells,
        multiplier_
      );
      emit Settled(player_, wager_, payout_, token_, multiplier_);
      shareEscrow(game_, wager_, payout_);

      delete (games[player_]);
    }
  }

  function _pickCell(
    address _player,
    uint256 _cellNumber,
    uint256 _numberCellsLeft,
    uint256 _numberOfMinesLeft,
    uint256 _random
  ) internal returns (bool) {
    uint256 winChance = BASIS_POINTS - (_numberOfMinesLeft * BASIS_POINTS) / _numberCellsLeft;

    bool won_ = false;
    if (_random % BASIS_POINTS <= winChance) {
      won_ = true;
    }
    games[_player].revealedCells[_cellNumber] = true;
    return won_;
  }

  /**
   * @dev function to set game max number of reveals only callable at deploy time
   * @param maxReveal max reveal for each num Mines
   */
  function setMaxReveal(uint8[24] memory maxReveal) external onlyGovernance {
    for (uint8 i = 0; i < maxReveal.length; i++) {
      minesMaxReveal[i + 1] = maxReveal[i];
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../core/Core.sol";

abstract contract MinesBase is Core {
  /*==================================================== Events =============================================================*/
   /**
     * @dev event emitted by the randomizer fulfill with the cell reveal results
     * @param playerAddress address of the player that made the bet
     * @param wager wager amount
     * @param payout payout if player were to end the game
     * @param token address of token the wager was made and payout
     * @param minesCells cells in which mines were revealed, if any is true the game is over and the player lost
     * @param revealedCells all cells that have been revealed, true correspond to a revealed cell
     * @param multiplier current game multiplier if the game player chooses to end the game
     */
    event Reveal(
        address indexed playerAddress,
        uint256 wager,
        uint256 payout,
        address token,
        bool[25] minesCells,
        bool[25] revealedCells,
        uint256 multiplier
    );

    /**
     * @dev event emitted by the randomizer fulfill with the cell reveal results and cashout
     * @param playerAddress address of the player that made the bet
     * @param wager wager amount
     * @param payout total payout transfered to the player
     * @param token address of token the wager was made and payout
     * @param minesCells cells in which mines were revealed, if any is true the game is over and the player lost
     * @param revealedCells all cells that have been revealed, true correspond to a revealed cell
     * @param multiplier current game multiplier
     */
    event RevealAndCashout(
        address indexed playerAddress,
        uint256 wager,
        uint256 payout,
        address token,
        bool[25] minesCells,
        bool[25] revealedCells,
        uint256 multiplier
    );

    /**
     * @dev event emitted by the randomizer fulfill with the bet results
     * @param playerAddress address of the player that made the bet
     * @param wager wager amount
     * @param payout total payout transfered to the player
     * @param token address of token the wager was made and payout
     * @param multiplier final game multiplier
     */
    event Settled(
        address indexed playerAddress,
        uint256 wager,
        uint256 payout,
        address token,
        uint256 multiplier
    );

    /**
     * @dev event emitted when a player makes a bet
     * @param playerAddress address of the player that made the bet
     * @param wager wager amount
     * @param token address of token the wager was made and payout
     * @param requestId random number request id of the bet
     * @param numMines number of mines in the game
     */
    event Created(
        address indexed playerAddress,
        uint256 wager,
        address token,
        uint256 requestId,
        uint8 numMines
    );


  /*==================================================== State Variables ====================================================*/

    struct Game {
        address player;
        address token;
        uint256 wager;
        uint256 requestId;
        uint256 startTime;
        uint64 currentMultiplier;
        uint8 numMines;
        bool[25] revealedCells;
        bool[25] cellsPicked;
        bool isCashout;
    }

  /// @notice house edge of game
  uint64 public houseEdge = 200; // 2%
  /// @notice cooldown duration to refund
  uint32 public refundCooldown = 2 hours; // default value

  uint32 public endByTeamCooldown = 2 hours; // default value
  /// @notice stores all games
  mapping(address => Game) public games;
  /// @notice stores all game ids
  mapping(uint256 => address) public gameIds;

  mapping(uint256 => mapping(uint256 => uint256)) minesMultipliers;
  mapping(uint8 => uint256) minesMaxReveal;

  /*==================================================== Functions ===========================================================*/

  constructor(IRandomizerRouter _router) Core(_router) {}

    /// @notice function that calculation or return a constant of house edge
  /// @return edge_ calculated house edge of game
  function getHouseEdge(Game memory) public view returns (uint64 edge_) {
    edge_ = houseEdge;
  }

  /// @notice function to update refund block count
  /// @param _refundCooldown duration to refund
  function updateRefundCooldown(uint32 _refundCooldown) external onlyGovernance {
    refundCooldown = _refundCooldown;
  }

  /// @notice function to update end game by team block count
  /// @param _endByTeamCooldown duration to end game by team
  function updateEndByTeamCooldown(uint32 _endByTeamCooldown) external onlyGovernance {
    require(_endByTeamCooldown >= refundCooldown, "Mines: End by team cooldown must be greater than refund cooldown");
    endByTeamCooldown = _endByTeamCooldown;
  }


  /// @notice function to refund uncompleted game wagers
  function refundGame() external nonReentrant{
    address player_ = _msgSender();
    Game memory game = games[player_];
    require(game.player == player_, "Mines: Only player");
    require(game.startTime + refundCooldown < block.timestamp, "Mines: Game is not refundable yet");
    _refundGame(player_);
  }

  /// @notice function to refund uncompleted game wagers by team role
  function refundGameByTeam(
    address _player
  ) external nonReentrant onlyTeam {
    Game memory game = games[_player];
    require(game.startTime + refundCooldown < block.timestamp, "Mines: Game is not refundable yet");
    _refundGame(_player);
  }

  function _refundGame(address _player) internal {
    Game memory _game = games[_player];
    require(_game.currentMultiplier == 0, "Mines: Game is only refundable if it has not passed the first round");
    vaultManager.refund(_game.token, _game.wager, 0, _player);

    delete gameIds[_game.requestId];
    delete games[_player];
  }

  /// @notice shares the amount which escrowed amount while starting the game by player
  /// @param _game player's game
  /// @param _wager wager of the game
  /// @param _payout accumulated payouts by game contract
  function shareEscrow(
    Game memory _game,
    uint256 _wager,
    uint256 _payout
  ) internal virtual returns (bool) {

    /// @notice sets referral reward if player has referee
    vaultManager.setReferralReward(_game.token, _game.player, _wager, getHouseEdge(_game));
    vaultManager.mintVestedWINR(_game.token, _wager, _game.player);
  
    /// @notice calculates the loss of user if its not zero transfers to Vault
    if (_payout == 0) {
      vaultManager.payin(_game.token, _wager);
    } else {
      vaultManager.payout(_game.token, _game.player, _wager, _payout);
    }

    /// @notice The used wager is the zero point. if the payout is above the wager, player wins
    return _payout > _wager;
  }



  /// @notice randomizer consumer triggers that function
  /// @notice manages the game variables and shares the escrowed amount
  /// @param _wager amount for a game
  /// @param _token input and output token
  function _create( uint8 _numMines, uint256 _wager, address _token, bool _isCashout, bool[25] memory _cells
  
  )
    internal
    isWagerAcceptable(_token, _wager)
    whenNotPaused
    returns(uint256)
  {
    address player_ = _msgSender();
    uint256 requestId_ = _requestRandom(1);
    /// @notice escrows total wager to Vault Manager
    vaultManager.escrow(_token, player_, _wager);

    Game storage game = games[player_];

    game.player = player_;
    game.token = _token;
    game.wager = _wager;
    game.requestId = requestId_;
    game.startTime = block.timestamp;
    game.numMines = _numMines;
    game.cellsPicked = _cells;
    game.isCashout = _isCashout;

    gameIds[requestId_] = player_;
    return requestId_;
   
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

  modifier isWagersAcceptable(address _token, uint256[] calldata _wagers) {
    uint256 dollarValue_;
    uint256 maxWager_ = vaultManager.getMaxWager();
    uint256 minWager_ = vaultManager.getMinWager(address(this));
    uint256 wager_;

    for (uint8 i = 0; i < _wagers.length; ++i) {
      dollarValue_ = _computeDollarValue(_token, _wagers[i]);
      require(dollarValue_ >= minWager_, "GAME: Wager too low");
      require(dollarValue_ <= maxWager_, "GAME: Wager too high");
    }

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

  function randomizerCallback(uint256 _requestId, uint256[] calldata _rngList) external onlyRandomizer {
    randomizerFulfill(_requestId, _rngList);
  }

  function _requestRandom(uint8 _count) internal returns (uint256 requestId_) {
    requestId_ = randomizerRouter.request(_count, minConfirmations);
  }

  function _requestScheduledRandom(uint8 _count, uint256 targetTime) internal returns (uint256 requestId_) {
    requestId_ = randomizerRouter.scheduledRequest(_count, targetTime);
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
pragma solidity >=0.8.5 <0.9.0;

interface ISupraRouter { 
	function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, address _clientWalletAddress) external returns(uint256);
    function generateRequest(string memory _functionSig, uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed, address _clientWalletAddress) external returns(uint256);
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