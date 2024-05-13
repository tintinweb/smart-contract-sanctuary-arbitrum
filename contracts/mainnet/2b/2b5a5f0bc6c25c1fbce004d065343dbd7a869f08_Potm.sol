// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./LinkTokenInterface.sol";


contract Potm is VRFConsumerBaseV2 {
    struct Prize {
        string name;
        address winner;
        bool isClaimed;
    }

    Prize[] public prizes;
    mapping(address => uint256) public ticketsPerParticipant;
    mapping(address => uint256) public initialTicketsPerParticipant;

    address[] public participants;
    bool public hasDrawn = false;
    address public owner;
    uint256 public claimDeadline;
    uint256 constant CLAIM_DURATION = 7 days;

    // Constantes configurées directement dans le code du contrat
    address private constant VRF_COORDINATOR = 0x41034678D6C633D8a95c75e1138A360a28bA15d1; // L'adresse du VRFCoordinator V2 pour votre réseau
    address private constant LINK_TOKEN_ADDRESS = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4; // L'adresse du token LINK pour votre réseau
    bytes32 private constant KEY_HASH = 0x72d2b016bb5b62912afea355ebf33b91319f828738b111b723b78696b9847b63; // Le keyHash spécifique à votre niveau de service et réseau
    uint64 private constant SUBSCRIPTION_ID = 202; // L'ID d'abonnement que vous avez créé via Chainlink VRF

    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    VRFCoordinatorV2Interface private COORDINATOR;

    event PrizeDrawn(string prizeName, address winner);
    event PrizeClaimed(string prizeName, address claimer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() VRFConsumerBaseV2(VRF_COORDINATOR) {
        owner = msg.sender;
        initializePrizes();
    }

    function initializePrizes() private {
        prizes.push(Prize("Pudgy Penguin #196", address(0), false));
        prizes.push(Prize("Lil Pudgy #16565", address(0), false));
        prizes.push(Prize("Lil Pudgy #18590", address(0), false));
        prizes.push(Prize("Lil Pudgy #18584", address(0), false));
        prizes.push(Prize("Lil Pudgy #20259", address(0), false));
        prizes.push(Prize("10000 PINGU", address(0), false));
        prizes.push(Prize("9000 PINGU", address(0), false));
        prizes.push(Prize("8000 PINGU", address(0), false));
        prizes.push(Prize("7000 PINGU", address(0), false));
        prizes.push(Prize("6000 PINGU", address(0), false));
        prizes.push(Prize("5000 PINGU", address(0), false));
        prizes.push(Prize("4500 PINGU", address(0), false));
        prizes.push(Prize("4000 PINGU", address(0), false));
        prizes.push(Prize("3500 PINGU", address(0), false));
        prizes.push(Prize("3000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
    }

    function addParticipants(address[] memory _participants, uint256[] memory _tickets) public onlyOwner {
        require(_participants.length == _tickets.length, "Participants and tickets must match");
        for (uint i = 0; i < _participants.length; i++) {
            require(ticketsPerParticipant[_participants[i]] == 0, "Participant already added");
            ticketsPerParticipant[_participants[i]] = _tickets[i];
            initialTicketsPerParticipant[_participants[i]] = _tickets[i];
            participants.push(_participants[i]);
        }
    }

    function drawPrizes() public onlyOwner {
        require(!hasDrawn, "Draw has already been performed");
        hasDrawn = true;
        claimDeadline = block.timestamp + CLAIM_DURATION;
        for (uint i = 0; i < prizes.length; i++) {
            requestRandomWords();
        }
    }

    function requestRandomWords() private {
        COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 prizeIndex = requestId % prizes.length; // Utilisation du requestId pour identifier le prix (si nécessaire)
        uint256 winnerIndex = randomWords[0] % participants.length;
        prizes[prizeIndex].winner = participants[winnerIndex];
        emit PrizeDrawn(prizes[prizeIndex].name, participants[winnerIndex]);
    }

    function claimPrize(uint256 prizeIndex) public {
        require(prizes[prizeIndex].winner == msg.sender, "You are not the winner of this prize");
        require(block.timestamp <= claimDeadline, "Claim period has ended");
        require(!prizes[prizeIndex].isClaimed, "Prize already claimed");
        prizes[prizeIndex].isClaimed = true;
        emit PrizeClaimed(prizes[prizeIndex].name, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable-next-line interface-starts-with-i
interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
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