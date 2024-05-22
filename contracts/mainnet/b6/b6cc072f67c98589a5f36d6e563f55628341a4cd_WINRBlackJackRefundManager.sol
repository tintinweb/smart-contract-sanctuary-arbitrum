// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IWINRBlackJack.sol";
import "../../../interfaces/core/IVaultManagerLight.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title WINRBlackJackRefundManager
 * @author balding-ghost
 * @notice External contract that allows the team to refund players if the VRF times out
 */
contract WINRBlackJackRefundManager is Ownable, Pausable, ReentrancyGuard {
	IWINRBlackJack public blackJack;
	IVaultManagerLight public vaultManager;

	// mapping what addresses of the team are allowed to refund
	mapping(address => bool) public teamRefunder;

	mapping(address => bool) public playerAlreadyRefunded;

	// mapping of gameIndex to bool if the game has been refunded to prevent double refunds
	mapping(address => mapping(uint256 => bool)) public refunded;

	bool public canPlayerRefund = false;

	bool public playerCanReRequestRandomness = true;

	uint256 public timeOutTimeForPlayerRefund = 360;

	uint256 public timeOutTimeForPlayerReRequestRandomness = 180;

	event RefundByTeam(
		address indexed _player,
		uint256 indexed _gameIndex,
		uint256 indexed amountHands,
		uint256 amountRefunded
	);

	event RefundByPlayer(
		address indexed _player,
		uint256 _amount,
		uint32 _amountHands,
		uint96 _gameIndex
	);

	event ReRequestRandomnessByTeam(address indexed _player, uint96 _gameIndex);

	event ReRequestRandomnessByPlayer(address indexed _player, uint96 _gameIndex);

	// MODIFIERS

	modifier onlyTeamRefunder() {
		require(teamRefunder[msg.sender], "WRM: Not team refunder");
		_;
	}

	constructor(address _vaultManager, address _teamOwner) Ownable() {
		vaultManager = IVaultManagerLight(_vaultManager);
		_transferOwnership(_teamOwner);
	}

	function refundHandByPlayer() external nonReentrant whenNotPaused {
		// check if player refunding is enabled
		require(canPlayerRefund, "WRM: Player refunding disabled");
		IWINRBlackJack.Game memory game_ = blackJack.returnGame(msg.sender);
		// check if the game is awaiting randomness
		require(game_.awaitingRandomness, "WRM: Game not awaiting randomness");
		// check if the game status is non FINISHED
		require(game_.status != IWINRBlackJack.GameStatus.FINISHED, "WRM: Game finished");
		// check if game status is not none
		require(game_.status != IWINRBlackJack.GameStatus.NONE, "WRM: Game none");
		// check if the game indeed timed out
		require(
			block.timestamp > game_.timestamp + timeOutTimeForPlayerRefund,
			"WRM: Game not timed out"
		);
		uint32[5] memory handIndexes_ = blackJack.returnHandIndexesInGame(msg.sender);
		IWINRBlackJack.Hand memory hand_ = blackJack.returnHand(handIndexes_[0]);
		// check if caller is player in hand_
		require(hand_.player == msg.sender, "WRM: Not player in hand");
		// check if the hand has not been refunded
		require(!refunded[msg.sender][hand_.gameIndex], "WRM: Game already refunded");
		refunded[msg.sender][hand_.gameIndex] = true;
		uint256 totalToRefund_;
		// loop over amountHands in game_ and check from the game and get the total amount to refund
		for (uint256 i = 0; i < game_.amountHands; i++) {
			// get the hand info using the handIndexes mapping (containting game index)
			hand_ = blackJack.returnHand(handIndexes_[i]);
			// check if the hand is not BUST @note this is a choice if we want to refund busted hands, we also do not
			// require(hand_.status != IWINRBlackJack.HandStatus.BUST, "WRM: Hand in bust");
			totalToRefund_ += hand_.betAmount;
		}
		vaultManager.refund(hand_.wagerAsset, totalToRefund_, 0, msg.sender);
		blackJack.setGameResolvedByRefund(msg.sender);
		emit RefundByPlayer(msg.sender, totalToRefund_, game_.amountHands, hand_.gameIndex);
	}

	function refundHandByTeam(
		address _player
	) external nonReentrant onlyTeamRefunder whenNotPaused {
		IWINRBlackJack.Game memory game_ = blackJack.returnGame(msg.sender);
		// check if the game is awaiting randomness
		require(game_.awaitingRandomness, "WRM: Game not awaiting randomness");
		// check if the game status is non FINISHED
		require(game_.status != IWINRBlackJack.GameStatus.FINISHED, "WRM: Game finished");
		// check if game status is not none
		require(game_.status != IWINRBlackJack.GameStatus.NONE, "WRM: Game none");
		// check if the game indeed timed out
		require(
			block.timestamp > game_.timestamp + timeOutTimeForPlayerRefund,
			"WRM: Game not timed out"
		);
		uint32[5] memory handIndexes_ = blackJack.returnHandIndexesInGame(_player);
		IWINRBlackJack.Hand memory hand_ = blackJack.returnHand(handIndexes_[0]);
		require(!refunded[_player][hand_.gameIndex], "WRM: Game already refunded");
		refunded[_player][hand_.gameIndex] = true;
		uint256 totalToRefund_;
		// loop over amountHands in game_ and check from the game and get the total amount to refund
		for (uint256 i = 0; i < game_.amountHands; i++) {
			// get the hand info using the handIndexes mapping (containting game index)
			hand_ = blackJack.returnHand(handIndexes_[i]);
			// check if the hand is not BUST @note this is a choice if we want to refund busted hands, we also do not
			require(hand_.status != IWINRBlackJack.HandStatus.BUST, "WRM: Hand in bust");
			totalToRefund_ += hand_.betAmount;
		}
		vaultManager.refund(hand_.wagerAsset, totalToRefund_, 0, msg.sender);
		blackJack.setGameResolvedByRefund(msg.sender);
		emit RefundByTeam(_player, hand_.gameIndex, game_.amountHands, totalToRefund_);
	}

	function reRequestRandomnessByPlayer() external nonReentrant whenNotPaused {
		require(playerCanReRequestRandomness, "WRM: Player can't re-request randomness");
		IWINRBlackJack.Game memory game_ = blackJack.returnGame(msg.sender);
		// check if the game is awaiting randomness
		require(game_.awaitingRandomness, "WRM: Game not awaiting randomness");
		// check if the game status is non FINISHED
		require(game_.status != IWINRBlackJack.GameStatus.FINISHED, "WRM: Game finished");
		// check if game status is not none
		require(game_.status != IWINRBlackJack.GameStatus.NONE, "WRM: Game none");
		require(
			block.timestamp > game_.timestamp + timeOutTimeForPlayerReRequestRandomness,
			"WRM: Game not timed out for re-request randomness"
		);
		blackJack.reRequestRandomness(msg.sender);
		uint32[5] memory handIndexes_ = blackJack.returnHandIndexesInGame(msg.sender);
		IWINRBlackJack.Hand memory hand_ = blackJack.returnHand(handIndexes_[0]);
		emit ReRequestRandomnessByPlayer(msg.sender, hand_.gameIndex);
	}

	function reRequestRandomnessByTeam(
		address _player
	) external nonReentrant onlyTeamRefunder whenNotPaused {
		IWINRBlackJack.Game memory game_ = blackJack.returnGame(_player);
		// check if the game is awaiting randomness
		require(game_.awaitingRandomness, "WRM: Game not awaiting randomness");
		// check if the game status is non FINISHED
		require(game_.status != IWINRBlackJack.GameStatus.FINISHED, "WRM: Game finished");
		// check if game status is not none
		require(game_.status != IWINRBlackJack.GameStatus.NONE, "WRM: Game none");
		require(
			block.timestamp > game_.timestamp + timeOutTimeForPlayerReRequestRandomness,
			"WRM: Game not timed out for re-request randomness"
		);
		blackJack.reRequestRandomness(_player);
		uint32[5] memory handIndexes_ = blackJack.returnHandIndexesInGame(_player);
		IWINRBlackJack.Hand memory hand_ = blackJack.returnHand(handIndexes_[0]);
		emit ReRequestRandomnessByTeam(_player, hand_.gameIndex);
	}

	// Configuration functions

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}

	function setTimeOutTimeForPlayerReRequestRandomness(
		uint256 _timeOutTimeForPlayerReRequestRandomness
	) external onlyOwner {
		timeOutTimeForPlayerReRequestRandomness = _timeOutTimeForPlayerReRequestRandomness;
	}

	function setPlayerCanReRequestRandomness(
		bool _playerCanReRequestRandomness
	) external onlyOwner {
		playerCanReRequestRandomness = _playerCanReRequestRandomness;
	}

	function setBlackjack(address _blackJack) external onlyOwner {
		blackJack = IWINRBlackJack(_blackJack);
	}

	// modifiers
	function setTeamRefunder(address _teamRefunder, bool _isTeamRefunder) external onlyOwner {
		teamRefunder[_teamRefunder] = _isTeamRefunder;
	}

	function setCanPlayerRefund(bool _canPlayerRefund) external onlyOwner {
		canPlayerRefund = _canPlayerRefund;
	}

	function settimeOutTimeForPlayerRefund(uint256 _timeOutTimeForPlayerRefund) external onlyOwner {
		timeOutTimeForPlayerRefund = _timeOutTimeForPlayerRefund;
	}

	// View functions

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

	function returnGameInfo(
		address _player
	)
		external
		view
		returns (
			uint96 gameIndex_,
			uint64 activeHandIndex_,
			uint32 amountHands_,
			uint256 timestamp_,
			bool awaitingRandomness_,
			IWINRBlackJack.GameStatus status_,
			uint256 totalBetAmount_,
			address wagerAsset_
		)
	{
		// Fetch the game using the player address
		IWINRBlackJack.Game memory game_ = blackJack.returnGame(_player);
		uint32[5] memory handIndexes_ = blackJack.returnHandIndexesInGame(_player);
		IWINRBlackJack.Hand memory hand_ = blackJack.returnHand(handIndexes_[0]);
		totalBetAmount_ = hand_.betAmount * game_.amountHands;

		return (
			hand_.gameIndex,
			game_.activeHandIndex,
			game_.amountHands,
			game_.timestamp,
			game_.awaitingRandomness,
			game_.status,
			totalBetAmount_,
			hand_.wagerAsset
		);
	}

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVaultManagerLight {
	function getMaxWager() external view returns (uint256);

	function getMinWager(address _game) external view returns (uint256);

	function getWhitelistedTokens() external view returns (address[] memory whitelistedTokenList_);

	function refund(
		address _token,
		uint256 _amount,
		uint256 _vWINRAmount,
		address _player
	) external;

	function escrow(address _token, address _sender, uint256 _amount) external;

	function payoutNoEscrow(
		address _tokenAddress,
		address _recipient,
		uint256 _totalAmount
	) external;

	function setReferralReward(
		address _token,
		address _player,
		uint256 _amount,
		uint64 _houseEdge
	) external returns (uint256 referralReward_);

	function payback(address _token, address _recipient, uint256 _amount) external;

	function getEscrowedTokens(address _token, uint256 _amount) external;

	function payout(
		address _token,
		address _recipient,
		uint256 _escrowAmount,
		uint256 _totalAmount
	) external;

	function payin(address _token, uint256 _escrowAmount) external;

	function transferIn(address _token, address _sender, uint256 _amount) external;

	function transferOut(address _token, address _recipient, uint256 _amount) external;

	function mintVestedWINR(
		address _input,
		uint256 _amount,
		address _recipient
	) external returns (uint256 vWINRAmount_);

	function getPrice(address _token) external view returns (uint256 _price);
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