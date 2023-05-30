// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Types.sol";
import "./IBoardManager.sol";
import "./shuffle/IShuffle.sol";
import "./account/IAccountManager.sol";
import "./chip/ChipManager.sol";
import "./utility/IUtility.sol";

// The main game logic contract
contract BoardManager is Ownable, IBoardManager {
    // Maps board id to a single board data
    mapping(uint256 => Board) public boards;
    // Mapping from permanent account to player index
    mapping(address => uint8) playerIndex;
    // ZK shuffle contract
    IShuffle public shuffle;
    // Account manager
    IAccountManager public accountManager;
    // Chip manager
    IChipManager public chipManager;
    // Utility contract
    IUtility public utility;
    // Minimal number of players in a game.
    uint8 public constant MIN_PLAYERS = 2;
    uint8 public constant MAX_PLAYERS = 6;
    // Whether collecting vig or not
    bool collectVig = false;

    // Checks if `boardId` is in the specified game `stage`.
    modifier ensureValidStage(uint256 boardId, GameStage stage) {
        require(stage == boards[boardId].stage, "Invalid game stage");
        _;
    }

    constructor(
        address shuffle_,
        address accountManager_,
        address utility_,
        address chipManager_
    ) {
        require(
            shuffle_ != address(0) &&
                accountManager_ != address(0) &&
                utility_ != address(0) &&
                chipManager_ != address(0),
            "empty address"
        );
        shuffle = IShuffle(shuffle_);
        accountManager = IAccountManager(accountManager_);
        utility = IUtility(utility_);
        chipManager = IChipManager(chipManager_);
    }

    // Gets the player index and permanent account of `msg.sender`.
    // Note: This checks that `msg.sender` is in `boardId` game.
    function getPlayerInfo(
        uint256 boardId
    ) public view returns (uint8, address) {
        address permanentAccount = accountManager.getPermanentAccount(
            msg.sender
        );
        require(
            accountManager.getCurGameId(permanentAccount) == boardId,
            "Player is not in a game"
        );
        return (playerIndex[permanentAccount], permanentAccount);
    }

    // Gets the player index and permanent account of `msg.sender`.
    // Note: This checks that `msg.sender` is in `boardId` game and
    // `msg.sender` should take action.
    function getPlayerInfoChecked(
        uint256 boardId
    ) internal view returns (uint8, address) {
        (uint8 index, address permanentAccount) = getPlayerInfo(boardId);
        require(index == boards[boardId].nextPlayer, "Not your turn");
        return (index, permanentAccount);
    }

    // Creates a board when starting a new game. Returns the newly created board id.
    function createBoard(uint8 numPlayers, uint256 bigBlindSize) external {
        uint256 boardId = accountManager.generateGameId();
        require(GameStage.Uncreated == boards[boardId].stage, "game created");
        require(
            numPlayers >= MIN_PLAYERS && numPlayers <= MAX_PLAYERS,
            "Invalid number of players"
        );
        boards[boardId].stage = GameStage.GatheringPlayers;
        boards[boardId].numPlayers = numPlayers;
        boards[boardId].numUnfoldedPlayers = numPlayers;
        shuffle.setGameSettings(numPlayers, boardId);
        chipManager.setGameSetting(boardId, bigBlindSize, numPlayers);
        emit BoardCreated(
            accountManager.getPermanentAccount(msg.sender),
            boardId
        );
    }

    // Joins the `boardId` board with the public key `pk`, the `ephemeralAccount` that `msg.sender`
    // wants to authorize, and `buyIn` amount of chips.
    // Reverts when a) user has joined; b) board players reach the limit.
    function join(
        uint256[2] calldata pk,
        address ephemeralAccount,
        uint256 buyIn,
        uint256 boardId
    ) public payable ensureValidStage(boardId, GameStage.GatheringPlayers) {
        boards[boardId].permanentAccounts.push(msg.sender);
        boards[boardId].folded.push(false);
        boards[boardId].hasAllIn.push(false);
        // Assuming number of players in a game will never exceed 2**8 = 256
        uint8 playerCount = uint8(boards[boardId].permanentAccounts.length);
        shuffle.register(msg.sender, pk, boardId);
        accountManager.join(msg.sender, boardId, buyIn);
        accountManager.authorize(msg.sender, ephemeralAccount);
        chipManager.setBuyIn(boardId, buyIn);
        require(
            payable(ephemeralAccount).send(msg.value),
            "send ether to ephemeral account failed"
        );
        playerIndex[msg.sender] = playerCount - 1;
        if (playerCount == boards[boardId].numPlayers) {
            boards[boardId].stage = GameStage.Shuffle;
            boards[boardId].dealer = playerCount - 1;
            chipManager.registerPlayers(
                boardId,
                boards[boardId].permanentAccounts
            );
        }
        emit JoinedBoard(msg.sender, boardId);
    }

    // Calls for `msg.sender` in `boardId` game.
    function call(uint256 boardId) external {
        (uint8 index, ) = getPlayerInfoChecked(boardId);
        GameStage stage = boards[boardId].stage;
        utility.canBet(stage, boards[boardId].folded[index]);
        chipManager.call(boardId, index, stage);
        moveToNextPlayer(boardId);
    }

    // Checks for `msg.sender` in `boardId` game.
    function check(uint256 boardId) external {
        (uint8 index, ) = getPlayerInfoChecked(boardId);
        GameStage stage = boards[boardId].stage;
        utility.canBet(stage, boards[boardId].folded[index]);
        chipManager.check(boardId, index, stage);
        moveToNextPlayer(boardId);
    }

    // Raises `amount` by `msg.sender` for `boardId` game.
    // Note: Suppose player A has bet 100 before and want to bet 300 instead, the amount
    //     would be 200.
    function raise(uint256 amount, uint256 boardId) external {
        (uint8 index, ) = getPlayerInfoChecked(boardId);
        GameStage stage = boards[boardId].stage;
        utility.canBet(stage, boards[boardId].folded[index]);
        chipManager.raise(boardId, amount, index, boards[boardId].stage);
        moveToNextPlayer(boardId);
    }

    // Folds and deals remaining cards so that `msg.sender` could safely leave the game.
    // Note: Use `memory` to compile (i.e., reducing local variables).
    function fold(
        uint256 boardId,
        uint8[] memory cardIdx,
        uint256[8][] memory proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta
    ) external {
        (uint8 index, address permanentAccount) = getPlayerInfoChecked(boardId);
        GameStage stage = boards[boardId].stage;
        utility.canBet(stage, boards[boardId].folded[index]);
        chipManager.fold(boardId, index, stage);
        boards[boardId].folded[index] = true;
        boards[boardId].numUnfoldedPlayers -= 1;
        dealAllRemainingCards(
            boardId,
            index,
            cardIdx,
            proof,
            decryptedCard,
            initDelta
        );
        accountManager.settleSinglePlayer(
            boardId,
            permanentAccount,
            chipManager.getChipSinglePlayer(boardId, index),
            collectVig,
            true
        );
        if (boards[boardId].numUnfoldedPlayers == 1) {
            uint8 winnerIndex = utility.getFirstNonFoldedPlayerIndex(
                boards[boardId].folded
            );
            accountManager.settleSinglePlayer(
                boardId,
                boards[boardId].permanentAccounts[winnerIndex],
                chipManager.getPotSize(boardId) +
                    chipManager.getChipSinglePlayer(boardId, winnerIndex),
                collectVig,
                true
            );
            boards[boardId].stage = GameStage.Ended;
            return;
        }
        moveToNextPlayer(boardId);
    }

    // All-Ins and deals remaining cards so that `msg.sender` do not need to take further actions.
    // Note: Use `memory` to compile (i.e., reducing local variables).
    function allIn(
        uint256 boardId,
        uint8[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta
    ) external {
        (uint8 index, ) = getPlayerInfoChecked(boardId);
        GameStage stage = boards[boardId].stage;
        utility.canBet(stage, boards[boardId].folded[index]);
        chipManager.allIn(boardId, index, boards[boardId].stage);
        boards[boardId].hasAllIn[index] = true;
        dealAllRemainingCards(
            boardId,
            index,
            cardIdx,
            proof,
            decryptedCard,
            initDelta
        );
        moveToNextPlayer(boardId);
    }

    // Deals all remaining cards for `msg.sender` in `boardId` game.
    function dealAllRemainingCards(
        uint256 boardId,
        uint8 playerIdx,
        uint8[] memory cardIdx,
        uint256[8][] memory proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta
    ) internal {
        (uint8[] memory indices, uint8 numUndealtCards) = shuffle
            .getUndealtCardIndices(
                boardId,
                playerIdx,
                2 * boards[boardId].numPlayers + 5
            );
        utility.checkCardIndexIfDealingAllRemainingCards(
            cardIdx,
            indices,
            numUndealtCards
        );
        shuffle.dealBatch(
            boards[boardId].permanentAccounts[playerIdx],
            playerIdx,
            cardIdx,
            proof,
            decryptedCard,
            initDelta,
            boardId,
            false
        );
    }

    // Shuffles the deck without submitting the proof.
    function shuffleDeck(
        uint256[52] calldata shuffledX0,
        uint256[52] calldata shuffledX1,
        uint256[2] calldata selector,
        uint256 boardId
    ) external ensureValidStage(boardId, GameStage.Shuffle) {
        (, address permanentAccount) = getPlayerInfoChecked(boardId);
        shuffle.shuffleDeck(
            permanentAccount,
            shuffledX0,
            shuffledX1,
            selector,
            boardId
        );
        emit DeckShuffled(permanentAccount, boardId);
        moveToNextPlayer(boardId);
    }

    // Submits the proof for shuffling the deck.
    function shuffleProof(uint256[8] calldata proof, uint256 boardId) external {
        (uint8 index, ) = getPlayerInfo(boardId);
        shuffle.shuffleProof(proof, boardId, index);
    }

    // Deals multiple cards.
    function deal(
        uint8[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] calldata decryptedCard,
        uint256[2][] calldata initDelta,
        uint256 boardId
    ) external {
        (uint8 playerIdx, address permanentAccount) = getPlayerInfoChecked(
            boardId
        );
        require(boards[boardId].nextPlayer == playerIdx, "Not your turn");
        GameStage stage = boards[boardId].stage;
        utility.validCardIndex(
            cardIdx,
            stage,
            boards[boardId].numPlayers,
            playerIdx
        );
        shuffle.dealBatch(
            permanentAccount,
            playerIdx,
            cardIdx,
            proof,
            decryptedCard,
            initDelta,
            boardId,
            stage == GameStage.PostRound
        );
        emit BatchDecryptProofProvided(
            permanentAccount,
            cardIdx.length,
            boardId
        );
        moveToNextPlayer(boardId);
    }

    // Gets board and chip with `boardId`.
    function getGameInfo(
        uint256 boardId
    ) external view returns (Board memory, Chip memory) {
        return (boards[boardId], chipManager.getChip(boardId));
    }

    // Moves the `boardId` game to the next player.
    function moveToNextPlayer(uint256 boardId) internal {
        if (boards[boardId].stage == GameStage.PreFlopBet) {
            if (boards[boardId].nextPlayer == 1) {
                boards[boardId].allExpressed = true;
            }
        } else {
            if (boards[boardId].nextPlayer == boards[boardId].dealer) {
                boards[boardId].allExpressed = true;
            }
        }
        if (boards[boardId].allExpressed) {
            if (!chipManager.getSomeoneHasBet(boardId)) {
                moveToTheNextStage(boardId);
                return;
            }
            if (chipManager.isEveryoneOnTheSameBet(boardId)) {
                moveToTheNextStage(boardId);
                return;
            }
        }
        uint8 nextPlayerIndex = (boards[boardId].nextPlayer + 1) %
            boards[boardId].numPlayers;
        boards[boardId].nextPlayer = nextPlayerIndex;
        emit NextPlayer(nextPlayerIndex, boardId);
        if (
            (boards[boardId].folded[nextPlayerIndex]) ||
            (boards[boardId].hasAllIn[nextPlayerIndex] &&
                boards[boardId].stage != GameStage.PostRound)
        ) {
            moveToNextPlayer(boardId);
        }
    }

    // Moves the `boardId` game to the next stage.
    function moveToTheNextStage(uint256 boardId) internal {
        boards[boardId].allExpressed = false;
        uint256 nextStage = uint256(boards[boardId].stage) + 1;
        require(nextStage <= uint256(GameStage.Ended), "game already ended");
        boards[boardId].stage = GameStage(nextStage);
        emit GameStageChanged(GameStage(nextStage), boardId);
        chipManager.setNewRound(boardId);
        if (GameStage(nextStage) == GameStage.Ended) {
            settleWinner(boardId);
        } else if (GameStage(nextStage) == GameStage.PreFlopBet) {
            uint8 nextPlayerIndex = (boards[boardId].dealer + 3) %
                boards[boardId].numPlayers;
            boards[boardId].nextPlayer = nextPlayerIndex;
            emit NextPlayer(nextPlayerIndex, boardId);
            chipManager.initialBet(boardId);
        } else {
            uint8 nextPlayerIndex = utility.getFirstNonFoldedPlayerIndex(
                boards[boardId].folded
            );
            boards[boardId].nextPlayer = nextPlayerIndex;
            emit NextPlayer(nextPlayerIndex, boardId);
            if (
                boards[boardId].hasAllIn[nextPlayerIndex] &&
                boards[boardId].stage != GameStage.PostRound
            ) {
                moveToNextPlayer(boardId);
            }
        }
    }

    // Settles winners for `boardId` game.
    function settleWinner(uint256 boardId) internal {
        accountManager.settle(
            boardId,
            boards[boardId].permanentAccounts,
            chipManager.settle(
                boardId,
                utility.evaluateScores(
                    boardId,
                    boards[boardId].folded,
                    boards[boardId].numPlayers
                )
            ),
            collectVig,
            true
        );
    }

    // Challenges the proof from `playerIdx` in `boardId` game. `isShuffle` indicates
    // whether challenging shuffle or deal which further specifies `cardIdx` card.
    function challenge(
        uint256 boardId,
        uint8 playerIdx,
        uint8 cardIdx,
        bool isShuffle
    ) external {
        address challenger = accountManager.getPermanentAccount(msg.sender);
        address challenged = boards[boardId].permanentAccounts[playerIdx];
        if (isShuffle) {
            try shuffle.verifyShuffle(boardId, playerIdx) {} catch (
                bytes memory
            ) {
                accountManager.punish(
                    boardId,
                    challenged,
                    challenger,
                    boards[boardId].permanentAccounts
                );
                boards[boardId].stage = GameStage.Ended;
            }
        } else {
            try shuffle.verifyDeal(boardId, playerIdx, cardIdx) {} catch (
                bytes memory
            ) {
                accountManager.punish(
                    boardId,
                    challenged,
                    challenger,
                    boards[boardId].permanentAccounts
                );
                boards[boardId].stage = GameStage.Ended;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./Types.sol";

interface IBoardManager {
    // ========================== Events ==========================
    // TODO: Add doc
    event EvaluatorSet(address indexed evaluator);
    // TODO: Add doc
    event ShuffleSet(address indexed shuffle);
    event BoardCreated(address indexed creator, uint256 indexed boardId);
    event JoinedBoard(address indexed player, uint256 indexed boardId);
    event NextPlayer(uint8 indexed playerIndex, uint256 indexed boardId);
    event GameStageChanged(GameStage indexed stage, uint256 indexed boardId);
    event DeckShuffled(address indexed player, uint256 indexed boardId);
    event DecryptProofProvided(
        address indexed sender,
        uint8 indexed cardIndex,
        uint256 indexed boardId
    );
    event BatchDecryptProofProvided(
        address indexed sender,
        uint256 indexed cardCount,
        uint256 indexed boardId
    );

    // Creates a board when starting a new game. Returns the newly created board id.
    function createBoard(uint8 numPlayers, uint256 bigBlindSize) external;

    // Joins the `boardId` board with the public key `pk`, the `ephemeralAccount` that `msg.sender`
    // wants to authorize, and `buyIn` amount of chips.
    // Reverts when a) user has joined; b) board players reach the limit.
    function join(
        uint256[2] calldata pk,
        address ephemeralAccount,
        uint256 buyIn,
        uint256 boardId
    ) external payable;

    // Calls for `msg.sender` in `boardId` game.
    function call(uint256 boardId) external;

    // Checks for `msg.sender` in `boardId` game.
    function check(uint256 boardId) external;

    // Raises `amount` by `msg.sender` for `boardId` game.
    // Note: Suppose player A has bet 100 before and want to bet 300 instead, the amount
    //     would be 200.
    function raise(uint256 amount, uint256 boardId) external;

    // Folds and deals remaining cards so that `msg.sender` could safely leave the game.
    function fold(
        uint256 boardId,
        uint8[] memory cardIdx,
        uint256[8][] memory proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta
    ) external;

    // All-Ins and deals remaining cards so that `msg.sender` do not need to take further actions.
    function allIn(
        uint256 boardId,
        uint8[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] memory decryptedCard,
        uint256[2][] memory initDelta
    ) external;

    // Shuffles the deck without submitting the proof.
    function shuffleDeck(
        uint256[52] calldata shuffledX0,
        uint256[52] calldata shuffledX1,
        uint256[2] calldata selector,
        uint256 boardId
    ) external;

    // Submits the proof for shuffling the deck.
    function shuffleProof(uint256[8] calldata proof, uint256 boardId) external;

    // Deals multiple cards.
    // #Note: `memory` is used to avoid `CompilerError: Stack too deep`
    function deal(
        uint8[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] calldata decryptedCard,
        uint256[2][] calldata initDelta,
        uint256 boardId
    ) external;

    // Challenges the proof from `playerIdx` in `boardId` game. `isShuffle` indicates
    // whether challenging shuffle or deal which further specifies `cardIdx` card.
    function challenge(
        uint256 boardId,
        uint8 playerIdx,
        uint8 cardIdx,
        bool isShuffle
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

// Bet types, unknown type means actions not performed yet
enum BetType {
    Unknown,
    Call,
    Fold,
    Raise,
    Check,
    AllIn
}

// Game stage
enum GameStage {
    Uncreated,
    GatheringPlayers,
    Shuffle,
    PreFlopReveal, // in pre-flop, every gets 2 cards, and everyone must provide proofs
    PreFlopBet,
    FlopReveal, // in flop, everyone must provide proofs for community cards
    FlopBet,
    TurnReveal, // need reveal
    TurnBet,
    RiverReveal, // need reveal
    RiverBet,
    PostRound, // waiting to announce winner
    Ended
}

// Card rank
enum Rank {
    Spades,
    Hearts,
    Diamonds,
    Clubs
}

// Board state
struct Board {
    // Current game stage
    GameStage stage;
    // Permanent accounts of all players
    address[] permanentAccounts;
    // Index of the next player to play
    uint8 nextPlayer;
    // Dealer index
    uint8 dealer;
    // Required number of players to play
    uint8 numPlayers;
    // Number of players that has not folded
    uint8 numUnfoldedPlayers;
    // Whether i-th player has folded
    bool[] folded;
    // Whether i-th player has all-in
    bool[] hasAllIn;
    // Whether all players have expressed opinion at least once
    bool allExpressed;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

// Withhold information for a player and a specific game with `gameId`
struct Withhold {
    // Game Id
    uint256 gameId;
    // Time stamp after which the withheld chips is repaid to the player
    uint256 maturityTime;
    // Amount of chips under withhold
    uint256 amount;
}

// Account information for each permanent account.
struct Account {
    // Ephemeral account for in-game operations
    address ephemeralAccount;
    // Amount of chips owned by this account
    uint256 chipEquity;
    // Current game ID (1,2,...) if in game; Set to 0 if Not-In-Game.
    uint256 gameId;
    // An array of withheld chips
    Withhold[] withholds;
}

interface IAccountManager {
    // `Challenged` is punished in `boardId` since `chanlleger` successfully challenged.
    event Punished(
        address indexed challenged,
        address indexed challenger,
        uint256 boardId
    );

    // Event that `permanentAccount` has received settlement funds of `amount` in `gameId`, considering whether `collectVigor` and receiving fund immediately (i.e., `removeDelay`).
    event Settled(
        address indexed permanentAccount,
        uint256 indexed gameId,
        uint256 indexed amount,
        bool collectVigor,
        bool removeDelay
    );

    // Generate a new game id.
    function generateGameId() external returns (uint256);

    // Joins a game with `gameId`, `buyIn`, and `isNewGame` on whether joining a new game or an existing game.
    //
    // # Note
    //
    // We prohibit players to join arbitrary game with `gameId`. We allow registered game contract to specify
    // `gameId` to resolve issues such as player collusion.
    function join(address player, uint256 gameId, uint256 buyIn) external;

    // Exchange ratio where `chipEquity` = `ratio` * `token`
    function ratio() external view returns (uint256);

    // ERC20 Token type to swap with `chipEquity`
    function token() external view returns (address);

    // Deposits ERC20 tokens for chips.
    function deposit(uint256 tokenAmount) external payable;

    // Authorizes `ephemeralAccount` for `permanentAccount` by a registered contract.
    function authorize(
        address permanentAccount,
        address ephemeralAccount
    ) external;

    // Checks if `permanentAccount` has authorized `ephemeralAccount`.
    function hasAuthorized(
        address permanentAccount,
        address ephemeralAccount
    ) external returns (bool);

    // Gets the largest game id which have been created.
    function getLargestGameId() external view returns (uint256);

    // Gets the current game id of `player`.
    function getCurGameId(address player) external view returns (uint256);

    // Returns the corresponding permanent account by ephemeral account
    function accountMapping(address ephemeral) external view returns (address);

    // Returns `account` if it has not been registered as an ephemeral account;
    // otherwise returns the corresponding permanent account.
    function getPermanentAccount(
        address account
    ) external view returns (address);

    // Gets the amount of chip equity.
    function getChipEquityAmount(
        address player
    ) external view returns (uint256);

    // Batch get the chip amounts of players
    function getChipEquityAmounts(
        address[] calldata players
    ) external view returns (uint256[] memory chips);

    // Punishes `challenged` player by moving all his chips to `challenger`.
    // For other players, simply returns chips.
    function punish(
        uint256 boardId,
        address challenged,
        address challenger,
        address[] memory permanentAccounts
    ) external;

    // Settles all players by iterating through `settle` on each player.
    function settle(
        uint256 gameId,
        address[] memory permanentAccount,
        uint256[] memory amount,
        bool collectVigor,
        bool removeDelay
    ) external;

    // Settles chips for `permanentAccount` and `gameId` by returning nearly `amount` (after `collectVigor`) chips to the player.
    // Chips are immediately repaid to `chipEquity` if `removeDelay`.
    function settleSinglePlayer(
        uint256 gameId,
        address permanentAccount,
        uint256 amount,
        bool collectVigor,
        bool removeDelay
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IChipManager.sol";
import "../Types.sol";

// Chip manager for buy-in into specific games.
contract ChipManager is Ownable, IChipManager {
    // Minimum big blind size
    uint256 public immutable MIN_BIG_BLIND_SIZE = 10;
    // Multipliers of buy-in size according to big blind
    uint256 public minBuyInMultiplier = 100;
    uint256 public maxBuyInMultiplier = 500;
    // Maximal number of players in a game
    uint256 public constant MAX_PLAYERS = 6;
    // Mapping from board id to chips
    mapping(uint256 => Chip) chips;
    // Address of game contract
    address gameContract;

    modifier onlyGameContract() {
        require(gameContract == msg.sender, "Caller is not game contract");
        _;
    }

    constructor(uint256 minBuyInMultiplier_, uint256 maxBuyInMultiplier_) {
        setBuyInMultipliers(minBuyInMultiplier_, maxBuyInMultiplier_);
    }

    // Sets buy-in multipliers.
    function setBuyInMultipliers(uint256 min, uint256 max) public onlyOwner {
        require(min < max && min > 0, "invalid buyin multipliers");
        minBuyInMultiplier = min;
        maxBuyInMultiplier = max;
    }

    // Sets game contract.
    function setGameContract(address gameContract_) external onlyOwner {
        gameContract = gameContract_;
    }

    // Sets game settings for `boardId` and specifying the big blind size.
    function setGameSetting(
        uint256 boardId,
        uint256 bigBlindSize,
        uint256 numPlayers
    ) external onlyGameContract {
        require(
            bigBlindSize >= MIN_BIG_BLIND_SIZE,
            "big blind size should be greater than 10"
        );
        chips[boardId].betsEachRound = new uint256[][](13);
        chips[boardId].betTypeEachRound = new BetType[][](13);
        for (uint256 i = 0; i < 13; i++) {
            chips[boardId].betsEachRound[i] = new uint256[](numPlayers);
            chips[boardId].betTypeEachRound[i] = new BetType[](numPlayers);
        }
        chips[boardId].bigBlindSize = bigBlindSize;
    }

    // Registers all `players` in `boardId`.
    function registerPlayers(
        uint256 boardId,
        address[] calldata players
    ) external onlyGameContract {
        require(
            players.length == chips[boardId].betsEachRound[0].length,
            "Invalid number of players"
        );
        chips[boardId].players = players;
    }

    // Bets for small blind and big blind.
    function initialBet(uint256 boardId) external onlyGameContract {
        uint256 bigBlindSize = chips[boardId].bigBlindSize;
        bet(boardId, bigBlindSize / 2, 0, BetType.Raise, GameStage.PreFlopBet);
        bet(boardId, bigBlindSize, 1, BetType.Raise, GameStage.PreFlopBet);
        chips[boardId].someoneHasBet = true;
    }

    // Sets the `buyIn` chips for `boardId`.
    function setBuyIn(
        uint256 boardId,
        uint256 buyIn
    ) external onlyGameContract {
        uint256 bb = chips[boardId].bigBlindSize;
        require(
            buyIn >= bb * minBuyInMultiplier &&
                buyIn <= bb * maxBuyInMultiplier,
            "Invalid buy-in size"
        );
        chips[boardId].bets.push(0);
        chips[boardId].chips.push(buyIn);
    }

    // Checks by `playerIndex` for `boardId` game in `stage`.
    function check(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        require(
            chips[boardId].bets[playerIndex] == chips[boardId].highestBet,
            "Cannot check since your bets is less than other players' bets"
        );
        bet(boardId, 0, playerIndex, BetType.Check, stage);
    }

    // Folds by `playerIndex` for `boardId` game in `stage`.
    function fold(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        bet(boardId, 0, playerIndex, BetType.Fold, stage);
        chips[boardId].foldRecord |= (uint8(1) << playerIndex);
    }

    // Raises `amount` by `playerIndex` for `boardId` game in `stage`.
    // Note: Suppose player A has bet 100 before and want to bet 300 instead, the amount
    //     would be 200.
    function raise(
        uint256 boardId,
        uint256 amount,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        require(
            amount >= getMinRaise(boardId, playerIndex),
            "cannot raise due to invalid amount"
        );
        require(
            chips[boardId].chips[playerIndex] >= amount,
            "cannot raise due to insufficient chips"
        );
        bet(boardId, amount, playerIndex, BetType.Raise, stage);
    }

    // Calls by `playerIndex` for `boardId` game in `stage`.
    function call(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        uint256 amount = chips[boardId].highestBet -
            chips[boardId].bets[playerIndex];
        require(amount > 0, "should check instead of call");
        require(
            chips[boardId].chips[playerIndex] >= amount,
            "cannot call due to insufficient chips"
        );
        bet(boardId, amount, playerIndex, BetType.Call, stage);
    }

    // All in by `playerIndex` for `boardId` game in `stage`.
    function allIn(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external onlyGameContract {
        chips[boardId].allInRecord = (chips[boardId].allInRecord |
            (uint8(1) << playerIndex));
        bet(
            boardId,
            chips[boardId].chips[playerIndex],
            playerIndex,
            BetType.AllIn,
            stage
        );
    }

    // Gets the minimal raise amount of `index`-th player in `boardId` game following rules:
    // a) need to match highest bet, i.e., bet (chips[boardId].highestBet - chips[boardId].bets[index])
    // b) at least additionally raise max(bigBlind, chips[boardId].lastRaise - chips[boardId].raiseBeforeLastRaise)
    function getMinRaise(
        uint256 boardId,
        uint8 index
    ) public view returns (uint256) {
        uint256 delta = chips[boardId].lastRaise -
            chips[boardId].raiseBeforeLastRaise;
        uint256 bb = chips[boardId].bigBlindSize;
        return
            (delta >= bb ? delta : bb) +
            chips[boardId].highestBet -
            chips[boardId].bets[index];
    }

    // Bets `amount` and `betType` of `playerIndex` for `boardId` game in `stage`.
    // Note: Suppose player A has bet 100 before and want to bet 300 instead, the amount
    //     would be 200.
    function bet(
        uint256 boardId,
        uint256 amount,
        uint8 playerIndex,
        BetType betType,
        GameStage stage
    ) internal {
        uint256 stageId = uint256(stage);
        chips[boardId].betTypeEachRound[stageId][playerIndex] = betType;
        if (amount != 0) {
            chips[boardId].chips[playerIndex] -= amount;
            uint256 newBetAmount = chips[boardId].bets[playerIndex] + amount;
            chips[boardId].bets[playerIndex] = newBetAmount;
            uint256 highestBet = chips[boardId].highestBet;
            chips[boardId].highestBet = newBetAmount > highestBet
                ? newBetAmount
                : highestBet;
            chips[boardId].potSize += amount;
            chips[boardId].betsEachRound[stageId][playerIndex] += amount;
        }
        if (betType == BetType.Raise) {
            uint256 lastRaise = chips[boardId].lastRaise;
            chips[boardId].raiseBeforeLastRaise = lastRaise;
            chips[boardId].lastRaise = chips[boardId].bets[playerIndex];
        }
        if (betType == BetType.Raise || betType == BetType.AllIn) {
            chips[boardId].someoneHasBet = true;
        }
        emit Bet(
            boardId,
            chips[boardId].players[playerIndex],
            amount,
            betType,
            stage
        );
    }

    // Gets chips[boardId].someoneHasBet.
    function getSomeoneHasBet(uint256 boardId) external view returns (bool) {
        return chips[boardId].someoneHasBet;
    }

    // Checks if every player has the same bet.
    function isEveryoneOnTheSameBet(
        uint256 boardId
    ) external view returns (bool) {
        uint256 highestBet = chips[boardId].highestBet;
        uint8 allInRecord = chips[boardId].allInRecord;
        uint8 foldRecord = chips[boardId].foldRecord;
        for (uint256 i = 0; i < chips[boardId].bets.length; i++) {
            if (
                ((allInRecord >> i) & 1) == 0 &&
                ((foldRecord >> i) & 1) == 0 &&
                chips[boardId].bets[i] != highestBet
            ) {
                return false;
            }
        }
        return true;
    }

    // Sets new round for `boardId`.
    function setNewRound(uint256 boardId) external onlyGameContract {
        chips[boardId].lastRaise = chips[boardId].highestBet;
        chips[boardId].raiseBeforeLastRaise = chips[boardId].highestBet;
        chips[boardId].someoneHasBet = false;
    }

    // Given `bets` and `scores` of each player, this function computes the order of players
    // according to the following rules:
    // 1. all players are sorted according to their scores in descending orders.
    // 2. for players with the same score, they are sorted according to their bets in ascending orders.
    // Assumption: `bets` and `scores` match the order of `chips[boardId].players`.
    // Note: this function makes in-place updates to `bets` and `scores` such that their order matches
    // `indices`. In other words, (indices[i], bets[i], scores[i]) matches for the i-th player.
    function getSettleOrder(
        uint256[] memory bets,
        uint256[] memory scores
    )
        internal
        pure
        returns (
            uint8[] memory indices,
            uint8[] memory groupCount,
            uint256[] memory sortedBets
        )
    {
        uint8 length = uint8(scores.length);
        indices = new uint8[](length);
        groupCount = new uint8[](length);
        uint8 i;
        for (i = 0; i < length; i++) {
            indices[i] = i;
        }
        sort(scores, indices, 0, length, true);
        sortedBets = reorder(bets, indices);
        i = 0;
        uint8 j = 1;
        uint256 curBet;
        uint8 numGroup = 0;
        while (i < length) {
            curBet = sortedBets[i];
            while (j < length) {
                if (scores[j] != scores[i]) {
                    break;
                }
                j++;
            }
            sort(sortedBets, indices, i, j, true);
            groupCount[numGroup] = j - i;
            i = j;
            j++;
            numGroup++;
        }
    }

    // Gets the settlement amount of players with indices between [start, end), assuming these
    // players have the same score. The rules are:
    // 1. For the i-th player, i \in [start, end):
    //    case-I: if bets[i] * (end-i) < potSize:
    //      a) compute totalSidePotForThisRound = getSidePotSingleRound(...)
    //      a) compute partialSidePot = totalSidePotForThisRound / (end-i);
    //      b) gives each player in [i, end) bets[i]+partialSidePot chips
    //      c) deducts each player's (i.e., in [i, end)) bet by bets[i], and update
    //          potSize -= (bets[i]*(end-i) + totalSidePotForThisRound).
    //
    //    case-II: if bets[i] * (end-i) >= potSize:
    //      a) gives each player potSize/(end-i) chips. The i-th player can get additionally
    //          potSize - potSize/(end-i)*(end-i) chips
    //      b) deducts each player's bet by postSize/(end-i)
    //      c) update postSize = 0.
    // 2. If potSize > 0, continue with (i+1)-th player with step2.
    // 3. Return updated potSize.
    // Note: order of `amounts` is the same as `chips[boardId].players`, which is different from
    //      `indices` and `bets` that is sorted by `getSettleOrder`.
    function getSettleAmountSameScore(
        uint256 potSize,
        uint256[] memory bets,
        uint256[] memory amounts,
        uint8[] memory indices,
        uint8 start,
        uint8 end
    ) internal pure returns (uint256) {
        for (uint8 i = start; i < end; i++) {
            uint256 betI = bets[i];
            if (betI * (end - i) <= potSize) {
                uint256 totalSidePotForThisRound = getSidePotSingleRound(
                    bets,
                    betI,
                    end
                );
                increaseSettlementAmount(
                    amounts,
                    betI,
                    totalSidePotForThisRound,
                    indices,
                    i,
                    end
                );
                decreaseRemainingBets(bets, betI, i, end);
                potSize -= (betI * (end - i) + totalSidePotForThisRound);
            } else {
                uint256 remainingAmount = potSize / (end - i);
                increaseSettlementAmount(
                    amounts,
                    remainingAmount,
                    0,
                    indices,
                    i,
                    end
                );
                decreaseRemainingBets(bets, remainingAmount, i, end);
                amounts[i] += (potSize - remainingAmount * (end - i));
                return 0;
            }
        }
        return potSize;
    }

    // Computes parts of the side pot for `getSettleAmountSameScore`. When settle amount for a group of
    // players with the same scores, they will also get chips from players with worse scores. This function
    // helps to compute the amount of these chips as `partialSidePot`. In particular, suppose a player i with better score has `baseBet`.
    // From a player j with worse score, we can get either `baseBet` if he/she has more than `baseBet` bets; or
    // `bets[j]` if he/she has less than `baseBet` bets.
    // Note: `bets` is in-place updated.
    function getSidePotSingleRound(
        uint256[] memory bets,
        uint256 baseBet,
        uint8 start
    ) internal pure returns (uint256) {
        uint8 numPlayers = uint8(bets.length);
        uint256 partialSidePot = 0;
        for (uint8 j = start; j < numPlayers; j++) {
            if (bets[j] > baseBet) {
                partialSidePot += baseBet;
                bets[j] -= baseBet;
            } else {
                partialSidePot += bets[j];
                bets[j] = 0;
            }
        }
        return partialSidePot;
    }

    // Gets the settlement amount of each player, given `bets`, `indices` and `groupCount` from `getSettleOrder`.
    function getSettleAmount(
        uint256 potSize,
        uint256[] memory bets,
        uint8[] memory indices,
        uint8[] memory groupCount
    ) internal pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](bets.length);
        uint8 start = 0;
        uint8 end;
        for (uint8 i = 0; i < groupCount.length; i++) {
            if (groupCount[i] == 0) {
                require(
                    potSize == 0,
                    "Should never happen that group count is zero but potSize is non-zero"
                );
                break;
            }
            end = start + groupCount[i];
            potSize = getSettleAmountSameScore(
                potSize,
                bets,
                amounts,
                indices,
                start,
                end
            );
            if (potSize == 0) {
                break;
            }
            start = end;
        }
        return amounts;
    }

    // Gets the settlement amount of each player in `boardId` game according to `scores` of each player.
    // Note1: `scores` match the order of `chips[boardId].players`
    // Note2: `amount` includes both winning/losses and the remaining buy-ins.
    function settle(
        uint256 boardId,
        uint256[] memory scores
    ) external view returns (uint256[] memory) {
        uint256[] memory bets = chips[boardId].bets;
        (
            uint8[] memory indices,
            uint8[] memory groupCount,
            uint256[] memory sortedBets
        ) = getSettleOrder(bets, scores);
        uint256[] memory amounts = getSettleAmount(
            chips[boardId].potSize,
            sortedBets,
            indices,
            groupCount
        );
        for (uint8 i = 0; i < amounts.length; i++) {
            amounts[i] += chips[boardId].chips[i];
        }
        return amounts;
    }

    // Updates the `amounts` by `increaseAmount` for index i \in [start, end).
    // Note: The order of `amounts` follows `chips[boardId].players` and [start, end) refers to `indices`.
    function increaseSettlementAmount(
        uint256[] memory amounts,
        uint256 increaseAmount,
        uint256 totalSidePotAmount,
        uint8[] memory indices,
        uint8 start,
        uint8 end
    ) internal pure {
        uint256 partialSidePot = totalSidePotAmount / (end - start);
        uint256 totalAmount = increaseAmount + partialSidePot;
        for (uint8 i = start; i < end; i++) {
            amounts[indices[i]] += totalAmount;
        }
        amounts[indices[start]] += (totalSidePotAmount -
            partialSidePot *
            (end - start));
    }

    // Updates the `bets` by `increaseAmount` for index i \in [start, end).
    function decreaseRemainingBets(
        uint256[] memory bets,
        uint256 amount,
        uint8 start,
        uint8 end
    ) internal pure {
        for (uint8 i = start; i < end; i++) {
            bets[i] -= amount;
        }
    }

    // Swaps data[i] and data[j].
    function swapUint256(
        uint256[] memory data,
        uint8 i,
        uint8 j
    ) internal pure {
        uint256 tmp = data[i];
        data[i] = data[j];
        data[j] = tmp;
    }

    // Swaps data[i] and data[j].
    function swapUint8(uint8[] memory data, uint8 i, uint8 j) internal pure {
        uint8 tmp = data[i];
        data[i] = data[j];
        data[j] = tmp;
    }

    // Sorts `data` between [`start`, `end`) index according to `ascending` order;
    // Updates `indices` corresponding to the order of `data`.
    function sort(
        uint256[] memory data,
        uint8[] memory indices,
        uint8 start,
        uint8 end,
        bool ascending
    ) internal pure {
        uint8 largestDataIndex;
        for (uint8 i = start; i < end; i++) {
            largestDataIndex = i;
            for (uint8 j = i + 1; j < end; j++) {
                if (data[j] > data[largestDataIndex]) {
                    largestDataIndex = j;
                }
            }
            if (i != largestDataIndex) {
                swapUint256(data, i, largestDataIndex);
                swapUint8(indices, i, largestDataIndex);
            }
        }
        if (ascending) {
            uint8 i = start;
            uint8 j = end - 1;
            while (i < j) {
                swapUint256(data, i, j);
                swapUint8(indices, i, j);
                i++;
                j--;
            }
        }
    }

    // Reorders `data` according to `indices`.
    function reorder(
        uint256[] memory data,
        uint8[] memory indices
    ) internal pure returns (uint256[] memory) {
        uint256[] memory reorderedData = new uint256[](data.length);
        for (uint8 i = 0; i < data.length; i++) {
            reorderedData[i] = data[indices[i]];
        }
        return reorderedData;
    }

    // Gets the pot size of `boardId` game.
    function getPotSize(uint256 boardId) external view returns (uint256) {
        return chips[boardId].potSize;
    }

    // Gets the chip of `boardId` game.
    function getChip(uint256 boardId) external view returns (Chip memory) {
        return chips[boardId];
    }

    // Gets the chips not bet yet for the `playerIdx`-th player in `boardId` game.
    function getChipSinglePlayer(
        uint256 boardId,
        uint8 playerIdx
    ) external view returns (uint256) {
        return chips[boardId].chips[playerIdx];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../Types.sol";

// Chip State
struct Chip {
    // Addresses of players
    address[] players;
    // Chips not betted yet for each player
    uint256[] chips;
    // Bet Chips from each player
    uint256[] bets;
    // Highest bet over all players (i.e., max(bets[0], ..., bets[numPlayers]))
    uint256 highestBet;
    // Total chips in pot
    uint256 potSize;
    // Bets of each round for each player
    uint256[][] betsEachRound;
    // Amount of last raise in the current betting round
    // Example: Suppose A first raised 100 and then B raised to 200, the lastRaise is 200.
    uint256 lastRaise;
    // Amount of the raise before last raise in the current betting round
    // Example: Suppose A first raised 100 and then B raised to 200, the raiseBeforeLastRaise is 100.
    uint256 raiseBeforeLastRaise;
    // Big blind size
    uint256 bigBlindSize;
    // Bet types of each round for each player
    BetType[][] betTypeEachRound;
    // Whether some players have bet in the current round
    bool someoneHasBet;
    // Encoding of boolean values on whether a player has all in.
    // For example, ((allInRecord >> i) & 1) indicates whether i-th player has all-in.
    uint8 allInRecord;
    // Encoding of boolean values on whether a player has folded.
    // For example, ((foldRecord >> i) & 1) indicates whether i-th player has folded.
    uint8 foldRecord;
}

interface IChipManager {
    // Emits bet event when a player `raise`, `fold`, `call`, or `check`.
    event Bet(
        uint256 boardId,
        address indexed player,
        uint256 indexed amount,
        BetType indexed betType,
        GameStage stage
    );

    // Sets game settings for `boardId` and specifying the big blind size.
    function setGameSetting(
        uint256 boardId,
        uint256 bigBlindSize,
        uint256 numPlayers
    ) external;

    // Sets new round for `boardId`.
    function setNewRound(uint256 boardId) external;

    // Registers all `players` in `boardId`.
    function registerPlayers(
        uint256 boardId,
        address[] calldata players
    ) external;

    // Bets for small blind and big blind.
    function initialBet(uint256 boardId) external;

    // Sets the `buyIn` chips for `boardId`.
    function setBuyIn(uint256 boardId, uint256 buyIn) external;

    // Calls by `playerIndex` for `boardId` game in `stage`.
    function call(uint256 boardId, uint8 playerIndex, GameStage stage) external;

    // Checks by `playerIndex` for `boardId` game in `stage`.
    function check(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external;

    // Raises `amount` by `playerIndex` for `boardId` game in `stage`.
    function raise(
        uint256 boardId,
        uint256 amount,
        uint8 playerIndex,
        GameStage stage
    ) external;

    // Folds by `playerIndex` for `boardId` game in `stage`.
    function fold(uint256 boardId, uint8 playerIndex, GameStage stage) external;

    function allIn(
        uint256 boardId,
        uint8 playerIndex,
        GameStage stage
    ) external;

    // Gets chips[boardId].someoneHasBet.
    function getSomeoneHasBet(uint256 boardId) external view returns (bool);

    // Checks if every player has the same bet.
    function isEveryoneOnTheSameBet(
        uint256 boardId
    ) external view returns (bool);

    // Gets the settlement amount of each player in `boardId` game according to `scores` of each player.
    function settle(
        uint256 boardId,
        uint256[] memory scores
    ) external view returns (uint256[] memory);

    // Gets the pot size of `boardId` game.
    function getPotSize(uint256 boardId) external view returns (uint256);

    // Gets the chip of `boardId` game.
    function getChip(uint256 boardId) external view returns (Chip memory);

    // Gets the chips not bet yet for the `playerIdx`-th player in `boardId` game.
    function getChipSinglePlayer(
        uint256 boardId,
        uint8 playerIdx
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

interface IPokerEvaluator {
    // return the point of a hand
    function evaluate(uint8[] calldata cards) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

interface IShuffleEncryptVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[215] memory input
    ) external view;
}

interface IDecryptVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) external view;
}

// Deck of cards
struct Deck {
    // x0 of 52 cards
    uint256[52] X0;
    // x1 of 52 cards
    uint256[52] X1;
    // 2 selectors for recovering y coordinates
    uint256[2] Selector;
    // proof
    uint256[8] Proof;
    // timestamp when receiving X0, X1, and Selector
    uint256 timestamp;
}

// Cards in dealing assuming at most 9 players.
struct CardDeal {
    uint256[52] X0;
    uint256[52] Y0;
    uint256[10][52] X1;
    uint256[10][52] Y1;
    uint256[8][9][52] proof;
    uint8[9][52] prevPlayerIdx;
    // Record which player has decrypted individual cards
    // Warning: Support at most 8 players
    uint8[52] record;
    // Index of the last player who dealed a card
    uint8[52] curPlayerIdx;
}

// Player information
struct PlayerInfo {
    // Address of each player. Length should match `numPlayer`.
    address[] playerAddr;
    // Public key of each player
    uint256[] playerPk;
    // An aggregated public key for all players
    uint256[2] aggregatedPk;
    // Nonce
    uint256 nonce;
}

// State of the game
enum State {
    Registration,
    ShufflingDeck,
    DealingCard
}

interface IShuffle {
    // A constant indicating the card is not found in the deck
    function INVALID_CARD_INDEX() external view returns (uint8);

    // A constant indicating the player is not found in the deck
    function UNREACHABLE_PLAYER_INDEX() external view returns (uint8);

    // Set the game settings of the game of `gameId`
    function setGameSettings(uint8 numPlayers_, uint256 gameId) external;

    // Registers a player with the `permanentAccount`, public key `pk`, and `gameId`.
    function register(
        address permanentAccount,
        uint256[2] memory pk,
        uint256 gameId
    ) external;

    // Returns the aggregated public key for all players.
    function queryAggregatedPk(
        uint256 gameId
    ) external view returns (uint256[2] memory);

    // Queries deck.
    function queryDeck(
        uint256 gameId,
        uint8 playerIdx
    ) external view returns (Deck memory);

    // Queries the `index`-th card from the deck.
    function queryCardFromDeck(
        uint8 index,
        uint256 gameId
    ) external view returns (uint256[4] memory card);

    // Queries the `index`-th card in deal.
    function queryCardInDeal(
        uint8 index,
        uint256 gameId
    ) external view returns (uint256[4] memory card);

    // Queries card deal records.
    function queryCardDealRecord(
        uint8 index,
        uint256 gameId
    ) external view returns (uint8);

    // Shuffles the deck for `permanentAccount`.
    function shuffleDeck(
        address permanentAccount,
        uint256[52] memory shuffledX0,
        uint256[52] memory shuffledX1,
        uint256[2] memory selector,
        uint256 gameId
    ) external;

    // Updates the shuffle `proof` for `gameId` and `playerIdx`.
    function shuffleProof(
        uint256[8] calldata proof,
        uint256 gameId,
        uint8 playerIdx
    ) external;

    // Deals a batch of cards.
    function dealBatch(
        address permanentAccount,
        uint8 curPlayerIdx,
        uint8[] calldata cardIdx,
        uint256[8][] calldata proof,
        uint256[2][] calldata decryptedCard,
        uint256[2][] calldata initDelta,
        uint256 gameId,
        bool shouldVerifyDeal
    ) external;

    // Searches the value of the `cardIndex`-th card in the `gameId`-th game.
    function search(
        uint8 cardIndex,
        uint256 gameId
    ) external view returns (uint8);

    // Verifies proof for the deal for `cardIdx` card from `playerIdx` in `gameId` game.
    // Returns true for succeed, false for invalid request, and revert for not passing verification.
    function verifyDeal(
        uint256 gameId,
        uint8 playerIdx,
        uint8 cardIdx
    ) external view returns (bool);

    // Verifies proof for `gameId` and `playerIdx`.
    // Returns true for succeed, false for invalid request, and revert for not passing verification.
    function verifyShuffle(
        uint256 gameId,
        uint8 playerIdx
    ) external view returns (bool);

    // Gets the number of undealt cards and their indices for `playerIdx` in `gameId` game.
    // `numCardsToDeal` is the number of cards to be dealt in a game.
    // For example, numCardsToDeal = 5 + 2*numPlayers in Texas Holdem.
    function getUndealtCardIndices(
        uint256 gameId,
        uint8 playerIdx,
        uint8 numCardsToDeal
    ) external view returns (uint8[] memory indices, uint8 numUndealtCards);

    // Gets card values `cardIndices` in `gameId` game.
    function getCardValues(
        uint256 gameId,
        uint8[] memory cardIndices
    ) external view returns (uint8[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../pokerEvaluator/IPokerEvaluator.sol";
import "../Types.sol";
import "../shuffle/IShuffle.sol";

interface IUtility {
    // Checks if a player at `stage` can bet if this player has `folded`.
    function canBet(GameStage stage, bool folded) external pure;

    // Gets the index of the first non-folded player.
    function getFirstNonFoldedPlayerIndex(
        bool[] memory folded
    ) external pure returns (uint8);

    // Checks if `playerIdx` should deal the `cardIdx` cards in `stage`, if there are `numPlayers` in the game.
    function validCardIndex(
        uint8[] calldata cardIdx,
        GameStage stage,
        uint8 numPlayers,
        uint8 playerIdx
    ) external pure;

    // When dealing all remaining cards, checks if card index matches expectedIndices[0:numUndealtCards].
    function checkCardIndexIfDealingAllRemainingCards(
        uint8[] calldata cardIdx,
        uint8[] calldata expectedIndices,
        uint8 numUndealtCards
    ) external pure;

    // Evaluates `scores` for `numPlayers` in `boardId` game considering whether each player has `folded`.
    function evaluateScores(
        uint256 boardId,
        bool[] memory folded,
        uint8 numPlayers
    ) external view returns (uint256[] memory scores);
}