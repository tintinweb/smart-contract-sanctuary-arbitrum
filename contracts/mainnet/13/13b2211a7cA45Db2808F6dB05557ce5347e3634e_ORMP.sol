// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./UserConfig.sol";
import "./interfaces/IVerifier.sol";

/// @title Channel
/// @notice A channel is a logical connection over cross-chain network.
/// It used for cross-chain message transfer.
/// - Accepts messages to be dispatched to destination chains,
///   constructs a Merkle tree of the messages.
/// - Dispatches verified messages from source chains.
contract Channel is UserConfig {
    /// @dev msgHash => isDispathed.
    mapping(bytes32 => bool) public dones;

    /// @dev message count.
    uint256 public count;

    /// @dev Self contract address cache.
    address private immutable __self = address(this);

    /// @dev Notifies an observer that the message has been accepted.
    /// @param msgHash Hash of the message.
    /// @param message Accepted message info.
    event MessageAccepted(bytes32 indexed msgHash, Message message);
    /// @dev Notifies an observer that the message has been dispatched.
    /// @param msgHash Hash of the message.
    /// @param dispatchResult The message dispatch result.
    event MessageDispatched(bytes32 indexed msgHash, bool dispatchResult);

    /// @dev Init code.
    constructor(address dao) UserConfig(dao) {}

    /// @dev Fetch local chain id.
    /// @return chainId Local chain id.
    function LOCAL_CHAINID() public view returns (uint256) {
        return block.chainid;
    }

    /// @dev Send message.
    /// @param from User application contract address which send the message.
    /// @param toChainId The Message destination chain id.
    /// @param to User application contract address which receive the message.
    /// @param gasLimit Gas limit for destination user application used.
    /// @param encoded The calldata which encoded by ABI Encoding.
    function _send(address from, uint256 toChainId, address to, uint256 gasLimit, bytes calldata encoded)
        internal
        returns (bytes32)
    {
        // only cross-chain message
        require(toChainId != LOCAL_CHAINID(), "!cross-chain");
        // constuct message object.
        Message memory message = Message({
            channel: __self,
            index: count,
            fromChainId: LOCAL_CHAINID(),
            from: from,
            toChainId: toChainId,
            to: to,
            gasLimit: gasLimit,
            encoded: encoded
        });
        // hash the message.
        bytes32 msgHash = hash(message);

        // emit accepted message event.
        emit MessageAccepted(msgHash, message);

        // increase message count
        count = count + 1;

        // return this message hash.
        return msgHash;
    }

    /// @dev Receive messages.
    /// @notice Only message.to's config relayer could relay this message.
    /// @param message Received message info.
    /// @param proof Message proof of this message.
    function _recv(Message calldata message, bytes calldata proof) internal returns (bytes32) {
        // get message.to user config.
        UC memory uc = getAppConfig(message.to);
        // only the config relayer could relay this message.
        require(uc.relayer == msg.sender, "!auth");
        // verify message by the config oracle.
        require(IVerifier(uc.oracle).verifyMessageProof(message, proof), "!proof");
        // check destination chain id is correct.
        require(LOCAL_CHAINID() == message.toChainId, "!toChainId");
        // hash the message.
        bytes32 msgHash = hash(message);
        // check the message is not dispatched.
        require(dones[msgHash] == false, "done");

        // set the message is dispatched.
        dones[msgHash] = true;

        return msgHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev The block of control information and data for comminicate
/// between user applications. Messages are the exchange medium
/// used by channels to send and receive data through cross-chain networks.
/// A message is sent from a source chain to a destination chain.
/// @param index The leaf index lives in channel's incremental mekle tree.
/// @param fromChainId The message source chain id.
/// @param from User application contract address which send the message.
/// @param toChainId The message destination chain id.
/// @param to User application contract address which receive the message.
/// @param gasLimit Gas limit for destination UA used.
/// @param encoded The calldata which encoded by ABI Encoding.
struct Message {
    address channel;
    uint256 index;
    uint256 fromChainId;
    address from;
    uint256 toChainId;
    address to;
    uint256 gasLimit;
    bytes encoded; /*(abi.encodePacked(SELECTOR, PARAMS))*/
}

/// @dev Hash of the message.
function hash(Message memory message) pure returns (bytes32) {
    return keccak256(abi.encode(message));
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Channel.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IRelayer.sol";
import "./security/ReentrancyGuard.sol";
import "./security/ExcessivelySafeCall.sol";

/// @title ORMP
/// @notice An endpoint is a type of network node for cross-chain communication.
/// It is an interface exposed by a communication channel.
/// @dev An endpoint is associated with an immutable channel and user configuration.
contract ORMP is ReentrancyGuard, Channel {
    using ExcessivelySafeCall for address;

    event MessageAssigned(
        bytes32 indexed msgHash,
        address indexed oracle,
        address indexed relayer,
        uint256 oracleFee,
        uint256 relayerFee,
        bytes params
    );
    event HashImported(address indexed oracle, uint256 chainId, address channel, uint256 msgIndex, bytes32 hash);

    /// oracle => lookupKey => hash
    mapping(address => mapping(bytes32 => bytes32)) public hashLookup;

    constructor(address dao) Channel(dao) {}

    function version() public pure returns (string memory) {
        return "2.1.0";
    }

    /// @dev Send a cross-chain message over the endpoint.
    /// @notice follow https://eips.ethereum.org/EIPS/eip-5750
    /// @param toChainId The Message destination chain id.
    /// @param to User application contract address which receive the message.
    /// @param gasLimit Gas limit for destination user application used.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param refund Return extra fee to refund address.
    /// @param params General extensibility for relayer to custom functionality.
    function send(
        uint256 toChainId,
        address to,
        uint256 gasLimit,
        bytes calldata encoded,
        address refund,
        bytes calldata params
    ) external payable sendNonReentrant returns (bytes32) {
        // user application address.
        address ua = msg.sender;
        // send message by channel, return the hash of the message as id.
        bytes32 msgHash = _send(ua, toChainId, to, gasLimit, encoded);

        // handle fee
        _handleFee(ua, refund, msgHash, toChainId, gasLimit, encoded, params);

        return msgHash;
    }

    /// @dev Import hash by any oracle address.
    /// @notice Hash is an abstract of the proof system, it can be a block hash or a message root hash,
    ///  		specifically provided by oracles.
    /// @param chainId The source chain id.
    /// @param channel The message channel.
    /// @param msgIndex The source chain message index.
    /// @param hash_ The hash to import.
    function importHash(uint256 chainId, address channel, uint256 msgIndex, bytes32 hash_) external {
        bytes32 lookupKey = keccak256(abi.encode(chainId, channel, msgIndex));
        hashLookup[msg.sender][lookupKey] = hash_;
        emit HashImported(msg.sender, chainId, channel, msgIndex, hash_);
    }

    function _handleFee(
        address ua,
        address refund,
        bytes32 msgHash,
        uint256 toChainId,
        uint256 gasLimit,
        bytes calldata encoded,
        bytes calldata params
    ) internal {
        // fetch user application's config.
        UC memory uc = getAppConfig(ua);
        // handle relayer fee
        uint256 relayerFee = _handleRelayer(uc.relayer, toChainId, ua, gasLimit, encoded, params);
        // handle oracle fee
        uint256 oracleFee = _handleOracle(uc.oracle, toChainId, ua);

        emit MessageAssigned(msgHash, uc.oracle, uc.relayer, oracleFee, relayerFee, params);

        // refund
        require(msg.value >= relayerFee + oracleFee, "!fee");
        if (msg.value > relayerFee + oracleFee) {
            uint256 refundFee = msg.value - (relayerFee + oracleFee);
            _sendValue(refund, refundFee);
        }
    }

    /// @notice Get a quote in source native gas, for the amount that send() requires to pay for message delivery.
    /// @param toChainId The Message destination chain id.
    //  @param ua User application contract address which send the message.
    /// @param gasLimit Gas limit for destination user application used.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    function fee(uint256 toChainId, address ua, uint256 gasLimit, bytes calldata encoded, bytes calldata params)
        external
        view
        returns (uint256)
    {
        UC memory uc = getAppConfig(ua);
        uint256 relayerFee = IRelayer(uc.relayer).fee(toChainId, ua, gasLimit, encoded, params);
        uint256 oracleFee = IOracle(uc.oracle).fee(toChainId, ua);
        return relayerFee + oracleFee;
    }

    function _handleRelayer(
        address relayer,
        uint256 toChainId,
        address ua,
        uint256 gasLimit,
        bytes calldata encoded,
        bytes calldata params
    ) internal returns (uint256) {
        uint256 relayerFee = IRelayer(relayer).fee(toChainId, ua, gasLimit, encoded, params);
        _sendValue(relayer, relayerFee);
        return relayerFee;
    }

    function _handleOracle(address oracle, uint256 toChainId, address ua) internal returns (uint256) {
        uint256 oracleFee = IOracle(oracle).fee(toChainId, ua);
        _sendValue(oracle, oracleFee);
        return oracleFee;
    }

    /// @dev Recv verified message from Channel and dispatch to destination user application address.
    /// @notice Only channel could call this function.
    /// @param message Verified receive message info.
    /// @param proof Message proof of this message.
    /// @return dispatchResult Result of the message dispatch.
    function recv(Message calldata message, bytes calldata proof)
        external
        recvNonReentrant
        returns (bool dispatchResult)
    {
        bytes32 msgHash = _recv(message, proof);
        dispatchResult = _dispatch(message, msgHash);
        // emit dispatched message event.
        emit MessageDispatched(msgHash, dispatchResult);
    }

    /// @dev Dispatch the cross chain message.
    function _dispatch(Message memory message, bytes32 msgHash) private returns (bool dispatchResult) {
        // where 5000 is the gas required for the operation between the call to gasleft()
        uint256 gasAvailable = gasleft() - 5000;
        require(gasAvailable - gasAvailable / 64 > message.gasLimit, "!gas");
        // Deliver the message to user application contract address.
        (dispatchResult,) = message.to.excessivelySafeCall(
            message.gasLimit, 0, 0, abi.encodePacked(message.encoded, msgHash, message.fromChainId, message.from)
        );
    }

    /// @dev Replacement for Solidity's `transfer`: sends `amount` wei to
    /// `recipient`, forwarding all available gas and reverting on errors.
    function _sendValue(address recipient, uint256 amount) internal {
        (bool success,) = recipient.call{value: amount}("");
        require(success, "!send");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev User application custom configuration.
/// @param oracle Oracle contract address.
/// @param relayer Relayer contract address.
struct UC {
    address oracle;
    address relayer;
}

/// @title UserConfig
/// @notice User config could select their own relayer and oracle.
/// The default configuration is used by default.
/// @dev Only setter could set default user config.
contract UserConfig {
    /// @dev Setter address.
    address public setter;
    /// @dev Default user config.
    UC public defaultUC;
    /// @dev ua => uc.
    mapping(address => UC) public ucOf;

    /// @dev Notifies an observer that the default user config has updated.
    /// @param oracle Default oracle.
    /// @param relayer Default relayer.
    event DefaultConfigUpdated(address oracle, address relayer);
    /// @dev Notifies an observer that the user application config has updated.
    /// @param ua User application contract address.
    /// @param oracle Oracle which the user application choose.
    /// @param relayer Relayer which the user application choose.
    event AppConfigUpdated(address indexed ua, address oracle, address relayer);
    /// @dev Notifies an observer that the setter is changed.
    /// @param oldSetter Old setter address.
    /// @param newSetter New setter address.
    event SetterChanged(address indexed oldSetter, address indexed newSetter);

    modifier onlySetter() {
        require(msg.sender == setter, "!auth");
        _;
    }

    constructor(address dao) {
        setter = dao;
    }

    /// @dev Change setter.
    /// @notice Only current setter could call.
    /// @param newSetter New setter.
    function changeSetter(address newSetter) external onlySetter {
        address oldSetter = setter;
        setter = newSetter;
        emit SetterChanged(oldSetter, newSetter);
    }

    /// @dev Set default user config for all user application.
    /// @notice Only setter could call.
    /// @param oracle Default oracle.
    /// @param relayer Default relayer.
    function setDefaultConfig(address oracle, address relayer) external onlySetter {
        defaultUC = UC(oracle, relayer);
        emit DefaultConfigUpdated(oracle, relayer);
    }

    /// @notice Set user application config.
    /// @param oracle Oracle which user application.
    /// @param relayer Relayer which user application choose.
    function setAppConfig(address oracle, address relayer) external {
        ucOf[msg.sender] = UC(oracle, relayer);
        emit AppConfigUpdated(msg.sender, oracle, relayer);
    }

    /// @dev Fetch user application config.
    /// @notice If user application has not configured, then the default user config is used.
    /// @param ua User application contract address.
    /// @return user application config.
    function getAppConfig(address ua) public view returns (UC memory) {
        UC memory c = ucOf[ua];

        if (c.relayer == address(0x0)) {
            c.relayer = defaultUC.relayer;
        }

        if (c.oracle == address(0x0)) {
            c.oracle = defaultUC.oracle;
        }

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IVerifier.sol";

interface IOracle is IVerifier {
    /// @notice Fetch oracle price to relay message root to the destination chain.
    /// @param toChainId The destination chain id.
    /// @param ua The user application which send the message.
    /// @return Oracle price in source native gas.
    function fee(uint256 toChainId, address ua) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRelayer {
    /// @notice Fetch relayer price to relay message to the destination chain.
    /// @param toChainId The destination chain id.
    /// @param ua The user application which send the message.
    /// @param gasLimit Gas limit for destination user application used.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    /// @return Relayer price in source native gas.
    function fee(uint256 toChainId, address ua, uint256 gasLimit, bytes calldata encoded, bytes calldata params)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Common.sol";

interface IVerifier {
    /// @notice Verify message proof
    /// @dev Message proof provided by relayer. Oracle should provide message root of
    ///      source chain, and verify the merkle proof of the message hash.
    /// @param message The message info.
    /// @param proof Proof of the message
    /// @return Result of the message verify.
    function verifyMessageProof(Message calldata message, bytes calldata proof) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

// Inspired: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/util/ExcessivelySafeCall.sol

library ExcessivelySafeCall {
    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _value Value in wei to send to the account
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(address _target, uint256 _gas, uint256 _value, uint16 _maxCopy, bytes memory _calldata)
        internal
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly ("memory-safe") {
            _success :=
                call(
                    _gas, // gas
                    _target, // recipient
                    _value, // ether value
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        view
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly ("memory-safe") {
            _success :=
                staticcall(
                    _gas, // gas
                    _target, // recipient
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract ReentrancyGuard {
    // send and receive nonreentrant lock
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _send_state = 1;
    uint256 private _receive_state = 1;

    modifier sendNonReentrant() {
        require(_send_state == _NOT_ENTERED, "!send-reentrancy");
        _send_state = _ENTERED;
        _;
        _send_state = _NOT_ENTERED;
    }

    modifier recvNonReentrant() {
        require(_receive_state == _NOT_ENTERED, "!recv-reentrancy");
        _receive_state = _ENTERED;
        _;
        _receive_state = _NOT_ENTERED;
    }
}