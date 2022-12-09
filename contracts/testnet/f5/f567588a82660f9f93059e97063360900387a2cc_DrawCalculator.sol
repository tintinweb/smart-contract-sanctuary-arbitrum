// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./RNGChainlinkV2Interface.sol";

contract RNGChainlinkV2 is RNGChainlinkV2Interface, VRFConsumerBaseV2, Manageable {
  /* ============ Global Variables ============ */

  /// @dev Reference to the VRFCoordinatorV2 deployed contract
  VRFCoordinatorV2Interface internal vrfCoordinator;

  /// @dev A counter for the number of requests made used for request ids
  uint32 internal requestCounter;

  /// @dev Chainlink VRF subscription id
  uint64 internal subscriptionId;

  /// @dev Hash of the public key used to verify the VRF proof
  bytes32 internal keyHash;

  /// @dev A list of random numbers from past requests mapped by request id
  mapping(uint32 => uint256) internal randomNumbers;

  /// @dev A list of blocks to be locked at based on past requests mapped by request id
  mapping(uint32 => uint32) internal requestLockBlock;

  /// @dev A mapping from Chainlink request ids to internal request ids
  mapping(uint256 => uint32) internal chainlinkRequestIds;

  /* ============ Events ============ */

  /**
   * @notice Emitted when the Chainlink VRF keyHash is set
   * @param keyHash Chainlink VRF keyHash
   */
  event KeyHashSet(bytes32 keyHash);

  /**
   * @notice Emitted when the Chainlink VRF subscription id is set
   * @param subscriptionId Chainlink VRF subscription id
   */
  event SubscriptionIdSet(uint64 subscriptionId);

  /**
   * @notice Emitted when the Chainlink VRF Coordinator address is set
   * @param vrfCoordinator Address of the VRF Coordinator
   */
  event VrfCoordinatorSet(VRFCoordinatorV2Interface indexed vrfCoordinator);

  /* ============ Constructor ============ */

  /**
   * @notice Constructor of the contract
   * @param _owner Owner of the contract
   * @param _vrfCoordinator Address of the VRF Coordinator
   * @param _subscriptionId Chainlink VRF subscription id
   * @param _keyHash Hash of the public key used to verify the VRF proof
   */
  constructor(
    address _owner,
    VRFCoordinatorV2Interface _vrfCoordinator,
    uint64 _subscriptionId,
    bytes32 _keyHash
  ) Ownable(_owner) VRFConsumerBaseV2(address(_vrfCoordinator)) {
    _setVRFCoordinator(_vrfCoordinator);
    _setSubscriptionId(_subscriptionId);
    _setKeyhash(_keyHash);
  }

  /* ============ External Functions ============ */

  /// @inheritdoc RNGInterface
  function requestRandomNumber()
    external
    override
    onlyManager
    returns (uint32 requestId, uint32 lockBlock)
  {
    uint256 _vrfRequestId = vrfCoordinator.requestRandomWords(
      keyHash,
      subscriptionId,
      3,
      1000000,
      1
    );

    requestCounter++;
    uint32 _requestCounter = requestCounter;

    requestId = _requestCounter;
    chainlinkRequestIds[_vrfRequestId] = _requestCounter;

    lockBlock = uint32(block.number);
    requestLockBlock[_requestCounter] = lockBlock;

    emit RandomNumberRequested(_requestCounter, msg.sender);
  }

  /// @inheritdoc RNGInterface
  function isRequestComplete(uint32 _internalRequestId)
    external
    view
    override
    returns (bool isCompleted)
  {
    return randomNumbers[_internalRequestId] != 0;
  }

  /// @inheritdoc RNGInterface
  function randomNumber(uint32 _internalRequestId)
    external
    view
    override
    returns (uint256 randomNum)
  {
    return randomNumbers[_internalRequestId];
  }

  /// @inheritdoc RNGInterface
  function getLastRequestId() external view override returns (uint32 requestId) {
    return requestCounter;
  }

  /// @inheritdoc RNGInterface
  function getRequestFee() external pure override returns (address feeToken, uint256 requestFee) {
    return (address(0), 0);
  }

  /// @inheritdoc RNGChainlinkV2Interface
  function getKeyHash() external view override returns (bytes32) {
    return keyHash;
  }

  /// @inheritdoc RNGChainlinkV2Interface
  function getSubscriptionId() external view override returns (uint64) {
    return subscriptionId;
  }

  /// @inheritdoc RNGChainlinkV2Interface
  function getVrfCoordinator() external view override returns (VRFCoordinatorV2Interface) {
    return vrfCoordinator;
  }

  /// @inheritdoc RNGChainlinkV2Interface
  function setSubscriptionId(uint64 _subscriptionId) external override onlyOwner {
    _setSubscriptionId(_subscriptionId);
  }

  /// @inheritdoc RNGChainlinkV2Interface
  function setKeyhash(bytes32 _keyHash) external override onlyOwner {
    _setKeyhash(_keyHash);
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Callback function called by VRF Coordinator
   * @dev The VRF Coordinator will only call it once it has verified the proof associated with the randomness.
   * @param _vrfRequestId Chainlink VRF request id
   * @param _randomWords Chainlink VRF array of random words
   */
  function fulfillRandomWords(uint256 _vrfRequestId, uint256[] memory _randomWords)
    internal
    override
  {
    uint32 _internalRequestId = chainlinkRequestIds[_vrfRequestId];
    require(_internalRequestId > 0, "RNGChainLink/requestId-incorrect");

    uint256 _randomNumber = _randomWords[0];
    randomNumbers[_internalRequestId] = _randomNumber;

    emit RandomNumberCompleted(_internalRequestId, _randomNumber);
  }

  /**
   * @notice Set Chainlink VRF coordinator contract address.
   * @param _vrfCoordinator Chainlink VRF coordinator contract address
   */
  function _setVRFCoordinator(VRFCoordinatorV2Interface _vrfCoordinator) internal {
    require(address(_vrfCoordinator) != address(0), "RNGChainLink/vrf-not-zero-addr");
    vrfCoordinator = _vrfCoordinator;
    emit VrfCoordinatorSet(_vrfCoordinator);
  }

  /**
   * @notice Set Chainlink VRF subscription id associated with this contract.
   * @param _subscriptionId Chainlink VRF subscription id
   */
  function _setSubscriptionId(uint64 _subscriptionId) internal {
    require(_subscriptionId > 0, "RNGChainLink/subId-gt-zero");
    subscriptionId = _subscriptionId;
    emit SubscriptionIdSet(_subscriptionId);
  }

  /**
   * @notice Set Chainlink VRF keyHash.
   * @param _keyHash Chainlink VRF keyHash
   */
  function _setKeyhash(bytes32 _keyHash) internal {
    require(_keyHash != bytes32(0), "RNGChainLink/keyHash-not-empty");
    keyHash = _keyHash;
    emit KeyHashSet(_keyHash);
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
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

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
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @title Abstract manageable contract that can be inherited by other contracts
 * @notice Contract module based on Ownable which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(address indexed previousManager, address indexed newManager);

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(_newManager != _previousManager, "Manageable/existing-manager-address");

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);
        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == msg.sender, "Manageable/caller-not-manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(manager() == msg.sender || owner() == msg.sender, "Manageable/caller-not-manager-or-owner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./RNGInterface.sol";

/**
 * @title RNG Chainlink V2 Interface
 * @notice Provides an interface for requesting random numbers from Chainlink VRF V2.
 */
interface RNGChainlinkV2Interface is RNGInterface {
  /**
   * @notice Get Chainlink VRF keyHash associated with this contract.
   * @return bytes32 Chainlink VRF keyHash
   */
  function getKeyHash() external view returns (bytes32);

  /**
   * @notice Get Chainlink VRF subscription id associated with this contract.
   * @return uint64 Chainlink VRF subscription id
   */
  function getSubscriptionId() external view returns (uint64);

  /**
   * @notice Get Chainlink VRF coordinator contract address associated with this contract.
   * @return address Chainlink VRF coordinator address
   */
  function getVrfCoordinator() external view returns (VRFCoordinatorV2Interface);

  /**
   * @notice Set Chainlink VRF keyHash.
   * @dev This function is only callable by the owner.
   * @param keyHash Chainlink VRF keyHash
   */
  function setKeyhash(bytes32 keyHash) external;

  /**
   * @notice Set Chainlink VRF subscription id associated with this contract.
   * @dev This function is only callable by the owner.
   * @param subscriptionId Chainlink VRF subscription id
   */
  function setSubscriptionId(uint64 subscriptionId) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/**
 * @title Random Number Generator Interface
 * @notice Provides an interface for requesting random numbers from 3rd-party RNG services (Chainlink VRF, Starkware VDF, etc..)
 */
interface RNGInterface {
  /**
   * @notice Emitted when a new request for a random number has been submitted
   * @param requestId The indexed ID of the request used to get the results of the RNG service
   * @param sender The indexed address of the sender of the request
   */
  event RandomNumberRequested(uint32 indexed requestId, address indexed sender);

  /**
   * @notice Emitted when an existing request for a random number has been completed
   * @param requestId The indexed ID of the request used to get the results of the RNG service
   * @param randomNumber The random number produced by the 3rd-party service
   */
  event RandomNumberCompleted(uint32 indexed requestId, uint256 randomNumber);

  /**
   * @notice Gets the last request id used by the RNG service
   * @return requestId The last request id used in the last request
   */
  function getLastRequestId() external view returns (uint32 requestId);

  /**
   * @notice Gets the Fee for making a Request against an RNG service
   * @return feeToken The address of the token that is used to pay fees
   * @return requestFee The fee required to be paid to make a request
   */
  function getRequestFee() external view returns (address feeToken, uint256 requestFee);

  /**
   * @notice Sends a request for a random number to the 3rd-party service
   * @dev Some services will complete the request immediately, others may have a time-delay
   * @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
   * @return requestId The ID of the request used to get the results of the RNG service
   * @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.
   * The calling contract should "lock" all activity until the result is available via the `requestId`
   */
  function requestRandomNumber() external returns (uint32 requestId, uint32 lockBlock);

  /**
   * @notice Checks if the request for randomness from the 3rd-party service has completed
   * @dev For time-delayed requests, this function is used to check/confirm completion
   * @param requestId The ID of the request used to get the results of the RNG service
   * @return isCompleted True if the request has completed and a random number is available, false otherwise
   */
  function isRequestComplete(uint32 requestId) external view returns (bool isCompleted);

  /**
   * @notice Gets the random number produced by the 3rd-party service
   * @param requestId The ID of the request used to get the results of the RNG service
   * @return randomNum The random number
   */
  function randomNumber(uint32 requestId) external returns (uint256 randomNum);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";
import "./IDrawBuffer.sol";

/** @title  IDrawBeacon
  * @author PoolTogether Inc Team
  * @notice The DrawBeacon interface.
*/
interface IDrawBeacon {

    /// @notice Draw struct created every draw
    /// @param winningRandomNumber The random number returned from the RNG service
    /// @param drawId The monotonically increasing drawId for each draw
    /// @param timestamp Unix timestamp of the draw. Recorded when the draw is created by the DrawBeacon.
    /// @param beaconPeriodStartedAt Unix timestamp of when the draw started
    /// @param beaconPeriodSeconds Unix timestamp of the beacon draw period for this draw.
    struct Draw {
        uint256 winningRandomNumber;
        uint32 drawId;
        uint64 timestamp;
        uint64 beaconPeriodStartedAt;
        uint32 beaconPeriodSeconds;
    }

    /**
     * @notice Emit when a new DrawBuffer has been set.
     * @param newDrawBuffer       The new DrawBuffer address
     */
    event DrawBufferUpdated(IDrawBuffer indexed newDrawBuffer);

    /**
     * @notice Emit when a draw has opened.
     * @param startedAt Start timestamp
     */
    event BeaconPeriodStarted(uint64 indexed startedAt);

    /**
     * @notice Emit when a draw has started.
     * @param rngRequestId  draw id
     * @param rngLockBlock  Block when draw becomes invalid
     */
    event DrawStarted(uint32 indexed rngRequestId, uint32 rngLockBlock);

    /**
     * @notice Emit when a draw has been cancelled.
     * @param rngRequestId  draw id
     * @param rngLockBlock  Block when draw becomes invalid
     */
    event DrawCancelled(uint32 indexed rngRequestId, uint32 rngLockBlock);

    /**
     * @notice Emit when a draw has been completed.
     * @param randomNumber  Random number generated from draw
     */
    event DrawCompleted(uint256 randomNumber);

    /**
     * @notice Emit when a RNG service address is set.
     * @param rngService  RNG service address
     */
    event RngServiceUpdated(RNGInterface indexed rngService);

    /**
     * @notice Emit when a draw timeout param is set.
     * @param rngTimeout  draw timeout param in seconds
     */
    event RngTimeoutSet(uint32 rngTimeout);

    /**
     * @notice Emit when the drawPeriodSeconds is set.
     * @param drawPeriodSeconds Time between draw
     */
    event BeaconPeriodSecondsUpdated(uint32 drawPeriodSeconds);

    /**
     * @notice Returns the number of seconds remaining until the beacon period can be complete.
     * @return The number of seconds remaining until the beacon period can be complete.
     */
    function beaconPeriodRemainingSeconds() external view returns (uint64);

    /**
     * @notice Returns the timestamp at which the beacon period ends
     * @return The timestamp at which the beacon period ends.
     */
    function beaconPeriodEndAt() external view returns (uint64);

    /**
     * @notice Returns whether a Draw can be started.
     * @return True if a Draw can be started, false otherwise.
     */
    function canStartDraw() external view returns (bool);

    /**
     * @notice Returns whether a Draw can be completed.
     * @return True if a Draw can be completed, false otherwise.
     */
    function canCompleteDraw() external view returns (bool);

    /**
     * @notice Calculates when the next beacon period will start.
     * @param time The timestamp to use as the current time
     * @return The timestamp at which the next beacon period would start
     */
    function calculateNextBeaconPeriodStartTime(uint64 time) external view returns (uint64);

    /**
     * @notice Can be called by anyone to cancel the draw request if the RNG has timed out.
     */
    function cancelDraw() external;

    /**
     * @notice Completes the Draw (RNG) request and pushes a Draw onto DrawBuffer.
     */
    function completeDraw() external;

    /**
     * @notice Returns the block number that the current RNG request has been locked to.
     * @return The block number that the RNG request is locked to
     */
    function getLastRngLockBlock() external view returns (uint32);

    /**
     * @notice Returns the current RNG Request ID.
     * @return The current Request ID
     */
    function getLastRngRequestId() external view returns (uint32);

    /**
     * @notice Returns whether the beacon period is over
     * @return True if the beacon period is over, false otherwise
     */
    function isBeaconPeriodOver() external view returns (bool);

    /**
     * @notice Returns whether the random number request has completed.
     * @return True if a random number request has completed, false otherwise.
     */
    function isRngCompleted() external view returns (bool);

    /**
     * @notice Returns whether a random number has been requested
     * @return True if a random number has been requested, false otherwise.
     */
    function isRngRequested() external view returns (bool);

    /**
     * @notice Returns whether the random number request has timed out.
     * @return True if a random number request has timed out, false otherwise.
     */
    function isRngTimedOut() external view returns (bool);

    /**
     * @notice Allows the owner to set the beacon period in seconds.
     * @param beaconPeriodSeconds The new beacon period in seconds.  Must be greater than zero.
     */
    function setBeaconPeriodSeconds(uint32 beaconPeriodSeconds) external;

    /**
     * @notice Allows the owner to set the RNG request timeout in seconds. This is the time that must elapsed before the RNG request can be cancelled and the pool unlocked.
     * @param rngTimeout The RNG request timeout in seconds.
     */
    function setRngTimeout(uint32 rngTimeout) external;

    /**
     * @notice Sets the RNG service that the Prize Strategy is connected to
     * @param rngService The address of the new RNG service interface
     */
    function setRngService(RNGInterface rngService) external;

    /**
     * @notice Starts the Draw process by starting random number request. The previous beacon period must have ended.
     * @dev The RNG-Request-Fee is expected to be held within this contract before calling this function
     */
    function startDraw() external;

    /**
     * @notice Set global DrawBuffer variable.
     * @dev    All subsequent Draw requests/completions will be pushed to the new DrawBuffer.
     * @param newDrawBuffer DrawBuffer address
     * @return DrawBuffer
     */
    function setDrawBuffer(IDrawBuffer newDrawBuffer) external returns (IDrawBuffer);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../interfaces/IDrawBeacon.sol";

/** @title  IDrawBuffer
  * @author PoolTogether Inc Team
  * @notice The DrawBuffer interface.
*/
interface IDrawBuffer {
    /**
     * @notice Emit when a new draw has been created.
     * @param drawId Draw id
     * @param draw The Draw struct
     */
    event DrawSet(uint32 indexed drawId, IDrawBeacon.Draw draw);

    /**
     * @notice Read a ring buffer cardinality
     * @return Ring buffer cardinality
     */
    function getBufferCardinality() external view returns (uint32);

    /**
     * @notice Read a Draw from the draws ring buffer.
     * @dev    Read a Draw using the Draw.drawId to calculate position in the draws ring buffer.
     * @param drawId Draw.drawId
     * @return IDrawBeacon.Draw
     */
    function getDraw(uint32 drawId) external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Read multiple Draws from the draws ring buffer.
     * @dev    Read multiple Draws using each drawId to calculate position in the draws ring buffer.
     * @param drawIds Array of drawIds
     * @return IDrawBeacon.Draw[]
     */
    function getDraws(uint32[] calldata drawIds) external view returns (IDrawBeacon.Draw[] memory);

    /**
     * @notice Gets the number of Draws held in the draw ring buffer.
     * @dev If no Draws have been pushed, it will return 0.
     * @dev If the ring buffer is full, it will return the cardinality.
     * @dev Otherwise, it will return the NewestDraw index + 1.
     * @return Number of Draws held in the draw ring buffer.
     */
    function getDrawCount() external view returns (uint32);

    /**
     * @notice Read newest Draw from draws ring buffer.
     * @dev    Uses the nextDrawIndex to calculate the most recently added Draw.
     * @return IDrawBeacon.Draw
     */
    function getNewestDraw() external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Read oldest Draw from draws ring buffer.
     * @dev    Finds the oldest Draw by comparing and/or diffing totalDraws with the cardinality.
     * @return IDrawBeacon.Draw
     */
    function getOldestDraw() external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Push new draw onto draws history via authorized manager or owner.
     * @param draw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function pushDraw(IDrawBeacon.Draw calldata draw) external returns (uint32);

    /**
     * @notice Set existing Draw in draws ring buffer with new parameters.
     * @dev    Updating a Draw should be used sparingly and only in the event an incorrect Draw parameter has been stored.
     * @param newDraw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function setDraw(IDrawBeacon.Draw calldata newDraw) external returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "./IPrizeDistributionFactory.sol";
import "./IDrawCalculatorTimelock.sol";

/**
 * @title  PoolTogether V4 IReceiverTimelockTrigger
 * @author PoolTogether Inc Team
 * @notice The IReceiverTimelockTrigger smart contract interface...
 */
interface IReceiverTimelockTrigger {
    /// @notice Emitted when the contract is deployed.
    event Deployed(
        IDrawBuffer indexed drawBuffer,
        IPrizeDistributionFactory indexed prizeDistributionFactory,
        IDrawCalculatorTimelock indexed timelock
    );

    /**
     * @notice Emitted when Draw is locked, pushed to Draw DrawBuffer and totalNetworkTicketSupply is pushed to PrizeDistributionFactory
     * @param drawId Draw ID
     * @param draw Draw
     * @param totalNetworkTicketSupply totalNetworkTicketSupply
     */
    event DrawLockedPushedAndTotalNetworkTicketSupplyPushed(
        uint32 indexed drawId,
        IDrawBeacon.Draw draw,
        uint256 totalNetworkTicketSupply
    );

    /**
     * @notice Locks next Draw, pushes Draw to DraWBuffer and pushes totalNetworkTicketSupply to PrizeDistributionFactory.
     * @dev    Restricts new draws for N seconds by forcing timelock on the next target draw id.
     * @param draw Draw
     * @param totalNetworkTicketSupply totalNetworkTicketSupply
     */
    function push(IDrawBeacon.Draw memory draw, uint256 totalNetworkTicketSupply) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface IPrizeDistributionFactory {
    function pushPrizeDistribution(uint32 _drawId, uint256 _totalNetworkTicketSupply) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/v4-core/contracts/interfaces/IDrawCalculator.sol";

interface IDrawCalculatorTimelock {
    /**
     * @notice Emitted when target draw id is locked.
     * @param timestamp The epoch timestamp to unlock the current locked Draw
     * @param drawId    The Draw to unlock
     */
    struct Timelock {
        uint64 timestamp;
        uint32 drawId;
    }

    /**
     * @notice Emitted when target draw id is locked.
     * @param drawId    Draw ID
     * @param timestamp Block timestamp
     */
    event LockedDraw(uint32 indexed drawId, uint64 timestamp);

    /**
     * @notice Emitted event when the timelock struct is updated
     * @param timelock Timelock struct set
     */
    event TimelockSet(Timelock timelock);

    /**
     * @notice Routes claim/calculate requests between PrizeDistributor and DrawCalculator.
     * @dev    Will enforce a "cooldown" period between when a Draw is pushed and when users can start to claim prizes.
     * @param user    User address
     * @param drawIds Draw.drawId
     * @param data    Encoded pick indices
     * @return Prizes awardable array
     */
    function calculate(
        address user,
        uint32[] calldata drawIds,
        bytes calldata data
    ) external view returns (uint256[] memory, bytes memory);

    /**
     * @notice Lock passed draw id for `timelockDuration` seconds.
     * @dev    Restricts new draws by forcing a push timelock.
     * @param _drawId Draw id to lock.
     * @param _timestamp Epoch timestamp to unlock the draw.
     * @return True if operation was successful.
     */
    function lock(uint32 _drawId, uint64 _timestamp) external returns (bool);

    /**
     * @notice Read internal DrawCalculator variable.
     * @return IDrawCalculator
     */
    function getDrawCalculator() external view returns (IDrawCalculator);

    /**
     * @notice Read internal Timelock struct.
     * @return Timelock
     */
    function getTimelock() external view returns (Timelock memory);

    /**
     * @notice Set the Timelock struct. Only callable by the contract owner.
     * @param _timelock Timelock struct to set.
     */
    function setTimelock(Timelock memory _timelock) external;

    /**
     * @notice Returns bool for timelockDuration elapsing.
     * @return True if timelockDuration, since last timelock has elapsed, false otherwise.
     */
    function hasElapsed() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./ITicket.sol";
import "./IDrawBuffer.sol";
import "../PrizeDistributionBuffer.sol";
import "../PrizeDistributor.sol";

/**
 * @title  PoolTogether V4 IDrawCalculator
 * @author PoolTogether Inc Team
 * @notice The DrawCalculator interface.
 */
interface IDrawCalculator {
    struct PickPrize {
        bool won;
        uint8 tierIndex;
    }

    ///@notice Emitted when the contract is initialized
    event Deployed(
        ITicket indexed ticket,
        IDrawBuffer indexed drawBuffer,
        IPrizeDistributionBuffer indexed prizeDistributionBuffer
    );

    ///@notice Emitted when the prizeDistributor is set/updated
    event PrizeDistributorSet(PrizeDistributor indexed prizeDistributor);

    /**
     * @notice Calculates the prize amount for a user for Multiple Draws. Typically called by a PrizeDistributor.
     * @param user User for which to calculate prize amount.
     * @param drawIds drawId array for which to calculate prize amounts for.
     * @param data The ABI encoded pick indices for all Draws. Expected to be winning picks. Pick indices must be less than the totalUserPicks.
     * @return List of awardable prize amounts ordered by drawId.
     */
    function calculate(
        address user,
        uint32[] calldata drawIds,
        bytes calldata data
    ) external view returns (uint256[] memory, bytes memory);

    /**
     * @notice Read global DrawBuffer variable.
     * @return IDrawBuffer
     */
    function getDrawBuffer() external view returns (IDrawBuffer);

    /**
     * @notice Read global prizeDistributionBuffer variable.
     * @return IPrizeDistributionBuffer
     */
    function getPrizeDistributionBuffer() external view returns (IPrizeDistributionBuffer);

    /**
     * @notice Returns a users balances expressed as a fraction of the total supply over time.
     * @param user The users address
     * @param drawIds The drawIds to consider
     * @return Array of balances
     */
    function getNormalizedBalancesForDrawIds(address user, uint32[] calldata drawIds)
        external
        view
        returns (uint256[] memory);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../libraries/TwabLib.sol";
import "./IControlledToken.sol";

interface ITicket is IControlledToken {
    /**
     * @notice A struct containing details for an Account.
     * @param balance The current balance for an Account.
     * @param nextTwabIndex The next available index to store a new twab.
     * @param cardinality The number of recorded twabs (plus one!).
     */
    struct AccountDetails {
        uint224 balance;
        uint16 nextTwabIndex;
        uint16 cardinality;
    }

    /**
     * @notice Combines account details with their twab history.
     * @param details The account details.
     * @param twabs The history of twabs for this account.
     */
    struct Account {
        AccountDetails details;
        ObservationLib.Observation[65535] twabs;
    }

    /**
     * @notice Emitted when TWAB balance has been delegated to another user.
     * @param delegator Address of the delegator.
     * @param delegate Address of the delegate.
     */
    event Delegated(address indexed delegator, address indexed delegate);

    /**
     * @notice Emitted when ticket is initialized.
     * @param name Ticket name (eg: PoolTogether Dai Ticket (Compound)).
     * @param symbol Ticket symbol (eg: PcDAI).
     * @param decimals Ticket decimals.
     * @param controller Token controller address.
     */
    event TicketInitialized(string name, string symbol, uint8 decimals, address indexed controller);

    /**
     * @notice Emitted when a new TWAB has been recorded.
     * @param delegate The recipient of the ticket power (may be the same as the user).
     * @param newTwab Updated TWAB of a ticket holder after a successful TWAB recording.
     */
    event NewUserTwab(
        address indexed delegate,
        ObservationLib.Observation newTwab
    );

    /**
     * @notice Emitted when a new total supply TWAB has been recorded.
     * @param newTotalSupplyTwab Updated TWAB of tickets total supply after a successful total supply TWAB recording.
     */
    event NewTotalSupplyTwab(ObservationLib.Observation newTotalSupplyTwab);

    /**
     * @notice Retrieves the address of the delegate to whom `user` has delegated their tickets.
     * @dev Address of the delegate will be the zero address if `user` has not delegated their tickets.
     * @param user Address of the delegator.
     * @return Address of the delegate.
     */
    function delegateOf(address user) external view returns (address);

    /**
    * @notice Delegate time-weighted average balances to an alternative address.
    * @dev    Transfers (including mints) trigger the storage of a TWAB in delegate(s) account, instead of the
              targetted sender and/or recipient address(s).
    * @dev    To reset the delegate, pass the zero address (0x000.000) as `to` parameter.
    * @dev Current delegate address should be different from the new delegate address `to`.
    * @param  to Recipient of delegated TWAB.
    */
    function delegate(address to) external;

    /**
     * @notice Allows the controller to delegate on a users behalf.
     * @param user The user for whom to delegate
     * @param delegate The new delegate
     */
    function controllerDelegateFor(address user, address delegate) external;

    /**
     * @notice Allows a user to delegate via signature
     * @param user The user who is delegating
     * @param delegate The new delegate
     * @param deadline The timestamp by which this must be submitted
     * @param v The v portion of the ECDSA sig
     * @param r The r portion of the ECDSA sig
     * @param s The s portion of the ECDSA sig
     */
    function delegateWithSignature(
        address user,
        address delegate,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Gets a users twab context.  This is a struct with their balance, next twab index, and cardinality.
     * @param user The user for whom to fetch the TWAB context.
     * @return The TWAB context, which includes { balance, nextTwabIndex, cardinality }
     */
    function getAccountDetails(address user) external view returns (TwabLib.AccountDetails memory);

    /**
     * @notice Gets the TWAB at a specific index for a user.
     * @param user The user for whom to fetch the TWAB.
     * @param index The index of the TWAB to fetch.
     * @return The TWAB, which includes the twab amount and the timestamp.
     */
    function getTwab(address user, uint16 index)
        external
        view
        returns (ObservationLib.Observation memory);

    /**
     * @notice Retrieves `user` TWAB balance.
     * @param user Address of the user whose TWAB is being fetched.
     * @param timestamp Timestamp at which we want to retrieve the TWAB balance.
     * @return The TWAB balance at the given timestamp.
     */
    function getBalanceAt(address user, uint64 timestamp) external view returns (uint256);

    /**
     * @notice Retrieves `user` TWAB balances.
     * @param user Address of the user whose TWABs are being fetched.
     * @param timestamps Timestamps range at which we want to retrieve the TWAB balances.
     * @return `user` TWAB balances.
     */
    function getBalancesAt(address user, uint64[] calldata timestamps)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Retrieves the average balance held by a user for a given time frame.
     * @param user The user whose balance is checked.
     * @param startTime The start time of the time frame.
     * @param endTime The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function getAverageBalanceBetween(
        address user,
        uint64 startTime,
        uint64 endTime
    ) external view returns (uint256);

    /**
     * @notice Retrieves the average balances held by a user for a given time frame.
     * @param user The user whose balance is checked.
     * @param startTimes The start time of the time frame.
     * @param endTimes The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function getAverageBalancesBetween(
        address user,
        uint64[] calldata startTimes,
        uint64[] calldata endTimes
    ) external view returns (uint256[] memory);

    /**
     * @notice Retrieves the total supply TWAB balance at the given timestamp.
     * @param timestamp Timestamp at which we want to retrieve the total supply TWAB balance.
     * @return The total supply TWAB balance at the given timestamp.
     */
    function getTotalSupplyAt(uint64 timestamp) external view returns (uint256);

    /**
     * @notice Retrieves the total supply TWAB balance between the given timestamps range.
     * @param timestamps Timestamps range at which we want to retrieve the total supply TWAB balance.
     * @return Total supply TWAB balances.
     */
    function getTotalSuppliesAt(uint64[] calldata timestamps)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Retrieves the average total supply balance for a set of given time frames.
     * @param startTimes Array of start times.
     * @param endTimes Array of end times.
     * @return The average total supplies held during the time frame.
     */
    function getAverageTotalSuppliesBetween(
        uint64[] calldata startTimes,
        uint64[] calldata endTimes
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./libraries/DrawRingBufferLib.sol";
import "./interfaces/IPrizeDistributionBuffer.sol";

/**
  * @title  PoolTogether V4 PrizeDistributionBuffer
  * @author PoolTogether Inc Team
  * @notice The PrizeDistributionBuffer contract provides historical lookups of PrizeDistribution struct parameters (linked with a Draw ID) via a
            circular ring buffer. Historical PrizeDistribution parameters can be accessed on-chain using a drawId to calculate
            ring buffer storage slot. The PrizeDistribution parameters can be created by manager/owner and existing PrizeDistribution
            parameters can only be updated the owner. When adding a new PrizeDistribution basic sanity checks will be used to
            validate the incoming parameters.
*/
contract PrizeDistributionBuffer is IPrizeDistributionBuffer, Manageable {
    using DrawRingBufferLib for DrawRingBufferLib.Buffer;

    /// @notice The maximum cardinality of the prize distribution ring buffer.
    /// @dev even with daily draws, 256 will give us over 8 months of history.
    uint256 internal constant MAX_CARDINALITY = 256;

    /// @notice The ceiling for prize distributions.  1e9 = 100%.
    /// @dev It's fixed point 9 because 1e9 is the largest "1" that fits into 2**32
    uint256 internal constant TIERS_CEILING = 1e9;

    /// @notice Emitted when the contract is deployed.
    /// @param cardinality The maximum number of records in the buffer before they begin to expire.
    event Deployed(uint8 cardinality);

    /// @notice PrizeDistribution ring buffer history.
    IPrizeDistributionBuffer.PrizeDistribution[MAX_CARDINALITY]
        internal prizeDistributionRingBuffer;

    /// @notice Ring buffer metadata (nextIndex, lastId, cardinality)
    DrawRingBufferLib.Buffer internal bufferMetadata;

    /* ============ Constructor ============ */

    /**
     * @notice Constructor for PrizeDistributionBuffer
     * @param _owner Address of the PrizeDistributionBuffer owner
     * @param _cardinality Cardinality of the `bufferMetadata`
     */
    constructor(address _owner, uint8 _cardinality) Ownable(_owner) {
        bufferMetadata.cardinality = _cardinality;
        emit Deployed(_cardinality);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeDistributionBuffer
    function getBufferCardinality() external view override returns (uint32) {
        return bufferMetadata.cardinality;
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getPrizeDistribution(uint32 _drawId)
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return _getPrizeDistribution(bufferMetadata, _drawId);
    }

    /// @inheritdoc IPrizeDistributionSource
    function getPrizeDistributions(uint32[] calldata _drawIds)
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution[] memory)
    {
        uint256 drawIdsLength = _drawIds.length;
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        IPrizeDistributionBuffer.PrizeDistribution[]
            memory _prizeDistributions = new IPrizeDistributionBuffer.PrizeDistribution[](
                drawIdsLength
            );

        for (uint256 i = 0; i < drawIdsLength; i++) {
            _prizeDistributions[i] = _getPrizeDistribution(buffer, _drawIds[i]);
        }

        return _prizeDistributions;
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getPrizeDistributionCount() external view override returns (uint32) {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        if (buffer.lastDrawId == 0) {
            return 0;
        }

        uint32 bufferNextIndex = buffer.nextIndex;

        // If the buffer is full return the cardinality, else retun the nextIndex
        if (prizeDistributionRingBuffer[bufferNextIndex].matchCardinality != 0) {
            return buffer.cardinality;
        } else {
            return bufferNextIndex;
        }
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getNewestPrizeDistribution()
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution, uint32 drawId)
    {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        return (prizeDistributionRingBuffer[buffer.getIndex(buffer.lastDrawId)], buffer.lastDrawId);
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getOldestPrizeDistribution()
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution, uint32 drawId)
    {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        // if the ring buffer is full, the oldest is at the nextIndex
        prizeDistribution = prizeDistributionRingBuffer[buffer.nextIndex];

        // The PrizeDistribution at index 0 IS by default the oldest prizeDistribution.
        if (buffer.lastDrawId == 0) {
            drawId = 0; // return 0 to indicate no prizeDistribution ring buffer history
        } else if (prizeDistribution.bitRangeSize == 0) {
            // IF the next PrizeDistribution.bitRangeSize == 0 the ring buffer HAS NOT looped around so the oldest is the first entry.
            prizeDistribution = prizeDistributionRingBuffer[0];
            drawId = (buffer.lastDrawId + 1) - buffer.nextIndex;
        } else {
            // Calculates the drawId using the ring buffer cardinality
            // Sequential drawIds are gauranteed by DrawRingBufferLib.push()
            drawId = (buffer.lastDrawId + 1) - buffer.cardinality;
        }
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function pushPrizeDistribution(
        uint32 _drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution
    ) external override onlyManagerOrOwner returns (bool) {
        return _pushPrizeDistribution(_drawId, _prizeDistribution);
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function setPrizeDistribution(
        uint32 _drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution
    ) external override onlyOwner returns (uint32) {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        uint32 index = buffer.getIndex(_drawId);
        prizeDistributionRingBuffer[index] = _prizeDistribution;

        emit PrizeDistributionSet(_drawId, _prizeDistribution);

        return _drawId;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Gets the PrizeDistributionBuffer for a drawId
     * @param _buffer DrawRingBufferLib.Buffer
     * @param _drawId drawId
     */
    function _getPrizeDistribution(DrawRingBufferLib.Buffer memory _buffer, uint32 _drawId)
        internal
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return prizeDistributionRingBuffer[_buffer.getIndex(_drawId)];
    }

    /**
     * @notice Set newest PrizeDistributionBuffer in ring buffer storage.
     * @param _drawId       drawId
     * @param _prizeDistribution PrizeDistributionBuffer struct
     */
    function _pushPrizeDistribution(
        uint32 _drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution
    ) internal returns (bool) {
        require(_drawId > 0, "DrawCalc/draw-id-gt-0");
        require(_prizeDistribution.matchCardinality > 0, "DrawCalc/matchCardinality-gt-0");
        require(
            _prizeDistribution.bitRangeSize <= 256 / _prizeDistribution.matchCardinality,
            "DrawCalc/bitRangeSize-too-large"
        );

        require(_prizeDistribution.bitRangeSize > 0, "DrawCalc/bitRangeSize-gt-0");
        require(_prizeDistribution.maxPicksPerUser > 0, "DrawCalc/maxPicksPerUser-gt-0");
        require(_prizeDistribution.expiryDuration > 0, "DrawCalc/expiryDuration-gt-0");

        // ensure that the sum of the tiers are not gt 100%
        uint256 sumTotalTiers = 0;
        uint256 tiersLength = _prizeDistribution.tiers.length;

        for (uint256 index = 0; index < tiersLength; index++) {
            uint256 tier = _prizeDistribution.tiers[index];
            sumTotalTiers += tier;
        }

        // Each tier amount stored as uint32 - summed can't exceed 1e9
        require(sumTotalTiers <= TIERS_CEILING, "DrawCalc/tiers-gt-100%");

        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        // store the PrizeDistribution in the ring buffer
        prizeDistributionRingBuffer[buffer.nextIndex] = _prizeDistribution;

        // update the ring buffer data
        bufferMetadata = buffer.push(_drawId);

        emit PrizeDistributionSet(_drawId, _prizeDistribution);

        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "./interfaces/IPrizeDistributor.sol";
import "./interfaces/IDrawCalculator.sol";

/**
    * @title  PoolTogether V4 PrizeDistributor
    * @author PoolTogether Inc Team
    * @notice The PrizeDistributor contract holds Tickets (captured interest) and distributes tickets to users with winning draw claims.
              PrizeDistributor uses an external IDrawCalculator to validate a users draw claim, before awarding payouts. To prevent users 
              from reclaiming prizes, a payout history for each draw claim is mapped to user accounts. Reclaiming a draw can occur
              if an "optimal" prize was not included in previous claim pick indices and the new claims updated payout is greater then
              the previous prize distributor claim payout.
*/
contract PrizeDistributor is IPrizeDistributor, Ownable {
    using SafeERC20 for IERC20;

    /* ============ Global Variables ============ */

    /// @notice DrawCalculator address
    IDrawCalculator internal drawCalculator;

    /// @notice Token address
    IERC20 internal immutable token;

    /// @notice Maps users => drawId => paid out balance
    mapping(address => mapping(uint256 => uint256)) internal userDrawPayouts;

    /* ============ Initialize ============ */

    /**
     * @notice Initialize PrizeDistributor smart contract.
     * @param _owner          Owner address
     * @param _token          Token address
     * @param _drawCalculator DrawCalculator address
     */
    constructor(
        address _owner,
        IERC20 _token,
        IDrawCalculator _drawCalculator
    ) Ownable(_owner) {
        _setDrawCalculator(_drawCalculator);
        require(address(_token) != address(0), "PrizeDistributor/token-not-zero-address");
        token = _token;
        emit TokenSet(_token);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeDistributor
    function claim(
        address _user,
        uint32[] calldata _drawIds,
        bytes calldata _data
    ) external override returns (uint256) {
        
        uint256 totalPayout;
        
        (uint256[] memory drawPayouts, ) = drawCalculator.calculate(_user, _drawIds, _data); // neglect the prizeCounts since we are not interested in them here

        uint256 drawPayoutsLength = drawPayouts.length;
        for (uint256 payoutIndex = 0; payoutIndex < drawPayoutsLength; payoutIndex++) {
            uint32 drawId = _drawIds[payoutIndex];
            uint256 payout = drawPayouts[payoutIndex];
            uint256 oldPayout = _getDrawPayoutBalanceOf(_user, drawId);
            uint256 payoutDiff = 0;

            // helpfully short-circuit, in case the user screwed something up.
            require(payout > oldPayout, "PrizeDistributor/zero-payout");

            unchecked {
                payoutDiff = payout - oldPayout;
            }

            _setDrawPayoutBalanceOf(_user, drawId, payout);

            totalPayout += payoutDiff;

            emit ClaimedDraw(_user, drawId, payoutDiff);
        }

        _awardPayout(_user, totalPayout);

        return totalPayout;
    }

    /// @inheritdoc IPrizeDistributor
    function withdrawERC20(
        IERC20 _erc20Token,
        address _to,
        uint256 _amount
    ) external override onlyOwner returns (bool) {
        require(_to != address(0), "PrizeDistributor/recipient-not-zero-address");
        require(address(_erc20Token) != address(0), "PrizeDistributor/ERC20-not-zero-address");

        _erc20Token.safeTransfer(_to, _amount);

        emit ERC20Withdrawn(_erc20Token, _to, _amount);

        return true;
    }

    /// @inheritdoc IPrizeDistributor
    function getDrawCalculator() external view override returns (IDrawCalculator) {
        return drawCalculator;
    }

    /// @inheritdoc IPrizeDistributor
    function getDrawPayoutBalanceOf(address _user, uint32 _drawId)
        external
        view
        override
        returns (uint256)
    {
        return _getDrawPayoutBalanceOf(_user, _drawId);
    }

    /// @inheritdoc IPrizeDistributor
    function getToken() external view override returns (IERC20) {
        return token;
    }

    /// @inheritdoc IPrizeDistributor
    function setDrawCalculator(IDrawCalculator _newCalculator)
        external
        override
        onlyOwner
        returns (IDrawCalculator)
    {
        _setDrawCalculator(_newCalculator);
        return _newCalculator;
    }

    /* ============ Internal Functions ============ */

    function _getDrawPayoutBalanceOf(address _user, uint32 _drawId)
        internal
        view
        returns (uint256)
    {
        return userDrawPayouts[_user][_drawId];
    }

    function _setDrawPayoutBalanceOf(
        address _user,
        uint32 _drawId,
        uint256 _payout
    ) internal {
        userDrawPayouts[_user][_drawId] = _payout;
    }

    /**
     * @notice Sets DrawCalculator reference for individual draw id.
     * @param _newCalculator  DrawCalculator address
     */
    function _setDrawCalculator(IDrawCalculator _newCalculator) internal {
        require(address(_newCalculator) != address(0), "PrizeDistributor/calc-not-zero");
        drawCalculator = _newCalculator;

        emit DrawCalculatorSet(_newCalculator);
    }

    /**
     * @notice Transfer claimed draw(s) total payout to user.
     * @param _to      User address
     * @param _amount  Transfer amount
     */
    function _awardPayout(address _to, uint256 _amount) internal {
        token.safeTransfer(_to, _amount);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./ExtendedSafeCastLib.sol";
import "./OverflowSafeComparatorLib.sol";
import "./RingBufferLib.sol";
import "./ObservationLib.sol";

/**
  * @title  PoolTogether V4 TwabLib (Library)
  * @author PoolTogether Inc Team
  * @dev    Time-Weighted Average Balance Library for ERC20 tokens.
  * @notice This TwabLib adds on-chain historical lookups to a user(s) time-weighted average balance.
            Each user is mapped to an Account struct containing the TWAB history (ring buffer) and
            ring buffer parameters. Every token.transfer() creates a new TWAB checkpoint. The new TWAB
            checkpoint is stored in the circular ring buffer, as either a new checkpoint or rewriting
            a previous checkpoint with new parameters. The TwabLib (using existing blocktimes of 1block/15sec)
            guarantees minimum 7.4 years of search history.
 */
library TwabLib {
    using OverflowSafeComparatorLib for uint32;
    using ExtendedSafeCastLib for uint256;

    /**
      * @notice Sets max ring buffer length in the Account.twabs Observation list.
                As users transfer/mint/burn tickets new Observation checkpoints are
                recorded. The current max cardinality guarantees a seven year minimum,
                of accurate historical lookups with current estimates of 1 new block
                every 15 seconds - assuming each block contains a transfer to trigger an
                observation write to storage.
      * @dev    The user Account.AccountDetails.cardinality parameter can NOT exceed
                the max cardinality variable. Preventing "corrupted" ring buffer lookup
                pointers and new observation checkpoints.

                The MAX_CARDINALITY in fact guarantees at least 7.4 years of records:
                If 14 = block time in seconds
                (2**24) * 14 = 234881024 seconds of history
                234881024 / (365 * 24 * 60 * 60) ~= 7.44 years
    */
    uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

    /** @notice Struct ring buffer parameters for single user Account
      * @param balance       Current balance for an Account
      * @param nextTwabIndex Next uninitialized or updatable ring buffer checkpoint storage slot
      * @param cardinality   Current total "initialized" ring buffer checkpoints for single user AccountDetails.
                             Used to set initial boundary conditions for an efficient binary search.
    */
    struct AccountDetails {
        uint208 balance;
        uint24 nextTwabIndex;
        uint24 cardinality;
    }

    /// @notice Combines account details with their twab history
    /// @param details The account details
    /// @param twabs The history of twabs for this account
    struct Account {
        AccountDetails details;
        ObservationLib.Observation[MAX_CARDINALITY] twabs;
    }

    /// @notice Increases an account's balance and records a new twab.
    /// @param _account The account whose balance will be increased
    /// @param _amount The amount to increase the balance by
    /// @param _currentTime The current time
    /// @return accountDetails The new AccountDetails
    /// @return twab The user's latest TWAB
    /// @return isNew Whether the TWAB is new
    function increaseBalance(
        Account storage _account,
        uint208 _amount,
        uint32 _currentTime
    )
        internal
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        AccountDetails memory _accountDetails = _account.details;
        (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
        accountDetails.balance = _accountDetails.balance + _amount;
    }

    /** @notice Calculates the next TWAB checkpoint for an account with a decreasing balance.
     * @dev    With Account struct and amount decreasing calculates the next TWAB observable checkpoint.
     * @param _account        Account whose balance will be decreased
     * @param _amount         Amount to decrease the balance by
     * @param _revertMessage  Revert message for insufficient balance
     * @return accountDetails Updated Account.details struct
     * @return twab           TWAB observation (with decreasing average)
     * @return isNew          Whether TWAB is new or calling twice in the same block
     */
    function decreaseBalance(
        Account storage _account,
        uint208 _amount,
        string memory _revertMessage,
        uint32 _currentTime
    )
        internal
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        AccountDetails memory _accountDetails = _account.details;

        require(_accountDetails.balance >= _amount, _revertMessage);

        (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
        unchecked {
            accountDetails.balance -= _amount;
        }
    }

    /** @notice Calculates the average balance held by a user for a given time frame.
      * @dev    Finds the average balance between start and end timestamp epochs.
                Validates the supplied end time is within the range of elapsed time i.e. less then timestamp of now.
      * @param _twabs          Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails User AccountDetails struct loaded in memory
      * @param _startTime      Start of timestamp range as an epoch
      * @param _endTime        End of timestamp range as an epoch
      * @param _currentTime    Block.timestamp
      * @return Average balance of user held between epoch timestamps start and end
    */
    function getAverageBalanceBetween(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _currentTime
    ) internal view returns (uint256) {
        uint32 endTime = _endTime > _currentTime ? _currentTime : _endTime;

        return
            _getAverageBalanceBetween(_twabs, _accountDetails, _startTime, endTime, _currentTime);
    }

    /// @notice Retrieves the oldest TWAB
    /// @param _twabs The storage array of twabs
    /// @param _accountDetails The TWAB account details
    /// @return index The index of the oldest TWAB in the twabs array
    /// @return twab The oldest TWAB
    function oldestTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails
    ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
        index = _accountDetails.nextTwabIndex;
        twab = _twabs[index];

        // If the TWAB is not initialized we go to the beginning of the TWAB circular buffer at index 0
        if (twab.timestamp == 0) {
            index = 0;
            twab = _twabs[0];
        }
    }

    /// @notice Retrieves the newest TWAB
    /// @param _twabs The storage array of twabs
    /// @param _accountDetails The TWAB account details
    /// @return index The index of the newest TWAB in the twabs array
    /// @return twab The newest TWAB
    function newestTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails
    ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
        index = uint24(RingBufferLib.newestIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY));
        twab = _twabs[index];
    }

    /// @notice Retrieves amount at `_targetTime` timestamp
    /// @param _twabs List of TWABs to search through.
    /// @param _accountDetails Accounts details
    /// @param _targetTime Timestamp at which the reserved TWAB should be for.
    /// @return uint256 TWAB amount at `_targetTime`.
    function getBalanceAt(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _targetTime,
        uint32 _currentTime
    ) internal view returns (uint256) {
        uint32 timeToTarget = _targetTime > _currentTime ? _currentTime : _targetTime;
        return _getBalanceAt(_twabs, _accountDetails, timeToTarget, _currentTime);
    }

    /// @notice Calculates the average balance held by a user for a given time frame.
    /// @param _startTime The start time of the time frame.
    /// @param _endTime The end time of the time frame.
    /// @return The average balance that the user held during the time frame.
    function _getAverageBalanceBetween(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _currentTime
    ) private view returns (uint256) {
        (uint24 oldestTwabIndex, ObservationLib.Observation memory oldTwab) = oldestTwab(
            _twabs,
            _accountDetails
        );

        (uint24 newestTwabIndex, ObservationLib.Observation memory newTwab) = newestTwab(
            _twabs,
            _accountDetails
        );

        ObservationLib.Observation memory startTwab = _calculateTwab(
            _twabs,
            _accountDetails,
            newTwab,
            oldTwab,
            newestTwabIndex,
            oldestTwabIndex,
            _startTime,
            _currentTime
        );

        ObservationLib.Observation memory endTwab = _calculateTwab(
            _twabs,
            _accountDetails,
            newTwab,
            oldTwab,
            newestTwabIndex,
            oldestTwabIndex,
            _endTime,
            _currentTime
        );

        // Difference in amount / time
        return (endTwab.amount - startTwab.amount) / OverflowSafeComparatorLib.checkedSub(endTwab.timestamp, startTwab.timestamp, _currentTime);
    }

    /** @notice Searches TWAB history and calculate the difference between amount(s)/timestamp(s) to return average balance
                between the Observations closes to the supplied targetTime.
      * @param _twabs          Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails User AccountDetails struct loaded in memory
      * @param _targetTime     Target timestamp to filter Observations in the ring buffer binary search
      * @param _currentTime    Block.timestamp
      * @return uint256 Time-weighted average amount between two closest observations.
    */
    function _getBalanceAt(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _targetTime,
        uint32 _currentTime
    ) private view returns (uint256) {
        uint24 newestTwabIndex;
        ObservationLib.Observation memory afterOrAt;
        ObservationLib.Observation memory beforeOrAt;
        (newestTwabIndex, beforeOrAt) = newestTwab(_twabs, _accountDetails);

        // If `_targetTime` is chronologically after the newest TWAB, we can simply return the current balance
        if (beforeOrAt.timestamp.lte(_targetTime, _currentTime)) {
            return _accountDetails.balance;
        }

        uint24 oldestTwabIndex;
        // Now, set before to the oldest TWAB
        (oldestTwabIndex, beforeOrAt) = oldestTwab(_twabs, _accountDetails);

        // If `_targetTime` is chronologically before the oldest TWAB, we can early return
        if (_targetTime.lt(beforeOrAt.timestamp, _currentTime)) {
            return 0;
        }

        // Otherwise, we perform the `binarySearch`
        (beforeOrAt, afterOrAt) = ObservationLib.binarySearch(
            _twabs,
            newestTwabIndex,
            oldestTwabIndex,
            _targetTime,
            _accountDetails.cardinality,
            _currentTime
        );

        // Sum the difference in amounts and divide by the difference in timestamps.
        // The time-weighted average balance uses time measured between two epoch timestamps as
        // a constaint on the measurement when calculating the time weighted average balance.
        return
            (afterOrAt.amount - beforeOrAt.amount) / OverflowSafeComparatorLib.checkedSub(afterOrAt.timestamp, beforeOrAt.timestamp, _currentTime);
    }

    /** @notice Calculates a user TWAB for a target timestamp using the historical TWAB records.
                The balance is linearly interpolated: amount differences / timestamp differences
                using the simple (after.amount - before.amount / end.timestamp - start.timestamp) formula.
    /** @dev    Binary search in _calculateTwab fails when searching out of bounds. Thus, before
                searching we exclude target timestamps out of range of newest/oldest TWAB(s).
                IF a search is before or after the range we "extrapolate" a Observation from the expected state.
      * @param _twabs           Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails  User AccountDetails struct loaded in memory
      * @param _newestTwab      Newest TWAB in history (end of ring buffer)
      * @param _oldestTwab      Olderst TWAB in history (end of ring buffer)
      * @param _newestTwabIndex Pointer in ring buffer to newest TWAB
      * @param _oldestTwabIndex Pointer in ring buffer to oldest TWAB
      * @param _targetTimestamp Epoch timestamp to calculate for time (T) in the TWAB
      * @param _time            Block.timestamp
      * @return accountDetails Updated Account.details struct
    */
    function _calculateTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        ObservationLib.Observation memory _newestTwab,
        ObservationLib.Observation memory _oldestTwab,
        uint24 _newestTwabIndex,
        uint24 _oldestTwabIndex,
        uint32 _targetTimestamp,
        uint32 _time
    ) private view returns (ObservationLib.Observation memory) {
        // If `_targetTimestamp` is chronologically after the newest TWAB, we extrapolate a new one
        if (_newestTwab.timestamp.lt(_targetTimestamp, _time)) {
            return _computeNextTwab(_newestTwab, _accountDetails.balance, _targetTimestamp);
        }

        if (_newestTwab.timestamp == _targetTimestamp) {
            return _newestTwab;
        }

        if (_oldestTwab.timestamp == _targetTimestamp) {
            return _oldestTwab;
        }

        // If `_targetTimestamp` is chronologically before the oldest TWAB, we create a zero twab
        if (_targetTimestamp.lt(_oldestTwab.timestamp, _time)) {
            return ObservationLib.Observation({ amount: 0, timestamp: _targetTimestamp });
        }

        // Otherwise, both timestamps must be surrounded by twabs.
        (
            ObservationLib.Observation memory beforeOrAtStart,
            ObservationLib.Observation memory afterOrAtStart
        ) = ObservationLib.binarySearch(
                _twabs,
                _newestTwabIndex,
                _oldestTwabIndex,
                _targetTimestamp,
                _accountDetails.cardinality,
                _time
            );

        uint224 heldBalance = (afterOrAtStart.amount - beforeOrAtStart.amount) /
            OverflowSafeComparatorLib.checkedSub(afterOrAtStart.timestamp, beforeOrAtStart.timestamp, _time);

        return _computeNextTwab(beforeOrAtStart, heldBalance, _targetTimestamp);
    }

    /**
     * @notice Calculates the next TWAB using the newestTwab and updated balance.
     * @dev    Storage of the TWAB obersation is managed by the calling function and not _computeNextTwab.
     * @param _currentTwab    Newest Observation in the Account.twabs list
     * @param _currentBalance User balance at time of most recent (newest) checkpoint write
     * @param _time           Current block.timestamp
     * @return TWAB Observation
     */
    function _computeNextTwab(
        ObservationLib.Observation memory _currentTwab,
        uint224 _currentBalance,
        uint32 _time
    ) private pure returns (ObservationLib.Observation memory) {
        // New twab amount = last twab amount (or zero) + (current amount * elapsed seconds)
        return
            ObservationLib.Observation({
                amount: _currentTwab.amount +
                    _currentBalance *
                    (_time.checkedSub(_currentTwab.timestamp, _time)),
                timestamp: _time
            });
    }

    /// @notice Sets a new TWAB Observation at the next available index and returns the new account details.
    /// @dev Note that if _currentTime is before the last observation timestamp, it appears as an overflow
    /// @param _twabs The twabs array to insert into
    /// @param _accountDetails The current account details
    /// @param _currentTime The current time
    /// @return accountDetails The new account details
    /// @return twab The newest twab (may or may not be brand-new)
    /// @return isNew Whether the newest twab was created by this call
    function _nextTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _currentTime
    )
        private
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        (, ObservationLib.Observation memory _newestTwab) = newestTwab(_twabs, _accountDetails);

        // if we're in the same block, return
        if (_newestTwab.timestamp == _currentTime) {
            return (_accountDetails, _newestTwab, false);
        }

        ObservationLib.Observation memory newTwab = _computeNextTwab(
            _newestTwab,
            _accountDetails.balance,
            _currentTime
        );

        _twabs[_accountDetails.nextTwabIndex] = newTwab;

        AccountDetails memory nextAccountDetails = push(_accountDetails);

        return (nextAccountDetails, newTwab, true);
    }

    /// @notice "Pushes" a new element on the AccountDetails ring buffer, and returns the new AccountDetails
    /// @param _accountDetails The account details from which to pull the cardinality and next index
    /// @return The new AccountDetails
    function push(AccountDetails memory _accountDetails)
        internal
        pure
        returns (AccountDetails memory)
    {
        _accountDetails.nextTwabIndex = uint24(
            RingBufferLib.nextIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY)
        );

        // Prevent the Account specific cardinality from exceeding the MAX_CARDINALITY.
        // The ring buffer length is limited by MAX_CARDINALITY. IF the account.cardinality
        // exceeds the max cardinality, new observations would be incorrectly set or the
        // observation would be out of "bounds" of the ring buffer. Once reached the
        // AccountDetails.cardinality will continue to be equal to max cardinality.
        if (_accountDetails.cardinality < MAX_CARDINALITY) {
            _accountDetails.cardinality += 1;
        }

        return _accountDetails;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title IControlledToken
  * @author PoolTogether Inc Team
  * @notice ERC20 Tokens with a controller for minting & burning.
*/
interface IControlledToken is IERC20 {

    /** 
        @notice Interface to the contract responsible for controlling mint/burn
    */
    function controller() external view returns (address);

    /** 
      * @notice Allows the controller to mint tokens for a user account
      * @dev May be overridden to provide more granular control over minting
      * @param user Address of the receiver of the minted tokens
      * @param amount Amount of tokens to mint
    */
    function controllerMint(address user, uint256 amount) external;

    /** 
      * @notice Allows the controller to burn tokens from a user account
      * @dev May be overridden to provide more granular control over burning
      * @param user Address of the holder account to burn tokens from
      * @param amount Amount of tokens to burn
    */
    function controllerBurn(address user, uint256 amount) external;

    /** 
      * @notice Allows an operator via the controller to burn tokens on behalf of a user account
      * @dev May be overridden to provide more granular control over operator-burning
      * @param operator Address of the operator performing the burn action via the controller contract
      * @param user Address of the holder account to burn tokens from
      * @param amount Amount of tokens to burn
    */
    function controllerBurnFrom(
        address operator,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library ExtendedSafeCastLib {

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 _value) internal pure returns (uint104) {
        require(_value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(_value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 _value) internal pure returns (uint208) {
        require(_value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(_value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 _value) internal pure returns (uint224) {
        require(_value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(_value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/// @title OverflowSafeComparatorLib library to share comparator functions between contracts
/// @dev Code taken from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/3e88af408132fc957e3e406f65a0ce2b1ca06c3d/contracts/libraries/Oracle.sol
/// @author PoolTogether Inc.
library OverflowSafeComparatorLib {
    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically < `_b`.
    function lt(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {
        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a < _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted < bAdjusted;
    }

    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically <= `_b`.
    function lte(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {

        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a <= _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    /// @notice 32-bit timestamp subtractor
    /// @dev safe for 0 or 1 overflows, where `_a` and `_b` must be chronologically before or equal to time
    /// @param _a The subtraction left operand
    /// @param _b The subtraction right operand
    /// @param _timestamp The current time.  Expected to be chronologically after both.
    /// @return The difference between a and b, adjusted for overflow
    function checkedSub(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (uint32) {
        // No need to adjust if there hasn't been an overflow

        if (_a <= _timestamp && _b <= _timestamp) return _a - _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return uint32(aAdjusted - bAdjusted);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

library RingBufferLib {
    /**
    * @notice Returns wrapped TWAB index.
    * @dev  In order to navigate the TWAB circular buffer, we need to use the modulo operator.
    * @dev  For example, if `_index` is equal to 32 and the TWAB circular buffer is of `_cardinality` 32,
    *       it will return 0 and will point to the first element of the array.
    * @param _index Index used to navigate through the TWAB circular buffer.
    * @param _cardinality TWAB buffer cardinality.
    * @return TWAB index.
    */
    function wrap(uint256 _index, uint256 _cardinality) internal pure returns (uint256) {
        return _index % _cardinality;
    }

    /**
    * @notice Computes the negative offset from the given index, wrapped by the cardinality.
    * @dev  We add `_cardinality` to `_index` to be able to offset even if `_amount` is superior to `_cardinality`.
    * @param _index The index from which to offset
    * @param _amount The number of indices to offset.  This is subtracted from the given index.
    * @param _cardinality The number of elements in the ring buffer
    * @return Offsetted index.
     */
    function offset(
        uint256 _index,
        uint256 _amount,
        uint256 _cardinality
    ) internal pure returns (uint256) {
        return wrap(_index + _cardinality - _amount, _cardinality);
    }

    /// @notice Returns the index of the last recorded TWAB
    /// @param _nextIndex The next available twab index.  This will be recorded to next.
    /// @param _cardinality The cardinality of the TWAB history.
    /// @return The index of the last recorded TWAB
    function newestIndex(uint256 _nextIndex, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        if (_cardinality == 0) {
            return 0;
        }

        return wrap(_nextIndex + _cardinality - 1, _cardinality);
    }

    /// @notice Computes the ring buffer index that follows the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The next index relative to the given index.  Will wrap around to 0 if the next index == cardinality
    function nextIndex(uint256 _index, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        return wrap(_index + 1, _cardinality);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./OverflowSafeComparatorLib.sol";
import "./RingBufferLib.sol";

/**
* @title Observation Library
* @notice This library allows one to store an array of timestamped values and efficiently binary search them.
* @dev Largely pulled from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/c05a0e2c8c08c460fb4d05cfdda30b3ad8deeaac/contracts/libraries/Oracle.sol
* @author PoolTogether Inc.
*/
library ObservationLib {
    using OverflowSafeComparatorLib for uint32;
    using SafeCast for uint256;

    /// @notice The maximum number of observations
    uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

    /**
    * @notice Observation, which includes an amount and timestamp.
    * @param amount `amount` at `timestamp`.
    * @param timestamp Recorded `timestamp`.
    */
    struct Observation {
        uint224 amount;
        uint32 timestamp;
    }

    /**
    * @notice Fetches Observations `beforeOrAt` and `atOrAfter` a `_target`, eg: where [`beforeOrAt`, `atOrAfter`] is satisfied.
    * The result may be the same Observation, or adjacent Observations.
    * @dev The answer must be contained in the array used when the target is located within the stored Observation.
    * boundaries: older than the most recent Observation and younger, or the same age as, the oldest Observation.
    * @dev  If `_newestObservationIndex` is less than `_oldestObservationIndex`, it means that we've wrapped around the circular buffer.
    *       So the most recent observation will be at `_oldestObservationIndex + _cardinality - 1`, at the beginning of the circular buffer.
    * @param _observations List of Observations to search through.
    * @param _newestObservationIndex Index of the newest Observation. Right side of the circular buffer.
    * @param _oldestObservationIndex Index of the oldest Observation. Left side of the circular buffer.
    * @param _target Timestamp at which we are searching the Observation.
    * @param _cardinality Cardinality of the circular buffer we are searching through.
    * @param _time Timestamp at which we perform the binary search.
    * @return beforeOrAt Observation recorded before, or at, the target.
    * @return atOrAfter Observation recorded at, or after, the target.
    */
    function binarySearch(
        Observation[MAX_CARDINALITY] storage _observations,
        uint24 _newestObservationIndex,
        uint24 _oldestObservationIndex,
        uint32 _target,
        uint24 _cardinality,
        uint32 _time
    ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 leftSide = _oldestObservationIndex;
        uint256 rightSide = _newestObservationIndex < leftSide
            ? leftSide + _cardinality - 1
            : _newestObservationIndex;
        uint256 currentIndex;

        while (true) {
            // We start our search in the middle of the `leftSide` and `rightSide`.
            // After each iteration, we narrow down the search to the left or the right side while still starting our search in the middle.
            currentIndex = (leftSide + rightSide) / 2;

            beforeOrAt = _observations[uint24(RingBufferLib.wrap(currentIndex, _cardinality))];
            uint32 beforeOrAtTimestamp = beforeOrAt.timestamp;

            // We've landed on an uninitialized timestamp, keep searching higher (more recently).
            if (beforeOrAtTimestamp == 0) {
                leftSide = currentIndex + 1;
                continue;
            }

            atOrAfter = _observations[uint24(RingBufferLib.nextIndex(currentIndex, _cardinality))];

            bool targetAtOrAfter = beforeOrAtTimestamp.lte(_target, _time);

            // Check if we've found the corresponding Observation.
            if (targetAtOrAfter && _target.lte(atOrAfter.timestamp, _time)) {
                break;
            }

            // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower. To the left of the current index.
            if (!targetAtOrAfter) {
                rightSide = currentIndex - 1;
            } else {
                // Otherwise, we keep searching higher. To the left of the current index.
                leftSide = currentIndex + 1;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./RingBufferLib.sol";

/// @title Library for creating and managing a draw ring buffer.
library DrawRingBufferLib {
    /// @notice Draw buffer struct.
    struct Buffer {
        uint32 lastDrawId;
        uint32 nextIndex;
        uint32 cardinality;
    }

    /// @notice Helper function to know if the draw ring buffer has been initialized.
    /// @dev since draws start at 1 and are monotonically increased, we know we are uninitialized if nextIndex = 0 and lastDrawId = 0.
    /// @param _buffer The buffer to check.
    function isInitialized(Buffer memory _buffer) internal pure returns (bool) {
        return !(_buffer.nextIndex == 0 && _buffer.lastDrawId == 0);
    }

    /// @notice Push a draw to the buffer.
    /// @param _buffer The buffer to push to.
    /// @param _drawId The drawID to push.
    /// @return The new buffer.
    function push(Buffer memory _buffer, uint32 _drawId) internal pure returns (Buffer memory) {
        require(!isInitialized(_buffer) || _drawId == _buffer.lastDrawId + 1, "DRB/must-be-contig");

        return
            Buffer({
                lastDrawId: _drawId,
                nextIndex: uint32(RingBufferLib.nextIndex(_buffer.nextIndex, _buffer.cardinality)),
                cardinality: _buffer.cardinality
            });
    }

    /// @notice Get draw ring buffer index pointer.
    /// @param _buffer The buffer to get the `nextIndex` from.
    /// @param _drawId The draw id to get the index for.
    /// @return The draw ring buffer index pointer.
    function getIndex(Buffer memory _buffer, uint32 _drawId) internal pure returns (uint32) {
        require(isInitialized(_buffer) && _drawId <= _buffer.lastDrawId, "DRB/future-draw");

        uint32 indexOffset = _buffer.lastDrawId - _drawId;
        require(indexOffset < _buffer.cardinality, "DRB/expired-draw");

        uint256 mostRecent = RingBufferLib.newestIndex(_buffer.nextIndex, _buffer.cardinality);

        return uint32(RingBufferLib.offset(uint32(mostRecent), indexOffset, _buffer.cardinality));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./IPrizeDistributionSource.sol";

/** @title  IPrizeDistributionBuffer
 * @author PoolTogether Inc Team
 * @notice The PrizeDistributionBuffer interface.
 */
interface IPrizeDistributionBuffer is IPrizeDistributionSource {
    /**
     * @notice Emit when PrizeDistribution is set.
     * @param drawId       Draw id
     * @param prizeDistribution IPrizeDistributionBuffer.PrizeDistribution
     */
    event PrizeDistributionSet(
        uint32 indexed drawId,
        IPrizeDistributionBuffer.PrizeDistribution prizeDistribution
    );

    /**
     * @notice Read a ring buffer cardinality
     * @return Ring buffer cardinality
     */
    function getBufferCardinality() external view returns (uint32);

    /**
     * @notice Read newest PrizeDistribution from prize distributions ring buffer.
     * @dev    Uses nextDrawIndex to calculate the most recently added PrizeDistribution.
     * @return prizeDistribution
     * @return drawId
     */
    function getNewestPrizeDistribution()
        external
        view
        returns (
            IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution,
            uint32 drawId
        );

    /**
     * @notice Read oldest PrizeDistribution from prize distributions ring buffer.
     * @dev    Finds the oldest Draw by buffer.nextIndex and buffer.lastDrawId
     * @return prizeDistribution
     * @return drawId
     */
    function getOldestPrizeDistribution()
        external
        view
        returns (
            IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution,
            uint32 drawId
        );

    /**
     * @notice Gets the PrizeDistributionBuffer for a drawId
     * @param drawId drawId
     * @return prizeDistribution
     */
    function getPrizeDistribution(uint32 drawId)
        external
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory);

    /**
     * @notice Gets the number of PrizeDistributions stored in the prize distributions ring buffer.
     * @dev If no Draws have been pushed, it will return 0.
     * @dev If the ring buffer is full, it will return the cardinality.
     * @dev Otherwise, it will return the NewestPrizeDistribution index + 1.
     * @return Number of PrizeDistributions stored in the prize distributions ring buffer.
     */
    function getPrizeDistributionCount() external view returns (uint32);

    /**
     * @notice Adds new PrizeDistribution record to ring buffer storage.
     * @dev    Only callable by the owner or manager
     * @param drawId            Draw ID linked to PrizeDistribution parameters
     * @param prizeDistribution PrizeDistribution parameters struct
     */
    function pushPrizeDistribution(
        uint32 drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata prizeDistribution
    ) external returns (bool);

    /**
     * @notice Sets existing PrizeDistribution with new PrizeDistribution parameters in ring buffer storage.
     * @dev    Retroactively updates an existing PrizeDistribution and should be thought of as a "safety"
               fallback. If the manager is setting invalid PrizeDistribution parameters the Owner can update
               the invalid parameters with correct parameters.
     * @return drawId
     */
    function setPrizeDistribution(
        uint32 drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata draw
    ) external returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/** @title IPrizeDistributionSource
 * @author PoolTogether Inc Team
 * @notice The PrizeDistributionSource interface.
 */
interface IPrizeDistributionSource {
    ///@notice PrizeDistribution struct created every draw
    ///@param bitRangeSize Decimal representation of bitRangeSize
    ///@param matchCardinality The number of numbers to consider in the 256 bit random number. Must be > 1 and < 256/bitRangeSize.
    ///@param startTimestampOffset The starting time offset in seconds from which Ticket balances are calculated.
    ///@param endTimestampOffset The end time offset in seconds from which Ticket balances are calculated.
    ///@param maxPicksPerUser Maximum number of picks a user can make in this draw
    ///@param expiryDuration Length of time in seconds the PrizeDistribution is valid for. Relative to the Draw.timestamp.
    ///@param numberOfPicks Number of picks this draw has (may vary across networks according to how much the network has contributed to the Reserve)
    ///@param tiers Array of prize tiers percentages, expressed in fraction form with base 1e9. Ordering: index0: grandPrize, index1: runnerUp, etc.
    ///@param prize Total prize amount available in this draw calculator for this draw (may vary from across networks)
    struct PrizeDistribution {
        uint8 bitRangeSize;
        uint8 matchCardinality;
        uint32 startTimestampOffset;
        uint32 endTimestampOffset;
        uint32 maxPicksPerUser;
        uint32 expiryDuration;
        uint104 numberOfPicks;
        uint32[16] tiers;
        uint256 prize;
    }

    /**
     * @notice Gets PrizeDistribution list from array of drawIds
     * @param drawIds drawIds to get PrizeDistribution for
     * @return prizeDistributionList
     */
    function getPrizeDistributions(uint32[] calldata drawIds)
        external
        view
        returns (PrizeDistribution[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IDrawBuffer.sol";
import "./IDrawCalculator.sol";

/** @title  IPrizeDistributor
  * @author PoolTogether Inc Team
  * @notice The PrizeDistributor interface.
*/
interface IPrizeDistributor {

    /**
     * @notice Emit when user has claimed token from the PrizeDistributor.
     * @param user   User address receiving draw claim payouts
     * @param drawId Draw id that was paid out
     * @param payout Payout for draw
     */
    event ClaimedDraw(address indexed user, uint32 indexed drawId, uint256 payout);

    /**
     * @notice Emit when DrawCalculator is set.
     * @param calculator DrawCalculator address
     */
    event DrawCalculatorSet(IDrawCalculator indexed calculator);

    /**
     * @notice Emit when Token is set.
     * @param token Token address
     */
    event TokenSet(IERC20 indexed token);

    /**
     * @notice Emit when ERC20 tokens are withdrawn.
     * @param token  ERC20 token transferred.
     * @param to     Address that received funds.
     * @param amount Amount of tokens transferred.
     */
    event ERC20Withdrawn(IERC20 indexed token, address indexed to, uint256 amount);

    /**
     * @notice Claim prize payout(s) by submitting valid drawId(s) and winning pick indice(s). The user address
               is used as the "seed" phrase to generate random numbers.
     * @dev    The claim function is public and any wallet may execute claim on behalf of another user.
               Prizes are always paid out to the designated user account and not the caller (msg.sender).
               Claiming prizes is not limited to a single transaction. Reclaiming can be executed
               subsequentially if an "optimal" prize was not included in previous claim pick indices. The
               payout difference for the new claim is calculated during the award process and transfered to user.
     * @param user    Address of user to claim awards for. Does NOT need to be msg.sender
     * @param drawIds Draw IDs from global DrawBuffer reference
     * @param data    The data to pass to the draw calculator
     * @return Total claim payout. May include calcuations from multiple draws.
     */
    function claim(
        address user,
        uint32[] calldata drawIds,
        bytes calldata data
    ) external returns (uint256);

    /**
        * @notice Read global DrawCalculator address.
        * @return IDrawCalculator
     */
    function getDrawCalculator() external view returns (IDrawCalculator);

    /**
        * @notice Get the amount that a user has already been paid out for a draw
        * @param user   User address
        * @param drawId Draw ID
     */
    function getDrawPayoutBalanceOf(address user, uint32 drawId) external view returns (uint256);

    /**
        * @notice Read global Ticket address.
        * @return IERC20
     */
    function getToken() external view returns (IERC20);

    /**
        * @notice Sets DrawCalculator reference contract.
        * @param newCalculator DrawCalculator address
        * @return New DrawCalculator address
     */
    function setDrawCalculator(IDrawCalculator newCalculator) external returns (IDrawCalculator);

    /**
        * @notice Transfer ERC20 tokens out of contract to recipient address.
        * @dev    Only callable by contract owner.
        * @param token  ERC20 token to transfer.
        * @param to     Recipient of the tokens.
        * @param amount Amount of tokens to transfer.
        * @return true if operation is successful.
    */
    function withdrawERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "./interfaces/IReceiverTimelockTrigger.sol";
import "./interfaces/IPrizeDistributionFactory.sol";
import "./interfaces/IDrawCalculatorTimelock.sol";

/**

  * @title  PoolTogether V4 ReceiverTimelockTrigger
  * @author PoolTogether Inc Team
  * @notice The ReceiverTimelockTrigger smart contract is an upgrade of the L2TimelockTimelock smart contract.
            Reducing protocol risk by eliminating off-chain computation of PrizeDistribution parameters. The timelock will
            only pass the total supply of all tickets in a "PrizePool Network" to the prize distribution factory contract.
*/
contract ReceiverTimelockTrigger is IReceiverTimelockTrigger, Manageable {
    /* ============ Global Variables ============ */

    /// @notice The DrawBuffer contract address.
    IDrawBuffer public immutable drawBuffer;

    /// @notice Internal PrizeDistributionFactory reference.
    IPrizeDistributionFactory public immutable prizeDistributionFactory;

    /// @notice Timelock struct reference.
    IDrawCalculatorTimelock public immutable timelock;

    /* ============ Constructor ============ */

    /**
     * @notice Initialize ReceiverTimelockTrigger smart contract.
     * @param _owner The smart contract owner
     * @param _drawBuffer DrawBuffer address
     * @param _prizeDistributionFactory PrizeDistributionFactory address
     * @param _timelock DrawCalculatorTimelock address
     */
    constructor(
        address _owner,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionFactory _prizeDistributionFactory,
        IDrawCalculatorTimelock _timelock
    ) Ownable(_owner) {
        drawBuffer = _drawBuffer;
        prizeDistributionFactory = _prizeDistributionFactory;
        timelock = _timelock;
        emit Deployed(_drawBuffer, _prizeDistributionFactory, _timelock);
    }

    /// @inheritdoc IReceiverTimelockTrigger
    function push(IDrawBeacon.Draw memory _draw, uint256 _totalNetworkTicketSupply)
        external
        override
        onlyManagerOrOwner
    {
        timelock.lock(_draw.drawId, _draw.timestamp + _draw.beaconPeriodSeconds);
        drawBuffer.pushDraw(_draw);
        prizeDistributionFactory.pushPrizeDistribution(_draw.drawId, _totalNetworkTicketSupply);
        emit DrawLockedPushedAndTotalNetworkTicketSupplyPushed(
            _draw.drawId,
            _draw,
            _totalNetworkTicketSupply
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "./IPrizeDistributionFactory.sol";
import "./IDrawCalculatorTimelock.sol";

/**
 * @title  PoolTogether V4 IBeaconTimelockTrigger
 * @author PoolTogether Inc Team
 * @notice The IBeaconTimelockTrigger smart contract interface...
 */
interface IBeaconTimelockTrigger {
    /// @notice Emitted when the contract is deployed.
    event Deployed(
        IPrizeDistributionFactory indexed prizeDistributionFactory,
        IDrawCalculatorTimelock indexed timelock
    );

    /**
     * @notice Emitted when Draw is locked and totalNetworkTicketSupply is pushed to PrizeDistributionFactory
     * @param drawId Draw ID
     * @param draw Draw
     * @param totalNetworkTicketSupply totalNetworkTicketSupply
     */
    event DrawLockedAndTotalNetworkTicketSupplyPushed(
        uint32 indexed drawId,
        IDrawBeacon.Draw draw,
        uint256 totalNetworkTicketSupply
    );

    /**
     * @notice Locks next Draw and pushes totalNetworkTicketSupply to PrizeDistributionFactory
     * @dev    Restricts new draws for N seconds by forcing timelock on the next target draw id.
     * @param draw Draw
     * @param totalNetworkTicketSupply totalNetworkTicketSupply
     */
    function push(IDrawBeacon.Draw memory draw, uint256 totalNetworkTicketSupply) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "./interfaces/IBeaconTimelockTrigger.sol";
import "./interfaces/IPrizeDistributionFactory.sol";
import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 BeaconTimelockTrigger
  * @author PoolTogether Inc Team
  * @notice The BeaconTimelockTrigger smart contract is an upgrade of the L1TimelockTimelock smart contract.
            Reducing protocol risk by eliminating off-chain computation of PrizeDistribution parameters. The timelock will
            only pass the total supply of all tickets in a "PrizePool Network" to the prize distribution factory contract.
*/
contract BeaconTimelockTrigger is IBeaconTimelockTrigger, Manageable {
    /* ============ Global Variables ============ */

    /// @notice PrizeDistributionFactory reference.
    IPrizeDistributionFactory public immutable prizeDistributionFactory;

    /// @notice DrawCalculatorTimelock reference.
    IDrawCalculatorTimelock public immutable timelock;

    /* ============ Constructor ============ */

    /**
     * @notice Initialize BeaconTimelockTrigger smart contract.
     * @param _owner The smart contract owner
     * @param _prizeDistributionFactory PrizeDistributionFactory address
     * @param _timelock DrawCalculatorTimelock address
     */
    constructor(
        address _owner,
        IPrizeDistributionFactory _prizeDistributionFactory,
        IDrawCalculatorTimelock _timelock
    ) Ownable(_owner) {
        prizeDistributionFactory = _prizeDistributionFactory;
        timelock = _timelock;
        emit Deployed(_prizeDistributionFactory, _timelock);
    }

    /// @inheritdoc IBeaconTimelockTrigger
    function push(IDrawBeacon.Draw memory _draw, uint256 _totalNetworkTicketSupply)
        external
        override
        onlyManagerOrOwner
    {
        timelock.lock(_draw.drawId, _draw.timestamp + _draw.beaconPeriodSeconds);
        prizeDistributionFactory.pushPrizeDistribution(_draw.drawId, _totalNetworkTicketSupply);
        emit DrawLockedAndTotalNetworkTicketSupplyPushed(
            _draw.drawId,
            _draw,
            _totalNetworkTicketSupply
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 L2TimelockTrigger
  * @author PoolTogether Inc Team
  * @notice L2TimelockTrigger(s) acts as an intermediary between multiple V4 smart contracts.
            The L2TimelockTrigger is responsible for pushing Draws to a DrawBuffer and routing
            claim requests from a PrizeDistributor to a DrawCalculator. The primary objective is
            to  include a "cooldown" period for all new Draws. Allowing the correction of a
            malicously set Draw in the unfortunate event an Owner is compromised.
*/
contract L2TimelockTrigger is Manageable {
    /// @notice Emitted when the contract is deployed.
    event Deployed(
        IDrawBuffer indexed drawBuffer,
        IPrizeDistributionBuffer indexed prizeDistributionBuffer,
        IDrawCalculatorTimelock indexed timelock
    );

    /**
     * @notice Emitted when Draw and PrizeDistribution are pushed to external contracts.
     * @param drawId            Draw ID
     * @param prizeDistribution PrizeDistribution
     */
    event DrawAndPrizeDistributionPushed(
        uint32 indexed drawId,
        IDrawBeacon.Draw draw,
        IPrizeDistributionBuffer.PrizeDistribution prizeDistribution
    );

    /* ============ Global Variables ============ */

    /// @notice The DrawBuffer contract address.
    IDrawBuffer public immutable drawBuffer;

    /// @notice Internal PrizeDistributionBuffer reference.
    IPrizeDistributionBuffer public immutable prizeDistributionBuffer;

    /// @notice Timelock struct reference.
    IDrawCalculatorTimelock public timelock;

    /* ============ Deploy ============ */

    /**
     * @notice Initialize L2TimelockTrigger smart contract.
     * @param _owner                   Address of the L2TimelockTrigger owner.
     * @param _prizeDistributionBuffer PrizeDistributionBuffer address
     * @param _drawBuffer              DrawBuffer address
     * @param _timelock                Elapsed seconds before timelocked Draw is available
     */
    constructor(
        address _owner,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer,
        IDrawCalculatorTimelock _timelock
    ) Ownable(_owner) {
        drawBuffer = _drawBuffer;
        prizeDistributionBuffer = _prizeDistributionBuffer;
        timelock = _timelock;

        emit Deployed(_drawBuffer, _prizeDistributionBuffer, _timelock);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Restricts new draws by forcing a push timelock.
     * @param _draw              Draw struct from IDrawBeacon
     * @param _prizeDistribution PrizeDistribution struct from IPrizeDistributionBuffer
     */
    function push(
        IDrawBeacon.Draw memory _draw,
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution
    ) external onlyManagerOrOwner {
        timelock.lock(_draw.drawId, _draw.timestamp + _draw.beaconPeriodSeconds);
        drawBuffer.pushDraw(_draw);
        prizeDistributionBuffer.pushPrizeDistribution(_draw.drawId, _prizeDistribution);
        emit DrawAndPrizeDistributionPushed(_draw.drawId, _draw, _prizeDistribution);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/PrizeDistributor.sol';

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "../interfaces/IPrizeSplit.sol";

/**
 * @title PrizeSplit Interface
 * @author PoolTogether Inc Team
 */
abstract contract PrizeSplit is IPrizeSplit, Ownable {
    /* ============ Global Variables ============ */
    PrizeSplitConfig[] internal _prizeSplits;

    uint16 public constant ONE_AS_FIXED_POINT_3 = 1000;

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeSplit
    function getPrizeSplit(uint256 _prizeSplitIndex)
        external
        view
        override
        returns (PrizeSplitConfig memory)
    {
        return _prizeSplits[_prizeSplitIndex];
    }

    /// @inheritdoc IPrizeSplit
    function getPrizeSplits() external view override returns (PrizeSplitConfig[] memory) {
        return _prizeSplits;
    }

    /// @inheritdoc IPrizeSplit
    function setPrizeSplits(PrizeSplitConfig[] calldata _newPrizeSplits)
        external
        override
        onlyOwner
    {
        uint256 newPrizeSplitsLength = _newPrizeSplits.length;
        require(newPrizeSplitsLength <= type(uint8).max, "PrizeSplit/invalid-prizesplits-length");

        // Add and/or update prize split configs using _newPrizeSplits PrizeSplitConfig structs array.
        for (uint256 index = 0; index < newPrizeSplitsLength; index++) {
            PrizeSplitConfig memory split = _newPrizeSplits[index];

            // REVERT when setting the canonical burn address.
            require(split.target != address(0), "PrizeSplit/invalid-prizesplit-target");

            // IF the CURRENT prizeSplits length is below the NEW prizeSplits
            // PUSH the PrizeSplit struct to end of the list.
            if (_prizeSplits.length <= index) {
                _prizeSplits.push(split);
            } else {
                // ELSE update an existing PrizeSplit struct with new parameters
                PrizeSplitConfig memory currentSplit = _prizeSplits[index];

                // IF new PrizeSplit DOES NOT match the current PrizeSplit
                // WRITE to STORAGE with the new PrizeSplit
                if (
                    split.target != currentSplit.target ||
                    split.percentage != currentSplit.percentage
                ) {
                    _prizeSplits[index] = split;
                } else {
                    continue;
                }
            }

            // Emit the added/updated prize split config.
            emit PrizeSplitSet(split.target, split.percentage, index);
        }

        // Remove old prize splits configs. Match storage _prizesSplits.length with the passed newPrizeSplits.length
        while (_prizeSplits.length > newPrizeSplitsLength) {
            uint256 _index;
            unchecked {
                _index = _prizeSplits.length - 1;
            }
            _prizeSplits.pop();
            emit PrizeSplitRemoved(_index);
        }

        // Total prize split do not exceed 100%
        uint256 totalPercentage = _totalPrizeSplitPercentageAmount();
        require(totalPercentage <= ONE_AS_FIXED_POINT_3, "PrizeSplit/invalid-prizesplit-percentage-total");
    }

    /// @inheritdoc IPrizeSplit
    function setPrizeSplit(PrizeSplitConfig memory _prizeSplit, uint8 _prizeSplitIndex)
        external
        override
        onlyOwner
    {
        require(_prizeSplitIndex < _prizeSplits.length, "PrizeSplit/nonexistent-prizesplit");
        require(_prizeSplit.target != address(0), "PrizeSplit/invalid-prizesplit-target");

        // Update the prize split config
        _prizeSplits[_prizeSplitIndex] = _prizeSplit;

        // Total prize split do not exceed 100%
        uint256 totalPercentage = _totalPrizeSplitPercentageAmount();
        require(totalPercentage <= ONE_AS_FIXED_POINT_3, "PrizeSplit/invalid-prizesplit-percentage-total");

        // Emit updated prize split config
        emit PrizeSplitSet(
            _prizeSplit.target,
            _prizeSplit.percentage,
            _prizeSplitIndex
        );
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculates total prize split percentage amount.
     * @dev Calculates total PrizeSplitConfig percentage(s) amount. Used to check the total does not exceed 100% of award distribution.
     * @return Total prize split(s) percentage amount
     */
    function _totalPrizeSplitPercentageAmount() internal view returns (uint256) {
        uint256 _tempTotalPercentage;
        uint256 prizeSplitsLength = _prizeSplits.length;

        for (uint256 index = 0; index < prizeSplitsLength; index++) {
            _tempTotalPercentage += _prizeSplits[index].percentage;
        }

        return _tempTotalPercentage;
    }

    /**
     * @notice Distributes prize split(s).
     * @dev Distributes prize split(s) by awarding ticket or sponsorship tokens.
     * @param _prize Starting prize award amount
     * @return The remainder after splits are taken
     */
    function _distributePrizeSplits(uint256 _prize) internal returns (uint256) {
        uint256 _prizeTemp = _prize;
        uint256 prizeSplitsLength = _prizeSplits.length;

        for (uint256 index = 0; index < prizeSplitsLength; index++) {
            PrizeSplitConfig memory split = _prizeSplits[index];
            uint256 _splitAmount = (_prize * split.percentage) / 1000;

            // Award the prize split distribution amount.
            _awardPrizeSplitAmount(split.target, _splitAmount);

            // Update the remaining prize amount after distributing the prize split percentage.
            _prizeTemp -= _splitAmount;
        }

        return _prizeTemp;
    }

    /**
     * @notice Mints ticket or sponsorship tokens to prize split recipient.
     * @dev Mints ticket or sponsorship tokens to prize split recipient via the linked PrizePool contract.
     * @param _target Recipient of minted tokens
     * @param _amount Amount of minted tokens
     */
    function _awardPrizeSplitAmount(address _target, uint256 _amount) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./IControlledToken.sol";
import "./IPrizePool.sol";

/**
 * @title Abstract prize split contract for adding unique award distribution to static addresses.
 * @author PoolTogether Inc Team
 */
interface IPrizeSplit {
    /**
     * @notice Emit when an individual prize split is awarded.
     * @param user          User address being awarded
     * @param prizeAwarded  Awarded prize amount
     * @param token         Token address
     */
    event PrizeSplitAwarded(
        address indexed user,
        uint256 prizeAwarded,
        IControlledToken indexed token
    );

    /**
     * @notice The prize split configuration struct.
     * @dev    The prize split configuration struct used to award prize splits during distribution.
     * @param target     Address of recipient receiving the prize split distribution
     * @param percentage Percentage of prize split using a 0-1000 range for single decimal precision i.e. 125 = 12.5%
     */
    struct PrizeSplitConfig {
        address target;
        uint16 percentage;
    }

    /**
     * @notice Emitted when a PrizeSplitConfig config is added or updated.
     * @dev    Emitted when a PrizeSplitConfig config is added or updated in setPrizeSplits or setPrizeSplit.
     * @param target     Address of prize split recipient
     * @param percentage Percentage of prize split. Must be between 0 and 1000 for single decimal precision
     * @param index      Index of prize split in the prizeSplts array
     */
    event PrizeSplitSet(address indexed target, uint16 percentage, uint256 index);

    /**
     * @notice Emitted when a PrizeSplitConfig config is removed.
     * @dev    Emitted when a PrizeSplitConfig config is removed from the prizeSplits array.
     * @param target Index of a previously active prize split config
     */
    event PrizeSplitRemoved(uint256 indexed target);

    /**
     * @notice Read prize split config from active PrizeSplits.
     * @dev    Read PrizeSplitConfig struct from prizeSplits array.
     * @param prizeSplitIndex Index position of PrizeSplitConfig
     * @return PrizeSplitConfig Single prize split config
     */
    function getPrizeSplit(uint256 prizeSplitIndex) external view returns (PrizeSplitConfig memory);

    /**
     * @notice Read all prize splits configs.
     * @dev    Read all PrizeSplitConfig structs stored in prizeSplits.
     * @return Array of PrizeSplitConfig structs
     */
    function getPrizeSplits() external view returns (PrizeSplitConfig[] memory);

    /**
     * @notice Get PrizePool address
     * @return IPrizePool
     */
    function getPrizePool() external view returns (IPrizePool);

    /**
     * @notice Set and remove prize split(s) configs. Only callable by owner.
     * @dev Set and remove prize split configs by passing a new PrizeSplitConfig structs array. Will remove existing PrizeSplitConfig(s) if passed array length is less than existing prizeSplits length.
     * @param newPrizeSplits Array of PrizeSplitConfig structs
     */
    function setPrizeSplits(PrizeSplitConfig[] calldata newPrizeSplits) external;

    /**
     * @notice Updates a previously set prize split config.
     * @dev Updates a prize split config by passing a new PrizeSplitConfig struct and current index position. Limited to contract owner.
     * @param prizeStrategySplit PrizeSplitConfig config struct
     * @param prizeSplitIndex Index position of PrizeSplitConfig to update
     */
    function setPrizeSplit(PrizeSplitConfig memory prizeStrategySplit, uint8 prizeSplitIndex)
        external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../external/compound/ICompLike.sol";
import "../interfaces/ITicket.sol";

interface IPrizePool {
    /// @dev Event emitted when controlled token is added
    event ControlledTokenAdded(ITicket indexed token);

    event AwardCaptured(uint256 amount);

    /// @dev Event emitted when assets are deposited
    event Deposited(
        address indexed operator,
        address indexed to,
        ITicket indexed token,
        uint256 amount
    );

    /// @dev Event emitted when interest is awarded to a winner
    event Awarded(address indexed winner, ITicket indexed token, uint256 amount);

    /// @dev Event emitted when external ERC20s are awarded to a winner
    event AwardedExternalERC20(address indexed winner, address indexed token, uint256 amount);

    /// @dev Event emitted when external ERC20s are transferred out
    event TransferredExternalERC20(address indexed to, address indexed token, uint256 amount);

    /// @dev Event emitted when external ERC721s are awarded to a winner
    event AwardedExternalERC721(address indexed winner, address indexed token, uint256[] tokenIds);

    /// @dev Event emitted when assets are withdrawn
    event Withdrawal(
        address indexed operator,
        address indexed from,
        ITicket indexed token,
        uint256 amount,
        uint256 redeemed
    );

    /// @dev Event emitted when the Balance Cap is set
    event BalanceCapSet(uint256 balanceCap);

    /// @dev Event emitted when the Liquidity Cap is set
    event LiquidityCapSet(uint256 liquidityCap);

    /// @dev Event emitted when the Prize Strategy is set
    event PrizeStrategySet(address indexed prizeStrategy);

    /// @dev Event emitted when the Ticket is set
    event TicketSet(ITicket indexed ticket);

    /// @dev Emitted when there was an error thrown awarding an External ERC721
    event ErrorAwardingExternalERC721(bytes error);

    /// @notice Deposit assets into the Prize Pool in exchange for tokens
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    function depositTo(address to, uint256 amount) external;

    /// @notice Deposit assets into the Prize Pool in exchange for tokens,
    /// then sets the delegate on behalf of the caller.
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    /// @param delegate The address to delegate to for the caller
    function depositToAndDelegate(address to, uint256 amount, address delegate) external;

    /// @notice Withdraw assets from the Prize Pool instantly.
    /// @param from The address to redeem tokens from.
    /// @param amount The amount of tokens to redeem for assets.
    /// @return The actual amount withdrawn
    function withdrawFrom(address from, uint256 amount) external returns (uint256);

    /// @notice Called by the prize strategy to award prizes.
    /// @dev The amount awarded must be less than the awardBalance()
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of assets to be awarded
    function award(address to, uint256 amount) external;

    /// @notice Returns the balance that is available to award.
    /// @dev captureAwardBalance() should be called first
    /// @return The total amount of assets to be awarded for the current prize
    function awardBalance() external view returns (uint256);

    /// @notice Captures any available interest as award balance.
    /// @dev This function also captures the reserve fees.
    /// @return The total amount of assets to be awarded for the current prize
    function captureAwardBalance() external returns (uint256);

    /// @dev Checks with the Prize Pool if a specific token type may be awarded as an external prize
    /// @param externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function canAwardExternal(address externalToken) external view returns (bool);

    // @dev Returns the total underlying balance of all assets. This includes both principal and interest.
    /// @return The underlying balance of assets
    function balance() external returns (uint256);

    /**
     * @notice Read internal Ticket accounted balance.
     * @return uint256 accountBalance
     */
    function getAccountedBalance() external view returns (uint256);

    /**
     * @notice Read internal balanceCap variable
     */
    function getBalanceCap() external view returns (uint256);

    /**
     * @notice Read internal liquidityCap variable
     */
    function getLiquidityCap() external view returns (uint256);

    /**
     * @notice Read ticket variable
     */
    function getTicket() external view returns (ITicket);

    /**
     * @notice Read token variable
     */
    function getToken() external view returns (address);

    /**
     * @notice Read prizeStrategy variable
     */
    function getPrizeStrategy() external view returns (address);

    /// @dev Checks if a specific token is controlled by the Prize Pool
    /// @param controlledToken The address of the token to check
    /// @return True if the token is a controlled token, false otherwise
    function isControlled(ITicket controlledToken) external view returns (bool);

    /// @notice Called by the Prize-Strategy to transfer out external ERC20 tokens
    /// @dev Used to transfer out tokens held by the Prize Pool.  Could be liquidated, or anything.
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external asset token being awarded
    /// @param amount The amount of external assets to be awarded
    function transferExternalERC20(
        address to,
        address externalToken,
        uint256 amount
    ) external;

    /// @notice Called by the Prize-Strategy to award external ERC20 prizes
    /// @dev Used to award any arbitrary tokens held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of external assets to be awarded
    /// @param externalToken The address of the external asset token being awarded
    function awardExternalERC20(
        address to,
        address externalToken,
        uint256 amount
    ) external;

    /// @notice Called by the prize strategy to award external ERC721 prizes
    /// @dev Used to award any arbitrary NFTs held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external NFT token being awarded
    /// @param tokenIds An array of NFT Token IDs to be transferred
    function awardExternalERC721(
        address to,
        address externalToken,
        uint256[] calldata tokenIds
    ) external;

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @dev If a user wins, his balance can go over the cap. He will be able to withdraw the excess but not deposit.
    /// @dev Needs to be called after deploying a prize pool to be able to deposit into it.
    /// @param balanceCap New balance cap.
    /// @return True if new balance cap has been successfully set.
    function setBalanceCap(uint256 balanceCap) external returns (bool);

    /// @notice Allows the Governor to set a cap on the amount of liquidity that he pool can hold
    /// @param liquidityCap The new liquidity cap for the prize pool
    function setLiquidityCap(uint256 liquidityCap) external;

    /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
    /// @param _prizeStrategy The new prize strategy.
    function setPrizeStrategy(address _prizeStrategy) external;

    /// @notice Set prize pool ticket.
    /// @param ticket Address of the ticket to set.
    /// @return True if ticket has been successfully set.
    function setTicket(ITicket ticket) external returns (bool);

    /// @notice Delegate the votes for a Compound COMP-like token held by the prize pool
    /// @param compLike The COMP-like token held by the prize pool that should be delegated
    /// @param to The address to delegate to
    function compLikeDelegate(ICompLike compLike, address to) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICompLike is IERC20 {
    function getCurrentVotes(address account) external view returns (uint96);

    function delegate(address delegate) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./PrizeSplit.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IPrizePool.sol";

/**
  * @title  PoolTogether V4 PrizeSplitStrategy
  * @author PoolTogether Inc Team
  * @notice Captures PrizePool interest for PrizeReserve and additional PrizeSplit recipients.
            The PrizeSplitStrategy will have at minimum a single PrizeSplit with 100% of the captured
            interest transfered to the PrizeReserve. Additional PrizeSplits can be added, depending on
            the deployers requirements (i.e. percentage to charity). In contrast to previous PoolTogether
            iterations, interest can be captured independent of a new Draw. Ideally (to save gas) interest
            is only captured when also distributing the captured prize(s) to applicable Prize Distributor(s).
*/
contract PrizeSplitStrategy is PrizeSplit, IStrategy {
    /**
     * @notice PrizePool address
     */
    IPrizePool internal immutable prizePool;

    /**
     * @notice Deployed Event
     * @param owner Contract owner
     * @param prizePool Linked PrizePool contract
     */
    event Deployed(address indexed owner, IPrizePool prizePool);

    /* ============ Constructor ============ */

    /**
     * @notice Deploy the PrizeSplitStrategy smart contract.
     * @param _owner     Owner address
     * @param _prizePool PrizePool address
     */
    constructor(address _owner, IPrizePool _prizePool) Ownable(_owner) {
        require(
            address(_prizePool) != address(0),
            "PrizeSplitStrategy/prize-pool-not-zero-address"
        );
        prizePool = _prizePool;
        emit Deployed(_owner, _prizePool);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IStrategy
    function distribute() external override returns (uint256) {
        uint256 prize = prizePool.captureAwardBalance();

        if (prize == 0) return 0;

        uint256 prizeRemaining = _distributePrizeSplits(prize);

        emit Distributed(prize - prizeRemaining);

        return prize;
    }

    /// @inheritdoc IPrizeSplit
    function getPrizePool() external view override returns (IPrizePool) {
        return prizePool;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Award ticket tokens to prize split recipient.
     * @dev Award ticket tokens to prize split recipient via the linked PrizePool contract.
     * @param _to Recipient of minted tokens.
     * @param _amount Amount of minted tokens.
     */
    function _awardPrizeSplitAmount(address _to, uint256 _amount) internal override {
        IControlledToken _ticket = prizePool.getTicket();
        prizePool.award(_to, _amount);
        emit PrizeSplitAwarded(_to, _amount, _ticket);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

interface IStrategy {
    /**
     * @notice Emit when a strategy captures award amount from PrizePool.
     * @param totalPrizeCaptured  Total prize captured from the PrizePool
     */
    event Distributed(uint256 totalPrizeCaptured);

    /**
     * @notice Capture the award balance and distribute to prize splits.
     * @dev    Permissionless function to initialize distribution of interst
     * @return Prize captured from PrizePool
     */
    function distribute() external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/prize-strategy/PrizeSplitStrategy.sol';

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "../external/compound/ICompLike.sol";
import "../interfaces/IPrizePool.sol";
import "../interfaces/ITicket.sol";

/**
  * @title  PoolTogether V4 PrizePool
  * @author PoolTogether Inc Team
  * @notice Escrows assets and deposits them into a yield source.  Exposes interest to Prize Strategy.
            Users deposit and withdraw from this contract to participate in Prize Pool.
            Accounting is managed using Controlled Tokens, whose mint and burn functions can only be called by this contract.
            Must be inherited to provide specific yield-bearing asset control, such as Compound cTokens
*/
abstract contract PrizePool is IPrizePool, Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    /// @notice Semver Version
    string public constant VERSION = "4.0.0";

    /// @notice Prize Pool ticket. Can only be set once by calling `setTicket()`.
    ITicket internal ticket;

    /// @notice The Prize Strategy that this Prize Pool is bound to.
    address internal prizeStrategy;

    /// @notice The total amount of tickets a user can hold.
    uint256 internal balanceCap;

    /// @notice The total amount of funds that the prize pool can hold.
    uint256 internal liquidityCap;

    /// @notice the The awardable balance
    uint256 internal _currentAwardBalance;

    /* ============ Modifiers ============ */

    /// @dev Function modifier to ensure caller is the prize-strategy
    modifier onlyPrizeStrategy() {
        require(msg.sender == prizeStrategy, "PrizePool/only-prizeStrategy");
        _;
    }

    /// @dev Function modifier to ensure the deposit amount does not exceed the liquidity cap (if set)
    modifier canAddLiquidity(uint256 _amount) {
        require(_canAddLiquidity(_amount), "PrizePool/exceeds-liquidity-cap");
        _;
    }

    /* ============ Constructor ============ */

    /// @notice Deploy the Prize Pool
    /// @param _owner Address of the Prize Pool owner
    constructor(address _owner) Ownable(_owner) ReentrancyGuard() {
        _setLiquidityCap(type(uint256).max);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizePool
    function balance() external override returns (uint256) {
        return _balance();
    }

    /// @inheritdoc IPrizePool
    function awardBalance() external view override returns (uint256) {
        return _currentAwardBalance;
    }

    /// @inheritdoc IPrizePool
    function canAwardExternal(address _externalToken) external view override returns (bool) {
        return _canAwardExternal(_externalToken);
    }

    /// @inheritdoc IPrizePool
    function isControlled(ITicket _controlledToken) external view override returns (bool) {
        return _isControlled(_controlledToken);
    }

    /// @inheritdoc IPrizePool
    function getAccountedBalance() external view override returns (uint256) {
        return _ticketTotalSupply();
    }

    /// @inheritdoc IPrizePool
    function getBalanceCap() external view override returns (uint256) {
        return balanceCap;
    }

    /// @inheritdoc IPrizePool
    function getLiquidityCap() external view override returns (uint256) {
        return liquidityCap;
    }

    /// @inheritdoc IPrizePool
    function getTicket() external view override returns (ITicket) {
        return ticket;
    }

    /// @inheritdoc IPrizePool
    function getPrizeStrategy() external view override returns (address) {
        return prizeStrategy;
    }

    /// @inheritdoc IPrizePool
    function getToken() external view override returns (address) {
        return address(_token());
    }

    /// @inheritdoc IPrizePool
    function captureAwardBalance() external override nonReentrant returns (uint256) {
        uint256 ticketTotalSupply = _ticketTotalSupply();
        uint256 currentAwardBalance = _currentAwardBalance;

        // it's possible for the balance to be slightly less due to rounding errors in the underlying yield source
        uint256 currentBalance = _balance();
        uint256 totalInterest = (currentBalance > ticketTotalSupply)
            ? currentBalance - ticketTotalSupply
            : 0;

        uint256 unaccountedPrizeBalance = (totalInterest > currentAwardBalance)
            ? totalInterest - currentAwardBalance
            : 0;

        if (unaccountedPrizeBalance > 0) {
            currentAwardBalance = totalInterest;
            _currentAwardBalance = currentAwardBalance;

            emit AwardCaptured(unaccountedPrizeBalance);
        }

        return currentAwardBalance;
    }

    /// @inheritdoc IPrizePool
    function depositTo(address _to, uint256 _amount)
        external
        override
        nonReentrant
        canAddLiquidity(_amount)
    {
        _depositTo(msg.sender, _to, _amount);
    }

    /// @inheritdoc IPrizePool
    function depositToAndDelegate(address _to, uint256 _amount, address _delegate)
        external
        override
        nonReentrant
        canAddLiquidity(_amount)
    {
        _depositTo(msg.sender, _to, _amount);
        ticket.controllerDelegateFor(msg.sender, _delegate);
    }

    /// @notice Transfers tokens in from one user and mints tickets to another
    /// @notice _operator The user to transfer tokens from
    /// @notice _to The user to mint tickets to
    /// @notice _amount The amount to transfer and mint
    function _depositTo(address _operator, address _to, uint256 _amount) internal
    {
        require(_canDeposit(_to, _amount), "PrizePool/exceeds-balance-cap");

        ITicket _ticket = ticket;

        _token().safeTransferFrom(_operator, address(this), _amount);

        _mint(_to, _amount, _ticket);
        _supply(_amount);

        emit Deposited(_operator, _to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePool
    function withdrawFrom(address _from, uint256 _amount)
        external
        override
        nonReentrant
        returns (uint256)
    {
        ITicket _ticket = ticket;

        // burn the tickets
        _ticket.controllerBurnFrom(msg.sender, _from, _amount);

        // redeem the tickets
        uint256 _redeemed = _redeem(_amount);

        _token().safeTransfer(_from, _redeemed);

        emit Withdrawal(msg.sender, _from, _ticket, _amount, _redeemed);

        return _redeemed;
    }

    /// @inheritdoc IPrizePool
    function award(address _to, uint256 _amount) external override onlyPrizeStrategy {
        if (_amount == 0) {
            return;
        }

        uint256 currentAwardBalance = _currentAwardBalance;

        require(_amount <= currentAwardBalance, "PrizePool/award-exceeds-avail");

        unchecked {
            _currentAwardBalance = currentAwardBalance - _amount;
        }

        ITicket _ticket = ticket;

        _mint(_to, _amount, _ticket);

        emit Awarded(_to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePool
    function transferExternalERC20(
        address _to,
        address _externalToken,
        uint256 _amount
    ) external override onlyPrizeStrategy {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit TransferredExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePool
    function awardExternalERC20(
        address _to,
        address _externalToken,
        uint256 _amount
    ) external override onlyPrizeStrategy {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit AwardedExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePool
    function awardExternalERC721(
        address _to,
        address _externalToken,
        uint256[] calldata _tokenIds
    ) external override onlyPrizeStrategy {
        require(_canAwardExternal(_externalToken), "PrizePool/invalid-external-token");

        if (_tokenIds.length == 0) {
            return;
        }

        uint256[] memory _awardedTokenIds = new uint256[](_tokenIds.length); 
        bool hasAwardedTokenIds;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            try IERC721(_externalToken).safeTransferFrom(address(this), _to, _tokenIds[i]) {
                hasAwardedTokenIds = true;
                _awardedTokenIds[i] = _tokenIds[i];
            } catch (
                bytes memory error
            ) {
                emit ErrorAwardingExternalERC721(error);
            }
        }
        if (hasAwardedTokenIds) { 
            emit AwardedExternalERC721(_to, _externalToken, _awardedTokenIds);
        }
    }

    /// @inheritdoc IPrizePool
    function setBalanceCap(uint256 _balanceCap) external override onlyOwner returns (bool) {
        _setBalanceCap(_balanceCap);
        return true;
    }

    /// @inheritdoc IPrizePool
    function setLiquidityCap(uint256 _liquidityCap) external override onlyOwner {
        _setLiquidityCap(_liquidityCap);
    }

    /// @inheritdoc IPrizePool
    function setTicket(ITicket _ticket) external override onlyOwner returns (bool) {
        require(address(_ticket) != address(0), "PrizePool/ticket-not-zero-address");
        require(address(ticket) == address(0), "PrizePool/ticket-already-set");

        ticket = _ticket;

        emit TicketSet(_ticket);

        _setBalanceCap(type(uint256).max);

        return true;
    }

    /// @inheritdoc IPrizePool
    function setPrizeStrategy(address _prizeStrategy) external override onlyOwner {
        _setPrizeStrategy(_prizeStrategy);
    }

    /// @inheritdoc IPrizePool
    function compLikeDelegate(ICompLike _compLike, address _to) external override onlyOwner {
        if (_compLike.balanceOf(address(this)) > 0) {
            _compLike.delegate(_to);
        }
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /* ============ Internal Functions ============ */

    /// @notice Transfer out `amount` of `externalToken` to recipient `to`
    /// @dev Only awardable `externalToken` can be transferred out
    /// @param _to Recipient address
    /// @param _externalToken Address of the external asset token being transferred
    /// @param _amount Amount of external assets to be transferred
    /// @return True if transfer is successful
    function _transferOut(
        address _to,
        address _externalToken,
        uint256 _amount
    ) internal returns (bool) {
        require(_canAwardExternal(_externalToken), "PrizePool/invalid-external-token");

        if (_amount == 0) {
            return false;
        }

        IERC20(_externalToken).safeTransfer(_to, _amount);

        return true;
    }

    /// @notice Called to mint controlled tokens.  Ensures that token listener callbacks are fired.
    /// @param _to The user who is receiving the tokens
    /// @param _amount The amount of tokens they are receiving
    /// @param _controlledToken The token that is going to be minted
    function _mint(
        address _to,
        uint256 _amount,
        ITicket _controlledToken
    ) internal {
        _controlledToken.controllerMint(_to, _amount);
    }

    /// @dev Checks if `user` can deposit in the Prize Pool based on the current balance cap.
    /// @param _user Address of the user depositing.
    /// @param _amount The amount of tokens to be deposited into the Prize Pool.
    /// @return True if the Prize Pool can receive the specified `amount` of tokens.
    function _canDeposit(address _user, uint256 _amount) internal view returns (bool) {
        uint256 _balanceCap = balanceCap;

        if (_balanceCap == type(uint256).max) return true;

        return (ticket.balanceOf(_user) + _amount <= _balanceCap);
    }

    /// @dev Checks if the Prize Pool can receive liquidity based on the current cap
    /// @param _amount The amount of liquidity to be added to the Prize Pool
    /// @return True if the Prize Pool can receive the specified amount of liquidity
    function _canAddLiquidity(uint256 _amount) internal view returns (bool) {
        uint256 _liquidityCap = liquidityCap;
        if (_liquidityCap == type(uint256).max) return true;
        return (_ticketTotalSupply() + _amount <= _liquidityCap);
    }

    /// @dev Checks if a specific token is controlled by the Prize Pool
    /// @param _controlledToken The address of the token to check
    /// @return True if the token is a controlled token, false otherwise
    function _isControlled(ITicket _controlledToken) internal view returns (bool) {
        return (ticket == _controlledToken);
    }

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @param _balanceCap New balance cap.
    function _setBalanceCap(uint256 _balanceCap) internal {
        balanceCap = _balanceCap;
        emit BalanceCapSet(_balanceCap);
    }

    /// @notice Allows the owner to set a liquidity cap for the pool
    /// @param _liquidityCap New liquidity cap
    function _setLiquidityCap(uint256 _liquidityCap) internal {
        liquidityCap = _liquidityCap;
        emit LiquidityCapSet(_liquidityCap);
    }

    /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
    /// @param _prizeStrategy The new prize strategy
    function _setPrizeStrategy(address _prizeStrategy) internal {
        require(_prizeStrategy != address(0), "PrizePool/prizeStrategy-not-zero");

        prizeStrategy = _prizeStrategy;

        emit PrizeStrategySet(_prizeStrategy);
    }

    /// @notice The current total of tickets.
    /// @return Ticket total supply.
    function _ticketTotalSupply() internal view returns (uint256) {
        return ticket.totalSupply();
    }

    /// @dev Gets the current time as represented by the current block
    /// @return The timestamp of the current block
    function _currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /* ============ Abstract Contract Implementatiton ============ */

    /// @notice Determines whether the passed token can be transferred out as an external award.
    /// @dev Different yield sources will hold the deposits as another kind of token: such a Compound's cToken.  The
    /// prize strategy should not be allowed to move those tokens.
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(address _externalToken) internal view virtual returns (bool);

    /// @notice Returns the ERC20 asset token used for deposits.
    /// @return The ERC20 asset token
    function _token() internal view virtual returns (IERC20);

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens
    function _balance() internal virtual returns (uint256);

    /// @notice Supplies asset tokens to the yield source.
    /// @param _mintAmount The amount of asset tokens to be supplied
    function _supply(uint256 _mintAmount) internal virtual;

    /// @notice Redeems asset tokens from the yield source.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(uint256 _redeemAmount) internal virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/v4-core/contracts/interfaces/ITicket.sol";

import "./Delegation.sol";
import "./LowLevelDelegator.sol";
import "./PermitAndMulticall.sol";

/**
 * @title Delegate chances to win to multiple accounts.
 * @notice This contract allows accounts to easily delegate a portion of their tickets to multiple delegatees.
  The delegatees chance of winning prizes is increased by the delegated amount.
  If a delegator doesn't want to actively manage the delegations, then they can stake on the contract and appoint representatives.
 */
contract TWABDelegator is ERC20, LowLevelDelegator, PermitAndMulticall {
  using Address for address;
  using Clones for address;
  using SafeERC20 for IERC20;

  /* ============ Events ============ */

  /**
   * @notice Emitted when ticket associated with this contract has been set.
   * @param ticket Address of the ticket
   */
  event TicketSet(ITicket indexed ticket);

  /**
   * @notice Emitted when tickets have been staked.
   * @param delegator Address of the delegator
   * @param amount Amount of tickets staked
   */
  event TicketsStaked(address indexed delegator, uint256 amount);

  /**
   * @notice Emitted when tickets have been unstaked.
   * @param delegator Address of the delegator
   * @param recipient Address of the recipient that will receive the tickets
   * @param amount Amount of tickets unstaked
   */
  event TicketsUnstaked(address indexed delegator, address indexed recipient, uint256 amount);

  /**
   * @notice Emitted when a new delegation is created.
   * @param delegator Delegator of the delegation
   * @param slot Slot of the delegation
   * @param lockUntil Timestamp until which the delegation is locked
   * @param delegatee Address of the delegatee
   * @param delegation Address of the delegation that was created
   * @param user Address of the user who created the delegation
   */
  event DelegationCreated(
    address indexed delegator,
    uint256 indexed slot,
    uint96 lockUntil,
    address indexed delegatee,
    Delegation delegation,
    address user
  );

  /**
   * @notice Emitted when a delegatee is updated.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param delegatee Address of the delegatee
   * @param lockUntil Timestamp until which the delegation is locked
   * @param user Address of the user who updated the delegatee
   */
  event DelegateeUpdated(
    address indexed delegator,
    uint256 indexed slot,
    address indexed delegatee,
    uint96 lockUntil,
    address user
  );

  /**
   * @notice Emitted when a delegation is funded.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param amount Amount of tickets that were sent to the delegation
   * @param user Address of the user who funded the delegation
   */
  event DelegationFunded(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed user
  );

  /**
   * @notice Emitted when a delegation is funded from the staked amount.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param amount Amount of tickets that were sent to the delegation
   * @param user Address of the user who pulled funds from the delegator stake to the delegation
   */
  event DelegationFundedFromStake(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed user
  );

  /**
   * @notice Emitted when an amount of tickets has been withdrawn from a delegation. The tickets are held by this contract and the delegator stake is increased.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param amount Amount of tickets withdrawn
   * @param user Address of the user who withdrew the tickets
   */
  event WithdrewDelegationToStake(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed user
  );

  /**
   * @notice Emitted when a delegator withdraws an amount of tickets from a delegation to a specified wallet.
   * @param delegator Address of the delegator
   * @param slot  Slot of the delegation
   * @param amount Amount of tickets withdrawn
   * @param to Recipient address of withdrawn tickets
   */
  event TransferredDelegation(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed to
  );

  /**
   * @notice Emitted when a representative is set.
   * @param delegator Address of the delegator
   * @param representative Address of the representative
   * @param set Boolean indicating if the representative was set or unset
   */
  event RepresentativeSet(address indexed delegator, address indexed representative, bool set);

  /* ============ Variables ============ */

  /// @notice Prize pool ticket to which this contract is tied to.
  ITicket public immutable ticket;

  /// @notice Max lock time during which a delegation cannot be updated.
  uint256 public constant MAX_LOCK = 180 days;

  /**
   * @notice Representative elected by the delegator to handle delegation.
   * @dev Representative can only handle delegation and cannot withdraw tickets to their wallet.
   * @dev delegator => representative => bool allowing representative to represent the delegator
   */
  mapping(address => mapping(address => bool)) internal representatives;

  /* ============ Constructor ============ */

  /**
   * @notice Creates a new TWAB Delegator that is bound to the given ticket contract.
   * @param name_ The name for the staked ticket token
   * @param symbol_ The symbol for the staked ticket token
   * @param _ticket Address of the ticket contract
   */
  constructor(
    string memory name_,
    string memory symbol_,
    ITicket _ticket
  ) LowLevelDelegator() ERC20(name_, symbol_) {
    require(address(_ticket) != address(0), "TWABDelegator/tick-not-zero-addr");
    ticket = _ticket;

    emit TicketSet(_ticket);
  }

  /* ============ External Functions ============ */

  /**
   * @notice Stake `_amount` of tickets in this contract.
   * @dev Tickets can be staked on behalf of a `_to` user.
   * @param _to Address to which the stake will be attributed
   * @param _amount Amount of tickets to stake
   */
  function stake(address _to, uint256 _amount) external {
    _requireAmountGtZero(_amount);

    IERC20(ticket).safeTransferFrom(msg.sender, address(this), _amount);
    _mint(_to, _amount);

    emit TicketsStaked(_to, _amount);
  }

  /**
   * @notice Unstake `_amount` of tickets from this contract. Transfers ticket to the passed `_to` address.
   * @dev If delegator has delegated his whole stake, he will first have to withdraw from a delegation to be able to unstake.
   * @param _to Address of the recipient that will receive the tickets
   * @param _amount Amount of tickets to unstake
   */
  function unstake(address _to, uint256 _amount) external {
    _requireRecipientNotZeroAddress(_to);
    _requireAmountGtZero(_amount);

    _burn(msg.sender, _amount);

    IERC20(ticket).safeTransfer(_to, _amount);

    emit TicketsUnstaked(msg.sender, _to, _amount);
  }

  /**
   * @notice Creates a new delegation.
   This will create a new Delegation contract for the given slot and have it delegate its tickets to the given delegatee.
   If a non-zero lock duration is passed, then the delegatee cannot be changed, nor funding withdrawn, until the lock has expired.
   * @dev The `_delegator` and `_slot` params are used to compute the salt of the delegation
   * @param _delegator Address of the delegator that will be able to handle the delegation
   * @param _slot Slot of the delegation
   * @param _delegatee Address of the delegatee
   * @param _lockDuration Duration of time for which the delegation is locked. Must be less than the max duration.
   * @return Returns the address of the Delegation contract that will hold the tickets
   */
  function createDelegation(
    address _delegator,
    uint256 _slot,
    address _delegatee,
    uint96 _lockDuration
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);
    _requireDelegateeNotZeroAddress(_delegatee);
    _requireLockDuration(_lockDuration);

    uint96 _lockUntil = _computeLockUntil(_lockDuration);

    Delegation _delegation = _createDelegation(
      _computeSalt(_delegator, bytes32(_slot)),
      _lockUntil
    );

    _setDelegateeCall(_delegation, _delegatee);

    emit DelegationCreated(_delegator, _slot, _lockUntil, _delegatee, _delegation, msg.sender);

    return _delegation;
  }

  /**
   * @notice Updates the delegatee and lock duration for a delegation slot.
   * @dev Only callable by the `_delegator` or their representative.
   * @dev Will revert if delegation is still locked.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _delegatee Address of the delegatee
   * @param _lockDuration Duration of time during which the delegatee cannot be changed nor withdrawn
   * @return The address of the Delegation
   */
  function updateDelegatee(
    address _delegator,
    uint256 _slot,
    address _delegatee,
    uint96 _lockDuration
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);
    _requireDelegateeNotZeroAddress(_delegatee);
    _requireLockDuration(_lockDuration);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));
    _requireDelegationUnlocked(_delegation);

    uint96 _lockUntil = _computeLockUntil(_lockDuration);

    if (_lockDuration > 0) {
      _delegation.setLockUntil(_lockUntil);
    }

    _setDelegateeCall(_delegation, _delegatee);

    emit DelegateeUpdated(_delegator, _slot, _delegatee, _lockUntil, msg.sender);

    return _delegation;
  }

  /**
   * @notice Fund a delegation by transferring tickets from the caller to the delegation.
   * @dev Callable by anyone.
   * @dev Will revert if delegation does not exist.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _amount Amount of tickets to transfer
   * @return The address of the Delegation
   */
  function fundDelegation(
    address _delegator,
    uint256 _slot,
    uint256 _amount
  ) external returns (Delegation) {
    require(_delegator != address(0), "TWABDelegator/dlgtr-not-zero-adr");
    _requireAmountGtZero(_amount);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));
    IERC20(ticket).safeTransferFrom(msg.sender, address(_delegation), _amount);

    emit DelegationFunded(_delegator, _slot, _amount, msg.sender);

    return _delegation;
  }

  /**
   * @notice Fund a delegation using the `_delegator` stake.
   * @dev Callable only by the `_delegator` or a representative.
   * @dev Will revert if delegation does not exist.
   * @dev Will revert if `_amount` is greater than the staked amount.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _amount Amount of tickets to send to the delegation from the staked amount
   * @return The address of the Delegation
   */
  function fundDelegationFromStake(
    address _delegator,
    uint256 _slot,
    uint256 _amount
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);
    _requireAmountGtZero(_amount);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

    _burn(_delegator, _amount);

    IERC20(ticket).safeTransfer(address(_delegation), _amount);

    emit DelegationFundedFromStake(_delegator, _slot, _amount, msg.sender);

    return _delegation;
  }

  /**
   * @notice Withdraw tickets from a delegation. The tickets will be held by this contract and the delegator's stake will increase.
   * @dev Only callable by the `_delegator` or a representative.
   * @dev Will send the tickets to this contract and increase the `_delegator` staked amount.
   * @dev Will revert if delegation is still locked.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _amount Amount of tickets to withdraw
   * @return The address of the Delegation
   */
  function withdrawDelegationToStake(
    address _delegator,
    uint256 _slot,
    uint256 _amount
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

    _transfer(_delegation, address(this), _amount);

    _mint(_delegator, _amount);

    emit WithdrewDelegationToStake(_delegator, _slot, _amount, msg.sender);

    return _delegation;
  }

  /**
   * @notice Withdraw an `_amount` of tickets from a delegation. The delegator is assumed to be the caller.
   * @dev Tickets are sent directly to the passed `_to` address.
   * @dev Will revert if delegation is still locked.
   * @param _slot Slot of the delegation
   * @param _amount Amount to withdraw
   * @param _to Account to transfer the withdrawn tickets to
   * @return The address of the Delegation
   */
  function transferDelegationTo(
    uint256 _slot,
    uint256 _amount,
    address _to
  ) external returns (Delegation) {
    _requireRecipientNotZeroAddress(_to);

    Delegation _delegation = Delegation(_computeAddress(msg.sender, _slot));
    _transfer(_delegation, _to, _amount);

    emit TransferredDelegation(msg.sender, _slot, _amount, _to);

    return _delegation;
  }

  /**
   * @notice Allow an account to set or unset a `_representative` to handle delegation.
   * @dev If `_set` is `true`, `_representative` will be set as representative of `msg.sender`.
   * @dev If `_set` is `false`, `_representative` will be unset as representative of `msg.sender`.
   * @param _representative Address of the representative
   * @param _set Set or unset the representative
   */
  function setRepresentative(address _representative, bool _set) external {
    require(_representative != address(0), "TWABDelegator/rep-not-zero-addr");

    representatives[msg.sender][_representative] = _set;

    emit RepresentativeSet(msg.sender, _representative, _set);
  }

  /**
   * @notice Returns whether or not the given rep is a representative of the delegator.
   * @param _delegator The delegator
   * @param _representative The representative to check for
   * @return True if the rep is a rep, false otherwise
   */
  function isRepresentativeOf(address _delegator, address _representative)
    external
    view
    returns (bool)
  {
    return representatives[_delegator][_representative];
  }

  /**
   * @notice Allows a user to call multiple functions on the same contract.  Useful for EOA who wants to batch transactions.
   * @param _data An array of encoded function calls.  The calls must be abi-encoded calls to this contract.
   * @return The results from each function call
   */
  function multicall(bytes[] calldata _data) external returns (bytes[] memory) {
    return _multicall(_data);
  }

  /**
   * @notice Alow a user to approve ticket and run various calls in one transaction.
   * @param _amount Amount of tickets to approve
   * @param _permitSignature Permit signature
   * @param _data Datas to call with `functionDelegateCall`
   */
  function permitAndMulticall(
    uint256 _amount,
    Signature calldata _permitSignature,
    bytes[] calldata _data
  ) external {
    _permitAndMulticall(IERC20Permit(address(ticket)), _amount, _permitSignature, _data);
  }

  /**
   * @notice Allows the caller to easily get the details for a delegation.
   * @param _delegator The delegator address
   * @param _slot The delegation slot they are using
   * @return delegation The address that holds tickets for the delegation
   * @return delegatee The address that tickets are being delegated to
   * @return balance The balance of tickets in the delegation
   * @return lockUntil The timestamp at which the delegation unlocks
   * @return wasCreated Whether or not the delegation has been created
   */
  function getDelegation(address _delegator, uint256 _slot)
    external
    view
    returns (
      Delegation delegation,
      address delegatee,
      uint256 balance,
      uint256 lockUntil,
      bool wasCreated
    )
  {
    delegation = Delegation(_computeAddress(_delegator, _slot));
    wasCreated = address(delegation).isContract();
    delegatee = ticket.delegateOf(address(delegation));
    balance = ticket.balanceOf(address(delegation));

    if (wasCreated) {
      lockUntil = delegation.lockUntil();
    }
  }

  /**
   * @notice Computes the address of the delegation for the delegator + slot combination.
   * @param _delegator The user who is delegating tickets
   * @param _slot The delegation slot
   * @return The address of the delegation.  This is the address that holds the balance of tickets.
   */
  function computeDelegationAddress(address _delegator, uint256 _slot)
    external
    view
    returns (address)
  {
    return _computeAddress(_delegator, _slot);
  }

  /**
   * @notice Returns the ERC20 token decimals.
   * @dev This value is equal to the decimals of the ticket being delegated.
   * @return ERC20 token decimals
   */
  function decimals() public view virtual override returns (uint8) {
    return ERC20(address(ticket)).decimals();
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Computes the address of a delegation contract using the delegator and slot as a salt.
   The contract is a clone, also known as minimal proxy contract.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @return Address at which the delegation contract will be deployed
   */
  function _computeAddress(address _delegator, uint256 _slot) internal view returns (address) {
    return _computeAddress(_computeSalt(_delegator, bytes32(_slot)));
  }

  /**
   * @notice Computes the timestamp at which the delegation unlocks, after which the delegatee can be changed and tickets withdrawn.
   * @param _lockDuration The duration of the lock
   * @return The lock expiration timestamp
   */
  function _computeLockUntil(uint96 _lockDuration) internal view returns (uint96) {
    unchecked {
      return uint96(block.timestamp) + _lockDuration;
    }
  }

  /**
   * @notice Delegates tickets from the `_delegation` contract to the `_delegatee` address.
   * @param _delegation Address of the delegation contract
   * @param _delegatee Address of the delegatee
   */
  function _setDelegateeCall(Delegation _delegation, address _delegatee) internal {
    bytes4 _selector = ticket.delegate.selector;
    bytes memory _data = abi.encodeWithSelector(_selector, _delegatee);

    _executeCall(_delegation, _data);
  }

  /**
   * @notice Tranfers tickets from the Delegation contract to the `_to` address.
   * @param _delegation Address of the delegation contract
   * @param _to Address of the recipient
   * @param _amount Amount of tickets to transfer
   */
  function _transferCall(
    Delegation _delegation,
    address _to,
    uint256 _amount
  ) internal {
    bytes4 _selector = ticket.transfer.selector;
    bytes memory _data = abi.encodeWithSelector(_selector, _to, _amount);

    _executeCall(_delegation, _data);
  }

  /**
   * @notice Execute a function call on the delegation contract.
   * @param _delegation Address of the delegation contract
   * @param _data The call data that will be executed
   * @return The return datas from the calls
   */
  function _executeCall(Delegation _delegation, bytes memory _data)
    internal
    returns (bytes[] memory)
  {
    Delegation.Call[] memory _calls = new Delegation.Call[](1);
    _calls[0] = Delegation.Call({ to: address(ticket), data: _data });

    return _delegation.executeCalls(_calls);
  }

  /**
   * @notice Transfers tickets from a delegation contract to `_to`.
   * @param _delegation Address of the delegation contract
   * @param _to Address of the recipient
   * @param _amount Amount of tickets to transfer
   */
  function _transfer(
    Delegation _delegation,
    address _to,
    uint256 _amount
  ) internal {
    _requireAmountGtZero(_amount);
    _requireDelegationUnlocked(_delegation);

    _transferCall(_delegation, _to, _amount);
  }

  /* ============ Modifier/Require Functions ============ */

  /**
   * @notice Require to only allow the delegator or representative to call a function.
   * @param _delegator Address of the delegator
   */
  function _requireDelegatorOrRepresentative(address _delegator) internal view {
    require(
      _delegator == msg.sender || representatives[_delegator][msg.sender],
      "TWABDelegator/not-dlgtr-or-rep"
    );
  }

  /**
   * @notice Require to verify that `_delegatee` is not address zero.
   * @param _delegatee Address of the delegatee
   */
  function _requireDelegateeNotZeroAddress(address _delegatee) internal pure {
    require(_delegatee != address(0), "TWABDelegator/dlgt-not-zero-addr");
  }

  /**
   * @notice Require to verify that `_amount` is greater than 0.
   * @param _amount Amount to check
   */
  function _requireAmountGtZero(uint256 _amount) internal pure {
    require(_amount > 0, "TWABDelegator/amount-gt-zero");
  }

  /**
   * @notice Require to verify that `_to` is not address zero.
   * @param _to Address to check
   */
  function _requireRecipientNotZeroAddress(address _to) internal pure {
    require(_to != address(0), "TWABDelegator/to-not-zero-addr");
  }

  /**
   * @notice Require to verify if a `_delegation` is locked.
   * @param _delegation Delegation to check
   */
  function _requireDelegationUnlocked(Delegation _delegation) internal view {
    require(block.timestamp >= _delegation.lockUntil(), "TWABDelegator/delegation-locked");
  }

  /**
   * @notice Require to verify that a `_lockDuration` does not exceed the maximum lock duration.
   * @param _lockDuration Lock duration to check
   */
  function _requireLockDuration(uint256 _lockDuration) internal pure {
    require(_lockDuration <= MAX_LOCK, "TWABDelegator/lock-too-long");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/**
 * @title Contract instantiated via CREATE2 to handle a Delegation by a delegator to a delegatee.
 * @notice A Delegation allows his owner to execute calls on behalf of the contract.
 * @dev This contract is intended to be counterfactually instantiated via CREATE2 through the LowLevelDelegator contract.
 * @dev This contract will hold tickets that will be delegated to a chosen delegatee.
 */
contract Delegation {
  /**
   * @notice A structure to define arbitrary contract calls.
   * @param to The address to call
   * @param data The call data
   */
  struct Call {
    address to;
    bytes data;
  }

  /// @notice Contract owner.
  address private _owner;

  /// @notice Timestamp until which the delegation is locked.
  uint96 public lockUntil;

  /**
   * @notice Initializes the delegation.
   * @param _lockUntil Timestamp until which the delegation is locked
   */
  function initialize(uint96 _lockUntil) external {
    require(_owner == address(0), "Delegation/already-init");
    _owner = msg.sender;
    lockUntil = _lockUntil;
  }

  /**
   * @notice Executes calls on behalf of this contract.
   * @param calls The array of calls to be executed
   * @return An array of the return values for each of the calls
   */
  function executeCalls(Call[] calldata calls) external onlyOwner returns (bytes[] memory) {
    uint256 _callsLength = calls.length;
    bytes[] memory response = new bytes[](_callsLength);
    Call memory call;

    for (uint256 i; i < _callsLength; i++) {
      call = calls[i];
      response[i] = _executeCall(call.to, call.data);
    }

    return response;
  }

  /**
   * @notice Set the timestamp until which the delegation is locked.
   * @param _lockUntil The timestamp until which the delegation is locked
   */
  function setLockUntil(uint96 _lockUntil) external onlyOwner {
    lockUntil = _lockUntil;
  }

  /**
   * @notice Executes a call to another contract.
   * @param to The address to call
   * @param data The call data
   * @return The return data from the call
   */
  function _executeCall(address to, bytes memory data) internal returns (bytes memory) {
    (bool succeeded, bytes memory returnValue) = to.call{ value: 0 }(data);
    require(succeeded, string(returnValue));
    return returnValue;
  }

  /// @notice Modifier to only allow the contract owner to call a function
  modifier onlyOwner() {
    require(msg.sender == _owner, "Delegation/only-owner");
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./Delegation.sol";

/// @title The LowLevelDelegator allows users to create delegations very cheaply.
contract LowLevelDelegator {
  using Clones for address;

  /// @notice The instance to which all proxies will point.
  Delegation public delegationInstance;

  /// @notice Contract constructor.
  constructor() {
    delegationInstance = new Delegation();
    delegationInstance.initialize(uint96(0));
  }

  /**
   * @notice Creates a clone of the delegation.
   * @param _salt Random number used to deterministically deploy the clone
   * @param _lockUntil Timestamp until which the delegation is locked
   * @return The newly created delegation
   */
  function _createDelegation(bytes32 _salt, uint96 _lockUntil) internal returns (Delegation) {
    Delegation _delegation = Delegation(address(delegationInstance).cloneDeterministic(_salt));
    _delegation.initialize(_lockUntil);
    return _delegation;
  }

  /**
   * @notice Computes the address of a clone, also known as minimal proxy contract.
   * @param _salt Random number used to compute the address
   * @return Address at which the clone will be deployed
   */
  function _computeAddress(bytes32 _salt) internal view returns (address) {
    return address(delegationInstance).predictDeterministicAddress(_salt, address(this));
  }

  /**
   * @notice Computes salt used to deterministically deploy a clone.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @return Salt used to deterministically deploy a clone.
   */
  function _computeSalt(address _delegator, bytes32 _slot) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_delegator, _slot));
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @notice Allows a user to permit token spend and then call multiple functions on a contract.
 */
contract PermitAndMulticall {
  /**
   * @notice Secp256k1 signature values.
   * @param deadline Timestamp at which the signature expires
   * @param v `v` portion of the signature
   * @param r `r` portion of the signature
   * @param s `s` portion of the signature
   */
  struct Signature {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @notice Allows a user to call multiple functions on the same contract.  Useful for EOA who want to batch transactions.
   * @param _data An array of encoded function calls.  The calls must be abi-encoded calls to this contract.
   * @return The results from each function call
   */
  function _multicall(bytes[] calldata _data) internal virtual returns (bytes[] memory) {
    uint256 _dataLength = _data.length;
    bytes[] memory results = new bytes[](_dataLength);

    for (uint256 i; i < _dataLength; i++) {
      results[i] = Address.functionDelegateCall(address(this), _data[i]);
    }

    return results;
  }

  /**
   * @notice Allow a user to approve an ERC20 token and run various calls in one transaction.
   * @param _permitToken Address of the ERC20 token
   * @param _amount Amount of tickets to approve
   * @param _permitSignature Permit signature
   * @param _data Datas to call with `functionDelegateCall`
   */
  function _permitAndMulticall(
    IERC20Permit _permitToken,
    uint256 _amount,
    Signature calldata _permitSignature,
    bytes[] calldata _data
  ) internal {
    _permitToken.permit(
      msg.sender,
      address(this),
      _amount,
      _permitSignature.deadline,
      _permitSignature.v,
      _permitSignature.r,
      _permitSignature.s
    );

    _multicall(_data);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@pooltogether/yield-source-interface/contracts/IYieldSource.sol";

import "./PrizePool.sol";

/**
 * @title  PoolTogether V4 YieldSourcePrizePool
 * @author PoolTogether Inc Team
 * @notice The Yield Source Prize Pool uses a yield source contract to generate prizes.
 *         Funds that are deposited into the prize pool are then deposited into a yield source. (i.e. Aave, Compound, etc...)
 */
contract YieldSourcePrizePool is PrizePool {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Address of the yield source.
    IYieldSource public immutable yieldSource;

    /// @dev Emitted when yield source prize pool is deployed.
    /// @param yieldSource Address of the yield source.
    event Deployed(address indexed yieldSource);

    /// @notice Emitted when stray deposit token balance in this contract is swept
    /// @param amount The amount that was swept
    event Swept(uint256 amount);

    /// @notice Deploy the Prize Pool and Yield Service with the required contract connections
    /// @param _owner Address of the Yield Source Prize Pool owner
    /// @param _yieldSource Address of the yield source
    constructor(address _owner, IYieldSource _yieldSource) PrizePool(_owner) {
        require(
            address(_yieldSource) != address(0),
            "YieldSourcePrizePool/yield-source-not-zero-address"
        );

        yieldSource = _yieldSource;

        // A hack to determine whether it's an actual yield source
        (bool succeeded, bytes memory data) = address(_yieldSource).staticcall(
            abi.encodePacked(_yieldSource.depositToken.selector)
        );
        address resultingAddress;
        if (data.length > 0) {
            resultingAddress = abi.decode(data, (address));
        }
        require(succeeded && resultingAddress != address(0), "YieldSourcePrizePool/invalid-yield-source");

        emit Deployed(address(_yieldSource));
    }

    /// @notice Sweeps any stray balance of deposit tokens into the yield source.
    /// @dev This becomes prize money
    function sweep() external nonReentrant onlyOwner {
        uint256 balance = _token().balanceOf(address(this));
        _supply(balance);

        emit Swept(balance);
    }

    /// @notice Determines whether the passed token can be transferred out as an external award.
    /// @dev Different yield sources will hold the deposits as another kind of token: such a Compound's cToken.  The
    /// prize strategy should not be allowed to move those tokens.
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(address _externalToken) internal view override returns (bool) {
        IYieldSource _yieldSource = yieldSource;
        return (
            _externalToken != address(_yieldSource) &&
            _externalToken != _yieldSource.depositToken()
        );
    }

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens
    function _balance() internal override returns (uint256) {
        return yieldSource.balanceOfToken(address(this));
    }

    /// @notice Returns the address of the ERC20 asset token used for deposits.
    /// @return Address of the ERC20 asset token.
    function _token() internal view override returns (IERC20) {
        return IERC20(yieldSource.depositToken());
    }

    /// @notice Supplies asset tokens to the yield source.
    /// @param _mintAmount The amount of asset tokens to be supplied
    function _supply(uint256 _mintAmount) internal override {
        _token().safeIncreaseAllowance(address(yieldSource), _mintAmount);
        yieldSource.supplyTokenTo(_mintAmount, address(this));
    }

    /// @notice Redeems asset tokens from the yield source.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(uint256 _redeemAmount) internal override returns (uint256) {
        return yieldSource.redeemToken(_redeemAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

/// @title Defines the functions used to interact with a yield source.  The Prize Pool inherits this contract.
/// @notice Prize Pools subclasses need to implement this interface so that yield can be generated.
interface IYieldSource {
    /// @notice Returns the ERC20 asset token used for deposits.
    /// @return The ERC20 asset token address.
    function depositToken() external view returns (address);

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens.
    function balanceOfToken(address addr) external returns (uint256);

    /// @notice Supplies tokens to the yield source.  Allows assets to be supplied on other user's behalf using the `to` param.
    /// @param amount The amount of asset tokens to be supplied.  Denominated in `depositToken()` as above.
    /// @param to The user whose balance will receive the tokens
    function supplyTokenTo(uint256 amount, address to) external;

    /// @notice Redeems tokens from the yield source.
    /// @param amount The amount of asset tokens to withdraw.  Denominated in `depositToken()` as above.
    /// @return The actual amount of interst bearing tokens that were redeemed.
    function redeemToken(uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the admin and the only minter.
 */
contract ERC20Mintable is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 internal _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _owner
    ) ERC20(_name, _symbol) {
        _decimals = decimals_;

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, _owner);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC20Mintable/caller-not-minter");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyAdminRole returns (bool) {
        _burn(account, amount);
        return true;
    }

    function masterTransfer(
        address from,
        address to,
        uint256 amount
    ) public onlyAdminRole {
        _transfer(from, to, amount);
    }

    modifier onlyAdminRole() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC20Mintable/caller-not-admin");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/test/ERC20Mintable.sol';

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IPrizePool.sol";
import "../interfaces/ITicket.sol";

/**
 * @notice Secp256k1 signature values.
 * @param deadline Timestamp at which the signature expires
 * @param v `v` portion of the signature
 * @param r `r` portion of the signature
 * @param s `s` portion of the signature
 */
struct Signature {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @notice Delegate signature to allow delegation of tickets to delegate.
 * @param delegate Address to delegate the prize pool tickets to
 * @param signature Delegate signature
 */
struct DelegateSignature {
    address delegate;
    Signature signature;
}

/// @title Allows users to approve and deposit EIP-2612 compatible tokens into a prize pool in a single transaction.
/// @custom:experimental This contract has not been fully audited yet.
contract EIP2612PermitAndDeposit {
    using SafeERC20 for IERC20;

    /**
     * @notice Permits this contract to spend on a user's behalf and deposits into the prize pool.
     * @dev The `spender` address required by the permit function is the address of this contract.
     * @param _prizePool Address of the prize pool to deposit into
     * @param _amount Amount of tokens to deposit into the prize pool
     * @param _to Address that will receive the tickets
     * @param _permitSignature Permit signature
     * @param _delegateSignature Delegate signature
     */
    function permitAndDepositToAndDelegate(
        IPrizePool _prizePool,
        uint256 _amount,
        address _to,
        Signature calldata _permitSignature,
        DelegateSignature calldata _delegateSignature
    ) external {
        ITicket _ticket = _prizePool.getTicket();
        address _token = _prizePool.getToken();

        IERC20Permit(_token).permit(
            msg.sender,
            address(this),
            _amount,
            _permitSignature.deadline,
            _permitSignature.v,
            _permitSignature.r,
            _permitSignature.s
        );

        _depositToAndDelegate(
            address(_prizePool),
            _ticket,
            _token,
            _amount,
            _to,
            _delegateSignature
        );
    }

    /**
     * @notice Deposits user's token into the prize pool and delegate tickets.
     * @param _prizePool Address of the prize pool to deposit into
     * @param _amount Amount of tokens to deposit into the prize pool
     * @param _to Address that will receive the tickets
     * @param _delegateSignature Delegate signature
     */
    function depositToAndDelegate(
        IPrizePool _prizePool,
        uint256 _amount,
        address _to,
        DelegateSignature calldata _delegateSignature
    ) external {
        ITicket _ticket = _prizePool.getTicket();
        address _token = _prizePool.getToken();

        _depositToAndDelegate(
            address(_prizePool),
            _ticket,
            _token,
            _amount,
            _to,
            _delegateSignature
        );
    }

    /**
     * @notice Deposits user's token into the prize pool and delegate tickets.
     * @param _prizePool Address of the prize pool to deposit into
     * @param _ticket Address of the ticket minted by the prize pool
     * @param _token Address of the token used to deposit into the prize pool
     * @param _amount Amount of tokens to deposit into the prize pool
     * @param _to Address that will receive the tickets
     * @param _delegateSignature Delegate signature
     */
    function _depositToAndDelegate(
        address _prizePool,
        ITicket _ticket,
        address _token,
        uint256 _amount,
        address _to,
        DelegateSignature calldata _delegateSignature
    ) internal {
        _depositTo(_token, msg.sender, _amount, _prizePool, _to);

        Signature memory signature = _delegateSignature.signature;

        _ticket.delegateWithSignature(
            _to,
            _delegateSignature.delegate,
            signature.deadline,
            signature.v,
            signature.r,
            signature.s
        );
    }

    /**
     * @notice Deposits user's token into the prize pool.
     * @param _token Address of the EIP-2612 token to approve and deposit
     * @param _owner Token owner's address (Authorizer)
     * @param _amount Amount of tokens to deposit
     * @param _prizePool Address of the prize pool to deposit into
     * @param _to Address that will receive the tickets
     */
    function _depositTo(
        address _token,
        address _owner,
        uint256 _amount,
        address _prizePool,
        address _to
    ) internal {
        IERC20(_token).safeTransferFrom(_owner, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(_prizePool, _amount);
        IPrizePool(_prizePool).depositTo(_to, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/ExtendedSafeCastLib.sol";
import "./libraries/TwabLib.sol";
import "./interfaces/ITicket.sol";
import "./ControlledToken.sol";

/**
  * @title  PoolTogether V4 Ticket
  * @author PoolTogether Inc Team
  * @notice The Ticket extends the standard ERC20 and ControlledToken interfaces with time-weighted average balance functionality.
            The average balance held by a user between two timestamps can be calculated, as well as the historic balance.  The
            historic total supply is available as well as the average total supply between two timestamps.

            A user may "delegate" their balance; increasing another user's historic balance while retaining their tokens.
*/
contract Ticket is ControlledToken, ITicket {
    using SafeERC20 for IERC20;
    using ExtendedSafeCastLib for uint256;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _DELEGATE_TYPEHASH =
        keccak256("Delegate(address user,address delegate,uint256 nonce,uint256 deadline)");

    /// @notice Record of token holders TWABs for each account.
    mapping(address => TwabLib.Account) internal userTwabs;

    /// @notice Record of tickets total supply and ring buff parameters used for observation.
    TwabLib.Account internal totalSupplyTwab;

    /// @notice Mapping of delegates.  Each address can delegate their ticket power to another.
    mapping(address => address) internal delegates;

    /* ============ Constructor ============ */

    /**
     * @notice Constructs Ticket with passed parameters.
     * @param _name ERC20 ticket token name.
     * @param _symbol ERC20 ticket token symbol.
     * @param decimals_ ERC20 ticket token decimals.
     * @param _controller ERC20 ticket controller address (ie: Prize Pool address).
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _controller
    ) ControlledToken(_name, _symbol, decimals_, _controller) {}

    /* ============ External Functions ============ */

    /// @inheritdoc ITicket
    function getAccountDetails(address _user)
        external
        view
        override
        returns (TwabLib.AccountDetails memory)
    {
        return userTwabs[_user].details;
    }

    /// @inheritdoc ITicket
    function getTwab(address _user, uint16 _index)
        external
        view
        override
        returns (ObservationLib.Observation memory)
    {
        return userTwabs[_user].twabs[_index];
    }

    /// @inheritdoc ITicket
    function getBalanceAt(address _user, uint64 _target) external view override returns (uint256) {
        TwabLib.Account storage account = userTwabs[_user];

        return
            TwabLib.getBalanceAt(
                account.twabs,
                account.details,
                uint32(_target),
                uint32(block.timestamp)
            );
    }

    /// @inheritdoc ITicket
    function getAverageBalancesBetween(
        address _user,
        uint64[] calldata _startTimes,
        uint64[] calldata _endTimes
    ) external view override returns (uint256[] memory) {
        return _getAverageBalancesBetween(userTwabs[_user], _startTimes, _endTimes);
    }

    /// @inheritdoc ITicket
    function getAverageTotalSuppliesBetween(
        uint64[] calldata _startTimes,
        uint64[] calldata _endTimes
    ) external view override returns (uint256[] memory) {
        return _getAverageBalancesBetween(totalSupplyTwab, _startTimes, _endTimes);
    }

    /// @inheritdoc ITicket
    function getAverageBalanceBetween(
        address _user,
        uint64 _startTime,
        uint64 _endTime
    ) external view override returns (uint256) {
        TwabLib.Account storage account = userTwabs[_user];

        return
            TwabLib.getAverageBalanceBetween(
                account.twabs,
                account.details,
                uint32(_startTime),
                uint32(_endTime),
                uint32(block.timestamp)
            );
    }

    /// @inheritdoc ITicket
    function getBalancesAt(address _user, uint64[] calldata _targets)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 length = _targets.length;
        uint256[] memory _balances = new uint256[](length);

        TwabLib.Account storage twabContext = userTwabs[_user];
        TwabLib.AccountDetails memory details = twabContext.details;

        for (uint256 i = 0; i < length; i++) {
            _balances[i] = TwabLib.getBalanceAt(
                twabContext.twabs,
                details,
                uint32(_targets[i]),
                uint32(block.timestamp)
            );
        }

        return _balances;
    }

    /// @inheritdoc ITicket
    function getTotalSupplyAt(uint64 _target) external view override returns (uint256) {
        return
            TwabLib.getBalanceAt(
                totalSupplyTwab.twabs,
                totalSupplyTwab.details,
                uint32(_target),
                uint32(block.timestamp)
            );
    }

    /// @inheritdoc ITicket
    function getTotalSuppliesAt(uint64[] calldata _targets)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 length = _targets.length;
        uint256[] memory totalSupplies = new uint256[](length);

        TwabLib.AccountDetails memory details = totalSupplyTwab.details;

        for (uint256 i = 0; i < length; i++) {
            totalSupplies[i] = TwabLib.getBalanceAt(
                totalSupplyTwab.twabs,
                details,
                uint32(_targets[i]),
                uint32(block.timestamp)
            );
        }

        return totalSupplies;
    }

    /// @inheritdoc ITicket
    function delegateOf(address _user) external view override returns (address) {
        return delegates[_user];
    }

    /// @inheritdoc ITicket
    function controllerDelegateFor(address _user, address _to) external override onlyController {
        _delegate(_user, _to);
    }

    /// @inheritdoc ITicket
    function delegateWithSignature(
        address _user,
        address _newDelegate,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual override {
        require(block.timestamp <= _deadline, "Ticket/delegate-expired-deadline");

        bytes32 structHash = keccak256(abi.encode(_DELEGATE_TYPEHASH, _user, _newDelegate, _useNonce(_user), _deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, _v, _r, _s);
        require(signer == _user, "Ticket/delegate-invalid-signature");

        _delegate(_user, _newDelegate);
    }

    /// @inheritdoc ITicket
    function delegate(address _to) external virtual override {
        _delegate(msg.sender, _to);
    }

    /// @notice Delegates a users chance to another
    /// @param _user The user whose balance should be delegated
    /// @param _to The delegate
    function _delegate(address _user, address _to) internal {
        uint256 balance = balanceOf(_user);
        address currentDelegate = delegates[_user];

        if (currentDelegate == _to) {
            return;
        }

        delegates[_user] = _to;

        _transferTwab(currentDelegate, _to, balance);

        emit Delegated(_user, _to);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Retrieves the average balances held by a user for a given time frame.
     * @param _account The user whose balance is checked.
     * @param _startTimes The start time of the time frame.
     * @param _endTimes The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function _getAverageBalancesBetween(
        TwabLib.Account storage _account,
        uint64[] calldata _startTimes,
        uint64[] calldata _endTimes
    ) internal view returns (uint256[] memory) {
        uint256 startTimesLength = _startTimes.length;
        require(startTimesLength == _endTimes.length, "Ticket/start-end-times-length-match");

        TwabLib.AccountDetails memory accountDetails = _account.details;

        uint256[] memory averageBalances = new uint256[](startTimesLength);
        uint32 currentTimestamp = uint32(block.timestamp);

        for (uint256 i = 0; i < startTimesLength; i++) {
            averageBalances[i] = TwabLib.getAverageBalanceBetween(
                _account.twabs,
                accountDetails,
                uint32(_startTimes[i]),
                uint32(_endTimes[i]),
                currentTimestamp
            );
        }

        return averageBalances;
    }

    // @inheritdoc ERC20
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        if (_from == _to) {
            return;
        }

        address _fromDelegate;
        if (_from != address(0)) {
            _fromDelegate = delegates[_from];
        }

        address _toDelegate;
        if (_to != address(0)) {
            _toDelegate = delegates[_to];
        }

        _transferTwab(_fromDelegate, _toDelegate, _amount);
    }

    /// @notice Transfers the given TWAB balance from one user to another
    /// @param _from The user to transfer the balance from.  May be zero in the event of a mint.
    /// @param _to The user to transfer the balance to.  May be zero in the event of a burn.
    /// @param _amount The balance that is being transferred.
    function _transferTwab(address _from, address _to, uint256 _amount) internal {
        // If we are transferring tokens from a delegated account to an undelegated account
        if (_from != address(0)) {
            _decreaseUserTwab(_from, _amount);

            if (_to == address(0)) {
                _decreaseTotalSupplyTwab(_amount);
            }
        }

        // If we are transferring tokens from an undelegated account to a delegated account
        if (_to != address(0)) {
            _increaseUserTwab(_to, _amount);

            if (_from == address(0)) {
                _increaseTotalSupplyTwab(_amount);
            }
        }
    }

    /**
     * @notice Increase `_to` TWAB balance.
     * @param _to Address of the delegate.
     * @param _amount Amount of tokens to be added to `_to` TWAB balance.
     */
    function _increaseUserTwab(
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        TwabLib.Account storage _account = userTwabs[_to];

        (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        ) = TwabLib.increaseBalance(_account, _amount.toUint208(), uint32(block.timestamp));

        _account.details = accountDetails;

        if (isNew) {
            emit NewUserTwab(_to, twab);
        }
    }

    /**
     * @notice Decrease `_to` TWAB balance.
     * @param _to Address of the delegate.
     * @param _amount Amount of tokens to be added to `_to` TWAB balance.
     */
    function _decreaseUserTwab(
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        TwabLib.Account storage _account = userTwabs[_to];

        (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        ) = TwabLib.decreaseBalance(
                _account,
                _amount.toUint208(),
                "Ticket/twab-burn-lt-balance",
                uint32(block.timestamp)
            );

        _account.details = accountDetails;

        if (isNew) {
            emit NewUserTwab(_to, twab);
        }
    }

    /// @notice Decreases the total supply twab.  Should be called anytime a balance moves from delegated to undelegated
    /// @param _amount The amount to decrease the total by
    function _decreaseTotalSupplyTwab(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory tsTwab,
            bool tsIsNew
        ) = TwabLib.decreaseBalance(
                totalSupplyTwab,
                _amount.toUint208(),
                "Ticket/burn-amount-exceeds-total-supply-twab",
                uint32(block.timestamp)
            );

        totalSupplyTwab.details = accountDetails;

        if (tsIsNew) {
            emit NewTotalSupplyTwab(tsTwab);
        }
    }

    /// @notice Increases the total supply twab.  Should be called anytime a balance moves from undelegated to delegated
    /// @param _amount The amount to increase the total by
    function _increaseTotalSupplyTwab(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory _totalSupply,
            bool tsIsNew
        ) = TwabLib.increaseBalance(totalSupplyTwab, _amount.toUint208(), uint32(block.timestamp));

        totalSupplyTwab.details = accountDetails;

        if (tsIsNew) {
            emit NewTotalSupplyTwab(_totalSupply);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "./interfaces/IControlledToken.sol";

/**
 * @title  PoolTogether V4 Controlled ERC20 Token
 * @author PoolTogether Inc Team
 * @notice  ERC20 Tokens with a controller for minting & burning
 */
contract ControlledToken is ERC20Permit, IControlledToken {
    /* ============ Global Variables ============ */

    /// @notice Interface to the contract responsible for controlling mint/burn
    address public override immutable controller;

    /// @notice ERC20 controlled token decimals.
    uint8 private immutable _decimals;

    /* ============ Events ============ */

    /// @dev Emitted when contract is deployed
    event Deployed(string name, string symbol, uint8 decimals, address indexed controller);

    /* ============ Modifiers ============ */

    /// @dev Function modifier to ensure that the caller is the controller contract
    modifier onlyController() {
        require(msg.sender == address(controller), "ControlledToken/only-controller");
        _;
    }

    /* ============ Constructor ============ */

    /// @notice Deploy the Controlled Token with Token Details and the Controller
    /// @param _name The name of the Token
    /// @param _symbol The symbol for the Token
    /// @param decimals_ The number of decimals for the Token
    /// @param _controller Address of the Controller contract for minting & burning
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _controller
    ) ERC20Permit("PoolTogether ControlledToken") ERC20(_name, _symbol) {
        require(address(_controller) != address(0), "ControlledToken/controller-not-zero-address");
        controller = _controller;

        require(decimals_ > 0, "ControlledToken/decimals-gt-zero");
        _decimals = decimals_;

        emit Deployed(_name, _symbol, decimals_, _controller);
    }

    /* ============ External Functions ============ */

    /// @notice Allows the controller to mint tokens for a user account
    /// @dev May be overridden to provide more granular control over minting
    /// @param _user Address of the receiver of the minted tokens
    /// @param _amount Amount of tokens to mint
    function controllerMint(address _user, uint256 _amount)
        external
        virtual
        override
        onlyController
    {
        _mint(_user, _amount);
    }

    /// @notice Allows the controller to burn tokens from a user account
    /// @dev May be overridden to provide more granular control over burning
    /// @param _user Address of the holder account to burn tokens from
    /// @param _amount Amount of tokens to burn
    function controllerBurn(address _user, uint256 _amount)
        external
        virtual
        override
        onlyController
    {
        _burn(_user, _amount);
    }

    /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
    /// @dev May be overridden to provide more granular control over operator-burning
    /// @param _operator Address of the operator performing the burn action via the controller contract
    /// @param _user Address of the holder account to burn tokens from
    /// @param _amount Amount of tokens to burn
    function controllerBurnFrom(
        address _operator,
        address _user,
        uint256 _amount
    ) external virtual override onlyController {
        if (_operator != _user) {
            _approve(_user, _operator, allowance(_user, _operator) - _amount);
        }

        _burn(_user, _amount);
    }

    /// @notice Returns the ERC20 controlled token decimals.
    /// @dev This value should be equal to the decimals of the token used to deposit into the pool.
    /// @return uint8 decimals.
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReserve {
    /**
     * @notice Emit when checkpoint is created.
     * @param reserveAccumulated  Total depsosited
     * @param withdrawAccumulated Total withdrawn
     */

    event Checkpoint(uint256 reserveAccumulated, uint256 withdrawAccumulated);
    /**
     * @notice Emit when the withdrawTo function has executed.
     * @param recipient Address receiving funds
     * @param amount    Amount of tokens transfered.
     */
    event Withdrawn(address indexed recipient, uint256 amount);

    /**
     * @notice Create observation checkpoint in ring bufferr.
     * @dev    Calculates total desposited tokens since last checkpoint and creates new accumulator checkpoint.
     */
    function checkpoint() external;

    /**
     * @notice Read global token value.
     * @return IERC20
     */
    function getToken() external view returns (IERC20);

    /**
     * @notice Calculate token accumulation beween timestamp range.
     * @dev    Search the ring buffer for two checkpoint observations and diffs accumulator amount.
     * @param startTimestamp Account address
     * @param endTimestamp   Transfer amount
     */
    function getReserveAccumulatedBetween(uint32 startTimestamp, uint32 endTimestamp)
        external
        returns (uint224);

    /**
     * @notice Transfer Reserve token balance to recipient address.
     * @dev    Creates checkpoint before token transfer. Increments withdrawAccumulator with amount.
     * @param recipient Account address
     * @param amount    Transfer amount
     */
    function withdrawTo(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IReserve.sol";
import "./libraries/ObservationLib.sol";
import "./libraries/RingBufferLib.sol";

/**
    * @title  PoolTogether V4 Reserve
    * @author PoolTogether Inc Team
    * @notice The Reserve contract provides historical lookups of a token balance increase during a target timerange.
              As the Reserve contract transfers OUT tokens, the withdraw accumulator is increased. When tokens are
              transfered IN new checkpoint *can* be created if checkpoint() is called after transfering tokens.
              By using the reserve and withdraw accumulators to create a new checkpoint, any contract or account
              can lookup the balance increase of the reserve for a target timerange.   
    * @dev    By calculating the total held tokens in a specific time range, contracts that require knowledge 
              of captured interest during a draw period, can easily call into the Reserve and deterministically
              determine the newly aqcuired tokens for that time range. 
 */
contract Reserve is IReserve, Manageable {
    using SafeERC20 for IERC20;

    /// @notice ERC20 token
    IERC20 public immutable token;

    /// @notice Total withdraw amount from reserve
    uint224 public withdrawAccumulator;
    uint32 private _gap;

    uint24 internal nextIndex;
    uint24 internal cardinality;

    /// @notice The maximum number of twab entries
    uint24 internal constant MAX_CARDINALITY = 16777215; // 2**24 - 1

    ObservationLib.Observation[MAX_CARDINALITY] internal reserveAccumulators;

    /* ============ Events ============ */

    event Deployed(IERC20 indexed token);

    /* ============ Constructor ============ */

    /**
     * @notice Constructs Ticket with passed parameters.
     * @param _owner Owner address
     * @param _token ERC20 address
     */
    constructor(address _owner, IERC20 _token) Ownable(_owner) {
        token = _token;
        emit Deployed(_token);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IReserve
    function checkpoint() external override {
        _checkpoint();
    }

    /// @inheritdoc IReserve
    function getToken() external view override returns (IERC20) {
        return token;
    }

    /// @inheritdoc IReserve
    function getReserveAccumulatedBetween(uint32 _startTimestamp, uint32 _endTimestamp)
        external
        view
        override
        returns (uint224)
    {
        require(_startTimestamp < _endTimestamp, "Reserve/start-less-then-end");
        uint24 _cardinality = cardinality;
        uint24 _nextIndex = nextIndex;

        (uint24 _newestIndex, ObservationLib.Observation memory _newestObservation) = _getNewestObservation(_nextIndex);
        (uint24 _oldestIndex, ObservationLib.Observation memory _oldestObservation) = _getOldestObservation(_nextIndex);

        uint224 _start = _getReserveAccumulatedAt(
            _newestObservation,
            _oldestObservation,
            _newestIndex,
            _oldestIndex,
            _cardinality,
            _startTimestamp
        );

        uint224 _end = _getReserveAccumulatedAt(
            _newestObservation,
            _oldestObservation,
            _newestIndex,
            _oldestIndex,
            _cardinality,
            _endTimestamp
        );

        return _end - _start;
    }

    /// @inheritdoc IReserve
    function withdrawTo(address _recipient, uint256 _amount) external override onlyManagerOrOwner {
        _checkpoint();

        withdrawAccumulator += uint224(_amount);
        
        token.safeTransfer(_recipient, _amount);

        emit Withdrawn(_recipient, _amount);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Find optimal observation checkpoint using target timestamp
     * @dev    Uses binary search if target timestamp is within ring buffer range.
     * @param _newestObservation ObservationLib.Observation
     * @param _oldestObservation ObservationLib.Observation
     * @param _newestIndex The index of the newest observation
     * @param _oldestIndex The index of the oldest observation
     * @param _cardinality       RingBuffer Range
     * @param _timestamp          Timestamp target
     *
     * @return Optimal reserveAccumlator for timestamp.
     */
    function _getReserveAccumulatedAt(
        ObservationLib.Observation memory _newestObservation,
        ObservationLib.Observation memory _oldestObservation,
        uint24 _newestIndex,
        uint24 _oldestIndex,
        uint24 _cardinality,
        uint32 _timestamp
    ) internal view returns (uint224) {
        uint32 timeNow = uint32(block.timestamp);

        // IF empty ring buffer exit early.
        if (_cardinality == 0) return 0;

        /**
         * Ring Buffer Search Optimization
         * Before performing binary search on the ring buffer check
         * to see if timestamp is within range of [o T n] by comparing
         * the target timestamp to the oldest/newest observation.timestamps
         * IF the timestamp is out of the ring buffer range avoid starting
         * a binary search, because we can return NULL or oldestObservation.amount
         */

        /**
         * IF oldestObservation.timestamp is after timestamp: T[old ]
         * the Reserve did NOT have a balance or the ring buffer
         * no longer contains that timestamp checkpoint.
         */
        if (_oldestObservation.timestamp > _timestamp) {
            return 0;
        }

        /**
         * IF newestObservation.timestamp is before timestamp: [ new]T
         * return _newestObservation.amount since observation
         * contains the highest checkpointed reserveAccumulator.
         */
        if (_newestObservation.timestamp <= _timestamp) {
            return _newestObservation.amount;
        }

        // IF the timestamp is witin range of ring buffer start/end: [new T old]
        // FIND the closest observation to the left(or exact) of timestamp: [OT ]
        (
            ObservationLib.Observation memory beforeOrAt,
            ObservationLib.Observation memory atOrAfter
        ) = ObservationLib.binarySearch(
                reserveAccumulators,
                _newestIndex,
                _oldestIndex,
                _timestamp,
                _cardinality,
                timeNow
            );

        // IF target timestamp is EXACT match for atOrAfter.timestamp observation return amount.
        // NOT having an exact match with atOrAfter means values will contain accumulator value AFTER the searchable range.
        // ELSE return observation.totalDepositedAccumulator closest to LEFT of target timestamp.
        if (atOrAfter.timestamp == _timestamp) {
            return atOrAfter.amount;
        } else {
            return beforeOrAt.amount;
        }
    }

    /// @notice Records the currently accrued reserve amount.
    function _checkpoint() internal {
        uint24 _cardinality = cardinality;
        uint24 _nextIndex = nextIndex;
        uint256 _balanceOfReserve = token.balanceOf(address(this));
        uint224 _withdrawAccumulator = withdrawAccumulator; //sload
        (uint24 newestIndex, ObservationLib.Observation memory newestObservation) = _getNewestObservation(_nextIndex);

        /**
         * IF tokens have been deposited into Reserve contract since the last checkpoint
         * create a new Reserve balance checkpoint. The will will update multiple times in a single block.
         */
        if (_balanceOfReserve + _withdrawAccumulator > newestObservation.amount) {
            uint32 nowTime = uint32(block.timestamp);

            // checkpointAccumulator = currentBalance + totalWithdraws
            uint224 newReserveAccumulator = uint224(_balanceOfReserve) + _withdrawAccumulator;

            // IF newestObservation IS NOT in the current block.
            // CREATE observation in the accumulators ring buffer.
            if (newestObservation.timestamp != nowTime) {
                reserveAccumulators[_nextIndex] = ObservationLib.Observation({
                    amount: newReserveAccumulator,
                    timestamp: nowTime
                });
                nextIndex = uint24(RingBufferLib.nextIndex(_nextIndex, MAX_CARDINALITY));
                if (_cardinality < MAX_CARDINALITY) {
                    cardinality = _cardinality + 1;
                }
            }
            // ELSE IF newestObservation IS in the current block.
            // UPDATE the checkpoint previously created in block history.
            else {
                reserveAccumulators[newestIndex] = ObservationLib.Observation({
                    amount: newReserveAccumulator,
                    timestamp: nowTime
                });
            }

            emit Checkpoint(newReserveAccumulator, _withdrawAccumulator);
        }
    }

    /// @notice Retrieves the oldest observation
    /// @param _nextIndex The next index of the Reserve observations
    function _getOldestObservation(uint24 _nextIndex)
        internal
        view
        returns (uint24 index, ObservationLib.Observation memory observation)
    {
        index = _nextIndex;
        observation = reserveAccumulators[index];

        // If the TWAB is not initialized we go to the beginning of the TWAB circular buffer at index 0
        if (observation.timestamp == 0) {
            index = 0;
            observation = reserveAccumulators[0];
        }
    }

    /// @notice Retrieves the newest observation
    /// @param _nextIndex The next index of the Reserve observations
    function _getNewestObservation(uint24 _nextIndex)
        internal
        view
        returns (uint24 index, ObservationLib.Observation memory observation)
    {
        index = uint24(RingBufferLib.newestIndex(_nextIndex, MAX_CARDINALITY));
        observation = reserveAccumulators[index];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@pooltogether/v4-core/contracts/interfaces/ITicket.sol";
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionSource.sol";
import "@pooltogether/v4-core/contracts/libraries/ExtendedSafeCastLib.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IPrizeTierHistoryV2.sol";

/**
 * @title PrizeDistributionFactoryV2
 * @author PoolTogether Inc.
 * @notice The PrizeDistributionFactoryV2 populates a Prize Distribution Buffer for a prize pool.  It uses a PrizeTierHistoryV2, Draw Buffer and Ticket
 * to compute the correct prize distribution.  It automatically sets the cardinality based on
 * the DPR (Draw Percentage Rate), prize, minPickCost and the total ticket supply.
 */
contract PrizeDistributionFactoryV2 is Manageable {
    using ExtendedSafeCastLib for uint256;

    /* ============ Events ============ */

    /**
     * @notice Emitted when a new Prize Distribution is pushed.
     * @param drawId The draw id for which the prize distribution was pushed
     */
    event PrizeDistributionPushed(uint32 indexed drawId);

    /**
     * @notice Emitted when a Prize Distribution is set (overrides another).
     * @param drawId The draw id for which the prize distribution was set
     */
    event PrizeDistributionSet(uint32 indexed drawId);

    /* ============ Variables ============ */

    /// @notice The prize tier history to pull tier information from.
    IPrizeTierHistoryV2 public immutable prizeTierHistory;

    /// @notice The draw buffer to pull the draw from.
    IDrawBuffer public immutable drawBuffer;

    /**
     * @notice The prize distribution buffer to push and set.
     * @dev This contract must be the manager or owner of the buffer.
     */
    IPrizeDistributionBuffer public immutable prizeDistributionBuffer;

    /// @notice The ticket whose average total supply will be measured to calculate the portion of picks
    ITicket public immutable ticket;

    /// @notice The minimum cost of each pick.  Used to calculate the cardinality.
    uint256 public immutable minPickCost;

    /**
     * @notice Unit of normalization.
     * @dev The Draw Percentage Rate (DPR) being a 1e9 number,
     *      we need to normalize calculations by scaling up or down by 1e9
     */
    uint32 public constant RATE_NORMALIZATION = 1e9;

    /* ============ Constructor ============ */

    /**
     * @notice PrizeDistributionFactoryV2 constructor.
     * @param _owner Address of the contract owner
     * @param _prizeTierHistory Address of the IPrizeTierHistoryV2 contract
     * @param _drawBuffer Address of the DrawBuffer contract
     * @param _prizeDistributionBuffer Address of the PrizeDistributionBuffer contract
     * @param _ticket Address of the Prize Pool Ticket contract
     * @param _minPickCost Minimum cost of a pick for a draw
     */
    constructor(
        address _owner,
        IPrizeTierHistoryV2 _prizeTierHistory,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer,
        ITicket _ticket,
        uint256 _minPickCost
    ) Ownable(_owner) {
        require(_owner != address(0), "PDC/owner-zero");
        require(address(_prizeTierHistory) != address(0), "PDC/pth-zero");
        require(address(_drawBuffer) != address(0), "PDC/db-zero");
        require(address(_prizeDistributionBuffer) != address(0), "PDC/pdb-zero");
        require(address(_ticket) != address(0), "PDC/ticket-zero");
        require(_minPickCost > 0, "PDC/pick-cost-gt-zero");

        minPickCost = _minPickCost;
        prizeTierHistory = _prizeTierHistory;
        drawBuffer = _drawBuffer;
        prizeDistributionBuffer = _prizeDistributionBuffer;
        ticket = _ticket;
    }

    /* ============ External Functions ============ */

    /**
     * @notice Allows the owner or manager to push a new prize distribution onto the buffer.
     * The PrizeTier and Draw for the given draw id will be pulled in, and the prize distribution will be computed.
     * @param _drawId The draw id to compute for
     * @return The resulting Prize Distribution
     */
    function pushPrizeDistribution(uint32 _drawId)
        external
        onlyManagerOrOwner
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        IPrizeDistributionBuffer.PrizeDistribution
            memory _prizeDistribution = _calculatePrizeDistribution(_drawId);

        prizeDistributionBuffer.pushPrizeDistribution(_drawId, _prizeDistribution);

        emit PrizeDistributionPushed(_drawId);

        return _prizeDistribution;
    }

    /**
     * @notice Allows the owner or manager to override an existing prize distribution in the buffer.
     * The PrizeTier and Draw for the given draw id will be pulled in, and the prize distribution will be computed.
     * @param _drawId The draw id to compute for
     * @return The resulting Prize Distribution
     */
    function setPrizeDistribution(uint32 _drawId)
        external
        onlyOwner
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        IPrizeDistributionBuffer.PrizeDistribution
            memory _prizeDistribution = _calculatePrizeDistribution(_drawId);

        prizeDistributionBuffer.setPrizeDistribution(_drawId, _prizeDistribution);

        emit PrizeDistributionSet(_drawId);

        return _prizeDistribution;
    }

    /**
     * @notice Calculate Prize Distribution for a given drawId
     * @param _drawId Draw ID
     * @return PrizeDistribution
     */
    function calculatePrizeDistribution(uint32 _drawId)
        external
        view
        virtual
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return _calculatePrizeDistribution(_drawId);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculate Prize Distribution for a given drawId
     * @param _drawId Draw ID
     * @return PrizeDistribution
     */
    function _calculatePrizeDistribution(uint32 _drawId)
        internal
        view
        virtual
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        IPrizeTierHistoryV2.PrizeTierV2 memory _prizeTier = prizeTierHistory.getPrizeTier(_drawId);
        IDrawBeacon.Draw memory _draw = drawBuffer.getDraw(_drawId);

        (
            uint64[] memory _startTimes,
            uint64[] memory _endTimes
        ) = _calculateDrawPeriodTimestampOffsets(
                _draw.timestamp,
                _draw.beaconPeriodSeconds,
                _prizeTier.endTimestampOffset
            );

        uint256 _totalSupply = ticket.getAverageTotalSuppliesBetween(_startTimes, _endTimes)[0];

        (uint8 _cardinality, uint104 _numberOfPicks) = _calculateCardinalityAndNumberOfPicks(
            _prizeTier.bitRangeSize,
            _prizeTier.prize,
            _prizeTier.dpr,
            minPickCost,
            _totalSupply
        );

        IPrizeDistributionBuffer.PrizeDistribution
            memory _prizeDistribution = IPrizeDistributionSource.PrizeDistribution({
                bitRangeSize: _prizeTier.bitRangeSize,
                matchCardinality: _cardinality,
                startTimestampOffset: _draw.beaconPeriodSeconds,
                endTimestampOffset: _prizeTier.endTimestampOffset,
                maxPicksPerUser: _prizeTier.maxPicksPerUser,
                expiryDuration: _prizeTier.expiryDuration,
                numberOfPicks: _numberOfPicks,
                tiers: _prizeTier.tiers,
                prize: _prizeTier.prize
            });

        return _prizeDistribution;
    }

    /**
     * @notice Compute prize pool cardinality and number of picks for a draw.
     * @dev `cardinality` must be gte to one, that's why we use a do/while loop to increase it.
     * @param _bitRangeSize Bit range size
     * @param _prize Total prize amount
     * @param _dpr Draw percentage rate
     * @param _minPickCost Minimum cost for a pick
     * @param _totalSupply Prize Pool Ticket total supply
     * @return cardinality and number of picks
     */
    function _calculateCardinalityAndNumberOfPicks(
        uint8 _bitRangeSize,
        uint256 _prize,
        uint32 _dpr,
        uint256 _minPickCost,
        uint256 _totalSupply
    ) internal pure returns (uint8 cardinality, uint104 numberOfPicks) {
        uint256 _odds = (_dpr * _totalSupply) / _prize;

        if (_odds == 0) {
            return (cardinality = 1, numberOfPicks);
        }

        /**
         * maxPicks = totalSupply / minPickCost
         * targetPicks = maxPicks / odds = (totalSupply / minPickCost) / ((dpr * totalSupply) / prize)
         * targetPicks = (1 / minPickCost) / ((dpr * 1) / prize) = prize / (dpr * minPickCost)
        */
        uint256 _targetPicks = (_prize * RATE_NORMALIZATION) / (_dpr * _minPickCost);

        do {
            cardinality++;
        } while (_calculateTotalPicks(_bitRangeSize, cardinality + 1) < _targetPicks);

        numberOfPicks = ((_calculateTotalPicks(_bitRangeSize, cardinality) * _odds) /
            RATE_NORMALIZATION).toUint104();
    }

    /**
     * @notice Calculate Draw period start and end timestamp.
     * @param _timestamp Timestamp at which the draw was created by the DrawBeacon
     * @param _startOffset Draw start time offset in seconds
     * @param _endOffset Draw end time offset in seconds
     * @return Draw start and end timestamp
     */
    function _calculateDrawPeriodTimestampOffsets(
        uint64 _timestamp,
        uint32 _startOffset,
        uint32 _endOffset
    ) internal pure returns (uint64[] memory, uint64[] memory) {
        uint64[] memory _startTimestamps = new uint64[](1);
        uint64[] memory _endTimestamps = new uint64[](1);

        _startTimestamps[0] = _timestamp - _startOffset;
        _endTimestamps[0] = _timestamp - _endOffset;

        return (_startTimestamps, _endTimestamps);
    }

    /**
     * @notice Calculate total picks for a draw.
     * @param _bitRangeSize Bit range size
     * @param _cardinality Cardinality
     * @return Total number of picks
     */
    function _calculateTotalPicks(uint8 _bitRangeSize, uint8 _cardinality)
        internal
        pure
        returns (uint256)
    {
        return (2**_bitRangeSize)**_cardinality;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@pooltogether/v4-core/contracts/DrawBeacon.sol";

/**
 * @title  PoolTogether V4 IPrizeTierHistoryV2
 * @author PoolTogether Inc Team
 * @notice IPrizeTierHistoryV2 is the base contract for PrizeTierHistoryV2
 */
interface IPrizeTierHistoryV2 {
    /**
     * @notice PrizeTierV2 struct
     * @dev    Adds Draw Percentage Rate (DPR) and minPickCost paramater to PrizeTier struct
     */
    struct PrizeTierV2 {
        uint8 bitRangeSize;
        uint32 drawId;
        uint32 maxPicksPerUser;
        uint32 expiryDuration;
        uint32 endTimestampOffset;
        uint32 dpr;
        uint256 prize;
        uint32[16] tiers;
    }

    /**
     * @notice Emit when new PrizeTierV2 is added to history
     * @param drawId    Draw ID
     * @param prizeTier PrizeTierV2 parameters
     */
    event PrizeTierPushed(uint32 indexed drawId, PrizeTierV2 prizeTier);

    /**
     * @notice Emitted when existing PrizeTierV2 is updated in history
     * @param drawId    Draw ID
     * @param prizeTier PrizeTierV2 parameters
     */
    event PrizeTierSet(uint32 indexed drawId, PrizeTierV2 prizeTier);

    /**
     * @notice Push PrizeTierV2 struct onto `prizeTiers` array.
     * @dev Callable only by the owner or manager.
     * @dev `drawId` must be greater than the latest one stored in `history`.
     * @param nextPrizeTier Next PrizeTierV2 struct
     */
    function push(PrizeTierV2 calldata nextPrizeTier) external;

    /**
     * @notice Replace PrizeTierV2 struct in `prizeTiers` array.
     * @dev    Callable only by the owner.
     * @param newPrizeTier PrizeTierV2 parameters
     */
    function replace(PrizeTierV2 calldata newPrizeTier) external;

    /**
     * @notice Pop the latest prize tier stored in the `prizeTiers` array and replace it with the new prize tier.
     * @dev    Callable only by the owner.
     * @param newPrizeTier Updated PrizeTierV2 struct
     * @return drawId Draw ID of the PrizeTierV2 that was pushed
     */
    function popAndPush(PrizeTierV2 calldata newPrizeTier) external returns (uint32 drawId);

    /**
     * @notice Returns the number of Prize Tier structs pushed
     * @return The number of prize tiers that have been pushed
     */
    function count() external view returns (uint256);

    /**
     * @notice Read PrizeTierHistory struct from history array.
     * @param drawId Draw ID
     * @return prizeTier
     */
    function getPrizeTier(uint32 drawId) external view returns (PrizeTierV2 memory prizeTier);

    /**
     * @notice Read PrizeTierV2 struct using Draw ID as the input
     * @param drawIds Draw ID
     * @return prizeTierList PrizeTierV2[] - Parameters to calculate PrizeDistrubtion
     */
    function getPrizeTierList(uint32[] calldata drawIds)
        external
        view
        returns (PrizeTierV2[] memory prizeTierList);

    /**
     * @notice Get prize tier at the specified `index`.
     * @param index Index at which to get the prize tier
     * @return PrizeTier at `index`
     */
    function getPrizeTierAtIndex(uint256 index) external view returns (PrizeTierV2 memory);

    /**
     * @notice Read first Draw ID used to initialize history
     * @return Draw ID of first PrizeTierV2 record
     */
    function getOldestDrawId() external view returns (uint32);

    /**
     * @notice Read last Draw ID stored in the history.
     * @return Draw ID of the last recorded PrizeTier record
     */
    function getNewestDrawId() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "./interfaces/IDrawBeacon.sol";
import "./interfaces/IDrawBuffer.sol";


/**
  * @title  PoolTogether V4 DrawBeacon
  * @author PoolTogether Inc Team
  * @notice Manages RNG (random number generator) requests and pushing Draws onto DrawBuffer.
            The DrawBeacon has 3 major actions for requesting a random number: start, cancel and complete.
            To create a new Draw, the user requests a new random number from the RNG service.
            When the random number is available, the user can create the draw using the create() method
            which will push the draw onto the DrawBuffer.
            If the RNG service fails to deliver a rng, when the request timeout elapses, the user can cancel the request.
*/
contract DrawBeacon is IDrawBeacon, Ownable {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /* ============ Variables ============ */

    /// @notice RNG contract interface
    RNGInterface internal rng;

    /// @notice Current RNG Request
    RngRequest internal rngRequest;

    /// @notice DrawBuffer address
    IDrawBuffer internal drawBuffer;

    /**
     * @notice RNG Request Timeout.  In fact, this is really a "complete draw" timeout.
     * @dev If the rng completes the award can still be cancelled.
     */
    uint32 internal rngTimeout;

    /// @notice Seconds between beacon period request
    uint32 internal beaconPeriodSeconds;

    /// @notice Epoch timestamp when beacon period can start
    uint64 internal beaconPeriodStartedAt;

    /**
     * @notice Next Draw ID to use when pushing a Draw onto DrawBuffer
     * @dev Starts at 1. This way we know that no Draw has been recorded at 0.
     */
    uint32 internal nextDrawId;

    /* ============ Structs ============ */

    /**
     * @notice RNG Request
     * @param id          RNG request ID
     * @param lockBlock   Block number that the RNG request is locked
     * @param requestedAt Time when RNG is requested
     */
    struct RngRequest {
        uint32 id;
        uint32 lockBlock;
        uint64 requestedAt;
    }

    /* ============ Events ============ */

    /**
     * @notice Emit when the DrawBeacon is deployed.
     * @param nextDrawId Draw ID at which the DrawBeacon should start. Can't be inferior to 1.
     * @param beaconPeriodStartedAt Timestamp when beacon period starts.
     */
    event Deployed(
        uint32 nextDrawId,
        uint64 beaconPeriodStartedAt
    );

    /* ============ Modifiers ============ */

    modifier requireDrawNotStarted() {
        _requireDrawNotStarted();
        _;
    }

    modifier requireCanStartDraw() {
        require(_isBeaconPeriodOver(), "DrawBeacon/beacon-period-not-over");
        require(!isRngRequested(), "DrawBeacon/rng-already-requested");
        _;
    }

    modifier requireCanCompleteRngRequest() {
        require(isRngRequested(), "DrawBeacon/rng-not-requested");
        require(isRngCompleted(), "DrawBeacon/rng-not-complete");
        _;
    }

    /* ============ Constructor ============ */

    /**
     * @notice Deploy the DrawBeacon smart contract.
     * @param _owner Address of the DrawBeacon owner
     * @param _drawBuffer The address of the draw buffer to push draws to
     * @param _rng The RNG service to use
     * @param _nextDrawId Draw ID at which the DrawBeacon should start. Can't be inferior to 1.
     * @param _beaconPeriodStart The starting timestamp of the beacon period.
     * @param _beaconPeriodSeconds The duration of the beacon period in seconds
     */
    constructor(
        address _owner,
        IDrawBuffer _drawBuffer,
        RNGInterface _rng,
        uint32 _nextDrawId,
        uint64 _beaconPeriodStart,
        uint32 _beaconPeriodSeconds,
        uint32 _rngTimeout
    ) Ownable(_owner) {
        require(_beaconPeriodStart > 0, "DrawBeacon/beacon-period-greater-than-zero");
        require(address(_rng) != address(0), "DrawBeacon/rng-not-zero");
        require(_nextDrawId >= 1, "DrawBeacon/next-draw-id-gte-one");

        beaconPeriodStartedAt = _beaconPeriodStart;
        nextDrawId = _nextDrawId;

        _setBeaconPeriodSeconds(_beaconPeriodSeconds);
        _setDrawBuffer(_drawBuffer);
        _setRngService(_rng);
        _setRngTimeout(_rngTimeout);

        emit Deployed(_nextDrawId, _beaconPeriodStart);
        emit BeaconPeriodStarted(_beaconPeriodStart);
    }

    /* ============ Public Functions ============ */

    /**
     * @notice Returns whether the random number request has completed.
     * @return True if a random number request has completed, false otherwise.
     */
    function isRngCompleted() public view override returns (bool) {
        return rng.isRequestComplete(rngRequest.id);
    }

    /**
     * @notice Returns whether a random number has been requested
     * @return True if a random number has been requested, false otherwise.
     */
    function isRngRequested() public view override returns (bool) {
        return rngRequest.id != 0;
    }

    /**
     * @notice Returns whether the random number request has timed out.
     * @return True if a random number request has timed out, false otherwise.
     */
    function isRngTimedOut() public view override returns (bool) {
        if (rngRequest.requestedAt == 0) {
            return false;
        } else {
            return rngTimeout + rngRequest.requestedAt < _currentTime();
        }
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawBeacon
    function canStartDraw() external view override returns (bool) {
        return _isBeaconPeriodOver() && !isRngRequested();
    }

    /// @inheritdoc IDrawBeacon
    function canCompleteDraw() external view override returns (bool) {
        return isRngRequested() && isRngCompleted();
    }

    /// @notice Calculates the next beacon start time, assuming all beacon periods have occurred between the last and now.
    /// @return The next beacon period start time
    function calculateNextBeaconPeriodStartTimeFromCurrentTime() external view returns (uint64) {
        return
            _calculateNextBeaconPeriodStartTime(
                beaconPeriodStartedAt,
                beaconPeriodSeconds,
                _currentTime()
            );
    }

    /// @inheritdoc IDrawBeacon
    function calculateNextBeaconPeriodStartTime(uint64 _time)
        external
        view
        override
        returns (uint64)
    {
        return
            _calculateNextBeaconPeriodStartTime(
                beaconPeriodStartedAt,
                beaconPeriodSeconds,
                _time
            );
    }

    /// @inheritdoc IDrawBeacon
    function cancelDraw() external override {
        require(isRngTimedOut(), "DrawBeacon/rng-not-timedout");
        uint32 requestId = rngRequest.id;
        uint32 lockBlock = rngRequest.lockBlock;
        delete rngRequest;
        emit DrawCancelled(requestId, lockBlock);
    }

    /// @inheritdoc IDrawBeacon
    function completeDraw() external override requireCanCompleteRngRequest {
        uint256 randomNumber = rng.randomNumber(rngRequest.id);
        uint32 _nextDrawId = nextDrawId;
        uint64 _beaconPeriodStartedAt = beaconPeriodStartedAt;
        uint32 _beaconPeriodSeconds = beaconPeriodSeconds;
        uint64 _time = _currentTime();

        // create Draw struct
        IDrawBeacon.Draw memory _draw = IDrawBeacon.Draw({
            winningRandomNumber: randomNumber,
            drawId: _nextDrawId,
            timestamp: rngRequest.requestedAt, // must use the startAward() timestamp to prevent front-running
            beaconPeriodStartedAt: _beaconPeriodStartedAt,
            beaconPeriodSeconds: _beaconPeriodSeconds
        });

        drawBuffer.pushDraw(_draw);

        // to avoid clock drift, we should calculate the start time based on the previous period start time.
        uint64 nextBeaconPeriodStartedAt = _calculateNextBeaconPeriodStartTime(
            _beaconPeriodStartedAt,
            _beaconPeriodSeconds,
            _time
        );
        beaconPeriodStartedAt = nextBeaconPeriodStartedAt;
        nextDrawId = _nextDrawId + 1;

        // Reset the rngRequest state so Beacon period can start again.
        delete rngRequest;

        emit DrawCompleted(randomNumber);
        emit BeaconPeriodStarted(nextBeaconPeriodStartedAt);
    }

    /// @inheritdoc IDrawBeacon
    function beaconPeriodRemainingSeconds() external view override returns (uint64) {
        return _beaconPeriodRemainingSeconds();
    }

    /// @inheritdoc IDrawBeacon
    function beaconPeriodEndAt() external view override returns (uint64) {
        return _beaconPeriodEndAt();
    }

    function getBeaconPeriodSeconds() external view returns (uint32) {
        return beaconPeriodSeconds;
    }

    function getBeaconPeriodStartedAt() external view returns (uint64) {
        return beaconPeriodStartedAt;
    }

    function getDrawBuffer() external view returns (IDrawBuffer) {
        return drawBuffer;
    }

    function getNextDrawId() external view returns (uint32) {
        return nextDrawId;
    }

    /// @inheritdoc IDrawBeacon
    function getLastRngLockBlock() external view override returns (uint32) {
        return rngRequest.lockBlock;
    }

    function getLastRngRequestId() external view override returns (uint32) {
        return rngRequest.id;
    }

    function getRngService() external view returns (RNGInterface) {
        return rng;
    }

    function getRngTimeout() external view returns (uint32) {
        return rngTimeout;
    }

    /// @inheritdoc IDrawBeacon
    function isBeaconPeriodOver() external view override returns (bool) {
        return _isBeaconPeriodOver();
    }

    /// @inheritdoc IDrawBeacon
    function setDrawBuffer(IDrawBuffer newDrawBuffer)
        external
        override
        onlyOwner
        returns (IDrawBuffer)
    {
        return _setDrawBuffer(newDrawBuffer);
    }

    /// @inheritdoc IDrawBeacon
    function startDraw() external override requireCanStartDraw {
        (address feeToken, uint256 requestFee) = rng.getRequestFee();

        if (feeToken != address(0) && requestFee > 0) {
            IERC20(feeToken).safeIncreaseAllowance(address(rng), requestFee);
        }

        (uint32 requestId, uint32 lockBlock) = rng.requestRandomNumber();
        rngRequest.id = requestId;
        rngRequest.lockBlock = lockBlock;
        rngRequest.requestedAt = _currentTime();

        emit DrawStarted(requestId, lockBlock);
    }

    /// @inheritdoc IDrawBeacon
    function setBeaconPeriodSeconds(uint32 _beaconPeriodSeconds)
        external
        override
        onlyOwner
        requireDrawNotStarted
    {
        _setBeaconPeriodSeconds(_beaconPeriodSeconds);
    }

    /// @inheritdoc IDrawBeacon
    function setRngTimeout(uint32 _rngTimeout) external override onlyOwner requireDrawNotStarted {
        _setRngTimeout(_rngTimeout);
    }

    /// @inheritdoc IDrawBeacon
    function setRngService(RNGInterface _rngService)
        external
        override
        onlyOwner
        requireDrawNotStarted
    {
        _setRngService(_rngService);
    }

    /**
     * @notice Sets the RNG service that the Prize Strategy is connected to
     * @param _rngService The address of the new RNG service interface
     */
    function _setRngService(RNGInterface _rngService) internal
    {
        rng = _rngService;
        emit RngServiceUpdated(_rngService);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculates when the next beacon period will start
     * @param _beaconPeriodStartedAt The timestamp at which the beacon period started
     * @param _beaconPeriodSeconds The duration of the beacon period in seconds
     * @param _time The timestamp to use as the current time
     * @return The timestamp at which the next beacon period would start
     */
    function _calculateNextBeaconPeriodStartTime(
        uint64 _beaconPeriodStartedAt,
        uint32 _beaconPeriodSeconds,
        uint64 _time
    ) internal pure returns (uint64) {
        uint64 elapsedPeriods = (_time - _beaconPeriodStartedAt) / _beaconPeriodSeconds;
        return _beaconPeriodStartedAt + (elapsedPeriods * _beaconPeriodSeconds);
    }

    /**
     * @notice returns the current time.  Used for testing.
     * @return The current time (block.timestamp)
     */
    function _currentTime() internal view virtual returns (uint64) {
        return uint64(block.timestamp);
    }

    /**
     * @notice Returns the timestamp at which the beacon period ends
     * @return The timestamp at which the beacon period ends
     */
    function _beaconPeriodEndAt() internal view returns (uint64) {
        return beaconPeriodStartedAt + beaconPeriodSeconds;
    }

    /**
     * @notice Returns the number of seconds remaining until the prize can be awarded.
     * @return The number of seconds remaining until the prize can be awarded.
     */
    function _beaconPeriodRemainingSeconds() internal view returns (uint64) {
        uint64 endAt = _beaconPeriodEndAt();
        uint64 time = _currentTime();

        if (endAt <= time) {
            return 0;
        }

        return endAt - time;
    }

    /**
     * @notice Returns whether the beacon period is over.
     * @return True if the beacon period is over, false otherwise
     */
    function _isBeaconPeriodOver() internal view returns (bool) {
        return _beaconPeriodEndAt() <= _currentTime();
    }

    /**
     * @notice Check to see draw is in progress.
     */
    function _requireDrawNotStarted() internal view {
        uint256 currentBlock = block.number;

        require(
            rngRequest.lockBlock == 0 || currentBlock < rngRequest.lockBlock,
            "DrawBeacon/rng-in-flight"
        );
    }

    /**
     * @notice Set global DrawBuffer variable.
     * @dev    All subsequent Draw requests/completions will be pushed to the new DrawBuffer.
     * @param _newDrawBuffer  DrawBuffer address
     * @return DrawBuffer
     */
    function _setDrawBuffer(IDrawBuffer _newDrawBuffer) internal returns (IDrawBuffer) {
        IDrawBuffer _previousDrawBuffer = drawBuffer;
        require(address(_newDrawBuffer) != address(0), "DrawBeacon/draw-history-not-zero-address");

        require(
            address(_newDrawBuffer) != address(_previousDrawBuffer),
            "DrawBeacon/existing-draw-history-address"
        );

        drawBuffer = _newDrawBuffer;

        emit DrawBufferUpdated(_newDrawBuffer);

        return _newDrawBuffer;
    }

    /**
     * @notice Sets the beacon period in seconds.
     * @param _beaconPeriodSeconds The new beacon period in seconds.  Must be greater than zero.
     */
    function _setBeaconPeriodSeconds(uint32 _beaconPeriodSeconds) internal {
        require(_beaconPeriodSeconds > 0, "DrawBeacon/beacon-period-greater-than-zero");
        beaconPeriodSeconds = _beaconPeriodSeconds;

        emit BeaconPeriodSecondsUpdated(_beaconPeriodSeconds);
    }

    /**
     * @notice Sets the RNG request timeout in seconds.  This is the time that must elapsed before the RNG request can be cancelled and the pool unlocked.
     * @param _rngTimeout The RNG request timeout in seconds.
     */
    function _setRngTimeout(uint32 _rngTimeout) internal {
        require(_rngTimeout > 60, "DrawBeacon/rng-timeout-gt-60-secs");
        rngTimeout = _rngTimeout;

        emit RngTimeoutSet(_rngTimeout);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IPrizeTierHistoryV2.sol";
import "./libraries/BinarySearchLib.sol";

/**
 * @title  PoolTogether V4 PrizeTierHistoryV2
 * @author PoolTogether Inc Team
 * @notice The PrizeTierHistoryV2 smart contract stores a history of PrizeTierV2 structs linked to
           a range of valid Draw IDs.
 * @dev    If the history param has single PrizeTierV2 struct with a "drawId" of 1 all subsequent
           Draws will use that PrizeTierV2 struct for PrizeDitribution calculations. The BinarySearchLib
           will find a PrizeTierV2 using a "atOrBefore" range search when supplied drawId input parameter.
 */
contract PrizeTierHistoryV2 is IPrizeTierHistoryV2, Manageable {
    using BinarySearchLib for uint32[];

    /**
     * @notice Ordered array of Draw IDs
     * @dev The history, with sequentially ordered ids, can be searched using binary search.
            The binary search will find index of a drawId (atOrBefore) using a specific drawId (at).
            When a new Draw ID is added to the history, a corresponding mapping of the ID is
            updated in the prizeTiers mapping.
    */
    uint32[] internal history;

    /**
     * @notice Mapping a Draw ID to a PrizeTierV2 struct.
     * @dev The prizeTiers mapping links a Draw ID to a PrizeTierV2 struct.
            The prizeTiers mapping is updated when a new Draw ID is added to the history.
    */
    mapping(uint32 => PrizeTierV2) internal prizeTiers;

    /**
     * @notice Ceiling for the dpr and total sum of tiers from the prize distribution. 1e9 = 100%.
     * @dev It's fixed point 9 because 1e9 is the largest "1" that fits into 2**32
     */
    uint256 internal constant CEILING = 1e9;

    /**
     * @notice PrizeTierHistoryV2 constructor
     * @param _owner Address of the contract owner
     */
    constructor(address _owner) Ownable(_owner) {}

    // @inheritdoc IPrizeTierHistoryV2
    function count() external view override returns (uint256) {
        return history.length;
    }

    // @inheritdoc IPrizeTierHistoryV2
    function getOldestDrawId() external view override returns (uint32) {
        return history[0];
    }

    // @inheritdoc IPrizeTierHistoryV2
    function getNewestDrawId() external view override returns (uint32) {
        return history[history.length - 1];
    }

    // @inheritdoc IPrizeTierHistoryV2
    function getPrizeTier(uint32 drawId) external view override returns (PrizeTierV2 memory) {
        require(drawId > 0, "PTH/draw-id-not-zero");
        return prizeTiers[history.binarySearch(drawId)];
    }

    // @inheritdoc IPrizeTierHistoryV2
    function getPrizeTierList(uint32[] calldata _drawIds)
        external
        view
        override
        returns (PrizeTierV2[] memory)
    {
        uint256 _length = _drawIds.length;
        PrizeTierV2[] memory _data = new PrizeTierV2[](_length);
        for (uint256 index = 0; index < _length; index++) {
            _data[index] = prizeTiers[history.binarySearch(_drawIds[index])];
        }
        return _data;
    }

    // @inheritdoc IPrizeTierHistoryV2
    function getPrizeTierAtIndex(uint256 index)
        external
        view
        override
        returns (PrizeTierV2 memory)
    {
        return prizeTiers[uint32(index)];
    }

    // @inheritdoc IPrizeTierHistoryV2
    function push(PrizeTierV2 calldata nextPrizeTier) external override onlyManagerOrOwner {
        _push(nextPrizeTier);
    }

    // @inheritdoc IPrizeTierHistoryV2
    function popAndPush(PrizeTierV2 calldata newPrizeTier)
        external
        override
        onlyOwner
        returns (uint32)
    {
        uint256 length = history.length;
        require(length > 0, "PTH/history-empty");
        require(history[length - 1] == newPrizeTier.drawId, "PTH/invalid-draw-id");
        _replace(newPrizeTier);
        return newPrizeTier.drawId;
    }

    // @inheritdoc IPrizeTierHistoryV2
    function replace(PrizeTierV2 calldata newPrizeTier) external override onlyOwner {
        _replace(newPrizeTier);
    }

    /**
     * @notice Check that the Draw Percentage Rate (DPR) is not greater than 1e9 (100%).
     * @param  _dpr DPR to check
     */
    function _checkDPR(uint32 _dpr) internal pure {
        require(_dpr <= CEILING, "PTH/dpr-gt-100%");
    }

    /**
     * @notice Check that the total sum of the tiers is not greater than 1e9 (100%).
     * @param  _tiers Array of tiers to check
     */
    function _checkTiersTotalSum(uint32[16] memory _tiers) internal pure {
        uint256 tiersTotalSum;
        uint256 tiersLength = _tiers.length;

        for (uint256 index; index < tiersLength; index++) {
            tiersTotalSum += _tiers[index];
        }

        require(tiersTotalSum <= CEILING, "PTH/tiers-gt-100%");
    }

    /**
     * @notice Push PrizeTierV2 struct onto `prizeTiers` array.
     * @dev Callable only by the owner or manager.
     * @dev `drawId` must be greater than the latest one stored in `history`.
     * @param _prizeTier Next PrizeTierV2 struct
     */
    function _push(PrizeTierV2 memory _prizeTier) internal {
        uint32 _length = uint32(history.length);

        if (_length > 0) {
            uint32 _id = history[_length - 1];
            require(_prizeTier.drawId > _id, "PTH/non-sequential-id");
        }

        _checkDPR(_prizeTier.dpr);
        _checkTiersTotalSum(_prizeTier.tiers);

        history.push(_prizeTier.drawId);
        prizeTiers[_length] = _prizeTier;

        emit PrizeTierPushed(_prizeTier.drawId, _prizeTier);
    }

    /**
     * @notice Replace PrizeTierV2 struct in `prizeTiers` array.
     * @dev Callable only by the owner.
     * @param _prizeTier PrizeTierV2 parameters
     */
    function _replace(PrizeTierV2 calldata _prizeTier) internal {
        uint256 cardinality = history.length;
        require(cardinality > 0, "PTH/no-prize-tiers");

        uint32 oldestDrawId = history[0];
        require(_prizeTier.drawId >= oldestDrawId, "PTH/draw-id-out-of-range");

        uint32 index = history.binarySearch(_prizeTier.drawId);
        require(history[index] == _prizeTier.drawId, "PTH/draw-id-must-match");

        _checkDPR(_prizeTier.dpr);
        _checkTiersTotalSum(_prizeTier.tiers);

        prizeTiers[index] = _prizeTier;

        emit PrizeTierSet(_prizeTier.drawId, _prizeTier);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 BinarySearchLib
 * @author PoolTogether Inc Team
 * @notice BinarySearchLib uses binary search to find a parent contract struct with the drawId parameter
 * @dev    The implementing contract must provider access to a struct (i.e. PrizeTier) list with is both
 *         sorted and indexed by the drawId field for binary search to work.
 */
library BinarySearchLib {

    /**
     * @notice Find ID in array of ordered IDs using Binary Search.
        * @param _history uin32[] - Array of IDsq
        * @param _drawId uint32 - Draw ID to search for
        * @return uint32 - Index of ID in array
     */
    function binarySearch(uint32[] storage _history, uint32 _drawId) internal view returns (uint32) {
        uint32 index;
        uint32 leftSide = 0;
        uint32 rightSide = uint32(_history.length - 1);

        uint32 oldestDrawId = _history[0];
        uint32 newestDrawId = _history[rightSide];

        require(_drawId >= oldestDrawId, "BinarySearchLib/draw-id-out-of-range");
        if (_drawId >= newestDrawId) return rightSide;
        if (_drawId == oldestDrawId) return leftSide;

        while (true) {
            uint32 length = rightSide - leftSide;
            uint32 center = leftSide + (length / 2);
            uint32 centerID = _history[center];

            if (centerID == _drawId) {
                index = center;
                break;
            }

            if (length <= 1) {
                if(_history[rightSide] <= _drawId) {
                    index = rightSide;
                } else {
                    index = leftSide;
                }
                break;
            }

            if (centerID < _drawId) {
                leftSide = center;
            } else {
                rightSide = center - 1;
            }
        }

        return index;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-periphery/contracts/PrizeTierHistoryV2.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/DrawBeacon.sol';

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";
import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 L1TimelockTrigger
  * @author PoolTogether Inc Team
  * @notice L1TimelockTrigger(s) acts as an intermediary between multiple V4 smart contracts.
            The L1TimelockTrigger is responsible for pushing Draws to a DrawBuffer and routing
            claim requests from a PrizeDistributor to a DrawCalculator. The primary objective is
            to  include a "cooldown" period for all new Draws. Allowing the correction of a
            malicously set Draw in the unfortunate event an Owner is compromised.
*/
contract L1TimelockTrigger is Manageable {
    /* ============ Events ============ */

    /// @notice Emitted when the contract is deployed.
    /// @param prizeDistributionBuffer The address of the prize distribution buffer contract.
    /// @param timelock The address of the DrawCalculatorTimelock
    event Deployed(
        IPrizeDistributionBuffer indexed prizeDistributionBuffer,
        IDrawCalculatorTimelock indexed timelock
    );

    /**
     * @notice Emitted when target prize distribution is pushed.
     * @param drawId    Draw ID
     * @param prizeDistribution PrizeDistribution
     */
    event PrizeDistributionPushed(
        uint32 indexed drawId,
        IPrizeDistributionBuffer.PrizeDistribution prizeDistribution
    );

    /* ============ Global Variables ============ */

    /// @notice Internal PrizeDistributionBuffer reference.
    IPrizeDistributionBuffer public immutable prizeDistributionBuffer;

    /// @notice Timelock struct reference.
    IDrawCalculatorTimelock public timelock;

    /* ============ Deploy ============ */

    /**
     * @notice Initialize L1TimelockTrigger smart contract.
     * @param _owner                    Address of the L1TimelockTrigger owner.
     * @param _prizeDistributionBuffer PrizeDistributionBuffer address
     * @param _timelock                 Elapsed seconds before new Draw is available
     */
    constructor(
        address _owner,
        IPrizeDistributionBuffer _prizeDistributionBuffer,
        IDrawCalculatorTimelock _timelock
    ) Ownable(_owner) {
        prizeDistributionBuffer = _prizeDistributionBuffer;
        timelock = _timelock;

        emit Deployed(_prizeDistributionBuffer, _timelock);
    }

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Restricts new draws by forcing a push timelock.
     * @param _draw Draw struct
     * @param _prizeDistribution PrizeDistribution struct
     */
    function push(
        IDrawBeacon.Draw calldata _draw,
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution
    ) external onlyManagerOrOwner {
        // Locks the new PrizeDistribution according to the Draw endtime.
        timelock.lock(_draw.drawId, _draw.timestamp + _draw.beaconPeriodSeconds);
        prizeDistributionBuffer.pushPrizeDistribution(_draw.drawId, _prizeDistribution);
        emit PrizeDistributionPushed(_draw.drawId, _prizeDistribution);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-timelocks/contracts/L1TimelockTrigger.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/PrizeDistributionBuffer.sol';

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IDrawBuffer.sol";
import "./interfaces/IDrawBeacon.sol";
import "./libraries/DrawRingBufferLib.sol";

/**
  * @title  PoolTogether V4 DrawBuffer
  * @author PoolTogether Inc Team
  * @notice The DrawBuffer provides historical lookups of Draws via a circular ring buffer.
            Historical Draws can be accessed on-chain using a drawId to calculate ring buffer storage slot.
            The Draw settings can be created by manager/owner and existing Draws can only be updated the owner.
            Once a starting Draw has been added to the ring buffer, all following draws must have a sequential Draw ID.
    @dev    A DrawBuffer store a limited number of Draws before beginning to overwrite (managed via the cardinality) previous Draws.
    @dev    All mainnet DrawBuffer(s) are updated directly from a DrawBeacon, but non-mainnet DrawBuffer(s) (Matic, Optimism, Arbitrum, etc...)
            will receive a cross-chain message, duplicating the mainnet Draw configuration - enabling a prize savings liquidity network.
*/
contract DrawBuffer is IDrawBuffer, Manageable {
    using DrawRingBufferLib for DrawRingBufferLib.Buffer;

    /// @notice Draws ring buffer max length.
    uint16 public constant MAX_CARDINALITY = 256;

    /// @notice Draws ring buffer array.
    IDrawBeacon.Draw[MAX_CARDINALITY] private drawRingBuffer;

    /// @notice Holds ring buffer information
    DrawRingBufferLib.Buffer internal bufferMetadata;

    /* ============ Deploy ============ */

    /**
     * @notice Deploy DrawBuffer smart contract.
     * @param _owner Address of the owner of the DrawBuffer.
     * @param _cardinality Draw ring buffer cardinality.
     */
    constructor(address _owner, uint8 _cardinality) Ownable(_owner) {
        bufferMetadata.cardinality = _cardinality;
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawBuffer
    function getBufferCardinality() external view override returns (uint32) {
        return bufferMetadata.cardinality;
    }

    /// @inheritdoc IDrawBuffer
    function getDraw(uint32 drawId) external view override returns (IDrawBeacon.Draw memory) {
        return drawRingBuffer[_drawIdToDrawIndex(bufferMetadata, drawId)];
    }

    /// @inheritdoc IDrawBuffer
    function getDraws(uint32[] calldata _drawIds)
        external
        view
        override
        returns (IDrawBeacon.Draw[] memory)
    {
        IDrawBeacon.Draw[] memory draws = new IDrawBeacon.Draw[](_drawIds.length);
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        for (uint256 index = 0; index < _drawIds.length; index++) {
            draws[index] = drawRingBuffer[_drawIdToDrawIndex(buffer, _drawIds[index])];
        }

        return draws;
    }

    /// @inheritdoc IDrawBuffer
    function getDrawCount() external view override returns (uint32) {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        if (buffer.lastDrawId == 0) {
            return 0;
        }

        uint32 bufferNextIndex = buffer.nextIndex;

        if (drawRingBuffer[bufferNextIndex].timestamp != 0) {
            return buffer.cardinality;
        } else {
            return bufferNextIndex;
        }
    }

    /// @inheritdoc IDrawBuffer
    function getNewestDraw() external view override returns (IDrawBeacon.Draw memory) {
        return _getNewestDraw(bufferMetadata);
    }

    /// @inheritdoc IDrawBuffer
    function getOldestDraw() external view override returns (IDrawBeacon.Draw memory) {
        // oldest draw should be next available index, otherwise it's at 0
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        IDrawBeacon.Draw memory draw = drawRingBuffer[buffer.nextIndex];

        if (draw.timestamp == 0) {
            // if draw is not init, then use draw at 0
            draw = drawRingBuffer[0];
        }

        return draw;
    }

    /// @inheritdoc IDrawBuffer
    function pushDraw(IDrawBeacon.Draw memory _draw)
        external
        override
        onlyManagerOrOwner
        returns (uint32)
    {
        return _pushDraw(_draw);
    }

    /// @inheritdoc IDrawBuffer
    function setDraw(IDrawBeacon.Draw memory _newDraw) external override onlyOwner returns (uint32) {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        uint32 index = buffer.getIndex(_newDraw.drawId);
        drawRingBuffer[index] = _newDraw;
        emit DrawSet(_newDraw.drawId, _newDraw);
        return _newDraw.drawId;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Convert a Draw.drawId to a Draws ring buffer index pointer.
     * @dev    The getNewestDraw.drawId() is used to calculate a Draws ID delta position.
     * @param _drawId Draw.drawId
     * @return Draws ring buffer index pointer
     */
    function _drawIdToDrawIndex(DrawRingBufferLib.Buffer memory _buffer, uint32 _drawId)
        internal
        pure
        returns (uint32)
    {
        return _buffer.getIndex(_drawId);
    }

    /**
     * @notice Read newest Draw from the draws ring buffer.
     * @dev    Uses the lastDrawId to calculate the most recently added Draw.
     * @param _buffer Draw ring buffer
     * @return IDrawBeacon.Draw
     */
    function _getNewestDraw(DrawRingBufferLib.Buffer memory _buffer)
        internal
        view
        returns (IDrawBeacon.Draw memory)
    {
        return drawRingBuffer[_buffer.getIndex(_buffer.lastDrawId)];
    }

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Push new draw onto draws list via authorized manager or owner.
     * @param _newDraw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function _pushDraw(IDrawBeacon.Draw memory _newDraw) internal returns (uint32) {
        DrawRingBufferLib.Buffer memory _buffer = bufferMetadata;
        drawRingBuffer[_buffer.nextIndex] = _newDraw;
        bufferMetadata = _buffer.push(_newDraw.drawId);

        emit DrawSet(_newDraw.drawId, _newDraw);

        return _newDraw.drawId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/DrawBuffer.sol';

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./interfaces/IDrawCalculator.sol";
import "./interfaces/ITicket.sol";
import "./interfaces/IDrawBuffer.sol";
import "./interfaces/IPrizeDistributionBuffer.sol";
import "./interfaces/IDrawBeacon.sol";

/**
  * @title  PoolTogether V4 DrawCalculator
  * @author PoolTogether Inc Team
  * @notice The DrawCalculator calculates a user's prize by matching a winning random number against
            their picks. A users picks are generated deterministically based on their address and balance
            of tickets held. Prize payouts are divided into multiple tiers: grand prize, second place, etc...
            A user with a higher average weighted balance (during each draw period) will be given a large number of
            picks to choose from, and thus a higher chance to match the winning numbers.
*/
contract DrawCalculator is IDrawCalculator {

    /// @notice DrawBuffer address
    IDrawBuffer public immutable drawBuffer;

    /// @notice Ticket associated with DrawCalculator
    ITicket public immutable ticket;

    /// @notice The stored history of draw settings.  Stored as ring buffer.
    IPrizeDistributionBuffer public immutable prizeDistributionBuffer;

    /// @notice The tiers array length
    uint8 public constant TIERS_LENGTH = 16;

    /* ============ Constructor ============ */

    /// @notice Constructor for DrawCalculator
    /// @param _ticket Ticket associated with this DrawCalculator
    /// @param _drawBuffer The address of the draw buffer to push draws to
    /// @param _prizeDistributionBuffer PrizeDistributionBuffer address
    constructor(
        ITicket _ticket,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) {
        require(address(_ticket) != address(0), "DrawCalc/ticket-not-zero");
        require(address(_prizeDistributionBuffer) != address(0), "DrawCalc/pdb-not-zero");
        require(address(_drawBuffer) != address(0), "DrawCalc/dh-not-zero");

        ticket = _ticket;
        drawBuffer = _drawBuffer;
        prizeDistributionBuffer = _prizeDistributionBuffer;

        emit Deployed(_ticket, _drawBuffer, _prizeDistributionBuffer);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawCalculator
    function calculate(
        address _user,
        uint32[] calldata _drawIds,
        bytes calldata _pickIndicesForDraws
    ) external view override returns (uint256[] memory, bytes memory) {
        uint64[][] memory pickIndices = abi.decode(_pickIndicesForDraws, (uint64 [][]));
        require(pickIndices.length == _drawIds.length, "DrawCalc/invalid-pick-indices-length");

        // READ list of IDrawBeacon.Draw using the drawIds from drawBuffer
        IDrawBeacon.Draw[] memory draws = drawBuffer.getDraws(_drawIds);

        // READ list of IPrizeDistributionBuffer.PrizeDistribution using the drawIds
        IPrizeDistributionBuffer.PrizeDistribution[] memory _prizeDistributions = prizeDistributionBuffer
            .getPrizeDistributions(_drawIds);

        // The userBalances are fractions representing their portion of the liquidity for a draw.
        uint256[] memory userBalances = _getNormalizedBalancesAt(_user, draws, _prizeDistributions);

        // The users address is hashed once.
        bytes32 _userRandomNumber = keccak256(abi.encodePacked(_user));

        return _calculatePrizesAwardable(
                userBalances,
                _userRandomNumber,
                draws,
                pickIndices,
                _prizeDistributions
            );
    }

    /// @inheritdoc IDrawCalculator
    function getDrawBuffer() external view override returns (IDrawBuffer) {
        return drawBuffer;
    }

    /// @inheritdoc IDrawCalculator
    function getPrizeDistributionBuffer()
        external
        view
        override
        returns (IPrizeDistributionBuffer)
    {
        return prizeDistributionBuffer;
    }

    /// @inheritdoc IDrawCalculator
    function getNormalizedBalancesForDrawIds(address _user, uint32[] calldata _drawIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        IDrawBeacon.Draw[] memory _draws = drawBuffer.getDraws(_drawIds);
        IPrizeDistributionBuffer.PrizeDistribution[] memory _prizeDistributions = prizeDistributionBuffer
            .getPrizeDistributions(_drawIds);

        return _getNormalizedBalancesAt(_user, _draws, _prizeDistributions);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculates the prizes awardable for each Draw passed.
     * @param _normalizedUserBalances Fractions representing the user's portion of the liquidity for each draw.
     * @param _userRandomNumber       Random number of the user to consider over draws
     * @param _draws                  List of Draws
     * @param _pickIndicesForDraws    Pick indices for each Draw
     * @param _prizeDistributions     PrizeDistribution for each Draw

     */
    function _calculatePrizesAwardable(
        uint256[] memory _normalizedUserBalances,
        bytes32 _userRandomNumber,
        IDrawBeacon.Draw[] memory _draws,
        uint64[][] memory _pickIndicesForDraws,
        IPrizeDistributionBuffer.PrizeDistribution[] memory _prizeDistributions
    ) internal view returns (uint256[] memory prizesAwardable, bytes memory prizeCounts) {

        uint256[] memory _prizesAwardable = new uint256[](_normalizedUserBalances.length);
        uint256[][] memory _prizeCounts = new uint256[][](_normalizedUserBalances.length);

        uint64 timeNow = uint64(block.timestamp);

        // calculate prizes awardable for each Draw passed
        for (uint32 drawIndex = 0; drawIndex < _draws.length; drawIndex++) {
            require(timeNow < _draws[drawIndex].timestamp + _prizeDistributions[drawIndex].expiryDuration, "DrawCalc/draw-expired");

            uint64 totalUserPicks = _calculateNumberOfUserPicks(
                _prizeDistributions[drawIndex],
                _normalizedUserBalances[drawIndex]
            );

            (_prizesAwardable[drawIndex], _prizeCounts[drawIndex]) = _calculate(
                _draws[drawIndex].winningRandomNumber,
                totalUserPicks,
                _userRandomNumber,
                _pickIndicesForDraws[drawIndex],
                _prizeDistributions[drawIndex]
            );
        }

        prizeCounts = abi.encode(_prizeCounts);
        prizesAwardable = _prizesAwardable;
    }

    /**
     * @notice Calculates the number of picks a user gets for a Draw, considering the normalized user balance and the PrizeDistribution.
     * @dev Divided by 1e18 since the normalized user balance is stored as a fixed point 18 number
     * @param _prizeDistribution The PrizeDistribution to consider
     * @param _normalizedUserBalance The normalized user balances to consider
     * @return The number of picks a user gets for a Draw
     */
    function _calculateNumberOfUserPicks(
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution,
        uint256 _normalizedUserBalance
    ) internal pure returns (uint64) {
        return uint64((_normalizedUserBalance * _prizeDistribution.numberOfPicks) / 1 ether);
    }

    /**
     * @notice Calculates the normalized balance of a user against the total supply for timestamps
     * @param _user The user to consider
     * @param _draws The draws we are looking at
     * @param _prizeDistributions The prize tiers to consider (needed for draw timestamp offsets)
     * @return An array of normalized balances
     */
    function _getNormalizedBalancesAt(
        address _user,
        IDrawBeacon.Draw[] memory _draws,
        IPrizeDistributionBuffer.PrizeDistribution[] memory _prizeDistributions
    ) internal view returns (uint256[] memory) {
        uint256 drawsLength = _draws.length;
        uint64[] memory _timestampsWithStartCutoffTimes = new uint64[](drawsLength);
        uint64[] memory _timestampsWithEndCutoffTimes = new uint64[](drawsLength);

        // generate timestamps with draw cutoff offsets included
        for (uint32 i = 0; i < drawsLength; i++) {
            unchecked {
                _timestampsWithStartCutoffTimes[i] =
                    _draws[i].timestamp - _prizeDistributions[i].startTimestampOffset;
                _timestampsWithEndCutoffTimes[i] =
                    _draws[i].timestamp - _prizeDistributions[i].endTimestampOffset;
            }
        }

        uint256[] memory balances = ticket.getAverageBalancesBetween(
            _user,
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256[] memory totalSupplies = ticket.getAverageTotalSuppliesBetween(
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256[] memory normalizedBalances = new uint256[](drawsLength);

        // divide balances by total supplies (normalize)
        for (uint256 i = 0; i < drawsLength; i++) {
            if(totalSupplies[i] == 0){
                normalizedBalances[i] = 0;
            }
            else {
                normalizedBalances[i] = (balances[i] * 1 ether) / totalSupplies[i];
            }
        }

        return normalizedBalances;
    }

    /**
     * @notice Calculates the prize amount for a PrizeDistribution over given picks
     * @param _winningRandomNumber Draw's winningRandomNumber
     * @param _totalUserPicks      number of picks the user gets for the Draw
     * @param _userRandomNumber    users randomNumber for that draw
     * @param _picks               users picks for that draw
     * @param _prizeDistribution   PrizeDistribution for that draw
     * @return prize (if any), prizeCounts (if any)
     */
    function _calculate(
        uint256 _winningRandomNumber,
        uint256 _totalUserPicks,
        bytes32 _userRandomNumber,
        uint64[] memory _picks,
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution
    ) internal pure returns (uint256 prize, uint256[] memory prizeCounts) {

        // create bitmasks for the PrizeDistribution
        uint256[] memory masks = _createBitMasks(_prizeDistribution);
        uint32 picksLength = uint32(_picks.length);
        uint256[] memory _prizeCounts = new uint256[](_prizeDistribution.tiers.length);

        uint8 maxWinningTierIndex = 0;

        require(
            picksLength <= _prizeDistribution.maxPicksPerUser,
            "DrawCalc/exceeds-max-user-picks"
        );

        // for each pick, find number of matching numbers and calculate prize distributions index
        for (uint32 index = 0; index < picksLength; index++) {
            require(_picks[index] < _totalUserPicks, "DrawCalc/insufficient-user-picks");

            if (index > 0) {
                require(_picks[index] > _picks[index - 1], "DrawCalc/picks-ascending");
            }

            // hash the user random number with the pick value
            uint256 randomNumberThisPick = uint256(
                keccak256(abi.encode(_userRandomNumber, _picks[index]))
            );

            uint8 tiersIndex = _calculateTierIndex(
                randomNumberThisPick,
                _winningRandomNumber,
                masks
            );

            // there is prize for this tier index
            if (tiersIndex < TIERS_LENGTH) {
                if (tiersIndex > maxWinningTierIndex) {
                    maxWinningTierIndex = tiersIndex;
                }
                _prizeCounts[tiersIndex]++;
            }
        }

        // now calculate prizeFraction given prizeCounts
        uint256 prizeFraction = 0;
        uint256[] memory prizeTiersFractions = _calculatePrizeTierFractions(
            _prizeDistribution,
            maxWinningTierIndex
        );

        // multiple the fractions by the prizeCounts and add them up
        for (
            uint256 prizeCountIndex = 0;
            prizeCountIndex <= maxWinningTierIndex;
            prizeCountIndex++
        ) {
            if (_prizeCounts[prizeCountIndex] > 0) {
                prizeFraction +=
                    prizeTiersFractions[prizeCountIndex] *
                    _prizeCounts[prizeCountIndex];
            }
        }

        // return the absolute amount of prize awardable
        // div by 1e9 as prize tiers are base 1e9
        prize = (prizeFraction * _prizeDistribution.prize) / 1e9;
        prizeCounts = _prizeCounts;
    }

    ///@notice Calculates the tier index given the random numbers and masks
    ///@param _randomNumberThisPick users random number for this Pick
    ///@param _winningRandomNumber The winning number for this draw
    ///@param _masks The pre-calculate bitmasks for the prizeDistributions
    ///@return The position within the prize tier array (0 = top prize, 1 = runner-up prize, etc)
    function _calculateTierIndex(
        uint256 _randomNumberThisPick,
        uint256 _winningRandomNumber,
        uint256[] memory _masks
    ) internal pure returns (uint8) {
        uint8 numberOfMatches = 0;
        uint8 masksLength = uint8(_masks.length);

        // main number matching loop
        for (uint8 matchIndex = 0; matchIndex < masksLength; matchIndex++) {
            uint256 mask = _masks[matchIndex];

            if ((_randomNumberThisPick & mask) != (_winningRandomNumber & mask)) {
                // there are no more sequential matches since this comparison is not a match
                if (masksLength == numberOfMatches) {
                    return 0;
                } else {
                    return masksLength - numberOfMatches;
                }
            }

            // else there was a match
            numberOfMatches++;
        }

        return masksLength - numberOfMatches;
    }

    /**
     * @notice Create an array of bitmasks equal to the PrizeDistribution.matchCardinality length
     * @param _prizeDistribution The PrizeDistribution to use to calculate the masks
     * @return An array of bitmasks
     */
    function _createBitMasks(IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory masks = new uint256[](_prizeDistribution.matchCardinality);
        masks[0] =  (2**_prizeDistribution.bitRangeSize) - 1;

        for (uint8 maskIndex = 1; maskIndex < _prizeDistribution.matchCardinality; maskIndex++) {
            // shift mask bits to correct position and insert in result mask array
            masks[maskIndex] = masks[maskIndex - 1] << _prizeDistribution.bitRangeSize;
        }

        return masks;
    }

    /**
     * @notice Calculates the expected prize fraction per PrizeDistributions and distributionIndex
     * @param _prizeDistribution prizeDistribution struct for Draw
     * @param _prizeTierIndex Index of the prize tiers array to calculate
     * @return returns the fraction of the total prize (fixed point 9 number)
     */
    function _calculatePrizeTierFraction(
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution,
        uint256 _prizeTierIndex
    ) internal pure returns (uint256) {
         // get the prize fraction at that index
        uint256 prizeFraction = _prizeDistribution.tiers[_prizeTierIndex];

        // calculate number of prizes for that index
        uint256 numberOfPrizesForIndex = _numberOfPrizesForIndex(
            _prizeDistribution.bitRangeSize,
            _prizeTierIndex
        );

        return prizeFraction / numberOfPrizesForIndex;
    }

    /**
     * @notice Generates an array of prize tiers fractions
     * @param _prizeDistribution prizeDistribution struct for Draw
     * @param maxWinningTierIndex Max length of the prize tiers array
     * @return returns an array of prize tiers fractions
     */
    function _calculatePrizeTierFractions(
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution,
        uint8 maxWinningTierIndex
    ) internal pure returns (uint256[] memory) {
        uint256[] memory prizeDistributionFractions = new uint256[](
            maxWinningTierIndex + 1
        );

        for (uint8 i = 0; i <= maxWinningTierIndex; i++) {
            prizeDistributionFractions[i] = _calculatePrizeTierFraction(
                _prizeDistribution,
                i
            );
        }

        return prizeDistributionFractions;
    }

    /**
     * @notice Calculates the number of prizes for a given prizeDistributionIndex
     * @param _bitRangeSize Bit range size for Draw
     * @param _prizeTierIndex Index of the prize tier array to calculate
     * @return returns the fraction of the total prize (base 1e18)
     */
    function _numberOfPrizesForIndex(uint8 _bitRangeSize, uint256 _prizeTierIndex)
        internal
        pure
        returns (uint256)
    {
        if (_prizeTierIndex > 0) {
            return ( 1 << _bitRangeSize * _prizeTierIndex ) - ( 1 << _bitRangeSize * (_prizeTierIndex - 1) );
        } else {
            return 1;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/DrawCalculator.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-periphery/contracts/PrizeDistributionFactoryV2.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/Reserve.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/Ticket.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/permit/EIP2612PermitAndDeposit.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-core/contracts/prize-pool/YieldSourcePrizePool.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-twab-delegator/contracts/TWABDelegator.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-timelocks/contracts/L2TimelockTrigger.sol';

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 OracleTimelock
  * @author PoolTogether Inc Team
  * @notice OracleTimelock(s) acts as an intermediary between multiple V4 smart contracts.
            The OracleTimelock is responsible for pushing Draws to a DrawBuffer and routing
            claim requests from a PrizeDistributor to a DrawCalculator. The primary objective is
            to include a "cooldown" period for all new Draws. Allowing the correction of a
            maliciously set Draw in the unfortunate event an Owner is compromised.
*/
contract DrawCalculatorTimelock is IDrawCalculatorTimelock, Manageable {
    /* ============ Global Variables ============ */

    /// @notice Internal DrawCalculator reference.
    IDrawCalculator internal immutable calculator;

    /// @notice Internal Timelock struct reference.
    Timelock internal timelock;

    /* ============ Events ============ */

    /**
     * @notice Deployed event when the constructor is called
     * @param drawCalculator DrawCalculator address bound to this timelock
     */
    event Deployed(IDrawCalculator indexed drawCalculator);

    /* ============ Deploy ============ */

    /**
     * @notice Initialize DrawCalculatorTimelockTrigger smart contract.
     * @param _owner                       Address of the DrawCalculator owner.
     * @param _calculator                 DrawCalculator address.
     */
    constructor(address _owner, IDrawCalculator _calculator) Ownable(_owner) {
        calculator = _calculator;

        emit Deployed(_calculator);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawCalculatorTimelock
    function calculate(
        address user,
        uint32[] calldata drawIds,
        bytes calldata data
    ) external view override returns (uint256[] memory, bytes memory) {
        Timelock memory _timelock = timelock;

        for (uint256 i = 0; i < drawIds.length; i++) {
            // if draw id matches timelock and not expired, revert
            if (drawIds[i] == _timelock.drawId) {
                _requireTimelockElapsed(_timelock);
            }
        }

        return calculator.calculate(user, drawIds, data);
    }

    /// @inheritdoc IDrawCalculatorTimelock
    function lock(uint32 _drawId, uint64 _timestamp)
        external
        override
        onlyManagerOrOwner
        returns (bool)
    {
        Timelock memory _timelock = timelock;
        require(_drawId == _timelock.drawId + 1, "OM/not-drawid-plus-one");

        _requireTimelockElapsed(_timelock);
        timelock = Timelock({ drawId: _drawId, timestamp: _timestamp });
        emit LockedDraw(_drawId, _timestamp);

        return true;
    }

    /// @inheritdoc IDrawCalculatorTimelock
    function getDrawCalculator() external view override returns (IDrawCalculator) {
        return calculator;
    }

    /// @inheritdoc IDrawCalculatorTimelock
    function getTimelock() external view override returns (Timelock memory) {
        return timelock;
    }

    /// @inheritdoc IDrawCalculatorTimelock
    function setTimelock(Timelock memory _timelock) external override onlyOwner {
        timelock = _timelock;

        emit TimelockSet(_timelock);
    }

    /// @inheritdoc IDrawCalculatorTimelock
    function hasElapsed() external view override returns (bool) {
        return _timelockHasElapsed(timelock);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Read global DrawCalculator variable.
     * @return IDrawCalculator
     */
    function _timelockHasElapsed(Timelock memory _timelock) internal view returns (bool) {
        // If the timelock hasn't been initialized, then it's elapsed
        if (_timelock.timestamp == 0) {
            return true;
        }

        // Otherwise if the timelock has expired, we're good.
        return (block.timestamp > _timelock.timestamp);
    }

    /**
     * @notice Require the timelock "cooldown" period has elapsed
     * @param _timelock the Timelock to check
     */
    function _requireTimelockElapsed(Timelock memory _timelock) internal view {
        require(_timelockHasElapsed(_timelock), "OM/timelock-not-expired");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-timelocks/contracts/DrawCalculatorTimelock.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-timelocks/contracts/BeaconTimelockTrigger.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/v4-timelocks/contracts/ReceiverTimelockTrigger.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/pooltogether-rng-contracts/contracts/RNGChainlinkV2.sol';