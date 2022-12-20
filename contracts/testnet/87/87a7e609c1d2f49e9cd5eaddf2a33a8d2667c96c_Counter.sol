/**
 *Submitted for verification at Arbiscan on 2022-12-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param payload_ the data which is needed by plug at inbound call on destination
     */
    function inbound(bytes calldata payload_) external payable;
}

interface ISocket {
    // to handle stack too deep
    struct VerificationParams {
        uint256 remoteChainSlug;
        uint256 packetId;
        bytes deaccumProof;
    }

    // TODO: add confs and blocking/non-blocking
    struct PlugConfig {
        address remotePlug;
        address accum;
        address deaccum;
        address verifier;
        bytes32 integrationType;
    }

    /**
     * @notice emits the message details when a new message arrives at outbound
     * @param localChainSlug local chain id
     * @param localPlug local plug address
     * @param dstChainSlug remote chain id
     * @param dstPlug remote plug address
     * @param msgId message id packed with remoteChainSlug and nonce
     * @param msgGasLimit gas limit needed to execute the inbound at remote
     * @param fees fees provided by msg sender
     * @param payload the data which will be used by inbound at remote
     */
    event MessageTransmitted(
        uint256 localChainSlug,
        address localPlug,
        uint256 dstChainSlug,
        address dstPlug,
        uint256 msgId,
        uint256 msgGasLimit,
        uint256 fees,
        bytes payload
    );

    event ConfigAdded(
        address accum_,
        address deaccum_,
        address verifier_,
        uint256 remoteChainSlug_,
        bytes32 integrationType_
    );

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     */
    event ExecutionSuccess(uint256 msgId);

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     * @param result if message reverts, returns the revert message
     */
    event ExecutionFailed(uint256 msgId, string result);

    /**
     * @notice emits the error message in bytes after inbound call
     * @param msgId msg id which is executed
     * @param result if message reverts, returns the revert message in bytes
     */
    event ExecutionFailedBytes(uint256 msgId, bytes result);

    event PlugConfigSet(
        address remotePlug,
        uint256 remoteChainSlug,
        bytes32 integrationType
    );

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with accumulator
     * @param remoteChainSlug_ the remote chain id
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable;

    /**
     * @notice executes a message
     * @param msgGasLimit gas limit needed to execute the inbound at remote
     * @param msgId message id packed with remoteChainSlug and nonce
     * @param localPlug remote plug address
     * @param payload the data which is needed by plug at inbound call on remote
     * @param verifyParams_ the details needed for message verification
     */
    function execute(
        uint256 msgGasLimit,
        uint256 msgId,
        address localPlug,
        bytes calldata payload,
        ISocket.VerificationParams calldata verifyParams_
    ) external;

    /**
     * @notice sets the config specific to the plug
     * @param remoteChainSlug_ the remote chain id
     * @param remotePlug_ address of plug present at remote chain to call inbound
     * @param integrationType_ the name of accum to be used
     */
    function setPlugConfig(
        uint256 remoteChainSlug_,
        address remotePlug_,
        string memory integrationType_
    ) external;

    function chainSlug() external returns (uint256);
}

abstract contract PlugBase {
    address public owner;
    ISocket socket;

    constructor(address _socket) {
        owner = msg.sender;
        socket = ISocket(_socket);
    }

    //
    // Modifiers
    //
    modifier onlyOwner() {
        require(msg.sender==owner,"no auth");
        _;
    }

    function connect(uint256 _remoteChainSlug, address _remotePlug, string memory _integrationType) external onlyOwner {
        socket.setPlugConfig(_remoteChainSlug, _remotePlug, _integrationType);
    }

    function outbound(uint256 chainSlug, uint256 gasLimit, uint256 fees, bytes memory payload) internal {
        socket.outbound{value: fees}(chainSlug, gasLimit, payload);
    }

    function inbound(bytes calldata payload_) external payable {
        require(msg.sender==address(socket), "no auth");
        _receiveInbound(payload_);
    }

    function getChainSlug() internal returns (uint256) {
        return socket.chainSlug();
    }

    function _receiveInbound(bytes memory payload_) internal virtual;

    function removeOwner() external onlyOwner() {
        owner = address(0);
    }
}

contract Counter is PlugBase {
    uint256 public number;
    uint256 constant public destGasLimit = 1000000;

    constructor(address _socket) PlugBase(_socket) {
        owner = msg.sender;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function setNumber(uint256 newNumber, uint256 toChainSlug) public payable {
        outbound(toChainSlug, destGasLimit, msg.value,abi.encode(newNumber));
    }

    function _receiveInbound(bytes memory payload_) internal virtual override{
        uint256 newNumber = abi.decode(payload_, (uint256));
        setNumber(newNumber);
    }
}