// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
  /// @notice Called by the Router to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution.
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the OffRampRouter
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainSelector The chain to check.
  /// @return supported is true if it is supported, false if not.
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chainSelector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns execution fee for the message
  /// delivery to destination chain, denominated in the feeToken specified in the message.
  /// @dev Reverts with appropriate reason upon invalid message.
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  /// @dev Reverts with appropriate reason upon invalid message.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// End consumer library.
library Client {
  /// @dev RMN depends on this struct, if changing, please notify the RMN maintainers.
  struct EVMTokenAmount {
    address token; // token address on the local chain.
    uint256 amount; // Amount of tokens.
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source.
    uint64 sourceChainSelector; // Source chain selector.
    bytes sender; // abi.decode(sender) if coming from an EVM chain.
    bytes data; // payload sent in original message.
    EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
  }

  // If extraArgs is empty bytes, the default is 200k gas limit.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit;
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IProvider {
    /**
     * @dev Used to make sure the function is only called by the teleport contract.
     */
    error OnlyTeleportCalls();

    /// @notice emitted when transmitting a payload
    event Transmission(
        bytes transmissionSender,
        uint8 targetChainId,
        bytes transmissionReceiver,
        bytes32 dAppId,
        bytes payload
    );
    /// @notice emitted when delivering a payload
    event Delivery(bytes32 transmissionId);

    struct DappTransmissionInfo {
        bytes dappTransmissionSender;
        bytes dappTransmissionReceiver;
        bytes32 dAppId;
        bytes dappPayload;
    }

    function supportedChains(uint256 index) external view returns (uint8);

    function supportedChainsCount() external view returns (uint256);

    /// @return The currently set service fee
    function fee(
        uint8 targetChainId,
        bytes calldata transmissionTeleportReceiver,
        DappTransmissionInfo calldata dappTranmissionInfo,
        bytes calldata extraOptionalArgs
    ) external view returns (uint256);

    function sendMsg(
        uint8 targetChainId,
        bytes calldata transmissionTeleportReceiver,
        DappTransmissionInfo calldata dappTranmissionInfo,
        bytes calldata extraOptionalArgs
    ) external payable;

    function manualClaim(bytes calldata args) external;

    function config(bytes calldata configData) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

/**
 * @title ITeleport
 * @dev Interface for the Teleport contract, which allows for cross-chain communication and messages transfer using different providers.
 */
interface ITeleport {
    /**
     * @notice Emitted when collecting fees
     * @param serviceFee The amount of service fee collected
     */
    event TransmissionFees(uint256 serviceFee);

    /**
     * @dev Transmits a message to the specified target chain ID. The message will be delivered using the most suitable provider.
     * @param targetChainId The ID of the target chain
     * @param transmissionReceiver The address of the receiver on the target chain
     * @param dAppId The ID of the dApp on the target chain
     * @param payload The message payload
     */
    function transmit(
        uint8 targetChainId,
        bytes calldata transmissionReceiver,
        bytes32 dAppId,
        bytes calldata payload
    ) external payable;

    /**
     * @notice Selects a provider to bridge the message to the target chain
     * @param targetChainId_ The chainID where the message should be delivered to
     * @param transmissionReceiver_ The address of the contract in the target chain to receive the transmission
     * @param dAppId_ ID for the dApp that the message belongs to
     * @param payload_ The dApp-specific message data
     * @param extraOptionalArgs_ Extra optional arguments to be passed to the provider. This allow for specific provider configurations. Send bytes('') if not needed
     */
    function transmitWithArgs(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external payable;

    /**
     * @dev Transmits a message to the specified target chain ID. The message will be delivered using the specified provider.
     * @param targetChainId The ID of the target chain
     * @param transmissionReceiver The address of the receiver on the target chain
     * @param dAppId The ID of the dApp on the target chain
     * @param payload The message payload
     * @param providerAddress The address of the provider to use
     */
    function transmitWithProvider(
        uint8 targetChainId,
        bytes calldata transmissionReceiver,
        bytes32 dAppId,
        bytes calldata payload,
        address providerAddress,
        bytes memory extraOptionalArgs_
    ) external payable;

    /**
     * @dev Delivers a message to this chain.
     * @param args The message arguments, which depend on the provider. See the provider's documentation for more information.
     */
    function deliver(address providerAddress, bytes calldata args) external;

    /**
     * @dev Returns the currently set teleport fee.
     * @return The teleport fee amount
     */
    function teleportFee() external view returns (uint256);

    /**
     * @dev Returns the fee for the automatic selected provider.
     * @return The provider fee amount
     */
    function providerFee(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    /**
     * @dev Returns the fee for the stated provider.
     * @return The provider fee amount
     */
    function providerFee(
        address providerAddress_,
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    /**
     * @dev Returns the currently set service fee.
     * @return The service fee amount
     */
    function serviceFee(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    /**
     * @dev Returns the currently set service fee.
     * @return The service fee amount
     */
    function serviceFee(
        address providerAddress_,
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_,
        bytes calldata extraOptionalArgs_
    ) external view returns (uint256);

    struct DappTransmissionReceive {
        bytes teleportSender;
        uint8 sourceChainId;
        bytes dappTransmissionSender;
        address dappTransmissionReceiver;
        bytes32 dAppId;
        bytes payload;
    }

    /**
     * @dev Notifies the teleport that the provider has received a new message. Teleport should invoke the related dapps.
     * @param args The arguments of the message.
     */
    function onProviderReceive(DappTransmissionReceive calldata args) external;

    function configProviderSelector(bytes calldata configData, bytes[] calldata signatures_) external;

    function configProvider(bytes calldata configData, address providerAddress, bytes[] calldata signatures_) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {IProvider} from "../../interfaces/IProvider.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {ITeleport} from "../../interfaces/ITeleport.sol";
import {IERC165} from "../../interfaces/IERC165.sol";

contract CCIPProvider is IProvider, IAny2EVMMessageReceiver, IERC165 {
    address public immutable TELEPORT_ADDRESS;
    address private _iRouter;
    uint256 private _gasLimit = 200_000;

    /**
     * @dev A mapping that stores the destination chain selectors for the CCIPProvider contract mapped to their corresponding MPCids
     */
    mapping(uint8 => uint64) internal ccipChainSelectors;

    /**
     * @dev A mapping that stores the destination chain CCIPProvider contract that would receive the transmission
     */
    mapping(uint8 => address) internal ccipReceivers;

    /**
     * @dev Mapping of source messaging protocol chain IDs to their corresponding values destination chain CCIP selectors
     */
    mapping(uint64 => uint8) internal mpcIds;

    /**
     * @dev Allows knowing all chains that are supported from offchain
     */
    uint8[] private _supportedChains;

    /**
     * @dev Used to make sure the correct amount has been sent.
     * @param valueSent The amount sent by the sender.
     * @param calculatedFees The amount calculated by the router.
     */
    error ValueNotEqualToFee(uint256 valueSent, uint256 calculatedFees);

    /**
     *
     * @dev Used to make sure the transmissionReceiver is a valid EVM address
     * @param transmissionReceiver The receiver of the transmission teleport.
     */
    error OnlyEVMSupport(bytes transmissionReceiver);

    /**
     * @dev Used to make sure the router address is not the zero address.
     */
    error ZeroAddressRouter();

    /**
     * @dev Used to make sure the teleport address is not the zero address.
     */
    error ZeroAddressTeleport();

    /**
     * @dev Used to make sure the chain MPCId and chain selector arrays have the same length.
     */
    error ArraysLenMismatch();

    /**
     * @dev Used to make sure the destination chain is supported.
     */
    error DstChainUnsupported();

    /**
     * @dev Used to make sure the source chain is supported.
     */
    error SrcChainUnsupported();

    /**
     * @dev Used to indicate that the sender address from the source chain is not recognized.
     */
    error UnrecognizedCCIPSender();

    /**
     * @dev Used to indicate that the teleport receiver address send is not recognized.
     */
    error UnrecognizedTeleportReceiver();

    /**
     * @dev Used to indicate that the manual claim should be perform offchain, by using the sdk.
     */
    error ManualClaimOffchain();

    /**
     *
     * @dev Emitted when the router address is updated.
     * @param router The new router address.
     */
    error InvalidRouter(address router);

    // Duplicate chain selector or MPC ID
    error DuplicateChainSelectorOrMPCId();

    // Receiver cannot be zero address
    error ReceiverCannotBeZeroAddress();

    /// @dev only calls from the set router are accepted.
    modifier onlyRouter() {
        if (msg.sender != address(_iRouter)) revert InvalidRouter(msg.sender);
        _;
    }

    /**
     * @dev Constructor function for CCIPProvider contract.
     * @param _router Address of the router contract.
     * @param _teleport Address of the teleport contract.
     * @param _mpcIds Array of MP chain IDs.
     * @param _ccipChainSelectors Array of CCIP chain selectors.
     */
    constructor(
        address _router,
        address _teleport,
        uint8[] memory _mpcIds,
        uint64[] memory _ccipChainSelectors,
        address[] memory _ccipReceivers
    ) {
        if (_router == address(0)) revert ZeroAddressRouter();
        if (_teleport == address(0)) revert ZeroAddressTeleport();
        _iRouter = _router;
        TELEPORT_ADDRESS = _teleport;

        if (_mpcIds.length != _ccipChainSelectors.length) revert ArraysLenMismatch();
        if (_mpcIds.length != _ccipReceivers.length) revert ArraysLenMismatch();

        for (uint256 i = 0; i < _mpcIds.length; ) {
            ccipChainSelectors[_mpcIds[i]] = _ccipChainSelectors[i];
            mpcIds[_ccipChainSelectors[i]] = _mpcIds[i];
            ccipReceivers[_mpcIds[i]] = _ccipReceivers[i];
            _supportedChains.push(_mpcIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Modifier to restrict access to functions only to the Teleport facet.
     */
    modifier onlyTeleport() {
        if (msg.sender != TELEPORT_ADDRESS) revert OnlyTeleportCalls();
        _;
    }

    /**
     * @dev Prepares a message to be sent to a target chain.
     * @param targetChainId The ID of the target chain.
     * @param transmissionTeleportReceiver The receiver of the transmission teleport.
     * @param dappTranmissionInfo The information about the DApp transmission.
     * @param extraOptionalArgs_ Extra optional arguments.
     * @return A tuple containing the message ID, the EVM2Any message, the router client, the message nonce, the sender address, and the message payload.
     */
    function prepareMessage(
        uint8 targetChainId,
        bytes calldata transmissionTeleportReceiver,
        DappTransmissionInfo calldata dappTranmissionInfo,
        bytes calldata extraOptionalArgs_
    ) private view returns (uint256, Client.EVM2AnyMessage memory, IRouterClient, uint64) {
        if (transmissionTeleportReceiver.length != 20) revert OnlyEVMSupport(transmissionTeleportReceiver);

        address transmissionReceiver = ccipReceivers[targetChainId];

        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            transmissionReceiver,
            _encodeTeleportMessage(dappTranmissionInfo, TELEPORT_ADDRESS, transmissionTeleportReceiver),
            address(0),
            extraOptionalArgs_
        );

        IRouterClient router = IRouterClient(getRouter());

        uint64 _destinationChainSelector = getChainSelector(targetChainId);

        if (_destinationChainSelector == 0) revert DstChainUnsupported();

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        return (fees, evm2AnyMessage, router, _destinationChainSelector);
    }

    /**
     * @notice Transmits the `payload` to the validators by emitting the `Transmission` event
     * @param targetChainId The chainID where the message should be delivered to
     * @param transmissionTeleportReceiver The address of the contract in the target chain to receive the transmission
     * @param dappTranmissionInfo The Id and data for the dApp that the message belongs to
     */
    function sendMsg(
        uint8 targetChainId,
        bytes calldata transmissionTeleportReceiver,
        DappTransmissionInfo calldata dappTranmissionInfo,
        bytes calldata extraOptionalArgs_
    ) external payable override onlyTeleport {
        (
            uint256 fees,
            Client.EVM2AnyMessage memory evm2AnyMessage,
            IRouterClient router,
            uint64 _destinationChainSelector
        ) = prepareMessage(targetChainId, transmissionTeleportReceiver, dappTranmissionInfo, extraOptionalArgs_);

        if (fees != msg.value) revert ValueNotEqualToFee(msg.value, fees);

        // Send the CCIP message through the router. We ignore the returned message ID as we don't need it.
        router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);
    }

    /**
     * @dev Returns the chain selector for a given chain ID.
     * @param chainId The ID of the chain to get the selector for.
     * @return The chain selector as a uint64.
     */
    function getChainSelector(uint8 chainId) public view returns (uint64) {
        return ccipChainSelectors[chainId];
    }

    /**
     * @dev Returns the chain selector for a given chain ID.
     * @param chainId The ID of the chain to get the selector for.
     * @return The chain selector as a uint64.
     */
    function getCCIPReceiver(uint8 chainId) public view returns (address) {
        return ccipReceivers[chainId];
    }

    /**
     * @dev Returns the chain ID for a given chain selector.
     * @param chainSelector The chain selector to get the chain ID for.
     * @return The chain ID as a uint8.
     */
    function getChainId(uint64 chainSelector) public view returns (uint8) {
        return mpcIds[chainSelector];
    }

    function manualClaim(bytes calldata) external view onlyTeleport {
        revert ManualClaimOffchain();
    }

    /// @notice Return the current router
    /// @return i_router address
    function getRouter() public view returns (address) {
        return address(_iRouter);
    }

    /// @notice Return the current gas limit
    /// @return _gasLimit gas limit
    function getGasLimit() public view returns (uint256) {
        return _gasLimit;
    }

    /**
     * @dev Returns the fee required for transmitting a message from the source chain to the target chain.
     * @param targetChainId The MPC ID of the target chain.
     * @param transmissionTeleportReceiver The address of the receiver on the target chain.
     * @param dappTranmissionInfo The transmission information.
     * @return The fee required for the transmission.
     */
    function fee(
        uint8 targetChainId,
        bytes calldata transmissionTeleportReceiver,
        DappTransmissionInfo calldata dappTranmissionInfo,
        bytes calldata extraOptionalArgs
    ) external view override returns (uint256) {
        (uint256 fees, , , ) = prepareMessage(
            targetChainId,
            transmissionTeleportReceiver,
            dappTranmissionInfo,
            extraOptionalArgs
        );
        return fees;
    }

    /**
     * @dev Configures the CCIPProvider contract with the provided configuration data.
     * @param configData The configuration data to be decoded and used to set the CCIPProvider parameters.
     * @notice Only callable by the Teleport contract.
     * @notice The `params.mpcIds` and `params.ccipChainSelectors` arrays must have the same length.
     * @notice For each `MPCId` in `params.mpcIds`, sets the corresponding `ccipChainSelector` in the `ccipChainSelectors` mapping.
     * @notice For each `ccipChainSelector` in `params.ccipChainSelectors`, sets the corresponding `MPCId` in the `mpcIds` mapping.
     * @notice If `params.routerAddress` is not the zero address, sets the `i_router` address to `params.routerAddress`.
     */
    function config(bytes calldata configData) external override onlyTeleport {
        ConfigCallParamsV1 memory params = _decodeConfigMessage(configData);

        if (params.mpcIds.length != params.ccipChainSelectors.length) revert ArraysLenMismatch();

        if (params.mpcIds.length != params.ccipReceivers.length) revert ArraysLenMismatch();

        // Set the router address only if a value is provided. Otherwise, keep the current address.
        if (params.routerAddress != address(0)) {
            _iRouter = params.routerAddress;
        }

        // Set the chain mappings only if some values are provided. Otherwise, keep the current mappings.
        if (params.mpcIds.length > 0) {
            uint256 len = _supportedChains.length; // We cache the length to avoid multiple reads
            // Reset mappings
            for (uint256 i = 0; i < len; ) {
                delete mpcIds[ccipChainSelectors[_supportedChains[i]]];
                delete ccipChainSelectors[_supportedChains[i]];
                delete ccipReceivers[_supportedChains[i]];

                unchecked {
                    ++i;
                }
            }

            // Reset _supportedChains
            delete _supportedChains;
            for (uint256 i = 0; i < params.mpcIds.length; ) {
                if (ccipChainSelectors[params.mpcIds[i]] != 0 || mpcIds[params.ccipChainSelectors[i]] != 0) {
                    revert DuplicateChainSelectorOrMPCId();
                }

                if (params.ccipReceivers[i] == address(0)) {
                    revert ReceiverCannotBeZeroAddress();
                }

                ccipChainSelectors[params.mpcIds[i]] = params.ccipChainSelectors[i];
                ccipReceivers[params.mpcIds[i]] = params.ccipReceivers[i];
                mpcIds[params.ccipChainSelectors[i]] = params.mpcIds[i];
                _supportedChains.push(params.mpcIds[i]);
                unchecked {
                    ++i;
                }
            }
        }

        // Set the gas limit only if a value is provided. Otherwise, keep the current value.
        if (params.gasLimit != 0) {
            _gasLimit = params.gasLimit;
        }
    }

    /**
     * @dev Internal function to handle receiving messages from the CCIP protocol.
     * @param message The message received from the CCIP protocol.
     */
    function ccipReceive(Client.Any2EVMMessage calldata message) external override onlyRouter {
        // Decode the payload to get the target chain ID, receiver address, dApp ID and payload from message.data

        MessageData memory decodedData = _decodeTeleportMessage(message.data);

        if (TELEPORT_ADDRESS != address(uint160(bytes20(decodedData.receiverTeleportAddress))))
            revert UnrecognizedTeleportReceiver();

        IProvider.DappTransmissionInfo memory info = decodedData.info;

        if (info.dappTransmissionReceiver.length != 20) revert OnlyEVMSupport(info.dappTransmissionReceiver);

        address transmissionReceiverAddress = address(uint160(bytes20(info.dappTransmissionReceiver)));

        uint8 sourceChainId = getChainId(message.sourceChainSelector);

        if (sourceChainId == 0) revert SrcChainUnsupported();

        address ccipSenderAddress = abi.decode(message.sender, (address));

        if (ccipSenderAddress != ccipReceivers[sourceChainId]) revert UnrecognizedCCIPSender();

        ITeleport(TELEPORT_ADDRESS).onProviderReceive(
            ITeleport.DappTransmissionReceive({
                teleportSender: decodedData.senderTeleportAddress,
                sourceChainId: sourceChainId,
                dappTransmissionSender: info.dappTransmissionSender,
                dappTransmissionReceiver: transmissionReceiverAddress,
                dAppId: info.dAppId,
                payload: info.dappPayload
            })
        );
    }

    /**
     * @dev Encodes a teleport message for the CCIP protocol.
     * @param info The transmission information for the message.
     * @return The encoded message as bytes.
     */
    function _encodeTeleportMessage(
        IProvider.DappTransmissionInfo memory info,
        address senderTeleportAddress,
        bytes calldata receiverTeleportAddress
    ) internal pure returns (bytes memory) {
        // Create an struct in memory with necessary information for sending a cross-chain message
        return abi.encode(MessageData(info, abi.encodePacked(senderTeleportAddress), receiverTeleportAddress));
    }

    struct MessageData {
        IProvider.DappTransmissionInfo info;
        bytes senderTeleportAddress;
        bytes receiverTeleportAddress;
    }

    /**
     * @dev Decodes a teleport message payload into a DappTransmissionInfo struct.
     * @param _payload The payload of the teleport message.
     * @return A DappTransmissionInfo struct containing the decoded information.
     */
    function _decodeTeleportMessage(bytes calldata _payload) internal pure returns (MessageData memory) {
        // Decode the payload from message.data and return the decoded values
        return abi.decode(_payload, (MessageData));
    }

    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for sending a text.
    /// @param _receiver The address of the receiver.
    /// @param _payload The data to be sent.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address _receiver,
        bytes memory _payload,
        address _feeTokenAddress,
        bytes calldata extraOptionalArgs_
    ) internal view returns (Client.EVM2AnyMessage memory) {
        Client.EVMExtraArgsV1 memory extraArgs;
        // If extraOptionalArgs_ is not empty, decode the EVMExtraArgsV1 struct from it
        if (extraOptionalArgs_.length != 0) {
            extraArgs = abi.decode(extraOptionalArgs_, (Client.EVMExtraArgsV1));
        } else {
            // If extraOptionalArgs_ is empty, create an empty EVMExtraArgsV1 struct
            extraArgs = Client.EVMExtraArgsV1({gasLimit: 0});
        }

        // If the gasLimit is not set, set it to 200_000
        if (extraArgs.gasLimit == 0) {
            extraArgs.gasLimit = _gasLimit;
        }

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: _payload, // ABI-encoded string
                tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array as no tokens are transferred
                extraArgs: Client._argsToBytes(extraArgs), // Additional arguments, setting gas limit and non-strict sequencing mode
                feeToken: _feeTokenAddress // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            });
    }

    /**
     * @dev Internal function to decode a configuration message received from the teleport.
     * @param _data The config data received from the CCIP.
     * @return The decoded configuration params.
     */
    function _decodeConfigMessage(bytes memory _data) internal pure returns (ConfigCallParamsV1 memory) {
        return abi.decode(_data, (ConfigCallParamsV1));
    }

    // TODO: Wouldn't it be better to have another struct to handle possible future versions of the config struct?
    struct ConfigCallParamsV1 {
        uint8[] mpcIds;
        uint64[] ccipChainSelectors;
        address[] ccipReceivers;
        address routerAddress;
        uint256 gasLimit;
    }

    /// @notice IERC165 supports an interfaceId
    /// @param interfaceId The interfaceId to check
    /// @return true if the interfaceId is supported
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IProvider).interfaceId;
    }

    /**
     * @dev Allows knowing all chains that are supported from offchain
     */
    function supportedChains(uint256 index) external view override returns (uint8) {
        return _supportedChains[index];
    }

    /**
     * @dev Amount of supported chains
     */
    function supportedChainsCount() external view override returns (uint256) {
        return _supportedChains.length;
    }
}