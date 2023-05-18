/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

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


// State of the game
enum State {
    Registration,
    ShufflingDeck,
    DealingCard
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


// The main game logic contract
contract BoardManager is Ownable {
    event DeckShuffled(address indexed player, uint256 indexed boardId);

    // Maps board id to a single board data
    mapping(uint256 => Board) public boards;

    // Mapping from permanent account to player index
    mapping(address => uint8) playerIndex;

    // The mapping of game id => current state of the card game
    mapping(uint256 => State) public states;


    // The mapping of game id => index of the current player to take action
    mapping(uint256 => uint8) public playerIndexes;

    // The mapping of game id => Number of players
    mapping(uint256 => uint8) public numPlayers;

    // Shuffle records of all game id and player index. The mapping of game id => (playerIndex => Deck)
    mapping(uint256 => mapping(uint256 => Deck)) decks;

    function shuffleDeck(
        uint256[52] calldata shuffledX0,
        uint256[52] calldata shuffledX1,
        uint256[2] calldata selector,
        uint256 gameId,
        address permanentAccount
    ) external {
        updateDeck(shuffledX0, shuffledX1, selector, gameId);
        playerIndexes[gameId] += 1;
        if (playerIndexes[gameId] == numPlayers[gameId]) {
            states[gameId] = State.DealingCard;
            playerIndexes[gameId] = 0;
        }
        emit DeckShuffled(permanentAccount, gameId);
    }

    // Gets board with `boardId`. This is a workaround to provide a getter since
    // we cannot export dynamic mappings.
    function getBoard(uint256 boardId) external view returns (Board memory) {
        return boards[boardId];
    }


    // Updates deck with the shuffled deck.
    // TODO: storing 1 uint256 costs ~20k gas. But in previous version, it costs only ~10k gas.
    function updateDeck(
        uint256[52] memory shuffledX0,
        uint256[52] memory shuffledX1,
        uint256[2] memory selector,
        uint256 gameId
    ) internal {
        uint8 playerIdx = playerIndexes[gameId];
        for (uint8 i = 0; i < 52; i++) {
            decks[gameId][playerIdx].X0[i] = shuffledX0[i];
            decks[gameId][playerIdx].X1[i] = shuffledX1[i];
        }
        decks[gameId][playerIdx].Selector[0] = selector[0];
        decks[gameId][playerIdx].Selector[1] = selector[1];
        decks[gameId][playerIdx].timestamp = block.timestamp;
    }

}