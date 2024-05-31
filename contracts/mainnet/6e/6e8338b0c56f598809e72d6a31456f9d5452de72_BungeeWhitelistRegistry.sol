// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";
import {SwitchBoardPlug} from "../base/SwitchboardPlug.sol";
import {AuthenticationLib} from "../lib/AuthenticationLib.sol";

/**
 * @title BungeeWhitelistRegistry
 * @author Bungee
 * @notice Whitelist & Registry contract that can be reused by Control Rooms
 * @dev As a registry, it tracks Switchboard Ids and their corresponding SwitchboardPlugs
 * @dev As a whitelist, it handles all Bungee signer address whitelist
 */
contract BungeeWhitelistRegistry is Ownable {
    /// @notice Bungee signer that signs against the order thats submitted.
    mapping(address => bool) internal bungeeSigners;

    /// @notice store switch board plugs
    mapping(uint32 switchboardId => SwitchBoardPlug switchBoardPlug) public switchBoardPlugsMap;

    constructor(address _owner) Ownable(_owner) {}

    // --------------------------------------- BUNGEE SIGNER ADMIN FUNCTIONS --------------------------------------- //

    /**
     * @notice Set Signer Addresses.
     * @param _signerAddress address that can sign against a batch.
     */
    function addSignerAddress(address _signerAddress) external onlyOwner {
        bungeeSigners[_signerAddress] = true;
    }

    /**
     * @notice Disable Signer Address.
     * @param _signerAddress address that can sign against a batch.
     */
    function disableSignerAddress(address _signerAddress) external onlyOwner {
        bungeeSigners[_signerAddress] = false;
    }

    // --------------------------------------- BUNGEE SIGNER VIEW FUNCTIONS --------------------------------------- //

    /**
     * @notice Check if an messageHash has been approved by Bungee
     * @param _messageHash messageHash that has been signed by a Bungee signer
     * @param _sig is the signature produced by Bungee signer
     */
    function isBungeeApproved(bytes32 _messageHash, bytes calldata _sig) public view returns (bool) {
        return bungeeSigners[AuthenticationLib.authenticate(_messageHash, _sig)];
    }

    /**
     * @notice Check if an address is a Bungee permitted signer address.
     * @param _signerAddress address that can sign against a batch.
     */
    function isSigner(address _signerAddress) public view returns (bool) {
        return bungeeSigners[_signerAddress];
    }

    // ---------------------------------- SWITCHBOARDPLUG REGISTRY ADMIN FUNCTIONS ---------------------------------- //

    /**
     * @notice Sets a switchboard address against the given id.
     * @param switchBoardId id of the switchboard.
     * @param switchBoardAddress The address of the switchboard through which message will be sent.
     */
    function setSwitchBoardMap(uint32 switchBoardId, address switchBoardAddress) external onlyOwner {
        switchBoardPlugsMap[switchBoardId] = SwitchBoardPlug(switchBoardAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {OnlyOwner, OnlyNominee} from "../base/ControlRoomErrors.sol";

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {ISocket} from "./../interfaces/ISocket.sol";
import {IPlug} from "./../interfaces/IPlug.sol";
import {IControlRoom} from "./../interfaces/IControlRoom.sol";

import {Ownable} from "../utils/Ownable.sol";

/**
 * @notice Switchboard Plug sends the message from the control room to
 *   the corresponding control room through socket DL.
 */
contract SwitchBoardPlug is IPlug, Ownable {
    /// @notice Switchboard id corresponding to this SwitchboardPlug
    uint32 internal switchBoardId;

    /// @notice Socket DL contract
    ISocket public immutable SOCKET;

    /// @notice Thrown when caller is not Socket contract
    error NotSocket();

    /// @notice Thrown when the inbound message tries to call invalid control room
    error InvalidInbound();

    /**
     * @dev  Initialize socket and switchboard id
     * @param _socket address of the socket data layer contract.
     * @param _switchBoardId switchboard id corresponding to this SwitchboardPlug.
     */
    constructor(address _socket, uint32 _switchBoardId, address _owner) Ownable(_owner) {
        SOCKET = ISocket(_socket);
        switchBoardId = _switchBoardId;
    }

    /**
     * @notice Function to send the message through socket data layer to the destination chain.
     * @param siblingChainSlug the destination chain slug to send the message to.
     * @param msgGasLimit gasLimit to use to execute the message on the destination chain.
     * @param payload payload is the encoded message that the inbound will receive.
     */
    function outbound(uint32 siblingChainSlug, uint256 msgGasLimit, bytes memory payload) external payable {
        // TODO - How do we validate that this can only be called by Control rooms.
        // I can spoof an outbound with false data to unlock funds.

        // encode sender dst & recipient src ControlRoom addresses along with payload
        payload = encodeOutboundPayload(siblingChainSlug, payload);

        SOCKET.outbound{value: msg.value}(siblingChainSlug, msgGasLimit, bytes32(0), bytes32(0), payload);
    }

    /**
     * @notice Message received from socket DL to unlock user funds.
     * @notice Message has to be received before an orders fulfillment deadline.
     *         Solver will not unlock user funds after this deadline.
     * @param payload payload to be executed.
     */
    function inbound(uint32 siblingChainSlug_, bytes calldata payload) external payable {
        if (msg.sender != address(SOCKET)) revert NotSocket();

        (address dstControlRoom, address srcControlRoom, bytes memory controlRoomPayload) = decodeInboundPayload(
            payload
        );

        validateSiblingControlRoom(dstControlRoom, srcControlRoom, siblingChainSlug_);

        IControlRoom(srcControlRoom).inboundMsg(switchBoardId, controlRoomPayload);
    }

    /**
     * @notice Connects the plug to the sibling chain via Socket DL
     * @param remoteChainSlug sibling chain slug
     * @param remotePlug address of plug present at sibling chain to send & receive messages
     * @param inboundSwitchboard address of switchboard to use for receiving messages
     * @param outboundSwitchboard address of switchboard to use for sending messages
     */
    function connect(
        uint32 remoteChainSlug,
        address remotePlug,
        address inboundSwitchboard,
        address outboundSwitchboard
    ) external onlyOwner {
        SOCKET.connect(remoteChainSlug, remotePlug, inboundSwitchboard, outboundSwitchboard);
    }

    /**
     * @notice Encodes an outbound payload.
     * @dev encodes sender dst & recipient src ControlRoom addresses along with payload
     * @param siblingChainSlug the destination chain slug to send the message to.
     * @param payload payload is the encoded message that control room is sending
     * @return encoded payload.
     */
    function encodeOutboundPayload(uint32 siblingChainSlug, bytes memory payload) public view returns (bytes memory) {
        return abi.encode(msg.sender, IControlRoom(msg.sender).siblingControlRoom(siblingChainSlug), payload);
    }

    /**
     * @notice Decodes an inbound payload.
     * @dev decodes sender dst & recipient src ControlRoom addresses along with payload
     * @param payload payload is the encoded message that the inbound will receive.
     * @return dstControlRoom, srcControlRoom, controlRoomPayload.
     */
    function decodeInboundPayload(bytes memory payload) public pure returns (address, address, bytes memory) {
        (address dstControlRoom, address srcControlRoom, bytes memory controlRoomPayload) = abi.decode(
            payload,
            (address, address, bytes)
        );

        return (dstControlRoom, srcControlRoom, controlRoomPayload);
    }

    /**
     * @notice Validates the sibling control room address.
     * @dev Queries src control room to check if the sibling control room address is valid.
     * @param dstControlRoom destination control room address.
     * @param srcControlRoom source control room address.
     * @param siblingChainSlug_ the sibling chain slug.
     */
    function validateSiblingControlRoom(
        address dstControlRoom,
        address srcControlRoom,
        uint32 siblingChainSlug_
    ) public view {
        if (IControlRoom(srcControlRoom).siblingControlRoom(siblingChainSlug_) != dstControlRoom)
            revert InvalidInbound();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Library to authenticate the signer address.
library AuthenticationLib {
    /// @notice authenticate a message hash signed by Bungee Protocol
    /// @param messageHash hash of the message
    /// @param signature signature of the message
    /// @return true if signature is valid
    function authenticate(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature);
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error BatchAuthenticationFailed();
error DeadlineNotMet();
error MinOutputNotMet();
error CommandAlreadyFulfilled();
error PromisedAmountNotMet();
error InvalidCommand();
error NonSocketMessageInbound();
error InvalidMsgSender();
error FulfillDeadlineNotMet();
error FulfillmentChainInvalid();
error AddressZero();
error NoExecutionCacheFound();
error ExecutionCacheFailed();
error InsufficientSwapOutputAmount();

error OnlyOwner();
error OnlyNominee();
error UnsupportedMethod();
error InvalidOrder();
error TransferFailed();
error DestinationChainInvalid();

/// RemoteCommandRoom
error ZeroAddressInvalid();
error IncorrectControlRoom();
error InvalidNonce();
error OriginChainIdInvalid();
error CommandAlreadyExecuted();
error RemoteCommandDoesNotExist();

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title ISocket
 * @notice An interface for a cross-chain communication contract
 * @dev This interface provides methods for transmitting and executing messages between chains,
 * connecting a plug to a remote chain and setting up switchboards for the message transmission
 * This interface also emits events for important operations such as message transmission, execution status,
 * and plug connection
 */
interface ISocket {
    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param minMsgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint32 remoteChainSlug_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    event PlugConnected(
        address plug,
        uint32 siblingChainSlug,
        address siblingPlug,
        address inboundSwitchboard,
        address outboundSwitchboard,
        address capacitor,
        address decapacitor
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title IPlug
 * @notice Interface for a plug contract that executes the message received from a source chain.
 */
interface IPlug {
    /**
     * @dev this should be only executable by Socket DL
     * @notice executes the message received from source chain
     * @notice It is expected to have original sender checks in the destination plugs using payload
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(uint32 srcChainSlug_, bytes calldata payload_) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @notice Interface for the control room contract
 * @dev Included functions to send inbound message & fetch sibling control room
 */
interface IControlRoom {
    /**
     * @notice Function to send the message from the socket data layer to the control room.
     * @param switchBoardId id of switchboard to be used
     * @param payload encoded message from the socket data layer
     */
    function inboundMsg(uint32 switchBoardId, bytes calldata payload) external;

    /**
     * @notice Function to fetch the sibling control room address.
     * @param _chainId chainId of the sibling chain.
     */
    function siblingControlRoom(uint256 _chainId) external view returns (address);
}