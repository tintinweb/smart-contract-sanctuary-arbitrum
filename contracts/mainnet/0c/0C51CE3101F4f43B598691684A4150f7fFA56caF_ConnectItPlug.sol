// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface ISocket {
    /**
     * @param transmissionFees fees needed for transmission
     * @param switchboardFees fees needed by switchboard
     * @param executionFee fees needed for execution
     */
    struct Fees {
        uint256 transmissionFees;
        uint256 switchboardFees;
        uint256 executionFee;
    }

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    struct MessageDetails {
        bytes32 msgId;
        uint256 executionFee;
        uint256 msgGasLimit;
        bytes payload;
        bytes decapacitorProof;
    }

    /**
     * @notice executes a message
     * @param packetId packet id
     * @param localPlug local plug address
     * @param messageDetails_ the details needed for message verification
     */
    function execute(
        bytes32 packetId,
        address localPlug,
        ISocket.MessageDetails calldata messageDetails_,
        bytes memory signature
    ) external;

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    function getPlugConfig(
        address plugAddress_,
        uint256 siblingChainSlug_
    )
        external
        view
        returns (
            address siblingPlug,
            address inboundSwitchboard__,
            address outboundSwitchboard__,
            address capacitor__,
            address decapacitor__
        );

    /**
     * @notice returns chain slug
     * @return chainSlug current chain slug
     */
    function chainSlug() external view returns (uint256 chainSlug);

    function capacitors__(address, uint256) external view returns (address);

    function decapacitors__(address, uint256) external view returns (address);

    function messageCount() external view returns (uint256);

    function packetIdRoots(bytes32 packetId_) external view returns (bytes32);

    function rootProposedAt(bytes32 packetId_) external view returns (uint256);

    function messageExecuted(bytes32 msgId_) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../interfaces/ISocket.sol";

abstract contract PlugBase {
    ISocket public socket;

    constructor(address socket_) {
        socket = ISocket(socket_);
    }

    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external {
        socket.connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    function inbound(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) external payable {
        require(msg.sender == address(socket), "no auth");
        _receiveInbound(siblingChainSlug_, payload_);
    }

    function _outbound(
        uint256 chainSlug_,
        uint256 gasLimit_,
        uint256 fees_,
        bytes memory payload_
    ) internal {
        socket.outbound{value: fees_}(chainSlug_, gasLimit_, payload_);
    }

    function _receiveInbound(
        uint256 siblingChainSlug_,
        bytes memory payload_
    ) internal virtual;

    function _getChainSlug() internal view returns (uint256) {
        return socket.chainSlug();
    }
}

contract ConnectItPlug is PlugBase {
    bool public msgArrived;
    address public sender;

    ISocket public socket__;
    error AlreadySet();

    constructor(address socket_) PlugBase(socket_) {}

    function setRemote(
        uint256 toChainSlug_,
        uint256 dstGasLimit_
    ) external payable {
        _setRemoteState(toChainSlug_, dstGasLimit_, abi.encode(msg.sender));
    }

    function _setRemoteState(
        uint256 toChainSlug_,
        uint256 dstGasLimit_,
        bytes memory data
    ) internal {
        _outbound(toChainSlug_, dstGasLimit_, msg.value, data);
    }

    function _receiveInbound(
        uint256,
        bytes memory data
    ) internal virtual override {
        sender = abi.decode(data, (address));
        msgArrived = true;
    }
}