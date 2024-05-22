// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IWINRBlackJack.sol";

/**
 * @title HelperBlackJack
 * @author balding-ghost
 * @notice This library contains helper functions for the Blackjack game.
 */
library HelperBlackJack {
	uint256 public constant AMOUNT_DECKS = 1;
	uint256 public constant AMOUNT_CARDS = AMOUNT_DECKS * 52;
	uint256 public constant LOOPS = 4 * AMOUNT_DECKS;

	/**
	 * @notice This function deals a card to a hand in a game of Blackjack.
	 * @param hand_ The current hand.
	 * @param cards_ The current cards in the hand.
	 * @param _card The card to be dealt.
	 * @return hand_ The updated hand after the card is dealt.
	 * @return cards_ The updated cards in the hand after the card is dealt.
	 */
	function dealCardToHand(
		IWINRBlackJack.Hand memory hand_,
		IWINRBlackJack.Cards memory cards_,
		uint256 _card
	) external pure returns (IWINRBlackJack.Hand memory, IWINRBlackJack.Cards memory) {
		unchecked {
			// Ensure the hand is in the state where it can receive a new card
			require(
				hand_.status == IWINRBlackJack.HandStatus.AWAITING_HIT,
				"Blackjack: Hand is not awaiting hit"
			);

			bool isSplitAces_;
			bool isSplitHand_;

			// Add the new card to the hand and update the hand status
			(cards_, isSplitAces_, isSplitHand_) = _hitHandWithCard(cards_, uint8(_card));

			// The hand is now in the playing state
			hand_.status = IWINRBlackJack.HandStatus.PLAYING;

			// If the hand is a double or split aces, the player cannot take any more cards and must stand
			if (hand_.isDouble || isSplitAces_) {
				hand_.status = IWINRBlackJack.HandStatus.STAND;
			}

			// If the total count is above 21
			if (cards_.totalCount > 21) {
				hand_.status = IWINRBlackJack.HandStatus.BUST;
			} else if (cards_.totalCount == 21) {
				// If the total count is 21
				if (cards_.amountCards == 2 && !isSplitHand_) {
					// If the hand has exactly two cards, it's a blackjack
					// it is not blackjack if the player has split aces or any other pair
					hand_.status = IWINRBlackJack.HandStatus.BLACKJACK;
				} else {
					// If the hand has more than two cards and the total count is 21, the player must stand as they cannot improve the hand without busting
					hand_.status = IWINRBlackJack.HandStatus.STAND;
				}
			}

			return (hand_, cards_);
		}
	}

	/**
	 * @notice This function adds a new card to the dealer's hand in a game of Blackjack.
	 * @param cards_ The current cards in the dealer's hand.
	 * @param _newCard The new card to be added to the hand.
	 * @return cards_ The updated cards structure after the new card is added.
	 */
	function hitDealerWithCard(
		IWINRBlackJack.Cards memory cards_,
		uint8 _newCard
	) external pure returns (IWINRBlackJack.Cards memory) {
		unchecked {
			// Increment the number of cards in the hand
			cards_.amountCards += 1;

			// If the new card is a face card (Jack, Queen, King), count it as 10
			uint256 newCardValue_ = (_newCard > 10) ? 10 : _newCard;

			// If the new card is an Ace
			if (_newCard == 1 && cards_.isSoftHand) {
				// If the hand is already soft, count the Ace as 1
				newCardValue_ = 1;
			} else if (_newCard == 1) {
				// If the hand is not soft, count the Ace as 11 and mark the hand as soft
				newCardValue_ = 11;
				cards_.isSoftHand = true;
			}

			// Add the value of the new card to the total count
			cards_.totalCount += uint8(newCardValue_);

			// If the total count is over 21 and the hand is soft
			if (cards_.totalCount > 21 && cards_.isSoftHand) {
				// Subtract 10 (count one of the aces as 1 instead of 11) and mark the hand as hard
				cards_.totalCount -= 10;
				cards_.isSoftHand = false;
			}

			return cards_;
		}
	}

	/**
	 * @notice This function adds a new card to the player's hand in a game of Blackjack.
	 * @param cards_ The current cards in the player's hand.
	 * @param _newCard The new card to be added to the hand.
	 * @return cards_ The updated cards structure after the new card is added.
	 * @return isSplitAces_ A boolean indicating whether the player has split aces.
	 */
	function _hitHandWithCard(
		IWINRBlackJack.Cards memory cards_,
		uint8 _newCard
	) internal pure returns (IWINRBlackJack.Cards memory, bool isSplitAces_, bool isSplitHand_) {
		unchecked {
			// Increment the number of cards in the hand
			cards_.amountCards += 1;

			// If the new card is a face card (Jack, Queen, King), count it as 10
			uint256 newCardValue_ = (_newCard > 10) ? 10 : _newCard;

			// If the player has only one card (after a split) -> dealing card to split hand!
			if (cards_.cards[1] == 0) {
				// deal the new card to the second position in the array
				cards_.cards[1] = _newCard;

				// Check if the player has split aces (so first card is 1)
				isSplitAces_ = cards_.cards[0] == 1 ? true : false;

				isSplitHand_ = true;

				// If the new card is an Ace and the hand is soft
				if (_newCard == 1 && cards_.isSoftHand) {
					// this means that the player now has split aces, so player split aces and has gotten another ace on a split hand
					// Count the Ace as 1 and allow the player to spli
					newCardValue_ = 1;
					cards_.canSplit = true;
					// note the hand is still soft
				} else if (_newCard == 1) {
					// If the new card is an Ace and the hand is not soft
					// Count the Ace as 11 and mark the hand as soft
					newCardValue_ = 11;
					cards_.isSoftHand = true;
				} else {
					// if the new card has the same amount of value/points as the first card, the player can split again
					if (_newCard == cards_.cards[0]) {
						// this means player can split the already split hand
						cards_.canSplit = true;
					} else if (cards_.cards[0] >= 10 && _newCard >= 10) {
						// this means player has split a pair of face cards
						cards_.canSplit = true;
					}
				}
				// Add the value of the new card to the total count
				cards_.totalCount += uint8(newCardValue_);
			} else {
				// Add the value of the new card to the total count

				// check if we have to overwrite the last card in the array
				if ((cards_.amountCards - 1) > 7) {
					cards_.cards[7] = _newCard;
				} else {
					// note this is the normal case where we just add the card to the array
					cards_.cards[cards_.amountCards - 1] = _newCard;
				}

				// If the new card is an Ace
				if (_newCard == 1 && cards_.isSoftHand) {
					// If the hand is already soft, count the Ace as 1
					newCardValue_ = 1;
				} else if (_newCard == 1) {
					// If the hand is not soft, count the Ace as 11 and mark the hand as soft
					newCardValue_ = 11;
					cards_.isSoftHand = true;
				}

				cards_.totalCount += uint8(newCardValue_);

				// If the total count is over 21 and the hand is soft
				if (cards_.totalCount > 21 && cards_.isSoftHand) {
					// Subtract 10 (count one of the aces as 1 instead of 11) and mark the hand as hard
					cards_.totalCount -= 10;
					cards_.isSoftHand = false;
				}
			}

			return (cards_, isSplitAces_, isSplitHand_);
		}
	}

	/**
	 * @notice This function splits the player's hand.
	 * @param cards_ The current cards in the player's hand (the hand the player wants to split)
	 * @return newCards_ The new hand of cards after the split.
	 */
	function splitHandHelper(
		IWINRBlackJack.Cards memory cards_
	) external pure returns (IWINRBlackJack.Cards memory newCards_) {
		unchecked {
			// Ensure the hand can be split (only pairs can be split)
			require(cards_.canSplit, "Blackjack: Hand cannot be split");
			// Ensure the hand only has two cards (a hand can only be split at the start of the game)
			require(cards_.amountCards == 2, "Blackjack: Hand cannot be split more than 2 cards");

			// If the total count is 12 and the hand is soft, the player is splitting aces
			if (cards_.totalCount == 12 && cards_.isSoftHand) {
				newCards_.cards[0] = 1; // The first card of the new hand is an Ace
				newCards_.cards[1] = 0; // The second card of the new hand is not yet dealt
				newCards_.isSoftHand = true; // The hand is soft because it contains an Ace
				newCards_.totalCount = 11; // The total count is 11 because an Ace is counted as 11 in a soft hand
			} else {
				// If the player is not splitting aces, the first card of the new hand is the second card of the old hand (or could be the first card if the player is splitting a pair of face cards)
				newCards_.cards[0] = cards_.cards[0];
				newCards_.cards[1] = 0; // The second card of the new hand is not yet dealt
				// The total count is the value of the first card, or 10 if the first card is a face card
				newCards_.totalCount = (cards_.cards[0] > 10) ? 10 : cards_.cards[0];
			}

			newCards_.amountCards = 1; // The new hand has one card

			return newCards_;
		}
	}

	function drawSingleCardFromStack(
		uint256 _randoms,
		uint8[13] memory _drawnCards
	) external pure returns (uint256 card_) {
		unchecked {
			uint256[AMOUNT_CARDS] memory allNumbersDecks_;
			uint256 index_ = 0;
			uint256 totalCards_ = 0;

			// Iterate over the 4 suits in the deck
			for (uint256 t = 0; t < LOOPS; ++t) {
				// Iterate over the 13 cards in each suit
				for (uint256 x = 1; x <= 13; ++x) {
					// Check if the card has already been drawn
					if (_drawnCards[x - 1] >= 1) {
						// If the card has been drawn, decrement its count and mark its spot in the deck as 0
						_drawnCards[x - 1] -= 1;
						allNumbersDecks_[index_] = 0;
					} else {
						// If the card has not been drawn, add it to the deck
						allNumbersDecks_[index_] = x;
						totalCards_ += 1;
					}
					index_++;
				}
			}

			// Check if there are still cards left in the deck
			require(totalCards_ > 0, "All cards have been drawn");

			// Perform a Fisher-Yates shuffle to randomize the deck
			for (uint256 y = AMOUNT_CARDS - 1; y >= 1; --y) {
				uint256 value_ = uint256(keccak256(abi.encodePacked(_randoms, y))) % (y + 1);
				(allNumbersDecks_[y], allNumbersDecks_[value_]) = (
					allNumbersDecks_[value_],
					allNumbersDecks_[y]
				);
			}

			// Draw the first non-zero card from the shuffled deck
			for (uint256 x = 0; x < 15; ++x) {
				uint256 value_ = allNumbersDecks_[x];
				if (value_ == 0) {
					continue;
				} else {
					card_ = value_;
					return card_;
				}
			}
		}
	}

	/**
	 * @notice This function deals the first two cards in a game of Blackjack.
	 * @param _firstCard The first card to be dealt.
	 * @param _secondCard The second card to be dealt.
	 * @return cards_ The updated cards structure after dealing the first two cards.
	 */
	function dealFirstCardsToHand(
		uint256 _firstCard,
		uint256 _secondCard
	) external pure returns (IWINRBlackJack.Cards memory cards_) {
		unchecked {
			// If the first and second cards are the same, the player can split.
			if (_firstCard == _secondCard) {
				cards_.canSplit = true;
			} else if (_firstCard >= 10 && _secondCard >= 10) {
				// If the first and second cards are both face cards (Jack, Queen, King), the player can split.
				cards_.canSplit = true;
			}

			// Set the amount of cards in the hand to 2.
			cards_.amountCards = 2;
			cards_.cards[0] = uint8(_firstCard);
			cards_.cards[1] = uint8(_secondCard);

			// If the card is a face card (Jack, Queen, King), count it as 10.
			uint8 firstCardValue = (_firstCard > 10) ? 10 : uint8(_firstCard);
			uint8 secondCardValue = (_secondCard > 10) ? 10 : uint8(_secondCard);

			// If the first card is an Ace.
			if (_firstCard == 1) {
				firstCardValue = 11; // Count the Ace as 11.
				cards_.isSoftHand = true; // Mark the hand as soft.

				// If the second card is also an Ace.
				if (_secondCard == 1) {
					cards_.totalCount = 12; // The total count is 12.
					return cards_;
				} else {
					// If the second card is not an Ace, add its value to 11.
					cards_.totalCount = 11 + secondCardValue;
					return cards_;
				}
			} else if (_secondCard == 1) {
				// If the second card is an Ace.
				cards_.isSoftHand = true; // Mark the hand as soft.
				cards_.totalCount = 11 + firstCardValue; // Add the value of the first card to 11.
				return cards_;
			} else {
				// If neither card is an Ace, just add their values.
				cards_.totalCount = firstCardValue + secondCardValue;
				return cards_;
			}
		}
	}

	function drawFirstCardsFromStack(
		uint256 _randoms,
		uint256 _amountCards
	) external pure returns (uint256[] memory topCards_) {
		unchecked {
			uint256[AMOUNT_CARDS] memory allNumbersDecks_;

			uint256 index_ = 0;

			// Iterate over the 4 suits in the deck
			for (uint256 t = 0; t < LOOPS; ++t) {
				// Iterate over the 13 cards in each suit
				for (uint256 x = 1; x <= 13; ++x) {
					allNumbersDecks_[index_] = x;
					index_++;
				}
			}

			// Perform a Fisher-Yates shuffle to randomize the deck
			for (uint256 y = AMOUNT_CARDS - 1; y >= 1; --y) {
				uint256 value_ = uint256(keccak256(abi.encodePacked(_randoms, y))) % (y + 1);
				(allNumbersDecks_[y], allNumbersDecks_[value_]) = (
					allNumbersDecks_[value_],
					allNumbersDecks_[y]
				);
			}

			// Initialize an array to hold the drawn cards
			topCards_ = new uint256[](_amountCards);

			// Draw the first _amountCards non-zero cards from the shuffled deck
			// The loop iterates over the first 13 positions of the shuffled deck.
			// It skips over positions that have a value of 0 (which represent cards that have already been drawn).
			// As soon as it encounters a non-zero value (which represents a card that hasn't been drawn yet), it adds that value to the `topCards_` array.
			for (uint256 x = 0; x < 7; ++x) {
				uint256 value_ = allNumbersDecks_[x];
				if (x == _amountCards) {
					break;
				}
				topCards_[x] = value_;
			}

			return topCards_;
		}
	}

	/**
	 * @notice This function draws a specified number of cards from a deck of cards.
	 * @param _randoms A random number used for shuffling the deck.
	 * @param _amountCards The number of cards to draw.
	 * @param _drawnCards An array representing the cards that have already been drawn.
	 * @return topCards_ The drawn cards.
	 */
	function drawCardsFromStack(
		uint256 _randoms,
		uint256 _amountCards,
		uint8[13] memory _drawnCards
	) external pure returns (uint256[] memory topCards_) {
		unchecked {
			uint256[AMOUNT_CARDS] memory allNumbersDecks_;
			uint256 index_ = 0;

			// Iterate over the 4 suits in the deck
			for (uint256 t = 0; t < LOOPS; ++t) {
				// Iterate over the 13 cards in each suit
				for (uint256 x = 1; x <= 13; ++x) {
					// Check if the card has already been drawn
					if (_drawnCards[x - 1] >= 1) {
						// If the card has been drawn, decrement its count and mark its spot in the deck as 0
						_drawnCards[x - 1] -= 1;
						allNumbersDecks_[index_] = 0;
					} else {
						// If the card has not been drawn, add it to the deck
						allNumbersDecks_[index_] = x;
					}
					index_++;
				}
			}

			// Perform a Fisher-Yates shuffle to randomize the deck
			for (uint256 y = AMOUNT_CARDS - 1; y >= 1; --y) {
				uint256 value_ = uint256(keccak256(abi.encodePacked(_randoms, y))) % (y + 1);
				(allNumbersDecks_[y], allNumbersDecks_[value_]) = (
					allNumbersDecks_[value_],
					allNumbersDecks_[y]
				);
			}

			// Initialize an array to hold the drawn cards
			topCards_ = new uint256[](_amountCards);

			uint256 drawnCardIndex = 0;
			for (uint256 x = 0; x < AMOUNT_CARDS; ++x) {
				uint256 value_ = allNumbersDecks_[x];
				if (drawnCardIndex == _amountCards) {
					break;
				}
				if (value_ != 0) {
					topCards_[drawnCardIndex] = value_;
					drawnCardIndex++;
				}
			}

			return topCards_;
		}
	}

	function _generateRandom(uint256 _random) internal pure returns (uint256 sumOfRandoms_) {
		// generate 12 random numbers that are between 0 and 1000 (0-1)
		unchecked {
			for (uint256 i = 1; i < 13; ++i) {
				sumOfRandoms_ += ((_random / (1000 ** (i - 1))) % 1000);
			}
		}
	}

	function computeMultiplier(uint256 _random) external pure returns (uint256 multiplier_) {
		// generate 12 random numbers and sum them up, then subtract 6000 from the sum to normalize the distribution
		unchecked {
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
			return multiplier_;
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
	function chip2Token(
		uint256 _chips,
		address _token,
		uint256 _price
	) external view returns (uint256 tokenAmount_, uint256 dollarValue_) {
		unchecked {
			uint256 decimals_ = IERC20Metadata(_token).decimals();
			tokenAmount_ = ((_chips * (10 ** (30 + decimals_)))) / _price;
			dollarValue_ = (tokenAmount_ * _price) / (10 ** decimals_);
			return (tokenAmount_, dollarValue_);
		}
	}

	/**
	 * @param _chips amount of chips
	 * @param _decimals decimals of token
	 * @param _price price of token (scaled 1e30)
	 */
	function chip2TokenDecimals(
		uint256 _chips,
		uint256 _decimals,
		uint256 _price
	) external pure returns (uint256 tokenAmount_) {
		unchecked {
			tokenAmount_ = ((_chips * (10 ** (30 + _decimals)))) / _price;
			return tokenAmount_;
		}
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
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IWINRBlackJack
 * @author balding-ghost
 * @notice Interface for the WINRBlackJack contract
 */
interface IWINRBlackJack {
	struct Hand {
		address player;
		address wagerAsset;
		uint96 gameIndex;
		uint16 chipsAmount;
		uint96 betAmount;
		HandStatus status;
		bool isInsured;
		bool isDouble;
	}

	struct Game {
		uint64 activeHandIndex;
		uint64 randomness;
		uint32 amountHands;
		uint32 timestamp;
		bool canInsure;
		bool awaitingRandomness;
		GameStatus status;
	}

	/**
	 * Cards represented as 1=13 with 1 being Ace and 13 being King.
	 *  Of course ace can count as 1 or 11 depending on the hand.
	 *  If the hand is soft, it means that the ace is counted as 11. If the hand is hard, it means that the ace is counted as 1.
	 *  the isSoftHand flag is used to determine if the hand is soft or hard.
	 *
	 *  An ace counted as 11 is still represented as 1 in the cards array.
	 *  It is the isSoftHand flag that determines if the hand is soft or hard and if the ace counts as 1 or 11 poins.
	 *
	 *  If a hand is hard and the player hits and gets an ace that is counted as 11, the hand becomes soft. Or if a hand is soft and the player hits and gets a card that is not an ace, the hand becomes hard if the total count is over 21.
	 *
	 *
	 *  If a hand does not have any aces it is by default hard (so isSoftHand is false). As soon as an ace is added to the hand, the hand becomes soft (so isSoftHand is true) - but only if the ace is counted as 11 points. If the hand is soft and the total count goes over 21, the hand becomes hard (so isSoftHand is false). If the hand is hard and the total count is over 21, the hand becomes bust (so isBust is true).
	 *
	 *  Due to the count it is only possible for a player to have 1 soft ace in a hand. If the player has 2 aces, one of them must be counted as 1 point. If the player has 3 aces, 2 of them must be counted as 1 point. And so on.
	 */
	struct Cards {
		uint8[8] cards;
		uint8 amountCards;
		uint8 totalCount;
		bool isSoftHand;
		bool canSplit;
	}

	enum GameStatus {
		NONE, // 0
		TABLE_DEAL, // 1
		PLAYER_TURN, // 2
		DEALER_TURN, // 3
		FINISHED // 4
	}

	enum HandStatus {
		NONE, // 0
		PLAYING, // 1
		AWAITING_HIT, // 2
		STAND, // 3
		BUST, // 4
		BLACKJACK // 5
	}

	// note for dune analytics - Blackjack is turn based game also depending on the cards the gamn If go on longer (more cards). Due to this there is a variance in how much events are emitted per game depending on how many cards are drawn.

	// PlayerHandInfo is emitted every time a player hand is updated. If a player has 2 hands, this event is emitted twice per game. If the player has 3 hands, this event is emitted 3 times per game. And so on.
	event PlayerHandInfo(
		address indexed player,
		uint256 handIndex,
		uint256 indexed gameIndex,
		HandStatus handStatus,
		bool isInsured,
		bool isDouble,
		bool canInsure,
		uint8 totalCount,
		GameStatus gameStatus,
		uint64 activeHandIndex,
		uint8[8] cards,
		bool isSoftHand
	);

	// DealerHandInfo is emitted once per card that the dealer draws. If the dealer draws 5 cards, this event is emitted 5 times. And so on.
	event DealerHandInfo(
		uint96 indexed gameIndex,
		uint8[8] cards,
		uint8 totalCount,
		bool isSoftHand
	);

	// HandCreated is emitted once per hand that is created. If a player has 2 hands, this event is emitted twice per game. If the player has 3 hands, this event is emitted 3 times per game. And so on. If a player splits a hand, a new hand is created and this event is emitted.
	event HandCreated(
		uint256 indexed handIndex_,
		address indexed player_,
		address wagerAsset_,
		uint256 gameIndex_,
		uint256 chipAmount
	);

	/**  
	If you want to build up a database of all games and the final hands you need to listen to the PlayerHandInfo for player hands and use DealerHandInfo for the dealer ahd. As noted these events are emitted multiple times per had.

	Probably for indexing you need to listen to all the HandCreated events to get the handIndex of the hand in a game. As per blackjack you start with a certain amount of hands and then if a player splits a hand is added. So you will need to craeate a gameIndex -> [handIndex_first_hand, handIndex_second_hand, etc]
	
	To get the final hand of the player (so a hand in a game is indetified by handIndex). Getting the final PlayerHandInfo is important otherwise it will seem like the player stands on a low total count. The 'final' PlayerHandInfo can be found by using the data from the event with the handStaus HandStatus.STAND, HandStatus.BUST or HandStatus.BLACKJACK is the hand of the player(so this is handStatus: 3,4 or 5). Or course totalCount is the players total count of the hand. If you want to know the cards the player had you can use the cards array - note that the ace is represented as 1 in the cards array. The cards have no colour or type, so all cards just have a number. 

	Unfortunately for the DealerHandInfo you cannot filter what is the last event (well except if you can use the last DealerHandInfo emitted in the game). Or you can catch them all and use the one with the highest totalCount.

	So in steps, always index/filter on gameIndex obviously:
	- Listen to HandCreated to get the handIndex of the hand in a game, now you know what handIndex to listen to for the game.
	- Listen to PlayerHandInfo for the player hands in the game. This event is emitted multiple times per hand. Only use the data from the event where the handStatus is HandStatus.STAND, HandStatus.BUST or HandStatus.BLACKJACK (4,5,6). This is the final hand of the player.
	- Listen to DealerHandInfo for the dealer hands in the game. This event is emitted multiple times per hand. Only use the data from the event with the highest totalCount. This is the final hand of the dealer.
	- Listen to Settled to get the result of the game. This event is emitted once per game.
	*/

	enum GameResult {
		DEALER_BLACKJACK_HAND_PUSH, // 0
		DEALER_BLACKJACK_PLAYER_LOST, // 1
		DEALER_BLACKJACK_PLAYER_INSURED, // 2
		DEALER_BUST_PLAYER_LOST, // 3
		DEALER_BUST_PLAYER_WIN, // 4
		DEALER_BUST_PLAYER_BLACKJACK, // 5
		DEALER_STAND_HAND_PUSH, // 6
		DEALER_STAND_PLAYER_WIN, // 7
		DEALER_STAND_PLAYER_LOST // 8
	}

	event Settled(
		address indexed player,
		uint256 handIndex,
		address token,
		uint256 betAmount,
		uint256 wagerWithMultiplier,
		GameResult result,
		uint256 payout
	);

	event DealerTurn(address indexed player_);

	event HandInsured(uint256 indexed handIndex_, uint256 costInsurance_);

	event RequestHandHit(uint256 indexed handIndex_);

	event HandSplit(uint256 indexed handIndex_, uint256 newHandIndex_);

	event HandDoubleDown(uint256 indexed handIndex_, uint256 newBetAmount_);

	event HandStandOff(uint256 indexed handIndex_, uint64 activeHandIndex);

	function returnActivePlayer(address _player) external view returns (uint256 gameIndex_);

	function returnGame(address _player) external view returns (IWINRBlackJack.Game memory game_);

	function returnHand(
		uint256 _handIndex
	) external view returns (IWINRBlackJack.Hand memory hand_);

	// function returnCards(
	// 	uint256 _handIndex
	// ) external view returns (IWINRBlackJack.Cards memory cards_);

	function returnSplitCouple(uint256 _handIndex) external view returns (uint256);

	function returnHandIndexesInGame(address _player) external view returns (uint32[5] memory);

	function reRequestRandomness(address _player) external;

	function setGameResolvedByRefund(address _player) external;

	// function returnActiveHandsInGame(address _player) external view returns (bool[5] memory);
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