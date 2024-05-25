// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "contracts/interfaces/ILayerZeroEndpointV2.sol";
import { IOAppCore } from "contracts/oapp/interfaces/IOAppCore.sol";
import { Address } from "contracts/utils/Address.sol";
import { EnumerableSet } from "contracts/utils/structs/EnumerableSet.sol";
import "contracts/token/ERC20/utils/SafeERC20.sol";
import { CoreOwnable } from "contracts/base/dependencies/CoreOwnable.sol";
import { IBridgeRelay } from "contracts/interfaces/IBridgeRelay.sol";
import { Peer, Target } from "contracts/bridge/dependencies/DataStructures.sol";

/**
    @title LayerZero V2 Relay
    @author defidotmoney
    @notice Standardized interface and ACL between LayerZeroEndpointV2 and
            protocol contracts which implement cross-chain functionality
 */
contract LayerZeroRelayV2 is IBridgeRelay, CoreOwnable {
    using Address for address;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct ExecutionOptions {
        uint128 gasLimit;
        uint128 value;
    }

    struct SetExecutionOptions {
        uint32 eid;
        bytes4 selector;
        uint128 gasLimit;
        uint128 value;
    }

    ILayerZeroEndpointV2 public immutable endpoint;
    uint32 public immutable thisId;
    uint32 public immutable primaryId;

    uint32 public nextId;
    uint32 public srcId;
    uint128 public defaultGasLimit;
    bool public roundRobinLock;

    address[] public bridgeTokens;
    EnumerableSet.UintSet private __eids;
    mapping(uint32 eid => bytes32 peer) public peers;
    mapping(bytes4 selector => address target) public targets;

    mapping(uint32 => mapping(bytes4 => ExecutionOptions)) private __executionOptions;

    event NextIdSet(uint32 nextId);
    event PeerSet(uint32 indexed eid, bytes32 peer);
    event TargetSet(bytes4 selector, address target);
    event ExecutionOptionsSet(uint32 indexed eid, bytes4 selector, ExecutionOptions executionOptions);
    event DefaultGasLimitSet(uint128 defaultGasLimit);

    event PacketSent(bytes32 guid);
    event PacketReceived(bytes32 guid);

    constructor(
        address _coreOwner,
        ILayerZeroEndpointV2 _endpoint,
        address[] memory _bridgeTokens,
        uint32 _primaryId,
        uint128 _defaultGasLimit
    ) CoreOwnable(_coreOwner) {
        endpoint = _endpoint;
        thisId = _endpoint.eid();
        primaryId = _primaryId;
        bridgeTokens = _bridgeTokens;

        defaultGasLimit = _defaultGasLimit;
        emit DefaultGasLimitSet(_defaultGasLimit);

        if (_primaryId != thisId) {
            // * If this IS the primary chain, `nextId` is unset as there are no peers.
            // * If this IS NOT the primary chain the relay will be added as the last
            //   chain of the round-robin, so `nextId` is set as the primary chain.
            _setNextId(primaryId);
        }

        // allow bridge to call itself when adding round-robin peer
        targets[this.addNewPeerRoundRobin.selector] = address(this);
    }

    modifier checkEid(uint32 _eid) {
        require(_eid != thisId, "DFM: eid == thisId");
        _;
    }

    modifier noRoundRobinLock() {
        require(!roundRobinLock, "DFM: roundRobinLock active");
        _;
    }

    receive() external payable {}

    /**
        @notice Entry point for sending messages
        @dev * Access is restricted according to the function selector of the message;
               if a contract is set as the target for the bytes4 selector, it is
               also allowed to send messages with the same selector.
             * If `msg.value > 0` the message value is used to pay for gas. Otherwise
               the gas is paid with the value in this contract.
             * Bridge messages related to individual users should require a non-zero
               value and forward it during this call. Bridge messages related to
               protocol upkeep should be funded with the balance in this contract.
               It is the responsibility of the protocol admin to keep this contract
               funded for such cases.
        @param dstId The destination endpoint id.
        @param message The message payload.
        @param refund The address to receive any excess native paid as a fee. If
                      msg.value is 0, this input is ignored and the refund is
                      returned to this contract.
     */
    function send(uint256 dstId, bytes memory message, address refund) external payable {
        _send(uint32(dstId), message, refund);
    }

    /**
        @notice Entry point for sending round-robin messages
        @dev Sends a message to `nextId` using this contract's balance for the
             bridge fee. Round-robin messages are assumed to always be related
             to protocol upkeep.
        @param message The message payload
     */
    function sendToNext(bytes memory message) external noRoundRobinLock {
        _send(nextId, message, address(this));
    }

    /**
        @dev Entry point for receiving messages or packets from the local endpoint.
        @param _origin The origin information containing the source endpoint and sender address.
                        * srcEid: The source chain endpoint ID.
                        * sender: The sender address on the src chain.
                        * nonce: The nonce of the message.
        @param _guid The unique identifier for the received LayerZero message.
        @param _message The payload of the received message.
        @dev _executor The address of the executor for the received message.
        @dev _extraData Additional arbitrary data provided by the corresponding executor.
     */
    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes memory _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) external payable {
        require(msg.sender == address(endpoint));
        require(_getPeerOrRevert(_origin.srcEid) == _origin.sender);

        uint32 cachedId = srcId;
        srcId = _origin.srcEid;
        _getTargetOrRevert(bytes4(_message)).functionCallWithValue(_message, msg.value);
        srcId = cachedId;

        emit PacketReceived(_guid);
    }

    /**
        @notice Set the next remote endpoint id
        @dev Used for round-robin messages to retreive updates on system-wide state
        @param _nextId The next remote endpoint id
     */
    function setNextId(uint32 _nextId) external onlyOwner {
        _setNextId(_nextId);
    }

    /**
        @notice Set the remote peer for a single endpoint
        @param eid The remote endpoint id
        @param peer The address of the remote peer encoded as a bytes32 value
     */
    function setPeer(uint32 eid, bytes32 peer) external onlyOwner {
        _setPeer(eid, peer);
    }

    /**
        @notice Set the remote peer for one or more remote endpoints
     */
    function setPeers(Peer[] calldata _peers) external onlyOwner {
        uint256 length = _peers.length;
        for (uint256 i; i < length; i++) {
            _setPeer(_peers[i].eid, _peers[i].peer);
        }
    }

    /**
        @notice Set the local target of a message based on the function selector
        @dev The target is approved to send outgoing messages with this selector,
             and also receives any incoming messages with this selector
        @param _selector The 4 byte function selector of a message
        @param _target Address of the local target
     */
    function setTarget(bytes4 _selector, address _target) external onlyOwner {
        _setTarget(_selector, _target);
    }

    function setTargets(Target[] calldata _targets) external onlyOwner {
        uint256 length = _targets.length;
        for (uint256 i; i < length; i++) {
            _setTarget(_targets[i].selector, _targets[i].target);
        }
    }

    /**
        @notice Set the options for execution of a message via a remote endpoint
        @dev https://docs.layerzero.network/v2/developers/evm/gas-settings/options
        @param _executionOptions The options for execution
     */
    function setExecutionOptions(SetExecutionOptions[] memory _executionOptions) external onlyOwner {
        for (uint256 i; i < _executionOptions.length; i++) {
            _setExecutionOptions(_executionOptions[i]);
        }
    }

    /**
        @notice Set the default gas limit used for remote execution
        @param _defaultGasLimit The default gas limit to use for remote execution
     */
    function setDefaultGasLimit(uint128 _defaultGasLimit) external onlyOwner {
        defaultGasLimit = _defaultGasLimit;
        emit DefaultGasLimitSet(_defaultGasLimit);
    }

    /**
        @notice Set the delegate of this OApp in the LayerZero endpoint.
        @dev The delegate is authorized to modify configuration values for this OApp.
     */
    function setDelegate(address _delegate) external onlyOwner {
        endpoint.setDelegate(_delegate);
    }

    /**
        @notice Set the round robin messaging lock
        @dev While `true`, calls to `sendToNext` will revert. Used to prevent
             potential conflicts between a peer update and another unrelated
             round-robin message. Should only be activated on the primary chain.
     */
    function setRoundRobinLock(bool isLocked) external onlyOwner {
        roundRobinLock = isLocked;
    }

    /**
        @notice Retrieve an ERC20 or native gas balance from this contract.
        @param token Address of the token to sweep. Set to `address(0)` for
                     the native gas token.
        @param receiver Address to send the token balance to.
     */
    function sweep(address token, address receiver) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = receiver.call{ value: address(this).balance }("");
            require(success, "DFM: Transfer failed");
        } else {
            uint256 amount = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(receiver, amount);
        }
    }

    /**
        @notice Add a new peer for all chains
        @dev Only callable on the primary chain. Initiates a round-robin message
             to add the peer on each chain. The round-robin lock is enabled until
             the `addNewPeerRoundRobin` call returns to the primary chain. Prior
             to adding a new chain:
                * verify that the chain's peers, targets, and execution options are
                  correctly configured
                * verify that the chain's admin ownership is set correctly
        @param _eid Remote endpoint ID for the chain to be added.
        @param _peerRelay Address where this contract is deployed on the chain being added.
        @param _peerBridgeTokens Array of bridge token addresses for the peer. Must match
                                 the tokens in this contract's `bridgeTokens`.
     */
    function addNewPeer(
        uint32 _eid,
        bytes32 _peerRelay,
        bytes32[] memory _peerBridgeTokens
    ) external onlyOwner noRoundRobinLock {
        require(isPrimaryChain(), "Only from primary chain");

        if (nextId == 0) nextId = _eid;
        _addNewPeer(_eid, _peerRelay, _peerBridgeTokens);
        // set the round-robin lock after adding the new peer so that the
        // external call back into `sendToNext` does not revert
        roundRobinLock = true;
    }

    function addNewPeerRoundRobin(
        uint32 _eid,
        bytes32 _peerRelay,
        bytes32[] memory _peerBridgeTokens
    ) external onlyBridgeRelay {
        if (isPrimaryChain()) {
            roundRobinLock = false;
            return;
        }

        _addNewPeer(_eid, _peerRelay, _peerBridgeTokens);
    }

    function _addNewPeer(uint32 _eid, bytes32 _peerRelay, bytes32[] memory _peerBridgeTokens) internal {
        // Do not attempt to add the peer if this IS the peer
        if (_eid != thisId) {
            _setPeer(_eid, _peerRelay);
            uint256 length = bridgeTokens.length;
            require(length == _peerBridgeTokens.length, "DFM: Incorrect peerBridgeTokens");
            for (uint256 i = 0; i < length; i++) {
                IOAppCore(bridgeTokens[i]).setPeer(_eid, _peerBridgeTokens[i]);
            }
            if (nextId == primaryId) {
                // The new peer is added to the end of the round robin. If this
                // chain's `nextId` is `primaryId`, it becomes the new peer.
                _setNextId(_eid);
            }
        }

        // Pass the message onward to the next round-robin peer. Handled via an
        // external call so the target selector check passes.
        this.sendToNext(
            abi.encodeWithSelector(this.addNewPeerRoundRobin.selector, _eid, _peerRelay, _peerBridgeTokens)
        );
    }

    /**
        @notice Query the options for execution of a message via a remote endpoint.
        @param _eid The remote endpoint id.
        @param _selector The function selector of a message.
     */
    function executionOptions(
        uint32 _eid,
        bytes4 _selector
    ) public view checkEid(_eid) returns (ExecutionOptions memory _executionOptions) {
        _executionOptions = __executionOptions[_eid][_selector];
        if (_executionOptions.gasLimit == 0) _executionOptions.gasLimit = defaultGasLimit;
    }

    /**
        @notice Estimate the native gas required to send a message
        @param _dstId The destination endpoint id
        @param _message The message payload
        @return _fee The amount of native fee required
     */
    function fee(uint256 _dstId, bytes memory _message) external view returns (uint256 _fee) {
        _quote(uint32(_dstId), _message);
    }

    /**
        @notice Checks if the path initialization is allowed based on the provided origin
        @dev This indicates to the endpoint that the OApp has enabled messages
             for this particular path to be received
        @param _origin Origin information containing source endpoint and sender address
        @return bool Whether the path has been initialized
     */
    function allowInitializePath(Origin calldata _origin) external view returns (bool) {
        return _getPeerOrRevert(_origin.srcEid) == _origin.sender;
    }

    /**
        @notice The next nonce for a given source endpoint and sender address
        @dev Nonce ordered enforcement is disabled
     */
    function nextNonce(uint32 _srcEid, bytes32 /*_sender*/) external view checkEid(_srcEid) returns (uint256) {
        return 0;
    }

    function peerCount() external view returns (uint256) {
        return __eids.length();
    }

    function getPeers() external view returns (uint32[] memory, bytes32[] memory) {
        uint256 size = __eids.length();

        uint32[] memory _eids = new uint32[](size);
        bytes32[] memory _peers = new bytes32[](size);

        for (uint256 i; i < size; i++) {
            uint32 eid = uint32(__eids.at(i));
            _eids[i] = eid;
            _peers[i] = peers[eid];
        }
        return (_eids, _peers);
    }

    function isPrimaryChain() public view returns (bool) {
        return thisId == primaryId;
    }

    function _setPeer(uint32 _eid, bytes32 _peer) internal checkEid(_eid) {
        if (_peer == bytes32(0)) __eids.remove(_eid);
        else __eids.add(_eid);

        peers[_eid] = _peer;
        emit PeerSet(_eid, _peer);
    }

    function _setTarget(bytes4 _selector, address _target) internal {
        targets[_selector] = _target;
        emit TargetSet(_selector, _target);
    }

    function _setNextId(uint32 _nextId) internal checkEid(_nextId) {
        nextId = _nextId;
        emit NextIdSet(_nextId);
    }

    function _setExecutionOptions(SetExecutionOptions memory _executionOptions) internal {
        uint32 eid = _executionOptions.eid;
        require(eid != thisId);
        bytes4 selector = _executionOptions.selector;
        ExecutionOptions memory opts = ExecutionOptions({
            gasLimit: _executionOptions.gasLimit,
            value: _executionOptions.value
        });
        __executionOptions[eid][selector] = opts;
        emit ExecutionOptionsSet(eid, selector, opts);
    }

    /** @dev Internal implementation of the send function */
    function _send(uint32 _dstEid, bytes memory _message, address _refundAddress) internal {
        require(msg.sender == _getTargetOrRevert(bytes4(_message)), "DFM: Wrong caller for target");
        uint256 amount = msg.value;
        if (amount == 0) {
            _refundAddress = address(this);
            amount = address(this).balance;
        }

        MessagingReceipt memory receipt = endpoint.send{ value: amount }(
            _getMessagingParams(_dstEid, _message),
            _refundAddress
        );

        emit PacketSent(receipt.guid);
    }

    /** @dev Internal implementation of the quote function */
    function _quote(uint32 _dstEid, bytes memory _message) internal view returns (uint256) {
        return endpoint.quote(_getMessagingParams(_dstEid, _message), address(this)).nativeFee;
    }

    /** @dev Generate MessagingParams struct for use in `send` and `quote` */
    function _getMessagingParams(
        uint32 _dstEid,
        bytes memory _message
    ) internal view returns (MessagingParams memory params) {
        bytes32 peer = _getPeerOrRevert(_dstEid);

        bytes memory options;
        ExecutionOptions memory _executionOptions = executionOptions(_dstEid, bytes4(_message));

        if (_executionOptions.value == 0) {
            options = abi.encodePacked(uint128(_executionOptions.gasLimit));
        } else {
            options = abi.encodePacked(uint128(_executionOptions.gasLimit), uint128(_executionOptions.value));
        }

        options = abi.encodePacked(uint16(3), uint8(1), uint16(options.length + 1), uint8(1), options);
        return MessagingParams(_dstEid, peer, _message, options, false);
    }

    /**
        @dev Get the local target of a message based on the function selector,
             or revert if one is not available
        @param _selector The function selector of a message
     */
    function _getTargetOrRevert(bytes4 _selector) internal view returns (address target) {
        target = targets[_selector];
        require(target != address(0), "DFM: target not set");
        return target;
    }

    /**
        @dev Get the remote peer for an endpoint or revert if one is not available
        @param _eid The endpoint id to get the remote peer of
     */
    function _getPeerOrRevert(uint32 _eid) internal view returns (bytes32 peer) {
        peer = peers[_eid];
        require(peer != bytes32(0), "DFM: peer not set");
        return peer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { IMessageLibManager } from "contracts/interfaces/IMessageLibManager.sol";
import { IMessagingComposer } from "contracts/interfaces/IMessagingComposer.sol";
import { IMessagingChannel } from "contracts/interfaces/IMessagingChannel.sol";
import { IMessagingContext } from "contracts/interfaces/IMessagingContext.sol";

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

    event DelegateSet(address sender, address delegate);

    function quote(MessagingParams calldata _params, address _sender) external view returns (MessagingFee memory);

    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory);

    function verify(Origin calldata _origin, address _receiver, bytes32 _payloadHash) external;

    function verifiable(Origin calldata _origin, address _receiver) external view returns (bool);

    function initializable(Origin calldata _origin, address _receiver) external view returns (bool);

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
    event DefaultReceiveLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibraryTimeoutSet(uint32 eid, address oldLib, uint256 expiry);
    event SendLibrarySet(address sender, uint32 eid, address newLib);
    event ReceiveLibrarySet(address receiver, uint32 eid, address newLib);
    event ReceiveLibraryTimeoutSet(address receiver, uint32 eid, address oldLib, uint256 timeout);

    function registerLibrary(address _lib) external;

    function isRegisteredLibrary(address _lib) external view returns (bool);

    function getRegisteredLibraries() external view returns (address[] memory);

    function setDefaultSendLibrary(uint32 _eid, address _newLib) external;

    function defaultSendLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibrary(uint32 _eid, address _newLib, uint256 _gracePeriod) external;

    function defaultReceiveLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibraryTimeout(uint32 _eid, address _lib, uint256 _expiry) external;

    function defaultReceiveLibraryTimeout(uint32 _eid) external view returns (address lib, uint256 expiry);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    function isValidReceiveLibrary(address _receiver, uint32 _eid, address _lib) external view returns (bool);

    /// ------------------- OApp interfaces -------------------
    function setSendLibrary(address _oapp, uint32 _eid, address _newLib) external;

    function getSendLibrary(address _sender, uint32 _eid) external view returns (address lib);

    function isDefaultSendLibrary(address _sender, uint32 _eid) external view returns (bool);

    function setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod) external;

    function getReceiveLibrary(address _receiver, uint32 _eid) external view returns (address lib, bool isDefault);

    function setReceiveLibraryTimeout(address _oapp, uint32 _eid, address _lib, uint256 _expiry) external;

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

    function lazyInboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingContext {
    function isSendingMessage() external view returns (bool);

    function getSendContext() external view returns (uint32 dstEid, address sender);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ILayerZeroEndpointV2 } from "contracts/interfaces/ILayerZeroEndpointV2.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "contracts/token/ERC20/IERC20.sol";
import "contracts/token/ERC20/extensions/IERC20Permit.sol";
import "contracts/utils/Address.sol";

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

pragma solidity ^0.8.0;

import "contracts/interfaces/IProtocolCore.sol";

/**
    @title Core Ownable
    @author Prisma Finance (with edits by defidotmoney)
    @notice Contracts inheriting `CoreOwnable` have the same owner as `ProtocolCore`.
            The ownership cannot be independently modified or renounced.
 */
abstract contract CoreOwnable {
    IProtocolCore public immutable CORE_OWNER;

    constructor(address _core) {
        CORE_OWNER = IProtocolCore(_core);
    }

    modifier onlyOwner() {
        require(msg.sender == address(CORE_OWNER.owner()), "DFM: Only owner");
        _;
    }

    modifier onlyBridgeRelay() {
        require(msg.sender == bridgeRelay(), "DFM: Only bridge relay");
        _;
    }

    function owner() public view returns (address) {
        return address(CORE_OWNER.owner());
    }

    function bridgeRelay() internal view returns (address) {
        return CORE_OWNER.bridgeRelay();
    }

    function feeReceiver() internal view returns (address) {
        return CORE_OWNER.feeReceiver();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProtocolCore {
    function owner() external view returns (address);

    function START_TIME() external view returns (uint256);

    function getAddress(bytes32 identifier) external view returns (address);

    function bridgeRelay() external view returns (address);

    function feeReceiver() external view returns (address);

    function acceptTransferOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @dev Minimal required interface for bridge relay
 */
interface IBridgeRelay {
    /**
        @notice Entry point for sending messages
        @dev Only intended to be called by other contracts within the protocol,
             never directly by external accounts. ACL must be configured or bad
             things will happen.
        @param dstId The destination endpoint id
        @param message The message payload
        @param refund The address to receive any excess native paid as a fee
     */
    function send(uint256 dstId, bytes calldata message, address refund) external payable;

    function sendToNext(bytes memory message) external;

    function setPeer(uint32 eid, bytes32 peer) external;

    function setNextId(uint32 _nextId) external;

    /**
        @notice Estimate the native gas required to send a message
        @param dstId The destination endpoint id
        @param message The message payload
        @return fee The amount of native fee required
     */
    function fee(uint256 dstId, bytes calldata message) external view returns (uint256 fee);

    /**
        @dev Emdpoint ID for this chain
     */
    function thisId() external view returns (uint32);

    /**
        @dev Endpoint ID for the next chain in round-robin messaging
     */
    function nextId() external view returns (uint32);

    function primaryId() external view returns (uint32);

    /**
        @dev During execution of a function call as a result of an inbound
             bridge message, this must return the endpoint ID of the chain
             that sent the message. Otherwise, must return 0.
     */
    function srcId() external view returns (uint32);

    function peerCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Peer {
    uint32 eid;
    bytes32 peer;
}

struct Target {
    bytes4 selector;
    address target;
}