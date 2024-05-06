// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@xcall/utils/Types.sol";
import "@xcall/contracts/xcall/interfaces/IConnection.sol";
import "@iconfoundation/xcall-solidity-library/interfaces/ICallService.sol";

contract CentralizedConnection is Initializable, IConnection {
    mapping(string => uint256) private messageFees;
    mapping(string => uint256) private responseFees;
    mapping(string => mapping(uint256 => bool)) receipts;
    address private xCall;
    address private adminAddress;
    uint256 public connSn;

    event Message(string targetNetwork, uint256 sn, bytes _msg);

    modifier onlyAdmin() {
        require(msg.sender == this.admin(), "OnlyRelayer");
        _;
    }

    function initialize(address _relayer, address _xCall) public initializer {
        xCall = _xCall;
        adminAddress = _relayer;
    }

    /**
     @notice Sets the fee to the target network
     @param networkId String Network Id of target chain
     @param messageFee Integer ( The fee needed to send a Message )
     @param responseFee Integer (The fee of the response )
     */
    function setFee(
        string calldata networkId,
        uint256 messageFee,
        uint256 responseFee
    ) external onlyAdmin {
        messageFees[networkId] = messageFee;
        responseFees[networkId] = responseFee;
    }

    /**
     @notice Gets the fee to the target network
    @param to String Network Id of target chain
    @param response Boolean ( Whether the responding fee is included )
    @return fee Integer (The fee of sending a message to a given destination network )
    */
    function getFee(
        string memory to,
        bool response
    ) external view override returns (uint256 fee) {
        uint256 messageFee = messageFees[to];
        if (response == true) {
            uint256 responseFee = responseFees[to];
            return messageFee + responseFee;
        }
        return messageFee;
    }

    /**
     @notice Sends the message to a specific network.
     @param sn : positive for two-way message, zero for one-way message, negative for response
     @param to  String ( Network Id of destination network )
     @param svc String ( name of the service )
     @param sn  Integer ( serial number of the xcall message )
     @param _msg Bytes ( serialized bytes of Service Message )
     */
    function sendMessage(
        string calldata to,
        string calldata svc,
        int256 sn,
        bytes calldata _msg
    ) external payable override {
        require(msg.sender == xCall, "Only Xcall can call sendMessage");
        uint256 fee;
        if (sn > 0) {
            fee = this.getFee(to, true);
        } else if (sn == 0) {
            fee = this.getFee(to, false);
        }
        require(msg.value >= fee, "Fee is not Sufficient");
        connSn++;
        emit Message(to, connSn, _msg);
    }

    /**
     @notice Sends the message to a xCall.
     @param srcNetwork  String ( Network Id )
     @param _connSn Integer ( connection message sn )
     @param _msg Bytes ( serialized bytes of Service Message )
     */
    function recvMessage(
        string memory srcNetwork,
        uint256 _connSn,
        bytes calldata _msg
    ) public onlyAdmin {
        require(!receipts[srcNetwork][_connSn], "Duplicate Message");
        receipts[srcNetwork][_connSn] = true;
        ICallService(xCall).handleMessage(srcNetwork, _msg);
    }

    /**
     @notice Sends the balance of the contract to the owner(relayer)

    */
    function claimFees() public onlyAdmin {
        payable(adminAddress).transfer(address(this).balance);
    }

    /**
     @notice Revert a messages, used in special cases where message can't just be dropped
     @param sn  Integer ( serial number of the  xcall message )
     */
    function revertMessage(uint256 sn) public onlyAdmin {
        ICallService(xCall).handleError(sn);
    }

    /**
     @notice Gets a message receipt
     @param srcNetwork String ( Network Id )
     @param _connSn Integer ( connection message sn )
     @return boolean if is has been recived or not
     */
    function getReceipt(
        string memory srcNetwork,
        uint256 _connSn
    ) public view returns (bool) {
        return receipts[srcNetwork][_connSn];
    }

    /**
        @notice Set the address of the admin.
        @param _address The address of the admin.
     */
    function setAdmin(address _address) external onlyAdmin {
        adminAddress = _address;
    }

    /**
       @notice Gets the address of admin
       @return (Address) the address of admin
    */
    function admin() external view returns (address) {
        return adminAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
import "@xcall/utils/RLPEncodeStruct.sol";
import "@xcall/utils/RLPEncodeStruct.sol";

/**
 * @notice List of ALL Struct being used to Encode and Decode RLP Messages
 */
library Types {
    using RLPEncodeStruct for Types.CallMessageWithRollback;
    using RLPEncodeStruct for Types.XCallEnvelope;

    // The name of CallService.
    string constant NAME = "xcallM";

    int constant CS_REQUEST = 1;
    /**
     * Legacy Code, CS_RESPONSE replaced by CS_RESULT in V2
     */
    int constant CS_RESPONSE = 2;

    int constant CS_RESULT = 2;

    int constant CALL_MESSAGE_TYPE = 0;
    int constant CALL_MESSAGE_ROLLBACK_TYPE = 1;
    int constant PERSISTENT_MESSAGE_TYPE = 2;

    /**
     * Legacy Code, CallRequest replaced with RollbackData
     */
    struct CallRequest {
        address from;
        string to;
        string[] sources;
        bytes rollback;
        bool enabled; //whether wait response or received
    }

    struct RollbackData {
        address from;
        string to;
        string[] sources;
        bytes rollback;
        bool enabled; 
    }

    struct CSMessage {
        int msgType;
        bytes payload;
    }

    struct CSMessageResponse {
        uint256 sn;
        int code;
    }

    /**
     * Legacy Code, CSMessageRequest replaced with CSMessageRequestV2
     */
    struct CSMessageRequest {
        string from;
        string to;
        uint256 sn;
        bool rollback;
        bytes data;
        string[] protocols;
    }

    /**
     * Legacy Code, ProxyRequest replaced with ProxyRequestV2
     */
    struct ProxyRequest {
        string from;
        string to;
        uint256 sn;
        bool rollback;
        bytes32 hash;
        string[] protocols;
    }

    struct CSMessageRequestV2 {
        string from;
        string to;
        uint256 sn;
        int messageType;
        bytes data;
        string[] protocols;
    }

    struct ProxyRequestV2 {
        string from;
        string to;
        uint256 sn;
        int256 messageType;
        bytes32 hash;
        string[] protocols;
    }

    int constant CS_RESP_SUCCESS = 1;
    int constant CS_RESP_FAILURE = 0;

    struct CSMessageResult {
        uint256 sn;
        int code;
        bytes message;
    }

    struct PendingResponse {
        bytes msg;
        string targetNetwork;
    }

    struct XCallEnvelope {
        int messageType;
        bytes message;
        string[] sources;
        string[] destinations;
    }

    struct CallMessage {
        bytes data;
    }

    struct CallMessageWithRollback {
        bytes data;
        bytes rollback;
    }

    struct ProcessResult {
        bool needResponse;
        bytes data;
    }

    function createPersistentMessage(
        bytes memory data,
        string[] memory sources,
        string[] memory destinations
    ) internal pure returns (bytes memory) {
        return
            XCallEnvelope(PERSISTENT_MESSAGE_TYPE, data, sources, destinations).encodeXCallEnvelope();
    }

    function createCallMessage(
        bytes memory data,
        string[] memory sources,
        string[] memory destinations
    ) internal pure returns (bytes memory) {
        return XCallEnvelope(CALL_MESSAGE_TYPE, data, sources, destinations).encodeXCallEnvelope();
    }

    function createCallMessageWithRollback(
        bytes memory data,
        bytes memory rollback,
        string[] memory sources,
        string[] memory destinations
    ) internal pure returns (bytes memory) {
        Types.CallMessageWithRollback memory _msg = Types
            .CallMessageWithRollback(data, rollback);

        return
            XCallEnvelope(
                CALL_MESSAGE_ROLLBACK_TYPE,
                _msg.encodeCallMessageWithRollback(),
                sources,
                destinations
            ).encodeXCallEnvelope();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

interface IConnection {

    /**
        @notice Send the message to a specific network.
        @dev Caller must be an registered BSH.
        @param _to      Network id of destination network
        @param _svc     Name of the service
        @param _sn      Serial number of the message
        @param _msg     Serialized bytes of Service Message
     */
    function sendMessage(
        string memory _to,
        string memory _svc,
        int256 _sn,
        bytes memory _msg
    ) external payable;

    /**
       @notice Gets the fee to the target network
       @dev _response should be true if it uses positive value for _sn of {@link #sendMessage}.
            If _to is not reachable, then it reverts.
            If _to does not exist in the fee table, then it returns zero.
       @param  _to       String ( Network ID of destionation chain )
       @param  _response Boolean ( Whether the responding fee is included )
       @return _fee      Integer (The fee of sending a message to a given destination network )
     */
    function getFee(
        string memory _to,
        bool _response
    ) external view returns (
        uint256 _fee
    );

    /**
     * @dev Set the address of the admin.
     * @param _address The address of the admin.
     */
    function setAdmin(address _address) external;

    /**
     * @dev Get the address of the admin.
     * @return (Address) The address of the admin.
     */
    function admin() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface ICallService {
    function getNetworkAddress() external view returns (string memory);

    function getNetworkId() external view returns (string memory);

    /**
       @notice Gets the fee for delivering a message to the _net.
               If the sender is going to provide rollback data, the _rollback param should set as true.
               The returned fee is the sum of the protocol fee and the relay fee.
       @param _net (String) The destination network address
       @param _rollback (Bool) Indicates whether it provides rollback data
       @return (Integer) the sum of the protocol fee and the relay fee
     */
    function getFee(
        string memory _net,
        bool _rollback
    ) external view returns (uint256);

    function getFee(
        string memory _net,
        bool _rollback,
        string[] memory _sources
    ) external view returns (uint256);

    /*======== At the source CALL_BSH ========*/
    /**
       @notice Sends a call message to the contract on the destination chain.
       @param _to The BTP address of the callee on the destination chain
       @param _data The calldata specific to the target contract
       @param _rollback (Optional) The data for restoring the caller state when an error occurred
       @return The serial number of the request
     */
    function sendCallMessage(
        string memory _to,
        bytes memory _data,
        bytes memory _rollback
    ) external payable returns (uint256);

    function sendCallMessage(
        string memory _to,
        bytes memory _data,
        bytes memory _rollback,
        string[] memory sources,
        string[] memory destinations
    ) external payable returns (uint256);

    function sendCall(
        string memory _to,
        bytes memory _data
    ) external payable returns (uint256);

    /**
       @notice Notifies that the requested call message has been sent.
       @param _from The chain-specific address of the caller
       @param _to The BTP address of the callee on the destination chain
       @param _sn The serial number of the request
     */
    event CallMessageSent(
        address indexed _from,
        string indexed _to,
        uint256 indexed _sn
    );

    /**
       @notice Notifies that a response message has arrived for the `_sn` if the request was a two-way message.
       @param _sn The serial number of the previous request
       @param _code The execution result code
                    (0: Success, -1: Unknown generic failure, >=1: User defined error code)
     */
    event ResponseMessage(uint256 indexed _sn, int _code);

    /**
       @notice Notifies the user that a rollback operation is required for the request '_sn'.
       @param _sn The serial number of the previous request
     */
    event RollbackMessage(uint256 indexed _sn);

    /**
       @notice Rollbacks the caller state of the request '_sn'.
       @param _sn The serial number of the previous request
     */
    function executeRollback(uint256 _sn) external;

    /**
       @notice Notifies that the rollback has been executed.
       @param _sn The serial number for the rollback
     */
    event RollbackExecuted(uint256 indexed _sn);

    /*======== At the destination CALL_BSH ========*/
    /**
       @notice Notifies the user that a new call message has arrived.
       @param _from The BTP address of the caller on the source chain
       @param _to A string representation of the callee address
       @param _sn The serial number of the request from the source
       @param _reqId The request id of the destination chain
       @param _data The calldata
     */
    event CallMessage(
        string indexed _from,
        string indexed _to,
        uint256 indexed _sn,
        uint256 _reqId,
        bytes _data
    );

    /**
       @notice Executes the requested call message.
       @param _reqId The request id
       @param _data The calldata
     */
    function executeCall(uint256 _reqId, bytes memory _data) external;

    /**
       @notice Notifies that the call message has been executed.
       @param _reqId The request id for the call message
       @param _code The execution result code
                    (0: Success, -1: Unknown generic failure)
       @param _msg The result message if any
     */
    event CallExecuted(uint256 indexed _reqId, int _code, string _msg);

    /**
       @notice BTP Message from other blockchain.
       @param _from    Network Address of source network
       @param _msg     Serialized bytes of ServiceMessage
   */
    function handleMessage(string calldata _from, bytes calldata _msg) external;

    /**
       @notice Handle the error on delivering the message.
       @param _sn      Serial number of the original message
   */
    function handleError(uint256 _sn) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "@iconfoundation/xcall-solidity-library/utils/RLPEncode.sol";
import "./Types.sol";

library RLPEncodeStruct {
    using RLPEncode for bytes;
    using RLPEncode for string;
    using RLPEncode for uint256;
    using RLPEncode for int256;
    using RLPEncode for address;
    using RLPEncode for bool;

    using RLPEncodeStruct for Types.CSMessage;
    using RLPEncodeStruct for Types.CSMessageRequest;
    using RLPEncodeStruct for Types.CSMessageResult;

    function encodeCSMessage(
        Types.CSMessage memory _bs
    ) internal pure returns (bytes memory) {
        bytes memory _rlp = abi.encodePacked(
            _bs.msgType.encodeInt(),
            _bs.payload.encodeBytes()
        );
        return _rlp.encodeList();
    }

    function encodeCSMessageRequest(Types.CSMessageRequest memory _bs)
        internal
        pure
        returns (bytes memory)
    {

        bytes memory _protocols;
        bytes memory temp;
        for (uint256 i = 0; i < _bs.protocols.length; i++) {
            temp = abi.encodePacked(_bs.protocols[i].encodeString());
            _protocols = abi.encodePacked(_protocols, temp);
        }
        bytes memory _rlp =
            abi.encodePacked(
                _bs.from.encodeString(),
                _bs.to.encodeString(),
                _bs.sn.encodeUint(),
                _bs.rollback.encodeBool(),
                _bs.data.encodeBytes(),
                _protocols.encodeList()

            );
        return _rlp.encodeList();
    }

    function encodeCSMessageRequestV2(
        Types.CSMessageRequestV2 memory _bs
    ) internal pure returns (bytes memory) {
        bytes memory _protocols;
        bytes memory temp;
        for (uint256 i = 0; i < _bs.protocols.length; i++) {
            temp = abi.encodePacked(_bs.protocols[i].encodeString());
            _protocols = abi.encodePacked(_protocols, temp);
        }
        bytes memory _rlp = abi.encodePacked(
            _bs.from.encodeString(),
            _bs.to.encodeString(),
            _bs.sn.encodeUint(),
            _bs.messageType.encodeInt(),
            _bs.data.encodeBytes(),
            _protocols.encodeList()
        );
        return _rlp.encodeList();
    }

    function encodeCSMessageResponse(Types.CSMessageResponse memory _bs)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp =
            abi.encodePacked(
                _bs.sn.encodeUint(),
                _bs.code.encodeInt()
            );
        return _rlp.encodeList();
    }

    function encodeXCallEnvelope(
        Types.XCallEnvelope memory env
    ) internal pure returns (bytes memory) {

        bytes memory _sources;
        bytes memory temp;

        for (uint256 i = 0; i < env.sources.length; i++) {
            temp = abi.encodePacked(env.sources[i].encodeString());
            _sources = abi.encodePacked(_sources, temp);
        }

        bytes memory _dests;
        for (uint256 i = 0; i < env.destinations.length; i++) {
            temp = abi.encodePacked(env.destinations[i].encodeString());
            _dests = abi.encodePacked(_dests, temp);
        }

        bytes memory _rlp = abi.encodePacked(
            env.messageType.encodeInt(),
            env.message.encodeBytes(),
            _sources.encodeList(),
            _dests.encodeList()
        );

        return _rlp.encodeList();
    }

    function encodeCSMessageResult(
        Types.CSMessageResult memory _bs
    ) internal pure returns (bytes memory) {
        bytes memory _rlp = abi.encodePacked(
            _bs.sn.encodeUint(),
            _bs.code.encodeInt(),
            _bs.message.encodeBytes()
        );
        return _rlp.encodeList();
    }

    function encodeCallMessageWithRollback(
        Types.CallMessageWithRollback memory _bs
    ) internal pure returns (bytes memory) {
        bytes memory _rlp = abi.encodePacked(
            _bs.data.encodeBytes(),
            _bs.rollback.encodeBytes()
        );
        return _rlp.encodeList();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * @title RLPEncode
 * @dev A simple RLP encoding library.
 * @author Bakaoh
 * The original code was modified. For more info, please check the link:
 * https://github.com/bakaoh/solidity-rlp-encode.git
 */
library RLPEncode {
    bytes internal constant NULL = hex"f800";

    /*
     * Internal functions
     */

    /**
     * @dev RLP encodes a byte string.
     * @param self The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeBytes(bytes memory self)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encoded;
        if (self.length == 1 && uint8(self[0]) < 128) {
            encoded = self;
        } else {
            encoded = abi.encodePacked(encodeLength(self.length, 128), self);
        }
        return encoded;
    }

    /**
     * @dev RLP encodes a list of RLP encoded byte byte strings.
     * @param self The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function encodeList(bytes[] memory self)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory list = flatten(self);
        return abi.encodePacked(encodeLength(list.length, 192), list);
    }

    /**
     * @dev RLP encodes a list
     * @param self concatenated bytes of RLP encoded bytes.
     * @return The RLP encoded list of items in bytes
     */
    function encodeList(bytes memory self)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(encodeLength(self.length, 192), self);
    }

    /**
     * @dev RLP encodes a string.
     * @param self The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeString(string memory self)
        internal
        pure
        returns (bytes memory)
    {
        return encodeBytes(bytes(self));
    }

    /**
     * @dev RLP encodes an address.
     * @param self The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function encodeAddress(address self) internal pure returns (bytes memory) {
        bytes memory inputBytes;
        assembly {
            let m := mload(0x40)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, self)
            )
            mstore(0x40, add(m, 52))
            inputBytes := m
        }
        return encodeBytes(inputBytes);
    }

    /**
     * @dev RLP encodes a uint.
     * @param self The uint to encode.
     * @return The RLP encoded uint in bytes.
     */
    function encodeUint(uint256 self) internal pure returns (bytes memory) {
        return encodeBytes(uintToBytes(self));
    }

    /**
     * @dev RLP encodes an int.
     * @param self The int to encode.
     * @return The RLP encoded int in bytes.
     */
    function encodeInt(int256 self) internal pure returns (bytes memory) {
        return encodeBytes(intToBytes(self));
    }

    /**
     * @dev RLP encodes a bool.
     * @param self The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function encodeBool(bool self) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (self ? bytes1(0x01) : bytes1(0x00));
        return encoded;
    }

    /**
     * @dev RLP encodes null.
     * @return bytes for null
     */
    function encodeNull() internal pure returns (bytes memory) {
        return NULL;
    }

    /*
     * Private functions
     */

    /**
     * @dev Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param len The length of the string or the payload.
     * @param offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function encodeLength(uint256 len, uint256 offset)
        private
        pure
        returns (bytes memory)
    {
        bytes memory encoded;
        if (len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes32(len + offset)[31];
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes32(lenLen + offset + 55)[31];
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes32((len / (256**(lenLen - i))) % 256)[31];
            }
        }
        return encoded;
    }

    function lastBytesOf(int256 value, uint256 size) internal pure returns  (bytes memory){
        bytes memory buffer = new bytes(size);
        assembly {
            let dst := add(buffer, 32)
            for { let idx := sub(32,size) } lt(idx,32) { idx := add(idx, 1) } {
                mstore8(dst, byte(idx, value))
                dst := add(dst, 1)
            }
        }
        return buffer;
    }

    function intToBytes(int256 x) internal pure returns (bytes memory) {
        if (x == 0) {
            return new bytes(1);
        }
        int256 right = 0x80;
        int256 left = -0x81;
        for (uint i = 1 ; i<32 ; i++) {
            if ((x<right) && (x>left)) {
                return lastBytesOf(x, i);
            }
            right <<= 8;
            left <<= 8;
        }
        return abi.encodePacked(x);
    }

    function uintToBytes(uint256 x) internal pure returns (bytes memory) {
        if (x == 0) {
            return new bytes(1);
        }
        uint256 right = 0x80;
        for (uint i = 1 ; i<32 ; i++) {
            if (x<right) {
                return lastBytesOf(int256(x), i);
            }
            right <<= 8;
        }
        if (x<right) {
            return abi.encodePacked(x);
        } else {
            return abi.encodePacked(bytes1(0), x);
        }
    }

    /**
     * @dev Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i;
        for (i = 0; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }

    /**
     * @dev Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param dest Destination location.
     * @param src Source location.
     * @param len Length of memory to copy.
     */
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}