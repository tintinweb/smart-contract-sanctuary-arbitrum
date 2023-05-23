/**
 *Submitted for verification at Arbiscan on 2023-05-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

enum MessageStatus {
    NOT_EXECUTED,
    EXECUTION_FAILED,
    EXECUTION_SUCCEEDED
}

struct Message {
    uint8 version;
    uint64 nonce;
    uint32 sourceChainId;
    address senderAddress;
    uint32 recipientChainId;
    bytes32 recipientAddress;
    bytes data;
}

interface ITelepathyRouter {
    event SentMessage(uint64 indexed nonce, bytes32 indexed msgHash, bytes message);

    function send(uint32 recipientChainId, bytes32 recipientAddress, bytes calldata data)
        external
        returns (bytes32);

    function send(uint32 recipientChainId, address recipientAddress, bytes calldata data)
        external
        returns (bytes32);

    function sendViaStorage(uint32 recipientChainId, bytes32 recipientAddress, bytes calldata data)
        external
        returns (bytes32);

    function sendViaStorage(uint32 recipientChainId, address recipientAddress, bytes calldata data)
        external
        returns (bytes32);
}

interface ITelepathyReceiver {
    event ExecutedMessage(
        uint32 indexed sourceChainId,
        uint64 indexed nonce,
        bytes32 indexed msgHash,
        bytes message,
        bool status
    );

    function executeMessage(
        uint64 slot,
        bytes calldata message,
        bytes[] calldata accountProof,
        bytes[] calldata storageProof
    ) external;

    function executeMessageFromLog(
        bytes calldata srcSlotTxSlotPack,
        bytes calldata messageBytes,
        bytes32[] calldata receiptsRootProof,
        bytes32 receiptsRoot,
        bytes[] calldata receiptProof, // receipt proof against receipt root
        bytes memory txIndexRLPEncoded,
        uint256 logIndex
    ) external;
}

interface ITelepathyHandler {
    function handleTelepathy(uint32 _sourceChainId, address _senderAddress, bytes memory _data)
        external
        returns (bytes4);
}

abstract contract TelepathyHandler is ITelepathyHandler {
    error NotFromTelepathyReceiever(address sender);

    address private _telepathyReceiever;

    constructor(address telepathyReceiever) {
        _telepathyReceiever = telepathyReceiever;
    }

    function handleTelepathy(uint32 _sourceChainId, address _senderAddress, bytes memory _data)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != _telepathyReceiever) {
            revert NotFromTelepathyReceiever(msg.sender);
        }
        handleTelepathyImpl(_sourceChainId, _senderAddress, _data);
        return ITelepathyHandler.handleTelepathy.selector;
    }

    function handleTelepathyImpl(uint32 _sourceChainId, address _senderAddress, bytes memory _data)
        internal
        virtual;
}

contract TargetCounter is TelepathyHandler {
    uint256 public counter = 0;
    
    event Incremented(address incrementer, uint256 value, uint32 sourceChainId, bytes msgData);

    constructor(address _router) TelepathyHandler(_router) {}

    // Handle messages being sent and decoding
    function handleTelepathyImpl(
        uint32 _sourceChainId, address _sourceAddress, bytes memory _msgData
    ) internal override {
        (uint256 amount) = abi.decode(_msgData, (uint256));
        counter += amount;
        emit Incremented(_sourceAddress, counter, _sourceChainId, _msgData);
    }
}