// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Client {
    struct EVMTokenAmount {
        address token; // token address on the local chain
        uint256 amount;
    }

    struct Any2EVMMessage {
        bytes32 messageId; // MessageId corresponding to ccipSend on source
        uint64 sourceChainSelector;
        bytes sender; // abi.decode(sender) if coming from an EVM chain
        bytes data; // payload sent in original message, max. length is 50k
        EVMTokenAmount[] tokenAmounts;
    }

    // If extraArgs is empty bytes, the default is
    // 200k gas limit and strict = false.
    struct EVM2AnyMessage {
        bytes receiver; // abi.encode(receiver address) for dest EVM chains
        bytes data; // Data payload, max. length is 50k
        EVMTokenAmount[] tokenAmounts; // Token transfers
        address feeToken; // Address of feeToken. address(0) means you will send msg.value.
        bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
    }

    // extraArgs will evolve to support new features
    // bytes4(keccak256("CCIP EVMExtraArgsV1"));
    bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
    struct EVMExtraArgsV1 {
        uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR BETA TESTING
        bool strict; // See strict sequencing details below.
    }

    function _argsToBytes(
        EVMExtraArgsV1 memory extraArgs
    ) internal pure returns (bytes memory bts) {
        return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Client} from "./Client.sol";

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
    /// @notice Router calls this to deliver a message.
    /// If this reverts, any token transfers also revert. The message
    /// will move to a FAILED state and become available for manual execution
    /// as a retry. Fees already paid are NOT currently refunded (may change).
    /// @param message CCIP Message
    /// @dev Note ensure you check the msg.sender is the router
    function ccipReceive(Client.Any2EVMMessage calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Client library above
import {Client} from "./Client.sol";

interface IRouterClient {
    error UnsupportedDestinationChain(uint64 destinationChainSelector);
    /// @dev Sender is not whitelisted
    error SenderNotAllowed(address sender);
    error InsufficientFeeTokenAmount();
    /// @dev Sent msg.value with a non-empty feeToken
    error InvalidMsgValue();

    /// @notice Checks if the given chain selector is supported for sending/receiving.
    /// @param chainSelector The chain to check
    /// @return supported is true if it is supported, false if not
    function isChainSupported(
        uint64 chainSelector
    ) external view returns (bool supported);

    /// @notice Gets a list of all supported tokens which can be sent or received
    /// to/from a given chain selector.
    /// @param chainSelector The chainSelector.
    /// @return tokens The addresses of all tokens that are supported.
    function getSupportedTokens(
        uint64 chainSelector
    ) external view returns (address[] memory tokens);

    /// @param destinationChainSelector The destination chain selector
    /// @param message The cross-chain CCIP message including data and/or tokens
    /// @return fee returns execution fee for the specified message
    /// delivery to destination chain
    /// @dev returns 0 fee on invalid message.
    function getFee(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage memory message
    ) external view returns (uint256 fee);

    /// @notice Request a message to be sent to the destination chain
    /// @param destinationChainSelector The destination chain selector
    /// @param message The cross-chain CCIP message including data and/or tokens
    /// @return messageId The message ID
    /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
    /// the overpayment with no refund.
    function ccipSend(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage calldata message
    ) external payable returns (bytes32 messageId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Client} from "./Client.sol";
import {IRouterClient} from "./IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "./IAny2EVMMessageReceiver.sol";

contract MyContract is IAny2EVMMessageReceiver {
    // Import thư viện Client
    using Client for Client.EVM2AnyMessage;
    event Message(bytes32 messageId);
    event MessageCallData(Client.Any2EVMMessage message);

    IRouterClient router; // Contract address of the router
    uint64 destinationChainSelector = 12532609583862916517;

    function setDestinationChainSelector(
        uint64 _destinationChainSelector
    ) public {
        destinationChainSelector = _destinationChainSelector;
    }

    function setRoute(address _router) public {
        router = IRouterClient(_router);
    }

    // Hàm để chuyển token từ chuỗi nguồn sang chuỗi đích
    function transferToken(
        address receiver, // Địa chỉ người nhận trên chuỗi đích
        address token, // Địa chỉ của token trên chuỗi nguồn
        uint256 amount // Số lượng token cần chuyển
    ) public {
        // Tạo một đối tượng EVM2AnyMessage
        Client.EVM2AnyMessage memory message;

        // Thiết lập đối tượng message với thông tin cần thiết
        message.receiver = abi.encode(receiver);
        message.tokenAmounts = new Client.EVMTokenAmount[](1);
        message.tokenAmounts[0] = Client.EVMTokenAmount(token, amount);
        // Gửi thông điệp để chuyển token
        bytes32 messageId = router.ccipSend(destinationChainSelector, message);
        // Xử lý messageId và tiếp tục thực hiện các hành động khác
        emit Message(messageId);
    }

    // Implement IAny2EVMMessageReceiver interface
    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external override {
        // Xử lý thông điệp nhận được trên chuỗi đích
        // Tiến hành xử lý các token nhận được và thực hiện các hành động khác
        emit MessageCallData(message);
    }

    // Implement IAny2EVMMessageReceiver interface
    function getSupportedTokens(uint64 chainSelector) public view {
        // Xử lý thông điệp nhận được trên chuỗi đích
        // Tiến hành xử lý các token nhận được và thực hiện các hành động khác
        router.getSupportedTokens(chainSelector);
    }
}