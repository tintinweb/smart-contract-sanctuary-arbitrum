// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
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

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event ExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        uint256 gasFeeAmount,
        address refundAddress
    );

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
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

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
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

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function addExpressGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IInterchainProposalSender } from './interfaces/IInterchainProposalSender.sol';
import { InterchainCalls } from './lib/InterchainCalls.sol';

/**
 * @title InterchainProposalSender
 * @dev This contract is responsible for facilitating the execution of approved proposals across multiple chains.
 * It achieves this by working in conjunction with the AxelarGateway and AxelarGasService contracts.
 *
 * The contract allows for the sending of a single proposal to multiple destination chains. This is achieved
 * through the `sendProposals` function, which takes in arrays representing the destination chains,
 * destination contracts, fees, target contracts, amounts of tokens to send, function signatures, and encoded
 * function arguments.
 *
 * Each destination chain has a unique corresponding set of contracts to call, amounts of native tokens to send,
 * function signatures to call, and encoded function arguments. This information is provided in a 2D array where
 * the first dimension is the destination chain index, and the second dimension corresponds to the specific details
 * for each chain.
 *
 * In addition, the contract also allows for the execution of a single proposal at a single destination chain
 * through the `sendProposal` function. This is a more granular approach and works similarly to the
 * aforementioned function but for a single destination.
 *
 * The contract ensures the correctness of the provided proposal details and fees through a series of internal
 * functions that revert the transaction if any of the checks fail. This includes checking if the provided fees
 * are equal to the total value sent with the transaction, if the lengths of the provided arrays match, and if the
 * provided proposal arguments are valid.
 *
 * The contract works in conjunction with the AxelarGateway and AxelarGasService contracts. It uses the
 * AxelarGasService contract to pay for the gas fees of the interchain transactions and the AxelarGateway
 * contract to call the target contracts on the destination chains with the provided encoded function arguments.
 */
contract InterchainProposalSender is IInterchainProposalSender {
    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;

    constructor(address _gateway, address _gasService) {
        if (_gateway == address(0) || _gasService == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(_gateway);
        gasService = IAxelarGasService(_gasService);
    }

    /**
     * @dev Broadcast the proposal to be executed at multiple destination chains
     * @param interchainCalls An array of `InterchainCalls.InterchainCall` to be executed at the destination chains. Where each `InterchainCalls.InterchainCall` contains the following:
     * - destinationChain: destination chain
     * - destinationContract: destination contract
     * - gas: gas to be paid for the interchain transaction
     * - calls: An array of `InterchainCalls.Call` to be executed at the destination chain. Where each `InterchainCalls.Call` contains the following:
     *   - target: target contract
     *   - value: amount of tokens to send
     *   - callData: encoded function arguments
     * Note that the destination chain must be unique in the destinationChains array.
     */
    function sendProposals(InterchainCalls.InterchainCall[] calldata interchainCalls) external payable override {
        // revert if the sum of given fees are not equal to the msg.value
        revertIfInvalidFee(interchainCalls);

        uint256 length = interchainCalls.length;

        for (uint256 i = 0; i < length; ) {
            _sendProposal(interchainCalls[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Broadcast the proposal to be executed at single destination chain.
     * @param destinationChain destination chain
     * @param destinationContract destination contract
     * @param calls An array of calls to be executed at the destination chain. Where each call contains the following:
     * - target: target contract
     * - value: amount of tokens to send
     * - callData: encoded function arguments
     */
    function sendProposal(
        string memory destinationChain,
        string memory destinationContract,
        InterchainCalls.Call[] calldata calls
    ) external payable override {
        _sendProposal(InterchainCalls.InterchainCall(destinationChain, destinationContract, msg.value, calls));
    }

    function _sendProposal(InterchainCalls.InterchainCall memory interchainCall) internal {
        bytes memory payload = abi.encode(abi.encodePacked(msg.sender), interchainCall.calls);

        if (interchainCall.gas > 0) {
            gasService.payNativeGasForContractCall{ value: interchainCall.gas }(
                address(this),
                interchainCall.destinationChain,
                interchainCall.destinationContract,
                payload,
                msg.sender
            );
        }

        gateway.callContract(interchainCall.destinationChain, interchainCall.destinationContract, payload);
    }

    function revertIfInvalidFee(InterchainCalls.InterchainCall[] calldata interchainCalls) private {
        uint256 totalGas = 0;
        uint256 length = interchainCalls.length;

        for (uint256 i = 0; i < length; ) {
            totalGas += interchainCalls[i].gas;
            unchecked {
                ++i;
            }
        }

        if (totalGas != msg.value) {
            revert InvalidFee();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainCalls } from '../lib/InterchainCalls.sol';

interface IInterchainProposalSender {
    // An error emitted when the given gas is invalid
    error InvalidFee();

    // An error emitted when the given address is invalid
    error InvalidAddress();

    /**
     * @dev Broadcast the proposal to be executed at multiple destination chains
     * @param calls An array of calls to be executed at the destination chain
     */
    function sendProposals(InterchainCalls.InterchainCall[] memory calls) external payable;

    /**
     * @dev Broadcast the proposal to be executed at single destination chain
     * @param destinationChain destination chain
     * @param destinationContract destination contract
     * @param calls An array of calls to be executed at the destination chain
     */
    function sendProposal(
        string calldata destinationChain,
        string calldata destinationContract,
        InterchainCalls.Call[] calldata calls
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library InterchainCalls {
    /**
     * @dev An interchain call to be executed at the destination chain
     * @param destinationChain destination chain
     * @param destinationContract destination contract
     * @param gas The amount of native token to transfer to the target contract as gas payment for the interchain call
     * @param calls An array of calls to be executed at the destination chain
     */
    struct InterchainCall {
        string destinationChain;
        string destinationContract;
        uint256 gas;
        Call[] calls;
    }

    /**
     * @dev A call to be executed at the destination chain
     * @param target The address of the contract to call
     * @param value The amount of native token to transfer to the target contract
     * @param callData The data to pass to the target contract
     */
    struct Call {
        address target;
        uint256 value;
        bytes callData;
    }
}