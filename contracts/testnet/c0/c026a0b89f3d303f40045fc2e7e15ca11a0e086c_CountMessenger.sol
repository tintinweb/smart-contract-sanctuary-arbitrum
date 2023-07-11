// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ITelepathyRouterV2} from "src/amb-v2/interfaces/ITelepathy.sol";
import {TelepathyHandlerV2} from "src/amb-v2/interfaces/TelepathyHandler.sol";

/// @notice Example Counter that uses messaging to make a cross-chain increment call.
/// @dev Assumes that this contract is deployed at the same address on all chains.
contract CountMessenger is TelepathyHandlerV2 {
    uint256 public count;

    event Incremented(uint32 srcChainId, address sender);

    error NotFromCountMessenger(address sender);

    constructor(address _telepathyRouter) TelepathyHandlerV2(_telepathyRouter) {}

    /// @notice Sends a cross-chain increment message.
    function sendIncrement(uint32 _dstChainId) external {
        ITelepathyRouterV2(telepathyRouter).send(_dstChainId, address(this), "");
    }

    /// @notice Recieve a cross-chain increment message.
    function handleTelepathyImpl(uint32 _srcChainId, address _srcAddress, bytes memory)
        internal
        override
    {
        if (_srcAddress != address(this)) {
            revert NotFromCountMessenger(_srcAddress);
        }

        count++;

        emit Incremented(_srcChainId, _srcAddress);
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

import {ITelepathyHandlerV2} from "src/amb-v2/interfaces/ITelepathy.sol";

abstract contract TelepathyHandlerV2 is ITelepathyHandlerV2 {
    error NotFromTelepathyRouterV2(address sender);

    address public telepathyRouter;

    constructor(address _telepathyRouter) {
        telepathyRouter = _telepathyRouter;
    }

    function handleTelepathy(uint32 _sourceChainId, address _sourceAddress, bytes memory _data)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != telepathyRouter) {
            revert NotFromTelepathyRouterV2(msg.sender);
        }
        handleTelepathyImpl(_sourceChainId, _sourceAddress, _data);
        return ITelepathyHandlerV2.handleTelepathy.selector;
    }

    function handleTelepathyImpl(uint32 _sourceChainId, address _sourceAddress, bytes memory _data)
        internal
        virtual;
}