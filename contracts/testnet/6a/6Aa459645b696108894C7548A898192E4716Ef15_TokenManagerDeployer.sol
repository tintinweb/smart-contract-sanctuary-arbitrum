// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ContractAddress } from '../utils/ContractAddress.sol';

error AlreadyDeployed();
error EmptyBytecode();
error DeployFailed();

/**
 * @title CreateDeployer Contract
 * @notice This contract deploys new contracts using the `CREATE` opcode and is used as part of
 * the `Create3` deployment method.
 */
contract CreateDeployer {
    /**
     * @dev Deploys a new contract with the specified bytecode using the CREATE opcode.
     * @param bytecode The bytecode of the contract to be deployed
     */
    function deploy(bytes memory bytecode) external {
        address deployed;

        assembly {
            deployed := create(0, add(bytecode, 32), mload(bytecode))
            if iszero(deployed) {
                revert(0, 0)
            }
        }
    }
}

/**
 * @title Create3 Library
 * @notice This library can be used to deploy a contract with a deterministic address that only
 * depends on the sender and salt, not the contract bytecode.
 */
library Create3 {
    using ContractAddress for address;

    bytes32 internal constant DEPLOYER_BYTECODE_HASH = keccak256(type(CreateDeployer).creationCode);

    /**
     * @dev Deploys a new contract using the CREATE3 method. This function first deploys the
     * CreateDeployer contract using the CREATE2 opcode and then utilizes the CreateDeployer
     * to deploy the new contract with the CREATE opcode.
     * @param salt A salt to further randomize the contract address
     * @param bytecode The bytecode of the contract to be deployed
     * @return deployed The address of the deployed contract
     */
    function deploy(bytes32 salt, bytes memory bytecode) internal returns (address deployed) {
        deployed = deployedAddress(address(this), salt);

        if (deployed.isContract()) revert AlreadyDeployed();
        if (bytecode.length == 0) revert EmptyBytecode();

        // Deploy using create2
        CreateDeployer deployer = new CreateDeployer{ salt: salt }();

        if (address(deployer) == address(0)) revert DeployFailed();

        deployer.deploy(bytecode);
    }

    /**
     * @dev Compute the deployed address that will result from the CREATE3 method.
     * @param salt A salt to further randomize the contract address
     * @param sender The sender address which would deploy the contract
     * @return deployed The deterministic contract address if it was deployed
     */
    function deployedAddress(address sender, bytes32 salt) internal pure returns (address deployed) {
        address deployer = address(
            uint160(uint256(keccak256(abi.encodePacked(hex'ff', sender, salt, DEPLOYER_BYTECODE_HASH))))
        );

        deployed = address(uint160(uint256(keccak256(abi.encodePacked(hex'd6_94', deployer, hex'01')))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3 } from './Create3.sol';

/**
 * @title Create3Deployer Contract
 * @notice This contract is responsible for deploying and initializing new contracts using the CREATE3 technique
 * which ensures that only the sender address and salt influence the deployed address, not the contract bytecode.
 */
contract Create3Deployer {
    error FailedInit();

    event Deployed(bytes32 indexed bytecodeHash, bytes32 indexed salt, address indexed deployedAddress);

    /**
     * @dev Deploys a contract using `CREATE3`. The address where the contract
     * will be deployed can be known in advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must not have been used already by the same `msg.sender`.
     */
    function deploy(bytes calldata bytecode, bytes32 salt) external returns (address deployedAddress_) {
        bytes32 deploySalt = keccak256(abi.encode(msg.sender, salt));
        deployedAddress_ = Create3.deploy(deploySalt, bytecode);

        emit Deployed(keccak256(bytecode), salt, deployedAddress_);
    }

    /**
     * @dev Deploys a contract using `CREATE3` and initialize it. The address where the contract
     * will be deployed can be known in advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must not have been used already by the same `msg.sender`.
     * - `init` is used to initialize the deployed contract
     */
    function deployAndInit(
        bytes memory bytecode,
        bytes32 salt,
        bytes calldata init
    ) external returns (address deployedAddress_) {
        bytes32 deploySalt = keccak256(abi.encode(msg.sender, salt));
        deployedAddress_ = Create3.deploy(deploySalt, bytecode);

        (bool success, ) = deployedAddress_.call(init);
        if (!success) revert FailedInit();

        emit Deployed(keccak256(bytecode), salt, deployedAddress_);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} or {deployAndInit} by `sender`.
     * Any change in `sender` or `salt` will result in a new destination address.
     */
    function deployedAddress(address sender, bytes32 salt) external view returns (address) {
        bytes32 deploySalt = keccak256(abi.encode(sender, salt));
        return Create3.deployedAddress(address(this), deploySalt);
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

library ContractAddress {
    function isContract(address _address) internal view returns (bool) {
        bytes32 existingCodeHash = _address.codehash;

        // https://eips.ethereum.org/EIPS/eip-1052
        // keccak256('') == 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
        return
            existingCodeHash != bytes32(0) &&
            existingCodeHash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExpressCallHandler {
    error AlreadyExpressCalled();
    error SameDestinationAsCaller();

    event ExpressReceive(
        bytes32 indexed tokenId,
        address indexed destinationAddress,
        uint256 amount,
        bytes32 indexed sendHash,
        address expressCaller
    );
    event ExpressExecutionFulfilled(
        bytes32 indexed tokenId,
        address indexed destinationAddress,
        uint256 amount,
        bytes32 indexed sendHash,
        address expressCaller
    );

    event ExpressReceiveWithData(
        bytes32 indexed tokenId,
        string sourceChain,
        bytes sourceAddress,
        address indexed destinationAddress,
        uint256 amount,
        bytes data,
        bytes32 indexed sendHash,
        address expressCaller
    );
    event ExpressExecutionWithDataFulfilled(
        bytes32 indexed tokenId,
        string sourceChain,
        bytes sourceAddress,
        address indexed destinationAddress,
        uint256 amount,
        bytes data,
        bytes32 indexed sendHash,
        address expressCaller
    );

    /**
     * @notice Gets the address of the express caller for a specific token transfer
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function getExpressReceiveToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId
    ) external view returns (address expressCaller);

    /**
     * @notice Gets the address of the express caller for a specific token transfer with data
     * @param tokenId The ID of the token being sent
     * @param sourceChain The chain from which the token will be sent
     * @param sourceAddress The originating address of the token on the source chain
     * @param destinationAddress The address of the recipient on the destination chain
     * @param amount The amount of tokens to be sent
     * @param data The data associated with the token transfer
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function getExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 commandId
    ) external view returns (address expressCaller);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol';

import { IExpressCallHandler } from './IExpressCallHandler.sol';
import { ITokenManagerDeployer } from './ITokenManagerDeployer.sol';
import { ITokenManagerType } from './ITokenManagerType.sol';
import { IPausable } from './IPausable.sol';
import { IMulticall } from './IMulticall.sol';

interface IInterchainTokenService is ITokenManagerType, IExpressCallHandler, IAxelarExecutable, IPausable, IMulticall {
    // more generic error
    error ZeroAddress();
    error LengthMismatch();
    error InvalidTokenManagerImplementation();
    error NotRemoteService();
    error TokenManagerDoesNotExist(bytes32 tokenId);
    error NotTokenManager();
    error ExecuteWithInterchainTokenFailed(address contractAddress);
    error NotCanonicalTokenManager();
    error GatewayToken();
    error TokenManagerDeploymentFailed();
    error StandardizedTokenDeploymentFailed();
    error DoesNotAcceptExpressExecute(address contractAddress);
    error SelectorUnknown();
    error InvalidMetadataVersion(uint32 version);
    error AlreadyExecuted(bytes32 commandId);

    event TokenSent(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 indexed amount);
    event TokenSentWithData(
        bytes32 tokenId,
        string destinationChain,
        bytes destinationAddress,
        uint256 indexed amount,
        address indexed sourceAddress,
        bytes data
    );
    event TokenReceived(bytes32 indexed tokenId, string sourceChain, address indexed destinationAddress, uint256 indexed amount);
    event TokenReceivedWithData(
        bytes32 indexed tokenId,
        string sourceChain,
        address indexed destinationAddress,
        uint256 indexed amount,
        bytes sourceAddress,
        bytes data
    );
    event RemoteTokenManagerDeploymentInitialized(
        bytes32 indexed tokenId,
        string destinationChain,
        uint256 indexed gasValue,
        TokenManagerType indexed tokenManagerType,
        bytes params
    );
    event RemoteStandardizedTokenAndManagerDeploymentInitialized(
        bytes32 indexed tokenId,
        string tokenName,
        string tokenSymbol,
        uint8 tokenDecimals,
        bytes distributor,
        bytes indexed operator,
        string destinationChain,
        uint256 indexed gasValue
    );
    event TokenManagerDeployed(bytes32 indexed tokenId, TokenManagerType indexed tokenManagerType, bytes params);
    event StandardizedTokenDeployed(
        bytes32 indexed tokenId,
        string name,
        string symbol,
        uint8 decimals,
        uint256 mintAmount,
        address mintTo
    );
    event CustomTokenIdClaimed(bytes32 indexed tokenId, address indexed deployer, bytes32 indexed salt);

    /**
     * @notice Returns the address of the token manager deployer contract.
     * @return tokenManagerDeployerAddress The address of the token manager deployer contract.
     */
    function tokenManagerDeployer() external view returns (address tokenManagerDeployerAddress);

    /**
     * @notice Returns the address of the standardized token deployer contract.
     * @return standardizedTokenDeployerAddress The address of the standardized token deployer contract.
     */
    function standardizedTokenDeployer() external view returns (address standardizedTokenDeployerAddress);

    /**
     * @notice Returns the name of the current chain.
     * @return name The name of the current chain.
     */
    function getChainName() external view returns (string memory name);

    /**
     * @notice Returns the address of the token manager associated with the given tokenId.
     * @param tokenId The tokenId of the token manager.
     * @return tokenManagerAddress The address of the token manager.
     */
    function getTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress);

    /**
     * @notice Returns the address of the valid token manager associated with the given tokenId.
     * @param tokenId The tokenId of the token manager.
     * @return tokenManagerAddress The address of the valid token manager.
     */
    function getValidTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress);

    /**
     * @notice Returns the address of the token associated with the given tokenId.
     * @param tokenId The tokenId of the token manager.
     * @return tokenAddress The address of the token.
     */
    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    /**
     * @notice Returns the address of the standardized token associated with the given tokenId.
     * @param tokenId The tokenId of the standardized token.
     * @return tokenAddress The address of the standardized token.
     */
    function getStandardizedTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    /**
     * @notice Returns the canonical tokenId associated with the given tokenAddress.
     * @param tokenAddress The address of the token.
     * @return tokenId The canonical tokenId associated with the tokenAddress.
     */
    function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    /**
     * @notice Returns the custom tokenId associated with the given operator and salt.
     * @param operator The operator address.
     * @param salt The salt used for token id calculation.
     * @return tokenId The custom tokenId associated with the operator and salt.
     */
    function getCustomTokenId(address operator, bytes32 salt) external view returns (bytes32 tokenId);

    /**
     * @notice Returns the parameters for the lock/unlock operation.
     * @param operator The operator address.
     * @param tokenAddress The address of the token.
     * @return params The parameters for the lock/unlock operation.
     */
    function getParamsLockUnlock(bytes memory operator, address tokenAddress) external pure returns (bytes memory params);

    /**
     * @notice Returns the parameters for the mint/burn operation.
     * @param operator The operator address.
     * @param tokenAddress The address of the token.
     * @return params The parameters for the mint/burn operation.
     */
    function getParamsMintBurn(bytes memory operator, address tokenAddress) external pure returns (bytes memory params);

    /**
     * @notice Returns the parameters for the liquidity pool operation.
     * @param operator The operator address.
     * @param tokenAddress The address of the token.
     * @param liquidityPoolAddress The address of the liquidity pool.
     * @return params The parameters for the liquidity pool operation.
     */
    function getParamsLiquidityPool(
        bytes memory operator,
        address tokenAddress,
        address liquidityPoolAddress
    ) external pure returns (bytes memory params);

    /**
     * @notice Registers a canonical token and returns its associated tokenId.
     * @param tokenAddress The address of the canonical token.
     * @return tokenId The tokenId associated with the registered canonical token.
     */
    function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId);

    /**
     * @notice Deploys a standardized canonical token on a remote chain.
     * @param tokenId The tokenId of the canonical token.
     * @param destinationChain The name of the destination chain.
     * @param gasValue The gas value for deployment.
     */
    function deployRemoteCanonicalToken(bytes32 tokenId, string calldata destinationChain, uint256 gasValue) external payable;

    /**
     * @notice Deploys a custom token manager contract.
     * @param salt The salt used for token manager deployment.
     * @param tokenManagerType The type of token manager.
     * @param params The deployment parameters.
     * @return tokenId The tokenId of the deployed token manager.
     */
    function deployCustomTokenManager(
        bytes32 salt,
        TokenManagerType tokenManagerType,
        bytes memory params
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Deploys a custom token manager contract on a remote chain.
     * @param salt The salt used for token manager deployment.
     * @param destinationChain The name of the destination chain.
     * @param tokenManagerType The type of token manager.
     * @param params The deployment parameters.
     * @param gasValue The gas value for deployment.
     */
    function deployRemoteCustomTokenManager(
        bytes32 salt,
        string calldata destinationChain,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Deploys a standardized token and registers it. The token manager type will be lock/unlock unless the distributor matches its address, in which case it will be a mint/burn one.
     * @param salt The salt used for token deployment.
     * @param name The name of the standardized token.
     * @param symbol The symbol of the standardized token.
     * @param decimals The number of decimals for the standardized token.
     * @param mintAmount The amount of tokens to mint to the deployer.
     * @param distributor The address of the distributor for mint/burn operations.
     */
    function deployAndRegisterStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) external payable;

    /**
     * @notice Deploys and registers a standardized token on a remote chain.
     * @param salt The salt used for token deployment.
     * @param name The name of the standardized tokens.
     * @param symbol The symbol of the standardized tokens.
     * @param decimals The number of decimals for the standardized tokens.
     * @param distributor The distributor data for mint/burn operations.
     * @param operator The operator data for standardized tokens.
     * @param destinationChain The name of the destination chain.
     * @param gasValue The gas value for deployment.
     */
    function deployAndRegisterRemoteStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory operator,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable;

    /**
     * @notice Returns the implementation address for a given token manager type.
     * @param tokenManagerType The type of token manager.
     * @return tokenManagerAddress The address of the token manager implementation.
     */
    function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress);

    /**
     * @notice Initiates an interchain token transfer. Only callable by TokenManagers
     * @param tokenId The tokenId of the token to be transmitted.
     * @param sourceAddress The source address of the token.
     * @param destinationChain The name of the destination chain.
     * @param destinationAddress The destination address on the destination chain.
     * @param amount The amount of tokens to transmit.
     * @param metadata The metadata associated with the transmission.
     */
    function transmitSendToken(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice Sets the flow limits for multiple tokens.
     * @param tokenIds An array of tokenIds.
     * @param flowLimits An array of flow limits corresponding to the tokenIds.
     */
    function setFlowLimit(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external;

    /**
     * @notice Returns the flow limit for a specific token.
     * @param tokenId The tokenId of the token.
     * @return flowLimit The flow limit for the token.
     */
    function getFlowLimit(bytes32 tokenId) external view returns (uint256 flowLimit);

    /**
     * @notice Returns the total amount of outgoing flow for a specific token.
     * @param tokenId The tokenId of the token.
     * @return flowOutAmount The total amount of outgoing flow for the token.
     */
    function getFlowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount);

    /**
     * @notice Returns the total amount of incoming flow for a specific token.
     * @param tokenId The tokenId of the token.
     * @return flowInAmount The total amount of incoming flow for the token.
     */
    function getFlowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount);

    /**
     * @notice Sets the paused state of the contract.
     * @param paused The boolean value indicating whether the contract is paused or not.
     */
    function setPaused(bool paused) external;

    /**
     * @notice Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.
     * @param tokenId the tokenId of the TokenManager used.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param commandId the commandId calculated from the event at the sourceChain.
     */
    function expressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) external;

    /**
     * @notice Uses the caller's tokens to fullfill a callContractWithInterchainToken ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.
     * @param tokenId the tokenId of the TokenManager used.
     * @param sourceChain the name of the chain where the call came from.
     * @param sourceAddress the caller of callContractWithInterchainToken.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param data the data to be passed to destinationAddress after giving them the tokens specified.
     * @param commandId the commandId calculated from the event at the sourceChain.
     */
    function expressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 commandId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IMulticall
 * @notice This contract is a multi-functional smart contract which allows for multiple
 * contract calls in a single transaction.
 */
interface IMulticall {
    /**
     * @notice Performs multiple delegate calls and returns the results of all calls as an array
     * @dev This function requires that the contract has sufficient balance for the delegate calls.
     * If any of the calls fail, the function will revert with the failure message.
     * @param data An array of encoded function calls
     * @return results An bytes array with the return data of each function call
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Pausable
 * @notice This contract provides a mechanism to halt the execution of specific functions
 * if a pause condition is activated.
 */
interface IPausable {
    event PausedSet(bool paused);

    error Paused();

    /**
     * @notice Check if the contract is paused
     * @return paused A boolean representing the pause status. True if paused, false otherwise.
     */
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

/**
 * @title ITokenManagerDeployer
 * @notice This contract is used to deploy new instances of the TokenManagerProxy contract.
 */
interface ITokenManagerDeployer {
    error AddressZero();
    error TokenManagerDeploymentFailed();

    /**
     * @notice Getter for the Create3Deployer.
     */
    function deployer() external view returns (Create3Deployer);

    /**
     * @notice Deploys a new instance of the TokenManagerProxy contract
     * @param tokenId The unique identifier for the token
     * @param implementationType Token manager implementation type
     * @param params Additional parameters used in the setup of the token manager
     */
    function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes calldata params) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title TokenManagerProxy
 * @dev This contract is a proxy for token manager contracts. It implements ITokenManagerProxy and
 * inherits from FixedProxy from the gmp sdk repo
 */
interface ITokenManagerProxy {
    error ImplementationLookupFailed();
    error SetupFailed();

    /**
     * @notice Returns implementation type of this token manager
     */
    function implementationType() external view returns (uint256);

    /**
     * @notice Returns the address of the current implementation.
     * @return impl The address of the current implementation
     */
    function implementation() external view returns (address);

    /**
     * @notice Returns token ID of the token manager.
     */
    function tokenId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenManagerType
 * @notice A simple interface that defines all the token manager types
 */
interface ITokenManagerType {
    enum TokenManagerType {
        LOCK_UNLOCK,
        MINT_BURN,
        LIQUIDITY_POOL
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';

/**
 * @title TokenManagerProxy
 * @dev This contract is a proxy for token manager contracts. It implements ITokenManagerProxy and
 * inherits from FixedProxy from the gmp sdk repo
 */
contract TokenManagerProxy is ITokenManagerProxy {
    IInterchainTokenService public immutable interchainTokenServiceAddress;
    uint256 public immutable implementationType;
    bytes32 public immutable tokenId;

    /**
     * @dev Constructs the TokenManagerProxy contract.
     * @param interchainTokenServiceAddress_ The address of the interchain token service
     * @param implementationType_ The token manager type
     * @param tokenId_ The identifier for the token
     * @param params The initialization parameters for the token manager contract
     */
    constructor(address interchainTokenServiceAddress_, uint256 implementationType_, bytes32 tokenId_, bytes memory params) {
        interchainTokenServiceAddress = IInterchainTokenService(interchainTokenServiceAddress_);
        implementationType = implementationType_;
        tokenId = tokenId_;
        address impl = _getImplementation(IInterchainTokenService(interchainTokenServiceAddress_), implementationType_);

        (bool success, ) = impl.delegatecall(abi.encodeWithSelector(TokenManagerProxy.setup.selector, params));
        if (!success) revert SetupFailed();
    }

    /**
     * @dev Returns the address of the current implementation.
     * @return impl The address of the current implementation
     */
    function implementation() public view returns (address impl) {
        impl = _getImplementation(interchainTokenServiceAddress, implementationType);
    }

    /**
     * @dev Returns the implementation address from the interchain token service for the provided type.
     * @param interchainTokenServiceAddress_ The address of the interchain token service
     * @param implementationType_ The token manager type
     * @return impl The address of the implementation
     */
    function _getImplementation(
        IInterchainTokenService interchainTokenServiceAddress_,
        uint256 implementationType_
    ) internal view returns (address impl) {
        impl = interchainTokenServiceAddress_.getImplementation(implementationType_);
    }

    /**
     * @dev Setup function. Empty in this contract.
     * @param setupParams Initialization parameters
     */
    function setup(bytes calldata setupParams) external {}

    /**
     * @dev Fallback function. Delegates the call to the token manager contract.
     */
    // solhint-disable-next-line no-complex-fallback
    fallback() external payable virtual {
        address implementaion_ = implementation();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementaion_, 0, calldatasize(), 0, 0)
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
     * @dev Receive function which allows this contract to receive ether.
     */
    receive() external payable virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { ITokenManagerDeployer } from '../interfaces/ITokenManagerDeployer.sol';

import { TokenManagerProxy } from '../proxies/TokenManagerProxy.sol';

/**
 * @title TokenManagerDeployer
 * @notice This contract is used to deploy new instances of the TokenManagerProxy contract.
 */
contract TokenManagerDeployer is ITokenManagerDeployer {
    Create3Deployer public immutable deployer;

    /**
     * @notice Constructor for the TokenManagerDeployer contract
     * @param deployer_ Address of the Create3Deployer contract
     */
    constructor(address deployer_) {
        if (deployer_ == address(0)) revert AddressZero();
        deployer = Create3Deployer(deployer_);
    }

    /**
     * @notice Deploys a new instance of the TokenManagerProxy contract
     * @param tokenId The unique identifier for the token
     * @param implementationType Token manager implementation type
     * @param params Additional parameters used in the setup of the token manager
     */
    function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes calldata params) external payable {
        bytes memory args = abi.encode(address(this), implementationType, tokenId, params);
        bytes memory bytecode = abi.encodePacked(type(TokenManagerProxy).creationCode, args);
        address tokenManagerAddress = deployer.deploy(bytecode, tokenId);
        if (tokenManagerAddress.code.length == 0) revert TokenManagerDeploymentFailed();
    }
}