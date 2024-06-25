// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "lib/chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "lib/chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

/* Errors */
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);
error Raffle__RaffleNotOpen();
error WithdrawTransfer();

contract Ethpot is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    mapping(uint256 => mapping(address => uint256)) private s_tickets;
    mapping(uint256 => address) private s_playersMapping;
    mapping(address => uint256) private s_playerPoints;

    /* State variables */
    // Chainlink VRF Variables
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private s_interval;
    uint256 private s_entranceFee;
    uint256 private s_playerTimeStamp;
    uint256 private s_seventhDayTimeStamp;
    address private s_recentWinner;
    address private s_V1;
    address private s_V2;
    RaffleState private s_raffleState;
    uint256 private s_treasuryV1Balance;
    uint256 private s_treasuryV2Balance;
    uint256 private s_raffleBalance;
    uint256 private s_raffleBalanceSeventhDay;
    uint256 private s_feePercentV1;
    uint256 private s_feePercentV2;
    uint256 private s_feePercentRaffleSeventhDay;
    uint256 private s_gameCount = 1;
    uint256 private s_lotteryDay = 1;
    uint256 private s_playersCount;
    uint256 private s_bonusPoints;
    uint256 private s_period = 7;

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(
        address indexed player,
        uint256 indexed ticketsOfPlayer,
        uint256 gameCount
    );
    event WinnerPicked(
        address indexed player,
        uint256 indexed ticketsOfPlayer,
        uint256 indexed amountWon,
        uint256 gameCount,
        uint256 ticketsInRound
    );
    event WeeklyWinnerPicked(
        address indexed player,
        uint256 indexed ticketsOfPlayer,
        uint256 indexed amountWon,
        uint256 gameCount,
        uint256 ticketsInRound
    );

    /* Functions */
    constructor(
        address vrfCoordinatorV2Plus,
        uint256 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address V1,
        address V2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2Plus) {
        i_gasLane = gasLane;
        s_interval = interval;
        i_subscriptionId = subscriptionId;
        s_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN;
        s_playerTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        s_bonusPoints = 100;
        s_V1 = V1;
        s_V2 = V2;
    }

    function enterRaffle(uint256 entries) public payable {
        require((msg.value >= s_entranceFee * entries) && entries > 0);

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        if (s_playersCount == 0) {
            s_playerTimeStamp = block.timestamp;
        }

        s_raffleBalanceSeventhDay += (((s_entranceFee * entries) *
            (s_feePercentRaffleSeventhDay * 1e2)) / 1e4);
        s_treasuryV1Balance += (((s_entranceFee * entries) *
            (s_feePercentV1 * 1e2)) / 1e4);
        s_treasuryV2Balance += (((s_entranceFee * entries) *
            (s_feePercentV2 * 1e2)) / 1e4);
        s_raffleBalance += ((s_entranceFee * entries) -
            (((s_entranceFee * entries) *
                (s_feePercentRaffleSeventhDay * 1e2)) / 1e4) -
            (((s_entranceFee * entries) * (s_feePercentV1 * 1e2)) / 1e4) -
            (((s_entranceFee * entries) * (s_feePercentV2 * 1e2)) / 1e4));
        for (uint256 i = 0; i < entries; i++) {
            s_playersMapping[s_playersCount] = msg.sender;
            ++s_playersCount;
            ++s_tickets[s_gameCount][msg.sender];
        }

        s_playerPoints[msg.sender] += entries * s_bonusPoints;

        emit RaffleEnter(
            msg.sender,
            s_tickets[s_gameCount][msg.sender],
            s_gameCount
        );
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_playerTimeStamp) > s_interval);
        bool hasPlayers = s_playersCount > 0;
        bool hasBalance = s_raffleBalance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                s_raffleBalance,
                s_playersCount,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        if (s_lotteryDay == s_period) {
            uint256 indexOfWinner = randomWords[0] % s_playersCount;
            address recentWinner = s_playersMapping[indexOfWinner];
            s_recentWinner = recentWinner;
            s_raffleState = RaffleState.OPEN;
            s_seventhDayTimeStamp = block.timestamp;
            uint256 playersCount = s_playersCount;
            s_playersCount = 0;
            uint256 newBalance = s_raffleBalanceSeventhDay + s_raffleBalance;
            s_raffleBalanceSeventhDay = 0;
            s_raffleBalance = 0;
            (bool success, ) = recentWinner.call{value: newBalance}("");
            require(success, "Transfer failed");
            s_lotteryDay = 1;
            emit WeeklyWinnerPicked(
                recentWinner,
                s_tickets[s_gameCount][s_recentWinner],
                newBalance,
                s_gameCount,
                playersCount
            );
            ++s_gameCount;
        } else {
            uint256 indexOfWinner = randomWords[0] % s_playersCount;
            address recentWinner = s_playersMapping[indexOfWinner];
            s_recentWinner = recentWinner;
            s_raffleState = RaffleState.OPEN;
            uint256 playersCount = s_playersCount;
            s_playersCount = 0;
            uint256 newBalance = s_raffleBalance;
            s_raffleBalance = 0;
            (bool success, ) = recentWinner.call{value: newBalance}("");
            require(success, "Transfer failed");
            ++s_lotteryDay;
            emit WinnerPicked(
                recentWinner,
                s_tickets[s_gameCount][recentWinner],
                newBalance,
                s_gameCount,
                playersCount
            );
            ++s_gameCount;
        }
    }

    /** Recovery Functions and Setters */
    function recoverTreasuryV1() external {
        require(msg.sender == s_V1, "Address Not Allowed");
        uint256 newBalance = s_treasuryV1Balance;
        s_treasuryV1Balance = 0;
        (bool success, ) = s_V1.call{value: newBalance}("");
        require(success, "Transfer failed");
    }

    function setInterval(uint256 interval) external onlyOwner {
        s_interval = interval;
    }

    function setEntraceFee(uint256 entranceFee) external onlyOwner {
        s_entranceFee = entranceFee;
    }

    function setFeePercentV1(uint256 feePercent) external onlyOwner {
        require(feePercent <= 25, "More than 25");
        s_feePercentV1 = feePercent;
    }

    function setFeePercentV2(uint256 feePercent) external {
        require(feePercent <= 25, "More than 25");
        require(msg.sender == s_V2, "Address Not Allowed");
        s_feePercentV2 = feePercent;
    }

    function setFeePercentRaffleSeventhDay(
        uint256 feePercent
    ) external onlyOwner {
        require(feePercent <= 25, "More than 25");
        s_feePercentRaffleSeventhDay = feePercent;
    }

    function setDay(uint256 day) external onlyOwner {
        s_lotteryDay = day; //days 1-period, in case of missed day add 1 for each one
    }

    function setPeriod(uint256 period) external onlyOwner {
        s_period = period; //7 => 1 week
    }

    function setNewWeeklyPrize() external payable onlyOwner {
        s_raffleBalanceSeventhDay += msg.value; //1e18 for prize
    }

    function recoverTreasuryV2() external {
        require(msg.sender == s_V2, "Address Not Allowed");
        uint256 newBalance = s_treasuryV2Balance;
        s_treasuryV2Balance = 0;
        (bool success, ) = s_V2.call{value: newBalance}("");
        require(success, "Transfer failed");
    }

    function emergencyRecovery() external onlyOwner {
        require(s_raffleState == RaffleState.CALCULATING, "Not emergency");
        uint256 newBalance = s_treasuryV2Balance;
        s_treasuryV2Balance = 0;
        (bool success, ) = s_V2.call{value: address(this).balance}("");
        require(success, "Transfer failed");
        newBalance = s_treasuryV1Balance;
        s_treasuryV1Balance = 0;
        (success, ) = s_V1.call{value: address(this).balance}("");
        require(success, "Transfer failed");
        newBalance = address(this).balance;
        s_raffleBalance = 0;
        s_raffleBalanceSeventhDay = 0;
        (success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    /** Getter Functions */
    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_playersMapping[index];
    }

    function getPeriod() public view returns (uint256) {
        return s_period;
    }

    function getPlayerTimeStamp() public view returns (uint256) {
        return s_playerTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return s_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return s_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_playersCount;
    }

    function getTicketsOfPlayer(
        address player
    ) external view returns (uint256) {
        return s_tickets[s_gameCount][player];
    }

    function getVrfCoordinatorV2Address() public view returns (address) {
        return address(s_vrfCoordinator);
    }

    function getGasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    function getSeventhDayTimestamp() public view returns (uint256) {
        return s_seventhDayTimeStamp;
    }

    function getBonusRate() public view returns (uint256) {
        return s_bonusPoints;
    }

    function getBonusPoints(address pointsOwner) public view returns (uint256) {
        return s_playerPoints[pointsOwner];
    }

    function getV1() public view returns (address) {
        return s_V1;
    }

    function getV2() public view returns (address) {
        return s_V2;
    }

    function getTreasuryV1Balance() public view returns (uint256) {
        return s_treasuryV1Balance;
    }

    function getTreasuryV2Balance() public view returns (uint256) {
        return s_treasuryV2Balance;
    }

    function getRaffleBalance() public view returns (uint256) {
        return s_raffleBalance;
    }

    function getRaffleBalanceSeventhDay() public view returns (uint256) {
        return s_raffleBalanceSeventhDay;
    }

    function getFeePercentV1() public view returns (uint256) {
        return s_feePercentV1;
    }

    function getFeePercentRaffleSeventhDay() public view returns (uint256) {
        return s_feePercentRaffleSeventhDay;
    }

    function getGameCount() public view returns (uint256) {
        return s_gameCount;
    }

    function getCurrentLotteryDay() public view returns (uint256) {
        return s_lotteryDay;
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
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
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

import {AutomationBase} from "./AutomationBase.sol";
import {AutomationCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function _preventExecution() internal view {
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin != address(0) && tx.origin != address(0x1111111111111111111111111111111111111111)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    _preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable-next-line interface-starts-with-i
interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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

import {IOwnable} from "../interfaces/IOwnable.sol";

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