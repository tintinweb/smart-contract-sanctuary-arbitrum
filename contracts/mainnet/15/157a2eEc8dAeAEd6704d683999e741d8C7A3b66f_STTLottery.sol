// SPDX-License-Identifier: MIT
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
  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
  LinkTokenInterface internal immutable LINK;
  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
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
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
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
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    // solhint-disable-next-line custom-errors
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}


pragma solidity ^0.8.0;


interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}


pragma solidity ^0.8.0;


/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line custom-errors
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
    // solhint-disable-next-line custom-errors
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
    // solhint-disable-next-line custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}


pragma solidity ^0.8.0;


/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}


pragma solidity ^0.8.7;


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
   * @dev Returns the value of tokens in existence.
     */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the value of tokens owned by `account`.
     */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
  function transfer(address to, uint256 value) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
  function approve(address spender, uint256 value) external returns (bool);

  /**
   * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract STTLottery is VRFV2WrapperConsumerBase, ConfirmedOwner {

  //CHAINLINK PART
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
    address sender;
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

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
  uint32 numWords = 1;

  // Address LINK
  address linkAddress = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;

  // address coordinator
  address coordinator = 0x41034678D6C633D8a95c75e1138A360a28bA15d1;

  // address WRAPPER
  address wrapperAddress = 0x2D159AE3bFf04a10A355B608D22BDEC092e934fa;


  constructor()
  ConfirmedOwner(msg.sender)
  VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
  {}

  function requestRandomWords(address _sender)
  private
  returns (uint256 requestId)
  {
    requestId = requestRandomness(
      callbackGasLimit,
      requestConfirmations,
      numWords
    );
    s_requests[requestId] = RequestStatus({
      paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
      randomWords: new uint256[](0),
      fulfilled: false,
      sender: _sender
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
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomWords = _randomWords;

    //Lottery
    uint _win = random(_randomWords[0]);

    if (_win != 0) {
      STT.transfer(s_requests[_requestId].sender, _win);
    }

    tickets[lastTicket].player = s_requests[_requestId].sender;
    tickets[lastTicket].winAmount = _win;

    emit Lottery (
      lastTicket,
      tickets[lastTicket].player,
      tickets[lastTicket].chainlinkNumber1,
      tickets[lastTicket].chainlinkNumber2,
      tickets[lastTicket].chainlinkNumber3,
      tickets[lastTicket].chainlinkNumber4,
      tickets[lastTicket].blockNumber,
      tickets[lastTicket].blockNumber1,
      tickets[lastTicket].blockNumber2,
      tickets[lastTicket].winAmount
    );


    lastTicket++;

    emit RequestFulfilled(
      _requestId,
      _randomWords,
      s_requests[_requestId].paid
    );
  }

  function getRequestStatus(
    uint256 _requestId
  )
  external
  view
  returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
  {
    require(s_requests[_requestId].paid > 0, "request not found");
    RequestStatus memory request = s_requests[_requestId];
    return (request.paid, request.fulfilled, request.randomWords);
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(linkAddress);
    require(
      link.transfer(msg.sender, link.balanceOf(address(this))),
      "Unable to transfer"
    );
  }

  //LOTTERY PART
  IERC20 public STT = IERC20(0x1635b6413d900D85fE45C2541342658F4E982185);

  uint public minPriceTicket = 1000000000;
  uint public k_balance = 1;
  uint public k_bank = 10;
  uint public k_rate = 1;

  uint public referralFee = 100;
  uint public adminFee = 100;
  address public adminAddress;
  uint public lastWin;
  uint public lastNumber;
  uint public lastTicket;

  struct Ticket {
    address player;
    uint chainlinkNumber1;
    uint chainlinkNumber2;
    uint chainlinkNumber3;
    uint chainlinkNumber4;
    uint blockNumber;
    uint blockNumber1;
    uint blockNumber2;
    uint winAmount;
  }
  mapping(uint => Ticket) public tickets;

  mapping(address => address) public myReferer;

  event BuyTicket (uint ticketID);
  event Lottery (
    uint ticketID,
    address player,
    uint chainLInkNumber1,
    uint chainLInkNumber2,
    uint chainLInkNumber3,
    uint chainLInkNumber4,
    uint blockNumber,
    uint blockNumber1,
    uint blockNumber2,
    uint win
  );

  function buyTicket(uint _amountSTT, address _myReferer) public {
    uint _refFee;

    //Admin fee
    uint _admFee = calculate(_amountSTT, adminFee);
    STT.transferFrom(msg.sender, adminAddress, _admFee);

    if (myReferer[msg.sender] == address(0) && _myReferer != address(0)) {
      myReferer[msg.sender] = _myReferer;
    }

    if (myReferer[msg.sender] != address(0)) {
      //Referal fee
      _refFee = calculate(_amountSTT, referralFee);
      STT.transferFrom(msg.sender, myReferer[msg.sender], _refFee);
    }

    if (_amountSTT < minPriceTicket) {
      STT.transferFrom(msg.sender, address(this), _amountSTT - _refFee - _admFee);

    } else {
      //Price for a ticket
      STT.transferFrom(msg.sender, address(this), _amountSTT - _refFee - _admFee);

      requestRandomWords(msg.sender);
    }

    emit BuyTicket (lastTicket);
  }

  function random(uint _number) private returns(uint) {
    uint _blockNumber = block.number;
    uint _blockNumber1 = _blockNumber % 10;
    uint _blockNumber2 = (_blockNumber / 10) % 10;

    uint _chainlinkNumber1 = _number % 10;
    uint _chainlinkNumber2 = (_number / 10) % 10;
    uint _chainlinkNumber3 = (_number / 100) % 10;
    uint _chainlinkNumber4 = (_number / 1000) % 10;

    uint _calculate_balance = calculate(STT.balanceOf(address(this)), k_balance);
    uint _calculate_rate = calculate(
      _chainlinkNumber1 * _chainlinkNumber2 * _chainlinkNumber3 * _chainlinkNumber4 * _blockNumber1 * _blockNumber2,
      k_rate
    );

    uint _win = calculate(
      _calculate_balance * _calculate_rate,
      k_bank
    );

    tickets[lastTicket].chainlinkNumber1 = _chainlinkNumber1;
    tickets[lastTicket].chainlinkNumber2 = _chainlinkNumber2;
    tickets[lastTicket].chainlinkNumber3 = _chainlinkNumber3;
    tickets[lastTicket].chainlinkNumber4 = _chainlinkNumber4;
    tickets[lastTicket].blockNumber = _blockNumber;
    tickets[lastTicket].blockNumber1 = _blockNumber1;
    tickets[lastTicket].blockNumber2 = _blockNumber2;

    return _win;
  }

  // Counting an percentage by basis points
  function calculate(uint256 amount, uint256 bps) public pure returns (uint256) {
    return amount * bps / 10000;
  }

  function setMinPriceTicket(uint _minPriceTicket) public onlyOwner {
    minPriceTicket = _minPriceTicket;
  }

  function setReferralFee(uint _fee) public onlyOwner {
    referralFee = _fee;
  }

  function setAdminFee(uint _fee, address _adminAddress) public onlyOwner {
    adminFee = _fee;
    adminAddress = _adminAddress;
  }

  function setRate(uint _k_balance, uint _k_bank, uint _k_rate) public onlyOwner {
    require(_k_balance <= 123, 'Invalid _k_balance');
    require(_k_bank <= 123, 'Invalid _k_bank');
    require(_k_rate <= 123, 'Invalid _k_rate');
    if (_k_balance > 0) k_balance = _k_balance;
    if (_k_bank > 0) k_bank = _k_bank;
    if (_k_rate > 0) k_rate = _k_rate;
  }

  function setGasLimit(uint32 _gas) public onlyOwner {
    callbackGasLimit = _gas;
  }
}