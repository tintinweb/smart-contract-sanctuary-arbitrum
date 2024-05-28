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

/**
 * @dev Struct representing enforced option parameters.
 */
struct EnforcedOptionParam {
    uint32 eid; // Endpoint ID
    uint16 msgType; // Message Type
    bytes options; // Additional options
}

/**
 * @title IOAppOptionsType3
 * @dev Interface for the OApp with Type 3 Options, allowing the setting and combining of enforced options.
 */
interface IOAppOptionsType3 {
    // Custom error message for invalid options
    error InvalidOptions(bytes options);

    // Event emitted when enforced options are set
    event EnforcedOptionSet(EnforcedOptionParam[] _enforcedOptions);

    /**
     * @notice Sets enforced options for specific endpoint and message type combinations.
     * @param _enforcedOptions An array of EnforcedOptionParam structures specifying enforced options.
     */
    function setEnforcedOptions(EnforcedOptionParam[] calldata _enforcedOptions) external;

    /**
     * @notice Combines options for a given endpoint and message type.
     * @param _eid The endpoint ID.
     * @param _msgType The OApp message type.
     * @param _extraOptions Additional options passed by the caller.
     * @return options The combination of caller specified options AND enforced options.
     */
    function combineOptions(
        uint32 _eid,
        uint16 _msgType,
        bytes calldata _extraOptions
    ) external view returns (bytes memory options);
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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IOAppOptionsType3, EnforcedOptionParam } from "../interfaces/IOAppOptionsType3.sol";

/**
 * @title OAppOptionsType3
 * @dev Abstract contract implementing the IOAppOptionsType3 interface with type 3 options.
 */
abstract contract OAppOptionsType3 is IOAppOptionsType3, Ownable {
    uint16 internal constant OPTION_TYPE_3 = 3;

    // @dev The "msgType" should be defined in the child contract.
    mapping(uint32 eid => mapping(uint16 msgType => bytes enforcedOption)) public enforcedOptions;

    /**
     * @dev Sets the enforced options for specific endpoint and message type combinations.
     * @param _enforcedOptions An array of EnforcedOptionParam structures specifying enforced options.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Provides a way for the OApp to enforce things like paying for PreCrime, AND/OR minimum dst lzReceive gas amounts etc.
     * @dev These enforced options can vary as the potential options/execution on the remote may differ as per the msgType.
     * eg. Amount of lzReceive() gas necessary to deliver a lzCompose() message adds overhead you dont want to pay
     * if you are only making a standard LayerZero message ie. lzReceive() WITHOUT sendCompose().
     */
    function setEnforcedOptions(EnforcedOptionParam[] calldata _enforcedOptions) public virtual onlyOwner {
        _setEnforcedOptions(_enforcedOptions);
    }

    /**
     * @dev Sets the enforced options for specific endpoint and message type combinations.
     * @param _enforcedOptions An array of EnforcedOptionParam structures specifying enforced options.
     *
     * @dev Provides a way for the OApp to enforce things like paying for PreCrime, AND/OR minimum dst lzReceive gas amounts etc.
     * @dev These enforced options can vary as the potential options/execution on the remote may differ as per the msgType.
     * eg. Amount of lzReceive() gas necessary to deliver a lzCompose() message adds overhead you dont want to pay
     * if you are only making a standard LayerZero message ie. lzReceive() WITHOUT sendCompose().
     */
    function _setEnforcedOptions(EnforcedOptionParam[] memory _enforcedOptions) internal virtual {
        for (uint256 i = 0; i < _enforcedOptions.length; i++) {
            // @dev Enforced options are only available for optionType 3, as type 1 and 2 dont support combining.
            _assertOptionsType3(_enforcedOptions[i].options);
            enforcedOptions[_enforcedOptions[i].eid][_enforcedOptions[i].msgType] = _enforcedOptions[i].options;
        }

        emit EnforcedOptionSet(_enforcedOptions);
    }

    /**
     * @notice Combines options for a given endpoint and message type.
     * @param _eid The endpoint ID.
     * @param _msgType The OAPP message type.
     * @param _extraOptions Additional options passed by the caller.
     * @return options The combination of caller specified options AND enforced options.
     *
     * @dev If there is an enforced lzReceive option:
     * - {gasLimit: 200k, msg.value: 1 ether} AND a caller supplies a lzReceive option: {gasLimit: 100k, msg.value: 0.5 ether}
     * - The resulting options will be {gasLimit: 300k, msg.value: 1.5 ether} when the message is executed on the remote lzReceive() function.
     * @dev This presence of duplicated options is handled off-chain in the verifier/executor.
     */
    function combineOptions(
        uint32 _eid,
        uint16 _msgType,
        bytes calldata _extraOptions
    ) public view virtual returns (bytes memory) {
        bytes memory enforced = enforcedOptions[_eid][_msgType];

        // No enforced options, pass whatever the caller supplied, even if it's empty or legacy type 1/2 options.
        if (enforced.length == 0) return _extraOptions;

        // No caller options, return enforced
        if (_extraOptions.length == 0) return enforced;

        // @dev If caller provided _extraOptions, must be type 3 as its the ONLY type that can be combined.
        if (_extraOptions.length >= 2) {
            _assertOptionsType3(_extraOptions);
            // @dev Remove the first 2 bytes containing the type from the _extraOptions and combine with enforced.
            return bytes.concat(enforced, _extraOptions[2:]);
        }

        // No valid set of options was found.
        revert InvalidOptions(_extraOptions);
    }

    /**
     * @dev Internal function to assert that options are of type 3.
     * @param _options The options to be checked.
     */
    function _assertOptionsType3(bytes memory _options) internal pure virtual {
        uint16 optionsType;
        assembly {
            optionsType := mload(add(_options, 2))
        }
        if (optionsType != OPTION_TYPE_3) revert InvalidOptions(_options);
    }
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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IPreCrime } from "./interfaces/IPreCrime.sol";
import { IOAppPreCrimeSimulator, InboundPacket, Origin } from "./interfaces/IOAppPreCrimeSimulator.sol";

/**
 * @title OAppPreCrimeSimulator
 * @dev Abstract contract serving as the base for preCrime simulation functionality in an OApp.
 */
abstract contract OAppPreCrimeSimulator is IOAppPreCrimeSimulator, Ownable {
    // The address of the preCrime implementation.
    address public preCrime;

    /**
     * @dev Retrieves the address of the OApp contract.
     * @return The address of the OApp contract.
     *
     * @dev The simulator contract is the base contract for the OApp by default.
     * @dev If the simulator is a separate contract, override this function.
     */
    function oApp() external view virtual returns (address) {
        return address(this);
    }

    /**
     * @dev Sets the preCrime contract address.
     * @param _preCrime The address of the preCrime contract.
     */
    function setPreCrime(address _preCrime) public virtual onlyOwner {
        preCrime = _preCrime;
        emit PreCrimeSet(_preCrime);
    }

    /**
     * @dev Interface for pre-crime simulations. Always reverts at the end with the simulation results.
     * @param _packets An array of InboundPacket objects representing received packets to be delivered.
     *
     * @dev WARNING: MUST revert at the end with the simulation results.
     * @dev Gives the preCrime implementation the ability to mock sending packets to the lzReceive function,
     * WITHOUT actually executing them.
     */
    function lzReceiveAndRevert(InboundPacket[] calldata _packets) public payable virtual {
        for (uint256 i = 0; i < _packets.length; i++) {
            InboundPacket calldata packet = _packets[i];

            // Ignore packets that are not from trusted peers.
            if (!isPeer(packet.origin.srcEid, packet.origin.sender)) continue;

            // @dev Because a verifier is calling this function, it doesnt have access to executor params:
            //  - address _executor
            //  - bytes calldata _extraData
            // preCrime will NOT work for OApps that rely on these two parameters inside of their _lzReceive().
            // They are instead stubbed to default values, address(0) and bytes("")
            // @dev Calling this.lzReceiveSimulate removes ability for assembly return 0 callstack exit,
            // which would cause the revert to be ignored.
            this.lzReceiveSimulate{ value: packet.value }(
                packet.origin,
                packet.guid,
                packet.message,
                packet.executor,
                packet.extraData
            );
        }

        // @dev Revert with the simulation results. msg.sender must implement IPreCrime.buildSimulationResult().
        revert SimulationResult(IPreCrime(msg.sender).buildSimulationResult());
    }

    /**
     * @dev Is effectively an internal function because msg.sender must be address(this).
     * Allows resetting the call stack for 'internal' calls.
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _guid The unique identifier of the packet.
     * @param _message The message payload of the packet.
     * @param _executor The executor address for the packet.
     * @param _extraData Additional data for the packet.
     */
    function lzReceiveSimulate(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable virtual {
        // @dev Ensure ONLY can be called 'internally'.
        if (msg.sender != address(this)) revert OnlySelf();
        _lzReceiveSimulate(_origin, _guid, _message, _executor, _extraData);
    }

    /**
     * @dev Internal function to handle the OAppPreCrimeSimulator simulated receive.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The GUID of the LayerZero message.
     * @param _message The LayerZero message.
     * @param _executor The address of the off-chain executor.
     * @param _extraData Arbitrary data passed by the msg executor.
     *
     * @dev Enables the preCrime simulator to mock sending lzReceive() messages,
     * routes the msg down from the OAppPreCrimeSimulator, and back up to the OAppReceiver.
     */
    function _lzReceiveSimulate(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual;

    /**
     * @dev checks if the specified peer is considered 'trusted' by the OApp.
     * @param _eid The endpoint Id to check.
     * @param _peer The peer to check.
     * @return Whether the peer passed is considered 'trusted' by the OApp.
     */
    function isPeer(uint32 _eid, bytes32 _peer) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// @dev Import the Origin so it's exposed to OAppPreCrimeSimulator implementers.
// solhint-disable-next-line no-unused-import
import { InboundPacket, Origin } from "../libs/Packet.sol";

/**
 * @title IOAppPreCrimeSimulator Interface
 * @dev Interface for the preCrime simulation functionality in an OApp.
 */
interface IOAppPreCrimeSimulator {
    // @dev simulation result used in PreCrime implementation
    error SimulationResult(bytes result);
    error OnlySelf();

    /**
     * @dev Emitted when the preCrime contract address is set.
     * @param preCrimeAddress The address of the preCrime contract.
     */
    event PreCrimeSet(address preCrimeAddress);

    /**
     * @dev Retrieves the address of the preCrime contract implementation.
     * @return The address of the preCrime contract.
     */
    function preCrime() external view returns (address);

    /**
     * @dev Retrieves the address of the OApp contract.
     * @return The address of the OApp contract.
     */
    function oApp() external view returns (address);

    /**
     * @dev Sets the preCrime contract address.
     * @param _preCrime The address of the preCrime contract.
     */
    function setPreCrime(address _preCrime) external;

    /**
     * @dev Mocks receiving a packet, then reverts with a series of data to infer the state/result.
     * @param _packets An array of LayerZero InboundPacket objects representing received packets.
     */
    function lzReceiveAndRevert(InboundPacket[] calldata _packets) external payable;

    /**
     * @dev checks if the specified peer is considered 'trusted' by the OApp.
     * @param _eid The endpoint Id to check.
     * @param _peer The peer to check.
     * @return Whether the peer passed is considered 'trusted' by the OApp.
     */
    function isPeer(uint32 _eid, bytes32 _peer) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
struct PreCrimePeer {
    uint32 eid;
    bytes32 preCrime;
    bytes32 oApp;
}

// TODO not done yet
interface IPreCrime {
    error OnlyOffChain();

    // for simulate()
    error PacketOversize(uint256 max, uint256 actual);
    error PacketUnsorted();
    error SimulationFailed(bytes reason);

    // for preCrime()
    error SimulationResultNotFound(uint32 eid);
    error InvalidSimulationResult(uint32 eid, bytes reason);
    error CrimeFound(bytes crime);

    function getConfig(bytes[] calldata _packets, uint256[] calldata _packetMsgValues) external returns (bytes memory);

    function simulate(
        bytes[] calldata _packets,
        uint256[] calldata _packetMsgValues
    ) external payable returns (bytes memory);

    function buildSimulationResult() external view returns (bytes memory);

    function preCrime(
        bytes[] calldata _packets,
        uint256[] calldata _packetMsgValues,
        bytes[] calldata _simulations
    ) external;

    function version() external view returns (uint64 major, uint8 minor);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { PacketV1Codec } from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/PacketV1Codec.sol";

/**
 * @title InboundPacket
 * @dev Structure representing an inbound packet received by the contract.
 */
struct InboundPacket {
    Origin origin; // Origin information of the packet.
    uint32 dstEid; // Destination endpointId of the packet.
    address receiver; // Receiver address for the packet.
    bytes32 guid; // Unique identifier of the packet.
    uint256 value; // msg.value of the packet.
    address executor; // Executor address for the packet.
    bytes message; // Message payload of the packet.
    bytes extraData; // Additional arbitrary data for the packet.
}

/**
 * @title PacketDecoder
 * @dev Library for decoding LayerZero packets.
 */
library PacketDecoder {
    using PacketV1Codec for bytes;

    /**
     * @dev Decode an inbound packet from the given packet data.
     * @param _packet The packet data to decode.
     * @return packet An InboundPacket struct representing the decoded packet.
     */
    function decode(bytes calldata _packet) internal pure returns (InboundPacket memory packet) {
        packet.origin = Origin(_packet.srcEid(), _packet.sender(), _packet.nonce());
        packet.dstEid = _packet.dstEid();
        packet.receiver = _packet.receiverB20();
        packet.guid = _packet.guid();
        packet.message = _packet.message();
    }

    /**
     * @dev Decode multiple inbound packets from the given packet data and associated message values.
     * @param _packets An array of packet data to decode.
     * @param _packetMsgValues An array of associated message values for each packet.
     * @return packets An array of InboundPacket structs representing the decoded packets.
     */
    function decode(
        bytes[] calldata _packets,
        uint256[] memory _packetMsgValues
    ) internal pure returns (InboundPacket[] memory packets) {
        packets = new InboundPacket[](_packets.length);
        for (uint256 i = 0; i < _packets.length; i++) {
            bytes calldata packet = _packets[i];
            packets[i] = PacketDecoder.decode(packet);
            // @dev Allows the verifier to specify the msg.value that gets passed in lzReceive.
            packets[i].value = _packetMsgValues[i];
        }
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

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { SetConfigParam } from "./IMessageLibManager.sol";

enum MessageLibType {
    Send,
    Receive,
    SendAndReceive
}

interface IMessageLib is IERC165 {
    function setConfig(address _oapp, SetConfigParam[] calldata _config) external;

    function getConfig(uint32 _eid, address _oapp, uint32 _configType) external view returns (bytes memory config);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    // message libs of same major version are compatible
    function version() external view returns (uint64 major, uint8 minor, uint8 endpointVersion);

    function messageLibType() external view returns (MessageLibType);
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

pragma solidity >=0.8.0;

import { MessagingFee } from "./ILayerZeroEndpointV2.sol";
import { IMessageLib } from "./IMessageLib.sol";

struct Packet {
    uint64 nonce;
    uint32 srcEid;
    address sender;
    uint32 dstEid;
    bytes32 receiver;
    bytes32 guid;
    bytes message;
}

interface ISendLib is IMessageLib {
    function send(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external returns (MessagingFee memory, bytes memory encodedPacket);

    function quote(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory);

    function setTreasury(address _treasury) external;

    function withdrawFee(address _to, uint256 _amount) external;

    function withdrawLzTokenFee(address _lzToken, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.22;

import { Errors } from "./Errors.sol";

library AddressCast {
    function toBytes32(bytes calldata _addressBytes) internal pure returns (bytes32 result) {
        if (_addressBytes.length > 32) revert Errors.InvalidAddress();
        result = bytes32(_addressBytes);
        unchecked {
            uint256 offset = 32 - _addressBytes.length;
            result = result >> (offset * 8);
        }
    }

    function toBytes32(address _address) internal pure returns (bytes32 result) {
        result = bytes32(uint256(uint160(_address)));
    }

    function toBytes(bytes32 _addressBytes32, uint256 _size) internal pure returns (bytes memory result) {
        if (_size == 0 || _size > 32) revert Errors.InvalidSizeForAddress();
        result = new bytes(_size);
        unchecked {
            uint256 offset = 256 - _size * 8;
            assembly {
                mstore(add(result, 32), shl(offset, _addressBytes32))
            }
        }
    }

    function toAddress(bytes32 _addressBytes32) internal pure returns (address result) {
        result = address(uint160(uint256(_addressBytes32)));
    }

    function toAddress(bytes calldata _addressBytes) internal pure returns (address result) {
        if (_addressBytes.length != 20) revert Errors.InvalidAddress();
        result = address(bytes20(_addressBytes));
    }
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.22;

library Errors {
    error LzTokenUnavailable();
    error OnlyAltToken();
    error InvalidReceiveLibrary();
    error InvalidNonce(uint64 nonce);
    error InvalidArgument();
    error InvalidExpiry();
    error InvalidAmount(uint256 required, uint256 supplied);
    error OnlyRegisteredOrDefaultLib();
    error OnlyRegisteredLib();
    error OnlyNonDefaultLib();
    error Unauthorized();
    error DefaultSendLibUnavailable();
    error DefaultReceiveLibUnavailable();
    error PathNotInitializable();
    error PathNotVerifiable();
    error OnlySendLib();
    error OnlyReceiveLib();
    error UnsupportedEid();
    error UnsupportedInterface();
    error AlreadyRegistered();
    error SameValue();
    error InvalidPayloadHash();
    error PayloadHashNotFound(bytes32 expected, bytes32 actual);
    error ComposeNotFound(bytes32 expected, bytes32 actual);
    error ComposeExists();
    error SendReentrancy();
    error NotImplemented();
    error InvalidAddress();
    error InvalidSizeForAddress();
    error InsufficientFee(
        uint256 requiredNative,
        uint256 suppliedNative,
        uint256 requiredLzToken,
        uint256 suppliedLzToken
    );
    error ZeroLzTokenFee();
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.22;

import { Packet } from "../../interfaces/ISendLib.sol";
import { AddressCast } from "../../libs/AddressCast.sol";

library PacketV1Codec {
    using AddressCast for address;
    using AddressCast for bytes32;

    uint8 internal constant PACKET_VERSION = 1;

    // header (version + nonce + path)
    // version
    uint256 private constant PACKET_VERSION_OFFSET = 0;
    //    nonce
    uint256 private constant NONCE_OFFSET = 1;
    //    path
    uint256 private constant SRC_EID_OFFSET = 9;
    uint256 private constant SENDER_OFFSET = 13;
    uint256 private constant DST_EID_OFFSET = 45;
    uint256 private constant RECEIVER_OFFSET = 49;
    // payload (guid + message)
    uint256 private constant GUID_OFFSET = 81; // keccak256(nonce + path)
    uint256 private constant MESSAGE_OFFSET = 113;

    function encode(Packet memory _packet) internal pure returns (bytes memory encodedPacket) {
        encodedPacket = abi.encodePacked(
            PACKET_VERSION,
            _packet.nonce,
            _packet.srcEid,
            _packet.sender.toBytes32(),
            _packet.dstEid,
            _packet.receiver,
            _packet.guid,
            _packet.message
        );
    }

    function encodePacketHeader(Packet memory _packet) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                PACKET_VERSION,
                _packet.nonce,
                _packet.srcEid,
                _packet.sender.toBytes32(),
                _packet.dstEid,
                _packet.receiver
            );
    }

    function encodePayload(Packet memory _packet) internal pure returns (bytes memory) {
        return abi.encodePacked(_packet.guid, _packet.message);
    }

    function header(bytes calldata _packet) internal pure returns (bytes calldata) {
        return _packet[0:GUID_OFFSET];
    }

    function version(bytes calldata _packet) internal pure returns (uint8) {
        return uint8(bytes1(_packet[PACKET_VERSION_OFFSET:NONCE_OFFSET]));
    }

    function nonce(bytes calldata _packet) internal pure returns (uint64) {
        return uint64(bytes8(_packet[NONCE_OFFSET:SRC_EID_OFFSET]));
    }

    function srcEid(bytes calldata _packet) internal pure returns (uint32) {
        return uint32(bytes4(_packet[SRC_EID_OFFSET:SENDER_OFFSET]));
    }

    function sender(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[SENDER_OFFSET:DST_EID_OFFSET]);
    }

    function senderAddressB20(bytes calldata _packet) internal pure returns (address) {
        return sender(_packet).toAddress();
    }

    function dstEid(bytes calldata _packet) internal pure returns (uint32) {
        return uint32(bytes4(_packet[DST_EID_OFFSET:RECEIVER_OFFSET]));
    }

    function receiver(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[RECEIVER_OFFSET:GUID_OFFSET]);
    }

    function receiverB20(bytes calldata _packet) internal pure returns (address) {
        return receiver(_packet).toAddress();
    }

    function guid(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[GUID_OFFSET:MESSAGE_OFFSET]);
    }

    function message(bytes calldata _packet) internal pure returns (bytes calldata) {
        return bytes(_packet[MESSAGE_OFFSET:]);
    }

    function payload(bytes calldata _packet) internal pure returns (bytes calldata) {
        return bytes(_packet[GUID_OFFSET:]);
    }

    function payloadHash(bytes calldata _packet) internal pure returns (bytes32) {
        return keccak256(payload(_packet));
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

library AddressCast {
    function toBytes32(address _address) internal pure returns (bytes32 result) {
        result = bytes32(uint256(uint160(_address)));
    }

    function toAddress(bytes32 _addressBytes32) internal pure returns (address result) {
        result = address(uint160(uint256(_addressBytes32)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { BusPassenger, BusCodec } from "./BusCodec.sol";

/* Bus Parameters
    There is three relevant bus parameters regarding the number of passengers than can queue up for it 
    and later sit on it to be driven:

    queueCapacity
    maxNumPassengers
    plannerPassengers

    In simple terms, up to queueCapacity passengers can queue up at once, up to maxNumPassengers can be driven per bus
    at once, and plannerPassengers passengers will be driven under steady state conditions. 
    
    When and how to set these parameters is explained next:

    queueCapacity
    Queue capacity is an on-chain parameter set at deployment time (it is part of the constructor). It limits the amount
    of passengers that can queue up for the bus at once. It also sets the size of the circular buffer used to represent
    the queue. The capacity impacts the cost of initialization since each capacity slot should be initialized, so it is
    a number that we want to bound. At the same time, the size of the circular buffer defines the bus behaviour under
    re-orgs: Because a re-org will re-order txs, that changes the hashChain, which will cause the `drive` txs to revert
    as they will contain the wrong hashes. Reverting the drives means that in the now-canonical fork there is no
    available room in the queue for all the passengers that queued up in the abandoned fork. This will cause all those
    txs to revert as well, leading to a bad UX. If the circular buffer is made larger, then the passengers txs can
    still be re-arranged despite all the `drive` txs reverting. This parameter should be set by estimating the inflow
    of txs for each chain and multiplying that by the p99 finality window (confirmation time) or another such indicator
    to minimize the chances that passengers `ride` tx revert under re-orgs. Naturally the queue constrains the
    `maxNumPassengers`.

    maxNumPassengers
    The max number of passengers to drive is an on-chain parameter that limits how many passengers can be driven at
    once. It is set through the `setMaxNumPassengers` function at wire/configure time but can be later
    modified. Its purpose is to ensure that all LZ messages are deliverable. Since LZ has a limit on the destination on
    the message size, we need to ensure on the source that we do not go above that limit.

    plannerPassengers
    The number of passengers that the Planner will actually attempt to drive. This is an off-chain parameter that tries
    to balance cost (by driving as many passengers as possible at once) with speed (by driving as often as possible).
    It is dynamically set on the off-chain side and the only significance on the contract side is that it corresponds
    to the typical value the contract will see on calls to `ride`.

    The way each parameter limits the next one means queueCapacity > maxNumPassengers > plannerPassengers.
*/

// Represents the bus state. This includes bus identifiers, current seats and a proof to verify the current passengers.
struct BusQueue {
    uint8 maxNumPassengers; // set by the owner
    uint80 busFare; // set by the planner
    uint80 busAndNativeDropFare; // set by the planner
    uint16 qLength; // the length of the queue, i.e. how many passengers are queued up
    uint72 nextTicketId; // the last ticketId driven + 1, so the next ticketId to be driven
    mapping(uint16 index => bytes32 hash) hashChain; // hash chain of passengers, range of the index is the bus capacity
}

struct Bus {
    uint72 startTicketId;
    uint8 numPassengers;
    uint8 totalNativeDrops;
    bytes passengersBytes;
}

using BusLib for BusQueue global;

/// @title A library containing functionality for riding and driving buses.
/// @dev A bus allows sending multiple Stargate `Send`s on a single LZ message, making it very
/// @dev cheap. This batching incurs in additional latency, as the messages sent using the bus
/// @dev are not immediately sent, but rather stored in the bus until the bus is `drive`n.
/// @dev The messages are not actually stored on-chain, but a hash representing them is stored.
/// @dev This hash serves as proof that the driver provided the original data when calling
/// @dev `drive`. This saves storage.
library BusLib {
    error Bus_InvalidFare(bool nativeDrop);
    error Bus_InvalidPassenger();
    error Bus_QueueFull();
    error Bus_InvalidStartTicket();
    error Bus_InvalidNumPassengers(uint8 numPassengers);

    event BusRode(uint32 dstEid, uint72 ticketId, uint80 fare, bytes passenger);
    event BusDriven(uint32 dstEid, uint72 startTicketId, uint8 numPassengers, bytes32 guid);

    function setMaxNumPassengers(BusQueue storage _queue, uint8 _maxNumPassengers) internal {
        _queue.maxNumPassengers = _maxNumPassengers;
    }

    function setFares(BusQueue storage _queue, uint80 _busFare, uint80 _busAndNativeDropFare) internal {
        _queue.busFare = _busFare;
        _queue.busAndNativeDropFare = _busAndNativeDropFare;
    }

    function safeGetFare(BusQueue storage _queue, bool _nativeDrop) internal view returns (uint80 fare) {
        fare = _nativeDrop ? _queue.busAndNativeDropFare : _queue.busFare;
        if (fare == 0) revert Bus_InvalidFare(_nativeDrop);
    }

    /// @notice Ride the bus, queueing the message for processing.
    /// @dev Updates the bus structure and emits an event with the relevant data.
    /// @dev Reverts with BusFull if the bus is full.
    /// @dev Emits BusRode with the passenger information.
    function ride(
        BusQueue storage _queue,
        uint16 _queueCapacity,
        uint32 _dstEid,
        BusPassenger memory _passenger
    ) internal returns (uint72 ticketId, bytes memory passengerBytes, uint80 fare) {
        // step 1: generate the ticketId
        unchecked {
            // create a new ticket
            ticketId = _queue.nextTicketId + _queue.qLength++;

            // check if the bus is full
            if (_queue.qLength >= _queueCapacity) revert Bus_QueueFull();
        }

        // step 2: generate the passenger bytes
        passengerBytes = BusCodec.encodePassenger(_passenger);

        // step 3: calculate the fare
        fare = _queue.safeGetFare(_passenger.nativeDrop);

        // step 4: update the hash chain
        bytes32 lastHash;
        unchecked {
            lastHash = ticketId == 0 ? bytes32(0) : _queue.hashChain[uint16((ticketId - 1) % _queueCapacity)];
        }
        _queue.hashChain[uint16(ticketId % _queueCapacity)] = keccak256(abi.encodePacked(lastHash, passengerBytes));

        // step 5: emit the event
        emit BusRode(_dstEid, ticketId, fare, passengerBytes);
    }

    /// @notice Drive the bus, validating the payload
    /// @dev This function validates the payload by re-seating all passengers and also resets the bus state.
    /// @param _queue The queue to get passengers from
    /// @param _queueCapacity An immutable value set on TokenMessaging, always larger than the maxNumPassengers
    /// @param _passengersBytes The concatenated data of all passengers in the bus
    function checkTicketsAndDrive(
        BusQueue storage _queue,
        uint16 _queueCapacity,
        bytes calldata _passengersBytes
    ) internal returns (Bus memory bus) {
        bus = checkTickets(_queue, _queueCapacity, _passengersBytes);
        // This effectively 'drives' the bus
        unchecked {
            _queue.nextTicketId += bus.numPassengers;
            _queue.qLength -= bus.numPassengers;
        }
    }

    /// @notice Validate that the aggregated payload corresponds to the list of bus passengers.
    /// @dev Verification is done by re-seating the passengers and recalculating the hash-chain.
    /// @dev Reverts with InvalidPassenger if the top hashes do not match.
    function checkTickets(
        BusQueue storage _queue,
        uint16 _queueCapacity,
        bytes calldata _passengersBytes
    ) internal view returns (Bus memory bus) {
        // Validate the number of passengers
        uint8 numPassengers = BusCodec.getNumPassengers(_passengersBytes);
        if (numPassengers == 0 || numPassengers > _queue.maxNumPassengers || numPassengers > _queue.qLength) {
            revert Bus_InvalidNumPassengers(numPassengers);
        }

        // Generate the last hash
        uint72 startTicketId = _queue.nextTicketId;
        bytes32 previousHash = startTicketId == 0
            ? bytes32(0)
            : _queue.hashChain[uint16((startTicketId - 1) % _queueCapacity)];
        (uint8 totalNativeDrops, bytes32 lastHash) = BusCodec.parsePassengers(_passengersBytes, previousHash);

        // Validate the last hash
        uint72 lastTicketIdToDrive = startTicketId + numPassengers - 1;
        if (lastHash != _queue.hashChain[uint16(lastTicketIdToDrive % _queueCapacity)]) revert Bus_InvalidPassenger();

        // Set the bus params
        bus.startTicketId = startTicketId;
        bus.numPassengers = numPassengers;
        bus.passengersBytes = _passengersBytes;
        bus.totalNativeDrops = totalNativeDrops;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

struct BusPassenger {
    uint16 assetId;
    bytes32 receiver;
    uint64 amountSD;
    bool nativeDrop;
}

/// @title A library for encoding and decoding Bus messages.
/// @dev Each bus contains one more more passengers.
/// @dev A passenger contains the payload for one transfer.
library BusCodec {
    uint8 internal constant MSG_TYPE_BUS = 2;

    // Bytes offsets for the passenger payload
    uint256 internal constant ASSET_ID_OFFSET = 2;
    uint256 internal constant RECEIVER_OFFSET = 34;
    uint256 internal constant AMOUNT_SD_OFFSET = 42;
    uint256 internal constant NATIVE_DROP_OFFSET = 43;
    uint256 internal constant PASSENGER_BYTES_LENGTH = NATIVE_DROP_OFFSET;

    // Bytes offsets for the header payload
    uint256 internal constant MSG_TYPE_BYTES_OFFSET = 1;
    uint256 internal constant NATIVE_DROP_AMOUNT_TOTAL_OFFSET = 17;
    uint256 internal constant NATIVE_DROP_AMOUNT_OFFSET = 33;
    uint256 internal constant HEADER_BYTES_LENGTH = NATIVE_DROP_AMOUNT_OFFSET;

    error BusCodec_InvalidBusBytesLength();
    error BusCodec_InvalidMessage();
    error BusCodec_InvalidPassenger();
    error BusCodec_InvalidPassengersBytesLength();

    // ---------------------------------- Passenger Functions ------------------------------------------

    function encodePassenger(BusPassenger memory _passenger) internal pure returns (bytes memory passengerBytes) {
        passengerBytes = abi.encodePacked(
            _passenger.assetId,
            _passenger.receiver,
            _passenger.amountSD,
            _passenger.nativeDrop
        );
    }

    function decodePassenger(bytes calldata _passengerBytes) internal pure returns (BusPassenger memory) {
        uint16 assetId = uint16(bytes2(_passengerBytes[:ASSET_ID_OFFSET]));
        bytes32 receiver = bytes32(_passengerBytes[ASSET_ID_OFFSET:RECEIVER_OFFSET]);
        uint64 amountSD = uint64(bytes8(_passengerBytes[RECEIVER_OFFSET:AMOUNT_SD_OFFSET]));
        bool nativeDrop = uint8(bytes1(_passengerBytes[AMOUNT_SD_OFFSET:NATIVE_DROP_OFFSET])) == 1;

        return BusPassenger({ assetId: assetId, receiver: receiver, amountSD: amountSD, nativeDrop: nativeDrop });
    }

    // ---------------------------------- Bus Functions ------------------------------------------

    /// @notice Checks if the message is a bus message.
    function isBus(bytes calldata _message) internal pure returns (bool) {
        if (_message.length < HEADER_BYTES_LENGTH) revert BusCodec_InvalidMessage();
        return uint8(_message[0]) == MSG_TYPE_BUS;
    }

    /// @notice Extracts the number of passengers on the bus.
    function getNumPassengers(bytes calldata _passengersBytes) internal pure returns (uint8) {
        uint256 passengersBytesLength = _passengersBytes.length;
        if (passengersBytesLength % PASSENGER_BYTES_LENGTH != 0) revert BusCodec_InvalidPassengersBytesLength();

        return SafeCast.toUint8((passengersBytesLength) / PASSENGER_BYTES_LENGTH);
    }

    /// @notice Encodes a Bus message.
    /// @param _numNativeDrops The total number of native drops requested by passengers on the bus.
    /// @dev Since each passenger can only request whether or not to drop native gas (and not the native drop amount),
    /// @dev _numNativeDrops <= the number of passengers on the Bus.
    /// @param _nativeDropAmount The amount destination gas included in the delivery.
    /// @param _nativeDropAmount is the same for each participating passenger.
    /// @param _passengersBytes The passengers payload, which contains one or more passengers.
    /// @return busBytes The encoded Bus message.
    function encodeBus(
        uint128 _numNativeDrops, // the number of passengers whom have requested a native drop on the destination
        uint128 _nativeDropAmount, // amount per drop
        bytes memory _passengersBytes
    ) internal pure returns (bytes memory busBytes) {
        busBytes = abi.encodePacked(MSG_TYPE_BUS, _numNativeDrops, _nativeDropAmount, _passengersBytes);
    }

    function decodeBus(
        bytes calldata _busBytes
    ) internal pure returns (uint128 totalNativeDrops, uint128 nativeDropAmount, BusPassenger[] memory busPassengers) {
        // gas savings by loading to memory
        uint256 busBytesLength = _busBytes.length;

        // Step 0: check payload length
        if (busBytesLength < HEADER_BYTES_LENGTH) revert BusCodec_InvalidBusBytesLength();

        // Step 1: decode nativeDrop details
        totalNativeDrops = uint128(bytes16(_busBytes[MSG_TYPE_BYTES_OFFSET:NATIVE_DROP_AMOUNT_TOTAL_OFFSET]));
        nativeDropAmount = uint128(bytes16(_busBytes[NATIVE_DROP_AMOUNT_TOTAL_OFFSET:NATIVE_DROP_AMOUNT_OFFSET]));

        // Step 2: determine the number of passengers in the bus.
        uint256 numPassengers = (busBytesLength - HEADER_BYTES_LENGTH) / PASSENGER_BYTES_LENGTH;

        // Step 3: Initialize the list of passenger details
        busPassengers = new BusPassenger[](numPassengers);

        // Step 4: Set the cursor to the start of the 'busPassengers'
        uint256 cursor = HEADER_BYTES_LENGTH;

        // Step 5: Iterate the 'busPassengers' and decode each passenger
        for (uint8 i = 0; i < numPassengers; i++) {
            busPassengers[i] = decodePassenger(_busBytes[cursor:cursor + PASSENGER_BYTES_LENGTH]);
            cursor += PASSENGER_BYTES_LENGTH;
        }
    }

    function parsePassengers(
        bytes calldata _passengersBytes,
        bytes32 _previousHash
    ) internal pure returns (uint8 totalNativeDrops, bytes32 lastHash) {
        lastHash = _previousHash;
        // iterate passengers
        for (uint256 i = 0; i < _passengersBytes.length; i += PASSENGER_BYTES_LENGTH) {
            // get the current passenger
            bytes calldata passengerBytes = _passengersBytes[i:i + PASSENGER_BYTES_LENGTH];

            // update the lastHash
            lastHash = keccak256(abi.encodePacked(lastHash, passengerBytes));

            // update total native drops
            bool hasNativeDrop = uint8(passengerBytes[NATIVE_DROP_OFFSET - 1]) == 1;
            if (hasNativeDrop) totalNativeDrops++;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { AddressCast } from "./AddressCast.sol";

library TaxiCodec {
    error TaxiCodec_InvalidMessage();

    uint8 internal constant MSG_TYPE_TAXI = 1;

    uint256 internal constant MSG_TYPE_OFFSET = 1;
    uint256 internal constant ASSET_ID_OFFSET = 3;
    uint256 internal constant RECEIVER_OFFSET = 35;
    uint256 internal constant AMOUNT_SD_OFFSET = 43;

    function isTaxi(bytes calldata _message) internal pure returns (bool) {
        if (_message.length < AMOUNT_SD_OFFSET) revert TaxiCodec_InvalidMessage();
        return uint8(_message[0]) == MSG_TYPE_TAXI;
    }

    function encodeTaxi(
        address _sender,
        uint16 _assetId,
        bytes32 _receiver,
        uint64 _amountSD,
        bytes calldata _composeMsg
    ) internal pure returns (bytes memory _taxiBytes) {
        _taxiBytes = abi.encodePacked(
            MSG_TYPE_TAXI,
            _assetId,
            _receiver,
            _amountSD,
            // @dev Remote chains will want to know the composed function caller ie. msg.sender on the src.
            _composeMsg.length > 0 ? abi.encodePacked(AddressCast.toBytes32(_sender), _composeMsg) : _composeMsg
        );
    }

    function decodeTaxi(
        bytes calldata _taxiBytes
    ) internal pure returns (uint16 assetId, bytes32 receiver, uint64 amountSD, bytes memory composeMsg) {
        assetId = uint16(bytes2(_taxiBytes[MSG_TYPE_OFFSET:ASSET_ID_OFFSET]));
        receiver = bytes32(_taxiBytes[ASSET_ID_OFFSET:RECEIVER_OFFSET]);
        amountSD = uint64(bytes8(_taxiBytes[RECEIVER_OFFSET:AMOUNT_SD_OFFSET]));
        composeMsg = _taxiBytes[AMOUNT_SD_OFFSET:]; // This has had the msg.sender encoded into the original composeMsg
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

import { OApp, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { OAppPreCrimeSimulator } from "@layerzerolabs/lz-evm-oapp-v2/contracts/precrime/OAppPreCrimeSimulator.sol";

abstract contract MessagingBase is OApp, OAppPreCrimeSimulator {
    // max asset id, for the off-chain to get the range of asset id and get the list of stargate impls
    uint16 public maxAssetId;
    mapping(address stargateImpl => uint16 assetId) public assetIds;
    mapping(uint16 assetId => address stargateImpl) public stargateImpls;

    address public planner;

    event AssetIdSet(address stargateImpl, uint16 assetId);
    event MaxAssetIdSet(uint16 maxAssetId);
    event PlannerSet(address planner);

    error Messaging_Unauthorized();
    error Messaging_Unavailable();
    error Messaging_InvalidAssetId();

    modifier onlyPlanner() {
        if (msg.sender != planner) revert Messaging_Unauthorized();
        _;
    }

    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) {}

    // ---------------------------------- Only Owner ------------------------------------------

    function setAssetId(address _stargateImpl, uint16 _assetId) external onlyOwner {
        if (_assetId == 0) revert Messaging_InvalidAssetId();
        if (_assetId > maxAssetId) {
            maxAssetId = _assetId;
            emit MaxAssetIdSet(_assetId);
        }

        // clean up the old stargate
        uint16 oldAssetId = assetIds[_stargateImpl];
        address oldStargateImpl = stargateImpls[_assetId];
        if (oldAssetId != 0) delete stargateImpls[oldAssetId];
        if (oldStargateImpl != address(0)) delete assetIds[oldStargateImpl];

        // if stargateImpl is address(0) then delete stargateImpls[_assetId]
        if (_stargateImpl == address(0)) {
            delete stargateImpls[_assetId];
        } else {
            // set the new stargate
            assetIds[_stargateImpl] = _assetId;
            stargateImpls[_assetId] = _stargateImpl;
        }
        emit AssetIdSet(_stargateImpl, _assetId);
    }

    /// @dev Update the max asset id manually if it is not set correctly
    function setMaxAssetId(uint16 _maxAssetId) external onlyOwner {
        maxAssetId = _maxAssetId;
        emit MaxAssetIdSet(_maxAssetId);
    }

    function setPlanner(address _planner) external onlyOwner {
        planner = _planner;
        emit PlannerSet(_planner);
    }

    // ---------------------------------- Internal Functions ------------------------------------------

    function _safeGetStargateImpl(uint16 _assetId) internal view returns (address stargate) {
        stargate = stargateImpls[_assetId];
        if (stargate == address(0)) revert Messaging_Unavailable();
    }

    function _safeGetAssetId(address _stargateImpl) internal view returns (uint16 assetId) {
        assetId = assetIds[_stargateImpl];
        if (assetId == 0) revert Messaging_Unavailable();
    }

    /// @dev Lz token is payed in the stargate contract and do nothing here.
    /// Function meant to be overridden
    // solhint-disable-next-line no-empty-blocks
    function _payLzToken(uint256 /*_lzTokenFee*/) internal pure override {}

    // ---------------------------------- PreCrime Functions ------------------------------------------
    function _lzReceiveSimulate(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal override {
        _lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    function isPeer(uint32 _eid, bytes32 _peer) public view override returns (bool) {
        return _peer == peers[_eid];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { MessagingReceipt, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

import { ITokenMessaging, TaxiParams, RideBusParams, Ticket } from "../interfaces/ITokenMessaging.sol";
import { ITokenMessagingHandler } from "../interfaces/ITokenMessagingHandler.sol";
import { BusQueue, BusLib, Bus, BusPassenger, BusCodec } from "../libs/Bus.sol";
import { Transfer } from "../libs/Transfer.sol";
import { TokenMessagingOptions } from "./TokenMessagingOptions.sol";
import { MessagingBase, Origin } from "./MessagingBase.sol";
import { TaxiCodec } from "../libs/TaxiCodec.sol";
import { AddressCast } from "../libs/AddressCast.sol";

contract TokenMessaging is Transfer, MessagingBase, TokenMessagingOptions, ITokenMessaging {
    /// @dev The maximum number of passengers is queueCapacity - 1 to avoid overwriting the hash root.
    uint16 public immutable queueCapacity;
    uint32 internal immutable localEid;

    mapping(uint32 dstEid => BusQueue queue) public busQueues;
    mapping(uint32 dstEid => uint128 nativeDropAmount) public nativeDropAmounts;

    event FaresSet(uint32 dstEid, uint80 busFare, uint80 busAndNativeDropFare);
    event NativeDropAmountSet(uint32 dstEid, uint128 nativeDropAmount);
    event MaxNumPassengersSet(uint32 dstEid, uint8 maxNumPassengers);
    event NativeDropApplied(address receiver, uint128 amount);
    event NativeDropFailed(address receiver, uint128 amount);
    event BusQueueStorageInitialized(uint32 dstEid, uint16 startSlot, uint16 endSlot);

    error Messaging_InvalidEid();
    error Messaging_InvalidQueueCapacity();
    error Messaging_InvalidMsgValue();
    error Messaging_MaxNumPassengersExceedsQueueCapacity();
    error Messaging_NotEnoughPassengers();

    constructor(address _endpoint, address _owner, uint16 _queueCapacity) MessagingBase(_endpoint, _owner) {
        if (_queueCapacity < 2) revert Messaging_InvalidQueueCapacity(); // queue capacity must be at least 2
        queueCapacity = _queueCapacity;
        localEid = endpoint.eid();
    }

    // ---------------------------------- Only Owner ------------------------------------------

    function setMaxNumPassengers(uint32 _dstEid, uint8 _maxNumPassengers) external onlyOwner {
        if (_maxNumPassengers >= queueCapacity) revert Messaging_MaxNumPassengersExceedsQueueCapacity();
        busQueues[_dstEid].setMaxNumPassengers(_maxNumPassengers);
        emit MaxNumPassengersSet(_dstEid, _maxNumPassengers);
    }

    function setNativeDropAmount(uint32 _dstEid, uint128 _nativeDropAmount) external onlyOwner {
        nativeDropAmounts[_dstEid] = _nativeDropAmount;
        emit NativeDropAmountSet(_dstEid, _nativeDropAmount);
    }

    /// @notice Initialize the queue storage to pay the storage costs upfront
    /// @dev Emits BusQueueStorageInitialized per queue initialized
    /// @param _dstEids The endpoint IDs of the busQueues to initialize
    /// @param _startSlot The first slot to initialize (inclusive)
    /// @param _endSlot The last slot to initialize (inclusive)
    function initializeBusQueueStorage(
        uint32[] calldata _dstEids,
        uint16 _startSlot,
        uint16 _endSlot
    ) external onlyOwner {
        for (uint256 i = 0; i < _dstEids.length; i++) {
            BusQueue storage queue = busQueues[_dstEids[i]];

            if (queue.nextTicketId + queue.qLength > queueCapacity) continue; // whole buffer already used
            uint16 lastTicketId = uint16(queue.nextTicketId + queue.qLength);

            // only initialize unused slots
            uint16 startSlot = _startSlot >= lastTicketId ? _startSlot : lastTicketId;
            // storage slots go from 0 to queueCapacity - 1
            uint16 endSlot = _endSlot >= queueCapacity - 1 ? queueCapacity - 1 : _endSlot;

            // use a non-zero value to initialize storage between [startSlot, endSlot], both inclusive
            for (uint16 slot = startSlot; slot <= endSlot; slot++) {
                queue.hashChain[slot] = bytes32("F");
            }
            emit BusQueueStorageInitialized(_dstEids[i], startSlot, endSlot);
        }
    }

    // ---------------------------------- Planner ------------------------------------------

    function quoteFares(
        uint32 _dstEid,
        uint8 _numPassengers
    ) external view returns (uint256 busFare, uint256 busAndNativeDropFare) {
        if (_numPassengers == 0) revert Messaging_NotEnoughPassengers();
        bytes memory mockPassengersBytes = new bytes(uint256(_numPassengers) * PASSENGER_SIZE);
        bytes memory message = BusCodec.encodeBus(0, 0, mockPassengersBytes);

        // Retrieve the LZ quote based on the busFare and NO native drop
        bytes memory optionsBusFare = _buildOptionsForDriveBus(_dstEid, _numPassengers, 0, 0);
        busFare = _quote(_dstEid, message, optionsBusFare, false).nativeFee / _numPassengers;

        // Retrieve the LZ quote based on the busFare and nativeDrop option
        bytes memory optionsBusAndNativeDropFare = _buildOptionsForDriveBus(
            _dstEid,
            _numPassengers,
            _numPassengers, // Assume every rider in this case is using nativeDrop
            nativeDropAmounts[_dstEid]
        );
        busAndNativeDropFare = _quote(_dstEid, message, optionsBusAndNativeDropFare, false).nativeFee / _numPassengers;
    }

    // The '_busAndNativeDropFare' is the cost for riding the bus AND the native drop
    function setFares(uint32 _dstEid, uint80 _busFare, uint80 _busAndNativeDropFare) external onlyPlanner {
        // If the planner sets the bus fare with the localEid, users can ride the bus to the local endpoint,
        // but the bus will never be driven.
        if (_dstEid == localEid) revert Messaging_InvalidEid();
        busQueues[_dstEid].setFares(_busFare, _busAndNativeDropFare);
        emit FaresSet(_dstEid, _busFare, _busAndNativeDropFare);
    }

    // ---------------------------------- Taxi ------------------------------------------

    function quoteTaxi(
        TaxiParams calldata _params,
        bool _payInLzToken
    ) external view returns (MessagingFee memory fee) {
        (bytes memory message, bytes memory options) = _encodeMessageAndOptionsForTaxi(_params);
        fee = _quote(_params.dstEid, message, options, _payInLzToken);
    }

    function taxi(
        TaxiParams calldata _params,
        MessagingFee calldata _messagingFee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory receipt) {
        (bytes memory message, bytes memory options) = _encodeMessageAndOptionsForTaxi(_params);
        receipt = _lzSend(_params.dstEid, message, options, _messagingFee, _refundAddress);
    }

    function _encodeMessageAndOptionsForTaxi(
        TaxiParams calldata _params
    ) internal view returns (bytes memory message, bytes memory options) {
        uint16 assetId = _safeGetAssetId(msg.sender);
        message = TaxiCodec.encodeTaxi(_params.sender, assetId, _params.receiver, _params.amountSD, _params.composeMsg);
        options = _buildOptionsForTaxi(_params.dstEid, _params.extraOptions);
    }

    // ---------------------------------- RideBus ------------------------------------------

    function quoteRideBus(uint32 _dstEid, bool _airdrop) external view returns (MessagingFee memory fee) {
        fee.nativeFee = busQueues[_dstEid].safeGetFare(_airdrop);
    }

    function rideBus(
        RideBusParams calldata _params
    ) external returns (MessagingReceipt memory receipt, Ticket memory ticket) {
        // step 1: check the msg.sender is the stargate by getting the assetId.  This acts as a form of access control,
        // as the function will revert if the msg.sender is not a stargate.
        uint16 assetId = _safeGetAssetId(msg.sender);

        // step 2: ride the bus and get the encoded passenger bytes etc.
        uint32 dstEid = _params.dstEid;
        (uint72 ticketId, bytes memory passengerBytes, uint256 fare) = busQueues[dstEid].ride(
            queueCapacity,
            dstEid,
            BusPassenger({
                assetId: assetId,
                receiver: _params.receiver,
                amountSD: _params.amountSD,
                nativeDrop: _params.nativeDrop
            })
        );

        // step 3: create the 'Ticket' which acts like a 'receipt' for the passenger
        ticket = Ticket(ticketId, passengerBytes);

        // step 4: refund any excess fare passed
        receipt.fee.nativeFee = fare;
    }

    function getPassengerHash(uint32 _dstEid, uint16 _index) external view returns (bytes32 hash) {
        hash = busQueues[_dstEid].hashChain[_index];
    }

    // ---------------------------------- Bus ------------------------------------------

    function quoteDriveBus(uint32 _dstEid, bytes calldata _passengers) external view returns (MessagingFee memory fee) {
        // Step 1: check the tickets
        Bus memory bus = busQueues[_dstEid].checkTickets(queueCapacity, _passengers);

        // Step 2: generate the lzMsg and lzOptions
        (bytes memory message, bytes memory options) = _encodeMessageAndOptionsForDriveBus(_dstEid, bus);

        // Step 3: quote the fee
        fee = _quote(_dstEid, message, options, false);
    }

    /// @dev Anyone can drive the bus with all or partial of the passengers
    function driveBus(
        uint32 _dstEid,
        bytes calldata _passengers
    ) external payable returns (MessagingReceipt memory receipt) {
        // Step 1: check the tickets and drive
        Bus memory bus = busQueues[_dstEid].checkTicketsAndDrive(queueCapacity, _passengers);

        // Step 2: generate the lzMsg and lzOptions
        (bytes memory message, bytes memory options) = _encodeMessageAndOptionsForDriveBus(_dstEid, bus);

        // Step 3: send the message through LZ
        receipt = _lzSend(_dstEid, message, options, MessagingFee(msg.value, 0), msg.sender);

        // Step 4: emit the bus driven event with the guid
        emit BusLib.BusDriven(_dstEid, bus.startTicketId, bus.numPassengers, receipt.guid);
    }

    function _encodeMessageAndOptionsForDriveBus(
        uint32 _dstEid,
        Bus memory _bus
    ) internal view returns (bytes memory message, bytes memory options) {
        // In the event that nativeDropAmount is zero, the transfer is skipped in _lzReceiveBus(...) on destination.
        uint128 nativeDropAmount = nativeDropAmounts[_dstEid];
        message = BusCodec.encodeBus(_bus.totalNativeDrops, nativeDropAmount, _bus.passengersBytes);
        options = _buildOptionsForDriveBus(_dstEid, _bus.numPassengers, _bus.totalNativeDrops, nativeDropAmount);
    }

    // ---------------------------------- OApp Functions ------------------------------------------

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        if (BusCodec.isBus(_message)) {
            _lzReceiveBus(_origin, _guid, _message);
        } else {
            _lzReceiveTaxi(_origin, _guid, _message);
        }
    }

    function _lzReceiveBus(Origin calldata _origin, bytes32 _guid, bytes calldata _busBytes) internal {
        (uint128 totalNativeDrops, uint128 nativeDropAmount, BusPassenger[] memory passengers) = BusCodec.decodeBus(
            _busBytes
        );
        if (totalNativeDrops > 0 && msg.value != (totalNativeDrops * nativeDropAmount))
            revert Messaging_InvalidMsgValue();

        uint256 nativeDropAmountLeft = msg.value;

        for (uint8 seatNumber = 0; seatNumber < passengers.length; seatNumber++) {
            BusPassenger memory passenger = passengers[seatNumber];
            address stargate = _safeGetStargateImpl(passenger.assetId);
            address receiver = AddressCast.toAddress(passenger.receiver);

            if (nativeDropAmount > 0 && passenger.nativeDrop) {
                // limit the native token transfer.
                // if it fails, the token drop will be considered failed and the receiver will not receive the token
                // if the receiver is a contract with custom receive function, this might OOG
                if (Transfer.transferNative(receiver, nativeDropAmount, true)) {
                    unchecked {
                        nativeDropAmountLeft -= nativeDropAmount;
                    }
                    emit NativeDropApplied(receiver, nativeDropAmount);
                } else {
                    emit NativeDropFailed(receiver, nativeDropAmount);
                }
            }

            ITokenMessagingHandler(stargate).receiveTokenBus(_origin, _guid, seatNumber, receiver, passenger.amountSD);
        }

        // refund the remaining native token to the planner without a gas limit
        if (nativeDropAmountLeft > 0) Transfer.safeTransferNative(planner, nativeDropAmountLeft, false);
    }

    function _lzReceiveTaxi(Origin calldata _origin, bytes32 _guid, bytes calldata _taxiBytes) internal {
        (uint16 assetId, bytes32 receiverBytes32, uint64 amountSD, bytes memory composeMsg) = TaxiCodec.decodeTaxi(
            _taxiBytes
        );
        address receiver = AddressCast.toAddress(receiverBytes32);

        address stargate = _safeGetStargateImpl(assetId);

        ITokenMessagingHandler(stargate).receiveTokenTaxi(_origin, _guid, receiver, amountSD, composeMsg);
    }

    /// @dev The native coin is already checked in the stargate contract and transferred to this contract
    function _payNative(uint256 _nativeFee) internal pure override returns (uint256 nativeFee) {
        nativeFee = _nativeFee;
    }

    function isComposeMsgSender(
        Origin calldata /*_origin*/,
        bytes calldata _message,
        address _sender
    ) public view override returns (bool) {
        // only compose msgs can come from taxi, so if its not a taxi its false
        if (TaxiCodec.isTaxi(_message)) {
            (uint16 assetId, , , ) = TaxiCodec.decodeTaxi(_message);
            if (stargateImpls[assetId] == _sender) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { OAppOptionsType3 } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol";

struct GasLimit {
    uint128 gasLimit;
    uint128 nativeDropGasLimit;
}

contract TokenMessagingOptions is OAppOptionsType3 {
    uint8 public constant MSG_TYPE_TAXI = 1;
    uint8 public constant MSG_TYPE_BUS = 2;

    uint8 internal constant EXECUTOR_WORKER_ID = 1;
    uint8 internal constant OPTION_TYPE_LZRECEIVE = 1;
    uint16 internal constant OPTION_LZRECEIVE_BASE_PARAMS_SIZE = 17; // type(1) + gas(16)
    uint16 internal constant OPTION_LZRECEIVE_PARAMS_SIZE = 33; // type(1) + gas(16) + value(16)

    uint256 internal constant PASSENGER_SIZE = 43;

    mapping(uint32 eid => GasLimit gasLimit) public gasLimits;

    event GasLimitSet(uint32 eid, uint128 gasLimit, uint128 nativeDropGasLimit);

    error MessagingOptions_ZeroGasLimit();

    function setGasLimit(uint32 _eid, uint128 _gasLimit, uint128 _nativeDropGasLimit) external onlyOwner {
        gasLimits[_eid] = GasLimit(_gasLimit, _nativeDropGasLimit);
        emit GasLimitSet(_eid, _gasLimit, _nativeDropGasLimit);
    }

    function _buildOptionsForTaxi(
        uint32 _eid,
        bytes calldata _extraOptions
    ) internal view returns (bytes memory options) {
        options = combineOptions(_eid, MSG_TYPE_TAXI, _extraOptions);
    }

    function _buildOptionsForDriveBus(
        uint32 _eid,
        uint8 _numPassengers,
        uint256 _totalNativeDrops,
        uint128 _nativeDropAmount
    ) internal view returns (bytes memory options) {
        // determine the gasLimit for delivering N passengers
        (uint128 gasLimit, uint128 nativeDropGasLimit) = _safeGetGasLimit(_eid);
        uint128 totalGas = SafeCast.toUint128(uint256(gasLimit) * _numPassengers);

        // calculate the total amount of native to drop
        uint128 totalNativeDropAmount = SafeCast.toUint128(_totalNativeDrops * _nativeDropAmount);

        // append the extraGas that is needed to distribute the _nativeDropAmount amongst the passengers with a drop
        if (totalNativeDropAmount > 0) totalGas += SafeCast.toUint128(nativeDropGasLimit * _totalNativeDrops);

        // generate the lzReceive options
        bytes memory lzReceiveOptions = totalNativeDropAmount > 0
            ? abi.encodePacked(
                EXECUTOR_WORKER_ID,
                OPTION_LZRECEIVE_PARAMS_SIZE,
                OPTION_TYPE_LZRECEIVE,
                totalGas,
                totalNativeDropAmount
            )
            : abi.encodePacked(EXECUTOR_WORKER_ID, OPTION_LZRECEIVE_BASE_PARAMS_SIZE, OPTION_TYPE_LZRECEIVE, totalGas);

        // if enforced options are present, concat them
        bytes memory enforced = enforcedOptions[_eid][MSG_TYPE_BUS];
        if (enforced.length >= 2) {
            options = abi.encodePacked(enforced, lzReceiveOptions);
        } else {
            options = abi.encodePacked(OPTION_TYPE_3, lzReceiveOptions);
        }
    }

    function _safeGetGasLimit(uint32 _eid) private view returns (uint128 gasLimit, uint128 nativeDropGasLimit) {
        GasLimit memory g = gasLimits[_eid];
        gasLimit = g.gasLimit;
        nativeDropGasLimit = g.nativeDropGasLimit;
        // dont require setting nativeDropGasLimit
        if (gasLimit == 0) revert MessagingOptions_ZeroGasLimit();
    }
}