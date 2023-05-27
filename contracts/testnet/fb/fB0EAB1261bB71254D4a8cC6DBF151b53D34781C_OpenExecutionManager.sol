// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
     * @notice initialises and grants RESCUE_ROLE to owner.
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
        uint256 /** maxPacketLength */
    ) external override returns (ICapacitor, IDecapacitor) {
        // sets the capacitor factory owner
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
                new HashChainCapacitor(msg.sender, owner),
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
pragma solidity 0.8.7;

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

    address public immutable socket;

    /// maps the packet count with the root hash generated while adding message
    mapping(uint64 => bytes32) internal _roots;

    error NoPendingPacket();
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
    }

    /**
     * @dev Seals the next pending packet and returns its root hash and packet count.
     * @dev we use seal packet count to make sure there is no scope of censorship and all the packets get sealed.
     * @return The root hash and packet count of the sealed packet.
     */
    function sealPacket(
        uint256
    ) external virtual override onlySocket returns (bytes32, uint64) {
        uint64 packetCount = _nextSealCount++;
        if (_roots[packetCount] == bytes32(0)) revert NoPendingPacket();

        bytes32 root = _roots[packetCount];
        return (root, packetCount);
    }

    /**
     * @dev Returns the root hash and packet count of the next pending packet to be sealed.
     * @return The root hash and packet count of the next pending packet.
     */
    function getNextPacketToBeSealed()
        external
        view
        virtual
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
    ) external view virtual override returns (bytes32) {
        return _roots[count_];
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
pragma solidity 0.8.7;

import "./BaseCapacitor.sol";

/**
 * @title HashChainCapacitor
 * @notice This is an experimental contract and have known bugs
 * @dev A contract that implements ICapacitor and stores packed messages in a hash chain.
 * The hash chain is made of packets, each packet contains a maximum of 10 messages.
 * Each new message added to the chain is hashed with the previous root to create a new root.
 * When a packet is full, a new packet is created and the root of the last packet is sealed.
 */
contract HashChainCapacitor is BaseCapacitor {
    uint256 private _chainLength;
    uint256 private constant _MAX_LEN = 10;

    /**
     * @notice Initializes the HashChainCapacitor contract with a socket address.
     * @param socket_ The address of the socket contract
     * @param owner_ The address of the contract owner
     */
    constructor(
        address socket_,
        address owner_
    ) BaseCapacitor(socket_, owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @notice Adds a packed message to the hash chain.
     * @dev The packed message is added to the current packet and hashed with the previous root to create a new root.
     * If the packet is full, a new packet is created and the root of the last packet is sealed.
     * @param packedMessage_ The packed message to be added to the hash chain.
     */
    function addPackedMessage(
        bytes32 packedMessage_
    ) external override onlySocket {
        uint64 packetCount = _nextPacketCount;

        _roots[packetCount] = keccak256(
            abi.encode(_roots[packetCount], packedMessage_)
        );
        _chainLength++;

        if (_chainLength == _MAX_LEN) {
            _nextPacketCount++;
            _chainLength = 0;
        }

        emit MessageAdded(packedMessage_, packetCount, _roots[packetCount]);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./BaseCapacitor.sol";

/**
 * @title SingleCapacitor
 * @notice A capacitor that adds a single message to each packet.
 * @dev This contract inherits from the `BaseCapacitor` contract, which provides the
 * basic implementation for adding messages to packets, sealing packets and retrieving packet roots.
 */
contract SingleCapacitor is BaseCapacitor {
    /**
     * @notice Initializes the SingleCapacitor contract with a socket address.
     * @param socket_ The address of the socket contract
     * @param owner_ The address of the contract owner
     */
    constructor(
        address socket_,
        address owner_
    ) BaseCapacitor(socket_, owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @notice Adds a packed message to a packet and seals the packet after a single message has been added
     * @param packedMessage_ The packed message to be added to the packet
     */
    function addPackedMessage(
        bytes32 packedMessage_
    ) external override onlySocket {
        uint64 packetCount = _nextPacketCount;
        _roots[packetCount] = packedMessage_;
        _nextPacketCount++;

        // as it is a single capacitor, here root and packed message are same
        emit MessageAdded(packedMessage_, packetCount, packedMessage_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
        for (uint256 i = 0; i < len; i++) {
            generatedRoot = keccak256(abi.encode(generatedRoot, chain[i]));
            if (chain[i] == packedMessage_) isIncluded = true;
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
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

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
        uint256 msgGasLimit_,
        bytes32 extraParams_
    ) external payable {
        bytes memory payload = abi.encode(OP_ADD, amount_, msg.sender);

        _outbound(chainSlug_, msgGasLimit_, extraParams_, payload);
    }

    function remoteSubOperation(
        uint32 chainSlug_,
        uint256 amount_,
        uint256 msgGasLimit_,
        bytes32 extraParams_
    ) external payable {
        bytes memory payload = abi.encode(OP_SUB, amount_, msg.sender);
        _outbound(chainSlug_, msgGasLimit_, extraParams_, payload);
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
        uint256 msgGasLimit_,
        bytes32 extraParams_,
        bytes memory payload_
    ) private {
        ISocket(socket).outbound{value: msg.value}(
            targetChain_,
            msgGasLimit_,
            extraParams_,
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
pragma solidity 0.8.7;

import "../interfaces/IPlug.sol";
import "../interfaces/ISocket.sol";
import "../utils/Ownable.sol";

contract Messenger is IPlug, Ownable(msg.sender) {
    // immutables
    ISocket public immutable _socket__;
    uint256 public immutable _localChainSlug;

    bytes32 public _message;
    uint256 public _msgGasLimit;

    bytes32 public constant _PING = keccak256("PING");
    bytes32 public constant _PONG = keccak256("PONG");

    error NoSocketFee();

    constructor(address socket_, uint256 chainSlug_, uint256 msgGasLimit_) {
        _socket__ = ISocket(socket_);
        _localChainSlug = chainSlug_;

        _msgGasLimit = msgGasLimit_;
    }

    receive() external payable {}

    function updateMsgGasLimit(uint256 msgGasLimit_) external onlyOwner {
        _msgGasLimit = msgGasLimit_;
    }

    function removeGas(address payable receiver_) external onlyOwner {
        receiver_.transfer(address(this).balance);
    }

    function sendLocalMessage(bytes32 message_) external {
        _updateMessage(message_);
    }

    function sendRemoteMessage(
        uint32 remoteChainSlug_,
        bytes32 extraParams_,
        bytes32 message_
    ) external payable {
        bytes memory payload = abi.encode(_localChainSlug, message_);
        _outbound(remoteChainSlug_, extraParams_, payload);
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
        _outbound(remoteChainSlug, bytes32(0), newPayload);
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
        bytes32 extraParams_,
        bytes memory payload_
    ) private {
        uint256 fee = _socket__.getMinFees(
            _msgGasLimit,
            uint256(payload_.length),
            extraParams_,
            targetChain_,
            address(this)
        );
        if (!(address(this).balance >= fee)) revert NoSocketFee();
        _socket__.outbound{value: fee}(
            targetChain_,
            _msgGasLimit,
            extraParams_,
            payload_
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./interfaces/IExecutionManager.sol";
import "./interfaces/ISignatureVerifier.sol";
import "./libraries/RescueFundsLib.sol";
import "./libraries/FeesHelper.sol";
import "./utils/AccessControlExtended.sol";
import {WITHDRAW_ROLE, RESCUE_ROLE, GOVERNANCE_ROLE, EXECUTOR_ROLE, FEES_UPDATER_ROLE} from "./utils/AccessRoles.sol";
import {FEES_UPDATE_SIG_IDENTIFIER, RELATIVE_NATIVE_TOKEN_PRICE_UPDATE_SIG_IDENTIFIER, MSG_VALUE_MAX_THRESHOLD_SIG_IDENTIFIER, MSG_VALUE_MIN_THRESHOLD_SIG_IDENTIFIER} from "./utils/SigIdentifiers.sol";

/**
 * @title ExecutionManager
 * @dev Implementation of the IExecutionManager interface, providing functions for executing cross-chain transactions and
 * managing execution fees. This contract also implements the AccessControl interface, allowing for role-based
 * access control.
 */
contract ExecutionManager is IExecutionManager, AccessControlExtended {
    ISignatureVerifier public immutable signatureVerifier__;

    /**
     * @notice Emitted when the executionFees is updated
     * @param dstChainSlug The destination chain slug for which the executionFees is updated
     * @param executionFees The new executionFees
     */
    event ExecutionFeesSet(uint256 dstChainSlug, uint256 executionFees);

    event RelativeNativeTokenPriceSet(
        uint256 dstChainSlug,
        uint256 relativeNativeTokenPrice
    );

    event MsgValueMaxThresholdSet(
        uint256 dstChainSlug,
        uint256 msgValueMaxThresholdSet
    );
    event MsgValueMinThresholdSet(
        uint256 dstChainSlug,
        uint256 msgValueMinThresholdSet
    );

    uint32 public immutable chainSlug;

    // transmitter => nextNonce
    mapping(address => uint256) public nextNonce;

    // remoteChainSlug => executionFees
    mapping(uint32 => uint256) public executionFees;

    // destSlug => relativeNativePrice (stores (destnativeTokenPriceUSD*(1e18)/srcNativeTokenPriceUSD))
    mapping(uint32 => uint256) public relativeNativeTokenPrice;

    // mapping(uint32 => uint256) public baseGasUsed;

    mapping(uint32 => uint256) public msgValueMinThreshold;

    mapping(uint32 => uint256) public msgValueMaxThreshold;

    // msg.value*scrNativePrice >= relativeNativeTokenPrice[srcSlug][destinationSlug] * destMsgValue /10^18

    error InvalidNonce();
    error MsgValueTooLow();
    error MsgValueTooHigh();
    error PayloadTooLarge();
    error InsufficientMsgValue();

    /**
     * @dev Constructor for ExecutionManager contract
     * @param owner_ Address of the contract owner
     */
    constructor(
        address owner_,
        uint32 chainSlug_,
        ISignatureVerifier signatureVerifier_
    ) AccessControlExtended(owner_) {
        chainSlug = chainSlug_;
        signatureVerifier__ = signatureVerifier_;
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
        executor = signatureVerifier__.recoverSignerFromDigest(
            packedMessage,
            sig
        );
        isValidExecutor = _hasRole(EXECUTOR_ROLE, executor);
    }

    /**
     * @dev Function to be used for on-chain fee distribution later
     */
    function updateExecutionFees(address, uint256, bytes32) external override {}

    /**
     * @notice Function for paying fees for cross-chain transaction execution
     * @param msgGasLimit_ Gas limit for the transaction
     * @param siblingChainSlug_ Sibling chain identifier
     */
    function payFees(
        uint256 msgGasLimit_,
        uint32 siblingChainSlug_
    ) external payable override {}

    /**
     * @notice Function for getting the minimum fees required for executing a cross-chain transaction
     * @dev This function is called at source to calculate the execution cost.
     * @param siblingChainSlug_ Sibling chain identifier
     * @param payloadSize_ byte length of payload. Currently only used to check max length, later on will be used for fees calculation.
     * @param extraParams_ Can be used for providing extra information. Currently used for msgValue
     * @return Minimum fees required for executing the transaction
     */
    function getMinFees(
        uint256 gasLimit_,
        uint256 payloadSize_,
        bytes32 extraParams_,
        uint32 siblingChainSlug_
    ) external view override returns (uint256) {
        if (payloadSize_ > 3000) revert PayloadTooLarge();

        uint256 params = uint256(extraParams_);
        uint8 paramType = uint8(params >> 224);

        if (paramType == 0) return executionFees[siblingChainSlug_];

        uint256 msgValue = uint256(uint224(params));

        if (msgValue < msgValueMinThreshold[siblingChainSlug_])
            revert MsgValueTooLow();
        if (msgValue > msgValueMaxThreshold[siblingChainSlug_])
            revert MsgValueTooHigh();

        uint256 msgValueRequiredOnSrcChain = (relativeNativeTokenPrice[
            siblingChainSlug_
        ] * msgValue) / 1e18;
        return msgValueRequiredOnSrcChain + executionFees[siblingChainSlug_];
    }

    function verifyParams(
        bytes32 extraParams_,
        uint256 msgValue_
    ) external pure override {
        uint256 params = uint256(extraParams_);
        uint8 paramType = uint8(params >> 224);

        if (paramType == 0) return;

        uint256 expectedMsgValue = uint256(uint224(params));

        if (msgValue_ < expectedMsgValue) revert InsufficientMsgValue();
    }

    function setExecutionFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 executionFees_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    FEES_UPDATE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    dstChainSlug_,
                    nonce_,
                    executionFees_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, dstChainSlug_, feesUpdater);

        uint256 nonce = nextNonce[feesUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        executionFees[dstChainSlug_] = executionFees_;
        emit ExecutionFeesSet(dstChainSlug_, executionFees_);
    }

    function setRelativeNativeTokenPrice(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 relativeNativeTokenPrice_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    RELATIVE_NATIVE_TOKEN_PRICE_UPDATE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    dstChainSlug_,
                    nonce_,
                    relativeNativeTokenPrice_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, dstChainSlug_, feesUpdater);

        uint256 nonce = nextNonce[feesUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        relativeNativeTokenPrice[dstChainSlug_] = relativeNativeTokenPrice_;
        emit RelativeNativeTokenPriceSet(
            dstChainSlug_,
            relativeNativeTokenPrice_
        );
    }

    function setMsgValueMinThreshold(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 msgValueMinThreshold_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    MSG_VALUE_MIN_THRESHOLD_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    dstChainSlug_,
                    nonce_,
                    msgValueMinThreshold_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, dstChainSlug_, feesUpdater);

        uint256 nonce = nextNonce[feesUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        msgValueMinThreshold[dstChainSlug_] = msgValueMinThreshold_;
        emit MsgValueMinThresholdSet(dstChainSlug_, msgValueMinThreshold_);
    }

    function setMsgValueMaxThreshold(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 msgValueMaxThreshold_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    MSG_VALUE_MAX_THRESHOLD_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    dstChainSlug_,
                    nonce_,
                    msgValueMaxThreshold_
                )
            ),
            signature_
        );

        _checkRoleWithSlug(FEES_UPDATER_ROLE, dstChainSlug_, feesUpdater);

        uint256 nonce = nextNonce[feesUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        msgValueMaxThreshold[dstChainSlug_] = msgValueMaxThreshold_;
        emit MsgValueMaxThresholdSet(dstChainSlug_, msgValueMaxThreshold_);
    }

    /**
     * @notice withdraws fees from contract
     * @param account_ withdraw fees to
     */
    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        FeesHelper.withdrawFees(account_);
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
pragma solidity 0.8.7;

/**
 * @title ICapacitor
 * @dev Interface for a Capacitor contract that stores and manages messages in packets
 */
interface ICapacitor {
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
     * @notice adds the packed message to a packet
     * @dev this should be only executable by socket
     * @dev it will be later replaced with a function adding each message to a merkle tree
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
     * @notice seals the packet
     * @dev also indicates the packet is ready to be shipped and no more messages can be added now.
     * @dev this should be executable by socket only
     * @param batchSize_ later to be used with packet batching capacitors
     * @return root root hash of the packet
     * @return packetCount id of the packed sealed
     */
    function sealPacket(
        uint256 batchSize_
    ) external returns (bytes32 root, uint64 packetCount);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

/**
 * @title IDecapacitor interface
 * @notice Interface for a contract that verifies if a packed message is part of a packet or not
 */
interface IDecapacitor {
    /**
     * @notice returns if the packed message is the part of a packet or not
     * @param root_ root hash of the packet
     * @param packedMessage_ packed message which needs to be verified
     * @param proof_ proof used to determine the inclusion
     */
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata proof_
    ) external pure returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

/**
 * @title Execution Manager Interface
 * @dev This interface defines the functions for managing and executing transactions on external chains
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
     * @param msgGasLimit The gas limit for the transaction
     * @param dstSlug The destination slug
     */
    function payFees(uint256 msgGasLimit, uint32 dstSlug) external payable;

    /**
     * @notice Returns the minimum fees required for executing a transaction on the external chain
     * @param msgGasLimit_ msgGasLimit_
     * @param siblingChainSlug_ The destination slug
     * @return The minimum fees required for executing the transaction
     */
    function getMinFees(
        uint256 msgGasLimit_,
        uint256 payloadSize_,
        bytes32 extraParams_,
        uint32 siblingChainSlug_
    ) external view returns (uint256);

    /**
     * @notice Updates the execution fees for an executor and message ID
     * @param executor The executor address
     * @param executionFees The execution fees to update
     * @param msgId The ID of the message
     */
    function updateExecutionFees(
        address executor,
        uint256 executionFees,
        bytes32 msgId
    ) external;

    function setExecutionFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 executionFees_,
        bytes calldata signature_
    ) external;

    function setMsgValueMinThreshold(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 msgValueMinThreshold_,
        bytes calldata signature_
    ) external;

    function setMsgValueMaxThreshold(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 msgValueMaxThreshold_,
        bytes calldata signature_
    ) external;

    function setRelativeNativeTokenPrice(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 relativeNativeTokenPrice_,
        bytes calldata signature_
    ) external;

    function verifyParams(
        bytes32 extraParams_,
        uint256 msgValue_
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

/**
 * @title INativeRelay
 * @notice Interface for the NativeRelay contract which is used to relay packets between two chains.
 * It allows for the reception of messages on the PolygonRootReceiver and the initiation of native confirmations
 * for the given packet ID.
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
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
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
pragma solidity 0.8.7;

/**
 * @title IPlug
 * @notice Interface for a plug contract that executes the message received from a source chain.
 */
interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint32 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

/**
 * @title Signature Verifier
 * @notice Verifies the signatures and returns the address of signer recovered from the input signature or digest.
 */
interface ISignatureVerifier {
    /**
     * @notice returns the address of signer recovered from input signature
     * @param dstChainSlug_ remote chain slug
     * @param packetId_ packet id
     * @param root_ root hash of packet
     * @param signature_ signature
     */
    function recoverSigner(
        uint32 dstChainSlug_,
        bytes32 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external pure returns (address signer);

    /**
     * @notice returns the address of signer recovered from input signature and digest
     */
    function recoverSignerFromDigest(
        bytes32 digest_,
        bytes memory signature_
    ) external pure returns (address signer);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
        uint256 transmissionFees;
        uint256 switchboardFees;
        uint256 executionFee;
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
        uint256 msgGasLimit;
        bytes32 extraParams;
        // The payload data to be executed in the message.
        bytes payload;
        // The proof data required by the Decapacitor contract to verify the message's authenticity.
        bytes decapacitorProof;
    }

    /**
     * @notice emits the message details when a new message arrives at outbound
     * @param localChainSlug local chain slug
     * @param localPlug local plug address
     * @param dstChainSlug remote chain slug
     * @param dstPlug remote plug address
     * @param msgId message id packed with remoteChainSlug and nonce
     * @param msgGasLimit gas limit needed to execute the inbound at remote
     * @param payload the data which will be used by inbound at remote
     */
    event MessageOutbound(
        uint32 localChainSlug,
        address localPlug,
        uint32 dstChainSlug,
        address dstPlug,
        bytes32 msgId,
        uint256 msgGasLimit,
        bytes32 extraParams,
        bytes payload,
        Fees fees
    );

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     */
    event ExecutionSuccess(bytes32 msgId);

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     * @param result if message reverts, returns the revert message
     */
    event ExecutionFailed(bytes32 msgId, string result);

    /**
     * @notice emits the error message in bytes after inbound call
     * @param msgId msg id which is executed
     * @param result if message reverts, returns the revert message in bytes
     */
    event ExecutionFailedBytes(bytes32 msgId, bytes result);

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
     * @notice emits when a new transmitManager contract is set
     * @param transmitManager address of new transmitManager contract
     */
    event TransmitManagerSet(address transmitManager);

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint32 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes32 extraParams_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    /**
     * @notice executes a message
     * @param packetId packet id
     * @param messageDetails_ the details needed for message verification
     */
    function execute(
        bytes32 packetId,
        ISocket.MessageDetails calldata messageDetails_,
        bytes memory signature
    ) external payable;

    /**
     * @notice seals data in capacitor for specific batchSizr
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
     * @param signature_ signed Data needed for verification
     */
    function propose(
        bytes32 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external;

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
     * @notice Registers a switchboard with a specified max packet length, sibling chain slug, and capacitor type.
     * @param siblingChainSlug_ The slug of the sibling chain that the switchboard is registered with.
     * @param maxPacketLength_ The maximum length of a packet allowed by the switchboard.
     * @param capacitorType_ The type of capacitor that the switchboard uses.
     */
    function registerSwitchBoard(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_
    ) external returns (address capacitor);

    /**
     * @notice Retrieves the packet id roots for a specified packet id.
     * @param packetId_ The packet id for which to retrieve the packet id roots.
     * @return The packet id roots for the specified packet id.
     */
    function packetIdRoots(bytes32 packetId_) external view returns (bytes32);

    /**
     * @notice Retrieves the minimum fees required for a message with a specified gas limit and destination chain.
     * @param msgGasLimit_ The gas limit of the message.
     * @param remoteChainSlug_ The slug of the destination chain for the message.
     * @param plug_ The address of the plug through which the message is sent.
     * @return totalFees The minimum fees required for the specified message.
     */
    function getMinFees(
        uint256 msgGasLimit_,
        uint256 payloadSize_,
        bytes32 extraParams_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view returns (uint256 totalFees);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
     */
    function registerSiblingSlug(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_
    ) external;

    /**
     * @notice Checks if a packet can be allowed to go through the switchboard.
     * @param root the packet root.
     * @param packetId The unique identifier for the packet.
     * @param srcChainSlug The unique identifier for the source chain of the packet.
     * @param proposeTime The time when the packet was proposed.
     * @return A boolean indicating whether the packet is allowed to go through the switchboard or not.
     */
    function allowPacket(
        bytes32 root,
        bytes32 packetId,
        uint32 srcChainSlug,
        uint256 proposeTime
    ) external view returns (bool);

    /**
     * @notice Pays the fees required for the destination chain to process the packet.
     * @dev The fees are paid by the sender of the packet to the switchboard contract.
     * @param dstChainSlug The unique identifier for the destination chain of the packet.
     */
    function payFees(uint32 dstChainSlug) external payable;

    /**
     * @notice Retrieves the minimum fees required for the destination chain to process the packet.
     * @param dstChainSlug the unique identifier for the destination chain of the packet.
     * @return switchboardFee the switchboard fee required for the destination chain to process the packet.
     * @return verificationFee the verification fee required for the destination chain to process the packet.
     */
    function getMinFees(
        uint32 dstChainSlug
    ) external view returns (uint256 switchboardFee, uint256 verificationFee);

    function setFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 verificationFees_,
        uint256 switchboardFees_,
        bytes calldata signature_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
     * @notice Pays the fees required for the destination chain to process the packet.
     * @dev The fees are paid by the sender of the packet to the transmit manager contract.
     * @param dstSlug The unique identifier for the destination chain of the packet.
     */
    function payFees(uint32 dstSlug) external payable;

    /**
     * @notice Retrieves the minimum fees required for the destination chain to process the packet.
     * @param dstSlug The unique identifier for the destination chain of the packet.
     * @return The minimum fee required for the destination chain to process the packet.
     */
    function getMinFees(uint32 dstSlug) external view returns (uint256);

    function setTransmissionFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 transmissionFees_,
        bytes calldata signature_
    ) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

/**
 * @title FeesHelper
 * @dev A library for managing fee collection and distribution.
 * @dev This contract will be further developed to support fee distribution to various
 * participants of the system
 */
library FeesHelper {
    error TransferFailed();
    event FeesWithdrawn(address account, uint256 amount);

    /**
     * @dev Transfers the fees collected to the specified address.
     * @notice The caller of this function must have the required funds.
     * @param account_ The address to transfer ETH to.
     */
    function withdrawFees(address account_) internal {
        require(account_ != address(0));

        uint256 amount = address(this).balance;
        (bool success, ) = account_.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit FeesWithdrawn(account_, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./SafeTransferLib.sol";

/**
 * @title RescueFundsLib
 * @dev A library that provides a function to rescue funds from a contract.
 */
library RescueFundsLib {
    using SafeTransferLib for IERC20;

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
        require(userAddress_ != address(0));

        if (token_ == ETH_ADDRESS) {
            (bool success, ) = userAddress_.call{value: amount_}("");
            require(success);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            IERC20(token_).safeTransfer(userAddress_, amount_);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
/// @dev Note This contract is only used in RescueFunds library for now.
library SafeTransferLib {
    function safeTransfer(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to_) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount_) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token_, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

/**
 * @title SignatureVerifierLib
 * @notice A library for verifying signatures and recovering the signer's address from a message digest.
 * @dev This library provides functions for recovering the signer's address from a message digest, splitting a signature into its v, r, and s components, and verifying that the signature is valid. The message digest is created by hashing the concatenation of the destination chain slug, packet ID, and packet data root. The signature must be a 65-byte array, containing the v, r, and s components.
 */
library SignatureVerifierLib {
    /*
     * @dev Error thrown when signature length is invalid
     */
    error InvalidSigLength();

    /**
     * @notice recovers the signer's address from a message digest and signature
     * @param dstChainSlug_ The destination chain slug of the packet
     * @param packetId_ The ID of the packet
     * @param root_ The root hash of the packet data
     * @param signature_ The signature to be verified
     * @return signer The address of the signer
     */
    function recoverSigner(
        uint32 dstChainSlug_,
        bytes32 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) internal pure returns (address signer) {
        bytes32 digest = keccak256(abi.encode(dstChainSlug_, packetId_, root_));
        signer = recoverSignerFromDigest(digest, signature_);
    }

    /**
     * @notice returns the address of signer recovered from input signature and digest
     * @param digest_ The message digest to be signed
     * @param signature_ The signature to be verified
     * @return signer The address of the signer
     */
    function recoverSignerFromDigest(
        bytes32 digest_,
        bytes memory signature_
    ) internal pure returns (address signer) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest_)
        );
        (bytes32 sigR, bytes32 sigS, uint8 sigV) = _splitSignature(signature_);

        // recovered signer is checked for the valid roles later
        signer = ecrecover(digest, sigV, sigR, sigS);
    }

    /**
     * @notice splits the signature into v, r and s.
     * @param signature_ The signature to be split
     * @return r The r component of the signature
     * @return s The s component of the signature
     * @return v The v component of the signature
     */
    function _splitSignature(
        bytes memory signature_
    ) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (signature_.length != 65) revert InvalidSigLength();
        assembly {
            r := mload(add(signature_, 0x20))
            s := mload(add(signature_, 0x40))
            v := byte(0, mload(add(signature_, 0x60)))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

import "../utils/Ownable.sol";

contract MockOwnable is Ownable {
    constructor(address owner_) Ownable(owner_) {}

    function ownerFunction() external onlyOwner {}

    function publicFunction() external {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;
import "./ExecutionManager.sol";

/**
 * @title OpenExecutionManager
 * @dev ExecutionManager contract along with open execution
 */
contract OpenExecutionManager is ExecutionManager {
    constructor(
        address owner_,
        uint32 chainSlug_,
        ISignatureVerifier signatureVerifier_
    ) ExecutionManager(owner_, chainSlug_, signatureVerifier_) {}

    /**
     * @notice This function allows all executors
     * @param packedMessage Packed message to be executed
     * @param sig Signature of the message
     * @return executor Address of the executor
     * @return isValidExecutor Boolean value indicating whether the executor is valid or not
     */
    function isExecutor(
        bytes32 packedMessage,
        bytes memory sig
    ) external view override returns (address executor, bool isValidExecutor) {
        executor = signatureVerifier__.recoverSignerFromDigest(
            packedMessage,
            sig
        );
        isValidExecutor = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./SocketDst.sol";
import "../libraries/RescueFundsLib.sol";

import {SocketSrc} from "./SocketSrc.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

/**
 * @title Socket
 * @notice A contract that acts as both a source and destination of cross-chain transactions.
 * @dev This contract inherits from SocketSrc and SocketDst
 */
contract Socket is SocketSrc, SocketDst {
    /*
     * @notice constructor for creating a new Socket contract instance.
     * @param chainSlug_ The unique identifier of the chain this socket belongs to.
     * @param hasher_ The address of the Hasher contract used to hash the messages before transmitting them.
     * @param transmitManager_ The address of the TransmitManager contract responsible for transmitting messages.
     * @param executionManager_ The address of the ExecutionManager contract responsible for executing transactions.
     * @param capacitorFactory_ The address of the CapacitorFactory contract used to create new Capacitor contracts.
     * @param owner_ The address of the owner who has the initial admin role.
     */
    constructor(
        uint32 chainSlug_,
        address hasher_,
        address transmitManager_,
        address executionManager_,
        address capacitorFactory_,
        address owner_,
        string memory version_
    ) AccessControlExtended(owner_) SocketBase(chainSlug_, version_) {
        hasher__ = IHasher(hasher_);
        transmitManager__ = ITransmitManager(transmitManager_);
        executionManager__ = IExecutionManager(executionManager_);
        capacitorFactory__ = ICapacitorFactory(capacitorFactory_);
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
pragma solidity 0.8.7;

import "../interfaces/IHasher.sol";
import "./SocketConfig.sol";

/**
 * @title SocketBase
 * @notice A contract that is responsible for the governance setters and inherits SocketConfig
 */
abstract contract SocketBase is SocketConfig {
    IHasher public hasher__;
    ITransmitManager public transmitManager__;
    IExecutionManager public executionManager__;

    uint32 public immutable chainSlug;
    // incrementing nonce, should be handled in next socket version.
    uint64 public messageCount;

    bytes32 public immutable version;

    /**
     * @dev Constructs a new Socket contract instance.
     * @param chainSlug_ The chain slug of the contract.
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
     * @notice updates hasher_
     * @param hasher_ address of hasher
     */
    function setHasher(address hasher_) external onlyRole(GOVERNANCE_ROLE) {
        hasher__ = IHasher(hasher_);
        emit HasherSet(hasher_);
    }

    /**
     * @notice updates transmitManager_
     * @param transmitManager_ address of Transmit Manager
     */
    function setTransmitManager(
        address transmitManager_
    ) external onlyRole(GOVERNANCE_ROLE) {
        transmitManager__ = ITransmitManager(transmitManager_);
        emit TransmitManagerSet(transmitManager_);
    }

    /**
     * @notice updates executionManager_
     * @param executionManager_ address of Execution Manager
     */
    function setExecutionManager(
        address executionManager_
    ) external onlyRole(GOVERNANCE_ROLE) {
        executionManager__ = IExecutionManager(executionManager_);
        emit ExecutionManagerSet(executionManager_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../libraries/RescueFundsLib.sol";
import "../utils/AccessControl.sol";

import {ISocket} from "../interfaces/ISocket.sol";
import {ITransmitManager} from "../interfaces/ITransmitManager.sol";
import {IExecutionManager} from "../interfaces/IExecutionManager.sol";

import {FastSwitchboard} from "../switchboard/default-switchboards/FastSwitchboard.sol";
import {INativeRelay} from "../interfaces/INativeRelay.sol";

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
     * @param signature The signature of the packet data.
     */
    struct ProposeRequest {
        bytes32 packetId;
        bytes32 root;
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
        bytes signature;
    }

    /**
     * @notice A struct representing a request to execute a packet.
     * @param packetId The ID of the packet to be executed.
     * @param localPlug The address of the local plug contract.
     * @param messageDetails The message details of the packet.
     * @param signature The signature of the packet data.
     */
    struct ExecuteRequest {
        bytes32 packetId;
        ISocket.MessageDetails messageDetails;
        bytes signature;
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
        uint256 switchboardFees;
        uint256 verificationFees;
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
        uint256 fees;
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
        uint256 executeRequestslength = switchboardSetFeesRequest_.length;
        for (uint256 index = 0; index < executeRequestslength; ) {
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
        uint256 executeRequestslength = setFeesRequests_.length;
        for (uint256 index = 0; index < executeRequestslength; ) {
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
        uint256 executeRequestslength = setFeesRequests_.length;
        for (uint256 index = 0; index < executeRequestslength; ) {
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
        uint256 sealRequestslength = sealRequests_.length;
        for (uint256 index = 0; index < sealRequestslength; ) {
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
        uint256 proposeRequestslength = proposeRequests_.length;
        for (uint256 index = 0; index < proposeRequestslength; ) {
            ISocket(socketAddress_).propose(
                proposeRequests_[index].packetId,
                proposeRequests_[index].root,
                proposeRequests_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice attests a batch of Packets
     * @param switchBoardAddress_ address of switchboard
     * @param attestRequests_ the list of requests with packets to be attested by switchboard in sequence
     */
    function attestBatch(
        address switchBoardAddress_,
        AttestRequest[] calldata attestRequests_
    ) external {
        uint256 attestRequestslength = attestRequests_.length;
        for (uint256 index = 0; index < attestRequestslength; ) {
            FastSwitchboard(switchBoardAddress_).attest(
                attestRequests_[index].packetId,
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
        uint256 executeRequestslength = executeRequests_.length;
        for (uint256 index = 0; index < executeRequestslength; ) {
            bytes32 extraParams = executeRequests_[index]
                .messageDetails
                .extraParams;
            uint256 msgValue = uint256(uint224(uint256(extraParams)));

            ISocket(socketAddress_).execute{value: msgValue}(
                executeRequests_[index].packetId,
                executeRequests_[index].messageDetails,
                executeRequests_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice invoke receieve Message on PolygonRootReceiver for a batch of messages in loop
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

        if (address(this).balance > 0)
            callValueRefundAddress_.call{value: address(this).balance}("");
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
pragma solidity 0.8.7;

import "../interfaces/ISocket.sol";
import "../interfaces/ICapacitorFactory.sol";
import "../interfaces/ISwitchboard.sol";
import "../utils/AccessControlExtended.sol";

import {GOVERNANCE_ROLE} from "../utils/AccessRoles.sol";

/**
 * @title SocketConfig
 * @notice An abstract contract for configuring socket connections between different chains
 * @dev This contract is meant to be inherited by other contracts that require socket configuration functionality
 */
abstract contract SocketConfig is ISocket, AccessControlExtended {
    /**
     * @dev Struct to hold the configuration for a plug connection
     */
    struct PlugConfig {
        // address of the sibling plug on the remote chain
        address siblingPlug;
        // capacitor instance for the plug connection
        ICapacitor capacitor__;
        // decapacitor instance for the plug connection
        IDecapacitor decapacitor__;
        // inbound switchboard instance for the plug connection
        ISwitchboard inboundSwitchboard__;
        // outbound switchboard instance for the plug connection
        ISwitchboard outboundSwitchboard__;
    }

    // Capacitor factory contract
    ICapacitorFactory public capacitorFactory__;

    // capacitor address => siblingChainSlug
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
    // Event triggered when the capacitor factory is set
    event CapacitorFactorySet(address capacitorFactory);

    // Error triggered when a switchboard already exists
    error SwitchboardExists();
    // Error triggered when a connection is invalid
    error InvalidConnection();

    /**
     * @dev Set the capacitor factory contract
     * @param capacitorFactory_ The address of the capacitor factory contract
     */
    function setCapacitorFactory(
        address capacitorFactory_
    ) external onlyRole(GOVERNANCE_ROLE) {
        capacitorFactory__ = ICapacitorFactory(capacitorFactory_);
        emit CapacitorFactorySet(capacitorFactory_);
    }

    /**
     * @dev Register a switchboard with the given configuration
     * @dev This function is called from switchboard
     * @param maxPacketLength_ The maximum packet length supported by the switchboard
     * @param siblingChainSlug_ The sibling chain slug to register the switchboard with
     * @param capacitorType_ The type of capacitor to use for the switchboard
     */
    function registerSwitchBoard(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_
    ) external override returns (address capacitor) {
        address switchBoardAddress = msg.sender;
        // only capacitor checked, decapacitor assumed will exist if capacitor does
        if (
            address(capacitors__[switchBoardAddress][siblingChainSlug_]) !=
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

        capacitorToSlug[address(capacitor__)] = siblingChainSlug_;
        capacitors__[switchBoardAddress][siblingChainSlug_] = capacitor__;
        decapacitors__[switchBoardAddress][siblingChainSlug_] = decapacitor__;

        emit SwitchboardAdded(
            switchBoardAddress,
            siblingChainSlug_,
            address(capacitor__),
            address(decapacitor__),
            maxPacketLength_,
            capacitorType_
        );

        return address(capacitor__);
    }

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
    ) external override {
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
            _plugConfig.siblingPlug,
            address(_plugConfig.inboundSwitchboard__),
            address(_plugConfig.outboundSwitchboard__),
            address(_plugConfig.capacitor__),
            address(_plugConfig.decapacitor__)
        );
    }

    /**
     * @notice returns the config for given plug and sibling
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
pragma solidity 0.8.7;

import "../interfaces/IDecapacitor.sol";
import "../interfaces/IExecutionManager.sol";
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
     * @dev Error emitted when a packet has already been proposed
     */
    error AlreadyProposed();

    /*
     * @dev Error emitted when a packet has not been proposed
     */
    error PacketNotProposed();
    /*
     * @dev Error emitted when a packet root is invalid
     */
    error InvalidPacketRoot();
    /*
     * @dev Error emitted when a packet id is invalid
     */
    error InvalidPacketId();

    /**
     * @dev Error emitted when proof is invalid
     */
    error InvalidProof();
    /**
     * @dev Error emitted when a retry is invalid
     */
    error InvalidRetry();

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
     * @dev msgId => message status mapping
     */
    mapping(bytes32 => bool) public messageExecuted;
    /**
     * @dev capacitorAddr|chainSlug|packetId mapping to packetIdRoots
     */
    mapping(bytes32 => bytes32) public override packetIdRoots;
    mapping(bytes32 => uint256) public rootProposedAt;

    /**
     * @notice emits the packet details when proposed at remote
     * @param transmitter address of transmitter
     * @param packetId packet id
     * @param root packet root
     */
    event PacketProposed(
        address indexed transmitter,
        bytes32 indexed packetId,
        bytes32 root
    );

    /**
     * @notice emits the root details when root is replaced by owner
     * @param packetId packet id
     * @param oldRoot old root
     * @param newRoot old root
     */
    event PacketRootUpdated(bytes32 packetId, bytes32 oldRoot, bytes32 newRoot);

    /**
     * @dev Function to propose a packet
     * @param packetId_ Packet ID
     * @param root_ Packet root
     * @param signature_ Signature
     */
    function propose(
        bytes32 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external override {
        if (packetId_ == bytes32(0)) revert InvalidPacketId();
        if (packetIdRoots[packetId_] != bytes32(0)) revert AlreadyProposed();

        (address transmitter, bool isTransmitter) = transmitManager__
            .checkTransmitter(
                uint32(_decodeSlug(packetId_)),
                keccak256(abi.encode(version, chainSlug, packetId_, root_)),
                signature_
            );

        if (!isTransmitter) revert InvalidTransmitter();

        packetIdRoots[packetId_] = root_;
        rootProposedAt[packetId_] = block.timestamp;

        emit PacketProposed(transmitter, packetId_, root_);
    }

    /**
     * @notice executes a message, fees will go to recovered executor address
     * @param packetId_ packet id
     * @param messageDetails_ the details needed for message verification
     */
    function execute(
        bytes32 packetId_,
        ISocket.MessageDetails calldata messageDetails_,
        bytes memory signature_
    ) external payable override {
        if (messageExecuted[messageDetails_.msgId])
            revert MessageAlreadyExecuted();
        messageExecuted[messageDetails_.msgId] = true;

        if (packetId_ == bytes32(0)) revert InvalidPacketId();
        if (packetIdRoots[packetId_] == bytes32(0)) revert PacketNotProposed();

        uint32 remoteSlug = _decodeSlug(messageDetails_.msgId);
        if (_decodeSlug(packetId_) != remoteSlug)
            revert ErrInSourceValidation();

        address localPlug = _decodePlug(messageDetails_.msgId);

        PlugConfig storage plugConfig = _plugConfigs[localPlug][remoteSlug];

        bytes32 packedMessage = hasher__.packMessage(
            remoteSlug,
            plugConfig.siblingPlug,
            chainSlug,
            localPlug,
            messageDetails_
        );

        (address executor, bool isValidExecutor) = executionManager__
            .isExecutor(packedMessage, signature_);
        if (!isValidExecutor) revert NotExecutor();

        _verify(
            packetId_,
            remoteSlug,
            packedMessage,
            plugConfig,
            messageDetails_.decapacitorProof,
            messageDetails_.extraParams
        );
        _execute(executor, localPlug, remoteSlug, messageDetails_);
    }

    function _verify(
        bytes32 packetId_,
        uint32 remoteChainSlug_,
        bytes32 packedMessage_,
        PlugConfig storage plugConfig_,
        bytes memory decapacitorProof_,
        bytes32 extraParams_
    ) internal view {
        if (
            !ISwitchboard(plugConfig_.inboundSwitchboard__).allowPacket(
                packetIdRoots[packetId_],
                packetId_,
                uint32(remoteChainSlug_),
                rootProposedAt[packetId_]
            )
        ) revert VerificationFailed();

        if (
            !plugConfig_.decapacitor__.verifyMessageInclusion(
                packetIdRoots[packetId_],
                packedMessage_,
                decapacitorProof_
            )
        ) revert InvalidProof();

        executionManager__.verifyParams(extraParams_, msg.value);
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
        ISocket.MessageDetails memory messageDetails_
    ) internal {
        try
            IPlug(localPlug_).inbound{
                gas: messageDetails_.msgGasLimit,
                value: msg.value
            }(remoteChainSlug_, messageDetails_.payload)
        {
            executionManager__.updateExecutionFees(
                executor_,
                messageDetails_.executionFee,
                messageDetails_.msgId
            );
            emit ExecutionSuccess(messageDetails_.msgId);
        } catch Error(string memory reason) {
            // catch failing revert() and require()
            messageExecuted[messageDetails_.msgId] = false;
            emit ExecutionFailed(messageDetails_.msgId, reason);
        } catch (bytes memory reason) {
            // catch failing assert()
            messageExecuted[messageDetails_.msgId] = false;
            emit ExecutionFailedBytes(messageDetails_.msgId, reason);
        }
    }

    /**
     * @dev Checks whether the specified packet has been proposed.
     * @param packetId_ The ID of the packet to check.
     * @return A boolean indicating whether the packet has been proposed or not.
     */
    function isPacketProposed(bytes32 packetId_) external view returns (bool) {
        return packetIdRoots[packetId_] == bytes32(0) ? false : true;
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
pragma solidity 0.8.7;

import "../interfaces/ICapacitor.sol";
import "./SocketBase.sol";

/**
 * @title SocketSrc
 * @dev The SocketSrc contract inherits from SocketBase and provides the functionality to send messages from the local chain to a remote chain via a Capacitor.
 */
abstract contract SocketSrc is SocketBase {
    error InsufficientFees();

    /**
     * @notice emits the verification and seal confirmation of a packet
     * @param transmitter address of transmitter recovered from sig
     * @param packetId packed id
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
     * @param remoteChainSlug_ the remote chain slug
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint32 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes32 extraParams_,
        bytes calldata payload_
    ) external payable override returns (bytes32 msgId) {
        PlugConfig memory plugConfig = _plugConfigs[msg.sender][
            remoteChainSlug_
        ];

        msgId = _encodeMsgId(chainSlug, plugConfig.siblingPlug);

        ISocket.Fees memory fees = _validateAndGetFees(
            msgGasLimit_,
            uint256(payload_.length),
            extraParams_,
            uint32(remoteChainSlug_),
            plugConfig.outboundSwitchboard__
        );

        ISocket.MessageDetails memory messageDetails;
        messageDetails.msgId = msgId;
        messageDetails.msgGasLimit = msgGasLimit_;
        messageDetails.extraParams = extraParams_;
        messageDetails.payload = payload_;
        messageDetails.executionFee = fees.executionFee;

        bytes32 packedMessage = hasher__.packMessage(
            chainSlug,
            msg.sender,
            remoteChainSlug_,
            plugConfig.siblingPlug,
            messageDetails
        );

        plugConfig.capacitor__.addPackedMessage(packedMessage);

        _sendFees(
            msgGasLimit_,
            uint32(remoteChainSlug_),
            plugConfig.outboundSwitchboard__,
            fees
        );

        emit MessageOutbound(
            chainSlug,
            msg.sender,
            remoteChainSlug_,
            plugConfig.siblingPlug,
            msgId,
            msgGasLimit_,
            extraParams_,
            payload_,
            fees
        );
    }

    /**
     * @dev Calculates fees needed for message transmission and execution and checks if msg value is enough
     * @param msgGasLimit_ The gas limit needed to execute the payload on the remote chain
     * @param remoteChainSlug_ The slug of the remote chain
     * @param switchboard__ The address of the switchboard contract
     * @return fees The fees object
     */
    function _validateAndGetFees(
        uint256 msgGasLimit_,
        uint256 payloadSize_,
        bytes32 extraParams_,
        uint32 remoteChainSlug_,
        ISwitchboard switchboard__
    ) internal returns (Fees memory fees) {
        uint256 minExecutionFees;
        (
            fees.transmissionFees,
            fees.switchboardFees,
            minExecutionFees
        ) = _getMinFees(
            msgGasLimit_,
            payloadSize_,
            extraParams_,
            remoteChainSlug_,
            switchboard__
        );

        if (
            msg.value <
            fees.transmissionFees + fees.switchboardFees + minExecutionFees
        ) revert InsufficientFees();

        unchecked {
            // any extra fee is considered as executionFee
            fees.executionFee =
                msg.value -
                fees.transmissionFees -
                fees.switchboardFees;
        }
    }

    /**
     * @dev Deducts the fees needed for message transmission and execution
     * @param msgGasLimit_ The gas limit needed to execute the payload on the remote chain
     * @param remoteChainSlug_ The slug of the remote chain
     * @param switchboard__ The address of the switchboard contract
     * @param fees_ The fees object
     */
    function _sendFees(
        uint256 msgGasLimit_,
        uint32 remoteChainSlug_,
        ISwitchboard switchboard__,
        Fees memory fees_
    ) internal {
        transmitManager__.payFees{value: fees_.transmissionFees}(
            remoteChainSlug_
        );
        executionManager__.payFees{value: fees_.executionFee}(
            msgGasLimit_,
            remoteChainSlug_
        );

        // call to unknown external contract at the end
        switchboard__.payFees{value: fees_.switchboardFees}(remoteChainSlug_);
    }

    /**
     * @notice Retrieves the minimum fees required for a message with a specified gas limit and destination chain.
     * @param msgGasLimit_ The gas limit of the message.
     * @param remoteChainSlug_ The slug of the destination chain for the message.
     * @param plug_ The address of the plug through which the message is sent.
     * @return totalFees The minimum fees required for the specified message.
     */
    function getMinFees(
        uint256 msgGasLimit_,
        uint256 payloadSize_,
        bytes32 extraParams_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view override returns (uint256 totalFees) {
        PlugConfig storage plugConfig = _plugConfigs[plug_][remoteChainSlug_];

        (
            uint256 transmissionFees,
            uint256 switchboardFees,
            uint256 executionFee
        ) = _getMinFees(
                msgGasLimit_,
                payloadSize_,
                extraParams_,
                remoteChainSlug_,
                plugConfig.outboundSwitchboard__
            );

        totalFees = transmissionFees + switchboardFees + executionFee;
    }

    function _getMinFees(
        uint256 msgGasLimit_,
        uint256 payloadSize_,
        bytes32 extraParams_,
        uint32 remoteChainSlug_,
        ISwitchboard switchboard__
    )
        internal
        view
        returns (
            uint256 transmissionFees,
            uint256 switchboardFees,
            uint256 executionFee
        )
    {
        transmissionFees = transmitManager__.getMinFees(remoteChainSlug_);

        uint256 verificationFee;
        (switchboardFees, verificationFee) = switchboard__.getMinFees(
            remoteChainSlug_
        );
        uint256 msgExecutionFee = executionManager__.getMinFees(
            msgGasLimit_,
            payloadSize_,
            extraParams_,
            remoteChainSlug_
        );

        executionFee = msgExecutionFee + verificationFee;
    }

    /**
     * @notice seals data in capacitor for specific batchSizr
     * @param batchSize_ size of batch to be sealed
     * @param capacitorAddress_ address of capacitor
     * @param signature_ signed Data needed for verification
     */
    function seal(
        uint256 batchSize_,
        address capacitorAddress_,
        bytes calldata signature_
    ) external payable override {
        (bytes32 root, uint64 packetCount) = ICapacitor(capacitorAddress_)
            .sealPacket(batchSize_);

        bytes32 packetId = _encodePacketId(capacitorAddress_, packetCount);

        uint32 siblingChainSlug = capacitorToSlug[capacitorAddress_];
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
    // messageCount++ will take care of msg id overflow as well
    // msgId(256) = localChainSlug(32) | siblingPlug_(160) | nonce(64)
    function _encodeMsgId(
        uint32 slug_,
        address siblingPlug_
    ) internal returns (bytes32) {
        return
            bytes32(
                (uint256(slug_) << 224) |
                    (uint256(uint160(siblingPlug_)) << 64) |
                    messageCount++
            );
    }

    function _encodePacketId(
        address capacitorAddress_,
        uint256 packetCount_
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
pragma solidity 0.8.7;

import "./SwitchboardBase.sol";

/**
 * @title FastSwitchboard contract
 * @dev This contract implements a fast version of the SwitchboardBase contract
 * that enables packet attestations and watchers registration.
 */
contract FastSwitchboard is SwitchboardBase {
    // mapping to store if packet is valid
    mapping(bytes32 => bool) public isPacketValid;

    // dst chain slug => total watchers registered
    mapping(uint32 => uint256) public totalWatchers;

    // attester => packetId => is attested
    mapping(address => mapping(bytes32 => bool)) public isAttested;

    // packetId => total attestations
    mapping(bytes32 => uint256) public attestations;

    // Event emitted when a new socket is set
    event SocketSet(address newSocket);
    // Event emitted when a packet is attested
    event PacketAttested(bytes32 packetId, address attester);

    // Error emitted when a watcher is found
    error WatcherFound();
    // Error emitted when a watcher is not found
    error WatcherNotFound();
    // Error emitted when a packet is already attested
    error AlreadyAttested();
    // Error emitted when role is invalid
    error InvalidRole();

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
     * @param signature_ Signature of the packet
     */
    function attest(bytes32 packetId_, bytes calldata signature_) external {
        uint32 srcChainSlug = uint32(uint256(packetId_) >> 224);
        address watcher = signatureVerifier__.recoverSignerFromDigest(
            keccak256(abi.encode(address(this), chainSlug, packetId_)),
            signature_
        );

        if (isAttested[watcher][packetId_]) revert AlreadyAttested();
        if (!_hasRoleWithSlug(WATCHER_ROLE, srcChainSlug, watcher))
            revert WatcherNotFound();

        isAttested[watcher][packetId_] = true;
        attestations[packetId_]++;

        if (attestations[packetId_] >= totalWatchers[srcChainSlug])
            isPacketValid[packetId_] = true;

        emit PacketAttested(packetId_, watcher);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId_ packetId
     * @param proposeTime_ time at which packet was proposed
     */
    function allowPacket(
        bytes32,
        bytes32 packetId_,
        uint32 srcChainSlug_,
        uint256 proposeTime_
    ) external view override returns (bool) {
        if (tripGlobalFuse || tripSinglePath[srcChainSlug_]) return false;
        if (isPacketValid[packetId_]) return true;
        if (block.timestamp - proposeTime_ > timeoutInSeconds) return true;
        return false;
    }

    /**
     * @notice adds a watcher for `srcChainSlug_` chain
     * @param watcher_ watcher address
     */
    function grantWatcherRole(
        uint32 srcChainSlug_,
        address watcher_
    ) external onlyRole(GOVERNANCE_ROLE) {
        if (_hasRoleWithSlug(WATCHER_ROLE, srcChainSlug_, watcher_))
            revert WatcherFound();
        _grantRoleWithSlug(WATCHER_ROLE, srcChainSlug_, watcher_);

        totalWatchers[srcChainSlug_]++;
    }

    /**
     * @notice removes a watcher from `srcChainSlug_` chain list
     * @param watcher_ watcher address
     */
    function revokeWatcherRole(
        uint32 srcChainSlug_,
        address watcher_
    ) external onlyRole(GOVERNANCE_ROLE) {
        if (!_hasRoleWithSlug(WATCHER_ROLE, srcChainSlug_, watcher_))
            revert WatcherNotFound();
        _revokeRoleWithSlug(WATCHER_ROLE, srcChainSlug_, watcher_);

        totalWatchers[srcChainSlug_]--;
    }

    function isNonWatcherRole(bytes32 role_) public pure returns (bool) {
        if (
            role_ == TRIP_ROLE ||
            role_ == UNTRIP_ROLE ||
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
        for (uint256 index = 0; index < roleNames_.length; index++) {
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
        for (uint256 index = 0; index < roleNames_.length; index++) {
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
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
     * @notice verifies if the packet satisfies needed checks before execution
     * @param srcChainSlug_ source chain slug
     * @param proposeTime_ time at which packet was proposed
     */
    function allowPacket(
        bytes32,
        bytes32,
        uint32 srcChainSlug_,
        uint256 proposeTime_
    ) external view override returns (bool) {
        if (tripGlobalFuse || tripSinglePath[srcChainSlug_]) return false;
        if (block.timestamp - proposeTime_ < timeoutInSeconds) return false;
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/ISocket.sol";
import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/ISignatureVerifier.sol";
import "../../utils/AccessControlExtended.sol";

import "../../libraries/RescueFundsLib.sol";
import "../../libraries/FeesHelper.sol";

import {GOVERNANCE_ROLE, WITHDRAW_ROLE, RESCUE_ROLE, TRIP_ROLE, UNTRIP_ROLE, WATCHER_ROLE, FEES_UPDATER_ROLE} from "../../utils/AccessRoles.sol";
import {TRIP_PATH_SIG_IDENTIFIER, TRIP_GLOBAL_SIG_IDENTIFIER, UNTRIP_PATH_SIG_IDENTIFIER, UNTRIP_GLOBAL_SIG_IDENTIFIER, FEES_UPDATE_SIG_IDENTIFIER} from "../../utils/SigIdentifiers.sol";

abstract contract SwitchboardBase is ISwitchboard, AccessControlExtended {
    ISignatureVerifier public immutable signatureVerifier__;
    ISocket public immutable socket__;

    bool public tripGlobalFuse;
    uint32 public immutable chainSlug;
    uint256 public immutable timeoutInSeconds;

    struct Fees {
        uint256 switchboardFees;
        uint256 verificationFees;
    }

    mapping(uint32 => bool) public isInitialised;
    mapping(uint32 => uint256) public maxPacketLength;

    // sourceChain => isPaused
    mapping(uint32 => bool) public tripSinglePath;

    // watcher => nextNonce
    mapping(address => uint256) public nextNonce;

    // destinationChainSlug => fees-struct with verificationFees and switchboardFees
    mapping(uint32 => Fees) public fees;

    /**
     * @dev Emitted when a path is tripped
     * @param srcChainSlug Chain slug of the source chain
     * @param tripSinglePath New trip status of the path
     */
    event PathTripped(uint32 srcChainSlug, bool tripSinglePath);
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
     * @dev Emitted when a capacitor is registered
     * @param siblingChainSlug Chain slug of the sibling chain
     * @param capacitor Address of the capacitor
     * @param maxPacketLength Maximum number of messages in one packet
     */
    event SwitchBoardRegistered(
        uint32 siblingChainSlug,
        address capacitor,
        uint256 maxPacketLength
    );

    /**
     * @dev Emitted when a fees is set for switchboard
     * @param siblingChainSlug Chain slug of the sibling chain
     * @param fees fees struct with verificationFees and switchboardFees
     */
    event SwitchboardFeesSet(uint32 siblingChainSlug, Fees fees);

    error AlreadyInitialised();
    error InvalidNonce();
    error OnlySocket();

    /**
     * @dev Constructor of SwitchboardBase
     * @param socket_ Address of the socket contract
     * @param chainSlug_ Chain slug of the contract
     * @param timeoutInSeconds_ Timeout duration of the transactions
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
    function payFees(uint32 dstChainSlug_) external payable override {}

    /**
     * @inheritdoc ISwitchboard
     */
    function getMinFees(
        uint32 dstChainSlug_
    ) external view override returns (uint256, uint256) {
        return (
            fees[dstChainSlug_].switchboardFees,
            fees[dstChainSlug_].verificationFees
        );
    }

    /// @inheritdoc ISwitchboard
    function registerSiblingSlug(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_
    ) external override onlyRole(GOVERNANCE_ROLE) {
        if (isInitialised[siblingChainSlug_]) revert AlreadyInitialised();

        address capacitor = socket__.registerSwitchBoard(
            siblingChainSlug_,
            maxPacketLength_,
            capacitorType_
        );

        isInitialised[siblingChainSlug_] = true;
        maxPacketLength[siblingChainSlug_] = maxPacketLength_;
        emit SwitchBoardRegistered(
            siblingChainSlug_,
            capacitor,
            maxPacketLength_
        );
    }

    /**
     * @notice pause a path
     */
    function tripPath(
        uint256 nonce_,
        uint32 srcChainSlug_,
        bytes memory signature_
    ) external {
        address watcher = signatureVerifier__.recoverSignerFromDigest(
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
        uint256 nonce = nextNonce[watcher]++;
        if (nonce_ != nonce) revert InvalidNonce();

        //source chain based tripping
        tripSinglePath[srcChainSlug_] = true;
        emit PathTripped(srcChainSlug_, true);
    }

    /**
     * @notice pause execution
     */
    function tripGlobal(uint256 nonce_, bytes memory signature_) external {
        address tripper = signatureVerifier__.recoverSignerFromDigest(
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
        uint256 nonce = nextNonce[tripper]++;
        if (nonce_ != nonce) revert InvalidNonce();

        tripGlobalFuse = true;
        emit SwitchboardTripped(true);
    }

    /**
     * @notice unpause a path
     */
    function untripPath(
        uint256 nonce_,
        uint32 srcChainSlug_,
        bytes memory signature_
    ) external {
        address untripper = signatureVerifier__.recoverSignerFromDigest(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    UNTRIP_PATH_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    srcChainSlug_,
                    nonce_,
                    false
                )
            ),
            signature_
        );

        _checkRole(UNTRIP_ROLE, untripper);
        uint256 nonce = nextNonce[untripper]++;
        if (nonce_ != nonce) revert InvalidNonce();

        tripSinglePath[srcChainSlug_] = false;
        emit PathTripped(srcChainSlug_, false);
    }

    /**
     * @notice unpause execution
     */
    function untrip(uint256 nonce_, bytes memory signature_) external {
        address untripper = signatureVerifier__.recoverSignerFromDigest(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    UNTRIP_GLOBAL_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    nonce_,
                    false
                )
            ),
            signature_
        );

        _checkRole(UNTRIP_ROLE, untripper);
        uint256 nonce = nextNonce[untripper]++;
        if (nonce_ != nonce) revert InvalidNonce();

        tripGlobalFuse = false;
        emit SwitchboardTripped(false);
    }

    function setFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 switchboardFees_,
        uint256 verificationFees_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSignerFromDigest(
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

        uint256 nonce = nextNonce[feesUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        Fees memory feesObject = Fees({
            switchboardFees: switchboardFees_,
            verificationFees: verificationFees_
        });

        fees[dstChainSlug_] = feesObject;

        emit SwitchboardFeesSet(dstChainSlug_, feesObject);
    }

    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        FeesHelper.withdrawFees(account_);
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
pragma solidity 0.8.7;

import "lib/openzeppelin-contracts/contracts/vendor/arbitrum/IBridge.sol";
import "lib/openzeppelin-contracts/contracts/vendor/arbitrum/IInbox.sol";
import "lib/openzeppelin-contracts/contracts/vendor/arbitrum/IOutbox.sol";
import "./NativeSwitchboardBase.sol";

/**
 * @title ArbitrumL1Switchboard
 * @dev This contract is a switchboard contract for the Arbitrum chain that handles packet attestation and actions on the L1 to Arbitrum and
 * Arbitrum to L1 path.
 * This contract inherits base functions from NativeSwitchboardBase, including fee calculation,
 * trip and untrip actions, and limit setting functions.
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
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

import "../../interfaces/ISocket.sol";
import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/ICapacitor.sol";
import "../../interfaces/ISignatureVerifier.sol";

import "../../libraries/RescueFundsLib.sol";
import "../../libraries/FeesHelper.sol";
import "../../utils/AccessControlExtended.sol";

import {GOVERNANCE_ROLE, RESCUE_ROLE, WITHDRAW_ROLE, TRIP_ROLE, UNTRIP_ROLE, FEES_UPDATER_ROLE} from "../../utils/AccessRoles.sol";
import {TRIP_NATIVE_SIG_IDENTIFIER, UNTRIP_NATIVE_SIG_IDENTIFIER, FEES_UPDATE_SIG_IDENTIFIER} from "../../utils/SigIdentifiers.sol";

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
    bool public isInitialised;

    /**
     * @dev The maximum packet size.
     */
    uint256 public maxPacketLength;

    /**
     * @dev Address of the remote native switchboard.
     */
    address public remoteNativeSwitchboard;

    uint32 public immutable chainSlug;

    /**
     * @dev Stores the roots received from native bridge.
     */
    mapping(bytes32 => bytes32) public packetIdToRoot;

    /**
     * @dev Transmitter to next nonce.
     */
    mapping(address => uint256) public nextNonce;

    uint256 public switchboardFees;
    uint256 public verificationFees;

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
     * @param siblingChainSlug Chain slug of the sibling chain
     * @param capacitor address of capacitor registered to switchboard
     * @param maxPacketLength maximum packets that can be set to capacitor
     */
    event SwitchBoardRegistered(
        uint32 siblingChainSlug,
        address capacitor,
        uint256 maxPacketLength
    );

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
    error AlreadyInitialised();

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
    modifier onlyRemoteSwitchboard() virtual {
        _;
    }

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
     * @notice checks if a packet can be executed
     * @param root_ Merkle root associated with the packet ID
     * @param packetId_ packet ID
     * @return true if the packet satisfies all the checks and can be executed, false otherwise
     */
    function allowPacket(
        bytes32 root_,
        bytes32 packetId_,
        uint32,
        uint256
    ) external view override returns (bool) {
        if (tripGlobalFuse) return false;
        if (packetIdToRoot[packetId_] != root_) return false;

        return true;
    }

    /**
     * @notice receives fees to be paid to the relayer for executing the packet
     * @param dstChainSlug_ chain slug of the destination chain
     * @dev assumes that the amount is paid in the native currency of the destination chain and has 18 decimals
     */
    function payFees(uint32 dstChainSlug_) external payable override {}

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
        returns (uint256 switchboardFee_, uint256 verificationFee_)
    {
        return (switchboardFees, verificationFees);
    }

    function setFees(
        uint256 nonce_,
        uint32,
        uint256 switchboardFees_,
        uint256 verificationFees_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSignerFromDigest(
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

        uint256 nonce = nextNonce[feesUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        switchboardFees = switchboardFees_;
        verificationFees = verificationFees_;

        emit SwitchboardFeesSet(switchboardFees, verificationFees);
    }

    /// @inheritdoc ISwitchboard
    function registerSiblingSlug(
        uint32 siblingChainSlug_,
        uint256 maxPacketLength_,
        uint256 capacitorType_
    ) external override onlyRole(GOVERNANCE_ROLE) {
        if (isInitialised) revert AlreadyInitialised();

        address capacitor = socket__.registerSwitchBoard(
            siblingChainSlug_,
            maxPacketLength_,
            capacitorType_
        );

        isInitialised = true;
        maxPacketLength = maxPacketLength_;
        capacitor__ = ICapacitor(capacitor);

        emit SwitchBoardRegistered(
            siblingChainSlug_,
            capacitor,
            maxPacketLength_
        );
    }

    /**
     * @notice Allows to trip the global fuse and prevent the switchboard to process packets
     * @dev The function recovers the signer from the given signature and verifies if the signer has the TRIP_ROLE.
     *      The nonce must be equal to the next nonce of the caller. If the caller doesn't have the TRIP_ROLE or the nonce
     *      is incorrect, it will revert.
     *       Once the function is successful, the tripGlobalFuse variable is set to true and the SwitchboardTripped event is emitted.
     * @param nonce_ The nonce of the caller.
     * @param signature_ The signature of the message "TRIP" + chainSlug + nonce_ + true.
     */
    function tripGlobal(uint256 nonce_, bytes memory signature_) external {
        address watcher = signatureVerifier__.recoverSignerFromDigest(
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
        uint256 nonce = nextNonce[watcher]++;
        if (nonce_ != nonce) revert InvalidNonce();

        tripGlobalFuse = true;
        emit SwitchboardTripped(true);
    }

    /**
     * @notice Allows a watcher to untrip the switchboard by providing a signature and a nonce.
     * @dev To untrip, the watcher must have the UNTRIP_ROLE. The signature must be created by signing the concatenation of the following values: "UNTRIP", the chainSlug, the nonce and false.
     * @param nonce_ The nonce to prevent replay attacks.
     * @param signature_ The signature created by the watcher.
     */
    function untrip(uint256 nonce_, bytes memory signature_) external {
        address watcher = signatureVerifier__.recoverSignerFromDigest(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    UNTRIP_NATIVE_SIG_IDENTIFIER,
                    address(this),
                    chainSlug,
                    nonce_,
                    false
                )
            ),
            signature_
        );

        _checkRole(UNTRIP_ROLE, watcher);
        uint256 nonce = nextNonce[watcher]++;
        if (nonce_ != nonce) revert InvalidNonce();

        tripGlobalFuse = false;
        emit SwitchboardTripped(false);
    }

    /**
    @dev Update the address of the remote native switchboard contract.
    @param remoteNativeSwitchboard_ The address of the new remote native switchboard contract.
    @notice This function can only be called by an account with the GOVERNANCE_ROLE.
    @notice Emits an UpdatedRemoteNativeSwitchboard event.
    */
    function updateRemoteNativeSwitchboard(
        address remoteNativeSwitchboard_
    ) external onlyRole(GOVERNANCE_ROLE) {
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        emit UpdatedRemoteNativeSwitchboard(remoteNativeSwitchboard_);
    }

    /**
     * @notice Allows the withdrawal of fees by the account with the specified address.
     * @param account_ The address of the account to withdraw fees to.
     * @dev The caller must have the WITHDRAW_ROLE.
     */
    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        FeesHelper.withdrawFees(account_);
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
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

import "./interfaces/ITransmitManager.sol";
import "./interfaces/ISignatureVerifier.sol";

import "./utils/AccessControlExtended.sol";
import "./libraries/RescueFundsLib.sol";
import "./libraries/FeesHelper.sol";
import {GOVERNANCE_ROLE, WITHDRAW_ROLE, RESCUE_ROLE, TRANSMITTER_ROLE, FEES_UPDATER_ROLE} from "./utils/AccessRoles.sol";
import {FEES_UPDATE_SIG_IDENTIFIER} from "./utils/SigIdentifiers.sol";

/**
 * @title TransmitManager
 * @notice The TransmitManager contract facilitates communication between chains
 * @dev This contract is responsible for verifying signatures and updating gas limits
 * @dev This contract inherits AccessControlExtended which manages access control
 */
contract TransmitManager is ITransmitManager, AccessControlExtended {
    ISignatureVerifier public signatureVerifier__;

    uint32 public immutable chainSlug;

    // transmitter => nextNonce
    mapping(address => uint256) public nextNonce;

    // remoteChainSlug => transmissionFees
    mapping(uint32 => uint256) public transmissionFees;

    error InsufficientTransmitFees();
    error InvalidNonce();

    /**
     * @notice Emitted when a new signature verifier contract is set
     * @param signatureVerifier The address of the new signature verifier contract
     */
    event SignatureVerifierSet(address signatureVerifier);

    /**
     * @notice Emitted when the transmissionFees is updated
     * @param dstChainSlug The destination chain slug for which the transmissionFees is updated
     * @param transmissionFees The new transmissionFees
     */
    event TransmissionFeesSet(uint256 dstChainSlug, uint256 transmissionFees);

    /**
     * @notice Initializes the TransmitManager contract
     * @param signatureVerifier_ The address of the signature verifier contract
     * @param owner_ The owner of the contract with GOVERNANCE_ROLE
     * @param chainSlug_ The chain slug of the current contract
     */
    constructor(
        ISignatureVerifier signatureVerifier_,
        address owner_,
        uint32 chainSlug_
    ) AccessControlExtended(owner_) {
        chainSlug = chainSlug_;
        signatureVerifier__ = signatureVerifier_;
    }

    /**
     * @notice verifies if the given signatures recovers a valid transmitter
     * @dev signature sent to this function can be reused on other chains
     * @dev hence caller should add some identifier to prevent this.
     * @dev In socket, this is handled by the calling functions everywhere.
     * @param siblingSlug_ sibling id for which transmitter is registered
     * @param digest_ digest which is signed by transmitter
     * @param signature_ signature
     */
    function checkTransmitter(
        uint32 siblingSlug_,
        bytes32 digest_,
        bytes calldata signature_
    ) external view override returns (address, bool) {
        address transmitter = signatureVerifier__.recoverSignerFromDigest(
            digest_,
            signature_
        );

        return (
            transmitter,
            _hasRoleWithSlug(TRANSMITTER_ROLE, siblingSlug_, transmitter)
        );
    }

    /**
     * @notice takes fees for the given sibling slug from socket for seal and propose
     * @param siblingChainSlug_ sibling id
     */
    function payFees(uint32 siblingChainSlug_) external payable override {}

    /**
     * @notice calculates fees for the given sibling slug
     * @param siblingChainSlug_ sibling id
     */
    function getMinFees(
        uint32 siblingChainSlug_
    ) external view override returns (uint256) {
        return transmissionFees[siblingChainSlug_];
    }

    function setTransmissionFees(
        uint256 nonce_,
        uint32 dstChainSlug_,
        uint256 transmissionFees_,
        bytes calldata signature_
    ) external override {
        address feesUpdater = signatureVerifier__.recoverSignerFromDigest(
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

        uint256 nonce = nextNonce[feesUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        transmissionFees[dstChainSlug_] = transmissionFees_;
        emit TransmissionFeesSet(dstChainSlug_, transmissionFees_);
    }

    /**
     * @notice withdraws fees from contract
     * @param account_ withdraw fees to
     */
    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        FeesHelper.withdrawFees(account_);
    }

    /**
     * @notice updates signatureVerifier_
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
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

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
        for (uint256 index = 0; index < roleNames_.length; index++) {
            if (slugs_[index] > 0)
                _grantRoleWithSlug(
                    roleNames_[index],
                    slugs_[index],
                    grantees_[index]
                );
            else _grantRole(roleNames_[index], grantees_[index]);
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
        for (uint256 index = 0; index < roleNames_.length; index++) {
            if (slugs_[index] > 0)
                _revokeRoleWithSlug(
                    roleNames_[index],
                    slugs_[index],
                    grantees_[index]
                );
            else _revokeRole(roleNames_[index], grantees_[index]);
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
pragma solidity 0.8.7;

bytes32 constant RESCUE_ROLE = keccak256("RESCUE_ROLE");
bytes32 constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
bytes32 constant TRIP_ROLE = keccak256("TRIP_ROLE");
bytes32 constant UNTRIP_ROLE = keccak256("UNTRIP_ROLE");
bytes32 constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
bytes32 constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
bytes32 constant TRANSMITTER_ROLE = keccak256("TRANSMITTER_ROLE");
bytes32 constant WATCHER_ROLE = keccak256("WATCHER_ROLE");
bytes32 constant FEES_UPDATER_ROLE = keccak256("FEES_UPDATER_ROLE");

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

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
     * @notice initialises and grants RESCUE_ROLE to owner.
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
                    messageDetails_.msgGasLimit,
                    messageDetails_.extraParams,
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
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

bytes32 constant TRIP_PATH_SIG_IDENTIFIER = keccak256("TRIP_PATH");
bytes32 constant TRIP_GLOBAL_SIG_IDENTIFIER = keccak256("TRIP_GLOBAL");

bytes32 constant UNTRIP_PATH_SIG_IDENTIFIER = keccak256("UNTRIP_PATH");
bytes32 constant UNTRIP_GLOBAL_SIG_IDENTIFIER = keccak256("UNTRIP_GLOBAL");

bytes32 constant TRIP_NATIVE_SIG_IDENTIFIER = keccak256("TRIP_NATIVE");
bytes32 constant UNTRIP_NATIVE_SIG_IDENTIFIER = keccak256("UNTRIP_NATIVE");

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
pragma solidity 0.8.7;

import "../interfaces/ISignatureVerifier.sol";

import "../libraries/RescueFundsLib.sol";
import "../libraries/SignatureVerifierLib.sol";

import "../utils/AccessControl.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

/**
 * @title Signature Verifier
 * @notice Verifies the signatures and returns the address of signer recovered from the input signature or digest.
 * @dev This contract is modular component in socket to support different signing algorithms.
 */
contract SignatureVerifier is ISignatureVerifier, AccessControl {
    /**
     * @notice initialises and grants RESCUE_ROLE to owner.
     * @param owner_ The address of the owner of the contract.
     */
    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /// @inheritdoc ISignatureVerifier
    function recoverSigner(
        uint32 dstChainSlug_,
        bytes32 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external pure override returns (address signer) {
        return
            SignatureVerifierLib.recoverSigner(
                dstChainSlug_,
                packetId_,
                root_,
                signature_
            );
    }

    /**
     * @notice returns the address of signer recovered from input signature and digest
     */
    function recoverSignerFromDigest(
        bytes32 digest_,
        bytes memory signature_
    ) public pure override returns (address signer) {
        return
            SignatureVerifierLib.recoverSignerFromDigest(digest_, signature_);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (vendor/arbitrum/IArbSys.sol)
pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint256);

    function arbChainID() external view returns (uint256);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

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
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns (address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint256);

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
}

// SPDX-License-Identifier: Apache-2.0
// OpenZeppelin Contracts (last updated v4.6.0) (vendor/arbitrum/IBridge.sol)

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.8.0;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    event BridgeCallTriggered(address indexed outbox, address indexed destAddr, uint256 amount, bytes data);

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
// OpenZeppelin Contracts (last updated v4.6.0) (vendor/arbitrum/IInbox.sol)

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.8.0;

import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicketNoRefundAliasRewrite(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);

    function bridge() external view returns (address);

    function pauseCreateRetryables() external;

    function unpauseCreateRetryables() external;

    function startRewriteAddress() external;

    function stopRewriteAddress() external;
}

// SPDX-License-Identifier: Apache-2.0
// OpenZeppelin Contracts (last updated v4.6.0) (vendor/arbitrum/IMessageProvider.sol)

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.8.0;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: Apache-2.0
// OpenZeppelin Contracts (last updated v4.6.0) (vendor/arbitrum/IOutbox.sol)

/*
 * Copyright 2021, Offchain Labs, Inc.
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

pragma solidity ^0.8.0;

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxEntryIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );
    event OutBoxTransactionExecuted(
        address indexed destAddr,
        address indexed l2Sender,
        uint256 indexed outboxEntryIndex,
        uint256 transactionIndex
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function l2ToL1BatchNum() external view returns (uint256);

    function l2ToL1OutputId() external view returns (bytes32);

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths) external;

    function outboxEntryExists(uint256 batchNum) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (vendor/optimism/ICrossDomainMessenger.sol)
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
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}