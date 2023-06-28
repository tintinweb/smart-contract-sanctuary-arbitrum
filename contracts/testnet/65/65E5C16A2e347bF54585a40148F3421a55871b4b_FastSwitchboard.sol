// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./interfaces/ICapacitorFactory.sol";
import "./capacitors/SingleCapacitor.sol";
import "./capacitors/HashChainCapacitor.sol";
import "./decapacitors/SingleDecapacitor.sol";
import "./decapacitors/HashChainDecapacitor.sol";

import "./libraries/RescueFundsLib.sol";
import "./utils/AccessControl.sol";
import {RESCUE_ROLE} from "./utils/AccessRoles.sol";

/**
 * @title CapacitorFactory
 * @notice Factory contract for creating capacitor and decapacitor pairs of different types.
 * @dev This contract is modular and can be updated in Socket with more capacitor types.
 * @dev The capacitorType_ parameter determines the type of capacitor and decapacitor to deploy.
 */
contract CapacitorFactory is ICapacitorFactory, AccessControl {
    uint256 private constant SINGLE_CAPACITOR = 1;
    uint256 private constant HASH_CHAIN_CAPACITOR = 2;

    /**
     * @notice initializes and grants RESCUE_ROLE to owner.
     * @param owner_ The address of the owner of the contract.
     */
    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @notice Creates a new capacitor and decapacitor pair based on the given type.
     * @dev It sets the capacitor factory owner as capacitor and decapacitor's owner.
     * @dev maxPacketLength is not being used with single capacitor system, will be useful later with batching
     * @dev siblingChainSlug sibling chain slug can be used for chain specific capacitors
     * @param capacitorType_ The type of capacitor to be created. Can be SINGLE_CAPACITOR or HASH_CHAIN_CAPACITOR.
     */
    function deploy(
        uint256 capacitorType_,
        uint32 /** siblingChainSlug */,
        uint256 maxPacketLength_
    ) external override returns (ICapacitor, IDecapacitor) {
        // fetch the capacitor factory owner
        address owner = this.owner();

        if (capacitorType_ == SINGLE_CAPACITOR) {
            return (
                // msg.sender is socket address
                new SingleCapacitor(msg.sender, owner),
                new SingleDecapacitor(owner)
            );
        }
        if (capacitorType_ == HASH_CHAIN_CAPACITOR) {
            return (
                // msg.sender is socket address
                new HashChainCapacitor(msg.sender, owner, maxPacketLength_),
                new HashChainDecapacitor(owner)
            );
        }
        revert InvalidCapacitorType();
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/ICapacitor.sol";
import "../utils/AccessControl.sol";
import "../libraries/RescueFundsLib.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

/**
 * @title BaseCapacitor
 * @dev Abstract base contract for the Capacitors. Implements shared functionality and provides
 * access control.
 */
abstract contract BaseCapacitor is ICapacitor, AccessControl {
    /// an incrementing count for each new packet created
    uint64 internal _nextPacketCount;

    /// tracks the last packet sealed
    uint64 internal _nextSealCount;

    /// address of socket
    address public immutable socket;

    /// maps the packet count with the root hash generated while adding message
    mapping(uint64 => bytes32) internal _roots;

    // Error triggered when not called by socket
    error OnlySocket();

    /**
     * @dev Throws if called by any account other than the socket.
     */
    modifier onlySocket() {
        if (msg.sender != socket) revert OnlySocket();
        _;
    }

    /**
     * @dev Initializes the contract with the specified socket address.
     * @param socket_ The address of the socket contract.
     * @param owner_ The address of the owner of the capacitor contract.
     */
    constructor(address socket_, address owner_) AccessControl(owner_) {
        socket = socket_;
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @dev Returns the count of the latest packet.
     * @return The count of the latest packet.
     */
    function getLatestPacketCount() external view returns (uint256) {
        return _nextPacketCount == 0 ? 0 : _nextPacketCount - 1;
    }

    /**
     * @dev Rescues funds from the contract.
     * @param token_ The address of the token to rescue.
     * @param userAddress_ The address of the user to rescue tokens for.
     * @param amount_ The amount of tokens to rescue.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./BaseCapacitor.sol";

/**
 * @title HashChainCapacitor
 * @dev A contract that implements ICapacitor and stores packed messages in a hash chain.
 * The hash chain is made of packets, each packet contains a capped number of messages.
 * Each new message added to the chain is hashed with the previous root to create a new root.
 * When a packet is full, a new packet is created and the root of the last packet is sealed.
 */
contract HashChainCapacitor is BaseCapacitor {
    uint256 private constant MAX_LEN = 10;
    uint256 public maxPacketLength;

    /// an incrementing count for each new message added
    uint64 public nextMessageCount = 1;
    /// points to last message included in packet
    uint64 public messagePacked;
    // message count => root
    mapping(uint64 => bytes32) public messageRoots;

    // Error triggered when batch size is more than max length
    error InvalidBatchSize();
    // Error triggered when no message found or total message count is less than expected length
    error InsufficientMessageLength();
    // Error triggered when packet length is more than max packet length supported
    error InvalidPacketLength();

    // Event triggered when max packet length is updated
    event MaxPacketLengthSet(uint256 maxPacketLength);

    /**
     * @notice emitted when a new message is added to a packet
     * @param packedMessage the message packed with payload, fees and config
     * @param messageCount an incremental id updates when a new message is added
     * @param packetCount an incremental id assigned to each new packet
     * @param newRootHash the packed message hash (to be replaced with the root hash of the merkle tree)
     */
    event MessageAdded(
        bytes32 packedMessage,
        uint64 messageCount,
        uint64 packetCount,
        bytes32 newRootHash
    );

    /**
     * @dev Initializes the contract with the specified socket address.
     * @param socket_ The address of the socket contract.
     * @param owner_ The address of the owner of the capacitor contract.
     * @param maxPacketLength_ The max Packet Length of the capacitor contract.
     */
    constructor(
        address socket_,
        address owner_,
        uint256 maxPacketLength_
    ) BaseCapacitor(socket_, owner_) {
        _grantRole(RESCUE_ROLE, owner_);

        if (maxPacketLength > MAX_LEN) revert InvalidPacketLength();
        maxPacketLength = maxPacketLength_;
    }

    /**
     * @notice Update packet length of the hash chain capacitor.
     * @notice Only owner can call this function
     * @dev The function will update the packet length of the hash chain capacitor, and also create any packets
     * if the new packet length is less than the current packet length.
     * @param maxPacketLength_ The new nax packet length of the hash chain.
     */
    function updateMaxPacketLength(
        uint256 maxPacketLength_
    ) external onlyOwner {
        if (maxPacketLength > MAX_LEN) revert InvalidPacketLength();
        if (maxPacketLength_ < maxPacketLength) {
            uint64 lastPackedMsgIndex = messagePacked;
            uint64 packetCount = _nextPacketCount;
            uint64 packets = (nextMessageCount - lastPackedMsgIndex) %
                uint64(maxPacketLength_);

            _nextPacketCount += packets;

            for (uint64 index = 0; index < packets; ) {
                uint64 packetEndAt = lastPackedMsgIndex +
                    uint64(maxPacketLength_);

                _roots[packetCount + index] = messageRoots[packetEndAt];
                lastPackedMsgIndex = packetEndAt;
                unchecked {
                    ++index;
                }
            }
            messagePacked = lastPackedMsgIndex;
        }

        maxPacketLength = maxPacketLength_;
        emit MaxPacketLengthSet(maxPacketLength_);
    }

    /**
     * @inheritdoc ICapacitor
     */
    function getMaxPacketLength() external view override returns (uint256) {
        return maxPacketLength;
    }

    /**
     * @notice Adds a packed message to the hash chain.
     * @notice Only socket can call this function
     * @dev The packed message is added to the current packet and hashed with the previous root to create a new root.
     * If the packet is full, a new packet is created and the root of the last packet is finalized to be sealed.
     * @param packedMessage_ The packed message to be added to the hash chain.
     */
    function addPackedMessage(
        bytes32 packedMessage_
    ) external override onlySocket {
        uint64 messageCount = nextMessageCount++;
        uint64 packetCount = _nextPacketCount;

        // hash the packed message with last root and create a new root
        bytes32 root = keccak256(
            abi.encode(messageRoots[messageCount - 1], packedMessage_)
        );
        // update the root for each new message added
        messageRoots[messageCount] = root;

        // create a packet if max length is reached and update packet count
        if (messageCount - messagePacked == maxPacketLength)
            _createPacket(packetCount, messageCount, root);

        emit MessageAdded(packedMessage_, messageCount, packetCount, root);
    }

    /**
     * @dev Seals the next pending packet and returns its root hash and packet count.
     * @param batchSize we use seal packet count to make sure there is no scope of censorship and all the packets get sealed.
     * @return root The root hash and packet count of the sealed packet.
     */
    function sealPacket(
        uint256 batchSize
    ) external override onlySocket returns (bytes32 root, uint64 packetCount) {
        uint256 messageCount = nextMessageCount;

        // revert if batch size exceeds max length
        if (batchSize > maxPacketLength) revert InvalidBatchSize();

        packetCount = _nextSealCount++;
        if (_roots[packetCount] == bytes32(0)) {
            // last message count included in this packet
            uint64 lastMessageCount = messagePacked + uint64(batchSize);

            // if no message found or total message count is less than expected length
            if (messageCount <= lastMessageCount)
                revert InsufficientMessageLength();

            _createPacket(
                packetCount,
                lastMessageCount,
                messageRoots[lastMessageCount]
            );
        }

        root = _roots[packetCount];
    }

    /**
     * @dev Returns the root hash and packet count of the next pending packet to be sealed.
     * @dev includes all the messages added till now if packet is not full yet
     * @return root The root hash and packet count of the next pending packet.
     */
    function getNextPacketToBeSealed()
        external
        view
        override
        returns (bytes32 root, uint64 count)
    {
        count = _nextSealCount;
        root = _getLatestRoot(count, 0);
    }

    /**
     * @dev Returns the root hash of the packet with the specified count.
     * @param count_ The count of the packet.
     * @return root The root hash of the packet.
     */
    function getRootByCount(
        uint64 count_
    ) external view override returns (bytes32) {
        return _getLatestRoot(count_, 0);
    }

    /**
     * @dev Returns the root hash and packet count of the next pending packet to be sealed with batch size.
     * @dev includes all the messages till `batchSize_` height from last msg packed
     * @param batchSize_ length of packet
     * @return root The root hash and packet count of the next pending packet.
     */
    function getNextPacketToBeSealed(
        uint256 batchSize_
    ) external view returns (bytes32 root, uint64 count) {
        count = _nextSealCount;
        root = _getLatestRoot(count, uint64(batchSize_));
    }

    function _getLatestRoot(
        uint64 count_,
        uint64 batchSize_
    ) internal view returns (bytes32 root) {
        if (_roots[count_] == bytes32(0)) {
            // as addPackedMessage auto update _roots as max length is reached, hence length is not verified here
            uint64 lastMessageCount = batchSize_ == 0
                ? nextMessageCount - 1
                : messagePacked + batchSize_;

            if (nextMessageCount <= lastMessageCount) return bytes32(0);
            root = messageRoots[lastMessageCount];
        } else root = _roots[count_];
    }

    function _createPacket(
        uint64 packetCount,
        uint64 messageCount,
        bytes32 root
    ) internal {
        // stores the root on given packet count and updated messages packed
        _roots[packetCount] = root;
        messagePacked = messageCount;

        // increments total packet count. we don't expect _nextPacketCount to reach the max value of uint256
        unchecked {
            _nextPacketCount++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./BaseCapacitor.sol";

/**
 * @title SingleCapacitor
 * @notice A capacitor that adds a single message to each packet.
 * @dev This contract inherits from the `BaseCapacitor` contract, which provides the
 * basic storage and common function implementations.
 */
contract SingleCapacitor is BaseCapacitor {
    uint256 public constant maxPacketLength = 1;
    // Error triggered when no new packet/message is there to be sealed
    error NoPendingPacket();

    /**
     * @notice emitted when a new message is added to a packet
     * @param packedMessage the message packed with payload, fees and config
     * @param packetCount an incremental id assigned to each new packet
     * @param newRootHash the packed message hash (to be replaced with the root hash of the merkle tree)
     */
    event MessageAdded(
        bytes32 packedMessage,
        uint64 packetCount,
        bytes32 newRootHash
    );

    /**
     * @dev Initializes the contract with the specified socket address.
     * @param socket_ The address of the socket contract.
     * @param owner_ The address of the owner of the capacitor contract.
     */

    constructor(
        address socket_,
        address owner_
    ) BaseCapacitor(socket_, owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @inheritdoc ICapacitor
     */
    function getMaxPacketLength() external pure override returns (uint256) {
        return maxPacketLength;
    }

    /**
     * @inheritdoc ICapacitor
     */
    function addPackedMessage(
        bytes32 packedMessage_
    ) external override onlySocket {
        uint64 packetCount = _nextPacketCount;
        _roots[packetCount] = packedMessage_;
        ++_nextPacketCount;

        // as it is a single capacitor, here root and packed message are same
        emit MessageAdded(packedMessage_, packetCount, packedMessage_);
    }

    /**
     * @inheritdoc ICapacitor
     */
    function sealPacket(
        uint256
    ) external override onlySocket returns (bytes32, uint64) {
        uint64 packetCount = _nextSealCount++;
        if (_roots[packetCount] == bytes32(0)) revert NoPendingPacket();

        bytes32 root = _roots[packetCount];
        return (root, packetCount);
    }

    /**
     * @inheritdoc ICapacitor
     */
    function getNextPacketToBeSealed()
        external
        view
        override
        returns (bytes32, uint64)
    {
        uint64 toSeal = _nextSealCount;
        return (_roots[toSeal], toSeal);
    }

    /**
     * @dev Returns the root hash of the packet with the specified count.
     * @param count_ The count of the packet.
     * @return The root hash of the packet.
     */
    function getRootByCount(
        uint64 count_
    ) external view override returns (bytes32) {
        return _roots[count_];
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IDecapacitor.sol";
import "../libraries/RescueFundsLib.sol";
import "../utils/AccessControl.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

/**
 * @title HashChainDecapacitor
 * @notice  This is an experimental contract and have known bugs
 * @notice A contract that verifies whether a message is part of a hash chain or not.
 * @dev This contract implements the `IDecapacitor` interface.
 */
contract HashChainDecapacitor is IDecapacitor, AccessControl {
    /**
     * @notice Initializes the HashChainDecapacitor contract with the owner's address.
     * @param owner_ The address of the contract owner.
     */
    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @notice Verifies whether a message is included in the given hash chain.
     * @param root_ The root of the hash chain.
     * @param packedMessage_ The packed message whose inclusion in the hash chain needs to be verified.
     * @param proof_ The proof for the inclusion of the packed message in the hash chain.
     * @return True if the packed message is included in the hash chain and the provided root is the calculated root; otherwise, false.
     */
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata proof_
    ) external pure override returns (bool) {
        bytes32[] memory chain = abi.decode(proof_, (bytes32[]));
        uint256 len = chain.length;
        bytes32 generatedRoot;
        bool isIncluded;
        for (uint256 i = 0; i < len; ) {
            generatedRoot = keccak256(abi.encode(generatedRoot, chain[i]));
            if (chain[i] == packedMessage_) isIncluded = true;
            unchecked {
                ++i;
            }
        }

        return root_ == generatedRoot && isIncluded;
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IDecapacitor.sol";
import "../libraries/RescueFundsLib.sol";
import "../utils/AccessControl.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

/**
 * @title SingleDecapacitor
 * @notice A decapacitor that verifies messages by checking if the packed message is equal to the root.
 * @dev This contract inherits from the `IDecapacitor` interface, which
 * defines the functions for verifying message inclusion.
 */
contract SingleDecapacitor is IDecapacitor, AccessControl {
    /**
     * @notice Initializes the SingleDecapacitor contract with an owner address.
     * @param owner_ The address of the contract owner
     */
    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @notice Returns true if the packed message is equal to the root, indicating that it is part of the packet.
     * @param root_ The packet root
     * @param packedMessage_ The packed message to be verified
     * @return A boolean indicating whether the message is included in the packet or not.
     */
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata
    ) external pure override returns (bool) {
        return root_ == packedMessage_;
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IPlug.sol";
import "../interfaces/ISocket.sol";
import "../libraries/RescueFundsLib.sol";

contract Counter is IPlug {
    // immutables
    address public immutable socket;

    address public owner;

    // application state
    uint256 public counter;

    // application ops
    bytes32 public constant OP_ADD = keccak256("OP_ADD");
    bytes32 public constant OP_SUB = keccak256("OP_SUB");

    error OnlyOwner();

    constructor(address socket_) {
        socket = socket_;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by owner");
        _;
    }

    function localAddOperation(uint256 amount_) external {
        _addOperation(amount_);
    }

    function localSubOperation(uint256 amount_) external {
        _subOperation(amount_);
    }

    function remoteAddOperation(
        uint32 chainSlug_,
        uint256 amount_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_
    ) external payable {
        bytes memory payload = abi.encode(OP_ADD, amount_, msg.sender);

        _outbound(
            chainSlug_,
            minMsgGasLimit_,
            executionParams_,
            transmissionParams_,
            payload
        );
    }

    function remoteSubOperation(
        uint32 chainSlug_,
        uint256 amount_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_
    ) external payable {
        bytes memory payload = abi.encode(OP_SUB, amount_, msg.sender);
        _outbound(
            chainSlug_,
            minMsgGasLimit_,
            executionParams_,
            transmissionParams_,
            payload
        );
    }

    function inbound(
        uint32,
        bytes calldata payload_
    ) external payable override {
        require(msg.sender == socket, "Counter: Invalid Socket");
        (bytes32 operationType, uint256 amount, ) = abi.decode(
            payload_,
            (bytes32, uint256, address)
        );

        if (operationType == OP_ADD) {
            _addOperation(amount);
        } else if (operationType == OP_SUB) {
            _subOperation(amount);
        } else {
            revert("CounterMock: Invalid Operation");
        }
    }

    function _outbound(
        uint32 targetChain_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes memory payload_
    ) private {
        ISocket(socket).outbound{value: msg.value}(
            targetChain_,
            minMsgGasLimit_,
            executionParams_,
            transmissionParams_,
            payload_
        );
    }

    //
    // base ops
    //
    function _addOperation(uint256 amount_) private {
        counter += amount_;
    }

    function _subOperation(uint256 amount_) private {
        require(counter > amount_, "CounterMock: Subtraction Overflow");
        counter -= amount_;
    }

    // settings
    function setSocketConfig(
        uint32 remoteChainSlug_,
        address remotePlug_,
        address switchboard_
    ) external onlyOwner {
        ISocket(socket).connect(
            remoteChainSlug_,
            remotePlug_,
            switchboard_,
            switchboard_
        );
    }

    function setupComplete() external {
        owner = address(0);
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IPlug.sol";
import "../interfaces/ISocket.sol";
import "../utils/Ownable.sol";

contract Messenger is IPlug, Ownable(msg.sender) {
    // immutables
    ISocket public immutable _socket__;
    uint256 public immutable _localChainSlug;

    bytes32 public _message;
    uint256 public _minMsgGasLimit;

    bytes32 public constant _PING = keccak256("PING");
    bytes32 public constant _PONG = keccak256("PONG");

    error NoSocketFee();

    constructor(address socket_, uint256 chainSlug_, uint256 minMsgGasLimit_) {
        _socket__ = ISocket(socket_);
        _localChainSlug = chainSlug_;

        _minMsgGasLimit = minMsgGasLimit_;
    }

    receive() external payable {}

    function updateMsgGasLimit(uint256 minMsgGasLimit_) external onlyOwner {
        _minMsgGasLimit = minMsgGasLimit_;
    }

    function removeGas(address payable receiver_) external onlyOwner {
        receiver_.transfer(address(this).balance);
    }

    function sendLocalMessage(bytes32 message_) external {
        _updateMessage(message_);
    }

    function sendRemoteMessage(
        uint32 remoteChainSlug_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes32 message_
    ) external payable {
        bytes memory payload = abi.encode(_localChainSlug, message_);
        _outbound(
            remoteChainSlug_,
            executionParams_,
            transmissionParams_,
            payload
        );
    }

    function inbound(
        uint32,
        bytes calldata payload_
    ) external payable override {
        require(msg.sender == address(_socket__), "Counter: Invalid Socket");
        (uint32 remoteChainSlug, bytes32 msgDecoded) = abi.decode(
            payload_,
            (uint32, bytes32)
        );

        _updateMessage(msgDecoded);

        bytes memory newPayload = abi.encode(
            _localChainSlug,
            msgDecoded == _PING ? _PONG : _PING
        );
        _outbound(remoteChainSlug, bytes32(0), bytes32(0), newPayload);
    }

    // settings
    function setSocketConfig(
        uint32 remoteChainSlug_,
        address remotePlug_,
        address switchboard_
    ) external onlyOwner {
        _socket__.connect(
            remoteChainSlug_,
            remotePlug_,
            switchboard_,
            switchboard_
        );
    }

    function message() external view returns (bytes32) {
        return _message;
    }

    function _updateMessage(bytes32 message_) private {
        _message = message_;
    }

    function _outbound(
        uint32 targetChain_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes memory payload_
    ) private {
        uint256 fee = _socket__.getMinFees(
            _minMsgGasLimit,
            uint256(payload_.length),
            executionParams_,
            transmissionParams_,
            targetChain_,
            address(this)
        );
        if (!(address(this).balance >= fee)) revert NoSocketFee();
        _socket__.outbound{value: fee}(
            targetChain_,
            _minMsgGasLimit,
            executionParams_,
            transmissionParams_,
            payload_
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./interfaces/ISwitchboard.sol";
import "./interfaces/ISocket.sol";
import "./interfaces/ISignatureVerifier.sol";
import "./libraries/RescueFundsLib.sol";
import "./utils/AccessControlExtended.sol";
import {WITHDRAW_ROLE, RESCUE_ROLE, EXECUTOR_ROLE, FEES_UPDATER_ROLE} from "./utils/AccessRoles.sol";
import {FEES_UPDATE_SIG_IDENTIFIER, RELATIVE_NATIVE_TOKEN_PRICE_UPDATE_SIG_IDENTIFIER, MSG_VALUE_MAX_THRESHOLD_SIG_IDENTIFIER, MSG_VALUE_MIN_THRESHOLD_SIG_IDENTIFIER} from "./utils/SigIdentifiers.sol";

/**
 * @title ExecutionManager
 * @dev Implementation of the IExecutionManager interface, providing functions for executing cross-chain transactions and
 * managing execution and other fees. This contract also implements the AccessControl interface, allowing for role-based
 * access control.
 */
contract ExecutionManager is IExecutionManager, AccessControlExtended {
    ISignatureVerifier public immutable signatureVerifier__;
    ISocket public immutable socket__;
    uint32 public immutable chainSlug;

    /**
     * @notice Emitted when the executionFees is updated
     * @param siblingChainSlug The destination chain slug for which the executionFees is updated
     * @param executionFees The new executionFees
     */
    event ExecutionFeesSet(uint256 siblingChainSlug, uint128 executionFees);

    /**
     * @notice Emitted when the relativeNativeTokenPrice is updated
     * @param siblingChainSlug The destination chain slug for which the relativeNativeTokenPrice is updated
     * @param relativeNativeTokenPrice The new relativeNativeTokenPrice
     */
    event RelativeNativeTokenPriceSet(
        uint256 siblingChainSlug,
        uint256 relativeNativeTokenPrice
    );

    /**
     * @notice Emitted when the msgValueMaxThresholdSet is updated
     * @param siblingChainSlug The destination chain slug for which the msgValueMaxThresholdSet is updated
     * @param msgValueMaxThresholdSet The new msgValueMaxThresholdSet
     */
    event MsgValueMaxThresholdSet(
        uint256 siblingChainSlug,
        uint256 msgValueMaxThresholdSet
    );

    /**
     * @notice Emitted when the msgValueMinThresholdSet is updated
     * @param siblingChainSlug The destination chain slug for which the msgValueMinThresholdSet is updated
     * @param msgValueMinThresholdSet The new msgValueMinThresholdSet
     */
    event MsgValueMinThresholdSet(
        uint256 siblingChainSlug,
        uint256 msgValueMinThresholdSet
    );

    /**
     * @notice Emitted when the execution fees is withdrawn
     * @param account The address to which fees is transferred
     * @param siblingChainSlug The destination chain slug for which the fees is withdrawn
     * @param amount The amount withdrawn
     */
    event ExecutionFeesWithdrawn(
        address account,
        uint32 siblingChainSlug,
        uint256 amount
    );

    /**
     * @notice Emitted when the transmission fees is withdrawn
     * @param transmitManager The address of transmit manager to which fees is transferred
     * @param siblingChainSlug The destination chain slug for which the fees is withdrawn
     * @param amount The amount withdrawn
     */
    event TransmissionFeesWithdrawn(
        address transmitManager,
        uint32 siblingChainSlug,
        uint256 amount
    );

    /**
     * @notice Emitted when the switchboard fees is withdrawn
     * @param switchboard The address of switchboard for which fees is claimed
     * @param siblingChainSlug The destination chain slug for which the fees is withdrawn
     * @param amount The amount withdrawn
     */
    event SwitchboardFeesWithdrawn(
        address switchboard,
        uint32 siblingChainSlug,
        uint256 amount
    );

    /**
     * @notice packs the total execution and transmission fees received for a sibling slug
     */
    struct TotalExecutionAndTransmissionFees {
        uint128 totalExecutionFees;
        uint128 totalTransmissionFees;
    }

    // maps total fee collected with chain slug
    mapping(uint32 => TotalExecutionAndTransmissionFees)
        public totalExecutionAndTransmissionFees;

    // switchboard => chain slug => switchboard fees collected
    mapping(address => mapping(uint32 => uint128)) public totalSwitchboardFees;

    // transmitter => nextNonce
    mapping(address => uint256) public nextNonce;

    // remoteChainSlug => executionFees
    mapping(uint32 => uint128) public executionFees;

    // transmit manager => chain slug => switchboard fees collected
    mapping(address => mapping(uint32 => uint128)) public transmissionMinFees;

    // destSlug => relativeNativePrice (stores (destnativeTokenPriceUSD*(1e18)/srcNativeTokenPriceUSD))
    mapping(uint32 => uint256) public relativeNativeTokenPrice;

    // chain slug => min msg value threshold
    mapping(uint32 => uint256) public msgValueMinThreshold;
    // chain slug => max msg value threshold
    mapping(uint32 => uint256) public msgValueMaxThreshold;

    // triggered when nonce is invalid
    error InvalidNonce();
    // triggered when msg value less than min threshold
    error MsgValueTooLow();
    // triggered when msg value more than max threshold
    error MsgValueTooHigh();
    // triggered when payload is larger than expected limit
    error PayloadTooLarge();
    // triggered when msg value is not enough
    error InsufficientMsgValue();
    // triggered when fees is not enough
    error InsufficientFees();
    // triggered when msg value exceeds uint128 max value
    error InvalidMsgValue();
    // triggered when fees exceeds uint128 max value
    error FeesTooHigh();

    /**
     * @dev Constructor for ExecutionManager contract
     * @param owner_ address of the contract owner
     * @param chainSlug_ chain slug, unique identifier of chain deployed on
     * @param signatureVerifier_ the signature verifier contract
     * @param socket_ the socket contract
     */
    constructor(
        address owner_,
        uint32 chainSlug_,
        ISocket socket_,
        ISignatureVerifier signatureVerifier_
    ) AccessControlExtended(owner_) {
        chainSlug = chainSlug_;
        signatureVerifier__ = signatureVerifier_;
        socket__ = ISocket(socket_);
    }

    /**
     * @notice Checks whether the provided signer address is an executor for the given packed message and signature
     * @param packedMessage Packed message to be executed
     * @param sig Signature of the message
     * @return executor Address of the executor
     * @return isValidExecutor Boolean value indicating whether the executor is valid or not
     */
    function isExecutor(
        bytes32 packedMessage,
        bytes memory sig
    )
        external
        view
        virtual
        override
        returns (address executor, bool isValidExecutor)
    {
        executor = signatureVerifier__.recoverSigner(packedMessage, sig);
        isValidExecutor = _hasRole(EXECUTOR_ROLE, executor);
    }

    /**
     * @notice updates the total fee used by an executor to execute a message
     * @dev this function should be called by socket only
     * @inheritdoc IExecutionManager
     */
    function updateExecutionFees(
        address,
        uint128,
        bytes32
    ) external view override {
        require(msg.sender == address(socket__));
    }

    /// @inheritdoc IExecutionManager
    function payAndCheckFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32,
        uint32 siblingChainSlug_,
        uint128 switchboardFees_,
        uint128 verificationFees_,
        address transmitManager_,
        address switchboard_,
        uint256 maxPacketLength_
    )
        external
        payable
        override
        returns (uint128 executionFee, uint128 transmissionFees)
    {
        if (msg.value >= type(uint128).max) revert InvalidMsgValue();
        uint128 msgValue = uint128(msg.value);
        transmissionFees =
            transmissionMinFees[transmitManager_][siblingChainSlug_] /
            uint128(maxPacketLength_);

        uint128 minMsgExecutionFees = _getMinFees(
            minMsgGasLimit_,
            payloadSize_,
            executionParams_,
            siblingChainSlug_
        );

        uint128 minExecutionFees = minMsgExecutionFees + verificationFees_;
        if (msgValue < transmissionFees + switchboardFees_ + minExecutionFees)
            revert InsufficientFees();

        // any extra fee is considered as executionFee
        executionFee = msgValue - transmissionFees - switchboardFees_;

        TotalExecutionAndTransmissionFees
            memory currentTotalFees = totalExecutionAndTransmissionFees[
                siblingChainSlug_
            ];

        totalExecutionAndTransmissionFees[
            siblingChainSlug_
        ] = TotalExecutionAndTransmissionFees({
            totalExecutionFees: currentTotalFees.totalExecutionFees +
                executionFee,
            totalTransmissionFees: currentTotalFees.totalTransmissionFees +
                transmissionFees
        });

        totalSwitchboardFees[switchboard_][
            siblingChainSlug_
        ] += switchboardFees_;
    }

    /**
     * @notice function for getting the minimum fees required for executing msg on destination
     * @dev this function is called at source to calculate the execution cost.
     * @param gasLimit_ the gas limit needed for execution at destination
     * @param payloadSize_ byte length of payload. Currently only used to check max length, later on will be used for fees calculation.
     * @param executionParams_ Can be used for providing extra information. Currently used for msgValue
     * @param siblingChainSlug_ Sibling chain identifier
     * @return minExecutionFee : Minimum fees required for executing the transaction
     */
    function getMinFees(
        uint256 gasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        uint32 siblingChainSlug_
    ) external view override returns (uint128 minExecutionFee) {
        minExecutionFee = _getMinFees(
            gasLimit_,
            payloadSize_,
            executionParams_,
            siblingChainSlug_
        );
    }

    /// @inheritdoc IExecutionManager
    function getExecutionTransmissionMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32,
        uint32 siblingChainSlug_,
        address transmitManager_
    )
        external
        view
        override
        returns (uint128 minExecutionFee, uint128 transmissionFees)
    {
        minExecutionFee = _getMinFees(
            minMsgGasLimit_,
            payloadSize_,
            executionParams_,
            siblingChainSlug_
        );
        transmissionFees = transmissionMinFees[transmitManager_][
            siblingChainSlug_
        ];
    }

    // decodes and validates the msg value if it is under given transfer limits and calculates
    // the total fees needed for execution for given payload size and msg value.
    function _getMinFees(
        uint256,
        uint256 payloadSize_,
        bytes32 executionParams_,
        uint32 siblingChainSlug_
    ) internal view returns (uint128) {
        if (payloadSize_ > 3000) revert PayloadTooLarge();

        uint256 params = uint256(executionParams_);
        uint8 paramType = uint8(params >> 248);

        if (paramType == 0) return executionFees[siblingChainSlug_];
        uint256 msgValue = uint256(uint248(params));

        if (msgValue < msgValueMinThreshold[siblingChainSlug_])
            revert MsgValueTooLow();
        if (msgValue > msgValueMaxThreshold[siblingChainSlug_])
            revert MsgValueTooHigh();

        uint256 msgValueRequiredOnSrcChain = (relativeNativeTokenPrice[
            siblingChainSlug_
        ] * msgValue) / 1e18;

        uint256 totalNativeValue = msgValueRequiredOnSrcChain +
            executionFees[siblingChainSlug_];

        if (totalNativeValue >= type(uint128).max) revert FeesTooHigh();
        return uint128(totalNativeValue);
    }

    /**
     * @notice called by socket while executing message to validate if the msg value provided is enough
     * @param executionParams_ a bytes32 string where first byte gives param type (if value is 0 or not)
     * and remaining bytes give the msg value needed
     * @param msgValue_ msg.value to be sent with inbound
     */
    function verifyParams(
        bytes32 executionParams_,
        uint256 msgValue_
    ) external pure override {
        uint256 params = uint256(executionParams_);
        uint8 paramType = uint8(params >> 248);

        if (paramType == 0) return;
        uint256 expectedMsgValue = uint256(uint248(params));
        if (msgValue_ < expectedMsgValue) revert InsufficientMsgValue();
    }

    /**
     * @notice sets the minimum execution fees required for executing at `siblingChainSlug_`
     * @dev this function currently sets the price for a constant msg gas limit and payload size but this will be
     * updated in future to consider gas limit and payload size to return fees which will be close to
     * actual execution cost.
     * @param nonce_ incremental id to prevent signature replay
     * @param siblingChainSlug_ sibling chain identifier
     * @param executionFees_ total fees where price in destination native token is converted to source native tokens
     * @param signature_ signature of fee updater
     */
    function setExecutionFees(
        uint256 nonce_,
        uint32 siblingChainSlug_,
        uint128 executionFees_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(
                    FEES_UPDATE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    siblingChainSlug_,
                    nonce_,
                    executionFees_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, siblingChainSlug_, feesUpdater);

        // nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[feesUpdater]++) revert InvalidNonce();
        }

        executionFees[siblingChainSlug_] = executionFees_;
        emit ExecutionFeesSet(siblingChainSlug_, executionFees_);
    }

    /**
     * @notice sets the relative token price for `siblingChainSlug_`
     * @dev this function is expected to be called frequently to match the original prices
     * @param nonce_ incremental id to prevent signature replay
     * @param siblingChainSlug_ sibling chain identifier
     * @param relativeNativeTokenPrice_ relative price
     * @param signature_ signature of fee updater
     */
    function setRelativeNativeTokenPrice(
        uint256 nonce_,
        uint32 siblingChainSlug_,
        uint256 relativeNativeTokenPrice_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(
                    RELATIVE_NATIVE_TOKEN_PRICE_UPDATE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    siblingChainSlug_,
                    nonce_,
                    relativeNativeTokenPrice_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, siblingChainSlug_, feesUpdater);

        // nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[feesUpdater]++) revert InvalidNonce();
        }

        relativeNativeTokenPrice[siblingChainSlug_] = relativeNativeTokenPrice_;
        emit RelativeNativeTokenPriceSet(
            siblingChainSlug_,
            relativeNativeTokenPrice_
        );
    }

    /**
     * @notice sets the min limit for msg value for `siblingChainSlug_`
     * @param nonce_ incremental id to prevent signature replay
     * @param siblingChainSlug_ sibling chain identifier
     * @param msgValueMinThreshold_ min msg value
     * @param signature_ signature of fee updater
     */
    function setMsgValueMinThreshold(
        uint256 nonce_,
        uint32 siblingChainSlug_,
        uint256 msgValueMinThreshold_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(
                    MSG_VALUE_MIN_THRESHOLD_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    siblingChainSlug_,
                    nonce_,
                    msgValueMinThreshold_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, siblingChainSlug_, feesUpdater);

        // nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[feesUpdater]++) revert InvalidNonce();
        }
        msgValueMinThreshold[siblingChainSlug_] = msgValueMinThreshold_;
        emit MsgValueMinThresholdSet(siblingChainSlug_, msgValueMinThreshold_);
    }

    /**
     * @notice sets the max limit for msg value for `siblingChainSlug_`
     * @param nonce_ incremental id to prevent signature replay
     * @param siblingChainSlug_ sibling chain identifier
     * @param msgValueMaxThreshold_ max msg value
     * @param signature_ signature of fee updater
     */
    function setMsgValueMaxThreshold(
        uint256 nonce_,
        uint32 siblingChainSlug_,
        uint256 msgValueMaxThreshold_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(
                    MSG_VALUE_MAX_THRESHOLD_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    siblingChainSlug_,
                    nonce_,
                    msgValueMaxThreshold_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, siblingChainSlug_, feesUpdater);

        // nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[feesUpdater]++) revert InvalidNonce();
        }
        msgValueMaxThreshold[siblingChainSlug_] = msgValueMaxThreshold_;
        emit MsgValueMaxThresholdSet(siblingChainSlug_, msgValueMaxThreshold_);
    }

    /**
     * @notice updates the transmission fee needed for transmission
     * @dev this function stores value against msg.sender hence expected to be called by transmit manager
     * @inheritdoc IExecutionManager
     */
    function setTransmissionMinFees(
        uint32 remoteChainSlug_,
        uint128 fees_
    ) external override {
        transmissionMinFees[msg.sender][remoteChainSlug_] = fees_;
    }

    /**
     * @notice withdraws fees from contract
     * @param siblingChainSlug_ withdraw fees corresponding to this slug
     * @param amount_ withdraw amount
     * @param account_ withdraw fees to
     */
    function withdrawExecutionFees(
        uint32 siblingChainSlug_,
        uint128 amount_,
        address account_
    ) external onlyRole(WITHDRAW_ROLE) {
        if (account_ == address(0)) revert ZeroAddress();
        if (
            totalExecutionAndTransmissionFees[siblingChainSlug_]
                .totalExecutionFees < amount_
        ) revert InsufficientFees();

        totalExecutionAndTransmissionFees[siblingChainSlug_]
            .totalExecutionFees -= amount_;

        SafeTransferLib.safeTransferETH(account_, amount_);
        emit ExecutionFeesWithdrawn(account_, siblingChainSlug_, amount_);
    }

    /**
     * @notice withdraws switchboard fees from contract
     * @param siblingChainSlug_ withdraw fees corresponding to this slug
     * @param amount_ withdraw amount
     */
    function withdrawSwitchboardFees(
        uint32 siblingChainSlug_,
        address switchboard_,
        uint128 amount_
    ) external override {
        if (totalSwitchboardFees[switchboard_][siblingChainSlug_] < amount_)
            revert InsufficientFees();

        totalSwitchboardFees[switchboard_][siblingChainSlug_] -= amount_;
        ISwitchboard(switchboard_).receiveFees{value: amount_}(
            siblingChainSlug_
        );

        emit SwitchboardFeesWithdrawn(switchboard_, siblingChainSlug_, amount_);
    }

    /**
     * @dev this function gets the transmitManager address from the socket contract. If it is ever upgraded in socket,
     * @dev remove the fees from executionManager first, and then upgrade address at socket.
     * @notice withdraws transmission fees from contract
     * @param siblingChainSlug_ withdraw fees corresponding to this slug
     * @param amount_ withdraw amount
     */
    function withdrawTransmissionFees(
        uint32 siblingChainSlug_,
        uint128 amount_
    ) external override {
        if (
            totalExecutionAndTransmissionFees[siblingChainSlug_]
                .totalTransmissionFees < amount_
        ) revert InsufficientFees();

        totalExecutionAndTransmissionFees[siblingChainSlug_]
            .totalTransmissionFees -= amount_;

        ITransmitManager tm = socket__.transmitManager__();
        tm.receiveFees{value: amount_}(siblingChainSlug_);
        emit TransmissionFeesWithdrawn(address(tm), siblingChainSlug_, amount_);
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title ICapacitor
 * @dev Interface for a Capacitor contract that stores and manages messages in packets
 */
interface ICapacitor {
    /**
     * @notice adds the packed message to a packet
     * @dev this should be only executable by socket
     * @param packedMessage the message packed with payload, fees and config
     */
    function addPackedMessage(bytes32 packedMessage) external;

    /**
     * @notice returns the latest packet details which needs to be sealed
     * @return root root hash of the latest packet which is not yet sealed
     * @return packetCount latest packet id which is not yet sealed
     */
    function getNextPacketToBeSealed()
        external
        view
        returns (bytes32 root, uint64 packetCount);

    /**
     * @notice returns the root of packet for given id
     * @param id the id assigned to packet
     * @return root root hash corresponding to given id
     */
    function getRootByCount(uint64 id) external view returns (bytes32 root);

    /**
     * @notice returns the maxPacketLength
     * @return maxPacketLength of the capacitor
     */
    function getMaxPacketLength()
        external
        view
        returns (uint256 maxPacketLength);

    /**
     * @notice seals the packet
     * @dev indicates the packet is ready to be shipped and no more messages can be added now.
     * @dev this should be called by socket only
     * @param batchSize_ used with packet batching capacitors
     * @return root root hash of the packet
     * @return packetCount id of the packed sealed
     */
    function sealPacket(
        uint256 batchSize_
    ) external returns (bytes32 root, uint64 packetCount);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./ICapacitor.sol";
import "./IDecapacitor.sol";

/**
 * @title ICapacitorFactory
 * @notice Interface for a factory contract that deploys new instances of `ICapacitor` and `IDecapacitor` contracts.
 */
interface ICapacitorFactory {
    /**
     * @dev Emitted when an invalid capacitor type is requested during deployment.
     */
    error InvalidCapacitorType();

    /**
     * @notice Deploys a new instance of an `ICapacitor` and `IDecapacitor` contract with the specified parameters.
     * @param capacitorType The type of the capacitor to be deployed.
     * @param siblingChainSlug The identifier of the sibling chain.
     * @param maxPacketLength The maximum length of a packet.
     * @return Returns the deployed `ICapacitor` and `IDecapacitor` contract instances.
     */
    function deploy(
        uint256 capacitorType,
        uint32 siblingChainSlug,
        uint256 maxPacketLength
    ) external returns (ICapacitor, IDecapacitor);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title IDecapacitor interface
 * @notice Interface for a contract that verifies if a packed message is part of a packet or not
 */
interface IDecapacitor {
    /**
     * @notice returns if the packed message is the part of a packet or not
     * @dev this function can be used to update deCapacitor states as well
     * @param root_ root hash of the packet
     * @param packedMessage_ packed message which needs to be verified
     * @param proof_ proof used to determine the inclusion
     * @dev this function is kept as view instead of pure, as in future we may have stateful decapacitors
     */
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata proof_
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title Execution Manager Interface
 * @dev This interface defines the functions for managing and executing transactions on external chains
 * @dev It is also responsible for collecting all the socket fees, which can then be pulled by others
 */
interface IExecutionManager {
    /**
     * @notice Returns the executor of the packed message and whether the executor is authorized
     * @param packedMessage The message packed with payload, fees and config
     * @param sig The signature of the message
     * @return The address of the executor and a boolean indicating if the executor is authorized
     */
    function isExecutor(
        bytes32 packedMessage,
        bytes memory sig
    ) external view returns (address, bool);

    /**
     * @notice Pays the fees for executing a transaction on the external chain
     * @dev This function is payable and assumes the socket is going to send correct amount of fees.
     * @param minMsgGasLimit_ The minimum gas limit for the transaction
     * @param payloadSize_ The payload size in bytes
     * @param executionParams_ Extra params for execution
     * @param transmissionParams_ Extra params for transmission
     * @param siblingChainSlug_ Sibling chain identifier
     * @param switchboardFees_ fee charged by switchboard for processing transaction
     * @param verificationFees_ fee charged for verifying transaction
     * @param transmitManager_ The transmitManager address
     * @param switchboard_ The switchboard address
     * @param maxPacketLength_ The maxPacketLength for the capacitor
     */
    function payAndCheckFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        uint32 siblingChainSlug_,
        uint128 switchboardFees_,
        uint128 verificationFees_,
        address transmitManager_,
        address switchboard_,
        uint256 maxPacketLength_
    ) external payable returns (uint128, uint128);

    /**
     * @notice Returns the minimum fees required for executing a transaction on the external chain
     * @param minMsgGasLimit_ minMsgGasLimit_
     * @param siblingChainSlug_ The destination slug
     * @return The minimum fees required for executing the transaction
     */
    function getMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        uint32 siblingChainSlug_
    ) external view returns (uint128);

    /**
     * @notice function for getting the minimum fees required for executing and transmitting a cross-chain transaction
     * @dev this function is called at source to calculate the execution cost.
     * @param payloadSize_ byte length of payload. Currently only used to check max length, later on will be used for fees calculation.
     * @param executionParams_ Can be used for providing extra information. Currently used for msgValue
     * @param siblingChainSlug_ Sibling chain identifier
     * @return minExecutionFee : Minimum fees required for executing the transaction
     */
    function getExecutionTransmissionMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        uint32 siblingChainSlug_,
        address transmitManager_
    ) external view returns (uint128, uint128);

    /**
     * @notice Updates the execution fees for an executor and message ID
     * @param executor The executor address
     * @param executionFees The execution fees to update
     * @param msgId The ID of the message
     */
    function updateExecutionFees(
        address executor,
        uint128 executionFees,
        bytes32 msgId
    ) external;

    /**
     * @notice updates the transmission fee
     * @param remoteChainSlug_ sibling chain identifier
     * @param transmitMinFees_ transmission fees collected
     */
    function setTransmissionMinFees(
        uint32 remoteChainSlug_,
        uint128 transmitMinFees_
    ) external;

    /**
     * @notice sets the minimum execution fees required for executing at `siblingChainSlug_`
     * @dev this function currently sets the price for a constant msg gas limit and payload size
     * @param nonce_ incremental id to prevent signature replay
     * @param siblingChainSlug_ sibling chain identifier
     * @param executionFees_ total fees where price in destination native token is converted to source native tokens
     * @param signature_ signature of fee updater
     */
    function setExecutionFees(
        uint256 nonce_,
        uint32 siblingChainSlug_,
        uint128 executionFees_,
        bytes calldata signature_
    ) external;

    /**
     * @notice sets the min limit for msg value for `siblingChainSlug_`
     * @param nonce_ incremental id to prevent signature replay
     * @param siblingChainSlug_ sibling chain identifier
     * @param msgValueMinThreshold_ min msg value
     * @param signature_ signature of fee updater
     */
    function setMsgValueMinThreshold(
        uint256 nonce_,
        uint32 siblingChainSlug_,
        uint256 msgValueMinThreshold_,
        bytes calldata signature_
    ) external;

    /**
     * @notice sets the max limit for msg value for `siblingChainSlug_`
     * @param nonce_ incremental id to prevent signature replay
     * @param siblingChainSlug_ sibling chain identifier
     * @param msgValueMaxThreshold_ max msg value
     * @param signature_ signature of fee updater
     */
    function setMsgValueMaxThreshold(
        uint256 nonce_,
        uint32 siblingChainSlug_,
        uint256 msgValueMaxThreshold_,
        bytes calldata signature_
    ) external;

    /**
     * @notice sets the relative token price for `siblingChainSlug_`
     * @dev this function is expected to be called frequently to match the original prices
     * @param nonce_ incremental id to prevent signature replay
     * @param siblingChainSlug_ sibling chain identifier
     * @param relativeNativeTokenPrice_ relative price
     * @param signature_ signature of fee updater
     */
    function setRelativeNativeTokenPrice(
        uint256 nonce_,
        uint32 siblingChainSlug_,
        uint256 relativeNativeTokenPrice_,
        bytes calldata signature_
    ) external;

    /**
     * @notice called by socket while executing message to validate if the msg value provided is enough
     * @param executionParams_ a bytes32 string where first byte gives param type (if value is 0 or not)
     * and remaining bytes give the msg value needed
     * @param msgValue_ msg.value to be sent with inbound
     */
    function verifyParams(
        bytes32 executionParams_,
        uint256 msgValue_
    ) external view;

    /**
     * @notice withdraws switchboard fees from contract
     * @param siblingChainSlug_ withdraw fees corresponding to this slug
     * @param amount_ withdraw amount
     */
    function withdrawSwitchboardFees(
        uint32 siblingChainSlug_,
        address switchboard_,
        uint128 amount_
    ) external;

    /**
     * @dev this function gets the transmitManager address from the socket contract. If it is ever upgraded in socket,
     * @dev remove the fees from executionManager first, and then upgrade address at socket.
     * @notice withdraws transmission fees from contract
     * @param siblingChainSlug_ withdraw fees corresponding to this slug
     * @param amount_ withdraw amount
     */
    function withdrawTransmissionFees(
        uint32 siblingChainSlug_,
        uint128 amount_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./ISocket.sol";

/**
 * @title IHasher
 * @notice Interface for hasher contract that calculates the packed message
 */
interface IHasher {
    /**
     * @notice returns the bytes32 hash of the message packed
     * @param srcChainSlug src chain slug
     * @param srcPlug address of plug at source
     * @param dstChainSlug remote chain slug
     * @param dstPlug address of plug at remote
     * @param messageDetails contains message details, see ISocket for more details
     */
    function packMessage(
        uint32 srcChainSlug,
        address srcPlug,
        uint32 dstChainSlug,
        address dstPlug,
        ISocket.MessageDetails memory messageDetails
    ) external returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title INativeRelay
 * @notice Interface for the NativeRelay contract which is used to relay packets between two chains.
 * It allows for the reception of messages on the PolygonRootReceiver and the initiation of native confirmations
 * for the given packet ID.
 * @dev this is only used by SocketBatcher currently
 */
interface INativeRelay {
    /**
     * @notice receiveMessage on PolygonRootReceiver
     * @param receivePacketProof receivePacketProof The proof of the packet being received on the Polygon network.
     */
    function receiveMessage(bytes memory receivePacketProof) external;

    /**
     * @notice Function to initiate a native confirmation for the given packet ID.
     * @dev The function can be called with maxSubmissionCost, maxGas, and gasPriceBid to customize the confirmation transaction,
     * or with no parameters to use default values.
     * @param packetId The ID of the packet to initiate confirmation for.
     * @param maxSubmissionCost The maximum submission cost of the transaction.
     * @param maxGas The maximum gas limit of the transaction.
     * @param gasPriceBid The gas price bid for the transaction.
     * @param callValueRefundAddress l2 call value gets credited here on L2 if retryable txn times out or gets cancelled
     * @param remoteRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     */
    function initiateNativeConfirmation(
        bytes32 packetId,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid,
        address callValueRefundAddress,
        address remoteRefundAddress
    ) external payable;

    /**
     * @notice Function to initiate a native confirmation for the given packet ID, using default values for transaction parameters.
     * @param packetId The ID of the packet to initiate confirmation for.
     */
    function initiateNativeConfirmation(bytes32 packetId) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title IPlug
 * @notice Interface for a plug contract that executes the message received from a source chain.
 */
interface IPlug {
    /**
     * @dev this should be only executable by socket
     * @notice executes the message received from source chain
     * @notice It is expected to have original sender checks in the destination plugs using payload
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint32 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title Signature Verifier
 * @notice Verifies the signatures and returns the address of signer recovered from the input signature or digest.
 */
interface ISignatureVerifier {
    /**
     * @notice returns the address of signer recovered from input signature and digest
     */
    function recoverSigner(
        bytes32 digest_,
        bytes memory signature_
    ) external pure returns (address signer);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./ITransmitManager.sol";
import "./IExecutionManager.sol";

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
     * @notice A struct containing fees required for message transmission and execution
     * @param transmissionFees fees needed for transmission
     * @param switchboardFees fees needed by switchboard
     * @param executionFee fees needed for execution
     */
    struct Fees {
        uint128 transmissionFees;
        uint128 executionFee;
        uint128 switchboardFees;
    }

    /**
     * @title MessageDetails
     * @dev This struct defines the details of a message to be executed in a Decapacitor contract.
     */
    struct MessageDetails {
        // A unique identifier for the message.
        bytes32 msgId;
        // The fee to be paid for executing the message.
        uint256 executionFee;
        // The maximum amount of gas that can be used to execute the message.
        uint256 minMsgGasLimit;
        // The extra params which provides msg value and additional info needed for message exec
        bytes32 executionParams;
        // The payload data to be executed in the message.
        bytes payload;
    }

    /**
     * @title ExecutionDetails
     * @dev This struct defines the execution details
     */
    struct ExecutionDetails {
        // packet id
        bytes32 packetId;
        // proposal count
        uint256 proposalCount;
        // gas limit needed to execute inbound
        uint256 executionGasLimit;
        // proof data required by the Decapacitor contract to verify the message's authenticity
        bytes decapacitorProof;
        // signature of executor
        bytes signature;
    }

    /**
     * @notice emits the message details when a new message arrives at outbound
     * @param localChainSlug local chain slug
     * @param localPlug local plug address
     * @param dstChainSlug remote chain slug
     * @param dstPlug remote plug address
     * @param msgId message id packed with remoteChainSlug and nonce
     * @param minMsgGasLimit gas limit needed to execute the inbound at remote
     * @param payload the data which will be used by inbound at remote
     */
    event MessageOutbound(
        uint32 localChainSlug,
        address localPlug,
        uint32 dstChainSlug,
        address dstPlug,
        bytes32 msgId,
        uint256 minMsgGasLimit,
        bytes32 executionParams,
        bytes32 transmissionParams,
        bytes payload,
        Fees fees
    );

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     */
    event ExecutionSuccess(bytes32 msgId);

    /**
     * @notice emits the config set by a plug for a remoteChainSlug
     * @param plug address of plug on current chain
     * @param siblingChainSlug sibling chain slug
     * @param siblingPlug address of plug on sibling chain
     * @param inboundSwitchboard inbound switchboard (select from registered options)
     * @param outboundSwitchboard outbound switchboard (select from registered options)
     * @param capacitor capacitor selected based on outbound switchboard
     * @param decapacitor decapacitor selected based on inbound switchboard
     */
    event PlugConnected(
        address plug,
        uint32 siblingChainSlug,
        address siblingPlug,
        address inboundSwitchboard,
        address outboundSwitchboard,
        address capacitor,
        address decapacitor
    );

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
     * @notice executes a message
     * @param executionDetails_ the packet details, proof and signature needed for message execution
     * @param messageDetails_ the message details
     */
    function execute(
        ISocket.ExecutionDetails calldata executionDetails_,
        ISocket.MessageDetails calldata messageDetails_
    ) external payable;

    /**
     * @notice seals data in capacitor for specific batchSize
     * @param batchSize_ size of batch to be sealed
     * @param capacitorAddress_ address of capacitor
     * @param signature_ signed Data needed for verification
     */
    function seal(
        uint256 batchSize_,
        address capacitorAddress_,
        bytes calldata signature_
    ) external payable;

    /**
     * @notice proposes a packet
     * @param packetId_ packet id
     * @param root_ root data
     * @param switchboard_ The address of switchboard for which this packet is proposed
     * @param signature_ signed Data needed for verification
     */
    function proposeForSwitchboard(
        bytes32 packetId_,
        bytes32 root_,
        address switchboard_,
        bytes calldata signature_
    ) external payable;

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

    /**
     * @notice deploy capacitor and decapacitor for a switchboard with a specified max packet length, sibling chain slug, and capacitor type.
     * @param siblingChainSlug_ The slug of the sibling chain that the switchboard is registered with.
     * @param maxPacketLength_ The maximum length of a packet allowed by the switchboard.
     * @param capacitorType_ The type of capacitor that the switchboard uses.
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function registerSwitchboardForSibling(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_,
        address siblingSwitchboard_
    ) external returns (address capacitor, address decapacitor);

    /**
     * @notice Emits the sibling switchboard for given `siblingChainSlug_`.
     * @dev This function is expected to be only called by switchboard.
     * @dev the event emitted is tracked by transmitters to decide which switchboard a packet should be proposed on
     * @param siblingChainSlug_ The slug of the sibling chain
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function useSiblingSwitchboard(
        uint32 siblingChainSlug_,
        address siblingSwitchboard_
    ) external;

    /**
     * @notice Retrieves the packet id roots for a specified packet id.
     * @param packetId_ The packet id for which to retrieve the root.
     * @param proposalCount_ The proposal id for packetId_ for which to retrieve the root.
     * @param switchboard_ The address of switchboard for which this packet is proposed
     * @return The packet id roots for the specified packet id.
     */
    function packetIdRoots(
        bytes32 packetId_,
        uint256 proposalCount_,
        address switchboard_
    ) external view returns (bytes32);

    /**
     * @notice Retrieves the minimum fees required for a message with a specified gas limit and destination chain.
     * @param minMsgGasLimit_ The gas limit of the message.
     * @param remoteChainSlug_ The slug of the destination chain for the message.
     * @param plug_ The address of the plug through which the message is sent.
     * @return totalFees The minimum fees required for the specified message.
     */
    function getMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view returns (uint256 totalFees);

    /// return instance of transmit manager
    function transmitManager__() external view returns (ITransmitManager);

    /// return instance of execution manager
    function executionManager__() external view returns (IExecutionManager);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title ISwitchboard
 * @dev The interface for a switchboard contract that is responsible for verification of packets between
 * different blockchain networks.
 */
interface ISwitchboard {
    /**
     * @notice Registers itself in Socket for given `siblingChainSlug_`.
     * @dev This function is expected to be only called by admin as it handles the capacitor config for given chain
     * @param siblingChainSlug_ The slug of the sibling chain to register switchboard with.
     * @param maxPacketLength_ The maximum length of a packet allowed by the switchboard.
     * @param capacitorType_ The type of capacitor that the switchboard uses.
     * @param initialPacketCount_ The packet count at the time of registering switchboard. Packets with packet count below this won't be allowed
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function registerSiblingSlug(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_,
        uint256 initialPacketCount_,
        address siblingSwitchboard_
    ) external;

    /**
     * @notice Updates the sibling switchboard for given `siblingChainSlug_`.
     * @dev This function is expected to be only called by admin
     * @param siblingChainSlug_ The slug of the sibling chain to register switchboard with.
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function updateSibling(
        uint32 siblingChainSlug_,
        address siblingSwitchboard_
    ) external;

    /**
     * @notice Checks if a packet can be allowed to go through the switchboard.
     * @param root the packet root.
     * @param packetId The unique identifier for the packet.
     * @param proposalCount The unique identifier for a proposal for the packet.
     * @param srcChainSlug The unique identifier for the source chain of the packet.
     * @param proposeTime The time when the packet was proposed.
     * @return A boolean indicating whether the packet is allowed to go through the switchboard or not.
     */
    function allowPacket(
        bytes32 root,
        bytes32 packetId,
        uint256 proposalCount,
        uint32 srcChainSlug,
        uint256 proposeTime
    ) external view returns (bool);

    /**
     * @notice Retrieves the minimum fees required for the destination chain to process the packet.
     * @param dstChainSlug the unique identifier for the destination chain of the packet.
     * @return switchboardFee the switchboard fee required for the destination chain to process the packet.
     * @return verificationFee the verification fee required for the destination chain to process the packet.
     */
    function getMinFees(
        uint32 dstChainSlug
    ) external view returns (uint128 switchboardFee, uint128 verificationFee);

    /**
     * @notice Receives the fees for processing of packet.
     * @param siblingChainSlug_ the chain slug of the sibling chain.
     */
    function receiveFees(uint32 siblingChainSlug_) external payable;

    /**
     * @notice Sets the minimum fees required for the destination chain to process the packet.
     * @param nonce_ the nonce of fee Updater to avoid replay.
     * @param dstChainSlug_ the unique identifier for the destination chain.
     * @param switchboardFees_ the switchboard fee required for the destination chain to process the packet.
     * @param verificationFees_ the verification fee required for the destination chain to process the packet.
     * @param signature_ the signature of the request.
     * @dev not important to override in all switchboards
     */
    function setFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint128 switchboardFees_,
        uint128 verificationFees_,
        bytes calldata signature_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title ITransmitManager
 * @dev The interface for a transmit manager contract
 */
interface ITransmitManager {
    /**
     * @notice Checks if a given transmitter is authorized to send transactions to the destination chain.
     * @param siblingSlug The unique identifier for the sibling chain.
     * @param digest The digest of the message being signed.
     * @param signature The signature of the message being signed.
     * @return The address of the transmitter and a boolean indicating whether the transmitter is authorized or not.
     */
    function checkTransmitter(
        uint32 siblingSlug,
        bytes32 digest,
        bytes calldata signature
    ) external view returns (address, bool);

    /**
     * @notice sets the transmission fee needed to transmit message to given `siblingSlug_`
     * @dev recovered address should add have feeUpdater role for `siblingSlug_`
     * @param nonce_ The incremental nonce to prevent signature replay
     * @param siblingSlug_ sibling id for which fee updater is registered
     * @param transmissionFees_ digest which is signed by transmitter
     * @param signature_ signature
     */
    function setTransmissionFees(
        uint256 nonce_,
        uint32 siblingSlug_,
        uint128 transmissionFees_,
        bytes calldata signature_
    ) external;

    /**
     * @notice receives fees from Execution manager
     * @dev this function can be used to keep track of fees received for each slug
     * @param siblingSlug_ sibling id for which fee updater is registered
     */
    function receiveFees(uint32 siblingSlug_) external payable;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

library AddressAliasHelper {
    uint160 internal constant _OFFSET =
        uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address_ the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(
        address l1Address_
    ) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address_) + _OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address_ L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(
        address l2Address_
    ) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address_) - _OFFSET);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "lib/solmate/src/utils/SafeTransferLib.sol";

error ZeroAddress();

/**
 * @title RescueFundsLib
 * @dev A library that provides a function to rescue funds from a contract.
 */

library RescueFundsLib {
    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev thrown when the given token address don't have any code
     */
    error InvalidTokenAddress();

    /**
     * @dev Rescues funds from a contract.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) internal {
        if (userAddress_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(userAddress_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), userAddress_, amount_);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../utils/AccessControl.sol";

contract MockAccessControl is AccessControl {
    bytes32 public constant ROLE_GIRAFFE = keccak256("ROLE_GIRAFFE");
    bytes32 public constant ROLE_HIPPO = keccak256("ROLE_HIPPO");

    constructor(address owner_) AccessControl(owner_) {}

    function giraffe() external onlyRole(ROLE_GIRAFFE) {}

    function hippo() external onlyRole(ROLE_HIPPO) {}

    function animal() external {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../utils/Ownable.sol";

contract MockOwnable is Ownable {
    constructor(address owner_) Ownable(owner_) {}

    function ownerFunction() external onlyOwner {}

    function publicFunction() external {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;
import "./ExecutionManager.sol";

/**
 * @title OpenExecutionManager
 * @dev ExecutionManager contract with open execution
 */
contract OpenExecutionManager is ExecutionManager {
    /**
     * @dev Constructor for OpenExecutionManager contract
     * @param owner_ Address of the contract owner
     * @param chainSlug_ chain slug used to identify current chain
     * @param signatureVerifier_ Address of the signature verifier contract
     * @param socket_ Address of the socket contract
     */
    constructor(
        address owner_,
        uint32 chainSlug_,
        ISocket socket_,
        ISignatureVerifier signatureVerifier_
    ) ExecutionManager(owner_, chainSlug_, socket_, signatureVerifier_) {}

    /**
     * @notice This function allows all executors
     * @notice The executor recovered here can be a random address hence should not be used for fee accounting
     * @param packedMessage Packed message to be executed
     * @param sig Signature of the message
     * @return executor Address of the executor
     * @return isValidExecutor Boolean value indicating whether the executor is valid or not
     */
    function isExecutor(
        bytes32 packedMessage,
        bytes memory sig
    ) external view override returns (address executor, bool isValidExecutor) {
        executor = signatureVerifier__.recoverSigner(packedMessage, sig);
        isValidExecutor = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./SocketDst.sol";
import {SocketSrc} from "./SocketSrc.sol";

/**
 * @title Socket
 * @notice A contract that acts as both a source and destination for cross-chain transactions.
 * @dev This contract inherits from SocketSrc and SocketDst
 */
contract Socket is SocketSrc, SocketDst {
    /*
     * @notice constructor for creating a new Socket contract instance.
     * @param chainSlug_ The unique identifier of the chain this socket is deployed on.
     * @param hasher_ The address of the Hasher contract used to pack the message before transmitting them.
     * @param capacitorFactory_ The address of the CapacitorFactory contract used to create new Capacitor and DeCapacitor contracts.
     * @param owner_ The address of the owner who has the initial admin role.
     * @param version_ The version string which is hashed and stored in socket.
     */
    constructor(
        uint32 chainSlug_,
        address hasher_,
        address capacitorFactory_,
        address owner_,
        string memory version_
    ) AccessControlExtended(owner_) SocketBase(chainSlug_, version_) {
        hasher__ = IHasher(hasher_);
        capacitorFactory__ = ICapacitorFactory(capacitorFactory_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IHasher.sol";
import "../libraries/RescueFundsLib.sol";
import "../utils/AccessControlExtended.sol";
import {RESCUE_ROLE, GOVERNANCE_ROLE} from "../utils/AccessRoles.sol";

import "./SocketConfig.sol";

/**
 * @title SocketBase
 * @notice A contract that is responsible for common storage for src and dest contracts, governance
 * setters and inherits SocketConfig
 */
abstract contract SocketBase is SocketConfig, AccessControlExtended {
    // Hasher contract
    IHasher public hasher__;
    // Transmit Manager contract
    ITransmitManager public override transmitManager__;
    // Execution Manager contract
    IExecutionManager public override executionManager__;

    // chain slug
    uint32 public immutable chainSlug;
    // incrementing counter for messages going out of current chain
    uint64 public globalMessageCount;
    // current version
    bytes32 public immutable version;

    /**
     * @dev constructs a new Socket contract instance.
     * @param chainSlug_ the chain slug of the contract.
     * @param version_ the string to identify current version.
     */
    constructor(uint32 chainSlug_, string memory version_) {
        chainSlug = chainSlug_;
        version = keccak256(bytes(version_));
    }

    /**
     * @dev An error that is thrown when an invalid signer tries to seal or propose.
     */
    error InvalidTransmitter();

    /**
     * @notice An event that is emitted when the capacitor factory is updated.
     * @param capacitorFactory The address of the new capacitorFactory.
     */
    event CapacitorFactorySet(address capacitorFactory);
    /**
     * @notice An event that is emitted when the hasher is updated.
     * @param hasher The address of the new hasher.
     */
    event HasherSet(address hasher);
    /**
     * @notice An event that is emitted when the executionManager is updated.
     * @param executionManager The address of the new executionManager.
     */
    event ExecutionManagerSet(address executionManager);
    /**
     * @notice An event that is emitted when a new transmitManager contract is set
     * @param transmitManager address of new transmitManager contract
     */
    event TransmitManagerSet(address transmitManager);

    /**
     * @dev Set the capacitor factory contract
     * @dev Only governance can call this function
     * @param capacitorFactory_ The address of the capacitor factory contract
     */
    function setCapacitorFactory(
        address capacitorFactory_
    ) external onlyRole(GOVERNANCE_ROLE) {
        capacitorFactory__ = ICapacitorFactory(capacitorFactory_);
        emit CapacitorFactorySet(capacitorFactory_);
    }

    /**
     * @notice updates hasher__
     * @dev Only governance can call this function
     * @param hasher_ address of hasher
     */
    function setHasher(address hasher_) external onlyRole(GOVERNANCE_ROLE) {
        hasher__ = IHasher(hasher_);
        emit HasherSet(hasher_);
    }

    /**
     * @notice updates executionManager__
     * @dev Only governance can call this function
     * @param executionManager_ address of Execution Manager
     */
    function setExecutionManager(
        address executionManager_
    ) external onlyRole(GOVERNANCE_ROLE) {
        executionManager__ = IExecutionManager(executionManager_);
        emit ExecutionManagerSet(executionManager_);
    }

    /**
     * @notice updates transmitManager__
     * @param transmitManager_ address of Transmit Manager
     * @dev Only governance can call this function
     * @dev This function sets the transmitManager address. If it is ever upgraded,
     * remove the fees from executionManager first, and then upgrade address at socket.
     */
    function setTransmitManager(
        address transmitManager_
    ) external onlyRole(GOVERNANCE_ROLE) {
        transmitManager__ = ITransmitManager(transmitManager_);
        emit TransmitManagerSet(transmitManager_);
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../libraries/RescueFundsLib.sol";
import "../utils/AccessControl.sol";
import "../interfaces/ISocket.sol";
import "../switchboard/default-switchboards/FastSwitchboard.sol";
import "../interfaces/INativeRelay.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

/**
 * @title SocketBatcher
 * @notice A contract that facilitates the batching of packets across chains. It manages requests for sealing, proposing, attesting, and executing packets across multiple chains.
 * It also has functions for setting gas limits, execution overhead, and registering switchboards.
 * @dev This contract uses the AccessControl contract for managing role-based access control.
 */
contract SocketBatcher is AccessControl {
    /*
     * @notice Constructs the SocketBatcher contract and grants the RESCUE_ROLE to the contract deployer.
     * @param owner_ The address of the contract deployer, who will be granted the RESCUE_ROLE.
     */
    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @notice A struct representing a request to seal a batch of packets on the source chain.
     * @param batchSize The number of packets to be sealed in the batch.
     * @param capacitorAddress The address of the capacitor contract on the source chain.
     * @param signature The signature of the packet data.
     */
    struct SealRequest {
        uint256 batchSize;
        address capacitorAddress;
        bytes signature;
    }

    /**
     * @notice A struct representing a proposal request for a packet.
     * @param packetId The ID of the packet being proposed.
     * @param root The Merkle root of the packet data.
     * @param switchboard The address of switchboard
     * @param signature The signature of the packet data.
     */
    struct ProposeRequest {
        bytes32 packetId;
        bytes32 root;
        address switchboard;
        bytes signature;
    }

    /**
     * @notice A struct representing an attestation request for a packet.
     * @param packetId The ID of the packet being attested.
     * @param srcChainSlug The slug of the source chain.
     * @param signature The signature of the packet data.
     */
    struct AttestRequest {
        bytes32 packetId;
        uint256 proposalCount;
        bytes32 root;
        bytes signature;
    }

    /**
     * @notice A struct representing a request to execute a packet.
     * @param executionDetails The execution details.
     * @param messageDetails The message details of the packet.
     */
    struct ExecuteRequest {
        ISocket.ExecutionDetails executionDetails;
        ISocket.MessageDetails messageDetails;
    }

    /**
     * @notice A struct representing a request to initiate an Arbitrum native transaction.
     * @param packetId The ID of the packet to be executed.
     * @param maxSubmissionCost The maximum submission cost of the transaction.
     * @param maxGas The maximum amount of gas for the transaction.
     * @param gasPriceBid The gas price bid for the transaction.
     * @param callValue The call value of the transaction.
     */
    struct ArbitrumNativeInitiatorRequest {
        bytes32 packetId;
        uint256 maxSubmissionCost;
        uint256 maxGas;
        uint256 gasPriceBid;
        uint256 callValue;
    }

    /**
     * @notice A struct representing a request to send proof to polygon root
     * @param proof proof to submit on root tunnel
     */
    struct ReceivePacketProofRequest {
        bytes proof;
    }

    /**
     * @notice A struct representing a request set fees in switchboard
     * @param nonce The nonce of fee setter address
     * @param dstChainSlug The sibling chain identifier
     * @param switchboardFees The fees needed by switchboard
     * @param verificationFees The fees needed for calling allowPacket while executing
     * @param signature The signature of the packet data.
     */
    struct SwitchboardSetFeesRequest {
        uint256 nonce;
        uint32 dstChainSlug;
        uint128 switchboardFees;
        uint128 verificationFees;
        bytes signature;
    }

    /**
     * @notice A struct representing a request to set fees in execution manager and transmit manager
     * @param nonce The nonce of fee setter address
     * @param dstChainSlug The sibling chain identifier
     * @param fees The total fees needed
     * @param signature The signature of the packet data.
     */
    struct SetFeesRequest {
        uint256 nonce;
        uint32 dstChainSlug;
        uint128 fees;
        bytes signature;
        bytes4 functionSelector;
    }

    /**
     * @notice sets fees in batch for switchboards
     * @param contractAddress_ address of contract to set fees
     * @param switchboardSetFeesRequest_ the list of requests
     */
    function setFeesBatch(
        address contractAddress_,
        SwitchboardSetFeesRequest[] calldata switchboardSetFeesRequest_
    ) external {
        uint256 executeRequestLength = switchboardSetFeesRequest_.length;
        for (uint256 index = 0; index < executeRequestLength; ) {
            FastSwitchboard(contractAddress_).setFees(
                switchboardSetFeesRequest_[index].nonce,
                switchboardSetFeesRequest_[index].dstChainSlug,
                switchboardSetFeesRequest_[index].switchboardFees,
                switchboardSetFeesRequest_[index].verificationFees,
                switchboardSetFeesRequest_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice sets fees in batch for transmit manager
     * @param contractAddress_ address of contract to set fees
     * @param setFeesRequests_ the list of requests
     */
    function setTransmissionFeesBatch(
        address contractAddress_,
        SetFeesRequest[] calldata setFeesRequests_
    ) external {
        uint256 feeRequestLength = setFeesRequests_.length;
        for (uint256 index = 0; index < feeRequestLength; ) {
            ITransmitManager(contractAddress_).setTransmissionFees(
                setFeesRequests_[index].nonce,
                setFeesRequests_[index].dstChainSlug,
                setFeesRequests_[index].fees,
                setFeesRequests_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice sets fees in batch for execution manager
     * @param contractAddress_ address of contract to set fees
     * @param setFeesRequests_ the list of requests
     */
    function setExecutionFeesBatch(
        address contractAddress_,
        SetFeesRequest[] calldata setFeesRequests_
    ) external {
        uint256 feeRequestLength = setFeesRequests_.length;
        for (uint256 index = 0; index < feeRequestLength; ) {
            if (
                setFeesRequests_[index].functionSelector ==
                IExecutionManager.setExecutionFees.selector
            )
                IExecutionManager(contractAddress_).setExecutionFees(
                    setFeesRequests_[index].nonce,
                    setFeesRequests_[index].dstChainSlug,
                    setFeesRequests_[index].fees,
                    setFeesRequests_[index].signature
                );

            if (
                setFeesRequests_[index].functionSelector ==
                IExecutionManager.setRelativeNativeTokenPrice.selector
            )
                IExecutionManager(contractAddress_).setRelativeNativeTokenPrice(
                    setFeesRequests_[index].nonce,
                    setFeesRequests_[index].dstChainSlug,
                    setFeesRequests_[index].fees,
                    setFeesRequests_[index].signature
                );

            if (
                setFeesRequests_[index].functionSelector ==
                IExecutionManager.setMsgValueMaxThreshold.selector
            )
                IExecutionManager(contractAddress_).setMsgValueMaxThreshold(
                    setFeesRequests_[index].nonce,
                    setFeesRequests_[index].dstChainSlug,
                    setFeesRequests_[index].fees,
                    setFeesRequests_[index].signature
                );

            if (
                setFeesRequests_[index].functionSelector ==
                IExecutionManager.setMsgValueMinThreshold.selector
            )
                IExecutionManager(contractAddress_).setMsgValueMinThreshold(
                    setFeesRequests_[index].nonce,
                    setFeesRequests_[index].dstChainSlug,
                    setFeesRequests_[index].fees,
                    setFeesRequests_[index].signature
                );

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice seal a batch of packets from capacitor on sourceChain mentioned in sealRequests
     * @param socketAddress_ address of socket
     * @param sealRequests_ the list of requests with packets to be sealed on sourceChain
     */
    function sealBatch(
        address socketAddress_,
        SealRequest[] calldata sealRequests_
    ) external {
        uint256 sealRequestLength = sealRequests_.length;
        for (uint256 index = 0; index < sealRequestLength; ) {
            ISocket(socketAddress_).seal(
                sealRequests_[index].batchSize,
                sealRequests_[index].capacitorAddress,
                sealRequests_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice propose a batch of packets sequentially by socketDestination
     * @param socketAddress_ address of socket
     * @param proposeRequests_ the list of requests with packets to be proposed by socketDestination
     */
    function proposeBatch(
        address socketAddress_,
        ProposeRequest[] calldata proposeRequests_
    ) external {
        uint256 proposeRequestLength = proposeRequests_.length;
        for (uint256 index = 0; index < proposeRequestLength; ) {
            ISocket(socketAddress_).proposeForSwitchboard(
                proposeRequests_[index].packetId,
                proposeRequests_[index].root,
                proposeRequests_[index].switchboard,
                proposeRequests_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice attests a batch of Packets
     * @param switchboardAddress_ address of switchboard
     * @param attestRequests_ the list of requests with packets to be attested by switchboard in sequence
     */
    function attestBatch(
        address switchboardAddress_,
        AttestRequest[] calldata attestRequests_
    ) external {
        uint256 attestRequestLength = attestRequests_.length;
        for (uint256 index = 0; index < attestRequestLength; ) {
            FastSwitchboard(switchboardAddress_).attest(
                attestRequests_[index].packetId,
                attestRequests_[index].proposalCount,
                attestRequests_[index].root,
                attestRequests_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice executes a batch of messages
     * @param socketAddress_ address of socket
     * @param executeRequests_ the list of requests with messages to be executed in sequence
     */
    function executeBatch(
        address socketAddress_,
        ExecuteRequest[] calldata executeRequests_
    ) external payable {
        uint256 executeRequestLength = executeRequests_.length;
        for (uint256 index = 0; index < executeRequestLength; ) {
            bytes32 executionParams = executeRequests_[index]
                .messageDetails
                .executionParams;
            uint8 paramType = uint8(uint256(executionParams) >> 248);
            uint256 msgValue = uint256(uint248(uint256(executionParams)));
            if (paramType == 0) msgValue = 0;

            ISocket(socketAddress_).execute{value: msgValue}(
                executeRequests_[index].executionDetails,
                executeRequests_[index].messageDetails
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice invoke receive Message on PolygonRootReceiver for a batch of messages in loop
     * @param polygonRootReceiverAddress_ address of polygonRootReceiver
     * @param receivePacketProofs_ the list of receivePacketProofs to be sent to receiveHook of polygonRootReceiver
     */
    function receiveMessageBatch(
        address polygonRootReceiverAddress_,
        ReceivePacketProofRequest[] calldata receivePacketProofs_
    ) external {
        uint256 receivePacketProofsLength = receivePacketProofs_.length;
        for (uint256 index = 0; index < receivePacketProofsLength; ) {
            INativeRelay(polygonRootReceiverAddress_).receiveMessage(
                receivePacketProofs_[index].proof
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice initiate NativeConfirmation on arbitrumChain for a batch of packets in loop
     * @param switchboardAddress_ address of nativeArbitrumSwitchboard
     * @param arbitrumNativeInitiatorRequests_ the list of requests with packets to initiate nativeConfirmation on switchboard of arbitrumChain
     */
    function initiateArbitrumNativeBatch(
        address switchboardAddress_,
        address callValueRefundAddress_,
        address remoteRefundAddress_,
        ArbitrumNativeInitiatorRequest[]
            calldata arbitrumNativeInitiatorRequests_
    ) external payable {
        uint256 arbitrumNativeInitiatorRequestsLength = arbitrumNativeInitiatorRequests_
                .length;
        for (
            uint256 index = 0;
            index < arbitrumNativeInitiatorRequestsLength;

        ) {
            INativeRelay(switchboardAddress_).initiateNativeConfirmation{
                value: arbitrumNativeInitiatorRequests_[index].callValue
            }(
                arbitrumNativeInitiatorRequests_[index].packetId,
                arbitrumNativeInitiatorRequests_[index].maxSubmissionCost,
                arbitrumNativeInitiatorRequests_[index].maxGas,
                arbitrumNativeInitiatorRequests_[index].gasPriceBid,
                callValueRefundAddress_,
                remoteRefundAddress_
            );
            unchecked {
                ++index;
            }
        }

        if (address(this).balance > 0) {
            if (callValueRefundAddress_ == address(0)) revert ZeroAddress();
            SafeTransferLib.safeTransferETH(
                callValueRefundAddress_,
                address(this).balance
            );
        }
    }

    /**
     * @notice initiate NativeConfirmation on nativeChain(s) for a batch of packets in loop
     * @param switchboardAddress_ address of nativeSwitchboard
     * @param nativePacketIds_ the list of requests with packets to initiate nativeConfirmation on switchboard of native chains
     */
    function initiateNativeBatch(
        address switchboardAddress_,
        bytes32[] calldata nativePacketIds_
    ) external {
        uint256 nativePacketIdsLength = nativePacketIds_.length;
        for (uint256 index = 0; index < nativePacketIdsLength; ) {
            INativeRelay(switchboardAddress_).initiateNativeConfirmation(
                nativePacketIds_[index]
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/ISocket.sol";
import "../interfaces/ICapacitorFactory.sol";
import "../interfaces/ISwitchboard.sol";

/**
 * @title SocketConfig
 * @notice An abstract contract for configuring socket connections for plugs between different chains,
 * manages plug configs and switchboard registrations
 * @dev This contract is meant to be inherited by other contracts that require socket configuration functionality
 */
abstract contract SocketConfig is ISocket {
    /**
     * @dev Struct to store the configuration for a plug connection
     */
    struct PlugConfig {
        // address of the sibling plug on the remote chain
        address siblingPlug;
        // capacitor instance for the outbound plug connection
        ICapacitor capacitor__;
        // decapacitor instance for the inbound plug connection
        IDecapacitor decapacitor__;
        // inbound switchboard instance for the plug connection
        ISwitchboard inboundSwitchboard__;
        // outbound switchboard instance for the plug connection
        ISwitchboard outboundSwitchboard__;
    }

    // Capacitor factory contract
    ICapacitorFactory public capacitorFactory__;

    // capacitor address => siblingChainSlug
    // It is used to maintain record of capacitors in the system registered for a slug and also used in seal for verification
    mapping(address => uint32) public capacitorToSlug;

    // switchboard => siblingChainSlug => ICapacitor
    mapping(address => mapping(uint32 => ICapacitor)) public capacitors__;
    // switchboard => siblingChainSlug => IDecapacitor
    mapping(address => mapping(uint32 => IDecapacitor)) public decapacitors__;

    // plug => remoteChainSlug => (siblingPlug, capacitor__, decapacitor__, inboundSwitchboard__, outboundSwitchboard__)
    mapping(address => mapping(uint32 => PlugConfig)) internal _plugConfigs;

    // Event triggered when a new switchboard is added
    event SwitchboardAdded(
        address switchboard,
        uint32 siblingChainSlug,
        address capacitor,
        address decapacitor,
        uint256 maxPacketLength,
        uint256 capacitorType
    );

    // Event triggered when a new switchboard is added
    event SiblingSwitchboardUpdated(
        address switchboard,
        uint32 siblingChainSlug,
        address siblingSwitchboard
    );

    // Error triggered when a switchboard already exists
    error SwitchboardExists();
    // Error triggered when a connection is invalid
    error InvalidConnection();

    /**
     * @notice deploy capacitor and decapacitor for a switchboard with a specified max packet length, sibling chain slug, and capacitor type.
     * @param siblingChainSlug_ The slug of the sibling chain that the switchboard is registered with.
     * @param maxPacketLength_ The maximum length of a packet allowed by the switchboard.
     * @param capacitorType_ The type of capacitor that the switchboard uses.
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function registerSwitchboardForSibling(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_,
        address siblingSwitchboard_
    ) external override returns (address capacitor, address decapacitor) {
        address switchboardAddress = msg.sender;
        // only capacitor checked, decapacitor assumed will exist if capacitor does
        if (
            address(capacitors__[switchboardAddress][siblingChainSlug_]) !=
            address(0)
        ) revert SwitchboardExists();

        (
            ICapacitor capacitor__,
            IDecapacitor decapacitor__
        ) = capacitorFactory__.deploy(
                capacitorType_,
                siblingChainSlug_,
                maxPacketLength_
            );

        capacitor = address(capacitor__);
        decapacitor = address(decapacitor__);

        capacitorToSlug[capacitor] = siblingChainSlug_;
        capacitors__[switchboardAddress][siblingChainSlug_] = capacitor__;
        decapacitors__[switchboardAddress][siblingChainSlug_] = decapacitor__;

        emit SwitchboardAdded(
            switchboardAddress,
            siblingChainSlug_,
            capacitor,
            decapacitor,
            maxPacketLength_,
            capacitorType_
        );

        emit SiblingSwitchboardUpdated(
            switchboardAddress,
            siblingChainSlug_,
            siblingSwitchboard_
        );
    }

    /**
     * @notice Emits the sibling switchboard for given `siblingChainSlug_`.
     * @dev This function is expected to be only called by switchboard.
     * @dev the event emitted is tracked by transmitters to decide which switchboard a packet should be proposed on
     * @param siblingChainSlug_ The slug of the sibling chain
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function useSiblingSwitchboard(
        uint32 siblingChainSlug_,
        address siblingSwitchboard_
    ) external {
        emit SiblingSwitchboardUpdated(
            msg.sender,
            siblingChainSlug_,
            siblingSwitchboard_
        );
    }

    /**
     * @notice connects Plug to Socket and sets the config for given `siblingChainSlug_`
     * @notice msg.sender is stored as plug address against given configuration
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at siblingChainSlug_ to call at inbound
     * @param inboundSwitchboard_ the address of switchboard to use for verifying messages at inbound
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external override {
        // only capacitor checked, decapacitor assumed will exist if capacitor does
        if (
            address(capacitors__[inboundSwitchboard_][siblingChainSlug_]) ==
            address(0) ||
            address(capacitors__[outboundSwitchboard_][siblingChainSlug_]) ==
            address(0)
        ) revert InvalidConnection();

        PlugConfig storage _plugConfig = _plugConfigs[msg.sender][
            siblingChainSlug_
        ];

        _plugConfig.siblingPlug = siblingPlug_;
        _plugConfig.capacitor__ = capacitors__[outboundSwitchboard_][
            siblingChainSlug_
        ];
        _plugConfig.decapacitor__ = decapacitors__[inboundSwitchboard_][
            siblingChainSlug_
        ];
        _plugConfig.inboundSwitchboard__ = ISwitchboard(inboundSwitchboard_);
        _plugConfig.outboundSwitchboard__ = ISwitchboard(outboundSwitchboard_);

        emit PlugConnected(
            msg.sender,
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_,
            address(_plugConfig.capacitor__),
            address(_plugConfig.decapacitor__)
        );
    }

    /**
     * @notice returns the config for given `plugAddress_` and `siblingChainSlug_`
     * @param siblingChainSlug_ the sibling chain slug
     * @param plugAddress_ address of plug present at current chain
     */
    function getPlugConfig(
        address plugAddress_,
        uint32 siblingChainSlug_
    )
        external
        view
        returns (
            address siblingPlug,
            address inboundSwitchboard__,
            address outboundSwitchboard__,
            address capacitor__,
            address decapacitor__
        )
    {
        PlugConfig memory _plugConfig = _plugConfigs[plugAddress_][
            siblingChainSlug_
        ];

        return (
            _plugConfig.siblingPlug,
            address(_plugConfig.inboundSwitchboard__),
            address(_plugConfig.outboundSwitchboard__),
            address(_plugConfig.capacitor__),
            address(_plugConfig.decapacitor__)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IPlug.sol";
import "./SocketBase.sol";

/**
 * @title SocketDst
 * @dev SocketDst is an abstract contract that inherits from SocketBase and
 * provides additional functionality for message execution, packet proposal, and verification.
 * It manages the mapping of message execution status, packet ID roots, and root proposed
 * timestamps. It emits events for packet proposal and root updates.
 * It also includes functions for message execution and verification, as well as a function
 * to check if a packet has been proposed.
 */
abstract contract SocketDst is SocketBase {
    /*
     * @dev Error emitted when a packet has not been proposed
     */
    error PacketNotProposed();
    /*
     * @dev Error emitted when a packet id is invalid
     */
    error InvalidPacketId();

    /**
     * @dev Error emitted when proof is invalid
     */
    error InvalidProof();

    /**
     * @dev Error emitted when a message has already been executed
     */
    error MessageAlreadyExecuted();
    /**
     * @dev Error emitted when the attester is not valid
     */
    error NotExecutor();
    /**
     * @dev Error emitted when verification fails
     */
    error VerificationFailed();
    /**
     * @dev Error emitted when source slugs deduced from packet id and msg id don't match
     */
    error ErrInSourceValidation();
    /**
     * @dev Error emitted when less gas limit is provided for execution than expected
     */
    error LowGasLimit();

    /**
     * @dev msgId => message status mapping
     */
    mapping(bytes32 => bool) public messageExecuted;
    /**
     * @dev capacitorAddr|chainSlug|packetId => proposalCount => switchboard => packetIdRoots
     */
    mapping(bytes32 => mapping(uint256 => mapping(address => bytes32)))
        public
        override packetIdRoots;
    /**
     * @dev packetId => proposalCount => switchboard => proposalTimestamp
     */
    mapping(bytes32 => mapping(uint256 => mapping(address => uint256)))
        public rootProposedAt;

    /**
     * @dev packetId => proposalCount
     */
    mapping(bytes32 => uint256) public proposalCount;

    /**
     * @notice emits the packet details when proposed at remote
     * @param transmitter address of transmitter
     * @param packetId packet id
     * @param proposalCount proposal id
     * @param root packet root
     */
    event PacketProposed(
        address indexed transmitter,
        bytes32 indexed packetId,
        uint256 proposalCount,
        bytes32 root,
        address switchboard
    );

    /**
     * @dev Function to propose a packet
     * @notice the signature is validated if it belongs to transmitter or not
     * @param packetId_ packet id
     * @param root_ packet root
     * @param switchboard_ The address of switchboard for which this packet is proposed
     * @param signature_ signature
     */
    function proposeForSwitchboard(
        bytes32 packetId_,
        bytes32 root_,
        address switchboard_,
        bytes calldata signature_
    ) external payable override {
        if (packetId_ == bytes32(0)) revert InvalidPacketId();

        (address transmitter, bool isTransmitter) = transmitManager__
            .checkTransmitter(
                uint32(_decodeSlug(packetId_)),
                keccak256(abi.encode(version, chainSlug, packetId_, root_)),
                signature_
            );

        if (!isTransmitter) revert InvalidTransmitter();

        packetIdRoots[packetId_][proposalCount[packetId_]][
            switchboard_
        ] = root_;
        rootProposedAt[packetId_][proposalCount[packetId_]][
            switchboard_
        ] = block.timestamp;

        emit PacketProposed(
            transmitter,
            packetId_,
            proposalCount[packetId_]++,
            root_,
            switchboard_
        );
    }

    /**
     * @notice executes a message, fees will go to recovered executor address
     * @param executionDetails_ the packet details, proof and signature needed for message execution
     * @param messageDetails_ the details needed for message verification
     */
    function execute(
        ISocket.ExecutionDetails calldata executionDetails_,
        ISocket.MessageDetails calldata messageDetails_
    ) external payable override {
        if (messageExecuted[messageDetails_.msgId])
            revert MessageAlreadyExecuted();
        messageExecuted[messageDetails_.msgId] = true;

        if (
            executionDetails_.executionGasLimit < messageDetails_.minMsgGasLimit
        ) revert LowGasLimit();

        if (executionDetails_.packetId == bytes32(0)) revert InvalidPacketId();

        uint32 remoteSlug = _decodeSlug(messageDetails_.msgId);
        if (_decodeSlug(executionDetails_.packetId) != remoteSlug)
            revert ErrInSourceValidation();

        address localPlug = _decodePlug(messageDetails_.msgId);

        PlugConfig memory plugConfig;
        plugConfig.decapacitor__ = _plugConfigs[localPlug][remoteSlug]
            .decapacitor__;
        plugConfig.siblingPlug = _plugConfigs[localPlug][remoteSlug]
            .siblingPlug;
        plugConfig.inboundSwitchboard__ = _plugConfigs[localPlug][remoteSlug]
            .inboundSwitchboard__;

        bytes32 packetRoot = packetIdRoots[executionDetails_.packetId][
            executionDetails_.proposalCount
        ][address(plugConfig.inboundSwitchboard__)];
        if (packetRoot == bytes32(0)) revert PacketNotProposed();

        bytes32 packedMessage = hasher__.packMessage(
            remoteSlug,
            plugConfig.siblingPlug,
            chainSlug,
            localPlug,
            messageDetails_
        );

        (address executor, bool isValidExecutor) = executionManager__
            .isExecutor(packedMessage, executionDetails_.signature);
        if (!isValidExecutor) revert NotExecutor();

        _verify(
            executionDetails_.packetId,
            executionDetails_.proposalCount,
            remoteSlug,
            packedMessage,
            packetRoot,
            plugConfig,
            executionDetails_.decapacitorProof,
            messageDetails_.executionParams
        );
        _execute(
            executor,
            localPlug,
            remoteSlug,
            executionDetails_.executionGasLimit,
            messageDetails_
        );
    }

    function _verify(
        bytes32 packetId_,
        uint256 proposalCount_,
        uint32 remoteChainSlug_,
        bytes32 packedMessage_,
        bytes32 packetRoot_,
        PlugConfig memory plugConfig_,
        bytes memory decapacitorProof_,
        bytes32 executionParams_
    ) internal {
        if (
            !ISwitchboard(plugConfig_.inboundSwitchboard__).allowPacket(
                packetRoot_,
                packetId_,
                proposalCount_,
                uint32(remoteChainSlug_),
                rootProposedAt[packetId_][proposalCount_][
                    address(plugConfig_.inboundSwitchboard__)
                ]
            )
        ) revert VerificationFailed();

        if (
            !plugConfig_.decapacitor__.verifyMessageInclusion(
                packetRoot_,
                packedMessage_,
                decapacitorProof_
            )
        ) revert InvalidProof();

        executionManager__.verifyParams(executionParams_, msg.value);
    }

    /**
     * This function assumes localPlug_ will have code while executing. As the message
     * execution failure is not blocking the system, it is not necessary to check if
     * code exists in the given address.
     * @dev distribution of msg.value in case of inbound failure is to be decided.
     */
    function _execute(
        address executor_,
        address localPlug_,
        uint32 remoteChainSlug_,
        uint256 executionGasLimit_,
        ISocket.MessageDetails memory messageDetails_
    ) internal {
        IPlug(localPlug_).inbound{gas: executionGasLimit_, value: msg.value}(
            remoteChainSlug_,
            messageDetails_.payload
        );

        executionManager__.updateExecutionFees(
            executor_,
            uint128(messageDetails_.executionFee),
            messageDetails_.msgId
        );
        emit ExecutionSuccess(messageDetails_.msgId);
    }

    /**
     * @dev Checks whether the specified packet has been proposed.
     * @param packetId_ The ID of the packet to check.
     * @param proposalCount_ The proposal ID of the packetId to check.
     * @param switchboard_ The address of switchboard for which this packet is proposed
     * @return A boolean indicating whether the packet has been proposed or not.
     */
    function isPacketProposed(
        bytes32 packetId_,
        uint256 proposalCount_,
        address switchboard_
    ) external view returns (bool) {
        return
            packetIdRoots[packetId_][proposalCount_][switchboard_] == bytes32(0)
                ? false
                : true;
    }

    /**
     * @dev Decodes the plug address from a given message id.
     * @param id_ The ID of the msg to decode the plug from.
     * @return plug_ The address of sibling plug decoded from the message ID.
     */
    function _decodePlug(bytes32 id_) internal pure returns (address plug_) {
        plug_ = address(uint160(uint256(id_) >> 64));
    }

    /**
     * @dev Decodes the chain ID from a given packet/message ID.
     * @param id_ The ID of the packet/msg to decode the chain slug from.
     * @return chainSlug_ The chain slug decoded from the packet/message ID.
     */
    function _decodeSlug(
        bytes32 id_
    ) internal pure returns (uint32 chainSlug_) {
        chainSlug_ = uint32(uint256(id_) >> 224);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./SocketBase.sol";

/**
 * @title SocketSrc
 * @dev The SocketSrc contract inherits from SocketBase and provides the functionality
 * to send messages from the local chain to a remote chain via a capacitor, estimate min fees
 * and allow transmitters to seal packets for a path.
 */
abstract contract SocketSrc is SocketBase {
    // triggered when fees is not sufficient at outbound
    error InsufficientFees();
    // triggered when an invalid capacitor address is used for sealing
    error InvalidCapacitor();

    /**
     * @notice emits the verification and seal confirmation of a packet
     * @param transmitter address of transmitter recovered from sig
     * @param packetId packed packet id
     * @param root root
     * @param signature signature of attester
     */
    event PacketVerifiedAndSealed(
        address indexed transmitter,
        bytes32 indexed packetId,
        bytes32 root,
        bytes signature
    );

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param siblingChainSlug_ the remote chain slug
     * @param minMsgGasLimit_ the gas limit needed to execute the payload on remote
     * @param executionParams_ a 32 bytes param to add extra details for execution
     * @param transmissionParams_ a 32 bytes param to add extra details for transmission
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint32 siblingChainSlug_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes calldata payload_
    ) external payable override returns (bytes32 msgId) {
        PlugConfig memory plugConfig;

        plugConfig.siblingPlug = _plugConfigs[msg.sender][siblingChainSlug_]
            .siblingPlug;
        plugConfig.capacitor__ = _plugConfigs[msg.sender][siblingChainSlug_]
            .capacitor__;
        plugConfig.outboundSwitchboard__ = _plugConfigs[msg.sender][
            siblingChainSlug_
        ].outboundSwitchboard__;

        msgId = _encodeMsgId(plugConfig.siblingPlug);

        // all the fees is transferred to execution manager and stored mapped to their addresses
        // transmit manager and switchboards can pull the fees from there
        // only external call is where we get min switchboard fees
        ISocket.Fees memory fees = _validateAndSendFees(
            minMsgGasLimit_,
            uint256(payload_.length),
            executionParams_,
            transmissionParams_,
            plugConfig.outboundSwitchboard__,
            plugConfig.capacitor__.getMaxPacketLength(),
            siblingChainSlug_
        );

        ISocket.MessageDetails memory messageDetails = ISocket.MessageDetails({
            msgId: msgId,
            minMsgGasLimit: minMsgGasLimit_,
            executionParams: executionParams_,
            payload: payload_,
            executionFee: fees.executionFee
        });

        // this packed message can be re-created if socket is redeployed with a new version
        // it is plug's responsibility to have proper checks in functions interacting
        // with socket to validate who has access to the contract at inbound
        bytes32 packedMessage = hasher__.packMessage(
            chainSlug,
            msg.sender,
            siblingChainSlug_,
            plugConfig.siblingPlug,
            messageDetails
        );

        plugConfig.capacitor__.addPackedMessage(packedMessage);

        emit MessageOutbound(
            chainSlug,
            msg.sender,
            siblingChainSlug_,
            plugConfig.siblingPlug,
            msgId,
            minMsgGasLimit_,
            executionParams_,
            transmissionParams_,
            payload_,
            fees
        );
    }

    /**
     * @notice Validates if enough fee is provided for message execution. If yes, fees is sent and stored in execution manager.
     * @param minMsgGasLimit_ The gas limit of the message.
     * @param payloadSize_ The byte length of payload of the message.
     * @param executionParams_ The extraParams required for execution.
     * @param transmissionParams_ The extraParams required for transmission.
     * @param switchboard_ The address of the switchboard through which the message is sent.
     * @param maxPacketLength_ The maxPacketLength for the capacitor used. Used for calculating transmission Fees.
     * @param siblingChainSlug_ The slug of the destination chain for the message.
     */
    function _validateAndSendFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        ISwitchboard switchboard_,
        uint256 maxPacketLength_,
        uint32 siblingChainSlug_
    ) internal returns (ISocket.Fees memory fees) {
        uint128 verificationFees;
        (fees.switchboardFees, verificationFees) = _getSwitchboardMinFees(
            siblingChainSlug_,
            switchboard_
        );

        // verificationFee is per message, so no need to divide by maxPacketLength
        (fees.executionFee, fees.transmissionFees) = executionManager__
            .payAndCheckFees{value: msg.value}(
            minMsgGasLimit_,
            payloadSize_,
            executionParams_,
            transmissionParams_,
            siblingChainSlug_,
            fees.switchboardFees / uint128(maxPacketLength_),
            verificationFees,
            address(transmitManager__),
            address(switchboard_),
            maxPacketLength_
        );
    }

    /**
     * @notice Retrieves the minimum fees required for a message with a specified gas limit and destination chain.
     * @param minMsgGasLimit_ The gas limit of the message.
     * @param payloadSize_ The byte length of payload of the message.
     * @param executionParams_ The extraParams required for execution.
     * @param siblingChainSlug_ The slug of the destination chain for the message.
     * @param plug_ The address of the plug through which the message is sent.
     * @return totalFees The minimum fees required for the specified message.
     */
    function getMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        uint32 siblingChainSlug_,
        address plug_
    ) external view override returns (uint256 totalFees) {
        ICapacitor capacitor__ = _plugConfigs[plug_][siblingChainSlug_]
            .capacitor__;
        uint256 maxPacketLength = capacitor__.getMaxPacketLength();
        (
            uint128 transmissionFees,
            uint128 switchboardFees,
            uint128 executionFees
        ) = _getAllMinFees(
                minMsgGasLimit_,
                payloadSize_,
                executionParams_,
                transmissionParams_,
                siblingChainSlug_,
                _plugConfigs[plug_][siblingChainSlug_].outboundSwitchboard__,
                maxPacketLength
            );
        totalFees = transmissionFees + switchboardFees + executionFees;
    }

    /**
     * @notice Retrieves the minimum fees required for switchboard.
     * @param siblingChainSlug_ The slug of the destination chain for the message.
     * @param switchboard__ The switchboard address for which fees is retrieved.
     * @return switchboardFees , verificationFees The minimum fees required for message execution
     */
    function _getSwitchboardMinFees(
        uint32 siblingChainSlug_,
        ISwitchboard switchboard__
    )
        internal
        view
        returns (uint128 switchboardFees, uint128 verificationFees)
    {
        (switchboardFees, verificationFees) = switchboard__.getMinFees(
            siblingChainSlug_
        );
    }

    /**
     * @notice Retrieves the minimum fees required for a message with a specified gas limit and destination chain.
     * @param minMsgGasLimit_ The gas limit of the message.
     * @param payloadSize_ The byte length of payload of the message.
     * @param executionParams_ The extraParams required for execution.
     * @param siblingChainSlug_ The slug of the destination chain for the message.
     * @param switchboard__ The address of the switchboard through which the message is sent.
     */
    function _getAllMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        uint32 siblingChainSlug_,
        ISwitchboard switchboard__,
        uint256 maxPacketLength_
    )
        internal
        view
        returns (
            uint128 transmissionFees,
            uint128 switchboardFees,
            uint128 executionFees
        )
    {
        uint128 verificationFees;
        uint128 msgExecutionFee;
        (switchboardFees, verificationFees) = _getSwitchboardMinFees(
            siblingChainSlug_,
            switchboard__
        );
        switchboardFees /= uint128(maxPacketLength_);
        (msgExecutionFee, transmissionFees) = executionManager__
            .getExecutionTransmissionMinFees(
                minMsgGasLimit_,
                payloadSize_,
                executionParams_,
                transmissionParams_,
                siblingChainSlug_,
                address(transmitManager__)
            );

        transmissionFees /= uint128(maxPacketLength_);
        executionFees = msgExecutionFee + verificationFees;
    }

    /**
     * @notice seals data in capacitor for specific batchSize
     * @param batchSize_ size of batch to be sealed
     * @param capacitorAddress_ address of capacitor
     * @param signature_ signed Data needed for verification
     */
    function seal(
        uint256 batchSize_,
        address capacitorAddress_,
        bytes calldata signature_
    ) external payable override {
        uint32 siblingChainSlug = capacitorToSlug[capacitorAddress_];
        if (siblingChainSlug == 0) revert InvalidCapacitor();

        (bytes32 root, uint64 packetCount) = ICapacitor(capacitorAddress_)
            .sealPacket(batchSize_);

        bytes32 packetId = _encodePacketId(capacitorAddress_, packetCount);
        (address transmitter, bool isTransmitter) = transmitManager__
            .checkTransmitter(
                siblingChainSlug,
                keccak256(
                    abi.encode(version, siblingChainSlug, packetId, root)
                ),
                signature_
            );

        if (!isTransmitter) revert InvalidTransmitter();
        emit PacketVerifiedAndSealed(transmitter, packetId, root, signature_);
    }

    // Packs the local plug, local chain slug, remote chain slug and nonce
    // globalMessageCount++ will take care of msg id overflow as well
    // msgId(256) = localChainSlug(32) | siblingPlug_(160) | nonce(64)
    function _encodeMsgId(address siblingPlug_) internal returns (bytes32) {
        return
            bytes32(
                (uint256(chainSlug) << 224) |
                    (uint256(uint160(siblingPlug_)) << 64) |
                    globalMessageCount++
            );
    }

    function _encodePacketId(
        address capacitorAddress_,
        uint64 packetCount_
    ) internal view returns (bytes32) {
        return
            bytes32(
                (uint256(chainSlug) << 224) |
                    (uint256(uint160(capacitorAddress_)) << 64) |
                    packetCount_
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./SwitchboardBase.sol";

/**
 * @title FastSwitchboard contract
 * @dev This contract implements a fast version of the SwitchboardBase contract
 * that enables packet attestations and watchers registration.
 */
contract FastSwitchboard is SwitchboardBase {
    // mapping to store if root is valid
    mapping(bytes32 => bool) public isRootValid;

    // dst chain slug => total watchers registered
    mapping(uint32 => uint256) public totalWatchers;

    // attester => root => is attested
    mapping(address => mapping(bytes32 => bool)) public isAttested;

    // root => total attestations
    // @dev : (assuming here that root will be unique across system)
    mapping(bytes32 => uint256) public attestations;

    // Event emitted when a new socket is set
    event SocketSet(address newSocket);
    // Event emitted when a root is attested
    event ProposalAttested(
        bytes32 packetId,
        uint256 proposalCount,
        bytes32 root,
        address attester,
        uint256 attestationsCount
    );

    // Error emitted when a watcher is found
    error WatcherFound();
    // Error emitted when a watcher is not found
    error WatcherNotFound();
    // Error emitted when a root is already attested
    error AlreadyAttested();
    // Error emitted when role is invalid
    error InvalidRole();

    // Error emitted when role is invalid
    error InvalidRoot();

    /**
     * @dev Constructor function for the FastSwitchboard contract
     * @param owner_ Address of the owner of the contract
     * @param socket_ Address of the socket contract
     * @param chainSlug_ Chain slug of the chain where the contract is deployed
     * @param timeoutInSeconds_ Timeout in seconds for the packets
     * @param signatureVerifier_ The address of the signature verifier contract
     */
    constructor(
        address owner_,
        address socket_,
        uint32 chainSlug_,
        uint256 timeoutInSeconds_,
        ISignatureVerifier signatureVerifier_
    )
        AccessControlExtended(owner_)
        SwitchboardBase(
            socket_,
            chainSlug_,
            timeoutInSeconds_,
            signatureVerifier_
        )
    {}

    /**
     * @dev Function to attest a packet
     * @param packetId_ Packet ID
     * @param proposalCount_ Proposal ID
     * @param root_ Root of the packet
     * @param signature_ Signature of the packet
     * @notice we are attesting a root uniquely identified with packetId and proposalCount. However,
     * there can be multiple proposals for same root. To avoid need to re-attest for different proposals
     *  with same root, we are storing attestations against root instead of packetId and proposalCount.
     */
    function attest(
        bytes32 packetId_,
        uint256 proposalCount_,
        bytes32 root_,
        bytes calldata signature_
    ) external {
        uint32 srcChainSlug = uint32(uint256(packetId_) >> 224);

        bytes32 root = socket__.packetIdRoots(
            packetId_,
            proposalCount_,
            address(this)
        );
        if (root == bytes32(0)) revert InvalidRoot();
        if (root != root_) revert InvalidRoot();

        address watcher = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(address(this), chainSlug, packetId_, proposalCount_)
            ),
            signature_
        );

        if (isAttested[watcher][root]) revert AlreadyAttested();
        if (!_hasRoleWithSlug(WATCHER_ROLE, srcChainSlug, watcher))
            revert WatcherNotFound();

        isAttested[watcher][root] = true;
        ++attestations[root];

        if (attestations[root] >= totalWatchers[srcChainSlug])
            isRootValid[root] = true;

        emit ProposalAttested(
            packetId_,
            proposalCount_,
            root,
            watcher,
            attestations[root]
        );
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function setFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint128 switchboardFees_,
        uint128 verificationFees_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(
                    FEES_UPDATE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    dstChainSlug_,
                    nonce_,
                    switchboardFees_,
                    verificationFees_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, dstChainSlug_, feesUpdater);
        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[feesUpdater]++) revert InvalidNonce();
        }
        Fees memory feesObject = Fees({
            switchboardFees: switchboardFees_ *
                uint128(totalWatchers[dstChainSlug_]),
            verificationFees: verificationFees_
        });

        fees[dstChainSlug_] = feesObject;
        emit SwitchboardFeesSet(dstChainSlug_, feesObject);
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function allowPacket(
        bytes32 root_,
        bytes32 packetId_,
        uint256 proposalCount_,
        uint32 srcChainSlug_,
        uint256 proposeTime_
    ) external view override returns (bool) {
        uint64 packetCount = uint64(uint256(packetId_));

        if (
            tripGlobalFuse ||
            tripSinglePath[srcChainSlug_] ||
            isProposalTripped[packetId_][proposalCount_] ||
            packetCount < initialPacketCount[srcChainSlug_]
        ) return false;
        if (isRootValid[root_]) return true;
        if (block.timestamp - proposeTime_ > timeoutInSeconds) return true;
        return false;
    }

    /**
     * @notice adds a watcher for `srcChainSlug_` chain
     * @param srcChainSlug_ chain slug of the chain where the watcher is being added
     * @param watcher_ watcher address
     */
    function grantWatcherRole(
        uint32 srcChainSlug_,
        address watcher_
    ) external onlyRole(GOVERNANCE_ROLE) {
        if (_hasRoleWithSlug(WATCHER_ROLE, srcChainSlug_, watcher_))
            revert WatcherFound();
        _grantRoleWithSlug(WATCHER_ROLE, srcChainSlug_, watcher_);

        Fees storage fees = fees[srcChainSlug_];
        uint128 watchersBefore = uint128(totalWatchers[srcChainSlug_]);
        if (watchersBefore != 0 && fees.switchboardFees != 0)
            fees.switchboardFees =
                (fees.switchboardFees * (watchersBefore + 1)) /
                watchersBefore;

        ++totalWatchers[srcChainSlug_];
    }

    /**
     * @notice removes a watcher from `srcChainSlug_` chain list
     * @param srcChainSlug_ chain slug of the chain where the watcher is being removed
     * @param watcher_ watcher address
     */
    function revokeWatcherRole(
        uint32 srcChainSlug_,
        address watcher_
    ) external onlyRole(GOVERNANCE_ROLE) {
        if (!_hasRoleWithSlug(WATCHER_ROLE, srcChainSlug_, watcher_))
            revert WatcherNotFound();
        _revokeRoleWithSlug(WATCHER_ROLE, srcChainSlug_, watcher_);

        Fees storage fees = fees[srcChainSlug_];
        uint128 watchersBefore = uint128(totalWatchers[srcChainSlug_]);

        if (watchersBefore > 1 && fees.switchboardFees != 0)
            fees.switchboardFees =
                (fees.switchboardFees * (watchersBefore - 1)) /
                watchersBefore;

        totalWatchers[srcChainSlug_]--;
    }

    /**
     * @notice returns true if non watcher role. Used to avoid granting watcher role directly
     * @dev If adding any new role to FastSwitchboard, have to add it here as well to make sure it can be set
     */
    function isNonWatcherRole(bytes32 role_) public pure returns (bool) {
        if (
            role_ == TRIP_ROLE ||
            role_ == UN_TRIP_ROLE ||
            role_ == WITHDRAW_ROLE ||
            role_ == RESCUE_ROLE ||
            role_ == GOVERNANCE_ROLE ||
            role_ == FEES_UPDATER_ROLE
        ) return true;

        return false;
    }

    /**
     * @dev Overriding this function from AccessControl to make sure owner can't grant Watcher Role directly, and should
     * only use grantWatcherRole function instead. This is to make sure watcher count remains correct
     */
    function grantRole(
        bytes32 role_,
        address grantee_
    ) external override onlyOwner {
        if (isNonWatcherRole(role_)) {
            _grantRole(role_, grantee_);
        } else {
            revert InvalidRole();
        }
    }

    /**
     * @dev Overriding this function from AccessControlExtended to make sure owner can't grant Watcher Role directly, and should
     * only use grantWatcherRole function instead. This is to make sure watcher count remains correct
     */
    function grantRoleWithSlug(
        bytes32 roleName_,
        uint32 chainSlug_,
        address grantee_
    ) external override onlyOwner {
        if (roleName_ != FEES_UPDATER_ROLE) revert InvalidRole();
        _grantRoleWithSlug(roleName_, chainSlug_, grantee_);
    }

    /**
     * @dev Overriding this function from AccessControl to make sure owner can't revoke Watcher Role directly, and should
     * only use revokeWatcherRole function instead. This is to make sure watcher count remains correct
     */
    function revokeRole(
        bytes32 role_,
        address grantee_
    ) external override onlyOwner {
        if (isNonWatcherRole(role_)) {
            _revokeRole(role_, grantee_);
        } else {
            revert InvalidRole();
        }
    }

    /**
     * @dev Overriding this function from AccessControlExtended to make sure owner can't revoke Watcher Role directly, and should
     * only use revokeWatcherRole function instead. This is to make sure watcher count remains correct
     */
    function revokeRoleWithSlug(
        bytes32 roleName_,
        uint32 chainSlug_,
        address grantee_
    ) external override onlyOwner {
        if (roleName_ != FEES_UPDATER_ROLE) revert InvalidRole();
        _revokeRoleWithSlug(roleName_, chainSlug_, grantee_);
    }

    /**
     * @dev Overriding this function from AccessControlExtended to make sure owner can't grant Watcher Role directly, and should
     * only use grantWatcherRole function instead. This is to make sure watcher count remains correct
     */
    function grantBatchRole(
        bytes32[] calldata roleNames_,
        uint32[] calldata slugs_,
        address[] calldata grantees_
    ) external override onlyOwner {
        if (
            roleNames_.length != grantees_.length ||
            roleNames_.length != slugs_.length
        ) revert UnequalArrayLengths();

        uint256 totalRoles = roleNames_.length;
        for (uint256 index = 0; index < totalRoles; ) {
            if (isNonWatcherRole(roleNames_[index])) {
                if (slugs_[index] > 0)
                    _grantRoleWithSlug(
                        roleNames_[index],
                        slugs_[index],
                        grantees_[index]
                    );
                else _grantRole(roleNames_[index], grantees_[index]);
            } else {
                revert InvalidRole();
            }
            // we will reach block gas limit before this overflows
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @dev Overriding this function from AccessControlExtended to make sure owner can't revoke Watcher Role directly, and should
     * only use revokeWatcherRole function instead. This is to make sure watcher count remains correct
     */
    function revokeBatchRole(
        bytes32[] calldata roleNames_,
        uint32[] calldata slugs_,
        address[] calldata grantees_
    ) external override onlyOwner {
        if (
            roleNames_.length != grantees_.length ||
            roleNames_.length != slugs_.length
        ) revert UnequalArrayLengths();
        uint256 totalRoles = roleNames_.length;
        for (uint256 index = 0; index < totalRoles; ) {
            if (isNonWatcherRole(roleNames_[index])) {
                if (slugs_[index] > 0)
                    _revokeRoleWithSlug(
                        roleNames_[index],
                        slugs_[index],
                        grantees_[index]
                    );
                else _revokeRole(roleNames_[index], grantees_[index]);
            } else {
                revert InvalidRole();
            }
            // we will reach block gas limit before this overflows
            unchecked {
                ++index;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./SwitchboardBase.sol";

/**
 * @title OptimisticSwitchboard
 * @notice A contract that extends the SwitchboardBase contract and implements the
 * allowPacket and fee getter functions.
 */
contract OptimisticSwitchboard is SwitchboardBase {
    /**
     * @notice Creates an OptimisticSwitchboard instance with the specified parameters.
     * @param owner_ The address of the contract owner.
     * @param socket_ The address of the socket contract.
     * @param chainSlug_ The chain slug.
     * @param timeoutInSeconds_ The timeout period in seconds.
     * @param signatureVerifier_ The address of the signature verifier contract
     */
    constructor(
        address owner_,
        address socket_,
        uint32 chainSlug_,
        uint256 timeoutInSeconds_,
        ISignatureVerifier signatureVerifier_
    )
        AccessControlExtended(owner_)
        SwitchboardBase(
            socket_,
            chainSlug_,
            timeoutInSeconds_,
            signatureVerifier_
        )
    {}

    /**
     * @inheritdoc ISwitchboard
     */
    function allowPacket(
        bytes32,
        bytes32 packetId_,
        uint256 proposalCount_,
        uint32 srcChainSlug_,
        uint256 proposeTime_
    ) external view override returns (bool) {
        uint64 packetCount = uint64(uint256(packetId_));

        if (
            tripGlobalFuse ||
            tripSinglePath[srcChainSlug_] ||
            isProposalTripped[packetId_][proposalCount_] ||
            packetCount < initialPacketCount[srcChainSlug_]
        ) return false;
        if (block.timestamp - proposeTime_ < timeoutInSeconds) return false;
        return true;
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function setFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint128,
        uint128 verificationFees_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(
                    FEES_UPDATE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    dstChainSlug_,
                    nonce_,
                    0,
                    verificationFees_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, dstChainSlug_, feesUpdater);
        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[feesUpdater]++) revert InvalidNonce();
        }

        fees[dstChainSlug_].verificationFees = verificationFees_;
        emit SwitchboardFeesSet(dstChainSlug_, fees[dstChainSlug_]);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../../interfaces/ISocket.sol";
import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/ISignatureVerifier.sol";
import "../../utils/AccessControlExtended.sol";
import "../../libraries/RescueFundsLib.sol";

import {GOVERNANCE_ROLE, WITHDRAW_ROLE, RESCUE_ROLE, TRIP_ROLE, UN_TRIP_ROLE, WATCHER_ROLE, FEES_UPDATER_ROLE} from "../../utils/AccessRoles.sol";
import {TRIP_PATH_SIG_IDENTIFIER, TRIP_GLOBAL_SIG_IDENTIFIER, TRIP_PROPOSAL_SIG_IDENTIFIER, UN_TRIP_PATH_SIG_IDENTIFIER, UN_TRIP_GLOBAL_SIG_IDENTIFIER, FEES_UPDATE_SIG_IDENTIFIER} from "../../utils/SigIdentifiers.sol";

abstract contract SwitchboardBase is ISwitchboard, AccessControlExtended {
    ISignatureVerifier public immutable signatureVerifier__;
    ISocket public immutable socket__;

    uint32 public immutable chainSlug;
    uint256 public immutable timeoutInSeconds;

    bool public tripGlobalFuse;
    struct Fees {
        uint128 switchboardFees;
        uint128 verificationFees;
    }

    // sourceChain => isPaused
    mapping(uint32 => bool) public tripSinglePath;

    // isProposalTripped(packetId => proposalCount => isTripped)
    mapping(bytes32 => mapping(uint256 => bool)) public isProposalTripped;

    // watcher => nextNonce
    mapping(address => uint256) public nextNonce;

    // destinationChainSlug => fees-struct with verificationFees and switchboardFees
    mapping(uint32 => Fees) public fees;

    // destinationChainSlug => initialPacketCount - packets with  packetCount after this will be accepted at the switchboard.
    // This is to prevent attacks with sending messages for chain slugs before the switchboard is registered for them.
    mapping(uint32 => uint256) public initialPacketCount;

    /**
     * @dev Emitted when a path is tripped
     * @param srcChainSlug Chain slug of the source chain
     * @param tripSinglePath New trip status of the path
     */
    event PathTripped(uint32 srcChainSlug, bool tripSinglePath);

    /**
     * @dev Emitted when a proposal for a packetId is tripped
     * @param packetId packetId of packet
     * @param proposalCount proposalCount being tripped
     */
    event ProposalTripped(bytes32 packetId, uint256 proposalCount);

    /**
     * @dev Emitted when Switchboard contract is tripped globally
     * @param tripGlobalFuse New trip status of the contract
     */

    event SwitchboardTripped(bool tripGlobalFuse);
    /**
     * @dev Emitted when execution overhead is set for a destination chain
     * @param dstChainSlug Chain slug of the destination chain
     * @param executionOverhead New execution overhead
     */
    event ExecutionOverheadSet(uint32 dstChainSlug, uint256 executionOverhead);

    /**
     * @dev Emitted when a fees is set for switchboard
     * @param siblingChainSlug Chain slug of the sibling chain
     * @param fees fees struct with verificationFees and switchboardFees
     */
    event SwitchboardFeesSet(uint32 siblingChainSlug, Fees fees);

    error InvalidNonce();

    /**
     * @dev Constructor of SwitchboardBase
     * @param socket_ Address of the socket contract
     * @param chainSlug_ Chain slug of the contract
     * @param timeoutInSeconds_ Timeout duration of the transactions
     * @param signatureVerifier_ signatureVerifier_ contract
     */
    constructor(
        address socket_,
        uint32 chainSlug_,
        uint256 timeoutInSeconds_,
        ISignatureVerifier signatureVerifier_
    ) {
        socket__ = ISocket(socket_);
        chainSlug = chainSlug_;
        timeoutInSeconds = timeoutInSeconds_;
        signatureVerifier__ = signatureVerifier_;
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function getMinFees(
        uint32 dstChainSlug_
    ) external view override returns (uint128, uint128) {
        Fees memory minFees = fees[dstChainSlug_];
        return (minFees.switchboardFees, minFees.verificationFees);
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function registerSiblingSlug(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_,
        uint256 initialPacketCount_,
        address siblingSwitchboard_
    ) external override onlyRole(GOVERNANCE_ROLE) {
        initialPacketCount[siblingChainSlug_] = initialPacketCount_;

        socket__.registerSwitchboardForSibling(
            siblingChainSlug_,
            maxPacketLength_,
            capacitorType_,
            siblingSwitchboard_
        );
    }

    /**
     * @notice Updates the sibling switchboard for given `siblingChainSlug_`.
     * @dev This function is expected to be only called by admin
     * @param siblingChainSlug_ The slug of the sibling chain to register switchboard with.
     * @param siblingSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function updateSibling(
        uint32 siblingChainSlug_,
        address siblingSwitchboard_
    ) external onlyRole(GOVERNANCE_ROLE) {
        socket__.useSiblingSwitchboard(siblingChainSlug_, siblingSwitchboard_);
    }

    /**
     * @notice Pauses a path.
     * @param nonce_ The nonce used for the trip transaction.
     * @param srcChainSlug_ The source chain slug of the path to be paused.
     * @param signature_ The signature provided to validate the trip transaction.
     */
    function tripPath(
        uint256 nonce_,
        uint32 srcChainSlug_,
        bytes memory signature_
    ) external {
        address watcher = signatureVerifier__.recoverSigner(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    TRIP_PATH_SIG_IDENTIFIER,
                    address(this),
                    srcChainSlug_,
                    chainSlug,
                    nonce_,
                    true
                )
            ),
            signature_
        );

        _checkRoleWithSlug(WATCHER_ROLE, srcChainSlug_, watcher);

        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[watcher]++) revert InvalidNonce();
        }
        //source chain based tripping
        tripSinglePath[srcChainSlug_] = true;
        emit PathTripped(srcChainSlug_, true);
    }

    /**
     * @notice Pauses a particular proposal of a packet.
     * @param nonce_ The nonce used for the trip transaction.
     * @param packetId_ The ID of the packet.
     * @param proposalCount_ The count of the proposal to be paused.
     * @param signature_ The signature provided to validate the trip transaction.
     */
    function tripProposal(
        uint256 nonce_,
        bytes32 packetId_,
        uint256 proposalCount_,
        bytes memory signature_
    ) external {
        uint32 srcChainSlug = uint32(uint256(packetId_) >> 224);
        address watcher = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(
                    TRIP_PROPOSAL_SIG_IDENTIFIER,
                    address(this),
                    srcChainSlug,
                    chainSlug,
                    nonce_,
                    packetId_,
                    proposalCount_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(WATCHER_ROLE, srcChainSlug, watcher);
        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[watcher]++) revert InvalidNonce();
        }

        isProposalTripped[packetId_][proposalCount_] = true;
        emit ProposalTripped(packetId_, proposalCount_);
    }

    /**
     * @notice Pauses global execution.
     * @param nonce_ The nonce used for the trip transaction.
     * @param signature_ The signature provided to validate the trip transaction.
     */
    function tripGlobal(uint256 nonce_, bytes memory signature_) external {
        address tripper = signatureVerifier__.recoverSigner(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    TRIP_GLOBAL_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    nonce_,
                    true
                )
            ),
            signature_
        );

        _checkRole(TRIP_ROLE, tripper);
        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[tripper]++) revert InvalidNonce();
        }
        tripGlobalFuse = true;
        emit SwitchboardTripped(true);
    }

    /**
     * @notice Unpauses a path.
     * @param nonce_ The nonce used for the un trip transaction.
     * @param srcChainSlug_ The source chain slug of the path to be unpaused.
     * @param signature_ The signature provided to validate the un trip transaction.
     */
    function unTripPath(
        uint256 nonce_,
        uint32 srcChainSlug_,
        bytes memory signature_
    ) external {
        address unTripper = signatureVerifier__.recoverSigner(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    UN_TRIP_PATH_SIG_IDENTIFIER,
                    address(this),
                    srcChainSlug_,
                    chainSlug,
                    nonce_,
                    false
                )
            ),
            signature_
        );

        _checkRole(UN_TRIP_ROLE, unTripper);
        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[unTripper]++) revert InvalidNonce();
        }
        tripSinglePath[srcChainSlug_] = false;
        emit PathTripped(srcChainSlug_, false);
    }

    /**
     * @notice Unpauses global execution.
     * @param nonce_ The nonce used for the un trip transaction.
     * @param signature_ The signature provided to validate the un trip transaction.
     */
    function unTrip(uint256 nonce_, bytes memory signature_) external {
        address unTripper = signatureVerifier__.recoverSigner(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    UN_TRIP_GLOBAL_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    nonce_,
                    false
                )
            ),
            signature_
        );

        _checkRole(UN_TRIP_ROLE, unTripper);

        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[unTripper]++) revert InvalidNonce();
        }
        tripGlobalFuse = false;
        emit SwitchboardTripped(false);
    }

    /**
     * @notice Withdraw fees from the contract to an account.
     * @param account_ The address where we should send the fees.
     */
    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        if (account_ == address(0)) revert ZeroAddress();
        SafeTransferLib.safeTransferETH(account_, address(this).balance);
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function receiveFees(uint32) external payable override {
        require(msg.sender == address(socket__.executionManager__()));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "lib/openzeppelin-contracts/contracts/vendor/arbitrum/IBridge.sol";
import "lib/openzeppelin-contracts/contracts/vendor/arbitrum/IInbox.sol";
import "lib/openzeppelin-contracts/contracts/vendor/arbitrum/IOutbox.sol";
import "./NativeSwitchboardBase.sol";

/**
 * @title ArbitrumL1Switchboard
 * @dev This contract is a switchboard contract for the Arbitrum chain that handles packet attestation
 * and actions on the L1 to Arbitrum and Arbitrum to L1 path.
 * This contract inherits base functions from NativeSwitchboardBase, including fee calculation,
 * trip and un trip actions, and limit setting functions.
 */
contract ArbitrumL1Switchboard is NativeSwitchboardBase {
    /**
     * @notice An interface for receiving incoming messages from the Arbitrum chain.
     */
    IInbox public inbox__;

    /**
     * @notice An interface for the Arbitrum-to-Ethereum bridge.
     */
    IBridge public bridge__;

    /**
     * @notice An interface for the Ethereum-to-Arbitrum outbox.
     */
    IOutbox public outbox__;

    /**
     * @notice Event emitted when the inbox address is updated.
     * @param inbox The new inbox address.
     */
    event UpdatedInboxAddress(address inbox);

    /**
     * @notice Event emitted when the bridge address is updated.
     * @param bridgeAddress The new bridge address.
     */
    event UpdatedBridge(address bridgeAddress);

    /**
     * @notice Event emitted when the outbox address is updated.
     * @param outboxAddress The new outbox address.
     */
    event UpdatedOutbox(address outboxAddress);

    /**
     * @notice Modifier that restricts access to the function to the remote switchboard.
     */
    modifier onlyRemoteSwitchboard() override {
        if (msg.sender != address(bridge__)) revert InvalidSender();
        address l2Sender = outbox__.l2ToL1Sender();
        if (l2Sender != remoteNativeSwitchboard) revert InvalidSender();
        _;
    }

    /**
     * @dev Constructor function for initializing the NativeBridge contract
     * @param chainSlug_ The identifier of the current chain in the system
     * @param inbox_ The address of the Arbitrum Inbox contract
     * @param owner_ The address of the owner of the NativeBridge contract
     * @param socket_ The address of the socket contract
     * @param bridge_ The address of the bridge contract
     * @param outbox_ The address of the Arbitrum Outbox contract
     */
    constructor(
        uint32 chainSlug_,
        address inbox_,
        address owner_,
        address socket_,
        address bridge_,
        address outbox_,
        ISignatureVerifier signatureVerifier_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(socket_, chainSlug_, signatureVerifier_)
    {
        inbox__ = IInbox(inbox_);

        bridge__ = IBridge(bridge_);
        outbox__ = IOutbox(outbox_);
    }

    /**
     * @notice This function is used to initiate a native confirmation.
     *         this is invoked in L1 to L2 and L2 to L1 paths
     *
     * @param packetId_ (bytes32) The ID of the packet to confirm.
     * @param maxSubmissionCost_ (uint256) The maximum submission cost for the retryable ticket.
     * @param maxGas_ (uint256) The maximum gas allowed for the retryable ticket.
     * @param gasPriceBid_ (uint256) The gas price bid for the retryable ticket.
     * @dev     encodes the remote call and creates a retryable ticket using the inbox__ contract.
     *          Finally, it emits the InitiatedNativeConfirmation event.
     */
    function initiateNativeConfirmation(
        bytes32 packetId_,
        uint256 maxSubmissionCost_,
        uint256 maxGas_,
        uint256 gasPriceBid_,
        address callValueRefundAddress_,
        address remoteRefundAddress_
    ) external payable {
        bytes memory data = _encodeRemoteCall(packetId_);

        inbox__.createRetryableTicket{value: msg.value}(
            remoteNativeSwitchboard,
            0, // no value needed for receivePacket
            maxSubmissionCost_,
            remoteRefundAddress_,
            callValueRefundAddress_,
            maxGas_,
            gasPriceBid_,
            data
        );

        emit InitiatedNativeConfirmation(packetId_);
    }

    /**
     * @notice This function is used to encode data to create retryableTicket on inbox
     * @param packetId_ (bytes32): The ID of the packet to confirm.
     * @return data encoded-data (packetId)
     * @dev  encodes the remote call used to create a retryable ticket using the inbox__ contract.
     */
    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encodeWithSelector(
            this.receivePacket.selector,
            packetId_,
            _getRoot(packetId_)
        );
    }

    /**
     * @notice updates the address of the inbox contract that is used to communicate with the Arbitrum Rollup.
     * @dev This function can only be called by a user with the GOVERNANCE_ROLE.
     * @param inbox_ address of new inbox to be updated
     */
    function updateInboxAddresses(
        address inbox_
    ) external onlyRole(GOVERNANCE_ROLE) {
        inbox__ = IInbox(inbox_);
        emit UpdatedInboxAddress(inbox_);
    }

    /**
     * @notice updates the address of the bridge contract that is used to communicate with the Arbitrum Rollup.
     * @dev This function can only be called by a user with the GOVERNANCE_ROLE.
     * @param bridgeAddress_ address of new bridge to be updated
     */
    function updateBridge(
        address bridgeAddress_
    ) external onlyRole(GOVERNANCE_ROLE) {
        bridge__ = IBridge(bridgeAddress_);

        emit UpdatedBridge(bridgeAddress_);
    }

    /**
     * @notice Updates the address of the outbox__ contract that this contract is configured to use.
     * @param outboxAddress_ The address of the new outbox__ contract to use.
     * @dev This function can only be called by an address with the GOVERNANCE_ROLE.
     * @dev Emits an UpdatedOutbox event with the updated outboxAddress_.
     */
    function updateOutbox(
        address outboxAddress_
    ) external onlyRole(GOVERNANCE_ROLE) {
        outbox__ = IOutbox(outboxAddress_);

        emit UpdatedOutbox(outboxAddress_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "lib/openzeppelin-contracts/contracts/vendor/arbitrum/IArbSys.sol";

import "../../libraries/AddressAliasHelper.sol";
import "./NativeSwitchboardBase.sol";

/**

@title ArbitrumL2Switchboard
@dev A contract that facilitates communication between the Ethereum mainnet and 
     the Arbitrum Layer 2 network by handling incoming and outgoing messages through the Arbitrum Sys contract. 
     Inherits from NativeSwitchboardBase contract that handles communication with 
     other Layer 1 networks.
*/
contract ArbitrumL2Switchboard is NativeSwitchboardBase {
    IArbSys public immutable arbsys__ = IArbSys(address(100));

    /**
     * @dev Modifier that checks if the sender of the transaction is the remote native switchboard on the L1 network.
     * If not, reverts with an InvalidSender error message.
     */
    modifier onlyRemoteSwitchboard() override {
        if (
            msg.sender !=
            AddressAliasHelper.applyL1ToL2Alias(remoteNativeSwitchboard)
        ) revert InvalidSender();
        _;
    }

    /**
     * @dev Constructor function that sets initial values for the arbsys__, and the NativeSwitchboardBase parent contract.
     * @param chainSlug_ A uint32 representing the ID of the L2 network.
     * @param owner_ The address that will have the default admin role in the AccessControl parent contract.
     * @param socket_ The address of the Ethereum mainnet Native Meta-Transaction Executor contract.
     */
    constructor(
        uint32 chainSlug_,
        address owner_,
        address socket_,
        ISignatureVerifier signatureVerifier_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(socket_, chainSlug_, signatureVerifier_)
    {}

    /**
     * @dev Sends a message to the L1 network requesting a confirmation for the packet with the specified packet ID.
     * @param packetId_ A bytes32 representing the ID of the packet to be confirmed.
     */
    function initiateNativeConfirmation(bytes32 packetId_) external {
        bytes memory data = _encodeRemoteCall(packetId_);

        arbsys__.sendTxToL1(remoteNativeSwitchboard, data);
        emit InitiatedNativeConfirmation(packetId_);
    }

    /**
    @dev Internal function to encode a remote call to L1.
         receivePacket on the Arbitrum L2 chain.
    @param packetId_ The ID of the packet to receive.
    @return data A bytes array containing the encoded function call.
    */
    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encodeWithSelector(
            this.receivePacket.selector,
            packetId_,
            _getRoot(packetId_)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../../interfaces/ISocket.sol";
import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/ICapacitor.sol";
import "../../interfaces/ISignatureVerifier.sol";
import "../../interfaces/IExecutionManager.sol";
import "../../libraries/RescueFundsLib.sol";
import "../../utils/AccessControlExtended.sol";

import {GOVERNANCE_ROLE, RESCUE_ROLE, WITHDRAW_ROLE, TRIP_ROLE, UN_TRIP_ROLE, FEES_UPDATER_ROLE} from "../../utils/AccessRoles.sol";
import {TRIP_NATIVE_SIG_IDENTIFIER, UN_TRIP_NATIVE_SIG_IDENTIFIER, FEES_UPDATE_SIG_IDENTIFIER} from "../../utils/SigIdentifiers.sol";

/**
@title Native Switchboard Base Contract
@notice This contract serves as the base for the implementation of a switchboard for native cross-chain communication.
It provides the necessary functionalities to allow packets to be sent and received between chains and ensures proper handling
of fees, gas limits, and packet validation.
@dev This contract has access-controlled functions and connects to a capacitor contract that holds packets for the native bridge.
*/
abstract contract NativeSwitchboardBase is ISwitchboard, AccessControlExtended {
    ISignatureVerifier public immutable signatureVerifier__;
    ISocket public immutable socket__;
    uint32 public immutable chainSlug;

    uint128 public switchboardFees;
    uint128 public verificationFees;

    /**
     * @dev Flag that indicates if the global fuse is tripped, meaning no more packets can be sent.
     */
    bool public tripGlobalFuse;

    /**
     * @dev The capacitor contract that holds packets for the native bridge.
     */
    ICapacitor public capacitor__;

    /**
     * @dev Flag that indicates if the capacitor has been registered.
     */
    bool public isInitialized;

    uint256 initialPacketCount;

    /**
     * @dev Address of the remote native switchboard.
     */
    address public remoteNativeSwitchboard;

    /**
     * @dev Stores the roots received from native bridge.
     */
    mapping(bytes32 => bytes32) public packetIdToRoot;

    /**
     * @dev Transmitter to next nonce.
     */
    mapping(address => uint256) public nextNonce;

    /**
     * @dev Event emitted when the switchboard is tripped.
     */
    event SwitchboardTripped(bool tripGlobalFuse);

    /**
     * @dev Event emitted when the capacitor address is set.
     * @param capacitor The new capacitor address.
     */
    event CapacitorSet(address capacitor);

    /**
     * @dev Event emitted when a native confirmation is initiated.
     * @param packetId The packet ID.
     */
    event InitiatedNativeConfirmation(bytes32 packetId);

    /**
     * @dev This event is emitted when a new capacitor is registered.
     *     It includes the address of the capacitor and the maximum size of the packet allowed.
     * @param remoteNativeSwitchboard address of capacitor registered to switchboard
     */
    event UpdatedRemoteNativeSwitchboard(address remoteNativeSwitchboard);

    /**
     * @dev Event emitted when a root hash is received by the contract.
     * @param packetId The unique identifier of the packet.
     * @param root The root hash of the Merkle tree containing the transaction data.
     */
    event RootReceived(bytes32 packetId, bytes32 root);

    /**
     * @dev Emitted when a fees is set for switchboard
     * @param switchboardFees switchboardFees
     * @param verificationFees verificationFees
     */
    event SwitchboardFeesSet(uint256 switchboardFees, uint256 verificationFees);

    /**
     * @dev Error thrown when the fees provided are not enough to execute the transaction.
     */
    error FeesNotEnough();

    /**
     * @dev Error thrown when the contract has already been initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev Error thrown when the transaction is not sent by a valid sender.
     */
    error InvalidSender();

    /**
     * @dev Error thrown when a root hash cannot be found for the given packet ID.
     */
    error NoRootFound();

    /**
     * @dev Error thrown when the nonce of the transaction is invalid.
     */
    error InvalidNonce();

    /**
     * @dev Error thrown when a function can only be called by the Socket.
     */
    error OnlySocket();

    /**
     * @dev Modifier to ensure that a function can only be called by the remote switchboard.
     */
    modifier onlyRemoteSwitchboard() virtual;

    /**
     * @dev Constructor function for the CrossChainReceiver contract.
     * @param socket_ The address of the remote switchboard.
     * @param chainSlug_ The identifier of the chain the contract is deployed on.
     * @param signatureVerifier_ signatureVerifier instance
     */
    constructor(
        address socket_,
        uint32 chainSlug_,
        ISignatureVerifier signatureVerifier_
    ) {
        socket__ = ISocket(socket_);
        chainSlug = chainSlug_;
        signatureVerifier__ = signatureVerifier_;
    }

    /**
     * @notice retrieves the Merkle root for a given packet ID
     * @param packetId_ packet ID
     * @return root Merkle root associated with the given packet ID
     * @dev Reverts with 'NoRootFound' error if no root is found for the given packet ID
     */
    function _getRoot(bytes32 packetId_) internal view returns (bytes32 root) {
        uint64 capacitorPacketCount = uint64(uint256(packetId_));
        root = capacitor__.getRootByCount(capacitorPacketCount);
        if (root == bytes32(0)) revert NoRootFound();
    }

    /**
     * @notice records the Merkle root for a given packet ID emitted by a remote switchboard
     * @param packetId_ packet ID
     * @param root_ Merkle root for the given packet ID
     */
    function receivePacket(
        bytes32 packetId_,
        bytes32 root_
    ) external onlyRemoteSwitchboard {
        packetIdToRoot[packetId_] = root_;
        emit RootReceived(packetId_, root_);
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function allowPacket(
        bytes32 root_,
        bytes32 packetId_,
        uint256,
        uint32,
        uint256
    ) external view override returns (bool) {
        uint64 packetCount = uint64(uint256(packetId_));

        if (tripGlobalFuse) return false;
        if (packetCount < initialPacketCount) return false;
        if (packetIdToRoot[packetId_] != root_) return false;

        return true;
    }

    /**
     * @dev Get the minimum fees for a cross-chain transaction.
     * @return switchboardFee_ The fee charged by the switchboard for the transaction.
     * @return verificationFee_ The fee charged by the verifier for the transaction.
     */
    function getMinFees(
        uint32
    )
        external
        view
        override
        returns (uint128 switchboardFee_, uint128 verificationFee_)
    {
        return (switchboardFees, verificationFees);
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function setFees(
        uint256 nonce_,
        uint32,
        uint128 switchboardFees_,
        uint128 verificationFees_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(
                    FEES_UPDATE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    nonce_,
                    switchboardFees_,
                    verificationFees_
                )
            ),
            signature_
        );

        _checkRole(FEES_UPDATER_ROLE, feesUpdater);
        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[feesUpdater]++) revert InvalidNonce();
        }
        switchboardFees = switchboardFees_;
        verificationFees = verificationFees_;

        emit SwitchboardFeesSet(switchboardFees, verificationFees);
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function registerSiblingSlug(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_,
        uint256 initialPacketCount_,
        address remoteNativeSwitchboard_
    ) external override onlyRole(GOVERNANCE_ROLE) {
        if (isInitialized) revert AlreadyInitialized();

        initialPacketCount = initialPacketCount_;
        (address capacitor, ) = socket__.registerSwitchboardForSibling(
            siblingChainSlug_,
            maxPacketLength_,
            capacitorType_,
            remoteNativeSwitchboard_
        );

        isInitialized = true;
        capacitor__ = ICapacitor(capacitor);
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
    }

    /**
     * @notice Updates the sibling switchboard for given `siblingChainSlug_`.
     * @dev This function is expected to be only called by admin
     * @param siblingChainSlug_ The slug of the sibling chain to register switchboard with.
     * @param remoteNativeSwitchboard_ The switchboard address deployed on `siblingChainSlug_`
     */
    function updateSibling(
        uint32 siblingChainSlug_,
        address remoteNativeSwitchboard_
    ) external onlyRole(GOVERNANCE_ROLE) {
        socket__.useSiblingSwitchboard(
            siblingChainSlug_,
            remoteNativeSwitchboard_
        );

        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        emit UpdatedRemoteNativeSwitchboard(remoteNativeSwitchboard_);
    }

    /**
     * @notice Allows to trip the global fuse and prevent the switchboard to process packets
     * @dev The function recovers the signer from the given signature and verifies if the signer has the TRIP_ROLE.
     *      The nonce must be equal to the next nonce of the caller. If the caller doesn't have the TRIP_ROLE or the nonce
     *      is incorrect, it will revert.
     *       Once the function is successful, the tripGlobalFuse variable is set to true and the SwitchboardTripped event is emitted.
     * @param nonce_ The nonce of the caller.
     * @param signature_ The signature of the message
     */
    function tripGlobal(uint256 nonce_, bytes memory signature_) external {
        address watcher = signatureVerifier__.recoverSigner(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    TRIP_NATIVE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    nonce_,
                    true
                )
            ),
            signature_
        );

        _checkRole(TRIP_ROLE, watcher);
        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[watcher]++) revert InvalidNonce();
        }
        tripGlobalFuse = true;
        emit SwitchboardTripped(true);
    }

    /**
     * @notice Allows a watcher to un trip the switchboard by providing a signature and a nonce.
     * @dev To un trip, the watcher must have the UN_TRIP_ROLE.
     * @param nonce_ The nonce to prevent replay attacks.
     * @param signature_ The signature created by the watcher.
     */
    function unTrip(uint256 nonce_, bytes memory signature_) external {
        address watcher = signatureVerifier__.recoverSigner(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    UN_TRIP_NATIVE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    nonce_,
                    false
                )
            ),
            signature_
        );

        _checkRole(UN_TRIP_ROLE, watcher);

        // Nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[watcher]++) revert InvalidNonce();
        }
        tripGlobalFuse = false;
        emit SwitchboardTripped(false);
    }

    /**
     * @notice Allows the withdrawal of fees by the account with the specified address.
     * @param account_ The address of the account to withdraw fees to.
     * @dev The caller must have the WITHDRAW_ROLE.
     */
    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        if (account_ == address(0)) revert ZeroAddress();
        SafeTransferLib.safeTransferETH(account_, address(this).balance);
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function receiveFees(uint32) external payable override {
        require(msg.sender == address(socket__.executionManager__()));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "lib/openzeppelin-contracts/contracts/vendor/optimism/ICrossDomainMessenger.sol";
import "./NativeSwitchboardBase.sol";

/**
 * @title OptimismSwitchboard
 * @dev A contract that acts as a switchboard for native tokens between L1 and L2 networks in the Optimism Layer 2 solution.
 *      This contract extends the NativeSwitchboardBase contract and implements the required functions to interact with the
 *      CrossDomainMessenger contract, which is used to send and receive messages between L1 and L2 networks in the Optimism solution.
 */
contract OptimismSwitchboard is NativeSwitchboardBase {
    uint256 public receiveGasLimit;

    ICrossDomainMessenger public immutable crossDomainMessenger__;

    event UpdatedReceiveGasLimit(uint256 receiveGasLimit);

    /**
     * @dev Modifier that checks if the sender of the function is the CrossDomainMessenger contract or the remoteNativeSwitchboard address.
     *      This modifier is inherited from the NativeSwitchboardBase contract and is used to ensure that only authorized entities can access the switchboard functions.
     */
    modifier onlyRemoteSwitchboard() override {
        if (
            msg.sender != address(crossDomainMessenger__) ||
            crossDomainMessenger__.xDomainMessageSender() !=
            remoteNativeSwitchboard
        ) revert InvalidSender();
        _;
    }

    /**
     * @dev Constructor function that initializes the OptimismSwitchboard contract with the required parameters.
     * @param chainSlug_ The unique identifier for the chain on which this contract is deployed.
     * @param receiveGasLimit_ The gas limit to be used when receiving messages from the remote switchboard contract.
     * @param owner_ The address of the owner of the contract who has access to the administrative functions.
     * @param socket_ The address of the socket contract that will be used to communicate with the chain.
     * @param crossDomainMessenger_ The address of the CrossDomainMessenger contract that will be used to send and receive messages between L1 and L2 networks in the Optimism solution.
     */
    constructor(
        uint32 chainSlug_,
        uint256 receiveGasLimit_,
        address owner_,
        address socket_,
        address crossDomainMessenger_,
        ISignatureVerifier signatureVerifier_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(socket_, chainSlug_, signatureVerifier_)
    {
        receiveGasLimit = receiveGasLimit_;
        crossDomainMessenger__ = ICrossDomainMessenger(crossDomainMessenger_);
    }

    /**
     * @dev Function used to initiate a confirmation of a native token transfer from the remote switchboard contract.
     * @param packetId_ The identifier of the packet containing the details of the native token transfer.
     */
    function initiateNativeConfirmation(bytes32 packetId_) external {
        bytes memory data = _encodeRemoteCall(packetId_);

        crossDomainMessenger__.sendMessage(
            remoteNativeSwitchboard,
            data,
            uint32(receiveGasLimit)
        );
        emit InitiatedNativeConfirmation(packetId_);
    }

    /**
     * @dev Encodes the arguments for the receivePacket function to be called on the remote switchboard contract, and returns the encoded data.
     * @param packetId_ the ID of the packet being sent.
     * @return data  encoded data.
     */
    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encodeWithSelector(
            this.receivePacket.selector,
            packetId_,
            _getRoot(packetId_)
        );
    }

    /**
     * @notice Update the gas limit for receiving messages from the remote switchboard.
     * @dev Can only be called by accounts with the GOVERNANCE_ROLE.
     * @param receiveGasLimit_ The new receive gas limit to set.
     */
    function updateReceiveGasLimit(
        uint256 receiveGasLimit_
    ) external onlyRole(GOVERNANCE_ROLE) {
        receiveGasLimit = receiveGasLimit_;
        emit UpdatedReceiveGasLimit(receiveGasLimit_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "lib/contracts/contracts/tunnel/FxBaseRootTunnel.sol";
import "./NativeSwitchboardBase.sol";

/**
 * @title PolygonL1Switchboard
 * @notice contract that facilitates cross-chain communication between Polygon and Ethereum mainnet.
 *  It is an implementation of the NativeSwitchboardBase contract and the FxBaseRootTunnel contract.
 */
contract PolygonL1Switchboard is NativeSwitchboardBase, FxBaseRootTunnel {
    /**
     * @notice This event is emitted when the fxChildTunnel address is set or updated.
     * @param fxChildTunnel is the current fxChildTunnel address.
     * @param newFxChildTunnel is the new fxChildTunnel address that was set.
     */
    event FxChildTunnelSet(address fxChildTunnel, address newFxChildTunnel);

    /**
     * @notice This modifier overrides the onlyRemoteSwitchboard modifier in the NativeSwitchboardBase contract
     */
    modifier onlyRemoteSwitchboard() override {
        revert("ONLY_FX_CHILD");

        _;
    }

    /**
     * @notice This is the constructor function of the PolygonL1Switchboard contract.
     *        initializes the contract with the provided parameters.
     * @param chainSlug_ is the identifier of the chain.
     * @param checkpointManager_ is the address of the checkpoint manager contract.
     * @param fxRoot_ is the address of the root contract.
     * @param owner_ is the address of the contract owner.
     * @param socket_ is the address of the Socket contract.
     */
    constructor(
        uint32 chainSlug_,
        address checkpointManager_,
        address fxRoot_,
        address owner_,
        address socket_,
        ISignatureVerifier signatureVerifier_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(socket_, chainSlug_, signatureVerifier_)
        FxBaseRootTunnel(checkpointManager_, fxRoot_)
    {}

    /**
     * @dev Initiates a native confirmation by encoding and sending a message to the child chain.
     * @param packetId_ The packet ID to be confirmed.
     */
    function initiateNativeConfirmation(bytes32 packetId_) external payable {
        bytes memory data = _encodeRemoteCall(packetId_);
        _sendMessageToChild(data);
        emit InitiatedNativeConfirmation(packetId_);
    }

    /**
     * @dev Internal function to encode the remote call.
     * @param packetId_ The packet ID to encode.
     * @return data The encoded data.
     */
    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encode(packetId_, _getRoot(packetId_));
    }

    /**
     * @notice The _processMessageFromChild function is an internal function that processes a
     *          message received from a child contract.decodes the message to extract the packetId and root values
     *          and stores them in the packetIdToRoot mapping.
     * @param message_ The message received from the child contract.
     */
    function _processMessageFromChild(bytes memory message_) internal override {
        (bytes32 packetId, bytes32 root) = abi.decode(
            message_,
            (bytes32, bytes32)
        );
        packetIdToRoot[packetId] = root;
        emit RootReceived(packetId, root);
    }

    /**
     * @notice Set the fxChildTunnel address if not set already.
     * @param fxChildTunnel_ The new fxChildTunnel address to set.
     * @dev The caller must have the GOVERNANCE_ROLE role.
     */
    function setFxChildTunnel(
        address fxChildTunnel_
    ) public override onlyRole(GOVERNANCE_ROLE) {
        emit FxChildTunnelSet(fxChildTunnel, fxChildTunnel_);
        fxChildTunnel = fxChildTunnel_;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "lib/contracts/contracts/tunnel/FxBaseChildTunnel.sol";
import "./NativeSwitchboardBase.sol";

/**
 * @title Polygon L2 Switchboard
 * @dev The Polygon L2 Switchboard contract facilitates the bridging
 *    of tokens and messages between the Polygon L1 and L2 networks.
 *    It inherits from the NativeSwitchboardBase and FxBaseChildTunnel contracts.
 */
contract PolygonL2Switchboard is NativeSwitchboardBase, FxBaseChildTunnel {
    /**
     * @dev Event emitted when the fxChildTunnel address is updated.
     * @param oldFxChild The old fxChildTunnel address.
     * @param newFxChild The new fxChildTunnel address.
     */
    event FxChildUpdate(address oldFxChild, address newFxChild);

    /**
     * @dev Event emitted when the fxRootTunnel address is updated.
     * @param fxRootTunnel The fxRootTunnel address.
     * @param newFxRootTunnel The new fxRootTunnel address.
     */
    event FxRootTunnelSet(address fxRootTunnel, address newFxRootTunnel);

    /**
     * @dev Modifier that restricts access to the onlyRemoteSwitchboard.
     * This modifier is inherited from the NativeSwitchboardBase contract.
     */
    modifier onlyRemoteSwitchboard() override {
        revert("ONLY_FX_CHILD");

        _;
    }

    /**
     * @dev Constructor for the PolygonL2Switchboard contract.
     * @param chainSlug_ The chainSlug for the contract.
     * @param fxChild_ The address of the fxChildTunnel contract.
     * @param owner_ The owner of the contract.
     * @param socket_ The socket address.
     */
    constructor(
        uint32 chainSlug_,
        address fxChild_,
        address owner_,
        address socket_,
        ISignatureVerifier signatureVerifier_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(socket_, chainSlug_, signatureVerifier_)
        FxBaseChildTunnel(fxChild_)
    {}

    /**
     * @dev Sends a message to the root chain to initiate a native confirmation with the given packet ID.
     * @param packetId_ The packet ID for which the native confirmation needs to be initiated.
     */
    function initiateNativeConfirmation(bytes32 packetId_) external payable {
        bytes memory data = _encodeRemoteCall(packetId_);

        _sendMessageToRoot(data);
        emit InitiatedNativeConfirmation(packetId_);
    }

    /**
     * @dev Encodes the remote call to be sent to the root chain to initiate a native confirmation.
     * @param packetId_ The packet ID for which the native confirmation needs to be initiated.
     * @return data encoded remote call data.
     */
    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encode(packetId_, _getRoot(packetId_));
    }

    /**
     * @notice This function processes the message received from the Root contract.
     * @dev decodes the data received and stores the packetId and root in packetIdToRoot mapping.
     *       emits a RootReceived event to indicate that a new root has been received.
     * @param rootMessageSender_ The address of the Root contract that sent the message.
     * @param data_ The data received from the Root contract.
     */
    function _processMessageFromRoot(
        uint256,
        address rootMessageSender_,
        bytes memory data_
    ) internal override validateSender(rootMessageSender_) {
        (bytes32 packetId, bytes32 root) = abi.decode(
            data_,
            (bytes32, bytes32)
        );
        packetIdToRoot[packetId] = root;
        emit RootReceived(packetId, root);
    }

    /**
     * @notice Update the address of the FxChild
     * @param fxChild_ The address of the new FxChild
     **/
    function updateFxChild(
        address fxChild_
    ) external onlyRole(GOVERNANCE_ROLE) {
        emit FxChildUpdate(fxChild, fxChild_);
        fxChild = fxChild_;
    }

    /**
     * @notice setFxRootTunnel is a function in the PolygonL2Switchboard contract that allows the contract owner to set the address of the root tunnel contract on the Ethereum mainnet.
     * @dev This function can only be called by an address with the GOVERNANCE_ROLE role.
     * @param fxRootTunnel_ The address of the root tunnel contract on the Ethereum mainnet.
     */
    function setFxRootTunnel(
        address fxRootTunnel_
    ) external override onlyRole(GOVERNANCE_ROLE) {
        emit FxRootTunnelSet(fxRootTunnel, fxRootTunnel_);
        fxRootTunnel = fxRootTunnel_;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./interfaces/ISocket.sol";
import "./interfaces/ISignatureVerifier.sol";
import "./libraries/RescueFundsLib.sol";
import "./utils/AccessControlExtended.sol";
import {GOVERNANCE_ROLE, WITHDRAW_ROLE, RESCUE_ROLE, TRANSMITTER_ROLE, FEES_UPDATER_ROLE} from "./utils/AccessRoles.sol";
import {FEES_UPDATE_SIG_IDENTIFIER} from "./utils/SigIdentifiers.sol";

/**
 * @title TransmitManager
 * @notice The TransmitManager contract managers transmitter which facilitates communication between chains
 * @dev This contract is responsible for verifying signatures and updating gas limits
 * @dev This contract inherits AccessControlExtended which manages access control
 * @dev The transmission fees is collected in execution manager which can be pulled from it when needed
 */
contract TransmitManager is ITransmitManager, AccessControlExtended {
    // chain slug of the current chain
    uint32 public immutable chainSlug;
    // socket contract
    ISocket public immutable socket__;
    // signature verifier contract
    ISignatureVerifier public signatureVerifier__;

    // feeUpdater => nextNonce
    mapping(address => uint256) public nextNonce;

    // triggered when nonce is not as expected for feeUpdater recovered from sig
    error InvalidNonce();

    /**
     * @notice Emitted when a new signature verifier contract is set
     * @param signatureVerifier The address of the new signature verifier contract
     */
    event SignatureVerifierSet(address signatureVerifier);
    event ExecutionManagerSet(address executionManager);

    /**
     * @notice Emitted when the transmissionFees is updated
     * @param dstChainSlug The destination chain slug for which the transmissionFees is updated
     * @param transmissionFees The new transmissionFees
     */
    event TransmissionFeesSet(uint256 dstChainSlug, uint256 transmissionFees);

    /**
     * @notice Initializes the TransmitManager contract
     * @param signatureVerifier_ The address of the signature verifier contract
     * @param socket_ The address of socket contract
     * @param owner_ The owner of the contract with GOVERNANCE_ROLE
     * @param chainSlug_ The chain slug of the current chain
     */
    constructor(
        address owner_,
        uint32 chainSlug_,
        ISocket socket_,
        ISignatureVerifier signatureVerifier_
    ) AccessControlExtended(owner_) {
        chainSlug = chainSlug_;
        signatureVerifier__ = signatureVerifier_;
        socket__ = socket_;
    }

    /**
     * @notice verifies if the given signatures recovers a valid transmitter
     * @dev signature sent to this function is validated against digest
     * @dev recovered transmitter should add have transmitter role for `siblingSlug_`
     * @dev This function is called by socket which creates the digest which is used to recover sig
     * @param siblingSlug_ sibling id for which transmitter is registered
     * @param digest_ digest which is signed by transmitter
     * @param signature_ signature
     */
    function checkTransmitter(
        uint32 siblingSlug_,
        bytes32 digest_,
        bytes calldata signature_
    ) external view override returns (address, bool) {
        address transmitter = signatureVerifier__.recoverSigner(
            digest_,
            signature_
        );

        return (
            transmitter,
            _hasRoleWithSlug(TRANSMITTER_ROLE, siblingSlug_, transmitter)
        );
    }

    /// @inheritdoc ITransmitManager
    function setTransmissionFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint128 transmissionFees_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSigner(
            keccak256(
                abi.encode(
                    FEES_UPDATE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    dstChainSlug_,
                    nonce_,
                    transmissionFees_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, dstChainSlug_, feesUpdater);

        // nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce_ != nextNonce[feesUpdater]++) revert InvalidNonce();
        }

        socket__.executionManager__().setTransmissionMinFees(
            dstChainSlug_,
            transmissionFees_
        );
        emit TransmissionFeesSet(dstChainSlug_, transmissionFees_);
    }

    /// @inheritdoc ITransmitManager
    function receiveFees(uint32) external payable override {
        require(msg.sender == address(socket__.executionManager__()));
    }

    /**
     * @notice withdraws fees from contract
     * @dev caller needs withdraw role
     * @param account_ withdraw fees to
     */
    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        if (account_ == address(0)) revert ZeroAddress();
        SafeTransferLib.safeTransferETH(account_, address(this).balance);
    }

    /**
     * @notice updates signatureVerifier_
     * @dev caller needs governance role
     * @param signatureVerifier_ address of Signature Verifier
     */
    function setSignatureVerifier(
        address signatureVerifier_
    ) external onlyRole(GOVERNANCE_ROLE) {
        signatureVerifier__ = ISignatureVerifier(signatureVerifier_);
        emit SignatureVerifierSet(signatureVerifier_);
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./Ownable.sol";

/**
 * @title AccessControl
 * @dev This abstract contract implements access control mechanism based on roles.
 * Each role can have one or more addresses associated with it, which are granted
 * permission to execute functions with the onlyRole modifier.
 */
abstract contract AccessControl is Ownable {
    /**
     * @dev A mapping of roles to a mapping of addresses to boolean values indicating whether or not they have the role.
     */
    mapping(bytes32 => mapping(address => bool)) private _permits;

    /**
     * @dev Emitted when a role is granted to an address.
     */
    event RoleGranted(bytes32 indexed role, address indexed grantee);

    /**
     * @dev Emitted when a role is revoked from an address.
     */
    event RoleRevoked(bytes32 indexed role, address indexed revokee);

    /**
     * @dev Error message thrown when an address does not have permission to execute a function with onlyRole modifier.
     */
    error NoPermit(bytes32 role);

    /**
     * @dev Constructor that sets the owner of the contract.
     */
    constructor(address owner_) Ownable(owner_) {}

    /**
     * @dev Modifier that restricts access to addresses having roles
     * Throws an error if the caller do not have permit
     */
    modifier onlyRole(bytes32 role) {
        if (!_permits[role][msg.sender]) revert NoPermit(role);
        _;
    }

    /**
     * @dev Checks and reverts if an address do not have a specific role.
     * @param role_ The role to check.
     * @param address_ The address to check.
     */
    function _checkRole(bytes32 role_, address address_) internal virtual {
        if (!_hasRole(role_, address_)) revert NoPermit(role_);
    }

    /**
     * @dev Grants a role to a given address.
     * @param role_ The role to grant.
     * @param grantee_ The address to grant the role to.
     * Emits a RoleGranted event.
     * Can only be called by the owner of the contract.
     */
    function grantRole(
        bytes32 role_,
        address grantee_
    ) external virtual onlyOwner {
        _grantRole(role_, grantee_);
    }

    /**
     * @dev Revokes a role from a given address.
     * @param role_ The role to revoke.
     * @param revokee_ The address to revoke the role from.
     * Emits a RoleRevoked event.
     * Can only be called by the owner of the contract.
     */
    function revokeRole(
        bytes32 role_,
        address revokee_
    ) external virtual onlyOwner {
        _revokeRole(role_, revokee_);
    }

    /**
     * @dev Internal function to grant a role to a given address.
     * @param role_ The role to grant.
     * @param grantee_ The address to grant the role to.
     * Emits a RoleGranted event.
     */
    function _grantRole(bytes32 role_, address grantee_) internal {
        _permits[role_][grantee_] = true;
        emit RoleGranted(role_, grantee_);
    }

    /**
     * @dev Internal function to revoke a role from a given address.
     * @param role_ The role to revoke.
     * @param revokee_ The address to revoke the role from.
     * Emits a RoleRevoked event.
     */
    function _revokeRole(bytes32 role_, address revokee_) internal {
        _permits[role_][revokee_] = false;
        emit RoleRevoked(role_, revokee_);
    }

    /**
     * @dev Checks whether an address has a specific role.
     * @param role_ The role to check.
     * @param address_ The address to check.
     * @return A boolean value indicating whether or not the address has the role.
     */
    function hasRole(
        bytes32 role_,
        address address_
    ) external view returns (bool) {
        return _hasRole(role_, address_);
    }

    function _hasRole(
        bytes32 role_,
        address address_
    ) internal view returns (bool) {
        return _permits[role_][address_];
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "./AccessControl.sol";

/**
 * @title AccessControlExtended
 * @dev This contract extends the functionality of the AccessControl contract by adding
 * the ability to grant and revoke roles based on a combination of role name and a chain slug.
 * It also provides batch operations for granting and revoking roles.
 */
contract AccessControlExtended is AccessControl {
    /**
     * @dev Constructor that sets the owner of the contract.
     */
    constructor(address owner_) AccessControl(owner_) {}

    /**
     * @dev thrown when array lengths are not equal
     */
    error UnequalArrayLengths();

    /**
     * @dev Checks if an address has the role.
     * @param roleName_ The name of the role.
     * @param chainSlug_ The chain slug associated with the role.
     * @param address_ The address to be granted the role.
     */
    function _checkRoleWithSlug(
        bytes32 roleName_,
        uint256 chainSlug_,
        address address_
    ) internal virtual {
        bytes32 roleHash = keccak256(abi.encode(roleName_, chainSlug_));
        if (!_hasRole(roleHash, address_)) revert NoPermit(roleHash);
    }

    /**
     * @dev Grants a role to an address based on the role name and chain slug.
     * @param roleName_ The name of the role.
     * @param chainSlug_ The chain slug associated with the role.
     * @param grantee_ The address to be granted the role.
     */
    function grantRoleWithSlug(
        bytes32 roleName_,
        uint32 chainSlug_,
        address grantee_
    ) external virtual onlyOwner {
        _grantRoleWithSlug(roleName_, chainSlug_, grantee_);
    }

    /**
     * @dev Grants multiple roles to multiple addresses in batch.
     * @param roleNames_ The names of the roles to grant.
     * @param slugs_ The slugs for chain specific roles. For roles which are not chain-specific, we can use slug = 0
     * @param grantees_ The addresses to be granted the roles.
     */
    function grantBatchRole(
        bytes32[] calldata roleNames_,
        uint32[] calldata slugs_,
        address[] calldata grantees_
    ) external virtual onlyOwner {
        if (
            roleNames_.length != grantees_.length ||
            roleNames_.length != slugs_.length
        ) revert UnequalArrayLengths();
        uint256 totalRoles = roleNames_.length;
        for (uint256 index = 0; index < totalRoles; ) {
            if (slugs_[index] > 0)
                _grantRoleWithSlug(
                    roleNames_[index],
                    slugs_[index],
                    grantees_[index]
                );
            else _grantRole(roleNames_[index], grantees_[index]);

            // inputs are controlled by owner
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @dev Revokes multiple roles from multiple addresses in batch.
     * @param roleNames_ The names of the roles to revoke.
     * @param slugs_ The slugs for chain specific roles. For roles which are not chain-specific, we can use slug = 0
     * @param grantees_ The addresses to be revoked the roles.
     */
    function revokeBatchRole(
        bytes32[] calldata roleNames_,
        uint32[] calldata slugs_,
        address[] calldata grantees_
    ) external virtual onlyOwner {
        if (
            roleNames_.length != grantees_.length ||
            roleNames_.length != slugs_.length
        ) revert UnequalArrayLengths();
        uint256 totalRoles = roleNames_.length;
        for (uint256 index = 0; index < totalRoles; ) {
            if (slugs_[index] > 0)
                _revokeRoleWithSlug(
                    roleNames_[index],
                    slugs_[index],
                    grantees_[index]
                );
            else _revokeRole(roleNames_[index], grantees_[index]);

            // inputs are controlled by owner
            unchecked {
                ++index;
            }
        }
    }

    function _grantRoleWithSlug(
        bytes32 roleName_,
        uint32 chainSlug_,
        address grantee_
    ) internal {
        _grantRole(keccak256(abi.encode(roleName_, chainSlug_)), grantee_);
    }

    /**
     * @dev Checks if an address has a role based on the role name and chain slug.
     * @param roleName_ The name of the role.
     * @param chainSlug_ The chain slug associated with the role.
     * @param address_ The address to check for the role.
     * @return A boolean indicating whether the address has the specified role.
     */
    function hasRoleWithSlug(
        bytes32 roleName_,
        uint32 chainSlug_,
        address address_
    ) external view returns (bool) {
        return _hasRoleWithSlug(roleName_, chainSlug_, address_);
    }

    function _hasRoleWithSlug(
        bytes32 roleName_,
        uint32 chainSlug_,
        address address_
    ) internal view returns (bool) {
        return _hasRole(keccak256(abi.encode(roleName_, chainSlug_)), address_);
    }

    /**
     * @dev Revokes roles from an address
     * @param roleName_ The names of the roles to revoke.
     * @param chainSlug_ The chain slug associated with the role.
     * @param grantee_ The addresses to be revoked the roles.
     */
    function revokeRoleWithSlug(
        bytes32 roleName_,
        uint32 chainSlug_,
        address grantee_
    ) external virtual onlyOwner {
        _revokeRoleWithSlug(roleName_, chainSlug_, grantee_);
    }

    function _revokeRoleWithSlug(
        bytes32 roleName_,
        uint32 chainSlug_,
        address revokee_
    ) internal {
        _revokeRole(keccak256(abi.encode(roleName_, chainSlug_)), revokee_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

// contains role hashes used in socket dl for various different operations

// used to rescue funds
bytes32 constant RESCUE_ROLE = keccak256("RESCUE_ROLE");
// used to withdraw fees
bytes32 constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
// used to trip switchboards
bytes32 constant TRIP_ROLE = keccak256("TRIP_ROLE");
// used to un trip switchboards
bytes32 constant UN_TRIP_ROLE = keccak256("UN_TRIP_ROLE");
// used by governance
bytes32 constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
//used by executors which executes message at destination
bytes32 constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
// used by transmitters who seal and propose packets in socket
bytes32 constant TRANSMITTER_ROLE = keccak256("TRANSMITTER_ROLE");
// used by switchboard watchers who work against transmitters
bytes32 constant WATCHER_ROLE = keccak256("WATCHER_ROLE");
// used by fee updaters responsible for updating fees at switchboards, transmit manager and execution manager
bytes32 constant FEES_UPDATER_ROLE = keccak256("FEES_UPDATER_ROLE");

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IHasher.sol";
import "../interfaces/ISocket.sol";
import "../libraries/RescueFundsLib.sol";

import "../utils/AccessControl.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

/**
 * @title Hasher
 * @notice contract for hasher contract that calculates the packed message
 * @dev This contract is modular component in socket to support different message packing algorithms in case of blockchains
 * not supporting this type of packing.
 */
contract Hasher is IHasher, AccessControl {
    /**
     * @notice initializes and grants RESCUE_ROLE to owner.
     * @param owner_ The address of the owner of the contract.
     */
    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /// @inheritdoc IHasher
    function packMessage(
        uint32 srcChainSlug_,
        address srcPlug_,
        uint32 dstChainSlug_,
        address dstPlug_,
        ISocket.MessageDetails memory messageDetails_
    ) external pure override returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    srcChainSlug_,
                    srcPlug_,
                    dstChainSlug_,
                    dstPlug_,
                    messageDetails_.msgId,
                    messageDetails_.minMsgGasLimit,
                    messageDetails_.executionParams,
                    messageDetails_.executionFee,
                    messageDetails_.payload
                )
            );
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title Ownable
 * @dev The Ownable contract provides a simple way to manage ownership of a contract
 * and allows for ownership to be transferred to a nominated address.
 */
abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    error OnlyOwner();
    error OnlyNominee();

    /**
     * @dev Sets the contract's owner to the address that is passed to the constructor.
     */
    constructor(address owner_) {
        _claimOwner(owner_);
    }

    /**
     * @dev Modifier that restricts access to only the contract's owner.
     * Throws an error if the caller is not the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) revert OnlyOwner();
        _;
    }

    /**
     * @dev Returns the current owner of the contract.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the current nominee for ownership of the contract.
     */
    function nominee() external view returns (address) {
        return _nominee;
    }

    /**
     * @dev Allows the current owner to nominate a new owner for the contract.
     * Throws an error if the caller is not the owner.
     * Emits an `OwnerNominated` event with the address of the nominee.
     */
    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) revert OnlyOwner();
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    /**
     * @dev Allows the nominated owner to claim ownership of the contract.
     * Throws an error if the caller is not the nominee.
     * Sets the nominated owner as the new owner of the contract.
     * Emits an `OwnerClaimed` event with the address of the new owner.
     */
    function claimOwner() external {
        if (msg.sender != _nominee) revert OnlyNominee();
        _claimOwner(msg.sender);
    }

    /**
     * @dev Internal function that sets the owner of the contract to the specified address
     * and sets the nominee to address(0).
     */
    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

// contains unique identifiers which are hashes of strings, they help in making signature digest unique
// hence preventing signature replay attacks

// default switchboards
bytes32 constant TRIP_PATH_SIG_IDENTIFIER = keccak256("TRIP_PATH");
bytes32 constant TRIP_PROPOSAL_SIG_IDENTIFIER = keccak256("TRIP_PROPOSAL");
bytes32 constant TRIP_GLOBAL_SIG_IDENTIFIER = keccak256("TRIP_GLOBAL");

bytes32 constant UN_TRIP_PATH_SIG_IDENTIFIER = keccak256("UN_TRIP_PATH");
bytes32 constant UN_TRIP_GLOBAL_SIG_IDENTIFIER = keccak256("UN_TRIP_GLOBAL");

// native switchboards
bytes32 constant TRIP_NATIVE_SIG_IDENTIFIER = keccak256("TRIP_NATIVE");
bytes32 constant UN_TRIP_NATIVE_SIG_IDENTIFIER = keccak256("UN_TRIP_NATIVE");

// value threshold, price and fee updaters
bytes32 constant FEES_UPDATE_SIG_IDENTIFIER = keccak256("FEES_UPDATE");
bytes32 constant RELATIVE_NATIVE_TOKEN_PRICE_UPDATE_SIG_IDENTIFIER = keccak256(
    "RELATIVE_NATIVE_TOKEN_PRICE_UPDATE"
);
bytes32 constant MSG_VALUE_MIN_THRESHOLD_SIG_IDENTIFIER = keccak256(
    "MSG_VALUE_MIN_THRESHOLD_UPDATE"
);
bytes32 constant MSG_VALUE_MAX_THRESHOLD_SIG_IDENTIFIER = keccak256(
    "MSG_VALUE_MAX_THRESHOLD_UPDATE"
);

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/ISignatureVerifier.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../libraries/RescueFundsLib.sol";
import "../utils/AccessControl.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

/**
 * @title Signature Verifier
 * @notice Verifies the signatures and returns the address of signer recovered from the input signature or digest.
 * @dev This contract is modular component in socket to support different signing algorithms.
 */
contract SignatureVerifier is ISignatureVerifier, AccessControl {
    /*
     * @dev Error thrown when signature length is invalid
     */
    error InvalidSigLength();

    /**
     * @notice initializes and grants RESCUE_ROLE to owner.
     * @param owner_ The address of the owner of the contract.
     */
    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @notice returns the address of signer recovered from input signature and digest
     * @param digest_ The message digest to be signed
     * @param signature_ The signature to be verified
     * @return signer The address of the signer
     */
    function recoverSigner(
        bytes32 digest_,
        bytes memory signature_
    ) public pure override returns (address signer) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest_)
        );
        // recovered signer is checked for the valid roles later
        signer = ECDSA.recover(digest, signature_);
    }

    /**
     * @notice Rescues funds from a contract that has lost access to them.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user who lost access to the funds.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}

pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library ExitPayloadReader {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 constant WORD_SIZE = 32;

    struct ExitPayload {
        RLPReader.RLPItem[] data;
    }

    struct Receipt {
        RLPReader.RLPItem[] data;
        bytes raw;
        uint256 logIndex;
    }

    struct Log {
        RLPReader.RLPItem data;
        RLPReader.RLPItem[] list;
    }

    struct LogTopics {
        RLPReader.RLPItem[] data;
    }

    // copy paste of private copy() from RLPReader to avoid changing of existing contracts
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toExitPayload(bytes memory data) internal pure returns (ExitPayload memory) {
        RLPReader.RLPItem[] memory payloadData = data.toRlpItem().toList();

        return ExitPayload(payloadData);
    }

    function getHeaderNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[0].toUint();
    }

    function getBlockProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[1].toBytes();
    }

    function getBlockNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[2].toUint();
    }

    function getBlockTime(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[3].toUint();
    }

    function getTxRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[4].toUint());
    }

    function getReceiptRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[5].toUint());
    }

    function getReceipt(ExitPayload memory payload) internal pure returns (Receipt memory receipt) {
        receipt.raw = payload.data[6].toBytes();
        RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

        if (receiptItem.isList()) {
            // legacy tx
            receipt.data = receiptItem.toList();
        } else {
            // pop first byte before parsing receipt
            bytes memory typedBytes = receipt.raw;
            bytes memory result = new bytes(typedBytes.length - 1);
            uint256 srcPtr;
            uint256 destPtr;
            assembly {
                srcPtr := add(33, typedBytes)
                destPtr := add(0x20, result)
            }

            copy(srcPtr, destPtr, result.length);
            receipt.data = result.toRlpItem().toList();
        }

        receipt.logIndex = getReceiptLogIndex(payload);
        return receipt;
    }

    function getReceiptProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[7].toBytes();
    }

    function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[8].toBytes();
    }

    function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[8].toUint();
    }

    function getReceiptLogIndex(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[9].toUint();
    }

    // Receipt methods
    function toBytes(Receipt memory receipt) internal pure returns (bytes memory) {
        return receipt.raw;
    }

    function getLog(Receipt memory receipt) internal pure returns (Log memory) {
        RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
        return Log(logData, logData.toList());
    }

    // Log methods
    function getEmitter(Log memory log) internal pure returns (address) {
        return RLPReader.toAddress(log.list[0]);
    }

    function getTopics(Log memory log) internal pure returns (LogTopics memory) {
        return LogTopics(log.list[1].toList());
    }

    function getData(Log memory log) internal pure returns (bytes memory) {
        return log.list[2].toBytes();
    }

    function toRlpBytes(Log memory log) internal pure returns (bytes memory) {
        return log.data.toRlpBytes();
    }

    // LogTopics methods
    function getField(LogTopics memory topics, uint256 index) internal pure returns (RLPReader.RLPItem memory) {
        return topics.data[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2**proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[nextPathNibble]));
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b) internal pure returns (bytes memory) {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
        return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }
}

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity ^0.8.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte < 128 is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shift to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;

        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "../lib/RLPReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";
import {Merkle} from "../lib/Merkle.sol";
import "../lib/ExitPayloadReader.sol";

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    // keccak256(MessageSent(bytes))
    bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    // state sender contract
    IFxStateSender public fxRoot;
    // root chain manager
    ICheckpointManager public checkpointManager;
    // child tunnel contract which receives and sends messages
    address public fxChildTunnel;

    // storage to avoid duplicate exits
    mapping(bytes32 => bool) public processedExits;

    constructor(address _checkpointManager, address _fxRoot) {
        checkpointManager = ICheckpointManager(_checkpointManager);
        fxRoot = IFxStateSender(_fxRoot);
    }

    // set fxChildTunnel if not set already
    function setFxChildTunnel(address _fxChildTunnel) public virtual {
        require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToChild(bytes memory message) internal {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }

    function _validateAndExtractMessage(bytes memory inputData) internal returns (bytes memory) {
        ExitPayloadReader.ExitPayload memory payload = inputData.toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );
        require(processedExits[exitHash] == false, "FxRootTunnel: EXIT_ALREADY_PROCESSED");
        processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        require(fxChildTunnel == log.getEmitter(), "FxRootTunnel: INVALID_FX_CHILD_TUNNEL");

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        require(
            MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot),
            "FxRootTunnel: INVALID_RECEIPT_PROOF"
        );

        // verify checkpoint inclusion
        _checkBlockMembershipInCheckpoint(
            blockNumber,
            payload.getBlockTime(),
            payload.getTxRoot(),
            receiptRoot,
            payload.getHeaderNumber(),
            payload.getBlockProof()
        );

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        require(
            bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
            "FxRootTunnel: INVALID_SIGNATURE"
        );

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
        return message;
    }

    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view {
        (bytes32 headerRoot, uint256 startBlock, , uint256 createdAt, ) = checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)).checkMembership(
                blockNumber - startBlock,
                headerRoot,
                blockProof
            ),
            "FxRootTunnel: INVALID_HEADER"
        );
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param inputData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function receiveMessage(bytes memory inputData) public virtual {
        bytes memory message = _validateAndExtractMessage(inputData);
        _processMessageFromChild(message);
    }

    /**
     * @notice Process message received from Child Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by receiveMessage function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function _processMessageFromChild(bytes memory message) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.9.0) (vendor/arbitrum/IArbSys.sol)

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface IArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused) external pure returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState() external view returns (uint256 size, bytes32 root, bytes32[] memory partials);

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(uint256 indexed reserved, bytes32 indexed hash, uint256 indexed position);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.9.0) (vendor/arbitrum/IBridge.sol)

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

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

    event BridgeCallTriggered(address indexed outbox, address indexed to, uint256 value, bytes data);

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    event SequencerInboxUpdated(address newSequencerInbox);

    function allowedDelayedInboxList(uint256) external returns (address);

    function allowedOutboxList(uint256) external returns (address);

    /// @dev Accumulator for delayed inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function delayedInboxAccs(uint256) external view returns (bytes32);

    /// @dev Accumulator for sequencer inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function sequencerInboxAccs(uint256) external view returns (bytes32);

    // OpenZeppelin: changed return type from IOwnable
    function rollup() external view returns (address);

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
    ) external returns (uint256 seqMessageIndex, bytes32 beforeAcc, bytes32 delayedAcc, bytes32 acc);

    /**
     * @dev Allows the sequencer inbox to submit a delayed message of the batchPostingReport type
     *      This is done through a separate function entrypoint instead of allowing the sequencer inbox
     *      to call `enqueueDelayedMessage` to avoid the gas overhead of an extra SLOAD in either
     *      every delayed inbox or every sequencer inbox call.
     */
    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash) external returns (uint256 msgNum);

    // ---------- onlyRollupOrOwner functions ----------

    function setSequencerInbox(address _sequencerInbox) external;

    function setDelayedInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // ---------- initializer ----------

    // OpenZeppelin: changed rollup_ type from IOwnable
    function initialize(address rollup_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.8.0) (vendor/arbitrum/IDelayedMessageProvider.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (vendor/arbitrum/IInbox.sol)

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";
import "./IDelayedMessageProvider.sol";

interface IInbox is IDelayedMessageProvider {
    function bridge() external view returns (IBridge);

    // OpenZeppelin: changed return type from ISequencerInbox
    function sequencerInbox() external view returns (address);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method is an optimization to avoid having to emit the entirety of the messageData in a log. Instead validators are expected to be able to parse the data from the transaction's input
     * @param messageData Data of the message being sent
     */
    function sendL2MessageFromOrigin(bytes calldata messageData) external returns (uint256);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method can be used to send any type of message that doesn't require L1 validation
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
     * @notice Get the L1 fee for submitting a retryable
     * @dev This fee can be paid by funds already in the L2 aliased address or by the current message value
     * @dev This formula may change in the future, to future proof your code query this method instead of inlining!!
     * @param dataLength The length of the retryable's calldata, in bytes
     * @param baseFee The block basefee when the retryable is included in the chain, if 0 current block.basefee will be used
     */
    function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee) external view returns (uint256);

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

    // OpenZeppelin: changed _sequencerInbox type from ISequencerInbox
    function initialize(IBridge _bridge, address _sequencerInbox) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.9.0) (vendor/arbitrum/IOutbox.sol)

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";

interface IOutbox {
    event SendRootUpdated(bytes32 indexed blockHash, bytes32 indexed outputRoot);
    event OutBoxTransactionExecuted(
        address indexed to,
        address indexed l2Sender,
        uint256 indexed zero,
        uint256 transactionIndex
    );

    function rollup() external view returns (address); // the rollup contract

    function bridge() external view returns (IBridge); // the bridge contract

    function spent(uint256) external view returns (bytes32); // packed spent bitmap

    function roots(bytes32) external view returns (bytes32); // maps root hashes => L2 block hash

    // solhint-disable-next-line func-name-mixedcase
    function OUTBOX_VERSION() external view returns (uint128); // the outbox version

    function updateSendRoot(bytes32 sendRoot, bytes32 l2BlockHash) external;

    /// @notice When l2ToL1Sender returns a nonzero address, the message was originated by an L2 account
    ///         When the return value is zero, that means this is a system message
    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function l2ToL1Sender() external view returns (address);

    /// @return l2Block return L2 block when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1Block() external view returns (uint256);

    /// @return l1Block return L1 block when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1EthBlock() external view returns (uint256);

    /// @return timestamp return L2 timestamp when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1Timestamp() external view returns (uint256);

    /// @return outputId returns the unique output identifier of the L2 to L1 tx or 0 if no L2 to L1 transaction is active
    function l2ToL1OutputId() external view returns (bytes32);

    /**
     * @notice Executes a messages in an Outbox entry.
     * @dev Reverts if dispute period hasn't expired, since the outbox entry
     *      is only created once the rollup confirms the respective assertion.
     * @dev it is not possible to execute any L2-to-L1 transaction which contains data
     *      to a contract address without any code (as enforced by the Bridge contract).
     * @param proof Merkle proof of message inclusion in send root
     * @param index Merkle path to message
     * @param l2Sender sender if original message (i.e., caller of ArbSys.sendTxToL1)
     * @param to destination address for L1 contract call
     * @param l2Block l2 block number at which sendTxToL1 call was made
     * @param l1Block l1 block number at which sendTxToL1 call was made
     * @param l2Timestamp l2 Timestamp at which sendTxToL1 call was made
     * @param value wei in L1 message
     * @param data abi-encoded L1 message data
     */
    function executeTransaction(
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     *  @dev function used to simulate the result of a particular function call from the outbox
     *       it is useful for things such as gas estimates. This function includes all costs except for
     *       proof validation (which can be considered offchain as a somewhat of a fixed cost - it's
     *       not really a fixed cost, but can be treated as so with a fixed overhead for gas estimation).
     *       We can't include the cost of proof validation since this is intended to be used to simulate txs
     *       that are included in yet-to-be confirmed merkle roots. The simulation entrypoint could instead pretend
     *       to confirm a pending merkle root, but that would be less practical for integrating with tooling.
     *       It is only possible to trigger it when the msg sender is address zero, which should be impossible
     *       unless under simulation in an eth_call or eth_estimateGas
     */
    function executeTransactionSimulation(
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * @param index Merkle path to message
     * @return true if the message has been spent
     */
    function isSpent(uint256 index) external view returns (bool);

    function calculateItemHash(
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes32);

    function calculateMerkleRoot(bytes32[] memory proof, uint256 path, bytes32 item) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (vendor/optimism/ICrossDomainMessenger.sol)
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(address indexed target, address sender, bytes message, uint256 messageNonce, uint256 gasLimit);
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(address _target, bytes calldata _message, uint32 _gasLimit) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}