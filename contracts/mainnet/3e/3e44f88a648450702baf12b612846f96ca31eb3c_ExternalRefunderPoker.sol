// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IWINRPoker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ExternalRefunderPoker is Ownable {
	IWINRPoker public immutable poker;

	mapping(address => bool) public refunders;

	// Events
	event RefunderSet(address indexed refunder, bool isRefunder);

	constructor(address _poker, address _admin) {
		poker = IWINRPoker(_poker);
		transferOwnership(_admin);
	}

	// Modifiers

	modifier onlyRefunder() {
		require(refunders[msg.sender], "ExternalRefunderPoker: caller is not a refunder");
		_;
	}

	/**
	 * @notice Returns if a game can be refunded
	 * @param _player Address of the player
	 * @return canBeRefunded_ If the game can be refunded
	 * @return token_ Address of the token that is refunded
	 * @return amount_ Amount to be refunded in the token
	 * @return gameIndex_ Index of the game
	 * @return state_ State of the game
	 @dev for state_ 1 is AWAITING_INITIAL_DEAL and 2 is PLAYERS_TURN, 3 is AWAITING_CALL_DEAL and 4 is RESOLVED
	 */
	function returnIfGameCanBeRefunded(
		address _player
	)
		external
		view
		returns (
			bool canBeRefunded_,
			address token_,
			uint256 amount_,
			uint256 gameIndex_,
			IWINRPoker.State state_
		)
	{
		IWINRPoker.Game memory game_ = poker.returnLatestGameInfoByAddress(_player);
		uint32 refundCooldown_ = poker.refundCooldown();
		uint256 timePassed_ = block.timestamp - game_.timestampLatest;
		// if the time passed is more as the refund cooldown, the game can be refunded also the state needs to be either State.AWAITING_INITIAL_DEAL or State.AWAITING_CALL_DEAL
		if (
			timePassed_ >= refundCooldown_ &&
			(game_.state == IWINRPoker.State.AWAITING_INITIAL_DEAL ||
				game_.state == IWINRPoker.State.AWAITING_CALL_DEAL)
		) {
			uint256 callAmount_;

			uint256 sideBet_;

			if (game_.state == IWINRPoker.State.AWAITING_INITIAL_DEAL) {
				// the vrf timed out before dealing the initial cards
				sideBet_ = game_.betAmountSideBet;

				callAmount_ = 0;
			} else {
				// the vrf timed out  and the final cards have not been dealt yet
				callAmount_ = game_.callBetAmount;
				// side bet is already paid out / processed
				sideBet_ = 0;
			}

			return (
				true,
				game_.wagerAsset,
				game_.anteAmount + sideBet_ + callAmount_,
				game_.gameIndex,
				game_.state
			);
		} else {
			return (false, address(0), 0, game_.gameIndex, game_.state);
		}
	}

	function returnPlayerByRequestId(uint256 _requestId) external view returns (address player_) {
		return poker.returnPlayerByRequestId(_requestId);
	}

	function returnGameIndexByUser(address _player) external view returns (uint256 gameIndex_) {
		return poker.returnGameIndexByUser(_player);
	}

	function returnLatestGameInfoByAddress(
		address _player
	) external view returns (IWINRPoker.Game memory) {
		return poker.returnLatestGameInfoByAddress(_player);
	}

	// External functions

	function refundGameByTeam(address _playerAddress) external onlyRefunder {
		poker.refundGameByTeam(_playerAddress);
	}

	// External config functions

	function setPublicTimeoutDecide(bool _publicTimeoutDecide) external onlyOwner {
		poker.setPublicTimeoutDecide(_publicTimeoutDecide);
	}

	function setTimeToDecide(uint256 _timeToDecide) external onlyOwner {
		poker.setTimeToDecide(_timeToDecide);
	}

	function setPayoutsAA(uint256 _combination, uint256 _payout) external onlyOwner {
		poker.setPayoutsAA(_combination, _payout);
	}

	function setPayoutsPerCombination(uint256 _combination, uint256 _payout) external onlyOwner {
		poker.setPayoutsPerCombination(_combination, _payout);
	}

	function callTransferOwnership(address newOwner) public onlyOwner {
		// Encode the function signature and arguments
		bytes memory data_ = abi.encodeWithSignature("transferOwnership(address)", newOwner);

		address pokerAddress_ = address(poker);

		// Perform the low-level call
		(bool success_, ) = pokerAddress_.call(data_);
		require(success_, "ExternalRefunderPoker: TransferOwnership failed");
	}

	// Configuration functions

	function setRefunder(address _refunder, bool _isRefunder) external onlyOwner {
		refunders[_refunder] = _isRefunder;
		emit RefunderSet(_refunder, _isRefunder);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IWINRPoker
 * @author developed by balding-ghost
 */
interface IWINRPoker {
	struct Hand {
		Combination combination;
		uint16[5] cards; // note only the values of the cards are stored here, not the suits/type
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
		ROYAL_FLUSH, // 10
		ACE_PAIR
	}

	enum SideBetResult {
		NONE,
		DEALER_WINS,
		PLAYER_WINS
	}

	enum Result {
		NONE,
		DEALER_WINS,
		PLAYER_WINS,
		PLAYER_LOSES_FOLD,
		DEALER_NOT_QUALIFIED,
		PUSH
	}

	/**
	 * @param wagerAsset Address of the wager asset
	 * @param anteAmount Amount of the ante (so the initial bet)
	 * @param gameIndex Index of the game
	 * @param anteChipsAmount Amount of chips to be used for the ante
	 * @param timestampLatest Timestamp of the latest action
	 * @param randomness Randomness of the game
	 * @param betAmountSideBet Amount of the side bet
	 * @param callBetAmount Amount of the call bet
	 * @param state State of the game
	 */
	struct Game {
		address wagerAsset;
		uint128 anteAmount;
		uint32 gameIndex;
		uint16 anteChipsAmount;
		uint32 timestampLatest;
		uint32 randomness;
		uint128 betAmountSideBet;
		uint128 callBetAmount;
		State state;
	}

	enum State {
		NONE,
		AWAITING_INITIAL_DEAL,
		PLAYERS_TURN,
		AWAITING_CALL_DEAL,
		RESOLVED
	}

	event FoldByTimeout(uint256 indexed gameIndex, address indexed player, address indexed caller);

	event InitialGameDealt(
		uint256 indexed gameIndex,
		address indexed player,
		uint16[9] drawnCards,
		Combination combination // note: of the player alone!
	);

	event PlayerFolded(uint256 indexed gameIndex, address indexed player, uint256 anteAmount);

	event PlayerCalled(
		uint256 indexed gameIndex,
		address indexed player,
		uint256 extraWagerAmount,
		uint256 anteAmount,
		uint256 anteChipAmount
	);

	event GameCreated(
		uint256 indexed gameIndex,
		address indexed player,
		uint256 anteAmount,
		uint256 betAmountSideBet,
		address wagerAsset,
		uint256 anteChipsAmount,
		uint256 chipsAmountSideBet
	);

	event SideBetSettled(
		uint256 indexed gameIndex,
		address indexed player,
		uint16[9] drawnCards,
		Combination combination,
		uint256 betAmountSideBet,
		uint256 payoutSideBet
	);

	/**
	 * Deck
	 *    2 = 2, 14 = Ace, 13 = King
	 *    100 = Heart
	 *    200 = Diamond
	 *    300 = Club
	 *    400 = Spade
	 * z
	 *    102 = 2 of Heart, 114 = Ace of Heart, 113 = King of Heart
	 *    214 = Ace of Diamond, 213 = King of Diamond
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
	event Settled(
		uint256 indexed gameIndex,
		address indexed player,
		uint16[9] drawnCards,
		uint256 wagerWithMultiplier,
		Hand playerCards,
		Hand dealerCards,
		Result result,
		uint256 payoutAmount,
		uint256 paybackAmount
	);

	event RefundGameByTeam(
		uint256 indexed gameIndex,
		address indexed player,
		uint256 anteAmount,
		uint256 sideBetAmount,
		uint256 callAmount
	);

	event RefundGame(
		uint256 indexed gameIndex,
		address indexed player,
		uint256 anteAmount,
		uint256 sideBetAmount,
		uint256 callAmount
	);

	// Interface for Poker
	function returnPlayerByRequestId(uint256 _requestId) external view returns (address player_);

	function returnGameIndexByUser(address _player) external view returns (uint256 gameIndex_);

	function returnLatestGameInfoByAddress(address _player) external view returns (Game memory);

	function setPublicTimeoutDecide(bool _publicTimeoutDecide) external;

	function setTimeToDecide(uint256 _timeToDecide) external;

	function setPayoutsAA(uint256 _combination, uint256 _payout) external;

	function setPayoutsPerCombination(uint256 _combination, uint256 _payout) external;

	function refundGameByTeam(address _playerAddress) external;

	function refundGame() external;

	function decide(uint256 _gameIndex, bool _fold) external;

	function decideForPlayerOnTimeout(address _playerAddress) external;

	function bet(
		uint256 _anteChipAmount,
		uint256 _sideBetChipAmount,
		address _wagerAsset
	) external returns (uint256 gameIndex_);

	function refundCooldown() external view returns (uint32);
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