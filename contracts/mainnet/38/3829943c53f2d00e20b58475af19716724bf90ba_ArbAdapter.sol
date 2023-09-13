// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseAdapter, IBaseAdapter} from '../BaseAdapter.sol';
import {IArbAdapter} from './IArbAdapter.sol';
import {IInbox} from 'nitro-contracts/bridge/IInbox.sol';
import {AddressAliasHelper} from 'nitro-contracts/libraries/AddressAliasHelper.sol';
import {Errors} from '../../libs/Errors.sol';
import {ChainIds} from '../../libs/ChainIds.sol';

/**
 * @title ArbAdapter
 * @author BGD Labs
 * @notice Arbitrum bridge adapter. Used to send and receive messages cross chain between Ethereum and Arbitrum
 * @dev it uses the eth balance of CrossChainController contract to pay for message bridging as the method to bridge
        is called via delegate call
 * @dev note that this adapter can only be used for the communication path ETHEREUM -> ARBITRUM
 */
contract ArbAdapter is IArbAdapter, BaseAdapter {
  /// @inheritdoc IArbAdapter
  address public immutable INBOX;

  /// @inheritdoc IArbAdapter
  address public immutable DESTINATION_CCC;

  /// @inheritdoc IArbAdapter
  uint256 public constant BASE_FEE_MARGIN = 10 gwei;

  /// @inheritdoc IArbAdapter
  uint256 public constant L2_MAX_FEE_PER_GAS = 1 gwei;

  /**
   * @param crossChainController address of the cross chain controller that will use this bridge adapter
   * @param inbox arbitrum entry point address
   * @param trustedRemotes list of remote configurations to set as trusted
   */
  constructor(
    address crossChainController,
    address inbox,
    address destinationCCC,
    TrustedRemotesConfig[] memory trustedRemotes
  ) BaseAdapter(crossChainController, trustedRemotes) {
    INBOX = inbox;
    DESTINATION_CCC = destinationCCC;
  }

  /// @inheritdoc IArbAdapter
  function getRequiredGas(
    uint256 bytesLength,
    uint256 gasLimit
  ) public view returns (uint256, uint256) {
    return (
      IInbox(INBOX).calculateRetryableSubmissionFee(bytesLength, block.basefee + BASE_FEE_MARGIN),
      gasLimit * L2_MAX_FEE_PER_GAS
    );
  }

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 destinationGasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external returns (address, uint256) {
    require(
      isDestinationChainIdSupported(destinationChainId),
      Errors.DESTINATION_CHAIN_ID_NOT_SUPPORTED
    );
    require(receiver != address(0), Errors.RECEIVER_NOT_SET);

    bytes memory data = abi.encodeWithSelector(IArbAdapter.arbReceive.selector, message);

    (uint256 maxSubmission, uint256 maxRedemption) = getRequiredGas(
      data.length,
      destinationGasLimit
    );
    uint256 ticketID = _forwardMessage(
      MessageInformation({
        receiver: receiver,
        destinationGasLimit: destinationGasLimit,
        encodedMessage: data,
        maxSubmission: maxSubmission,
        maxRedemption: maxRedemption
      })
    );

    return (INBOX, ticketID);
  }

  /// @inheritdoc IArbAdapter
  function arbReceive(bytes calldata message) external {
    uint256 originChainId = getOriginChainId();
    address srcAddress = AddressAliasHelper.undoL1ToL2Alias(msg.sender);
    require(
      _trustedRemotes[originChainId] == srcAddress && srcAddress != address(0),
      Errors.REMOTE_NOT_TRUSTED
    );

    _registerReceivedMessage(message, originChainId);
  }

  /// @inheritdoc IArbAdapter
  function getOriginChainId() public view virtual returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  /// @inheritdoc IArbAdapter
  function isDestinationChainIdSupported(uint256 chainId) public view virtual returns (bool) {
    return chainId == ChainIds.ARBITRUM;
  }

  /// @inheritdoc IBaseAdapter
  function nativeToInfraChainId(uint256 nativeChainId) public pure override returns (uint256) {
    return nativeChainId;
  }

  /// @inheritdoc IBaseAdapter
  function infraToNativeChainId(uint256 infraChainId) public pure override returns (uint256) {
    return infraChainId;
  }

  /**
   * @notice method that forwards a message to a destination
   * @param message object with the necessary information to pay and send a message to a destination
   * @return identifier of the sent transaction
   */
  function _forwardMessage(MessageInformation memory message) internal returns (uint256) {
    uint256 requiredGas = message.maxSubmission + message.maxRedemption;
    require(address(this).balance >= requiredGas, Errors.NOT_ENOUGH_VALUE_TO_PAY_BRIDGE_FEES);

    return
      IInbox(INBOX).createRetryableTicket{value: requiredGas}(
        message.receiver,
        0,
        message.maxSubmission,
        DESTINATION_CCC,
        DESTINATION_CCC,
        message.destinationGasLimit,
        L2_MAX_FEE_PER_GAS,
        message.encodedMessage
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IBaseAdapter} from './IBaseAdapter.sol';
import {IBaseCrossChainController} from '../interfaces/IBaseCrossChainController.sol';
import {Errors} from '../libs/Errors.sol';

/**
 * @title BaseAdapter
 * @author BGD Labs
 * @notice base contract implementing the method to route a bridged message to the CrossChainController contract.
 * @dev All bridge adapters must implement this contract
 */
abstract contract BaseAdapter is IBaseAdapter {
  IBaseCrossChainController public immutable CROSS_CHAIN_CONTROLLER;

  // @dev this is the original address of the contract. Required to identify and prevent delegate calls.
  address private immutable _selfAddress;

  // (standard chain id -> origin forwarder address) saves for every chain the address that can forward messages to this adapter
  mapping(uint256 => address) internal _trustedRemotes;

  /**
   * @param crossChainController address of the CrossChainController the bridged messages will be routed to
   */
  constructor(address crossChainController, TrustedRemotesConfig[] memory originConfigs) {
    require(crossChainController != address(0), Errors.INVALID_BASE_ADAPTER_CROSS_CHAIN_CONTROLLER);
    CROSS_CHAIN_CONTROLLER = IBaseCrossChainController(crossChainController);

    _selfAddress = address(this);

    for (uint256 i = 0; i < originConfigs.length; i++) {
      TrustedRemotesConfig memory originConfig = originConfigs[i];
      require(originConfig.originForwarder != address(0), Errors.INVALID_TRUSTED_REMOTE);
      _trustedRemotes[originConfig.originChainId] = originConfig.originForwarder;
      emit SetTrustedRemote(originConfig.originChainId, originConfig.originForwarder);
    }
  }

  /// @inheritdoc IBaseAdapter
  function nativeToInfraChainId(uint256 nativeChainId) public view virtual returns (uint256);

  /// @inheritdoc IBaseAdapter
  function infraToNativeChainId(uint256 infraChainId) public view virtual returns (uint256);

  function setupPayments() external virtual {}

  /// @inheritdoc IBaseAdapter
  function getTrustedRemoteByChainId(uint256 chainId) external view returns (address) {
    return _trustedRemotes[chainId];
  }

  /**
   * @notice calls CrossChainController to register the bridged payload
   * @param _payload bytes containing the bridged message
   * @param originChainId id of the chain where the message originated
   */
  function _registerReceivedMessage(bytes calldata _payload, uint256 originChainId) internal {
    // this method should be always called via call
    require(address(this) == _selfAddress, Errors.DELEGATE_CALL_FORBIDDEN);
    CROSS_CHAIN_CONTROLLER.receiveCrossChainMessage(_payload, originChainId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IArbAdapter
 * @author BGD Labs
 * @notice interface containing the events, objects and method definitions used in the Arbitrum bridge adapter
 */
interface IArbAdapter {
  /**
   * @notice object used to store the message information
   * @param receiver address that will receive the message
   * @param destinationGasLimit max gas limit to be used on destination chain
   * @param maxSubmission gas required for ticket submission
   * @param maxRedemption gas required for ticket redemption
   * @param encodedMessage calldata used on destination chain
   */
  struct MessageInformation {
    address receiver;
    uint256 destinationGasLimit;
    uint256 maxSubmission;
    uint256 maxRedemption;
    bytes encodedMessage;
  }

  /**
   * @notice method to get the INBOX address
   * @return address of the INBOX
   */
  function INBOX() external view returns (address);

  /**
   * @notice method to get the destination CrossChainController
   * @return address of the dstination CrossChainController
   */
  function DESTINATION_CCC() external view returns (address);

  /**
   * @notice amount of gwei to overpay on basefee for fast submission
   * @return fee margin in gwei
   */
  function BASE_FEE_MARGIN() external view returns (uint256);

  /**
   * @notice method to get the max fee per gas on destination chain
   * @return max fee per gas
   * @dev There is currently no oracle on L1 exposing gasPrice of arbitrum.
          Therefore we overpay by assuming 1 gwei (10x of current price).
   */
  function L2_MAX_FEE_PER_GAS() external view returns (uint256);

  /**
   * @notice method to know if a destination chain is supported
   * @return flag indicating if the destination chain is supported
   */
  function isDestinationChainIdSupported(uint256 chainId) external view returns (bool);

  /**
   * @notice method to get the origin chain id
   * @return id of the chain where the messages originate.
   * @dev this method is needed as Arbitrum does not pass the origin chain
   */
  function getOriginChainId() external view returns (uint256);

  /**
   * @notice method called by arbitrum with the bridged message
   * @param message bytes containing the bridged information
   */
  function arbReceive(bytes memory message) external;

  /**
   * @dev returns the amount of gas needed for submitting the ticket
   * @param bytesLength the payload bytes length (usually 580)
   * @param gasLimit max number of gas to be used
   * @return uint256 maxSubmissionFee needed on L2 with BASE_FEE_MARGIN
   * @return uint256 estimated L2 redepmption fee
   */
  function getRequiredGas(
    uint256 bytesLength,
    uint256 gasLimit
  ) external view returns (uint256, uint256);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";
import "./IDelayedMessageProvider.sol";
import "./ISequencerInbox.sol";

interface IInbox is IDelayedMessageProvider {
    function bridge() external view returns (IBridge);

    function sequencerInbox() external view returns (ISequencerInbox);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method is an optimization to avoid having to emit the entirety of the messageData in a log. Instead validators are expected to be able to parse the data from the transaction's input
     *      This method will be disabled upon L1 fork to prevent replay attacks on L2
     * @param messageData Data of the message being sent
     */
    function sendL2MessageFromOrigin(bytes calldata messageData) external returns (uint256);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method can be used to send any type of message that doesn't require L1 validation
     *      This method will be disabled upon L1 fork to prevent replay attacks on L2
     * @param messageData Data of the message being sent
     */
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendL1FundedUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @notice Send a message to initiate L2 withdrawal
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendWithdrawEthToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        uint256 value,
        address withdrawTo
    ) external returns (uint256);

    /**
     * @notice Get the L1 fee for submitting a retryable
     * @dev This fee can be paid by funds already in the L2 aliased address or by the current message value
     * @dev This formula may change in the future, to future proof your code query this method instead of inlining!!
     * @param dataLength The length of the retryable's calldata, in bytes
     * @param baseFee The block basefee when the retryable is included in the chain, if 0 current block.basefee will be used
     */
    function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee)
        external
        view
        returns (uint256);

    /**
     * @notice Deposit eth from L1 to L2 to address of the sender if sender is an EOA, and to its aliased address if the sender is a contract
     * @dev This does not trigger the fallback function when receiving in the L2 side.
     *      Look into retryable tickets if you are interested in this functionality.
     * @dev This function should not be called inside contract constructors
     */
    function depositEth() external payable returns (uint256);

    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev all msg.value will deposited to callValueRefundAddress on L2
     * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev Same as createRetryableTicket, but does not guarantee that submission will succeed by requiring the needed funds
     * come from the deposit alone, rather than falling back on the user's L2 balance
     * @dev Advanced usage only (does not rewrite aliases for excessFeeRefundAddress and callValueRefundAddress).
     * createRetryableTicket method is the recommended standard.
     * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function unsafeCreateRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    // ---------- onlyRollupOrOwner functions ----------

    /// @notice pauses all inbox functionality
    function pause() external;

    /// @notice unpauses all inbox functionality
    function unpause() external;

    // ---------- initializer ----------

    /**
     * @dev function to be called one time during the inbox upgrade process
     *      this is used to fix the storage slots
     */
    function postUpgradeInit(IBridge _bridge) external;

    function initialize(IBridge _bridge, ISequencerInbox _sequencerInbox) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author BGD Labs
 * @notice Defines the error messages emitted by the different contracts of the Aave CrossChain Infrastructure
 */
library Errors {
  string public constant ETH_TRANSFER_FAILED = '1'; // failed to transfer eth to destination
  string public constant CALLER_IS_NOT_APPROVED_SENDER = '2'; // caller must be an approved message sender
  string public constant ENVELOPE_NOT_PREVIOUSLY_REGISTERED = '3'; // envelope can only be retried if it has been previously registered
  string public constant CURRENT_OR_DESTINATION_CHAIN_ADAPTER_NOT_SET = '4'; // can not enable bridge adapter if the current or destination chain adapter is 0 address
  string public constant CALLER_NOT_APPROVED_BRIDGE = '5'; // caller must be an approved bridge
  string public constant INVALID_VALIDITY_TIMESTAMP = '6'; // new validity timestamp is not correct (< last validity or in the future
  string public constant CALLER_NOT_CCIP_ROUTER = '7'; // caller must be bridge provider contract
  string public constant CCIP_ROUTER_CANT_BE_ADDRESS_0 = '8'; // CCIP bridge adapters needs a CCIP Router
  string public constant RECEIVER_NOT_SET = '9'; // receiver address on destination chain can not be 0
  string public constant DESTINATION_CHAIN_ID_NOT_SUPPORTED = '10'; // destination chain id must be supported by bridge provider
  string public constant NOT_ENOUGH_VALUE_TO_PAY_BRIDGE_FEES = '11'; // cross chain controller does not have enough funds to forward the message
  string public constant REMOTE_NOT_TRUSTED = '12'; // remote address has not been registered as a trusted origin
  string public constant CALLER_NOT_HL_MAILBOX = '13'; // caller must be the HyperLane Mailbox contract
  string public constant NO_BRIDGE_ADAPTERS_FOR_SPECIFIED_CHAIN = '14'; // no bridge adapters are configured for the specified destination chain
  string public constant ONLY_ONE_EMERGENCY_UPDATE_PER_CHAIN = '15'; // only one emergency update is allowed at the time
  string public constant INVALID_REQUIRED_CONFIRMATIONS = '16'; // required confirmations must be less or equal than allowed adapters or bigger or equal than 1
  string public constant DESTINATION_CHAIN_NOT_SAME_AS_CURRENT_CHAIN = '17'; // destination chain must be the same chain as the current chain where contract is deployed
  string public constant INVALID_BRIDGE_ADAPTER = '18'; // a bridge adapter address can not be the 0 address
  string public constant TRANSACTION_NOT_PREVIOUSLY_FORWARDED = '19'; // to retry sending a transaction, it needs to have been previously sent
  string public constant TRANSACTION_RETRY_FAILED = '20'; // transaction retry has failed (no bridge adapters where able to send)
  string public constant BRIDGE_ADAPTERS_SHOULD_BE_UNIQUE = '21'; // can not use the same bridge adapter twice
  string public constant ENVELOPE_NOT_CONFIRMED_OR_DELIVERED = '22'; // to deliver an envelope, this should have been previously confirmed
  string public constant INVALID_BASE_ADAPTER_CROSS_CHAIN_CONTROLLER = '23'; // crossChainController address can not be 0
  string public constant DELEGATE_CALL_FORBIDDEN = '24'; // calling this function during delegatecall is forbidden
  string public constant CALLER_NOT_LZ_ENDPOINT = '25'; // caller must be the LayerZero endpoint contract
  string public constant INVALID_LZ_ENDPOINT = '26'; // LayerZero endpoint can't be 0
  string public constant INVALID_TRUSTED_REMOTE = '27'; // trusted remote endpoint can't be 0
  string public constant INVALID_EMERGENCY_ORACLE = '28'; // emergency oracle can not be 0 because if not, system could not be rescued on emergency
  string public constant NOT_IN_EMERGENCY = '29'; // execution can only happen when in an emergency
  string public constant LINK_TOKEN_CANT_BE_ADDRESS_0 = '30'; // link token address should be set
  string public constant CCIP_MESSAGE_IS_INVALID = '31'; // ccip message is not an accepted message
  string public constant ADAPTER_PAYMENT_SETUP_FAILED = '32'; // adapter payment setup failed
  string public constant CHAIN_ID_MISMATCH = '33'; // the message delivered to/from wrong network
  string public constant CALLER_NOT_OVM = '34'; // the caller must be the optimism ovm contract
  string public constant CALLER_NOT_FX_CHILD = '35'; // the caller must be the polygon fx child contract
  string public constant INVALID_SENDER = '36'; // sender can not be address 0
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ChainIds {
  uint256 constant ETHEREUM = 1;
  uint256 constant POLYGON = 137;
  uint256 constant AVALANCHE = 43114;
  uint256 constant ARBITRUM = 42161;
  uint256 constant OPTIMISM = 10;
  uint256 constant FANTOM = 250;
  uint256 constant HARMONY = 1666600000;
  uint256 constant METIS = 1088;
  uint256 constant BNB = 56;
  uint256 constant BASE = 8453;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseAdapter
 * @author BGD Labs
 * @notice interface containing the event and method used in all bridge adapters
 */
interface IBaseAdapter {
  /**
   * @notice emitted when a trusted remote is set
   * @param originChainId id of the chain where the trusted remote is from
   * @param originForwarder address of the contract that will send the messages
   */
  event SetTrustedRemote(uint256 originChainId, address originForwarder);

  /**
   * @notice pair of origin address and origin chain
   * @param originForwarder address of the contract that will send the messages
   * @param originChainId id of the chain where the trusted remote is from
   */
  struct TrustedRemotesConfig {
    address originForwarder;
    uint256 originChainId;
  }

  /**
   * @notice method that will bridge the payload to the chain specified
   * @param receiver address of the receiver contract on destination chain
   * @param gasLimit amount of the gas limit in wei to use for bridging on receiver side. Each adapter will manage this
            as needed
   * @param destinationChainId id of the destination chain in the bridge notation
   * @param message to send to the specified chain
   * @return the third-party bridge entrypoint, the third-party bridge message id
   */
  function forwardMessage(
    address receiver,
    uint256 gasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external returns (address, uint256);

  /**
   * @notice method used to setup payment, ie grant approvals over tokens used to pay for tx fees
   */
  function setupPayments() external;

  /**
   * @notice method to get the trusted remote address from a specified chain id
   * @param chainId id of the chain from where to get the trusted remote
   * @return address of the trusted remote
   */
  function getTrustedRemoteByChainId(uint256 chainId) external view returns (address);

  /**
   * @notice method to get infrastructure chain id from bridge native chain id
   * @param bridgeChainId bridge native chain id
   */
  function nativeToInfraChainId(uint256 bridgeChainId) external returns (uint256);

  /**
   * @notice method to get bridge native chain id from native bridge chain id
   * @param infraChainId infrastructure chain id
   */
  function infraToNativeChainId(uint256 infraChainId) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICrossChainForwarder.sol';
import './ICrossChainReceiver.sol';
import {IRescuable} from 'solidity-utils/contracts/utils/interfaces/IRescuable.sol';

/**
 * @title IBaseCrossChainController
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainController contract
 */
interface IBaseCrossChainController is IRescuable, ICrossChainForwarder, ICrossChainReceiver {

}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IOwnable.sol";

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash,
        uint256 baseFeeL1,
        uint64 timestamp
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed to,
        uint256 value,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    event SequencerInboxUpdated(address newSequencerInbox);

    function allowedDelayedInboxList(uint256) external returns (address);

    function allowedOutboxList(uint256) external returns (address);

    /// @dev Accumulator for delayed inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function delayedInboxAccs(uint256) external view returns (bytes32);

    /// @dev Accumulator for sequencer inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function sequencerInboxAccs(uint256) external view returns (bytes32);

    function rollup() external view returns (IOwnable);

    function sequencerInbox() external view returns (address);

    function activeOutbox() external view returns (address);

    function allowedDelayedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function sequencerReportedSubMessageCount() external view returns (uint256);

    /**
     * @dev Enqueue a message in the delayed inbox accumulator.
     *      These messages are later sequenced in the SequencerInbox, either
     *      by the sequencer as part of a normal batch, or by force inclusion.
     */
    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    function delayedMessageCount() external view returns (uint256);

    function sequencerMessageCount() external view returns (uint256);

    // ---------- onlySequencerInbox functions ----------

    function enqueueSequencerMessage(
        bytes32 dataHash,
        uint256 afterDelayedMessagesRead,
        uint256 prevMessageCount,
        uint256 newMessageCount
    )
        external
        returns (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 acc
        );

    /**
     * @dev Allows the sequencer inbox to submit a delayed message of the batchPostingReport type
     *      This is done through a separate function entrypoint instead of allowing the sequencer inbox
     *      to call `enqueueDelayedMessage` to avoid the gas overhead of an extra SLOAD in either
     *      every delayed inbox or every sequencer inbox call.
     */
    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash)
        external
        returns (uint256 msgNum);

    // ---------- onlyRollupOrOwner functions ----------

    function setSequencerInbox(address _sequencerInbox) external;

    function setDelayedInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // ---------- initializer ----------

    function initialize(IOwnable rollup_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IDelayedMessageProvider {
    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    /// same as InboxMessageDelivered but the batch data is available in tx.input
    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libraries/IGasRefunder.sol";
import "./IDelayedMessageProvider.sol";
import "./IBridge.sol";

interface ISequencerInbox is IDelayedMessageProvider {
    struct MaxTimeVariation {
        uint256 delayBlocks;
        uint256 futureBlocks;
        uint256 delaySeconds;
        uint256 futureSeconds;
    }

    struct TimeBounds {
        uint64 minTimestamp;
        uint64 maxTimestamp;
        uint64 minBlockNumber;
        uint64 maxBlockNumber;
    }

    enum BatchDataLocation {
        TxInput,
        SeparateBatchEvent,
        NoData
    }

    event SequencerBatchDelivered(
        uint256 indexed batchSequenceNumber,
        bytes32 indexed beforeAcc,
        bytes32 indexed afterAcc,
        bytes32 delayedAcc,
        uint256 afterDelayedMessagesRead,
        TimeBounds timeBounds,
        BatchDataLocation dataLocation
    );

    event OwnerFunctionCalled(uint256 indexed id);

    /// @dev a separate event that emits batch data when this isn't easily accessible in the tx.input
    event SequencerBatchData(uint256 indexed batchSequenceNumber, bytes data);

    /// @dev a valid keyset was added
    event SetValidKeyset(bytes32 indexed keysetHash, bytes keysetBytes);

    /// @dev a keyset was invalidated
    event InvalidateKeyset(bytes32 indexed keysetHash);

    function totalDelayedMessagesRead() external view returns (uint256);

    function bridge() external view returns (IBridge);

    /// @dev The size of the batch header
    // solhint-disable-next-line func-name-mixedcase
    function HEADER_LENGTH() external view returns (uint256);

    /// @dev If the first batch data byte after the header has this bit set,
    ///      the sequencer inbox has authenticated the data. Currently not used.
    // solhint-disable-next-line func-name-mixedcase
    function DATA_AUTHENTICATED_FLAG() external view returns (bytes1);

    function rollup() external view returns (IOwnable);

    function isBatchPoster(address) external view returns (bool);

    struct DasKeySetInfo {
        bool isValidKeyset;
        uint64 creationBlock;
    }

    // https://github.com/ethereum/solidity/issues/11826
    // function maxTimeVariation() external view returns (MaxTimeVariation calldata);
    // function dasKeySetInfo(bytes32) external view returns (DasKeySetInfo calldata);

    /// @notice Remove force inclusion delay after a L1 chainId fork
    function removeDelayAfterFork() external;

    /// @notice Force messages from the delayed inbox to be included in the chain
    ///         Callable by any address, but message can only be force-included after maxTimeVariation.delayBlocks and
    ///         maxTimeVariation.delaySeconds has elapsed. As part of normal behaviour the sequencer will include these
    ///         messages so it's only necessary to call this if the sequencer is down, or not including any delayed messages.
    /// @param _totalDelayedMessagesRead The total number of messages to read up to
    /// @param kind The kind of the last message to be included
    /// @param l1BlockAndTime The l1 block and the l1 timestamp of the last message to be included
    /// @param baseFeeL1 The l1 gas price of the last message to be included
    /// @param sender The sender of the last message to be included
    /// @param messageDataHash The messageDataHash of the last message to be included
    function forceInclusion(
        uint256 _totalDelayedMessagesRead,
        uint8 kind,
        uint64[2] calldata l1BlockAndTime,
        uint256 baseFeeL1,
        address sender,
        bytes32 messageDataHash
    ) external;

    function inboxAccs(uint256 index) external view returns (bytes32);

    function batchCount() external view returns (uint256);

    function isValidKeysetHash(bytes32 ksHash) external view returns (bool);

    /// @notice the creation block is intended to still be available after a keyset is deleted
    function getKeysetCreationBlock(bytes32 ksHash) external view returns (uint256);

    // ---------- BatchPoster functions ----------

    function addSequencerL2BatchFromOrigin(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder
    ) external;

    function addSequencerL2Batch(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder,
        uint256 prevMessageCount,
        uint256 newMessageCount
    ) external;

    // ---------- onlyRollupOrOwner functions ----------

    /**
     * @notice Set max delay for sequencer inbox
     * @param maxTimeVariation_ the maximum time variation parameters
     */
    function setMaxTimeVariation(MaxTimeVariation memory maxTimeVariation_) external;

    /**
     * @notice Updates whether an address is authorized to be a batch poster at the sequencer inbox
     * @param addr the address
     * @param isBatchPoster_ if the specified address should be authorized as a batch poster
     */
    function setIsBatchPoster(address addr, bool isBatchPoster_) external;

    /**
     * @notice Makes Data Availability Service keyset valid
     * @param keysetBytes bytes of the serialized keyset
     */
    function setValidKeyset(bytes calldata keysetBytes) external;

    /**
     * @notice Invalidates a Data Availability Service keyset
     * @param ksHash hash of the keyset
     */
    function invalidateKeysetHash(bytes32 ksHash) external;

    // ---------- initializer ----------

    function initialize(IBridge bridge_, MaxTimeVariation calldata maxTimeVariation_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Transaction, Envelope} from '../libs/EncodingUtils.sol';

/**
 * @title ICrossChainForwarder
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainForwarder contract
 */
interface ICrossChainForwarder {
  /**
   * @notice object storing the connected pair of bridge adapters, on current and destination chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current network
   */
  struct ChainIdBridgeConfig {
    address destinationBridgeAdapter;
    address currentChainBridgeAdapter;
  }

  /**
   * @notice object with the necessary information to remove bridge adapters
   * @param bridgeAdapter address of the bridge adapter to remove
   * @param chainIds array of chain ids where the bridge adapter connects
   */
  struct BridgeAdapterToDisable {
    address bridgeAdapter;
    uint256[] chainIds;
  }

  /**
   * @notice object storing the pair bridgeAdapter (current deployed chain) destination chain bridge adapter configuration
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param destinationChainId id of the destination chain using our own nomenclature
   */
  struct ForwarderBridgeAdapterConfigInput {
    address currentChainBridgeAdapter;
    address destinationBridgeAdapter;
    uint256 destinationChainId;
  }

  /**
   * @notice emitted when a transaction is successfully forwarded through a bridge adapter
   * @param envelopeId internal id of the envelope
   * @param envelope the Envelope type data
   */
  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);

  /**
   * @notice emitted when a transaction forwarding is attempted through a bridge adapter
   * @param transactionId id of the forwarded transaction
   * @param envelopeId internal id of the envelope
   * @param encodedTransaction object intended to be bridged
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param adapterSuccessful adapter was able to forward the message
   * @param returnData bytes with error information
   */
  event TransactionForwardingAttempted(
    bytes32 transactionId,
    bytes32 indexed envelopeId,
    bytes encodedTransaction,
    uint256 destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed adapterSuccessful,
    bytes returnData
  );

  /**
   * @notice emitted when a bridge adapter has been added to the allowed list
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter added (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param allowed boolean indicating if the bridge adapter is allowed or disallowed
   */
  event BridgeAdapterUpdated(
    uint256 indexed destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed allowed
  );

  /**
   * @notice emitted when a sender has been updated
   * @param sender address of the updated sender
   * @param isApproved boolean that indicates if the sender has been approved or removed
   */
  event SenderUpdated(address indexed sender, bool indexed isApproved);

  /**
   * @notice method to get the current valid envelope nonce
   * @return the current valid envelope nonce
   */
  function getCurrentEnvelopeNonce() external view returns (uint256);

  /**
   * @notice method to get the current valid transaction nonce
   * @return the current valid transaction nonce
   */
  function getCurrentTransactionNonce() external view returns (uint256);

  /**
   * @notice method to check if a envelope has been previously forwarded.
   * @param envelope the Envelope type data
   * @return boolean indicating if the envelope has been registered
   */
  function isEnvelopeRegistered(Envelope memory envelope) external view returns (bool);

  /**
   * @notice method to check if a envelope has been previously forwarded.
   * @param envelopeId the hashed id of the envelope
   * @return boolean indicating if the envelope has been registered
   */
  function isEnvelopeRegistered(bytes32 envelopeId) external view returns (bool);

  /**
   * @notice method to get if a transaction has been forwarded
   * @param transaction the Transaction type data
   * @return flag indicating if a transaction has been forwarded
   */
  function isTransactionForwarded(Transaction memory transaction) external view returns (bool);

  /**
   * @notice method to get if a transaction has been forwarded
   * @param transactionId hashed id of the transaction
   * @return flag indicating if a transaction has been forwarded
   */
  function isTransactionForwarded(bytes32 transactionId) external view returns (bool);

  /**
   * @notice method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   * @return internal id of the envelope and transaction
   */
  function forwardMessage(
    uint256 destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external returns (bytes32, bytes32);

  /**
   * @notice method called to re forward a previously sent envelope.
   * @param envelope the Envelope type data
   * @param gasLimit gas cost on receiving side of the message
   * @return the transaction id that has the retried envelope
   * @dev This method will send an existing Envelope using a new Transaction.
   * @dev This method should be used when the intention is to send the Envelope as if it was a new message. This way on
          the Receiver side it will start from 0 to count for the required confirmations. (usual use case would be for
          when an envelope has been invalidated on Receiver side, and needs to be retried as a new message)
   */
  function retryEnvelope(Envelope memory envelope, uint256 gasLimit) external returns (bytes32);

  /**
   * @notice method to retry forwarding an already forwarded transaction
   * @param encodedTransaction the encoded Transaction data
   * @param gasLimit limit of gas to spend on forwarding per bridge
   * @param bridgeAdaptersToRetry list of bridge adapters to be used for the transaction forwarding retry
   * @dev This method will send an existing Transaction with its Envelope to the specified adapters.
   * @dev Should be used when some of the bridges on the initial forwarding did not work (out of gas),
          and we want the Transaction with Envelope to still account for the required confirmations on the Receiver side
   */
  function retryTransaction(
    bytes memory encodedTransaction,
    uint256 gasLimit,
    address[] memory bridgeAdaptersToRetry
  ) external;

  /**
   * @notice method to enable bridge adapters
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function enableBridgeAdapters(ForwarderBridgeAdapterConfigInput[] memory bridgeAdapters) external;

  /**
   * @notice method to disable bridge adapters
   * @param bridgeAdapters array of bridge adapter addresses to disable
   */
  function disableBridgeAdapters(BridgeAdapterToDisable[] memory bridgeAdapters) external;

  /**
   * @notice method to remove sender addresses
   * @param senders list of addresses to remove
   */
  function removeSenders(address[] memory senders) external;

  /**
   * @notice method to approve new sender addresses
   * @param senders list of addresses to approve
   */
  function approveSenders(address[] memory senders) external;

  /**
   * @notice method to get all the forwarder bridge adapters of a chain
   * @param chainId id of the chain we want to get the adapters from
   * @return an array of chain configurations where the bridge adapter can communicate
   */
  function getForwarderBridgeAdaptersByChain(
    uint256 chainId
  ) external view returns (ChainIdBridgeConfig[] memory);

  /**
   * @notice method to get if a sender is approved
   * @param sender address that we want to check if approved
   * @return boolean indicating if the address has been approved as sender
   */
  function isSenderApproved(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';
import {Transaction, Envelope} from '../libs/EncodingUtils.sol';

/**
 * @title ICrossChainReceiver
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainReceiver contract
 */
interface ICrossChainReceiver {
  /**
   * @notice object with information to set new required confirmations
   * @param chainId id of the origin chain
   * @param requiredConfirmations required confirmations to set a message as confirmed
   */
  struct ConfirmationInput {
    uint256 chainId;
    uint8 requiredConfirmations;
  }

  /**
   * @notice object with information to set new validity timestamp
   * @param chainId id of the origin chain
   * @param validityTimestamp new timestamp in seconds to set as validity point
   */
  struct ValidityTimestampInput {
    uint256 chainId;
    uint120 validityTimestamp;
  }

  /**
   * @notice object with necessary information to configure bridge adapters
   * @param bridgeAdapter address of the bridge adapter to configure
   * @param chainIds array of ids of the chains the adapter receives messages from
   */
  struct ReceiverBridgeAdapterConfigInput {
    address bridgeAdapter;
    uint256[] chainIds;
  }

  /**
   * @notice object containing the receiver configuration
   * @param requiredConfirmation number of bridges that are needed to make a bridged message valid from origin chain
   * @param validityTimestamp all messages originated but not finally confirmed before this timestamp per origin chain, are invalid
   */
  struct ReceiverConfiguration {
    uint8 requiredConfirmation;
    uint120 validityTimestamp;
  }

  /**
   * @notice object with full information of the receiver configuration for a chain
   * @param configuration object containing the specifications of the receiver for a chain
   * @param allowedBridgeAdapters stores if a bridge adapter is allowed for a chain
   */
  struct ReceiverConfigurationFull {
    ReceiverConfiguration configuration;
    EnumerableSet.AddressSet allowedBridgeAdapters;
  }

  /**
   * @notice object that stores the internal information of the transaction
   * @param confirmations number of times that this transaction has been bridged
   * @param firstBridgedAt timestamp in seconds indicating the first time a transaction was received
   */
  struct TransactionStateWithoutAdapters {
    uint8 confirmations;
    uint120 firstBridgedAt;
  }
  /**
   * @notice object that stores the internal information of the transaction with bridge adapters state
   * @param confirmations number of times that this transactions has been bridged
   * @param firstBridgedAt timestamp in seconds indicating the first time a transaction was received
   * @param bridgedByAdapter list of bridge adapters that have bridged the message
   */
  struct TransactionState {
    uint8 confirmations;
    uint120 firstBridgedAt;
    mapping(address => bool) bridgedByAdapter;
  }

  /**
   * @notice object with the current state of an envelope
   * @param confirmed boolean indicating if the bridged message has been confirmed by the infrastructure
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   */
  enum EnvelopeState {
    None,
    Confirmed,
    Delivered
  }

  /**
   * @notice emitted when a transaction has been received successfully
   * @param transactionId id of the transaction
   * @param envelopeId id of the envelope
   * @param originChainId id of the chain where the envelope originated
   * @param transaction the Transaction type data
   * @param bridgeAdapter address of the bridge adapter who received the message (deployed on current network)
   * @param confirmations number of current confirmations for this message
   */
  event TransactionReceived(
    bytes32 transactionId,
    bytes32 indexed envelopeId,
    uint256 indexed originChainId,
    Transaction transaction,
    address indexed bridgeAdapter,
    uint8 confirmations
  );

  /**
   * @notice emitted when an envelope has been delivery attempted
   * @param envelopeId id of the envelope
   * @param envelope the Envelope type data
   * @param isDelivered flag indicating if the message has been delivered successfully
   */
  event EnvelopeDeliveryAttempted(bytes32 envelopeId, Envelope envelope, bool isDelivered);

  /**
   * @notice emitted when a bridge adapter gets updated (allowed or disallowed)
   * @param bridgeAdapter address of the updated bridge adapter
   * @param allowed boolean indicating if the bridge adapter has been allowed or disallowed
   * @param chainId id of the chain updated
   */
  event ReceiverBridgeAdaptersUpdated(
    address indexed bridgeAdapter,
    bool indexed allowed,
    uint256 indexed chainId
  );

  /**
   * @notice emitted when number of confirmations needed to validate a message changes
   * @param newConfirmations number of new confirmations needed for a message to be valid
   * @param chainId id of the chain updated
   */
  event ConfirmationsUpdated(uint8 newConfirmations, uint256 indexed chainId);

  /**
   * @notice emitted when a new timestamp for invalidations gets set
   * @param invalidTimestamp timestamp to invalidate previous messages
   * @param chainId id of the chain updated
   */
  event NewInvalidation(uint256 invalidTimestamp, uint256 indexed chainId);

  /**
   * @notice method to get the current allowed receiver bridge adapters for a chain
   * @param chainId id of the chain to get the allowed bridge adapter list
   * @return the list of allowed bridge adapters
   */
  function getReceiverBridgeAdaptersByChain(
    uint256 chainId
  ) external view returns (address[] memory);

  /**
   * @notice method to get the current supported chains (at least one allowed bridge adapter)
   * @return list of supported chains
   */
  function getSupportedChains() external view returns (uint256[] memory);

  /**
   * @notice method to get the current configuration of a chain
   * @param chainId id of the chain to get the configuration from
   * @return the specified chain configuration object
   */
  function getConfigurationByChain(
    uint256 chainId
  ) external view returns (ReceiverConfiguration memory);

  /**
   * @notice method to get if a bridge adapter is allowed
   * @param bridgeAdapter address of the bridge adapter to check
   * @param chainId id of the chain to check
   * @return boolean indicating if bridge adapter is allowed
   */
  function isReceiverBridgeAdapterAllowed(
    address bridgeAdapter,
    uint256 chainId
  ) external view returns (bool);

  /**
   * @notice  method to get the current state of a transaction
   * @param transactionId the id of transaction
   * @return number of confirmations of internal message identified by the transactionId and the updated timestamp
   */
  function getTransactionState(
    bytes32 transactionId
  ) external view returns (TransactionStateWithoutAdapters memory);

  /**
   * @notice  method to get the internal transaction information
   * @param transaction Transaction type data
   * @return number of confirmations of internal message identified by internalId and the updated timestamp
   */
  function getTransactionState(
    Transaction memory transaction
  ) external view returns (TransactionStateWithoutAdapters memory);

  /**
   * @notice method to get the internal state of an envelope
   * @param envelope the Envelope type data
   * @return the envelope current state, containing if it has been confirmed and delivered
   */
  function getEnvelopeState(Envelope memory envelope) external view returns (EnvelopeState);

  /**
   * @notice method to get the internal state of an envelope
   * @param envelopeId id of the envelope
   * @return the envelope current state, containing if it has been confirmed and delivered
   */
  function getEnvelopeState(bytes32 envelopeId) external view returns (EnvelopeState);

  /**
   * @notice method to get if transaction has been received by bridge adapter
   * @param transactionId id of the transaction as stored internally
   * @param bridgeAdapter address of the bridge adapter to check if it has bridged the message
   * @return boolean indicating if the message has been received
   */
  function isTransactionReceivedByAdapter(
    bytes32 transactionId,
    address bridgeAdapter
  ) external view returns (bool);

  /**
   * @notice method to set a new timestamp from where the messages will be valid.
   * @param newValidityTimestamp array of objects containing the chain and timestamp where all the previous unconfirmed
            messages must be invalidated.
   */
  function updateMessagesValidityTimestamp(
    ValidityTimestampInput[] memory newValidityTimestamp
  ) external;

  /**
   * @notice method to update the number of confirmations necessary for the messages to be accepted as valid
   * @param newConfirmations array of objects with the chainId and the new number of needed confirmations
   */
  function updateConfirmations(ConfirmationInput[] memory newConfirmations) external;

  /**
   * @notice method that receives a bridged transaction and tries to deliver the contents to destination if possible
   * @param encodedTransaction bytes containing the bridged information
   * @param originChainId id of the chain where the transaction originated
   */
  function receiveCrossChainMessage(
    bytes memory encodedTransaction,
    uint256 originChainId
  ) external;

  /**
   * @notice method to deliver an envelope to its destination
   * @param envelope the Envelope typed data
   * @dev to deliver an envelope, it needs to have been previously confirmed and not delivered
   */
  function deliverEnvelope(Envelope memory envelope) external;

  /**
   * @notice method to add bridge adapters to the allowed list
   * @param bridgeAdaptersInput array of objects with the new bridge adapters and supported chains
   */
  function allowReceiverBridgeAdapters(
    ReceiverBridgeAdapterConfigInput[] memory bridgeAdaptersInput
  ) external;

  /**
   * @notice method to remove bridge adapters from the allowed list
   * @param bridgeAdaptersInput array of objects with the bridge adapters and supported chains to disallow
   */
  function disallowReceiverBridgeAdapters(
    ReceiverBridgeAdapterConfigInput[] memory bridgeAdaptersInput
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @title IRescuable
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the Rescuable contract
 */
interface IRescuable {
  /**
   * @notice emitted when erc20 tokens get rescued
   * @param caller address that triggers the rescue
   * @param token address of the rescued token
   * @param to address that will receive the rescued tokens
   * @param amount quantity of tokens rescued
   */
  event ERC20Rescued(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /**
   * @notice emitted when native tokens get rescued
   * @param caller address that triggers the rescue
   * @param to address that will receive the rescued tokens
   * @param amount quantity of tokens rescued
   */
  event NativeTokensRescued(address indexed caller, address indexed to, uint256 amount);

  /**
   * @notice method called to rescue tokens sent erroneously to the contract. Only callable by owner
   * @param erc20Token address of the token to rescue
   * @param to address to send the tokens
   * @param amount of tokens to rescue
   */
  function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;

  /**
   * @notice method called to rescue ether sent erroneously to the contract. Only callable by owner
   * @param to address to send the eth
   * @param amount of eth to rescue
   */
  function emergencyEtherTransfer(address to, uint256 amount) external;

  /**
   * @notice method that defines the address that is allowed to rescue tokens
   * @return the allowed address
   */
  function whoCanRescue() external view returns (address);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.21 <0.9.0;

interface IOwnable {
    function owner() external view returns (address);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IGasRefunder {
    function onGasSpent(
        address payable spender,
        uint256 gasUsed,
        uint256 calldataSize
    ) external returns (bool success);
}

abstract contract GasRefundEnabled {
    /// @dev this refunds the sender for execution costs of the tx
    /// calldata costs are only refunded if `msg.sender == tx.origin` to guarantee the value refunded relates to charging
    /// for the `tx.input`. this avoids a possible attack where you generate large calldata from a contract and get over-refunded
    modifier refundsGas(IGasRefunder gasRefunder) {
        uint256 startGasLeft = gasleft();
        _;
        if (address(gasRefunder) != address(0)) {
            uint256 calldataSize;
            assembly {
                calldataSize := calldatasize()
            }
            uint256 calldataWords = (calldataSize + 31) / 32;
            // account for the CALLDATACOPY cost of the proxy contract, including the memory expansion cost
            startGasLeft += calldataWords * 6 + (calldataWords**2) / 512;
            // if triggered in a contract call, the spender may be overrefunded by appending dummy data to the call
            // so we check if it is a top level call, which would mean the sender paid calldata as part of tx.input
            // solhint-disable-next-line avoid-tx-origin
            if (msg.sender != tx.origin) {
                // We can't be sure if this calldata came from the top level tx,
                // so to be safe we tell the gas refunder there was no calldata.
                calldataSize = 0;
            }
            gasRefunder.onGasSpent(payable(msg.sender), startGasLeft - gasleft(), calldataSize);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

using EnvelopeUtils for Envelope global;
using TransactionUtils for Transaction global;

/**
 * @notice Object with the necessary information to define a unique envelope
 * @param nonce sequential (unique) numeric indicator of the Envelope creation
 * @param origin address that originated the bridging of a message
 * @param destination address where the message needs to be sent
 * @param originChainId id of the chain where the message originated
 * @param destinationChainId id of the chain where the message needs to be bridged
 * @param message bytes that needs to be bridged
 */
struct Envelope {
  uint256 nonce;
  address origin;
  address destination;
  uint256 originChainId;
  uint256 destinationChainId;
  bytes message;
}

/**
 * @notice Object containing the information of an envelope for internal usage
 * @param data bytes of the encoded envelope
 * @param id hash of the encoded envelope
 */
struct EncodedEnvelope {
  bytes data;
  bytes32 id;
}

/**
 * @title EnvelopeUtils library
 * @author BGD Labs
 * @notice Defines utility functions for Envelopes
 */
library EnvelopeUtils {
  /**
   * @notice method that encodes an Envelope and generates its id
   * @param envelope object with the routing information necessary to send a message to a destination chain
   * @return object containing the encoded envelope and the envelope id
   */
  function encode(Envelope memory envelope) internal pure returns (EncodedEnvelope memory) {
    EncodedEnvelope memory encodedEnvelope;
    encodedEnvelope.data = abi.encode(envelope);
    encodedEnvelope.id = getId(encodedEnvelope.data);
    return encodedEnvelope;
  }

  /**
   * @notice method to decode and encoded envelope to its raw parameters
   * @param envelope bytes with the encoded envelope data
   * @return object with the decoded envelope information
   */
  function decode(bytes memory envelope) internal pure returns (Envelope memory) {
    return abi.decode(envelope, (Envelope));
  }

  /**
   * @notice method to get an envelope's id
   * @param envelope object with the routing information necessary to send a message to a destination chain
   * @return hash id of the envelope
   */
  function getId(Envelope memory envelope) internal pure returns (bytes32) {
    EncodedEnvelope memory encodedEnvelope = encode(envelope);
    return encodedEnvelope.id;
  }

  /**
   * @notice method to get an envelope's id
   * @param envelope bytes with the encoded envelope data
   * @return hash id of the envelope
   */
  function getId(bytes memory envelope) internal pure returns (bytes32) {
    return keccak256(envelope);
  }
}

/**
 * @notice Object with the necessary information to send an envelope to a bridge
 * @param nonce sequential (unique) numeric indicator of the Transaction creation
 * @param encodedEnvelope bytes of an encoded envelope object
 */
struct Transaction {
  uint256 nonce;
  bytes encodedEnvelope;
}

/**
 * @notice Object containing the information of a transaction for internal usage
 * @param data bytes of the encoded transaction
 * @param id hash of the encoded transaction
 */
struct EncodedTransaction {
  bytes data;
  bytes32 id;
}

/**
 * @title TransactionUtils library
 * @author BGD Labs
 * @notice Defines utility functions for Transactions
 */
library TransactionUtils {
  /**
   * @notice method that encodes a Transaction and generates its id
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return object containing the encoded transaction and the transaction id
   */
  function encode(
    Transaction memory transaction
  ) internal pure returns (EncodedTransaction memory) {
    EncodedTransaction memory encodedTransaction;
    encodedTransaction.data = abi.encode(transaction);
    encodedTransaction.id = getId(encodedTransaction.data);
    return encodedTransaction;
  }

  /**
   * @notice method that decodes an encoded transaction (bytes) into a Transaction object
   * @param transaction encoded transaction object
   * @return object containing the decoded Transaction object
   */
  function decode(bytes memory transaction) internal pure returns (Transaction memory) {
    return abi.decode(transaction, (Transaction));
  }

  /**
   * @notice method to get a transaction id
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return hash id of the transaction
   */
  function getId(Transaction memory transaction) internal pure returns (bytes32) {
    EncodedTransaction memory encodedTransaction = encode(transaction);
    return encodedTransaction.id;
  }

  /**
   * @notice method to get a transaction id
   * @param transaction encoded transaction object
   * @return hash id of the transaction
   */
  function getId(bytes memory transaction) internal pure returns (bytes32) {
    return keccak256(transaction);
  }

  /**
   * @notice method to get the envelope information from the transaction object
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return object with decoded information of the envelope in the transaction
   */
  function getEnvelope(Transaction memory transaction) internal pure returns (Envelope memory) {
    return EnvelopeUtils.decode(transaction.encodedEnvelope);
  }

  /**
   * @notice method to get the envelope id from the transaction object
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return hash id of the envelope on a transaction
   */
  function getEnvelopeId(Transaction memory transaction) internal pure returns (bytes32) {
    return EnvelopeUtils.getId(transaction.encodedEnvelope);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}