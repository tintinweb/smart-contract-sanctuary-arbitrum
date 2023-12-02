// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../../core/CoreLight.sol";
import "./IWINRPoker.sol";
import "./HelperPoker.sol";

// import "forge-std/Test.sol";

/**
 * @title WINRPoker
 * @author balding-ghost
 * @notice casino holdem game see https://en.wikipedia.org/wiki/Casino_hold_%27em
 */
contract WINRPoker is IWINRPoker, CoreLight {
    uint256 public gameIndex;

    uint64 public constant houseEdge = 98;

    uint256 public constant minWagerAmount = 1e17;

    /**
     * Deck
     *    2 = 2, 14 = Ace, 13 = King
     *    100 = Heart
     *    200 = Diamond
     *    300 = Club
     *    400 = Spade
     *
     *    114 = Ace of Heart, 113 = King of Heart, 102 = 2 of Heart
     *    214 = Ace of Diamond, 213 = King of Diamond, 208 = 8 of Diamond
     *
     *  note that the 2 of heart is 102, not 2, there is no 1 because we use 14 for ace
     *  etc
     *
     *  Card deck stored in packed uint16[9] drawnCards
     *     0 = Player Card 1
     *     1 = Player Card 2
     *     2 = Dealer Card 1
     *     3 = Dealer Card 2
     *     4 = Common Card 1
     *     5 = Common Card 2
     *     6 = Common Card 3
     *     7 = Common Card 4
     *     8 = Common Card 5
     *
     *
     *  Game rules
     *  The game is played with a standard 52 card deck.
     * Each player makes an Ante bet and may make an optional AA bonus side bet.
     * The player and dealer are both dealt two cards (face down).
     * Three cards are then dealt to the board and will eventually contain five cards.
     * After checking his/her cards, the player has to decide (a) to fold with no further play losing the Ante bet or (b) to make a Call bet of double the Ante bet.
     * If one or more players makes a Call bet the dealer will deal two more cards to the board, for a total of five.
     * Players and dealer make their best five card poker hand from their own two personal cards and five board cards.
     * Each player’s hand are compared with the dealer’s.
     * The dealer must have a pair of 4s or better to qualify.
     * If the dealer does not qualify, the Ante bet pays according to the AnteWin pay table and the Call bet is a push (stand off).
     * If the dealer qualifies, and the player's hand is better than the dealer's, the Ante bet pays according to the Ante-Win pay table and the Call bet pays 1 to 1.
     * If the dealer qualifies, and the dealer's hand is equal to the player's, all bets are push (it doesn't win or lose).
     * If the dealer qualifies, and the dealer's hand is better than the player's, the player loses all bets
     *
     *   This pay table typically pays a royal flush 100 to 1, straight flush 20 to 1, four of a kind 10 to 1, full house 3 to 1, flush 2 to 1, and straight or less the standard 1 to 1.
     *
     *
     * All payouts require that delear qualifies
     *      enum Combination {
     *     NONE, // 0 -> 0 (non qualify)
     *     HIGH_CARD, // 1 (non qualify / 0)
     *     PAIR, // 2 -> 1 (if dealer qualifies)
     *     TWO_PAIR, // 3 -> 1
     *     THREE_OF_A_KIND, // 4 -> 1
     *     STRAIGHT, // 5 -> 1
     *     FLUSH, // 6 -> 2
     *     FULL_HOUSE, // 7 -> 3
     *     FOUR_OF_A_KIND, // 8 -> 10
     *     STRAIGHT_FLUSH, // 9 -> 20
     *     ROYAL_FLUSH // 10 -> 100
     * }
     */

    // gameIndex => Game struct
    mapping(uint256 => Game) public games;

    // uint16[9] drawnCards; // P=Player, D=Dealer, C=Common [P,P,D,D,C,C,C,C,C]
    mapping(uint256 => uint16[9]) internal gameHands_;

    // requestId => gameIndex
    mapping(uint256 => uint256) internal requestIdToGameIndex;

    // gameIndex => Hand of dealer
    mapping(uint256 => Hand) public dealerHands;

    // gameIndex => Hand of player
    mapping(uint256 => Hand) public playerHands;

    // payouts table for each combination (enum value => payout multiplier) 1:1 is ante is doubled
    mapping(uint256 => uint256) public payoutsPerCombination;

    uint32 public refundCooldown = 2 hours; // default value

    constructor(IRandomizerRouter _router) CoreLight(_router) {
        payoutsPerCombination[uint256(Combination.NONE)] = 0;
        payoutsPerCombination[uint256(Combination.HIGH_CARD)] = 0;
        payoutsPerCombination[uint256(Combination.PAIR)] = 1;
        payoutsPerCombination[uint256(Combination.TWO_PAIR)] = 1;
        payoutsPerCombination[uint256(Combination.THREE_OF_A_KIND)] = 1;
        payoutsPerCombination[uint256(Combination.STRAIGHT)] = 1;
        payoutsPerCombination[uint256(Combination.FLUSH)] = 2;
        payoutsPerCombination[uint256(Combination.FULL_HOUSE)] = 3;
        payoutsPerCombination[uint256(Combination.FOUR_OF_A_KIND)] = 10;
        payoutsPerCombination[uint256(Combination.STRAIGHT_FLUSH)] = 20;
        payoutsPerCombination[uint256(Combination.ROYAL_FLUSH)] = 100;
    }

    function randomizerFulfill(uint256 _requestId, uint256[] calldata _randoms) internal override {
        uint256 _gameIndex = requestIdToGameIndex[_requestId]; // Get the game index associated with the requestId

        require(_gameIndex < gameIndex, "WINRPoker: Invalid game index");

        Game memory game_ = games[_gameIndex]; // Get the game struct

        if (game_.state == State.AWAITING_DEAL) {
            // game is awaiting deal

            uint16[9] memory drawnCards_ = HelperPoker.drawInitialCards(_randoms[0]); // Draw the cards
            gameHands_[_gameIndex] = drawnCards_; // Set the drawn cards

            // game_.drawnCards = drawnCards_; // Set the drawn cards
            game_.state = State.DEALT; // Set the state to dealt

            games[_gameIndex] = game_; // Update the game

            emit GameDealt(_gameIndex, drawnCards_);
        } else if (game_.state == State.CALLED) {
            uint16[9] memory drawnCards_ = HelperPoker.dealRemainingCards(_randoms[0], gameHands_[_gameIndex]); // Draw the cards
            gameHands_[_gameIndex] = drawnCards_; // Set the drawn cards
            // Hand memory playerHand_ = HelperPoker.findCombinationPlayer(drawnCards_); // Find the player's combination
            Hand memory playerHand_ = HelperPoker.findCombinationPlayer(drawnCards_); // Find the player's combination
            Hand memory dealerHand_ = HelperPoker.findCombinationDealer(drawnCards_); // Find the dealer's combination
            Result result_ = HelperPoker.determineWinner(dealerHand_, playerHand_); // Find the result

            uint256 payout_;

            // todo figure out the payout here
            if (result_ == Result.DEALER_WINS) {
                // dealer wins, payin and return
                vaultManager.payin(game_.wagerAsset, game_.ante);
            } else if (result_ == Result.PLAYER_WINS) {
                // player wins, payin and return
                payout_ = game_.ante * payoutsPerCombination[uint256(playerHand_.combination)];
                vaultManager.payout(game_.wagerAsset, game_.player, game_.ante, payout_);
            } else if (result_ == Result.DEALER_NOT_QUALIFIED) {
                // dealer not qualified, payin and return
                // return ante
                payout_ = game_.ante;
                // vaultManager.payin(game_.wagerAsset, payout_);
                vaultManager.payback(game_.wagerAsset, game_.player, payout_);
            } else if (result_ == Result.PUSH) {
                // push, payin and return
                // return ante
                payout_ = game_.ante;
                // vaultManager.payin(game_.wagerAsset, game_.ante);
                payout_ = game_.ante;
                vaultManager.payback(game_.wagerAsset, game_.player, payout_);
            } else {
                // invalid result, impossible state
                revert("xWINRPoker: Invalid result");
            }

            dealerHands[_gameIndex] = dealerHand_; // Set the dealer's hand

            playerHands[_gameIndex] = playerHand_; // Set the player's hand

            // game_.drawnCards = drawnCards_; // Set the drawn cards
            // game_.playerHand = playerHand_; // Set the player's hand
            // game_.dealerHand = dealerHand_; // Set the dealer's hand
            // game_.result = result_; // Set the result

            game_.result = result_; // Set the result
            game_.state = State.RESOLVED; // Set the state to resolved
            games[_gameIndex] = game_; // Update the game

            emit GameResolved(_gameIndex, drawnCards_, result_, payout_);
        } else {
            revert("WINRPoker: Invalid state");
        }
    }

    function _checkWagerReturn(uint256 _betChipAmount, address _token) internal view returns (uint256) {
        uint256 price_ = vaultManager.getPrice(_token);
        (uint256 tokenAmount_, uint256 dollarValue_) = HelperPoker.chip2Token(_betChipAmount, _token, price_);
        require(dollarValue_ <= vaultManager.getMaxWager(), "Blackjack: wager is too big");
        require(dollarValue_ >= minWagerAmount, "Blackjack: Wager too low");
        return tokenAmount_;
    }

    function bet(uint256 _betChipAmount, address _wagerAsset)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 gameIndex_)
    {
        gameIndex_ = gameIndex;

        Game memory game_ = games[gameIndex_];

        game_.player = msg.sender;

        uint256 _wagerAmount = _checkWagerReturn(_betChipAmount, _wagerAsset);
        game_.ante = uint128(_wagerAmount);
        game_.wagerAsset = _wagerAsset;
        game_.state = State.AWAITING_DEAL;
        game_.timestampLatest = uint32(block.timestamp);

        games[gameIndex_] = game_;

        gameIndex++;

        uint256 requestId_ = _requestRandom(1);

        vaultManager.escrow(_wagerAsset, msg.sender, _wagerAmount);

        requestIdToGameIndex[requestId_] = gameIndex_;

        emit GameCreated(gameIndex_, msg.sender, _wagerAmount, _wagerAsset);

        return gameIndex_;
    }

    function decide(uint256 _gameIndex, bool _fold) external nonReentrant whenNotPaused {
        Game memory game_ = games[_gameIndex];

        require(game_.player == msg.sender, "WINRPoker: Not player");

        game_.timestampLatest = uint32(block.timestamp);

        // only allow player to decide if game state is dealt
        require(game_.state == State.DEALT, "WINRPoker: Game not dealt");

        if (_fold) {
            game_.state = State.FOLD;

            games[_gameIndex] = game_;

            // payin the ante, the player has folded, the dealer/house wins
            vaultManager.payin(game_.wagerAsset, game_.ante);

            emit GameResolved(_gameIndex, gameHands_[_gameIndex], IWINRPoker.Result.PLAYER_LOSES_FOLD, 0);
        } else {
            game_.state = State.CALLED;

            // get the additional wager
            uint256 extraWager_ = uint256(game_.ante);

            // double the ante
            game_.ante *= 2;

            // set the game state to called
            games[_gameIndex] = game_;

            // escrow the additional wager
            vaultManager.escrow(game_.wagerAsset, msg.sender, extraWager_);

            uint256 requestId_ = _requestRandom(1);

            // note this overwrites the previous requestId, but we don't need it anymore
            requestIdToGameIndex[requestId_] = _gameIndex;

            emit PlayerCalled(_gameIndex, requestId_, game_.ante);
        }
    }

    // CONFIGURATION FUNCTIONS

    function refundGame(uint256 _gameIndex) external nonReentrant {
        Game memory game_ = games[_gameIndex];

        require(game_.player == msg.sender, "WINRPoker: Not player");

        // check if state is not NONE
        require(game_.state != State.NONE, "WINRPoker: Game is not started yet");

        // check if state is not DEALT
        require(game_.state != State.DEALT, "WINRPoker: Game is already dealt"); // it is the players choice to fold or call no timeout

        // check if state is not REFUNDED
        require(game_.state != State.REFUNDED, "WINRPoker: Game is already refunded");

        game_.state = State.REFUNDED;

        games[_gameIndex] = game_;

        require(game_.timestampLatest + refundCooldown < block.timestamp, "WINRPoker: Game is not refundable yet");

        _refundGame(_gameIndex);
    }

    function refundGameByTeam(uint256 _gameIndex) external nonReentrant onlyOwner {
        Game memory game_ = games[_gameIndex];

        // check if the game can be refunded
        require(game_.timestampLatest + refundCooldown < block.timestamp, "WINRPoker: Game is not refundable yet");

        // check if state is not NONE
        require(game_.state != State.NONE, "WINRPoker: Game is not started yet");

        // check if state is not refunded
        require(game_.state != State.REFUNDED, "WINRPoker: Game is already refunded");

        game_.state = State.REFUNDED;

        games[_gameIndex] = game_;

        _refundGame(_gameIndex);
    }

    function _refundGame(uint256 _gameIndex) internal {
        Game memory game_ = games[_gameIndex];

        vaultManager.refund(game_.wagerAsset, game_.ante, 0, game_.player);
    }

    function _generateRandom(uint256 _random) internal pure returns (uint256 sumOfRandoms_) {
        // generate 12 random numbers that are between 0 and 1000 (0-1)
        unchecked {
            for (uint256 i = 1; i < 13; ++i) {
                sumOfRandoms_ += ((_random / (1000 ** (i - 1))) % 1000);
            }
        }
    }

    function _computeMultiplier(uint256 _random) internal pure returns (uint256 multiplier_) {
        unchecked {
            // generate 12 random numbers and sum them up, then subtract 6000 from the sum to normalize the distribution
            int256 _sumOfRandoms = int256(_generateRandom(_random)) - 6000;

            _random = (_random % 1000) + 1;

            // check if the random number is greater than or equal to alpha
            // using alpha as a threshold to determine which distribution to use
            if (_random >= 999) {
                multiplier_ = uint256((10000 * _sumOfRandoms) / 1e3 + 100000);
            } else {
                multiplier_ = uint256((100 * _sumOfRandoms) / 1e3 + 600);
            }

            if (multiplier_ < 100) {
                multiplier_ = 100;
            }
            if (multiplier_ > 100000) {
                multiplier_ = 100000;
            }
        }
    }

    function getHouseEdge() public pure returns (uint64 edge_) {
        edge_ = houseEdge;
    }

    // VIEW FUNCTIONS
    function returnGameInfo(uint256 _gameIndex) external view returns (Game memory) {
        require(_gameIndex < gameIndex, "WINRPoker: Invalid game index");
        return games[_gameIndex];
    }

    function returnGameHand(uint256 _gameIndex) external view returns (uint16[9] memory) {
        require(_gameIndex < gameIndex, "WINRPoker: Invalid game index");
        return gameHands_[_gameIndex];
    }

    function returnDealerHand(uint256 _gameIndex) external view returns (Hand memory) {
        require(_gameIndex < gameIndex, "WINRPoker: Invalid game index");
        return dealerHands[_gameIndex];
    }

    function returnPlayerHand(uint256 _gameIndex) external view returns (Hand memory) {
        require(_gameIndex < gameIndex, "WINRPoker: Invalid game index");
        return playerHands[_gameIndex];
    }

    function returnRequestIdToGameIndex(uint256 _requestId) external view returns (uint256) {
        return requestIdToGameIndex[_requestId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./LuckyStrikeRouter.sol";
import "../../interfaces/core/IVaultManagerLight.sol";
import "../helpers/RandomizerConsumerLight.sol";

abstract contract CoreLight is RandomizerConsumerLight, LuckyStrikeRouter, Pausable {
    IVaultManagerLight public vaultManager;

    constructor(IRandomizerRouter _router) RandomizerConsumerLight(_router) {}

    function setVaultManager(IVaultManagerLight _vaultManager) external onlyOwner {
        vaultManager = _vaultManager;
    }

    function setLuckyStrikeMaster(ILuckyStrikeMaster _masterStrike) external onlyOwner {
        masterStrike = _masterStrike;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice internal function that checks in the player has won the lucky strike jackpot
     * @param _randomness random number from the randomizer / vrf
     * @param _player address of the player that has wagered
     * @param _token address of the token the player has wagered
     * @param _usedWager amount of the token the player has wagered
     */
    function _hasLuckyStrike(uint256 _randomness, address _player, address _token, uint256 _usedWager)
        internal
        returns (bool hasWon_)
    {
        if (_hasLuckyStrikeCheck(_randomness, _computeDollarValue(_token, _usedWager))) {
            _processLuckyStrike(_player);
            return true;
        } else {
            return false;
        }
    }

    function _computeDollarValue(address _token, uint256 _wager) internal view returns (uint256 _wagerInDollar) {
        unchecked {
            _wagerInDollar = ((_wager * vaultManager.getPrice(_token))) / (10 ** IERC20Metadata(_token).decimals());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IWINRPoker
 * @author balding-ghost
 * @notice xxx
 */
interface IWINRPoker {
    /**
     * Deck
     *    2 = 2, 14 = Ace, 13 = King
     *    100 = Heart
     *    200 = Diamond
     *    300 = Club
     *    400 = Spade
     * z
     *    102 = 2 of Heart, 114 = Ace of Heart, 113 = King of Heart
     *    201 = Ace of Diamond, 213 = King of Diamond
     *  etc
     *
     *  Card deck stored in packed uint16[9] drawnCards
     *     0 = Player Card 1
     *     1 = Player Card 2
     *     2 = Dealer Card 1
     *     3 = Dealer Card 2
     *     4 = Common Card 1
     *     5 = Common Card 2
     *     6 = Common Card 3
     *     7 = Common Card 4
     *     8 = Common Card 5
     */

    // Hand playerHand;
    // Hand dealerHand;
    // Result result;

    struct Hand {
        Combination combination;
        uint16[5] cards;
    }

    enum Combination {
        NONE, // 0
        HIGH_CARD, // 1
        PAIR, // 2
        TWO_PAIR, // 3
        THREE_OF_A_KIND, // 4
        STRAIGHT, // 5
        FLUSH, // 6
        FULL_HOUSE, // 7
        FOUR_OF_A_KIND, // 8
        STRAIGHT_FLUSH, // 9
        ROYAL_FLUSH // 10
    }

    enum Result {
        NONE,
        DEALER_WINS,
        PLAYER_WINS,
        PLAYER_LOSES_FOLD,
        DEALER_NOT_QUALIFIED,
        PUSH
    }

    struct Game {
        address player;
        address wagerAsset;
        uint128 ante;
        uint32 timestampLatest;
        State state;
        Result result;
    }

    enum State {
        NONE,
        AWAITING_DEAL,
        DEALT,
        FOLD,
        CALLED,
        RESOLVED,
        REFUNDED
    }

    event GameResolved(uint256 indexed gameIndex, uint16[9] drawnCards, Result result, uint256 payout);

    event GameDealt(uint256 indexed gameIndex, uint16[9] drawnCards);

    event PlayerCalled(uint256 indexed gameIndex, uint256 indexed requestId, uint256 ante);

    // event PlayerFolded(uint256 indexed gameIndex, uint256 ante);

    event GameCreated(uint256 gameIndex, address player, uint256 ante, address wagerAsset);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IWINRPoker.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// import "forge-std/Test.sol";

/**
 * @title HelperPoker
 * @author balding-ghost
 */
library HelperPoker {
    uint256 public constant AMOUNT_DECKS = 1;
    uint256 public constant AMOUNT_CARDS = 52;
    uint256 public constant LOOPS = 4;

    function drawInitialCards(uint256 _randoms) external returns (uint16[9] memory) {
        uint256[52] memory allNumbersDecks_;
        uint16[9] memory initialDeal;
        uint256 index_ = 0;

        unchecked {
            // Initialize deck
            for (uint256 t = 0; t < LOOPS; ++t) {
                uint256 suitBase = (t + 1) * 100; // 100 for hearts, 200 for diamonds, etc.
                for (uint256 x = 2; x <= 14; ++x) {
                    allNumbersDecks_[index_] = suitBase + x;
                    index_++;
                }
            }

            // Perform a Fisher-Yates shuffle to randomize the deck
            for (uint256 y = AMOUNT_CARDS - 1; y >= 1; --y) {
                uint256 value_ = uint256(keccak256(abi.encodePacked(_randoms, y))) % (y + 1);
                (allNumbersDecks_[y], allNumbersDecks_[value_]) = (allNumbersDecks_[value_], allNumbersDecks_[y]);
            }

            // Deal initial cards
            initialDeal[0] = uint16(allNumbersDecks_[0]); // Player Card 1
            initialDeal[1] = uint16(allNumbersDecks_[1]); // Player Card 2
            // Dealer cards remain undealt
            initialDeal[4] = uint16(allNumbersDecks_[2]); // Common Card 1
            initialDeal[5] = uint16(allNumbersDecks_[3]); // Common Card 2
            initialDeal[6] = uint16(allNumbersDecks_[4]); // Common Card 3
                // Final two common cards remain undealt, dealers cards remain undealt
        }

        return initialDeal;
    }

    function dealRemainingCards(uint256 _randoms, uint16[9] memory initialDeal) external returns (uint16[9] memory) {
        uint256[AMOUNT_CARDS] memory allNumbersDecks_;
        uint256 index_ = 0;

        // Initialize deck
        for (uint256 t = 0; t < LOOPS; ++t) {
            uint256 suitBase = (t + 1) * 100; // 100 for hearts, 200 for diamonds, etc.
            for (uint256 x = 2; x <= 14; ++x) {
                allNumbersDecks_[index_] = suitBase + x;
                index_++;
            }
        }

        // Perform a Fisher-Yates shuffle to randomize the deck
        for (uint256 y = AMOUNT_CARDS - 1; y >= 1; --y) {
            uint256 value_ = uint256(keccak256(abi.encodePacked(_randoms, y))) % (y + 1);
            (allNumbersDecks_[y], allNumbersDecks_[value_]) = (allNumbersDecks_[value_], allNumbersDecks_[y]);
        }

        // Filter out already dealt cards
        for (uint256 i = 0; i < 9; ++i) {
            if (initialDeal[i] > 0) {
                for (uint256 j = 0; j < AMOUNT_CARDS; ++j) {
                    if (allNumbersDecks_[j] == uint256(initialDeal[i])) {
                        allNumbersDecks_[j] = 0; // Mark this card as dealt
                        break;
                    }
                }
            }
        }

        // Deal the remaining cards
        index_ = 0;
        for (uint256 i = 0; i < AMOUNT_CARDS && index_ < 4; ++i) {
            if (allNumbersDecks_[i] > 0) {
                if (index_ < 2) {
                    initialDeal[2 + index_] = uint16(allNumbersDecks_[i]); // Dealer Cards
                } else {
                    initialDeal[7 + index_ - 2] = uint16(allNumbersDecks_[i]); // Remaining Common Cards
                }
                index_++;
            }
        }

        // Deal the remaining cards
        // index_ = 0;
        // for (uint256 i = 0; i < AMOUNT_CARDS && index_ < 4; ++i) {
        //     if (allNumbersDecks_[i] > 0) {
        //         if (index_ < 2) {
        //             initialDeal[2 + index_] = uint16(allNumbersDecks_[i]); // Dealer Cards
        //         } else if (index_ < 3) {
        //             // Add this condition to prevent index_ from reaching 4
        //             initialDeal[7 + index_ - 2] = uint16(allNumbersDecks_[i]); // Remaining Common Cards
        //         }
        //         index_++;
        //     }
        // }

        return initialDeal;
    }

    function determineWinner(IWINRPoker.Hand memory dealerHand, IWINRPoker.Hand memory playerHand)
        external
        returns (IWINRPoker.Result)
    {
        // Check if dealer qualifies
        if (
            dealerHand.combination == IWINRPoker.Combination.NONE
                || (dealerHand.combination == IWINRPoker.Combination.HIGH_CARD)
                || (dealerHand.combination == IWINRPoker.Combination.PAIR && dealerHand.cards[0] < 5)
        ) {
            // note should probably revert with NONE state as it is invalid
            return IWINRPoker.Result.DEALER_NOT_QUALIFIED;
        }

        // Check for a tie
        if (dealerHand.combination == playerHand.combination) {
            for (uint16 i = 0; i < 5; i++) {
                if (dealerHand.cards[i] > playerHand.cards[i]) {
                    return IWINRPoker.Result.DEALER_WINS;
                } else if (dealerHand.cards[i] < playerHand.cards[i]) {
                    return IWINRPoker.Result.PLAYER_WINS;
                }
            }
            return IWINRPoker.Result.PUSH; // All cards are equal, it's a push
        }

        // Compare hand ranks to determine the winner
        return (dealerHand.combination > playerHand.combination)
            ? IWINRPoker.Result.DEALER_WINS
            : IWINRPoker.Result.PLAYER_WINS;
    }

    function findCombinationPlayer(uint16[9] memory cardData) external returns (IWINRPoker.Hand memory) {
        // Merge player and community cards for easier processing
        uint16[7] memory allCards_ =
            [cardData[0], cardData[1], cardData[4], cardData[5], cardData[6], cardData[7], cardData[8]];

        // Initialize the best hand to NONE
        // IWINRPoker.Hand memory bestHand_;
        // bestHand_.combination = IWINRPoker.Combination.NONE;

        uint16[7] memory suits_;
        uint16[7] memory values_;

        // Split suits and values
        // for (uint16 i = 0; i < 7; ++i) {
        //     suits_[i] = allCards_[i] / 100;
        //     values_[i] = allCards_[i] % 100;
        // }

        // Split suits and values
        for (uint16 i = 0; i < 7; ++i) {
            require(allCards_[i] >= 100, "Card value must be at least 100");
            suits_[i] = allCards_[i] / 100;
            values_[i] = allCards_[i] % 100;
        }

        // Sort values in ascending order
        values_ = insertionSort(values_);

        uint16[5] memory winningCards1_;
        IWINRPoker.Combination winningCombination1_;

        // Check for each combination type, from highest to lowest
        // Update bestHand if a better combination is found
        (winningCombination1_, winningCards1_) = _checkFlushesAndStraights(values_, suits_);

        IWINRPoker.Hand memory bestHand_;

        if (
            winningCombination1_ == IWINRPoker.Combination.ROYAL_FLUSH
                || winningCombination1_ == IWINRPoker.Combination.STRAIGHT_FLUSH
        ) {
            bestHand_.cards = winningCards1_;
            bestHand_.combination = winningCombination1_;
            return bestHand_;
        }

        uint16[5] memory winningCards2_;
        IWINRPoker.Combination winningCombination2_;

        (winningCombination2_, winningCards2_) = _checkPairsAndFullHouse(values_);

        if (winningCombination1_ != IWINRPoker.Combination.NONE && winningCombination2_ != IWINRPoker.Combination.NONE)
        {
            // the user might have a flush or a straight, but user also has a pair  / fullhouse / etc
            // check which one is better
            // if user has fullhouse or four of a kind, return that
            if (
                winningCombination2_ == IWINRPoker.Combination.FULL_HOUSE
                    || winningCombination2_ == IWINRPoker.Combination.FOUR_OF_A_KIND
            ) {
                bestHand_.cards = winningCards2_;
                bestHand_.combination = winningCombination2_;
                return bestHand_;
            }
            // if user has flush return that
            else if (winningCombination1_ == IWINRPoker.Combination.FLUSH) {
                bestHand_.cards = winningCards1_;
                bestHand_.combination = winningCombination1_;
                return bestHand_;
            }
            // else {
            //     revert("215 Poker: Invalid combination");
            // }
        } else if (winningCombination1_ != IWINRPoker.Combination.NONE) {
            bestHand_.cards = winningCards1_;
            bestHand_.combination = winningCombination1_;
            return bestHand_;
        } else if (winningCombination2_ != IWINRPoker.Combination.NONE) {
            bestHand_.cards = winningCards2_;
            bestHand_.combination = winningCombination2_;
            return bestHand_;
        }
        // if user has nothing for both
        else if (
            winningCombination1_ == IWINRPoker.Combination.NONE && winningCombination2_ == IWINRPoker.Combination.NONE
        ) {
            // bestHand_.cards = values_; // todo return sorted uint16[5] memory asceding
            bestHand_.cards = [values_[6], values_[5], values_[4], values_[3], values_[2]];
            bestHand_.combination = IWINRPoker.Combination.HIGH_CARD;
            return bestHand_;
            // user has nothing, return high card array
        } else {
            revert("236 Poker: Invalid combination");
        }

        // return bestHand_;
    }

    function findCombinationDealer(uint16[9] memory cardData) external returns (IWINRPoker.Hand memory) {
        // Merge player and community cards for easier processing
        uint16[7] memory allCards_ =
            [cardData[2], cardData[3], cardData[4], cardData[5], cardData[6], cardData[7], cardData[8]];

        // Initialize the best hand to NONE
        // IWINRPoker.Hand memory bestHand_;
        // bestHand_.combination = IWINRPoker.Combination.NONE;

        uint16[7] memory suits_;
        uint16[7] memory values_;

        // Split suits and values
        for (uint16 i = 0; i < 7; ++i) {
            require(allCards_[i] >= 100, "Card value must be at least 100");
            suits_[i] = allCards_[i] / 100;
            values_[i] = allCards_[i] % 100;
        }

        values_ = insertionSort(values_);

        uint16[5] memory winningCards1_;
        IWINRPoker.Combination winningCombination1_;

        // Check for each combination type, from highest to lowest
        // Update bestHand if a better combination is found
        (winningCombination1_, winningCards1_) = _checkFlushesAndStraights(values_, suits_);

        IWINRPoker.Hand memory bestHand_;

        if (
            winningCombination1_ == IWINRPoker.Combination.ROYAL_FLUSH
                || winningCombination1_ == IWINRPoker.Combination.STRAIGHT_FLUSH
        ) {
            bestHand_.cards = winningCards1_;
            bestHand_.combination = winningCombination1_;
            return bestHand_;
        }

        uint16[5] memory winningCards2_;
        IWINRPoker.Combination winningCombination2_;

        (winningCombination2_, winningCards2_) = _checkPairsAndFullHouse(values_);

        if (winningCombination1_ != IWINRPoker.Combination.NONE && winningCombination2_ != IWINRPoker.Combination.NONE)
        {
            // the user might have a flush or a straight, but user also has a pair  / fullhouse / etc
            // check which one is better
            // if user has fullhouse or four of a kind, return that
            if (
                winningCombination2_ == IWINRPoker.Combination.FULL_HOUSE
                    || winningCombination2_ == IWINRPoker.Combination.FOUR_OF_A_KIND
            ) {
                bestHand_.cards = winningCards2_;
                bestHand_.combination = winningCombination2_;
                return bestHand_;
            }
            // if user has flush return that
            else if (winningCombination1_ == IWINRPoker.Combination.FLUSH) {
                bestHand_.cards = winningCards1_;
                bestHand_.combination = winningCombination1_;
                return bestHand_;
            }
            // else {
            //     revert("305 - Poker: Invalid combination");
            // }
        } else if (winningCombination1_ != IWINRPoker.Combination.NONE) {
            bestHand_.cards = winningCards1_;
            bestHand_.combination = winningCombination1_;
            return bestHand_;
        } else if (winningCombination2_ != IWINRPoker.Combination.NONE) {
            bestHand_.cards = winningCards2_;
            bestHand_.combination = winningCombination2_;
            return bestHand_;
        }
        // if user has nothing for both
        else if (
            winningCombination1_ == IWINRPoker.Combination.NONE && winningCombination2_ == IWINRPoker.Combination.NONE
        ) {
            // bestHand_.cards = values_; // todo return sorted uint16[5] memory asceding
            bestHand_.cards = [values_[6], values_[5], values_[4], values_[3], values_[2]];
            bestHand_.combination = IWINRPoker.Combination.HIGH_CARD;
            return bestHand_;
            // user has nothing, return high card array
        } else {
            revert("326 - Poker: Invalid combination");
        }
    }

    function _checkPairsAndFullHouse(uint16[7] memory values)
        public
        returns (IWINRPoker.Combination, uint16[5] memory)
    {
        uint16 currentCount = 1;
        uint16 previousValue = values[0];
        uint16 firstPairValue = 0;
        uint16 secondPairValue = 0;
        uint16 threeOfAKindValue = 0;
        uint16 fourOfAKindValue = 0;

        for (uint16 i = 1; i < 7; ++i) {
            if (values[i] == previousValue) {
                currentCount++;
            } else {
                (firstPairValue, secondPairValue, threeOfAKindValue, fourOfAKindValue) = updateCounts(
                    currentCount, previousValue, firstPairValue, secondPairValue, threeOfAKindValue, fourOfAKindValue
                );
                currentCount = 1;
                previousValue = values[i];
            }
        }
        // Update counts for the last set of identical values
        (firstPairValue, secondPairValue, threeOfAKindValue, fourOfAKindValue) = updateCounts(
            currentCount, previousValue, firstPairValue, secondPairValue, threeOfAKindValue, fourOfAKindValue
        );

        // IWINRPoker.Hand memory hand;
        IWINRPoker.Combination combination_;
        uint16[5] memory cards_;

        // Check for four of a kind
        if (fourOfAKindValue > 0) {
            combination_ = IWINRPoker.Combination.FOUR_OF_A_KIND;
            cards_ = [
                fourOfAKindValue,
                fourOfAKindValue,
                fourOfAKindValue,
                fourOfAKindValue,
                (firstPairValue > 0 ? firstPairValue : secondPairValue)
            ];
            return (combination_, cards_);
        }

        // Check for full house
        // if (threeOfAKindValue > 0 && (firstPairValue > 0 || secondPairValue > 0)) {
        //     combination_ = IWINRPoker.Combination.FULL_HOUSE;
        //     cards_ = [threeOfAKindValue, threeOfAKindValue, threeOfAKindValue, firstPairValue, firstPairValue];
        //     return (combination_, cards_);
        // }
        // Check for full house
        if (
            threeOfAKindValue > 0
                && (
                    (firstPairValue > 0 && firstPairValue != threeOfAKindValue)
                        || (secondPairValue > 0 && secondPairValue != threeOfAKindValue)
                )
        ) {
            combination_ = IWINRPoker.Combination.FULL_HOUSE;
            cards_ = [threeOfAKindValue, threeOfAKindValue, threeOfAKindValue, firstPairValue, firstPairValue];
            return (combination_, cards_);
        }

        // Check for two pair
        if (firstPairValue > 0 && secondPairValue > 0) {
            combination_ = IWINRPoker.Combination.TWO_PAIR;
            cards_ = [firstPairValue, firstPairValue, secondPairValue, secondPairValue, 0];
            // cards_ = [firstPairValue, firstPairValue, secondPairValue, secondPairValue, values[6]];
            return (combination_, cards_);
        }

        // Check for one pair
        if (firstPairValue > 0) {
            combination_ = IWINRPoker.Combination.PAIR;
            // cards_ = [firstPairValue, firstPairValue, values[6], values[5], values[4]]; // Other cards can be filled based on remaining values
            cards_ = [firstPairValue, firstPairValue, 0, 0, 0]; // Other cards can be filled based on remaining values

            return (combination_, cards_);
        }

        return (combination_, cards_); // No relevant combination found
    }

    function updateCounts(
        uint16 currentCount,
        uint16 value,
        uint16 firstPairValue,
        uint16 secondPairValue,
        uint16 threeOfAKindValue,
        uint16 fourOfAKindValue
    ) public returns (uint16, uint16, uint16, uint16) {
        if (currentCount == 4) {
            fourOfAKindValue = value;
        } else if (currentCount == 3) {
            threeOfAKindValue = value;
        } else if (currentCount == 2) {
            if (firstPairValue == 0) {
                firstPairValue = value;
            } else {
                secondPairValue = value;
            }
        }
        return (firstPairValue, secondPairValue, threeOfAKindValue, fourOfAKindValue);
    }

    function insertionSort(uint16[7] memory arr) public returns (uint16[7] memory) {
        uint16 n = 7;
        for (uint16 i = 1; i < n; i++) {
            uint16 key = arr[i];
            uint16 j = i;
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = key;
        }
        return arr;
    }
    // returns (IWINRPoker.Combination, uint16[5] memory)

    function _checkFlushesAndStraights(uint16[7] memory values, uint16[7] memory types)
        public
        returns (IWINRPoker.Combination, uint16[5] memory)
    {
        // Count occurrences of each suit
        uint16[4] memory suitCounts;
        for (uint16 i = 0; i < 7; ++i) {
            suitCounts[types[i] - 1]++;
        }

        // Check for flushes
        for (uint16 i = 0; i < 4; ++i) {
            if (suitCounts[i] >= 5) {
                // Extract cards of the flush suit
                uint16[7] memory flushCards;
                uint16 index = 0;
                for (uint16 j = 0; j < 7; ++j) {
                    if (types[j] == i + 1) {
                        flushCards[index] = values[j];
                        index++;
                    }
                }

                // Check for Straight Flush or Royal Flush in flushCards
                for (uint16 j = 0; j <= index - 5; ++j) {
                    if (isSequential(flushCards, j, j + 4)) {
                        if (flushCards[j] == 1 && flushCards[j + 1] == 10) {
                            return (
                                IWINRPoker.Combination.ROYAL_FLUSH,
                                [
                                    flushCards[j],
                                    flushCards[j + 1],
                                    flushCards[j + 2],
                                    flushCards[j + 3],
                                    flushCards[j + 4]
                                ]
                            );
                        }
                        return (
                            IWINRPoker.Combination.STRAIGHT_FLUSH,
                            [flushCards[j], flushCards[j + 1], flushCards[j + 2], flushCards[j + 3], flushCards[j + 4]]
                        );
                    }
                }

                // If no Straight Flush or Royal Flush, it's a normal Flush
                return (
                    IWINRPoker.Combination.FLUSH,
                    [flushCards[0], flushCards[1], flushCards[2], flushCards[3], flushCards[4]]
                );
            }
        }

        // uint16[7] memory values

        // // Check for Straight in values array
        // for (uint16 i = 0; i <= 2; ++i) {
        //     // Loop only needs to go to index 2 for a valid straight to be possible
        //     if (isSequential(values, i, i + 4)) {
        //         // note there is a bug here, it returns the lower stragiht
        //         return (
        //             IWINRPoker.Combination.STRAIGHT,
        //             [values[i], values[i + 1], values[i + 2], values[i + 3], values[i + 4]]
        //         );
        //     }
        // }

        // // Check for Straight in values array
        // for (uint16 i = 6; i >= 3; --i) {
        //     console.log("6");
        //     // Loop only needs to go to index 3 for a valid straight to be possible
        //     if (isSequential(values, i - 4, i)) {
        //         console.log("6.1");
        //         return (
        //             IWINRPoker.Combination.STRAIGHT,
        //             [values[i - 4], values[i - 3], values[i - 2], values[i - 1], values[i]]
        //         );
        //     }
        // }
        // Check for Straight in values array
        uint16 i = 6;
        while (true) {
            // Loop only needs to go to index 3 for a valid straight to be possible
            if (i >= 4) {
                if (isSequential(values, i - 4, i)) {
                    return (
                        IWINRPoker.Combination.STRAIGHT,
                        [values[i - 4], values[i - 3], values[i - 2], values[i - 1], values[i]]
                    );
                }
            }
            if (i == 2) {
                break;
            }
            --i;
        }

        return (IWINRPoker.Combination.NONE, [uint16(0), uint16(0), uint16(0), uint16(0), uint16(0)]);
    }

    function isSequential(uint16[7] memory arr, uint16 start, uint16 end) public returns (bool) {
        for (uint16 i = start; i < end; ++i) {
            // if (arr[i] + 1 != arr[i + 1]) {
            if (arr[i] > 0 && arr[i + 1] > 0 && arr[i] + 1 != arr[i + 1]) {
                // Special case for checking for low straight (Ace to 5)
                if (arr[i] == 5 && arr[end] == 14 && start == 0) {
                    return true;
                }
                return false;
            }
        }
        return true;
    }

    /**
     * @notice returns the amount of tokens and the dollar value of a certain amount of chips in a game
     * @param _chips amount of chips
     * @param _token token address
     * @param _price usd price of the token (scaled 1e30)
     * @return tokenAmount_ amount of tokens that the chips are worth
     * @return dollarValue_ dollar value of the chips
     */
    function chip2Token(uint256 _chips, address _token, uint256 _price)
        external
        view
        returns (uint256 tokenAmount_, uint256 dollarValue_)
    {
        uint256 decimals_ = IERC20Metadata(_token).decimals();
        unchecked {
            tokenAmount_ = ((_chips * (10 ** (30 + decimals_)))) / _price;
            dollarValue_ = (tokenAmount_ * _price) / (10 ** decimals_);
        }
        return (tokenAmount_, dollarValue_);
    }

    /**
     * @param _chips amount of chips
     * @param _decimals decimals of token
     * @param _price price of token (scaled 1e30)
     */
    function chip2TokenDecimals(uint256 _chips, uint256 _decimals, uint256 _price)
        external
        returns (uint256 tokenAmount_)
    {
        unchecked {
            tokenAmount_ = ((_chips * (10 ** (30 + _decimals)))) / _price;
        }
        return tokenAmount_;
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
  event LuckyStrikeDraw(address indexed player, uint256 wonAmount, bool won);

  ILuckyStrikeMaster public masterStrike;

  function _hasLuckyStrikeCheck(
    uint256 _randomness,
    uint256 _usdWager
  ) internal view returns (bool hasWon_) {
    hasWon_ = masterStrike.hasLuckyStrike(_randomness, _usdWager);
  }

  function _processLuckyStrike(address _player) internal returns (uint256 wonAmount_) {
    wonAmount_ = masterStrike.processLuckyStrike(_player);
    emit LuckyStrikeDraw(_player, wonAmount_, wonAmount_ > 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "../../interfaces/vault/IFeeCollector.sol";
// import "../../interfaces/vault/IVault.sol";

/// @dev This contract designed to easing token transfers broadcasting information between contracts
interface IVaultManagerLight {
  // function vault() external view returns (IVault);

  // function wlp() external view returns (IERC20);

  // function BASIS_POINTS() external view returns (uint32);

  // function feeCollector() external view returns (IFeeCollector);

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
  // function removeReferralReward(
  //   address _token,
  //   address _player,
  //   uint256 _amount,
  //   uint64 _houseEdge
  // ) external;

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

  // /// @notice used to transfer player's token to WLP
  // /// @param _input currency of payment
  // /// @param _amount convert token amount
  // /// @param _sender sender of token
  // /// @param _recipient recipient of WLP
  // function deposit(
  //   address _input,
  //   uint256 _amount,
  //   address _sender,
  //   address _recipient
  // ) external returns (uint256);

  function getPrice(address _token) external view returns (uint256 _price);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/randomizer/IRandomizerRouter.sol";
import "../../interfaces/randomizer/IRandomizerConsumer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract RandomizerConsumerLight is Ownable, ReentrancyGuard, IRandomizerConsumer {
    modifier onlyRandomizer() {
        require(_msgSender() == address(randomizerRouter), "RC: Not randomizer");
        _;
    }

    /// @notice minimum confirmation blocks
    uint256 public minConfirmations = 3;
    /// @notice router address
    IRandomizerRouter public randomizerRouter;

    constructor(IRandomizerRouter _randomizerRouter) {
        changeRandomizerRouter(_randomizerRouter);
    }

    function changeRandomizerRouter(IRandomizerRouter _randomizerRouter) public onlyOwner {
        randomizerRouter = _randomizerRouter;
    }

    function setMinConfirmations(uint16 _minConfirmations) external onlyOwner {
        minConfirmations = _minConfirmations;
    }

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

  function hasLuckyStrike(
    uint256 _randomness,
    uint256 _wagerUSD
  ) external view returns (bool hasWon_);

  function valueOfLuckyStrikeJackpot() external view returns (uint256 valueTotal_);

  function processLuckyStrike(address _player) external returns (uint256 wonAmount_);
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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