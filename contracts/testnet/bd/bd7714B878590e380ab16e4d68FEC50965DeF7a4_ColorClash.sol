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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ColorClash is 
    Ownable,
    VRFV2WrapperConsumerBase
{

    //Protocol constants
    uint256 public constant protocolFeePercent = 0.02 ether; // 2%
    uint256 public constant deductionFee = 0.3 ether; // 30%
    uint256 public constant GAME_DURATION = 59 minutes; // 1 hour

    //Chainlink VRF constants
    uint32 callbackGasLimit = 1000000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    address linkAddress = 0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28;
    address wrapperAddress = 0x674Cda1Fef7b3aA28c535693D658B42424bb7dBD;

    //Colors of the rainbow
    enum ColorTypes {
        Red,
        Orange,
        Yellow,
        Green,
        Blue,
        Indigo,
        Violet,
        None
    }

    enum RoundState {
        None, // Round has not started
        Open, // Round is open for contributions
        FetchingRandomNumber, // Fetching random words
        Finished, // Random words received and winner determined
        NoContest // No color has any contributions
    }

    struct VrfRequestStatus {
        uint requestId;
        uint256 paid; // amount paid in link
        uint256[] randomWords;
    }

    struct Round {
        bool ended;
        RoundState status;
        ColorTypes winner;
        VrfRequestStatus vrfRequestStatus;
    }

    struct Color {
        uint256 value;
        uint256 supply;
    }

    //events
    event FetchingRandomNumber(uint256 timestamp, uint256 roundNumber);
    event RandomNumberReceived(uint256 timestamp, uint256 roundNumber, uint256 randomNumber);
    event RoundStarted(uint256 timestamp, uint256 roundNumber, uint256 startTime, uint256 endTime);
    event RoundColorDeduction(uint256 timestamp, uint256 roundNumber, ColorTypes color, uint256 deduction, uint256 value, uint256 supply);
    event RoundEnded(uint256 timestamp, uint256 roundNumber, RoundState status, ColorTypes winner, uint256 reward, uint256 value, uint256 supply);
    event Trade(uint256 timestamp, address trader, ColorTypes color, bool isBuy, uint256 shareAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 supply, uint256 value);

    //dApp state variables
    address public protocolFeeDestination;
    uint256 public gameEndTime;
    uint256 public currentRound = 0;
    uint256 public totalValueDeposited;
    mapping(uint256 => Round) public rounds;
    mapping(ColorTypes => Color) public colors;
    mapping(ColorTypes => mapping(address => uint256)) public colorSharesBalance;

    modifier canContributeRound() {
        require(block.timestamp < gameEndTime, "Contribution time has ended");
        require(rounds[currentRound].status == RoundState.Open, "Round not open yet");
        require(!rounds[currentRound].ended, "Current round has ended");
        _;
    }

    modifier canEndRound() {
        require(block.timestamp >= gameEndTime, "Round cannot be ended yet");
        require(rounds[currentRound].status == RoundState.Open, "Round not open yet");
        require(!rounds[currentRound].ended, "Current round already ended");
        _;
    }

    modifier isRoundOver(uint roundNumber) {
        require(rounds[roundNumber].ended, "Round not ended yet");
        _;
    }

    constructor() 
        Ownable(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        protocolFeeDestination = msg.sender;
        _startNewRound();
    }

    //Bonding curve is y=x;
    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000;
    }

    function getScalingFactor(ColorTypes color) public view returns (uint256) {
        uint256 xf = colors[color].supply > 1 ? colors[color].supply - 1 : 0;
        uint256 originalValue = getPrice(1, xf);
        
        // Check to prevent division by zero
        if (originalValue == 0) {
            return 1 ether; // Return default scaling factor if original value is zero
        }
        
        uint256 scalingFactor = colors[color].value * 1 ether / originalValue;
        return scalingFactor == 0 ? 1 ether : scalingFactor;
    }

    function getAdjustedPrice(uint256 supply, uint256 amount, uint256 scalingFactor) public pure returns (uint256) {
        uint256 price = getPrice(supply, amount);
        return (price * scalingFactor) / 1 ether;
    }

    function getBuyPrice(ColorTypes color, uint256 amount) public view returns (uint256) {
        uint256 scalingFactor = getScalingFactor(color);
        return getAdjustedPrice(colors[color].supply, amount, scalingFactor);
    }

    function getSellPrice(ColorTypes color, uint256 amount) public view returns (uint256) {
        uint256 scalingFactor = getScalingFactor(color);
        return getAdjustedPrice(colors[color].supply - amount, amount, scalingFactor);
    }

    function getBuyPriceAfterFee(ColorTypes color, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(color, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        return price + protocolFee;
    }

    function getSellPriceAfterFee(ColorTypes color, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(color, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        return price - protocolFee;
    }

    function buyShares(ColorTypes color, uint256 amount) public payable {
        uint256 supply = colors[color].supply;
        uint256 price = getBuyPrice(color, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        require(msg.value >= price + protocolFee, "Insufficient payment");
        colorSharesBalance[color][msg.sender] = colorSharesBalance[color][msg.sender] + amount;
        colors[color].supply = supply + amount;
        colors[color].value = colors[color].value + price;
        totalValueDeposited = totalValueDeposited + price;
        emit Trade(block.timestamp, msg.sender, color, true, amount, price, protocolFee, supply + amount, colors[color].value);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        require(success1, "Unable to send funds");
    }

    function sellShares(ColorTypes color, uint256 amount) public payable {
        uint256 supply = colors[color].supply;
        require(supply > amount, "Cannot sell the last share");
        uint256 price = getSellPrice(color, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        require(colorSharesBalance[color][msg.sender] >= amount, "Insufficient shares");
        colorSharesBalance[color][msg.sender] = colorSharesBalance[color][msg.sender] - amount;
        colors[color].supply = supply - amount;
        colors[color].value = colors[color].value - price;
        totalValueDeposited = totalValueDeposited - price;
        emit Trade(block.timestamp, msg.sender, color, false, amount, price, protocolFee, supply - amount, colors[color].value);
        (bool success1, ) = msg.sender.call{value: price - protocolFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        require(success1 && success2, "Unable to send funds");
    }

    function endRound() external canEndRound {
        Round storage round = rounds[currentRound];
        round.status = RoundState.FetchingRandomNumber;

        //Confirm at least two colors have contributions
        uint256 contributingColors = 0;
        for (uint256 index = 0; index < 7; index++) {
            ColorTypes colorType = ColorTypes(index);
            Color memory color = colors[colorType];

            if (color.value > 0) {
                contributingColors++;
            }
        }
        if (contributingColors == 0) {
            round.status = RoundState.NoContest;
            round.ended = true;
            emit RoundEnded(block.timestamp, currentRound, round.status, ColorTypes.None, 0, 0, 0);
            _startNewRound();
            return;
        }


        //Fetch random number
        uint requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        round.vrfRequestStatus = VrfRequestStatus({
            requestId: requestId,
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](numWords)
        });
        emit FetchingRandomNumber(block.timestamp, currentRound);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        Round storage round = rounds[currentRound];
        require(round.vrfRequestStatus.paid > 0, "Request not found");
        require(round.vrfRequestStatus.requestId == _requestId, "Request ID mismatch");
        round.vrfRequestStatus.randomWords = _randomWords;

        emit RandomNumberReceived(block.timestamp, currentRound, _randomWords[0]);

        _determineWinner();
        _startNewRound();
    }

    function testFulfillRandomWords(
        uint256 _randomWord
    ) public {
        Round storage round = rounds[currentRound];
        round.vrfRequestStatus.randomWords = new uint256[](numWords);
        round.vrfRequestStatus.randomWords[0] = _randomWord;
        emit RandomNumberReceived(block.timestamp, currentRound, _randomWord);
        _determineWinner();
        _startNewRound();
    }

    //determin winner function, called by fulfillRandomWords takes in the random number and determines the winner
    //sets the round status and ended to true
    //uses the random number to determine the winner based on the size of red contributions and blue contributions, bigger the contribution the bigger the chance of winning
    function _determineWinner() private {
        Round storage round = rounds[currentRound];
        uint256 randomNumber = round.vrfRequestStatus.randomWords[0];
        round.ended = true;
        uint256 randomThreshold = randomNumber % totalValueDeposited;

        uint256 accumulatedValue = 0;
        uint256 reward = 0;
        uint256 i = 0;
        while(i < 7){
            ColorTypes colorType = ColorTypes(i);
            Color memory color = colors[colorType];
            accumulatedValue += color.value;

            if (round.winner==ColorTypes.None && accumulatedValue > randomThreshold) {
                round.winner = colorType;
                i++;
                continue;
            } 
            
            //deduct 10% of the value from the color
            uint256 deduction = color.value * deductionFee / 1 ether;
            colors[colorType].value = color.value - deduction;
            reward += deduction;
            emit RoundColorDeduction(block.timestamp, currentRound, colorType, deduction, colors[colorType].value, colors[colorType].supply);
            i++;
            
        }

        //pay the winner
        colors[round.winner].value += reward;
        round.status = RoundState.Finished;

        emit RoundEnded(block.timestamp, currentRound, round.status, round.winner, reward, colors[round.winner].value, colors[round.winner].supply);
    }

    function _startNewRound() private {
        currentRound++;
        gameEndTime = block.timestamp + GAME_DURATION;
        rounds[currentRound].status = RoundState.Open;
        rounds[currentRound].ended = false;
        rounds[currentRound].winner = ColorTypes.None;
        emit RoundStarted(block.timestamp, currentRound, block.timestamp, gameEndTime);
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    
}