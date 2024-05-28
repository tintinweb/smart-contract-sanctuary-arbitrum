// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./interfaces/IFeeManage.sol";
import "./interfaces/IConnection.sol";
import "@xcall/utils/RLPDecodeStruct.sol";
import "@xcall/utils/RLPEncodeStruct.sol";
import "@xcall/utils/Types.sol";

import "@iconfoundation/xcall-solidity-library/interfaces/IBSH.sol";
import "@iconfoundation/xcall-solidity-library/interfaces/ICallService.sol";
import "@iconfoundation/xcall-solidity-library/interfaces/ICallServiceReceiver.sol";
import "@iconfoundation/xcall-solidity-library/interfaces/IDefaultCallServiceReceiver.sol";
import "@iconfoundation/xcall-solidity-library/utils/NetworkAddress.sol";
import "@iconfoundation/xcall-solidity-library/utils/Integers.sol";
import "@iconfoundation/xcall-solidity-library/utils/ParseAddress.sol";
import "@iconfoundation/xcall-solidity-library/utils/Strings.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/// @custom:oz-upgrades-from contracts/xcall/CallServiceV1.sol:CallServiceV1
contract CallService is IBSH, ICallService, IFeeManage, Initializable {
    using Strings for string;
    using Integers for uint;
    using ParseAddress for address;
    using ParseAddress for string;
    using NetworkAddress for string;
    using RLPEncodeStruct for Types.CSMessage;
    using RLPEncodeStruct for Types.CSMessageRequestV2;
    using RLPEncodeStruct for Types.CSMessageResult;
    using RLPEncodeStruct for Types.CallMessageWithRollback;
    using RLPEncodeStruct for Types.XCallEnvelope;
    using RLPDecodeStruct for bytes;

    uint256 private constant MAX_DATA_SIZE = 2048;
    uint256 private constant MAX_ROLLBACK_SIZE = 1024;
    string private nid;
    string private networkAddress;
    uint256 private lastSn;
    uint256 private lastReqId;
    uint256 private protocolFee;

    /**
     * Legacy Code, replaced by rollbacks in V2
     */
    mapping(uint256 => Types.CallRequest) private requests;

    /**
     * Legacy Code, replaced by proxyReqsV2 in V2
     */
    mapping(uint256 => Types.ProxyRequest) private proxyReqs;

    mapping(uint256 => bool) private successfulResponses;

    mapping(bytes32 => mapping(string => bool)) private pendingReqs;
    mapping(uint256 => mapping(string => bool)) private pendingResponses;

    mapping(string => address) private defaultConnections;

    address private owner;
    address private adminAddress;
    address payable private feeHandler;

    mapping(uint256 => Types.RollbackData) private rollbacks;
    mapping(uint256 => Types.ProxyRequestV2) private proxyReqsV2;

    bytes private callReply;
    Types.ProxyRequestV2 private replyState;

    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin(), "OnlyAdmin");
        _;
    }

    function initialize(string memory _nid) public initializer {
        owner = msg.sender;
        adminAddress = msg.sender;
        nid = _nid;
        networkAddress = nid.networkAddress(address(this).toString());
    }

    /* Implementation-specific external */
    function getNetworkAddress()
        external
        view
        override
        returns (string memory)
    {
        return networkAddress;
    }

    function getNetworkId() external view override returns (string memory) {
        return nid;
    }

    function checkService(string calldata _svc) internal pure {
        require(Types.NAME.compareTo(_svc), "InvalidServiceName");
    }

    function getNextSn() internal returns (uint256) {
        lastSn = lastSn + 1;
        return lastSn;
    }

    function getNextReqId() internal returns (uint256) {
        lastReqId = lastReqId + 1;
        return lastReqId;
    }

    function cleanupCallRequest(uint256 sn) internal {
        delete rollbacks[sn];
    }

    function sendCallMessage(
        string memory _to,
        bytes memory _data,
        bytes memory _rollback,
        string[] memory sources,
        string[] memory destinations
    ) external payable override returns (uint256) {
        return _sendCallMessage(_to, _data, _rollback, sources, destinations);
    }

    function sendCallMessage(
        string memory _to,
        bytes memory _data,
        bytes memory _rollback
    ) external payable override returns (uint256) {
        string[] memory src;
        string[] memory dst;
        return _sendCallMessage(_to, _data, _rollback, src, dst);
    }

    function sendCall(
        string memory _to,
        bytes memory _data
    ) public payable returns (uint256) {
        address caller = msg.sender;
        Types.XCallEnvelope memory envelope = _data.decodeXCallEnvelope();
        uint256 sn = getNextSn();
        Types.ProcessResult memory result = preProcessMessage(
            sn,
            _to,
            envelope
        );

        string memory from = nid.networkAddress(caller.toString());

        (string memory netTo, string memory dstAccount) = _to
            .parseNetworkAddress();

        Types.CSMessageRequestV2 memory req = Types.CSMessageRequestV2(
            from,
            dstAccount,
            sn,
            envelope.messageType,
            result.data,
            envelope.destinations
        );

        bytes memory _msg = req.encodeCSMessageRequestV2();
        require(_msg.length <= MAX_DATA_SIZE, "MaxDataSizeExceeded");

        if (isReply(netTo, envelope.sources) && !result.needResponse) {
            delete replyState;
            callReply = _msg;
        } else {
            uint256 sendSn = result.needResponse ? sn : 0;

            sendMessage(
                envelope.sources,
                netTo,
                Types.CS_REQUEST,
                int(sendSn),
                _msg
            );
            claimProtocolFee();
        }
        emit CallMessageSent(caller, _to, sn);
        return sn;
    }

    function sendMessage(
        string[] memory sources,
        string memory netTo,
        int msgType,
        int256 sn,
        bytes memory data
    ) private {
        if (sources.length == 0) {
            address conn = defaultConnections[netTo];
            require(conn != address(0), "NoDefaultConnection");
            uint256 requiredFee = _getFee(conn, netTo, sn);
            sendToConnection(conn, requiredFee, netTo, msgType, sn, data);
        } else {
            for (uint i = 0; i < sources.length; i++) {
                address conn = sources[i].parseAddress("IllegalArgument");
                uint256 requiredFee = _getFee(conn, netTo, sn);
                sendToConnection(conn, requiredFee, netTo, msgType, sn, data);
            }
        }
    }

    function preProcessMessage(
        uint256 sn,
        string memory to,
        Types.XCallEnvelope memory envelope
    ) internal returns (Types.ProcessResult memory) {
        int envelopeType = envelope.messageType;
        if (
            envelopeType == Types.CALL_MESSAGE_TYPE ||
            envelopeType == Types.PERSISTENT_MESSAGE_TYPE
        ) {
            return Types.ProcessResult(false, envelope.message);
        } else if (envelopeType == Types.CALL_MESSAGE_ROLLBACK_TYPE) {
            address caller = msg.sender;
            Types.CallMessageWithRollback memory _msg = envelope
                .message
                .decodeCallMessageWithRollback();
            require(msg.sender.code.length > 0, "RollbackNotPossible");
            Types.RollbackData memory req = Types.RollbackData(
                caller,
                to.nid(),
                envelope.sources,
                _msg.rollback,
                false
            );
            rollbacks[sn] = req;
            return Types.ProcessResult(true, _msg.data);
        }
        revert("Message type is not supported");
    }

    function claimProtocolFee() internal {
        uint256 balance = address(this).balance;
        require(balance >= protocolFee, "InsufficientBalance");
        feeHandler.transfer(balance);
    }

    function _sendCallMessage(
        string memory _to,
        bytes memory _data,
        bytes memory _rollback,
        string[] memory sources,
        string[] memory destinations
    ) internal returns (uint256) {
        int msgType;

        Types.XCallEnvelope memory envelope;

        if (_rollback.length == 0) {
            Types.CallMessage memory _msg = Types.CallMessage(_data);
            envelope = Types.XCallEnvelope(
                Types.CALL_MESSAGE_TYPE,
                _msg.data,
                sources,
                destinations
            );
        } else {
            Types.CallMessageWithRollback memory _msg = Types
                .CallMessageWithRollback(_data, _rollback);

            envelope = Types.XCallEnvelope(
                Types.CALL_MESSAGE_ROLLBACK_TYPE,
                _msg.encodeCallMessageWithRollback(),
                sources,
                destinations
            );
        }

        return sendCall(_to, envelope.encodeXCallEnvelope());
    }

    function executeCall(uint256 _reqId, bytes memory _data) external override {
        Types.ProxyRequestV2 memory req = proxyReqsV2[_reqId];
        require(bytes(req.from).length > 0, "InvalidRequestId");
        require(req.hash == keccak256(_data), "DataHashMismatch");
        // cleanup
        delete proxyReqsV2[_reqId];

        string[] memory protocols = req.protocols;
        address dapp = req.to.parseAddress("IllegalArgument");
        if (req.messageType == Types.CALL_MESSAGE_TYPE) {
            tryExecuteCall(_reqId, dapp, req.from, _data, protocols);
        } else if (req.messageType == Types.PERSISTENT_MESSAGE_TYPE) {
            this.executeMessage(dapp, req.from, _data, protocols);
        } else if (req.messageType == Types.CALL_MESSAGE_ROLLBACK_TYPE) {
            replyState = req;
            int256 code = tryExecuteCall(
                _reqId,
                dapp,
                req.from,
                _data,
                protocols
            );
            delete replyState;

            bytes memory message;
            if (callReply.length > 0 && code == Types.CS_RESP_SUCCESS) {
                message = callReply;
                delete callReply;
            }
            Types.CSMessageResult memory response = Types.CSMessageResult(
                req.sn,
                code,
                message
            );

            sendMessage(
                protocols,
                req.from.nid(),
                Types.CS_RESULT,
                int256(req.sn) * -1,
                response.encodeCSMessageResult()
            );
        } else {
            revert("Message type is not yet supported");
        }
    }

    function tryExecuteCall(
        uint256 id,
        address dapp,
        string memory from,
        bytes memory data,
        string[] memory protocols
    ) private returns (int256) {
        try this.executeMessage(dapp, from, data, protocols) {
            emit CallExecuted(id, Types.CS_RESP_SUCCESS, "");
            return Types.CS_RESP_SUCCESS;
        } catch Error(string memory errorMessage) {
            emit CallExecuted(id, Types.CS_RESP_FAILURE, errorMessage);
            return Types.CS_RESP_FAILURE;
        } catch (bytes memory) {
            emit CallExecuted(id, Types.CS_RESP_FAILURE, "unknownError");
            return Types.CS_RESP_FAILURE;
        }
    }

    //  @dev To catch error
    function executeMessage(
        address to,
        string memory from,
        bytes memory data,
        string[] memory protocols
    ) external {
        require(msg.sender == address(this), "OnlyInternal");
        if (protocols.length == 0) {
            IDefaultCallServiceReceiver(to).handleCallMessage(from, data);
        } else {
            ICallServiceReceiver(to).handleCallMessage(from, data, protocols);
        }
    }

    function executeRollback(uint256 _sn) external override {
        Types.RollbackData memory req = rollbacks[_sn];
        require(req.from != address(0), "InvalidSerialNum");
        require(req.enabled, "RollbackNotEnabled");
        cleanupCallRequest(_sn);

        this.executeMessage(
            req.from,
            networkAddress,
            req.rollback,
            req.sources
        );

        emit RollbackExecuted(_sn);
    }

    /* ========== Interfaces with BMC ========== */
    function handleBTPMessage(
        string calldata _from,
        string calldata _svc,
        uint256 _sn,
        bytes calldata _msg
    ) external override {
        checkService(_svc);
        handleMessage(_from, _msg);
    }

    function handleBTPError(
        string calldata _src,
        string calldata _svc,
        uint256 _sn,
        uint256 _code,
        string calldata _msg
    ) external override {
        checkService(_svc);
        handleError(_sn);
    }

    /* ========================================= */

    function handleMessage(
        string calldata _from,
        bytes calldata _msg
    ) public override {
        require(!_from.compareTo(nid), "Invalid Network ID");
        Types.CSMessage memory csMsg = _msg.decodeCSMessage();
        if (csMsg.msgType == Types.CS_REQUEST) {
            handleRequest(_from, csMsg.payload);
        } else if (csMsg.msgType == Types.CS_RESULT) {
            handleResult(csMsg.payload.decodeCSMessageResult());
        } else {
            string memory errMsg = string("UnknownMsgType(")
                .concat(uint(csMsg.msgType).toString())
                .concat(string(")"));
            revert(errMsg);
        }
    }

    function handleError(uint256 _sn) public override {
        handleResult(
            Types.CSMessageResult(_sn, Types.CS_RESP_FAILURE, bytes(""))
        );
    }

    function sendToConnection(
        address connection,
        uint256 value,
        string memory netTo,
        int msgType,
        int256 sn,
        bytes memory msgPayload
    ) internal {
        IConnection(connection).sendMessage{value: value}(
            netTo,
            Types.NAME,
            sn,
            Types.CSMessage(msgType, msgPayload).encodeCSMessage()
        );
    }

    function handleRequest(
        string memory netFrom,
        bytes memory msgPayload
    ) internal {
        Types.CSMessageRequestV2 memory req = msgPayload
            .decodeCSMessageRequestV2();
        string memory fromNID = req.from.nid();
        require(netFrom.compareTo(fromNID), "Invalid NID");

        bytes32 dataHash = keccak256(msgPayload);
        if (req.protocols.length > 1) {
            pendingReqs[dataHash][msg.sender.toString()] = true;
            for (uint i = 0; i < req.protocols.length; i++) {
                if (!pendingReqs[dataHash][req.protocols[i]]) {
                    return;
                }
            }
            for (uint i = 0; i < req.protocols.length; i++) {
                delete pendingReqs[dataHash][req.protocols[i]];
            }
        } else if (req.protocols.length == 1) {
            require(
                msg.sender == req.protocols[0].parseAddress("IllegalArgument"),
                "NotAuthorized"
            );
        } else {
            require(msg.sender == defaultConnections[fromNID], "NotAuthorized");
        }
        uint256 reqId = getNextReqId();

        proxyReqsV2[reqId] = Types.ProxyRequestV2(
            req.from,
            req.to,
            req.sn,
            req.messageType,
            keccak256(req.data),
            req.protocols
        );

        emit CallMessage(req.from, req.to, req.sn, reqId, req.data);
    }

    function handleReply(
        Types.RollbackData memory rollback,
        Types.CSMessageRequestV2 memory reply
    ) internal {
        require(rollback.to.compareTo(reply.from.nid()), "Invalid Reply");
        uint256 reqId = getNextReqId();

        emit CallMessage(reply.from, reply.to, reply.sn, reqId, reply.data);

        proxyReqsV2[reqId] = Types.ProxyRequestV2(
            reply.from,
            reply.to,
            reply.sn,
            reply.messageType,
            keccak256(reply.data),
            rollback.sources
        );
    }

    function handleResult(Types.CSMessageResult memory res) internal {
        Types.RollbackData memory rollback = rollbacks[res.sn];
        require(rollback.from != address(0), "CallRequestNotFound");

        if (rollback.sources.length > 1) {
            pendingResponses[res.sn][msg.sender.toString()] = true;
            for (uint i = 0; i < rollback.sources.length; i++) {
                if (!pendingResponses[res.sn][rollback.sources[i]]) {
                    return;
                }
            }

            for (uint i = 0; i < rollback.sources.length; i++) {
                delete pendingResponses[res.sn][rollback.sources[i]];
            }
        } else if (rollback.sources.length == 1) {
            require(
                msg.sender ==
                    rollback.sources[0].parseAddress("IllegalArgument"),
                "NotAuthorized"
            );
        } else {
            require(
                msg.sender == defaultConnections[rollback.to],
                "NotAuthorized"
            );
        }

        emit ResponseMessage(res.sn, res.code);
        if (res.code == Types.CS_RESP_SUCCESS) {
            cleanupCallRequest(res.sn);
            if (res.message.length > 0) {
                handleReply(rollback, res.message.decodeCSMessageRequestV2());
            }
            successfulResponses[res.sn] = true;
        } else {
            //emit rollback event
            require(rollback.rollback.length > 0, "NoRollbackData");
            rollback.enabled = true;
            rollbacks[res.sn] = rollback;

            emit RollbackMessage(res.sn);
        }
    }

    function _admin() internal view returns (address) {
        if (adminAddress == address(0)) {
            return owner;
        }
        return adminAddress;
    }

    /**
       @notice Gets the address of admin
       @return (Address) the address of admin
    */
    function admin() external view returns (address) {
        return _admin();
    }

    /**
       @notice Sets the address of admin
       @dev Only the owner wallet can invoke this.
       @param _address (Address) The address of admin
    */
    function setAdmin(address _address) external onlyAdmin {
        require(_address != address(0), "InvalidAddress");
        adminAddress = _address;
    }

    function setProtocolFeeHandler(address _addr) external override onlyAdmin {
        require(_addr != address(0), "InvalidAddress");
        feeHandler = payable(_addr);
    }

    function getProtocolFeeHandler() external view override returns (address) {
        return feeHandler;
    }

    function setDefaultConnection(
        string memory _nid,
        address connection
    ) external onlyAdmin {
        defaultConnections[_nid] = connection;
    }

    function getDefaultConnection(
        string memory _nid
    ) external view returns (address) {
        return defaultConnections[_nid];
    }

    function setProtocolFee(uint256 _value) external override onlyAdmin {
        require(_value >= 0, "ValueShouldBePositive");
        protocolFee = _value;
    }

    function getProtocolFee() external view override returns (uint256) {
        return protocolFee;
    }

    function _getFee(
        address connection,
        string memory _net,
        bool _rollback
    ) internal view returns (uint256) {
        return IConnection(connection).getFee(_net, _rollback);
    }

    function _getFee(
        address connection,
        string memory _net,
        int256 sn
    ) internal view returns (uint256) {
        if (sn < 0) {
            return 0;
        }
        return IConnection(connection).getFee(_net, sn > 0);
    }

    function getFee(
        string memory _net,
        bool _rollback
    ) external view override returns (uint256) {
        return protocolFee + _getFee(defaultConnections[_net], _net, _rollback);
    }

    function getFee(
        string memory _net,
        bool _rollback,
        string[] memory _sources
    ) external view override returns (uint256) {
        uint256 fee = protocolFee;
        if (isReply(_net, _sources) && !_rollback) {
            return 0;
        }
        for (uint i = 0; i < _sources.length; i++) {
            address conn = _sources[i].parseAddress("IllegalArgument");
            fee = fee + _getFee(conn, _net, _rollback);
        }

        return fee;
    }

    function isReply(
        string memory _net,
        string[] memory _sources
    ) internal view returns (bool) {
        if (!replyState.from.compareTo("")) {
            return
                replyState.from.nid().compareTo(_net) &&
                areArraysEqual(replyState.protocols, _sources);
        }
        return false;
    }

    function areArraysEqual(
        string[] memory array1,
        string[] memory array2
    ) internal pure returns (bool) {
        if (array1.length != array2.length) {
            return false;
        }

        for (uint256 i = 0; i < array1.length; i++) {
            if (!array1[i].compareTo(array2[i])) {
                return false;
            }
        }

        return true;
    }

    function verifySuccess(uint256 _sn) external view returns (bool) {
        return successfulResponses[_sn];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IFeeManage {
    /**
       @notice Sets the address of FeeHandler.
               If _addr is null (default), it accrues protocol fees.
               If _addr is a valid address, it transfers accrued fees to the address and
               will also transfer the receiving fees hereafter.
       @dev Only the admin wallet can invoke this.
       @param _addr (Address) The address of FeeHandler
     */
    function setProtocolFeeHandler(
        address _addr
    ) external;

    /**
       @notice Gets the current protocol fee handler address.
       @return (Address) The protocol fee handler address
     */
    function getProtocolFeeHandler(
    ) external view returns (
        address
    );

    /**
       @notice Sets the protocol fee amount.
       @dev Only the admin wallet can invoke this.
       @param _value (Integer) The protocol fee amount in loop
     */
    function setProtocolFee(
        uint256 _value
    ) external;

    /**
       @notice Gets the current protocol fee amount.
       @return (Integer) The protocol fee amount in loop
     */
    function getProtocolFee(
    ) external view returns (
        uint256
    );
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
pragma abicoder v2;

import "@iconfoundation/xcall-solidity-library/utils/RLPDecode.sol";
import "./Types.sol";

library RLPDecodeStruct {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;
    using RLPDecode for bytes;

    using RLPDecodeStruct for bytes;

    uint8 private constant LIST_SHORT_START = 0xc0;
    uint8 private constant LIST_LONG_START = 0xf7;

    function decodeCSMessage(
        bytes memory _rlp
    ) internal pure returns (Types.CSMessage memory) {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return
            Types.CSMessage(
                ls[0].toInt(),
                ls[1].toBytes() //  bytes array of RLPEncode(Data)
            );
    }

    function decodeCSMessageResponse(bytes memory _rlp)
        internal
        pure
    returns (Types.CSMessageResponse memory)
    {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return
        Types.CSMessageResponse(
            ls[0].toUint(),
            int(ls[1].toInt())
        );
    }

    function toStringArray(
        RLPDecode.RLPItem memory item
    ) internal pure returns (string[] memory) {
        RLPDecode.RLPItem[] memory ls = item.toList();
        string[] memory protocols = new string[](ls.length);
        for (uint256 i = 0; i < ls.length; i++) {
            protocols[i] = string(ls[i].toBytes());
        }
        return protocols;
    }

    function decodeCSMessageRequest(bytes memory _rlp)
        internal
        pure
    returns (Types.CSMessageRequest memory)
    {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return
        Types.CSMessageRequest(
            string(ls[0].toBytes()),
            string(ls[1].toBytes()),
            ls[2].toUint(),
            ls[3].toBoolean(),
            ls[4].toBytes(),
            toStringArray(ls[5])
        );
    }

    function decodeCSMessageRequestV2(
        bytes memory _rlp
    ) internal pure returns (Types.CSMessageRequestV2 memory) {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return
            Types.CSMessageRequestV2(
                string(ls[0].toBytes()),
                string(ls[1].toBytes()),
                ls[2].toUint(),
                ls[3].toInt(),
                ls[4].toBytes(),
                toStringArray(ls[5])
            );
    }

    function decodeCallMessageWithRollback(
        bytes memory _rlp
    ) internal pure returns (Types.CallMessageWithRollback memory) {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return
            Types.CallMessageWithRollback(
                ls[0].toBytes(),
                ls[1].toBytes()
            );
    }


    function decodeXCallEnvelope(
        bytes memory _rlp
    ) internal pure returns (Types.XCallEnvelope memory) {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        
        return
            Types.XCallEnvelope(
                ls[0].toInt(),
                ls[1].toBytes(),
                toStringArray(ls[2]),
                toStringArray(ls[3])
            );
    }

    function decodeCSMessageResult(
        bytes memory _rlp
    ) internal pure returns (Types.CSMessageResult memory) {
        RLPDecode.RLPItem[] memory ls = _rlp.toRlpItem().toList();
        return Types.CSMessageResult(ls[0].toUint(), ls[1].toInt(), ls[2].toBytes());
    }
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

interface IBSH {
    /**
       @notice Handle BTP Message from other blockchain.
       @dev Accept the message only from the BMC.
       Every BSH must implement this function
       @param _from    Network Address of source network
       @param _svc     Name of the service
       @param _sn      Serial number of the message
       @param _msg     Serialized bytes of ServiceMessage
   */
    function handleBTPMessage(
        string calldata _from,
        string calldata _svc,
        uint256 _sn,
        bytes calldata _msg
    ) external;

    /**
       @notice Handle the error on delivering the message.
       @dev Accept the error only from the BMC.
       Every BSH must implement this function
       @param _src     BTP Address of BMC generates the error
       @param _svc     Name of the service
       @param _sn      Serial number of the original message
       @param _code    Code of the error
       @param _msg     Message of the error
   */
    function handleBTPError(
        string calldata _src,
        string calldata _svc,
        uint256 _sn,
        uint256 _code,
        string calldata _msg
    ) external;

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

interface ICallServiceReceiver {
        /**
       @notice Handles the call message received from the source chain.
       @dev Only called from the Call Message Service.
       @param _from The BTP address of the caller on the source chain
       @param _data The calldata delivered from the caller
       @param _protocols The addresses that delivered the message
     */
    function handleCallMessage(
        string calldata _from,
        bytes calldata _data,
        string[] calldata _protocols
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IDefaultCallServiceReceiver {
    /**
       @notice Handles the call message received from the source chain.
       @dev Only called from the Call Message Service.
       @param _from The BTP address of the caller on the source chain
       @param _data The calldata delivered from the caller
     */
    function handleCallMessage(
        string calldata _from,
        bytes calldata _data
    ) external;

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
   NetworkAdress 'NETWORK_ID/ACCOUNT_ADDRESS'
*/
library NetworkAddress {
    string internal constant REVERT = "invalidNetworkAddress";
    bytes internal constant DELIMITER = bytes("/");

    /**
       @notice Parse NetworkAddress address
       @param _str (String) Network Address
       @return (String) network id
       @return (String) account address
    */
    function parseNetworkAddress(
        string memory _str
    ) internal pure returns (
        string memory,
        string memory
    ) {
        uint256 offset = _validate(_str);
        return (_slice(_str, 0, offset),
        _slice(_str, offset+1, bytes(_str).length));
    }


    /**
       @notice Gets network id of Network address
       @param _str (String) Network address
       @return (String) network id
    */
    function nid(
        string memory _str
    ) internal pure returns (
        string memory
    ) {
        return _slice(_str, 0, _validate(_str));
    }

    function _validate(
        string memory _str
    ) private pure returns (
        uint256 offset
    ){
        bytes memory _bytes = bytes(_str);

        uint256 i = 0;
        for (; i < _bytes.length; i++) {
            if (_bytes[i] == DELIMITER[0]) {
                return i;
            }
        }
        revert(REVERT);
    }

    function _slice(
        string memory _str,
        uint256 _from,
        uint256 _to
    ) private pure returns (
        string memory
    ) {
        //If _str is calldata, could use slice
        //        return string(bytes(_str)[_from:_to]);
        bytes memory _bytes = bytes(_str);
        bytes memory _ret = new bytes(_to - _from);
        uint256 j = _from;
        for (uint256 i = 0; i < _ret.length; i++) {
            _ret[i] = _bytes[j++];
        }
        return string(_ret);
    }

    /**
       @notice Create Network address by network id and account address
       @param _net (String) network id
       @param _addr (String) account address
       @return (String) Network address
    */
    function networkAddress(
        string memory _net,
        string memory _addr
    ) internal pure returns (
        string memory
    ) {
        return string(abi.encodePacked(_net, DELIMITER, _addr));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * Integers Library
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * The original library was modified. If you want to know more about the original version
 * please check this link: https://github.com/willitscale/solidity-util.git
 */
library Integers {
    /**
     * Parse Int
     *
     * Converts an ASCII string value into an uint as long as the string
     * its self is a valid unsigned integer
     *
     * @param _value The ASCII string to be converted to an unsigned integer
     * @return _ret The unsigned value of the ASCII string
     */
    function parseInt(string memory _value)
    public
    pure
    returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48)*j;
            j*=10;
        }
    }

    /**
     * To String
     *
     * Converts an unsigned integer to the ASCII string equivalent value
     *
     * @param _base The unsigned integer to be converted to a string
     * @return string The resulting ASCII string value
     */
    function toString(uint _base)
    internal
    pure
    returns (string memory) {
        if (_base == 0) {
            return string("0");
        }
        bytes memory _tmp = new bytes(32);
        uint i;
        for(i = 0;_base > 0;i++) {
            _tmp[i] = bytes1(uint8((_base % 10) + 48));
            _base /= 10;
        }
        bytes memory _real = new bytes(i--);
        for(uint j = 0; j < _real.length; j++) {
            //not allowed i-- if i==0
            _real[j] = _tmp[i-j];
        }
        return string(_real);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/*
 * Utility library of inline functions on addresses
 */
library ParseAddress {
    /**
     * @dev Get a checksummed string hex representation of an account address.
     * @param account address The account to get the checksum for.
     * @return The checksummed account string in ASCII format. Note that leading
     * "0x" is not included.
     */
    function toString(address account) internal pure returns (string memory) {
        // call internal function for converting an account to a checksummed string.
        return _toChecksumString(account);
    }

    /**
     * @dev Get a fixed-size array of whether or not each character in an account
     * will be capitalized in the checksum.
     * @param account address The account to get the checksum capitalization
     * information for.
     * @return A fixed-size array of booleans that signify if each character or
     * "nibble" of the hex encoding of the address will be capitalized by the
     * checksum.
     */
    function getChecksumCapitalizedCharacters(address account)
        internal
        pure
        returns (bool[40] memory)
    {
        // call internal function for computing characters capitalized in checksum.
        return _toChecksumCapsFlags(account);
    }

    /**
     * @dev Determine whether a string hex representation of an account address
     * matches the ERC-55 checksum of that address.
     * @param accountChecksum string The checksummed account string in ASCII
     * format. Note that a leading "0x" MUST NOT be included.
     * @return A boolean signifying whether or not the checksum is valid.
     */
    function isChecksumValid(string calldata accountChecksum)
        internal
        pure
        returns (bool)
    {
        // call internal function for validating checksum strings.
        return _isChecksumValid(accountChecksum);
    }

    function _toChecksumString(address account)
        internal
        pure
        returns (string memory asciiString)
    {
        // convert the account argument from address to bytes.
        bytes20 data = bytes20(account);

        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        bool leftCaps;
        bool rightCaps;
        uint8 asciiOffset;

        // get the capitalized characters in the actual checksum.
        bool[40] memory caps = _toChecksumCapsFlags(account);

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // locate and extract each capitalization status.
            leftCaps = caps[2 * i];
            rightCaps = caps[2 * i + 1];

            // get the offset from nibble value to ascii character for left nibble.
            asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);

            // get the offset from nibble value to ascii character for right nibble.
            asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
        }

        return string(abi.encodePacked("0x", string(asciiBytes)));
    }

    function _toChecksumCapsFlags(address account)
        internal
        pure
        returns (bool[40] memory characterCapitalized)
    {
        // convert the address to bytes.
        bytes20 a = bytes20(account);

        // hash the address (used to calculate checksum).
        bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

        // declare variable types.
        uint8 leftNibbleAddress;
        uint8 rightNibbleAddress;
        uint8 leftNibbleHash;
        uint8 rightNibbleHash;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i; i < a.length; i++) {
            // locate the byte and extract each nibble for the address and the hash.
            rightNibbleAddress = uint8(a[i]) % 16;
            leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
            rightNibbleHash = uint8(b[i]) % 16;
            leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

            characterCapitalized[2 * i] = (leftNibbleAddress > 9 &&
                leftNibbleHash > 7);
            characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 &&
                rightNibbleHash > 7);
        }
    }

    function _isChecksumValid(string memory provided)
        internal
        pure
        returns (bool ok)
    {
        // convert the provided string into account type.
        address account = _toAddress(provided);

        // return false in the event the account conversion returned null address.
        if (account == address(0)) {
            // ensure that provided address is not also the null address first.
            bytes memory b = bytes(provided);
            for (uint256 i; i < b.length; i++) {
                if (b[i] != hex"30") {
                    return false;
                }
            }
        }

        // get the capitalized characters in the actual checksum.
        string memory actual = _toChecksumString(account);

        // compare provided string to actual checksum string to test for validity.
        return (keccak256(abi.encodePacked(actual)) ==
            keccak256(abi.encodePacked(provided)));
    }

    function _getAsciiOffset(uint8 nibble, bool caps)
        internal
        pure
        returns (uint8 offset)
    {
        // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
        if (nibble < 10) {
            offset = 48;
        } else if (caps) {
            offset = 55;
        } else {
            offset = 87;
        }
    }

    function _toAddress(string memory account)
        internal
        pure
        returns (address accountAddress)
    {
        // convert the account argument from address to bytes.
        bytes memory accountBytes = bytes(account);

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        // only proceed if the provided string has a length of 40.
        if (accountBytes.length == 40) {
            for (uint256 i; i < 40; i++) {
                // get the byte in question.
                b = uint8(accountBytes[i]);

                // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
                if (b < 48) return address(0);
                if (57 < b && b < 65) return address(0);
                if (70 < b && b < 97) return address(0);
                if (102 < b) return address(0); //bytes(hex"");

                // find the offset from ascii encoding to the nibble representation.
                if (b < 65) {
                    // 0-9
                    asciiOffset = 48;
                } else if (70 < b) {
                    // a-f
                    asciiOffset = 87;
                } else {
                    // A-F
                    asciiOffset = 55;
                }

                // store left nibble on even iterations, then store byte on odd ones.
                if (i % 2 == 0) {
                    nibble = b - asciiOffset;
                } else {
                    accountAddressBytes[(i - 1) / 2] = (
                        bytes1(16 * nibble + (b - asciiOffset))
                    );
                }
            }

            // pack up the fixed-size byte array and cast it to accountAddress.
            bytes memory packed = abi.encodePacked(accountAddressBytes);
            assembly {
                accountAddress := mload(add(packed, 20))
            }
        }
    }

    // based on https://ethereum.stackexchange.com/a/56499/48410
    function _toAsciiString(bytes20 data)
        internal
        pure
        returns (string memory asciiString)
    {
        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
            asciiBytes[2 * i] = bytes1(
                leftNibble + (leftNibble < 10 ? 48 : 87)
            );
            asciiBytes[2 * i + 1] = bytes1(
                rightNibble + (rightNibble < 10 ? 48 : 87)
            );
        }

        return string(asciiBytes);
    }

    function parseAddress(
        string memory account,
        string memory revertMsg
    ) internal pure returns (address accountAddress)
    {
        bytes memory accountBytes = bytes(account);
        require(
            accountBytes.length == 42 &&
            accountBytes[0] == bytes1("0") &&
            accountBytes[1] == bytes1("x"),
            revertMsg
        );

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        for (uint256 i = 0; i < 40; i++) {
            // get the byte in question.
            b = uint8(accountBytes[i + 2]);

            bool isValidASCII = true;
            // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
            if (b < 48) isValidASCII = false;
            if (57 < b && b < 65) isValidASCII = false;
            if (70 < b && b < 97) isValidASCII = false;
            if (102 < b) isValidASCII = false; //bytes(hex"");

            // If string contains invalid ASCII characters, revert()
            if (!isValidASCII) revert(revertMsg);

            // find the offset from ascii encoding to the nibble representation.
            if (b < 65) {
                // 0-9
                asciiOffset = 48;
            } else if (70 < b) {
                // a-f
                asciiOffset = 87;
            } else {
                // A-F
                asciiOffset = 55;
            }

            // store left nibble on even iterations, then store byte on odd ones.
            if (i % 2 == 0) {
                nibble = b - asciiOffset;
            } else {
                accountAddressBytes[(i - 1) / 2] = (
                bytes1(16 * nibble + (b - asciiOffset))
                );
            }
        }

        // pack up the fixed-size byte array and cast it to accountAddress.
        bytes memory packed = abi.encodePacked(accountAddressBytes);
        assembly {
            accountAddress := mload(add(packed, 20))
        }

        // return false in the event the account conversion returned null address.
        if (accountAddress == address(0)) {
            // ensure that provided address is not also the null address first.
            for (uint256 i = 2; i < accountBytes.length; i++)
                require(accountBytes[i] == hex"30", revertMsg);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * Strings Library
 *
 * This is a simple library of string functions which try to simplify
 * string operations in solidity.
 *
 * Please be aware some of these functions can be quite gas heavy so use them only when necessary
 *
 * The original library was modified. If you want to know more about the original version
 * please check this link: https://github.com/willitscale/solidity-util.git
 */
library Strings {
    /**
     * splitBTPAddress
     *
     * Split the BTP Address format i.e. btp://1234.iconee/0x123456789
     * into Network_address (1234.iconee) and Server_address (0x123456789)
     *
     * @param _base String base BTP Address format to be split
     * @dev _base must follow a BTP Address format
     *
     * @return string, string   The resulting strings of Network_address and Server_address
     */
    function splitBTPAddress(string memory _base)
        internal
        pure
        returns (string memory, string memory)
    {
        string[] memory temp = split(_base, "/");
        return (temp[2], temp[3]);
    }

    function bytesToHex(bytes memory buffer) internal pure returns (string memory) {
        if (buffer.length == 0) {
            return string("0x");
        }
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) >> 4 & 0xf];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) & 0xf];
        }

        return string(abi.encodePacked("0x", converted));
    }

    /**
     * Concat
     *
     * Appends two strings together and returns a new value
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_base, _value));
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int256)
    {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    /**
     * Length
     *
     * Returns the length of the specified string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /*
     * String Split (Very high gas cost)
     *
     * Splits a string into an array of strings based off the delimiter value.
     * Please note this can be quite a gas expensive function due to the use of
     * storage so only use if really required.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * @param _value The delimiter to split the string on which must be a single
     *               character
     * @return string[] An array of values split based off the delimiter, but
     *                  do not container the delimiter.
     */
    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     *
     * Compares the characters of two strings, to ensure that they have an
     * identical footprint
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        if (
            keccak256(abi.encodePacked(_base)) ==
            keccak256(abi.encodePacked(_value))
        ) {
            return true;
        }
        return false;
    }

    /**
     * Lower
     *
     * Converts all the values of a string to their corresponding lower case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     *
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
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

/*
 *  Change supporting solidity compiler version
 *  The original code can be found via this link: https://github.com/hamdiallam/Solidity-RLP.git
 */

library RLPDecode {
    uint8 private constant STRING_SHORT_START = 0x80;
    uint8 private constant STRING_LONG_START = 0xb8;
    uint8 private constant LIST_SHORT_START = 0xc0;
    uint8 private constant LIST_LONG_START = 0xf8;
    uint8 private constant WORD_SIZE = 32;

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
        require(hasNext(self), "Must have next elements");

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
    function toRlpItem(bytes memory item)
        internal
        pure
        returns (RLPItem memory)
    {
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
    function iterator(RLPItem memory self)
        internal
        pure
        returns (Iterator memory)
    {
        require(isList(self), "Must be a list");

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
    function toList(RLPItem memory item)
        internal
        pure
        returns (RLPItem[] memory)
    {
        require(isList(item), "Must be a list");

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

    function isNull(RLPItem memory item) internal pure returns (bool) {
        if (item.len != 2) return false;

        uint8 byte0;
        uint8 itemLen;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
            memPtr := add(memPtr, 1)
            itemLen := byte(0, mload(memPtr))
        }
        if (byte0 != LIST_LONG_START || itemLen != 0) return false;
        return true;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Must have length 1");
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21, "Must have length 21");

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33, "Invalid uint number");

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    function toInt(RLPItem memory item) internal pure returns (int256) {
        require(item.len >= 0 && item.len < 33, "Invalid int number");

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        int256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)
            if lt(len, 32) {
                result := sar(mul(8, sub(32, len)), result)
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33, "Must have length 33");

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0, "Invalid length");

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
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;
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
        else if (
            byte0 < STRING_LONG_START ||
            (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
        ) return 1;
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

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256**(WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
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