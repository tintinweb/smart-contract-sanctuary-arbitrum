// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IZKBridgeEntrypoint.sol";
import "./interfaces/IZKBridgeReceiver.sol";

/// @title Mailbox
/// @notice An example contract for receiving messages from other chains
contract Mailbox is IZKBridgeReceiver {

    event MessageReceived(uint64 indexed sequence, uint32 indexed sourceChainId, address indexed sourceAddress, address sender, address recipient, string message);

    struct Msg {
        address sender;
        string message;
    }

    address private zkBridgeReceiver;

    // recipient=>Msg
    mapping(address => Msg[]) public messages;

    constructor(address _zkBridgeReceiver) {
        zkBridgeReceiver = _zkBridgeReceiver;
    }

    // @notice ZKBridge endpoint will invoke this function to deliver the message on the destination
    // @param srcChainId - the source endpoint identifier
    // @param srcAddress - the source sending contract address from the source chain
    // @param sequence - the ordered message nonce
    // @param message - the signed payload is the UA bytes has encoded to be sent
    function zkReceive(uint16 srcChainId, address srcAddress, uint64 sequence, bytes calldata payload) external override {
        require(msg.sender == zkBridgeReceiver, "Not From ZKBridgeReceiver");
        (address sender,address recipient,string memory message) = abi.decode(payload, (address, address, string));
        messages[recipient].push(Msg(sender, message));
        emit MessageReceived(sequence, srcChainId, srcAddress, sender, recipient, message);
    }

    function messagesLength(address recipient) external view returns (uint256) {
        return messages[recipient].length;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeEntrypoint {

    // @notice send a ZKBridge message to the specified address at a ZKBridge endpoint.
    // @param dstChainId - the destination chain identifier
    // @param dstAddress - the address on destination chain
    // @param payload - a custom bytes payload to send to the destination contract
    function send(uint16 dstChainId, address dstAddress, bytes memory payload) external payable returns (uint64 sequence);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeReceiver {
    // @notice ZKBridge endpoint will invoke this function to deliver the message on the destination
    // @param srcChainId - the source endpoint identifier
    // @param srcAddress - the source sending contract address from the source chain
    // @param sequence - the ordered message nonce
    // @param payload - the signed payload is the UA bytes has encoded to be sent
    function zkReceive(uint16 srcChainId, address srcAddress, uint64 sequence, bytes calldata payload) external;
}