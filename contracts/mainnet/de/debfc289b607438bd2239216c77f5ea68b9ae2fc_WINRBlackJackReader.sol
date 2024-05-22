// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IWINRBlackJack.sol";

/**
 * @title WINRBlackJackReader
 * @author balding-ghost
 */
contract WINRBlackJackReader {
	IWINRBlackJack public blackJack;
	address public deployer;

	constructor(address _blackjack) {
		blackJack = IWINRBlackJack(_blackjack);
		deployer = msg.sender;
	}

	function setBlackJackAddress(address _blackjack) external {
		require(msg.sender == deployer, "WINRBlackJackReader: Only deployer can set the address");
		blackJack = IWINRBlackJack(_blackjack);
	}

	function returnGameByGameIndex(
		uint256 _gameIndex
	) external view returns (IWINRBlackJack.Game memory game_, address playerAddress_) {
		// Fetch the hand using the gameIndex
		IWINRBlackJack.Hand memory hand_ = blackJack.returnHand(_gameIndex);

		// Fetch the player address from the hand
		playerAddress_ = hand_.player;

		game_ = blackJack.returnGame(playerAddress_);

		return (game_, playerAddress_);
	}

	function returnGameByHandIndex(
		uint256 _handIndex
	) external view returns (IWINRBlackJack.Game memory game_, address playerAddress_) {
		// Fetch the hand using the handIndex
		IWINRBlackJack.Hand memory hand_ = blackJack.returnHand(_handIndex);

		// Fetch the player address from the hand
		playerAddress_ = hand_.player;

		game_ = blackJack.returnGame(playerAddress_);

		return (game_, playerAddress_);
	}

	function returnActiveGameIndexPlayer(
		address _player
	) external view returns (uint256 gameIndex_) {
		// Return the active game index using the player address
		return blackJack.returnActivePlayer(_player);
	}

	function returnActiveGamePlayer(
		address _player
	) external view returns (IWINRBlackJack.Game memory game_) {
		// Return the active game using the player address
		return blackJack.returnGame(_player);
	}

	// function returnCardsOfHand(
	// 	uint256 _handIndex
	// ) external view returns (IWINRBlackJack.Cards memory cards_) {
	// 	// Return the cards of the hand using the handIndex
	// 	return blackJack.returnCards(_handIndex);
	// }

	function returnActiveHandInfo(
		address _player
	) external view returns (IWINRBlackJack.Hand memory hand_) {
		// Fetch the active game index using the player address
		uint256 gameIndex_ = blackJack.returnActivePlayer(_player);

		// Fetch the hand using the gameIndex
		return blackJack.returnHand(gameIndex_);
	}

	function returnHandInfo(
		uint256 _handIndex
	) external view returns (IWINRBlackJack.Hand memory hand_) {
		// Fetch the hand using the handIndex
		return blackJack.returnHand(_handIndex);
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