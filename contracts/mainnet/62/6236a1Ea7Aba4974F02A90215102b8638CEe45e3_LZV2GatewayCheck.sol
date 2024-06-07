// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IActionDataStructures } from '../interfaces/IActionDataStructures.sol';
import { IGateway } from '../crosschain/interfaces/IGateway.sol';
import { IGatewayClient } from '../crosschain/interfaces/IGatewayClient.sol';
import { IVariableBalanceRecordsProvider } from '../interfaces/IVariableBalanceRecordsProvider.sol';
import { IVariableBalanceRecords } from '../interfaces/IVariableBalanceRecords.sol';
import { SystemVersionId } from '../SystemVersionId.sol';
import '../helpers/TransferHelper.sol' as TransferHelper;

contract LZV2GatewayCheck is
    SystemVersionId,
    IGatewayClient,
    IVariableBalanceRecordsProvider,
    IVariableBalanceRecords
{
    address public owner = msg.sender;
    IGateway public gateway;
    IVariableBalanceRecords public variableBalanceRecords = this;
    uint256 public loop = 0;

    event DataSent(uint256 targetChainId, uint256 actionId);
    event DataReceived(uint256 sourceChainId, uint256 actionId, uint256 sum);

    constructor(IGateway _gateway) {
        gateway = _gateway;
    }

    receive() external payable {}

    function checkSend(
        uint256 _targetChainId,
        IActionDataStructures.TargetMessage calldata _data,
        bytes calldata _settings
    ) external payable {
        bytes memory message = abi.encode(_data);

        uint256 sendValue = gateway.messageFee(_targetChainId, message, _settings);

        gateway.sendMessage{ value: sendValue }(_targetChainId, message, _settings);

        if (address(this).balance > 0) {
            TransferHelper.safeTransferNative(msg.sender, address(this).balance);
        }

        emit DataSent(_targetChainId, _data.actionId);
    }

    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external override(IGatewayClient) {
        // require(msg.sender == address(gateway), 'only gateway');

        uint256 sum;

        for (uint index; index < loop; index++) {
            unchecked {
                sum += index;
            }
        }

        IActionDataStructures.TargetMessage memory data = abi.decode(
            _payloadData,
            (IActionDataStructures.TargetMessage)
        );

        emit DataReceived(_messageSourceChainId, data.actionId, sum);
    }

    function setGateway(IGateway _gateway) external {
        require(msg.sender == owner, 'only owner');

        gateway = _gateway;
    }

    function setLoop(uint256 _loop) external {
        require(msg.sender == owner, 'only owner');

        loop = _loop;
    }

    function checkFee(
        uint256 _targetChainId,
        IActionDataStructures.TargetMessage calldata _data,
        bytes calldata _settings
    ) external view returns (uint256) {
        return gateway.messageFee(_targetChainId, abi.encode(_data), _settings);
    }

    // - - - variable balance records - - -

    function increaseBalance(
        address /*_account*/,
        uint256 /*_vaultType*/,
        uint256 /*_amount*/
    ) external {}

    function clearBalance(address /*_account*/, uint256 /*_vaultType*/) external {}

    function getAccountBalance(
        address /*_account*/,
        uint256 /*_vaultType*/
    ) external pure returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IGateway
 * @notice Cross-chain gateway interface
 */
interface IGateway {
    /**
     * @notice Send a cross-chain message
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable;

    /**
     * @notice Cross-chain message fee estimation
     * @param _targetChainId The ID of the target chain
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IGatewayClient
 * @notice Cross-chain gateway client interface
 */
interface IGatewayClient {
    /**
     * @notice Cross-chain message handler on the target chain
     * @dev The function is called by cross-chain gateways
     * @param _messageSourceChainId The ID of the message source chain
     * @param _payloadData The content of the cross-chain message
     */
    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external;

    /**
     * @notice The standard "receive" function
     */
    receive() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an approval action fails
 */
error SafeApproveError();

/**
 * @notice Emitted when a transfer action fails
 */
error SafeTransferError();

/**
 * @notice Emitted when a transferFrom action fails
 */
error SafeTransferFromError();

/**
 * @notice Emitted when a transfer of the native token fails
 */
error SafeTransferNativeError();

/**
 * @notice Safely approve the token to the account
 * @param _token The token address
 * @param _to The token approval recipient address
 * @param _value The token approval amount
 */
function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

/**
 * @notice Safely transfer the token to the account
 * @param _token The token address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

/**
 * @notice Safely transfer the token between the accounts
 * @param _token The token address
 * @param _from The token transfer source address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

/**
 * @notice Safely transfer the native token to the account
 * @param _to The native token transfer recipient address
 * @param _value The native token transfer amount
 */
function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IActionDataStructures
 * @notice Action data structure declarations
 */
interface IActionDataStructures {
    /**
     * @notice Single-chain action data structure
     * @param fromTokenAddress The address of the input token
     * @param toTokenAddress The address of the output token
     * @param swapInfo The data for the single-chain swap
     * @param recipient The address of the recipient
     */
    struct LocalAction {
        address fromTokenAddress;
        address toTokenAddress;
        SwapInfo swapInfo;
        address recipient;
    }

    /**
     * @notice Cross-chain action data structure
     * @param gatewayType The numeric type of the cross-chain gateway
     * @param vaultType The numeric type of the vault
     * @param sourceTokenAddress The address of the input token on the source chain
     * @param sourceSwapInfo The data for the source chain swap
     * @param targetChainId The action target chain ID
     * @param targetTokenAddress The address of the output token on the destination chain
     * @param targetSwapInfoOptions The list of data options for the target chain swap
     * @param targetRecipient The address of the recipient on the target chain
     * @param gatewaySettings The gateway-specific settings data
     */
    struct Action {
        uint256 gatewayType;
        uint256 vaultType;
        address sourceTokenAddress;
        SwapInfo sourceSwapInfo;
        uint256 targetChainId;
        address targetTokenAddress;
        SwapInfo[] targetSwapInfoOptions;
        address targetRecipient;
        bytes gatewaySettings;
    }

    /**
     * @notice Token swap data structure
     * @param fromAmount The quantity of the token
     * @param routerType The numeric type of the swap router
     * @param routerData The data for the swap router call
     */
    struct SwapInfo {
        uint256 fromAmount;
        uint256 routerType;
        bytes routerData;
    }

    /**
     * @notice Cross-chain message data structure
     * @param actionId The unique identifier of the cross-chain action
     * @param sourceSender The address of the sender on the source chain
     * @param vaultType The numeric type of the vault
     * @param targetTokenAddress The address of the output token on the target chain
     * @param targetSwapInfo The data for the target chain swap
     * @param targetRecipient The address of the recipient on the target chain
     */
    struct TargetMessage {
        uint256 actionId;
        address sourceSender;
        uint256 vaultType;
        address targetTokenAddress;
        SwapInfo targetSwapInfo;
        address targetRecipient;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IVariableBalanceRecords
 * @notice Variable balance records interface
 */
interface IVariableBalanceRecords {
    /**
     * @notice Increases the variable balance for the account
     * @param _account The account address
     * @param _vaultType The vault type
     * @param _amount The amount by which to increase the variable balance
     */
    function increaseBalance(address _account, uint256 _vaultType, uint256 _amount) external;

    /**
     * @notice Clears the variable balance for the account
     * @param _account The account address
     * @param _vaultType The vault type
     */
    function clearBalance(address _account, uint256 _vaultType) external;

    /**
     * @notice Getter of the variable balance by the account
     * @param _account The account address
     * @param _vaultType The vault type
     */
    function getAccountBalance(
        address _account,
        uint256 _vaultType
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IVariableBalanceRecords } from './IVariableBalanceRecords.sol';

/**
 * @title IVariableBalanceRecordsProvider
 * @notice The variable balance records provider interface
 */
interface IVariableBalanceRecordsProvider {
    /**
     * @notice Getter of the variable balance records contract reference
     * @return The variable balance records contract reference
     */
    function variableBalanceRecords() external returns (IVariableBalanceRecords);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title SystemVersionId
 * @notice Base contract providing the system version identifier
 */
abstract contract SystemVersionId {
    /**
     * @dev The system version identifier
     */
    uint256 public constant SYSTEM_VERSION_ID =
        uint256(keccak256('LZV2GatewayCheck-2024-06-07-Test')); // TODO
}