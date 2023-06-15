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
    // Chips won by individual players
    uint256[] winnerChips;
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
    // Theme id of the current board
    uint256 themeId;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IUtility.sol";
import "../pokerEvaluator/IPokerEvaluator.sol";
import "../Types.sol";
import "../shuffle/IShuffle.sol";

contract Utility is IUtility {
    // Poker evaluatoras contract
    IPokerEvaluator public pokerEvaluator;
    // ZK shuffle contract
    IShuffle public shuffle;
    // Invalid player index
    uint8 public constant INVALID_PLAYER_INDEX = 255;
    // High score that cannot be reached (i.e., 2**32-1)
    uint32 public constant UNREACHABLE_HIGH_SCORE = 4294967295;

    constructor(address pokerEvaluator_, address shuffle_) {
        require(
            pokerEvaluator_ != address(0) && shuffle_ != address(0),
            "empty address"
        );
        pokerEvaluator = IPokerEvaluator(pokerEvaluator_);
        shuffle = IShuffle(shuffle_);
    }

    // Checks if a player at `stage` can bet if this player has `folded`.
    function canBet(GameStage stage, bool folded) external pure {
        require(
            (stage == GameStage.PreFlopBet ||
                stage == GameStage.FlopBet ||
                stage == GameStage.TurnBet ||
                stage == GameStage.RiverBet) && !folded,
            "cannot bet"
        );
    }

    // Gets the index of the first non-folded player.
    function getFirstNonFoldedPlayerIndex(
        bool[] memory folded
    ) external pure returns (uint8) {
        for (uint8 i = 0; i < folded.length; ++i) {
            if (!folded[i]) {
                return i;
            }
        }
        return INVALID_PLAYER_INDEX;
    }

    // For deal stages, checks if `playerIdx` should deal the `cardIdx` cards in `stage`, if there are `numPlayers` in the game.
    function validCardIndex(
        uint8[] calldata cardIdx,
        GameStage stage,
        uint8 numPlayers,
        uint8 playerIdx
    ) external pure {
        if (stage == GameStage.PreFlopReveal) {
            require(
                cardIdx.length == 2 * numPlayers - 2,
                "Invalid length of card index"
            );
            for (uint256 i = 0; i < 2 * numPlayers; i++) {
                if (i < 2 * playerIdx) {
                    require(
                        cardIdx[i] == i,
                        "Dealing unexpected card index in PreFlopReveal"
                    );
                } else if (i > 2 * playerIdx + 1) {
                    require(
                        cardIdx[i - 2] == i,
                        "Dealing unexpected card index in PreFlopReveal"
                    );
                }
            }
        } else if (stage == GameStage.FlopReveal) {
            require(cardIdx.length == 3, "Invalid length of card index");
            require(
                (cardIdx[0] == 2 * numPlayers) &&
                    (cardIdx[1] == 2 * numPlayers + 1) &&
                    (cardIdx[2] == 2 * numPlayers + 2),
                "Dealing unexpected card index in FlopReveal"
            );
        } else if (stage == GameStage.TurnReveal) {
            require(cardIdx.length == 1, "Invalid length of card index");
            require(
                cardIdx[0] == 2 * numPlayers + 3,
                "Dealing unexpected card index in TurnReveal"
            );
        } else if (stage == GameStage.RiverReveal) {
            require(cardIdx.length == 1, "Invalid length of card index");
            require(
                cardIdx[0] == 2 * numPlayers + 4,
                "Dealing unexpected card index in RiverReveal"
            );
        } else if (stage == GameStage.PostRound) {
            require(cardIdx.length == 2, "Invalid length of card index");
            require(
                (cardIdx[0] == 2 * playerIdx) &&
                    (cardIdx[1] == 2 * playerIdx + 1),
                "Dealing unexpected card index in RiverReveal"
            );
        } else {
            revert("Not in deal phase");
        }
    }

    // When dealing all remaining cards, checks if card index matches expectedIndices[0:numUndealtCards].
    function checkCardIndexIfDealingAllRemainingCards(
        uint8[] calldata cardIdx,
        uint8[] calldata expectedIndices,
        uint8 numUndealtCards
    ) external pure {
        require(
            cardIdx.length == numUndealtCards,
            "Invalid number of cards when dealing all remaining cards"
        );
        for (uint8 i = 0; i < numUndealtCards; i++) {
            require(
                cardIdx[i] == expectedIndices[i],
                "Dealing unexpected card index when dealing all remaining cards"
            );
        }
    }

    // Evaluates `scores` for `numPlayers` in `boardId` game considering whether each player has `folded`.
    function evaluateScores(
        uint256 boardId,
        bool[] memory folded,
        uint8 numPlayers
    ) external view virtual returns (uint256[] memory scores) {
        scores = new uint256[](numPlayers);
        uint8[] memory cardIndices = new uint8[](7);
        for (uint8 i = 0; i < 5; i++) {
            cardIndices[i] = numPlayers * 2 + i;
        }
        for (uint8 i = 0; i < numPlayers; i++) {
            if (folded[i]) {
                scores[i] = UNREACHABLE_HIGH_SCORE;
            } else {
                cardIndices[5] = 2 * i;
                cardIndices[6] = 2 * i + 1;
                scores[i] = pokerEvaluator.evaluate(
                    shuffle.getCardValues(boardId, cardIndices)
                );
            }
        }
    }
}