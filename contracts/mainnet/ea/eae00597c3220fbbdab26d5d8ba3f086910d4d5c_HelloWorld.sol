/**
 *Submitted for verification at Arbiscan.io on 2023-09-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title ISocket
 * @dev Interface that lets smart contracts interact with Socket
 */
interface ISocket {
    function outbound(
        uint32 remoteChainSlug_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    function getMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view returns (uint256 totalFees);
}

/**
 * @title Hello World
 * @dev Sends "Hello World" message from one chain to another
 */
contract HelloWorld {
    string public message = "Hello World";
    address owner;

    /**
     * @dev Hardcoded values for Arbitrum
     */
    uint256 destGasLimit = 100000; // Gas cost of sending "Hello World" on Polygon
    uint32 public remoteChainSlug = 137; // Polygon chain ID
    address public socket = 0x37cc674582049b579571E2fFd890a4d99355f6Ba; // Socket Address on Arbitrum
    address public inboundSwitchboard =
        0xFff4A34925301d231ddF42B871c3b199c1E80584; // FAST Switchboard on Arbitrum -> Polygon
    address public outboundSwitchboard =
        0xFff4A34925301d231ddF42B871c3b199c1E80584; // FAST Switchboard on Arbitrum- > PPolygon

    event MessageSent(uint32 destChainSlug, string message);

    event MessageReceived(uint32 srcChainSlug, string message);

    modifier isOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier isSocket() {
        require(msg.sender == socket, "Not Socket");
        _;
    }

    error InsufficientFees();

    constructor() {
        owner = msg.sender;
    }

    /************************************************************************
        Config Functions 
    ************************************************************************/

    /**
     * @dev Configures plug to send/receive message
     */
    function connectPlug(address siblingPlug_) external isOwner {
        ISocket(socket).connect(
            remoteChainSlug,
            siblingPlug_,
            inboundSwitchboard,
            outboundSwitchboard
        );
    }

    /**
     * @dev Sets destination chain gas limit
     */
    function setDestGasLimit(uint256 _destGasLimit) external isOwner {
        destGasLimit = _destGasLimit;
    }

    function setRemoteChainSlug(uint32 _remoteChainSlug) external isOwner {
        remoteChainSlug = _remoteChainSlug;
    }

    function setSocketAddress(address _socket) external isOwner {
        socket = _socket;
    }

    function setSwitchboards(
        address _inboundSwitchboard,
        address _outboundSwitchboard
    ) external isOwner {
        inboundSwitchboard = _inboundSwitchboard;
        outboundSwitchboard = _outboundSwitchboard;
    }

    /************************************************************************
        Send Messages
    ************************************************************************/

    /**
     * @dev Sends message to remote chain HelloWorld plug
     */
    function sendMessage() external payable {
        bytes memory payload = abi.encode(message);

        uint256 totalFees = _getMinimumFees(destGasLimit, payload.length);

        if (msg.value < totalFees) revert InsufficientFees();

        ISocket(socket).outbound{value: msg.value}(
            remoteChainSlug,
            destGasLimit,
            bytes32(0),
            bytes32(0),
            payload
        );

        emit MessageSent(remoteChainSlug, message);
    }

    function _getMinimumFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_
    ) internal view returns (uint256) {
        return
            ISocket(socket).getMinFees(
                minMsgGasLimit_,
                payloadSize_,
                bytes32(0),
                bytes32(0),
                remoteChainSlug,
                address(this)
            );
    }

    /************************************************************************
        Receive Messages
    ************************************************************************/

    /**
     * @dev Sets new message on destination chain and emits event
     */
    function _receiveMessage(
        uint32 _srcChainSlug,
        string memory _message
    ) internal {
        message = _message;
        emit MessageReceived(_srcChainSlug, _message);
    }

    /**
     * @dev Called by Socket when sending destination payload
     */
    function inbound(
        uint32 srcChainSlug_,
        bytes calldata payload_
    ) external isSocket {
        string memory _message = abi.decode(payload_, (string));
        _receiveMessage(srcChainSlug_, _message);
    }
}