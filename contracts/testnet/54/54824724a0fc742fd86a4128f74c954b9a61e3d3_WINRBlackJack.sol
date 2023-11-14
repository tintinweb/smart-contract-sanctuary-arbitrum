// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../../core/CoreLight.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./HelperBlackJack.sol";
import "./IWINRBlackJack.sol";
// import "forge-std/Test.sol";

/**
 * @title WINRBlackJack
 * @author balding-ghost
 * @notice This contract implements the game logic for a game of Blackjack.
 */
contract WINRBlackJack is IWINRBlackJack, CoreLight {
    using EnumerableSet for EnumerableSet.UintSet;

    uint64 public constant houseEdge = 98;
    uint256 public constant dealerStandOn = 17;
    uint256 public constant minWagerAmount = 1e17;
    uint256 public constant dealerHandIndexIncrement = 1e7;
    uint8 public constant maxHands = 5;

    // enumerable mapping that stores the active hands in a game
    // gameIndex -> handIndex[]
    mapping(uint256 => EnumerableSet.UintSet) private _activeGameIndexToHandIndexSet;

    // enumerable mapping that stores the completed hands of a game
    // gameIndex -> handIndex[]
    mapping(uint256 => EnumerableSet.UintSet) private _completedGameIndexToHandIndexSet;

    // mapping that stores the 'twin' of a split hand. So if you split handIndex 10 then the twin index could be 11 (or it could be any number since more hands could have been started in the time you got dealt your card)
    mapping(uint256 => uint256) internal splitCouple;

    // gameIndex -> Game
    mapping(uint256 => Game) internal games;

    // gameIndex -> bool if game is awaiting randomness (if it is false it means the game is done, or waiting for a player to decide)
    // mapping(uint256 => bool) internal awaitingRandomness;

    // handIndex -> Hand
    mapping(uint256 => Hand) internal hands;

    /**
     * note the cards mapping is used for both the dealer and the player
     * when storing the cards of the dealer, the gameIndex is used as the key
     * when storing the cards of the player, the handIndex is used as the key
     * to prevent overlap between the two, the gameIndex starts at 1e7
     *
     * so the cards of the dealer as well as the player are stored in the same mapping
     * if you want to know what cards the dealer has, you can look up the gameIndex in the cards mapping
     * if you want to know what cards a player has, you can look up the handIndex in the cards mapping
     */
    // gameIndex/HandIndex -> Cards
    mapping(uint256 => Cards) internal cards;

    // requestId -> gameIndex
    mapping(uint256 => uint256) internal requestIdToGameIndex;

    uint256 internal randomness_;

    // index of the game
    uint256 internal gameIndex = 1e7; // game index starts at 1e7

    uint256 internal handIndex = 1; // hand index starts at 1

    // uint256 public totalPayedIn; // note for testing only

    // uint256 public totalPayedOut; // note for testing only

    constructor(IRandomizerRouter _router) CoreLight(_router) {}

    /**
     * @notice This function is used to place a bet for a game. If the _doubleHand parameter is true, the player will play two hands.
     * @param _betAmount The amount of the bet.
     * @param _tokenAddress The address of the token used for the bet.
     * @param _amountHands The amount of hands the player wants to play.
     * @return gameIndex_ The index of the game.
     * @return handIndex_ The index of the hand for which the bet is placed.
     */
    function bet(uint256 _betAmount, address _tokenAddress, uint256 _amountHands)
        external
        returns (uint256 gameIndex_, uint256 handIndex_)
    {
        gameIndex_ = _createGame(); // Create a new game
        if (_amountHands == 1) {
            // If _doubleHand is true, the player wants to play two hands
            handIndex_ = _addHandToGame(_betAmount, gameIndex_, _tokenAddress); // Place the bet for the first hand
        } else if (_amountHands == 2) {
            handIndex_ = _addHandToGame(_betAmount, gameIndex_, _tokenAddress); // Place the bet for the hand
            _addHandToGame(_betAmount, gameIndex_, _tokenAddress); // Place the bet for the second hand
        } else if (_amountHands == 3) {
            handIndex_ = _addHandToGame(_betAmount, gameIndex_, _tokenAddress); // Place the bet for the hand
            _addHandToGame(_betAmount, gameIndex_, _tokenAddress); // Place the bet for the second hand
            _addHandToGame(_betAmount, gameIndex_, _tokenAddress); // Place the bet for the third hand
        } else {
            revert("Blackjack: Invalid amount of hands");
        }
        _requestRandomnessIfPossible(gameIndex_, 1); // Request randomness for the game
        return (gameIndex_, handIndex_); // Return the game index and the hand index
    }

    /**
     * @notice This function is called by the VRF (Verifiable Random Function) to provide randomness for the game.
     * Depending on the state of the game, the VRF's randomness is used either for a hit, split, double, or dealer card.
     * @param _requestId The ID of the randomness request.
     * @param _randoms The array of random numbers provided by the VRF.
     */
    function randomizerFulfill(uint256 _requestId, uint256[] calldata _randoms) internal override {
        uint256 _gameIndex = requestIdToGameIndex[_requestId]; // Get the game index associated with the requestId
        games[_gameIndex].awaitingRandomness = false; // Set the awaitingRandomness flag to false
        // delete awaitingRandomness[_gameIndex]; // Delete the game from the awaitingRandomness mapping
        Game memory game_ = games[_gameIndex]; // Get the game

        if (game_.status == GameStatus.TABLE_DEAL) {
            unchecked {
                // If the game is in the TABLE_DEAL status, calculate the amount of cards to deal (1 for dealer, 2 for each hand)
                uint256 amountCards_ = (_activeGameIndexToHandIndexSet[_gameIndex].length() * 2) + 1;

                // Draw cards from the stack
                uint256[] memory topCards_ =
                    HelperBlackJack.drawCardsFromStack(_randoms[0], amountCards_, game_.drawnCards);

                uint256 index_;

                // Deal the drawn cards to the players hands
                for (uint256 i = 1; i < amountCards_; i += 2) {
                    uint256 handIndex_ = _activeGameIndexToHandIndexSet[_gameIndex].at(index_);
                    bool hasBlackjack_ = _dealFirstCardsToHand(handIndex_, topCards_[i], topCards_[i + 1]);
                    if (!hasBlackjack_) {
                        // this is needed since if a previous hand has blackjack, it will be removed from the active set, so the index will be off, therefor if the hand has blackjack, we don't increment the index
                        index_++;
                    }
                }

                // Prepare dealer's cards
                Cards memory dealerCards_ = cards[_gameIndex];
                dealerCards_.firstCard = uint8(topCards_[0]);

                // Get the value of the dealer's first card
                uint256 firstCardValue_ = (dealerCards_.firstCard > 10) ? 10 : dealerCards_.firstCard;

                // set canInsure to true if dealerCard1 is an ace
                if (dealerCards_.firstCard == 1) {
                    firstCardValue_ = 11;
                    dealerCards_.isSoftHand = true;
                    // set canInsure to true if dealerCard1 is an ace
                    game_.canInsure = true;
                }

                dealerCards_.totalCount = uint8(firstCardValue_);
                dealerCards_.amountCards = 1;

                // store the drawn cards in the game so that they cannot be drawn again
                for (uint256 i = 0; i < amountCards_; ++i) {
                    game_.drawnCards[topCards_[i] - 1] += 1;
                }

                cards[_gameIndex] = dealerCards_; // Update the dealer's cards in the contract's storage
            }

            // If there are no more hands to draw, move to the dealer turn and request randomness for the dealer to solve the game
            // If there are more hands to draw, set the next hand to draw
            if (_activeGameIndexToHandIndexSet[_gameIndex].length() == 0) {
                // if there are no more hands to draw, we can move to the dealer turn
                game_.status = GameStatus.DEALER_TURN;
                game_.activeHandIndex = 0; // No more hands to draw, so set activeHandIndex to 0
                games[_gameIndex] = game_; // Update the game in the contract's storage
                // cards[_gameIndex] = dealerCards_; // Update the dealer's cards in the contract's storage

                // Request randomness for the dealer to solve the game
                _requestRandomnessIfPossible(_gameIndex, 1);
                return;
            } else {
                // If there are more hands to draw, we set the next hand to draw
                game_.activeHandIndex = uint64(_activeGameIndexToHandIndexSet[_gameIndex].at(0));
                emit NextHandsTurn(_gameIndex, game_.activeHandIndex); // Emit an event to log the player's turn
                game_.status = GameStatus.PLAYER_TURN; // Update the game's status to PLAYER_TURN
                games[_gameIndex] = game_; // Update the game in the contract's storage
                // cards[_gameIndex] = dealerCards_; // Update the dealer's cards in the contract's storage
                return;
            }
        } else if (game_.status == GameStatus.PLAYER_TURN) {
            // If the game is in the PLAYER_TURN status, draw a card for a hit or split
            if (_randoms.length == 2) {
                // This is a split hand
                uint256 topCard1_ = HelperBlackJack.drawSingleCardFromStack(_randoms[0], game_.drawnCards);
                unchecked {
                    game_.drawnCards[topCard1_ - 1] += 1; // Store the drawn card in the game
                }
                _dealCardToHand(game_.activeHandIndex, topCard1_); // Deal the drawn card to the hand

                // Get the twin of this hand
                uint256 splitIndex_ = splitCouple[game_.activeHandIndex];
                // require(splitIndex_ != 0, "Blackjack: Hand is not split"); // note unnessary check but for testing
                uint256 topCard2_ = HelperBlackJack.drawSingleCardFromStack(_randoms[1], game_.drawnCards);
                unchecked {
                    game_.drawnCards[topCard2_ - 1] += 1; // Store the drawn card in the game
                }
                game_.activeHandIndex = games[_gameIndex].activeHandIndex; // Update the game's activeHandIndex in case the first dealt dealt hand was a blackjack/21
                games[_gameIndex] = game_; // Update the game in the contract's storage
                _dealCardToHand(splitIndex_, topCard2_); // Deal the drawn card to the hand
                // log active hand index
                return;
            } else {
                uint256 topCard_ = HelperBlackJack.drawSingleCardFromStack(_randoms[0], game_.drawnCards);
                unchecked {
                    game_.drawnCards[topCard_ - 1] += 1; // Add the drawn card to the game
                }
                games[_gameIndex] = game_; // Update the game in the contract's storage
                _dealCardToHand(game_.activeHandIndex, topCard_); // Deal the drawn card to the hand
                return;
            }
        } else if (game_.status == GameStatus.DEALER_TURN) {
            // If the game is in the DEALER_TURN status, draw cards for the dealer
            // if we have 1 deck the max amount of cards a dealer can ever get is 6; Ace, Ace, Ace, Ace, 2, 2 = 18 (stand)
            uint256[] memory topCards_ = HelperBlackJack.drawCardsFromStack(_randoms[0], 6, game_.drawnCards);
            randomness_ = _randoms[0]; // Store the randomness in the contract's storage
            _dealCardsToDealer(_gameIndex, topCards_); // Deal the drawn cards to the dealer
            return;
        } else {
            // If the game is in NONE or FINISHED status, revert
            revert("Blackjack: Game is in invalid state");
        }
    }

    /**
     * @notice This function allows a player to hit another card in a game of Blackjack.
     * @param _handIndex The index of the player's hand.
     */
    function hitAnotherCard(uint256 _handIndex) external {
        Hand memory hand_ = hands[_handIndex]; // Get the player's hand

        _checkState(_handIndex); // Check the state of the hand

        hand_.status = HandStatus.AWAITING_HIT; // Update the hand's status to AWAITING_HIT

        _requestRandomnessIfPossible(hand_.gameIndex, 1); // Request randomness for the next card

        hands[_handIndex] = hand_; // Update the hand in the contract's storage

        // Emit an event to log the hit action
        emit RequestHandHit(_handIndex);
    }

    /**
     * @notice This function allows a player to split their hand in a game of Blackjack.
     * @param _handIndex The index of the player's hand.
     * @return newHandIndex_ The index of the newly created hand.
     */
    function splitHand(uint256 _handIndex) external returns (uint256 newHandIndex_) {
        Hand memory hand_ = hands[_handIndex]; // Get the player's hand
        Cards memory cards_ = cards[_handIndex]; // Get the cards of the hand

        uint256 _gameIndex = hand_.gameIndex; // Get the game index

        // check if the split doesn't exceed the max hands
        require(
            _activeGameIndexToHandIndexSet[_gameIndex].length() + _completedGameIndexToHandIndexSet[_gameIndex].length()
                < maxHands,
            "Blackjack: Max hands exceeded"
        );

        _checkState(_handIndex); // Check the state of the hand

        uint256 betAmount_ = hand_.betAmount; // Get the bet amount of the hand
        vaultManager.escrow(hand_.wagerAsset, msg.sender, betAmount_); // Escrow the bet amount of the split hand
        newHandIndex_ = _initHand(msg.sender, hand_.wagerAsset, _gameIndex, betAmount_); // Initialize a new hand with the same details as the original hand
        splitCouple[_handIndex] = newHandIndex_; // Store the index of the new hand in the splitCouple mapping

        // Ensure the hand is not insured
        require(hand_.insuranceAmount == 0, "Blackjack: Hand cannot be split if insured");

        cards_ = HelperBlackJack.splitHandHelper(cards_); // Split the cards of the hand

        cards[newHandIndex_] = cards_; // Store the cards of the new hand
        cards[_handIndex] = cards_; // Update the cards of the original hand
        hands[newHandIndex_].status = HandStatus.AWAITING_HIT; // Update the status of the new hand to AWAITING_HIT
        hands[_handIndex].status = HandStatus.AWAITING_HIT; // Update the status of the original hand to AWAITING_HIT

        // Add the new hand to the active set
        _activeGameIndexToHandIndexSet[_gameIndex].add(newHandIndex_);

        // Request randomness for both splits
        _requestRandomnessIfPossible(_gameIndex, 2);

        // Emit an event to log the hand split
        emit HandSplit(_handIndex, newHandIndex_);

        return newHandIndex_; // Return the index of the newly created hand
    }

    /**
     * @notice This function allows a player to buy insurance for their hand in a game of Blackjack.
     * @param _handIndex The index of the player's hand.
     */
    function buyInsurance(uint256 _handIndex) external {
        Hand memory hand_ = hands[_handIndex]; // Get the player's hand

        // Check if the hand is in play. If the player has blackjack, they are not playing anymore
        require(hand_.status == HandStatus.PLAYING, "Blackjack: Hand is not playing (or has blackjack)");

        // Check if the hand belongs to the sender
        require(hand_.player == msg.sender, "Blackjack: Hand is not yours");

        // Check if the hand is already insured
        require(hand_.insuranceAmount == 0, "Blackjack: Hand is already insured");

        // Check if the hand can be insured, only if the player has 2 cards
        require(cards[_handIndex].newCard == 0, "Blackjack: Hand cannot be insured");

        // Check if the dealer has an ace
        // Game memory game_ = games[hand_.gameIndex];
        require(games[hand_.gameIndex].canInsure, "Blackjack: Dealer does not have an ace");

        // The cost of insurance is half of the hand's bet amount
        uint256 costInsurance_ = hand_.betAmount / 2;

        // Escrow the cost of insurance and pay it in
        vaultManager.escrow(hand_.wagerAsset, msg.sender, costInsurance_);
        vaultManager.payin(hand_.wagerAsset, costInsurance_);

        // Update the total amount paid in
        // unchecked {
        //     totalPayedIn += costInsurance_;
        // }

        // Set the insurance amount for the hand
        hands[_handIndex].insuranceAmount = uint96(costInsurance_);

        // Emit an event to log the insurance purchase
        emit HandInsured(_handIndex, costInsurance_);
    }

    /**
     * @notice This function allows a player to stand on their hand in a game of Blackjack.
     * @param _handIndex The index of the player's hand.
     */
    function standOff(uint256 _handIndex) external {
        _requireNotPaused();
        Hand memory hand_ = hands[_handIndex]; // Get the player's hand
        uint256 _gameIndex = hand_.gameIndex; // Get the game index

        /**
         * It is possible that a player stops responding when it is their turn.
         *     To handle this we allow the owner of this contract to stand off a hand on behalf of a player.
         *     This way we can prevent that a game gets stuck because a player does not respond.
         */

        // Check the state of the hand if the sender is not the owner
        if (msg.sender != owner()) {
            _checkState(_handIndex);
        }

        // Update the hand's status to STAND
        hands[_handIndex].status = HandStatus.STAND;

        // Emit an event to log the stand off action
        emit HandStandOff(_handIndex);

        // Remove the hand from the active hands set and add it to the completed hands set
        _removeAndAddHand(_gameIndex, _handIndex);

        // Check if there are any active hands left in the game
        if (_activeGameIndexToHandIndexSet[_gameIndex].length() == 0) {
            // If there are no active hands left, it's the dealer's turn
            // Update the game status to DEALER_TURN and request randomness for the dealer to draw cards
            games[_gameIndex].status = GameStatus.DEALER_TURN;
            _requestRandomnessIfPossible(_gameIndex, 1);
            return;
        } else {
            // If there are active hands left, it's the next hand's turn
            // Update the activeHandIndex index to the index of the next active hand and emit an event to log the turn of the next hand
            games[_gameIndex].activeHandIndex = uint64(_activeGameIndexToHandIndexSet[_gameIndex].at(0));
            emit NextHandsTurn(_gameIndex, games[_gameIndex].activeHandIndex);
            return;
        }
    }

    /**
     * @notice This function allows a player to double down on their hand in a game of Blackjack.
     * @param _handIndex The index of the player's hand.
     */
    function doubleDown(uint256 _handIndex) external {
        Hand memory hand_ = hands[_handIndex]; // Get the player's hand

        // Ensure the hand has not already been doubled
        require(!hand_.isDouble, "Blackjack: Hand is already doubled");

        hand_.isDouble = true; // Mark the hand as doubled
        // uint256 _gameIndex = hand_.gameIndex; // Get the game index

        _checkState(_handIndex); // Check the state of the hand

        hand_.status = HandStatus.AWAITING_HIT; // Update the hand's status to AWAITING_HIT

        Cards memory cards_ = cards[_handIndex]; // Get the cards of the hand

        // Ensure the player only has 2 cards (i.e., the player has not hit yet)
        require(cards_.amountCards == 2, "Blackjack: Hand cannot be doubled");

        // Double the bet amount
        uint256 betAmount_ = hand_.betAmount;
        uint256 newBetAmount_ = betAmount_ * 2;

        // Escrow the additional bet amount
        vaultManager.escrow(hand_.wagerAsset, msg.sender, betAmount_);

        hand_.betAmount = uint96(newBetAmount_); // Update the bet amount of the hand

        _requestRandomnessIfPossible(hand_.gameIndex, 1); // Request randomness for the next card

        hands[_handIndex] = hand_; // Update the hand in the contract's storage

        // Emit an event to log the double down action
        emit HandDoubleDown(_handIndex, newBetAmount_);
    }

    // INTERNAL FUNCTIONS

    function _createGame() internal returns (uint256 gameIndex_) {
        gameIndex_ = gameIndex;
        games[gameIndex_].status = GameStatus.TABLE_DEAL;
        gameIndex++;
        emit GameStarted(gameIndex_);
        return gameIndex_;
    }

    /**
     * @notice This function initializes a new hand for a player in a game of Blackjack.
     * @param _player The address of the player who is playing the hand.
     * @param _wagerAsset The address of the token that the player is using to bet.
     * @param _gameIndex The index of the game in which the hand is being played.
     * @param _betAmount The amount that the player is betting on the hand.
     * @return handIndex_ The index of the newly created hand.
     */
    function _initHand(address _player, address _wagerAsset, uint256 _gameIndex, uint256 _betAmount)
        internal
        returns (uint256 handIndex_)
    {
        handIndex_ = handIndex; // Get the current hand index
        Hand memory hand_ = hands[handIndex_]; // Create a new hand
        hand_.player = _player; // Set the player of the hand
        hand_.wagerAsset = _wagerAsset; // Set the wager asset of the hand
        hand_.gameIndex = uint64(_gameIndex); // Set the game index of the hand
        hand_.betAmount = uint96(_betAmount); // Set the bet amount of the hand
        handIndex++; // Increment the hand index for the next hand
        hands[handIndex_] = hand_; // Store the hand in the contract's storage
        emit HandCreated(handIndex_, _player, _wagerAsset, _gameIndex, _betAmount); // Emit an event for the creation of the hand
        return handIndex_; // Return the index of the newly created hand
    }

    function _checkWagerReturn(uint256 _betAmount, address _token) internal view returns (uint256) {
        uint256 price_ = vaultManager.getPrice(_token);
        (uint256 tokenAmount_, uint256 dollarValue_) = HelperBlackJack.chip2Token(_betAmount, _token, price_);
        require(dollarValue_ <= vaultManager.getMaxWager(), "Blackjack: wager is too big");
        require(dollarValue_ >= minWagerAmount, "Blackjack: Wager too low");
        return tokenAmount_;
    }

    /**
     * @notice This function deals the first two cards to a hand in a game of Blackjack.
     * @param _handIndex The index of the hand.
     * @param _firstCard The first card to be dealt.
     * @param _secondCard The second card to be dealt.
     * @return _isBlackjack A boolean indicating whether the hand is a blackjack (i.e., the total count of the cards is 21).
     */
    function _dealFirstCardsToHand(uint256 _handIndex, uint256 _firstCard, uint256 _secondCard)
        internal
        returns (bool _isBlackjack)
    {
        // Call the dealFirstCardsToHand function from the HelperBlackJack contract
        // This function updates the hand's cards based on the first and second cards
        Cards memory cards_ = HelperBlackJack.dealFirstCardsToHand(_firstCard, _secondCard);
        Hand memory hand_ = hands[_handIndex];

        // Check if the hand is in the initial state
        require(hand_.status == HandStatus.NONE, "Blackjack: Hand is not in initial state");
        if (cards_.totalCount == 21) {
            // If the total count of the cards is 21, the hand is a blackjack
            // Update the hand's status to BLACKJACK and remove it from the active hands set
            hand_.status = HandStatus.BLACKJACK;
            _removeAndAddHand(hand_.gameIndex, _handIndex);
            _isBlackjack = true;
        } else {
            // If the total count of the cards is not 21, the hand is still playing
            // Update the hand's status to PLAYING
            hand_.status = HandStatus.PLAYING;
        }
        // Update the hand and its cards in the contract's storage
        hands[_handIndex] = hand_;
        cards[_handIndex] = cards_;
        // Emit an event to log the dealt cards and their total count
        emit HandDealt(_handIndex, _firstCard, _secondCard, cards_.totalCount);

        return (_isBlackjack);
    }

    /**
     * @notice This function processes the completion of a hand in a game of Blackjack.
     * @param _gameIndex The index of the game.
     * @param _handIndex The index of the hand.
     */
    function _processHandCompleted(uint256 _gameIndex, uint256 _handIndex) internal {
        // Remove the completed hand from the active hands set and add it to the completed hands set
        _removeAndAddHand(_gameIndex, _handIndex);

        // Check if there are any active hands left in the game
        if (_activeGameIndexToHandIndexSet[_gameIndex].length() == 0) {
            // If there are no active hands left, it's the dealer's turn
            // Update the game status to DEALER_TURN and reset the activeHandIndex index
            games[_gameIndex].status = GameStatus.DEALER_TURN;
            games[_gameIndex].activeHandIndex = 0;
            // Request randomness for the dealer to draw cards
            _requestRandomnessIfPossible(_gameIndex, 1);
            // Emit an event to log the dealer's turn
            emit DealerTurn(_gameIndex);
        } else {
            // If there are active hands left, it's the next hand's turn
            // Update the activeHandIndex index to the index of the next active hand
            games[_gameIndex].activeHandIndex = uint64(_activeGameIndexToHandIndexSet[_gameIndex].at(0));
            // Emit an event to log the turn of the next hand
            emit NextHandsTurn(_gameIndex, games[_gameIndex].activeHandIndex);
        }
    }

    /**
     * @notice This function deals a card to a player's hand in a game of Blackjack.
     * @param _handIndex The index of the player's hand.
     * @param _card The card to be dealt.
     */
    function _dealCardToHand(uint256 _handIndex, uint256 _card) internal {
        // Call the dealCardToHand function from the HelperBlackJack contract
        // This function updates the player's hand and cards based on the new card
        (Hand memory hand_, Cards memory cards_) =
            HelperBlackJack.dealCardToHand(hands[_handIndex], cards[_handIndex], _card);

        // Check the status of the player's hand after dealing the new card
        if (hand_.status != HandStatus.PLAYING) {
            // If the player's hand is not in the PLAYING state (e.g., the player has busted or achieved a blackjack),
            // process the completion of the hand
            _processHandCompleted(hand_.gameIndex, _handIndex);
        }

        // log active hand index
        // else {
        //     // If the player's hand is still in the PLAYING state, update the hand's status to PLAYING
        //     hand_.status = HandStatus.PLAYING;
        // }
        // Update the player's hand and cards in the contract's storage
        hands[_handIndex] = hand_;
        cards[_handIndex] = cards_;
        // Emit an event to log the hit action
        emit HandHit(_handIndex, _card, cards_.totalCount);
    }

    /**
     * @notice This function deals cards to the dealer in a game of Blackjack.
     * @param _gameIndex The index of the game.
     * @param _cardsToDealer An array of cards to be dealt to the dealer.
     */
    function _dealCardsToDealer(uint256 _gameIndex, uint256[] memory _cardsToDealer) internal {
        // note this is a logical check but technically redundant
        // require(
        //   _activeGameIndexToHandIndexSet[_gameIndex].length() == 0,
        //   "Blackjack: Not all hands are completed"
        // );
        unchecked {
            // Change the game status to FINISHED
            games[_gameIndex].status = GameStatus.FINISHED;
            // Get the dealer's current cards
            Cards memory dealerCards_ = cards[_gameIndex];
            // Deal the first card from _cardsToDealer to the dealer
            dealerCards_ = HelperBlackJack.hitDealerWithCard(dealerCards_, uint8(_cardsToDealer[0]));
            // Set the second card of the dealer
            dealerCards_.secondCard = uint8(_cardsToDealer[0]);
            // Check if the dealer has a blackjack (a total count of 21)
            if (dealerCards_.totalCount == 21) {
                // revert("Blackjack: Dealer has blackjack");
                // If the dealer has a blackjack, update the dealer's cards and emit an event
                cards[_gameIndex] = dealerCards_;
                emit DealerCardsDealt(_gameIndex, dealerCards_);
                // Process the dealer's blackjack
                _processDealerBlackjack(_gameIndex);
                return;
            } else if (dealerCards_.totalCount >= dealerStandOn) {
                // At this point, the dealer has 2 cards and doesn't have a blackjack.
                // Check if the dealer has to draw another card.
                if (dealerCards_.totalCount >= 22) {
                    // If the dealer's total count is 22 or more, the dealer busts.
                    // Update the dealer's cards, emit an event, and process the dealer's bust.
                    cards[_gameIndex] = dealerCards_;
                    emit DealerCardsDealt(_gameIndex, dealerCards_);
                    _processDealerBust(_gameIndex);
                    return;
                } else {
                    // If the dealer's total count is less than 22 and greater than or equal to dealerStandOn, the dealer stands.
                    // Update the dealer's cards, emit an event, and process the dealer's stand.
                    cards[_gameIndex] = dealerCards_;
                    emit DealerCardsDealt(_gameIndex, dealerCards_);
                    _processDealerStand(_gameIndex);
                    return;
                }
            }
            // If the dealer's total count is less than dealerStandOn, the dealer has to draw more cards.
            for (uint256 i = 1; i < 6; ++i) {
                // note this might cost more gas than needed
                dealerCards_.newCard = uint8(_cardsToDealer[i]);
                // Deal the next card from _cardsToDealer to the dealer
                dealerCards_ = HelperBlackJack.hitDealerWithCard(dealerCards_, uint8(_cardsToDealer[i]));
                // Check again if the dealer has to draw another card
                if (dealerCards_.totalCount >= dealerStandOn) {
                    if (dealerCards_.totalCount >= 22) {
                        // If the dealer's total count is 22 or more, the dealer busts.
                        // Update the dealer's cards, emit an event, and process the dealer's bust.
                        cards[_gameIndex] = dealerCards_;
                        emit DealerCardsDealt(_gameIndex, dealerCards_);
                        _processDealerBust(_gameIndex);
                        break;
                    } else {
                        // If the dealer's total count is less than 22 and greater than or equal to dealerStandOn, the dealer stands.
                        // Update the dealer's cards, emit an event, and process the dealer's stand.
                        cards[_gameIndex] = dealerCards_;
                        emit DealerCardsDealt(_gameIndex, dealerCards_);
                        _processDealerStand(_gameIndex);
                        break;
                    }
                } else {
                    // If the dealer's total count is still less than dealerStandOn, the dealer continues to draw more cards.
                    continue;
                }
            }
        }
        return;
    }

    function _returnCompletedHandsInGame(uint256 _gameIndex)
        internal
        view
        returns (uint256[] memory completedHands_, uint256 length_)
    {
        unchecked {
            EnumerableSet.UintSet storage completedHandsSet_ = _completedGameIndexToHandIndexSet[_gameIndex];
            completedHands_ = new uint256[](completedHandsSet_.length());
            for (uint256 i = 0; i < completedHandsSet_.length(); ++i) {
                completedHands_[i] = completedHandsSet_.at(i);
            }
            return (completedHands_, completedHandsSet_.length());
        }
    }

    /**
     * @notice This function processes the dealer's blackjack in a game of Blackjack.
     * @param _gameIndex The index of the game.
     */
    function _processDealerBlackjack(uint256 _gameIndex) internal {
        // Retrieve the completed hands in the game
        (uint256[] memory completedHands_, uint256 length_) = _returnCompletedHandsInGame(_gameIndex);

        // Loop through each completed hand
        for (uint256 i = 0; i < length_; ++i) {
            uint256 handIndex_ = completedHands_[i];
            Hand memory hand_ = hands[handIndex_];

            // If the player also has a blackjack, it's a push
            if (hand_.status == HandStatus.BLACKJACK) {
                _handleReferralVestedLucky(hand_, GameResult.DEALER_BLACKJACK_HAND_PUSH, hand_.betAmount, handIndex_);
                _paybackPlayer(hand_.wagerAsset, hand_.player, hand_.betAmount);
            }
            // If the player has insurance, they are paid back their bet amount
            else if (hand_.insuranceAmount != 0) {
                _handleReferralVestedLucky(
                    hand_, GameResult.DEALER_BLACKJACK_PLAYER_INSURED, hand_.betAmount, handIndex_
                );
                _paybackPlayer(hand_.wagerAsset, hand_.player, hand_.betAmount);
            }
            // If the player doesn't have a blackjack or insurance, they lose their bet
            else {
                _handleReferralVestedLucky(hand_, GameResult.DEALER_BLACKJACK_PLAYER_LOST, hand_.betAmount, handIndex_);
                _payinPlayer(hand_.wagerAsset, hand_.betAmount);
            }
        }
    }

    /**
     * @notice This function processes the dealer's bust in a game of Blackjack.
     * @param _gameIndex The index of the game.
     */
    function _processDealerBust(uint256 _gameIndex) internal {
        // Retrieve the completed hands in the game
        (uint256[] memory completedHands_, uint256 length_) = _returnCompletedHandsInGame(_gameIndex);

        // Loop through each completed hand
        for (uint256 i = 0; i < length_; ++i) {
            uint256 handIndex_ = completedHands_[i];
            Hand memory hand_ = hands[handIndex_];
            uint256 _dealerTotal = 0; // Dealer's total is 0 because dealer has busted
            uint256 _playerTotal;

            // If the player's hand has busted, set the player's total to 0
            if (hand_.status == HandStatus.BUST) {
                _playerTotal = 0;
            } else {
                // Otherwise, set the player's total to the total count of their cards
                _playerTotal = cards[handIndex_].totalCount;
            }

            // If the player has a blackjack
            if (hand_.status == HandStatus.BLACKJACK) {
                // Handle referral, vesting and emit event for the player's blackjack
                _handleReferralVestedLucky(
                    hand_,
                    GameResult.DEALER_BUST_PLAYER_BLACKJACK,
                    (2 * hand_.betAmount) + (hand_.betAmount / 2),
                    handIndex_
                );
                // Payout the player
                _payoutPlayer(
                    hand_.wagerAsset, hand_.player, hand_.betAmount, (2 * hand_.betAmount) + (hand_.betAmount / 2)
                );
            } else if (_dealerTotal == _playerTotal) {
                // If the dealer's total is equal to the player's total, the player loses
                _handleReferralVestedLucky(hand_, GameResult.DEALER_BUST_PLAYER_LOST, hand_.betAmount, handIndex_);
                _payinPlayer(hand_.wagerAsset, hand_.betAmount);
            } else {
                // If the dealer's total is not equal to the player's total, the player wins
                _handleReferralVestedLucky(hand_, GameResult.DEALER_BUST_PLAYER_WIN, hand_.betAmount * 2, handIndex_);
                _payoutPlayer(hand_.wagerAsset, hand_.player, hand_.betAmount, hand_.betAmount * 2);
            }
        }
    }

    /**
     * @notice This function processes the dealer's stand in a game of Blackjack.
     * @param _gameIndex The index of the game.
     */
    function _processDealerStand(uint256 _gameIndex) internal {
        // Retrieve the completed hands in the game
        (uint256[] memory completedHands_, uint256 length_) = _returnCompletedHandsInGame(_gameIndex);
        // Retrieve the dealer's cards
        Cards memory dealerCards_ = cards[_gameIndex];

        // Loop through each completed hand
        for (uint256 i = 0; i < length_; ++i) {
            uint256 handIndex_ = completedHands_[i];
            Hand memory hand_ = hands[handIndex_];
            uint256 _dealerTotal = dealerCards_.totalCount;
            uint256 _playerTotal;

            // If the player's hand has busted, set the player's total to 0
            if (hand_.status == HandStatus.BUST) {
                _playerTotal = 0;
            } else {
                // Otherwise, set the player's total to the total count of their cards
                _playerTotal = cards[handIndex_].totalCount;
            }

            // If the player has a blackjack
            if (hand_.status == HandStatus.BLACKJACK) {
                // Handle referral, vesting and emit event for the hand push
                _handleReferralVestedLucky(
                    hand_, GameResult.DEALER_STAND_HAND_PUSH, (2 * hand_.betAmount) + (hand_.betAmount / 2), handIndex_
                );
                // Payout the player
                _payoutPlayer(
                    hand_.wagerAsset, hand_.player, hand_.betAmount, (2 * hand_.betAmount) + (hand_.betAmount / 2)
                );
            } else if (_dealerTotal > _playerTotal) {
                // If the dealer's total is greater than the player's total, the player loses
                _handleReferralVestedLucky(hand_, GameResult.DEALER_BUST_PLAYER_LOST, hand_.betAmount, handIndex_);
                _payinPlayer(hand_.wagerAsset, hand_.betAmount);
            } else if (_dealerTotal < _playerTotal) {
                // If the dealer's total is less than the player's total, the player wins
                _handleReferralVestedLucky(hand_, GameResult.DEALER_BUST_PLAYER_WIN, hand_.betAmount * 2, handIndex_);
                _payoutPlayer(hand_.wagerAsset, hand_.player, hand_.betAmount, hand_.betAmount * 2);
            } else {
                // If the dealer's total is equal to the player's total, it's a push
                _handleReferralVestedLucky(hand_, GameResult.DEALER_STAND_HAND_PUSH, hand_.betAmount, handIndex_);
                _paybackPlayer(hand_.wagerAsset, hand_.player, hand_.betAmount);
            }
        }
    }

    /**
     * @notice This function is used to place a bet for a hand in the game.
     * @param _betAmount The amount of the bet.
     * @param _gameIndex The index of the game.
     * @param _tokenAddress The address of the token used for the bet.
     * @return handIndex_ The index of the hand for which the bet is placed.
     */
    function _addHandToGame(uint256 _betAmount, uint256 _gameIndex, address _tokenAddress)
        internal
        returns (uint256 handIndex_)
    {
        // Check the wager amount and return the actual amount to be wagered
        uint256 wagerAmount_ = _checkWagerReturn(_betAmount, _tokenAddress);

        // Initialize a new hand for the player with the wager amount
        handIndex_ = _initHand(msg.sender, _tokenAddress, _gameIndex, wagerAmount_);

        // Add the hand index to the set of active hands for the game
        _activeGameIndexToHandIndexSet[_gameIndex].add(handIndex_);

        // Escrow the wager amount from the player's account
        vaultManager.escrow(_tokenAddress, msg.sender, wagerAmount_);

        return handIndex_;
    }

    function _handleReferralVestedLucky(Hand memory _hand, GameResult _result, uint256 _payout, uint256 _handIndex)
        internal
    {
        vaultManager.setReferralReward(_hand.wagerAsset, _hand.player, _hand.betAmount, houseEdge);
        // in blackjack we use randomness per game not per hand, to save gas and flow, to prevent that every player has the same randomness (so that each player has same multiplier or that all players win the luckystrike - thereby having some players win nothing since the jackpot was already won by another player) we add handIndex to the randomness
        uint256 _random = randomness_ + _handIndex;
        uint256 wagerWithMultiplier_ = (_computeMultiplier(_random) * _hand.betAmount) / 1e3;
        vaultManager.mintVestedWINR(_hand.wagerAsset, wagerWithMultiplier_, _hand.player);
        _hasLuckyStrike(_random, _hand.player, _hand.wagerAsset, _hand.betAmount);
        emit HandSettled(
            _hand.player, _handIndex, _hand.wagerAsset, _hand.betAmount, wagerWithMultiplier_, _result, _payout
        );
    }

    function _generateRandom(uint256 _random) internal pure returns (uint256 sumOfRandoms_) {
        // generate 12 random numbers that are between 0 and 1000 (0-1)
        unchecked {
            for (uint256 i = 1; i < 13; ++i) {
                sumOfRandoms_ += ((_random / (1000 ** (i - 1))) % 1000);
            }
        }
    }

    /// @notice function to compute jackpot multiplier
    function _computeMultiplier(uint256 _random) internal pure returns (uint256 multiplier_) {
        // generate 12 random numbers and sum them up, then subtract 6000 from the sum to normalize the distribution
        int256 _sumOfRandoms = int256(_generateRandom(_random)) - 6000;

        unchecked {
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

    function _payinPlayer(address _betAsset, uint256 _betAmount) internal {
        // totalPayedIn += _betAmount;
        vaultManager.payin(_betAsset, _betAmount);
    }

    function _payoutPlayer(address _wagerAsset, address _player, uint256 _betAmount, uint256 _payoutAmount) internal {
        // totalPayedOut += (_payoutAmount - _betAmount);
        vaultManager.payout(_wagerAsset, _player, _betAmount, _payoutAmount);
    }

    function _paybackPlayer(address _betAsset, address _player, uint256 _betAmount) internal {
        vaultManager.payback(_betAsset, _player, _betAmount);
    }

    function _checkState(uint256 _handIndex) internal view {
        Hand memory _hand = hands[_handIndex];
        Game memory _game = games[_hand.gameIndex];
        require(_hand.status == HandStatus.PLAYING, "Blackjack: Hand is not playing");
        require(_hand.player == msg.sender, "Blackjack: Hand is not yours");
        require(_game.status == GameStatus.PLAYER_TURN, "Blackjack: Game is not in player turn");
        require(_game.activeHandIndex == _handIndex, "Blackjack: It is not your turn to draw a card");
    }

    /**
     * @notice This function requests randomness for a game if possible.
     * @param _gameIndex The index of the game for which randomness is being requested.
     * @param _amount The amount of randomness being requested.
     */
    function _requestRandomnessIfPossible(uint256 _gameIndex, uint256 _amount) internal nonReentrant {
        _requireNotPaused();
        // Check if the game is already waiting for randomness
        // require(!awaitingRandomness[_gameIndex], "Blackjack: Game still waiting on randomness");
        require(!games[_gameIndex].awaitingRandomness, "Blackjack: Game still waiting on randomness");

        uint256 requestId_ = _requestRandom(uint8(_amount));

        // Map the requestId to the gameIndex
        requestIdToGameIndex[requestId_] = _gameIndex;

        // Mark the game as awaiting randomness, this ensures that the game cannot request randomness again until the current request is fulfilled
        games[_gameIndex].awaitingRandomness = true;

        // Emit an event to log the randomness request for a hand
        emit RequestVRFForHand(_gameIndex, games[_gameIndex].activeHandIndex);
    }

    function _removeAndAddHand(uint256 _gameIndex, uint256 _handIndex) internal {
        // check if the hand is in the active set
        // require(
        //   _activeGameIndexToHandIndexSet[_gameIndex].contains(_handIndex),
        //   "Blackjack: Hand is not in active set"
        // );
        _activeGameIndexToHandIndexSet[_gameIndex].remove(_handIndex);
        _completedGameIndexToHandIndexSet[_gameIndex].add(_handIndex);
    }

    // VIEW FUNCTIONS

    function returnActiveHands(uint256 _gameIndex) external view returns (uint256[] memory activeHands_) {
        EnumerableSet.UintSet storage activeHandsSet_ = _activeGameIndexToHandIndexSet[_gameIndex];
        activeHands_ = new uint256[](activeHandsSet_.length());
        for (uint256 i = 0; i < activeHandsSet_.length(); ++i) {
            activeHands_[i] = activeHandsSet_.at(i);
        }
        return activeHands_;
    }

    function returnSplitCouple(uint256 _handIndex) external view returns (uint256) {
        return splitCouple[_handIndex];
    }

    function returnHand(uint256 _handIndex) external view returns (Hand memory hand_) {
        return hands[_handIndex];
    }

    function returnCards(uint256 _handIndex) external view returns (Cards memory cards_) {
        return cards[_handIndex];
    }

    function returnGame(uint256 _gameIndex) external view returns (Game memory game_) {
        return games[_gameIndex];
    }

    function returnCompletedHands(uint256 _gameIndex) external view returns (uint256[] memory completedHands_) {
        EnumerableSet.UintSet storage completedHandsSet_ = _completedGameIndexToHandIndexSet[_gameIndex];
        completedHands_ = new uint256[](completedHandsSet_.length());
        for (uint256 i = 0; i < completedHandsSet_.length(); ++i) {
            completedHands_[i] = completedHandsSet_.at(i);
        }
        return completedHands_;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IWINRBlackJack.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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
    function dealCardToHand(IWINRBlackJack.Hand memory hand_, IWINRBlackJack.Cards memory cards_, uint256 _card)
        external
        pure
        returns (IWINRBlackJack.Hand memory, IWINRBlackJack.Cards memory)
    {
        unchecked {
            // Ensure the hand is in the state where it can receive a new card
            require(hand_.status == IWINRBlackJack.HandStatus.AWAITING_HIT, "Blackjack: Hand is not awaiting hit");

            bool isSplitAces_;
            bool isSplitHand_;

            // Add the new card to the hand and update the hand status
            (cards_, isSplitAces_, isSplitHand_) = hitHandWithCard(cards_, uint8(_card));

            // The hand is now in the playing state
            hand_.status = IWINRBlackJack.HandStatus.PLAYING;

            // If the hand is a double or split aces, the player cannot take any more cards and must stand
            if (hand_.isDouble || isSplitAces_) {
                hand_.status = IWINRBlackJack.HandStatus.STAND;
            }

            // If the total count is above 21
            if (cards_.totalCount > 21) {
                // If the hand is soft (contains an Ace counted as 11), subtract 10 to count the Ace as 1 and mark the hand as hard
                if (cards_.isSoftHand) {
                    cards_.totalCount -= 10;
                    cards_.isSoftHand = false;
                } else {
                    // If the hand is hard (does not contain an Ace or contains an Ace counted as 1), the player busts
                    hand_.status = IWINRBlackJack.HandStatus.BUST;
                }
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
        }

        return (hand_, cards_);
    }

    /**
     * @notice calculates the total count of the cards and if the new hand is soft or not - for a blackjack game
     * @dev this function is used to calculate the total count of the cards and if the new hand is soft or not
     * @dev note that cards with value 11, 12 and 13 are counted as 10 - we do store them as 11, 12 and 13 in the cards struct because we need to know the exact value of the card to access if the user has a pair or not (for splitting)
     * @param _newCard the new card that was drawn from the deck, this is a value between 1 and 13
     * @param _totalCountOld the total count of the cards before the new card was drawn
     * @param _isSoftHandOld if the hand was soft before the new card was drawn
     * @return totalCountNew_ the total count of the cards after the new card was drawn
     * @return isSoftHandNew_ if the hand is soft after the new card was drawn
     */
    function calculateTotalPoints(uint8 _newCard, uint8 _totalCountOld, bool _isSoftHandOld)
        public
        pure
        returns (uint256 totalCountNew_, bool isSoftHandNew_)
    {
        unchecked {
            // Initialize the new total count and soft hand status with the old values
            totalCountNew_ = _totalCountOld;
            isSoftHandNew_ = _isSoftHandOld;

            // If the new card is an ace
            if (_newCard == 1) {
                // If the hand is already soft, count the ace as 1
                if (isSoftHandNew_) {
                    totalCountNew_ += 1;
                } else {
                    // Otherwise, count the ace as 11 and mark the hand as soft
                    totalCountNew_ += 11;
                    isSoftHandNew_ = true;
                }
            } else if (_newCard > 10) {
                // If the new card is a face card (value 11, 12, or 13), count it as 10
                totalCountNew_ += 10;
            } else {
                // Otherwise, add the value of the new card to the total count
                totalCountNew_ += _newCard;
            }

            // If the total count is over 21 and the hand is soft
            if (totalCountNew_ > 21 && isSoftHandNew_) {
                // Subtract 10 (count one of the aces as 1 instead of 11) and mark the hand as hard
                totalCountNew_ -= 10;
                isSoftHandNew_ = false;
            }
        }

        return (totalCountNew_, isSoftHandNew_);
    }

    /**
     * @notice This function adds a new card to the dealer's hand in a game of Blackjack.
     * @param cards_ The current cards in the dealer's hand.
     * @param _newCard The new card to be added to the hand.
     * @return cards_ The updated cards structure after the new card is added.
     */
    function hitDealerWithCard(IWINRBlackJack.Cards memory cards_, uint8 _newCard)
        public
        pure
        returns (IWINRBlackJack.Cards memory)
    {
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
        }

        return cards_;
    }

    /**
     * @notice This function adds a new card to the player's hand in a game of Blackjack.
     * @param cards_ The current cards in the player's hand.
     * @param _newCard The new card to be added to the hand.
     * @return cards_ The updated cards structure after the new card is added.
     * @return isSplitAces_ A boolean indicating whether the player has split aces.
     */
    function hitHandWithCard(IWINRBlackJack.Cards memory cards_, uint8 _newCard)
        public
        pure
        returns (IWINRBlackJack.Cards memory, bool isSplitAces_, bool isSplitHand_)
    {
        unchecked {
            // Increment the number of cards in the hand
            cards_.amountCards += 1;

            // If the new card is a face card (Jack, Queen, King), count it as 10
            uint256 newCardValue_ = (_newCard > 10) ? 10 : _newCard;

            // If the player has only one card (after a split)
            if (cards_.secondCard == 0) {
                cards_.secondCard = _newCard;

                // Check if the player has split aces
                isSplitAces_ = cards_.firstCard == 1 ? true : false;
                isSplitHand_ = true;

                // If the new card is an Ace and the hand is soft
                if (_newCard == 1 && cards_.isSoftHand) {
                    // Count the Ace as 1 and allow the player to split
                    newCardValue_ = 1;
                    cards_.canSplit = true;
                } else if (_newCard == 1) {
                    // If the new card is an Ace and the hand is not soft
                    // Count the Ace as 11 and mark the hand as soft
                    newCardValue_ = 11;
                    cards_.isSoftHand = true;
                } else {
                    // If the new card is not an Ace
                    // If the new card is the same as the first card, the player can split
                    if (_newCard == cards_.firstCard) {
                        cards_.canSplit = true;
                    }
                }
                // Add the value of the new card to the total count
                cards_.totalCount += uint8(newCardValue_);
            } else {
                // If the player has more than one card (not after a split)
                cards_.newCard = _newCard;

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
            }
        }

        return (cards_, isSplitAces_, isSplitHand_);
    }

    /**
     * @notice This function deals the first two cards in a game of Blackjack.
     * @param _firstCard The first card to be dealt.
     * @param _secondCard The second card to be dealt.
     * @return cards_ The updated cards structure after dealing the first two cards.
     */
    function dealFirstCardsToHand(uint256 _firstCard, uint256 _secondCard)
        external
        pure
        returns (IWINRBlackJack.Cards memory cards_)
    {
        unchecked {
            // If the first and second cards are the same, the player can split.
            if (_firstCard == _secondCard) {
                cards_.canSplit = true;
            }

            // Set the amount of cards in the hand to 2.
            cards_.amountCards = 2;
            cards_.firstCard = uint8(_firstCard);
            cards_.secondCard = uint8(_secondCard);

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

    function checkStateHelper(IWINRBlackJack.Hand memory _hand, IWINRBlackJack.Game memory _game, uint256 _handIndex)
        public
        view
    {
        require(_hand.status == IWINRBlackJack.HandStatus.PLAYING, "Blackjack: Hand is not playing");
        require(_hand.player == msg.sender, "Blackjack: Hand is not yours");
        require(_game.status == IWINRBlackJack.GameStatus.PLAYER_TURN, "Blackjack: Game is not in player turn");
        require(_game.activeHandIndex == _handIndex, "Blackjack: It is not your turn to draw a card");
    }

    /**
     * @notice This function splits the player's hand.
     * @param cards_ The current cards in the player's hand (the hand the player wants to split)
     * @return newCards_ The new hand of cards after the split.
     */
    function splitHandHelper(IWINRBlackJack.Cards memory cards_)
        external
        pure
        returns (IWINRBlackJack.Cards memory newCards_)
    {
        unchecked {
            // Ensure the hand can be split (only pairs can be split)
            require(cards_.canSplit, "Blackjack: Hand cannot be split");
            // Ensure the hand only has two cards (a hand can only be split at the start of the game)
            require(cards_.amountCards == 2, "Blackjack: Hand cannot be split more than 2 cards");

            // If the total count is 12 and the hand is soft, the player is splitting aces
            if (cards_.totalCount == 12 && cards_.isSoftHand) {
                newCards_.firstCard = 1; // The first card of the new hand is an Ace
                newCards_.secondCard = 0; // The second card of the new hand is not yet dealt
                newCards_.isSoftHand = true; // The hand is soft because it contains an Ace
                newCards_.totalCount = 11; // The total count is 11 because an Ace is counted as 11 in a soft hand
            } else {
                // If the player is not splitting aces, the first card of the new hand is the second card of the old hand (or could be the first card if the player is splitting a pair of face cards)
                newCards_.firstCard = cards_.secondCard;
                newCards_.secondCard = 0; // The second card of the new hand is not yet dealt
                // The total count is the value of the first card, or 10 if the first card is a face card
                newCards_.totalCount = (cards_.secondCard > 10) ? 10 : cards_.secondCard;
            }

            newCards_.amountCards = 1; // The new hand has one card
        }

        return newCards_;
    }

    /**
     * @notice This function draws a single card from a deck of cards.
     * @param _randoms A random number used for shuffling the deck.
     * @param _drawnCards An array representing the cards that have already been drawn.
     * @return card_ The drawn card.
     */
    function drawSingleCardFromStack(uint256 _randoms, uint8[13] memory _drawnCards)
        external
        pure
        returns (uint256 card_)
    {
        // Initialize a deck of 156 cards
        uint256[AMOUNT_CARDS] memory allNumbersDecks_;
        uint256 index_ = 0;

        unchecked {
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
                (allNumbersDecks_[y], allNumbersDecks_[value_]) = (allNumbersDecks_[value_], allNumbersDecks_[y]);
            }

            // Draw the first non-zero card from the shuffled deck
            // The loop iterates over the first 15 positions of the shuffled deck.
            // It skips over positions that have a value of 0 (which represent cards that have already been drawn).
            // As soon as it encounters a non-zero value (which represents a card that hasn't been drawn yet), it assigns that value to `card_` and returns it.
            // The number 15 is chosen as an arbitrary limit to prevent the loop from running indefinitely in case all cards have been drawn.
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
     * @notice This function draws a specified number of cards from a deck of cards.
     * @param _randoms A random number used for shuffling the deck.
     * @param _amountCards The number of cards to draw.
     * @param _drawnCards An array representing the cards that have already been drawn.
     * @return topCards_ The drawn cards.
     */
    function drawCardsFromStack(uint256 _randoms, uint256 _amountCards, uint8[13] memory _drawnCards)
        external
        pure
        returns (uint256[] memory topCards_)
    {
        // Initialize a deck of 156 cards
        uint256[AMOUNT_CARDS] memory allNumbersDecks_;
        uint256 index_ = 0;

        unchecked {
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
                (allNumbersDecks_[y], allNumbersDecks_[value_]) = (allNumbersDecks_[value_], allNumbersDecks_[y]);
            }

            // Initialize an array to hold the drawn cards
            topCards_ = new uint256[](_amountCards);

            // Draw the first _amountCards non-zero cards from the shuffled deck
            // The loop iterates over the first 20 positions of the shuffled deck.
            // It skips over positions that have a value of 0 (which represent cards that have already been drawn).
            // As soon as it encounters a non-zero value (which represents a card that hasn't been drawn yet), it adds that value to the `topCards_` array.
            // The number 20 is chosen as an arbitrary limit to prevent the loop from running indefinitely in case all cards have been drawn.
            for (uint256 x = 0; x < 20; ++x) {
                uint256 value_ = allNumbersDecks_[x];
                if (x == _amountCards) {
                    break;
                }
                if (value_ == 0) {
                    continue;
                } else {
                    topCards_[x] = value_;
                }
            }
        }

        return topCards_;
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
        pure
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
 * @title IWINRBlackJack
 * @author balding-ghost
 * @notice Interface for the WINRBlackJack contract
 */
interface IWINRBlackJack {
    struct Game {
        uint64 activeHandIndex;
        uint8[13] drawnCards;
        bool canInsure;
        bool awaitingRandomness;
        GameStatus status;
    }

    enum GameStatus {
        NONE, // 0
        TABLE_DEAL, // 1
        PLAYER_TURN, // 2
        DEALER_TURN, // 3
        FINISHED // 4
    }

    enum GameResult {
        DEALER_BLACKJACK_HAND_PUSH,
        DEALER_BLACKJACK_PLAYER_LOST,
        DEALER_BLACKJACK_PLAYER_INSURED,
        DEALER_BUST_PLAYER_LOST,
        DEALER_BUST_PLAYER_WIN,
        DEALER_BUST_PLAYER_BLACKJACK,
        DEALER_STAND_HAND_PUSH,
        DEALER_STAND_PLAYER_WIN,
        DEALER_STAND_PLAYER_LOST
    }

    struct Hand {
        address player;
        address wagerAsset;
        uint64 gameIndex;
        uint96 betAmount;
        uint96 insuranceAmount;
        HandStatus status;
        bool isDouble;
    }

    enum HandStatus {
        NONE,
        PLAYING, // 1
        AWAITING_HIT, // 2
        STAND, // 3
        BUST, // 4
        BLACKJACK // 5
    }

    struct Cards {
        uint8 amountCards;
        uint8 firstCard;
        uint8 secondCard;
        uint8 newCard;
        uint8 totalCount;
        bool isSoftHand;
        bool canSplit;
    }

    event HandSettled(
        address indexed player,
        uint256 handIndex,
        address token,
        uint256 betAmount,
        uint256 wagerWithMultiplier,
        GameResult result,
        uint256 payout
    );

    event HandHit(uint256 indexed handIndex_, uint256 card_, uint256 totalCount_);

    event NextHandsTurn(uint256 indexed gameIndex_, uint256 handIndex_);

    event DealerTurn(uint256 indexed gameIndex_);

    event HandCreated(
        uint256 indexed handIndex_, address player_, address wagerAsset_, uint256 gameIndex_, uint256 betAmount_
    );

    event GameStarted(uint256 indexed gameIndex_);

    event HandInsured(uint256 indexed handIndex_, uint256 costInsurance_);

    event RequestVRFForHand(uint256 indexed gameIndex_, uint256 indexed activeHandIndex);

    event HandDealt(uint256 indexed handIndex_, uint256 firstCard_, uint256 secondCard_, uint256 totalCount_);

    event DealerCardsDealt(uint256 indexed gameIndex_, Cards cards_);

    event RequestHandHit(uint256 indexed handIndex_);

    event HandSplit(uint256 indexed handIndex_, uint256 newHandIndex_);

    event HandStandOff(uint256 indexed handIndex_);

    event HandDoubleDown(uint256 indexed handIndex_, uint256 newBetAmount_);
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