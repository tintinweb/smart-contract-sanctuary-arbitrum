// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./interfaces/ICapacitorFactory.sol";
import "./capacitors/SingleCapacitor.sol";
import "./capacitors/HashChainCapacitor.sol";
import "./decapacitors/SingleDecapacitor.sol";
import "./decapacitors/HashChainDecapacitor.sol";

import "./libraries/RescueFundsLib.sol";
import "./utils/AccessControlExtended.sol";
import {RESCUE_ROLE} from "./utils/AccessRoles.sol";

contract CapacitorFactory is ICapacitorFactory, AccessControlExtended {
    uint256 private constant SINGLE_CAPACITOR = 1;
    uint256 private constant HASH_CHAIN_CAPACITOR = 2;

    constructor(address owner_) AccessControlExtended(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    function deploy(
        uint256 capacitorType_,
        uint256 /** siblingChainSlug */,
        uint256 /** maxPacketLength */
    ) external override returns (ICapacitor, IDecapacitor) {
        address owner = this.owner();

        if (capacitorType_ == SINGLE_CAPACITOR) {
            return (
                new SingleCapacitor(msg.sender, owner),
                new SingleDecapacitor(owner)
            );
        }
        if (capacitorType_ == HASH_CHAIN_CAPACITOR) {
            return (
                new HashChainCapacitor(msg.sender, owner),
                new HashChainDecapacitor(owner)
            );
        }
        revert InvalidCapacitorType();
    }

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
import "../utils/AccessControlExtended.sol";
import "../libraries/RescueFundsLib.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

abstract contract BaseCapacitor is ICapacitor, AccessControlExtended {
    /// an incrementing id for each new packet created
    uint64 internal _nextPacketCount;
    uint64 internal _nextSealCount;

    address public immutable socket;

    /// maps the packet id with the root hash generated while adding message
    mapping(uint64 => bytes32) internal _roots;

    error NoPendingPacket();
    error OnlySocket();

    modifier onlySocket() {
        if (msg.sender != socket) revert OnlySocket();

        _;
    }

    /**
     * @notice initialises the contract with socket address
     */
    constructor(address socket_, address owner_) AccessControlExtended(owner_) {
        socket = socket_;
    }

    function sealPacket(
        uint256
    ) external virtual override onlySocket returns (bytes32, uint64) {
        uint64 packetCount = _nextSealCount++;
        if (_roots[packetCount] == bytes32(0)) revert NoPendingPacket();

        bytes32 root = _roots[packetCount];
        return (root, packetCount);
    }

    /// returns the latest packet details to be sealed
    /// @inheritdoc ICapacitor
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

    /// returns the root of packet for given id
    /// @inheritdoc ICapacitor
    function getRootByCount(
        uint64 id_
    ) external view virtual override returns (bytes32) {
        return _roots[id_];
    }

    function getLatestPacketCount() external view returns (uint256) {
        return _nextPacketCount == 0 ? 0 : _nextPacketCount - 1;
    }

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

contract HashChainCapacitor is BaseCapacitor {
    uint256 private _chainLength;
    uint256 private constant _MAX_LEN = 10;

    /**
     * @notice initialises the contract with socket address
     */
    constructor(
        address socket_,
        address owner_
    ) BaseCapacitor(socket_, owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /// adds the packed message to a packet
    /// @inheritdoc ICapacitor
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

contract SingleCapacitor is BaseCapacitor {
    /**
     * @notice initialises the contract with socket address
     */
    constructor(
        address socket_,
        address owner_
    ) BaseCapacitor(socket_, owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /// adds the packed message to a packet
    /// @inheritdoc ICapacitor
    function addPackedMessage(
        bytes32 packedMessage_
    ) external override onlySocket {
        uint64 packetCount = _nextPacketCount;
        _roots[packetCount] = packedMessage_;
        _nextPacketCount++;

        emit MessageAdded(packedMessage_, packetCount, packedMessage_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IDecapacitor.sol";
import "../libraries/RescueFundsLib.sol";
import "../utils/AccessControlExtended.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

contract HashChainDecapacitor is IDecapacitor, AccessControlExtended {
    /**
     * @notice initialises the contract with owner address
     */
    constructor(address owner_) AccessControlExtended(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /// returns if the packed message is the part of a merkle tree or not
    /// @inheritdoc IDecapacitor
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
import "../utils/AccessControlExtended.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

contract SingleDecapacitor is IDecapacitor, AccessControlExtended {
    /**
     * @notice initialises the contract with owner address
     */
    constructor(address owner_) AccessControlExtended(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /// returns if the packed message is the part of a merkle tree or not
    /// @inheritdoc IDecapacitor
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata
    ) external pure override returns (bool) {
        return root_ == packedMessage_;
    }

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
        uint256 chainSlug_,
        uint256 amount_,
        uint256 msgGasLimit_
    ) external payable {
        bytes memory payload = abi.encode(OP_ADD, amount_, msg.sender);
        _outbound(chainSlug_, msgGasLimit_, payload);
    }

    function remoteSubOperation(
        uint256 chainSlug_,
        uint256 amount_,
        uint256 msgGasLimit_
    ) external payable {
        bytes memory payload = abi.encode(OP_SUB, amount_, msg.sender);
        _outbound(chainSlug_, msgGasLimit_, payload);
    }

    function inbound(
        uint256,
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
        uint256 targetChain_,
        uint256 msgGasLimit_,
        bytes memory payload_
    ) private {
        ISocket(socket).outbound{value: msg.value}(
            targetChain_,
            msgGasLimit_,
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
        uint256 remoteChainSlug_,
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
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IPlug.sol";
import "../interfaces/ISocket.sol";
import "../interfaces/ITransmitManager.sol";
import "../interfaces/ISwitchboard.sol";
import "../interfaces/IExecutionManager.sol";
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
        bytes32 message_
    ) external payable {
        bytes memory payload = abi.encode(_localChainSlug, message_);
        _outbound(remoteChainSlug_, payload);
    }

    function inbound(
        uint256,
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
        _outbound(remoteChainSlug, newPayload);
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

    function _outbound(uint32 targetChain_, bytes memory payload_) private {
        uint256 fee = _socket__.getMinFees(
            _msgGasLimit,
            targetChain_,
            address(this)
        );
        if (!(address(this).balance >= fee)) revert NoSocketFee();
        _socket__.outbound{value: fee}(targetChain_, _msgGasLimit, payload_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./interfaces/IExecutionManager.sol";
import "./interfaces/IGasPriceOracle.sol";
import "./utils/AccessControlExtended.sol";
import "./libraries/RescueFundsLib.sol";
import "./libraries/SignatureVerifierLib.sol";
import "./libraries/FeesHelper.sol";
import {WITHDRAW_ROLE, RESCUE_ROLE, GOVERNANCE_ROLE, EXECUTOR_ROLE} from "./utils/AccessRoles.sol";

contract ExecutionManager is IExecutionManager, AccessControlExtended {
    IGasPriceOracle public gasPriceOracle__;
    event GasPriceOracleSet(address gasPriceOracle);

    constructor(
        IGasPriceOracle gasPriceOracle_,
        address owner_
    ) AccessControlExtended(owner_) {
        gasPriceOracle__ = IGasPriceOracle(gasPriceOracle_);
    }

    function isExecutor(
        bytes32 packedMessage,
        bytes memory sig
    ) external view override returns (address executor, bool isValidExecutor) {
        executor = SignatureVerifierLib.recoverSignerFromDigest(
            packedMessage,
            sig
        );
        isValidExecutor = _hasRole(EXECUTOR_ROLE, executor);
    }

    // these details might be needed for on-chain fee distribution later
    function updateExecutionFees(address, uint256, bytes32) external override {}

    function payFees(
        uint256 msgGasLimit_,
        uint32 siblingChainSlug_
    ) external payable override {}

    function getMinFees(
        uint256 msgGasLimit_,
        uint32 siblingChainSlug_
    ) external view override returns (uint256) {
        return _getMinExecutionFees(msgGasLimit_, siblingChainSlug_);
    }

    function _getMinExecutionFees(
        uint256 msgGasLimit_,
        uint32 dstChainSlug_
    ) internal view returns (uint256) {
        uint256 dstRelativeGasPrice = gasPriceOracle__.relativeGasPrice(
            dstChainSlug_
        );
        return msgGasLimit_ * dstRelativeGasPrice;
    }

    /**
     * @notice updates gasPriceOracle__
     * @param gasPriceOracle_ address of Gas Price Oracle
     */
    function setGasPriceOracle(
        address gasPriceOracle_
    ) external onlyRole(GOVERNANCE_ROLE) {
        gasPriceOracle__ = IGasPriceOracle(gasPriceOracle_);
        emit GasPriceOracleSet(gasPriceOracle_);
    }

    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        FeesHelper.withdrawFees(account_);
    }

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

import "./interfaces/IGasPriceOracle.sol";
import "./interfaces/ITransmitManager.sol";
import "./utils/AccessControlExtended.sol";
import "./libraries/RescueFundsLib.sol";
import {GOVERNANCE_ROLE, RESCUE_ROLE} from "./utils/AccessRoles.sol";

contract GasPriceOracle is IGasPriceOracle, AccessControlExtended {
    ITransmitManager public transmitManager__;

    // plugs/switchboards/transmitter can use it to ensure prices are updated
    mapping(uint256 => uint256) public updatedAt;
    // chain slug => relative gas price
    mapping(uint32 => uint256) public override relativeGasPrice;

    // transmitter => nextNonce
    mapping(address => uint256) public nextNonce;

    // gas price of source chain
    uint256 public override sourceGasPrice;
    uint32 public immutable chainSlug;

    event TransmitManagerUpdated(address transmitManager);
    event RelativeGasPriceUpdated(
        uint256 dstChainSlug,
        uint256 relativeGasPrice
    );
    event SourceGasPriceUpdated(uint256 sourceGasPrice);

    error TransmitterNotFound();
    error InvalidNonce();

    constructor(
        address owner_,
        uint32 chainSlug_
    ) AccessControlExtended(owner_) {
        chainSlug = chainSlug_;
    }

    /**
     * @notice update the sourceGasPrice which is to be used in various computations
     * @param sourceGasPrice_ gas price of source chain
     */
    function setSourceGasPrice(
        uint256 nonce_,
        uint256 sourceGasPrice_,
        bytes calldata signature_
    ) external {
        (address transmitter, bool isTransmitter) = transmitManager__
            .checkTransmitter(
                chainSlug,
                keccak256(abi.encode(chainSlug, nonce_, sourceGasPrice_)),
                signature_
            );

        if (!isTransmitter) revert TransmitterNotFound();

        uint256 nonce = nextNonce[transmitter]++;
        if (nonce_ != nonce) revert InvalidNonce();

        sourceGasPrice = sourceGasPrice_;
        updatedAt[chainSlug] = block.timestamp;

        emit SourceGasPriceUpdated(sourceGasPrice);
    }

    /**
     * @dev the relative prices are calculated as:
     * relativeGasPrice = (siblingGasPrice * siblingGasUSDPrice)/srcGasUSDPrice
     * It is assumed that precision of relative gas price will be same as src native tokens
     * So that when it is multiplied with gas limits at other contracts, we get correct values.
     */
    function setRelativeGasPrice(
        uint32 siblingChainSlug_,
        uint256 nonce_,
        uint256 relativeGasPrice_,
        bytes calldata signature_
    ) external {
        (address transmitter, bool isTransmitter) = transmitManager__
            .checkTransmitter(
                siblingChainSlug_,
                keccak256(
                    abi.encode(
                        chainSlug,
                        siblingChainSlug_,
                        nonce_,
                        relativeGasPrice_
                    )
                ),
                signature_
            );

        if (!isTransmitter) revert TransmitterNotFound();
        uint256 nonce = nextNonce[transmitter]++;
        if (nonce_ != nonce) revert InvalidNonce();

        relativeGasPrice[siblingChainSlug_] = relativeGasPrice_;
        updatedAt[siblingChainSlug_] = block.timestamp;

        emit RelativeGasPriceUpdated(siblingChainSlug_, relativeGasPrice_);
    }

    function getGasPrices(
        uint32 siblingChainSlug_
    ) external view override returns (uint256, uint256) {
        return (sourceGasPrice, relativeGasPrice[siblingChainSlug_]);
    }

    function setTransmitManager(
        ITransmitManager transmitManager_
    ) external onlyRole(GOVERNANCE_ROLE) {
        transmitManager__ = transmitManager_;
        emit TransmitManagerUpdated(address(transmitManager_));
    }

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

interface ICapacitor {
    /**
     * @notice emits the message details when it arrives
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

interface ICapacitorFactory {
    error InvalidCapacitorType();

    function deploy(
        uint256 capacitorType,
        uint256 siblingChainSlug,
        uint256 maxPacketLength
    ) external returns (ICapacitor, IDecapacitor);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IDecapacitor {
    /**
     * @notice returns if the packed message is the part of a merkle tree or not
     * @param root_ root hash of the merkle tree
     * @param packedMessage_ packed message which needs to be verified
     * @param proof_ proof used to determine the inclusion
     */
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata proof_
    ) external pure returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IExecutionManager {
    function isExecutor(
        bytes32 packedMessage,
        bytes memory sig
    ) external view returns (address, bool);

    function payFees(uint256 msgGasLimit, uint32 dstSlug) external payable;

    function getMinFees(
        uint256 msgGasLimit,
        uint32 dstSlug
    ) external view returns (uint256);

    function updateExecutionFees(
        address executor,
        uint256 executionFees,
        bytes32 msgId
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IGasPriceOracle {
    function relativeGasPrice(
        uint32 dstChainSlug
    ) external view returns (uint256);

    function sourceGasPrice() external view returns (uint256);

    function getGasPrices(
        uint32 dstChainSlug_
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IHasher {
    /**
     * @notice returns the bytes32 hash of the message packed
     * @param srcChainSlug src chain slug
     * @param srcPlug address of plug at source
     * @param dstChainSlug remote chain slug
     * @param dstPlug address of plug at remote
     * @param msgId message id assigned at outbound
     * @param msgGasLimit gas limit which is expected to be consumed by the inbound transaction on plug
     * @param executionFee msg value which is expected to be sent with inbound transaction to plug
     * @param payload the data packed which is used by inbound for execution
     */
    function packMessage(
        uint256 srcChainSlug,
        address srcPlug,
        uint256 dstChainSlug,
        address dstPlug,
        bytes32 msgId,
        uint256 msgGasLimit,
        uint256 executionFee,
        bytes calldata payload
    ) external returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface INativeRelay {
    /**
     * @notice receiveMessage on PolygonRootReceiver
     * @param receivePacketProof receivePacketProof
     */
    function receiveMessage(bytes memory receivePacketProof) external;

    function initiateNativeConfirmation(
        bytes32 packetId,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) external payable;

    function initiateNativeConfirmation(bytes32 packetId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint256 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface ISignatureVerifier {
    /**
     * @notice returns the address of signer recovered from input signature
     * @param dstChainSlug_ remote chain slug
     * @param packetId_ packet id
     * @param root_ root hash of merkle tree
     * @param signature_ signature
     */
    function recoverSigner(
        uint256 dstChainSlug_,
        uint256 packetId_,
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./ITransmitManager.sol";
import "./IExecutionManager.sol";

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
        uint256 localChainSlug,
        address localPlug,
        uint256 dstChainSlug,
        address dstPlug,
        bytes32 msgId,
        uint256 msgGasLimit,
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
        uint256 siblingChainSlug,
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
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    function packetIdRoots(bytes32 packetId_) external view returns (bytes32);

    function getMinFees(
        uint256 msgGasLimit_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view returns (uint256 totalFees);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface ISwitchboard {
    function registerCapacitor(
        uint256 siblingChainSlug_,
        address capacitor_,
        uint256 maxPacketSize_
    ) external;

    function allowPacket(
        bytes32 root,
        bytes32 packetId,
        uint32 srcChainSlug,
        uint256 proposeTime
    ) external view returns (bool);

    function payFees(uint32 dstChainSlug) external payable;

    function getMinFees(
        uint32 dstChainSlug
    ) external view returns (uint256 switchboardFee, uint256 verificationFee);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface ITransmitManager {
    function checkTransmitter(
        uint32 siblingSlug,
        bytes32 digest,
        bytes calldata signature
    ) external view returns (address, bool);

    function payFees(uint32 dstSlug) external payable;

    function getMinFees(uint32 dstSlug) external view returns (uint256);

    function setProposeGasLimit(
        uint256 nonce_,
        uint256 dstChainSlug_,
        uint256 gasLimit_,
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

library FeesHelper {
    error TransferFailed();
    event FeesWithdrawn(address account, uint256 amount);

    // TODO: to support fee distribution
    /**
     * @notice transfers the fees collected to `account_`
     * @param account_ address to transfer ETH
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

import "../libraries/SafeTransferLib.sol";

library RescueFundsLib {
    using SafeTransferLib for IERC20;
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) internal {
        require(userAddress_ != address(0));

        if (token_ == ETH_ADDRESS) {
            (bool success, ) = userAddress_.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            IERC20(token_).transfer(userAddress_, amount_);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
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

library SignatureVerifierLib {
    error InvalidSigLength();

    function recoverSigner(
        uint256 destChainSlug_,
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) internal pure returns (address signer) {
        bytes32 digest = keccak256(
            abi.encode(destChainSlug_, packetId_, root_)
        );
        signer = recoverSignerFromDigest(digest, signature_);
    }

    /**
     * @notice returns the address of signer recovered from input signature and digest
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

import {SocketSrc} from "./SocketSrc.sol";
import "./SocketDst.sol";
import "../libraries/RescueFundsLib.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";

contract Socket is SocketSrc, SocketDst {
    constructor(
        uint32 chainSlug_,
        address hasher_,
        address transmitManager_,
        address executionManager_,
        address capacitorFactory_,
        address owner_
    ) AccessControlExtended(owner_) SocketBase(chainSlug_) {
        hasher__ = IHasher(hasher_);
        transmitManager__ = ITransmitManager(transmitManager_);
        executionManager__ = IExecutionManager(executionManager_);
        capacitorFactory__ = ICapacitorFactory(capacitorFactory_);
    }

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
import "../interfaces/ITransmitManager.sol";
import "../interfaces/IExecutionManager.sol";

import "./SocketConfig.sol";

abstract contract SocketBase is SocketConfig {
    IHasher public hasher__;
    ITransmitManager public transmitManager__;
    IExecutionManager public executionManager__;

    uint32 public immutable chainSlug;
    // incrementing nonce, should be handled in next socket version.
    uint224 public messageCount;

    constructor(uint32 chainSlug_) {
        chainSlug = chainSlug_;
    }

    error InvalidAttester();

    event HasherSet(address hasher);
    event ExecutionManagerSet(address executionManager);

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
import "../utils/AccessControlExtended.sol";
import {RESCUE_ROLE} from "../utils/AccessRoles.sol";
import {ISocket} from "../interfaces/ISocket.sol";
import {ITransmitManager} from "../interfaces/ITransmitManager.sol";

import {FastSwitchboard} from "../switchboard/default-switchboards/FastSwitchboard.sol";
import {INativeRelay} from "../interfaces/INativeRelay.sol";

contract SocketBatcher is AccessControlExtended {
    constructor(address owner_) AccessControlExtended(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    struct SealRequest {
        uint256 batchSize;
        address capacitorAddress;
        bytes signature;
    }

    struct ProposeRequest {
        bytes32 packetId;
        bytes32 root;
        bytes signature;
    }

    struct AttestRequest {
        bytes32 packetId;
        uint256 srcChainSlug;
        bytes signature;
    }

    struct ExecuteRequest {
        bytes32 packetId;
        address localPlug;
        ISocket.MessageDetails messageDetails;
        bytes signature;
    }

    struct ArbitrumNativeInitiatorRequest {
        bytes32 packetId;
        uint256 maxSubmissionCost;
        uint256 maxGas;
        uint256 gasPriceBid;
        uint256 callValue;
    }

    struct SetProposeGasLimitRequest {
        uint256 nonce;
        uint256 dstChainId;
        uint256 proposeGasLimit;
        bytes signature;
    }

    struct SetAttestGasLimitRequest {
        uint256 nonce;
        uint256 dstChainId;
        uint256 attestGasLimit;
        bytes signature;
    }

    struct SetExecutionOverheadRequest {
        uint256 nonce;
        uint256 dstChainId;
        uint256 executionOverhead;
        bytes signature;
    }

    /**
     * @notice set propose gas limit for a list of siblings
     * @param socketAddress_ address of socket
     * @param setProposeGasLimitRequests_ the list of requests with gas limit details
     */
    function registerSwitchboards(
        address socketAddress_,
        SetProposeGasLimitRequest[] calldata setProposeGasLimitRequests_
    ) external {
        uint256 setProposeGasLimitLength = setProposeGasLimitRequests_.length;
        for (uint256 index = 0; index < setProposeGasLimitLength; ) {
            ITransmitManager(socketAddress_).setProposeGasLimit(
                setProposeGasLimitRequests_[index].nonce,
                setProposeGasLimitRequests_[index].dstChainId,
                setProposeGasLimitRequests_[index].proposeGasLimit,
                setProposeGasLimitRequests_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice set propose gas limit for a list of siblings
     * @param transmitManagerAddress_ address of transmit manager
     * @param setProposeGasLimitRequests_ the list of requests with gas limit details
     */
    function setProposeGasLimits(
        address transmitManagerAddress_,
        SetProposeGasLimitRequest[] calldata setProposeGasLimitRequests_
    ) external {
        uint256 setProposeGasLimitLength = setProposeGasLimitRequests_.length;
        for (uint256 index = 0; index < setProposeGasLimitLength; ) {
            ITransmitManager(transmitManagerAddress_).setProposeGasLimit(
                setProposeGasLimitRequests_[index].nonce,
                setProposeGasLimitRequests_[index].dstChainId,
                setProposeGasLimitRequests_[index].proposeGasLimit,
                setProposeGasLimitRequests_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice set attest gas limit for a list of siblings
     * @param fastSwitchboardAddress_ address of fast switchboard
     * @param setAttestGasLimitRequests_ the list of requests with gas limit details
     */
    function setAttestGasLimits(
        address fastSwitchboardAddress_,
        SetAttestGasLimitRequest[] calldata setAttestGasLimitRequests_
    ) external {
        uint256 setAttestGasLimitLength = setAttestGasLimitRequests_.length;
        for (uint256 index = 0; index < setAttestGasLimitLength; ) {
            FastSwitchboard(fastSwitchboardAddress_).setAttestGasLimit(
                setAttestGasLimitRequests_[index].nonce,
                setAttestGasLimitRequests_[index].dstChainId,
                setAttestGasLimitRequests_[index].attestGasLimit,
                setAttestGasLimitRequests_[index].signature
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice set execution overhead for a list of siblings
     * @param switchboardAddress_ address of fast switchboard
     * @param setExecutionOverheadRequests_ the list of requests with gas limit details
     */
    function setExecutionOverheadBatch(
        address switchboardAddress_,
        SetExecutionOverheadRequest[] calldata setExecutionOverheadRequests_
    ) external {
        uint256 sealRequestslength = setExecutionOverheadRequests_.length;
        for (uint256 index = 0; index < sealRequestslength; ) {
            FastSwitchboard(switchboardAddress_).setExecutionOverhead(
                setExecutionOverheadRequests_[index].nonce,
                setExecutionOverheadRequests_[index].dstChainId,
                setExecutionOverheadRequests_[index].executionOverhead,
                setExecutionOverheadRequests_[index].signature
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
                attestRequests_[index].srcChainSlug,
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
    ) external {
        uint256 executeRequestslength = executeRequests_.length;
        for (uint256 index = 0; index < executeRequestslength; ) {
            ISocket(socketAddress_).execute(
                executeRequests_[index].packetId,
                executeRequests_[index].localPlug,
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
        bytes[] calldata receivePacketProofs_
    ) external {
        uint256 receivePacketProofsLength = receivePacketProofs_.length;
        for (uint256 index = 0; index < receivePacketProofsLength; ) {
            INativeRelay(polygonRootReceiverAddress_).receiveMessage(
                receivePacketProofs_[index]
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
                arbitrumNativeInitiatorRequests_[index].gasPriceBid
            );
            unchecked {
                ++index;
            }
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

abstract contract SocketConfig is ISocket, AccessControlExtended {
    struct PlugConfig {
        address siblingPlug;
        ICapacitor capacitor__;
        IDecapacitor decapacitor__;
        ISwitchboard inboundSwitchboard__;
        ISwitchboard outboundSwitchboard__;
    }

    ICapacitorFactory public capacitorFactory__;

    // siblingChainSlug => capacitor address
    mapping(address => uint32) public capacitorToSlug;

    // switchboard => siblingChainSlug => ICapacitor
    mapping(address => mapping(uint256 => ICapacitor)) public capacitors__;
    // switchboard => siblingChainSlug => IDecapacitor
    mapping(address => mapping(uint256 => IDecapacitor)) public decapacitors__;

    // plug => remoteChainSlug => (siblingPlug, capacitor__, decapacitor__, inboundSwitchboard__, outboundSwitchboard__)
    mapping(address => mapping(uint256 => PlugConfig)) internal _plugConfigs;

    event SwitchboardAdded(
        address switchboard,
        uint256 siblingChainSlug,
        address capacitor,
        address decapacitor,
        uint256 maxPacketLength,
        uint32 capacitorType
    );
    event CapacitorFactorySet(address capacitorFactory);

    error SwitchboardExists();
    error InvalidConnection();

    function setCapacitorFactory(
        address capacitorFactory_
    ) external onlyRole(GOVERNANCE_ROLE) {
        capacitorFactory__ = ICapacitorFactory(capacitorFactory_);
        emit CapacitorFactorySet(capacitorFactory_);
    }

    // it's msg.sender's responsibility to set correct sibling slug
    function registerSwitchBoard(
        address switchBoardAddress_,
        uint256 maxPacketLength_,
        uint32 siblingChainSlug_,
        uint32 capacitorType_
    ) external {
        // only capacitor checked, decapacitor assumed will exist if capacitor does
        if (
            address(capacitors__[switchBoardAddress_][siblingChainSlug_]) !=
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
        capacitors__[switchBoardAddress_][siblingChainSlug_] = capacitor__;
        decapacitors__[switchBoardAddress_][siblingChainSlug_] = decapacitor__;

        ISwitchboard(switchBoardAddress_).registerCapacitor(
            siblingChainSlug_,
            address(capacitor__),
            maxPacketLength_
        );

        emit SwitchboardAdded(
            switchBoardAddress_,
            siblingChainSlug_,
            address(capacitor__),
            address(decapacitor__),
            maxPacketLength_,
            capacitorType_
        );
    }

    function connect(
        uint256 siblingChainSlug_,
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
import "../interfaces/IPlug.sol";

import "./SocketBase.sol";

abstract contract SocketDst is SocketBase {
    error AlreadyAttested();
    error InvalidProof();
    error InvalidRetry();
    error MessageAlreadyExecuted();
    error NotExecutor();
    error VerificationFailed();

    // msgId => message status
    mapping(bytes32 => bool) public messageExecuted;
    // capacitorAddr|chainSlug|packetId
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

    function propose(
        bytes32 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external override {
        if (packetIdRoots[packetId_] != bytes32(0)) revert AlreadyAttested();

        (address transmitter, bool isTransmitter) = transmitManager__
            .checkTransmitter(
                uint32(_decodeSlug(packetId_)),
                keccak256(abi.encode(chainSlug, packetId_, root_)),
                signature_
            );

        if (!isTransmitter) revert InvalidAttester();

        packetIdRoots[packetId_] = root_;
        rootProposedAt[packetId_] = block.timestamp;

        emit PacketProposed(transmitter, packetId_, root_);
    }

    /**
     * @notice executes a message, fees will go to recovered executor address
     * @param packetId_ packet id
     * @param localPlug_ remote plug address
     * @param messageDetails_ the details needed for message verification
     */
    function execute(
        bytes32 packetId_,
        address localPlug_,
        ISocket.MessageDetails calldata messageDetails_,
        bytes memory signature_
    ) external override {
        if (messageExecuted[messageDetails_.msgId])
            revert MessageAlreadyExecuted();
        messageExecuted[messageDetails_.msgId] = true;

        uint256 remoteSlug = _decodeSlug(messageDetails_.msgId);

        PlugConfig storage plugConfig = _plugConfigs[localPlug_][remoteSlug];

        bytes32 packedMessage = hasher__.packMessage(
            remoteSlug,
            plugConfig.siblingPlug,
            chainSlug,
            localPlug_,
            messageDetails_.msgId,
            messageDetails_.msgGasLimit,
            messageDetails_.executionFee,
            messageDetails_.payload
        );

        (address executor, bool isValidExecutor) = executionManager__
            .isExecutor(packedMessage, signature_);
        if (!isValidExecutor) revert NotExecutor();

        _verify(
            packetId_,
            remoteSlug,
            packedMessage,
            plugConfig,
            messageDetails_.decapacitorProof
        );
        _execute(
            executor,
            messageDetails_.executionFee,
            localPlug_,
            remoteSlug,
            messageDetails_.msgGasLimit,
            messageDetails_.msgId,
            messageDetails_.payload
        );
    }

    function _verify(
        bytes32 packetId_,
        uint256 remoteChainSlug_,
        bytes32 packedMessage_,
        PlugConfig storage plugConfig_,
        bytes memory decapacitorProof_
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
    }

    function _execute(
        address executor,
        uint256 executionFee,
        address localPlug_,
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes32 msgId_,
        bytes calldata payload_
    ) internal {
        try
            IPlug(localPlug_).inbound{gas: msgGasLimit_}(
                remoteChainSlug_,
                payload_
            )
        {
            executionManager__.updateExecutionFees(
                executor,
                executionFee,
                msgId_
            );
            emit ExecutionSuccess(msgId_);
        } catch Error(string memory reason) {
            // catch failing revert() and require()
            messageExecuted[msgId_] = false;
            emit ExecutionFailed(msgId_, reason);
        } catch (bytes memory reason) {
            // catch failing assert()
            messageExecuted[msgId_] = false;
            emit ExecutionFailedBytes(msgId_, reason);
        }
    }

    function isPacketProposed(bytes32 packetId_) external view returns (bool) {
        return packetIdRoots[packetId_] == bytes32(0) ? false : true;
    }

    function _decodeSlug(
        bytes32 id_
    ) internal pure returns (uint256 chainSlug_) {
        chainSlug_ = uint256(id_) >> 224;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/ICapacitor.sol";
import "./SocketBase.sol";

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
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable override returns (bytes32 msgId) {
        PlugConfig storage plugConfig = _plugConfigs[msg.sender][
            remoteChainSlug_
        ];
        uint256 localChainSlug = chainSlug;

        msgId = _encodeMsgId(localChainSlug);

        ISocket.Fees memory fees = _deductFees(
            msgGasLimit_,
            uint32(remoteChainSlug_),
            plugConfig.outboundSwitchboard__
        );

        bytes32 packedMessage = hasher__.packMessage(
            localChainSlug,
            msg.sender,
            remoteChainSlug_,
            plugConfig.siblingPlug,
            msgId,
            msgGasLimit_,
            fees.executionFee,
            payload_
        );

        plugConfig.capacitor__.addPackedMessage(packedMessage);
        emit MessageOutbound(
            localChainSlug,
            msg.sender,
            remoteChainSlug_,
            plugConfig.siblingPlug,
            msgId,
            msgGasLimit_,
            payload_,
            fees
        );
    }

    function _deductFees(
        uint256 msgGasLimit_,
        uint32 remoteChainSlug_,
        ISwitchboard switchboard__
    ) internal returns (Fees memory fees) {
        uint256 minExecutionFees;
        (
            fees.transmissionFees,
            fees.switchboardFees,
            minExecutionFees
        ) = _getMinFees(msgGasLimit_, remoteChainSlug_, switchboard__);

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

            transmitManager__.payFees{value: fees.transmissionFees}(
                remoteChainSlug_
            );
            switchboard__.payFees{value: fees.switchboardFees}(
                remoteChainSlug_
            );
            executionManager__.payFees{value: fees.executionFee}(
                msgGasLimit_,
                remoteChainSlug_
            );
        }
    }

    function getMinFees(
        uint256 msgGasLimit_,
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
                remoteChainSlug_,
                plugConfig.outboundSwitchboard__
            );

        totalFees = transmissionFees + switchboardFees + executionFee;
    }

    function _getMinFees(
        uint256 msgGasLimit_,
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
            remoteChainSlug_
        );

        executionFee = msgExecutionFee + verificationFee;
    }

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
                keccak256(abi.encode(siblingChainSlug, packetId, root)),
                signature_
            );

        if (!isTransmitter) revert InvalidAttester();
        emit PacketVerifiedAndSealed(transmitter, packetId, root, signature_);
    }

    // Packs the local plug, local chain slug, remote chain slug and nonce
    // messageCount++ will take care of msg id overflow as well
    // msgId(256) = localChainSlug(32) | nonce(224)
    function _encodeMsgId(uint256 slug_) internal returns (bytes32) {
        return bytes32((uint256(uint32(slug_)) << 224) | messageCount++);
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
import "../../libraries/SignatureVerifierLib.sol";

contract FastSwitchboard is SwitchboardBase {
    mapping(bytes32 => bool) public isPacketValid;

    // dst chain slug => total watchers registered
    mapping(uint256 => uint256) public totalWatchers;

    // dst chain slug => attest gas limit
    mapping(uint256 => uint256) public attestGasLimit;

    // attester => packetId => is attested
    mapping(address => mapping(bytes32 => bool)) public isAttested;

    // packetId => total attestations
    mapping(bytes32 => uint256) public attestations;

    event SocketSet(address newSocket);
    event PacketAttested(bytes32 packetId, address attester);
    event AttestGasLimitSet(uint256 dstChainSlug, uint256 attestGasLimit);

    error WatcherFound();
    error WatcherNotFound();
    error AlreadyAttested();

    constructor(
        address owner_,
        address socket_,
        address gasPriceOracle_,
        uint256 chainSlug_,
        uint256 timeoutInSeconds_
    )
        AccessControlExtended(owner_)
        SwitchboardBase(gasPriceOracle_, socket_, chainSlug_, timeoutInSeconds_)
    {}

    function attest(
        bytes32 packetId_,
        uint256 srcChainSlug_,
        bytes calldata signature_
    ) external {
        address watcher = SignatureVerifierLib.recoverSignerFromDigest(
            keccak256(abi.encode(srcChainSlug_, packetId_)),
            signature_
        );

        if (isAttested[watcher][packetId_]) revert AlreadyAttested();
        if (!_hasRole("WATCHER_ROLE", srcChainSlug_, watcher))
            revert WatcherNotFound();

        isAttested[watcher][packetId_] = true;
        attestations[packetId_]++;

        if (attestations[packetId_] >= totalWatchers[srcChainSlug_])
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

    function _getMinSwitchboardFees(
        uint256 dstChainSlug_,
        uint256 dstRelativeGasPrice_
    ) internal view override returns (uint256) {
        // assumption: number of watchers are going to be same on all chains for particular chain slug?
        return
            totalWatchers[dstChainSlug_] *
            attestGasLimit[dstChainSlug_] *
            dstRelativeGasPrice_;
    }

    /**
     * @notice updates attest gas limit for given chain slug
     * @param dstChainSlug_ destination chain
     * @param attestGasLimit_ average gas limit needed for attest function call
     */
    function setAttestGasLimit(
        uint256 nonce_,
        uint256 dstChainSlug_,
        uint256 attestGasLimit_,
        bytes calldata signature_
    ) external {
        address gasLimitUpdater = SignatureVerifierLib.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "ATTEST_GAS_LIMIT_UPDATE",
                    chainSlug,
                    dstChainSlug_,
                    nonce_,
                    attestGasLimit_
                )
            ),
            signature_
        );

        if (!_hasRole("GAS_LIMIT_UPDATER_ROLE", dstChainSlug_, gasLimitUpdater))
            revert NoPermit("GAS_LIMIT_UPDATER_ROLE");

        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        attestGasLimit[dstChainSlug_] = attestGasLimit_;
        emit AttestGasLimitSet(dstChainSlug_, attestGasLimit_);
    }

    /**
     * @notice adds a watcher for `srcChainSlug_` chain
     * @param watcher_ watcher address
     */
    function grantWatcherRole(
        uint256 srcChainSlug_,
        address watcher_
    ) external onlyRole(GOVERNANCE_ROLE) {
        if (_hasRole("WATCHER_ROLE", srcChainSlug_, watcher_))
            revert WatcherFound();
        _grantRole("WATCHER_ROLE", srcChainSlug_, watcher_);

        totalWatchers[srcChainSlug_]++;
    }

    /**
     * @notice removes a watcher from `srcChainSlug_` chain list
     * @param watcher_ watcher address
     */
    function revokeWatcherRole(
        uint256 srcChainSlug_,
        address watcher_
    ) external onlyRole(GOVERNANCE_ROLE) {
        if (!_hasRole("WATCHER_ROLE", srcChainSlug_, watcher_))
            revert WatcherNotFound();
        _revokeRole("WATCHER_ROLE", srcChainSlug_, watcher_);

        totalWatchers[srcChainSlug_]--;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./SwitchboardBase.sol";

contract OptimisticSwitchboard is SwitchboardBase {
    constructor(
        address owner_,
        address socket_,
        address gasPriceOracle_,
        uint256 chainSlug_,
        uint256 timeoutInSeconds_
    )
        AccessControlExtended(owner_)
        SwitchboardBase(gasPriceOracle_, socket_, chainSlug_, timeoutInSeconds_)
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

    function _getMinSwitchboardFees(
        uint256,
        uint256
    ) internal pure override returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/IGasPriceOracle.sol";
import "../../utils/AccessControlExtended.sol";

import "../../libraries/SignatureVerifierLib.sol";
import "../../libraries/RescueFundsLib.sol";
import "../../libraries/FeesHelper.sol";

import {GOVERNANCE_ROLE, WITHDRAW_ROLE, RESCUE_ROLE, GAS_LIMIT_UPDATER_ROLE} from "../../utils/AccessRoles.sol";

abstract contract SwitchboardBase is ISwitchboard, AccessControlExtended {
    IGasPriceOracle public gasPriceOracle__;

    bool public tripGlobalFuse;
    address public socket;
    uint256 public immutable chainSlug;
    uint256 public immutable timeoutInSeconds;

    mapping(uint256 => bool) public isInitialised;
    mapping(uint256 => uint256) public maxPacketSize;

    mapping(uint256 => uint256) public executionOverhead;

    // sourceChain => isPaused
    mapping(uint256 => bool) public tripSinglePath;

    // watcher => nextNonce
    mapping(address => uint256) public nextNonce;

    event PathTripped(uint256 srcChainSlug, bool tripSinglePath);
    event SwitchboardTripped(bool tripGlobalFuse);
    event ExecutionOverheadSet(uint256 dstChainSlug, uint256 executionOverhead);
    event GasPriceOracleSet(address gasPriceOracle);
    event CapacitorRegistered(
        uint256 siblingChainSlug,
        address capacitor,
        uint256 maxPacketSize
    );

    error AlreadyInitialised();
    error InvalidNonce();
    error OnlySocket();

    constructor(
        address gasPriceOracle_,
        address socket_,
        uint256 chainSlug_,
        uint256 timeoutInSeconds_
    ) {
        gasPriceOracle__ = IGasPriceOracle(gasPriceOracle_);
        socket = socket_;
        chainSlug = chainSlug_;
        timeoutInSeconds = timeoutInSeconds_;
    }

    function payFees(uint32 dstChainSlug_) external payable override {}

    function getMinFees(
        uint32 dstChainSlug_
    ) external view override returns (uint256, uint256) {
        return _calculateMinFees(dstChainSlug_);
    }

    function _calculateMinFees(
        uint32 dstChainSlug_
    ) internal view returns (uint256 switchboardFee, uint256 verificationFee) {
        uint256 dstRelativeGasPrice = gasPriceOracle__.relativeGasPrice(
            dstChainSlug_
        );

        switchboardFee =
            _getMinSwitchboardFees(dstChainSlug_, dstRelativeGasPrice) /
            maxPacketSize[dstChainSlug_];
        verificationFee =
            executionOverhead[dstChainSlug_] *
            dstRelativeGasPrice;
    }

    function _getMinSwitchboardFees(
        uint256 dstChainSlug_,
        uint256 dstRelativeGasPrice_
    ) internal view virtual returns (uint256);

    /**
     * @notice set capacitor address and packet size
     * @param capacitor_ capacitor address
     * @param maxPacketSize_ max messages allowed in one packet
     */
    function registerCapacitor(
        uint256 siblingChainSlug_,
        address capacitor_,
        uint256 maxPacketSize_
    ) external override {
        if (msg.sender != socket) revert OnlySocket();
        if (isInitialised[siblingChainSlug_]) revert AlreadyInitialised();

        isInitialised[siblingChainSlug_] = true;
        maxPacketSize[siblingChainSlug_] = maxPacketSize_;
        emit CapacitorRegistered(siblingChainSlug_, capacitor_, maxPacketSize_);
    }

    /**
     * @notice pause a path
     */
    function tripPath(
        uint256 nonce_,
        uint256 srcChainSlug_,
        bytes memory signature_
    ) external {
        address watcher = SignatureVerifierLib.recoverSignerFromDigest(
            // it includes trip status at the end
            keccak256(
                abi.encode("TRIP_PATH", srcChainSlug_, chainSlug, nonce_, true)
            ),
            signature_
        );

        if (!_hasRole("WATCHER_ROLE", srcChainSlug_, watcher))
            revert NoPermit("WATCHER_ROLE");
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
        address tripper = SignatureVerifierLib.recoverSignerFromDigest(
            // it includes trip status at the end
            keccak256(abi.encode("TRIP", chainSlug, nonce_, true)),
            signature_
        );

        if (!_hasRole("TRIP_ROLE", tripper)) revert NoPermit("TRIP_ROLE");
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
        uint256 srcChainSlug_,
        bytes memory signature_
    ) external {
        address untripper = SignatureVerifierLib.recoverSignerFromDigest(
            // it includes trip status at the end
            keccak256(
                abi.encode(
                    "UNTRIP_PATH",
                    chainSlug,
                    srcChainSlug_,
                    nonce_,
                    false
                )
            ),
            signature_
        );

        if (!_hasRole("UNTRIP_ROLE", untripper)) revert NoPermit("UNTRIP_ROLE");
        uint256 nonce = nextNonce[untripper]++;
        if (nonce_ != nonce) revert InvalidNonce();

        tripSinglePath[srcChainSlug_] = false;
        emit PathTripped(srcChainSlug_, false);
    }

    /**
     * @notice unpause execution
     */
    function untrip(uint256 nonce_, bytes memory signature_) external {
        address untripper = SignatureVerifierLib.recoverSignerFromDigest(
            // it includes trip status at the end
            keccak256(abi.encode("UNTRIP", chainSlug, nonce_, false)),
            signature_
        );

        if (!_hasRole("UNTRIP_ROLE", untripper)) revert NoPermit("UNTRIP_ROLE");
        uint256 nonce = nextNonce[untripper]++;
        if (nonce_ != nonce) revert InvalidNonce();

        tripGlobalFuse = false;
        emit SwitchboardTripped(false);
    }

    /**
     * @notice updates execution overhead
     * @param executionOverhead_ new execution overhead cost
     */
    function setExecutionOverhead(
        uint256 nonce_,
        uint256 dstChainSlug_,
        uint256 executionOverhead_,
        bytes memory signature_
    ) external {
        address gasLimitUpdater = SignatureVerifierLib.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "EXECUTION_OVERHEAD_UPDATE",
                    nonce_,
                    chainSlug,
                    dstChainSlug_,
                    executionOverhead_
                )
            ),
            signature_
        );

        if (!_hasRole("GAS_LIMIT_UPDATER_ROLE", dstChainSlug_, gasLimitUpdater))
            revert NoPermit("GAS_LIMIT_UPDATER_ROLE");
        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        executionOverhead[dstChainSlug_] = executionOverhead_;
        emit ExecutionOverheadSet(dstChainSlug_, executionOverhead_);
    }

    /**
     * @notice updates gasPriceOracle_ address
     * @param gasPriceOracle_ new gasPriceOracle_
     */
    function setGasPriceOracle(
        address gasPriceOracle_
    ) external onlyRole(GOVERNANCE_ROLE) {
        gasPriceOracle__ = IGasPriceOracle(gasPriceOracle_);
        emit GasPriceOracleSet(gasPriceOracle_);
    }

    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        FeesHelper.withdrawFees(account_);
    }

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

contract ArbitrumL1Switchboard is NativeSwitchboardBase {
    address public remoteRefundAddress;
    address public callValueRefundAddress;
    uint256 public arbitrumNativeFee;

    IInbox public inbox__;
    IBridge public bridge__;
    IOutbox public outbox__;

    event UpdatedInboxAddress(address inbox);
    event UpdatedRefundAddresses(
        address remoteRefundAddress,
        address callValueRefundAddress
    );
    event UpdatedArbitrumNativeFee(uint256 arbitrumNativeFee);
    event UpdatedBridge(address bridgeAddress);
    event UpdatedOutbox(address outboxAddress);

    modifier onlyRemoteSwitchboard() override {
        if (msg.sender != address(bridge__)) revert InvalidSender();
        address l2Sender = outbox__.l2ToL1Sender();
        if (l2Sender != remoteNativeSwitchboard) revert InvalidSender();
        _;
    }

    constructor(
        uint256 chainSlug_,
        uint256 arbitrumNativeFee_,
        uint256 initiateGasLimit_,
        uint256 executionOverhead_,
        address inbox_,
        address owner_,
        address socket_,
        IGasPriceOracle gasPriceOracle_,
        address bridge_,
        address outbox_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(
            socket_,
            chainSlug_,
            initiateGasLimit_,
            executionOverhead_,
            gasPriceOracle_
        )
    {
        inbox__ = IInbox(inbox_);
        arbitrumNativeFee = arbitrumNativeFee_;

        bridge__ = IBridge(bridge_);
        outbox__ = IOutbox(outbox_);

        remoteRefundAddress = msg.sender;
        callValueRefundAddress = msg.sender;
    }

    function initiateNativeConfirmation(
        bytes32 packetId_,
        uint256 maxSubmissionCost_,
        uint256 maxGas_,
        uint256 gasPriceBid_
    ) external payable {
        bytes memory data = _encodeRemoteCall(packetId_);

        // to avoid stack too deep
        address callValueRefund = callValueRefundAddress;
        address remoteRefund = remoteRefundAddress;

        inbox__.createRetryableTicket{value: msg.value}(
            remoteNativeSwitchboard,
            0, // no value needed for receivePacket
            maxSubmissionCost_,
            remoteRefund,
            callValueRefund,
            maxGas_,
            gasPriceBid_,
            data
        );

        emit InitiatedNativeConfirmation(packetId_);
    }

    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encodeWithSelector(
            this.receivePacket.selector,
            packetId_,
            _getRoot(packetId_)
        );
    }

    function _getMinSwitchboardFees(
        uint256,
        uint256,
        uint256 sourceGasPrice_
    ) internal view override returns (uint256) {
        // TODO: check if dynamic fees can be divided into more constants
        // arbitrum: check src contract
        return initiateGasLimit * sourceGasPrice_ + arbitrumNativeFee;
    }

    function updateRefundAddresses(
        address remoteRefundAddress_,
        address callValueRefundAddress_
    ) external onlyRole(GOVERNANCE_ROLE) {
        remoteRefundAddress = remoteRefundAddress_;
        callValueRefundAddress = callValueRefundAddress_;

        emit UpdatedRefundAddresses(
            remoteRefundAddress_,
            callValueRefundAddress_
        );
    }

    function updateArbitrumNativeFee(
        uint256 nonce_,
        uint256 arbitrumNativeFee_,
        bytes calldata signature_
    ) external {
        address gasLimitUpdater = SignatureVerifierLib.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "ARBITRUM_NATIVE_FEE_UPDATE",
                    chainSlug,
                    nonce_,
                    arbitrumNativeFee_
                )
            ),
            signature_
        );

        if (!_hasRole(GAS_LIMIT_UPDATER_ROLE, gasLimitUpdater))
            revert NoPermit(GAS_LIMIT_UPDATER_ROLE);
        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        arbitrumNativeFee = arbitrumNativeFee_;
        emit UpdatedArbitrumNativeFee(arbitrumNativeFee_);
    }

    function updateInboxAddresses(
        address inbox_
    ) external onlyRole(GOVERNANCE_ROLE) {
        inbox__ = IInbox(inbox_);
        emit UpdatedInboxAddress(inbox_);
    }

    function updateBridge(
        address bridgeAddress_
    ) external onlyRole(GOVERNANCE_ROLE) {
        bridge__ = IBridge(bridgeAddress_);

        emit UpdatedBridge(bridgeAddress_);
    }

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

contract ArbitrumL2Switchboard is NativeSwitchboardBase {
    uint256 public confirmGasLimit;
    IArbSys public immutable arbsys__ = IArbSys(address(100));
    event UpdatedConfirmGasLimit(uint256 confirmGasLimit);

    modifier onlyRemoteSwitchboard() override {
        if (
            msg.sender !=
            AddressAliasHelper.applyL1ToL2Alias(remoteNativeSwitchboard)
        ) revert InvalidSender();
        _;
    }

    constructor(
        uint256 chainSlug_,
        uint256 confirmGasLimit_,
        uint256 initiateGasLimit_,
        uint256 executionOverhead_,
        address owner_,
        address socket_,
        IGasPriceOracle gasPriceOracle_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(
            socket_,
            chainSlug_,
            initiateGasLimit_,
            executionOverhead_,
            gasPriceOracle_
        )
    {
        confirmGasLimit = confirmGasLimit_;
    }

    function initiateNativeConfirmation(bytes32 packetId_) external {
        bytes memory data = _encodeRemoteCall(packetId_);

        arbsys__.sendTxToL1(remoteNativeSwitchboard, data);
        emit InitiatedNativeConfirmation(packetId_);
    }

    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encodeWithSelector(
            this.receivePacket.selector,
            packetId_,
            _getRoot(packetId_)
        );
    }

    function _getMinSwitchboardFees(
        uint256,
        uint256 dstRelativeGasPrice_,
        uint256 sourceGasPrice_
    ) internal view override returns (uint256) {
        return
            initiateGasLimit *
            sourceGasPrice_ +
            confirmGasLimit *
            dstRelativeGasPrice_;
    }

    function updateConfirmGasLimit(
        uint256 nonce_,
        uint256 confirmGasLimit_,
        bytes memory signature_
    ) external {
        address gasLimitUpdater = SignatureVerifierLib.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "L1_RECEIVE_GAS_LIMIT_UPDATE",
                    chainSlug,
                    nonce_,
                    confirmGasLimit_
                )
            ),
            signature_
        );

        if (!_hasRole(GAS_LIMIT_UPDATER_ROLE, gasLimitUpdater))
            revert NoPermit(GAS_LIMIT_UPDATER_ROLE);
        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        confirmGasLimit = confirmGasLimit_;
        emit UpdatedConfirmGasLimit(confirmGasLimit_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/IGasPriceOracle.sol";
import "../../interfaces/ICapacitor.sol";

import "../../utils/AccessControlExtended.sol";
import "../../libraries/SignatureVerifierLib.sol";
import "../../libraries/RescueFundsLib.sol";
import "../../libraries/FeesHelper.sol";

import {GAS_LIMIT_UPDATER_ROLE, GOVERNANCE_ROLE, RESCUE_ROLE, WITHDRAW_ROLE, TRIP_ROLE, UNTRIP_ROLE} from "../../utils/AccessRoles.sol";

abstract contract NativeSwitchboardBase is ISwitchboard, AccessControlExtended {
    IGasPriceOracle public gasPriceOracle__;

    bool public tripGlobalFuse;

    ICapacitor public capacitor__;
    bool public isInitialised;
    uint256 public maxPacketSize;

    uint256 public executionOverhead;
    uint256 public initiateGasLimit;
    address public remoteNativeSwitchboard;
    address public socket;

    uint256 public immutable chainSlug;

    // stores the roots received from native bridge
    mapping(bytes32 => bytes32) public packetIdToRoot;
    // transmitter => nextNonce
    mapping(address => uint256) public nextNonce;

    event SwitchboardTripped(bool tripGlobalFuse);
    event ExecutionOverheadSet(uint256 executionOverhead);
    event InitiateGasLimitSet(uint256 gasLimit);
    event CapacitorSet(address capacitor);
    event GasPriceOracleSet(address gasPriceOracle);
    event InitiatedNativeConfirmation(bytes32 packetId);
    event CapacitorRegistered(address capacitor, uint256 maxPacketSize);
    event UpdatedRemoteNativeSwitchboard(address remoteNativeSwitchboard);
    event RootReceived(bytes32 packetId, bytes32 root);

    error FeesNotEnough();
    error AlreadyInitialised();
    error InvalidSender();
    error NoRootFound();
    error InvalidNonce();
    error OnlySocket();

    modifier onlyRemoteSwitchboard() virtual {
        _;
    }

    constructor(
        address socket_,
        uint256 chainSlug_,
        uint256 initiateGasLimit_,
        uint256 executionOverhead_,
        IGasPriceOracle gasPriceOracle_
    ) {
        socket = socket_;
        chainSlug = chainSlug_;
        initiateGasLimit = initiateGasLimit_;
        executionOverhead = executionOverhead_;
        gasPriceOracle__ = gasPriceOracle_;
    }

    function _getRoot(bytes32 packetId_) internal view returns (bytes32 root) {
        uint64 capacitorPacketCount = uint64(uint256(packetId_));
        root = capacitor__.getRootByCount(capacitorPacketCount);
        if (root == bytes32(0)) revert NoRootFound();
    }

    function receivePacket(
        bytes32 packetId_,
        bytes32 root_
    ) external onlyRemoteSwitchboard {
        packetIdToRoot[packetId_] = root_;
        emit RootReceived(packetId_, root_);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId_ packet id
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

    // assumption: natives have 18 decimals
    function payFees(uint32 dstChainSlug_) external payable override {}

    function getMinFees(
        uint32 dstChainSlug_
    )
        external
        view
        override
        returns (uint256 switchboardFee_, uint256 verificationFee_)
    {
        return _calculateMinFees(dstChainSlug_);
    }

    function _calculateMinFees(
        uint32 dstChainSlug_
    )
        internal
        view
        returns (uint256 switchboardFee_, uint256 verificationFee_)
    {
        (uint256 sourceGasPrice, uint256 dstRelativeGasPrice) = gasPriceOracle__
            .getGasPrices(dstChainSlug_);

        switchboardFee_ =
            _getMinSwitchboardFees(
                dstChainSlug_,
                dstRelativeGasPrice,
                sourceGasPrice
            ) /
            maxPacketSize;

        verificationFee_ = executionOverhead * dstRelativeGasPrice;
    }

    function _getMinSwitchboardFees(
        uint256 dstChainSlug_,
        uint256 dstRelativeGasPrice_,
        uint256 sourceGasPrice_
    ) internal view virtual returns (uint256);

    /**
     * @notice set capacitor address and packet size
     * @param capacitor_ capacitor address
     * @param maxPacketSize_ max messages allowed in one packet
     */
    function registerCapacitor(
        uint256,
        address capacitor_,
        uint256 maxPacketSize_
    ) external override {
        if (msg.sender != socket) revert OnlySocket();
        if (isInitialised) revert AlreadyInitialised();

        isInitialised = true;
        maxPacketSize = maxPacketSize_;
        capacitor__ = ICapacitor(capacitor_);

        emit CapacitorRegistered(capacitor_, maxPacketSize_);
    }

    /**
     * @notice pause execution
     */
    function tripGlobal(uint256 nonce_, bytes memory signature_) external {
        address watcher = SignatureVerifierLib.recoverSignerFromDigest(
            // it includes trip status at the end
            keccak256(abi.encode("TRIP", chainSlug, nonce_, true)),
            signature_
        );

        if (!_hasRole(TRIP_ROLE, watcher)) revert NoPermit(TRIP_ROLE);

        uint256 nonce = nextNonce[watcher]++;
        if (nonce_ != nonce) revert InvalidNonce();

        tripGlobalFuse = true;
        emit SwitchboardTripped(true);
    }

    /**
     * @notice unpause execution
     */
    function untrip(uint256 nonce_, bytes memory signature_) external {
        address watcher = SignatureVerifierLib.recoverSignerFromDigest(
            // it includes trip status at the end
            keccak256(abi.encode("UNTRIP", chainSlug, nonce_, false)),
            signature_
        );

        if (!_hasRole(UNTRIP_ROLE, watcher)) revert NoPermit(UNTRIP_ROLE);
        uint256 nonce = nextNonce[watcher]++;
        if (nonce_ != nonce) revert InvalidNonce();

        tripGlobalFuse = false;
        emit SwitchboardTripped(false);
    }

    /**
     * @notice updates execution overhead
     * @param executionOverhead_ new execution overhead cost
     */
    function setExecutionOverhead(
        uint256 nonce_,
        uint256 executionOverhead_,
        bytes memory signature_
    ) external {
        address gasLimitUpdater = SignatureVerifierLib.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "EXECUTION_OVERHEAD_UPDATE",
                    nonce_,
                    chainSlug,
                    executionOverhead_
                )
            ),
            signature_
        );

        if (!_hasRole(GAS_LIMIT_UPDATER_ROLE, gasLimitUpdater))
            revert NoPermit(GAS_LIMIT_UPDATER_ROLE);
        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        executionOverhead = executionOverhead_;
        emit ExecutionOverheadSet(executionOverhead_);
    }

    /**
     * @notice updates initiateGasLimit
     * @param gasLimit_ new gas limit for initiateGasLimit
     */
    function setInitiateGasLimit(
        uint256 nonce_,
        uint256 gasLimit_,
        bytes memory signature_
    ) external {
        address gasLimitUpdater = SignatureVerifierLib.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "INITIAL_CONFIRMATION_GAS_LIMIT_UPDATE",
                    chainSlug,
                    nonce_,
                    gasLimit_
                )
            ),
            signature_
        );

        if (!_hasRole(GAS_LIMIT_UPDATER_ROLE, gasLimitUpdater))
            revert NoPermit(GAS_LIMIT_UPDATER_ROLE);
        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        initiateGasLimit = gasLimit_;
        emit InitiateGasLimitSet(gasLimit_);
    }

    /**
     * @notice updates gasPriceOracle_ address
     * @param gasPriceOracle_ new gasPriceOracle_
     */
    function setGasPriceOracle(
        address gasPriceOracle_
    ) external onlyRole(GOVERNANCE_ROLE) {
        gasPriceOracle__ = IGasPriceOracle(gasPriceOracle_);
        emit GasPriceOracleSet(gasPriceOracle_);
    }

    function updateRemoteNativeSwitchboard(
        address remoteNativeSwitchboard_
    ) external onlyRole(GOVERNANCE_ROLE) {
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        emit UpdatedRemoteNativeSwitchboard(remoteNativeSwitchboard_);
    }

    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        FeesHelper.withdrawFees(account_);
    }

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

contract OptimismSwitchboard is NativeSwitchboardBase {
    uint256 public receiveGasLimit;
    uint256 public confirmGasLimit;

    ICrossDomainMessenger public immutable crossDomainMessenger__;

    event UpdatedReceiveGasLimit(uint256 receiveGasLimit);
    event UpdatedConfirmGasLimit(uint256 confirmGasLimit);

    modifier onlyRemoteSwitchboard() override {
        if (
            msg.sender != address(crossDomainMessenger__) &&
            crossDomainMessenger__.xDomainMessageSender() !=
            remoteNativeSwitchboard
        ) revert InvalidSender();
        _;
    }

    constructor(
        uint256 chainSlug_,
        uint256 receiveGasLimit_,
        uint256 confirmGasLimit_,
        uint256 initiateGasLimit_,
        uint256 executionOverhead_,
        address owner_,
        address socket_,
        IGasPriceOracle gasPriceOracle_,
        address crossDomainMessenger_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(
            socket_,
            chainSlug_,
            initiateGasLimit_,
            executionOverhead_,
            gasPriceOracle_
        )
    {
        receiveGasLimit = receiveGasLimit_;
        confirmGasLimit = confirmGasLimit_;
        crossDomainMessenger__ = ICrossDomainMessenger(crossDomainMessenger_);
    }

    function initiateNativeConfirmation(bytes32 packetId_) external {
        bytes memory data = _encodeRemoteCall(packetId_);

        crossDomainMessenger__.sendMessage(
            remoteNativeSwitchboard,
            data,
            uint32(receiveGasLimit)
        );
        emit InitiatedNativeConfirmation(packetId_);
    }

    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encodeWithSelector(
            this.receivePacket.selector,
            packetId_,
            _getRoot(packetId_)
        );
    }

    function _getMinSwitchboardFees(
        uint256,
        uint256 dstRelativeGasPrice_,
        uint256 sourceGasPrice_
    ) internal view override returns (uint256) {
        // confirmGasLimit will be 0 when switchboard is deployed on L1
        return
            initiateGasLimit *
            sourceGasPrice_ +
            confirmGasLimit *
            dstRelativeGasPrice_;
    }

    function updateConfirmGasLimit(
        uint256 nonce_,
        uint256 confirmGasLimit_,
        bytes memory signature_
    ) external {
        address gasLimitUpdater = SignatureVerifierLib.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "L1_RECEIVE_GAS_LIMIT_UPDATE",
                    chainSlug,
                    nonce_,
                    confirmGasLimit_
                )
            ),
            signature_
        );

        if (!_hasRole(GAS_LIMIT_UPDATER_ROLE, gasLimitUpdater))
            revert NoPermit(GAS_LIMIT_UPDATER_ROLE);
        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        confirmGasLimit = confirmGasLimit_;
        emit UpdatedConfirmGasLimit(confirmGasLimit_);
    }

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

contract PolygonL1Switchboard is NativeSwitchboardBase, FxBaseRootTunnel {
    event FxChildTunnelSet(address fxChildTunnel, address newFxChildTunnel);

    modifier onlyRemoteSwitchboard() override {
        require(true, "ONLY_FX_CHILD");

        _;
    }

    constructor(
        uint256 chainSlug_,
        uint256 initiateGasLimit_,
        uint256 executionOverhead_,
        address checkpointManager_,
        address fxRoot_,
        address owner_,
        address socket_,
        IGasPriceOracle gasPriceOracle_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(
            socket_,
            chainSlug_,
            initiateGasLimit_,
            executionOverhead_,
            gasPriceOracle_
        )
        FxBaseRootTunnel(checkpointManager_, fxRoot_)
    {}

    /**
     * @param packetId_ - packet id
     */
    function initiateNativeConfirmation(bytes32 packetId_) external payable {
        bytes memory data = _encodeRemoteCall(packetId_);
        _sendMessageToChild(data);
        emit InitiatedNativeConfirmation(packetId_);
    }

    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encode(packetId_, _getRoot(packetId_));
    }

    function _processMessageFromChild(bytes memory message_) internal override {
        (bytes32 packetId, bytes32 root) = abi.decode(
            message_,
            (bytes32, bytes32)
        );
        packetIdToRoot[packetId] = root;
        emit RootReceived(packetId, root);
    }

    function _getMinSwitchboardFees(
        uint256,
        uint256,
        uint256 sourceGasPrice_
    ) internal view override returns (uint256) {
        return initiateGasLimit * sourceGasPrice_;
    }

    // set fxChildTunnel if not set already
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

contract PolygonL2Switchboard is NativeSwitchboardBase, FxBaseChildTunnel {
    uint256 public confirmGasLimit;

    event FxChildUpdate(address oldFxChild, address newFxChild);
    event FxRootTunnelSet(address fxRootTunnel, address newFxRootTunnel);
    event UpdatedConfirmGasLimit(uint256 confirmGasLimit);

    modifier onlyRemoteSwitchboard() override {
        require(true, "ONLY_FX_CHILD");

        _;
    }

    constructor(
        uint256 chainSlug_,
        uint256 confirmGasLimit_,
        uint256 initiateGasLimit_,
        uint256 executionOverhead_,
        address fxChild_,
        address owner_,
        address socket_,
        IGasPriceOracle gasPriceOracle_
    )
        AccessControlExtended(owner_)
        NativeSwitchboardBase(
            socket_,
            chainSlug_,
            initiateGasLimit_,
            executionOverhead_,
            gasPriceOracle_
        )
        FxBaseChildTunnel(fxChild_)
    {
        confirmGasLimit = confirmGasLimit_;
    }

    /**
     * @param packetId_ - packet id
     */
    function initiateNativeConfirmation(bytes32 packetId_) external payable {
        bytes memory data = _encodeRemoteCall(packetId_);

        _sendMessageToRoot(data);
        emit InitiatedNativeConfirmation(packetId_);
    }

    function _encodeRemoteCall(
        bytes32 packetId_
    ) internal view returns (bytes memory data) {
        data = abi.encode(packetId_, _getRoot(packetId_));
    }

    /**
     * validate sender verifies if `rootMessageSender` is the root contract (notary) on L1.
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

    function _getMinSwitchboardFees(
        uint256,
        uint256 dstRelativeGasPrice_,
        uint256 sourceGasPrice_
    ) internal view override returns (uint256) {
        return
            initiateGasLimit *
            sourceGasPrice_ +
            confirmGasLimit *
            dstRelativeGasPrice_;
    }

    function updateConfirmGasLimit(
        uint256 nonce_,
        uint256 confirmGasLimit_,
        bytes memory signature_
    ) external {
        address gasLimitUpdater = SignatureVerifierLib.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "L1_RECEIVE_GAS_LIMIT_UPDATE",
                    chainSlug,
                    nonce_,
                    confirmGasLimit_
                )
            ),
            signature_
        );

        if (!_hasRole(GAS_LIMIT_UPDATER_ROLE, gasLimitUpdater))
            revert NoPermit(GAS_LIMIT_UPDATER_ROLE);
        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        confirmGasLimit = confirmGasLimit_;
        emit UpdatedConfirmGasLimit(confirmGasLimit_);
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

    function setFxRootTunnel(
        address fxRootTunnel_
    ) external override onlyRole(GOVERNANCE_ROLE) {
        emit FxRootTunnelSet(fxRootTunnel, fxRootTunnel_);
        fxRootTunnel = fxRootTunnel_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./interfaces/ITransmitManager.sol";
import "./interfaces/ISignatureVerifier.sol";
import "./interfaces/IGasPriceOracle.sol";

import "./utils/AccessControlExtended.sol";
import "./libraries/RescueFundsLib.sol";
import "./libraries/FeesHelper.sol";
import {GOVERNANCE_ROLE, WITHDRAW_ROLE, RESCUE_ROLE, GAS_LIMIT_UPDATER_ROLE} from "./utils/AccessRoles.sol";

contract TransmitManager is ITransmitManager, AccessControlExtended {
    ISignatureVerifier public signatureVerifier__;
    IGasPriceOracle public gasPriceOracle__;

    uint32 public immutable chainSlug;
    uint256 public sealGasLimit;
    mapping(uint256 => uint256) public proposeGasLimit;

    // transmitter => nextNonce
    mapping(address => uint256) public nextNonce;

    error InsufficientTransmitFees();
    error InvalidNonce();

    event GasPriceOracleSet(address gasPriceOracle);
    event SealGasLimitSet(uint256 gasLimit);
    event ProposeGasLimitSet(uint256 dstChainSlug, uint256 gasLimit);

    /**
     * @notice emits when a new signature verifier contract is set
     * @param signatureVerifier address of new verifier contract
     */
    event SignatureVerifierSet(address signatureVerifier);

    constructor(
        ISignatureVerifier signatureVerifier_,
        IGasPriceOracle gasPriceOracle_,
        address owner_,
        uint32 chainSlug_,
        uint256 sealGasLimit_
    ) AccessControlExtended(owner_) {
        chainSlug = chainSlug_;
        sealGasLimit = sealGasLimit_;
        signatureVerifier__ = signatureVerifier_;
        gasPriceOracle__ = IGasPriceOracle(gasPriceOracle_);
    }

    // @param slugs_ packs the siblingChainSlug & sigChainSlug
    // @dev signature sent to this function can be reused on other chains
    // @dev hence caller should add some identifier to stop this.
    // slugs_(256) = siblingChainSlug(128) | sigChainSlug(128)
    // @dev sibling chain slug is required to check the transmitter role
    // @dev sig chain slug is required by signature. On src, this is sibling slug while on
    // destination, it is current chain slug
    function checkTransmitter(
        uint32 siblingSlug,
        bytes32 digest_,
        bytes calldata signature_
    ) external view override returns (address, bool) {
        address transmitter = signatureVerifier__.recoverSignerFromDigest(
            digest_,
            signature_
        );

        return (
            transmitter,
            _hasRole("TRANSMITTER_ROLE", siblingSlug, transmitter)
        );
    }

    function payFees(uint32 siblingChainSlug_) external payable override {}

    function getMinFees(
        uint32 siblingChainSlug_
    ) external view override returns (uint256) {
        return _calculateMinFees(siblingChainSlug_);
    }

    function _calculateMinFees(
        uint32 siblingChainSlug_
    ) internal view returns (uint256 minTransmissionFees) {
        (
            uint256 sourceGasPrice,
            uint256 siblingRelativeGasPrice
        ) = gasPriceOracle__.getGasPrices(siblingChainSlug_);

        minTransmissionFees =
            sealGasLimit *
            sourceGasPrice +
            proposeGasLimit[siblingChainSlug_] *
            siblingRelativeGasPrice;
    }

    function withdrawFees(address account_) external onlyRole(WITHDRAW_ROLE) {
        FeesHelper.withdrawFees(account_);
    }

    /**
     * @notice updates seal gas limit
     * @param gasLimit_ new seal gas limit
     */
    function setSealGasLimit(
        uint256 nonce_,
        uint256 gasLimit_,
        bytes calldata signature_
    ) external {
        address gasLimitUpdater = signatureVerifier__.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "SEAL_GAS_LIMIT_UPDATE",
                    chainSlug,
                    nonce_,
                    gasLimit_
                )
            ),
            signature_
        );

        if (!_hasRole(GAS_LIMIT_UPDATER_ROLE, gasLimitUpdater))
            revert NoPermit(GAS_LIMIT_UPDATER_ROLE);

        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        sealGasLimit = gasLimit_;
        emit SealGasLimitSet(gasLimit_);
    }

    /**
     * @notice updates propose gas limit for `dstChainSlug_`
     * @param gasLimit_ new propose gas limit
     */
    function setProposeGasLimit(
        uint256 nonce_,
        uint256 dstChainSlug_,
        uint256 gasLimit_,
        bytes calldata signature_
    ) external override {
        address gasLimitUpdater = signatureVerifier__.recoverSignerFromDigest(
            keccak256(
                abi.encode(
                    "PROPOSE_GAS_LIMIT_UPDATE",
                    chainSlug,
                    dstChainSlug_,
                    nonce_,
                    gasLimit_
                )
            ),
            signature_
        );

        if (!_hasRole("GAS_LIMIT_UPDATER_ROLE", dstChainSlug_, gasLimitUpdater))
            revert NoPermit("GAS_LIMIT_UPDATER_ROLE");

        uint256 nonce = nextNonce[gasLimitUpdater]++;
        if (nonce_ != nonce) revert InvalidNonce();

        proposeGasLimit[dstChainSlug_] = gasLimit_;
        emit ProposeGasLimitSet(dstChainSlug_, gasLimit_);
    }

    /**
     * @notice updates gasPriceOracle__
     * @param gasPriceOracle_ address of Gas Price Oracle
     */
    function setGasPriceOracle(
        address gasPriceOracle_
    ) external onlyRole(GOVERNANCE_ROLE) {
        gasPriceOracle__ = IGasPriceOracle(gasPriceOracle_);
        emit GasPriceOracleSet(gasPriceOracle_);
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

abstract contract AccessControl is Ownable {
    // role => address => permit
    mapping(bytes32 => mapping(address => bool)) private _permits;

    event RoleGranted(bytes32 indexed role, address indexed grantee);

    event RoleRevoked(bytes32 indexed role, address indexed revokee);

    error NoPermit(bytes32 role);

    constructor(address owner_) Ownable(owner_) {}

    modifier onlyRole(bytes32 role) {
        if (!_permits[role][msg.sender]) revert NoPermit(role);
        _;
    }

    function grantRole(
        bytes32 role_,
        address grantee_
    ) external virtual onlyOwner {
        _grantRole(role_, grantee_);
    }

    function revokeRole(
        bytes32 role_,
        address revokee_
    ) external virtual onlyOwner {
        _revokeRole(role_, revokee_);
    }

    function _grantRole(bytes32 role_, address grantee_) internal {
        _permits[role_][grantee_] = true;
        emit RoleGranted(role_, grantee_);
    }

    function _revokeRole(bytes32 role_, address revokee_) internal {
        _permits[role_][revokee_] = false;
        emit RoleRevoked(role_, revokee_);
    }

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

contract AccessControlExtended is AccessControl {
    modifier onlyRoleWithChainSlug(
        string memory roleName_,
        uint256 chainSlug_
    ) {
        bytes32 role = keccak256(abi.encode(roleName_, chainSlug_));
        if (!_hasRole(role, msg.sender)) revert NoPermit(role);
        _;
    }

    constructor(address owner_) AccessControl(owner_) {}

    function grantRole(
        string memory roleName_,
        uint256 chainSlug_,
        address grantee_
    ) external virtual onlyOwner {
        _grantRole(roleName_, chainSlug_, grantee_);
    }

    function grantBatchRole(
        bytes32[] calldata roleNames_,
        address[] calldata grantees_
    ) external virtual onlyOwner {
        require(roleNames_.length == grantees_.length);
        for (uint256 index = 0; index < roleNames_.length; index++)
            _grantRole(roleNames_[index], grantees_[index]);
    }

    function revokeBatchRole(
        bytes32[] calldata roleNames_,
        address[] calldata grantees_
    ) external virtual onlyOwner {
        require(roleNames_.length == grantees_.length);
        for (uint256 index = 0; index < roleNames_.length; index++)
            _revokeRole(roleNames_[index], grantees_[index]);
    }

    function _grantRole(
        string memory roleName_,
        uint256 chainSlug_,
        address grantee_
    ) internal {
        _grantRole(keccak256(abi.encode(roleName_, chainSlug_)), grantee_);
    }

    function hasRole(
        string memory roleName_,
        uint256 chainSlug_,
        address address_
    ) external view returns (bool) {
        return _hasRole(roleName_, chainSlug_, address_);
    }

    function _hasRole(
        string memory roleName_,
        uint256 chainSlug_,
        address address_
    ) internal view returns (bool) {
        return _hasRole(keccak256(abi.encode(roleName_, chainSlug_)), address_);
    }

    function revokeRole(
        string memory roleName_,
        uint256 chainSlug_,
        address grantee_
    ) external virtual onlyOwner {
        _revokeRole(roleName_, chainSlug_, grantee_);
    }

    function _revokeRole(
        string memory roleName_,
        uint256 chainSlug_,
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
bytes32 constant GAS_LIMIT_UPDATER_ROLE = keccak256("GAS_LIMIT_UPDATER_ROLE");
bytes32 constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IHasher.sol";

contract Hasher is IHasher {
    /// @inheritdoc IHasher
    function packMessage(
        uint256 srcChainSlug_,
        address srcPlug_,
        uint256 dstChainSlug_,
        address dstPlug_,
        bytes32 msgId_,
        uint256 msgGasLimit_,
        uint256 executionFee_,
        bytes calldata payload_
    ) external pure override returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    srcChainSlug_,
                    srcPlug_,
                    dstChainSlug_,
                    dstPlug_,
                    msgId_,
                    msgGasLimit_,
                    executionFee_,
                    payload_
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    error OnlyOwner();
    error OnlyNominee();

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert OnlyOwner();
        _;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function nominee() external view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) revert OnlyOwner();
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) revert OnlyNominee();
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private _locked = 1;

    modifier nonReentrant() virtual {
        require(_locked == 1, "REENTRANCY");

        _locked = 2;

        _;

        _locked = 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/ISignatureVerifier.sol";
import "../libraries/SignatureVerifierLib.sol";

contract SignatureVerifier is ISignatureVerifier {
    /// @inheritdoc ISignatureVerifier
    function recoverSigner(
        uint256 destChainSlug_,
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external pure override returns (address signer) {
        return
            SignatureVerifierLib.recoverSigner(
                destChainSlug_,
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