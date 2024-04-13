// File: @chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol


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

// File: @chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol


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

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol


pragma solidity ^0.8.0;



/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// File: contracts/OnChainMultiRaffleLink.sol


pragma solidity ^0.8.20;


contract OnChainMultiRaffle is VRFV2WrapperConsumerBase {

    event RequestSent(uint256 requestId, uint32 numWords);

    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;

    uint256 public lastRequestId;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 300000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    // Num words retrived 
    uint32 numWords = 1;

    // Address LINK - hardcoded for Arbitrum
    address constant linkAddress = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
    
    // address WRAPPER - hardcoded for Arbitrum
    address constant wrapperAddress = 0x2D159AE3bFf04a10A355B608D22BDEC092e934fa;

    // Sepolia
    // address constant linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    // address constant wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;


    uint256 public randomSeed;
    address public owner;
    bool randomnessSet;

    constructor() VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) {
        owner = msg.sender; 
    }

    function pickWinnersOrdinalsRaffle() public view returns (uint256[] memory) {
        require(randomnessSet, "Need randomness");

        uint256[] memory winners = new uint256[](10);

        uint256 seed = randomSeed;
        // seed = newSeed;

        // hardcoded heroes entries 
        uint16[54] memory heroesList = [1,15,22,23,37,43,63,67,78,130,143,151,217,313,329,369,474,593,607,635,701,796,800,854,878,888,891,925,1000,1002,1026,1045,1058,1115,1139,1169,1240,1263,1304,1331,1337,1364,1387,1465,1551,1561,1902,2254,2460,3165,3203,3781,4444,9999];

        uint256 lenArray = heroesList.length;
        uint256 pickedIndex = 0;

        for (uint256 i = 0; i < 10; i++) {
            // new random seed from previous seed
            seed = uint256(keccak256(abi.encode(seed)));
            
            // pick index of winner
            pickedIndex = seed % lenArray;

            // store winner i
            winners[i] = heroesList[pickedIndex];

            // swap used index with last element, and remove last element from count in the next round
            // this avoids getting duplicate winner picks
            heroesList[pickedIndex] = heroesList[lenArray - 1];
            lenArray--;
        }

        return winners;
    }

    function requestRandomWords()
        external
        returns (uint256 requestId)
    {
        require(msg.sender == owner, "Not the owner");
        require(!randomnessSet, "Already set");

        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });

        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");

        randomSeed = _randomWords[0];
        randomnessSet = true;

        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public {
        require(msg.sender == owner, "Not the owner");
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}