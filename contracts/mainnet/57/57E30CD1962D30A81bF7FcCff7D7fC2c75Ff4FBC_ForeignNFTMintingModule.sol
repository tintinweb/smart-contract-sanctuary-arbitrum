// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {IMailbox} from "../interfaces/IMailbox.sol";
import {IPostDispatchHook} from "../interfaces/hooks/IPostDispatchHook.sol";
import {IInterchainSecurityModule} from "../interfaces/IInterchainSecurityModule.sol";
import {Message} from "../libs/Message.sol";

// ============ External Imports ============
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract MailboxClient is OwnableUpgradeable {
    using Message for bytes;

    IMailbox public immutable mailbox;

    uint32 public immutable localDomain;

    IPostDispatchHook public hook;

    IInterchainSecurityModule public interchainSecurityModule;

    uint256[48] private __GAP; // gap for upgrade safety

    // ============ Modifiers ============
    modifier onlyContract(address _contract) {
        require(
            Address.isContract(_contract),
            "MailboxClient: invalid mailbox"
        );
        _;
    }

    modifier onlyContractOrNull(address _contract) {
        require(
            Address.isContract(_contract) || _contract == address(0),
            "MailboxClient: invalid contract setting"
        );
        _;
    }

    /**
     * @notice Only accept messages from an Hyperlane Mailbox contract
     */
    modifier onlyMailbox() {
        require(
            msg.sender == address(mailbox),
            "MailboxClient: sender not mailbox"
        );
        _;
    }

    constructor(address _mailbox) onlyContract(_mailbox) {
        mailbox = IMailbox(_mailbox);
        localDomain = mailbox.localDomain();
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Sets the address of the application's custom hook.
     * @param _hook The address of the hook contract.
     */
    function setHook(address _hook) public onlyContractOrNull(_hook) onlyOwner {
        hook = IPostDispatchHook(_hook);
    }

    /**
     * @notice Sets the address of the application's custom interchain security module.
     * @param _module The address of the interchain security module contract.
     */
    function setInterchainSecurityModule(
        address _module
    ) public onlyContractOrNull(_module) onlyOwner {
        interchainSecurityModule = IInterchainSecurityModule(_module);
    }

    // ======== Initializer =========
    function _MailboxClient_initialize(
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) internal onlyInitializing {
        __Ownable_init();
        setHook(_hook);
        setInterchainSecurityModule(_interchainSecurityModule);
        _transferOwnership(_owner);
    }

    function _isLatestDispatched(bytes32 id) internal view returns (bool) {
        return mailbox.latestDispatchedId() == id;
    }

    function _metadata(
        uint32 /*_destinationDomain*/
    ) internal view virtual returns (bytes memory) {
        return "";
    }

    function _dispatch(
        uint32 _destinationDomain,
        bytes32 _recipient,
        bytes memory _messageBody
    ) internal virtual returns (bytes32) {
        return
            _dispatch(_destinationDomain, _recipient, msg.value, _messageBody);
    }

    function _dispatch(
        uint32 _destinationDomain,
        bytes32 _recipient,
        uint256 _value,
        bytes memory _messageBody
    ) internal virtual returns (bytes32) {
        return
            mailbox.dispatch{value: _value}(
                _destinationDomain,
                _recipient,
                _messageBody,
                _metadata(_destinationDomain),
                hook
            );
    }

    function _quoteDispatch(
        uint32 _destinationDomain,
        bytes32 _recipient,
        bytes memory _messageBody
    ) internal view virtual returns (uint256) {
        return
            mailbox.quoteDispatch(
                _destinationDomain,
                _recipient,
                _messageBody,
                _metadata(_destinationDomain),
                hook
            );
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {IMessageRecipient} from "../interfaces/IMessageRecipient.sol";
import {IPostDispatchHook} from "../interfaces/hooks/IPostDispatchHook.sol";
import {IInterchainSecurityModule} from "../interfaces/IInterchainSecurityModule.sol";
import {MailboxClient} from "./MailboxClient.sol";
import {EnumerableMapExtended} from "../libs/EnumerableMapExtended.sol";

// ============ External Imports ============
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Router is MailboxClient, IMessageRecipient {
    using EnumerableMapExtended for EnumerableMapExtended.UintToBytes32Map;
    using Strings for uint32;

    // ============ Mutable Storage ============
    EnumerableMapExtended.UintToBytes32Map internal _routers;

    uint256[48] private __GAP; // gap for upgrade safety

    constructor(address _mailbox) MailboxClient(_mailbox) {}

    // ============ External functions ============
    function domains() external view returns (uint32[] memory) {
        return _routers.uint32Keys();
    }

    /**
     * @notice Returns the address of the Router contract for the given domain
     * @param _domain The remote domain ID.
     * @dev Returns 0 address if no router is enrolled for the given domain
     * @return router The address of the Router contract for the given domain
     */
    function routers(uint32 _domain) public view virtual returns (bytes32) {
        (, bytes32 _router) = _routers.tryGet(_domain);
        return _router;
    }

    /**
     * @notice Unregister the domain
     * @param _domain The domain of the remote Application Router
     */
    function unenrollRemoteRouter(uint32 _domain) external virtual onlyOwner {
        _unenrollRemoteRouter(_domain);
    }

    /**
     * @notice Register the address of a Router contract for the same Application on a remote chain
     * @param _domain The domain of the remote Application Router
     * @param _router The address of the remote Application Router
     */
    function enrollRemoteRouter(
        uint32 _domain,
        bytes32 _router
    ) external virtual onlyOwner {
        _enrollRemoteRouter(_domain, _router);
    }

    /**
     * @notice Batch version of `enrollRemoteRouter`
     * @param _domains The domains of the remote Application Routers
     * @param _addresses The addresses of the remote Application Routers
     */
    function enrollRemoteRouters(
        uint32[] calldata _domains,
        bytes32[] calldata _addresses
    ) external virtual onlyOwner {
        require(_domains.length == _addresses.length, "!length");
        uint256 length = _domains.length;
        for (uint256 i = 0; i < length; i += 1) {
            _enrollRemoteRouter(_domains[i], _addresses[i]);
        }
    }

    /**
     * @notice Batch version of `unenrollRemoteRouter`
     * @param _domains The domains of the remote Application Routers
     */
    function unenrollRemoteRouters(
        uint32[] calldata _domains
    ) external virtual onlyOwner {
        uint256 length = _domains.length;
        for (uint256 i = 0; i < length; i += 1) {
            _unenrollRemoteRouter(_domains[i]);
        }
    }

       /**
     * @notice Handles an incoming message
     * @param _origin The origin domain
     * @param _sender The sender address
     * @param _message The message
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable virtual override onlyMailbox {
        bytes32 _router = _mustHaveRemoteRouter(_origin);
        require(_router == _sender, "Enrolled router does not match sender");
        _handle(_origin, _sender, _message);
    }
    
    // ============ Virtual functions ============
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) internal virtual;

    // ============ Internal functions ============

    /**
     * @notice Set the router for a given domain
     * @param _domain The domain
     * @param _address The new router
     */
    function _enrollRemoteRouter(
        uint32 _domain,
        bytes32 _address
    ) internal virtual {
        _routers.set(_domain, _address);
    }

    /**
     * @notice Remove the router for a given domain
     * @param _domain The domain
     */
    function _unenrollRemoteRouter(uint32 _domain) internal virtual {
        require(_routers.remove(_domain), _domainNotFoundError(_domain));
    }

    /**
     * @notice Return true if the given domain / router is the address of a remote Application Router
     * @param _domain The domain of the potential remote Application Router
     * @param _address The address of the potential remote Application Router
     */
    function _isRemoteRouter(
        uint32 _domain,
        bytes32 _address
    ) internal view returns (bool) {
        return routers(_domain) == _address;
    }

    /**
     * @notice Assert that the given domain has a Application Router registered and return its address
     * @param _domain The domain of the chain for which to get the Application Router
     * @return _router The address of the remote Application Router on _domain
     */
    function _mustHaveRemoteRouter(
        uint32 _domain
    ) internal view returns (bytes32) {
        (bool contained, bytes32 _router) = _routers.tryGet(_domain);
        require(contained, _domainNotFoundError(_domain));
        return _router;
    }

    function _domainNotFoundError(
        uint32 _domain
    ) internal pure returns (string memory) {
        return
            string.concat(
                "No router enrolled for domain: ",
                _domain.toString()
            );
    }

    function _dispatch(
        uint32 _destinationDomain,
        bytes memory _messageBody
    ) internal virtual returns (bytes32) {
        return _dispatch(_destinationDomain, msg.value, _messageBody);
    }

    function _dispatch(
        uint32 _destinationDomain,
        uint256 _value,
        bytes memory _messageBody
    ) internal virtual returns (bytes32) {
        bytes32 _router = _mustHaveRemoteRouter(_destinationDomain);
        return
            super._dispatch(_destinationDomain, _router, _value, _messageBody);
    }

    function _quoteDispatch(
        uint32 _destinationDomain,
        bytes memory _messageBody
    ) internal view virtual returns (uint256) {
        bytes32 _router = _mustHaveRemoteRouter(_destinationDomain);
        return super._quoteDispatch(_destinationDomain, _router, _messageBody);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

/**
 * Format of metadata:
 *
 * [0:2] variant
 * [2:34] msg.value
 * [34:66] Gas limit for message (IGP)
 * [66:86] Refund address for message (IGP)
 * [86:] Custom metadata
 */
library StandardHookMetadata {
    struct Metadata {
        uint16 variant;
        uint256 msgValue;
        uint256 gasLimit;
        address refundAddress;
    }

    uint8 private constant VARIANT_OFFSET = 0;
    uint8 private constant MSG_VALUE_OFFSET = 2;
    uint8 private constant GAS_LIMIT_OFFSET = 34;
    uint8 private constant REFUND_ADDRESS_OFFSET = 66;
    uint256 private constant MIN_METADATA_LENGTH = 86;

    uint16 public constant VARIANT = 1;

    /**
     * @notice Returns the variant of the metadata.
     * @param _metadata ABI encoded standard hook metadata.
     * @return variant of the metadata as uint8.
     */
    function variant(bytes calldata _metadata) internal pure returns (uint16) {
        if (_metadata.length < VARIANT_OFFSET + 2) return 0;
        return uint16(bytes2(_metadata[VARIANT_OFFSET:VARIANT_OFFSET + 2]));
    }

    /**
     * @notice Returns the specified value for the message.
     * @param _metadata ABI encoded standard hook metadata.
     * @param _default Default fallback value.
     * @return Value for the message as uint256.
     */
    function msgValue(
        bytes calldata _metadata,
        uint256 _default
    ) internal pure returns (uint256) {
        if (_metadata.length < MSG_VALUE_OFFSET + 32) return _default;
        return
            uint256(bytes32(_metadata[MSG_VALUE_OFFSET:MSG_VALUE_OFFSET + 32]));
    }

    /**
     * @notice Returns the specified gas limit for the message.
     * @param _metadata ABI encoded standard hook metadata.
     * @param _default Default fallback gas limit.
     * @return Gas limit for the message as uint256.
     */
    function gasLimit(
        bytes calldata _metadata,
        uint256 _default
    ) internal pure returns (uint256) {
        if (_metadata.length < GAS_LIMIT_OFFSET + 32) return _default;
        return
            uint256(bytes32(_metadata[GAS_LIMIT_OFFSET:GAS_LIMIT_OFFSET + 32]));
    }

    /**
     * @notice Returns the specified refund address for the message.
     * @param _metadata ABI encoded standard hook metadata.
     * @param _default Default fallback refund address.
     * @return Refund address for the message as address.
     */
    function refundAddress(
        bytes calldata _metadata,
        address _default
    ) internal pure returns (address) {
        if (_metadata.length < REFUND_ADDRESS_OFFSET + 20) return _default;
        return
            address(
                bytes20(
                    _metadata[REFUND_ADDRESS_OFFSET:REFUND_ADDRESS_OFFSET + 20]
                )
            );
    }

    /**
     * @notice Returns any custom metadata.
     * @param _metadata ABI encoded standard hook metadata.
     * @return Custom metadata.
     */
    function getCustomMetadata(
        bytes calldata _metadata
    ) internal pure returns (bytes calldata) {
        if (_metadata.length < MIN_METADATA_LENGTH) return _metadata[0:0];
        return _metadata[MIN_METADATA_LENGTH:];
    }

    /**
     * @notice Formats the specified gas limit and refund address into standard hook metadata.
     * @param _msgValue msg.value for the message.
     * @param _gasLimit Gas limit for the message.
     * @param _refundAddress Refund address for the message.
     * @param _customMetadata Additional metadata to include in the standard hook metadata.
     * @return ABI encoded standard hook metadata.
     */
    function formatMetadata(
        uint256 _msgValue,
        uint256 _gasLimit,
        address _refundAddress,
        bytes memory _customMetadata
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                VARIANT,
                _msgValue,
                _gasLimit,
                _refundAddress,
                _customMetadata
            );
    }

    /**
     * @notice Formats the specified gas limit and refund address into standard hook metadata.
     * @param _msgValue msg.value for the message.
     * @return ABI encoded standard hook metadata.
     */
    function overrideMsgValue(
        uint256 _msgValue
    ) internal view returns (bytes memory) {
        return formatMetadata(_msgValue, uint256(0), msg.sender, "");
    }

    /**
     * @notice Formats the specified gas limit and refund address into standard hook metadata.
     * @param _gasLimit Gas limit for the message.
     * @return ABI encoded standard hook metadata.
     */
    function overrideGasLimit(
        uint256 _gasLimit
    ) internal view returns (bytes memory) {
        return formatMetadata(uint256(0), _gasLimit, msg.sender, "");
    }

    /**
     * @notice Formats the specified refund address into standard hook metadata.
     * @param _refundAddress Refund address for the message.
     * @return ABI encoded standard hook metadata.
     */
    function overrideRefundAddress(
        address _refundAddress
    ) internal pure returns (bytes memory) {
        return formatMetadata(uint256(0), uint256(0), _refundAddress, "");
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

interface IPostDispatchHook {
    enum Types {
        UNUSED,
        ROUTING,
        AGGREGATION,
        MERKLE_TREE,
        INTERCHAIN_GAS_PAYMASTER,
        FALLBACK_ROUTING,
        ID_AUTH_ISM,
        PAUSABLE,
        PROTOCOL_FEE
    }

    /**
     * @notice Returns an enum that represents the type of hook
     */
    function hookType() external view returns (uint8);

    /**
     * @notice Returns whether the hook supports metadata
     * @param metadata metadata
     * @return Whether the hook supports metadata
     */
    function supportsMetadata(
        bytes calldata metadata
    ) external view returns (bool);

    /**
     * @notice Post action after a message is dispatched via the Mailbox
     * @param metadata The metadata required for the hook
     * @param message The message passed from the Mailbox.dispatch() call
     */
    function postDispatch(
        bytes calldata metadata,
        bytes calldata message
    ) external payable;

    /**
     * @notice Compute the payment required by the postDispatch call
     * @param metadata The metadata required for the hook
     * @param message The message passed from the Mailbox.dispatch() call
     * @return Quoted payment for the postDispatch call
     */
    function quoteDispatch(
        bytes calldata metadata,
        bytes calldata message
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IInterchainSecurityModule {
    enum Types {
        UNUSED,
        ROUTING,
        AGGREGATION,
        LEGACY_MULTISIG,
        MERKLE_ROOT_MULTISIG,
        MESSAGE_ID_MULTISIG,
        NULL, // used with relayer carrying no metadata
        CCIP_READ
    }

    /**
     * @notice Returns an enum that represents the type of security model
     * encoded by this ISM.
     * @dev Relayers infer how to fetch and format metadata.
     */
    function moduleType() external view returns (uint8);

    /**
     * @notice Defines a security model responsible for verifying interchain
     * messages based on the provided metadata.
     * @param _metadata Off-chain metadata provided by a relayer, specific to
     * the security model encoded by the module (e.g. validator signatures)
     * @param _message Hyperlane encoded interchain message
     * @return True if the message was verified
     */
    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external returns (bool);
}

interface ISpecifiesInterchainSecurityModule {
    function interchainSecurityModule()
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "./IInterchainSecurityModule.sol";
import {IPostDispatchHook} from "./hooks/IPostDispatchHook.sol";

interface IMailbox {
    // ============ Events ============
    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param sender The address that dispatched the message
     * @param destination The destination domain of the message
     * @param recipient The message recipient address on `destination`
     * @param message Raw bytes of message
     */
    event Dispatch(
        address indexed sender,
        uint32 indexed destination,
        bytes32 indexed recipient,
        bytes message
    );

    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param messageId The unique message identifier
     */
    event DispatchId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is processed
     * @param messageId The unique message identifier
     */
    event ProcessId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is delivered
     * @param origin The origin domain of the message
     * @param sender The message sender address on `origin`
     * @param recipient The address that handled the message
     */
    event Process(
        uint32 indexed origin,
        bytes32 indexed sender,
        address indexed recipient
    );

    function localDomain() external view returns (uint32);

    function delivered(bytes32 messageId) external view returns (bool);

    function defaultIsm() external view returns (IInterchainSecurityModule);

    function defaultHook() external view returns (IPostDispatchHook);

    function requiredHook() external view returns (IPostDispatchHook);

    function latestDispatchedId() external view returns (bytes32);

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external payable returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external view returns (uint256 fee);

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata body,
        bytes calldata defaultHookMetadata
    ) external payable returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata defaultHookMetadata
    ) external view returns (uint256 fee);

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata body,
        bytes calldata customHookMetadata,
        IPostDispatchHook customHook
    ) external payable returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata customHookMetadata,
        IPostDispatchHook customHook
    ) external view returns (uint256 fee);

    function process(
        bytes calldata metadata,
        bytes calldata message
    ) external payable;

    function recipientIsm(
        address recipient
    ) external view returns (IInterchainSecurityModule module);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ External Imports ============
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// extends EnumerableMap with uint256 => bytes32 type
// modelled after https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/utils/structs/EnumerableMap.sol
library EnumerableMapExtended {
    using EnumerableMap for EnumerableMap.Bytes32ToBytes32Map;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct UintToBytes32Map {
        EnumerableMap.Bytes32ToBytes32Map _inner;
    }

    // ============ Library Functions ============
    function keys(
        UintToBytes32Map storage map
    ) internal view returns (uint256[] memory _keys) {
        uint256 _length = map._inner.length();
        _keys = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _keys[i] = uint256(map._inner._keys.at(i));
        }
    }

    function uint32Keys(
        UintToBytes32Map storage map
    ) internal view returns (uint32[] memory _keys) {
        uint256[] memory uint256keys = keys(map);
        _keys = new uint32[](uint256keys.length);
        for (uint256 i = 0; i < uint256keys.length; i++) {
            _keys[i] = uint32(uint256keys[i]);
        }
    }

    function set(
        UintToBytes32Map storage map,
        uint256 key,
        bytes32 value
    ) internal {
        map._inner.set(bytes32(key), value);
    }

    function get(
        UintToBytes32Map storage map,
        uint256 key
    ) internal view returns (bytes32) {
        return map._inner.get(bytes32(key));
    }

    function tryGet(
        UintToBytes32Map storage map,
        uint256 key
    ) internal view returns (bool, bytes32) {
        return map._inner.tryGet(bytes32(key));
    }

    function remove(
        UintToBytes32Map storage map,
        uint256 key
    ) internal returns (bool) {
        return map._inner.remove(bytes32(key));
    }

    function contains(
        UintToBytes32Map storage map,
        uint256 key
    ) internal view returns (bool) {
        return map._inner.contains(bytes32(key));
    }

    function length(
        UintToBytes32Map storage map
    ) internal view returns (uint256) {
        return map._inner.length();
    }

    function at(
        UintToBytes32Map storage map,
        uint256 index
    ) internal view returns (uint256, bytes32) {
        (bytes32 key, bytes32 value) = map._inner.at(index);
        return (uint256(key), value);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {TypeCasts} from "./TypeCasts.sol";

/**
 * @title Hyperlane Message Library
 * @notice Library for formatted messages used by Mailbox
 **/
library Message {
    using TypeCasts for bytes32;

    uint256 private constant VERSION_OFFSET = 0;
    uint256 private constant NONCE_OFFSET = 1;
    uint256 private constant ORIGIN_OFFSET = 5;
    uint256 private constant SENDER_OFFSET = 9;
    uint256 private constant DESTINATION_OFFSET = 41;
    uint256 private constant RECIPIENT_OFFSET = 45;
    uint256 private constant BODY_OFFSET = 77;

    /**
     * @notice Returns formatted (packed) Hyperlane message with provided fields
     * @dev This function should only be used in memory message construction.
     * @param _version The version of the origin and destination Mailboxes
     * @param _nonce A nonce to uniquely identify the message on its origin chain
     * @param _originDomain Domain of origin chain
     * @param _sender Address of sender as bytes32
     * @param _destinationDomain Domain of destination chain
     * @param _recipient Address of recipient on destination chain as bytes32
     * @param _messageBody Raw bytes of message body
     * @return Formatted message
     */
    function formatMessage(
        uint8 _version,
        uint32 _nonce,
        uint32 _originDomain,
        bytes32 _sender,
        uint32 _destinationDomain,
        bytes32 _recipient,
        bytes calldata _messageBody
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                _version,
                _nonce,
                _originDomain,
                _sender,
                _destinationDomain,
                _recipient,
                _messageBody
            );
    }

    /**
     * @notice Returns the message ID.
     * @param _message ABI encoded Hyperlane message.
     * @return ID of `_message`
     */
    function id(bytes memory _message) internal pure returns (bytes32) {
        return keccak256(_message);
    }

    /**
     * @notice Returns the message version.
     * @param _message ABI encoded Hyperlane message.
     * @return Version of `_message`
     */
    function version(bytes calldata _message) internal pure returns (uint8) {
        return uint8(bytes1(_message[VERSION_OFFSET:NONCE_OFFSET]));
    }

    /**
     * @notice Returns the message nonce.
     * @param _message ABI encoded Hyperlane message.
     * @return Nonce of `_message`
     */
    function nonce(bytes calldata _message) internal pure returns (uint32) {
        return uint32(bytes4(_message[NONCE_OFFSET:ORIGIN_OFFSET]));
    }

    /**
     * @notice Returns the message origin domain.
     * @param _message ABI encoded Hyperlane message.
     * @return Origin domain of `_message`
     */
    function origin(bytes calldata _message) internal pure returns (uint32) {
        return uint32(bytes4(_message[ORIGIN_OFFSET:SENDER_OFFSET]));
    }

    /**
     * @notice Returns the message sender as bytes32.
     * @param _message ABI encoded Hyperlane message.
     * @return Sender of `_message` as bytes32
     */
    function sender(bytes calldata _message) internal pure returns (bytes32) {
        return bytes32(_message[SENDER_OFFSET:DESTINATION_OFFSET]);
    }

    /**
     * @notice Returns the message sender as address.
     * @param _message ABI encoded Hyperlane message.
     * @return Sender of `_message` as address
     */
    function senderAddress(
        bytes calldata _message
    ) internal pure returns (address) {
        return sender(_message).bytes32ToAddress();
    }

    /**
     * @notice Returns the message destination domain.
     * @param _message ABI encoded Hyperlane message.
     * @return Destination domain of `_message`
     */
    function destination(
        bytes calldata _message
    ) internal pure returns (uint32) {
        return uint32(bytes4(_message[DESTINATION_OFFSET:RECIPIENT_OFFSET]));
    }

    /**
     * @notice Returns the message recipient as bytes32.
     * @param _message ABI encoded Hyperlane message.
     * @return Recipient of `_message` as bytes32
     */
    function recipient(
        bytes calldata _message
    ) internal pure returns (bytes32) {
        return bytes32(_message[RECIPIENT_OFFSET:BODY_OFFSET]);
    }

    /**
     * @notice Returns the message recipient as address.
     * @param _message ABI encoded Hyperlane message.
     * @return Recipient of `_message` as address
     */
    function recipientAddress(
        bytes calldata _message
    ) internal pure returns (address) {
        return recipient(_message).bytes32ToAddress();
    }

    /**
     * @notice Returns the message body.
     * @param _message ABI encoded Hyperlane message.
     * @return Body of `_message`
     */
    function body(
        bytes calldata _message
    ) internal pure returns (bytes calldata) {
        return bytes(_message[BODY_OFFSET:]);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library TypeCasts {
    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev Interface for {TransparentUpgradeableProxy}. In order to implement transparency, {TransparentUpgradeableProxy}
 * does not implement this interface directly, and some of its functions are implemented by an internal dispatch
 * mechanism. The compiler is unaware that these functions are implemented by {TransparentUpgradeableProxy} and will not
 * include them in the ABI so this interface must be used to interact with it.
 */
interface ITransparentUpgradeableProxy is IERC1967 {
    function admin() external view returns (address);

    function implementation() external view returns (address);

    function changeAdmin(address) external;

    function upgradeTo(address) external;

    function upgradeToAndCall(address, bytes memory) external payable;
}

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 *
 * NOTE: The real interface of this proxy is that defined in `ITransparentUpgradeableProxy`. This contract does not
 * inherit from that interface, and instead the admin functions are implicitly implemented using a custom dispatch
 * mechanism in `_fallback`. Consequently, the compiler will not produce an ABI for this contract. This is necessary to
 * fully implement transparency without decoding reverts caused by selector clashes between the proxy and the
 * implementation.
 *
 * WARNING: It is not recommended to extend this contract to add additional external functions. If you do so, the compiler
 * will not check that there are no selector conflicts, due to the note above. A selector clash between any new function
 * and the functions declared in {ITransparentUpgradeableProxy} will be resolved in favor of the new one. This could
 * render the admin operations inaccessible, which could prevent upgradeability. Transparency may also be compromised.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     *
     * CAUTION: This modifier is deprecated, as it could cause issues if the modified function has arguments, and the
     * implementation provides a function with the same selector.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior
     */
    function _fallback() internal virtual override {
        if (msg.sender == _getAdmin()) {
            bytes memory ret;
            bytes4 selector = msg.sig;
            if (selector == ITransparentUpgradeableProxy.upgradeTo.selector) {
                ret = _dispatchUpgradeTo();
            } else if (selector == ITransparentUpgradeableProxy.upgradeToAndCall.selector) {
                ret = _dispatchUpgradeToAndCall();
            } else if (selector == ITransparentUpgradeableProxy.changeAdmin.selector) {
                ret = _dispatchChangeAdmin();
            } else if (selector == ITransparentUpgradeableProxy.admin.selector) {
                ret = _dispatchAdmin();
            } else if (selector == ITransparentUpgradeableProxy.implementation.selector) {
                ret = _dispatchImplementation();
            } else {
                revert("TransparentUpgradeableProxy: admin cannot fallback to proxy target");
            }
            assembly {
                return(add(ret, 0x20), mload(ret))
            }
        } else {
            super._fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function _dispatchAdmin() private returns (bytes memory) {
        _requireZeroValue();

        address admin = _getAdmin();
        return abi.encode(admin);
    }

    /**
     * @dev Returns the current implementation.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function _dispatchImplementation() private returns (bytes memory) {
        _requireZeroValue();

        address implementation = _implementation();
        return abi.encode(implementation);
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _dispatchChangeAdmin() private returns (bytes memory) {
        _requireZeroValue();

        address newAdmin = abi.decode(msg.data[4:], (address));
        _changeAdmin(newAdmin);

        return "";
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     */
    function _dispatchUpgradeTo() private returns (bytes memory) {
        _requireZeroValue();

        address newImplementation = abi.decode(msg.data[4:], (address));
        _upgradeToAndCall(newImplementation, bytes(""), false);

        return "";
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     */
    function _dispatchUpgradeToAndCall() private returns (bytes memory) {
        (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
        _upgradeToAndCall(newImplementation, data, true);

        return "";
    }

    /**
     * @dev Returns the current admin.
     *
     * CAUTION: This function is deprecated. Use {ERC1967Upgrade-_getAdmin} instead.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev To keep this contract fully transparent, all `ifAdmin` functions must be payable. This helper is here to
     * emulate some proxy functions being non-payable while still allowing value to pass through.
     */
    function _requireZeroValue() private {
        require(msg.value == 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.5) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Context.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * Consider any assumption about calldata validation performed by the sender may be violated if it's not especially
 * careful about sending transactions invoking {multicall}. For example, a relay address that filters function
 * selectors won't filter calls nested within a {multicall} operation.
 *
 * NOTE: Since 5.0.1 and 4.9.4, this contract identifies non-canonical contexts (i.e. `msg.sender` is not {_msgSender}).
 * If a non-canonical context is identified, the following self `delegatecall` appends the last bytes of `msg.data`
 * to the subcall. This makes it safe to use with {ERC2771Context}. Contexts that don't affect the resolution of
 * {_msgSender} are not propagated to subcalls.
 *
 * _Available since v4.1._
 */
abstract contract Multicall is Context {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        bytes memory context = msg.sender == _msgSender()
            ? new bytes(0)
            : msg.data[msg.data.length - _contextSuffixLength():];

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), bytes.concat(data[i], context));
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToBytes32Map storage map) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToUintMap storage map, uint256 key, string memory errorMessage) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToUintMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToAddressMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(AddressToUintMap storage map) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToUintMap storage map, bytes32 key, uint256 value) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToUintMap storage map) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "@solarity/solidity-lib/utils/Globals.sol";

import {IDAOVoting} from "../interfaces/IDAOVoting.sol";
import {IPermissionManager} from "../interfaces/IPermissionManager.sol";

import {ArrayHelper} from "../libs/utils/ArrayHelper.sol";
import {Parameter} from "../libs/data-structures/Parameters.sol";

address constant ETHEREUM_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

string constant MASTER_ROLE = "MASTER";

string constant CREATE_PERMISSION = "CREATE";
string constant UPDATE_PERMISSION = "UPDATE";
string constant EXECUTE_PERMISSION = "EXECUTE";
string constant DELETE_PERMISSION = "DELETE";
string constant UPGRADE_PERMISSION = "UPGRADE";

string constant CONFIGURE_DAO_PERMISSION = "CONFIGURE_DAO";

string constant CREATE_VOTING_PERMISSION = "CREATE_VOTING";

string constant VOTE_FOR_PERMISSION = "VOTE_FOR";
string constant EXPERT_PERMISSION = "EXPERT";

string constant ADD_GROUP_PERMISSION = "ADD_GROUP";
string constant UPDATE_GROUP_PERMISSION = "UPDATE_GROUP";
string constant DELETE_GROUP_PERMISSION = "DELETE_GROUP";
string constant UPDATE_MEMBER_GROUP_PERMISSION = "UPDATE_MEMBER_GROUP";

string constant ADD_MEMBER_PERMISSION = "ADD_MEMBER";
string constant DELETE_MEMBER_PERMISSION = "DELETE_MEMBER";

string constant INTEGRATION_PERMISSION = "INTEGRATION";

string constant CHANGE_DAO_METADATA_PERMISSION = "CHANGE_DAO_METADATA";

string constant MINT_PERMISSION = "MINT";
string constant BURN_PERMISSION = "BURN";

string constant EXPERTS_VOTING_NAME = "EXPERTS_VOTING";
string constant GENERAL_VOTING_NAME = "GENERAL_VOTING";

string constant TOKEN_FACTORY_NAME = "TOKEN_FACTORY";
string constant TOKEN_REGISTRY_NAME = "TOKEN_REGISTRY";

string constant DAO_RESERVED_NAME = "DAO Token Holder";

string constant DAO_REGISTRY_NAME = "DAO_REGISTRY";
string constant DAO_PERMISSION_MANAGER_NAME = "DAO_PERMISSION_MANAGER";

string constant DAO_VAULT_NAME = "DAO_VAULT";

string constant DAO_MEMBER_STORAGE_NAME = "DAO_MEMBER_STORAGE";

// Used to get the implementation from the master DAO Registry
string constant DAO_PARAMETER_STORAGE_NAME = "DAO_PARAMETER_STORAGE";

// Parameter storage for configuration parameters such as votingPeriod, vetoPeriod, etc.
string constant DAO_CONF_PARAMETER_STORAGE_NAME = "DAO_CONF_PARAMETER_STORAGE";

// Parameter storage for regular experts parameters
string constant DAO_REG_PARAMETER_STORAGE_NAME = "DAO_REG_PARAMETER_STORAGE";

string constant DAO_PANEL_LIMIT_NAME = "constitution.maxPanelPerDAO";
string constant DAO_CONSTITUTION_HASH_NAME = "constitution.hash";

string constant TOKEN_FACTORY_RESOURCE = "TOKEN_FACTORY_RESOURCE";

string constant MASTER_DAO_FACTORY_RESOURCE = "MASTER_DAO_FACTORY_RESOURCE";

string constant DAO_VAULT_RESOURCE = "DAO_VAULT_RESOURCE";

string constant Q_REPRESENTATIVES_PANEL_NAME = "Q Root Node Representation";

/**
 * @title DAO Replacements Structure
 * @dev This structure represents a mapping for the DAO components in the MasterDAORegistry.
 * It is used to define custom implementations for various components of the DAO.
 *
 * @param componentName The name of the DAO component. This is a string that uniquely identifies
 * a specific implementation of a DAO component in the MasterDAORegistry.
 *
 * @param componentImplementation The address of the custom contract. This contract address
 * is used as a replacement for the default implementation of the specified DAO component.
 * It allows for customization and extension of DAO functionalities.
 */
struct DAOReplacements {
    string componentName;
    address componentImplementation;
}

/**
 * @title DAOConstructorParameters
 * @notice Structure containing the initial parameters required for creating a new DAO.
 *         This consolidates all necessary information for DAO creation.
 *
 * @param daoCreator Address of the individual or entity creating the DAO.
 * @param votingToken Address of the token used for voting in the DAO.
 * @param daoURI URI containing the DAO's descriptive information.
 * @param deploymentSalt Unique salt used for deployment, ensuring unique contract addresses.
 * @param initialParameters Array of parameters for setting up the initial configuration of the DAO.
 * @param daoReplacements Array of module replacements for the DAO.
 */
struct DAOConstructorParameters {
    address daoCreator;
    address votingToken;
    string daoURI;
    bytes32 deploymentSalt;
    Parameter[] initialParameters;
    DAOReplacements[] daoReplacements;
}

/**
 * @title DAOPanelConstructorParameters
 * @notice Structure containing the initial parameters for setting up a new panel within a DAO.
 *         Defines the initial configuration for the panel, including its voting parameters, initial settings, and members.
 *
 * @param panelName Name of the panel.
 * @param votingToken Address of the token used for voting within the panel.
 * @param situations Array of initial voting situations for the panel, defining different voting scenarios and rules.
 * @param initialParameters Array of initial parameters for the panel's configuration.
 * @param initialMembers Array of addresses representing the initial members of the panel, who will be granted EXPERT_PERMISSION.
 */
struct DAOPanelConstructorParameters {
    string panelName;
    address votingToken;
    IDAOVoting.ExtendedSituation[] situations;
    Parameter[] initialParameters;
    address[] initialMembers;
}

/**
 * @title Module Addition Types for DAO
 * @notice Enum for specifying module addition behavior in DAO.
 *
 * AddContract: Represents a standalone contract that will be directly added to the DAO Registry.
 *              This type indicates the use of a contract, not a proxy.
 *
 * AddProxyContract: Denotes an address that should serve as an implementation for a proxy.
 *                   The proxy will be deployed by the DAO Registry, and this address is used
 *                   for its implementation.
 *
 * JustAddProxyContract: Specifies that the provided address already represents a proxy contract.
 *                       This type is used to add the address to the DAO Registry and mark it
 *                       as a proxy.
 *
 * AddDeterministicProxyContract: Denotes an address that should serve as an implementation for a proxy.
 *                                The proxy will be deployed by the DAO Registry through the Crate2, and this address is used
 *                                for its implementation.
 */
enum ModuleAdditionType {
    AddContract,
    AddProxyContract,
    JustAddProxyContract,
    AddDeterministicProxyContract
}

/**
 * @notice Struct for detailed configuration of DAO modules.
 * @param moduleName The name representing the module in the DAO Registry.
 * @param moduleAddress The module address, varying based on `ModuleAdditionType`.
 * @param connectorPanelName Optional name for a separate role for the module.
 * @param moduleType Type of module addition, as defined in `ModuleAdditionType`.
 * @param constitutionParameters Optional parameters to be added to the constitution during DAO deployment.
 * @param votingName The name associated with the voting configuration.
 * @param situations Array of situations requiring extended voting scenarios.
 * @param vetoGroupSource Optional entity (DAOMemberStorage) to specify eligibility for vetoing proposals targeting the module.
 * @param initCallData Optional initialization data for the module.
 * @param salt Optional salt for deterministic deployment of the module.
 */
struct DAOModuleContractorParameters {
    string moduleName;
    address moduleAddress;
    string connectorRoleName;
    ModuleAdditionType moduleType;
    Parameter[] constitutionParameters;
    string votingName;
    IDAOVoting.ExtendedSituation situation;
    address vetoGroupSource;
    bytes initCallData;
    bytes32 salt;
}

function getVotingKey(string memory situation_, string memory key_) pure returns (string memory) {
    return string.concat(situation_, ".", key_);
}

// Return `string[] memory` in all functions instead of `string memory`
// to avoid stack too deep error
using ArrayHelper for string[1];

function getDAOGroup(string memory daoRegistryResource_) pure returns (string[] memory) {
    return [string.concat("DAOGroup:", daoRegistryResource_)].asArray();
}

function getDAOExpertGroup(string memory panelName_) pure returns (string[] memory) {
    return [string.concat("DAOExpertVotingGroup:", panelName_)].asArray();
}

function getDAOCreatorRole(string memory resource_) pure returns (string[] memory) {
    return [string.concat("DAOCreatorRole:", resource_)].asArray();
}

function getDAOMemberRole(string memory panelName_) pure returns (string[] memory) {
    return [string.concat("DAOMemberRole:", panelName_)].asArray();
}

function getDAOExpertRole(string memory panelName_) pure returns (string[] memory) {
    return [string.concat("DAOExpertRole:", panelName_)].asArray();
}

function getDAOVotingRole(string memory panelName_) pure returns (string[] memory) {
    return [string.concat("DAOVotingRole:", panelName_)].asArray();
}

function getDAOMemberStorageRole(string memory panelName_) pure returns (string[] memory) {
    return [string.concat("DAOMemberStorageRole:", panelName_)].asArray();
}

function getDAOVaultRole() pure returns (string[] memory) {
    return [string.concat("DAOVaultRole:", DAO_VAULT_RESOURCE)].asArray();
}

using Strings for uint256;

/**
 * @notice Returns the resource name for the specified DAO module.
 * @param moduleType_ The type of the DAO module for which to get the resource name.
 * @param moduleProxy_ The proxy address of the DAO module for which to get the resource name.
 * @return The resource name for the specified DAO module.
 */
function getDAOResource(
    string memory moduleType_,
    address moduleProxy_
) pure returns (string memory) {
    return string.concat(moduleType_, ":", uint256(uint160(moduleProxy_)).toHexString(20));
}

/**
 * @notice Returns the resource name for the specified DAO panel.
 * @param moduleType_ The type of the DAO module for which to get the resource name.
 * @param panelName_ The name of the panel for which to get the resource name.
 * @return The resource name for the specified DAO panel.
 */
function getDAOPanelResource(
    string memory moduleType_,
    string memory panelName_
) pure returns (string memory) {
    return string.concat(moduleType_, ":", panelName_);
}

function calculatePercentage(uint256 part, uint256 amount) pure returns (uint256) {
    if (amount == 0) {
        return 0;
    }

    return (part * PERCENTAGE_100) / amount;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

import {AbstractContractsRegistry} from "@solarity/solidity-lib/contracts-registry/AbstractContractsRegistry.sol";

import "../Globals.sol";

/**
 * @title RoleManagedRegistry
 * @notice This contract serves as a registry for contracts and implements role-based access control
 * for performing certain actions.
 *
 * @dev To perform actions on contracts, such as upgrading or modifying them, appropriate permissions
 * must be possessed by the caller.
 *
 * The `DAORegistry` and `MasterContractsRegistry` are based on this contract.
 * In addition, this contract inherits from the `AbstractContractsRegistry` contract as per the EIP-6224 standard.
 * For more information, see https://eips.ethereum.org/EIPS/eip-6224. The documentation on the `AbstractContractsRegistry` contract
 * can also be used to gain a deeper understanding of the architecture of contract registries in this project.
 *
 * All implementation details are contained in the `AbstractContractsRegistry` contract;
 * therefore, if any aspect is unclear, it is recommended to refer to its documentation.
 */
abstract contract RoleManagedRegistry is AbstractContractsRegistry, Multicall {
    /**
     * @notice Initializes the contract by setting the address of the permission manager,
     * which will be used to check the permissions of the user performing operations
     * on the contracts registry (currently, the registries are `DAORegistry` and `MasterContractsRegistry`).
     * @param permissionManager_ The address of the permission manager.
     */
    function __RoleManagedRegistry_init(address permissionManager_) internal onlyInitializing {
        __ContractsRegistry_init();
        _addProxyContract(DAO_PERMISSION_MANAGER_NAME, permissionManager_);
    }

    modifier onlyCreatePermission() virtual {
        _;
    }

    modifier onlyUpdatePermission() virtual {
        _;
    }

    modifier onlyDeletePermission() virtual {
        _;
    }

    /**
     * @notice Returns the address of the permission manager contract.
     * @return The address of the permission manager contract.
     */
    function getPermissionManager() public view returns (address) {
        return getContract(DAO_PERMISSION_MANAGER_NAME);
    }

    /**
     * @notice Injects dependencies into the contract with the given name.
     * @param name_ The name of the contract into which to inject dependencies.
     *
     * This function takes the contract with the specified name from the Contract Registry
     * and calls its setDependencies(...) function to inject dependencies.
     */
    function injectDependencies(string memory name_) external onlyCreatePermission {
        _injectDependencies(name_);
    }

    /**
     * @notice Upgrades the contract with the given name to the new implementation.
     * @param name_ The name of the contract to upgrade.
     * @param newImplementation_ The address of the new implementation.
     */
    function upgradeContract(
        string memory name_,
        address newImplementation_
    ) external onlyUpdatePermission {
        _upgradeContract(name_, newImplementation_);
    }

    /**
     * @notice Upgrades the contract with the given name to the new implementation and calls the
     * new implementation with the given data.
     * @param name_ The name of the contract to upgrade.
     * @param newImplementation_ The address of the new implementation.
     * @param data_ The data to call the new implementation with.
     */
    function upgradeContractAndCall(
        string memory name_,
        address newImplementation_,
        bytes memory data_
    ) external onlyUpdatePermission {
        _upgradeContractAndCall(name_, newImplementation_, data_);
    }

    /**
     * @notice Adds a new contract to the registry.
     * @param name_ The name of the contract.
     * @param contractAddress_ The address of the contract.
     */
    function addContract(
        string memory name_,
        address contractAddress_
    ) public virtual onlyCreatePermission {
        _addContract(name_, contractAddress_);
    }

    /**
     * @notice Adds a new proxy contract to the registry.
     * @param name_ The name of the contract.
     * @param contractAddress_ The address of the contract.
     *
     * Under the hood it will deploy TransparentUpgradeableProxy with the given contractAddress_ as implementation
     */
    function addProxyContract(
        string memory name_,
        address contractAddress_
    ) public virtual onlyCreatePermission {
        _addProxyContract(name_, contractAddress_);
    }

    /**
     * @notice Adds a new proxy contract to the registry and calls the contract with the given data.
     * @param name_ The name of the contract.
     * @param contractAddress_ The address of the contract.
     * @param data_ The data to call the contract with.
     *
     * Under the hood it will deploy TransparentUpgradeableProxy with the given contractAddress_ as implementation
     */
    function addProxyContractAndCall(
        string memory name_,
        address contractAddress_,
        bytes memory data_
    ) public virtual onlyCreatePermission {
        _addProxyContractAndCall(name_, contractAddress_, data_);
    }

    /**
     * @notice Adds a new proxy contract to the registry.
     * @param name_ The name of the contract to add.
     * @param contractAddress_ The address of the contract to add.
     *
     * This function adds a new contract to the contract registry and marks it as a proxy.
     */
    function justAddProxyContract(
        string memory name_,
        address contractAddress_
    ) public virtual onlyCreatePermission {
        _justAddProxyContract(name_, contractAddress_);
    }

    /**
     * @notice Removes a contract from the registry.
     * @param name_ The name of the contract to remove.
     */
    function removeContract(string memory name_) public virtual onlyDeletePermission {
        _removeContract(name_);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {AbstractDependant} from "@solarity/solidity-lib/contracts-registry/AbstractDependant.sol";

import {DAORegistry} from "./DAORegistry.sol";
import {PermissionManager} from "./PermissionManager.sol";

import "../core/Globals.sol";

import {ISubmitSignature} from "../interfaces/ISubmitSignature.sol";
import {IDAOMemberStorage, IDAOResource} from "../interfaces/IDAOMemberStorage.sol";

import {EIP712Upgradeable} from "../upgradable-contracts/EIP712Upgradeable.sol";

/**
 * @title DAOMemberStorage
 * @notice Manages the storage of DAO panel members, focusing on the identification and assignment of experts to specific resources.
 *
 * @dev
 * - Serves as the storage contract for the DAO panel members.
 * - Integral to the DAO's functionality for designating special addresses (experts) in charge of
 *   certain resources, specifically related to the panel DAO (resource).
 * - Facilitates the addition of new members to the panel, typically through a voting process,
 *   aligning them with the respective DAO panel identified by its name.
 */
contract DAOMemberStorage is
    IDAOMemberStorage,
    Initializable,
    EIP712Upgradeable,
    ERC165,
    AbstractDependant
{
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant CANDIDATE_TYPEHASH =
        keccak256("Candidate(address dao,address candidate,string message,bytes32 nonce)");

    /**
     * @notice An immutable string representing the Members storage in the DAO.
     * @dev Added in v1.0.0.
     */
    string public DAO_MEMBER_STORAGE_RESOURCE;

    /**
     * @notice An immutable string representing the related Expert panel.
     * @dev Added in v1.0.0.
     */
    string public targetPanel;

    /**
     * @notice Related Permission Manager contract.
     * @dev Added in v1.0.0.
     */
    PermissionManager public permissionManager;

    /**
     * @notice A list of current members.
     * @dev Added in v1.0.0.
     */
    EnumerableSet.AddressSet internal _members;

    /**
     * @notice A mapping of submitted signatures.
     * @dev Added in v1.4.0.
     */
    mapping(address candidate => mapping(uint256 blockId => bool)) internal _submittedSignatures;

    modifier onlyCreatePermission() {
        _requirePermission(CREATE_PERMISSION);
        _;
    }

    modifier onlyDeletePermission() {
        _requirePermission(DELETE_PERMISSION);
        _;
    }

    function __DAOMemberStorage_init(
        string memory targetPanel_,
        string memory resource_,
        address[] memory initMembers_
    ) external initializer {
        require(bytes(resource_).length > 0, "[QGDK-004005]-The resource name cannot be empty.");

        targetPanel = targetPanel_;

        DAO_MEMBER_STORAGE_RESOURCE = resource_;

        for (uint256 i = 0; i < initMembers_.length; i++) {
            _addMember(initMembers_[i]);
        }

        DAORegistry registry_ = permissionManager.getDAORegistry();

        __EIP712_init(resource_, registry_.version());
    }

    /**
     * @dev Added to ensure backwards compatibility with older DAOs.
     *
     * @notice Enables the initialization of the domain separator for the EIP712 contract separately during
     * contract upgrades on older DAOs.
     */
    function __EIP712Domain_init() external {
        require(
            bytes(_EIP712Name()).length == 0,
            "[QGDK-004002]-The domain has already been initialized."
        );

        DAORegistry registry_ = permissionManager.getDAORegistry();

        __EIP712_init(DAO_MEMBER_STORAGE_RESOURCE, registry_.version());
    }

    /**
     * @inheritdoc AbstractDependant
     */
    function setDependencies(address registryAddress_, bytes memory) public override dependant {
        DAORegistry registry_ = DAORegistry(registryAddress_);

        permissionManager = PermissionManager(registry_.getPermissionManager());
    }

    /**
     * @inheritdoc IDAOResource
     */
    function checkPermission(
        address account_,
        string memory permission_
    ) public view returns (bool) {
        return permissionManager.hasPermission(account_, DAO_MEMBER_STORAGE_RESOURCE, permission_);
    }

    /**
     * @inheritdoc IDAOResource
     */
    function getResource() external view returns (string memory) {
        return DAO_MEMBER_STORAGE_RESOURCE;
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function addMember(address member_) external onlyCreatePermission {
        require(
            member_ == tx.origin || _submittedSignatures[member_][block.number],
            "[QGDK-004001]-The candidate should be the one who initiates the transaction."
        );

        _addMember(member_);
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function submitSignature(
        address signer_,
        bytes memory signature_,
        bytes32 nonce_
    ) external onlyCreatePermission {
        bool valid_ = SignatureChecker.isValidSignatureNow(
            signer_,
            getCandidateHash(signer_, nonce_),
            signature_
        );

        require(valid_, "[QGDK-004004]-Invalid signature.");

        _submittedSignatures[signer_][block.number] = true;
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function removeMember(address member_) external onlyDeletePermission {
        _removeMember(member_);
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function removeMembers(address[] memory members_) external onlyDeletePermission {
        for (uint256 i = 0; i < members_.length; i++) {
            _removeMember(members_[i]);
        }
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function getCandidateHash(address candidate_, bytes32 nonce_) public view returns (bytes32) {
        address dao_ = address(permissionManager.getDAORegistry());

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        CANDIDATE_TYPEHASH,
                        dao_,
                        candidate_,
                        keccak256(bytes(getMessage())),
                        nonce_
                    )
                )
            );
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function getMessage() public view returns (string memory) {
        return string.concat("I accept to become a member of ", targetPanel, " expert panel.");
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function isMember(address member_) external view returns (bool) {
        return _members.contains(member_);
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function getMembers() external view returns (address[] memory) {
        return _members.values();
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function getMembersCount() external view returns (uint256) {
        return _members.length();
    }

    /**
     * @inheritdoc IDAOMemberStorage
     */
    function getGroup() external view returns (string[] memory) {
        return getDAOExpertGroup(targetPanel);
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(ISubmitSignature).interfaceId ||
            interfaceId == type(IDAOMemberStorage).interfaceId ||
            interfaceId == type(IDAOResource).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _addMember(address member_) private {
        _members.add(member_);

        string[] memory group_ = getDAOExpertGroup(targetPanel);
        permissionManager.addMemberToGroup(member_, group_);

        emit MemberAdded(member_, group_[0]);
    }

    function _removeMember(address member_) private {
        _members.remove(member_);

        string[] memory group_ = getDAOExpertGroup(targetPanel);
        permissionManager.removeMemberFromGroup(member_, group_);

        emit MemberRemoved(member_, group_[0]);
    }

    function _requirePermission(string memory permission_) private view {
        require(
            checkPermission(msg.sender, permission_),
            "[QGDK-004000]-The sender is not allowed to perform the action, access denied."
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {AbstractDependant} from "@solarity/solidity-lib/contracts-registry/AbstractDependant.sol";

import {DAORegistry} from "./DAORegistry.sol";
import {PermissionManager} from "./PermissionManager.sol";

import "../core/Globals.sol";

import {ParameterSet, Parameter} from "../libs/data-structures/ParameterSet.sol";

import {IDAOParameterStorage, IDAOResource} from "../interfaces/IDAOParameterStorage.sol";

/**
 * @title DAOParameterStorage
 * @notice Implements a storage system for managing parameters within a DAO context, particularly
 * related to DAO panels.
 *
 * The contract serves as a central repository for various DAO parameters, such as voting types,
 * durations, and other governance-related settings. It is tightly integrated with the overall DAO
 * structure, providing functionalities for the addition, update, retrieval, and removal of these parameters.
 * This enables dynamic and flexible governance models tailored to specific needs of the DAO.
 */
contract DAOParameterStorage is IDAOParameterStorage, ERC165, Initializable, AbstractDependant {
    using ParameterSet for ParameterSet.Set;

    /**
     * @notice An immutable string representing the Parameters storage in the DAO.
     * @dev Added in v1.0.0.
     */
    string public DAO_PARAMETER_STORAGE_RESOURCE;

    /**
     * @notice Removed variable that is left here to maintain the storage layout.
     * @dev Introduced in v1.0.0. Removed in v1.4.0.
     * Previously, it was voting type (type: enum VotingType).
     */
    uint8 private __removed0;

    /**
     * @notice Related Permission Manager contract.
     * @dev Added in v1.0.0.
     */
    PermissionManager public permissionManager;

    /**
     * @notice A list of current parameters.
     * @dev Added in v1.0.0.
     */
    ParameterSet.Set internal _parameters;

    modifier onlyUpdatePermission() {
        _requirePermission(UPDATE_PERMISSION);
        _;
    }

    modifier onlyDeletePermission() {
        _requirePermission(DELETE_PERMISSION);
        _;
    }

    /**
     * @notice Initializes the contract with resource that contains panel name as part of itself.
     */
    function __DAOParameterStorage_init(string memory resource_) external initializer {
        DAO_PARAMETER_STORAGE_RESOURCE = resource_;
    }

    /**
     * @inheritdoc AbstractDependant
     */
    function setDependencies(address registryAddress_, bytes memory) public override dependant {
        DAORegistry registry_ = DAORegistry(registryAddress_);

        permissionManager = PermissionManager(registry_.getPermissionManager());
    }

    /**
     * @inheritdoc IDAOResource
     */
    function checkPermission(
        address member_,
        string memory permission_
    ) public view returns (bool) {
        return
            permissionManager.hasPermission(member_, DAO_PARAMETER_STORAGE_RESOURCE, permission_);
    }

    /**
     * @inheritdoc IDAOResource
     */
    function getResource() external view returns (string memory) {
        return DAO_PARAMETER_STORAGE_RESOURCE;
    }

    /**
     * @inheritdoc IDAOParameterStorage
     */
    function setDAOParameter(Parameter memory parameter_) external onlyUpdatePermission {
        _setDAOParameter(parameter_);
    }

    /**
     * @inheritdoc IDAOParameterStorage
     */
    function setDAOParameters(Parameter[] memory parameters_) external onlyUpdatePermission {
        for (uint256 i = 0; i < parameters_.length; i++) {
            _setDAOParameter(parameters_[i]);
        }
    }

    /**
     * @inheritdoc IDAOParameterStorage
     */
    function removeDAOParameter(string memory parameterName_) external onlyDeletePermission {
        _removeDAOParameter(parameterName_);
    }

    /**
     * @inheritdoc IDAOParameterStorage
     */
    function removeDAOParameters(string[] memory parameterNames_) external onlyDeletePermission {
        for (uint256 i = 0; i < parameterNames_.length; i++) {
            _removeDAOParameter(parameterNames_[i]);
        }
    }

    /**
     * @inheritdoc IDAOParameterStorage
     */
    function getDAOParameter(
        string memory parameterName_
    ) external view returns (Parameter memory) {
        _checkParameterExistence(parameterName_);

        return _parameters.get(parameterName_);
    }

    /**
     * @inheritdoc IDAOParameterStorage
     */
    function getDAOParameters() external view returns (Parameter[] memory) {
        return _parameters.values();
    }

    /**
     * @inheritdoc IDAOParameterStorage
     */
    function hasDAOParameter(string memory parameterName_) external view returns (bool) {
        return _parameters.contains(parameterName_);
    }

    /**
     * @inheritdoc IDAOParameterStorage
     */
    function getParameterByIndex(uint256 index_) external view returns (Parameter memory) {
        return _parameters.at(index_);
    }

    /**
     * @inheritdoc IDAOParameterStorage
     */
    function getParametersCount() external view returns (uint256) {
        return _parameters.length();
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IDAOParameterStorage).interfaceId ||
            interfaceId == type(IDAOResource).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _setDAOParameter(Parameter memory parameter_) internal {
        if (_parameters.contains(parameter_.name)) {
            _parameters.change(parameter_);

            emit ParameterChanged(parameter_);

            return;
        }

        _parameters.add(parameter_);

        emit ParameterAdded(parameter_);
    }

    function _removeDAOParameter(string memory parameterName_) internal {
        _checkParameterExistence(parameterName_);

        _parameters.remove(parameterName_);

        emit ParameterRemoved(parameterName_);
    }

    function _checkParameterExistence(string memory parameterName_) private view {
        if (!_parameters.contains(parameterName_)) {
            revert DAOParameterStorage__ParameterNotFound(parameterName_);
        }
    }

    function _requirePermission(string memory permission_) private view {
        require(
            checkPermission(msg.sender, permission_),
            "[QGDK-005000]-The sender is not allowed to perform the action, access denied."
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {StringSet} from "@solarity/solidity-lib/libs/data-structures/StringSet.sol";

import {PermissionManager} from "./PermissionManager.sol";
import {DAOParameterStorage} from "./DAOParameterStorage.sol";

import {IDAORegistry} from "../interfaces/IDAORegistry.sol";
import {IDAOResource} from "../interfaces/IDAOResource.sol";

import {DAOMetadata} from "../metadata/DAOMetadata.sol";

import "../core/Globals.sol";

import {RoleManagedRegistry} from "../core/registry/RoleManagedRegistry.sol";

import {ParameterCodec} from "../libs/data-structures/Parameters.sol";

/**
 * @title DAORegistry
 * @notice This contract serves as a registry for all DAO contracts and grants permission
 * to update contracts to eligible parties via the permission manager.
 *
 * The `DAORegistry` contract primarily stores addresses of contracts associated with the DAO.
 * Upon the creation of a DAO, several contracts (such as dao vault, permission manager, etc.) are already in place.
 *
 * However, the process doesn't end there. Throughout its lifecycle, a DAO may decide to incorporate additional functionalities,
 * necessitating the addition of new contracts and their management through the DAO itself.
 * This is achievable by utilizing the `PermissionManager` contract and DAO resources.
 *
 * The fundamental paradigm of the system is as follows:
 *  - All contracts in the system are considered `resources`.
 *  - Over each resource, an `action` can be performed.
 *
 * This contract allows access to the addresses of the base modules and a list of panels currently active in the DAO.
 */
contract DAORegistry is IDAORegistry, ERC165, DAOMetadata, UUPSUpgradeable, RoleManagedRegistry {
    using ParameterCodec for *;

    using StringSet for StringSet.Set;

    /**
     * @notice An immutable string representing the Parameters storage in the DAO.
     * @dev Added in v1.0.0.
     */
    string public DAO_REGISTRY_RESOURCE;

    /**
     * @notice Related Permission Manager contract.
     * @dev Added in v1.0.0.
     */
    PermissionManager public permissionManager;

    /**
     * @notice A list of DAO panels. Does not include the reserved panel.
     * @dev Added in v1.0.0.
     */
    StringSet.Set internal _panels;

    /**
     * @notice A list of registry contract names.
     * @dev Added in v1.0.0.
     */
    StringSet.Set internal _registryContractNames;

    /**
     * @notice A Protocol Version of the DAO.
     * @dev Added in v1.4.0.
     */
    string private _version;

    modifier onlyCreatePermission() override {
        _requirePermission(CREATE_PERMISSION);
        _;
    }

    modifier onlyUpdatePermission() override {
        _requirePermission(UPDATE_PERMISSION);
        _;
    }

    modifier onlyDeletePermission() override {
        _requirePermission(DELETE_PERMISSION);
        _;
    }

    modifier onlyChangeDAOMetadataPermission() override {
        _requirePermission(CHANGE_DAO_METADATA_PERMISSION);
        _;
    }

    /**
     * @notice Initializes the contract with unique resource, and inits the permission manager,
     * that will be used to manage the permissions for the DAO.
     */
    function __DAORegistry_init(
        address permissionManager_,
        address master_,
        string memory registryResource_,
        string memory daoURI_,
        string memory version_
    ) external initializer {
        __DAOMetadata_init(daoURI_);
        __RoleManagedRegistry_init(permissionManager_);

        permissionManager = PermissionManager(getPermissionManager());

        string memory managerResource_ = getDAOResource(
            DAO_PERMISSION_MANAGER_NAME,
            address(permissionManager)
        );

        DAO_REGISTRY_RESOURCE = registryResource_;

        permissionManager.__PermissionManager_init(this, master_, managerResource_);

        _registryContractNames.add(DAO_PERMISSION_MANAGER_NAME);

        _version = version_;

        emit Initialized(master_, daoURI_);
    }

    /**
     * @inheritdoc IDAOResource
     */
    function checkPermission(
        address account_,
        string memory permission_
    ) public view returns (bool) {
        return permissionManager.hasPermission(account_, DAO_REGISTRY_RESOURCE, permission_);
    }

    /**
     * @inheritdoc IDAOResource
     */
    function getResource() external view returns (string memory) {
        return DAO_REGISTRY_RESOURCE;
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function addPanel(string memory panelName_) external onlyCreatePermission {
        require(
            !Strings.equal(panelName_, DAO_RESERVED_NAME),
            "[QGDK-006001]-The panel name is reserved."
        );

        require(_panels.add(panelName_), "[QGDK-006002]-The panel already exists in the DAO.");

        require(isAbleToAddPanel(), "[QGDK-006004]-The panel limit has been reached.");

        emit PanelAdded(panelName_);
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function removePanel(string memory panelName_) external onlyDeletePermission {
        require(_panels.remove(panelName_), "[QGDK-006003]-The panel does not exist in the DAO.");

        emit PanelRemoved(panelName_);
    }

    /**
     * @inheritdoc RoleManagedRegistry
     */
    function addContract(string memory name_, address contractAddress_) public override {
        super.addContract(name_, contractAddress_);

        _registryContractNames.add(name_);
    }

    /**
     * @inheritdoc RoleManagedRegistry
     */
    function addProxyContract(string memory name_, address contractAddress_) public override {
        super.addProxyContract(name_, contractAddress_);

        _registryContractNames.add(name_);
    }

    /**
     * @inheritdoc RoleManagedRegistry
     */
    function addProxyContractAndCall(
        string memory name_,
        address contractAddress_,
        bytes memory data_
    ) public override {
        super.addProxyContractAndCall(name_, contractAddress_, data_);

        _registryContractNames.add(name_);
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function addDeterministicProxy(
        string memory name_,
        bytes32 salt_,
        address contractAddress_,
        bytes memory data_
    ) external {
        address proxy_ = _deploy2Proxy(salt_, contractAddress_, data_);

        justAddProxyContract(name_, proxy_);
    }

    /**
     * @inheritdoc RoleManagedRegistry
     */
    function justAddProxyContract(string memory name_, address contractAddress_) public override {
        super.justAddProxyContract(name_, contractAddress_);

        _registryContractNames.add(name_);
    }

    /**
     * @inheritdoc RoleManagedRegistry
     */
    function removeContract(string memory name_) public override {
        super.removeContract(name_);

        _registryContractNames.remove(name_);
    }

    function predictProxyAddress(
        bytes32 salt_,
        address contractAddress_,
        bytes memory data_
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(TransparentUpgradeableProxy).creationCode,
                abi.encode(contractAddress_, getProxyUpgrader(), data_)
            )
        );

        return Create2.computeAddress(salt_, bytecodeHash);
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function getConfDAOParameterStorage(string memory panelName_) public view returns (address) {
        return getContract(getDAOPanelResource(DAO_CONF_PARAMETER_STORAGE_NAME, panelName_));
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function getPanels() external view returns (string[] memory) {
        return _panels.values();
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function getRegistryContractAddresses()
        external
        view
        returns (RegistryEntry[] memory entries_)
    {
        string[] memory names_ = _registryContractNames.values();
        entries_ = new RegistryEntry[](names_.length);

        for (uint256 i = 0; i < names_.length; i++) {
            entries_[i] = RegistryEntry(names_[i], getContract(names_[i]));
        }
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function isAbleToAddPanel() public view returns (bool) {
        DAOParameterStorage daoParameterStorage_ = DAOParameterStorage(
            getConfDAOParameterStorage(DAO_RESERVED_NAME)
        );

        uint256 panelLimit_ = daoParameterStorage_
            .getDAOParameter(DAO_PANEL_LIMIT_NAME)
            .decodeUint256();

        return _panels.length() < panelLimit_;
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function getAccountStatuses(
        address account_
    ) external view returns (AccountStatus memory status) {
        string[] memory panels_ = _panels.values();
        uint256 panelsLength_ = panels_.length;

        string[] memory groups_ = new string[](panelsLength_ + 1);
        bool[] memory isMember_ = new bool[](panelsLength_ + 1);

        groups_[0] = "DAO Token Holder";
        isMember_[0] = permissionManager.hasPermission(
            account_,
            DAO_REGISTRY_RESOURCE,
            VOTE_FOR_PERMISSION
        );

        for (uint256 i = 0; i < panelsLength_; i++) {
            groups_[i + 1] = getDAOGroup(panels_[i])[0];
            isMember_[i + 1] = permissionManager.hasPermission(
                account_,
                getDAOPanelResource(EXPERTS_VOTING_NAME, panels_[i]),
                EXPERT_PERMISSION
            );
        }

        status.groups = groups_;
        status.isMember = isMember_;
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function getRegDAOParameterStorage(string memory panelName_) external view returns (address) {
        return getContract(getDAOPanelResource(DAO_REG_PARAMETER_STORAGE_NAME, panelName_));
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function getDAOMemberStorage(string memory panelName_) external view returns (address) {
        return getContract(getDAOPanelResource(DAO_MEMBER_STORAGE_NAME, panelName_));
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function getGeneralDAOVoting(string memory panelName_) external view returns (address) {
        return getContract(getDAOPanelResource(GENERAL_VOTING_NAME, panelName_));
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function getExpertsDAOVoting(string memory panelName_) external view returns (address) {
        return getContract(getDAOPanelResource(EXPERTS_VOTING_NAME, panelName_));
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function getDAOVault() external view returns (address) {
        return getContract(DAO_VAULT_NAME);
    }

    /**
     * @inheritdoc IDAORegistry
     */
    function version() external view returns (string memory) {
        return _version;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IDAORegistry).interfaceId ||
            interfaceId == type(IDAOResource).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _requirePermission(string memory permission_) internal view {
        require(
            checkPermission(msg.sender, permission_),
            "[QGDK-006000]-The sender is not allowed to perform the action, access denied."
        );
    }

    function _deploy2Proxy(
        bytes32 salt_,
        address contractAddress_,
        bytes memory data_
    ) internal returns (address) {
        return
            address(
                new TransparentUpgradeableProxy{salt: salt_}(
                    contractAddress_,
                    getProxyUpgrader(),
                    data_
                )
            );
    }

    function _authorizeUpgrade(address) internal virtual override {
        require(msg.sender == getProxyUpgrader(), "[QGDK-006005]-Not authorized to upgrade.");
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {PriorityQueue} from "@solarity/solidity-lib/libs/data-structures/PriorityQueue.sol";
import {AbstractDependant} from "@solarity/solidity-lib/contracts-registry/AbstractDependant.sol";

import {DAORegistry} from "./DAORegistry.sol";
import {PermissionManager} from "./PermissionManager.sol";

import {IDAOVault} from "../interfaces/IDAOVault.sol";
import {IERC5484} from "../interfaces/tokens/IERC5484.sol";

import "../core/Globals.sol";

import {TokenBalance} from "../libs/utils/TokenBalance.sol";
import {TimeLockHelper} from "../libs/utils/TimeLockHelper.sol";
import {ConstitutionData} from "../libs/utils/ConstitutionData.sol";

import {EIP712Upgradeable} from "../upgradable-contracts/EIP712Upgradeable.sol";

/**
 * @title DAOVault
 * @notice Manages tokens for a DAO, allowing users to lock ERC20, ERC721, and Native tokens,
 * or authorize with SBT to obtain the DAO Token Holder role.
 *
 * This contract distinguishes between ERC20 and Native tokens using the ETHEREUM_ADDRESS in
 * depositNative and depositERC20 functions. For NFT operations, it provides separate functions
 * such as lockNFT, depositNFT, and withdrawNFT.
 *
 * The locking mechanism for ERC20 and Native tokens is straightforward: the voting contract
 * locks all user tokens in the Vault for a specified duration. After the lock period ends, users
 * can withdraw their tokens directly without needing a separate transaction to remove time-locks.
 *
 * For NFTs and SBTs, the process differs. Only one of the user's NFTs is locked for a certain
 * period, whereas SBTs are not locked. The DAO Vault contract checks for SBT ownership, and if
 * present, grants the user the DAO Token Holder role.
 *
 * Users can withdraw NFTs only after the lock period has elapsed, and may revoke SBT authorization
 * at any time.
 */
contract DAOVault is IDAOVault, Initializable, EIP712Upgradeable, AbstractDependant {
    using TokenBalance for address;
    using ERC165Checker for address;

    using EnumerableSet for *;

    using PriorityQueue for PriorityQueue.UintQueue;
    using TimeLockHelper for PriorityQueue.UintQueue;

    bytes32 public constant CONSTITUTION_SIGN_TYPEHASH =
        keccak256("ConstitutionSign(address dao,bytes32 constitutionHash,address signer)");

    uint256 public constant MAX_LOCKED_TIME = 365 days;

    string public CONNECTED_DAO_REGISTRY;

    PermissionManager public permissionManager;

    // user => token => total voting power
    mapping(address user => mapping(address token => uint256 balance)) public userTokenBalance;

    // user => token => locks
    mapping(address user => mapping(address token => PriorityQueue.UintQueue)) public lockedTokens;

    // token => total supply
    mapping(address token => uint256 amountInVault) public tokenBalance;

    // user => token collection
    mapping(address user => EnumerableSet.AddressSet) internal _userTokens;

    // user => token => tokenIds
    mapping(address user => mapping(address nft => EnumerableSet.UintSet tokenIds))
        internal _userNFTs;

    // user => constitution data
    mapping(address user => ConstitutionDataInfo) internal _constitutionData;

    modifier onlyUpdatePermission() {
        _requirePermission(UPDATE_PERMISSION);
        _;
    }

    modifier onlyEligibleUser(address user_) {
        _requireConstitutionSigned(user_);
        _;
    }

    receive() external payable {
        _deposit(ETHEREUM_ADDRESS, msg.value);
    }

    /**
     * @inheritdoc AbstractDependant
     */
    function setDependencies(address registryAddress_, bytes memory) public override dependant {
        DAORegistry registry_ = DAORegistry(registryAddress_);

        permissionManager = PermissionManager(registry_.getPermissionManager());

        CONNECTED_DAO_REGISTRY = registry_.DAO_REGISTRY_RESOURCE();

        __EIP712_init(
            string.concat(DAO_VAULT_RESOURCE, CONNECTED_DAO_REGISTRY),
            registry_.version()
        );
    }

    /**
     * @inheritdoc IDAOVault
     */
    function signConstitution(address signer_, bytes calldata signature_) external {
        DAORegistry registry_ = permissionManager.getDAORegistry();

        require(
            ConstitutionData.validateSignature(signature_, registry_, signer_),
            "[QGDK-007012]-Invalid signature."
        );

        _signConstitution(signer_);
    }

    function signEIP712Constitution(address signer_, bytes calldata signature_) external {
        bool valid_ = SignatureChecker.isValidSignatureNow(
            signer_,
            getConstitutionSignHash(signer_),
            signature_
        );

        require(valid_, "[QGDK-007012]-Invalid signature.");

        _signConstitution(signer_);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function depositNative() external payable {
        _deposit(ETHEREUM_ADDRESS, msg.value);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function depositERC20(address tokenAddress_, uint256 amount_) public {
        IERC20(tokenAddress_).transferFrom(msg.sender, address(this), amount_);

        _deposit(tokenAddress_, amount_);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function depositNFT(
        address tokenAddress_,
        uint256 tokenId_
    ) public onlyEligibleUser(msg.sender) {
        require(isSupportedNFT(tokenAddress_), "[QGDK-007000]-The token does not supported.");

        IERC721(tokenAddress_).transferFrom(msg.sender, address(this), tokenId_);

        _userTokens[msg.sender].add(tokenAddress_);
        _userNFTs[msg.sender][tokenAddress_].add(tokenId_);

        permissionManager.addMemberToGroup(msg.sender, getDAOGroup(CONNECTED_DAO_REGISTRY));

        emit NFTDeposited(tokenAddress_, msg.sender, tokenId_);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function authorizeBySBT(address tokenAddress_) external onlyEligibleUser(msg.sender) {
        require(
            isAuthorizedBySBT(msg.sender, tokenAddress_),
            "[QGDK-007001]-The user is not authorized or token does not supported."
        );

        _userTokens[msg.sender].add(tokenAddress_);

        permissionManager.addMemberToGroup(msg.sender, getDAOGroup(CONNECTED_DAO_REGISTRY));

        emit AuthorizedBySBT(tokenAddress_, msg.sender);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function withdrawNative(uint256 amount_) external {
        _withdraw(ETHEREUM_ADDRESS, amount_);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function withdrawERC20(address tokenAddress_, uint256 amount_) external {
        _withdraw(tokenAddress_, amount_);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function withdrawNFT(address tokenAddress_, uint256 tokenId_) external {
        require(
            lockedTokens[msg.sender][tokenAddress_].isAbleToWithdrawNFT(tokenId_),
            "[QGDK-007004]-Trying to withdraw locked NFT."
        );

        uint256 userTokenId_ = _userNFTs[msg.sender][tokenAddress_].at(0);
        _userNFTs[msg.sender][tokenAddress_].remove(userTokenId_);

        if (_userNFTs[msg.sender][tokenAddress_].length() == 0) {
            _removeTokenFromUser(tokenAddress_);
        }

        IERC721(tokenAddress_).transferFrom(address(this), msg.sender, userTokenId_);

        emit NFTWithdrew(tokenAddress_, msg.sender, tokenId_);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function revokeSBTAuthorization(address tokenAddress_) external {
        require(
            isAuthorizedBySBT(msg.sender, tokenAddress_),
            "[QGDK-007005]-The user is not authorized or token does not supported."
        );

        _removeTokenFromUser(tokenAddress_);

        emit SBTAuthorizationRevoked(tokenAddress_, msg.sender);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function lock(
        address sender_,
        address tokenAddress_,
        uint256 amount_,
        uint256 timeToLock_
    ) public onlyUpdatePermission onlyEligibleUser(sender_) {
        require(
            timeToLock_ <= MAX_LOCKED_TIME + block.timestamp,
            "[QGDK-007002]-The lock time is too big."
        );

        if (isSupportedSBT(tokenAddress_)) {
            _SBTAuthorization(sender_, tokenAddress_);

            emit AuthenticatedBySBT(tokenAddress_, sender_);

            return;
        }

        if (isSupportedNFT(tokenAddress_)) {
            _lockNFT(sender_, tokenAddress_, timeToLock_);

            return;
        }

        require(amount_ > 0, "[QGDK-007003]-The amount to lock should be more than 0.");

        _lockTokens(sender_, tokenAddress_, amount_, timeToLock_);

        emit TokensLocked(tokenAddress_, sender_, amount_, timeToLock_);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function lockAndGetUserVotingPower(
        address userAddress_,
        address tokenAddress_,
        uint256 timeToLock_
    ) external virtual returns (uint256) {
        uint256 userVotingPower_ = getUserVotingPower(userAddress_, tokenAddress_);

        lock(userAddress_, tokenAddress_, userVotingPower_, timeToLock_);

        return userVotingPower_;
    }

    /**
     * @inheritdoc IDAOVault
     */
    function getUserVotingPower(
        address userAddress_,
        address tokenAddress_
    ) public view returns (uint256) {
        if (isSupportedSBT(tokenAddress_)) {
            return IERC721(tokenAddress_).balanceOf(userAddress_) != 0 ? 1 : 0;
        }

        if (isSupportedNFT(tokenAddress_)) {
            return _userNFTs[userAddress_][tokenAddress_].length() > 0 ? 1 : 0;
        }

        return userTokenBalance[userAddress_][tokenAddress_];
    }

    /**
     * @inheritdoc IDAOVault
     */
    function getTokenSupply(address tokenAddress_) external view virtual returns (uint256) {
        if (tokenAddress_ == ETHEREUM_ADDRESS) {
            return tokenBalance[tokenAddress_];
        }

        return IERC20(tokenAddress_).totalSupply();
    }

    /**
     * @inheritdoc IDAOVault
     */
    function getUserTokens(address userAddress_) external view returns (address[] memory) {
        return _userTokens[userAddress_].values();
    }

    /**
     * @inheritdoc IDAOVault
     */
    function getTimeLockInfo(
        address userAddress_,
        address tokenAddress_
    ) external view returns (TomeLockInfo memory info_) {
        uint256 userTokenBalance_ = userTokenBalance[userAddress_][tokenAddress_];

        (uint256 amount_, uint256 lastEndTime_) = lockedTokens[userAddress_][tokenAddress_]
            .getWithdrawalAmountAndEndTime(userTokenBalance_);

        info_.withdrawalAmount = amount_;
        info_.lockedAmount = userTokenBalance_ - amount_;
        info_.unlockTime = lastEndTime_;
    }

    /**
     * @inheritdoc IDAOVault
     */
    function getUserNFTs(
        address userAddress_,
        address tokenAddress_
    ) external view returns (uint256[] memory) {
        return _userNFTs[userAddress_][tokenAddress_].values();
    }

    /**
     * @inheritdoc IDAOVault
     */
    function getUserConstitutionData(
        address userAddress_
    ) external view returns (ConstitutionDataInfo memory) {
        return _constitutionData[userAddress_];
    }

    /**
     * @inheritdoc IDAOVault
     */
    function isAuthorizedBySBT(address sender_, address tokenAddress_) public view returns (bool) {
        if (isSupportedSBT(tokenAddress_) && IERC721(tokenAddress_).balanceOf(sender_) != 0) {
            return true;
        }

        return false;
    }

    /**
     * @inheritdoc IDAOVault
     */
    function isSupportedNFT(address tokenAddress_) public view returns (bool) {
        (, bytes memory data) = tokenAddress_.staticcall(abi.encodeWithSignature("totalSupply()"));

        return tokenAddress_.supportsInterface(type(IERC721).interfaceId) && data.length == 32;
    }

    /**
     * @inheritdoc IDAOVault
     */
    function isSupportedSBT(address tokenAddress_) public view returns (bool) {
        return
            isSupportedNFT(tokenAddress_) &&
            tokenAddress_.supportsInterface(type(IERC5484).interfaceId);
    }

    /**
     * @inheritdoc IDAOVault
     */
    function getConstitutionSignHash(address signer_) public view returns (bytes32) {
        DAORegistry daoRegistry_ = permissionManager.getDAORegistry();

        bytes32 constitutionHash_ = ConstitutionData.getConstitutionHash(daoRegistry_);

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        CONSTITUTION_SIGN_TYPEHASH,
                        address(daoRegistry_),
                        constitutionHash_,
                        signer_
                    )
                )
            );
    }

    function _deposit(
        address tokenAddress_,
        uint256 amount_
    ) internal onlyEligibleUser(msg.sender) {
        _userTokens[msg.sender].add(tokenAddress_);

        userTokenBalance[msg.sender][tokenAddress_] += amount_;
        tokenBalance[tokenAddress_] += amount_;

        permissionManager.addMemberToGroup(msg.sender, getDAOGroup(CONNECTED_DAO_REGISTRY));

        lockedTokens[msg.sender][tokenAddress_].purgeTimeLocks();

        emit TokensDeposited(tokenAddress_, msg.sender, amount_);
    }

    function _SBTAuthorization(address sender_, address tokenAddress_) internal {
        bool isUserHasSBT_ = IERC721(tokenAddress_).balanceOf(sender_) != 0;
        bool isUserHasSBTInVault_ = _userTokens[sender_].contains(tokenAddress_);

        if (isUserHasSBT_ && isUserHasSBTInVault_) {
            return;
        }

        if (!isUserHasSBT_) {
            revert("[QGDK-007006]-The user does not have the SBT token.");
        }

        _userTokens[sender_].add(tokenAddress_);
    }

    function _lockTokens(
        address sender_,
        address tokenAddress_,
        uint256 amount_,
        uint256 timeToLock_
    ) internal {
        require(
            userTokenBalance[sender_][tokenAddress_] >= amount_,
            "[QGDK-007007]-Not enough tokens to lock."
        );

        lockedTokens[sender_][tokenAddress_].purgeTimeLocks();
        lockedTokens[sender_][tokenAddress_].lock(amount_, timeToLock_);
    }

    function _lockNFT(address sender_, address tokenAddress_, uint256 timeToLock_) internal {
        require(_userNFTs[sender_][tokenAddress_].length() > 0, "[QGDK-007008]-No NFT to lock.");

        uint256 userTokenId_ = _userNFTs[sender_][tokenAddress_].at(0);
        lockedTokens[sender_][tokenAddress_].lockNFT(userTokenId_, timeToLock_);

        emit NFTLocked(tokenAddress_, sender_, userTokenId_, timeToLock_);
    }

    function _withdraw(address tokenAddress_, uint256 amount_) internal {
        require(
            lockedTokens[msg.sender][tokenAddress_].isAbleToWithdraw(
                userTokenBalance[msg.sender][tokenAddress_],
                amount_
            ),
            "[QGDK-007009]-Trying to withdraw more than locked."
        );

        require(
            userTokenBalance[msg.sender][tokenAddress_] >= amount_,
            "[QGDK-007010]-Not enough tokens to withdraw."
        );

        if (userTokenBalance[msg.sender][tokenAddress_] - amount_ == 0) {
            _removeTokenFromUser(tokenAddress_);
        }

        userTokenBalance[msg.sender][tokenAddress_] -= amount_;
        tokenBalance[tokenAddress_] -= amount_;

        lockedTokens[msg.sender][tokenAddress_].purgeTimeLocks();

        tokenAddress_.sendFunds(msg.sender, amount_);

        emit TokensWithdrew(tokenAddress_, msg.sender, amount_);
    }

    function _removeTokenFromUser(address tokenAddress_) internal {
        _userTokens[msg.sender].remove(tokenAddress_);

        if (_userTokens[msg.sender].length() == 0) {
            permissionManager.removeMemberFromGroup(
                msg.sender,
                getDAOGroup(CONNECTED_DAO_REGISTRY)
            );
        }
    }

    function _requirePermission(string memory permission_) internal view {
        require(
            permissionManager.hasPermission(msg.sender, DAO_VAULT_RESOURCE, permission_),
            "[QGDK-007011]-The sender is not allowed to perform the action, access denied."
        );
    }

    function _requireConstitutionSigned(address userAddress_) internal view {
        require(
            _isConstitutionSigned(userAddress_),
            "[QGDK-007014]-The user has not signed the constitution."
        );
    }

    function _signConstitution(address signer_) private {
        require(
            !_isConstitutionSigned(signer_),
            "[QGDK-007013]-The user already has the right to participate in the DAO governance."
        );

        _constitutionData[signer_].isSigned = true;
        _constitutionData[signer_].signedAt = uint128(block.timestamp);

        emit ConstitutionSigned(signer_);
    }

    function _isConstitutionSigned(address userAddress_) private view returns (bool) {
        DAORegistry registry_ = permissionManager.getDAORegistry();

        return
            _constitutionData[userAddress_].isSigned ||
            ConstitutionData.isConstitutionHashZero(registry_);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {IRBAC} from "@solarity/solidity-lib/interfaces/access-control/IRBAC.sol";
import {RBACGroupable} from "@solarity/solidity-lib/access-control/extensions/RBACGroupable.sol";
import {AbstractDependant} from "@solarity/solidity-lib/contracts-registry/AbstractDependant.sol";
import {IRBACGroupable} from "@solarity/solidity-lib/interfaces/access-control/extensions/IRBACGroupable.sol";

import {DAOVault} from "./DAOVault.sol";
import {DAORegistry} from "./DAORegistry.sol";
import {DAOMemberStorage} from "./DAOMemberStorage.sol";

import {IDAOResource} from "../interfaces/IDAOResource.sol";
import {IDAOIntegration} from "../interfaces/IDAOIntegration.sol";
import {IPermissionManager} from "../interfaces/IPermissionManager.sol";

import "../core/Globals.sol";

import {ArrayHelper} from "../libs/utils/ArrayHelper.sol";

/**
 * @title Permission Manager for DAO
 * @notice Implements a contract that manages permissions and roles within a DAO, based on RBAC (Role-Based Access Control) principles.
 *         It is a core component of the DAO, enabling the creation of roles, assignment of permissions to resources,
 *         and addition of specific users to groups.
 */
contract PermissionManager is IPermissionManager, ERC165, Multicall, RBACGroupable {
    using ArrayHelper for *;
    using Strings for uint256;

    using ERC165Checker for address;

    using EnumerableSet for EnumerableSet.AddressSet;

    string public PERMISSION_MANAGER_RESOURCE;

    EnumerableSet.AddressSet internal _existingVetoGroupTargets;

    // Maps a resource to its corresponding Veto Group
    mapping(string => VetoGroup) internal _vetoGroups;

    DAORegistry private _daoRegistry;

    modifier onlyAddGroupPermission() {
        _requirePermission(ADD_GROUP_PERMISSION);
        _;
    }

    modifier onlyUpdateGroupPermission() {
        _requirePermission(UPDATE_GROUP_PERMISSION);
        _;
    }

    modifier onlyDeleteGroupPermission() {
        _requirePermission(DELETE_GROUP_PERMISSION);
        _;
    }

    modifier onlyIntegrationPermission() {
        _requirePermission(INTEGRATION_PERMISSION);
        _;
    }

    modifier onlyUpdateMemberGroupPermission() {
        _requirePermission(UPDATE_MEMBER_GROUP_PERMISSION);
        _;
    }

    /**
     * @notice Initializes the Permission Manager contract.
     * @param daoRegistry_ The DAORegistry instance associated with this contract.
     * @param master_ The address that will be granted the MASTER_ROLE, enabling creation of roles and granting permissions.
     * @param resource_ The resource identifier associated with this Permission Manager.
     */
    function __PermissionManager_init(
        DAORegistry daoRegistry_,
        address master_,
        string memory resource_
    ) external initializer {
        __RBAC_init();
        _grantRoles(master_, MASTER_ROLE.asArray());

        PERMISSION_MANAGER_RESOURCE = resource_;

        setDAORegistry(daoRegistry_);
    }

    function setDAORegistry(DAORegistry daoRegistry_) public {
        require(
            address(_daoRegistry) == address(0),
            "[QGDK-008007]-The DAO Registry address already set."
        );

        _daoRegistry = daoRegistry_;
    }

    /**
     * @inheritdoc IDAOResource
     */
    function checkPermission(
        address account_,
        string memory permission_
    ) public view returns (bool) {
        return hasPermission(account_, PERMISSION_MANAGER_RESOURCE, permission_);
    }

    /**
     * @inheritdoc IDAOResource
     */
    function getResource() external view returns (string memory) {
        return PERMISSION_MANAGER_RESOURCE;
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function confExternalModule(string memory moduleName_) public onlyIntegrationPermission {
        require(
            _daoRegistry.hasContract(moduleName_),
            "[QGDK-008000]-The module not found in the DAO Registry."
        );

        address module_ = _daoRegistry.getContract(moduleName_);

        _validateModule(module_);

        IDAOIntegration.ResourceRecords[] memory records_ = IDAOIntegration(module_)
            .getResourceRecords();

        for (uint256 i = 0; i < records_.length; i++) {
            _addPermissionsToRole(
                records_[i].existingRole,
                records_[i].resource,
                records_[i].permissions,
                true
            );
        }
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function addVetoGroups(VetoGroup[] memory vetoGroups_) external onlyAddGroupPermission {
        for (uint256 i = 0; i < vetoGroups_.length; i++) {
            _addVetoGroup(vetoGroups_[i].target, vetoGroups_[i].linkedMemberStorage);
        }
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function addVetoGroup(
        address target_,
        DAOMemberStorage linkedMemberStorage_
    ) external onlyAddGroupPermission {
        _addVetoGroup(target_, linkedMemberStorage_);
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function removeVetoGroup(address target_) external onlyDeleteGroupPermission {
        string memory resource_ = IDAOResource(target_).getResource();

        require(
            _vetoGroups[resource_].target != address(0),
            "[QGDK-008002]-The veto group does not exists, impossible to remove it."
        );

        delete _vetoGroups[resource_];

        _existingVetoGroupTargets.remove(target_);

        emit VetoGroupRemoved(target_);
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function linkStorageToVetoGroup(
        address target_,
        DAOMemberStorage linkedMemberStorage_
    ) external onlyUpdateGroupPermission {
        _validateMemberStorage(linkedMemberStorage_);

        string memory resource_ = IDAOResource(target_).getResource();

        require(
            _vetoGroups[resource_].target != address(0),
            "[QGDK-008003]-The veto group does not exists, impossible to link it with member storage."
        );

        _vetoGroups[resource_].linkedMemberStorage = linkedMemberStorage_;

        emit LinkedStorageToVetoGroup(target_, address(linkedMemberStorage_));
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function addMemberToGroup(
        address member_,
        string[] memory groups_
    ) external onlyUpdateMemberGroupPermission {
        _addUserToGroups(member_, groups_);
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function removeMemberFromGroup(
        address member_,
        string[] memory groups_
    ) external onlyUpdateMemberGroupPermission {
        _removeUserFromGroups(member_, groups_);
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function getVetoGroupMembers(address target_) external view returns (address[] memory) {
        VetoGroup storage vetoGroup_ = _vetoGroups[IDAOResource(target_).getResource()];

        if (vetoGroup_.target == address(0)) {
            return new address[](0);
        }

        return vetoGroup_.linkedMemberStorage.getMembers();
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function getVetoMembersCount(address target_) external view returns (uint256) {
        VetoGroup storage vetoGroup_ = _vetoGroups[IDAOResource(target_).getResource()];

        if (vetoGroup_.target == address(0)) {
            return 0;
        }

        return vetoGroup_.linkedMemberStorage.getMembers().length;
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function getVetoGroupInfo(address target_) external view returns (VetoGroup memory) {
        return _vetoGroups[IDAOResource(target_).getResource()];
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function isVetoGroupExists(address target_) external view returns (bool) {
        return _vetoGroups[IDAOResource(target_).getResource()].target != address(0);
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function getExistingVetoGroupTargets() external view returns (address[] memory) {
        return _existingVetoGroupTargets.values();
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function isUserInVetoGroup(address target_, address member_) external view returns (bool) {
        VetoGroup storage vetoGroup_ = _vetoGroups[IDAOResource(target_).getResource()];

        if (vetoGroup_.target == address(0)) {
            return false;
        }

        return vetoGroup_.linkedMemberStorage.isMember(member_);
    }

    /**
     * @inheritdoc IPermissionManager
     */
    function getDAORegistry() external view returns (DAORegistry) {
        return _daoRegistry;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IPermissionManager).interfaceId ||
            interfaceId == type(IRBAC).interfaceId ||
            interfaceId == type(IRBACGroupable).interfaceId ||
            interfaceId == type(IDAOResource).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _addVetoGroup(address target_, DAOMemberStorage linkedMemberStorage_) internal {
        _validateTarget(target_);
        _validateMemberStorage(linkedMemberStorage_);

        string memory resource_ = IDAOResource(target_).getResource();

        require(
            _vetoGroups[resource_].target == address(0),
            "[QGDK-008004]-The veto group already exists."
        );

        _vetoGroups[resource_].target = target_;
        _vetoGroups[resource_].linkedMemberStorage = linkedMemberStorage_;

        _existingVetoGroupTargets.add(target_);

        emit VetoGroupAdded(target_, address(linkedMemberStorage_));
    }

    function _validateModule(address module_) internal view {
        require(
            module_.supportsInterface(type(IDAOIntegration).interfaceId),
            "[QGDK-008009]-The module does not support IDAOIntegration interface."
        );
    }

    function _validateTarget(address target_) internal view {
        require(
            target_.supportsInterface(type(IDAOResource).interfaceId),
            "[QGDK-008009]-The target does not support IDAOResource interface."
        );
    }

    function _validateMemberStorage(DAOMemberStorage linkedMemberStorage_) internal view {
        (bool success_, bytes memory result_) = address(linkedMemberStorage_).staticcall(
            abi.encodeWithSelector(linkedMemberStorage_.isMember.selector, address(0))
        );

        require(
            success_ && result_.length > 0,
            "[QGDK-008010]-The member storage does not have the isMember function."
        );

        (success_, result_) = address(linkedMemberStorage_).staticcall(
            abi.encodeWithSelector(linkedMemberStorage_.getMembers.selector)
        );

        require(
            success_ && result_.length > 0,
            "[QGDK-008011]-The member storage does not have the getMembers function."
        );
    }

    function _requirePermission(string memory permission_) private view {
        require(
            checkPermission(msg.sender, permission_),
            "[QGDK-008006]-The sender is not allowed to perform the action, access denied."
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @title IDAOIntegration
 * @notice Interface for DAO Integration
 *
 * This interface is used to integrate other modules with the existing DAO.
 */
interface IDAOIntegration {
    struct ResourceRecords {
        string existingRole;
        string resource;
        string[] permissions;
    }

    /**
     * @notice Function to integrate the module with the DAO.
     */
    function getResourceRecords() external view returns (ResourceRecords[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {IDAOResource} from "./IDAOResource.sol";
import {ISubmitSignature} from "./ISubmitSignature.sol";

import {ParameterSet} from "../libs/data-structures/ParameterSet.sol";

/**
 * @title IDAOMemberStorage
 * @notice Interface for a contract that stores and manages members of a DAO panel.
 */
interface IDAOMemberStorage is IDAOResource, ISubmitSignature {
    event MemberAdded(address indexed member, string group);

    event MemberRemoved(address indexed member, string group);

    /**
     * @notice Adds a single member to the DAO.
     * This function can only be called by an account possessing the CREATE_PERMISSION permission.
     *
     * @param member_ The address of the member to add.
     *
     * @dev When a member is added to this list, they are considered an Expert and given the ability to
     * veto or participate in restricted voting.
     */
    function addMember(address member_) external;

    /**
     * @notice Submits a signature for a member to be added to the DAO.
     * This function can only be called by an account possessing the CREATE_PERMISSION permission.
     *
     * The submitted signature is valid only within the block.number in which it was submitted.
     *
     * @param signer_ The address of the member to be added.
     * @param signature_ The EIP-712 compliant signature provided by the member.
     * @param nonce_ An entropy source to prevent replay attacks.
     *
     * @dev
     * - The signature is based on EIP-712, a standard for hashing and signing typed structured data,
     *   which requires a domain separator and a hash of the typed data.
     * - This contract utilizes the `_hashTypedDataV4` function to obtain the message digest,
     *   which is then signed via ECDSA according to the EIP-712 encoding scheme.
     * - After verifying the signature's validity, the function adds the member to the DAO if the verification is successful.
     */
    function submitSignature(address signer_, bytes memory signature_, bytes32 nonce_) external;

    /**
     * @notice Removes a single member from the DAO, including automatic removal from the experts group.
     * @param member_ The address of the member to be removed.
     */
    function removeMember(address member_) external;

    /**
     * @notice Removes multiple members from the DAO.
     * @param members_ An array of member addresses to remove.
     */
    function removeMembers(address[] calldata members_) external;

    /**
     * @notice Returns an EIP-712 domain-specific hash for a candidate, important for DAO membership
     * verification when applying to the targeted Expert Panel.
     */
    function getCandidateHash(address candidate_, bytes32 nonce_) external view returns (bytes32);

    /**
     * @notice Gets the message in string format that the expert must sign to become a member of the DAO.
     */
    function getMessage() external view returns (string memory);

    /**
     * @notice Checks if an address is a member of the DAO.
     * @param member_ The address to check.
     * @return true if the address is a member of the DAO, false otherwise.
     */
    function isMember(address member_) external view returns (bool);

    /**
     * @notice Returns an array of all members of the DAO.
     * @return An array of all members of the DAO.
     */
    function getMembers() external view returns (address[] memory);

    /**
     * @notice Returns the number of members in the DAO.
     * @return The number of members in the DAO.
     */
    function getMembersCount() external view returns (uint256);

    /**
     * @notice Returns to which group this contract belongs.
     */
    function getGroup() external view returns (string[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Parameter} from "../libs/data-structures/ParameterSet.sol";

import {IDAOResource} from "./IDAOResource.sol";

/**
 * @title IDAOParameterStorage
 * @notice An interface for contracts that store and manage parameters for a DAO.
 * This interface defines functionalities for setting, retrieving, and removing various DAO parameters.
 */
interface IDAOParameterStorage is IDAOResource {
    /**
     * @notice Emitted when a new DAO parameter is added.
     * @param parameter The parameter that was added, including all its details.
     */
    event ParameterAdded(Parameter parameter);

    /**
     * @notice Emitted when an existing DAO parameter is changed.
     * @param parameter The updated parameter, including all its new details.
     */
    event ParameterChanged(Parameter parameter);

    /**
     * @notice Emitted when a DAO parameter is removed.
     * @param parameterName The name of the parameter that was removed.
     */
    event ParameterRemoved(string parameterName);

    /**
     * @notice Indicates that the specified DAO parameter was not found in the storage.
     * This error is used in functions that require the existence of a parameter, such as retrieving,
     * or removing a specific parameter.
     * @param parameterName The name of the DAO parameter that was not found.
     */
    error DAOParameterStorage__ParameterNotFound(string parameterName);

    /**
     * @notice Sets a single DAO parameter.
     * @dev If the parameter already exists, it will be updated with the new value.
     * @param parameter_ The parameter to set or change
     */
    function setDAOParameter(Parameter memory parameter_) external;

    /**
     * @notice Sets multiple DAO parameters.
     * @dev Existing parameters will be updated with new values.
     * @param parameters_ An array of parameters to set or change
     */
    function setDAOParameters(Parameter[] memory parameters_) external;

    /**
     * @notice Removes a specific DAO parameter identified by its name.
     * @dev Will revert if parameter does not exist.
     * @param parameterName_ The name of the parameter to remove.
     */
    function removeDAOParameter(string memory parameterName_) external;

    /**
     * @notice Removes multiple DAO parameters identified by their names.
     * @dev Will revert if one of the parameters does not exist.
     * @param parameterNames_ An array of parameter names to remove.
     */
    function removeDAOParameters(string[] memory parameterNames_) external;

    /**
     * @notice Returns a single DAO parameter.
     * @dev Will revert if parameter does not exist.
     * @param parameterName_ The name of the parameter to retrieve.
     * @return The specified DAO parameter.
     */
    function getDAOParameter(
        string memory parameterName_
    ) external view returns (Parameter memory);

    /**
     * @notice Returns all DAO parameters.
     * @return An array of all DAO parameters.
     */
    function getDAOParameters() external view returns (Parameter[] memory);

    /**
     * @notice Checks if a specific DAO parameter exists.
     * @param parameterName_ The name of the parameter to check.
     * @return A boolean indicating whether the parameter exists.
     */
    function hasDAOParameter(string memory parameterName_) external view returns (bool);

    /**
     * @notice Retrieves a DAO parameter by its index in the storage.
     * @dev This function is useful for iterating over all parameters when the total count is known.
     * @param index_ The index of the parameter in the storage array.
     * @return The DAO parameter at the specified index.
     */
    function getParameterByIndex(uint256 index_) external view returns (Parameter memory);

    /**
     * @notice Returns the total number of DAO parameters currently stored.
     * @return The total count of DAO parameters.
     */
    function getParametersCount() external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {IDAOResource} from "./IDAOResource.sol";

/**
 * @title IDAORegistry
 * @notice Interface for the DAO Registry, managing panels, and contract addresses within the DAO.
 */
interface IDAORegistry is IDAOResource {
    /**
     * @dev Represents the status of an account within the DAO.
     * @param groups An array of group names to which the account may belong.
     * @param isMember An array of boolean values indicating membership status in corresponding groups.
     */
    struct AccountStatus {
        string[] groups;
        bool[] isMember;
    }

    /**
     * @dev Represents an entry in the DAO Registry.
     * @param name The name of the resource or contract.
     * @param address_ The address of the resource or contract.
     */
    struct RegistryEntry {
        string name;
        address address_;
    }

    /**
     * @notice Emitted when the DAO Registry is initialized.
     * @param master The address of the master contract or administrator initializing the DAO.
     * @param daoURI The URI containing metadata or additional information about the DAO.
     *
     * @dev The master account will be granted the `MASTER_ROLE` role in the DAO.
     */
    event Initialized(address master, string daoURI);

    /**
     * @notice Emitted when a new panel is added to the DAO.
     * @param panelName The name of the panel that has been added.
     */
    event PanelAdded(string panelName);

    /**
     * @notice Emitted when a panel is removed from the DAO.
     * @param panelName The name of the panel that has been removed.
     */
    event PanelRemoved(string panelName);

    /**
     * @notice Adds a new panel to the DAO.
     * @param panelName_ The name of the panel to be added.
     *
     * @dev Reverts if the panel already exists in the DAO.
     */
    function addPanel(string memory panelName_) external;

    /**
     * @notice Removes a panel from the DAO.
     * @param panelName_ The name of the panel to be removed.
     *
     * @dev Reverts if the panel does not exist in the DAO.
     * Deleting a panel and then calling `deployDAOPanel` from `MasterDAOFactory`
     * will overwrite old contract addresses in the DAORegistry with new ones, making
     * it nearly impossible to restore the old contracts.
     */
    function removePanel(string memory panelName_) external;

    /**
     * @notice Deploys a new TransparentUpgradeableProxy through Create2 and adds it to the DAO Registry.
     * @param name_ The name of the contract to add.
     * @param salt_ The salt to use for the Create2 deployment.
     * @param contractAddress_ The address of the contract to add.
     * @param data_ The data to call the contract with.
     */
    function addDeterministicProxy(
        string memory name_,
        bytes32 salt_,
        address contractAddress_,
        bytes memory data_
    ) external;

    /**
     * @notice Returns the list of panels in the DAO.
     *
     * @dev Manual creation of a panel (not through `deployDAOPanel`) may cause issues.
     */
    function getPanels() external view returns (string[] memory);

    /**
     * @notice Provides a list of contract names and addresses in the DAO Registry.
     */
    function getRegistryContractAddresses() external view returns (RegistryEntry[] memory);

    /**
     * @notice Checks if a new panel can be added without exceeding the limit.
     * @dev It accounts for the Reserved Panel by default.
     * @return bool True if a new panel can be added, false otherwise.
     */
    function isAbleToAddPanel() external view returns (bool);

    /**
     * @notice Retrieves account statuses in the DAO.
     * @param account_ The account to check statuses for.
     * @return status The status of the account in the DAO.
     */
    function getAccountStatuses(
        address account_
    ) external view returns (AccountStatus memory status);

    /**
     * @notice Gets the address of the configuration parameter storage contract for
     * a specific DAO panel.
     * @param panelName_ The name of the panel for which to get the parameter storage contract address.
     * @return address The address of the parameter storage contract for the specified DAO panel.
     *
     * @dev Stores parameters such as votingPeriod, vetoPeriod, etc.
     */
    function getConfDAOParameterStorage(string memory panelName_) external view returns (address);

    /**
     * @notice Retrieves the address of the regular experts parameter storage contract for
     * a specific DAO panel.
     * @param panelName_ The name of the panel for which to get the parameter storage contract address.
     * @return address The address of the parameter storage contract for the specified DAO panel.
     *
     * @dev Only experts can typically change parameters in this storage.
     */
    function getRegDAOParameterStorage(string memory panelName_) external view returns (address);

    /**
     * @notice Gets the address of the member storage contract for a specific DAO panel.
     * @param panelName_ The name of the panel for which to get the member storage contract address.
     * @return address The address of the member storage contract for the specified DAO panel.
     */
    function getDAOMemberStorage(string memory panelName_) external view returns (address);

    /**
     * @notice Retrieves the address of the general voting contract for a specific DAO panel.
     * @param panelName_ The name of the panel for which to get the voting contract address.
     * @return address The address of the general voting contract for the specified DAO panel.
     */
    function getGeneralDAOVoting(string memory panelName_) external view returns (address);

    /**
     * @notice Retrieves the address of the experts voting contract for a specific DAO panel.
     * @param panelName_ The name of the panel for which to get the voting contract address.
     * @return address The address of the experts voting contract for the specified DAO panel.
     */
    function getExpertsDAOVoting(string memory panelName_) external view returns (address);

    /**
     * @notice Retrieves the address of the vault contract for the DAO.
     * @return address The address of the vault contract for the DAO.
     */
    function getDAOVault() external view returns (address);

    /**
     * @notice Retrieves the Protocol Version of the DAO.
     */
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @title IDAOResource
 * @notice Interface for a contract that serves as a resource within a DAO.
 *
 * This interface should be implemented by contracts that are designated as resources within a DAO,
 * and upon which DAO voting could potentially occur.
 */
interface IDAOResource {
    /**
     * @notice Checks if an account has permission to perform a specific action on a contract implementing this interface.
     * @param member_ The account address whose permission is to be checked.
     * @param permission_ The specific permission to check for.
     * @return bool True if the account has the specified permission, false otherwise.
     *
     * @dev This function enables the verification of permissions for accounts in relation to the DAO resource.
     */
    function checkPermission(
        address member_,
        string calldata permission_
    ) external view returns (bool);

    /**
     * @notice Retrieves the resource name for the contract implementing this interface.
     * @return string The name of the resource.
     *
     * @dev This function provides the identifier for the DAO resource represented by the contract.
     */
    function getResource() external view returns (string memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {IDAORegistry} from "./IDAORegistry.sol";

/**
 * @title IDAOVault
 * @dev Interface for a vault contract that stores and manages tokens for a DAO.
 * Allows operations with ERC20, ERC721, Native tokens, and Soulbound Tokens (SBT).
 */
interface IDAOVault {
    /**
     * @dev Struct representing the signing status and timestamp of the DAO constitution by a user.
     * @param isSigned Indicates whether the constitution is signed by the user.
     * @param signedAt Timestamp when the constitution was signed.
     */
    struct ConstitutionDataInfo {
        bool isSigned;
        uint128 signedAt;
    }

    /**
     * @dev Struct providing information about token time locks.
     * @param withdrawalAmount Amount available for withdrawal.
     * @param lockedAmount Amount currently locked.
     * @param unlockTime Timestamp when the tokens will be unlocked.
     */
    struct TomeLockInfo {
        uint256 withdrawalAmount;
        uint256 lockedAmount;
        uint256 unlockTime;
    }

    event TokensDeposited(address indexed tokenAddress, address indexed sender, uint256 amount);
    event NFTDeposited(address indexed tokenAddress, address indexed sender, uint256 tokenId);
    event AuthorizedBySBT(address indexed tokenAddress, address indexed sender);

    event TokensLocked(
        address indexed tokenAddress,
        address indexed sender,
        uint256 amount,
        uint256 unlockTime
    );
    event NFTLocked(
        address indexed tokenAddress,
        address indexed sender,
        uint256 tokenId,
        uint256 unlockTime
    );
    event AuthenticatedBySBT(address indexed tokenAddress, address indexed sender);

    event TokensWithdrew(address indexed tokenAddress, address indexed sender, uint256 amount);
    event NFTWithdrew(address indexed tokenAddress, address indexed sender, uint256 tokenId);
    event SBTAuthorizationRevoked(address indexed tokenAddress, address indexed sender);

    event ConstitutionSigned(address indexed user);

    /**
     * @notice Allows a user to sign the DAO constitution with their signature.
     * @param signer_ The address of the user signing the constitution.
     * @param signature_ The user's digital signature of the constitution.
     */
    function signConstitution(address signer_, bytes calldata signature_) external;

    /**
     * @dev Deposits Native tokens to the vault.
     */
    function depositNative() external payable;

    /**
     * @dev Deposits ERC20 and Native tokens to the vault.
     * @param tokenAddress_ The address of the ERC20 token to deposit.
     * @param amount_ The amount of ERC20 tokens to deposit.
     */
    function depositERC20(address tokenAddress_, uint256 amount_) external;

    /**
     * @dev Deposits ERC721 tokens to the vault.
     * @param tokenAddress_ The address of the ERC721 token to deposit.
     * @param tokenId_ The id of the ERC721 token to deposit.
     */
    function depositNFT(address tokenAddress_, uint256 tokenId_) external;

    /**
     * @dev Authorizes the user with DAO Token Holder role with SBT token.
     * @param tokenAddress_ The address of the SBT to authorize.
     */
    function authorizeBySBT(address tokenAddress_) external;

    /**
     * @dev Locks and Native tokens in the vault for a specified time period.
     * @param sender_ The address of the account sending the tokens to be locked.
     * @param tokenAddress_ The address of the token to lock.
     * @param amount_ The amount of tokens to lock.
     * @param timeToLock_ The time period for which the tokens should be locked.
     *
     * ERC165 standard is used to identify other token types.
     */
    function lock(
        address sender_,
        address tokenAddress_,
        uint256 amount_,
        uint256 timeToLock_
    ) external;

    /**
     * @notice Locks tokens for a specified period and retrieves the user's voting power.
     * @dev Locks the user's tokens and calculates their voting power based on the locked amount.
     *      The voting power calculation varies depending on the token type: standard tokens, supported NFTs, or supported SBTs.
     * @param userAddress_ The address of the user whose tokens are to be locked.
     * @param tokenAddress_ The address of the token contract.
     * @param timeToLock_ The period for which the tokens should be locked. This time must not exceed the maximum allowed lock time.
     * @return uint256 The voting power of the user after locking the tokens.
     */
    function lockAndGetUserVotingPower(
        address userAddress_,
        address tokenAddress_,
        uint256 timeToLock_
    ) external returns (uint256);

    /**
     * @dev Withdraws Native tokens from the vault.
     * @param amount_ The amount of Q tokens to withdraw.
     */
    function withdrawNative(uint256 amount_) external;

    /**
     * @dev Withdraws ERC20 and Native tokens from the vault.
     * @param tokenAddress_ The address of the token to withdraw.
     * @param amount_ The amount of tokens to withdraw.
     */
    function withdrawERC20(address tokenAddress_, uint256 amount_) external;

    /**
     * @dev Withdraws ERC721 tokens from the vault.
     * @param tokenAddress_ The address of the token to withdraw.
     * @param tokenId_ The id of the token to withdraw.
     */
    function withdrawNFT(address tokenAddress_, uint256 tokenId_) external;

    /**
     * @dev Revokes the authorization of a SBT.
     * @param tokenAddress_ The address of the token that was used for the authorization.
     */
    function revokeSBTAuthorization(address tokenAddress_) external;

    /**
     * @notice Returns the total supply of a given token.
     * @param tokenAddress_ The address of the token.
     * @return The total supply of the token.
     */
    function getTokenSupply(address tokenAddress_) external view returns (uint256);

    /**
     * @notice Returns the voting power of a user for a specific token.
     * @param userAddress_ The address of the user.
     * @param tokenAddress_ The address of the token.
     * @return The user's voting power in the DAO.
     */
    function getUserVotingPower(
        address userAddress_,
        address tokenAddress_
    ) external view returns (uint256);

    /**
     * @notice Returns the list of tokens held by a user in the DAO.
     * @param userAddress_ The address of the user.
     * @return An array of addresses representing the tokens held by the user.
     */
    function getUserTokens(address userAddress_) external view returns (address[] memory);

    /**
     * @notice Provides time lock information for a specific user and token.
     * Info for NFT and SBT tokens is not provided.
     * @param userAddress_ The address of the user.
     * @param tokenAddress_ The address of the token.
     * @return info_ A `TomeLockInfo` struct containing time lock details.
     */
    function getTimeLockInfo(
        address userAddress_,
        address tokenAddress_
    ) external view returns (TomeLockInfo memory info_);

    /**
     * @notice Returns the list of NFTs held by a user in the DAO.
     * @param userAddress_ The address of the user.
     * @param tokenAddress_ The address of the NFT contract.
     * @return An array of token IDs representing the NFTs held by the user.
     */
    function getUserNFTs(
        address userAddress_,
        address tokenAddress_
    ) external view returns (uint256[] memory);

    /**
     * @notice Retrieves the constitution data for a given user.
     * @param userAddress_ The address of the user.
     * @return The constitution data for the user.
     */
    function getUserConstitutionData(
        address userAddress_
    ) external view returns (ConstitutionDataInfo memory);

    /**
     * @notice Checks if a user is authorized by a specific SBT.
     * @param sender_ The address of the user.
     * @param tokenAddress_ The address of the SBT contract.
     * @return True if the user is authorized, false otherwise.
     */
    function isAuthorizedBySBT(
        address sender_,
        address tokenAddress_
    ) external view returns (bool);

    /**
     * @notice Determines if a token address supports NFT standards.
     * @param tokenAddress_ The address of the token contract.
     * @return True if the token supports NFT standards, false otherwise.
     */
    function isSupportedNFT(address tokenAddress_) external view returns (bool);

    /**
     * @notice Determines if a token address supports SBT standards in addition to NFT standards.
     * @param tokenAddress_ The address of the token contract.
     * @return True if the token supports SBT and NFT standards, false otherwise.
     */
    function isSupportedSBT(address tokenAddress_) external view returns (bool);

    /**
     * @notice Returns an EIP-712 domain-specific hash for a constitution hash, crucial for verifying
     DAO membership when initiating interactions with the DAO.
     */
    function getConstitutionSignHash(address signer_) external view returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {StringSet} from "@solarity/solidity-lib/libs/data-structures/StringSet.sol";

import {IDAOResource} from "./IDAOResource.sol";

import {DAOVault} from "../DAO/DAOVault.sol";
import {DAORegistry} from "../DAO/DAORegistry.sol";
import {DAOMemberStorage} from "../DAO/DAOMemberStorage.sol";
import {PermissionManager} from "../DAO/PermissionManager.sol";
import {DAOParameterStorage} from "../DAO/DAOParameterStorage.sol";

enum VotingType {
    NON_RESTRICTED,
    RESTRICTED,
    PARTIALLY_RESTRICTED
}

/**
 * @notice Represents the storage structure specifically for Experts DAO Voting.
 * @dev This struct acts as a helper data structure for libraries that extend the functionality of DAO Voting.
 *      In terms of storage layout, it follows after the GeneralDAOVotingStorage.
 *      Given that Initializable occupies slot 0 and GeneralDAOVotingStorage spans slots 1 to 13,
 *      this structure starts from slot 14.
 */
struct ExpertsDAOVotingStorage {
    DAOMemberStorage daoMemberStorage;
}

uint256 constant EXPERTS_DAO_VOTING_STORAGE = 14;

/**
 * @notice Represents the general storage structure for DAO Voting.
 * @dev This struct serves as a helper data structure used by libraries extending DAO Voting functionality.
 *      It follows the storage layout convention where the storage begins after the Initializable contract,
 *      occupying the next available slot.
 *      Initializable occupies slot 0, thus this structure starts from slot 1.
 */
// prettier-ignore
struct GeneralDAOVotingStorage {
    string DAO_VOTING_RESOURCE;

    string targetPanel;

    address votingToken;

    uint256 proposalCount;

    DAOVault daoVault;
    DAORegistry daoRegistry;
    PermissionManager permissionManager;
    DAOParameterStorage daoParameterStorage;

    StringSet.Set _votingSituations;

    mapping(uint256 => IDAOVoting.DAOProposal) proposals;
    mapping(uint256 => mapping(address => bool)) hasUserVoted;
    mapping(uint256 => mapping(address => bool)) hasUserVetoed;
}

/**
 * @notice Represents the storage structure for an external link in DAO Voting.
 * @dev This struct adds the capability to store external links related to DAO Voting situations.
 *      It utilizes a specific storage slot determined by the keccak256 hash of the string "extended.storage".
 *      The storage slot for this structure is 0x69ff26ae7567e3e590df6e0174c58cf39f6d291d404355c047056a744cc2c456,
 *      ensuring a fixed and predictable location in the contract's storage layout.
 */
struct ExtendedStorage {
    mapping(uint256 => string) proposalSituationLink;
}

// keccak256("extended.storage")
bytes32 constant EXTENDED_STORAGE = 0x69ff26ae7567e3e590df6e0174c58cf39f6d291d404355c047056a744cc2c456;

function getExtendedStorage() pure returns (ExtendedStorage storage $) {
    assembly {
        $.slot := EXTENDED_STORAGE
    }
}

/**
 * @title IDAOVoting
 * @notice Interface for managing voting and proposals within a DAO.
 */
interface IDAOVoting is IDAOResource {
    enum ProposalStatus {
        NONE,
        PENDING,
        REJECTED,
        ACCEPTED,
        PASSED,
        EXECUTED,
        EXPIRED,
        UNDER_REVIEW,
        UNDER_EVALUATION,
        UNDEFINED
    }

    enum VotingOption {
        NONE,
        FOR,
        AGAINST
    }

    /**
     * @dev Stores the configuration values for a DAO voting situation.
     * @param votingPeriod Duration of the voting period.
     * @param vetoPeriod Duration of the veto period.
     * @param proposalExecutionPeriod Time allowed for executing a proposal after it is passed.
     * @param requiredQuorum Minimum number of votes needed for a proposal to be considered valid.
     * @param requiredMajority Minimum number of votes needed for a proposal to be accepted.
     * @param requiredVetoQuorum Minimum number of vetoes needed for a proposal to be rejected.
     * @param votingType The type of voting (e.g., restricted, non-restricted).
     * @param votingTarget Target of the voting, often specifying the group or area affected by the vote.
     * @param votingMinAmount Minimum amount of tokens/units required to participate in the voting.
     */
    struct DAOVotingValues {
        uint256 votingPeriod;
        uint256 vetoPeriod;
        uint256 proposalExecutionPeriod;
        uint256 requiredQuorum;
        uint256 requiredMajority;
        uint256 requiredVetoQuorum;
        uint256 votingType;
        string votingTarget;
        uint256 votingMinAmount;
    }

    /**
     * @dev Represents an initial configuration for a DAO voting situation.
     * @param votingSituationName Name of the voting situation.
     * @param votingValues Configuration values for the voting situation, represented by a DAOVotingValues struct.
     */
    struct InitialSituation {
        string votingSituationName;
        DAOVotingValues votingValues;
    }

    /**
     * @dev Extends the InitialSituation struct to include an external link, providing additional context or information.
     * @param initialSituation The initial situation, represented by an InitialSituation struct.
     * @param externalLink A URI providing additional information about the voting situation.
     */
    struct ExtendedSituation {
        InitialSituation initialSituation;
        string externalLink;
    }

    /**
     * @dev Stores parameters for a specific voting instance within a DAO.
     * @param votingType Type of voting (e.g., restricted, non-restricted).
     * @param votingStartTime Timestamp for the start of the voting period.
     * @param votingEndTime Timestamp for the end of the voting period.
     * @param vetoEndTime Timestamp for the end of the veto period.
     * @param proposalExecutionPeriod Time allowed for executing a proposal after it is passed.
     * @param requiredQuorum Minimum number of votes needed for a proposal to be considered valid.
     * @param requiredMajority Minimum number of votes needed for a proposal to be accepted.
     * @param requiredVetoQuorum Minimum number of vetoes needed for a proposal to be rejected.
     */
    struct VotingParams {
        VotingType votingType;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 vetoEndTime;
        uint256 proposalExecutionPeriod;
        uint256 requiredQuorum;
        uint256 requiredMajority;
        uint256 requiredVetoQuorum;
    }

    /**
     * @dev Represents the counters for voting activities on a DAO proposal.
     * @param votedFor The total number of votes cast in favor of the proposal.
     * @param votedAgainst The total number of votes cast against the proposal.
     * @param vetoesCount The total number of vetoes exercised against the proposal.
     */
    struct VotingCounters {
        uint256 votedFor;
        uint256 votedAgainst;
        uint256 vetoesCount;
    }

    /**
     * @dev Contains the statistical data relevant to the voting process of a DAO proposal.
     * @param requiredQuorum The minimum number of votes required for the proposal to be considered valid.
     * @param currentQuorum The current number of votes that have been cast on the proposal.
     * @param requiredMajority The minimum number of votes required for the proposal to be accepted.
     * @param currentMajority The current number of votes in favor of the proposal.
     * @param currentVetoQuorum The current number of vetoes exercised against the proposal.
     * @param requiredVetoQuorum The minimum number of vetoes required for the proposal to be rejected.
     */
    struct VotingStats {
        uint256 requiredQuorum;
        uint256 currentQuorum;
        uint256 requiredMajority;
        uint256 currentMajority;
        uint256 currentVetoQuorum;
        uint256 requiredVetoQuorum;
    }

    /**
     * @dev Represents a proposal within the DAO.
     * @param id The unique identifier of the proposal.
     * @param remark A brief description or title of the proposal.
     * @param relatedExpertPanel The name of the expert panel related to the proposal.
     * @param relatedVotingSituation The name of the voting situation to which the proposal is related.
     * @param callData The bytecode to be executed when the proposal is passed.
     * @param target The address of the contract to which the callData will be sent if the proposal is passed.
     * @param params The voting parameters associated with the proposal.
     * @param counters The voting counters for the proposal.
     * @param executed A boolean flag indicating whether the proposal has been executed.
     */
    struct DAOProposal {
        uint256 id;
        string remark;
        string relatedExpertPanel;
        string relatedVotingSituation;
        bytes callData;
        address target;
        VotingParams params;
        VotingCounters counters;
        bool executed;
    }

    /**
     * @notice Emitted when a new proposal is created in the DAO.
     * @param id The unique identifier of the newly created proposal.
     * @param proposal A DAOProposal struct containing details about the proposal.
     */
    event ProposalCreated(uint256 indexed id, DAOProposal proposal);

    /**
     * @notice Emitted when a user casts a vote on a proposal.
     * @param id The unique identifier of the proposal being voted on.
     * @param voter The address of the user who cast the vote.
     * @param votingPower The amount of voting power the user had when casting the vote.
     * @param option The voting option chosen by the user, represented as an integer (e.g., 1 for 'FOR', 2 for 'AGAINST').
     */
    event UserVoted(uint256 indexed id, address indexed voter, uint256 votingPower, uint8 option);

    /**
     * @notice Emitted when a user vetoes a proposal.
     * @param id The unique identifier of the proposal being vetoed.
     * @param voter The address of the user who casted the veto.
     */
    event UserVetoed(uint256 indexed id, address indexed voter);

    /**
     * @notice Emitted when a proposal is executed.
     * @param id The unique identifier of the proposal that has been executed.
     */
    event ProposalExecuted(uint256 indexed id);

    /**
     * @notice Creates a new voting situation for the DAO. This situation serves as an interface
     * to interact with any Smart Contract implementing the IDAOResource interface.
     *
     * @dev Deprecated in favor of createDAOVotingSituationWithLink.
     *
     * @param conf_ Configuration parameters for the initial voting situation, encapsulated
     * in an IDAOVoting.InitialSituation struct.
     */
    function createDAOVotingSituation(IDAOVoting.InitialSituation memory conf_) external;

    /**
     * @notice Creates a new voting situation for the DAO with an associated external link,
     * serving as an interface to interact with any Smart Contract implementing the IDAOResource interface.
     * The external link provides additional details such as the ABI and other specifications of the voting situation.
     *
     * @param conf_ Configuration parameters for the extended voting situation,
     * including the external link, encapsulated in an IDAOVoting.ExtendedSituation struct.
     */
    function createDAOVotingSituationWithLink(IDAOVoting.ExtendedSituation memory conf_) external;

    /**
     * @notice Removes a specified voting situation from the DAO, also removing associated voting
     * situation parameters.
     * @param situation_ The name of the voting situation to be removed.
     */
    function removeVotingSituation(string memory situation_) external;

    /**
     * @notice Retrieves a list of all currently available voting situations within the DAO.
     * @return An array of strings, each representing the name of a voting situation.
     */
    function getVotingSituations() external view returns (string[] memory);

    /**
     * @notice Retrieves information about a specific voting situation within the DAO.
     * @dev Deprecated in favor of getVotingSituationInfoWithLink.
     * @param situation_ The name of the voting situation for which information is requested.
     * @return DAOVotingValues struct containing various parameters and settings of the specified voting situation.
     */
    function getVotingSituationInfo(
        string calldata situation_
    ) external view returns (DAOVotingValues memory);

    /**
     * @notice Retrieves information about a specific voting situation within the DAO,
     * including its associated external link. The external link provides additional details such
     * as the ABI and other specifications of the voting situation.
     * @param situation_ The name of the voting situation for which information is requested.
     * @return A tuple containing DAOVotingValues struct and a string representing the external
     * link associated with the specified voting situation.
     */
    function getVotingSituationInfoWithLink(
        string calldata situation_
    ) external view returns (DAOVotingValues memory, string memory);

    /**
     * @notice Retrieves the external link associated with a specified voting situation in the DAO.
     * @param situation_ The name of the voting situation for which the external link is requested.
     * @return A string representing the external link of the specified voting situation.
     */
    function getVotingSituationExternalLink(
        string calldata situation_
    ) external view returns (string memory);

    /**
     * @notice Creates a new proposal in the DAO associated with a specific voting situation.
     * @param situation_ The name of the voting situation under which the proposal is created.
     * @param remark_ A brief description or title of the proposal.
     * @param callData_ The data that will be passed to the target contract when the proposal is executed.
     * @return The unique ID of the newly created proposal.
     */
    function createProposal(
        string calldata situation_,
        string calldata remark_,
        bytes calldata callData_
    ) external returns (uint256);

    /**
     * @notice Casts a vote in favor of a proposal identified by its unique ID.
     * @param proposalId_ The ID of the proposal to vote for.
     */
    function voteFor(uint256 proposalId_) external;

    /**
     * @notice Casts a vote against a proposal identified by its unique ID.
     * @param proposalId_ The ID of the proposal to vote against.
     */
    function voteAgainst(uint256 proposalId_) external;

    /**
     * @notice Vetoes a proposal, identified by its unique ID, within the DAO.
     * @param proposalId_ The ID of the proposal to veto.
     */
    function veto(uint256 proposalId_) external;

    /**
     * @notice Executes a proposal identified by its unique ID within the DAO.
     * @param proposalId_ The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId_) external;

    /**
     * @notice Executes a proposal identified by its unique ID within the DAO, providing the ability to pass a signature along with proposal data.
     * @param proposalId_ The unique identifier of the proposal to be executed.
     * @param signature_ The signature associated with the proposal data.
     *
     * @dev This function reverts if the signature is not exactly 65 bytes long. Additionally, it prepends a nonce to the signature. The nonce is used to ensure the uniqueness and security of the signature, guarding against replay attacks and other potential security risks. This operation is crucial for maintaining the integrity of the proposal execution process.
     */
    function executeProposalWithSignature(uint256 proposalId_, bytes memory signature_) external;

    /**
     * @notice Retrieves detailed information about a specific proposal by its ID.
     * @param proposalId_ The ID of the proposal to retrieve.
     * @return A DAOProposal struct containing detailed information about the proposal.
     */
    function getProposal(uint256 proposalId_) external view returns (DAOProposal memory);

    /**
     * @notice Returns an external link associated with a specific proposal.
     * @param proposalId_ The ID of the proposal for which to retrieve the external link.
     * @return A string representing the external link of the specified proposal.
     */
    function proposalSituationLink(uint256 proposalId_) external view returns (string memory);

    /**
     * @notice Retrieves a list of proposals within the DAO, starting from a specified offset and up to a specified limit.
     * @param offset_ The starting index from which to retrieve proposals. If set to 0, retrieval starts from the most recent proposal.
     * @param limit_ The maximum number of proposals to retrieve.
     * @return An array of DAOProposal structs, representing the retrieved proposals.
     */
    function getProposalList(
        uint256 offset_,
        uint256 limit_
    ) external view returns (DAOProposal[] memory);

    /**
     * @notice Retrieves a list of external links associated with different proposals,
     * starting from a specified offset and up to a specified limit.
     * @param offset_ The starting index from which to retrieve proposal links.
     * @param limit_ The maximum number of proposal links to retrieve.
     * @return An array of strings, each representing the external link of a proposals.
     */
    function getProposalSituationLinkList(
        uint256 offset_,
        uint256 limit_
    ) external view returns (string[] memory);

    /**
     * @notice Retrieves the current status of a specific proposal, identified by its unique ID.
     * @param proposalId_ The ID of the proposal for which to retrieve the status.
     * @return The current status of the proposal, represented as a value from the ProposalStatus enum.
     */
    function getProposalStatus(uint256 proposalId_) external view returns (ProposalStatus);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IRBAC} from "@solarity/solidity-lib/interfaces/access-control/IRBAC.sol";
import {IRBACGroupable} from "@solarity/solidity-lib/interfaces/access-control/extensions/IRBACGroupable.sol";

import {IDAOResource} from "./IDAOResource.sol";

import {DAORegistry} from "../DAO/DAORegistry.sol";
import {DAOMemberStorage} from "../DAO/DAOMemberStorage.sol";

/**
 * @title IPermissionManager
 * @notice Interface for managing permissions and roles in a DAO.
 * This interface provides methods for configuring and managing permissions and roles within a DAO.
 */
interface IPermissionManager is IRBACGroupable, IRBAC, IDAOResource {
    /**
     * @notice Represents a Veto Group within a DAO.
     * @notice Defines the structure of a Veto Group in a DAO environment.
     * @param target The address targeted by this Veto Group. Typically, this is an address that holds certain permissions or roles within the DAO.
     * @param linkedMemberStorage The address of the DAOMemberStorage contract associated with this Veto Group.
     * This contract usually manages membership and related data for the group.
     */
    struct VetoGroup {
        address target;
        DAOMemberStorage linkedMemberStorage;
    }

    /**
     * @notice Emitted when a new Veto Group is added.
     * @notice Indicates that a Veto Group has been successfully added.
     * @param target The address of the target associated with the new Veto Group.
     * @param linkedMemberStorage The address of the DAOMemberStorage contract linked to the new Veto Group.
     */
    event VetoGroupAdded(address target, address linkedMemberStorage);

    /**
     * @notice Emitted when a Veto Group is removed.
     * @notice Indicates that a Veto Group has been successfully removed.
     * @param target The address of the target associated with the removed Veto Group.
     */
    event VetoGroupRemoved(address target);

    /**
     * @notice Emitted when a DAOMemberStorage contract is linked to a Veto Group.
     * @notice Indicates that a DAOMemberStorage contract has been linked to a Veto Group.
     * @param target The address of the target Veto Group to which the storage is linked.
     * @param linkedMemberStorage The address of the DAOMemberStorage contract that has been linked to the Veto Group.
     */
    event LinkedStorageToVetoGroup(address target, address linkedMemberStorage);

    /**
     * @notice Adds multiple veto groups in a single operation.
     * @param vetoGroups_ An array of `VetoGroupInitializationParams` struct that contains the parameters to initialize the veto groups.
     */
    function addVetoGroups(VetoGroup[] memory vetoGroups_) external;

    /**
     * @notice Adds a single veto group.
     * @param target_ The target address that implements IDAOResource.
     * @param linkedMemberStorage_ The address of the `DAOMemberStorage` contract linked to the veto group.
     */
    function addVetoGroup(address target_, DAOMemberStorage linkedMemberStorage_) external;

    /**
     * @notice Removes a specific veto group.
     * @param target_ The target address of the veto group to be removed.
     */
    function removeVetoGroup(address target_) external;

    /**
     * @notice Links a `DAOMemberStorage` contract to a specific veto group.
     * @param target_ The target address of the veto group for the linkage.
     * @param linkedMemberStorage_ The address of the `DAOMemberStorage` contract to link to the veto group.
     */
    function linkStorageToVetoGroup(
        address target_,
        DAOMemberStorage linkedMemberStorage_
    ) external;

    /**
     * @notice Adds a member to specified groups.
     * @dev It requires `UpdateMemberGroupPermission` to be called.
     * @param member_ The address of the member to be added to the groups.
     * @param groups_ An array of group names to which the member will be added.
     */
    function addMemberToGroup(address member_, string[] memory groups_) external;

    /**
     * @notice Removes a member from specified groups.
     * @dev It requires `onlyUpdateMemberGroupPermission` to be called.
     * @param member_ The address of the member to be removed from the groups.
     * @param groups_ An array of group names from which the member will be removed.
     */
    function removeMemberFromGroup(address member_, string[] memory groups_) external;

    /**
     * @notice Retrieves the members of a veto group associated with a given target.
     * @dev This function returns an array of addresses representing the members of the veto group.
     *      If no veto group exists, it returns an empty array.
     * @param target_ The address of the target for which veto group members are being queried.
     * @return An array of addresses representing the members of the specified veto group.
     */
    function getVetoGroupMembers(address target_) external view returns (address[] memory);

    /**
     * @notice Retrieves the number of members in a specified veto group.
     * @param target_ The target address of the veto group.
     * @return The number of members in the veto group.
     */
    function getVetoMembersCount(address target_) external view returns (uint256);

    /**
     * @notice Provides information about a specified veto group.
     * @param target_ The target address of the veto group.
     * @return The target address, name, and the address of the linked `DAOMemberStorage` contract of the veto group.
     */
    function getVetoGroupInfo(address target_) external view returns (VetoGroup memory);

    /**
     * @notice Checks for the existence of a veto group.
     * @param target_ The target address of the veto group to check.
     * @return True if the veto group exists, false otherwise.
     */
    function isVetoGroupExists(address target_) external view returns (bool);

    /**
     * @notice Retrieves a list of all existing veto groups.
     * @return An array of all veto group addresses.
     */
    function getExistingVetoGroupTargets() external view returns (address[] memory);

    /**
     * @notice Checks if a user is a member of a veto group.
     * @param target_ The target address of the veto group.
     * @param member_ The address of the user to check.
     * @return True if the user is a member of the veto group, false otherwise.
     */
    function isUserInVetoGroup(address target_, address member_) external view returns (bool);

    /**
     * @notice Configures permissions for external modules associated with a DAO.
     * @param moduleName_ The name of the external module to configure.
     */
    function confExternalModule(string memory moduleName_) external;

    /**
     * @notice Retrieves the DAO registry.
     * @return The address of the DAO registry.
     */
    function getDAORegistry() external view returns (DAORegistry);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @title ISubmitSignature Interface
 * @dev Interface for submitting signatures in a secure manner to a DAO's proposal system.
 */
interface ISubmitSignature {
    /**
     * @notice Submits a signature for a DAO member, facilitating secure communication between the
     * voting contract and the proposal's target contract.
     *
     * @param signer_ The address of the DAO member whose signature is being submitted.
     * @param signature_ The cryptographic signature provided by the signer.
     * @param nonce_ A unique value used to prevent replay attacks.
     */
    function submitSignature(address signer_, bytes memory signature_, bytes32 nonce_) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {IERC4824} from "./IERC4824.sol";

/**
 * @title IDAOMetadata
 * @dev Interface for a contract that provides metadata for the DAO.
 */
interface IDAOMetadata is IERC4824 {
    /**
     * @dev Sets the DAO metadata URI.
     * @param daoURI_ The URI to set for the dao metadata.
     */
    function setDAOMetadata(string memory daoURI_) external;

    /**
     * @dev Retrieves the dao metadata URI.
     * @return _daoURI A string representing the URI for the dao metadata.
     */
    function daoURI() external view override returns (string memory _daoURI);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

/**
 * @title EIP-4824 Common Interfaces for DAOs
 * @dev See https://eips.ethereum.org/EIPS/eip-4824
 */
interface IERC4824 {
    event DAOURIUpdate(address daoAddress, string daoURI);

    /**
     * @notice A distinct Uniform Resource Identifier (URI) pointing to a JSON object following
     * the "EIP-4824 DAO JSON-LD Schema".
     *
     * This JSON file splits into four URIs:
     * membersURI, proposalsURI, activityLogURI, and governanceURI.
     *
     * The membersURI should point to a JSON file that conforms to the
     * "EIP-4824 Members JSON-LD Schema".
     *
     * The proposalsURI should point to a JSON file that conforms to the
     * "EIP-4824 Proposals JSON-LD Schema".
     *
     * The activityLogURI should point to a JSON file that conforms to the
     * "EIP-4824 Activity Log JSON-LD Schema".
     *
     * The governanceURI should point to a flat-file, normatively a .md file.
     *
     * Each of the JSON files named above can be statically-hosted or dynamically-generated.
     * @return _daoURI The DAO metadata URI.
     */
    function daoURI() external view returns (string memory _daoURI);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

/**
 * @title ERC5484 Interface
 * @notice Interface of the ERC5484 standard as defined in the EIP.
 * Link: https://eips.ethereum.org/EIPS/eip-5484
 */
interface IERC5484 {
    /**
     * @notice Enum for standardizing burn authorization number coding.
     */
    enum BurnAuth {
        IssuerOnly, // Only the issuer is allowed to burn the token.
        OwnerOnly, // Only the owner of the token can burn it.
        Both, // Both the issuer and the owner have burning rights.
        Neither // Neither the issuer nor the owner can burn the token.
    }

    /**
     * @notice Emitted when a southbound token (SBT) is issued.
     * @dev Complements the NFT transfer event to distinguish SBTs from standard NFTs, ensuring backward compatibility.
     * @param from The address of the issuer.
     * @param to The address of the receiver.
     * @param tokenId The identifier of the issued token.
     * @param burnAuth The burn authorization level assigned to the token.
     */
    event Issued(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        BurnAuth burnAuth
    );

    /**
     * @notice Returns the burn authorization status for a given token ID.
     * @dev Queries for unassigned or invalid token IDs will revert.
     * @param tokenId_ The identifier of the token.
     * @return BurnAuth The burn authorization status of the token.
     */
    function burnAuth(uint256 tokenId_) external view returns (BurnAuth);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

enum ParameterType {
    NONE,
    ADDRESS,
    UINT,
    STRING,
    BYTES,
    BOOL
}

struct Parameter {
    string name;
    bytes value;
    ParameterType solidityType;
}

/**
 * @title ParameterCodec
 * @notice Library for encoding and decoding parameters of different Solidity types.
 * @dev Provides functions to encode various Solidity types into bytes and to decode them back.
 */
library ParameterCodec {
    error InvalidParameterType(string name, ParameterType expected, ParameterType actual);

    /**
     * @notice Decodes an address from a Parameter.
     * @param parameter_ The Parameter to decode.
     * @return The decoded address.
     * @dev Reverts if the Parameter is not of type ADDRESS.
     */
    function decodeAddress(Parameter memory parameter_) internal pure returns (address) {
        _checkType(parameter_, ParameterType.ADDRESS);

        return address(uint160(uint256(bytes32(parameter_.value))));
    }

    /**
     * @notice Decodes a uint256 from a Parameter.
     * @param parameter_ The Parameter to decode.
     * @return The decoded uint256.
     * @dev Reverts if the Parameter is not of type UINT.
     */
    function decodeUint256(Parameter memory parameter_) internal pure returns (uint256) {
        _checkType(parameter_, ParameterType.UINT);

        return uint256(bytes32(parameter_.value));
    }

    /**
     * @notice Decodes a string from a Parameter.
     * @param parameter_ The Parameter to decode.
     * @return The decoded string.
     * @dev Reverts if the Parameter is not of type STRING.
     */
    function decodeString(Parameter memory parameter_) internal pure returns (string memory) {
        _checkType(parameter_, ParameterType.STRING);

        return abi.decode(parameter_.value, (string));
    }

    /**
     * @notice Decodes bytes from a Parameter.
     * @param parameter_ The Parameter to decode.
     * @return The decoded bytes.
     * @dev Reverts if the Parameter is not of type BYTES.
     */
    function decodeBytes(Parameter memory parameter_) internal pure returns (bytes memory) {
        _checkType(parameter_, ParameterType.BYTES);

        return parameter_.value;
    }

    /**
     * @notice Decodes a boolean value from a Parameter.
     * @param parameter_ The Parameter to decode.
     * @return The decoded boolean value.
     * @dev Reverts if the Parameter is not of type BOOL.
     */
    function decodeBool(Parameter memory parameter_) internal pure returns (bool) {
        _checkType(parameter_, ParameterType.BOOL);

        return uint256(bytes32(parameter_.value)) == 1;
    }

    /**
     * @notice Encodes a uint256 value into a Parameter.
     * @param value_ The uint256 value to encode.
     * @param name_ The name of the Parameter.
     * @return The encoded Parameter.
     */
    function encodeUint256(
        uint256 value_,
        string memory name_
    ) internal pure returns (Parameter memory) {
        return Parameter(name_, abi.encode(value_), ParameterType.UINT);
    }

    /**
     * @notice Encodes an address value into a Parameter.
     * @param value_ The address value to encode.
     * @param name_ The name of the Parameter.
     * @return The encoded Parameter.
     */
    function encodeAddress(
        address value_,
        string memory name_
    ) internal pure returns (Parameter memory) {
        return Parameter(name_, abi.encode(value_), ParameterType.ADDRESS);
    }

    /**
     * @notice Encodes a string value into a Parameter.
     * @param value_ The string value to encode.
     * @param name_ The name of the Parameter.
     * @return The encoded Parameter.
     */
    function encodeString(
        string memory value_,
        string memory name_
    ) internal pure returns (Parameter memory) {
        return Parameter(name_, abi.encode(value_), ParameterType.STRING);
    }

    /**
     * @notice Encodes bytes into a Parameter.
     * @param value_ The bytes value to encode.
     * @param name_ The name of the Parameter.
     * @return The encoded Parameter.
     */
    function encodeBytes(
        bytes memory value_,
        string memory name_
    ) internal pure returns (Parameter memory) {
        return Parameter(name_, value_, ParameterType.BYTES);
    }

    /**
     * @notice Encodes a boolean value into a Parameter.
     * @param value_ The boolean value to encode.
     * @param name_ The name of the Parameter.
     * @return The encoded Parameter.
     */
    function encodeBool(
        bool value_,
        string memory name_
    ) internal pure returns (Parameter memory) {
        return Parameter(name_, abi.encode((value_ ? 1 : 0)), ParameterType.BOOL);
    }

    function _checkType(Parameter memory parameter_, ParameterType expected_) private pure {
        if (parameter_.solidityType != expected_) {
            revert InvalidParameterType(parameter_.name, expected_, parameter_.solidityType);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Parameter} from "./Parameters.sol";

/**
 * @title ParameterSet
 * @notice A library for managing a collection of parameters.
 * @dev Provides functionality to add, change, remove, and query parameters within a set.
 */
library ParameterSet {
    struct Set {
        Parameter[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     * @notice Adds a parameter to the set.
     * @param set The set object.
     * @param parameter_ The parameter to add.
     * @return True if the parameter was successfully added, false if it already exists.
     */
    function add(Set storage set, Parameter memory parameter_) internal returns (bool) {
        if (!contains(set, parameter_.name)) {
            set._values.push(parameter_);
            set._indexes[parameter_.name] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Changes the value of an existing parameter in the set.
     * @param set The set object.
     * @param parameter_ The parameter to change.
     * @return True if the parameter was successfully changed, false if it does not exist.
     */
    function change(Set storage set, Parameter memory parameter_) internal returns (bool) {
        if (contains(set, parameter_.name)) {
            set._values[set._indexes[parameter_.name] - 1] = parameter_;

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Removes a parameter from the set.
     * @param set The set object.
     * @param name_ The name of the parameter to remove.
     * @return True if the parameter was successfully removed, false if it does not exist.
     */
    function remove(Set storage set, string memory name_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[name_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                Parameter memory lastValue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastValue_;
                set._indexes[lastValue_.name] = valueIndex_;
            }

            set._values.pop();
            delete set._indexes[name_];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Checks if a parameter exists in the set.
     * @param set The set object.
     * @param name_ The name of the parameter to check.
     * @return True if the parameter exists, false otherwise.
     */
    function contains(Set storage set, string memory name_) internal view returns (bool) {
        return set._indexes[name_] != 0;
    }

    /**
     * @notice Retrieves a parameter from the set by its name.
     * @param set The set object.
     * @param name_ The name of the parameter to retrieve.
     * @return The parameter associated with the given name.
     */
    function get(Set storage set, string memory name_) internal view returns (Parameter memory) {
        return set._values[set._indexes[name_] - 1];
    }

    /**
     * @notice Returns the number of parameters in the set.
     * @param set The set object.
     * @return The total number of parameters in the set.
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @notice Retrieves a parameter from the set by its index.
     * @param set The set object.
     * @param index_ The index of the parameter in the set.
     * @return The parameter at the specified index.
     */
    function at(Set storage set, uint256 index_) internal view returns (Parameter memory) {
        return set._values[index_];
    }

    /**
     * @notice Retrieves all parameters in the set. This function can be very expensive in terms of gas.
     * @param set The set object.
     * @return An array of all parameters in the set.
     */
    function values(Set storage set) internal view returns (Parameter[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {IRBAC} from "@solarity/solidity-lib/interfaces/access-control/IRBAC.sol";

import {Parameter} from "../data-structures/Parameters.sol";

/**
 * @title ArrayHelper
 * @notice Library to convert fixed-size arrays (or one element) into dynamic array.
 */
library ArrayHelper {
    function asArray(string memory element_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = element_;
    }

    function asArray(string[1] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = elements_[0];
    }

    function asArray(string[2] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](2);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
    }

    function asArray(string[3] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](3);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
    }

    function asArray(string[4] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](4);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
    }

    function asArray(string[5] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](5);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
    }

    function asArray(string[6] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](6);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
    }

    function asArray(string[7] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](7);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
        array_[6] = elements_[6];
    }

    function asArray(string[8] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](8);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
        array_[6] = elements_[6];
        array_[7] = elements_[7];
    }

    function asArray(string[9] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](9);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
        array_[6] = elements_[6];
        array_[7] = elements_[7];
        array_[8] = elements_[8];
    }

    function asArray(string[10] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](10);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
        array_[6] = elements_[6];
        array_[7] = elements_[7];
        array_[8] = elements_[8];
        array_[9] = elements_[9];
    }

    function asArray(
        IRBAC.ResourceWithPermissions[1] memory elements_
    ) internal pure returns (IRBAC.ResourceWithPermissions[] memory array_) {
        array_ = new IRBAC.ResourceWithPermissions[](1);
        array_[0] = elements_[0];
    }

    function asArray(
        IRBAC.ResourceWithPermissions[2] memory elements_
    ) internal pure returns (IRBAC.ResourceWithPermissions[] memory array_) {
        array_ = new IRBAC.ResourceWithPermissions[](2);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
    }

    function asArray(
        IRBAC.ResourceWithPermissions[3] memory elements_
    ) internal pure returns (IRBAC.ResourceWithPermissions[] memory array_) {
        array_ = new IRBAC.ResourceWithPermissions[](3);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
    }

    function asArray(
        IRBAC.ResourceWithPermissions[4] memory elements_
    ) internal pure returns (IRBAC.ResourceWithPermissions[] memory array_) {
        array_ = new IRBAC.ResourceWithPermissions[](4);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
    }

    function asArray(
        Parameter[1] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](1);
        array_[0] = elements_[0];
    }

    function asArray(
        Parameter[2] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](2);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
    }

    function asArray(
        Parameter[3] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](3);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
    }

    function asArray(
        Parameter[4] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](4);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
    }

    function asArray(
        Parameter[5] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](5);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
    }

    function asArray(
        Parameter[6] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](6);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
    }

    function asArray(
        Parameter[7] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](7);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
        array_[6] = elements_[6];
    }

    function asArray(
        Parameter[8] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](8);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
        array_[6] = elements_[6];
        array_[7] = elements_[7];
    }

    function asArray(
        Parameter[9] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](9);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
        array_[6] = elements_[6];
        array_[7] = elements_[7];
        array_[8] = elements_[8];
    }

    function asArray(
        Parameter[10] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](10);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
        array_[4] = elements_[4];
        array_[5] = elements_[5];
        array_[6] = elements_[6];
        array_[7] = elements_[7];
        array_[8] = elements_[8];
        array_[9] = elements_[9];
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {ParameterCodec} from "../data-structures/Parameters.sol";

import "../../core/Globals.sol";

import {DAORegistry} from "../../DAO/DAORegistry.sol";

import {IDAOParameterStorage} from "../../interfaces/IDAOParameterStorage.sol";

/**
 * @title ConstitutionData
 * @notice Library providing functionalities related to the DAO's constitution.
 * @dev Utilizes OpenZeppelin's ECDSA and SignatureChecker libraries for signature verification.
 */
library ConstitutionData {
    using ECDSA for bytes32;
    using SignatureChecker for address;

    using ParameterCodec for *;

    /**
     * @notice Checks if the constitution hash in the DAO parameters is set to zero.
     * @param daoRegistry_ The DAO registry contract.
     * @return True if the constitution hash is zero, false otherwise.
     * @dev Retrieves the constitution hash from the DAO parameters and compares it to zero.
     */
    function isConstitutionHashZero(DAORegistry daoRegistry_) internal view returns (bool) {
        bytes32 hash_ = getConstitutionHash(daoRegistry_);

        return hash_ == bytes32(0);
    }

    /**
     * @notice Verifies the signature of the DAO constitution by a user.
     * @param signature_ The digital signature of the constitution hash by the user.
     * @param registry_ The DAO registry contract.
     * @param signer_ The address of the signer to validate.
     * @return True if the signature is valid and signed by the signer, false otherwise.
     * @dev Recovers the signer from the signature and compares it to the provided signer address.
     */
    function validateSignature(
        bytes calldata signature_,
        DAORegistry registry_,
        address signer_
    ) internal view returns (bool) {
        bytes32 hash_ = getConstitutionHash(registry_);

        return
            SignatureChecker.isValidSignatureNow(
                signer_,
                hash_.toEthSignedMessageHash(),
                signature_
            );
    }

    /*
     * @notice Returns the constitution hash from the DAO parameters.
     */
    function getConstitutionHash(DAORegistry registry_) internal view returns (bytes32) {
        return
            bytes32(
                IDAOParameterStorage(registry_.getConfDAOParameterStorage(DAO_RESERVED_NAME))
                    .getDAOParameter(DAO_CONSTITUTION_HASH_NAME)
                    .decodeBytes()
            );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {PriorityQueue} from "@solarity/solidity-lib/libs/data-structures/PriorityQueue.sol";

/**
 * @title TimeLockHelper
 * @notice Library for managing time-locked assets using a priority queue.
 * @dev In this implementation, the amount represents the priority, while time represents the value.
 * Therefore, the `top` function will always return the TimeLock with the largest amount locked.
 */
library TimeLockHelper {
    using PriorityQueue for PriorityQueue.UintQueue;

    /**
     * @notice Locks an amount of assets for a specified duration.
     * @param locks_ The priority queue of time locks.
     * @param amount_ The amount of assets to lock.
     * @param timeToLock_ The duration (in seconds) to lock the assets.
     * @dev Adds a time lock to the priority queue with the specified amount and duration. The priority of the time lock
     * is based on the amount of assets being locked, with higher amounts having higher priority.
     */
    function lock(
        PriorityQueue.UintQueue storage locks_,
        uint256 amount_,
        uint256 timeToLock_
    ) internal {
        locks_.add(timeToLock_, amount_);
    }

    /**
     * @notice Locks an NFT for a specified duration.
     * @param locks_ The priority queue of time locks.
     * @param tokenId_ The ID of the NFT to lock.
     * @param timeToLock_ The duration (in seconds) to lock the NFT.
     * @dev Locks an NFT by adding it to the priority queue with its unlock time.
     * If the queue is empty or the new lock has a later unlock time, it updates the top lock time.
     */
    function lockNFT(
        PriorityQueue.UintQueue storage locks_,
        uint256 tokenId_,
        uint256 timeToLock_
    ) internal {
        if (locks_.length() == 0) {
            locks_.add(timeToLock_, tokenId_);
            return;
        }

        if (uint256(locks_._queue._values[0]) < timeToLock_) {
            locks_._queue._values[0] = bytes32(timeToLock_);
        }
    }

    /**
     * @notice Removes all expired time locks from the priority queue.
     * @param locks_ The priority queue of time locks.
     * @dev Iterates over the priority queue from highest to lowest priority, removing all time locks
     * whose expiration time is less than the current block timestamp. It stops if a valid time lock is encountered.
     */
    function purgeTimeLocks(PriorityQueue.UintQueue storage locks_) internal {
        uint256 currentTimestamp_ = block.timestamp;

        while (locks_.length() > 0 && locks_.topValue() < currentTimestamp_) {
            locks_.removeTop();
        }
    }

    /**
     * @notice Checks if an account can withdraw a specified amount of assets.
     * @param locks_ The priority queue of time locks.
     * @param userBalance_ The current balance of the user.
     * @param amount_ The amount of assets to withdraw.
     * @return bool True if the account can withdraw the specified amount, false otherwise.
     * @dev Iterates through the priority queue, removing any expired time locks and
     * checking if the remaining balance, excluding locked assets, is sufficient for withdrawal.
     */
    function isAbleToWithdraw(
        PriorityQueue.UintQueue storage locks_,
        uint256 userBalance_,
        uint256 amount_
    ) internal returns (bool) {
        uint256 currentTimestamp_ = block.timestamp;

        while (locks_.length() > 0) {
            (uint256 unlockTime_, uint256 lockedAmount_) = locks_.top();

            if (unlockTime_ < currentTimestamp_) {
                locks_.removeTop();

                continue;
            }

            if (amount_ + lockedAmount_ > userBalance_) {
                return false;
            } else {
                return true;
            }
        }

        return true;
    }

    /**
     * @notice Checks if an account can withdraw a specified amount of assets without modifying the queue (view function).
     * @param locks_ The priority queue of time locks.
     * @param userBalance_ The current balance of the user.
     * @param amount_ The amount of assets to withdraw.
     * @return bool True if the account can withdraw the specified amount, false otherwise.
     * @dev Views the priority queue to check if the current balance, minus the locked assets,
     * is sufficient for the withdrawal.
     */
    function isAbleToWithdrawView(
        PriorityQueue.UintQueue storage locks_,
        uint256 userBalance_,
        uint256 amount_
    ) internal view returns (bool) {
        (uint256[] memory timeLocks_, uint256[] memory amounts_) = locks_.elements();

        for (uint256 i = 0; i < timeLocks_.length; i++) {
            if (timeLocks_[i] < block.timestamp) {
                continue;
            }

            if (amount_ + amounts_[i] > userBalance_) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Provides the available withdrawal amount and the unlock time of the last lock for a user.
     * @param locks_ The priority queue of time locks.
     * @param userBalance_ The current balance of the user.
     * @return amount_ The available amount for withdrawal.
     * @return lastEndTime_ The unlock time of the last time lock.
     * @dev Calculates the available withdrawal amount after considering the locked assets.
     */
    function getWithdrawalAmountAndEndTime(
        PriorityQueue.UintQueue storage locks_,
        uint256 userBalance_
    ) internal view returns (uint256 amount_, uint256 lastEndTime_) {
        (uint256[] memory timeLocks_, uint256[] memory amounts_) = locks_.elements();

        uint256 maxLockAmount_ = 0;
        for (uint256 i = 0; i < timeLocks_.length; i++) {
            if (timeLocks_[i] < block.timestamp) {
                continue;
            }

            if (timeLocks_[i] > lastEndTime_) {
                lastEndTime_ = timeLocks_[i];
            }

            if (amounts_[i] > maxLockAmount_) {
                maxLockAmount_ = amounts_[i];
            }
        }

        if (maxLockAmount_ >= userBalance_) {
            return (0, lastEndTime_);
        } else {
            return (userBalance_ - maxLockAmount_, lastEndTime_);
        }
    }

    /**
     * @notice Checks if an NFT can be withdrawn from the vault.
     * @param locks_ The priority queue of time locks for NFTs.
     * @param tokenId_ The ID of the NFT to check.
     * @return bool True if the NFT can be withdrawn, false otherwise.
     * @dev Determines the ability to withdraw an NFT based on its position in the queue and its lock status.
     */
    function isAbleToWithdrawNFT(
        PriorityQueue.UintQueue storage locks_,
        uint256 tokenId_
    ) internal view returns (bool) {
        if (locks_.length() == 0) {
            return true;
        }

        if (uint256(locks_._queue._priorities[0]) != tokenId_) {
            return true;
        }

        if (uint256(locks_._queue._values[0]) < block.timestamp) {
            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../core/Globals.sol";

/**
 * @title TokenBalance
 * @notice Provides functionality to transfer ETH or ERC20 tokens to a specified address.
 */
library TokenBalance {
    using SafeERC20 for IERC20;

    /**
     * @notice Transfers the specified amount of ETH or ERC20 tokens to the specified receiver.
     * @param token The address of the ERC20 token to transfer, or the ETHEREUM_ADDRESS constant for ETH transfers.
     * @param receiver The address that will receive the transferred funds.
     * @param amount The amount of tokens or ETH to transfer.
     * @dev Utilizes a low-level `call` for transferring ETH to properly handle the transfer and
     * verify its success. For ERC20 token transfers, the SafeERC20 `safeTransfer` function is used.
     */
    function sendFunds(address token, address receiver, uint256 amount) internal {
        if (token == ETHEREUM_ADDRESS) {
            (bool status_, bytes memory data_) = receiver.call{value: amount}("");
            Address.verifyCallResult(
                status_,
                data_,
                "[QGDK-019000]-Transferring of native currency failed."
            );
        } else {
            IERC20(token).safeTransfer(receiver, amount);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IDAOMetadata} from "../interfaces/metadata/IDAOMetadata.sol";

/**
 * @title DAOMetadata
 * @notice A contract that allows changing and retrieving metadata about the DAO,
 * such as a URI that points to a JSON file with information about the DAO.
 */
abstract contract DAOMetadata is IDAOMetadata, Initializable {
    string private _uri;

    modifier onlyChangeDAOMetadataPermission() virtual {
        // Ensures only authorized changes to the DAO metadata.
        _;
    }

    /**
     * @notice Initializes the DAO with a specified URI.
     * @param daoURI_ The DAO URI.
     */
    function __DAOMetadata_init(string memory daoURI_) internal onlyInitializing {
        _setDAOMetadata(daoURI_);
    }

    /**
     * @inheritdoc IDAOMetadata
     */
    function setDAOMetadata(string memory daoURI_) external onlyChangeDAOMetadataPermission {
        _setDAOMetadata(daoURI_);
    }

    /**
     * @inheritdoc IDAOMetadata
     */
    function daoURI() external view returns (string memory _daoURI) {
        return _uri;
    }

    function _setDAOMetadata(string memory daoURI_) private {
        _uri = daoURI_;

        emit DAOURIUpdate(address(this), daoURI_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.20;

import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

// CHANGE: Deleted initializable import to prevent ambiguity with `Initializable` contract from 4.9.5 version of OpenZeppelin
// import {Initializable} from "./Initializable.sol";
import {MessageHashUtils} from "./MessageHashUtils.sol";

// Forked from: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/0b2bfd74c98d45143cc060417922b3c1328a9fef/contracts/utils/cryptography/EIP712Upgradeable.sol#L1

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP-712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding scheme specified in the EIP requires a domain separator and a hash of the typed structured data, whose
 * encoding is very generic and therefore its implementation in Solidity is not feasible, thus this contract
 * does not implement the encoding itself. Protocols need to implement the type-specific encoding they need in order to
 * produce the hash of their typed data using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP-712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the {_domainSeparatorV4} function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 */
abstract contract EIP712Upgradeable is IERC5267 {
    bytes32 private constant TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @custom:storage-location erc7201:openzeppelin.storage.EIP712
    struct EIP712Storage {
        /// @custom:oz-renamed-from _HASHED_NAME
        bytes32 _hashedName;
        /// @custom:oz-renamed-from _HASHED_VERSION
        bytes32 _hashedVersion;
        string _name;
        string _version;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.EIP712")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EIP712StorageLocation =
        0xa16a46d94261c7517cc8ff89f61c0ce93598e3c849801011dee649a6a557d100;

    function _getEIP712Storage() private pure returns (EIP712Storage storage $) {
        assembly {
            $.slot := EIP712StorageLocation
        }
    }

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP-712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal {
        EIP712Storage storage $ = _getEIP712Storage();
        $._name = name;
        $._version = version;

        // Reset prior values in storage if upgrading
        $._hashedName = 0;
        $._hashedVersion = 0;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    _EIP712NameHash(),
                    _EIP712VersionHash(),
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {IERC-5267}.
     */
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        EIP712Storage storage $ = _getEIP712Storage();
        // If the hashed name and version in storage are non-zero, the contract hasn't been properly initialized
        // and the EIP712 domain is not reliable, as it will be missing name and version.
        require($._hashedName == 0 && $._hashedVersion == 0, "EIP712: Uninitialized");

        return (
            hex"0f", // 01111
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Name() internal view virtual returns (string memory) {
        EIP712Storage storage $ = _getEIP712Storage();
        return $._name;
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Version() internal view virtual returns (string memory) {
        EIP712Storage storage $ = _getEIP712Storage();
        return $._version;
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Name` instead.
     */
    function _EIP712NameHash() internal view returns (bytes32) {
        EIP712Storage storage $ = _getEIP712Storage();
        string memory name = _EIP712Name();
        if (bytes(name).length > 0) {
            return keccak256(bytes(name));
        } else {
            // If the name is empty, the contract may have been upgraded without initializing the new storage.
            // We return the name hash in storage if non-zero, otherwise we assume the name is empty by design.
            bytes32 hashedName = $._hashedName;
            if (hashedName != 0) {
                return hashedName;
            } else {
                return keccak256("");
            }
        }
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Version` instead.
     */
    function _EIP712VersionHash() internal view returns (bytes32) {
        EIP712Storage storage $ = _getEIP712Storage();
        string memory version = _EIP712Version();
        if (bytes(version).length > 0) {
            return keccak256(bytes(version));
        } else {
            // If the version is empty, the contract may have been upgraded without initializing the new storage.
            // We return the version hash in storage if non-zero, otherwise we assume the version is empty by design.
            bytes32 hashedVersion = $._hashedVersion;
            if (hashedVersion != 0) {
                return hashedVersion;
            } else {
                return keccak256("");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)

pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// Forked from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/abcf9dd8b78ca81ac0c3571a6ce9831235ff1b4c/contracts/utils/cryptography/MessageHashUtils.sol#L1

/**
 * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
 *
 * The library provides methods for generating a hash of a message that conforms to the
 * https://eips.ethereum.org/EIPS/eip-191[ERC-191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
 * specifications.
 */
library MessageHashUtils {
    /**
     * @dev Returns the keccak256 digest of an ERC-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing a bytes32 `messageHash` with
     * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
     * keccak256, although any bytes32 value can be safely used because the final digest will
     * be re-hashed.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    /**
     * @dev Returns the keccak256 digest of an ERC-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing an arbitrary `message` with
     * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    "\x19Ethereum Signed Message:\n",
                    bytes(Strings.toString(message.length)),
                    message
                )
            );
    }

    /**
     * @dev Returns the keccak256 digest of an ERC-191 signed data with version
     * `0x00` (data with intended validator).
     *
     * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
     * `validator` address. Then hashing the result.
     *
     * See {ECDSA-recover}.
     */
    function toDataWithIntendedValidatorHash(
        address validator,
        bytes memory data
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (ERC-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IRBACGroupable} from "../../interfaces/access-control/extensions/IRBACGroupable.sol";

import {StringSet} from "../../libs/data-structures/StringSet.sol";
import {SetHelper} from "../../libs/arrays/SetHelper.sol";

import {RBAC} from "../RBAC.sol";

/**
 * @notice The Role Based Access Control (RBAC) module
 *
 * This contract is an extension for the RBAC contract to provide the ability to organize roles
 * into groups and assign users to them.
 *
 * The contract also supports default groups that all users may be in by default.
 *
 * The RBAC structure becomes the following:
 *
 * ((PERMISSION >- RESOURCE) >- ROLE) >- GROUP
 *
 * Where ROLE and GROUP are assignable to users
 */
abstract contract RBACGroupable is IRBACGroupable, RBAC {
    using StringSet for StringSet.Set;
    using SetHelper for StringSet.Set;

    uint256 private _defaultGroupEnabled;

    mapping(address => StringSet.Set) private _userGroups;
    mapping(string => StringSet.Set) private _groupRoles;

    /**
     * @notice The initialization function
     */
    function __RBACGroupable_init() internal onlyInitializing {
        __RBAC_init();
    }

    /**
     * @notice The function to assign the user to groups
     * @param who_ the user to be assigned
     * @param groupsToAddTo_ the list of groups to assign the user to
     */
    function addUserToGroups(
        address who_,
        string[] memory groupsToAddTo_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        require(groupsToAddTo_.length > 0, "RBACGroupable: empty groups");

        _addUserToGroups(who_, groupsToAddTo_);
    }

    /**
     * @notice The function to remove the user from groups
     * @param who_ the user to be removed from groups
     * @param groupsToRemoveFrom_ the list of groups to remove the user from
     */
    function removeUserFromGroups(
        address who_,
        string[] memory groupsToRemoveFrom_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        require(groupsToRemoveFrom_.length > 0, "RBACGroupable: empty groups");

        _removeUserFromGroups(who_, groupsToRemoveFrom_);
    }

    /**
     * @notice The function to grant roles to the group
     * @param groupTo_ the group to grant roles to
     * @param rolesToGrant_ the list of roles to grant
     */
    function grantGroupRoles(
        string memory groupTo_,
        string[] memory rolesToGrant_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        require(rolesToGrant_.length > 0, "RBACGroupable: empty roles");

        _grantGroupRoles(groupTo_, rolesToGrant_);
    }

    /**
     * @notice The function to revoke roles from the group
     * @param groupFrom_ the group to revoke roles from
     * @param rolesToRevoke_ the list of roles to revoke
     */
    function revokeGroupRoles(
        string memory groupFrom_,
        string[] memory rolesToRevoke_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        require(rolesToRevoke_.length > 0, "RBACGroupable: empty roles");

        _revokeGroupRoles(groupFrom_, rolesToRevoke_);
    }

    /**
     * @notice The function to toggle the default group state. When `defaultGroupEnabled` is set
     * to true, the default group is enabled, otherwise it is disabled
     */
    function toggleDefaultGroup()
        public
        virtual
        override
        onlyPermission(RBAC_RESOURCE, UPDATE_PERMISSION)
    {
        _defaultGroupEnabled ^= 1;

        emit ToggledDefaultGroup(getDefaultGroupEnabled());
    }

    /**
     * @notice The function to get the list of user groups
     * @param who_ the user
     * @return groups_ the list of user groups
     */
    function getUserGroups(address who_) public view override returns (string[] memory groups_) {
        StringSet.Set storage userGroups = _userGroups[who_];

        uint256 userGroupsLength_ = userGroups.length();

        groups_ = new string[](userGroupsLength_ + _defaultGroupEnabled);

        for (uint256 i = 0; i < userGroupsLength_; ++i) {
            groups_[i] = userGroups.at(i);
        }
    }

    /**
     * @notice The function to get the list of groups roles
     * @param group_ the group
     * @return roles_ the list of group roles
     */
    function getGroupRoles(
        string memory group_
    ) public view override returns (string[] memory roles_) {
        return _groupRoles[group_].values();
    }

    /**
     * @notice The function to get the current state of the default group
     * @return defaultGroupEnabled_ the boolean indicating whether the default group is enabled
     */
    function getDefaultGroupEnabled() public view returns (bool defaultGroupEnabled_) {
        return _defaultGroupEnabled > 0;
    }

    /**
     * @dev DO NOT call `super.hasPermission(...)` in derived contracts, because this method
     * handles not 2 but 3 states: NO PERMISSION, ALLOWED, DISALLOWED
     * @notice The function to check the user's possession of the role. Unlike the base method,
     * this method also looks up the required permission in the user's groups
     * @param who_ the user
     * @param resource_ the resource the user has to have the permission of
     * @param permission_ the permission the user has to have
     * @return isAllowed_ true if the user has the permission, false otherwise
     */
    function hasPermission(
        address who_,
        string memory resource_,
        string memory permission_
    ) public view virtual override returns (bool isAllowed_) {
        string[] memory roles_ = getUserRoles(who_);

        for (uint256 i = 0; i < roles_.length; i++) {
            string memory role_ = roles_[i];

            if (_isDisallowed(role_, resource_, permission_)) {
                return false;
            }

            isAllowed_ = isAllowed_ || _isAllowed(role_, resource_, permission_);
        }

        string[] memory groups_ = getUserGroups(who_);

        for (uint256 i = 0; i < groups_.length; i++) {
            roles_ = getGroupRoles(groups_[i]);

            for (uint256 j = 0; j < roles_.length; j++) {
                string memory role_ = roles_[j];

                if (_isDisallowed(role_, resource_, permission_)) {
                    return false;
                }

                isAllowed_ = isAllowed_ || _isAllowed(role_, resource_, permission_);
            }
        }
    }

    /**
     * @notice The internal function to assign groups to the user
     * @param who_ the user to assign groups to
     * @param groupsToAddTo_ the list of groups to be assigned
     */
    function _addUserToGroups(address who_, string[] memory groupsToAddTo_) internal {
        _userGroups[who_].add(groupsToAddTo_);

        emit AddedToGroups(who_, groupsToAddTo_);
    }

    /**
     * @notice The internal function to remove the user from groups
     * @param who_ the user to be removed from groups
     * @param groupsToRemoveFrom_ the list of groups to remove the user from
     */
    function _removeUserFromGroups(address who_, string[] memory groupsToRemoveFrom_) internal {
        _userGroups[who_].remove(groupsToRemoveFrom_);

        emit RemovedFromGroups(who_, groupsToRemoveFrom_);
    }

    /**
     * @notice The internal function to grant roles to the group
     * @param groupTo_ the group to grant roles to
     * @param rolesToGrant_ the list of roles to grant
     */
    function _grantGroupRoles(string memory groupTo_, string[] memory rolesToGrant_) internal {
        _groupRoles[groupTo_].add(rolesToGrant_);

        emit GrantedGroupRoles(groupTo_, rolesToGrant_);
    }

    /**
     * @notice The internal function to revoke roles from the group
     * @param groupFrom_ the group to revoke roles from
     * @param rolesToRevoke_ the list of roles to revoke
     */
    function _revokeGroupRoles(string memory groupFrom_, string[] memory rolesToRevoke_) internal {
        _groupRoles[groupFrom_].remove(rolesToRevoke_);

        emit RevokedGroupRoles(groupFrom_, rolesToRevoke_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The PermanentOwnable module
 *
 * Contract module which provides a basic access control mechanism, where there is
 * an account (an owner) that can be granted exclusive access to specific functions.
 *
 * The owner is set to the address provided by the deployer. The ownership cannot be further changed.
 *
 * This module will make available the modifier `onlyOwner`, which can be applied
 * to your functions to restrict their use to the owners.
 */
abstract contract PermanentOwnable {
    address private immutable _OWNER;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @notice Initializes the contract setting the address provided by the deployer as the owner.
     * @param owner_ the address of the permanent owner.
     */
    constructor(address owner_) {
        require(owner_ != address(0), "PermanentOwnable: zero address can not be the owner");

        _OWNER = owner_;
    }

    /**
     * @notice Returns the address of the owner.
     * @return the permanent owner.
     */
    function owner() public view virtual returns (address) {
        return _OWNER;
    }

    function _onlyOwner() internal view virtual {
        require(_OWNER == msg.sender, "PermanentOwnable: caller is not the owner");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IRBAC} from "../interfaces/access-control/IRBAC.sol";

import {TypeCaster} from "../libs/utils/TypeCaster.sol";
import {SetHelper} from "../libs/arrays/SetHelper.sol";
import {StringSet} from "../libs/data-structures/StringSet.sol";

/**
 * @notice The Role Based Access Control (RBAC) module
 *
 * This is advanced module that handles role management for huge systems. One can declare specific permissions
 * for specific resources (contracts) and aggregate them into roles for further assignment to users.
 *
 * Each user can have multiple roles and each role can manage multiple resources. Each resource can posses a set of
 * permissions (CREATE, DELETE) that are only valid for that specific resource.
 *
 * The RBAC model supports antipermissions as well. One can grant antipermissions to users to restrict their access level.
 * There also is a special wildcard symbol "*" that means "everything". This symbol can be applied either to the
 * resources or permissions.
 *
 * By default, the MASTER role is configured with "*" as resources and permissions, allowing masters to do everything.
 *
 * The RBAC structure is the following:
 *
 * (PERMISSION >- RESOURCE) >- ROLE
 *
 * Where ROLE is assignable to users
 */
abstract contract RBAC is IRBAC, Initializable {
    using StringSet for StringSet.Set;
    using SetHelper for StringSet.Set;
    using TypeCaster for string;

    string public constant MASTER_ROLE = "MASTER";

    string public constant ALL_RESOURCE = "*";
    string public constant ALL_PERMISSION = "*";

    string public constant CREATE_PERMISSION = "CREATE";
    string public constant READ_PERMISSION = "READ";
    string public constant UPDATE_PERMISSION = "UPDATE";
    string public constant DELETE_PERMISSION = "DELETE";

    string public constant RBAC_RESOURCE = "RBAC_RESOURCE";

    mapping(string => mapping(bool => mapping(string => StringSet.Set))) private _rolePermissions;
    mapping(string => mapping(bool => StringSet.Set)) private _roleResources;

    mapping(address => StringSet.Set) private _userRoles;

    modifier onlyPermission(string memory resource_, string memory permission_) {
        require(
            hasPermission(msg.sender, resource_, permission_),
            string(
                abi.encodePacked("RBAC: no ", permission_, " permission for resource ", resource_)
            )
        );
        _;
    }

    /**
     * @notice The initialization function
     */
    function __RBAC_init() internal onlyInitializing {
        _addPermissionsToRole(MASTER_ROLE, ALL_RESOURCE, ALL_PERMISSION.asSingletonArray(), true);
    }

    /**
     * @notice The function to grant roles to a user
     * @param to_ the user to grant roles to
     * @param rolesToGrant_ roles to grant
     */
    function grantRoles(
        address to_,
        string[] memory rolesToGrant_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        require(rolesToGrant_.length > 0, "RBAC: empty roles");

        _grantRoles(to_, rolesToGrant_);
    }

    /**
     * @notice The function to revoke roles
     * @param from_ the user to revoke roles from
     * @param rolesToRevoke_ the roles to revoke
     */
    function revokeRoles(
        address from_,
        string[] memory rolesToRevoke_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        require(rolesToRevoke_.length > 0, "RBAC: empty roles");

        _revokeRoles(from_, rolesToRevoke_);
    }

    /**
     * @notice The function to add resource permission to role
     * @param role_ the role to add permissions to
     * @param permissionsToAdd_ the array of resources and permissions to add to the role
     * @param allowed_ indicates whether to add permissions to an allowlist or disallowlist
     */
    function addPermissionsToRole(
        string memory role_,
        ResourceWithPermissions[] memory permissionsToAdd_,
        bool allowed_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        for (uint256 i = 0; i < permissionsToAdd_.length; i++) {
            _addPermissionsToRole(
                role_,
                permissionsToAdd_[i].resource,
                permissionsToAdd_[i].permissions,
                allowed_
            );
        }
    }

    /**
     * @notice The function to remove permissions from role
     * @param role_ the role to remove permissions from
     * @param permissionsToRemove_ the array of resources and permissions to remove from the role
     * @param allowed_ indicates whether to remove permissions from the allowlist or disallowlist
     */
    function removePermissionsFromRole(
        string memory role_,
        ResourceWithPermissions[] memory permissionsToRemove_,
        bool allowed_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        for (uint256 i = 0; i < permissionsToRemove_.length; i++) {
            _removePermissionsFromRole(
                role_,
                permissionsToRemove_[i].resource,
                permissionsToRemove_[i].permissions,
                allowed_
            );
        }
    }

    /**
     * @notice The function to get the list of user roles
     * @param who_ the user
     * @return roles_ the roles of the user
     */
    function getUserRoles(address who_) public view override returns (string[] memory roles_) {
        return _userRoles[who_].values();
    }

    /**
     * @notice The function to get the permissions of the role
     * @param role_ the role
     * @return allowed_ the list of allowed permissions of the role
     * @return disallowed_ the list of disallowed permissions of the role
     */
    function getRolePermissions(
        string memory role_
    )
        public
        view
        override
        returns (
            ResourceWithPermissions[] memory allowed_,
            ResourceWithPermissions[] memory disallowed_
        )
    {
        StringSet.Set storage _allowedResources = _roleResources[role_][true];
        StringSet.Set storage _disallowedResources = _roleResources[role_][false];

        mapping(string => StringSet.Set) storage _allowedPermissions = _rolePermissions[role_][
            true
        ];
        mapping(string => StringSet.Set) storage _disallowedPermissions = _rolePermissions[role_][
            false
        ];

        allowed_ = new ResourceWithPermissions[](_allowedResources.length());
        disallowed_ = new ResourceWithPermissions[](_disallowedResources.length());

        for (uint256 i = 0; i < allowed_.length; i++) {
            allowed_[i].resource = _allowedResources.at(i);
            allowed_[i].permissions = _allowedPermissions[allowed_[i].resource].values();
        }

        for (uint256 i = 0; i < disallowed_.length; i++) {
            disallowed_[i].resource = _disallowedResources.at(i);
            disallowed_[i].permissions = _disallowedPermissions[disallowed_[i].resource].values();
        }
    }

    /**
     * @notice The function to check the user's possession of the role
     *
     * @dev DO NOT call `super.hasPermission(...)` in derived contracts, because this method
     * handles not 2 but 3 states: NO PERMISSION, ALLOWED, DISALLOWED
     *
     * @param who_ the user
     * @param resource_ the resource the user has to have the permission of
     * @param permission_ the permission the user has to have
     * @return isAllowed_ true if the user has the permission, false otherwise
     */
    function hasPermission(
        address who_,
        string memory resource_,
        string memory permission_
    ) public view virtual override returns (bool isAllowed_) {
        string[] memory roles_ = getUserRoles(who_);

        for (uint256 i = 0; i < roles_.length; i++) {
            string memory role_ = roles_[i];

            if (_isDisallowed(role_, resource_, permission_)) {
                return false;
            }

            isAllowed_ = isAllowed_ || _isAllowed(role_, resource_, permission_);
        }
    }

    /**
     * @notice The internal function to grant roles
     * @param to_ the user to grant roles to
     * @param rolesToGrant_ the roles to grant
     */
    function _grantRoles(address to_, string[] memory rolesToGrant_) internal {
        _userRoles[to_].add(rolesToGrant_);

        emit GrantedRoles(to_, rolesToGrant_);
    }

    /**
     * @notice The internal function to revoke roles
     * @param from_ the user to revoke roles from
     * @param rolesToRevoke_ the roles to revoke
     */
    function _revokeRoles(address from_, string[] memory rolesToRevoke_) internal {
        _userRoles[from_].remove(rolesToRevoke_);

        emit RevokedRoles(from_, rolesToRevoke_);
    }

    /**
     * @notice The internal function to add permission to the role
     * @param role_ the role to add permissions to
     * @param resourceToAdd_ the resource to which the permissions belong
     * @param permissionsToAdd_ the permissions of the resource
     * @param allowed_ whether to add permissions to the allowlist or the disallowlist
     */
    function _addPermissionsToRole(
        string memory role_,
        string memory resourceToAdd_,
        string[] memory permissionsToAdd_,
        bool allowed_
    ) internal {
        StringSet.Set storage _resources = _roleResources[role_][allowed_];
        StringSet.Set storage _permissions = _rolePermissions[role_][allowed_][resourceToAdd_];

        _permissions.add(permissionsToAdd_);
        _resources.add(resourceToAdd_);

        emit AddedPermissions(role_, resourceToAdd_, permissionsToAdd_, allowed_);
    }

    /**
     * @notice The internal function to remove permissions from the role
     * @param role_ the role to remove permissions from
     * @param resourceToRemove_ the resource to which the permissions belong
     * @param permissionsToRemove_ the permissions of the resource
     * @param allowed_ whether to remove permissions from the allowlist or the disallowlist
     */
    function _removePermissionsFromRole(
        string memory role_,
        string memory resourceToRemove_,
        string[] memory permissionsToRemove_,
        bool allowed_
    ) internal {
        StringSet.Set storage _resources = _roleResources[role_][allowed_];
        StringSet.Set storage _permissions = _rolePermissions[role_][allowed_][resourceToRemove_];

        _permissions.remove(permissionsToRemove_);

        if (_permissions.length() == 0) {
            _resources.remove(resourceToRemove_);
        }

        emit RemovedPermissions(role_, resourceToRemove_, permissionsToRemove_, allowed_);
    }

    /**
     * @notice The function to check if the role has the permission
     * @param role_ the role to search the permission in
     * @param resource_ the role resource to search the permission in
     * @param permission_ the permission to search
     * @return true_ if the role has the permission, false otherwise
     */
    function _isAllowed(
        string memory role_,
        string memory resource_,
        string memory permission_
    ) internal view returns (bool) {
        mapping(string => StringSet.Set) storage _resources = _rolePermissions[role_][true];

        StringSet.Set storage _allAllowed = _resources[ALL_RESOURCE];
        StringSet.Set storage _allowed = _resources[resource_];

        return (_allAllowed.contains(ALL_PERMISSION) ||
            _allAllowed.contains(permission_) ||
            _allowed.contains(ALL_PERMISSION) ||
            _allowed.contains(permission_));
    }

    /**
     * @notice The function to check if the role has the antipermission
     * @param role_ the role to search the antipermission in
     * @param resource_ the role resource to search the antipermission in
     * @param permission_ the antipermission to search
     * @return true_ if the role has the antipermission, false otherwise
     */
    function _isDisallowed(
        string memory role_,
        string memory resource_,
        string memory permission_
    ) internal view returns (bool) {
        mapping(string => StringSet.Set) storage _resources = _rolePermissions[role_][false];

        StringSet.Set storage _allDisallowed = _resources[ALL_RESOURCE];
        StringSet.Set storage _disallowed = _resources[resource_];

        return (_allDisallowed.contains(ALL_PERMISSION) ||
            _allDisallowed.contains(permission_) ||
            _disallowed.contains(ALL_PERMISSION) ||
            _disallowed.contains(permission_));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {TransparentProxyUpgrader} from "../proxy/transparent/TransparentProxyUpgrader.sol";
import {AbstractDependant} from "./AbstractDependant.sol";

/**
 * @notice The ContractsRegistry module
 *
 * For more information please refer to [EIP-6224](https://eips.ethereum.org/EIPS/eip-6224).
 *
 * The purpose of this module is to provide an organized registry of the project's smart contracts
 * together with the upgradeability and dependency injection mechanisms.
 *
 * The ContractsRegistry should be used as the highest level smart contract that is aware of any other
 * contract present in the system. The contracts that demand other system's contracts would then inherit
 * special `AbstractDependant` contract and override `setDependencies()` function to enable ContractsRegistry
 * to inject dependencies into them.
 *
 * The ContractsRegistry will help with the following use cases:
 *
 * 1) Making the system upgradeable
 * 2) Making the system contracts-interchangeable
 * 3) Simplifying the contracts management and deployment
 *
 * The ContractsRegistry acts as a TransparentProxy deployer. One can add proxy-compatible implementations to the registry
 * and deploy proxies to them. Then these proxies can be upgraded easily using the provided interface.
 * The ContractsRegistry itself can be deployed behind a proxy as well.
 *
 * The dependency injection system may come in handy when one wants to substitute a contract `A` with a contract `B`
 * (for example contract `A` got exploited) without a necessity of redeploying the whole system. One would just add
 * a new `B` contract to a ContractsRegistry and re-inject all the required dependencies. Dependency injection mechanism
 * is also meant to be compatible with factories.
 *
 * Users may also fetch all the contracts present in the system as they are now located in a single place.
 */
abstract contract AbstractContractsRegistry is Initializable {
    TransparentProxyUpgrader private _proxyUpgrader;

    mapping(string => address) private _contracts;
    mapping(address => bool) private _isProxy;

    event ContractAdded(string name, address contractAddress);
    event ProxyContractAdded(string name, address contractAddress, address implementation);
    event ProxyContractUpgraded(string name, address newImplementation);
    event ContractRemoved(string name);

    /**
     * @notice The initialization function
     */
    function __ContractsRegistry_init() internal onlyInitializing {
        _proxyUpgrader = new TransparentProxyUpgrader();
    }

    /**
     * @notice The function that returns an associated contract with the name
     * @param name_ the name of the contract
     * @return the address of the contract
     */
    function getContract(string memory name_) public view returns (address) {
        address contractAddress_ = _contracts[name_];

        require(contractAddress_ != address(0), "ContractsRegistry: this mapping doesn't exist");

        return contractAddress_;
    }

    /**
     * @notice The function that checks if a contract with a given name has been added
     * @param name_ the name of the contract
     * @return true if the contract is present in the registry
     */
    function hasContract(string memory name_) public view returns (bool) {
        return _contracts[name_] != address(0);
    }

    /**
     * @notice The function that returns the admin of the added proxy contracts
     * @return the proxy admin address
     */
    function getProxyUpgrader() public view returns (address) {
        return address(_proxyUpgrader);
    }

    /**
     * @notice The function that returns an implementation of the given proxy contract
     * @param name_ the name of the contract
     * @return the implementation address
     */
    function getImplementation(string memory name_) public view returns (address) {
        address contractProxy_ = _contracts[name_];

        require(contractProxy_ != address(0), "ContractsRegistry: this mapping doesn't exist");
        require(_isProxy[contractProxy_], "ContractsRegistry: not a proxy contract");

        return _proxyUpgrader.getImplementation(contractProxy_);
    }

    /**
     * @notice The function that injects the dependencies into the given contract
     * @param name_ the name of the contract
     */
    function _injectDependencies(string memory name_) internal virtual {
        _injectDependenciesWithData(name_, bytes(""));
    }

    /**
     * @notice The function that injects the dependencies into the given contract with data
     * @param name_ the name of the contract
     * @param data_ the extra context data
     */
    function _injectDependenciesWithData(
        string memory name_,
        bytes memory data_
    ) internal virtual {
        address contractAddress_ = _contracts[name_];

        require(contractAddress_ != address(0), "ContractsRegistry: this mapping doesn't exist");

        AbstractDependant dependant_ = AbstractDependant(contractAddress_);
        dependant_.setDependencies(address(this), data_);
    }

    /**
     * @notice The function to upgrade added proxy contract with a new implementation
     * @param name_ the name of the proxy contract
     * @param newImplementation_ the new implementation the proxy should be upgraded to
     *
     * It is the Owner's responsibility to ensure the compatibility between implementations
     */
    function _upgradeContract(string memory name_, address newImplementation_) internal virtual {
        _upgradeContractAndCall(name_, newImplementation_, bytes(""));
    }

    /**
     * @notice The function to upgrade added proxy contract with a new implementation, providing data
     * @param name_ the name of the proxy contract
     * @param newImplementation_ the new implementation the proxy should be upgraded to
     * @param data_ the data that the new implementation will be called with. This can be an ABI encoded function call
     *
     * It is the Owner's responsibility to ensure the compatibility between implementations
     */
    function _upgradeContractAndCall(
        string memory name_,
        address newImplementation_,
        bytes memory data_
    ) internal virtual {
        address contractToUpgrade_ = _contracts[name_];

        require(contractToUpgrade_ != address(0), "ContractsRegistry: this mapping doesn't exist");
        require(_isProxy[contractToUpgrade_], "ContractsRegistry: not a proxy contract");

        _proxyUpgrader.upgrade(contractToUpgrade_, newImplementation_, data_);

        emit ProxyContractUpgraded(name_, newImplementation_);
    }

    /**
     * @notice The function to add pure contracts to the ContractsRegistry. These should either be
     * the contracts the system does not have direct upgradeability control over, or the contracts that are not upgradeable
     * @param name_ the name to associate the contract with
     * @param contractAddress_ the address of the contract
     */
    function _addContract(string memory name_, address contractAddress_) internal virtual {
        require(contractAddress_ != address(0), "ContractsRegistry: zero address is forbidden");

        _contracts[name_] = contractAddress_;

        emit ContractAdded(name_, contractAddress_);
    }

    /**
     * @notice The function to add the contracts and deploy the proxy above them. It should be used to add
     * contract that the ContractsRegistry should be able to upgrade
     * @param name_ the name to associate the contract with
     * @param contractAddress_ the address of the implementation
     */
    function _addProxyContract(string memory name_, address contractAddress_) internal virtual {
        _addProxyContractAndCall(name_, contractAddress_, bytes(""));
    }

    /**
     * @notice The function to add the contracts and deploy the proxy above them. It should be used to add
     * contract that the ContractsRegistry should be able to upgrade
     * @param name_ the name to associate the contract with
     * @param contractAddress_ the address of the implementation
     * @param data_ the additional proxy initialization data
     */
    function _addProxyContractAndCall(
        string memory name_,
        address contractAddress_,
        bytes memory data_
    ) internal virtual {
        require(contractAddress_ != address(0), "ContractsRegistry: zero address is forbidden");

        address proxyAddr_ = _deployProxy(contractAddress_, address(_proxyUpgrader), data_);

        _contracts[name_] = proxyAddr_;
        _isProxy[proxyAddr_] = true;

        emit ProxyContractAdded(name_, proxyAddr_, contractAddress_);
    }

    /**
     * @notice The function to add the already deployed proxy to the ContractsRegistry. This might be used
     * when the system migrates to a new ContractRegistry. This means that the new ProxyUpgrader must have the
     * credentials to upgrade the added proxies
     * @param name_ the name to associate the contract with
     * @param contractAddress_ the address of the proxy
     */
    function _justAddProxyContract(
        string memory name_,
        address contractAddress_
    ) internal virtual {
        require(contractAddress_ != address(0), "ContractsRegistry: zero address is forbidden");

        _contracts[name_] = contractAddress_;
        _isProxy[contractAddress_] = true;

        emit ProxyContractAdded(
            name_,
            contractAddress_,
            _proxyUpgrader.getImplementation(contractAddress_)
        );
    }

    /**
     * @notice The function to remove the contract from the ContractsRegistry
     * @param name_ the associated name with the contract
     */
    function _removeContract(string memory name_) internal virtual {
        address contractAddress_ = _contracts[name_];

        require(contractAddress_ != address(0), "ContractsRegistry: this mapping doesn't exist");

        delete _isProxy[contractAddress_];
        delete _contracts[name_];

        emit ContractRemoved(name_);
    }

    /**
     * @notice The utility function to deploy a Transparent Proxy contract to be used within the registry
     * @param contractAddress_ the implementation address
     * @param admin_ the proxy admin to be set
     * @param data_ the proxy initialization data
     * @return the address of a Transparent Proxy
     */
    function _deployProxy(
        address contractAddress_,
        address admin_,
        bytes memory data_
    ) internal virtual returns (address) {
        return address(new TransparentUpgradeableProxy(contractAddress_, admin_, data_));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The ContractsRegistry module
 *
 * The contract that must be used as dependencies accepter in the dependency injection mechanism.
 * Upon the injection, the Injector (ContractsRegistry most of the time) will call the `setDependencies()` function.
 * The dependant contract will have to pull the required addresses from the supplied ContractsRegistry as a parameter.
 *
 * The AbstractDependant is fully compatible with proxies courtesy of custom storage slot.
 */
abstract contract AbstractDependant {
    /**
     * @notice The slot where the dependency injector is located.
     *
     * @dev bytes32(uint256(keccak256("eip6224.dependant.slot")) - 1)
     *
     * Only the injector is allowed to inject dependencies.
     * The first to call the setDependencies() (with the modifier applied) function becomes an injector
     */
    bytes32 private constant _INJECTOR_SLOT =
        0x3d1f25f1ac447e55e7fec744471c4dab1c6a2b6ffb897825f9ea3d2e8c9be583;

    modifier dependant() {
        _checkInjector();
        _;
        _setInjector(msg.sender);
    }

    /**
     * @notice The function that will be called from the ContractsRegistry (or factory) to inject dependencies.
     *
     * The Dependant must apply `dependant()` modifier to this function
     *
     * @param contractsRegistry_ the registry to pull dependencies from
     * @param data_ the extra data that might provide additional context
     */
    function setDependencies(address contractsRegistry_, bytes memory data_) public virtual;

    /**
     * @notice The function is made external to allow for the factories to set the injector to the ContractsRegistry
     * @param injector_ the new injector
     */
    function setInjector(address injector_) external {
        _checkInjector();
        _setInjector(injector_);
    }

    /**
     * @notice The function to get the current injector
     * @return injector_ the current injector
     */
    function getInjector() public view returns (address injector_) {
        bytes32 slot_ = _INJECTOR_SLOT;

        assembly {
            injector_ := sload(slot_)
        }
    }

    /**
     * @notice Internal function that sets the injector
     */
    function _setInjector(address injector_) internal {
        bytes32 slot_ = _INJECTOR_SLOT;

        assembly {
            sstore(slot_, injector_)
        }
    }

    /**
     * @notice Internal function that checks the injector credentials
     */
    function _checkInjector() internal view {
        address injector_ = getInjector();

        require(injector_ == address(0) || injector_ == msg.sender, "Dependant: not an injector");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The RBAC module
 */
interface IRBACGroupable {
    event AddedToGroups(address who, string[] groupsToAddTo);
    event RemovedFromGroups(address who, string[] groupsToRemoveFrom);

    event GrantedGroupRoles(string groupTo, string[] rolesToGrant);
    event RevokedGroupRoles(string groupFrom, string[] rolesToRevoke);

    event ToggledDefaultGroup(bool defaultGroupEnabled);

    /**
     * @notice The function to assign the user to groups
     * @param who_ the user to be assigned
     * @param groupsToAddTo_ the list of groups to assign the user to
     */
    function addUserToGroups(address who_, string[] calldata groupsToAddTo_) external;

    /**
     * @notice The function to remove the user from groups
     * @param who_ the user to be removed from groups
     * @param groupsToRemoveFrom_ the list of groups to remove the user from
     */
    function removeUserFromGroups(address who_, string[] calldata groupsToRemoveFrom_) external;

    /**
     * @notice The function to grant roles to the group
     * @param groupTo_ the group to grant roles to
     * @param rolesToGrant_ the list of roles to grant
     */
    function grantGroupRoles(string calldata groupTo_, string[] calldata rolesToGrant_) external;

    /**
     * @notice The function to revoke roles from the group
     * @param groupFrom_ the group to revoke roles from
     * @param rolesToRevoke_ the list of roles to revoke
     */
    function revokeGroupRoles(
        string calldata groupFrom_,
        string[] calldata rolesToRevoke_
    ) external;

    /**
     * @notice The function to toggle the default group state. When `defaultGroupEnabled` is set
     * to true, the default group is enabled, otherwise it is disabled
     */
    function toggleDefaultGroup() external;

    /**
     * @notice The function to get the list of user groups
     * @param who_ the user
     * @return groups_ the list of user groups
     */
    function getUserGroups(address who_) external view returns (string[] calldata groups_);

    /**
     * @notice The function to get the list of groups roles
     * @param group_ the group
     * @return roles_ the list of group roles
     */
    function getGroupRoles(
        string calldata group_
    ) external view returns (string[] calldata roles_);

    /**
     * @notice The function to get the current state of the default group
     * @return defaultGroupEnabled_ the boolean indicating whether the default group is enabled
     */
    function getDefaultGroupEnabled() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {StringSet} from "../../libs/data-structures/StringSet.sol";

/**
 * @notice The RBAC module
 */
interface IRBAC {
    struct ResourceWithPermissions {
        string resource;
        string[] permissions;
    }

    event GrantedRoles(address to, string[] rolesToGrant);
    event RevokedRoles(address from, string[] rolesToRevoke);

    event AddedPermissions(string role, string resource, string[] permissionsToAdd, bool allowed);
    event RemovedPermissions(
        string role,
        string resource,
        string[] permissionsToRemove,
        bool allowed
    );

    /**
     * @notice The function to grant roles to a user
     * @param to_ the user to grant roles to
     * @param rolesToGrant_ roles to grant
     */
    function grantRoles(address to_, string[] calldata rolesToGrant_) external;

    /**
     * @notice The function to revoke roles
     * @param from_ the user to revoke roles from
     * @param rolesToRevoke_ the roles to revoke
     */
    function revokeRoles(address from_, string[] calldata rolesToRevoke_) external;

    /**
     * @notice The function to add resource permission to role
     * @param role_ the role to add permissions to
     * @param permissionsToAdd_ the array of resources and permissions to add to the role
     * @param allowed_ indicates whether to add permissions to an allowlist or disallowlist
     */
    function addPermissionsToRole(
        string calldata role_,
        ResourceWithPermissions[] calldata permissionsToAdd_,
        bool allowed_
    ) external;

    /**
     * @notice The function to remove permissions from role
     * @param role_ the role to remove permissions from
     * @param permissionsToRemove_ the array of resources and permissions to remove from the role
     * @param allowed_ indicates whether to remove permissions from the allowlist or disallowlist
     */
    function removePermissionsFromRole(
        string calldata role_,
        ResourceWithPermissions[] calldata permissionsToRemove_,
        bool allowed_
    ) external;

    /**
     * @notice The function to get the list of user roles
     * @param who_ the user
     * @return roles_ the roles of the user
     */
    function getUserRoles(address who_) external view returns (string[] calldata roles_);

    /**
     * @notice The function to get the permissions of the role
     * @param role_ the role
     * @return allowed_ the list of allowed permissions of the role
     * @return disallowed_ the list of disallowed permissions of the role
     */
    function getRolePermissions(
        string calldata role_
    )
        external
        view
        returns (
            ResourceWithPermissions[] calldata allowed_,
            ResourceWithPermissions[] calldata disallowed_
        );

    /**
     * @notice The function to check the user's possession of the role
     *
     * @dev DO NOT call `super.hasPermission(...)` in derived contracts, because this method
     * handles not 2 but 3 states: NO PERMISSION, ALLOWED, DISALLOWED
     *
     * @param who_ the user
     * @param resource_ the resource the user has to have the permission of
     * @param permission_ the permission the user has to have
     * @return isAllowed_ true if the user has the permission, false otherwise
     */
    function hasPermission(
        address who_,
        string calldata resource_,
        string calldata permission_
    ) external view returns (bool isAllowed_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {StringSet} from "../data-structures/StringSet.sol";

/**
 * @notice A simple library to work with Openzeppelin sets
 */
library SetHelper {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using StringSet for StringSet.Set;

    /**
     * @notice The function to insert an array of elements into the address set
     * @param set the set to insert the elements into
     * @param array_ the elements to be inserted
     */
    function add(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the uint256 set
     */
    function add(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the string set
     */
    function add(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the address set
     * @param set the set to remove the elements from
     * @param array_ the elements to be removed
     */
    function remove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the uint256 set
     */
    function remove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the string set
     */
    function remove(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TypeCaster} from "../utils/TypeCaster.sol";

/**
 * @notice The library that realizes a heap based priority queue.
 *
 * Courtesy of heap property,
 * add() and removeTop() operations are O(log(n)) complex
 * top(), topValue() operations are O(1)
 *
 * The library might be useful to implement priority withdrawals/purchases, reputation based systems, and similar logic.
 *
 * The library is a maximal priority queue. The element with the highest priority is the topmost element.
 * If you wish a minimal queue, change the priority of the elements to type(uint256).max - priority.
 *
 * IMPORTANT
 * The queue order of the elements is NOT guaranteed.
 * The interaction with the data structure must be made via the topmost element only.
 *
 * ## Usage example:
 *
 * ```
 * using PriorityQueue for PriorityQueue.UintQueue;
 * using PriorityQueue for PriorityQueue.AddressQueue;
 * using PriorityQueue for PriorityQueue.Bytes32Queue;
 * ```
 */
library PriorityQueue {
    using TypeCaster for *;

    /**
     ************************
     *      UintQueue       *
     ************************
     */

    struct UintQueue {
        Queue _queue;
    }

    /**
     * @notice The function to add an element to the uint256 queue. O(log(n)) complex
     * @param queue self
     * @param value_ the element value
     * @param priority_ the element priority
     */
    function add(UintQueue storage queue, uint256 value_, uint256 priority_) internal {
        _add(queue._queue, bytes32(value_), priority_);
    }

    /**
     * @notice The function to remove the element with the highest priority. O(log(n)) complex
     * @param queue self
     */
    function removeTop(UintQueue storage queue) internal {
        _removeTop(queue._queue);
    }

    /**
     * @notice The function to read the value of the element with the highest priority. O(1) complex
     * @param queue self
     * @return the value of the element with the highest priority
     */
    function topValue(UintQueue storage queue) internal view returns (uint256) {
        return uint256(_topValue(queue._queue));
    }

    /**
     * @notice The function to read the element with the highest priority. O(1) complex
     * @param queue self
     * @return the element with the highest priority
     */
    function top(UintQueue storage queue) internal view returns (uint256, uint256) {
        (bytes32 value_, uint256 priority_) = _top(queue._queue);

        return (uint256(value_), priority_);
    }

    /**
     * @notice The function to read the size of the queue. O(1) complex
     * @param queue self
     * @return the size of the queue
     */
    function length(UintQueue storage queue) internal view returns (uint256) {
        return _length(queue._queue);
    }

    /**
     * @notice The function to get the values stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     * @param queue self
     * @return values_ the values of the elements stored
     */
    function values(UintQueue storage queue) internal view returns (uint256[] memory values_) {
        return _values(queue._queue).asUint256Array();
    }

    /**
     * @notice The function to get the values and priorities stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     * @param queue self
     * @return values_ the values of the elements stored
     * @return priorities_ the priorities of the elements stored
     */
    function elements(
        UintQueue storage queue
    ) internal view returns (uint256[] memory values_, uint256[] memory priorities_) {
        return (_values(queue._queue).asUint256Array(), _priorities(queue._queue));
    }

    /**
     ************************
     *     Bytes32Queue     *
     ************************
     */

    struct Bytes32Queue {
        Queue _queue;
    }

    /**
     * @notice The function to add an element to the bytes32 queue. O(log(n)) complex
     */
    function add(Bytes32Queue storage queue, bytes32 value_, uint256 priority_) internal {
        _add(queue._queue, value_, priority_);
    }

    /**
     * @notice The function to remove the element with the highest priority. O(log(n)) complex
     */
    function removeTop(Bytes32Queue storage queue) internal {
        _removeTop(queue._queue);
    }

    /**
     * @notice The function to read the value of the element with the highest priority. O(1) complex
     */
    function topValue(Bytes32Queue storage queue) internal view returns (bytes32) {
        return _topValue(queue._queue);
    }

    /**
     * @notice The function to read the element with the highest priority. O(1) complex
     */
    function top(Bytes32Queue storage queue) internal view returns (bytes32, uint256) {
        return _top(queue._queue);
    }

    /**
     * @notice The function to read the size of the queue. O(1) complex
     */
    function length(Bytes32Queue storage queue) internal view returns (uint256) {
        return _length(queue._queue);
    }

    /**
     * @notice The function to get the values stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     */
    function values(Bytes32Queue storage queue) internal view returns (bytes32[] memory values_) {
        values_ = _values(queue._queue);
    }

    /**
     * @notice The function to get the values and priorities stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     */
    function elements(
        Bytes32Queue storage queue
    ) internal view returns (bytes32[] memory values_, uint256[] memory priorities_) {
        values_ = _values(queue._queue);
        priorities_ = _priorities(queue._queue);
    }

    /**
     ************************
     *     AddressQueue     *
     ************************
     */

    struct AddressQueue {
        Queue _queue;
    }

    /**
     * @notice The function to add an element to the address queue. O(log(n)) complex
     */
    function add(AddressQueue storage queue, address value_, uint256 priority_) internal {
        _add(queue._queue, bytes32(uint256(uint160(value_))), priority_);
    }

    /**
     * @notice The function to remove the element with the highest priority. O(log(n)) complex
     */
    function removeTop(AddressQueue storage queue) internal {
        _removeTop(queue._queue);
    }

    /**
     * @notice The function to read the value of the element with the highest priority. O(1) complex
     */
    function topValue(AddressQueue storage queue) internal view returns (address) {
        return address(uint160(uint256(_topValue(queue._queue))));
    }

    /**
     * @notice The function to read the element with the highest priority. O(1) complex
     */
    function top(AddressQueue storage queue) internal view returns (address, uint256) {
        (bytes32 value_, uint256 priority_) = _top(queue._queue);

        return (address(uint160(uint256(value_))), priority_);
    }

    /**
     * @notice The function to read the size of the queue. O(1) complex
     */
    function length(AddressQueue storage queue) internal view returns (uint256) {
        return _length(queue._queue);
    }

    /**
     * @notice The function to get the values stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     */
    function values(AddressQueue storage queue) internal view returns (address[] memory values_) {
        return _values(queue._queue).asAddressArray();
    }

    /**
     * @notice The function to get the values and priorities stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     */
    function elements(
        AddressQueue storage queue
    ) internal view returns (address[] memory values_, uint256[] memory priorities_) {
        return (_values(queue._queue).asAddressArray(), _priorities(queue._queue));
    }

    /**
     ************************
     *    Internal Queue    *
     ************************
     */

    struct Queue {
        bytes32[] _values;
        uint256[] _priorities;
    }

    function _add(Queue storage queue, bytes32 value_, uint256 priority_) private {
        queue._values.push(value_);
        queue._priorities.push(priority_);

        _shiftUp(queue, queue._values.length - 1);
    }

    function _removeTop(Queue storage queue) private {
        _requireNotEmpty(queue);

        uint256 length_ = _length(queue);

        queue._values[0] = queue._values[length_ - 1];
        queue._priorities[0] = queue._priorities[length_ - 1];

        queue._values.pop();
        queue._priorities.pop();

        _shiftDown(queue, 0);
    }

    function _topValue(Queue storage queue) private view returns (bytes32) {
        _requireNotEmpty(queue);

        return queue._values[0];
    }

    function _top(Queue storage queue) private view returns (bytes32, uint256) {
        return (_topValue(queue), queue._priorities[0]);
    }

    function _length(Queue storage queue) private view returns (uint256) {
        return queue._values.length;
    }

    function _values(Queue storage queue) private view returns (bytes32[] memory) {
        return queue._values;
    }

    function _priorities(Queue storage queue) private view returns (uint256[] memory) {
        return queue._priorities;
    }

    function _shiftUp(Queue storage queue, uint256 index_) private {
        uint256 priority_ = queue._priorities[index_];

        while (index_ > 0) {
            uint256 parent_ = _parent(index_);

            if (queue._priorities[parent_] >= priority_) {
                break;
            }

            _swap(queue, parent_, index_);

            index_ = parent_;
        }
    }

    function _shiftDown(Queue storage queue, uint256 index_) private {
        while (true) {
            uint256 maxIndex_ = _maxPriorityIndex(queue, index_);

            if (index_ == maxIndex_) {
                break;
            }

            _swap(queue, maxIndex_, index_);

            index_ = maxIndex_;
        }
    }

    function _swap(Queue storage queue, uint256 index1_, uint256 index2_) private {
        bytes32[] storage _vals = queue._values;
        uint256[] storage _priors = queue._priorities;

        (_vals[index1_], _vals[index2_]) = (_vals[index2_], _vals[index1_]);
        (_priors[index1_], _priors[index2_]) = (_priors[index2_], _priors[index1_]);
    }

    function _maxPriorityIndex(
        Queue storage queue,
        uint256 index_
    ) private view returns (uint256) {
        uint256[] storage _priors = queue._priorities;

        uint256 length_ = _priors.length;
        uint256 maxIndex_ = index_;

        uint256 child_ = _leftChild(index_);

        if (child_ < length_ && _priors[child_] > _priors[maxIndex_]) {
            maxIndex_ = child_;
        }

        child_ = _rightChild(index_);

        if (child_ < length_ && _priors[child_] > _priors[maxIndex_]) {
            maxIndex_ = child_;
        }

        return maxIndex_;
    }

    function _parent(uint256 index_) private pure returns (uint256) {
        return (index_ - 1) / 2;
    }

    function _leftChild(uint256 index_) private pure returns (uint256) {
        return index_ * 2 + 1;
    }

    function _rightChild(uint256 index_) private pure returns (uint256) {
        return index_ * 2 + 2;
    }

    function _requireNotEmpty(Queue storage queue) private view {
        require(_length(queue) > 0, "PriorityQueue: empty queue");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The string extension to Openzeppelin sets
 *
 * ## Usage example:
 *
 * ```
 * using StringSet for StringSet.Set;
 *
 * StringSet.Set internal set;
 * ```
 */
library StringSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     * @notice The function add value to set
     * @param set the set object
     * @param value_ the value to add
     */
    function add(Set storage set, string memory value_) internal returns (bool) {
        if (!contains(set, value_)) {
            set._values.push(value_);
            set._indexes[value_] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function remove value to set
     * @param set the set object
     * @param value_ the value to remove
     */
    function remove(Set storage set, string memory value_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[value_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                string memory lastValue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastValue_;
                set._indexes[lastValue_] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[value_];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function returns true if value in the set
     * @param set the set object
     * @param value_ the value to search in set
     * @return true if value is in the set, false otherwise
     */
    function contains(Set storage set, string memory value_) internal view returns (bool) {
        return set._indexes[value_] != 0;
    }

    /**
     * @notice The function returns length of set
     * @param set the set object
     * @return the the number of elements in the set
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @notice The function returns value from set by index
     * @param set the set object
     * @param index_ the index of slot in set
     * @return the value at index
     */
    function at(Set storage set, uint256 index_) internal view returns (string memory) {
        return set._values[index_];
    }

    /**
     * @notice The function that returns values the set stores, can be very expensive to call
     * @param set the set object
     * @return the memory array of values
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice This library simplifies non-obvious type castings.
 *
 * Convertions from static to dynamic arrays, singleton arrays, and arrays of different types are supported.
 */
library TypeCaster {
    /**
     * @notice The function that casts the bytes32 array to the uint256 array
     * @param from_ the bytes32 array
     * @return array_ the uint256 array
     */
    function asUint256Array(
        bytes32[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the address array to the uint256 array
     */
    function asUint256Array(
        address[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the bytes32 array to the address array
     * @param from_ the bytes32 array
     * @return array_ the list of addresses
     */
    function asAddressArray(
        bytes32[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the uint256 array to the address array
     */
    function asAddressArray(
        uint256[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the uint256 array to the bytes32 array
     * @param from_ the bytes32 array
     * @return array_ the list of addresses
     */
    function asBytes32Array(
        uint256[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the address array to the bytes32 array
     */
    function asBytes32Array(
        address[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function to transform a uint256 element into an array
     * @param from_ the element
     * @return array_ the element as an array
     */
    function asSingletonArray(uint256 from_) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform an address element into an array
     */
    function asSingletonArray(address from_) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform a bool element into an array
     */
    function asSingletonArray(bool from_) internal pure returns (bool[] memory array_) {
        array_ = new bool[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform a string element into an array
     */
    function asSingletonArray(string memory from_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform a bytes32 element into an array
     */
    function asSingletonArray(bytes32 from_) internal pure returns (bytes32[] memory array_) {
        array_ = new bytes32[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to convert static uint256[1] array to dynamic
     * @param static_ the static array to convert
     * @return dynamic_ the converted dynamic array
     */
    function asDynamic(
        uint256[1] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static uint256[2] array to dynamic
     */
    function asDynamic(
        uint256[2] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static uint256[3] array to dynamic
     */
    function asDynamic(
        uint256[3] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static uint256[4] array to dynamic
     */
    function asDynamic(
        uint256[4] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static uint256[5] array to dynamic
     */
    function asDynamic(
        uint256[5] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static address[1] array to dynamic
     */
    function asDynamic(
        address[1] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static address[2] array to dynamic
     */
    function asDynamic(
        address[2] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static address[3] array to dynamic
     */
    function asDynamic(
        address[3] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static address[4] array to dynamic
     */
    function asDynamic(
        address[4] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static address[5] array to dynamic
     */
    function asDynamic(
        address[5] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static bool[1] array to dynamic
     */
    function asDynamic(bool[1] memory static_) internal pure returns (bool[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static bool[2] array to dynamic
     */
    function asDynamic(bool[2] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static bool[3] array to dynamic
     */
    function asDynamic(bool[3] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static bool[4] array to dynamic
     */
    function asDynamic(bool[4] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static bool[5] array to dynamic
     */
    function asDynamic(bool[5] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static string[1] array to dynamic
     */
    function asDynamic(string[1] memory static_) internal pure returns (string[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static string[2] array to dynamic
     */
    function asDynamic(string[2] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static string[3] array to dynamic
     */
    function asDynamic(string[3] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static string[4] array to dynamic
     */
    function asDynamic(string[4] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static string[5] array to dynamic
     */
    function asDynamic(string[5] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static bytes32[1] array to dynamic
     */
    function asDynamic(
        bytes32[1] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static bytes32[2] array to dynamic
     */
    function asDynamic(
        bytes32[2] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static bytes32[3] array to dynamic
     */
    function asDynamic(
        bytes32[3] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static bytes32[4] array to dynamic
     */
    function asDynamic(
        bytes32[4] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static bytes32[5] array to dynamic
     */
    function asDynamic(
        bytes32[5] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice private function to copy memory
     */
    function _copy(uint256 locationS_, uint256 locationD_, uint256 length_) private pure {
        assembly {
            for {
                let i := 0
            } lt(i, length_) {
                i := add(i, 1)
            } {
                locationD_ := add(locationD_, 0x20)

                mstore(locationD_, mload(locationS_))

                locationS_ := add(locationS_, 0x20)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {PermanentOwnable} from "../../access-control/PermanentOwnable.sol";

/**
 * @notice The proxies module
 *
 * This is the lightweight helper contract that may be used as a TransparentProxy admin.
 */
contract TransparentProxyUpgrader is PermanentOwnable {
    using Address for address;

    constructor() PermanentOwnable(msg.sender) {}

    /**
     * @notice The function to upgrade the implementation contract
     * @param what_ the proxy contract to upgrade
     * @param to_ the new implementation contract
     * @param data_ arbitrary data the proxy will be called with after the upgrade
     */
    function upgrade(address what_, address to_, bytes calldata data_) external virtual onlyOwner {
        if (data_.length > 0) {
            ITransparentUpgradeableProxy(payable(what_)).upgradeToAndCall(to_, data_);
        } else {
            ITransparentUpgradeableProxy(payable(what_)).upgradeTo(to_);
        }
    }

    /**
     * @notice The function to get the address of the proxy implementation
     * @param what_ the proxy contract to observe
     * @return the implementation address
     */
    function getImplementation(address what_) public view virtual returns (address) {
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success_, bytes memory returndata_) = address(what_).staticcall(hex"5c60da1b");

        require(success_, "TransparentProxyUpgrader: not a proxy");

        return abi.decode(returndata_, (address));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant PRECISION = 10 ** 25;
uint256 constant DECIMAL = 10 ** 18;
uint256 constant PERCENTAGE_100 = 10 ** 27;

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ISupportedNFT} from "../interfaces/ISupportedNFT.sol";

import {NFTMintingHelper} from "../lib/NFTMintingHelper.sol";

/**
 * @title Base for NFT Minting Module
 *
 * @notice Designed for DAO integration, this module extends NFT minting capabilities. It acts as an interface
 * for interacting with existing functionalities in an associated NFT contract, utilizing functions like
 * predefined and arbitraryNFTExecute.
 *
 * @dev The module supports:
 *      - Basic minting operations through the mintTo function.
 *      - Interaction with the Ownable aspect of the NFT contract, including functions like transferOwnership.
 *      - The arbitraryNFTExecute function, allowing for more complex interactions with the NFT contract.
 *      - Batch minting with an optional automatic tokenId generation. When tokenIds are not specified,
 *        they are auto-generated based on the formula: block.timestamp + batchId, where batchId is the index
 *        of the token in the batch. This ensures unique and time-referenced tokenId for each NFT in the batch.
 *
 * This module's flexibility in NFT management makes it suitable for a variety of minting scenarios within a DAO ecosystem.
 */
abstract contract NFTMinting {
    using Address for address;

    using NFTMintingHelper for IERC721;

    string public NFT_MINTING_RESOURCE;

    ISupportedNFT public supportedNFT;

    uint256 public startPoint;

    modifier onlyCreatePermission() virtual {
        _;
    }

    modifier onlyUpdatePermission() virtual {
        _;
    }

    /**
     * @notice Initializes the contract with the given DAO registry and NFT token addresses.
     * @param token_ The address of the NFT token.
     */
    function __NFTMinting_init(
        address token_,
        uint256 startPoint_,
        string memory resource_
    ) internal {
        supportedNFT = ISupportedNFT(token_);

        if (startPoint_ == 0) {
            startPoint = IERC721(token_).lowerBound(0);
        } else {
            startPoint = startPoint_;
        }

        NFT_MINTING_RESOURCE = resource_;
    }

    /**
     * @notice Mints a new NFT with an automatically generated token ID to the specified address.
     *
     * @param to_ The address to mint the NFT to.
     * @dev The token ID is generated starting from a predetermined point. If the ID already exists,
     *      the next available ID is found using the NFTMintingHelper library.
     *
     *      Requirements:
     *        - The caller must have create permission.
     *        - The provided address must be valid and not zero.
     */
    function mintTo(address to_) public onlyCreatePermission {
        uint256 tokenId_ = startPoint++;

        if (IERC721(supportedNFT).isTokenExist(tokenId_)) {
            uint256 newTokenId_ = IERC721(supportedNFT).lowerBound(tokenId_);

            startPoint = newTokenId_ + 1;

            tokenId_ = newTokenId_;
        }

        supportedNFT.mintTo(to_, tokenId_, "");
    }

    /**
     * @notice Batch mints new NFTs with automatically generated token IDs to specified addresses.
     * @param recipients_ Array of addresses to mint the NFTs to.
     *
     * @dev Iterates over the recipients array, generating a new token ID for each recipient.
     *      In case of token ID collision, the next available ID is found using the NFTMintingHelper library.
     *
     *      Requirements:
     *        - The caller must have create permission.
     *        - The lengths of the recipients array must be valid.
     */
    function batchMintTo(address[] memory recipients_) public onlyCreatePermission {
        uint256 length_ = recipients_.length;
        uint256 startPoint_ = startPoint;

        ISupportedNFT nft_ = supportedNFT;

        for (uint256 i = 0; i < length_; ++i) {
            uint256 tokenId_ = startPoint_++;

            if (IERC721(supportedNFT).isTokenExist(tokenId_)) {
                uint256 newTokenId_ = IERC721(nft_).lowerBound(tokenId_);

                startPoint_ = newTokenId_ + 1;

                tokenId_ = newTokenId_;
            }

            nft_.mintTo(recipients_[i], tokenId_, "");
        }

        startPoint = startPoint_;
    }

    /**
     * @notice Transfers ownership of the NFT contract to the specified address.
     *
     * @param newOwner_ The address to transfer ownership to.
     *
     * @dev Requirements:
     *        - The caller must have update permission.
     */
    function transferOwnership(address newOwner_) external virtual onlyUpdatePermission {
        supportedNFT.transferOwnership(newOwner_);
    }

    /**
     * @notice Executes an arbitrary function on the NFT contract.
     * @param data_ The encoded data of the function to call.
     *
     * @dev Requirements:
     *        - The caller must have update permission.
     *
     * @return The bytes returned from the function call.
     */
    function arbitraryNFTExecute(
        bytes memory data_
    ) public onlyUpdatePermission returns (bytes memory) {
        return address(supportedNFT).functionCall(data_);
    }

    /**
     * @notice Checks if the NFT contract is owned by this module.
     * @dev Compares the owner of the supported NFT contract to the address of this module.
     * @return True if this module owns the NFT contract, false otherwise.
     */
    function isModuleNFTOwner() external view returns (bool) {
        return supportedNFT.owner() == address(this);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ISupportedNFT Interface
 * @notice Defines the interface for NFTs compatible with the NFT Minting Module.
 * @dev This interface extends IERC721 and includes additional functionalities specific to supported NFTs,
 * such as minting and ownership transfer. NFTs must comply with the ERC721 standard and be Ownable.
 */
interface ISupportedNFT is IERC721 {
    /**
     * @notice Mints a new NFT to a specified address.
     * @param to_ The address to receive the newly minted NFT.
     * @param tokenId_ The unique identifier for the new NFT.
     * @param tokenURI_ The URI containing metadata for the new NFT.
     * @dev Implementing contracts might impose additional requirements or restrictions for minting.
     */
    function mintTo(address to_, uint256 tokenId_, string calldata tokenURI_) external;

    /**
     * @notice Transfers the ownership of the NFT contract to a new address.
     * @param newOwner_ The address to become the new owner of the contract.
     * @dev Can only be called by the current owner of the contract.
     */
    function transferOwnership(address newOwner_) external;

    /**
     * @notice Retrieves the address of the current owner of the NFT contract.
     * @return The address of the current owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title NFT Minting Helper
 * @notice Provides utility functions to assist in NFT minting, particularly for identifying unowned token IDs.
 * @dev This library includes functions for efficiently finding the lower bound of unowned token IDs
 * in an ERC721 token contract and checking the existence of a token ID.
 */
library NFTMintingHelper {
    uint256 public constant MAX_ITERATIONS = 15;

    /**
     * @notice Finds the lowest unowned token ID greater than or equal to a given value.
     * @dev Performs a binary search to find the lower bound of unowned token IDs.
     * @param token_ The ERC721 token contract to search in.
     * @param low_ The starting point of the search.
     * @return index_ The lowest unowned token ID.
     */
    function lowerBound(IERC721 token_, uint256 low_) internal view returns (uint256 index_) {
        uint256 high_ = _getFirstUnownedTokenId(token_, low_);

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);

            if (!isTokenExist(token_, mid_)) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        return high_;
    }

    /**
     * @notice Checks if a token ID exists in the given ERC721 token contract.
     * @dev Uses a static call to `ownerOf` function of the ERC721 contract to determine token existence.
     * @param token_ The ERC721 token contract to check in.
     * @param tokenId_ The token ID to check.
     * @return true if the token ID exists, false otherwise.
     */
    function isTokenExist(IERC721 token_, uint256 tokenId_) internal view returns (bool) {
        (bool success_, bytes memory data_) = address(token_).staticcall(
            abi.encodeWithSelector(token_.ownerOf.selector, tokenId_)
        );

        return success_ && uint256(bytes32(data_)) != 0;
    }

    /**
     * @notice Finds the first unowned token ID greater than a given value.
     * @dev Iteratively doubles the search space until an unowned token ID is found or the maximum iterations are reached.
     * @param token_ The ERC721 token contract to search in.
     * @param low_ The starting point of the search.
     * @return index_ The first unowned token ID found.
     */
    function _getFirstUnownedTokenId(
        IERC721 token_,
        uint256 low_
    ) internal view returns (uint256 index_) {
        uint256 start_ = low_;
        uint256 counter_ = 0;

        while (isTokenExist(token_, start_)) {
            start_ = start_ * 2 + 1;

            if (counter_++ > MAX_ITERATIONS) {
                revert("NFTMinting: No free token ids found");
            }
        }

        return start_;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import {Router} from "@hyperlane-xyz/core/contracts/client/Router.sol";
import {StandardHookMetadata} from "@hyperlane-xyz/core/contracts/hooks/libs/StandardHookMetadata.sol";

import {AbstractDependant} from "@solarity/solidity-lib/contracts-registry/AbstractDependant.sol";
import {TypeCaster} from "@solarity/solidity-lib/libs/utils/TypeCaster.sol";

import "@q-dev/gdk-contracts/core/Globals.sol";

import {IDAOResource} from "@q-dev/gdk-contracts/interfaces/IDAOResource.sol";
import {IDAOIntegration} from "@q-dev/gdk-contracts/interfaces/IDAOIntegration.sol";
import {DAORegistry} from "@q-dev/gdk-contracts/DAO/DAORegistry.sol";
import {PermissionManager} from "@q-dev/gdk-contracts/DAO/PermissionManager.sol";
import {ArrayHelper} from "@q-dev/gdk-contracts/libs/utils/ArrayHelper.sol";

enum Action {
    MINT,
    BATCH_MINT,
    TRANSFER_NFT_OWNERSHIP,
    ARBITRARY_NFT_EXECUTE,
    TRANSFER_OWNERSHIP
}

struct MessageAction {
    address[] to;
    bytes data;
    Action action;
}

/**
 * @title Cross-chain NFT Minting Module
 * @notice Designed for DAOs to mint ERC20 tokens to specified users on another chain.
 */
contract CrossChainNFTMintingModule is
    IDAOResource,
    IDAOIntegration,
    ERC165,
    UUPSUpgradeable,
    AbstractDependant,
    Router
{
    using ArrayHelper for *;
    using TypeCaster for address;

    // A generous upper bound on the amount of gas to use in the handle
    // function when a message is processed. Used for paying for gas.
    uint256 public constant HANDLE_GAS_AMOUNT = 950_000;

    string public MODULE_RESOURCE;

    PermissionManager public permissionManager;

    uint32 public destinationDomain;

    string private _relatedExpertPanelName;

    event MessageSent(uint32 indexed origin, uint32 indexed destination, MessageAction action);

    modifier onlyCreatePermission() {
        _requirePermission(CREATE_PERMISSION);
        _;
    }

    modifier onlyUpdatePermission() {
        _requirePermission(UPDATE_PERMISSION);
        _;
    }

    constructor(address mailboxAddress_) Router(mailboxAddress_) {
        _transferOwnership(address(0));

        _disableInitializers();
    }

    receive() external payable {}

    function __CrossChainNFTMintingModule_init(
        uint32 remoteDomain_,
        address ism_,
        bytes32 remoteRouter_,
        string memory resource_,
        string memory relatedExpertPanelName_
    ) external initializer {
        _initialize(remoteDomain_, ism_, remoteRouter_, resource_, relatedExpertPanelName_);
    }

    function __CrossChainNFTMintingModule_initAndSetDeps(
        address registry_,
        uint32 remoteDomain_,
        address ism_,
        bytes32 remoteRouter_,
        string memory resource_,
        string memory relatedExpertPanelName_
    ) external initializer {
        setDependencies(registry_, new bytes(0));
        _setInjector(registry_);

        _initialize(remoteDomain_, ism_, remoteRouter_, resource_, relatedExpertPanelName_);
    }

    /**
     * @inheritdoc AbstractDependant
     */
    function setDependencies(address registry_, bytes memory) public override dependant {
        DAORegistry daoRegistry_ = DAORegistry(registry_);

        permissionManager = PermissionManager(daoRegistry_.getPermissionManager());
    }

    /**
     * @notice Relays a message to mint a new NFT on another chain with an automatically generated
     * token ID to the specified address.
     * @param to_ The address to mint the NFT to.
     * @dev Relays a message to another chain.
     *      Requirements:
     *        - The caller must have create permission.
     *        - The provided address must be valid and not zero.
     */
    function mintTo(address to_) external onlyCreatePermission {
        MessageAction memory operation_ = MessageAction(to_.asSingletonArray(), "0x", Action.MINT);

        _relayMessageAction(operation_);
    }

    /**
     * @notice Relays a message to batch mint new NFTs on another chain with automatically generated
     * token IDs to specified addresses.
     * @param recipients_ Array of addresses to mint the NFTs to.
     * @dev Relays a message to another chain.
     *      Requirements:
     *        - The caller must have create permission.
     *        - The lengths of the recipients array must be valid.
     */
    function batchMintTo(address[] memory recipients_) external onlyCreatePermission {
        MessageAction memory operation_ = MessageAction(recipients_, "0x", Action.BATCH_MINT);

        _relayMessageAction(operation_);
    }

    /**
     * @notice Relays a message to transfer ownership of the NFT contract on another chain
     * to the specified address.
     * @param newOwner_ The address to transfer ownership to.
     * @dev Requirements:
     *        - The caller must have update permission.
     */
    function transferNFTOwnership(address newOwner_) external onlyUpdatePermission {
        MessageAction memory operation_ = MessageAction(
            newOwner_.asSingletonArray(),
            "0x",
            Action.TRANSFER_NFT_OWNERSHIP
        );

        _relayMessageAction(operation_);
    }

    /**
     * @notice Executes an arbitrary function on the NFT contract on another chain.
     * @param data_ The encoded data of the function to call.
     * @dev Requirements:
     *        - The caller must have update permission.
     */
    function arbitraryNFTExecute(bytes calldata data_) external onlyUpdatePermission {
        MessageAction memory operation_ = MessageAction(
            address(0).asSingletonArray(),
            data_,
            Action.ARBITRARY_NFT_EXECUTE
        );

        _relayMessageAction(operation_);
    }

//may be innessesary, in case of ownership in mailbox
    /**
     * @notice Relays a message to transfer ownership of the foreign module on another chain
     * to the specified address.
     * @param newOwner_ The address to transfer ownership to.
     * @dev Requirements:
     *        - The caller must have update permission.
     */
    function transferForeignModuleOwnership(address newOwner_) external onlyUpdatePermission {
        MessageAction memory operation_ = MessageAction(
            newOwner_.asSingletonArray(),
            "0x",
            Action.TRANSFER_OWNERSHIP
        );

        _relayMessageAction(operation_);
    }

    /**
     * @notice Transfers native tokens to the specified account from the module balance.
     * @param to_ The address to transfer tokens to.
     * @param value_ The amount to transfer.
     * @dev The caller must have update permission.
     */
    function redeemTokens(address to_, uint256 value_) public onlyUpdatePermission {
        (bool success_, ) = to_.call{value: value_}("");

        require(success_, "CrossChainNFTMintingModule: sending error.");
    }

    /**
     * @inheritdoc IDAOResource
     */
    function checkPermission(
        address member_,
        string memory permission_
    ) public view virtual returns (bool) {
        return permissionManager.hasPermission(member_, MODULE_RESOURCE, permission_);
    }

    /**
     * @inheritdoc IDAOResource
     */
    function getResource() external view returns (string memory) {
        return MODULE_RESOURCE;
    }

    /**
     * @inheritdoc IDAOIntegration
     *
     * @notice Used by the Permission Manager in confExternalModule function.
     */
    function getResourceRecords()
        external
        view
        virtual
        returns (ResourceRecords[] memory records_)
    {
        records_ = new ResourceRecords[](3);

        string[] memory memberPermissions_ = [CREATE_VOTING_PERMISSION, VOTE_FOR_PERMISSION]
            .asArray();

        records_[0] = ResourceRecords(
            getDAOMemberRole(_relatedExpertPanelName)[0],
            MODULE_RESOURCE,
            memberPermissions_
        );

        string[] memory expertPermissions_ = [EXPERT_PERMISSION].asArray();

        records_[1] = ResourceRecords(
            getDAOExpertRole(_relatedExpertPanelName)[0],
            MODULE_RESOURCE,
            expertPermissions_
        );

        records_[2] = ResourceRecords(
            getDAOVotingRole(_relatedExpertPanelName)[0],
            MODULE_RESOURCE,
            [UPDATE_PERMISSION].asArray()
        );
    }

    /**
     * @notice Fetches the amount of gas that will be used when a message is
     * dispatched to the given domain.
     */
    function quoteDispatch(
        uint32 destinationDomain_,
        bytes calldata message_
    ) external view returns (uint256) {
        return _quoteDispatch(destinationDomain_, message_);
    }

    /**
     * @notice Encoding the MessageAction into bytes.
     */
    function getEncodedOperation(
        address[] memory to_,
        bytes calldata data_,
        Action action_
    ) external pure returns (bytes memory) {
        return abi.encode(MessageAction(to_, data_, action_));
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IDAOResource).interfaceId ||
            interfaceId == type(IDAOIntegration).interfaceId ||
            interfaceId == type(AbstractDependant).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _requirePermission(string memory permission_) internal view {
        require(
            checkPermission(msg.sender, permission_),
            "CrossChainNFTMintingModule: permission denied."
        );
    }

    function _relayMessageAction(MessageAction memory operation_) internal {
        uint256 fee_ = _quoteDispatch(destinationDomain, abi.encode(operation_));

        _dispatch(destinationDomain, fee_, abi.encode(operation_));

        emit MessageSent(mailbox.localDomain(), destinationDomain, operation_);
    }

    function _metadata(
        uint32 /*_destinationDomain*/
    ) internal view override returns (bytes memory) {
        return StandardHookMetadata.overrideGasLimit(HANDLE_GAS_AMOUNT);
    }

    function _handle(uint32 origin_, bytes32 sender_, bytes calldata message_) internal override {}

    function _initialize(
        uint32 remoteDomain_,
        address ism_,
        bytes32 remoteRouter_,
        string memory resource_,
        string memory relatedExpertPanelName_
    ) private {
        _MailboxClient_initialize(address(0), ism_, msg.sender);

        destinationDomain = remoteDomain_;

        _enrollRemoteRouter(remoteDomain_, remoteRouter_);

        _relatedExpertPanelName = relatedExpertPanelName_;

        MODULE_RESOURCE = resource_;
    }

    // A functionality to upgrade the contract
    function _authorizeUpgrade(address) internal virtual override {
        address proxyUpgrader_ = permissionManager.getDAORegistry().getProxyUpgrader();

        require(msg.sender == proxyUpgrader_, "[QGDK-006005]-Not authorized to upgrade.");
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Router} from "@hyperlane-xyz/core/contracts/client/Router.sol";

import {NFTMinting} from "../../common/NFTMinting.sol";
import {MessageAction, Action} from "./CrossChainNFTMintingModule.sol";

/**
 * @title Foreign NFT Minting Module
 * @notice A cross-chain module for NFT minting combining features from both NFTMinting and Router contracts.
 *
 * @dev The module supports:
 *      - Receiving messages from a local mailbox and handles them through the _handle function.
 *      - Basic minting operations through the mintTo function.
 *      - Interaction with the Ownable part of the NFT contract, including functions like transferNFTOwnership
 *        and transferOwnership.
 *      - The arbitraryNFTExecute function, allowing for more complex interactions with the NFT contract.
 *      - Batch minting with an optional automatic tokenId generation. When tokenIds are not specified,
 *        they are auto-generated based on the formula: block.timestamp + batchId, where batchId is the index
 *        of the token in the batch. This ensures unique and time-referenced tokenId for each NFT in the batch.
 */
contract ForeignNFTMintingModule is Router, NFTMinting {
    event MessageReceived(
        uint32 indexed origin,
        uint32 indexed destination,
        bytes32 sender,
        MessageAction action
    );

    modifier onlyCreatePermission() override {
        _checkOwner();
        _;
    }

    modifier onlyUpdatePermission() override {
        _checkOwner();
        _;
    }

    constructor(
        address mailboxAddress_,
        uint32 remoteDomain_,
        bytes32 remoteRouter_,
        address ism_
    ) Router(mailboxAddress_) {
        _transferOwnership(msg.sender); //test

        _enrollRemoteRouter(remoteDomain_, remoteRouter_);
        setInterchainSecurityModule(ism_);

        _transferOwnership(mailboxAddress_);
    }

    function __ForeignNFTMintingModule_init(
        //do it needed?
        address token_,
        uint256 startPoint_
    ) external initializer {
        __NFTMinting_init(token_, startPoint_, "");
    }

    /**
     * @inheritdoc OwnableUpgradeable
     */
    function transferOwnership(address newOwner_) public override(OwnableUpgradeable, NFTMinting) {
        OwnableUpgradeable.transferOwnership(newOwner_);
    }

    /**
     * @notice Handles a message from a remote router.
     * @dev Only called for messages sent from a remote router, as enforced by Router.sol.
     * @param origin_ The domain of the origin of the message.
     * @param sender_ The sender of the message.
     * @param message_ The message body.
     */
    function _handle(uint32 origin_, bytes32 sender_, bytes calldata message_) internal override {
        //for now it seems to be impossible to catch error from abi.decode,
        //see: https://github.com/ethereum/solidity/issues/10381
        MessageAction memory operation_ = abi.decode(message_, (MessageAction));

        if (operation_.action == Action.MINT) {
            mintTo(operation_.to[0]);
        } else if (operation_.action == Action.BATCH_MINT) {
            batchMintTo(operation_.to);
        } else if (operation_.action == Action.TRANSFER_NFT_OWNERSHIP) {
            supportedNFT.transferOwnership(operation_.to[0]);
        } else if (operation_.action == Action.TRANSFER_OWNERSHIP) {
            transferOwnership(operation_.to[0]);
        } else {
            arbitraryNFTExecute(operation_.data);
        }

        emit MessageReceived(origin_, mailbox.localDomain(), sender_, operation_);
    }
}