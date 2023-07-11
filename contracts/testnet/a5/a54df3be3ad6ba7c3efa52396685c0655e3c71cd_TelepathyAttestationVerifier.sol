// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {VerifierType, IMessageVerifier} from "src/amb-v2/verifier/interfaces/IMessageVerifier.sol";
import {SourceAMBV2} from "src/amb-v2/SourceAMB.sol";
import {Message} from "src/libraries/Message.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

/// @notice Struct for StateQuery request information wrapped with the attested result.
/// @dev Setting these corresponse to the `CallMsg` fields of StateQuery:
///      https://github.com/ethereum/go-ethereum/blob/fd5d2ef0a6d9eac7542ead4bfbc9b5f0f399eb10/interfaces.go#L134
/// @param chainId The chain ID of the chain where the StateQuery will be made.
/// @param blockNumber The block number of the chain where the StateQuery is made.
///        If blockNumber is 0, then the StateQuery is made at the latest avaliable
///        block.
/// @param fromAddress The address that is used as the 'from' StateQuery argument
///        (influencing msg.sender & tx.origin). If set to address(0) then the
///        call is made from address(0).
/// @param toAddress The address that is used as the 'to' StateQuery argument.
/// @param toCalldata The calldata that is used as the 'data' StateQuery argument.
/// @param result The result from executing the StateQuery.
struct StateQueryResponse {
    uint32 chainId;
    uint64 blockNumber;
    address fromAddress;
    address toAddress;
    bytes toCalldata;
    bytes result;
}

interface IStateQueryGateway {
    /// @notice The response currently being processed by the gateway.
    function currentResponse() external view returns (StateQueryResponse memory);
}

/// @title TelepathyAttestationVerifier
/// @author Succinct Labs
/// @notice Verifies messages using Telepathy StateQuery attestations.
contract TelepathyAttestationVerifier is IMessageVerifier, Initializable {
    using Message for bytes;

    /// @notice The address of the StateQueryGateway contract.
    address public stateQueryGateway;
    /// @notice Source ChainId => TelepathyRouterV2 address.
    mapping(uint32 => address) public telepathyRouters;

    error InvalidSourceChainLength(uint256 length);
    error InvalidChainId(uint32 chainId);
    error TelepathyRouterNotFound(uint32 sourceChainId);
    error TelepathyRouterIncorrect(address telepathyRouter);
    error InvalidResult();
    error InvalidToCalldata(bytes toCalldata);
    error InvalidMessageId(bytes32 messageId);
    error InvalidFuncSelector(bytes4 selector);

    /// @param _stateQueryGateway The address of the StateQueryGateway contract on this chain.
    /// @param _sourceChainIds The chain IDs that this contract will verify messages from.
    /// @param _telepathyRouters The sending TelepathyRouters, one for each sourceChainId.
    function initialize(
        address _stateQueryGateway,
        uint32[] memory _sourceChainIds,
        address[] memory _telepathyRouters
    ) external initializer {
        stateQueryGateway = _stateQueryGateway;
        if (_sourceChainIds.length != _telepathyRouters.length) {
            revert InvalidSourceChainLength(_sourceChainIds.length);
        }
        for (uint32 i = 0; i < _sourceChainIds.length; i++) {
            telepathyRouters[_sourceChainIds[i]] = _telepathyRouters[i];
        }
    }

    function verifierType() external pure override returns (VerifierType) {
        return VerifierType.ATTESTATION_STATE_QUERY;
    }

    /// @notice Verifies messages using Telepathy StateQuery attestations.
    /// @dev The first argument will be the same as the response.result (in the expected case),
    ///      so it is better to just ignore it.
    /// @param _message The message to verify.
    function verify(bytes calldata, bytes calldata _message)
        external
        view
        override
        returns (bool)
    {
        StateQueryResponse memory response = IStateQueryGateway(stateQueryGateway).currentResponse();
        if (response.result.length == 0) {
            revert InvalidResult();
        }

        // Check that the attestation is from the same chain as the message.
        if (response.chainId != _message.sourceChainId()) {
            revert InvalidChainId(response.chainId);
        }

        // Check that the attestation is from the same contract as the telepathyRouter.
        address telepathyRouter = telepathyRouters[response.chainId];
        if (telepathyRouter == address(0)) {
            revert TelepathyRouterNotFound(response.chainId);
        }
        if (response.toAddress != telepathyRouter) {
            revert TelepathyRouterIncorrect(response.toAddress);
        }

        // Check that the attestation toCalldata has the correct function selector and nonce.
        bytes memory expectedToCalldata =
            abi.encodeWithSelector(SourceAMBV2.getMessageId.selector, _message.nonce());
        if (keccak256(response.toCalldata) != keccak256(expectedToCalldata)) {
            revert InvalidToCalldata(response.toCalldata);
        }

        // Check that the claimed messageId matches the attested ethcall result for
        // "getMessageId(uint64)".
        bytes32 attestedMsgId = abi.decode(response.result, (bytes32));
        if (attestedMsgId != _message.getId()) {
            revert InvalidMessageId(attestedMsgId);
        }

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

enum VerifierType {
    NULL,
    CUSTOM,
    ZK_EVENT,
    ZK_STORAGE,
    ATTESTATION_STATE_QUERY
}

/// @title IMessageVerifier
/// @author Succinct Labs
/// @notice Interface for a message verifier.
interface IMessageVerifier {
    /// @notice Returns the type of the verifier.
    /// @dev This signals what type of proofData to include for the message.
    function verifierType() external view returns (VerifierType);

    /// @notice Verifies a message.
    /// @param proofData The packed proof data that the proves the message is valid.
    /// @param message The message contents.
    /// @return isValid Whether the message is valid.
    function verify(bytes calldata proofData, bytes calldata message) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Bytes32} from "src/libraries/Typecast.sol";
import {Message} from "src/libraries/Message.sol";
import {ITelepathyRouterV2} from "src/amb-v2/interfaces/ITelepathy.sol";
import {TelepathyStorageV2} from "src/amb-v2/TelepathyStorage.sol";
import {MerkleProof} from "src/libraries/MerkleProof.sol";

/// @title Source Arbitrary Message Bridge
/// @author Succinct Labs
/// @notice This contract is the entrypoint for sending messages to other chains.
contract SourceAMBV2 is TelepathyStorageV2, ITelepathyRouterV2 {
    using Message for bytes;

    error SendingDisabled();

    /// @notice Modifier to require that sending is enabled.
    modifier isSendingEnabled() {
        if (!sendingEnabled) {
            revert SendingDisabled();
        }
        _;
    }

    /// @notice Sends a message to a destination chain.
    /// @param _destinationChainId The chain id that specifies the destination chain.
    /// @param _destinationAddress The contract address that will be called on the destination
    ///        chain.
    /// @param _data The data passed to the contract on the other chain
    /// @return messageId A unique identifier for a message.
    function send(uint32 _destinationChainId, bytes32 _destinationAddress, bytes calldata _data)
        external
        isSendingEnabled
        returns (bytes32)
    {
        (bytes memory message, bytes32 messageId) =
            _getMessageAndId(_destinationChainId, _destinationAddress, _data);
        messages[nonce] = messageId;
        emit SentMessage(nonce++, messageId, message);
        return messageId;
    }

    /// @notice Sends a message to a destination chain.
    /// @param _destinationChainId The chain id that specifies the destination chain.
    /// @param _destinationAddress The contract address that will be called on the destination
    ///        chain.
    /// @param _data The data passed to the contract on the other chain
    /// @return messageId A unique identifier for a message.
    function send(uint32 _destinationChainId, address _destinationAddress, bytes calldata _data)
        external
        isSendingEnabled
        returns (bytes32)
    {
        (bytes memory message, bytes32 messageId) =
            _getMessageAndId(_destinationChainId, Bytes32.fromAddress(_destinationAddress), _data);
        messages[nonce] = messageId;
        emit SentMessage(nonce++, messageId, message);
        return messageId;
    }

    /// @notice Gets the message and message root from the user-provided arguments to `send`
    /// @param _destinationChainId The chain id that specifies the destination chain.
    /// @param _destinationAddress The contract address that will be called on the destination
    ///        chain.
    /// @param _data The calldata used when calling the contract on the destination chain.
    /// @return message The message encoded as bytes, used in SentMessage event.
    /// @return messageId The hash of message, used as a unique identifier for a message.
    function _getMessageAndId(
        uint32 _destinationChainId,
        bytes32 _destinationAddress,
        bytes calldata _data
    ) internal view returns (bytes memory message, bytes32 messageId) {
        message = Message.encode(
            version,
            nonce,
            uint32(block.chainid),
            msg.sender,
            _destinationChainId,
            _destinationAddress,
            _data
        );
        messageId = keccak256(message);
    }

    /// @notice Gets the messageId for a nonce.
    /// @param _nonce The nonce of the message, assigned when the message is sent.
    /// @return messageId The hash of message contents, used as a unique identifier for a message.
    function getMessageId(uint64 _nonce) external view returns (bytes32) {
        return messages[_nonce];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Message
/// @author Succinct Labs
/// @notice This library is used to encode and decode message data.
library Message {
    /// @dev Since bytes are a dynamic type, they have the first 32 bytes reserved for the
    ///      length of the data, so we start at an offset of 32.
    uint256 private constant VERSION_OFFSET = 32;
    uint256 private constant NONCE_OFFSET = 33;
    uint256 private constant SOURCE_CHAIN_ID_OFFSET = 41;
    uint256 private constant SOURCE_ADDRESS_OFFSET = 45;
    uint256 private constant DESTINATION_CHAIN_ID_OFFSET = 65;
    uint256 private constant DESTINATION_ADDRESS_OFFSET = 69;

    /// @notice Encodes the message into a single bytes array.
    /// @param _version The version of the message.
    /// @param _nonce The nonce of the message.
    /// @param _sourceChainId The source chain ID of the message.
    /// @param _sourceAddress The source address of the message.
    /// @param _destinationChainId The destination chain ID of the message.
    /// @param _destinationAddress The destination address of the message.
    /// @param _data The raw content of the message.
    function encode(
        uint8 _version,
        uint64 _nonce,
        uint32 _sourceChainId,
        address _sourceAddress,
        uint32 _destinationChainId,
        bytes32 _destinationAddress,
        bytes memory _data
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _version,
            _nonce,
            _sourceChainId,
            _sourceAddress,
            _destinationChainId,
            _destinationAddress,
            _data
        );
    }

    function getId(bytes memory _message) internal pure returns (bytes32) {
        return keccak256(_message);
    }

    function version(bytes memory _message) internal pure returns (uint8 version_) {
        assembly {
            // 256 - 248 = 8 bits to extract.
            version_ := shr(248, mload(add(_message, VERSION_OFFSET)))
        }
        return version_;
    }

    function nonce(bytes memory _message) internal pure returns (uint64 nonce_) {
        assembly {
            // 256 - 192 = 64 bits to extract.
            nonce_ := shr(192, mload(add(_message, NONCE_OFFSET)))
        }
        return nonce_;
    }

    function sourceChainId(bytes memory _message) internal pure returns (uint32 sourceChainId_) {
        assembly {
            // 256 - 224 = 32 bits to extract.
            sourceChainId_ := shr(224, mload(add(_message, SOURCE_CHAIN_ID_OFFSET)))
        }
        return sourceChainId_;
    }

    function sourceAddress(bytes memory _message) internal pure returns (address sourceAddress_) {
        assembly {
            // 256 - 96 = 160 bits to extract.
            sourceAddress_ := shr(96, mload(add(_message, SOURCE_ADDRESS_OFFSET)))
        }
        return sourceAddress_;
    }

    function destinationChainId(bytes memory _message)
        internal
        pure
        returns (uint32 destinationChainId_)
    {
        assembly {
            // 256 - 224 = 32 bits to extract.
            destinationChainId_ := shr(224, mload(add(_message, DESTINATION_CHAIN_ID_OFFSET)))
        }
        return destinationChainId_;
    }

    function destinationAddress(bytes memory _message)
        internal
        pure
        returns (address destinationAddress_)
    {
        assembly {
            // Extract the full 256 bits in the slot.
            // Even though the destination address is stored as a bytes32, we want to read it as an address.
            // This is equivalent to address(uint160(destinationAddress_)) if we load destinationAddress_ as a full bytes32.
            destinationAddress_ := mload(add(_message, DESTINATION_ADDRESS_OFFSET))
        }
        return destinationAddress_;
    }

    function data(bytes memory _message) internal pure returns (bytes memory data_) {
        // All bytes after the destination address is the data.
        data_ = BytesLib.slice(
            _message, DESTINATION_ADDRESS_OFFSET, _message.length - DESTINATION_ADDRESS_OFFSET
        );
    }
}

// From here: https://stackoverflow.com/questions/74443594/how-to-slice-bytes-memory-in-solidity
library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length)
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        // Check length is 0. `iszero` return 1 for `true` and 0 for `false`.
        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // Calculate length mod 32 to handle slices that are not a multiple of 32 in size.
                let lengthmod := and(_length, 31)

                // tempBytes will have the following format in memory: <length><data>
                // When copying data we will offset the start forward to avoid allocating additional memory
                // Therefore part of the length area will be written, but this will be overwritten later anyways.
                // In case no offset is require, the start is set to the data region (0x20 from the tempBytes)
                // mc will be used to keep track where to copy the data to.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // Same logic as for mc is applied and additionally the start offset specified for the method is added
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    // increase `mc` and `cc` to read the next word from memory
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // Copy the data from source (cc location) to the slice data (mc location)
                    mstore(mc, mload(cc))
                }

                // Store the length of the slice. This will overwrite any partial data that
                // was copied when having slices that are not a multiple of 32.
                mstore(tempBytes, _length)

                // update free-memory pointer
                // allocating the array padded to 32 bytes like the compiler does now
                // To set the used memory as a multiple of 32, add 31 to the actual memory usage (mc)
                // and remove the modulo 32 (the `and` with `not(31)`)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            // if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                // zero out the 32 bytes slice we are about to return
                // we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                // update free-memory pointer
                // tempBytes uses 32 bytes in memory (even when empty) for the length.
                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.16;

library Address {
    function fromBytes32(bytes32 buffer) internal pure returns (address) {
        return address(uint160(uint256(buffer)));
    }
}

library Bytes32 {
    function fromAddress(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// A magic destinationChainId number to specify for messages that can be executed on any chain.
// Check the doc for current set of chains where the message will be executed. If any are not
// included in this set, it will still be possible to execute via self-relay.
uint32 constant BROADCAST_ALL_CHAINS = uint32(0);

enum MessageStatus {
    NOT_EXECUTED,
    EXECUTION_FAILED, // Deprecated in V2: failed handleTelepathy calls will cause the execute call to revert
    EXECUTION_SUCCEEDED
}

interface ITelepathyRouterV2 {
    event SentMessage(uint64 indexed nonce, bytes32 indexed msgHash, bytes message);

    function send(uint32 destinationChainId, bytes32 destinationAddress, bytes calldata data)
        external
        returns (bytes32);

    function send(uint32 destinationChainId, address destinationAddress, bytes calldata data)
        external
        returns (bytes32);
}

interface ITelepathyReceiverV2 {
    event ExecutedMessage(
        uint32 indexed sourceChainId,
        uint64 indexed nonce,
        bytes32 indexed msgHash,
        bytes message,
        bool success
    );

    function execute(bytes calldata _proof, bytes calldata _message) external;
}

interface ITelepathyHandlerV2 {
    function handleTelepathy(uint32 _sourceChainId, address _sourceAddress, bytes memory _data)
        external
        returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ILightClient} from "src/lightclient/interfaces/ILightClient.sol";
import {MessageStatus} from "src/amb-v2/interfaces/ITelepathy.sol";
import {VerifierType} from "src/amb-v2/verifier/interfaces/IMessageVerifier.sol";

contract TelepathyStorageV2 {
    /*//////////////////////////////////////////////////////////////
                           BROADCASTER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether sending is enabled or not.
    bool public sendingEnabled;

    /// @notice Mapping between a nonce and a message root.
    mapping(uint64 => bytes32) public messages;

    /// @notice Keeps track of the next nonce to be used.
    uint64 public nonce;

    /*//////////////////////////////////////////////////////////////
                           RECEIVER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice All sourceChainIds.
    /// @dev DEPRECATED: This is no longer in use since the move over to external IMessageVerifiers.
    uint32[] public sourceChainIds;

    /// @notice Mapping between source chainId and the corresponding light client.
    /// @dev DEPRECATED: This is no longer in use since the move over to external IMessageVerifiers.
    mapping(uint32 => ILightClient) public lightClients;

    /// @notice Mapping between source chainId and the address of the TelepathyRouterV2 on that chain.
    /// @dev DEPRECATED: This is no longer in use since the move over to external IMessageVerifiers.
    mapping(uint32 => address) public broadcasters;

    /// @notice Mapping between a source chainId and whether it's frozen.
    /// @dev DEPRECATED: This is no longer in use, a global bool 'executingEnabled' is now used.
    mapping(uint32 => bool) public frozen;

    /// @notice Mapping between a message root and its status.
    mapping(bytes32 => MessageStatus) public messageStatus;

    /*//////////////////////////////////////////////////////////////
                           SHARED STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns current contract version.
    uint8 public version;

    /*//////////////////////////////////////////////////////////////
                        RECEIVER STORAGE V2
    //////////////////////////////////////////////////////////////*/

    /// @notice Storage root cache.
    /// @dev DEPRECATED: This is no longer in use since the move over to external IMessageVerifiers.
    mapping(bytes32 => bytes32) public storageRootCache;

    /// @notice Default verifier contracts for each type.
    mapping(VerifierType => address) public defaultVerifiers;

    /// @notice Whether executing messages is enabled or not.
    bool public executingEnabled;

    /// @dev This empty reserved space is put in place to allow future versions to add new variables
    /// without shifting down storage in the inheritance chain.
    /// See: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps
    uint256[38] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library MerkleProof {
    function verifyProof(bytes32 _root, bytes32 _leaf, bytes32[] memory _proof, uint256 _index)
        public
        pure
        returns (bool)
    {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {
            if (_index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, _proof[i]));
            } else {
                computedHash = keccak256(abi.encodePacked(_proof[i], computedHash));
            }
            _index = _index / 2;
        }

        return computedHash == _root;
    }

    function getProof(bytes32[] memory nodes, uint256 index)
        public
        pure
        returns (bytes32[] memory)
    {
        // Build the tree
        uint256 treeHeight = ceilLog2(nodes.length);
        bytes32[][] memory tree = new bytes32[][](treeHeight + 1);
        tree[0] = nodes;

        for (uint256 i = 1; i <= treeHeight; i++) {
            uint256 previousLevelLength = tree[i - 1].length;
            bytes32[] memory currentLevel = new bytes32[](previousLevelLength / 2);

            for (uint256 j = 0; j < previousLevelLength; j += 2) {
                currentLevel[j / 2] =
                    keccak256(abi.encodePacked(tree[i - 1][j], tree[i - 1][j + 1]));
            }

            tree[i] = currentLevel;
        }

        // Generate the proof
        bytes32[] memory proof = new bytes32[](treeHeight);
        for (uint256 i = 0; i < treeHeight; i++) {
            if (index % 2 == 0) {
                // sibling is on the right
                proof[i] = tree[i][index + 1];
            } else {
                // sibling is on the left
                proof[i] = tree[i][index - 1];
            }

            index = index / 2;
        }

        return proof;
    }

    function ceilLog2(uint256 _x) private pure returns (uint256 y) {
        require(_x != 0);
        y = (_x & (_x - 1)) == 0 ? 0 : 1;
        while (_x > 1) {
            _x >>= 1;
            y += 1;
        }
        return y;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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

pragma solidity ^0.8.0;

interface ILightClient {
    function consistent() external view returns (bool);

    function head() external view returns (uint256);

    function headers(uint256 slot) external view returns (bytes32);

    function executionStateRoots(uint256 slot) external view returns (bytes32);

    function timestamps(uint256 slot) external view returns (uint256);
}