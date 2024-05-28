// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// @dev Import the 'MessagingFee' and 'MessagingReceipt' so it's exposed to OApp implementers
// solhint-disable-next-line no-unused-import
import { OAppSender, MessagingFee, MessagingReceipt } from "./OAppSender.sol";
// @dev Import the 'Origin' so it's exposed to OApp implementers
// solhint-disable-next-line no-unused-import
import { OAppReceiver, Origin } from "./OAppReceiver.sol";
import { OAppCore } from "./OAppCore.sol";

/**
 * @title OApp
 * @dev Abstract contract serving as the base for OApp implementation, combining OAppSender and OAppReceiver functionality.
 */
abstract contract OApp is OAppSender, OAppReceiver {
    /**
     * @dev Constructor to initialize the OApp with the provided endpoint and owner.
     * @param _endpoint The address of the LOCAL LayerZero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(address _endpoint, address _delegate) OAppCore(_endpoint, _delegate) {}

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol implementation.
     * @return receiverVersion The version of the OAppReceiver.sol implementation.
     */
    function oAppVersion()
        public
        pure
        virtual
        override(OAppSender, OAppReceiver)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (SENDER_VERSION, RECEIVER_VERSION);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IOAppCore, ILayerZeroEndpointV2 } from "./interfaces/IOAppCore.sol";

/**
 * @title OAppCore
 * @dev Abstract contract implementing the IOAppCore interface with basic OApp configurations.
 */
abstract contract OAppCore is IOAppCore, Ownable {
    // The LayerZero endpoint associated with the given OApp
    ILayerZeroEndpointV2 public immutable endpoint;

    // Mapping to store peers associated with corresponding endpoints
    mapping(uint32 eid => bytes32 peer) public peers;

    /**
     * @dev Constructor to initialize the OAppCore with the provided endpoint and delegate.
     * @param _endpoint The address of the LOCAL Layer Zero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     *
     * @dev The delegate typically should be set as the owner of the contract.
     */
    constructor(address _endpoint, address _delegate) {
        endpoint = ILayerZeroEndpointV2(_endpoint);

        if (_delegate == address(0)) revert InvalidDelegate();
        endpoint.setDelegate(_delegate);
    }

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
     * @dev Set this to bytes32(0) to remove the peer address.
     * @dev Peer is a bytes32 to accommodate non-evm chains.
     */
    function setPeer(uint32 _eid, bytes32 _peer) public virtual onlyOwner {
        _setPeer(_eid, _peer);
    }

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     *
     * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
     * @dev Set this to bytes32(0) to remove the peer address.
     * @dev Peer is a bytes32 to accommodate non-evm chains.
     */
    function _setPeer(uint32 _eid, bytes32 _peer) internal virtual {
        peers[_eid] = _peer;
        emit PeerSet(_eid, _peer);
    }

    /**
     * @notice Internal function to get the peer address associated with a specific endpoint; reverts if NOT set.
     * ie. the peer is set to bytes32(0).
     * @param _eid The endpoint ID.
     * @return peer The address of the peer associated with the specified endpoint.
     */
    function _getPeerOrRevert(uint32 _eid) internal view virtual returns (bytes32) {
        bytes32 peer = peers[_eid];
        if (peer == bytes32(0)) revert NoPeer(_eid);
        return peer;
    }

    /**
     * @notice Sets the delegate address for the OApp.
     * @param _delegate The address of the delegate to be set.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Provides the ability for a delegate to set configs, on behalf of the OApp, directly on the Endpoint contract.
     */
    function setDelegate(address _delegate) public onlyOwner {
        endpoint.setDelegate(_delegate);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IOAppReceiver, Origin } from "./interfaces/IOAppReceiver.sol";
import { OAppCore } from "./OAppCore.sol";

/**
 * @title OAppReceiver
 * @dev Abstract contract implementing the ILayerZeroReceiver interface and extending OAppCore for OApp receivers.
 */
abstract contract OAppReceiver is IOAppReceiver, OAppCore {
    // Custom error message for when the caller is not the registered endpoint/
    error OnlyEndpoint(address addr);

    // @dev The version of the OAppReceiver implementation.
    // @dev Version is bumped when changes are made to this contract.
    uint64 internal constant RECEIVER_VERSION = 2;

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol contract.
     * @return receiverVersion The version of the OAppReceiver.sol contract.
     *
     * @dev Providing 0 as the default for OAppSender version. Indicates that the OAppSender is not implemented.
     * ie. this is a RECEIVE only OApp.
     * @dev If the OApp uses both OAppSender and OAppReceiver, then this needs to be override returning the correct versions.
     */
    function oAppVersion() public view virtual returns (uint64 senderVersion, uint64 receiverVersion) {
        return (0, RECEIVER_VERSION);
    }

    /**
     * @notice Indicates whether an address is an approved composeMsg sender to the Endpoint.
     * @dev _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @dev _message The lzReceive payload.
     * @param _sender The sender address.
     * @return isSender Is a valid sender.
     *
     * @dev Applications can optionally choose to implement separate composeMsg senders that are NOT the bridging layer.
     * @dev The default sender IS the OAppReceiver implementer.
     */
    function isComposeMsgSender(
        Origin calldata /*_origin*/,
        bytes calldata /*_message*/,
        address _sender
    ) public view virtual returns (bool) {
        return _sender == address(this);
    }

    /**
     * @notice Checks if the path initialization is allowed based on the provided origin.
     * @param origin The origin information containing the source endpoint and sender address.
     * @return Whether the path has been initialized.
     *
     * @dev This indicates to the endpoint that the OApp has enabled msgs for this particular path to be received.
     * @dev This defaults to assuming if a peer has been set, its initialized.
     * Can be overridden by the OApp if there is other logic to determine this.
     */
    function allowInitializePath(Origin calldata origin) public view virtual returns (bool) {
        return peers[origin.srcEid] == origin.sender;
    }

    /**
     * @notice Retrieves the next nonce for a given source endpoint and sender address.
     * @dev _srcEid The source endpoint ID.
     * @dev _sender The sender address.
     * @return nonce The next nonce.
     *
     * @dev The path nonce starts from 1. If 0 is returned it means that there is NO nonce ordered enforcement.
     * @dev Is required by the off-chain executor to determine the OApp expects msg execution is ordered.
     * @dev This is also enforced by the OApp.
     * @dev By default this is NOT enabled. ie. nextNonce is hardcoded to return 0.
     */
    function nextNonce(uint32 /*_srcEid*/, bytes32 /*_sender*/) public view virtual returns (uint64 nonce) {
        return 0;
    }

    /**
     * @dev Entry point for receiving messages or packets from the endpoint.
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The payload of the received message.
     * @param _executor The address of the executor for the received message.
     * @param _extraData Additional arbitrary data provided by the corresponding executor.
     *
     * @dev Entry point for receiving msg/packet from the LayerZero endpoint.
     */
    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) public payable virtual {
        // Ensures that only the endpoint can attempt to lzReceive() messages to this OApp.
        if (address(endpoint) != msg.sender) revert OnlyEndpoint(msg.sender);

        // Ensure that the sender matches the expected peer for the source endpoint.
        if (_getPeerOrRevert(_origin.srcEid) != _origin.sender) revert OnlyPeer(_origin.srcEid, _origin.sender);

        // Call the internal OApp implementation of lzReceive.
        _lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    /**
     * @dev Internal function to implement lzReceive logic without needing to copy the basic parameter validation.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MessagingParams, MessagingFee, MessagingReceipt } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { OAppCore } from "./OAppCore.sol";

/**
 * @title OAppSender
 * @dev Abstract contract implementing the OAppSender functionality for sending messages to a LayerZero endpoint.
 */
abstract contract OAppSender is OAppCore {
    using SafeERC20 for IERC20;

    // Custom error messages
    error NotEnoughNative(uint256 msgValue);
    error LzTokenUnavailable();

    // @dev The version of the OAppSender implementation.
    // @dev Version is bumped when changes are made to this contract.
    uint64 internal constant SENDER_VERSION = 1;

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol contract.
     * @return receiverVersion The version of the OAppReceiver.sol contract.
     *
     * @dev Providing 0 as the default for OAppReceiver version. Indicates that the OAppReceiver is not implemented.
     * ie. this is a SEND only OApp.
     * @dev If the OApp uses both OAppSender and OAppReceiver, then this needs to be override returning the correct versions
     */
    function oAppVersion() public view virtual returns (uint64 senderVersion, uint64 receiverVersion) {
        return (SENDER_VERSION, 0);
    }

    /**
     * @dev Internal function to interact with the LayerZero EndpointV2.quote() for fee calculation.
     * @param _dstEid The destination endpoint ID.
     * @param _message The message payload.
     * @param _options Additional options for the message.
     * @param _payInLzToken Flag indicating whether to pay the fee in LZ tokens.
     * @return fee The calculated MessagingFee for the message.
     *      - nativeFee: The native fee for the message.
     *      - lzTokenFee: The LZ token fee for the message.
     */
    function _quote(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        bool _payInLzToken
    ) internal view virtual returns (MessagingFee memory fee) {
        return
            endpoint.quote(
                MessagingParams(_dstEid, _getPeerOrRevert(_dstEid), _message, _options, _payInLzToken),
                address(this)
            );
    }

    /**
     * @dev Internal function to interact with the LayerZero EndpointV2.send() for sending a message.
     * @param _dstEid The destination endpoint ID.
     * @param _message The message payload.
     * @param _options Additional options for the message.
     * @param _fee The calculated LayerZero fee for the message.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess fee values sent to the endpoint.
     * @return receipt The receipt for the sent message.
     *      - guid: The unique identifier for the sent message.
     *      - nonce: The nonce of the sent message.
     *      - fee: The LayerZero fee incurred for the message.
     */
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    ) internal virtual returns (MessagingReceipt memory receipt) {
        // @dev Push corresponding fees to the endpoint, any excess is sent back to the _refundAddress from the endpoint.
        uint256 messageValue = _payNative(_fee.nativeFee);
        if (_fee.lzTokenFee > 0) _payLzToken(_fee.lzTokenFee);

        return
            // solhint-disable-next-line check-send-result
            endpoint.send{ value: messageValue }(
                MessagingParams(_dstEid, _getPeerOrRevert(_dstEid), _message, _options, _fee.lzTokenFee > 0),
                _refundAddress
            );
    }

    /**
     * @dev Internal function to pay the native fee associated with the message.
     * @param _nativeFee The native fee to be paid.
     * @return nativeFee The amount of native currency paid.
     *
     * @dev If the OApp needs to initiate MULTIPLE LayerZero messages in a single transaction,
     * this will need to be overridden because msg.value would contain multiple lzFees.
     * @dev Should be overridden in the event the LayerZero endpoint requires a different native currency.
     * @dev Some EVMs use an ERC20 as a method for paying transactions/gasFees.
     * @dev The endpoint is EITHER/OR, ie. it will NOT support both types of native payment at a time.
     */
    function _payNative(uint256 _nativeFee) internal virtual returns (uint256 nativeFee) {
        if (msg.value != _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    /**
     * @dev Internal function to pay the LZ token fee associated with the message.
     * @param _lzTokenFee The LZ token fee to be paid.
     *
     * @dev If the caller is trying to pay in the specified lzToken, then the lzTokenFee is passed to the endpoint.
     * @dev Any excess sent, is passed back to the specified _refundAddress in the _lzSend().
     */
    function _payLzToken(uint256 _lzTokenFee) internal virtual {
        // @dev Cannot cache the token because it is not immutable in the endpoint.
        address lzToken = endpoint.lzToken();
        if (lzToken == address(0)) revert LzTokenUnavailable();

        // Pay LZ token fee by sending tokens to the endpoint.
        IERC20(lzToken).safeTransferFrom(msg.sender, address(endpoint), _lzTokenFee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

/**
 * @title IOAppCore
 */
interface IOAppCore {
    // Custom error messages
    error OnlyPeer(uint32 eid, bytes32 sender);
    error NoPeer(uint32 eid);
    error InvalidEndpointCall();
    error InvalidDelegate();

    // Event emitted when a peer (OApp) is set for a corresponding endpoint
    event PeerSet(uint32 eid, bytes32 peer);

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol contract.
     * @return receiverVersion The version of the OAppReceiver.sol contract.
     */
    function oAppVersion() external view returns (uint64 senderVersion, uint64 receiverVersion);

    /**
     * @notice Retrieves the LayerZero endpoint associated with the OApp.
     * @return iEndpoint The LayerZero endpoint as an interface.
     */
    function endpoint() external view returns (ILayerZeroEndpointV2 iEndpoint);

    /**
     * @notice Retrieves the peer (OApp) associated with a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @return peer The peer address (OApp instance) associated with the corresponding endpoint.
     */
    function peers(uint32 _eid) external view returns (bytes32 peer);

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     */
    function setPeer(uint32 _eid, bytes32 _peer) external;

    /**
     * @notice Sets the delegate address for the OApp Core.
     * @param _delegate The address of the delegate to be set.
     */
    function setDelegate(address _delegate) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ILayerZeroReceiver, Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroReceiver.sol";

interface IOAppReceiver is ILayerZeroReceiver {
    /**
     * @notice Indicates whether an address is an approved composeMsg sender to the Endpoint.
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _message The lzReceive payload.
     * @param _sender The sender address.
     * @return isSender Is a valid sender.
     *
     * @dev Applications can optionally choose to implement a separate composeMsg sender that is NOT the bridging layer.
     * @dev The default sender IS the OAppReceiver implementer.
     */
    function isComposeMsgSender(
        Origin calldata _origin,
        bytes calldata _message,
        address _sender
    ) external view returns (bool isSender);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { MessagingReceipt, MessagingFee } from "../../oapp/OAppSender.sol";

/**
 * @dev Struct representing token parameters for the OFT send() operation.
 */
struct SendParam {
    uint32 dstEid; // Destination endpoint ID.
    bytes32 to; // Recipient address.
    uint256 amountLD; // Amount to send in local decimals.
    uint256 minAmountLD; // Minimum amount to send in local decimals.
    bytes extraOptions; // Additional options supplied by the caller to be used in the LayerZero message.
    bytes composeMsg; // The composed message for the send() operation.
    bytes oftCmd; // The OFT command to be executed, unused in default OFT implementations.
}

/**
 * @dev Struct representing OFT limit information.
 * @dev These amounts can change dynamically and are up the the specific oft implementation.
 */
struct OFTLimit {
    uint256 minAmountLD; // Minimum amount in local decimals that can be sent to the recipient.
    uint256 maxAmountLD; // Maximum amount in local decimals that can be sent to the recipient.
}

/**
 * @dev Struct representing OFT receipt information.
 */
struct OFTReceipt {
    uint256 amountSentLD; // Amount of tokens ACTUALLY debited from the sender in local decimals.
    // @dev In non-default implementations, the amountReceivedLD COULD differ from this value.
    uint256 amountReceivedLD; // Amount of tokens to be received on the remote side.
}

/**
 * @dev Struct representing OFT fee details.
 * @dev Future proof mechanism to provide a standardized way to communicate fees to things like a UI.
 */
struct OFTFeeDetail {
    int256 feeAmountLD; // Amount of the fee in local decimals.
    string description; // Description of the fee.
}

/**
 * @title IOFT
 * @dev Interface for the OftChain (OFT) token.
 * @dev Does not inherit ERC20 to accommodate usage by OFTAdapter as well.
 * @dev This specific interface ID is '0x02e49c2c'.
 */
interface IOFT {
    // Custom error messages
    error InvalidLocalDecimals();
    error SlippageExceeded(uint256 amountLD, uint256 minAmountLD);

    // Events
    event OFTSent(
        bytes32 indexed guid, // GUID of the OFT message.
        uint32 dstEid, // Destination Endpoint ID.
        address indexed fromAddress, // Address of the sender on the src chain.
        uint256 amountSentLD, // Amount of tokens sent in local decimals.
        uint256 amountReceivedLD // Amount of tokens received in local decimals.
    );
    event OFTReceived(
        bytes32 indexed guid, // GUID of the OFT message.
        uint32 srcEid, // Source Endpoint ID.
        address indexed toAddress, // Address of the recipient on the dst chain.
        uint256 amountReceivedLD // Amount of tokens received in local decimals.
    );

    /**
     * @notice Retrieves interfaceID and the version of the OFT.
     * @return interfaceId The interface ID.
     * @return version The version.
     *
     * @dev interfaceId: This specific interface ID is '0x02e49c2c'.
     * @dev version: Indicates a cross-chain compatible msg encoding with other OFTs.
     * @dev If a new feature is added to the OFT cross-chain msg encoding, the version will be incremented.
     * ie. localOFT version(x,1) CAN send messages to remoteOFT version(x,1)
     */
    function oftVersion() external view returns (bytes4 interfaceId, uint64 version);

    /**
     * @notice Retrieves the address of the token associated with the OFT.
     * @return token The address of the ERC20 token implementation.
     */
    function token() external view returns (address);

    /**
     * @notice Indicates whether the OFT contract requires approval of the 'token()' to send.
     * @return requiresApproval Needs approval of the underlying token implementation.
     *
     * @dev Allows things like wallet implementers to determine integration requirements,
     * without understanding the underlying token implementation.
     */
    function approvalRequired() external view returns (bool);

    /**
     * @notice Retrieves the shared decimals of the OFT.
     * @return sharedDecimals The shared decimals of the OFT.
     */
    function sharedDecimals() external view returns (uint8);

    /**
     * @notice Provides a quote for OFT-related operations.
     * @param _sendParam The parameters for the send operation.
     * @return limit The OFT limit information.
     * @return oftFeeDetails The details of OFT fees.
     * @return receipt The OFT receipt information.
     */
    function quoteOFT(
        SendParam calldata _sendParam
    ) external view returns (OFTLimit memory, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory);

    /**
     * @notice Provides a quote for the send() operation.
     * @param _sendParam The parameters for the send() operation.
     * @param _payInLzToken Flag indicating whether the caller is paying in the LZ token.
     * @return fee The calculated LayerZero messaging fee from the send() operation.
     *
     * @dev MessagingFee: LayerZero msg fee
     *  - nativeFee: The native fee.
     *  - lzTokenFee: The lzToken fee.
     */
    function quoteSend(SendParam calldata _sendParam, bool _payInLzToken) external view returns (MessagingFee memory);

    /**
     * @notice Executes the send() operation.
     * @param _sendParam The parameters for the send operation.
     * @param _fee The fee information supplied by the caller.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess funds from fees etc. on the src.
     * @return receipt The LayerZero messaging receipt from the send() operation.
     * @return oftReceipt The OFT receipt information.
     *
     * @dev MessagingReceipt: LayerZero msg receipt
     *  - guid: The unique identifier for the sent message.
     *  - nonce: The nonce of the sent message.
     *  - fee: The LayerZero fee incurred for the message.
     */
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory, OFTReceipt memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library OFTComposeMsgCodec {
    // Offset constants for decoding composed messages
    uint8 private constant NONCE_OFFSET = 8;
    uint8 private constant SRC_EID_OFFSET = 12;
    uint8 private constant AMOUNT_LD_OFFSET = 44;
    uint8 private constant COMPOSE_FROM_OFFSET = 76;

    /**
     * @dev Encodes a OFT composed message.
     * @param _nonce The nonce value.
     * @param _srcEid The source endpoint ID.
     * @param _amountLD The amount in local decimals.
     * @param _composeMsg The composed message.
     * @return _msg The encoded Composed message.
     */
    function encode(
        uint64 _nonce,
        uint32 _srcEid,
        uint256 _amountLD,
        bytes memory _composeMsg // 0x[composeFrom][composeMsg]
    ) internal pure returns (bytes memory _msg) {
        _msg = abi.encodePacked(_nonce, _srcEid, _amountLD, _composeMsg);
    }

    /**
     * @dev Retrieves the nonce from the composed message.
     * @param _msg The message.
     * @return The nonce value.
     */
    function nonce(bytes calldata _msg) internal pure returns (uint64) {
        return uint64(bytes8(_msg[:NONCE_OFFSET]));
    }

    /**
     * @dev Retrieves the source endpoint ID from the composed message.
     * @param _msg The message.
     * @return The source endpoint ID.
     */
    function srcEid(bytes calldata _msg) internal pure returns (uint32) {
        return uint32(bytes4(_msg[NONCE_OFFSET:SRC_EID_OFFSET]));
    }

    /**
     * @dev Retrieves the amount in local decimals from the composed message.
     * @param _msg The message.
     * @return The amount in local decimals.
     */
    function amountLD(bytes calldata _msg) internal pure returns (uint256) {
        return uint256(bytes32(_msg[SRC_EID_OFFSET:AMOUNT_LD_OFFSET]));
    }

    /**
     * @dev Retrieves the composeFrom value from the composed message.
     * @param _msg The message.
     * @return The composeFrom value.
     */
    function composeFrom(bytes calldata _msg) internal pure returns (bytes32) {
        return bytes32(_msg[AMOUNT_LD_OFFSET:COMPOSE_FROM_OFFSET]);
    }

    /**
     * @dev Retrieves the composed message.
     * @param _msg The message.
     * @return The composed message.
     */
    function composeMsg(bytes calldata _msg) internal pure returns (bytes memory) {
        return _msg[COMPOSE_FROM_OFFSET:];
    }

    /**
     * @dev Converts an address to bytes32.
     * @param _addr The address to convert.
     * @return The bytes32 representation of the address.
     */
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    /**
     * @dev Converts bytes32 to an address.
     * @param _b The bytes32 value to convert.
     * @return The address representation of bytes32.
     */
    function bytes32ToAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { IMessageLibManager } from "./IMessageLibManager.sol";
import { IMessagingComposer } from "./IMessagingComposer.sol";
import { IMessagingChannel } from "./IMessagingChannel.sol";
import { IMessagingContext } from "./IMessagingContext.sol";

struct MessagingParams {
    uint32 dstEid;
    bytes32 receiver;
    bytes message;
    bytes options;
    bool payInLzToken;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct MessagingFee {
    uint256 nativeFee;
    uint256 lzTokenFee;
}

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

enum ExecutionState {
    NotExecutable,
    Executable,
    Executed
}

interface ILayerZeroEndpointV2 is IMessageLibManager, IMessagingComposer, IMessagingChannel, IMessagingContext {
    event PacketSent(bytes encodedPayload, bytes options, address sendLibrary);

    event PacketVerified(Origin origin, address receiver, bytes32 payloadHash);

    event PacketDelivered(Origin origin, address receiver);

    event LzReceiveAlert(
        address indexed receiver,
        address indexed executor,
        Origin origin,
        bytes32 guid,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    event LzTokenSet(address token);

    function quote(MessagingParams calldata _params, address _sender) external view returns (MessagingFee memory);

    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory);

    function verify(Origin calldata _origin, address _receiver, bytes32 _payloadHash) external;

    function verifiable(
        Origin calldata _origin,
        address _receiver,
        address _receiveLib,
        bytes32 _payloadHash
    ) external view returns (bool);

    function executable(Origin calldata _origin, address _receiver) external view returns (ExecutionState);

    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;

    // oapp can burn messages partially by calling this function with its own business logic if messages are verified in order
    function clear(address _oapp, Origin calldata _origin, bytes32 _guid, bytes calldata _message) external;

    function setLzToken(address _lzToken) external;

    function lzToken() external view returns (address);

    function nativeToken() external view returns (address);

    function setDelegate(address _delegate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { Origin } from "./ILayerZeroEndpointV2.sol";

interface ILayerZeroReceiver {
    function allowInitializePath(Origin calldata _origin) external view returns (bool);

    // todo: move to OAppReceiver? it is just convention for executor. we may can change it in a new Receiver version
    function nextNonce(uint32 _eid, bytes32 _sender) external view returns (uint64);

    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

struct SetConfigParam {
    uint32 eid;
    uint32 configType;
    bytes config;
}

interface IMessageLibManager {
    struct Timeout {
        address lib;
        uint256 expiry;
    }

    event LibraryRegistered(address newLib);
    event DefaultSendLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibrarySet(uint32 eid, address oldLib, address newLib);
    event DefaultReceiveLibraryTimeoutSet(uint32 eid, address oldLib, uint256 expiry);
    event SendLibrarySet(address sender, uint32 eid, address newLib);
    event ReceiveLibrarySet(address receiver, uint32 eid, address oldLib, address newLib);
    event ReceiveLibraryTimeoutSet(address receiver, uint32 eid, address oldLib, uint256 timeout);

    function registerLibrary(address _lib) external;

    function isRegisteredLibrary(address _lib) external view returns (bool);

    function getRegisteredLibraries() external view returns (address[] memory);

    function setDefaultSendLibrary(uint32 _eid, address _newLib) external;

    function defaultSendLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibrary(uint32 _eid, address _newLib, uint256 _timeout) external;

    function defaultReceiveLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibraryTimeout(uint32 _eid, address _lib, uint256 _expiry) external;

    function defaultReceiveLibraryTimeout(uint32 _eid) external view returns (address lib, uint256 expiry);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    /// ------------------- OApp interfaces -------------------
    function setSendLibrary(address _oapp, uint32 _eid, address _newLib) external;

    function getSendLibrary(address _sender, uint32 _eid) external view returns (address lib);

    function isDefaultSendLibrary(address _sender, uint32 _eid) external view returns (bool);

    function setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod) external;

    function getReceiveLibrary(address _receiver, uint32 _eid) external view returns (address lib, bool isDefault);

    function setReceiveLibraryTimeout(address _oapp, uint32 _eid, address _lib, uint256 _gracePeriod) external;

    function receiveLibraryTimeout(address _receiver, uint32 _eid) external view returns (address lib, uint256 expiry);

    function setConfig(address _oapp, address _lib, SetConfigParam[] calldata _params) external;

    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view returns (bytes memory config);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingChannel {
    event InboundNonceSkipped(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce);
    event PacketNilified(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce, bytes32 payloadHash);
    event PacketBurnt(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce, bytes32 payloadHash);

    function eid() external view returns (uint32);

    // this is an emergency function if a message cannot be verified for some reasons
    // required to provide _nextNonce to avoid race condition
    function skip(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce) external;

    function nilify(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce, bytes32 _payloadHash) external;

    function burn(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce, bytes32 _payloadHash) external;

    function nextGuid(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (bytes32);

    function inboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64);

    function outboundNonce(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (uint64);

    function inboundPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingComposer {
    event ComposeSent(address from, address to, bytes32 guid, uint16 index, bytes message);
    event ComposeDelivered(address from, address to, bytes32 guid, uint16 index);
    event LzComposeAlert(
        address indexed from,
        address indexed to,
        address indexed executor,
        bytes32 guid,
        uint16 index,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    function composeQueue(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index
    ) external view returns (bytes32 messageHash);

    function sendCompose(address _to, bytes32 _guid, uint16 _index, bytes calldata _message) external;

    function lzCompose(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingContext {
    function isSendingMessage() external view returns (bool);

    function getSendContext() external view returns (uint32 dstEid, address sender);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";
import { Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
// Solidity does not support splitting import across multiple lines
// solhint-disable-next-line max-line-length
import { OFTLimit, OFTFeeDetail, OFTReceipt, SendParam, MessagingReceipt, MessagingFee, IOFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

import { IStargate, Ticket } from "./interfaces/IStargate.sol";
import { IStargateFeeLib, FeeParams } from "./interfaces/IStargateFeeLib.sol";
import { ITokenMessaging, RideBusParams, TaxiParams } from "./interfaces/ITokenMessaging.sol";
import { ITokenMessagingHandler } from "./interfaces/ITokenMessagingHandler.sol";
import { ICreditMessagingHandler, Credit, TargetCredit } from "./interfaces/ICreditMessagingHandler.sol";
import { Path } from "./libs/Path.sol";
import { Transfer } from "./libs/Transfer.sol";

/// @title The base contract for StargateOFT, StargatePool, StargatePoolMigratable, and StargatePoolNative.
abstract contract StargateBase is Transfer, IStargate, ITokenMessagingHandler, ICreditMessagingHandler {
    using SafeCast for uint256;

    // Stargate status
    uint8 internal constant NOT_ENTERED = 1;
    uint8 internal constant ENTERED = 2;
    uint8 internal constant PAUSED = 3;

    /// @dev The token for the Pool or OFT.
    /// @dev address(0) indicates native coin, such as ETH.
    address public immutable override token;
    /// @dev The shared decimals (lowest common decimals between chains).
    uint8 public immutable override sharedDecimals;
    /// @dev The rate between local decimals and shared decimals.
    uint256 internal immutable convertRate;

    /// @dev The local LayerZero EndpointV2.
    ILayerZeroEndpointV2 public immutable endpoint;
    /// @dev The local LayerZero endpoint ID
    uint32 public immutable localEid;

    address internal feeLib;
    /// @dev The StargateBase status.  Options include 1. NOT_ENTERED 2. ENTERED and 3. PAUSED.
    uint8 public status = NOT_ENTERED;
    /// @dev The treasury accrued fees, stored in SD.
    uint64 public treasuryFee;

    address internal creditMessaging;
    address internal lzToken;
    address internal planner;
    address internal tokenMessaging;
    address internal treasurer;

    /// @dev Mapping of paths from this chain to other chains identified by their endpoint ID.
    mapping(uint32 eid => Path path) public paths;

    /// @dev A store for tokens that could not be delivered because _outflow() failed.
    /// @dev retryReceiveToken() can be called to retry the receive.
    mapping(bytes32 guid => mapping(uint8 index => bytes32 hash)) public unreceivedTokens;

    modifier onlyCaller(address _caller) {
        if (msg.sender != _caller) revert Stargate_Unauthorized();
        _;
    }

    modifier nonReentrantAndNotPaused() {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        if (status != NOT_ENTERED) {
            if (status == ENTERED) revert Stargate_ReentrantCall();
            revert Stargate_Paused();
        }
        // Any calls to nonReentrant after this point will fail
        status = ENTERED;
        _;
        status = NOT_ENTERED;
    }

    error Stargate_ReentrantCall();
    error Stargate_InvalidTokenDecimals();
    error Stargate_Unauthorized();
    error Stargate_SlippageTooHigh();
    error Stargate_UnreceivedTokenNotFound();
    error Stargate_OutflowFailed();
    error Stargate_InvalidAmount();
    error Stargate_InsufficientFare();
    error Stargate_InvalidPath();
    error Stargate_LzTokenUnavailable();
    error Stargate_Paused();
    error Stargate_RecoverTokenUnsupported();

    event AddressConfigSet(AddressConfig config);
    event CreditsSent(uint32 dstEid, Credit[] credits);
    event CreditsReceived(uint32 srcEid, Credit[] credits);
    event UnreceivedTokenCached(
        bytes32 guid,
        uint8 index,
        uint32 srcEid,
        address receiver,
        uint256 amountLD,
        bytes composeMsg
    );
    event OFTPathSet(uint32 dstEid, bool oft);
    event PauseSet(bool paused);
    event PlannerFeeWithdrawn(uint256 amount);
    event TreasuryFeeAdded(uint64 amountSD);
    event TreasuryFeeWithdrawn(address to, uint64 amountSD);

    struct AddressConfig {
        address feeLib;
        address planner;
        address treasurer;
        address tokenMessaging;
        address creditMessaging;
        address lzToken;
    }

    /// @notice Create a new Stargate contract
    /// @dev Reverts with InvalidTokenDecimals if the token decimals are smaller than the shared decimals.
    /// @param _token The token for the pool or oft. If the token is address(0), it is the native coin
    /// @param _tokenDecimals The number of decimals for this tokens implementation on this chain
    /// @param _sharedDecimals The number of decimals shared between all implementations of the OFT
    /// @param _endpoint The LZ endpoint contract
    /// @param _owner The owner of this contract
    constructor(address _token, uint8 _tokenDecimals, uint8 _sharedDecimals, address _endpoint, address _owner) {
        token = _token;
        if (_tokenDecimals < _sharedDecimals) revert Stargate_InvalidTokenDecimals();
        convertRate = 10 ** (_tokenDecimals - _sharedDecimals);
        sharedDecimals = _sharedDecimals;

        endpoint = ILayerZeroEndpointV2(_endpoint);
        localEid = endpoint.eid();
        _transferOwnership(_owner);
    }

    // ---------------------------------- Only Owner ------------------------------------------

    /// @notice Configure the roles for this contract.
    /// @param _config An AddressConfig object containing the addresses for the different roles used by Stargate.
    function setAddressConfig(AddressConfig calldata _config) external onlyOwner {
        feeLib = _config.feeLib;
        planner = _config.planner;
        treasurer = _config.treasurer;
        tokenMessaging = _config.tokenMessaging;
        creditMessaging = _config.creditMessaging;
        lzToken = _config.lzToken;
        emit AddressConfigSet(_config);
    }

    /// @notice Sets a given Path as using OFT or resets it from OFT.
    /// @dev Set the path as OFT if the remote chain is using OFT.
    /// @dev When migrating from OFT to pool on remote chain (e.g. migrate USDC to circles), reset the path to non-OFT.
    /// @dev Reverts with InvalidPath if the destination chain is the same as local.
    /// @param _dstEid The destination chain endpoint ID
    /// @param _oft Whether to set or reset the path
    function setOFTPath(uint32 _dstEid, bool _oft) external onlyOwner {
        if (_dstEid == localEid) revert Stargate_InvalidPath();
        paths[_dstEid].setOFTPath(_oft);
        emit OFTPathSet(_dstEid, _oft);
    }

    // ---------------------------------- Only Treasurer ------------------------------------------

    /// @notice Withdraw from the accrued fees in the treasury.
    /// @param _to The destination account
    /// @param _amountSD The amount to withdraw in SD
    function withdrawTreasuryFee(address _to, uint64 _amountSD) external onlyCaller(treasurer) {
        treasuryFee -= _amountSD;
        _safeOutflow(_to, _sd2ld(_amountSD));
        emit TreasuryFeeWithdrawn(_to, _amountSD);
    }

    /// @notice Add tokens to the treasury, from the senders account.
    /// @dev Only used for increasing the overall budget for transaction rewards
    /// @dev The treasuryFee is essentially the reward pool.
    /// @dev Rewards are capped to the treasury amount, which limits exposure so
    /// @dev Stargate does not pay beyond what it's charged.
    /// @param _amountLD The amount to add in LD
    function addTreasuryFee(uint256 _amountLD) external payable onlyCaller(treasurer) {
        _assertMsgValue(_amountLD);
        uint64 amountSD = _inflow(msg.sender, _amountLD);
        treasuryFee += amountSD;
        emit TreasuryFeeAdded(amountSD);
    }

    /// @dev Recover tokens sent to this contract by mistake.
    /// @dev Only the treasurer can recover the token.
    /// @dev Reverts with Stargate_RecoverTokenUnsupported if the treasurer attempts to withdraw StargateBase.token().
    /// @param _token the token to recover. if 0x0 then it is native token
    /// @param _to the address to send the token to
    /// @param _amount the amount to send
    function recoverToken(
        address _token,
        address _to,
        uint256 _amount
    ) public virtual nonReentrantAndNotPaused onlyCaller(treasurer) returns (uint256) {
        /// @dev Excess native is considered planner accumulated fees.
        if (_token == address(0)) revert Stargate_RecoverTokenUnsupported();
        Transfer.safeTransfer(_token, _to, _amount, false);
        return _amount;
    }

    // ---------------------------------- Only Planner ------------------------------------------

    /// @notice Pause or unpause a Stargate
    /// @dev Be careful with this call, as it unsets the re-entry guard.
    /// @param _paused Whether to pause or unpause the stargate
    function setPause(bool _paused) external onlyCaller(planner) {
        if (status == ENTERED) revert Stargate_ReentrantCall();
        status = _paused ? PAUSED : NOT_ENTERED;
        emit PauseSet(_paused);
    }

    function _plannerFee() internal view virtual returns (uint256) {
        return address(this).balance;
    }

    function plannerFee() external view returns (uint256 available) {
        available = _plannerFee();
    }

    /// @notice Withdraw planner fees accumulated in StargateBase.
    /// @dev The planner fee is accumulated in StargateBase to avoid the cost of passing msg.value to TokenMessaging.
    function withdrawPlannerFee() external virtual onlyCaller(planner) {
        uint256 available = _plannerFee();
        Transfer.safeTransferNative(msg.sender, available, false);
        emit PlannerFeeWithdrawn(available);
    }

    // ------------------------------- Public Functions ---------------------------------------

    /// @notice Send tokens through the Stargate
    /// @dev Emits OFTSent when the send is successful
    /// @param _sendParam The SendParam object detailing the transaction
    /// @param _fee The MessagingFee object describing the fee to pay
    /// @param _refundAddress The address to refund any LZ fees paid in excess
    /// @return msgReceipt The receipt proving the message was sent
    /// @return oftReceipt The receipt proving the OFT swap
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable override returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        (msgReceipt, oftReceipt, ) = sendToken(_sendParam, _fee, _refundAddress);
    }

    function sendToken(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    )
        public
        payable
        override
        nonReentrantAndNotPaused
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt, Ticket memory ticket)
    {
        // step 1: assets inflows and apply the fee to the input amount
        (bool isTaxi, uint64 amountInSD, uint64 amountOutSD) = _inflowAndCharge(_sendParam);

        // step 2: generate the oft receipt
        oftReceipt = OFTReceipt(_sd2ld(amountInSD), _sd2ld(amountOutSD));

        // step 3: assert the messaging fee
        MessagingFee memory messagingFee = _assertMessagingFee(_fee, oftReceipt.amountSentLD);

        // step 4: send the token depending on the mode Taxi or Bus
        if (isTaxi) {
            msgReceipt = _taxi(_sendParam, messagingFee, amountOutSD, _refundAddress);
        } else {
            (msgReceipt, ticket) = _rideBus(_sendParam, messagingFee, amountOutSD, _refundAddress);
        }

        emit OFTSent(
            msgReceipt.guid,
            _sendParam.dstEid,
            msg.sender,
            oftReceipt.amountSentLD,
            oftReceipt.amountReceivedLD
        );
    }

    /// @notice Retry receiving a token that initially failed.
    /// @dev The message has been delivered by the Messaging layer, so it is ok for anyone to retry.
    /// @dev try to receive the token if the previous attempt failed in lzReceive
    /// @dev Reverts with UnreceivedTokenNotFound if the message is not found in the cache
    /// @dev Emits OFTReceived if the receive succeeds
    /// @param _guid The global unique ID for the message that failed
    /// @param _index The index of the message that failed
    /// @param _srcEid The source endpoint ID for the message that failed
    /// @param _receiver The account receiver for the message that failed
    /// @param _amountLD The amount of tokens in LD to transfer to the account
    /// @param _composeMsg The bytes representing the compose message in the message that failed
    function retryReceiveToken(
        bytes32 _guid,
        uint8 _index,
        uint32 _srcEid,
        address _receiver,
        uint256 _amountLD,
        bytes calldata _composeMsg
    ) external nonReentrantAndNotPaused {
        if (unreceivedTokens[_guid][_index] != keccak256(abi.encodePacked(_srcEid, _receiver, _amountLD, _composeMsg)))
            revert Stargate_UnreceivedTokenNotFound();
        delete unreceivedTokens[_guid][_index];

        _safeOutflow(_receiver, _amountLD);
        _postOutflow(_ld2sd(_amountLD));
        if (_composeMsg.length > 0) {
            endpoint.sendCompose(_receiver, _guid, 0, _composeMsg);
        }
        emit OFTReceived(_guid, _srcEid, _receiver, _amountLD);
    }

    // ------------------------------- Only Messaging ---------------------------------------

    /// @notice Entrypoint for receiving tokens
    /// @dev Emits OFTReceived when the OFT token is correctly received
    /// @dev Emits UnreceivedTokenCached when the OFT token is not received
    /// @param _origin The Origin struct describing the origin, useful for composing
    /// @param _guid The global unique ID for this message, useful for composing
    function receiveTokenBus(
        Origin calldata _origin,
        bytes32 _guid,
        uint8 _seatNumber,
        address _receiver,
        uint64 _amountSD
    ) external nonReentrantAndNotPaused onlyCaller(tokenMessaging) {
        uint256 amountLD = _sd2ld(_amountSD);

        bool success = _outflow(_receiver, amountLD);
        if (success) {
            _postOutflow(_amountSD);
            emit OFTReceived(_guid, _origin.srcEid, _receiver, amountLD);
        } else {
            /**
             * @dev The busRide mode does not support composeMsg in any form. Thus we hardcode it to ""
             */
            unreceivedTokens[_guid][_seatNumber] = keccak256(abi.encodePacked(_origin.srcEid, _receiver, amountLD, ""));
            emit UnreceivedTokenCached(_guid, _seatNumber, _origin.srcEid, _receiver, amountLD, "");
        }
    }

    // taxi mode
    function receiveTokenTaxi(
        Origin calldata _origin,
        bytes32 _guid,
        address _receiver,
        uint64 _amountSD,
        bytes calldata _composeMsg
    ) external nonReentrantAndNotPaused onlyCaller(tokenMessaging) {
        uint256 amountLD = _sd2ld(_amountSD);
        bool hasCompose = _composeMsg.length > 0;
        bytes memory composeMsg;
        if (hasCompose) {
            composeMsg = OFTComposeMsgCodec.encode(_origin.nonce, _origin.srcEid, amountLD, _composeMsg);
        }

        bool success = _outflow(_receiver, amountLD);
        if (success) {
            _postOutflow(_amountSD);
            // send the composeMsg to the endpoint
            if (hasCompose) {
                endpoint.sendCompose(_receiver, _guid, 0, composeMsg);
            }
            emit OFTReceived(_guid, _origin.srcEid, _receiver, amountLD);
        } else {
            /**
             * @dev We use the '0' index to represent the seat number. This is because for a type 'taxi' msg,
             *      there is only ever one corresponding receiveTokenTaxi function per GUID.
             */
            unreceivedTokens[_guid][0] = keccak256(abi.encodePacked(_origin.srcEid, _receiver, amountLD, composeMsg));
            emit UnreceivedTokenCached(_guid, 0, _origin.srcEid, _receiver, amountLD, composeMsg);
        }
    }

    function sendCredits(
        uint32 _dstEid,
        TargetCredit[] calldata _credits
    ) external nonReentrantAndNotPaused onlyCaller(creditMessaging) returns (Credit[] memory) {
        Credit[] memory credits = new Credit[](_credits.length);
        uint256 index = 0;
        for (uint256 i = 0; i < _credits.length; i++) {
            TargetCredit calldata c = _credits[i];
            uint64 decreased = paths[c.srcEid].tryDecreaseCredit(c.amount, c.minAmount);
            if (decreased > 0) credits[index++] = Credit(c.srcEid, decreased);
        }
        // resize the array to the actual number of credits
        assembly {
            mstore(credits, index)
        }
        emit CreditsSent(_dstEid, credits);
        return credits;
    }

    /// @notice Entrypoint for receiving credits into paths
    /// @dev Emits CreditsReceived when credits are received
    /// @param _srcEid The endpoint ID of the source of credits
    /// @param _credits An array indicating to which paths and how much credits to add
    function receiveCredits(
        uint32 _srcEid,
        Credit[] calldata _credits
    ) external nonReentrantAndNotPaused onlyCaller(creditMessaging) {
        for (uint256 i = 0; i < _credits.length; i++) {
            Credit calldata c = _credits[i];
            paths[c.srcEid].increaseCredit(c.amount);
        }
        emit CreditsReceived(_srcEid, _credits);
    }

    // ---------------------------------- View Functions ------------------------------------------

    /// @notice Provides a quote for sending OFT to another chain.
    /// @dev Implements the IOFT interface
    /// @param _sendParam The parameters for the send operation
    /// @return limit The information on OFT transfer limits
    /// @return oftFeeDetails The details of OFT transaction cost or reward
    /// @return receipt The OFT receipt information, indicating how many tokens would be sent and received
    function quoteOFT(
        SendParam calldata _sendParam
    ) external view returns (OFTLimit memory limit, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory receipt) {
        // cap the transfer to the paths limit
        limit = OFTLimit(_sd2ld(1), _sd2ld(paths[_sendParam.dstEid].credit));

        // get the expected amount in the destination chain from FeeLib
        uint64 amountInSD = _ld2sd(_sendParam.amountLD > limit.maxAmountLD ? limit.maxAmountLD : _sendParam.amountLD);
        FeeParams memory params = _buildFeeParams(_sendParam.dstEid, amountInSD, _isTaxiMode(_sendParam.oftCmd));
        uint64 amountOutSD = IStargateFeeLib(feeLib).applyFeeView(params);

        // fill in the FeeDetails if there is a fee or reward
        if (amountOutSD != amountInSD) {
            oftFeeDetails = new OFTFeeDetail[](1);
            if (amountOutSD < amountInSD) {
                // fee
                oftFeeDetails[0] = OFTFeeDetail(-1 * _sd2ld(amountInSD - amountOutSD).toInt256(), "protocol fee");
            } else if (amountOutSD > amountInSD) {
                // reward
                uint64 reward = amountOutSD - amountInSD;
                (amountOutSD, reward) = _capReward(amountOutSD, reward);
                if (amountOutSD == amountInSD) {
                    // hide the Fee detail if the reward is capped to 0
                    oftFeeDetails = new OFTFeeDetail[](0);
                } else {
                    oftFeeDetails[0] = OFTFeeDetail(_sd2ld(reward).toInt256(), "reward");
                }
            }
        }

        receipt = OFTReceipt(_sd2ld(amountInSD), _sd2ld(amountOutSD));
    }

    /// @notice Provides a quote for the send() operation.
    /// @dev Implements the IOFT interface.
    /// @dev Reverts with InvalidAmount if send mode is drive but value is specified.
    /// @param _sendParam The parameters for the send() operation
    /// @param _payInLzToken Flag indicating whether the caller is paying in the LZ token
    /// @return fee The calculated LayerZero messaging fee from the send() operation
    /// @dev MessagingFee: LayerZero message fee
    ///   - nativeFee: The native fee.
    ///   - lzTokenFee: The LZ token fee.
    function quoteSend(
        SendParam calldata _sendParam,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee) {
        uint64 amountSD = _ld2sd(_sendParam.amountLD);
        if (amountSD == 0) revert Stargate_InvalidAmount();

        bool isTaxi = _isTaxiMode(_sendParam.oftCmd);
        if (isTaxi) {
            fee = ITokenMessaging(tokenMessaging).quoteTaxi(
                TaxiParams({
                    sender: msg.sender,
                    dstEid: _sendParam.dstEid,
                    receiver: _sendParam.to,
                    amountSD: amountSD,
                    composeMsg: _sendParam.composeMsg,
                    extraOptions: _sendParam.extraOptions
                }),
                _payInLzToken
            );
        } else {
            bool nativeDrop = _sendParam.extraOptions.length > 0;
            fee = ITokenMessaging(tokenMessaging).quoteRideBus(_sendParam.dstEid, nativeDrop);
        }
    }

    /// @notice Returns the current roles configured.
    /// @return An AddressConfig struct containing the current configuration
    function getAddressConfig() external view returns (AddressConfig memory) {
        return
            AddressConfig({
                feeLib: feeLib,
                planner: planner,
                treasurer: treasurer,
                tokenMessaging: tokenMessaging,
                creditMessaging: creditMessaging,
                lzToken: lzToken
            });
    }

    /// @notice Get the OFT version information
    /// @dev Implements the IOFT interface.
    /// @dev 0 version means the message encoding is not compatible with the default OFT.
    /// @return interfaceId The ERC165 interface ID for this contract
    /// @return version The cross-chain compatible message encoding version.
    function oftVersion() external pure override returns (bytes4 interfaceId, uint64 version) {
        return (type(IOFT).interfaceId, 0);
    }

    /// @notice Indicates whether the OFT contract requires approval of the 'token()' to send.
    /// @dev Implements the IOFT interface.
    /// @return Whether approval of the underlying token implementation is required
    function approvalRequired() external pure override returns (bool) {
        return true;
    }

    // ---------------------------------- Internal Functions ------------------------------------------

    /// @notice Ingest value into the contract and charge the Stargate fee.
    /// @dev This is triggered when value is transferred from an account into Stargate to execute a swap.
    /// @param _sendParam A SendParam struct containing the swap information
    function _inflowAndCharge(
        SendParam calldata _sendParam
    ) internal returns (bool isTaxi, uint64 amountInSD, uint64 amountOutSD) {
        isTaxi = _isTaxiMode(_sendParam.oftCmd);
        amountInSD = _inflow(msg.sender, _sendParam.amountLD);

        FeeParams memory feeParams = _buildFeeParams(_sendParam.dstEid, amountInSD, isTaxi);

        amountOutSD = _chargeFee(feeParams, _ld2sd(_sendParam.minAmountLD));

        paths[_sendParam.dstEid].decreaseCredit(amountOutSD); // remove the credit from the path
        _postInflow(amountOutSD); // post inflow actions with the amount deducted by the fee
    }

    /// @notice Consult the FeeLib the fee/reward for sending this token
    /// @dev Reverts with SlippageTooHigh when the slippage amount sent would be below the desired minimum or zero.
    /// @return amountOutSD The actual amount that would be sent after applying fees/rewards
    function _chargeFee(FeeParams memory _feeParams, uint64 _minAmountOutSD) internal returns (uint64 amountOutSD) {
        // get the output amount from the fee library
        amountOutSD = IStargateFeeLib(feeLib).applyFee(_feeParams);

        uint64 amountInSD = _feeParams.amountInSD;
        if (amountOutSD < amountInSD) {
            // fee
            treasuryFee += amountInSD - amountOutSD;
        } else if (amountOutSD > amountInSD) {
            // reward
            uint64 reward = amountOutSD - amountInSD;
            (amountOutSD, reward) = _capReward(amountOutSD, reward);
            if (reward > 0) treasuryFee -= reward;
        }

        if (amountOutSD < _minAmountOutSD || amountOutSD == 0) revert Stargate_SlippageTooHigh(); // 0 not allowed
    }

    function _taxi(
        SendParam calldata _sendParam,
        MessagingFee memory _messagingFee,
        uint64 _amountSD,
        address _refundAddress
    ) internal returns (MessagingReceipt memory receipt) {
        if (_messagingFee.lzTokenFee > 0) _payLzToken(_messagingFee.lzTokenFee); // handle lz token fee

        receipt = ITokenMessaging(tokenMessaging).taxi{ value: _messagingFee.nativeFee }(
            TaxiParams({
                sender: msg.sender,
                dstEid: _sendParam.dstEid,
                receiver: _sendParam.to,
                amountSD: _amountSD,
                composeMsg: _sendParam.composeMsg,
                extraOptions: _sendParam.extraOptions
            }),
            _messagingFee,
            _refundAddress
        );
    }

    function _rideBus(
        SendParam calldata _sendParam,
        MessagingFee memory _messagingFee,
        uint64 _amountSD,
        address _refundAddress
    ) internal virtual returns (MessagingReceipt memory receipt, Ticket memory ticket) {
        if (_messagingFee.lzTokenFee > 0) revert Stargate_LzTokenUnavailable();

        (receipt, ticket) = ITokenMessaging(tokenMessaging).rideBus(
            RideBusParams({
                sender: msg.sender,
                dstEid: _sendParam.dstEid,
                receiver: _sendParam.to,
                amountSD: _amountSD,
                nativeDrop: _sendParam.extraOptions.length > 0
            })
        );

        uint256 busFare = receipt.fee.nativeFee;
        uint256 providedFare = _messagingFee.nativeFee;

        // assert sufficient nativeFee was provided to cover the fare
        if (busFare == providedFare) {
            // return; Do nothing in this case
        } else if (providedFare > busFare) {
            uint256 refund;
            unchecked {
                refund = providedFare - busFare;
            }
            Transfer.transferNative(_refundAddress, refund, false); // no gas limit to refund
        } else {
            revert Stargate_InsufficientFare();
        }
    }

    /// @notice Pay the LZ fee in LZ tokens.
    /// @dev Reverts with LzTokenUnavailable if the LZ token OFT has not been set.
    /// @param _lzTokenFee The fee to pay in LZ tokens
    function _payLzToken(uint256 _lzTokenFee) internal {
        address lzTkn = lzToken;
        if (lzTkn == address(0)) revert Stargate_LzTokenUnavailable();
        Transfer.safeTransferTokenFrom(lzTkn, msg.sender, address(endpoint), _lzTokenFee);
    }

    /// @notice Translate an amount in SD to LD
    /// @dev Since SD <= LD by definition, convertRate >= 1, so there is no rounding errors in this function.
    /// @param _amountSD The amount in SD
    /// @return amountLD The same value expressed in LD
    function _sd2ld(uint64 _amountSD) internal view returns (uint256 amountLD) {
        unchecked {
            amountLD = _amountSD * convertRate;
        }
    }

    /// @notice Translate an value in LD to SD
    /// @dev Since SD <= LD by definition, convertRate >= 1, so there might be rounding during the cast.
    /// @param _amountLD The value in LD
    /// @return amountSD The same value expressed in SD
    function _ld2sd(uint256 _amountLD) internal view returns (uint64 amountSD) {
        unchecked {
            amountSD = SafeCast.toUint64(_amountLD / convertRate);
        }
    }

    /// @dev if _cmd is empty, Taxi mode. Otherwise, Bus mode
    function _isTaxiMode(bytes calldata _oftCmd) internal pure returns (bool) {
        return _oftCmd.length == 0;
    }

    // ---------------------------------- Virtual Functions ------------------------------------------

    /// @notice Limits the reward awarded when withdrawing value.
    /// @param _amountOutSD The amount of expected on the destination chain in SD
    /// @param _reward The initial calculated reward by FeeLib
    /// @return newAmountOutSD The actual amount to be delivered on the destination chain
    /// @return newReward The actual reward after applying any caps
    function _capReward(
        uint64 _amountOutSD,
        uint64 _reward
    ) internal view virtual returns (uint64 newAmountOutSD, uint64 newReward);

    /// @notice Hook called when there is ingress of value into the contract.
    /// @param _from The account from which to obtain the value
    /// @param _amountLD The amount of tokens to get from the account in LD
    /// @return amountSD The actual amount of tokens in SD that got into the Stargate
    function _inflow(address _from, uint256 _amountLD) internal virtual returns (uint64 amountSD);

    /// @notice Hook called when there is egress of value out of the contract.
    /// @return success Whether the outflow was successful
    function _outflow(address _to, uint256 _amountLD) internal virtual returns (bool success);

    /// @notice Hook called when there is egress of value out of the contract.
    /// @dev Reverts with OutflowFailed when the outflow hook fails
    function _safeOutflow(address _to, uint256 _amountLD) internal virtual {
        bool success = _outflow(_to, _amountLD);
        if (!success) revert Stargate_OutflowFailed();
    }

    /// @notice Ensure that the value passed through the message equals the native fee
    /// @dev the native fee should be the same as msg value by default
    /// @dev Reverts with InvalidAmount if the native fee does not match the value passed.
    /// @param _fee The MessagingFee object containing the expected fee
    /// @return The messaging fee object
    function _assertMessagingFee(
        MessagingFee memory _fee,
        uint256 /*_amountInLD*/
    ) internal view virtual returns (MessagingFee memory) {
        if (_fee.nativeFee != msg.value) revert Stargate_InvalidAmount();
        return _fee;
    }

    /// @notice Ensure the msg.value is as expected.
    /// @dev Override this contract to provide a specific validation.
    /// @dev This implementation will revert if value is passed, because we do not expect value except for
    /// @dev the native token when adding to the treasury.
    /// @dev Reverts with InvalidAmount if msg.value > 0
    function _assertMsgValue(uint256 /*_amountLD*/) internal view virtual {
        if (msg.value > 0) revert Stargate_InvalidAmount();
    }

    /// @dev Build the FeeParams object for the FeeLib
    /// @param _dstEid The destination endpoint ID
    /// @param _amountInSD The amount to send in SD
    /// @param _isTaxi Whether this send is riding the bus or taxing
    function _buildFeeParams(
        uint32 _dstEid,
        uint64 _amountInSD,
        bool _isTaxi
    ) internal view virtual returns (FeeParams memory);

    /// @notice Hook called after the inflow of value into the contract by sendToken().
    /// Function meant to be overridden
    // solhint-disable-next-line no-empty-blocks
    function _postInflow(uint64 _amountSD) internal virtual {}

    /// @notice Hook called after the outflow of value out of the contract by receiveToken().
    /// Function meant to be overridden
    // solhint-disable-next-line no-empty-blocks
    function _postOutflow(uint64 _amountSD) internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

/// @notice Stores the information related to a batch of credit transfers.
struct TargetCreditBatch {
    uint16 assetId;
    TargetCredit[] credits;
}

/// @notice Stores the information related to a single credit transfer.
struct TargetCredit {
    uint32 srcEid;
    uint64 amount; // the amount of credits to intended to send
    uint64 minAmount; // the minimum amount of credits to keep on local chain after sending
}

/// @title Credit Messaging API
/// @dev This interface defines the API for quoting and sending credits to other chains.
interface ICreditMessaging {
    /// @notice Sends credits to the destination endpoint.
    /// @param _dstEid The destination LayerZero endpoint ID.
    /// @param _creditBatches The credit batch payloads to send to the destination LayerZero endpoint ID.
    function sendCredits(uint32 _dstEid, TargetCreditBatch[] calldata _creditBatches) external payable;

    /// @notice Quotes the fee for sending credits to the destination endpoint.
    /// @param _dstEid The destination LayerZero endpoint ID.
    /// @param _creditBatches The credit batch payloads to send to the destination LayerZero endpoint ID.
    /// @return fee The fee for sending the credits to the destination endpoint.
    function quoteSendCredits(
        uint32 _dstEid,
        TargetCreditBatch[] calldata _creditBatches
    ) external view returns (MessagingFee memory fee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { TargetCredit } from "./ICreditMessaging.sol";

struct Credit {
    uint32 srcEid;
    uint64 amount;
}

/// @dev This is an internal interface, defining functions to handle messages/calls from the credit messaging contract.
interface ICreditMessagingHandler {
    function sendCredits(uint32 _dstEid, TargetCredit[] calldata _credits) external returns (Credit[] memory);

    function receiveCredits(uint32 _srcEid, Credit[] calldata _credits) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// Solidity does not support splitting import across multiple lines
// solhint-disable-next-line max-line-length
import { IOFT, SendParam, MessagingFee, MessagingReceipt, OFTReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

/// @notice Stargate implementation type.
enum StargateType {
    Pool,
    OFT
}

/// @notice Ticket data for bus ride.
struct Ticket {
    uint72 ticketId;
    bytes passengerBytes;
}

/// @title Interface for Stargate.
/// @notice Defines an API for sending tokens to destination chains.
interface IStargate is IOFT {
    /// @dev This function is same as `send` in OFT interface but returns the ticket data if in the bus ride mode,
    /// which allows the caller to ride and drive the bus in the same transaction.
    function sendToken(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt, Ticket memory ticket);

    /// @notice Returns the Stargate implementation type.
    function stargateType() external pure returns (StargateType);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @notice Parameters used to assess fees to send tokens to a destination endpoint.
struct FeeParams {
    address sender;
    uint32 dstEid;
    uint64 amountInSD;
    uint64 deficitSD;
    bool toOFT;
    bool isTaxi;
}

/// @title Interface for assessing fees to send tokens to a destination endpoint.
interface IStargateFeeLib {
    /// @notice Apply a fee for a given request, allowing for state modification.
    /// @dev This is included for future proofing potential implementations
    /// @dev where state is modified in the feeLib based on a FeeParams

    function applyFee(FeeParams calldata _params) external returns (uint64 amountOutSD);
    /// @notice Apply a fee for a given request, without modifying state.
    function applyFeeView(FeeParams calldata _params) external view returns (uint64 amountOutSD);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { MessagingReceipt, MessagingFee, Ticket } from "./IStargate.sol";

/// @notice Payload for sending a taxi message.
/// @dev A taxi message is sent immediately and is not stored on the bus.
struct TaxiParams {
    address sender;
    uint32 dstEid;
    bytes32 receiver;
    uint64 amountSD;
    bytes composeMsg;
    bytes extraOptions;
}

/// @notice Payload for riding the bus.
/// @dev Riding the bus is a two-step process:
/// @dev - The message is sent to the bus,
/// @dev - The bus is driven to the destination.
struct RideBusParams {
    address sender;
    uint32 dstEid;
    bytes32 receiver;
    uint64 amountSD;
    bool nativeDrop;
}

/// @title Token Messaging API.
/// @notice This interface defines the API for sending a taxi message, riding the bus, and driving the bus, along with
/// corresponding quote functions.
interface ITokenMessaging {
    /// @notice Sends a taxi message
    /// @param _params The taxi message payload
    /// @param _messagingFee The messaging fee for sending a taxi message
    /// @param _refundAddress The address to refund excess LayerZero MessagingFees
    /// @return receipt The MessagingReceipt resulting from sending the taxi
    function taxi(
        TaxiParams calldata _params,
        MessagingFee calldata _messagingFee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory receipt);

    /// @notice Quotes the messaging fee for sending a taxi message
    /// @param _params The taxi message payload
    /// @param _payInLzToken Whether to pay the fee in LZ token
    /// @return fee The MessagingFee for sending the taxi message
    function quoteTaxi(TaxiParams calldata _params, bool _payInLzToken) external view returns (MessagingFee memory fee);

    /// @notice Sends a message to ride the bus, queuing the passenger in preparation for the drive.
    /// @notice The planner will later driveBus to the destination endpoint.
    /// @param _params The rideBus message payload
    /// @return receipt The MessagingReceipt resulting from sending the rideBus message
    /// @return ticket The Ticket for riding the bus
    function rideBus(
        RideBusParams calldata _params
    ) external returns (MessagingReceipt memory receipt, Ticket memory ticket);

    /// @notice Quotes the messaging fee for riding the bus
    /// @param _dstEid The destination LayerZero endpoint ID.
    /// @param _nativeDrop Whether to pay for a native drop on the destination.
    /// @return fee The MessagingFee for riding the bus
    function quoteRideBus(uint32 _dstEid, bool _nativeDrop) external view returns (MessagingFee memory fee);

    /// @notice Drives the bus to the destination.
    /// @param _dstEid The destination LayerZero endpoint ID.
    /// @param _passengers The passengers to drive to the destination.
    /// @return receipt The MessagingReceipt resulting from driving the bus
    function driveBus(
        uint32 _dstEid,
        bytes calldata _passengers
    ) external payable returns (MessagingReceipt memory receipt);

    /// @notice Quotes the messaging fee for driving the bus to the destination.
    /// @param _dstEid The destination LayerZero endpoint ID.
    /// @param _passengers The passengers to drive to the destination.
    /// @return fee The MessagingFee for driving the bus
    function quoteDriveBus(uint32 _dstEid, bytes calldata _passengers) external view returns (MessagingFee memory fee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";

/// @dev This is an internal interface, defining the function to handle token message from the token messaging contract.
interface ITokenMessagingHandler {
    function receiveTokenBus(
        Origin calldata _origin,
        bytes32 _guid,
        uint8 _seatNumber,
        address _receiver,
        uint64 _amountSD
    ) external;

    function receiveTokenTaxi(
        Origin calldata _origin,
        bytes32 _guid,
        address _receiver,
        uint64 _amountSD,
        bytes calldata _composeMsg
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

/// @dev The Path struct contains the bus base fare multiplier bps and the credit in the same slot for gas saving.
struct Path {
    uint64 credit; // available credit for the path, in SD
}

using PathLib for Path global;

/**
 * @title A library to operate on Paths.
 * @dev A Path is a route through which value can be sent. It entails the local chain and a destination chain, and has
 *      a given amount of credit associated with it. Every time the value is sent from A to B, the credit on A is
 *      decreased and credit on B is increased. If credit hits 0 then the path can no longer be used.
 */
library PathLib {
    uint64 internal constant UNLIMITED_CREDIT = type(uint64).max;

    // solhint-disable-next-line event-name-camelcase
    event Path_CreditBurned(uint64 amountSD);

    error Path_InsufficientCredit();
    error Path_AlreadyHasCredit();
    error Path_UnlimitedCredit();

    /// @notice Increase credit for a given Path.
    /// @dev Reverts with Path_UnlimitedCredit if the increase would hit the maximum amount of credit (reserved value)
    /// @param _path The Path for which to increase credit
    /// @param _amountSD The amount by which to increase credit
    function increaseCredit(Path storage _path, uint64 _amountSD) internal {
        uint64 credit = _path.credit;
        if (credit == UNLIMITED_CREDIT) return;
        credit += _amountSD;
        if (credit == UNLIMITED_CREDIT) revert Path_UnlimitedCredit();
        _path.credit = credit;
    }

    /// @notice Decrease credit for a given Path.
    /// @dev Reverts with InsufficientCredit if there is not enough credit
    /// @param _path The Path for which to decrease credit
    /// @param _amountSD The amount by which to decrease credit
    function decreaseCredit(Path storage _path, uint64 _amountSD) internal {
        uint64 currentCredit = _path.credit;
        if (currentCredit == UNLIMITED_CREDIT) return;
        if (currentCredit < _amountSD) revert Path_InsufficientCredit();
        unchecked {
            _path.credit = currentCredit - _amountSD;
        }
    }

    /// @notice Decrease credit for a given path, even if only a partial amount is possible.
    /// @param _path The Path for which to decrease credit
    /// @param _amountSD The amount by which try to decrease credit
    /// @param _minKept The minimum amount of credit to keep after the decrease
    /// @return decreased The actual amount of credit decreased
    function tryDecreaseCredit(
        Path storage _path,
        uint64 _amountSD,
        uint64 _minKept
    ) internal returns (uint64 decreased) {
        uint64 currentCredit = _path.credit;
        // not allowed to try to decrease unlimited credit
        if (currentCredit == UNLIMITED_CREDIT) revert Path_UnlimitedCredit();
        if (_minKept < currentCredit) {
            unchecked {
                uint64 maxDecreased = currentCredit - _minKept;
                decreased = _amountSD > maxDecreased ? maxDecreased : _amountSD;
                _path.credit = currentCredit - decreased;
            }
        }
    }

    /// @notice Set a given path as OFT or reset an OFT path to 0 credit.
    /// @dev A Path for which the asset is using an OFT on destination gets unlimited credit because value transfers
    /// @dev do not spend value.
    /// @dev Such a path is expected to not have credit before.
    /// @dev Reverts with AlreadyHasCredit if the Path already had credit assigned to it
    /// @param _path The Path to set
    /// @param _oft Whether to set it as OFT or reset it from OFT
    function setOFTPath(Path storage _path, bool _oft) internal {
        uint64 currentCredit = _path.credit;
        if (_oft) {
            // only allow un-limiting from 0
            if (currentCredit != 0) revert Path_AlreadyHasCredit();
            _path.credit = UNLIMITED_CREDIT;
        } else {
            // only allow resetting from unlimited
            if (currentCredit != UNLIMITED_CREDIT) revert Path_AlreadyHasCredit();
            _path.credit = 0;
        }
    }

    /// @notice Check whether a given Path is set as OFT.
    /// @param _path The path to examine
    /// @return whether the Path is set as OFT
    function isOFTPath(Path storage _path) internal view returns (bool) {
        return _path.credit == UNLIMITED_CREDIT;
    }

    /// @notice Burn credit for a given Path during bridged token migration.
    function burnCredit(Path storage _path, uint64 _amountSD) internal {
        decreaseCredit(_path, _amountSD);
        emit Path_CreditBurned(_amountSD);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev WARNING: Transferring tokens, when the token address is wrong, will fail silently.
contract Transfer is Ownable {
    error Transfer_TransferFailed();
    error Transfer_ApproveFailed();

    // @dev default this to 2300, but it is modifiable
    // @dev this is intended to provide just enough gas to receive native tokens.
    // @dev ie. empty fallbacks or EOA addresses
    uint256 internal transferGasLimit = 2300;

    function getTransferGasLimit() external view returns (uint256) {
        return transferGasLimit;
    }

    function setTransferGasLimit(uint256 _gasLimit) external onlyOwner {
        transferGasLimit = _gasLimit;
    }

    /// @notice Transfer native coin to an account
    /// @dev If gas is unlimited, we pass 63/64 of the gasleft()
    /// @dev This call may revert due to out of gas instead of returning false.
    /// @param _to The account to transfer native coin to
    /// @param _value The amount of native coin to transfer
    /// @param _gasLimited Whether to limit gas available for the 'fall-back'
    /// @return success Whether the transfer was successful
    function transferNative(address _to, uint256 _value, bool _gasLimited) internal returns (bool success) {
        uint256 gasForCall = _gasLimited ? transferGasLimit : gasleft();

        // @dev We dont care about the data returned here, only success or not.
        assembly {
            success := call(gasForCall, _to, _value, 0, 0, 0, 0)
        }
    }

    /// @notice Transfer an ERC20 token from the sender to an account
    /// @param _token The address of the ERC20 token to send
    /// @param _to The receiving account
    /// @param _value The amount of tokens to transfer
    /// @return success Whether the transfer was successful or not
    function transferToken(address _token, address _to, uint256 _value) internal returns (bool success) {
        success = _call(_token, abi.encodeWithSelector(IERC20(_token).transfer.selector, _to, _value));
    }

    /// @notice Transfer an ERC20 token from one account to another
    /// @param _token The address of the ERC20 token to send
    /// @param _from The source account
    /// @param _to The destination account
    /// @param _value The amount of tokens to transfer
    /// @return success Whether the transfer was successful or not
    function transferTokenFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool success) {
        success = _call(_token, abi.encodeWithSelector(IERC20(_token).transferFrom.selector, _from, _to, _value));
    }

    /// @notice Transfer either native coin or ERC20 token from the sender to an account
    /// @param _token The ERC20 address or 0x0 if native is desired
    /// @param _to The destination account
    /// @param _value the amount to transfer
    /// @param _gasLimited Whether to limit the amount of gas when doing a native transfer
    /// @return success Whether the transfer was successful or not
    function transfer(address _token, address _to, uint256 _value, bool _gasLimited) internal returns (bool success) {
        if (_token == address(0)) {
            success = transferNative(_to, _value, _gasLimited);
        } else {
            success = transferToken(_token, _to, _value);
        }
    }

    /// @notice Approve a given amount of token for an account
    /// @param _token The OFT contract to use for approval
    /// @param _spender The account to approve
    /// @param _value The amount of tokens to approve
    /// @return success Whether the approval succeeded
    function approveToken(address _token, address _spender, uint256 _value) internal returns (bool success) {
        success = _call(_token, abi.encodeWithSelector(IERC20(_token).approve.selector, _spender, _value));
    }

    /// @notice Transfer native coin to an account or revert
    /// @dev Reverts with TransferFailed if the transfer failed
    /// @param _to The account to transfer native coin to
    /// @param _value The amount of native coin to transfer
    /// @param _gasLimited Whether to limit the amount of gas to 2300
    function safeTransferNative(address _to, uint256 _value, bool _gasLimited) internal {
        if (!transferNative(_to, _value, _gasLimited)) revert Transfer_TransferFailed();
    }

    /// @notice Transfer an ERC20 token from one account to another or revert
    /// @dev Reverts with TransferFailed when the transfer fails
    /// @param _token The address of the ERC20 token to send
    /// @param _to The destination account
    /// @param _value The amount of tokens to transfer
    function safeTransferToken(address _token, address _to, uint256 _value) internal {
        if (!transferToken(_token, _to, _value)) revert Transfer_TransferFailed();
    }

    /// @notice Transfer an ERC20 token from one account to another
    /// @dev Reverts with TransferFailed when the transfer fails
    /// @param _token The address of the ERC20 token to send
    /// @param _from The source account
    /// @param _to The destination account
    /// @param _value The amount of tokens to transfer
    function safeTransferTokenFrom(address _token, address _from, address _to, uint256 _value) internal {
        if (!transferTokenFrom(_token, _from, _to, _value)) revert Transfer_TransferFailed();
    }

    /// @notice Transfer either native coin or ERC20 token from the sender to an account
    /// @dev Reverts with TransferFailed when the transfer fails
    /// @param _token The ERC20 address or 0x0 if native is desired
    /// @param _to The destination account
    /// @param _value the amount to transfer
    /// @param _gasLimited Whether to limit the amount of gas when doing a native transfer
    function safeTransfer(address _token, address _to, uint256 _value, bool _gasLimited) internal {
        if (!transfer(_token, _to, _value, _gasLimited)) revert Transfer_TransferFailed();
    }

    /// @notice Approve a given amount of token for an account or revert
    /// @dev Reverts with ApproveFailed if the approval failed
    /// @dev Consider using forceApproveToken(...) to ensure the approval is set correctly.
    /// @param _token The OFT contract to use for approval
    /// @param _spender The account to approve
    /// @param _value The amount of tokens to approve
    function safeApproveToken(address _token, address _spender, uint256 _value) internal {
        if (!approveToken(_token, _spender, _value)) revert Transfer_ApproveFailed();
    }

    /// @notice Force approve a given amount of token for an account by first resetting the approval
    /// @dev Some tokens that require the approval to be set to zero before setting it to a non-zero value, e.g. USDT.
    /// @param _token The OFT contract to use for approval
    /// @param _spender The account to approve
    /// @param _value The amount of tokens to approve
    function forceApproveToken(address _token, address _spender, uint256 _value) internal {
        if (!approveToken(_token, _spender, _value)) {
            safeApproveToken(_token, _spender, 0);
            safeApproveToken(_token, _spender, _value);
        }
    }

    function _call(address _token, bytes memory _data) private returns (bool success) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool s, bytes memory returndata) = _token.call(_data);
        success = s ? returndata.length == 0 || abi.decode(returndata, (bool)) : false;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { Transfer } from "../libs/Transfer.sol";
import { StargateBase } from "../StargateBase.sol";

/**
 * @title The treasurer is a role that administers the Stargate treasuries. Treasuries refer to the value that
 *        contracts hold and accrue as they collect fees from transactions and pay rewards.
 * @dev Only the Treasurer admin can add or withdraw from the Stargate treasuries. Only the Treasurer owner can
 *      withdraw from the Treasurer account. The main use-case for this role is to provide an initial treasury to
 *      pay rewards and to claim the unallocated rewards.
 */
contract Treasurer is Transfer {
    /// @dev admin only has the power to withdraw treasury fee to address(this) or recycle the balance into the treasury
    address public admin;
    mapping(address => bool) public stargates;

    error Unauthorized();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    modifier onlyStargate(address _stargate) {
        if (!stargates[_stargate]) revert Unauthorized();
        _;
    }

    /// @notice Create a new Treasurer
    /// @dev Ownership of the Treasurer is transferred to the Owner of the Stargate contract.
    constructor(address _owner, address _admin) {
        _transferOwnership(_owner);
        admin = _admin;
    }

    /// @notice Set the Admin role to an account.
    /// @dev Emits SetAdmin with the new Admin role
    /// @param _admin The address of the new Admin role
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    /// @notice Set the Stargate contract to be managed by the Treasurer.
    function setStargate(address _stargate, bool _value) external onlyOwner {
        stargates[_stargate] = _value;
    }

    /// @notice Transfer tokens from the Treasurer account to another account
    /// @param _token The token to transfer
    /// @param _to The destination account
    /// @param _amount How many tokens to transfer
    function transfer(address _token, address _to, uint256 _amount) external onlyOwner {
        Transfer.safeTransfer(_token, _to, _amount, false); // no gas limit
    }

    /// @notice Transfer treasury fee from a Stargate contract into the Treasurer (this) contract.
    /// @param _amountSD The amount to withdraw, in SD
    function withdrawTreasuryFee(address _stargate, uint64 _amountSD) external onlyAdmin onlyStargate(_stargate) {
        StargateBase(_stargate).withdrawTreasuryFee(address(this), _amountSD);
    }

    /// @notice Return value to the Stargate contract.
    /// @dev can only withdraw from the balance of this contract
    /// @dev if the balance is not enough, just deposit directly to address(this)
    /// @param _amountLD How much value to add to the Stargate contract
    function addTreasuryFee(address _stargate, uint256 _amountLD) external onlyAdmin onlyStargate(_stargate) {
        StargateBase stargate = StargateBase(_stargate);
        address token = stargate.token();
        uint256 value;
        if (token != address(0)) {
            Transfer.forceApproveToken(token, _stargate, _amountLD);
        } else {
            value = _amountLD;
        }
        stargate.addTreasuryFee{ value: value }(_amountLD);
    }

    function recoverToken(
        address _stargate,
        address _token,
        uint256 _amount
    ) external onlyAdmin onlyStargate(_stargate) {
        StargateBase(_stargate).recoverToken(_token, address(this), _amount);
    }

    /// @notice Enable receiving native into the Treasurer
    receive() external payable {}
}