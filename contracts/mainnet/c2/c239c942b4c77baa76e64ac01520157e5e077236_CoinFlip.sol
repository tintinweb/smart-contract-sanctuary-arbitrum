// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 Solidity Contract Layout: 
    1. Pragmas
    2. Import Statements
    3. Interfaces
    4. Libraries
    5. Contracts
    6. Enums and Structs
    7. Errors
    7. Events
    8. State Variables
    9. Constructor
    11. Functions
    10. Modifiers
 */

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title CoinFlip Contract
 * @author 0xNascosta / RamanSB
 * @dev This contract implements a coin flip betting game using Chainlink VRF for randomness.
 */
contract CoinFlip is VRFConsumerBaseV2Plus {
    // Enums & Structs
    enum State {
        OPEN, // 0
        WIN, // 1
        LOSS // 2
    }

    // Even = Heads, Odd = Tails
    enum Choice {
        HEADS, // 0
        TAILS // 1
    }

    struct CoinFlipRequest {
        uint256 requestId;
        uint256 amount;
        State state;
        address user;
        Choice choice;
    }

    // Errors
    /// @notice Bet is below the minimum amount
    error CoinFlip__BetIsBelowMinimumAmount(address player, uint256 amount);
    /// @notice Existing bet in progress (can only place 1 live bet at a time)
    error CoinFlip__ExistingBetIsInProgress(address player);
    /// @notice CoinFlip contract has insufficient funds to payout potential bet.
    error CoinFlip__InsufficientFundsForPayout(
        address player,
        uint256 wageAmount,
        uint256 balance
    );
    /// @notice Unable to associate result with bet placed due to requestId not found.
    error CoinFlip__NoBetFoundForRequestId(uint256 requestId);
    /// @notice Error with the call function (sending payout)
    error CoinFlip__PayoutFailed(
        address player,
        uint256 requestId,
        uint256 amount
    );
    error CoinFlip__InsufficientFundsToWithdraw(uint256 amount);

    /// @notice Logs when a payment to a winning player fails
    event CoinFlip__PaymentFailed(
        address indexed user,
        uint256 indexed requestId,
        uint256 indexed amount
    );
    /// @notice Logs a winning (0 ether) bet which should never occur
    event CoinFlip__ErrorLog(string message, uint256 indexed requestId);
    /// @notice Logs a players coin flip bet
    event CoinFlip__FlipRequest(
        address indexed player,
        uint256 indexed requestId,
        uint256 amount,
        Choice choice
    );
    event CoinFlip__FlipWin(
        address indexed player,
        uint256 indexed requestId,
        uint256 amount
    );
    event CoinFlip__FlipLoss(
        address indexed player,
        uint256 indexed requestId,
        uint256 amount
    );
    event CoinFlip__Funded(address indexed funder, uint256 indexed amount);
    event CoinFlip__Withdrawl(uint256 indexed balance, uint256 indexed amount);

    // VRF State Variables
    /// @dev Number of random words to request from Chainlink VRF
    uint32 private constant NUMBER_OF_WORDS = 1;
    /// @dev Address of Chainlink VRF Coordinator
    address s_vrfCoordinatorAddress;
    /// @dev Chainlink VRF subscription id.
    uint256 private immutable i_subscriptionId;
    /// @dev Maximum gas we are willing to pay for gas used by our fulfillRandomWords
    uint32 private immutable i_callbackGasLimit;
    /// @dev Specifies the maximum gas price we are willing to pay to make a request.
    bytes32 private immutable i_gasLane;
    /// @dev Minimum number of blocks to be confirmed before Chainlink VRF invokes our fulfillRandomWords (sends us our random word.)
    uint16 private immutable i_numOfRequestConfirmations;
    /// @dev ReEntrancy locks per user.
    mapping(address => bool) internal s_locksByUser;

    /// @dev minimum amount a user must wage.
    uint256 immutable MINIMUM_WAGER;
    /// @dev Tracks the potential amount the contract is required to potentially payout (tracks potential payout of unconcluded games)
    uint256 private s_totalPotentialPayout;
    /// @dev Status of coin flip game by request ID
    mapping(uint256 => CoinFlipRequest) private s_flipRequestByRequestId;
    /// @dev Status of most recent coin flip game by address
    mapping(address => CoinFlipRequest) private s_recentFlipRequestByAddress;
    /// @dev Tracks potential payout of in-play (unconcluded) games by address.
    mapping(address => uint256) private s_potentialPayoutByAddress;

    /**
     * @notice Constructor to initialize the CoinFlip contract
     * @param minimumWager The minimum amount required to place a bet
     * @param vrfCoordinatorAddress The address of the VRF Coordinator
     * @param subscriptionId The subscription ID for Chainlink VRF
     * @param gasLane The gas lane key hash for VRF
     * @param callbackGasLimit The gas limit for the VRF callback
     */
    constructor(
        uint256 minimumWager,
        address vrfCoordinatorAddress,
        uint256 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit,
        uint16 numOfRequestConfirmations
    ) VRFConsumerBaseV2Plus(vrfCoordinatorAddress) {
        MINIMUM_WAGER = minimumWager;
        s_vrfCoordinatorAddress = vrfCoordinatorAddress;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_gasLane = gasLane;
        i_numOfRequestConfirmations = numOfRequestConfirmations;
    }

    /**
     * @dev Modifier to prevent reentrancy attacks
     */
    modifier ReEntrancyGuard() {
        require(!s_locksByUser[msg.sender], "ReEntrancy not allowed");
        s_locksByUser[msg.sender] = true;
        _;
        s_locksByUser[msg.sender] = false;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice Function to fund the contract with ether
     */
    function fund() external payable ReEntrancyGuard {
        require(msg.value > 0, "Cannot fund with zero ether");
        emit CoinFlip__Funded(msg.sender, msg.value);
    }

    /**
     * @notice Function for the owner to withdraw ether from the contract
     * @param amount The amount of ether to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner ReEntrancyGuard {
        uint256 balance = address(this).balance;
        if (balance < amount) {
            revert CoinFlip__InsufficientFundsToWithdraw(amount);
        }
        (bool sent /* bytes memory */, ) = msg.sender.call{value: amount}("");
        require(sent, "Withdrawal failed");
        emit CoinFlip__Withdrawl(balance, amount);
    }

    /**
     * @notice Function to place a bet on the coin flip game
     * @param userChoice The choice of the user (0 for HEADS, 1 for TAILS)
     */
    function bet(uint8 userChoice) external payable ReEntrancyGuard {
        // Checks
        // User bets above minimum amount
        if (msg.value < MINIMUM_WAGER) {
            revert CoinFlip__BetIsBelowMinimumAmount(msg.sender, msg.value);
        }

        // If user has never played a game before, recentFlipRequest will have a state of OPEN, amount will be 0, we can use this.
        CoinFlipRequest memory recentFlipRequest = s_recentFlipRequestByAddress[
            msg.sender
        ];
        if (
            recentFlipRequest.amount != 0 &&
            (recentFlipRequest.state == State.OPEN)
        ) {
            // Users recent
            revert CoinFlip__ExistingBetIsInProgress(msg.sender);
        }

        // Check if contract has amount to pay user excluding the funds the user has provided.
        uint256 contractBalanceExcludingBet = address(this).balance - msg.value;
        if (contractBalanceExcludingBet - s_totalPotentialPayout < msg.value) {
            revert CoinFlip__InsufficientFundsForPayout(
                msg.sender,
                msg.value,
                contractBalanceExcludingBet
            );
        }

        // Effects
        uint256 payoutAmount = 2 * msg.value;
        s_potentialPayoutByAddress[msg.sender] = payoutAmount;
        s_totalPotentialPayout += payoutAmount;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: i_numOfRequestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUMBER_OF_WORDS,
                extraArgs: ""
            })
        );

        emit CoinFlip__FlipRequest(
            msg.sender,
            requestId,
            msg.value,
            Choice(userChoice % 2)
        );

        CoinFlipRequest memory flipRequest = CoinFlipRequest({
            amount: msg.value,
            state: State.OPEN,
            requestId: requestId,
            user: msg.sender,
            choice: Choice(userChoice % 2)
        });

        s_flipRequestByRequestId[requestId] = flipRequest;
        s_recentFlipRequestByAddress[msg.sender] = flipRequest;
    }

    /**
     * @notice Function called by VRF coordinator to fulfill random words request
     * @param requestId The ID of the VRF request
     * @param randomWords The array of random words generated
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // This function will be called by the VRF service
        Choice result = Choice(randomWords[0] % 2);
        CoinFlipRequest memory recentRequest = s_flipRequestByRequestId[
            requestId
        ];
        if (recentRequest.amount == 0) {
            emit CoinFlip__ErrorLog("Invalid request data", requestId);
            return;
        }
        uint256 potentialPayoutAmount = 2 * recentRequest.amount;
        s_totalPotentialPayout -= potentialPayoutAmount;
        delete s_potentialPayoutByAddress[recentRequest.user];

        if (recentRequest.choice == result) {
            recentRequest.state = State.WIN;
            s_flipRequestByRequestId[requestId] = recentRequest;
            s_recentFlipRequestByAddress[recentRequest.user] = recentRequest;
            // User has won.
            (bool sent /* bytes memory data */, ) = (recentRequest.user).call{
                value: potentialPayoutAmount
            }("");

            if (!sent) {
                emit CoinFlip__PaymentFailed(
                    recentRequest.user,
                    requestId,
                    potentialPayoutAmount
                );
            }

            emit CoinFlip__FlipWin(
                recentRequest.user,
                requestId,
                potentialPayoutAmount
            );
        } else {
            recentRequest.state = State.LOSS;
            s_flipRequestByRequestId[requestId] = recentRequest;
            s_recentFlipRequestByAddress[recentRequest.user] = recentRequest;
            // User has lost.
            emit CoinFlip__FlipLoss(
                recentRequest.user,
                requestId,
                potentialPayoutAmount
            );
        }
    }

    /**
     * @notice Get the most recent coin flip result for a given address
     * @param user The address of the user
     * @return CoinFlipRequest The most recent coin flip request
     */
    function getRecentCoinFlipResultByAddress(
        address user
    ) public view returns (CoinFlipRequest memory) {
        return s_recentFlipRequestByAddress[user];
    }

    /**
     * @notice Get the total potential payout for all bets
     * @return uint256 The total potential payout
     */
    function getTotalPotentialPayout() public view returns (uint256) {
        return s_totalPotentialPayout;
    }

    /**
     * @notice Get the potential payout for a specific user
     * @param user The address of the user
     * @return uint256 The potential payout for the user
     */
    function getPotentialPayoutForAddress(
        address user
    ) public view returns (uint256) {
        return s_potentialPayoutByAddress[user];
    }

    /**
     * @notice Get the coin flip result by request ID
     * @param requestId The ID of the request
     * @return CoinFlipRequest The coin flip request data
     */
    function getResultByRequestId(
        uint256 requestId
    ) public view returns (CoinFlipRequest memory) {
        return s_flipRequestByRequestId[requestId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IVRFCoordinatorV2Plus} from "./interfaces/IVRFCoordinatorV2Plus.sol";
import {IVRFMigratableConsumerV2Plus} from "./interfaces/IVRFMigratableConsumerV2Plus.sol";
import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";

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
 * @dev 1. The fulfillment came from the VRFCoordinatorV2Plus.
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBaseV2Plus, and can
 * @dev initialize VRFConsumerBaseV2Plus's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumerV2Plus is VRFConsumerBaseV2Plus {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _subOwner)
 * @dev       VRFConsumerBaseV2Plus(_vrfCoordinator, _subOwner) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create a subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords, extraArgs),
 * @dev see (IVRFCoordinatorV2Plus for a description of the arguments).
 *
 * @dev Once the VRFCoordinatorV2Plus has received and validated the oracle's response
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
 * @dev (specifically, by the VRFConsumerBaseV2Plus.rawFulfillRandomness method).
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
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @inheritdoc IVRFMigratableConsumerV2Plus
   */
  function setCoordinator(address _vrfCoordinator) external override onlyOwnerOrCoordinator {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);

    emit CoordinatorSet(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// End consumer library.
library VRFV2PlusClient {
  // extraArgs will evolve to support new features
  bytes4 public constant EXTRA_ARGS_V1_TAG = bytes4(keccak256("VRF ExtraArgsV1"));
  struct ExtraArgsV1 {
    bool nativePayment;
  }

  struct RandomWordsRequest {
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;
  }

  function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFV2PlusClient} from "../libraries/VRFV2PlusClient.sol";
import {IVRFSubscriptionV2Plus} from "./IVRFSubscriptionV2Plus.sol";

// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fields for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - abi-encoded extra args
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  event CoordinatorSet(address vrfCoordinator);

  /// @notice Sets the VRF Coordinator address
  /// @notice This method should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwnerWithProposal} from "./ConfirmedOwnerWithProposal.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFSubscriptionV2Plus interface defines the subscription
/// @notice related methods implemented by the V2Plus coordinator.
interface IVRFSubscriptionV2Plus {
  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint256 subId, address to) external;

  /**
   * @notice Accept subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner) external;

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription with LINK, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   * @dev Note to fund the subscription with Native, use fundSubscriptionWithNative. Be sure
   * @dev  to send Native with the call, for example:
   * @dev COORDINATOR.fundSubscriptionWithNative{value: amount}(subId);
   */
  function createSubscription() external returns (uint256 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return nativeBalance - native balance of the subscription in wei.
   * @return reqCount - Requests count of subscription.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint256 subId
  )
    external
    view
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address owner, address[] memory consumers);

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint256 subId) external view returns (bool);

  /**
   * @notice Paginate through all active VRF subscriptions.
   * @param startIndex index of the subscription to start from
   * @param maxCount maximum number of subscriptions to return, 0 to return all
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * @dev should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveSubscriptionIds(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  /**
   * @notice Fund a subscription with native.
   * @param subId - ID of the subscription
   * @notice This method expects msg.value to be greater than or equal to 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOwnable } from "../interfaces/IOwnable.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
    address private s_owner;
    address private s_pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(address newOwner, address pendingOwner) {
        // solhint-disable-next-line gas-custom-errors
        require(newOwner != address(0), "Cannot set owner to zero");

        s_owner = newOwner;
        if (pendingOwner != address(0)) {
            _transferOwnership(pendingOwner);
        }
    }

    /// @notice Allows an owner to begin transferring ownership to a new address.
    function transferOwnership(address to) public override onlyOwner {
        _transferOwnership(to);
    }

    /// @notice Allows an ownership transfer to be completed by the recipient.
    function acceptOwnership() external override {
        // solhint-disable-next-line gas-custom-errors
        require(msg.sender == s_pendingOwner, "Must be proposed owner");

        address oldOwner = s_owner;
        s_owner = msg.sender;
        s_pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /// @notice Get the current owner
    function owner() public view override returns (address) {
        return s_owner;
    }

    /// @notice validate, transfer ownership, and emit relevant events
    function _transferOwnership(address to) private {
        // solhint-disable-next-line gas-custom-errors
        require(to != msg.sender, "Cannot transfer to self");

        s_pendingOwner = to;

        emit OwnershipTransferRequested(s_owner, to);
    }

    /// @notice validate access
    function _validateOwnership() internal view {
        // solhint-disable-next-line gas-custom-errors
        require(msg.sender == s_owner, "Only callable by owner");
    }

    /// @notice Reverts if called by anyone other than the contract owner.
    modifier onlyOwner() {
        _validateOwnership();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}