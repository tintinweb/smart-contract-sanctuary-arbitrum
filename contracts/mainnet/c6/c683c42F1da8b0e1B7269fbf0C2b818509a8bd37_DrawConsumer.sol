// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/// @title Handles drawing of Chainlink VRF numbers for the lottery system.
contract DrawConsumer is VRFConsumerBaseV2 {

    /// @dev Numbers available at beginning of draw.
    uint256 public AVAILABLE_NUMBERS;
    /// @dev Draw offset.
    uint256 public DIGIT_OFFSET;

    /// @dev Checks if initialized.
    bool public isInitialized = false;

    /// @dev Tracks drawable numbers;
    uint256[] public availableNumbers;
    /// @dev Tracks drawable numbers max;
    uint256 public availableNumbersLeft;

    /*
     * @dev Keyhash used for Chainlink VRF.
     * Arbitrum Sepolia: 0x027f94ff1465b3525f9fc03e9ff7d6d2c0953482246dd6ae07570c45d6631414;
     */
    bytes32 keyHash;

    /// @dev Interface for VRFCoordinatorV2.
    VRFCoordinatorV2Interface COORDINATOR;
    /// @dev Callback gas limit.
    uint32 callbackGasLimit = 2500000;
    /// @dev Request confirmations.
    uint16 requestConfirmations = 10;

    /*
     * @dev Consumer Subscription ID.
     * Arbitrum Sepolia: 275;
     */
    uint64 public subscriptionId;

    struct Draw {
        // chainlink VRF request id
        uint256 requestId;
        // Winning Numbers
        uint256[] winningNumbers;
        // Numbers drawn
        uint32 numWords;
    }

    /// @dev Total draws.
    uint256 public totalDraws = 0;

    /// @dev Mapping of draw ID to request ID.
    mapping (uint256 => uint256) private requestIds;
    /// @dev Mapping of draw ID to random words. (for re-verifiability)
    mapping (uint256 => uint256[]) private drawIdsToRandomWords;

    /// @dev Mapping of request ID to draw ID.
    mapping (uint256 => uint256) private drawIds;
    /// @dev Mapping of requst ID to draw info.
    mapping (uint256 => Draw) private draws;

    event DrawRequested(uint256 drawId, uint256 requestId);
    event DrawFulfilled(uint256 drawId, uint256 requestId, uint256[] randomWords, uint256[] winningNumbers);
    event Initialized();

    /// @dev Owner Address
    address public owner;

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    /// @dev Transfers ownership to (`newOwner`).
    /// Transfer to zero address to renounce ownership to disable `onlyOwner` functionality.
    function TransferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    event OwnershipTransferred(address oldOwner, address newOwner);

    constructor (
        bytes32 _keyHash,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        uint256 _available_numbers,
        uint256 _digit_offset
    ) 
        VRFConsumerBaseV2(_vrfCoordinator) 
    {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;

        AVAILABLE_NUMBERS = _available_numbers;
        DIGIT_OFFSET = _digit_offset;

        owner = msg.sender;
    }

    /// @dev Initialize availableNumbers.
    function Initialize(uint256 batchCount) external onlyOwner {
        require(!isInitialized, "Already initialized");

        if (availableNumbers.length == 0) {
            // Initialize an array for the range of possible numbers
            availableNumbers = new uint256[](AVAILABLE_NUMBERS);
        } 
            
        uint256 maxBatchCount = availableNumbersLeft + batchCount > AVAILABLE_NUMBERS 
            ? AVAILABLE_NUMBERS 
            : availableNumbersLeft + batchCount;

        for (uint256 i = availableNumbersLeft; i < maxBatchCount; i += 1) {
            availableNumbers[i] = i + DIGIT_OFFSET; // Populate it through AVAILABLE_NUMBERS
        }
        availableNumbersLeft = maxBatchCount;

        if (availableNumbersLeft == AVAILABLE_NUMBERS) {
            isInitialized = true;
            emit Initialized();
        }
    }

    /// @dev Allows owner to subscription ID.
    function UpdateSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    /// @dev Initiates the request to draw random numbers using Chainlink VRF
    /// @dev Returns used request ID.
    function RequestDraw(uint32 numWords) external onlyOwner returns (uint256 requestId) {     
        require(isInitialized, "Not ready");
        require(numWords > 0 && numWords <= 10, "Between 1-10 numbers only");
        require(numWords <= availableNumbersLeft, "No numbers left");

        uint256 drawId = GetNextDrawId();

        require(requestIds[drawId] == 0, "Already drawn");

        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        drawIds[requestId] = drawId;
        draws[drawId].numWords = numWords;

        requestIds[drawId] = requestId;

        totalDraws += 1;
        emit DrawRequested(drawId, requestId);
        return requestId;
    }

    /// @dev Draws the winning numbers and additional number.
    /// @dev Callback function used by VRF Coordinator
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Record and emit event.
        uint256 drawId = drawIds[requestId];
        
        uint256[] memory winningNumbers = findWinningNumbers(randomWords, drawId);

        draws[drawId].requestId = requestId;
        draws[drawId].winningNumbers = winningNumbers;

        drawIdsToRandomWords[drawId] = randomWords;
        
        emit DrawFulfilled(drawId, requestId, randomWords, winningNumbers);
    }

    /// @notice Returns unique numbers.
    function findWinningNumbers(uint256[] memory randomWords, uint256 drawId) internal
    returns (uint256[] memory winningNumbers) {
        winningNumbers = new uint256[](draws[drawId].numWords);

        for (uint256 draw = 0; draw < draws[drawId].numWords; draw += 1) {
            uint256 selectedIndex = randomWords[draw] % availableNumbersLeft;
            uint256 selectedNumber = availableNumbers[selectedIndex];

            winningNumbers[draw] = selectedNumber;

            // Move the last number in the array to the selected index (to remove the selected number)
            availableNumbers[selectedIndex] = availableNumbers[availableNumbersLeft - 1];
            availableNumbersLeft -= 1; // Reduce the count of available numbers
        }
    }

    /// @notice Returns the draw ID of the next draw.
    function GetNextDrawId() public view returns (uint256 nextDrawId) {
        nextDrawId = totalDraws + 1;
    }

    /// @notice Returns the draw result for (`_drawId`).
    function GetDraw(uint256 _drawId) external view 
    returns (uint256 id, uint256[] memory winningNumbers, uint256 numWords) {
        id = _drawId;
        winningNumbers = draws[_drawId].winningNumbers;
        numWords = draws[_drawId].numWords;
    }

    /// @notice Returns the randomWords used for (`drawId`).
    function GetRandomWords(uint256 drawId) external view
    returns (uint256[] memory randomWords) {
        return drawIdsToRandomWords[drawId];
    }
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
  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
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
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

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