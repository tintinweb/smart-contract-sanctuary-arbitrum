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