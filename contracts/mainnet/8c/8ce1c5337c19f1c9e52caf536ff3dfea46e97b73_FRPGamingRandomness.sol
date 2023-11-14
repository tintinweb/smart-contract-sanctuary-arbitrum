/**
 *Submitted for verification at Arbiscan.io on 2023-11-14
*/

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


pragma solidity ^0.8.0;

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

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

//Everything above this point is a dependency contract that is imported

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract FRPGamingRandomness is Ownable
{
    uint32 public constant randomNumberAmount = 4;

    struct RequestStatus {
        uint256 paid; //LINK
        uint256 randomWord;
        bool fulfilled;
    }

    //VRF 
    mapping(uint256 => RequestStatus) vrfRequests;
    error OnlyCoordinatorCanFulfill(address have, VRFCoordinatorV2Interface want);

    //For direct funding
    VRFV2WrapperInterface immutable public vrfWrapper;

    //For subscription
    VRFCoordinatorV2Interface immutable public vrfCoordinator;
    uint64 public subscriptionId;
    bytes32 public keyHash;

    LinkTokenInterface immutable public LINK;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    bool public useSubscription;

    event RandomnessRequested(uint256 indexed requestId);
    event RandomnessSucceeded(uint256 indexed requestId, uint256 spinGameResult, uint256 cardGameResultPlayer, uint256 cardGameResultBanker, uint256 rouletteResult);
    //

    //Internal (Deploying with chainlink variables)
    constructor(VRFV2WrapperInterface _vrfWrapper, VRFCoordinatorV2Interface _vrfCoordinator, LinkTokenInterface link, uint32 _callbackGasLimit, uint16 _requestConfirmations, uint64 _subscriptionId, bytes32 _keyHash, bool _useSubscription) {
        vrfWrapper = _vrfWrapper;
        vrfCoordinator = _vrfCoordinator;
        LINK = link;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        useSubscription = _useSubscription;
    }
    //

    //Once we generate our randomNumber, We add % 4 as the odds are 1 in 4. Thus returning a random number between 0-3.
    //We also emit an event (RandomnessSucceeded) which can be viewed and includes the random number.
    //0 = Purple
    //1 = Yellow
    //2 = Blue
    //3 = Orange
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal {
        require(vrfRequests[requestId].paid > 0 && !vrfRequests[requestId].fulfilled, "Request not available.");
        vrfRequests[requestId].fulfilled = true;

        
        vrfRequests[requestId].randomWord = randomWords[0];
        vrfRequests[requestId].randomWord = randomWords[1];
        vrfRequests[requestId].randomWord = randomWords[2];
        vrfRequests[requestId].randomWord = randomWords[3];

        emit RandomnessSucceeded(requestId, (randomWords[0] % 4), (randomWords[1] % 52), (randomWords[2] % 52), (randomWords[3] % 36));
    }
    //

    //Once spin is initatied, we recieve a requestID which we can then call vrfRequest and that would return to as an array and the middle item in the array
    //is the random number (Based on the RequestStatus struct. This can also viewed from the event system as we fire off RandomnessSucceeded with the random number included.
    function vrfRequest(uint256 requestId) external view returns (RequestStatus memory)
    {
        return vrfRequests[requestId];
    }
    //

    //Admin
    function FRPRequestingRandomness() public onlyOwner returns (uint256 requestId)
    {
        requestId = requestRandomWords();
        emit RandomnessRequested(requestId);
    }

    function setVrfSettings(uint32 gas, uint16 confirmations, uint64 subscription, bytes32 key, bool subscribe) external onlyOwner
    {
        callbackGasLimit = gas;
        requestConfirmations = confirmations;
        subscriptionId = subscription;
        keyHash = key;
        useSubscription = subscribe;
    }

    function withdrawLink() external onlyOwner {
        require(
            LINK.transfer(msg.sender, LINK.balanceOf(address(this))),
            "Unable to transfer."
        );
    }

    function withdrawLink(uint256 amount) external onlyOwner {
        require(
            LINK.transfer(msg.sender, amount),
            "Unable to transfer."
        );
    }
    //

    //Chainlink required functions to ensure that our request is based on the variables we set for our subscription within VRF.
    function requestRandomnessDirect(
    ) internal returns (uint256) {
        LINK.transferAndCall(
            address(vrfWrapper),
            vrfWrapper.calculateRequestPrice(callbackGasLimit),
            abi.encode(callbackGasLimit, requestConfirmations, 1)
        );
        return vrfWrapper.lastRequestId();
    }

    function requestRandomWordsDirect() internal returns (uint256 requestId)
    {
        requestId = requestRandomnessDirect();
        vrfRequests[requestId] = RequestStatus({
        paid: vrfWrapper.calculateRequestPrice(callbackGasLimit),
        randomWord: 0,
        fulfilled: false
        });
    }

    function requestRandomnessSubscription(
    ) internal returns (uint256) {
        return vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            randomNumberAmount
        );
    }

    function requestRandomWordsSubscription() internal returns (uint256 requestId)
    {
        requestId = requestRandomnessSubscription();
        vrfRequests[requestId] = RequestStatus({
            paid: 1,
            randomWord: 0,
            fulfilled: false
        });
    }

    function requestRandomWords() internal returns (uint256)
    {
        if(block.chainid == 31337)
        {
            uint256 requestId = 0;
            vrfRequests[requestId] = RequestStatus({
            paid: 1,
            randomWord: 0,
            fulfilled: false
            });
            uint256[] memory randomWords = new uint256[](1);
            uint256 len = randomWords.length;
            uint256 seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
            for(uint256 i = 0; i < len; i += 1)
            {
                seed = uint256(keccak256(abi.encodePacked(seed, block.difficulty, block.timestamp)));
                randomWords[i] = seed;
            }
            fulfillRandomWords(requestId, randomWords);
            return requestId;
        }
        return useSubscription ? requestRandomWordsSubscription() : requestRandomWordsDirect();
    }
    
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != address(vrfCoordinator)) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
    //
}