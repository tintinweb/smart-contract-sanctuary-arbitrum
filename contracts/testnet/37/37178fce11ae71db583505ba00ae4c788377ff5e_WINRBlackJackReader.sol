// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IWINRBlackJackExternal.sol";
import "./IWINRBlackJack.sol";

contract WINRBlackJackReader {
    IWINRBlackJackExternal public immutable blackjack;

    constructor(address _blackjack) {
        blackjack = IWINRBlackJackExternal(_blackjack);
    }

    function returnAllHandsInGame(address _playerAddress)
        external
        view
        returns (uint256[] memory allHands_, uint256 length_)
    {
        IWINRBlackJack.Game memory game = blackjack.returnGame(_playerAddress);
        uint32 amountHands = game.amountHands;

        uint32[5] memory handIndexesGame = blackjack.returnHandIndexes(_playerAddress);

        allHands_ = new uint256[](amountHands);
        for (uint32 i = 0; i < amountHands; ++i) {
            allHands_[i] = handIndexesGame[i];
        }

        return (allHands_, amountHands);
    }

    function returnGameByGameIndex(uint256 _gameIndex) external view returns (IWINRBlackJack.Game memory game_) {
        // Fetch the hand using the gameIndex
        IWINRBlackJack.Hand memory hand_ = blackjack.returnHand(_gameIndex);

        // Fetch the player address from the hand
        address playerAddress = hand_.player;

        // Revert if the player address is the null address
        require(playerAddress != address(0), "Player address is the null address");

        // Return the Game struct using the player address
        return blackjack.returnGame(playerAddress);
    }

    function returnActiveHands(address _playerAddress)
        external
        view
        returns (uint256[] memory activeHands_, uint256 length_)
    {
        IWINRBlackJack.Game memory game = blackjack.returnGame(_playerAddress);
        uint32 amountHands = game.amountHands;

        bool[5] memory activeHandsInGame = blackjack.returnActiveHandsInGame(_playerAddress);

        uint32[5] memory handIndexesGame = blackjack.returnHandIndexes(_playerAddress);

        unchecked {
            uint256 count = 0;
            for (uint32 i = 0; i < amountHands; ++i) {
                if (activeHandsInGame[i]) {
                    count++;
                }
            }

            activeHands_ = new uint256[](count);
            uint256 index = 0;
            for (uint32 i = 0; i < amountHands; ++i) {
                if (activeHandsInGame[i]) {
                    activeHands_[index] = handIndexesGame[i];
                    index++;
                }
            }

            return (activeHands_, count);
        }
    }

    function returnSingleActiveHand(address _playerAddress) external view returns (uint256 activeHand_) {
        IWINRBlackJack.Game memory game = blackjack.returnGame(_playerAddress);
        uint32 amountHands = game.amountHands;

        bool[5] memory activeHandsInGame = blackjack.returnActiveHandsInGame(_playerAddress);

        uint32[5] memory handIndexesGame = blackjack.returnHandIndexes(_playerAddress);

        unchecked {
            for (uint32 i = 0; i < amountHands; ++i) {
                if (activeHandsInGame[i]) {
                    return handIndexesGame[i];
                }
            }
        }

        return 0;
    }

    function returnGameByHandIndex(uint256 _handIndex) external view returns (IWINRBlackJack.Game memory game_) {
        // Fetch the hand using the handIndex
        IWINRBlackJack.Hand memory hand_ = blackjack.returnHand(_handIndex);

        // Fetch the player address from the hand
        address playerAddress = hand_.player;

        // Revert if the player address is the null address
        require(playerAddress != address(0), "Player address is the null address");

        // Return the Game struct using the player address
        return blackjack.returnGame(playerAddress);
    }

    function returnCompletedHandsInGame(address _playerAddress)
        external
        view
        returns (uint256[] memory completedHands_, uint256 length_)
    {
        IWINRBlackJack.Game memory game = blackjack.returnGame(_playerAddress);
        uint32 amountHands = game.amountHands;

        bool[5] memory activeHandsInGame = blackjack.returnActiveHandsInGame(_playerAddress);

        uint32[5] memory handIndexesGame = blackjack.returnHandIndexes(_playerAddress);

        unchecked {
            uint256 count = 0;
            for (uint32 i = 0; i < amountHands; ++i) {
                if (!activeHandsInGame[i]) {
                    count++;
                }
            }

            completedHands_ = new uint256[](count);
            uint256 index = 0;
            for (uint32 i = 0; i < amountHands; ++i) {
                if (!activeHandsInGame[i]) {
                    completedHands_[index] = handIndexesGame[i];
                    index++;
                }
            }

            return (completedHands_, count);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IWINRBlackJack.sol";

interface IWINRBlackJackExternal {
    function returnGame(address _player) external view returns (IWINRBlackJack.Game memory game_);

    function returnActivePlayer(address _player) external view returns (uint256 gameIndex_);

    function returnCards(uint256 _handIndex) external view returns (IWINRBlackJack.Cards memory cards_);

    function returnHand(uint256 _handIndex) external view returns (IWINRBlackJack.Hand memory hand_);

    function returnSplitCouple(uint256 _handIndex) external view returns (uint256);

    function returnActiveHandsInGame(address _player) external view returns (bool[5] memory activeHands_);

    function returnHandIndexes(address _player) external view returns (uint32[5] memory hands_);
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
        uint32 gameIndex;
        uint32 chipsAmount;
        uint96 betAmount;
        uint96 insuranceAmount;
        HandStatus status;
        bool isDouble;
    }

    struct Game {
        uint64 activeHandIndex;
        uint32 amountHands;
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
     *  If a hand does not have any aces it is by default hard (so isSoftHand is false). As soon as an ace is added to the hand, the hand becomes soft (so isSoftHand is true) - but only if the ace is counted as 11 points. If the hand is soft and the total count goes over 21, the hand becomes hard (so isSoftHand is false). If the hand is hard and the total count is over 21, the hand becomes bust (so isBust is true).
     *
     *  Due to the count it is only possible for a player to have 1 soft ace in a hand. If the player has 2 aces, one of them must be counted as 1 point. If the player has 3 aces, 2 of them must be counted as 1 point. And so on.
     */
    struct Cards {
        uint8 amountCards;
        uint8[8] cards;
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

    enum HandStatus {
        NONE, // 0
        PLAYING, // 1
        AWAITING_HIT, // 2
        STAND, // 3
        BUST, // 4
        BLACKJACK // 5
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

    event HandHit(uint256 indexed handIndex_, uint256 card_, uint256 totalCount_, bool _isDouble);

    event DealerTurn(address indexed player_);

    event HandCreated(
        uint256 indexed handIndex_, address indexed player_, address wagerAsset_, uint256 gameIndex_, uint256 betAmount_
    );

    event HandInsured(uint256 indexed handIndex_, uint256 costInsurance_);

    event HandDealt(
        uint256 indexed handIndex_,
        uint256 indexed gameIndex,
        uint256 firstCard_,
        uint256 secondCard_,
        uint256 totalCount_
    );

    event DealerCardsDealt(uint256 indexed gameIndex_, Cards cards_);

    event RequestHandHit(uint256 indexed handIndex_);

    event HandSplit(uint256 indexed handIndex_, uint256 newHandIndex_);

    event HandDoubleDown(uint256 indexed handIndex_, uint256 newBetAmount_);

    event HandStandOff(uint256 indexed handIndex_);

    // event DealerTurn(uint256 indexed gameIndex_);

    // event NextHandsTurn(uint256 indexed gameIndex_, uint256 handIndex_);

    // event GameStarted(uint256 indexed gameIndex_);

    // event RequestVRFForHand(uint256 indexed gameIndex_, uint256 indexed activeHandIndex);
}