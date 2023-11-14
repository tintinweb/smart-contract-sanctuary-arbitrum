/**
 *Submitted for verification at Arbiscan.io on 2023-11-09
*/

/**
 *Submitted for verification at Etherscan.io on 2023-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title LnAccessController
/// @notice LnAccessController is a contract to control the access permission 
/// @dev See https://github.com/helix-bridge/contracts/tree/master/helix-contract
contract LnAccessController {
    address public dao;
    address public operator;

    mapping(address=>bool) public callerWhiteList;

    modifier onlyDao() {
        require(msg.sender == dao, "!dao");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!operator");
        _;
    }

    modifier onlyWhiteListCaller() {
        require(callerWhiteList[msg.sender], "caller not in white list");
        _;
    }

    function _initialize(address _dao) internal {
        dao = _dao;
        operator = _dao;
    }

    function setOperator(address _operator) onlyDao external {
        operator = _operator;
    }

    function authoriseAppCaller(address appAddress, bool enable) onlyOperator external {
        callerWhiteList[appAddress] = enable;
    }

    function transferOwnership(address _dao) onlyDao external {
        dao = _dao;
    }
}

interface ILowLevelMessageSender {
    function registerRemoteReceiver(uint256 remoteChainId, address remoteBridge) external;
    function sendMessage(uint256 remoteChainId, bytes memory message, bytes memory params) external payable;
}

interface ILowLevelMessageReceiver {
    function registerRemoteSender(uint256 remoteChainId, address remoteBridge) external;
    function recvMessage(address remoteSender, address localReceiver, bytes memory payload) external;
}

interface ILayerZeroEndpoint {
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint nativeFee, uint zroFee);
}

contract LayerZeroMessager is LnAccessController {
    ILayerZeroEndpoint public endpoint;

    struct RemoteMessager {
        uint16 lzRemoteChainId;
        address messager;
    }

    // app remoteChainId => layerzero remote messager
    mapping(uint256=>RemoteMessager) public remoteMessagers;
    // lz remoteChainId => trustedRemotes
    mapping(uint16=>bytes32) public trustedRemotes;

    // token bridge pair
    // hash(lzRemoteChainId, localAppAddress) => remoteAppAddress
    mapping(bytes32=>address) public remoteAppReceivers;
    mapping(bytes32=>address) public remoteAppSenders;

    event CallResult(uint16 lzRemoteChainId, bytes srcAddress, bool successed);
    event CallerUnMatched(uint16 lzRemoteChainId, bytes srcAddress, address remoteAppAddress);

    constructor(address _dao, address _endpoint) {
        _initialize(_dao);
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    modifier onlyRemoteBridge(uint16 lzRemoteChainId, bytes calldata srcAddress) {
        require(msg.sender == address(endpoint), "invalid caller");
        require(trustedRemotes[lzRemoteChainId] == keccak256(srcAddress), "invalid remote caller");
        _;
    }

    function setRemoteMessager(uint256 _appRemoteChainId, uint16 _lzRemoteChainId, address _remoteMessager) onlyOperator external {
        remoteMessagers[_appRemoteChainId] = RemoteMessager(_lzRemoteChainId, _remoteMessager);
        trustedRemotes[_lzRemoteChainId] = keccak256(abi.encodePacked(_remoteMessager, address(this)));
    }

    function registerRemoteReceiver(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.lzRemoteChainId, msg.sender));
        remoteAppReceivers[key] = _remoteBridge;
    }

    function registerRemoteSender(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.lzRemoteChainId, msg.sender));
        remoteAppSenders[key] = _remoteBridge;
    }

    function sendMessage(uint256 _remoteChainId, bytes memory _message, bytes memory _params) onlyWhiteListCaller external  payable {
        address refunder = address(bytes20(_params));
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes memory destination = abi.encodePacked(
            remoteMessager.messager,
            address(this)
        );
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.lzRemoteChainId, msg.sender));
        address remoteAppAddress = remoteAppReceivers[key];
        require(remoteAppAddress != address(0), "app pair not registered");
        bytes memory lzPayload = abi.encode(msg.sender, remoteAppAddress, _message);
        endpoint.send{ value: msg.value }(
            remoteMessager.lzRemoteChainId,
            destination,
            lzPayload,
            payable(refunder),
            // zro payment, future parameter
            address(0x0),
            bytes("")
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64, //nonce unused
        bytes calldata _payload) onlyRemoteBridge(_srcChainId, _srcAddress) external {
        // call
        (address remoteAppAddress, address localAppAddress, bytes memory message) = abi.decode(_payload, (address, address, bytes));
        bytes32 key = keccak256(abi.encodePacked(_srcChainId, localAppAddress));
        if (remoteAppAddress != remoteAppSenders[key]) {
            emit CallerUnMatched(_srcChainId, _srcAddress, remoteAppAddress);
            return;
        }
        (bool success,) = localAppAddress.call(message);
        // don't revert to prevent message block
        emit CallResult(_srcChainId, _srcAddress, success);
    }

    function fee(
        uint256 _remoteChainId,
        bytes memory _message
    ) external view returns(uint256 nativeFee, uint256 zroFee) {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "messager not configured");
        return endpoint.estimateFees(
            remoteMessager.lzRemoteChainId,
            remoteMessager.messager,
            _message,
            false,
            bytes("")
        );
    }
}