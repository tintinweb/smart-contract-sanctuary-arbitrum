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

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
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

import "../shared/interfaces/LinkTokenInterface.sol";
import "../interfaces/VRFV2WrapperInterface.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BubbleWars is 
    VRFV2WrapperConsumerBase,
    Ownable
{
    //Game constants
    uint public currentRound = 0;
    uint public startTime;
    uint public roundDuration = 69 minutes;
    address public protocolFeeDestination;
    uint256 public protocolFeePercent = 2 * 1 ether / 100;
    uint256 public bubbleOwnerFeePercent = 2 * 1 ether / 100;
    uint256 public loserPercentDeduction = 10;
    uint256 public totalValueDeposited;

    //Chainlink VRF constants
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;
    address linkAddress = 0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28;
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    enum RoundStatus {
        None,
        Open,
        FetchingRandomNumber, // Fetching random words
        RecievedRandomNumber, // Upon recieving random words, determine winner
        Distributing, // Upon recieving winner, distribute rewards by looping through all bubbles and dedu
        Finished // 
    }

    struct VrfRequestStatus {
        uint requestId;
        uint256 paid; // amount paid in link
        uint256[] randomWords;
    }

    struct Round {
        uint256 startTime;
        VrfRequestStatus vrfRequestStatus;
        RoundStatus status;
        uint256 lastProcessedIndex;
    }

    struct Bubble {
        uint256 value;  // Total value deposited in the bubble (some say "marketcap")
        uint256 supply; // Total shares of bubble in circulation
    }

    modifier canTrade() {
        require(block.timestamp < rounds[currentRound].startTime + roundDuration, "Trading is closed");
        require(rounds[currentRound].status == RoundStatus.Open, "Trading is not open");
        _;
    }

    modifier canFinish() {
        require(rounds[currentRound].status == RoundStatus.Open, "Trading is not open");
        require(block.timestamp >= rounds[currentRound].startTime + roundDuration, "Trading is not closed");
        _;
    }

    modifier canDistributeRewards() {
        require(rounds[currentRound].status == RoundStatus.RecievedRandomNumber || rounds[currentRound].status == RoundStatus.Distributing, "Invalid round status");
        _;
    }

    event BubbleCreated(address bubbleAddress);
    event BubblePopped(address bubbleAddress);
    event Trade(address trader, address subject, bool isBuy, uint256 shareAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 supply);
    event RoundFinished(uint256 round, uint256 totalValueDeposited, uint256[] randomWords, address winner, uint256 reward);

    // BubbleAddress => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public bubbleSharesBalance;

    // BubbleAddress => Bubble
    mapping(address => Bubble) public bubbles;

    // Bubble addresses
    address[] public bubbleAddresses;

    // Rounds
    mapping (uint => Round) public rounds;

    constructor() 
        Ownable(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        protocolFeeDestination = msg.sender;
        _startRound(1);
    }

    //linear function scales based on the number of bubbles
    function getCreationFee() public view returns (uint256) {
        uint count = bubbleAddresses.length;
        return count * totalValueDeposited * 1 ether / 10000000;
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000;
    }

    function getScalingFactor(address bubbleAddress) public view returns (uint256) {
        uint256 originalValue = (bubbles[bubbleAddress].supply * (bubbles[bubbleAddress].supply + 1) * (2 * bubbles[bubbleAddress].supply + 1)) / 6;
        return bubbles[bubbleAddress].value * 1 ether / originalValue;
    }

    function getAdjustedPrice(uint256 supply, uint256 amount, uint256 scalingFactor) public pure returns (uint256) {
        uint256 price = getPrice(supply, amount);
        return (price * scalingFactor) / 1 ether;
    }

    function getBuyPrice(address bubbleAddress, uint256 amount) public view returns (uint256) {
        uint256 scalingFactor = getScalingFactor(bubbleAddress);
        return getAdjustedPrice(bubbles[bubbleAddress].supply, amount, scalingFactor);
    }

    function getSellPrice(address bubbleAddress, uint256 amount) public view returns (uint256) {
        uint256 scalingFactor = getScalingFactor(bubbleAddress);
        return getAdjustedPrice(bubbles[bubbleAddress].supply - amount, amount, scalingFactor);
    }

    function getBuyPriceAfterFee(address bubbleAddress, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(bubbleAddress, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * bubbleOwnerFeePercent / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function getSellPriceAfterFee(address bubbleAddress, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(bubbleAddress, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * bubbleOwnerFeePercent / 1 ether;
        return price - protocolFee - subjectFee;
    }

    function createBubble() public payable {
        uint creationFee = getCreationFee();
        require(msg.value >= creationFee, "Insufficient payment");
        require(bubbles[msg.sender].supply == 0, "Bubble already exists");
        bubbleAddresses.push(msg.sender);
        buyShares(msg.sender, 1);
    }

    function buyShares(address bubbleAddress, uint256 amount) public payable {
        uint256 supply = bubbles[bubbleAddress].supply;
        require(supply > 0 || bubbleAddress == msg.sender, "Bubble does not exist");
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * bubbleOwnerFeePercent / 1 ether;
        require(msg.value >= price + protocolFee + subjectFee, "Insufficient payment");
        bubbleSharesBalance[bubbleAddress][msg.sender] = bubbleSharesBalance[bubbleAddress][msg.sender] + amount;
        bubbles[bubbleAddress].supply = supply + amount;
        bubbles[bubbleAddress].value = bubbles[bubbleAddress].value + price;
        totalValueDeposited = totalValueDeposited + price;
        emit Trade(msg.sender, bubbleAddress, true, amount, price, protocolFee, subjectFee, supply + amount);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = bubbleAddress.call{value: subjectFee}("");
        require(success1 && success2, "Unable to send funds");
    }

    function sellShares(address bubbleAddress, uint256 amount) public payable {
        uint256 supply = bubbles[bubbleAddress].supply;
        require(supply > amount, "Cannot sell the last share");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * bubbleOwnerFeePercent / 1 ether;
        require(bubbleSharesBalance[bubbleAddress][msg.sender] >= amount, "Insufficient shares");
        bubbleSharesBalance[bubbleAddress][msg.sender] = bubbleSharesBalance[bubbleAddress][msg.sender] - amount;
        bubbles[bubbleAddress].supply = supply - amount;
        bubbles[bubbleAddress].value = bubbles[bubbleAddress].value - price;
        totalValueDeposited = totalValueDeposited - price;
        emit Trade(msg.sender, bubbleAddress, false, amount, price, protocolFee, subjectFee, supply - amount);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = bubbleAddress.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

    function endRound() public canFinish {
        uint requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        Round storage round = rounds[currentRound];
        round.status = RoundStatus.FetchingRandomNumber;
        round.vrfRequestStatus = VrfRequestStatus({
            requestId: requestId,
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](numWords)
        });
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        Round storage round = rounds[currentRound];
        require(round.vrfRequestStatus.paid > 0, "Request not found");
        require(round.vrfRequestStatus.requestId == _requestId, "Request ID mismatch");
        round.vrfRequestStatus.randomWords = _randomWords;
        round.status = RoundStatus.RecievedRandomNumber;

        distributeReward(50);
    }

    function distributeReward(uint256 count) public canDistributeRewards {
        Round storage round = rounds[currentRound];
        uint256 endIndex = round.lastProcessedIndex + count > bubbleAddresses.length ? bubbleAddresses.length : round.lastProcessedIndex + count;
        uint256 randomValue = round.vrfRequestStatus.randomWords[0];
        uint256 reward = 0;
        uint256 accumulatedValue = 0;  // Define accumulatedValue
        address winningBubbleAddress = address(0);  // Define winningBubbleAddress
        uint256 normalizedRandomValue = randomValue % totalValueDeposited;  // Assume it is derived from randomValue, adjust as per your logic
        uint256 i = round.lastProcessedIndex;
        for (i; i < endIndex; i++) {
            accumulatedValue += bubbles[bubbleAddresses[i]].value;
            if (normalizedRandomValue < accumulatedValue && winningBubbleAddress == address(0)) {
                winningBubbleAddress = bubbleAddresses[i];
                break;
            }
            bubbles[bubbleAddresses[i]].value -= bubbles[bubbleAddresses[i]].value / loserPercentDeduction;
            reward += bubbles[bubbleAddresses[i]].value / loserPercentDeduction;
        }
        for (i; i < endIndex; i++) {
            bubbles[bubbleAddresses[i]].value -= bubbles[bubbleAddresses[i]].value / loserPercentDeduction;
            reward += bubbles[bubbleAddresses[i]].value / loserPercentDeduction;
        }
        round.lastProcessedIndex = endIndex;
        require(winningBubbleAddress != address(0), "Winning address not initialized");
        bubbles[winningBubbleAddress].value += reward;

        if(round.lastProcessedIndex == bubbleAddresses.length) {
            round.status = RoundStatus.Finished;
            _startRound(currentRound + 1);
            emit RoundFinished(currentRound, totalValueDeposited, round.vrfRequestStatus.randomWords, winningBubbleAddress, reward);
        }
    }

    function _startRound(uint roundNumber) internal {
        currentRound = roundNumber;
        rounds[currentRound].startTime = block.timestamp;
        rounds[currentRound].status = RoundStatus.Open;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

}