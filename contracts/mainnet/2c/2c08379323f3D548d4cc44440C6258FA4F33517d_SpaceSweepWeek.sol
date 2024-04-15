// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
	error OnlyCoordinatorCanFulfill(address have, address want);
	address private immutable vrfCoordinator;

	/**
	 * @param _vrfCoordinator address of VRFCoordinator contract
	 */
	constructor(address _vrfCoordinator) {
		vrfCoordinator = _vrfCoordinator;
	}

	/**
	 * @notice fulfillRandomness handles the VRF response. Your contract must
	 * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
	 * @notice principles to keep in mind when implementing your fulfillRandomness
	 * @notice method.
	 *
	 * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
	 * @dev signature, and will call it once it has verified the proof
	 * @dev associated with the randomness. (It is triggered via a call to
	 * @dev rawFulfillRandomness, below.)
	 *
	 * @param requestId The Id initially returned by requestRandomness
	 * @param randomWords the VRF output expanded to the requested number of words
	 */
	function fulfillRandomWords(
		uint256 requestId,
		uint256[] memory randomWords
	) internal virtual;

	// rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
	// proof. rawFulfillRandomness then calls fulfillRandomness, after validating
	// the origin of the call
	function rawFulfillRandomWords(
		uint256 requestId,
		uint256[] memory randomWords
	) external virtual {
		if (msg.sender != vrfCoordinator) {
			revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
		}
		fulfillRandomWords(requestId, randomWords);
	}
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error SpaceSweepWeek__NotEnoughEth();
error SpaceSweepWeek__TransferFailed();
error SpaceSweepWeek__NotOpen();
error SpaceSweepWeek__UpkeepNotNeeded(
	uint256 currentBalance,
	uint256 numPlayers,
	uint256 SpaceSweepWeekState
);

contract SpaceSweepWeek is VRFConsumerBaseV2, Ownable, ReentrancyGuard {
	/* state variables */
	uint256 public i_entranceFee;
	address payable[] public s_players;
	uint256[] public playerContributions;
	address payable public treasuryWallet;
	address[] public specialWallets;
	uint256 public treasuryFund;
	address payable[] public s_recentWinners;
	uint256 public totalWinnings;
	mapping(address => uint256) public winnings;
	mapping(address => uint256) contributions;
	uint256 public currentPool = 0;
	mapping(uint256 => mapping(address => bool)) public roundWinners;
	uint256 public currentRound = 1;
	address public s_forwarderAddress;

	/** Lottey Variables */
	enum SpaceSweepWeekState {
		OPEN,
		CALCULATING
	}
	SpaceSweepWeekState private s_SpaceSweepWeekState;

	/* Chainlink VRF Variables */
	VRFCoordinatorV2Interface private immutable i_vrfCOORDINATOR;
	bytes32 private immutable i_gasLane;
	uint64 private immutable i_subscriptionId;
	uint16 private constant REQUEST_CONFIRMATIONS = 3;
	uint32 private immutable i_callbackGasLimit;
	uint32 private constant NUM_WORDS = 10;

	/* events */
	event SpaceSweepWeekEnter(address indexed player, uint256 entryFee, uint256 entries);
	event RequestedSpaceSweepWeek(uint256 indexed requestId);
	event WinnerPicked(
		address indexed winner,
		uint256 prize,
		uint256 position,
		uint256 p_length
	);
	event TreasuryChanged(address indexed newTreasury);

	// Events for tracking refund status
	event RefundIssued(address to, uint256 amount);
	event RefundFailed(address to, uint256 amount);

	constructor(
		address VRFCoordinatorV2,
		uint256 entranceFee,
		bytes32 keyHash,
		uint64 subscriptionId,
		uint32 callBackGasLimit,
		address payable _treasuryWallet
	) VRFConsumerBaseV2(VRFCoordinatorV2) {
		i_entranceFee = entranceFee;
		i_vrfCOORDINATOR = VRFCoordinatorV2Interface(VRFCoordinatorV2);
		i_gasLane = keyHash;
		i_subscriptionId = subscriptionId;
		i_callbackGasLimit = callBackGasLimit;
		s_SpaceSweepWeekState = SpaceSweepWeekState.OPEN;
		treasuryWallet = _treasuryWallet;
	}

	function enterSpaceSweepWeekSpecial() public payable {
		require(
			s_SpaceSweepWeekState == SpaceSweepWeekState.OPEN,
			"SpaceSweepDay__NotOpen"
		);

		// Initialize a flag to check if the sender is a special wallet
		bool isSpecialWallet = false;

		// Search for the sender's address in the specialWallets array
		for (uint256 i = 0; i < specialWallets.length; i++) {
			if (msg.sender == specialWallets[i]) {
				isSpecialWallet = true;
				specialWallets[i] = specialWallets[specialWallets.length - 1];
				specialWallets.pop();
				break;
			}
		}

		// Require that the sender must be a special wallet
		require(isSpecialWallet, "SpaceSweepWeek__NotSpecialWallet");

		s_players.push(payable(msg.sender));
		playerContributions.push(msg.value);
		contributions[msg.sender] += msg.value;

		emit SpaceSweepWeekEnter(msg.sender, msg.value, 1);
	}

	function enterSpaceSweepWeek(uint256 entries) public payable {
		require(
			s_SpaceSweepWeekState == SpaceSweepWeekState.OPEN,
			"SpaceSweepDay__NotOpen"
		);

		uint256 totalEntryFee = i_entranceFee * entries;
		require(msg.value >= totalEntryFee, "SpaceSweepWeek__NotEnoughEth");

		contributions[msg.sender] += msg.value;
		currentPool += msg.value;

		// Track each entry separately
		for (uint256 i = 0; i < entries; i++) {
			playerContributions.push(i_entranceFee);
			s_players.push(payable(msg.sender));
		}

		emit SpaceSweepWeekEnter(msg.sender, msg.value, entries);
	}

	/**
	 * @dev This is the function that the Chainlink Keeper nodes call
	 * they look for `upkeepNeeded` to return True.
	 * the following should be true for this to return true:
	 */
	/** CHAINLINK KEEPERS (AUTOMATION) */
	function checkUpkeep(
		bytes memory /* checkData*/
	) public view returns (bool upkeepNeeded, bytes memory /* performData*/) {
		bool isOpen = SpaceSweepWeekState.OPEN == s_SpaceSweepWeekState;
		bool hasBalance = currentPool > 0;
		bool hasPlayers = s_players.length >= 3;

		upkeepNeeded = (isOpen && hasBalance && hasPlayers);
		return (upkeepNeeded, "0x0");
	}

	/**
	 * @dev Once `checkUpkeep` is returning `true`, this function is called
	 * and it kicks off a Chainlink VRF call to get a random winner.
	 */
	function performUpkeep(bytes calldata /* performData */) external {
		require(
			msg.sender == s_forwarderAddress || msg.sender == owner(),
			"This address does not have permission to call performUpkeep"
		);

		(bool upKeepNeeded, ) = checkUpkeep("");
		if (!upKeepNeeded) {
			revert SpaceSweepWeek__UpkeepNotNeeded(
				currentPool,
				s_players.length,
				uint256(s_SpaceSweepWeekState)
			);
		}

		s_SpaceSweepWeekState = SpaceSweepWeekState.CALCULATING;

		uint256 requestId = i_vrfCOORDINATOR.requestRandomWords(
			i_gasLane,
			i_subscriptionId,
			REQUEST_CONFIRMATIONS,
			i_callbackGasLimit,
			NUM_WORDS
		);
		emit RequestedSpaceSweepWeek(requestId);
	}

	/** CHAINLINK VRF */
	function fulfillRandomWords(
		uint256 /* requestId */,
		uint256[] memory randomWords
	) internal override {
		delete s_recentWinners;

		uint256 totalPool = currentPool;

		uint256 treasuryAmount = (totalPool * 20) / 100;
		treasuryFund += treasuryAmount;

		uint256 availablePool = totalPool - ((totalPool * 20) / 100);

		uint256[10] memory prizePercentages = [
			uint256(35),
			uint256(20),
			uint256(15),
			uint256(10),
			uint256(5),
			uint256(4),
			uint256(4),
			uint256(3),
			uint256(2),
			uint256(2)
		];

		uint256 counter = 0;

		for (uint256 i = 0; i < prizePercentages.length && counter < s_players.length; ) {
			uint256 index = (randomWords[i] + counter) % s_players.length;
			address payable winner = s_players[index];

			if (!roundWinners[currentRound][winner]) {
				uint256 prize = (availablePool * prizePercentages[i]) / 100;
				winnings[winner] += prize; // Accumulate winnings
				totalWinnings += prize;
				roundWinners[currentRound][winner] = true; // Mark as winner for the round
				s_recentWinners.push(winner);
				emit WinnerPicked(winner, prize, i + 1, s_players.length);
				i++;
				counter = 0;
			} else {
				counter++;
			}
		}

		(bool successTreasury, ) = treasuryWallet.call{ value: treasuryFund }("");
		require(successTreasury, "Transfer failed.");
		treasuryFund = 0;

		// Reset for next SpaceSweepWeek
		s_SpaceSweepWeekState = SpaceSweepWeekState.OPEN;
		currentPool = 0;
		for (uint256 i = 0; i < s_players.length; i++) {
			contributions[s_players[i]] = 0;
		}
		delete s_players;
		delete playerContributions;
		currentRound++;
	}

	function claimWinnings() external nonReentrant {
		uint256 winningAmount = winnings[msg.sender];
		require(winningAmount > 0, "No winnings to claim");
		winnings[msg.sender] = 0;
		totalWinnings -= winningAmount;

		// Transfer winnings
		(bool success, ) = msg.sender.call{ value: winningAmount }("");
		require(success, "Failed to send winnings to user wallet");
	}

	function getAllRecentWinnersWinnings()
		public
		view
		returns (address[] memory, uint256[] memory)
	{
		uint256 winnersCount = s_recentWinners.length;
		address[] memory winnerAddresses = new address[](winnersCount);
		uint256[] memory winnerWinnings = new uint256[](winnersCount);

		for (uint256 i = 0; i < winnersCount; i++) {
			winnerAddresses[i] = s_recentWinners[i];
			winnerWinnings[i] = winnings[s_recentWinners[i]];
		}

		return (winnerAddresses, winnerWinnings);
	}

	function setForwarderAddress(address forwarderAddress) external onlyOwner {
		s_forwarderAddress = forwarderAddress;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function addToPool() external payable {
		require(msg.value > 0, "Must send ETH to add to the pool");
		currentPool += msg.value;
	}

	function getSpaceSweepWeekState() public view returns (SpaceSweepWeekState) {
		return s_SpaceSweepWeekState;
	}

	function getSpecialWallets() public view returns (address[] memory) {
		return specialWallets;
	}

	function getEntranceFee() public view returns (uint256) {
		return i_entranceFee;
	}

	function getPlayer(uint256 index) public view returns (address) {
		return s_players[index];
	}

	function getAllPlayers() public view returns (address payable[] memory) {
		return s_players;
	}

	function getAllContributions() public view returns (uint256[] memory) {
		return playerContributions;
	}

	function getCurrentPool() public view returns (uint256) {
		return currentPool;
	}

	function getNumberOfPlayers() public view returns (uint256) {
		return s_players.length;
	}

	function addSpecialWallets(address[] calldata _wallets) external onlyOwner {
		for (uint i = 0; i < _wallets.length; i++) {
			specialWallets.push(_wallets[i]);
		}
	}

	function getTotalWinnings() public view returns (uint256) {
		return totalWinnings;
	}

	function removeSpecialWallet(address _wallet) external onlyOwner {
		for (uint256 i = 0; i < specialWallets.length; i++) {
			if (specialWallets[i] == _wallet) {
				specialWallets[i] = specialWallets[specialWallets.length - 1];
				specialWallets.pop();
				break;
			}
		}
	}

	// Function to update the entrance fee
	function setEntranceFee(uint256 _newEntranceFee) external onlyOwner {
		i_entranceFee = _newEntranceFee;
	}

	function setTreasury(address payable _newTreasury) public onlyOwner {
		require(_newTreasury != address(0), "New treasury cannot be the zero address");
		treasuryWallet = _newTreasury;
		emit TreasuryChanged(_newTreasury);
	}

	function transferTreasuryFunds() public onlyOwner {
		require(treasuryFund > 0, "No treasury to transfer");
		uint256 amountToTransfer = treasuryFund;
		treasuryFund = 0; // Reset remains before transfer to prevent re-entrancy attack
		(bool success, ) = treasuryWallet.call{ value: amountToTransfer }("");
		require(success, "Transfer failed");
	}

	function refundAllParticipants() external onlyOwner nonReentrant {
		uint256 playerCount = s_players.length;

		for (uint256 i = 0; i < playerCount; i++) {
			address payable player = s_players[i];
			// Attempt to refund each player individually
			(bool success, ) = player.call{ value: i_entranceFee }("");
			if (success) {
				emit RefundIssued(player, i_entranceFee);
			} else {
				emit RefundFailed(player, i_entranceFee);
			}
		}
		s_SpaceSweepWeekState = SpaceSweepWeekState.OPEN;
		delete s_players;
		currentPool = 0;
		delete playerContributions;
	}

	function transferDeadFunds() public onlyOwner {
		// Ensure calculatedFunds represents the leftover balance correctly.
		uint256 calculatedFunds = address(this).balance - (totalWinnings + currentPool);

		require(calculatedFunds > 0, "No funds available for transfer");

		// Attempt to transfer the calculated amount to the treasury wallet
		(bool success, ) = treasuryWallet.call{ value: calculatedFunds }("");
		require(success, "Transfer failed");
	}

	receive() external payable {}
}