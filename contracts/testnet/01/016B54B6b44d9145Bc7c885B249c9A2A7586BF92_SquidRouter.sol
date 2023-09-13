// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IUpgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IUpgradable.sol';

/**
 * @title IAxelarGasService Interface
 * @notice This is an interface for the AxelarGasService contract which manages gas payments
 * and refunds for cross-chain communication on the Axelar network.
 * @dev This interface inherits IUpgradable
 */
interface IAxelarGasService is IUpgradable {
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(bytes32 indexed txHash, uint256 indexed logIndex, address gasToken, uint256 gasFeeAmount, address refundAddress);

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event ExpressGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, address gasToken, uint256 gasFeeAmount, address refundAddress);

    event NativeExpressGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event Refunded(bytes32 indexed txHash, uint256 indexed logIndex, address payable receiver, address token, uint256 amount);

    /**
     * @notice Pay for gas using ERC20 tokens for a contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Pay for gas using ERC20 tokens for a contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Pay for gas using native currency for a contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    /**
     * @notice Pay for gas using native currency for a contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    /**
     * @notice Pay for gas using ERC20 tokens for an express contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to express execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForExpressCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Pay for gas using ERC20 tokens for an express contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to express execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Pay for gas using native currency for an express contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForExpressCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    /**
     * @notice Pay for gas using native currency for an express contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    /**
     * @notice Add additional gas payment using ERC20 tokens after initiating a cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param gasToken The ERC20 token address used to add gas
     * @param gasFeeAmount The amount of tokens to add as gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addGas(
        bytes32 txHash,
        uint256 logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Add additional gas payment using native currency after initiating a cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    /**
     * @notice Add additional gas payment using ERC20 tokens after initiating an express cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to express execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param gasToken The ERC20 token address used to add gas
     * @param gasFeeAmount The amount of tokens to add as gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Add additional gas payment using native currency after initiating an express cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to express execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    /**
     * @notice Allows the gasCollector to collect accumulated fees from the contract.
     * @dev Use address(0) as the token address for native currency.
     * @param receiver The address to receive the collected fees
     * @param tokens Array of token addresses to be collected
     * @param amounts Array of amounts to be collected for each respective token address
     */
    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Refunds gas payment to the receiver in relation to a specific cross-chain transaction.
     * @dev Only callable by the gasCollector.
     * @dev Use address(0) as the token address to refund native currency.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param receiver The address to receive the refund
     * @param token The token address to be refunded
     * @param amount The amount to refund
     */
    function refund(
        bytes32 txHash,
        uint256 logIndex,
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    /**
     * @notice Returns the address of the designated gas collector.
     * @return address of the gas collector
     */
    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(address indexed sender, string destinationChain, string destinationAddress, string symbol, uint256 amount);

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { ExpressExecutorTracker } from './ExpressExecutorTracker.sol';

import { SafeTokenTransferFrom, SafeTokenTransfer } from '../libs/SafeTransfer.sol';
import { IERC20 } from '../interfaces/IERC20.sol';

contract AxelarExpressExecutable is ExpressExecutorTracker {
    using SafeTokenTransfer for IERC20;
    using SafeTokenTransferFrom for IERC20;

    IAxelarGateway public immutable gateway;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();

        address expressExecutor = _popExpressExecutor(commandId, sourceChain, sourceAddress, payloadHash);

        if (expressExecutor != address(0)) {
            // slither-disable-next-line reentrancy-events
            emit ExpressExecutionFulfilled(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);
        } else {
            _execute(sourceChain, sourceAddress, payload);
        }
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        address expressExecutor = _popExpressExecutorWithToken(
            commandId,
            sourceChain,
            sourceAddress,
            payloadHash,
            tokenSymbol,
            amount
        );

        if (expressExecutor != address(0)) {
            // slither-disable-next-line reentrancy-events
            emit ExpressExecutionWithTokenFulfilled(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount,
                expressExecutor
            );

            address gatewayToken = gateway.tokenAddresses(tokenSymbol);
            IERC20(gatewayToken).safeTransfer(expressExecutor, amount);
        } else {
            _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
        }
    }

    function expressExecute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external payable virtual {
        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted();

        address expressExecutor = msg.sender;
        bytes32 payloadHash = keccak256(payload);

        emit ExpressExecuted(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);

        _setExpressExecutor(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);

        _execute(sourceChain, sourceAddress, payload);
    }

    function expressExecuteWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external payable virtual {
        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted();

        address expressExecutor = msg.sender;
        address gatewayToken = gateway.tokenAddresses(symbol);
        bytes32 payloadHash = keccak256(payload);

        emit ExpressExecutedWithToken(
            commandId,
            sourceChain,
            sourceAddress,
            payloadHash,
            symbol,
            amount,
            expressExecutor
        );

        _setExpressExecutorWithToken(
            commandId,
            sourceChain,
            sourceAddress,
            payloadHash,
            symbol,
            amount,
            expressExecutor
        );

        IERC20(gatewayToken).safeTransferFrom(expressExecutor, address(this), amount);

        _executeWithToken(sourceChain, sourceAddress, payload, symbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarExpressExecutable } from '../interfaces/IAxelarExpressExecutable.sol';

abstract contract ExpressExecutorTracker is IAxelarExpressExecutable {
    bytes32 internal constant PREFIX_EXPRESS_EXECUTE = keccak256('express-execute');
    bytes32 internal constant PREFIX_EXPRESS_EXECUTE_WITH_TOKEN = keccak256('express-execute-with-token');

    function _expressExecuteSlot(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) internal pure returns (bytes32 slot) {
        slot = keccak256(abi.encode(PREFIX_EXPRESS_EXECUTE, commandId, sourceChain, sourceAddress, payloadHash));
    }

    function _expressExecuteWithTokenSlot(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) internal pure returns (bytes32 slot) {
        slot = keccak256(
            abi.encode(
                PREFIX_EXPRESS_EXECUTE_WITH_TOKEN,
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                symbol,
                amount
            )
        );
    }

    function getExpressExecutor(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external view returns (address expressExecutor) {
        bytes32 slot = _expressExecuteSlot(commandId, sourceChain, sourceAddress, payloadHash);

        assembly {
            expressExecutor := sload(slot)
        }
    }

    function getExpressExecutorWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (address expressExecutor) {
        bytes32 slot = _expressExecuteWithTokenSlot(commandId, sourceChain, sourceAddress, payloadHash, symbol, amount);

        assembly {
            expressExecutor := sload(slot)
        }
    }

    function _setExpressExecutor(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        address expressExecutor
    ) internal {
        bytes32 slot = _expressExecuteSlot(commandId, sourceChain, sourceAddress, payloadHash);
        address currentExecutor;

        assembly {
            currentExecutor := sload(slot)
        }

        if (currentExecutor != address(0)) revert ExpressExecutorAlreadySet();

        assembly {
            sstore(slot, expressExecutor)
        }
    }

    function _setExpressExecutorWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount,
        address expressExecutor
    ) internal {
        bytes32 slot = _expressExecuteWithTokenSlot(commandId, sourceChain, sourceAddress, payloadHash, symbol, amount);
        address currentExecutor;

        assembly {
            currentExecutor := sload(slot)
        }

        if (currentExecutor != address(0)) revert ExpressExecutorAlreadySet();

        assembly {
            sstore(slot, expressExecutor)
        }
    }

    function _popExpressExecutor(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) internal returns (address expressExecutor) {
        bytes32 slot = _expressExecuteSlot(commandId, sourceChain, sourceAddress, payloadHash);

        assembly {
            expressExecutor := sload(slot)
            if expressExecutor {
                sstore(slot, 0)
            }
        }
    }

    function _popExpressExecutorWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) internal returns (address expressExecutor) {
        bytes32 slot = _expressExecuteWithTokenSlot(commandId, sourceChain, sourceAddress, payloadHash, symbol, amount);

        assembly {
            expressExecutor := sload(slot)
            if expressExecutor {
                sstore(slot, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarExecutable } from './IAxelarExecutable.sol';

/**
 * @title IAxelarExpressExecutable
 * @notice Interface for the Axelar Express Executable contract.
 */
interface IAxelarExpressExecutable is IAxelarExecutable {
    // Custom errors
    error AlreadyExecuted();
    error InsufficientValue();
    error ExpressExecutorAlreadySet();

    /**
     * @notice Emitted when an express execution is successfully performed.
     * @param commandId The unique identifier for the command.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address.
     * @param payloadHash The hash of the payload.
     * @param expressExecutor The address of the express executor.
     */
    event ExpressExecuted(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        bytes32 payloadHash,
        address indexed expressExecutor
    );

    /**
     * @notice Emitted when an express execution with a token is successfully performed.
     * @param commandId The unique identifier for the command.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address.
     * @param payloadHash The hash of the payload.
     * @param symbol The token symbol.
     * @param amount The amount of tokens.
     * @param expressExecutor The address of the express executor.
     */
    event ExpressExecutedWithToken(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        bytes32 payloadHash,
        string symbol,
        uint256 indexed amount,
        address indexed expressExecutor
    );

    /**
     * @notice Emitted when an express execution is fulfilled.
     * @param commandId The commandId for the contractCall.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address.
     * @param payloadHash The hash of the payload.
     * @param expressExecutor The address of the express executor.
     */
    event ExpressExecutionFulfilled(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        bytes32 payloadHash,
        address indexed expressExecutor
    );

    /**
     * @notice Emitted when an express execution with a token is fulfilled.
     * @param commandId The commandId for the contractCallWithToken.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address.
     * @param payloadHash The hash of the payload.
     * @param symbol The token symbol.
     * @param amount The amount of tokens.
     * @param expressExecutor The address of the express executor.
     */
    event ExpressExecutionWithTokenFulfilled(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        bytes32 payloadHash,
        string symbol,
        uint256 indexed amount,
        address indexed expressExecutor
    );

    /**
     * @notice Returns the express executor for a given command.
     * @param commandId The commandId for the contractCall.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address.
     * @param payloadHash The hash of the payload.
     * @return expressExecutor The address of the express executor.
     */
    function getExpressExecutor(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external view returns (address expressExecutor);

    /**
     * @notice Returns the express executor with token for a given command.
     * @param commandId The commandId for the contractCallWithToken.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address.
     * @param payloadHash The hash of the payload.
     * @param symbol The token symbol.
     * @param amount The amount of tokens.
     * @return expressExecutor The address of the express executor.
     */
    function getExpressExecutorWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (address expressExecutor);

    /**
     * @notice Express executes a contract call.
     * @param commandId The commandId for the contractCall.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address.
     * @param payload The payload data.
     */
    function expressExecute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external payable;

    /**
     * @notice Express executes a contract call with token.
     * @param commandId The commandId for the contractCallWithToken.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address.
     * @param payload The payload data.
     * @param symbol The token symbol.
     * @param amount The amount of token.
     */
    function expressExecuteWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IGovernable } from './IGovernable.sol';

interface IAxelarGateway is IGovernable {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IContractIdentifier {
    /**
     * @notice Returns the contract ID. It can be used as a check during upgrades.
     * @dev Meant to be overridden in derived contracts.
     * @return bytes32 The contract ID
     */
    function contractId() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IGovernable Interface
 * @notice This is an interface used by the AxelarGateway contract to manage governance and mint limiter roles.
 */
interface IGovernable {
    error NotGovernance();
    error NotMintLimiter();
    error InvalidGovernance();
    error InvalidMintLimiter();

    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event MintLimiterTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @notice Returns the governance address.
     * @return address of the governance
     */
    function governance() external view returns (address);

    /**
     * @notice Returns the mint limiter address.
     * @return address of the mint limiter
     */
    function mintLimiter() external view returns (address);

    /**
     * @notice Transfer the governance role to another address.
     * @param newGovernance The new governance address
     */
    function transferGovernance(address newGovernance) external;

    /**
     * @notice Transfer the mint limiter role to another address.
     * @param newGovernance The new mint limiter address
     */
    function transferMintLimiter(address newGovernance) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from './IProxy.sol';

// General interface for upgradable contracts
interface IInitProxy is IProxy {
    function init(
        address implementationAddress,
        address newOwner,
        bytes memory params
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IOwnable Interface
 * @notice IOwnable is an interface that abstracts the implementation of a
 * contract with ownership control features. It's commonly used in upgradable
 * contracts and includes the functionality to get current owner, transfer
 * ownership, and propose and accept ownership.
 */
interface IOwnable {
    error NotOwner();
    error InvalidOwner();
    error InvalidOwnerAddress();

    event OwnershipTransferStarted(address indexed newOwner);
    event OwnershipTransferred(address indexed newOwner);

    /**
     * @notice Returns the current owner of the contract.
     * @return address The address of the current owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the pending owner of the contract.
     * @return address The address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice Transfers ownership of the contract to a new address
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Proposes to transfer the contract's ownership to a new address.
     * The new owner needs to accept the ownership explicitly.
     * @param newOwner The address to transfer ownership to
     */
    function proposeOwnership(address newOwner) external;

    /**
     * @notice Transfers ownership to the pending owner.
     * @dev Can only be called by the pending owner
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IProxy {
    error InvalidOwner();
    error InvalidImplementation();
    error SetupFailed();
    error NotOwner();
    error AlreadyInitialized();

    function implementation() external view returns (address);

    function setup(bytes calldata setupParams) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';
import { IContractIdentifier } from './IContractIdentifier.sol';

// General interface for upgradable contracts
interface IUpgradable is IOwnable, IContractIdentifier {
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../interfaces/IERC20.sol';

error TokenTransferFailed();

/*
 * @title SafeTokenCall
 * @dev This library is used for performing safe token transfers.
 */
library SafeTokenCall {
    /*
     * @notice Make a safe call to a token contract.
     * @param token The token contract to interact with.
     * @param callData The function call data.
     * @throws TokenTransferFailed error if transfer of token is not successful.
     */
    function safeCall(IERC20 token, bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(token).call(callData);
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || address(token).code.length == 0) revert TokenTransferFailed();
    }
}

/*
 * @title SafeTokenTransfer
 * @dev This library safely transfers tokens from the contract to a recipient.
 */
library SafeTokenTransfer {
    /*
     * @notice Transfer tokens to a recipient.
     * @param token The token contract.
     * @param receiver The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     */
    function safeTransfer(
        IERC20 token,
        address receiver,
        uint256 amount
    ) internal {
        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20.transfer.selector, receiver, amount));
    }
}

/*
 * @title SafeTokenTransferFrom
 * @dev This library helps to safely transfer tokens on behalf of a token holder.
 */
library SafeTokenTransferFrom {
    /*
     * @notice Transfer tokens on behalf of a token holder.
     * @param token The token contract.
     * @param from The address of the token holder.
     * @param to The address the tokens are to be sent to.
     * @param amount The amount of tokens to be transferred.
     */
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../interfaces/IProxy.sol';

/**
 * @title BaseProxy Contract
 * @dev This abstract contract implements a basic proxy that stores an implementation address. Fallback function
 * calls are delegated to the implementation. This contract is meant to be inherited by other proxy contracts.
 */
abstract contract BaseProxy is IProxy {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;

    /**
     * @dev Returns the current implementation address.
     * @return implementation_ The address of the current implementation contract
     */
    function implementation() public view virtual returns (address implementation_) {
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @dev Shadows the setup function of the implementation contract so it can't be called directly via the proxy.
     * @param params The setup parameters for the implementation contract.
     */
    function setup(bytes calldata params) external {}

    /**
     * @dev Returns the contract ID. It can be used as a check during upgrades. Meant to be implemented in derived contracts.
     * @return bytes32 The contract ID
     */
    function contractId() internal pure virtual returns (bytes32);

    /**
     * @dev Fallback function. Delegates the call to the current implementation contract.
     */
    fallback() external payable virtual {
        address implementation_ = implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Payable fallback function. Can be overridden in derived contracts.
     */
    receive() external payable virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInitProxy } from '../interfaces/IInitProxy.sol';
import { IContractIdentifier } from '../interfaces/IContractIdentifier.sol';
import { BaseProxy } from './BaseProxy.sol';

/**
 * @title InitProxy Contract
 * @notice A proxy contract that can be initialized to use a specified implementation and owner. Inherits from BaseProxy
 * and implements the IInitProxy interface.
 * @dev This proxy is constructed empty and then later initialized with the implementation contract address, new owner address,
 * and any optional setup parameters.
 */
contract InitProxy is BaseProxy, IInitProxy {
    /**
     * @dev Initializes the contract and sets the caller as the owner of the contract.
     */
    constructor() {
        assembly {
            sstore(_OWNER_SLOT, caller())
        }
    }

    function contractId() internal pure virtual override returns (bytes32) {
        return bytes32(0);
    }

    /**
     * @notice Initializes the proxy contract with the specified implementation, new owner, and any optional setup parameters.
     * @param implementationAddress The address of the implementation contract
     * @param newOwner The address of the new proxy owner
     * @param params Optional parameters to be passed to the setup function of the implementation contract
     * @dev This function is only callable by the owner of the proxy. If the proxy has already been initialized, it will revert.
     * If the contract ID of the implementation is incorrect, it will also revert. It then stores the implementation address and
     * new owner address in the designated storage slots and calls the setup function on the implementation (if setup params exist).
     */
    function init(
        address implementationAddress,
        address newOwner,
        bytes memory params
    ) external {
        address owner;

        assembly {
            owner := sload(_OWNER_SLOT)
        }

        if (msg.sender != owner) revert NotOwner();
        if (implementation() != address(0)) revert AlreadyInitialized();

        bytes32 id = contractId();
        // Skipping the check if contractId() is not set by an inheriting proxy contract
        if (id != bytes32(0) && IContractIdentifier(implementationAddress).contractId() != id)
            revert InvalidImplementation();

        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementationAddress)
            sstore(_OWNER_SLOT, newOwner)
        }

        if (params.length != 0) {
            (bool success, ) = implementationAddress.delegatecall(
                abi.encodeWithSelector(BaseProxy.setup.selector, params)
            );
            if (!success) revert SetupFailed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IUpgradable } from '../interfaces/IUpgradable.sol';
import { Ownable } from '../utils/Ownable.sol';

/**
 * @title Upgradable Contract
 * @notice This contract provides an interface for upgradable smart contracts and includes the functionality to perform upgrades.
 */
abstract contract Upgradable is Ownable, IUpgradable {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address internal immutable implementationAddress;

    /**
     * @notice Constructor sets the implementation address to the address of the contract itself
     * @dev This is used in the onlyProxy modifier to prevent certain functions from being called directly
     * on the implementation contract itself.
     * @dev The owner is initially set as address(1) because the actual owner is set within the proxy. It is not
     * set as the zero address because Ownable is designed to throw an error for ownership transfers to the zero address.
     */
    constructor() Ownable(address(1)) {
        implementationAddress = address(this);
    }

    /**
     * @notice Modifier to ensure that a function can only be called by the proxy
     */
    modifier onlyProxy() {
        // Prevent setup from being called on the implementation
        if (address(this) == implementationAddress) revert NotProxy();
        _;
    }

    /**
     * @notice Returns the address of the current implementation
     * @return implementation_ Address of the current implementation
     */
    function implementation() public view returns (address implementation_) {
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @notice Upgrades the contract to a new implementation
     * @param newImplementation The address of the new implementation contract
     * @param newImplementationCodeHash The codehash of the new implementation contract
     * @param params Optional setup parameters for the new implementation contract
     * @dev This function is only callable by the owner.
     */
    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external override onlyOwner {
        if (IUpgradable(newImplementation).contractId() != IUpgradable(this).contractId())
            revert InvalidImplementation();

        if (newImplementationCodeHash != newImplementation.codehash) revert InvalidCodeHash();

        emit Upgraded(newImplementation);

        if (params.length > 0) {
            // slither-disable-next-line controlled-delegatecall
            (bool success, ) = newImplementation.delegatecall(abi.encodeWithSelector(this.setup.selector, params));

            if (!success) revert SetupFailed();
        }

        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    /**
     * @notice Sets up the contract with initial data
     * @param data Initialization data for the contract
     * @dev This function is only callable by the proxy contract.
     */
    function setup(bytes calldata data) external override onlyProxy {
        _setup(data);
    }

    /**
     * @notice Internal function to set up the contract with initial data
     * @param data Initialization data for the contract
     * @dev This function should be implemented in derived contracts.
     */
    function _setup(bytes calldata data) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from '../interfaces/IOwnable.sol';

/**
 * @title Ownable
 * @notice A contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The owner account is set through ownership transfer. This module makes
 * it possible to transfer the ownership of the contract to a new account in one
 * step, as well as to an interim pending owner. In the second flow the ownership does not
 * change until the pending owner accepts the ownership transfer.
 */
abstract contract Ownable is IOwnable {
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;
    // keccak256('ownership-transfer')
    bytes32 internal constant _OWNERSHIP_TRANSFER_SLOT =
        0x9855384122b55936fbfb8ca5120e63c6537a1ac40caf6ae33502b3c5da8c87d1;

    /**
     * @notice Initializes the contract by transferring ownership to the owner parameter.
     * @param _owner Address to set as the initial owner of the contract
     */
    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /**
     * @notice Modifier that throws an error if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != msg.sender) revert NotOwner();

        _;
    }

    /**
     * @notice Returns the current owner of the contract.
     * @return owner_ The current owner of the contract
     */
    function owner() public view returns (address owner_) {
        assembly {
            owner_ := sload(_OWNER_SLOT)
        }
    }

    /**
     * @notice Returns the pending owner of the contract.
     * @return owner_ The pending owner of the contract
     */
    function pendingOwner() public view returns (address owner_) {
        assembly {
            owner_ := sload(_OWNERSHIP_TRANSFER_SLOT)
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new account `newOwner`.
     * @dev Can only be called by the current owner.
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @notice Propose to transfer ownership of the contract to a new account `newOwner`.
     * @dev Can only be called by the current owner. The ownership does not change
     * until the new owner accepts the ownership transfer.
     * @param newOwner The address to transfer ownership to
     */
    function proposeOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) revert InvalidOwnerAddress();

        emit OwnershipTransferStarted(newOwner);

        assembly {
            sstore(_OWNERSHIP_TRANSFER_SLOT, newOwner)
        }
    }

    /**
     * @notice Accepts ownership of the contract.
     * @dev Can only be called by the pending owner
     */
    function acceptOwnership() external virtual {
        address newOwner = pendingOwner();
        if (newOwner != msg.sender) revert InvalidOwner();

        _transferOwnership(newOwner);
    }

    /**
     * @notice Internal function to transfer ownership of the contract to a new account `newOwner`.
     * @dev Called in the constructor to set the initial owner.
     * @param newOwner The address to transfer ownership to
     */
    function _transferOwnership(address newOwner) internal virtual {
        if (newOwner == address(0)) revert InvalidOwnerAddress();

        emit OwnershipTransferred(newOwner);

        assembly {
            sstore(_OWNER_SLOT, newOwner)
            sstore(_OWNERSHIP_TRANSFER_SLOT, 0)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity 0.8.20;

import {ISquidDepositService} from "../interfaces/ISquidDepositService.sol";

contract DepositReceiver {
    constructor(bytes memory delegateData, address refundRecipient) {
        // Reading the implementation of the AxelarDepositService
        // and delegating the call back to it
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = ISquidDepositService(msg.sender).receiverImplementation().delegatecall(delegateData);

        // if not success revert with the original revert data
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        if (refundRecipient == address(0)) refundRecipient = msg.sender;

        selfdestruct(payable(refundRecipient));
    }

    // @dev This function is for receiving Ether from unwrapping WETH9
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAxelarGateway} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol";
import {ISquidRouter} from "../interfaces/ISquidRouter.sol";
import {ISquidMulticall} from "../interfaces/ISquidMulticall.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISquidDepositService} from "../interfaces/ISquidDepositService.sol";

contract ReceiverImplementation {
    using SafeERC20 for IERC20;

    error ZeroAddressProvided();
    error InvalidSymbol();
    error NothingDeposited();

    address private constant nativeCoin = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable router;
    address immutable gateway;

    constructor(address _router, address _gateway) {
        if (_router == address(0) || _gateway == address(0)) revert ZeroAddressProvided();

        router = _router;
        gateway = _gateway;
    }

    // Context: msg.sender == SquidDepositService, this == DepositReceiver
    function receiveAndBridgeCall(
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();
        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        address tokenAddress = IAxelarGateway(gateway).tokenAddresses(bridgedTokenSymbol);
        if (tokenAddress == address(0)) revert InvalidSymbol();
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(tokenAddress).approve(router, amount);
        ISquidRouter(router).bridgeCall{value: address(this).balance}(
            bridgedTokenSymbol,
            amount,
            destinationChain,
            destinationAddress,
            payload,
            refundRecipient,
            enableExpress
        );
    }

    // Context: msg.sender == SquidDepositService, this == DepositReceiver
    function receiveAndCallBridge(
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();
        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(token).approve(router, amount);
        ISquidRouter(router).callBridge{value: address(this).balance}(
            token,
            amount,
            calls,
            bridgedTokenSymbol,
            destinationChain,
            destinationAddress
        );
    }

    function receiveAndCallBridgeCall(
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();
        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(token).approve(router, amount);
        ISquidRouter(router).callBridgeCall{value: address(this).balance}(
            token,
            amount,
            calls,
            bridgedTokenSymbol,
            destinationChain,
            destinationAddress,
            payload,
            refundRecipient,
            enableExpress
        );
    }

    function receiveAndFundAndRunMulticall(
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();

        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(token).approve(router, amount);
        ISquidRouter(router).fundAndRunMulticall{value: address(this).balance}(token, amount, calls);
    }

    function _refund(address tokenToRefund, address refundRecipient) private {
        if (refundRecipient == address(0)) refundRecipient = msg.sender;

        if (tokenToRefund != nativeCoin) {
            uint256 contractBalance = IERC20(tokenToRefund).balanceOf(address(this));
            IERC20(tokenToRefund).safeTransfer(refundRecipient, contractBalance);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISquidDepositService} from "../interfaces/ISquidDepositService.sol";
import {ISquidMulticall} from "../interfaces/ISquidMulticall.sol";
import {IAxelarGateway} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol";
import {DepositReceiver} from "./DepositReceiver.sol";
import {ReceiverImplementation} from "./ReceiverImplementation.sol";

/// @dev This should be owned by the microservice that is paying for gas.
contract SquidDepositService is Upgradable, ISquidDepositService {
    using SafeERC20 for IERC20;

    // This public storage is for ERC20 token intended to be refunded.
    // It triggers the DepositReceiver/ReceiverImplementation to switch into a refund mode.
    // Address is stored and deleted withing the same refund transaction.
    address public refundToken;

    address private constant nativeCoin = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable gateway;
    address public immutable refundIssuer;
    address public immutable receiverImplementation;

    constructor(address _router, address _gateway, address _refundIssuer) {
        if (_gateway == address(0) || _refundIssuer == address(0)) revert ZeroAddressProvided();

        gateway = _gateway;
        refundIssuer = _refundIssuer;
        receiverImplementation = address(new ReceiverImplementation(_router, _gateway));
    }

    function addressForBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndBridgeCall.selector,
                    bridgedTokenSymbol,
                    destinationChain,
                    destinationAddress,
                    payload,
                    refundRecipient,
                    enableExpress
                ),
                refundRecipient
            );
    }

    function addressForCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndCallBridge.selector,
                    token,
                    calls,
                    bridgedTokenSymbol,
                    destinationChain,
                    destinationAddress,
                    refundRecipient
                ),
                refundRecipient
            );
    }

    function addressForCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndCallBridgeCall.selector,
                    token,
                    calls,
                    bridgedTokenSymbol,
                    destinationChain,
                    destinationAddress,
                    payload,
                    refundRecipient,
                    enableExpress
                ),
                refundRecipient
            );
    }

    function addressForFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndFundAndRunMulticall.selector,
                    token,
                    calls,
                    refundRecipient
                ),
                refundRecipient
            );
    }

    function bridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external {
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndBridgeCall.selector,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                enableExpress
            ),
            refundRecipient
        );
    }

    function callBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external {
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridge.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                refundRecipient
            ),
            refundRecipient
        );
    }

    function callBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express
    ) external {
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridgeCall.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                express
            ),
            refundRecipient
        );
    }

    function fundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external {
        // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndFundAndRunMulticall.selector,
                token,
                calls,
                refundRecipient
            ),
            refundRecipient
        );
    }

    /// @dev Refunds ERC20 token from the deposit address if it doesn't match the intended token
    // Only refundRecipient can refund the token that was intended to go cross-chain (if not sent yet)
    function refundBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external {
        address intendedToken = IAxelarGateway(gateway).tokenAddresses(bridgedTokenSymbol);
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == intendedToken && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;

        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndBridgeCall.selector,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                express
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient,
        address tokenToRefund
    ) external {
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == token && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridge.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                refundRecipient
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external {
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == token && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridgeCall.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                express
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient,
        address tokenToRefund
    ) external {
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == token && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndFundAndRunMulticall.selector,
                token,
                calls,
                refundRecipient
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundLockedAsset(address receiver, address token, uint256 amount) external {
        if (msg.sender != refundIssuer) revert NotRefundIssuer();
        if (receiver == address(0)) revert ZeroAddressProvided();

        if (token == nativeCoin) {
            (bool sent, ) = receiver.call{value: amount}("");
            if (!sent) revert NativeTransferFailed();
        } else {
            IERC20(token).safeTransfer(receiver, amount);
        }
    }

    function _depositAddress(
        bytes32 salt,
        bytes memory delegateData,
        address refundRecipient
    ) private view returns (address) {
        /* Convert a hash which is bytes32 to an address which is 20-byte long
        according to https://docs.soliditylang.org/en/v0.8.9/control-structures.html?highlight=create2#salted-contract-creations-create2 */
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                // Encoding delegateData and refundRecipient as constructor params
                                keccak256(
                                    abi.encodePacked(
                                        type(DepositReceiver).creationCode,
                                        abi.encode(delegateData, refundRecipient)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function contractId() external pure returns (bytes32) {
        return keccak256("squid-deposit-service");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRoledPausable {
    event PauserProposed(address indexed currentPauser, address indexed pendingPauser);
    event PauserUpdated(address indexed pendingPauser);
    event Paused();
    event Unpaused();

    error ContractIsPaused();
    error NotPauser();
    error NotPendingPauser();

    function updatePauser(address _newPauser) external;

    function acceptPauser() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool value);

    function pauser() external view returns (address value);

    function pendingPauser() external view returns (address value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IUpgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IUpgradable.sol";
import {ISquidMulticall} from "./ISquidMulticall.sol";

// This should be owned by the microservice that is paying for gas.
interface ISquidDepositService is IUpgradable {
    error ZeroAddressProvided();
    error NotRefundIssuer();
    error NativeTransferFailed();

    function addressForBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address);

    function addressForCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external view returns (address);

    function addressForCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address);

    function addressForFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external view returns (address);

    function bridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external;

    function callBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external;

    function callBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express
    ) external;

    function fundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external;

    function refundBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external;

    function refundCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient,
        address tokenToRefund
    ) external;

    function refundCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external;

    function refundFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient,
        address tokenToRefund
    ) external;

    function refundLockedAsset(address receiver, address token, uint256 amount) external;

    function receiverImplementation() external returns (address receiver);

    function refundToken() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISquidFeeCollector {
    event FeeCollected(address token, address integrator, uint256 squidFee, uint256 integratorFee);
    event FeeWithdrawn(address token, address account, uint256 amount);

    error TransferFailed();
    error ExcessiveIntegratorFee();

    function collectFee(address token, uint256 amountToTax, address integratorAddress, uint256 integratorFee) external;

    function withdrawFee(address token) external;

    function getBalance(address token, address account) external view returns (uint256 accountBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISquidMulticall {
    enum CallType {
        Default,
        FullTokenBalance,
        FullNativeBalance,
        CollectTokenBalance
    }

    struct Call {
        CallType callType;
        address target;
        uint256 value;
        bytes callData;
        bytes payload;
    }

    error AlreadyRunning();
    error CallFailed(uint256 callPosition, bytes reason);

    function run(Call[] calldata calls) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ISquidMulticall} from "./ISquidMulticall.sol";

interface ISquidRouter {
    event CrossMulticallExecuted(bytes32 indexed payloadHash);
    event CrossMulticallFailed(bytes32 indexed payloadHash, bytes reason, address indexed refundRecipient);

    error ZeroAddressProvided();
    error ApprovalFailed();

    function bridgeCall(
        string calldata bridgedTokenSymbol,
        uint256 amount,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable;

    function callBridge(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external payable;

    function callBridgeCall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable;

    function fundAndRunMulticall(address token, uint256 amount, ISquidMulticall.Call[] memory calls) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAggregationExecutor {
    function callBytes(bytes calldata data) external payable; // 0xd9c45357

    // callbytes per swap sequence
    function swapSingleSequence(bytes calldata data) external;

    function finalTransactionProcessing(
        address tokenIn,
        address tokenOut,
        address to,
        bytes calldata destTokenFeeData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IExecutorHelper1 {
    struct UniSwap {
        address pool;
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 collectAmount; // amount that should be transferred to the pool
        uint256 limitReturnAmount;
        uint32 swapFee;
        uint32 feePrecision;
        uint32 tokenWeightInput;
    }

    struct StableSwap {
        address pool;
        address tokenFrom;
        address tokenTo;
        uint8 tokenIndexFrom;
        uint8 tokenIndexTo;
        uint256 dx;
        uint256 minDy;
        uint256 poolLength;
        address poolLp;
        bool isSaddle; // true: saddle, false: stable
    }

    struct CurveSwap {
        address pool;
        address tokenFrom;
        address tokenTo;
        int128 tokenIndexFrom;
        int128 tokenIndexTo;
        uint256 dx;
        uint256 minDy;
        bool usePoolUnderlying;
        bool useTriCrypto;
    }

    struct UniSwapV3ProMM {
        address recipient;
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount;
        uint256 limitReturnAmount;
        uint160 sqrtPriceLimitX96;
        bool isUniV3; // true = UniV3, false = ProMM
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    struct SwapCallbackDataPath {
        address pool;
        address tokenIn;
        address tokenOut;
    }

    struct BalancerV2 {
        address vault;
        bytes32 poolId;
        address assetIn;
        address assetOut;
        uint256 amount;
        uint256 limit;
    }

    struct KyberRFQ {
        address rfq;
        bytes order;
        bytes signature;
        uint256 amount;
        address payable target;
    }

    struct DODO {
        address recipient;
        address pool;
        address tokenFrom;
        address tokenTo;
        uint256 amount;
        uint256 minReceiveQuote;
        address sellHelper;
        bool isSellBase;
        bool isVersion2;
    }

    struct GMX {
        address vault;
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint256 minOut;
        address receiver;
    }

    struct Synthetix {
        address synthetixProxy;
        address tokenIn;
        address tokenOut;
        bytes32 sourceCurrencyKey;
        uint256 sourceAmount;
        bytes32 destinationCurrencyKey;
        uint256 minAmount;
        bool useAtomicExchange;
    }

    function executeUniSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeStableSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeCurveSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeKyberDMMSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeUniV3ProMMSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeRfqSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeBalV2Swap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeDODOSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeVelodromeSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeGMXSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeSynthetixSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeHashflowSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeCamelotSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IExecutorHelper2 {
    function executeKyberLimitOrder(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAggregationExecutor} from "./IAggregationExecutor.sol";

interface IMetaAggregationRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address[] srcReceivers;
        uint256[] srcAmounts;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external payable returns (uint256, uint256);

    function swapSimpleMode(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAggregationExecutor} from "./IAggregationExecutor.sol";

interface IMetaAggregationRouterV2 {
    struct SwapDescriptionV2 {
        IERC20 srcToken;
        IERC20 dstToken;
        address[] srcReceivers; // transfer src token to these addresses, default
        uint256[] srcAmounts;
        address[] feeReceivers;
        uint256[] feeAmounts;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    /// @dev  use for swapGeneric and swap to avoid stack too deep
    struct SwapExecutionParams {
        address callTarget; // call this address
        address approveTarget; // approve this address if _APPROVE_FUND set
        bytes targetData;
        SwapDescriptionV2 desc;
        bytes clientData;
    }

    function swap(SwapExecutionParams calldata execution) external payable returns (uint256, uint256);

    function swapSimpleMode(
        IAggregationExecutor caller,
        SwapDescriptionV2 memory desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IExecutorHelper1} from "../../interfaces/kyberswap/IExecutorHelper1.sol";

library ScaleDataHelper1 {
    function newUniSwap(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwap memory uniSwap = abi.decode(data, (IExecutorHelper1.UniSwap));
        uniSwap.collectAmount = (uniSwap.collectAmount * newAmount) / oldAmount;
        return abi.encode(uniSwap);
    }

    function newStableSwap(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.StableSwap memory stableSwap = abi.decode(data, (IExecutorHelper1.StableSwap));
        stableSwap.dx = (stableSwap.dx * newAmount) / oldAmount;
        return abi.encode(stableSwap);
    }

    function newCurveSwap(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.CurveSwap memory curveSwap = abi.decode(data, (IExecutorHelper1.CurveSwap));
        curveSwap.dx = (curveSwap.dx * newAmount) / oldAmount;
        return abi.encode(curveSwap);
    }

    function newKyberDMM(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwap memory kyberDMMSwap = abi.decode(data, (IExecutorHelper1.UniSwap));
        kyberDMMSwap.collectAmount = (kyberDMMSwap.collectAmount * newAmount) / oldAmount;
        return abi.encode(kyberDMMSwap);
    }

    function newUniV3ProMM(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwapV3ProMM memory uniSwapV3ProMM = abi.decode(data, (IExecutorHelper1.UniSwapV3ProMM));
        uniSwapV3ProMM.swapAmount = (uniSwapV3ProMM.swapAmount * newAmount) / oldAmount;

        return abi.encode(uniSwapV3ProMM);
    }

    function newBalancerV2(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.BalancerV2 memory balancerV2 = abi.decode(data, (IExecutorHelper1.BalancerV2));
        balancerV2.amount = (balancerV2.amount * newAmount) / oldAmount;
        return abi.encode(balancerV2);
    }

    function newDODO(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.DODO memory dodo = abi.decode(data, (IExecutorHelper1.DODO));
        dodo.amount = (dodo.amount * newAmount) / oldAmount;
        return abi.encode(dodo);
    }

    function newVelodrome(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwap memory velodrome = abi.decode(data, (IExecutorHelper1.UniSwap));
        velodrome.collectAmount = (velodrome.collectAmount * newAmount) / oldAmount;
        return abi.encode(velodrome);
    }

    function newGMX(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.GMX memory gmx = abi.decode(data, (IExecutorHelper1.GMX));
        gmx.amount = (gmx.amount * newAmount) / oldAmount;
        return abi.encode(gmx);
    }

    function newSynthetix(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.Synthetix memory synthetix = abi.decode(data, (IExecutorHelper1.Synthetix));
        synthetix.sourceAmount = (synthetix.sourceAmount * newAmount) / oldAmount;
        return abi.encode(synthetix);
    }

    function newCamelot(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwap memory camelot = abi.decode(data, (IExecutorHelper1.UniSwap));
        camelot.collectAmount = (camelot.collectAmount * newAmount) / oldAmount;
        return abi.encode(camelot);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IRoledPausable} from "../interfaces/IRoledPausable.sol";
import {StorageSlot} from "./StorageSlot.sol";

abstract contract RoledPausable is IRoledPausable {
    using StorageSlot for bytes32;

    bytes32 internal constant PAUSED_SLOT = keccak256("RoledPausable.paused");
    bytes32 internal constant PAUSER_SLOT = keccak256("RoledPausable.pauser");
    bytes32 internal constant PENDING_PAUSER_SLOT = keccak256("RoledPausable.pendingPauser");

    modifier whenNotPaused() {
        if (paused()) revert ContractIsPaused();
        _;
    }

    modifier onlyPauser() {
        if (msg.sender != pauser()) revert NotPauser();
        _;
    }

    constructor() {
        _setPauser(msg.sender);
    }

    function updatePauser(address newPauser) external onlyPauser {
        PENDING_PAUSER_SLOT.setAddress(newPauser);
        emit PauserProposed(msg.sender, newPauser);
    }

    function acceptPauser() external {
        if (msg.sender != pendingPauser()) revert NotPendingPauser();
        _setPauser(msg.sender);
        PENDING_PAUSER_SLOT.setAddress(address(0));
    }

    function pause() external virtual onlyPauser {
        PAUSED_SLOT.setBool(true);
        emit Paused();
    }

    function unpause() external virtual onlyPauser {
        PAUSED_SLOT.setBool(false);
        emit Unpaused();
    }

    function pauser() public view returns (address value) {
        value = PAUSER_SLOT.getAddress();
    }

    function paused() public view returns (bool value) {
        value = PAUSED_SLOT.getBool();
    }

    function pendingPauser() public view returns (address value) {
        value = PENDING_PAUSER_SLOT.getAddress();
    }

    function _setPauser(address _pauser) internal {
        PAUSER_SLOT.setAddress(_pauser);
        emit PauserUpdated(_pauser);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library StorageSlot {
    function setUint256(bytes32 slot, uint256 value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getUint256(bytes32 slot) internal view returns (uint256 value) {
        assembly {
            value := sload(slot)
        }
    }

    function setAddress(bytes32 slot, address value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getAddress(bytes32 slot) internal view returns (address value) {
        assembly {
            value := sload(slot)
        }
    }

    function setBool(bytes32 slot, bool value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getBool(bytes32 slot) internal view returns (bool value) {
        assembly {
            value := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IExecutorHelper1} from "../interfaces/kyberswap/IExecutorHelper1.sol";
import {IExecutorHelper2} from "../interfaces/kyberswap/IExecutorHelper2.sol";
import {IMetaAggregationRouterV2} from "../interfaces/kyberswap/IMetaAggregationRouterV2.sol";
import {IMetaAggregationRouter} from "../interfaces/kyberswap/IMetaAggregationRouter.sol";
import {ScaleDataHelper1} from "../libraries/kyberswap/ScaleDataHelper1.sol";

contract KyberswapPatcher {
    uint256 private constant _PARTIAL_FILL = 0x01;
    uint256 private constant _REQUIRES_EXTRA_ETH = 0x02;
    uint256 private constant _SHOULD_CLAIM = 0x04;
    uint256 private constant _BURN_FROM_MSG_SENDER = 0x08;
    uint256 private constant _BURN_FROM_TX_ORIGIN = 0x10;
    uint256 private constant _SIMPLE_SWAP = 0x20;

    struct Swap {
        bytes data;
        bytes4 functionSelector;
    }

    struct SimpleSwapData {
        address[] firstPools;
        uint256[] firstSwapAmounts;
        bytes[] swapDatas;
        uint256 deadline;
        bytes destTokenFeeData;
    }

    struct SwapExecutorDescription {
        Swap[][] swapSequences;
        address tokenIn;
        address tokenOut;
        uint256 minTotalAmountOut;
        address to;
        uint256 deadline;
        bytes destTokenFeeData;
    }

    struct Data {
        address router;
        bytes inputData;
        uint256 newAmount;
    }

    error CallFailed(string message, bytes reason);

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        if (value == 0) return;
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransferFrom: Transfer from fail");
    }

    function safeApprove(address token, address to, uint256 value) internal {
        if (value == 0) return;
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeApprove: Approve fail");
    }

    function scaleAndSwap(uint256 newAmount, address router, bytes calldata inputData) external payable {
        bytes4 selector = bytes4(inputData[:4]);
        bytes memory dataToDecode = new bytes(inputData.length - 4);
        bytes memory callData;

        for (uint256 i = 0; i < inputData.length - 4; ++i) {
            dataToDecode[i] = inputData[i + 4];
        }

        if (
            selector == IMetaAggregationRouter.swap.selector ||
            selector == IMetaAggregationRouter.swapSimpleMode.selector
        ) {
            (
                address callTarget,
                IMetaAggregationRouter.SwapDescription memory desc,
                bytes memory targetData,
                bytes memory clientData
            ) = abi.decode(dataToDecode, (address, IMetaAggregationRouter.SwapDescription, bytes, bytes));

            (desc, targetData) = _getScaledInputDataV1(
                desc,
                targetData,
                newAmount,
                selector == IMetaAggregationRouter.swapSimpleMode.selector || _flagsChecked(desc.flags, _SIMPLE_SWAP)
            );
            callData = abi.encodeWithSelector(selector, callTarget, desc, targetData, clientData);

            safeTransferFrom(address(desc.srcToken), msg.sender, address(this), newAmount);
            safeApprove(address(desc.srcToken), router, newAmount);
        } else if (selector == IMetaAggregationRouterV2.swap.selector) {
            IMetaAggregationRouterV2.SwapExecutionParams memory params = abi.decode(
                dataToDecode,
                (IMetaAggregationRouterV2.SwapExecutionParams)
            );

            (params.desc, params.targetData) = _getScaledInputDataV2(
                params.desc,
                params.targetData,
                newAmount,
                _flagsChecked(params.desc.flags, _SIMPLE_SWAP)
            );
            callData = abi.encodeWithSelector(selector, params);

            safeTransferFrom(address(params.desc.srcToken), msg.sender, address(this), newAmount);
            safeApprove(address(params.desc.srcToken), router, newAmount);
        } else if (selector == IMetaAggregationRouterV2.swapSimpleMode.selector) {
            (
                address callTarget,
                IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
                bytes memory targetData,
                bytes memory clientData
            ) = abi.decode(dataToDecode, (address, IMetaAggregationRouterV2.SwapDescriptionV2, bytes, bytes));

            (desc, targetData) = _getScaledInputDataV2(desc, targetData, newAmount, true);
            callData = abi.encodeWithSelector(selector, callTarget, desc, targetData, clientData);

            safeTransferFrom(address(desc.srcToken), msg.sender, address(this), newAmount);
            safeApprove(address(desc.srcToken), router, newAmount);
        } else revert("KyberswapPatcher: Invalid selector");

        (bool success, bytes memory data) = router.call(callData);
        if (!success) revert CallFailed("KyberswapPatcher: call failed", data);
    }

    function _getScaledInputDataV1(
        IMetaAggregationRouter.SwapDescription memory desc,
        bytes memory executorData,
        uint256 newAmount,
        bool isSimpleMode
    ) internal pure returns (IMetaAggregationRouter.SwapDescription memory, bytes memory) {
        uint256 oldAmount = desc.amount;
        if (oldAmount == newAmount) {
            return (desc, executorData);
        }

        // simple mode swap
        if (isSimpleMode) {
            return (
                _scaledSwapDescriptionV1(desc, oldAmount, newAmount),
                _scaledSimpleSwapData(executorData, oldAmount, newAmount)
            );
        }

        //normal mode swap
        return (
            _scaledSwapDescriptionV1(desc, oldAmount, newAmount),
            _scaledExecutorCallBytesData(executorData, oldAmount, newAmount)
        );
    }

    function _getScaledInputDataV2(
        IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
        bytes memory executorData,
        uint256 newAmount,
        bool isSimpleMode
    ) internal pure returns (IMetaAggregationRouterV2.SwapDescriptionV2 memory, bytes memory) {
        uint256 oldAmount = desc.amount;
        if (oldAmount == newAmount) {
            return (desc, executorData);
        }

        // simple mode swap
        if (isSimpleMode) {
            return (
                _scaledSwapDescriptionV2(desc, oldAmount, newAmount),
                _scaledSimpleSwapData(executorData, oldAmount, newAmount)
            );
        }

        //normal mode swap
        return (
            _scaledSwapDescriptionV2(desc, oldAmount, newAmount),
            _scaledExecutorCallBytesData(executorData, oldAmount, newAmount)
        );
    }

    function _scaledSwapDescriptionV1(
        IMetaAggregationRouter.SwapDescription memory desc,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (IMetaAggregationRouter.SwapDescription memory) {
        desc.minReturnAmount = (desc.minReturnAmount * newAmount) / oldAmount;
        if (desc.minReturnAmount == 0) desc.minReturnAmount = 1;
        desc.amount = newAmount;
        for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
            desc.srcAmounts[i] = (desc.srcAmounts[i] * newAmount) / oldAmount;
        }
        return desc;
    }

    function _scaledSwapDescriptionV2(
        IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (IMetaAggregationRouterV2.SwapDescriptionV2 memory) {
        desc.minReturnAmount = (desc.minReturnAmount * newAmount) / oldAmount;
        if (desc.minReturnAmount == 0) desc.minReturnAmount = 1;
        desc.amount = newAmount;
        for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
            desc.srcAmounts[i] = (desc.srcAmounts[i] * newAmount) / oldAmount;
        }
        return desc;
    }

    function _scaledSimpleSwapData(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        SimpleSwapData memory swapData = abi.decode(data, (SimpleSwapData));
        for (uint256 i = 0; i < swapData.firstPools.length; i++) {
            swapData.firstSwapAmounts[i] = (swapData.firstSwapAmounts[i] * newAmount) / oldAmount;
        }
        return abi.encode(swapData);
    }

    function _scaledExecutorCallBytesData(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        SwapExecutorDescription memory executorDesc = abi.decode(data, (SwapExecutorDescription));
        executorDesc.minTotalAmountOut = (executorDesc.minTotalAmountOut * newAmount) / oldAmount;
        for (uint256 i = 0; i < executorDesc.swapSequences.length; i++) {
            Swap memory swap = executorDesc.swapSequences[i][0];
            bytes4 functionSelector = swap.functionSelector;

            if (functionSelector == IExecutorHelper1.executeUniSwap.selector) {
                swap.data = ScaleDataHelper1.newUniSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeStableSwap.selector) {
                swap.data = ScaleDataHelper1.newStableSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeCurveSwap.selector) {
                swap.data = ScaleDataHelper1.newCurveSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeKyberDMMSwap.selector) {
                swap.data = ScaleDataHelper1.newKyberDMM(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeUniV3ProMMSwap.selector) {
                swap.data = ScaleDataHelper1.newUniV3ProMM(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeRfqSwap.selector) {
                revert("KyberswapPatcher: Can not scale RFQ swap");
            } else if (functionSelector == IExecutorHelper1.executeBalV2Swap.selector) {
                swap.data = ScaleDataHelper1.newBalancerV2(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeDODOSwap.selector) {
                swap.data = ScaleDataHelper1.newDODO(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeVelodromeSwap.selector) {
                swap.data = ScaleDataHelper1.newVelodrome(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeGMXSwap.selector) {
                swap.data = ScaleDataHelper1.newGMX(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeSynthetixSwap.selector) {
                swap.data = ScaleDataHelper1.newSynthetix(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeHashflowSwap.selector) {
                revert("KyberswapPatcher: Can not scale RFQ swap");
            } else if (functionSelector == IExecutorHelper1.executeCamelotSwap.selector) {
                swap.data = ScaleDataHelper1.newCamelot(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper2.executeKyberLimitOrder.selector) {
                revert("KyberswapPatcher: Can not scale RFQ swap");
            } else revert("AggregationExecutor: Dex type not supported");
        }
        return abi.encode(executorDesc);
    }

    function _flagsChecked(uint256 number, uint256 flag) internal pure returns (bool) {
        return number & flag != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol";
import {ISquidFeeCollector} from "../interfaces/ISquidFeeCollector.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SquidFeeCollector is ISquidFeeCollector, Upgradable {
    bytes32 private constant BALANCES_PREFIX = keccak256("SquidFeeCollector.balances");
    bytes32 private constant SPECIFIC_FEES_PREFIX = keccak256("SquidFeeCollector.specificFees");
    address public immutable squidTeam;
    // Value expected with 2 decimals
    /// eg. 825 is 8.25%
    uint256 public immutable squidDefaultFee;

    error ZeroAddressProvided();

    constructor(address _squidTeam, uint256 _squidDefaultFee) {
        if (_squidTeam == address(0)) revert ZeroAddressProvided();

        squidTeam = _squidTeam;
        squidDefaultFee = _squidDefaultFee;
    }

    /// @param integratorFee Value expected with 2 decimals
    /// eg. 825 is 8.25%
    function collectFee(address token, uint256 amountToTax, address integratorAddress, uint256 integratorFee) external {
        if (integratorFee > 1000) revert ExcessiveIntegratorFee();

        uint256 specificFee = getSpecificFee(integratorAddress);
        uint256 squidFee = specificFee == 0 ? squidDefaultFee : specificFee;

        uint256 baseFeeAmount = (amountToTax * integratorFee) / 10000;
        uint256 squidFeeAmount = (baseFeeAmount * squidFee) / 10000;
        uint256 integratorFeeAmount = baseFeeAmount - squidFeeAmount;

        _safeTransferFrom(token, msg.sender, baseFeeAmount);
        _setBalance(token, squidTeam, getBalance(token, squidTeam) + squidFeeAmount);
        _setBalance(token, integratorAddress, getBalance(token, integratorAddress) + integratorFeeAmount);

        emit FeeCollected(token, integratorAddress, squidFeeAmount, integratorFeeAmount);
    }

    function withdrawFee(address token) external {
        uint256 balance = getBalance(token, msg.sender);
        _setBalance(token, msg.sender, 0);
        _safeTransfer(token, msg.sender, balance);

        emit FeeWithdrawn(token, msg.sender, balance);
    }

    function setSpecificFee(address integrator, uint256 fee) external onlyOwner {
        bytes32 slot = _computeSpecificFeeSlot(integrator);
        assembly {
            sstore(slot, fee)
        }
    }

    function getBalance(address token, address account) public view returns (uint256 value) {
        bytes32 slot = _computeBalanceSlot(token, account);
        assembly {
            value := sload(slot)
        }
    }

    function getSpecificFee(address integrator) public view returns (uint256 value) {
        bytes32 slot = _computeSpecificFeeSlot(integrator);
        assembly {
            value := sload(slot)
        }
    }

    function contractId() external pure returns (bytes32 id) {
        id = keccak256("squid-fee-collector");
    }

    function _setBalance(address token, address account, uint256 amount) private {
        bytes32 slot = _computeBalanceSlot(token, account);
        assembly {
            sstore(slot, amount)
        }
    }

    function _computeBalanceSlot(address token, address account) private pure returns (bytes32 slot) {
        slot = keccak256(abi.encodePacked(BALANCES_PREFIX, token, account));
    }

    function _computeSpecificFeeSlot(address integrator) private pure returns (bytes32 slot) {
        slot = keccak256(abi.encodePacked(SPECIFIC_FEES_PREFIX, integrator));
    }

    function _safeTransferFrom(address token, address from, uint256 amount) internal {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {InitProxy} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/InitProxy.sol";

contract SquidFeeCollectorProxy is InitProxy {
    function contractId() internal pure override returns (bytes32 id) {
        id = keccak256("squid-fee-collector");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISquidMulticall} from "../interfaces/ISquidMulticall.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract SquidMulticall is ISquidMulticall, IERC721Receiver, IERC1155Receiver {
    bytes4 private constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant ERC721_TOKENRECEIVER_INTERFACE_ID = 0x150b7a02;
    bytes4 private constant ERC1155_TOKENRECEIVER_INTERFACE_ID = 0x4e2312e0;

    bool private isRunning;

    error TransferFailed();

    function run(Call[] calldata calls) external payable {
        // Prevents reentrancy
        if (isRunning) revert AlreadyRunning();
        isRunning = true;

        for (uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];

            if (call.callType == CallType.FullTokenBalance) {
                (address token, uint256 amountParameterPosition) = abi.decode(call.payload, (address, uint256));
                uint256 amount = IERC20(token).balanceOf(address(this));
                _setCallDataParameter(call.callData, amountParameterPosition, amount);
            } else if (call.callType == CallType.FullNativeBalance) {
                call.value = address(this).balance;
            } else if (call.callType == CallType.CollectTokenBalance) {
                address token = abi.decode(call.payload, (address));
                _safeTransferFrom(token, msg.sender, IERC20(token).balanceOf(msg.sender));
                continue;
            }

            (bool success, bytes memory data) = call.target.call{value: call.value}(call.callData);
            if (!success) revert CallFailed(i, data);
        }

        isRunning = false;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == ERC1155_TOKENRECEIVER_INTERFACE_ID ||
            interfaceId == ERC721_TOKENRECEIVER_INTERFACE_ID ||
            interfaceId == ERC165_INTERFACE_ID;
    }

    function _safeTransferFrom(address token, address from, uint256 amount) private {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }

    function _setCallDataParameter(bytes memory callData, uint256 parameterPosition, uint256 value) private pure {
        assembly {
            // 36 bytes shift because 32 for prefix + 4 for selector
            mstore(add(callData, add(36, mul(parameterPosition, 32))), value)
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    // Required to enable ETH reception with .transfer or .send
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISquidRouter} from "../interfaces/ISquidRouter.sol";
import {ISquidMulticall} from "../interfaces/ISquidMulticall.sol";
import {AxelarExpressExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/express/AxelarExpressExecutable.sol";
import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IERC20} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol";
import {SafeTokenTransfer, SafeTokenTransferFrom, TokenTransferFailed} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol";
import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol";
import {RoledPausable} from "../libraries/RoledPausable.sol";

contract SquidRouter is ISquidRouter, AxelarExpressExecutable, Upgradable, RoledPausable {
    using SafeTokenTransferFrom for IERC20;
    using SafeTokenTransfer for IERC20;

    IAxelarGasService private immutable gasService;
    ISquidMulticall private immutable squidMulticall;

    constructor(
        address _gateway,
        address _gasService,
        address _multicall
    ) AxelarExpressExecutable(_gateway) {
        if (
            _gateway == address(0) ||
            _gasService == address(0) ||
            _multicall == address(0)
        ) revert ZeroAddressProvided();

        gasService = IAxelarGasService(_gasService);
        squidMulticall = ISquidMulticall(_multicall);
    }

    function bridgeCall(
        string calldata bridgedTokenSymbol,
        uint256 amount,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable whenNotPaused {
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);

        IERC20(bridgedTokenAddress).safeTransferFrom(msg.sender, address(this), amount);

        _bridgeCall(
            bridgedTokenSymbol,
            bridgedTokenAddress,
            destinationChain,
            destinationAddress,
            payload,
            gasRefundRecipient,
            enableExpress
        );
    }

    function callBridge(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external payable whenNotPaused {
        fundAndRunMulticall(token, amount, calls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 bridgedTokenAmount = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(gateway), bridgedTokenAmount);
        gateway.sendToken(destinationChain, destinationAddress, bridgedTokenSymbol, bridgedTokenAmount);
    }

    function callBridgeCall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable whenNotPaused {
        fundAndRunMulticall(token, amount, calls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);

        _bridgeCall(
            bridgedTokenSymbol,
            bridgedTokenAddress,
            destinationChain,
            destinationAddress,
            payload,
            gasRefundRecipient,
            enableExpress
        );
    }

    function contractId() external pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }

    function fundAndRunMulticall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] memory calls
    ) public payable whenNotPaused {
        uint256 valueToSend;

        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            valueToSend = amount;
        } else {
            _transferTokenToMulticall(token, amount);
        }

        squidMulticall.run{value: valueToSend}(calls);
    }

    function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata bridgedTokenSymbol,
        uint256
    ) internal override {
        (ISquidMulticall.Call[] memory calls, address refundRecipient) = abi.decode(
            payload,
            (ISquidMulticall.Call[], address)
        );

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 contractBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(squidMulticall), contractBalance);

        try squidMulticall.run(calls) {
            emit CrossMulticallExecuted(keccak256(payload));
        } catch (bytes memory reason) {
            // Refund tokens to refund recipient if swap fails
            IERC20(bridgedTokenAddress).safeTransfer(refundRecipient, contractBalance);
            emit CrossMulticallFailed(keccak256(payload), reason, refundRecipient);
        }
    }

    function _bridgeCall(
        string calldata bridgedTokenSymbol,
        address bridgedTokenAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) private {
        uint256 bridgedTokenBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        if (address(this).balance > 0) {
            if (enableExpress) {
                gasService.payNativeGasForExpressCallWithToken{value: address(this).balance}(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    bridgedTokenSymbol,
                    bridgedTokenBalance,
                    gasRefundRecipient
                );
            } else {
                gasService.payNativeGasForContractCallWithToken{value: address(this).balance}(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    bridgedTokenSymbol,
                    bridgedTokenBalance,
                    gasRefundRecipient
                );
            }
        }

        _approve(bridgedTokenAddress, address(gateway), bridgedTokenBalance);
        gateway.callContractWithToken(
            destinationChain,
            destinationAddress,
            payload,
            bridgedTokenSymbol,
            bridgedTokenBalance
        );
    }

    function _approve(address token, address spender, uint256 amount) private {
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < amount) {
            if (allowance > 0) {
                _approveCall(token, spender, 0);
            }
            _approveCall(token, spender, type(uint256).max);
        }
    }

    function _approveCall(address token, address spender, uint256 amount) private {
        // Unlimited approval is not security issue since the contract doesn't store tokens
        (bool success, ) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, amount));
        if (!success) revert ApprovalFailed();
    }

    function _transferTokenToMulticall(address token, uint256 amount) private {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, msg.sender, address(squidMulticall), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TokenTransferFailed();
    }

    function _setup(bytes calldata data) internal override {
        address _pauser = abi.decode(data, (address));
        if (_pauser == address(0)) revert ZeroAddressProvided();
        _setPauser(_pauser);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {InitProxy} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/InitProxy.sol";

contract SquidRouterProxy is InitProxy {
    function contractId() internal pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }
}