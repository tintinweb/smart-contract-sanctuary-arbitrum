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

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
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

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";
import "./interfaces/AccessControllerInterface.sol";

/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that.
 */
contract SimpleWriteAccessController is AccessControllerInterface, ConfirmedOwner {
  bool public checkEnabled;
  mapping(address => bool) internal accessList;

  event AddedAccess(address user);
  event RemovedAccess(address user);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  constructor() ConfirmedOwner(msg.sender) {
    checkEnabled = true;
  }

  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(address _user, bytes memory) public view virtual override returns (bool) {
    return accessList[_user] || !checkEnabled;
  }

  /**
   * @notice Adds an address to the access list
   * @param _user The address to add
   */
  function addAccess(address _user) external onlyOwner {
    if (!accessList[_user]) {
      accessList[_user] = true;

      emit AddedAccess(_user);
    }
  }

  /**
   * @notice Removes an address from the access list
   * @param _user The address to remove
   */
  function removeAccess(address _user) external onlyOwner {
    if (accessList[_user]) {
      accessList[_user] = false;

      emit RemovedAccess(_user);
    }
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck() external onlyOwner {
    if (!checkEnabled) {
      checkEnabled = true;

      emit CheckAccessEnabled();
    }
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck() external onlyOwner {
    if (checkEnabled) {
      checkEnabled = false;

      emit CheckAccessDisabled();
    }
  }

  /**
   * @dev reverts if the caller does not have access
   */
  modifier checkAccess() {
    require(hasAccess(msg.sender, msg.data), "No access");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleReadAccessController.sol";
import "./interfaces/AccessControllerInterface.sol";
import "./interfaces/FlagsInterface.sol";

/**
 * @title The Flags contract
 * @notice Allows flags to signal to any reader on the access control list.
 * The owner can set flags, or designate other addresses to set flags. The
 * owner must turn the flags off, other setters cannot. An expected pattern is
 * to allow addresses to raise flags on themselves, so if you are subscribing to
 * FlagOn events you should filter for addresses you care about.
 */
contract Flags is FlagsInterface, SimpleReadAccessController {
  AccessControllerInterface public raisingAccessController;

  mapping(address => bool) private flags;

  event FlagRaised(address indexed subject);
  event FlagLowered(address indexed subject);
  event RaisingAccessControllerUpdated(address indexed previous, address indexed current);

  /**
   * @param racAddress address for the raising access controller.
   */
  constructor(address racAddress) {
    setRaisingAccessController(racAddress);
  }

  /**
   * @notice read the warning flag status of a contract address.
   * @param subject The contract address being checked for a flag.
   * @return A true value indicates that a flag was raised and a
   * false value indicates that no flag was raised.
   */
  function getFlag(address subject) external view override checkAccess returns (bool) {
    return flags[subject];
  }

  /**
   * @notice read the warning flag status of a contract address.
   * @param subjects An array of addresses being checked for a flag.
   * @return An array of bools where a true value for any flag indicates that
   * a flag was raised and a false value indicates that no flag was raised.
   */
  function getFlags(address[] calldata subjects) external view override checkAccess returns (bool[] memory) {
    bool[] memory responses = new bool[](subjects.length);
    for (uint256 i = 0; i < subjects.length; i++) {
      responses[i] = flags[subjects[i]];
    }
    return responses;
  }

  /**
   * @notice enable the warning flag for an address.
   * Access is controlled by raisingAccessController, except for owner
   * who always has access.
   * @param subject The contract address whose flag is being raised
   */
  function raiseFlag(address subject) external override {
    require(allowedToRaiseFlags(), "Not allowed to raise flags");

    tryToRaiseFlag(subject);
  }

  /**
   * @notice enable the warning flags for multiple addresses.
   * Access is controlled by raisingAccessController, except for owner
   * who always has access.
   * @param subjects List of the contract addresses whose flag is being raised
   */
  function raiseFlags(address[] calldata subjects) external override {
    require(allowedToRaiseFlags(), "Not allowed to raise flags");

    for (uint256 i = 0; i < subjects.length; i++) {
      tryToRaiseFlag(subjects[i]);
    }
  }

  /**
   * @notice allows owner to disable the warning flags for multiple addresses.
   * @param subjects List of the contract addresses whose flag is being lowered
   */
  function lowerFlags(address[] calldata subjects) external override onlyOwner {
    for (uint256 i = 0; i < subjects.length; i++) {
      address subject = subjects[i];

      if (flags[subject]) {
        flags[subject] = false;
        emit FlagLowered(subject);
      }
    }
  }

  /**
   * @notice allows owner to change the access controller for raising flags.
   * @param racAddress new address for the raising access controller.
   */
  function setRaisingAccessController(address racAddress) public override onlyOwner {
    address previous = address(raisingAccessController);

    if (previous != racAddress) {
      raisingAccessController = AccessControllerInterface(racAddress);

      emit RaisingAccessControllerUpdated(previous, racAddress);
    }
  }

  // PRIVATE

  function allowedToRaiseFlags() private view returns (bool) {
    return msg.sender == owner() || raisingAccessController.hasAccess(msg.sender, msg.data);
  }

  function tryToRaiseFlag(address subject) private {
    if (!flags[subject]) {
      flags[subject] = true;
      emit FlagRaised(subject);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleWriteAccessController.sol";

/**
 * @title SimpleReadAccessController
 * @notice Gives access to:
 * - any externally owned account (note that off-chain actors can always read
 * any contract storage regardless of on-chain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list
 * @dev SimpleReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * SimpleWriteAccessController for that.
 */
contract SimpleReadAccessController is SimpleWriteAccessController {
  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(address _user, bytes memory _calldata) public view virtual override returns (bool) {
    return super.hasAccess(_user, _calldata) || _user == tx.origin;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);

  function getFlags(address[] calldata) external view returns (bool[] memory);

  function raiseFlag(address) external;

  function raiseFlags(address[] calldata) external;

  function lowerFlags(address[] calldata) external;

  function setRaisingAccessController(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AddressAliasHelper} from "./vendor/arb-bridge-eth/v0.8.0-custom/contracts/libraries/AddressAliasHelper.sol";
import {ForwarderInterface} from "./interfaces/ForwarderInterface.sol";
import {AggregatorInterface} from "../interfaces/AggregatorInterface.sol";
import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {AggregatorV2V3Interface} from "../interfaces/AggregatorV2V3Interface.sol";
import {TypeAndVersionInterface} from "../interfaces/TypeAndVersionInterface.sol";
import {FlagsInterface} from "./interfaces/FlagsInterface.sol";
import {ArbitrumSequencerUptimeFeedInterface} from "./interfaces/ArbitrumSequencerUptimeFeedInterface.sol";
import {SimpleReadAccessController} from "../SimpleReadAccessController.sol";
import {ConfirmedOwner} from "../ConfirmedOwner.sol";

/**
 * @title ArbitrumSequencerUptimeFeed - L2 sequencer uptime status aggregator
 * @notice L2 contract that receives status updates from a specific L1 address,
 *  records a new answer if the status changed, and raises or lowers the flag on the
 *   stored Flags contract.
 */
contract ArbitrumSequencerUptimeFeed is
  AggregatorV2V3Interface,
  ArbitrumSequencerUptimeFeedInterface,
  TypeAndVersionInterface,
  SimpleReadAccessController
{
  /// @dev Round info (for uptime history)
  struct Round {
    bool status;
    uint64 timestamp;
  }

  /// @dev Packed state struct to save sloads
  struct FeedState {
    uint80 latestRoundId;
    bool latestStatus;
    uint64 latestTimestamp;
  }

  /// @notice Contract is not yet initialized
  error Uninitialized();
  /// @notice Contract is already initialized
  error AlreadyInitialized();
  /// @notice Sender is not the L2 messenger
  error InvalidSender();
  /// @notice Replacement for AggregatorV3Interface "No data present"
  error NoDataPresent();

  event Initialized();
  event L1SenderTransferred(address indexed from, address indexed to);
  /// @dev Emitted when an `updateStatus` call is ignored due to unchanged status or stale timestamp
  event UpdateIgnored(bool latestStatus, uint64 latestTimestamp, bool incomingStatus, uint64 incomingTimestamp);

  /// @dev Follows: https://eips.ethereum.org/EIPS/eip-1967
  address public constant FLAG_L2_SEQ_OFFLINE =
    address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));

  uint8 public constant override decimals = 0;
  string public constant override description = "L2 Sequencer Uptime Status Feed";
  uint256 public constant override version = 1;

  /// @dev Flags contract to raise/lower flags on, during status transitions
  FlagsInterface public immutable FLAGS;
  /// @dev L1 address
  address private s_l1Sender;
  /// @dev s_latestRoundId == 0 means this contract is uninitialized.
  FeedState private s_feedState = FeedState({latestRoundId: 0, latestStatus: false, latestTimestamp: 0});
  mapping(uint80 => Round) private s_rounds;

  /**
   * @param flagsAddress Address of the Flags contract on L2
   * @param l1SenderAddress Address of the L1 contract that is permissioned to call this contract
   */
  constructor(address flagsAddress, address l1SenderAddress) {
    setL1Sender(l1SenderAddress);

    FLAGS = FlagsInterface(flagsAddress);
  }

  /**
   * @notice Check if a roundId is valid in this current contract state
   * @dev Mainly used for AggregatorV2V3Interface functions
   * @param roundId Round ID to check
   */
  function isValidRound(uint256 roundId) private view returns (bool) {
    return roundId > 0 && roundId <= type(uint80).max && s_feedState.latestRoundId >= roundId;
  }

  /// @notice Check that this contract is initialised, otherwise throw
  function requireInitialized(uint80 latestRoundId) private pure {
    if (latestRoundId == 0) {
      revert Uninitialized();
    }
  }

  /**
   * @notice Initialise the first round. Can't be done in the constructor,
   *    because this contract's address must be permissioned by the the Flags contract
   *    (The Flags contract itself is a SimpleReadAccessController).
   */
  function initialize() external onlyOwner {
    FeedState memory feedState = s_feedState;
    if (feedState.latestRoundId != 0) {
      revert AlreadyInitialized();
    }

    uint64 timestamp = uint64(block.timestamp);
    bool currentStatus = FLAGS.getFlag(FLAG_L2_SEQ_OFFLINE);

    // Initialise roundId == 1 as the first round
    recordRound(1, currentStatus, timestamp);

    emit Initialized();
  }

  /**
   * @notice versions:
   *
   * - ArbitrumSequencerUptimeFeed 1.0.0: initial release
   *
   * @inheritdoc TypeAndVersionInterface
   */
  function typeAndVersion() external pure virtual override returns (string memory) {
    return "ArbitrumSequencerUptimeFeed 1.0.0";
  }

  /// @return L1 sender address
  function l1Sender() public view virtual returns (address) {
    return s_l1Sender;
  }

  /**
   * @notice Set the allowed L1 sender for this contract to a new L1 sender
   * @dev Can be disabled by setting the L1 sender as `address(0)`. Accessible only by owner.
   * @param to new L1 sender that will be allowed to call `updateStatus` on this contract
   */
  function transferL1Sender(address to) external virtual onlyOwner {
    setL1Sender(to);
  }

  /// @notice internal method that stores the L1 sender
  function setL1Sender(address to) private {
    address from = s_l1Sender;
    if (from != to) {
      s_l1Sender = to;
      emit L1SenderTransferred(from, to);
    }
  }

  /**
   * @notice Messages sent by the stored L1 sender will arrive on L2 with this
   *  address as the `msg.sender`
   * @return L2-aliased form of the L1 sender address
   */
  function aliasedL1MessageSender() public view returns (address) {
    return AddressAliasHelper.applyL1ToL2Alias(l1Sender());
  }

  /**
   * @dev Returns an AggregatorV2V3Interface compatible answer from status flag
   *
   * @param status The status flag to convert to an aggregator-compatible answer
   */
  function getStatusAnswer(bool status) private pure returns (int256) {
    return status ? int256(1) : int256(0);
  }

  /**
   * @notice Raise or lower the flag on the stored Flags contract.
   */
  function forwardStatusToFlags(bool status) private {
    if (status) {
      FLAGS.raiseFlag(FLAG_L2_SEQ_OFFLINE);
    } else {
      FLAGS.lowerFlag(FLAG_L2_SEQ_OFFLINE);
    }
  }

  /**
   * @notice Helper function to record a round and set the latest feed state.
   *
   * @param roundId The round ID to record
   * @param status Sequencer status
   * @param timestamp Block timestamp of status update
   */
  function recordRound(
    uint80 roundId,
    bool status,
    uint64 timestamp
  ) private {
    Round memory nextRound = Round(status, timestamp);
    FeedState memory feedState = FeedState(roundId, status, timestamp);

    s_rounds[roundId] = nextRound;
    s_feedState = feedState;

    emit NewRound(roundId, msg.sender, timestamp);
    emit AnswerUpdated(getStatusAnswer(status), roundId, timestamp);
  }

  /**
   * @notice Record a new status and timestamp if it has changed since the last round.
   * @dev This function will revert if not called from `l1Sender` via the L1->L2 messenger.
   *
   * @param status Sequencer status
   * @param timestamp Block timestamp of status update
   */
  function updateStatus(bool status, uint64 timestamp) external override {
    FeedState memory feedState = s_feedState;
    requireInitialized(feedState.latestRoundId);
    if (msg.sender != aliasedL1MessageSender()) {
      revert InvalidSender();
    }

    // Ignore if status did not change or latest recorded timestamp is newer
    if (feedState.latestStatus == status || feedState.latestTimestamp > timestamp) {
      emit UpdateIgnored(feedState.latestStatus, feedState.latestTimestamp, status, timestamp);
      return;
    }

    // Prepare a new round with updated status
    feedState.latestRoundId += 1;
    recordRound(feedState.latestRoundId, status, timestamp);

    forwardStatusToFlags(status);
  }

  /// @inheritdoc AggregatorInterface
  function latestAnswer() external view override checkAccess returns (int256) {
    FeedState memory feedState = s_feedState;
    requireInitialized(feedState.latestRoundId);
    return getStatusAnswer(feedState.latestStatus);
  }

  /// @inheritdoc AggregatorInterface
  function latestTimestamp() external view override checkAccess returns (uint256) {
    FeedState memory feedState = s_feedState;
    requireInitialized(feedState.latestRoundId);
    return feedState.latestTimestamp;
  }

  /// @inheritdoc AggregatorInterface
  function latestRound() external view override checkAccess returns (uint256) {
    FeedState memory feedState = s_feedState;
    requireInitialized(feedState.latestRoundId);
    return feedState.latestRoundId;
  }

  /// @inheritdoc AggregatorInterface
  function getAnswer(uint256 roundId) external view override checkAccess returns (int256) {
    requireInitialized(s_feedState.latestRoundId);
    if (isValidRound(roundId)) {
      return getStatusAnswer(s_rounds[uint80(roundId)].status);
    }

    return 0;
  }

  /// @inheritdoc AggregatorInterface
  function getTimestamp(uint256 roundId) external view override checkAccess returns (uint256) {
    requireInitialized(s_feedState.latestRoundId);
    if (isValidRound(roundId)) {
      return s_rounds[uint80(roundId)].timestamp;
    }

    return 0;
  }

  /// @inheritdoc AggregatorV3Interface
  function getRoundData(uint80 _roundId)
    public
    view
    override
    checkAccess
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    requireInitialized(s_feedState.latestRoundId);

    if (isValidRound(_roundId)) {
      Round memory round = s_rounds[_roundId];
      answer = getStatusAnswer(round.status);
      startedAt = uint256(round.timestamp);
    } else {
      answer = 0;
      startedAt = 0;
    }
    roundId = _roundId;
    updatedAt = startedAt;
    answeredInRound = roundId;
  }

  /// @inheritdoc AggregatorV3Interface
  function latestRoundData()
    external
    view
    override
    checkAccess
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    FeedState memory feedState = s_feedState;
    requireInitialized(feedState.latestRoundId);

    roundId = feedState.latestRoundId;
    answer = getStatusAnswer(feedState.latestStatus);
    startedAt = feedState.latestTimestamp;
    updatedAt = startedAt;
    answeredInRound = roundId;
  }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// NOTICE: pragma change from original (^0.6.11)
pragma solidity ^0.8.0;

library AddressAliasHelper {
  uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

  /// @notice Utility function that converts the msg.sender viewed in the L2 to the
  /// address in the L1 that submitted a tx to the inbox
  /// @param l1Address L2 address as viewed in msg.sender
  /// @return l2Address the address in the L1 that triggered the tx to L2
  function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
    unchecked {
      l2Address = address(uint160(l1Address) + offset);
    }
  }

  /// @notice Utility function that converts the msg.sender viewed in the L2 to the
  /// address in the L1 that submitted a tx to the inbox
  /// @param l2Address L2 address as viewed in msg.sender
  /// @return l1Address the address in the L1 that triggered the tx to L2
  function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
    unchecked {
      l1Address = address(uint160(l2Address) - offset);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ForwarderInterface - forwards a call to a target, under some conditions
interface ForwarderInterface {
  /**
   * @notice forward calls the `target` with `data`
   * @param target contract address to be called
   * @param data to send to target contract
   */
  function forward(address target, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);

  function getFlags(address[] calldata) external view returns (bool[] memory);

  function raiseFlag(address) external;

  function raiseFlags(address[] calldata) external;

  function lowerFlag(address) external;

  function lowerFlags(address[] calldata) external;

  function setRaisingAccessController(address) external;

  function setLoweringAccessController(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ArbitrumSequencerUptimeFeedInterface {
  function updateStatus(bool status, uint64 timestamp) external;
}