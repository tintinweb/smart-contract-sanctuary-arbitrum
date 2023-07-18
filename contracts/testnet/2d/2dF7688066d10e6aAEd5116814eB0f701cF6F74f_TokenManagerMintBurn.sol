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

import { IERC20 } from '../interfaces/IERC20.sol';

error TokenTransferFailed();
error NativeTransferFailed();

library SafeTokenCall {
    function safeCall(IERC20 token, bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(token).call(callData);
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || address(token).code.length == 0) revert TokenTransferFailed();
    }
}

library SafeTokenTransfer {
    function safeTransfer(
        IERC20 token,
        address receiver,
        uint256 amount
    ) internal {
        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20.transfer.selector, receiver, amount));
    }
}

library SafeTokenTransferFrom {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
    }
}

library SafeNativeTransfer {
    function safeNativeTransfer(address receiver, uint256 amount) internal {
        bool success;

        assembly {
            success := call(gas(), receiver, amount, 0, 0, 0, 0)
        }

        if (!success) revert NativeTransferFailed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableMintable is IERC20 {
    /**
     * @notice Function to mint new tokens
     * Can only be called by the distributor address.
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Function to burn tokens
     * Can only be called by the distributor address.
     * @param from The address that will have its tokens burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;
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

interface IFlowLimit {
    error FlowLimitExceeded();

    event FlowLimitSet(uint256 flowLimit);

    /**
     * @notice Returns the current flow limit
     * @return flowLimit The current flow limit value
     */
    function getFlowLimit() external view returns (uint256 flowLimit);

    /**
     * @notice Returns the current flow out amount
     * @return flowOutAmount The current flow out amount
     */
    function getFlowOutAmount() external view returns (uint256 flowOutAmount);

    /**
     * @notice Returns the current flow in amount
     * @return flowInAmount The current flow in amount
     */
    function getFlowInAmount() external view returns (uint256 flowInAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IImplementation {
    error NotProxy();
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

interface IOperatable {
    error NotOperator();

    event OperatorChanged(address operator);

    /**
     * @notice Get the address of the operator
     * @return operator_ of the operator
     */
    function operator() external view returns (address operator_);

    /**
     * @notice Change the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function setOperator(address operator_) external;
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

import { ITokenManagerType } from './ITokenManagerType.sol';
import { IOperatable } from './IOperatable.sol';
import { IFlowLimit } from './IFlowLimit.sol';
import { IImplementation } from './IImplementation.sol';

/**
 * @title ITokenManager
 * @notice This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.
 */
interface ITokenManager is ITokenManagerType, IOperatable, IFlowLimit, IImplementation {
    error TokenLinkerZeroAddress();
    error NotService();
    error TakeTokenFailed();
    error GiveTokenFailed();
    error NotToken();

    /**
     * @notice A function that should return the address of the token.
     * Must be overridden in the inheriting contract.
     * @return address address of the token.
     */
    function tokenAddress() external view returns (address);

    /**
     * @notice A function that should return the implementation type of the token manager.
     */
    function implementationType() external pure returns (uint256);

    /**
     * @notice Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     */
    function sendToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice Calls the service to initiate the a cross-chain transfer with data after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     * @param data the data to pass to the destination contract.
     */
    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable;

    /**
     * @notice Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
     * @param sender the address of the user paying for the cross chain transfer.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     */
    function transmitInterchainTransfer(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice This function gives token to a specified address. Can only be called by the service.
     * @param destinationAddress the address to give tokens to.
     * @param amount the amount of token to give.
     * @return the amount of token actually given, which will onle be differen than `amount` in cases where the token takes some on-transfer fee.
     */
    function giveToken(address destinationAddress, uint256 amount) external returns (uint256);

    /**
     * @notice This function sets the flow limit for this TokenManager. Can only be called by the operator.
     * @param flowLimit the maximum difference between the tokens flowing in and/or out at any given interval of time (6h)
     */
    function setFlowLimit(uint256 flowLimit) external;
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

/**
 * @title AddressBytesUtils
 * @dev This library provides utility functions to convert between `address` and `bytes`.
 */
library AddressBytesUtils {
    error InvalidBytesLength(bytes bytesAddress);

    /**
     * @dev Converts a bytes address to an address type.
     * @param bytesAddress The bytes representation of an address
     * @return addr The converted address
     */
    function toAddress(bytes memory bytesAddress) internal pure returns (address addr) {
        if (bytesAddress.length != 20) revert InvalidBytesLength(bytesAddress);

        assembly {
            addr := mload(add(bytesAddress, 20))
        }
    }

    /**
     * @dev Converts an address to bytes.
     * @param addr The address to be converted
     * @return bytesAddress The bytes representation of the address
     */
    function toBytes(address addr) internal pure returns (bytes memory bytesAddress) {
        bytesAddress = new bytes(20);

        assembly {
            mstore(add(bytesAddress, 20), addr)
            mstore(bytesAddress, 20)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenManager } from '../TokenManager.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';

/**
 * @title TokenManagerAddressStorage
 * @notice This contract extends the TokenManager contract and provides additional functionality to store and retrieve
 * the token address using a predetermined storage slot
 */
abstract contract TokenManagerAddressStorage is TokenManager {
    /**
     * @dev Creates an instance of the TokenManagerAddressStorage contract.
     * @param interchainTokenService_ The address of the interchain token service contract
     */
    constructor(address interchainTokenService_) TokenManager(interchainTokenService_) {}

    // uint256(keccak256('token-address')) - 1
    uint256 internal constant TOKEN_ADDRESS_SLOT = 0xc4e632779a6a7838736dd7e5e6a0eadf171dd37dfb6230720e265576dfcf42ba;

    /**
     * @dev Reads the stored token address from the predetermined storage slot
     * @return tokenAddress_ The address of the token
     */
    function tokenAddress() public view override returns (address tokenAddress_) {
        assembly {
            tokenAddress_ := sload(TOKEN_ADDRESS_SLOT)
        }
    }

    /**
     * @dev Stores the token address in the predetermined storage slot
     * @param tokenAddress_ The address of the token to store
     */
    function _setTokenAddress(address tokenAddress_) internal {
        assembly {
            sstore(TOKEN_ADDRESS_SLOT, tokenAddress_)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenManagerAddressStorage } from './TokenManagerAddressStorage.sol';
import { IERC20BurnableMintable } from '../../interfaces/IERC20BurnableMintable.sol';

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';

/**
 * @title TokenManagerMintBurn
 * @notice This contract is an implementation of TokenManager that mints and burns a specific token on behalf of the interchain token service.
 * @dev This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
 * It uses the Axelar SDK to safely transfer tokens.
 */
contract TokenManagerMintBurn is TokenManagerAddressStorage {
    /**
     * @dev Constructs an instance of TokenManagerMintBurn. Calls the constructor
     * of TokenManagerAddressStorage which calls the constructor of TokenManager.
     * @param interchainTokenService_ The address of the interchain token service contract
     */
    constructor(address interchainTokenService_) TokenManagerAddressStorage(interchainTokenService_) {}

    function implementationType() external pure returns (uint256) {
        return 1;
    }

    /**
     * @dev Sets up the token address.
     * @param params The setup parameters in bytes. Should be encoded with the token address.
     */
    function _setup(bytes calldata params) internal override {
        // The first argument is reserved for the operator.
        (, address tokenAddress) = abi.decode(params, (bytes, address));
        _setTokenAddress(tokenAddress);
    }

    /**
     * @dev Burns the specified amount of tokens from a particular address.
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     * @return uint Amount of tokens burned
     */
    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());

        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20BurnableMintable.burn.selector, from, amount));

        return amount;
    }

    /**
     * @dev Mints the specified amount of tokens to a particular address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     * @return uint Amount of tokens minted
     */
    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());

        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20BurnableMintable.mint.selector, to, amount));

        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';

import { Operatable } from '../utils/Operatable.sol';
import { FlowLimit } from '../utils/FlowLimit.sol';
import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { Implementation } from '../utils/Implementation.sol';

/**
 * @title The main functionality of TokenManagers.
 * @notice This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.
 */
abstract contract TokenManager is ITokenManager, Operatable, FlowLimit, Implementation {
    using AddressBytesUtils for bytes;

    IInterchainTokenService public immutable interchainTokenService;

    /**
     * @notice Constructs the TokenManager contract.
     * @param interchainTokenService_ The address of the interchain token service
     */
    constructor(address interchainTokenService_) {
        if (interchainTokenService_ == address(0)) revert TokenLinkerZeroAddress();
        interchainTokenService = IInterchainTokenService(interchainTokenService_);
    }

    /**
     * @dev A modifier that allows only the interchain token service to execute the function.
     */
    modifier onlyService() {
        if (msg.sender != address(interchainTokenService)) revert NotService();
        _;
    }

    /**
     * @dev A modifier that allows only the token to execute the function.
     */
    modifier onlyToken() {
        if (msg.sender != tokenAddress()) revert NotToken();
        _;
    }

    /**
     * @notice A function that should return the address of the token.
     * Must be overridden in the inheriting contract.
     * @return address address of the token.
     */
    function tokenAddress() public view virtual returns (address);

    /**
     * @dev This function should only be called by the proxy, and only once from the proxy constructor
     * @param params the parameters to be used to initialize the TokenManager. The exact format depends
     * on the type of TokenManager used but the first 32 bytes are reserved for the address of the operator,
     * stored as bytes (to be compatible with non-EVM chains)
     */
    function setup(bytes calldata params) external override onlyProxy {
        bytes memory operatorBytes = abi.decode(params, (bytes));
        address operator_;
        /**
         * @dev Specifying an empty operator will default to the service being the operator. This makes it easy to deploy
         * remote standardized tokens without knowing anything about the service address at the destination.
         */
        if (operatorBytes.length == 0) {
            operator_ = address(interchainTokenService);
        } else {
            operator_ = operatorBytes.toAddress();
        }
        _setOperator(operator_);
        _setup(params);
    }

    /**
     * @notice Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     */
    function sendToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable virtual {
        address sender = msg.sender;
        amount = _takeToken(sender, amount);
        _addFlowOut(amount);
        interchainTokenService.transmitSendToken{ value: msg.value }(
            _getTokenId(),
            sender,
            destinationChain,
            destinationAddress,
            amount,
            metadata
        );
    }

    /**
     * @notice Calls the service to initiate the a cross-chain transfer with data after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     * @param data the data to pass to the destination contract.
     */
    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable virtual {
        address sender = msg.sender;
        amount = _takeToken(sender, amount);
        _addFlowOut(amount);
        uint32 version = 0;
        interchainTokenService.transmitSendToken{ value: msg.value }(
            _getTokenId(),
            sender,
            destinationChain,
            destinationAddress,
            amount,
            abi.encodePacked(version, data)
        );
    }

    /**
     * @notice Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
     * @param sender the address of the user paying for the cross chain transfer.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     */
    function transmitInterchainTransfer(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable virtual onlyToken {
        amount = _takeToken(sender, amount);
        _addFlowOut(amount);
        interchainTokenService.transmitSendToken{ value: msg.value }(
            _getTokenId(),
            sender,
            destinationChain,
            destinationAddress,
            amount,
            metadata
        );
    }

    /**
     * @notice This function gives token to a specified address. Can only be called by the service.
     * @param destinationAddress the address to give tokens to.
     * @param amount the amount of token to give.
     * @return the amount of token actually given, which will onle be differen than `amount` in cases where the token takes some on-transfer fee.
     */
    function giveToken(address destinationAddress, uint256 amount) external onlyService returns (uint256) {
        amount = _giveToken(destinationAddress, amount);
        _addFlowIn(amount);
        return amount;
    }

    /**
     * @notice This function sets the flow limit for this TokenManager. Can only be called by the operator.
     * @param flowLimit the maximum difference between the tokens flowing in and/or out at any given interval of time (6h)
     */
    function setFlowLimit(uint256 flowLimit) external onlyOperator {
        _setFlowLimit(flowLimit);
    }

    /**
     * @notice Transfers tokens from a specific address to this contract.
     * Must be overridden in the inheriting contract.
     * @param from The address from which the tokens will be sent
     * @param amount The amount of tokens to receive
     * @return uint amount of tokens received
     */
    function _takeToken(address from, uint256 amount) internal virtual returns (uint256);

    /**
     * @notice Transfers tokens from this contract to a specific address.
     * Must be overridden in the inheriting contract.
     * @param from The address to which the tokens will be sent
     * @param amount The amount of tokens to send
     * @return uint amount of tokens sent
     */
    function _giveToken(address from, uint256 amount) internal virtual returns (uint256);

    /**
     * @dev Additional setup logic to perform
     * Must be overridden in the inheriting contract.
     * @param params The setup parameters
     */
    function _setup(bytes calldata params) internal virtual;

    /**
     * @notice Gets the token ID from the token manager proxy.
     * @return tokenId The ID of the token
     */
    function _getTokenId() internal view returns (bytes32 tokenId) {
        tokenId = ITokenManagerProxy(address(this)).tokenId();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IFlowLimit } from '../interfaces/IFlowLimit.sol';

/**
 * @title FlowLimit
 * @notice Implements flow limit logic for interchain token transfers.
 * @dev This contract implements low-level assembly for optimization purposes.
 */
contract FlowLimit is IFlowLimit {
    // uint256(keccak256('flow-limit')) - 1
    uint256 internal constant FLOW_LIMIT_SLOT = 0x201b7a0b7c19aaddc4ce9579b7df8d2db123805861bc7763627f13e04d8af42f;
    uint256 internal constant PREFIX_FLOW_OUT_AMOUNT = uint256(keccak256('prefix-flow-out-amount'));
    uint256 internal constant PREFIX_FLOW_IN_AMOUNT = uint256(keccak256('prefix-flow-in-amount'));

    uint256 internal constant EPOCH_TIME = 6 hours;

    /**
     * @notice Returns the current flow limit
     * @return flowLimit The current flow limit value
     */
    function getFlowLimit() public view returns (uint256 flowLimit) {
        assembly {
            flowLimit := sload(FLOW_LIMIT_SLOT)
        }
    }

    /**
     * @dev Internal function to set the flow limit
     * @param flowLimit The value to set the flow limit to
     */
    function _setFlowLimit(uint256 flowLimit) internal {
        assembly {
            sstore(FLOW_LIMIT_SLOT, flowLimit)
        }
        emit FlowLimitSet(flowLimit);
    }

    /**
     * @dev Returns the slot which is used to get the flow out amount for a specific epoch
     * @param epoch The epoch to get the flow out amount for
     * @return slot The slot to get the flow out amount from
     */
    function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_OUT_AMOUNT, epoch)));
    }

    /**
     * @dev Returns the slot which is used to get the flow in amount for a specific epoch
     * @param epoch The epoch to get the flow in amount for
     * @return slot The slot to get the flow in amount from
     */
    function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_IN_AMOUNT, epoch)));
    }

    /**
     * @notice Returns the current flow out amount
     * @return flowOutAmount The current flow out amount
     */
    function getFlowOutAmount() external view returns (uint256 flowOutAmount) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowOutSlot(epoch);
        assembly {
            flowOutAmount := sload(slot)
        }
    }

    /**
     * @notice Returns the current flow in amount
     * @return flowInAmount The current flow in amount
     */
    function getFlowInAmount() external view returns (uint256 flowInAmount) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowInSlot(epoch);
        assembly {
            flowInAmount := sload(slot)
        }
    }

    /**
     * @dev Adds a flow amount while ensuring it does not exceed the flow limit
     * @param slotToAdd The slot to add the flow to
     * @param slotToCompare The slot to compare the flow against
     * @param flowAmount The flow amount to add
     */
    function _addFlow(uint256 flowLimit, uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal {
        uint256 flowToAdd;
        uint256 flowToCompare;
        assembly {
            flowToAdd := sload(slotToAdd)
            flowToCompare := sload(slotToCompare)
        }
        if (flowToAdd + flowAmount > flowToCompare + flowLimit) revert FlowLimitExceeded();
        assembly {
            sstore(slotToAdd, add(flowToAdd, flowAmount))
        }
    }

    /**
     * @dev Adds a flow out amount
     * @param flowOutAmount The flow out amount to add
     */
    function _addFlowOut(uint256 flowOutAmount) internal {
        uint256 flowLimit = getFlowLimit();
        if (flowLimit == 0) return;
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowOutSlot(epoch);
        uint256 slotToCompare = _getFlowInSlot(epoch);
        _addFlow(flowLimit, slotToAdd, slotToCompare, flowOutAmount);
    }

    /**
     * @dev Adds a flow in amount
     * @param flowInAmount The flow in amount to add
     */
    function _addFlowIn(uint256 flowInAmount) internal {
        uint256 flowLimit = getFlowLimit();
        if (flowLimit == 0) return;
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowInSlot(epoch);
        uint256 slotToCompare = _getFlowOutSlot(epoch);
        _addFlow(flowLimit, slotToAdd, slotToCompare, flowInAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IImplementation } from '../interfaces/IImplementation.sol';

/**
 * @title Implementation
 * @notice This contract serves as a base for other contracts and enforces a proxy-first access restriction.
 * @dev Derived contracts must implement the setup function.
 */
abstract contract Implementation is IImplementation {
    address private immutable implementationAddress;

    /**
     * @dev Contract constructor that sets the implementation address to the address of this contract.
     */
    constructor() {
        implementationAddress = address(this);
    }

    /**
     * @dev Modifier to require the caller to be the proxy contract.
     * Reverts if the caller is the current contract (i.e., the implementation contract itself).
     */
    modifier onlyProxy() {
        if (implementationAddress == address(this)) revert NotProxy();
        _;
    }

    /**
     * @notice Initializes contract parameters.
     * This function is intended to be overridden by derived contracts.
     * The overriding function must have the onlyProxy modifier.
     * @param params The parameters to be used for initialization
     */
    function setup(bytes calldata params) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOperatable } from '../interfaces/IOperatable.sol';

/**
 * @title Operatable Contract
 * @dev A contract module which provides a basic access control mechanism, where
 * there is an account (an operator) that can be granted exclusive access to
 * specific functions. This module is used through inheritance.
 */
contract Operatable is IOperatable {
    // uint256(keccak256('operator')) - 1
    uint256 internal constant OPERATOR_SLOT = 0xf23ec0bb4210edd5cba85afd05127efcd2fc6a781bfed49188da1081670b22d7;

    /**
     * @dev Throws a NotOperator custom error if called by any account other than the operator.
     */
    modifier onlyOperator() {
        if (operator() != msg.sender) revert NotOperator();
        _;
    }

    /**
     * @notice Get the address of the operator
     * @return operator_ of the operator
     */
    function operator() public view returns (address operator_) {
        assembly {
            operator_ := sload(OPERATOR_SLOT)
        }
    }

    /**
     * @dev Internal function that stores the new operator address in the operator storage slot
     * @param operator_ The address of the new operator
     */
    function _setOperator(address operator_) internal {
        assembly {
            sstore(OPERATOR_SLOT, operator_)
        }
        emit OperatorChanged(operator_);
    }

    /**
     * @notice Change the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function setOperator(address operator_) external onlyOperator {
        _setOperator(operator_);
    }
}