// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../../shared/access/ConfirmedOwner.sol";
import "../../interfaces/TypeAndVersionInterface.sol";
import "./VRFConsumerBaseV2Plus.sol";
import "../../shared/interfaces/LinkTokenInterface.sol";
import "../../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IVRFCoordinatorV2Plus.sol";
import "../interfaces/VRFV2PlusWrapperInterface.sol";
import "./VRFV2PlusWrapperConsumerBase.sol";
import "../../ChainSpecificUtil.sol";

/**
 * @notice A wrapper for VRFCoordinatorV2 that provides an interface better suited to one-off
 * @notice requests for randomness.
 */
contract VRFV2PlusWrapper is ConfirmedOwner, TypeAndVersionInterface, VRFConsumerBaseV2Plus, VRFV2PlusWrapperInterface {
  event WrapperFulfillmentFailed(uint256 indexed requestId, address indexed consumer);

  error LinkAlreadySet();
  error FailedToTransferLink();

  /* Storage Slot 1: BEGIN */
  // s_keyHash is the key hash to use when requesting randomness. Fees are paid based on current gas
  // fees, so this should be set to the highest gas lane on the network.
  bytes32 s_keyHash;
  /* Storage Slot 1: END */

  /* Storage Slot 2: BEGIN */
  uint256 public immutable SUBSCRIPTION_ID;
  /* Storage Slot 2: END */

  /* Storage Slot 3: BEGIN */
  // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
  // and some arithmetic operations.
  uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
  /* Storage Slot 3: END */

  /* Storage Slot 4: BEGIN */
  // lastRequestId is the request ID of the most recent VRF V2 request made by this wrapper. This
  // should only be relied on within the same transaction the request was made.
  uint256 public override lastRequestId;
  /* Storage Slot 4: END */

  /* Storage Slot 5: BEGIN */
  // s_fallbackWeiPerUnitLink is the backup LINK exchange rate used when the LINK/NATIVE feed is
  // stale.
  int256 private s_fallbackWeiPerUnitLink;
  /* Storage Slot 5: END */

  /* Storage Slot 6: BEGIN */
  // s_stalenessSeconds is the number of seconds before we consider the feed price to be stale and
  // fallback to fallbackWeiPerUnitLink.
  uint32 private s_stalenessSeconds;

  // s_fulfillmentFlatFeeLinkPPM is the flat fee in millionths of LINK that VRFCoordinatorV2
  // charges.
  uint32 private s_fulfillmentFlatFeeLinkPPM;

  // s_fulfillmentFlatFeeLinkPPM is the flat fee in millionths of LINK that VRFCoordinatorV2
  // charges.
  uint32 private s_fulfillmentFlatFeeNativePPM;

  LinkTokenInterface public s_link;
  /* Storage Slot 6: END */

  /* Storage Slot 7: BEGIN */
  // s_wrapperGasOverhead reflects the gas overhead of the wrapper's fulfillRandomWords
  // function. The cost for this gas is passed to the user.
  uint32 private s_wrapperGasOverhead;

  // Configuration fetched from VRFCoordinatorV2

  /// @dev this is the size of a VRF v2 fulfillment's calldata abi-encoded in bytes.
  /// @dev proofSize = 13 words = 13 * 256 = 3328 bits
  /// @dev commitmentSize = 5 words = 5 * 256 = 1280 bits
  /// @dev dataSize = proofSize + commitmentSize = 4608 bits
  /// @dev selector = 32 bits
  /// @dev total data size = 4608 bits + 32 bits = 4640 bits = 580 bytes
  uint32 public s_fulfillmentTxSizeBytes = 580;

  // s_coordinatorGasOverhead reflects the gas overhead of the coordinator's fulfillRandomWords
  // function. The cost for this gas is billed to the subscription, and must therefor be included
  // in the pricing for wrapped requests. This includes the gas costs of proof verification and
  // payment calculation in the coordinator.
  uint32 private s_coordinatorGasOverhead;

  AggregatorV3Interface public s_linkNativeFeed;
  /* Storage Slot 7: END */

  /* Storage Slot 8: BEGIN */
  // s_configured tracks whether this contract has been configured. If not configured, randomness
  // requests cannot be made.
  bool public s_configured;

  // s_disabled disables the contract when true. When disabled, new VRF requests cannot be made
  // but existing ones can still be fulfilled.
  bool public s_disabled;

  // s_wrapperPremiumPercentage is the premium ratio in percentage. For example, a value of 0
  // indicates no premium. A value of 15 indicates a 15 percent premium.
  uint8 private s_wrapperPremiumPercentage;

  // s_maxNumWords is the max number of words that can be requested in a single wrapped VRF request.
  uint8 s_maxNumWords;
  /* Storage Slot 8: END */

  struct Callback {
    address callbackAddress;
    uint32 callbackGasLimit;
    // Reducing requestGasPrice from uint256 to uint64 slots Callback struct
    // into a single word, thus saving an entire SSTORE and leading to 21K
    // gas cost saving. 18 ETH would be the max gas price we can process.
    // GasPrice is unlikely to be more than 14 ETH on most chains
    uint64 requestGasPrice;
  }
  /* Storage Slot 9: BEGIN */
  mapping(uint256 => Callback) /* requestID */ /* callback */ public s_callbacks;

  /* Storage Slot 9: END */

  constructor(address _link, address _linkNativeFeed, address _coordinator) VRFConsumerBaseV2Plus(_coordinator) {
    if (_link != address(0)) {
      s_link = LinkTokenInterface(_link);
    }
    if (_linkNativeFeed != address(0)) {
      s_linkNativeFeed = AggregatorV3Interface(_linkNativeFeed);
    }

    // Create this wrapper's subscription and add itself as a consumer.
    uint256 subId = s_vrfCoordinator.createSubscription();
    SUBSCRIPTION_ID = subId;
    s_vrfCoordinator.addConsumer(subId, address(this));
  }

  /**
   * @notice set the link token to be used by this wrapper
   * @param link address of the link token
   */
  function setLINK(address link) external onlyOwner {
    // Disallow re-setting link token because the logic wouldn't really make sense
    if (address(s_link) != address(0)) {
      revert LinkAlreadySet();
    }
    s_link = LinkTokenInterface(link);
  }

  /**
   * @notice set the link native feed to be used by this wrapper
   * @param linkNativeFeed address of the link native feed
   */
  function setLinkNativeFeed(address linkNativeFeed) external onlyOwner {
    s_linkNativeFeed = AggregatorV3Interface(linkNativeFeed);
  }

  /**
   * @notice setFulfillmentTxSize sets the size of the fulfillment transaction in bytes.
   * @param size is the size of the fulfillment transaction in bytes.
   */
  function setFulfillmentTxSize(uint32 size) external onlyOwner {
    s_fulfillmentTxSizeBytes = size;
  }

  /**
   * @notice setConfig configures VRFV2Wrapper.
   *
   * @dev Sets wrapper-specific configuration based on the given parameters, and fetches any needed
   * @dev VRFCoordinatorV2 configuration from the coordinator.
   *
   * @param _wrapperGasOverhead reflects the gas overhead of the wrapper's fulfillRandomWords
   *        function.
   *
   * @param _coordinatorGasOverhead reflects the gas overhead of the coordinator's
   *        fulfillRandomWords function.
   *
   * @param _wrapperPremiumPercentage is the premium ratio in percentage for wrapper requests.
   *
   * @param _keyHash to use for requesting randomness.
   */
  function setConfig(
    uint32 _wrapperGasOverhead,
    uint32 _coordinatorGasOverhead,
    uint8 _wrapperPremiumPercentage,
    bytes32 _keyHash,
    uint8 _maxNumWords,
    uint32 stalenessSeconds,
    int256 fallbackWeiPerUnitLink,
    uint32 fulfillmentFlatFeeLinkPPM,
    uint32 fulfillmentFlatFeeNativePPM
  ) external onlyOwner {
    s_wrapperGasOverhead = _wrapperGasOverhead;
    s_coordinatorGasOverhead = _coordinatorGasOverhead;
    s_wrapperPremiumPercentage = _wrapperPremiumPercentage;
    s_keyHash = _keyHash;
    s_maxNumWords = _maxNumWords;
    s_configured = true;

    // Get other configuration from coordinator
    s_stalenessSeconds = stalenessSeconds;
    s_fallbackWeiPerUnitLink = fallbackWeiPerUnitLink;
    s_fulfillmentFlatFeeLinkPPM = fulfillmentFlatFeeLinkPPM;
    s_fulfillmentFlatFeeNativePPM = fulfillmentFlatFeeNativePPM;
  }

  /**
   * @notice getConfig returns the current VRFV2Wrapper configuration.
   *
   * @return fallbackWeiPerUnitLink is the backup LINK exchange rate used when the LINK/NATIVE feed
   *         is stale.
   *
   * @return stalenessSeconds is the number of seconds before we consider the feed price to be stale
   *         and fallback to fallbackWeiPerUnitLink.
   *
   * @return fulfillmentFlatFeeLinkPPM is the flat fee in millionths of LINK that VRFCoordinatorV2Plus
   *         charges.
   *
   * @return wrapperGasOverhead reflects the gas overhead of the wrapper's fulfillRandomWords
   *         function. The cost for this gas is passed to the user.
   *
   * @return coordinatorGasOverhead reflects the gas overhead of the coordinator's
   *         fulfillRandomWords function.
   *
   * @return wrapperPremiumPercentage is the premium ratio in percentage. For example, a value of 0
   *         indicates no premium. A value of 15 indicates a 15 percent premium.
   *
   * @return keyHash is the key hash to use when requesting randomness. Fees are paid based on
   *         current gas fees, so this should be set to the highest gas lane on the network.
   *
   * @return maxNumWords is the max number of words that can be requested in a single wrapped VRF
   *         request.
   */
  function getConfig()
    external
    view
    returns (
      int256 fallbackWeiPerUnitLink,
      uint32 stalenessSeconds,
      uint32 fulfillmentFlatFeeLinkPPM,
      uint32 wrapperGasOverhead,
      uint32 coordinatorGasOverhead,
      uint8 wrapperPremiumPercentage,
      bytes32 keyHash,
      uint8 maxNumWords
    )
  {
    return (
      s_fallbackWeiPerUnitLink,
      s_stalenessSeconds,
      s_fulfillmentFlatFeeLinkPPM,
      s_wrapperGasOverhead,
      s_coordinatorGasOverhead,
      s_wrapperPremiumPercentage,
      s_keyHash,
      s_maxNumWords
    );
  }

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(
    uint32 _callbackGasLimit
  ) external view override onlyConfiguredNotDisabled returns (uint256) {
    int256 weiPerUnitLink = getFeedData();
    return calculateRequestPriceInternal(_callbackGasLimit, tx.gasprice, weiPerUnitLink);
  }

  function calculateRequestPriceNative(
    uint32 _callbackGasLimit
  ) external view override onlyConfiguredNotDisabled returns (uint256) {
    return calculateRequestPriceNativeInternal(_callbackGasLimit, tx.gasprice);
  }

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(
    uint32 _callbackGasLimit,
    uint256 _requestGasPriceWei
  ) external view override onlyConfiguredNotDisabled returns (uint256) {
    int256 weiPerUnitLink = getFeedData();
    return calculateRequestPriceInternal(_callbackGasLimit, _requestGasPriceWei, weiPerUnitLink);
  }

  function estimateRequestPriceNative(
    uint32 _callbackGasLimit,
    uint256 _requestGasPriceWei
  ) external view override onlyConfiguredNotDisabled returns (uint256) {
    return calculateRequestPriceNativeInternal(_callbackGasLimit, _requestGasPriceWei);
  }

  function calculateRequestPriceNativeInternal(uint256 _gas, uint256 _requestGasPrice) internal view returns (uint256) {
    // costWei is the base fee denominated in wei (native)
    // costWei takes into account the L1 posting costs of the VRF fulfillment
    // transaction, if we are on an L2.
    uint256 costWei = (_requestGasPrice *
      (_gas + s_wrapperGasOverhead + s_coordinatorGasOverhead) +
      ChainSpecificUtil.getL1CalldataGasCost(s_fulfillmentTxSizeBytes));
    // ((wei/gas * (gas)) + l1wei)
    // baseFee is the base fee denominated in wei
    uint256 baseFee = costWei;
    // feeWithPremium is the fee after the percentage premium is applied
    uint256 feeWithPremium = (baseFee * (s_wrapperPremiumPercentage + 100)) / 100;
    // feeWithFlatFee is the fee after the flat fee is applied on top of the premium
    uint256 feeWithFlatFee = feeWithPremium + (1e12 * uint256(s_fulfillmentFlatFeeNativePPM));

    return feeWithFlatFee;
  }

  function calculateRequestPriceInternal(
    uint256 _gas,
    uint256 _requestGasPrice,
    int256 _weiPerUnitLink
  ) internal view returns (uint256) {
    // costWei is the base fee denominated in wei (native)
    // costWei takes into account the L1 posting costs of the VRF fulfillment
    // transaction, if we are on an L2.
    uint256 costWei = (_requestGasPrice *
      (_gas + s_wrapperGasOverhead + s_coordinatorGasOverhead) +
      ChainSpecificUtil.getL1CalldataGasCost(s_fulfillmentTxSizeBytes));
    // (1e18 juels/link) * ((wei/gas * (gas)) + l1wei) / (wei/link) == 1e18 juels * wei/link / (wei/link) == 1e18 juels * wei/link * link/wei == juels
    // baseFee is the base fee denominated in juels (link)
    uint256 baseFee = (1e18 * costWei) / uint256(_weiPerUnitLink);
    // feeWithPremium is the fee after the percentage premium is applied
    uint256 feeWithPremium = (baseFee * (s_wrapperPremiumPercentage + 100)) / 100;
    // feeWithFlatFee is the fee after the flat fee is applied on top of the premium
    uint256 feeWithFlatFee = feeWithPremium + (1e12 * uint256(s_fulfillmentFlatFeeLinkPPM));

    return feeWithFlatFee;
  }

  /**
   * @notice onTokenTransfer is called by LinkToken upon payment for a VRF request.
   *
   * @dev Reverts if payment is too low.
   *
   * @param _sender is the sender of the payment, and the address that will receive a VRF callback
   *        upon fulfillment.
   *
   * @param _amount is the amount of LINK paid in Juels.
   *
   * @param _data is the abi-encoded VRF request parameters: uint32 callbackGasLimit,
   *        uint16 requestConfirmations, and uint32 numWords.
   */
  function onTokenTransfer(address _sender, uint256 _amount, bytes calldata _data) external onlyConfiguredNotDisabled {
    require(msg.sender == address(s_link), "only callable from LINK");

    (uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords) = abi.decode(
      _data,
      (uint32, uint16, uint32)
    );
    uint32 eip150Overhead = getEIP150Overhead(callbackGasLimit);
    int256 weiPerUnitLink = getFeedData();
    uint256 price = calculateRequestPriceInternal(callbackGasLimit, tx.gasprice, weiPerUnitLink);
    require(_amount >= price, "fee too low");
    require(numWords <= s_maxNumWords, "numWords too high");
    VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
      keyHash: s_keyHash,
      subId: SUBSCRIPTION_ID,
      requestConfirmations: requestConfirmations,
      callbackGasLimit: callbackGasLimit + eip150Overhead + s_wrapperGasOverhead,
      numWords: numWords,
      extraArgs: "" // empty extraArgs defaults to link payment
    });
    uint256 requestId = s_vrfCoordinator.requestRandomWords(req);
    s_callbacks[requestId] = Callback({
      callbackAddress: _sender,
      callbackGasLimit: callbackGasLimit,
      requestGasPrice: uint64(tx.gasprice)
    });
    lastRequestId = requestId;
  }

  function requestRandomWordsInNative(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) external payable override returns (uint256 requestId) {
    uint32 eip150Overhead = getEIP150Overhead(_callbackGasLimit);
    uint256 price = calculateRequestPriceNativeInternal(_callbackGasLimit, tx.gasprice);
    require(msg.value >= price, "fee too low");
    require(_numWords <= s_maxNumWords, "numWords too high");
    VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
      keyHash: s_keyHash,
      subId: SUBSCRIPTION_ID,
      requestConfirmations: _requestConfirmations,
      callbackGasLimit: _callbackGasLimit + eip150Overhead + s_wrapperGasOverhead,
      numWords: _numWords,
      extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
    });
    requestId = s_vrfCoordinator.requestRandomWords(req);
    s_callbacks[requestId] = Callback({
      callbackAddress: msg.sender,
      callbackGasLimit: _callbackGasLimit,
      requestGasPrice: uint64(tx.gasprice)
    });

    return requestId;
  }

  /**
   * @notice withdraw is used by the VRFV2Wrapper's owner to withdraw LINK revenue.
   *
   * @param _recipient is the address that should receive the LINK funds.
   *
   * @param _amount is the amount of LINK in Juels that should be withdrawn.
   */
  function withdraw(address _recipient, uint256 _amount) external onlyOwner {
    if (!s_link.transfer(_recipient, _amount)) {
      revert FailedToTransferLink();
    }
  }

  /**
   * @notice withdraw is used by the VRFV2Wrapper's owner to withdraw native revenue.
   *
   * @param _recipient is the address that should receive the native funds.
   *
   * @param _amount is the amount of native in Wei that should be withdrawn.
   */
  function withdrawNative(address _recipient, uint256 _amount) external onlyOwner {
    (bool success, ) = payable(_recipient).call{value: _amount}("");
    require(success, "failed to withdraw native");
  }

  /**
   * @notice enable this contract so that new requests can be accepted.
   */
  function enable() external onlyOwner {
    s_disabled = false;
  }

  /**
   * @notice disable this contract so that new requests will be rejected. When disabled, new requests
   * @notice will revert but existing requests can still be fulfilled.
   */
  function disable() external onlyOwner {
    s_disabled = true;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    Callback memory callback = s_callbacks[_requestId];
    delete s_callbacks[_requestId];
    require(callback.callbackAddress != address(0), "request not found"); // This should never happen

    VRFV2PlusWrapperConsumerBase c;
    bytes memory resp = abi.encodeWithSelector(c.rawFulfillRandomWords.selector, _requestId, _randomWords);

    bool success = callWithExactGas(callback.callbackGasLimit, callback.callbackAddress, resp);
    if (!success) {
      emit WrapperFulfillmentFailed(_requestId, callback.callbackAddress);
    }
  }

  function getFeedData() private view returns (int256) {
    bool staleFallback = s_stalenessSeconds > 0;
    uint256 timestamp;
    int256 weiPerUnitLink;
    (, weiPerUnitLink, , timestamp, ) = s_linkNativeFeed.latestRoundData();
    // solhint-disable-next-line not-rely-on-time
    if (staleFallback && s_stalenessSeconds < block.timestamp - timestamp) {
      weiPerUnitLink = s_fallbackWeiPerUnitLink;
    }
    require(weiPerUnitLink >= 0, "Invalid LINK wei price");
    return weiPerUnitLink;
  }

  /**
   * @dev Calculates extra amount of gas required for running an assembly call() post-EIP150.
   */
  function getEIP150Overhead(uint32 gas) private pure returns (uint32) {
    return gas / 63 + 1;
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available.
   */
  function callWithExactGas(uint256 gasAmount, address target, bytes memory data) private returns (bool success) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let g := gas()
      // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
      // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
      // We want to ensure that we revert if gasAmount >  63//64*gas available
      // as we do not want to provide them with less, however that check itself costs
      // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
      // to revert if gasAmount >  63//64*gas available.
      if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
        revert(0, 0)
      }
      g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  function typeAndVersion() external pure virtual override returns (string memory) {
    return "VRFV2Wrapper 1.0.0";
  }

  modifier onlyConfiguredNotDisabled() {
    require(s_configured, "wrapper is not configured");
    require(!s_disabled, "wrapper is disabled");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IVRFCoordinatorV2Plus.sol";
import "../interfaces/IVRFMigratableConsumerV2Plus.sol";
import "../../shared/access/ConfirmedOwner.sol";

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

  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
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
  function setCoordinator(address _vrfCoordinator) public override onlyOwnerOrCoordinator {
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../vrf/libraries/VRFV2PlusClient.sol";
import "./IVRFSubscriptionV2Plus.sol";

// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fiels for randomness request:
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

interface VRFV2PlusWrapperInterface {
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
   * @notice Calculates the price of a VRF request in native with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPriceNative(uint32 _callbackGasLimit) external view returns (uint256);

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

  /**
   * @notice Estimates the price of a VRF request in native with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPriceNative(
    uint32 _callbackGasLimit,
    uint256 _requestGasPriceWei
  ) external view returns (uint256);

  /**
   * @notice Requests randomness from the VRF V2 wrapper, paying in native token.
   *
   * @param _callbackGasLimit is the gas limit for the request.
   * @param _requestConfirmations number of request confirmations to wait before serving a request.
   * @param _numWords is the number of words to request.
   */
  function requestRandomWordsInNative(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) external payable returns (uint256 requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/interfaces/LinkTokenInterface.sol";
import "../interfaces/VRFV2PlusWrapperInterface.sol";

/**
 *
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2+ requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2+ subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2PlusWrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK or ether to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomWords' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2PlusWrapperConsumerBase {
  error LINKAlreadySet();

  LinkTokenInterface internal LINK;
  VRFV2PlusWrapperInterface internal VRF_V2_PLUS_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2PlusWrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2PlusWrapper) {
    if (_link != address(0)) {
      LINK = LinkTokenInterface(_link);
    }

    VRF_V2_PLUS_WRAPPER = VRFV2PlusWrapperInterface(_vrfV2PlusWrapper);
  }

  /**
   * @notice setLinkToken changes the LINK token address.
   * @param _link is the address of the new LINK token contract
   */
  function setLinkToken(address _link) external {
    if (address(LINK) != address(0)) {
      revert LINKAlreadySet();
    }

    LINK = LinkTokenInterface(_link);
  }

  /**
   * @dev Requests randomness from the VRF V2+ wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2+ request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_PLUS_WRAPPER),
      VRF_V2_PLUS_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_PLUS_WRAPPER.lastRequestId();
  }

  function requestRandomnessPayInNative(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    uint256 requestPrice = VRF_V2_PLUS_WRAPPER.calculateRequestPriceNative(_callbackGasLimit);
    return
      VRF_V2_PLUS_WRAPPER.requestRandomWordsInNative{value: requestPrice}(
        _callbackGasLimit,
        _requestConfirmations,
        _numWords
      );
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
    require(msg.sender == address(VRF_V2_PLUS_WRAPPER), "only VRF V2 Plus wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ArbSys} from "./vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import {ArbGasInfo} from "./vendor/@arbitrum/nitro-contracts/src/precompiles/ArbGasInfo.sol";

//@dev A library that abstracts out opcodes that behave differently across chains.
//@dev The methods below return values that are pertinent to the given chain.
//@dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
  address private constant ARBSYS_ADDR = address(0x0000000000000000000000000000000000000064);
  ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);
  address private constant ARBGAS_ADDR = address(0x000000000000000000000000000000000000006C);
  ArbGasInfo private constant ARBGAS = ArbGasInfo(ARBGAS_ADDR);
  uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
  uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;
  uint256 private constant ARB_SEPOLIA_TESTNET_CHAIN_ID = 421614;

  function getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
    uint256 chainid = block.chainid;
    if (isArbitrumChainId(chainid)) {
      if ((getBlockNumber() - blockNumber) > 256 || blockNumber >= getBlockNumber()) {
        return "";
      }
      return ARBSYS.arbBlockHash(blockNumber);
    }
    return blockhash(blockNumber);
  }

  function getBlockNumber() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (isArbitrumChainId(chainid)) {
      return ARBSYS.arbBlockNumber();
    }
    return block.number;
  }

  function getCurrentTxL1GasFees() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (isArbitrumChainId(chainid)) {
      return ARBGAS.getCurrentTxL1GasFees();
    }
    return 0;
  }

  /**
   * @notice Returns the gas cost in wei of calldataSizeBytes of calldata being posted
   * @notice to L1.
   */
  function getL1CalldataGasCost(uint256 calldataSizeBytes) internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (isArbitrumChainId(chainid)) {
      (, uint256 l1PricePerByte, , , , ) = ARBGAS.getPricesInWei();
      // see https://developer.arbitrum.io/devs-how-tos/how-to-estimate-gas#where-do-we-get-all-this-information-from
      // for the justification behind the 140 number.
      return l1PricePerByte * (calldataSizeBytes + 140);
    }
    return 0;
  }

  /**
   * @notice Return true if and only if the provided chain ID is an Arbitrum chain ID.
   */
  function isArbitrumChainId(uint256 chainId) internal pure returns (bool) {
    return
      chainId == ARB_MAINNET_CHAIN_ID ||
      chainId == ARB_GOERLI_TESTNET_CHAIN_ID ||
      chainId == ARB_SEPOLIA_TESTNET_CHAIN_ID;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOwnable.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  /// @notice Sets the VRF Coordinator address
  /// @notice This method is should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
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
   * @notice Request subscription owner transfer.
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
   * @notice This method expects msg.value to be greater than 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

interface ArbGasInfo {
    // return gas prices in wei, assuming the specified aggregator is used
    //        (
    //            per L2 tx,
    //            per L1 calldata unit, (zero byte = 4 units, nonzero byte = 16 units)
    //            per storage allocation,
    //            per ArbGas base,
    //            per ArbGas congestion,
    //            per ArbGas total
    //        )
    function getPricesInWeiWithAggregator(address aggregator) external view returns (uint, uint, uint, uint, uint, uint);

    // return gas prices in wei, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInWei() external view returns (uint, uint, uint, uint, uint, uint);

    // return prices in ArbGas (per L2 tx, per L1 calldata unit, per storage allocation),
    //       assuming the specified aggregator is used
    function getPricesInArbGasWithAggregator(address aggregator) external view returns (uint, uint, uint);

    // return gas prices in ArbGas, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInArbGas() external view returns (uint, uint, uint);

    // return gas accounting parameters (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams() external view returns (uint, uint, uint);

    // get ArbOS's estimate of the L1 gas price in wei
    function getL1GasPriceEstimate() external view returns(uint);

    // set ArbOS's estimate of the L1 gas price in wei
    // reverts unless called by chain owner or designated gas oracle (if any)
    function setL1GasPriceEstimate(uint priceInWei) external;

    // get L1 gas fees paid by the current transaction (txBaseFeeWei, calldataFeeWei)
    function getCurrentTxL1GasFees() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}