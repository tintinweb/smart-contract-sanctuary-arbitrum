// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

struct PacketForQuote {
    address sender;
    uint32 dstEid;
    bytes message;
}

struct Packet {
    uint64 nonce;
    uint32 srcEid;
    address sender;
    uint32 dstEid;
    bytes32 receiver;
    bytes32 guid;
    bytes message;
}

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./IMessageLibManager.sol";
import "./IMessagingComposer.sol";
import "./IMessagingChannel.sol";
import "./IMessagingContext.sol";
import {Origin} from "../MessagingStructs.sol";

struct MessagingParams {
    uint32 dstEid;
    bytes32 receiver;
    bytes message;
    bytes options;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct MessagingFee {
    uint nativeFee;
    uint lzTokenFee;
}

interface ILayerZeroEndpointV2 is IMessageLibManager, IMessagingComposer, IMessagingChannel, IMessagingContext {
    event PacketSent(bytes encodedPayload, bytes options, address sendLibrary);

    event PacketDelivered(Origin origin, address receiver, bytes32 payloadHash);

    event PacketReceived(Origin origin, address receiver);

    event LzReceiveFailed(Origin origin, address receiver, bytes reason);

    event LayerZeroTokenSet(address token);

    function quote(
        address _sender,
        uint32 _dstEid,
        bytes calldata _message,
        bool _payInLzToken,
        bytes calldata _options
    ) external view returns (MessagingFee memory);

    function send(
        MessagingParams calldata _params,
        uint _lzTokenFee,
        address payable _refundAddress
    ) external payable returns (MessagingReceipt memory);

    function sendWithAlt(
        MessagingParams calldata _params,
        uint _lzTokenFee,
        uint _altTokenFee
    ) external returns (MessagingReceipt memory);

    function deliver(Origin calldata _origin, address _receiver, bytes32 _payloadHash) external;

    function deliverable(Origin calldata _origin, address _receiveLib, address _receiver) external view returns (bool);

    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable returns (bool, bytes memory);

    // oapp can burn messages partially by calling this function with its own business logic if messages are delivered in order
    function clear(Origin calldata _origin, bytes32 _guid, bytes calldata _message) external;

    function setLayerZeroToken(address _layerZeroToken) external;

    function layerZeroToken() external view returns (address);

    function altFeeToken() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {MessagingFee, SetConfigParam} from "./ILayerZeroEndpointV2.sol";
import {Packet, PacketForQuote} from "../MessagingStructs.sol";

interface IMessageLib is IERC165 {
    function send(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external returns (MessagingFee memory, bytes memory encodedPacket);

    function quote(
        PacketForQuote calldata _packet,
        bool _payInLzToken,
        bytes calldata _options
    ) external view returns (MessagingFee memory);

    function setTreasury(address _treasury) external;

    function setConfig(address _oapp, uint32 _eid, SetConfigParam[] calldata _config) external;

    function snapshotConfig(uint32[] calldata _eids, address _oapp) external;

    function resetConfig(uint32[] calldata _eids, address _oapp) external;

    function getConfig(
        uint32 _eid,
        address _oapp,
        uint32 _configType
    ) external view returns (bytes memory config, bool isDefault);

    function getDefaultConfig(uint32 _eid, uint32 _configType) external view returns (bytes memory);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    function withdrawFee(address _to, uint _amount) external;

    function withdrawLzTokenFee(address _lzToken, address _to, uint _amount) external;

    // message libs of same major version are compatible
    function version() external view returns (uint64 major, uint8 minor, uint8 endpointVersion);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

struct SetConfigParam {
    uint32 configType;
    bytes config;
}

interface IMessageLibManager {
    struct Timeout {
        address lib;
        uint expiry;
    }

    event LibraryRegistered(address newLib);
    event DefaultSendLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibrarySet(uint32 eid, address oldLib, address newLib);
    event DefaultReceiveLibraryTimeoutSet(uint32 eid, address oldLib, uint expiry);
    event SendLibrarySet(address sender, uint32 eid, address newLib);
    event ReceiveLibrarySet(address receiver, uint32 eid, address oldLib, address newLib);
    event ReceiveLibraryTimoutSet(address receiver, uint32 eid, address oldLib, uint timeout);

    function registerLibrary(address _lib) external;

    function isRegisteredLibrary(address _lib) external view returns (bool);

    function getRegisteredLibraries() external view returns (address[] memory);

    function setDefaultSendLibrary(uint32 _eid, address _newLib) external;

    function defaultSendLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibrary(uint32 _eid, address _newLib, uint _timeout) external;

    function defaultReceiveLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibraryTimeout(uint32 _eid, address _lib, uint _expiry) external;

    function defaultReceiveLibraryTimeout(uint32 _eid) external view returns (address lib, uint expiry);

    function defaultConfig(address _lib, uint32 _eid, uint32 _configType) external view returns (bytes memory);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    /// ------------------- OApp interfaces -------------------
    function setSendLibrary(uint32 _eid, address _newLib) external;

    function getSendLibrary(address _sender, uint32 _eid) external view returns (address lib);

    function isDefaultSendLibrary(address _sender, uint32 _eid) external view returns (bool);

    function setReceiveLibrary(uint32 _eid, address _newLib, uint _gracePeriod) external;

    function getReceiveLibrary(address _receiver, uint32 _eid) external view returns (address lib, bool isDefault);

    function setReceiveLibraryTimeout(uint32 _eid, address _lib, uint _gracePeriod) external;

    function receiveLibraryTimeout(address _receiver, uint32 _eid) external view returns (address lib, uint expiry);

    function setConfig(address _lib, uint32 _eid, SetConfigParam[] calldata _params) external;

    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view returns (bytes memory config, bool isDefault);

    function snapshotConfig(address _lib, uint32[] calldata _eids) external;

    function resetConfig(address _lib, uint32[] calldata _eids) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IMessagingChannel {
    event InboundNonceSkipped(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce);

    function eid() external view returns (uint32);

    // this is an emergency function if a message can not be delivered for some reasons
    // required to provide _nextNonce to avoid race condition
    function skip(uint32 _srcEid, bytes32 _sender, uint64 _nonce) external;

    function nextGuid(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (bytes32);

    function inboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64);

    function outboundNonce(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (uint64);

    function inboundPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bytes32);

    function hasPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IMessagingComposer {
    event ComposedMessageDelivered(address receiver, address composer, bytes32 guid, bytes message);
    event ComposedMessageReceived(address receiver, address composer, bytes32 guid);
    event LzComposeFailed(address receiver, address composer, bytes32 guid, bytes reason);

    function deliverComposedMessage(address _composer, bytes32 _guid, bytes calldata _message) external;

    function lzCompose(
        address _receiver,
        address _composer,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable returns (bool, bytes memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IMessagingContext {
    function isSendingMessage() external view returns (bool);

    function getSendContext() external view returns (uint32, address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Errors {
    // Invalid Argument (http: 400)
    string internal constant INVALID_ARGUMENT = "LZ10000";
    string internal constant ONLY_REGISTERED = "LZ10001";
    string internal constant ONLY_REGISTERED_OR_DEFAULT = "LZ10002";
    string internal constant INVALID_AMOUNT = "LZ10003";
    string internal constant INVALID_NONCE = "LZ10004";
    string internal constant SAME_VALUE = "LZ10005";
    string internal constant UNSORTED = "LZ10006";
    string internal constant INVALID_VERSION = "LZ10007";
    string internal constant INVALID_EID = "LZ10008";
    string internal constant INVALID_SIZE = "LZ10009";
    string internal constant ONLY_NON_DEFAULT = "LZ10010";
    string internal constant INVALID_VERIFIERS = "LZ10011";
    string internal constant INVALID_WORKER_ID = "LZ10012";
    string internal constant DUPLICATED_OPTION = "LZ10013";
    string internal constant INVALID_LEGACY_OPTION = "LZ10014";
    string internal constant INVALID_VERIFIER_OPTION = "LZ10015";
    string internal constant INVALID_WORKER_OPTIONS = "LZ10016";
    string internal constant INVALID_EXECUTOR_OPTION = "LZ10017";
    string internal constant INVALID_ADDRESS = "LZ10018";

    // Out of Range (http: 400)
    string internal constant OUT_OF_RANGE = "LZ20000";

    // Invalid State (http: 400)
    string internal constant INVALID_STATE = "LZ30000";
    string internal constant SEND_REENTRANCY = "LZ30001";
    string internal constant RECEIVE_REENTRANCY = "LZ30002";
    string internal constant COMPOSE_REENTRANCY = "LZ30003";

    // Permission Denied (http: 403)
    string internal constant PERMISSION_DENIED = "LZ50000";

    // Not Found (http: 404)
    string internal constant NOT_FOUND = "LZ60000";

    // Already Exists (http: 409)
    string internal constant ALREADY_EXISTS = "LZ80000";

    // Not Implemented (http: 501)
    string internal constant NOT_IMPLEMENTED = "LZC0000";
    string internal constant UNSUPPORTED_INTERFACE = "LZC0001";
    string internal constant UNSUPPORTED_OPTION_TYPE = "LZC0002";

    // Unavailable (http: 503)
    string internal constant UNAVAILABLE = "LZD0000";
    string internal constant NATIVE_COIN_UNAVAILABLE = "LZD0001";
    string internal constant TOKEN_UNAVAILABLE = "LZD0002";
    string internal constant DEFAULT_LIBRARY_UNAVAILABLE = "LZD0003";
    string internal constant VERIFIERS_UNAVAILABLE = "LZD0004";
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroUltraLightNodeV2 {
    // Relayer functions
    function validateTransactionProof(
        uint16 _srcChainId,
        address _dstAddress,
        uint _gasLimit,
        bytes32 _lookupHash,
        bytes32 _blockData,
        bytes calldata _transactionProof
    ) external;

    // an Oracle delivers the block data using updateHash()
    function updateHash(uint16 _srcChainId, bytes32 _lookupHash, uint _confirmations, bytes32 _blockData) external;

    // can only withdraw the receivable of the msg.sender
    function withdrawNative(address payable _to, uint _amount) external;

    function withdrawZRO(address _to, uint _amount) external;

    // view functions
    function getAppConfig(
        uint16 _remoteChainId,
        address _userApplicationAddress
    ) external view returns (ApplicationConfiguration memory);

    function accruedNativeFee(address _address) external view returns (uint);

    struct ApplicationConfiguration {
        uint16 inboundProofLibraryVersion;
        uint64 inboundBlockConfirmations;
        address relayer;
        uint16 outboundProofType;
        uint64 outboundBlockConfirmations;
        address oracle;
    }

    event HashReceived(
        uint16 indexed srcChainId,
        address indexed oracle,
        bytes32 lookupHash,
        bytes32 blockData,
        uint confirmations
    );
    event RelayerParams(bytes adapterParams, uint16 outboundProofType);
    event Packet(bytes payload);
    event InvalidDst(
        uint16 indexed srcChainId,
        bytes srcAddress,
        address indexed dstAddress,
        uint64 nonce,
        bytes32 payloadHash
    );
    event PacketReceived(
        uint16 indexed srcChainId,
        bytes srcAddress,
        address indexed dstAddress,
        uint64 nonce,
        bytes32 payloadHash
    );
    event AppConfigUpdated(address indexed userApplication, uint indexed configType, bytes newConfig);
    event AddInboundProofLibraryForChain(uint16 indexed chainId, address lib);
    event EnableSupportedOutboundProof(uint16 indexed chainId, uint16 proofType);
    event SetChainAddressSize(uint16 indexed chainId, uint size);
    event SetDefaultConfigForChainId(
        uint16 indexed chainId,
        uint16 inboundProofLib,
        uint64 inboundBlockConfirm,
        address relayer,
        uint16 outboundProofType,
        uint64 outboundBlockConfirm,
        address oracle
    );
    event SetDefaultAdapterParamsForChainId(uint16 indexed chainId, uint16 indexed proofType, bytes adapterParams);
    event SetLayerZeroToken(address indexed tokenAddress);
    event SetRemoteUln(uint16 indexed chainId, bytes32 uln);
    event SetTreasury(address indexed treasuryAddress);
    event WithdrawZRO(address indexed msgSender, address indexed to, uint amount);
    event WithdrawNative(address indexed msgSender, address indexed to, uint amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/libs/Errors.sol";

import "./interfaces/ILayerZeroExecutor.sol";
import "./interfaces/ILayerZeroTreasury.sol";

struct WorkerOptions {
    uint8 workerId;
    bytes options;
}

enum DeliveryState {
    Signing,
    Deliverable,
    Delivered,
    Waiting
}

abstract contract MessageLibBase is Ownable {
    address internal immutable endpoint;
    uint32 internal immutable localEid;
    uint internal immutable treasuryGasCap;

    // config
    address public treasury;

    // accumulated fees for workers and treasury
    mapping(address worker => uint) public fees;

    event ExecutorFeePaid(address executor, uint fee);
    event TreasurySet(address treasury);

    // only the endpoint can call SEND() and setConfig()
    modifier onlyEndpoint() {
        require(endpoint == msg.sender, Errors.PERMISSION_DENIED);
        _;
    }

    constructor(address _endpoint, uint32 _localEid, uint _treasuryGasCap) {
        endpoint = _endpoint;
        localEid = _localEid;
        treasuryGasCap = _treasuryGasCap;
    }

    // ======================= Internal =======================
    function _assertMessageSize(uint _actual, uint _max) internal pure {
        require(_actual <= _max, Errors.INVALID_SIZE);
    }

    function _sendToExecutor(
        address _executor,
        uint32 _dstEid,
        address _sender,
        uint _msgSize,
        bytes memory _executorOptions
    ) internal returns (uint executorFee) {
        executorFee = ILayerZeroExecutor(_executor).assignJob(_dstEid, _sender, _msgSize, _executorOptions);
        if (executorFee > 0) {
            fees[_executor] += executorFee;
        }
        emit ExecutorFeePaid(_executor, executorFee);
    }

    function _sendToTreasury(
        address _sender,
        uint32 _dstEid,
        uint _totalNativeFee,
        bool _payInLzToken
    ) internal returns (uint treasuryNativeFee, uint lzTokenFee) {
        // fee should be in lzTokenFee if payInLzToken, otherwise in native
        (treasuryNativeFee, lzTokenFee) = _quoteTreasuryFee(_sender, _dstEid, _totalNativeFee, _payInLzToken);
        // if payInLzToken, handle in messagelib / endpoint
        if (treasuryNativeFee > 0) {
            fees[treasury] += treasuryNativeFee;
        }
    }

    function _quote(
        address _sender,
        uint32 _dstEid,
        uint _msgSize,
        bool _payInLzToken,
        bytes calldata _options
    ) internal view returns (uint, uint) {
        require(_options.length > 0, Errors.INVALID_ARGUMENT);

        (bytes memory executorOptions, WorkerOptions[] memory otherWorkerOptions) = _getExecutorAndOtherOptions(
            _options
        );

        // quote other workers
        (uint nativeFee, address executor, uint maxMsgSize) = _quoteWorkers(_sender, _dstEid, otherWorkerOptions);

        // assert msg size
        _assertMessageSize(_msgSize, maxMsgSize);

        // quote executor
        nativeFee += ILayerZeroExecutor(executor).getFee(_dstEid, _sender, _msgSize, executorOptions);

        // quote treasury
        (uint treasuryNativeFee, uint lzTokenFee) = _quoteTreasuryFee(_sender, _dstEid, nativeFee, _payInLzToken);
        if (treasuryNativeFee > 0) {
            nativeFee += treasuryNativeFee;
        }

        return (nativeFee, lzTokenFee);
    }

    function _quoteTreasuryFee(
        address _sender,
        uint32 _eid,
        uint _totalFee,
        bool _payInLzToken
    ) internal view returns (uint nativeFee, uint lzTokenFee) {
        if (treasury != address(0x0)) {
            try ILayerZeroTreasury(treasury).getFee(_sender, _eid, _totalFee, _payInLzToken) returns (
                uint treasuryFee
            ) {
                // success
                if (_payInLzToken) {
                    lzTokenFee = treasuryFee;
                } else {
                    // pay in native, make sure that the treasury fee is not higher than the cap
                    uint gasFeeEstimate = tx.gasprice * treasuryGasCap;
                    // cap is the max of total fee and gasFeeEstimate. this is to prevent apps from forcing the cap to 0.
                    uint nativeFeeCap = _totalFee > gasFeeEstimate ? _totalFee : gasFeeEstimate;
                    // to prevent the treasury from returning an overly high value to break the path
                    nativeFee = treasuryFee > nativeFeeCap ? nativeFeeCap : treasuryFee;
                }
            } catch {
                // failure, something wrong with treasury contract, charge nothing and continue
            }
        }
    }

    function _transferNative(address _to, uint _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, Errors.INVALID_STATE);
    }

    // for msg.sender only
    function _assertAndDebitAmount(address _to, uint _amount) internal {
        uint fee = fees[msg.sender];
        require(_to != address(0x0) && _amount <= fee, Errors.INVALID_ARGUMENT);
        unchecked {
            fees[msg.sender] = fee - _amount;
        }
    }

    function _setTreasury(address _treasury) internal {
        treasury = _treasury;
        emit TreasurySet(_treasury);
    }

    // ======================= Virtual =======================
    // For implementation to override
    function _quoteWorkers(
        address _oapp,
        uint32 _eid,
        WorkerOptions[] memory _options
    ) internal view virtual returns (uint nativeFee, address executor, uint maxMsgSize);

    function _getExecutorAndOtherOptions(
        bytes calldata _options
    ) internal view virtual returns (bytes memory executorOptions, WorkerOptions[] memory otherWorkerOptions);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLib.sol";
import "./interfaces/IWorker.sol";

abstract contract Worker is AccessControl, Pausable, IWorker {
    bytes32 internal constant MESSAGE_LIB_ROLE = keccak256("MESSAGE_LIB_ROLE");
    bytes32 internal constant ALLOWLIST = keccak256("ALLOWLIST");
    bytes32 internal constant DENYLIST = keccak256("DENYLIST");
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public workerFeeLib;

    uint64 public allowlistSize;
    uint16 public defaultMultiplierBps;
    address public priceFeed;

    // ========================= Constructor =========================

    /// @param _messageLibs array of message lib addresses that are granted the MESSAGE_LIB_ROLE
    /// @param _priceFeed price feed address
    /// @param _defaultMultiplierBps default multiplier for worker fee
    /// @param _roleAdmin address that is granted the DEFAULT_ADMIN_ROLE (can grant and revoke all roles)
    /// @param _admins array of admin addresses that are granted the ADMIN_ROLE
    constructor(
        address[] memory _messageLibs,
        address _priceFeed,
        uint16 _defaultMultiplierBps,
        address _roleAdmin,
        address[] memory _admins
    ) {
        defaultMultiplierBps = _defaultMultiplierBps;
        priceFeed = _priceFeed;

        if (_roleAdmin != address(0x0)) {
            _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin); // _roleAdmin can grant and revoke all roles
        }

        for (uint i = 0; i < _messageLibs.length; ++i) {
            _grantRole(MESSAGE_LIB_ROLE, _messageLibs[i]);
        }

        for (uint i = 0; i < _admins.length; ++i) {
            _grantRole(ADMIN_ROLE, _admins[i]);
        }
    }

    // ========================= Modifier =========================

    modifier onlyAcl(address _sender) {
        require(hasAcl(_sender), "Worker: not allowed");
        _;
    }

    /// @dev Access control list using allowlist and denylist
    /// @dev 1) if one address is in the denylist -> deny
    /// @dev 2) else if address in the allowlist OR allowlist is empty (allows everyone)-> allow
    /// @dev 3) else deny
    /// @param _sender address to check
    function hasAcl(address _sender) public view returns (bool) {
        if (hasRole(DENYLIST, _sender)) {
            return false;
        } else if (allowlistSize == 0 || hasRole(ALLOWLIST, _sender)) {
            return true;
        } else {
            return false;
        }
    }

    // ========================= OnyDefaultAdmin =========================

    /// @dev flag to pause execution of workers (if used with whenNotPaused modifier)
    /// @param _paused true to pause, false to unpause
    function setPaused(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    // ========================= OnlyAdmin =========================

    /// @param _priceFeed price feed address
    function setPriceFeed(address _priceFeed) external onlyRole(ADMIN_ROLE) {
        priceFeed = _priceFeed;
        emit SetPriceFeed(_priceFeed);
    }

    /// @param _workerFeeLib worker fee lib address
    function setWorkerFeeLib(address _workerFeeLib) external onlyRole(ADMIN_ROLE) {
        workerFeeLib = _workerFeeLib;
        emit SetWorkerLib(_workerFeeLib);
    }

    /// @param _multiplierBps default multiplier for worker fee
    function setDefaultMultiplierBps(uint16 _multiplierBps) external onlyRole(ADMIN_ROLE) {
        defaultMultiplierBps = _multiplierBps;
        emit SetDefaultMultiplierBps(_multiplierBps);
    }

    /// @dev supports withdrawing fee from ULN301, ULN302 and more
    /// @param _lib message lib address
    /// @param _to address to withdraw fee to
    /// @param _amount amount to withdraw
    function withdrawFee(address _lib, address _to, uint _amount) external onlyRole(ADMIN_ROLE) {
        require(hasRole(MESSAGE_LIB_ROLE, _lib), "Worker: Invalid message lib");
        IMessageLib(_lib).withdrawFee(_to, _amount);
        emit Withdraw(_lib, _to, _amount);
    }

    // ========================= Internal Functions =========================

    /// @dev overrides AccessControl to allow for counting of allowlistSize
    /// @param _role role to grant
    /// @param _account address to grant role to
    function _grantRole(bytes32 _role, address _account) internal override {
        if (_role == ALLOWLIST && !hasRole(_role, _account)) {
            ++allowlistSize;
        }
        super._grantRole(_role, _account);
    }

    /// @dev overrides AccessControl to allow for counting of allowlistSize
    /// @param _role role to revoke
    /// @param _account address to revoke role from
    function _revokeRole(bytes32 _role, address _account) internal override {
        if (_role == ALLOWLIST && hasRole(_role, _account)) {
            --allowlistSize;
        }
        super._revokeRole(_role, _account);
    }

    /// @dev overrides AccessControl to disable renouncing of roles
    function renounceRole(bytes32 /*role*/, address /*account*/) public pure override {
        revert("Worker: cannot renounce role");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroExecutor {
    // @notice query price and assign jobs at the same time
    // @param _dstEid - the destination endpoint identifier
    // @param _sender - the source sending contract address. executors may apply price discrimination to senders
    // @param _calldataSize - dynamic data size of message + caller params
    // @param _options - optional parameters for extra service plugins, e.g. sending dust tokens at the destination chain
    function assignJob(
        uint32 _dstEid,
        address _sender,
        uint _calldataSize,
        bytes calldata _options
    ) external payable returns (uint price);

    // @notice query the executor price for relaying the payload and its proof to the destination chain
    // @param _dstEid - the destination endpoint identifier
    // @param _sender - the source sending contract address. executors may apply price discrimination to senders
    // @param _calldataSize - dynamic data size of message + caller params
    // @param _options - optional parameters for extra service plugins, e.g. sending dust tokens at the destination chain
    function getFee(
        uint32 _dstEid,
        address _sender,
        uint _calldataSize,
        bytes calldata _options
    ) external view returns (uint price);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroTreasury {
    function getFee(address _sender, uint32 _eid, uint _totalFee, bool _payInLzToken) external view returns (uint);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IWorker {
    event SetWorkerLib(address workerLib);
    event SetPriceFeed(address priceFeed);
    event SetDefaultMultiplierBps(uint16 multiplierBps);
    event Withdraw(address lib, address to, uint amount);

    function setPriceFeed(address _priceFeed) external;

    function priceFeed() external view returns (address);

    function setDefaultMultiplierBps(uint16 _multiplierBps) external;

    function defaultMultiplierBps() external view returns (uint16);

    function withdrawFee(address _lib, address _to, uint _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract MultiSig {
    enum Errors {
        NoError,
        SignatureError,
        DuplicatedSigner,
        SignerNotInCommittee
    }

    mapping(address signer => bool active) public signers;
    uint64 public signerSize;
    uint64 public quorum;

    event UpdateSigner(address _signer, bool _active);
    event UpdateQuorum(uint64 _quorum);

    modifier onlySigner() {
        require(signers[msg.sender], "MultiSig: caller must be signer");
        _;
    }

    constructor(address[] memory _signers, uint64 _quorum) {
        require(_signers.length >= _quorum && _quorum > 0, "MultiSig: signers too few");

        address lastSigner = address(0);
        for (uint i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer > lastSigner, "MultiSig: signers not sorted"); // to ensure no duplicates
            signers[signer] = true;
            lastSigner = signer;
        }
        signerSize = uint64(_signers.length);
        quorum = _quorum;
    }

    function _setSigner(address _signer, bool _active) internal {
        require(signers[_signer] != _active, "MultiSig: signer already in that state");
        signers[_signer] = _active;
        signerSize = _active ? signerSize + 1 : signerSize - 1;
        require(signerSize >= quorum, "MultiSig: committee size < threshold");
        emit UpdateSigner(_signer, _active);
    }

    function _setQuorum(uint64 _quorum) internal {
        require(_quorum <= signerSize && _quorum > 0, "MultiSig: invalid quorum");
        quorum = _quorum;
        emit UpdateQuorum(_quorum);
    }

    function verifySignatures(bytes32 _hash, bytes calldata _signatures) public view returns (bool, Errors) {
        if (_signatures.length != uint(quorum) * 65) {
            return (false, Errors.SignatureError);
        }

        bytes32 messageDigest = _getEthSignedMessageHash(_hash);

        address lastSigner = address(0); // There cannot be a signer with address 0.
        for (uint i = 0; i < quorum; i++) {
            bytes calldata signature = _signatures[i * 65:(i + 1) * 65];
            (address currentSigner, ECDSA.RecoverError error) = ECDSA.tryRecover(messageDigest, signature);

            if (error != ECDSA.RecoverError.NoError) return (false, Errors.SignatureError);
            if (currentSigner <= lastSigner) return (false, Errors.DuplicatedSigner); // prevent duplicate signatures
            if (!signers[currentSigner]) return (false, Errors.SignerNotInCommittee); // signature is not in committee
            lastSigner = currentSigner;
        }
        return (true, Errors.NoError);
    }

    function _getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "@layerzerolabs/lz-evm-v1-0.8/contracts/interfaces/ILayerZeroUltraLightNodeV2.sol";

import "../Worker.sol";
import "./MultiSig.sol";
import "./interfaces/IVerifier.sol";
import "./interfaces/IVerifierFeeLib.sol";
import "./interfaces/IUltraLightNode.sol";
import {DeliveryState} from "../MessageLibBase.sol";

struct ExecuteParam {
    uint32 vid;
    address target;
    bytes callData;
    uint expiration;
    bytes signatures;
}

contract VerifierNetwork is Worker, MultiSig, IVerifier {
    // to uniquely identify this VerifierNetwork instance
    // set to endpoint v1 eid if available OR endpoint v2 eid % 30_000
    uint32 public immutable vid;

    mapping(uint32 dstEid => DstConfig) public dstConfig;
    mapping(bytes32 executableHash => bool used) public usedHashes;

    event VerifySignaturesFailed(uint idx);
    event ExecuteFailed(uint _index, bytes _data);
    event HashAlreadyUsed(ExecuteParam param, bytes32 _hash);
    event VerifierFeePaid(uint fee);

    // ========================= Constructor =========================

    /// @dev VerifierNetwork doesn't have a roleAdmin (address(0x0))
    /// @dev Supports all of ULNv2, ULN301, ULN302 and more
    /// @param _messageLibs array of message lib addresses that are granted the MESSAGE_LIB_ROLE
    /// @param _priceFeed price feed address
    /// @param _signers array of signer addresses for multisig
    /// @param _quorum quorum for multisig
    /// @param _admins array of admin addresses that are granted the ADMIN_ROLE
    constructor(
        uint32 _vid,
        address[] memory _messageLibs,
        address _priceFeed,
        address[] memory _signers,
        uint64 _quorum,
        address[] memory _admins
    ) Worker(_messageLibs, _priceFeed, 12000, address(0x0), _admins) MultiSig(_signers, _quorum) {
        vid = _vid;
    }

    // ========================= Modifier =========================

    /// @dev depending on role, restrict access to only self or admin
    /// @dev ALLOWLIST, DENYLIST, MESSAGE_LIB_ROLE can only be granted/revoked by self
    /// @dev ADMIN_ROLE can only be granted/revoked by admin
    /// @dev reverts if not one of the above roles
    /// @param _role role to check
    modifier onlySelfOrAdmin(bytes32 _role) {
        if (_role == ALLOWLIST || _role == DENYLIST || _role == MESSAGE_LIB_ROLE) {
            // self required
            require(address(this) == msg.sender, "Verifier: caller must be self");
        } else if (_role == ADMIN_ROLE) {
            // admin required
            _checkRole(ADMIN_ROLE);
        } else {
            revert("Verifier: invalid role");
        }
        _;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Verifier: caller must be self");
        _;
    }

    // ========================= OnlySelf =========================

    /// @dev set signers for multisig
    /// @dev function sig 0x31cb6105
    /// @param _signer signer address
    /// @param _active true to add, false to remove
    function setSigner(address _signer, bool _active) external onlySelf {
        _setSigner(_signer, _active);
    }

    /// @dev set quorum for multisig
    /// @dev function sig 0x8585c945
    /// @param _quorum to set
    function setQuorum(uint64 _quorum) external onlySelf {
        _setQuorum(_quorum);
    }

    /// @dev one function to verify and deliver to ULN302 and more (does not support ULN301)
    /// @dev if last verifier, can use this function to save overhead gas on deliver
    /// @dev function sig 0xb724b133
    /// @param _uln IUltraLightNode compatible contract
    /// @param _packetHeader packet header
    /// @param _payloadHash payload hash
    /// @param _confirmations block confirmations
    function verifyAndDeliver(
        IUltraLightNode _uln,
        bytes calldata _packetHeader,
        bytes32 _payloadHash,
        uint64 _confirmations
    ) external onlySelf {
        require(hasRole(MESSAGE_LIB_ROLE, address(_uln)), "Verifier: invalid uln");
        _uln.verify(_packetHeader, _payloadHash, _confirmations);
        // if deliverable, deliver. else, skip or it will revert in uln
        if (_uln.deliverable(_packetHeader, _payloadHash) == DeliveryState.Deliverable) {
            _uln.deliver(_packetHeader, _payloadHash);
        }
    }

    // ========================= OnlySelf / OnlyAdmin =========================

    /// @dev overrides AccessControl to allow self/admin to grant role'
    /// @dev function sig 0x2f2ff15d
    /// @param _role role to grant
    /// @param _account account to grant role to
    function grantRole(bytes32 _role, address _account) public override onlySelfOrAdmin(_role) {
        _grantRole(_role, _account);
    }

    /// @dev overrides AccessControl to allow self/admin to revoke role
    /// @dev function sig 0xd547741f
    /// @param _role role to revoke
    /// @param _account account to revoke role from
    function revokeRole(bytes32 _role, address _account) public override onlySelfOrAdmin(_role) {
        _revokeRole(_role, _account);
    }

    // ========================= OnlyQuorum =========================

    // @notice function for quorum to change admin without going through execute function
    // @dev calldata in the case is abi.encode new admin address
    function quorumChangeAdmin(ExecuteParam calldata _param) external {
        require(_param.expiration > block.timestamp, "Verifier: expired");
        require(_param.target == address(this), "Verifier: invalid target");
        require(_param.vid == vid, "Verifier: invalid vid");

        // generate and validate hash
        bytes32 hash = hashCallData(_param.vid, _param.target, _param.callData, _param.expiration);
        (bool sigsValid, ) = verifySignatures(hash, _param.signatures);
        require(sigsValid, "Verifier: invalid signatures");
        require(!usedHashes[hash], "Verifier: hash already used");

        usedHashes[hash] = true;
        _grantRole(ADMIN_ROLE, abi.decode(_param.callData, (address)));
    }

    // ========================= OnlyAdmin =========================

    /// @param _params array of DstConfigParam
    function setDstConfig(DstConfigParam[] calldata _params) external onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < _params.length; ++i) {
            DstConfigParam calldata param = _params[i];
            dstConfig[param.dstEid] = DstConfig(param.gas, param.multiplierBps, param.floorMarginUSD);
        }
        emit SetDstConfig(_params);
    }

    /// @dev takes a list of instructions and executes them in order
    /// @dev if any of the instructions fail, it will emit an error event and continue to execute the rest of the instructions
    /// @param _params array of ExecuteParam, includes target, callData, expiration, signatures
    function execute(ExecuteParam[] calldata _params) external onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < _params.length; ++i) {
            ExecuteParam calldata param = _params[i];
            // 1. skip if invalid vid
            if (param.vid != vid) {
                continue;
            }

            // 2. skip if expired
            if (param.expiration <= block.timestamp) {
                continue;
            }

            // generate and validate hash
            bytes32 hash = hashCallData(param.vid, param.target, param.callData, param.expiration);

            // 3. check signatures
            (bool sigsValid, ) = verifySignatures(hash, param.signatures);
            if (!sigsValid) {
                emit VerifySignaturesFailed(i);
                continue;
            }

            // 4. should check hash
            bool shouldCheckHash = _shouldCheckHash(bytes4(param.callData));
            if (shouldCheckHash) {
                if (usedHashes[hash]) {
                    emit HashAlreadyUsed(param, hash);
                    continue;
                } else {
                    usedHashes[hash] = true; // prevent reentry and replay attack
                }
            }

            (bool success, bytes memory rtnData) = param.target.call(param.callData);
            if (!success) {
                if (shouldCheckHash) {
                    // need to unset the usedHash otherwise it cant be used
                    usedHashes[hash] = false;
                }
                // emit an event in any case
                emit ExecuteFailed(i, rtnData);
            }
        }
    }

    /// @dev to support ULNv2
    /// @dev the withdrawFee function for ULN30X is built in the Worker contract
    /// @param _lib message lib address
    /// @param _to address to withdraw to
    /// @param _amount amount to withdraw
    function withdrawFeeFromUlnV2(address _lib, address payable _to, uint _amount) external onlyRole(ADMIN_ROLE) {
        require(hasRole(MESSAGE_LIB_ROLE, _lib), "Verifier: Invalid message lib");
        ILayerZeroUltraLightNodeV2(_lib).withdrawNative(_to, _amount);
    }

    // ========================= OnlyMessageLib =========================

    /// @dev for ULN301, ULN302 and more to assign job
    /// @dev verifier network can reject job from _sender by adding/removing them from allowlist/denylist
    /// @param _param assign job param
    /// @param _options verifier options
    function assignJob(
        AssignJobParam calldata _param,
        bytes calldata _options
    ) external payable onlyRole(MESSAGE_LIB_ROLE) onlyAcl(_param.sender) returns (uint totalFee) {
        IVerifierFeeLib.FeeParams memory feeParams = IVerifierFeeLib.FeeParams(
            priceFeed,
            _param.dstEid,
            _param.confirmations,
            _param.sender,
            quorum,
            defaultMultiplierBps
        );
        totalFee = IVerifierFeeLib(workerFeeLib).getFeeOnSend(feeParams, dstConfig[_param.dstEid], _options);
    }

    /// @dev to support ULNv2
    /// @dev verifier network can reject job from _sender by adding/removing them from allowlist/denylist
    /// @param _dstEid destination EndpointId
    /// @param //_outboundProofType outbound proof type
    /// @param _confirmations block confirmations
    /// @param _sender message sender address
    function assignJob(
        uint16 _dstEid,
        uint16 /*_outboundProofType*/,
        uint64 _confirmations,
        address _sender
    ) external onlyRole(MESSAGE_LIB_ROLE) onlyAcl(_sender) returns (uint totalFee) {
        IVerifierFeeLib.FeeParams memory params = IVerifierFeeLib.FeeParams(
            priceFeed,
            _dstEid,
            _confirmations,
            _sender,
            quorum,
            defaultMultiplierBps
        );
        // ULNV2 does not have verifier options
        totalFee = IVerifierFeeLib(workerFeeLib).getFeeOnSend(params, dstConfig[_dstEid], bytes(""));
        emit VerifierFeePaid(totalFee);
    }

    // ========================= View =========================

    /// @dev getFee can revert if _sender doesn't pass ACL
    /// @param _dstEid destination EndpointId
    /// @param _confirmations block confirmations
    /// @param _sender message sender address
    /// @param _options verifier options
    /// @return fee fee in native amount
    function getFee(
        uint32 _dstEid,
        uint64 _confirmations,
        address _sender,
        bytes calldata _options
    ) external view onlyAcl(_sender) returns (uint fee) {
        IVerifierFeeLib.FeeParams memory params = IVerifierFeeLib.FeeParams(
            priceFeed,
            _dstEid,
            _confirmations,
            _sender,
            quorum,
            defaultMultiplierBps
        );
        return IVerifierFeeLib(workerFeeLib).getFee(params, dstConfig[_dstEid], _options);
    }

    /// @dev to support ULNv2
    /// @dev getFee can revert if _sender doesn't pass ACL
    /// @param _dstEid destination EndpointId
    /// @param //_outboundProofType outbound proof type
    /// @param _confirmations block confirmations
    /// @param _sender message sender address
    function getFee(
        uint16 _dstEid,
        uint16 /*_outboundProofType*/,
        uint64 _confirmations,
        address _sender
    ) public view onlyAcl(_sender) returns (uint fee) {
        IVerifierFeeLib.FeeParams memory params = IVerifierFeeLib.FeeParams(
            priceFeed,
            _dstEid,
            _confirmations,
            _sender,
            quorum,
            defaultMultiplierBps
        );
        return IVerifierFeeLib(workerFeeLib).getFee(params, dstConfig[_dstEid], bytes(""));
    }

    /// @param _target target address
    /// @param _callData call data
    /// @param _expiration expiration timestamp
    /// @return hash of above
    function hashCallData(
        uint32 _vid,
        address _target,
        bytes calldata _callData,
        uint _expiration
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_vid, _target, _expiration, _callData));
    }

    // ========================= Internal =========================

    /// @dev to save gas, we don't check hash for some functions (where replaying won't change the state)
    /// @dev for example, some administrative functions like changing signers, the contract should check hash to double spending
    /// @dev should ensure that all onlySelf functions have unique functionSig
    /// @param _functionSig function signature
    /// @return true if should check hash
    function _shouldCheckHash(bytes4 _functionSig) internal pure returns (bool) {
        // never check for these selectors to save gas
        return
            _functionSig != IUltraLightNode.verify.selector && // 0x0223536e, replaying won't change the state
            _functionSig != this.verifyAndDeliver.selector && // 0xb724b133, replaying calls deliver on top of verify, which will be rejected at uln if not deliverable
            _functionSig != ILayerZeroUltraLightNodeV2.updateHash.selector; // 0x704316e5, replaying will be revert at uln
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroVerifier {
    struct AssignJobParam {
        uint32 dstEid;
        bytes packetHeader;
        bytes32 payloadHash;
        uint64 confirmations;
        address sender;
    }

    // @notice query price and assign jobs at the same time
    // @param _dstEid - the destination endpoint identifier
    // @param _packetHeader - version + nonce + path
    // @param _payloadHash - hash of guid + message
    // @param _confirmations - block confirmation delay before relaying blocks
    // @param _sender - the source sending contract address
    // @param _options - options
    function assignJob(AssignJobParam calldata _param, bytes calldata _options) external payable returns (uint fee);

    // @notice query the verifier fee for relaying block information to the destination chain
    // @param _dstEid the destination endpoint identifier
    // @param _confirmations - block confirmation delay before relaying blocks
    // @param _sender - the source sending contract address
    // @param _options - options
    function getFee(
        uint32 _dstEid,
        uint64 _confirmations,
        address _sender,
        bytes calldata _options
    ) external view returns (uint fee);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import {DeliveryState} from "../../MessageLibBase.sol";

interface IUltraLightNode {
    function verify(bytes calldata _packetHeader, bytes32 _payloadHash, uint64 _confirmations) external;

    function deliver(bytes calldata _packetHeader, bytes32 _payloadHash) external;

    function deliverable(bytes calldata _packetHeader, bytes32 _payloadHash) external view returns (DeliveryState);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "../../interfaces/IWorker.sol";
import "./ILayerZeroVerifier.sol";

interface IVerifier is IWorker, ILayerZeroVerifier {
    struct DstConfigParam {
        uint32 dstEid;
        uint64 gas;
        uint16 multiplierBps;
        uint128 floorMarginUSD;
    }

    struct DstConfig {
        uint64 gas;
        uint16 multiplierBps;
        uint128 floorMarginUSD; // uses priceFeed PRICE_RATIO_DENOMINATOR
    }

    event SetDstConfig(DstConfigParam[] params);

    function dstConfig(uint32 _dstEid) external view returns (uint64, uint16, uint128);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./IVerifier.sol";

interface IVerifierFeeLib {
    struct FeeParams {
        address priceFeed;
        uint32 dstEid;
        uint64 confirmations;
        address sender;
        uint64 quorum;
        uint16 defaultMultiplierBps;
    }

    function getFeeOnSend(
        FeeParams memory _params,
        IVerifier.DstConfig memory _dstConfig,
        bytes memory _options
    ) external payable returns (uint fee);

    function getFee(
        FeeParams calldata _params,
        IVerifier.DstConfig calldata _dstConfig,
        bytes calldata _options
    ) external view returns (uint fee);
}