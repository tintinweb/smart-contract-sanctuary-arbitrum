// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDeploy } from '../interfaces/IDeploy.sol';
import { ContractAddress } from '../libs/ContractAddress.sol';
import { SafeNativeTransfer } from '../libs/SafeTransfer.sol';
import { CreateDeploy } from './CreateDeploy.sol';

/**
 * @title Create3 contract
 * @notice This contract can be used to deploy a contract with a deterministic address that depends only on
 * the deployer address and deployment salt, not the contract bytecode and constructor parameters.
 */
contract Create3 is IDeploy {
    using ContractAddress for address;
    using SafeNativeTransfer for address;

    // slither-disable-next-line too-many-digits
    bytes32 internal constant DEPLOYER_BYTECODE_HASH = keccak256(type(CreateDeploy).creationCode);

    /**
     * @notice Deploys a new contract using the `CREATE3` method.
     * @dev This function first deploys the CreateDeploy contract using
     * the `CREATE2` opcode and then utilizes the CreateDeploy to deploy the
     * new contract with the `CREATE` opcode.
     * @param bytecode The bytecode of the contract to be deployed
     * @param deploySalt A salt to influence the contract address
     * @return deployed The address of the deployed contract
     */
    function _create3(bytes memory bytecode, bytes32 deploySalt) internal returns (address deployed) {
        deployed = _create3Address(deploySalt);

        if (bytecode.length == 0) revert EmptyBytecode();
        if (deployed.isContract()) revert AlreadyDeployed();

        if (msg.value > 0) {
            deployed.safeNativeTransfer(msg.value);
        }

        // Deploy using create2
        CreateDeploy create = new CreateDeploy{ salt: deploySalt }();

        if (address(create) == address(0)) revert DeployFailed();

        // Deploy using create
        create.deploy(bytecode);
    }

    /**
     * @notice Compute the deployed address that will result from the `CREATE3` method.
     * @param deploySalt A salt to influence the contract address
     * @return deployed The deterministic contract address if it was deployed
     */
    function _create3Address(bytes32 deploySalt) internal view returns (address deployed) {
        address deployer = address(
            uint160(uint256(keccak256(abi.encodePacked(hex'ff', address(this), deploySalt, DEPLOYER_BYTECODE_HASH))))
        );

        deployed = address(uint160(uint256(keccak256(abi.encodePacked(hex'd6_94', deployer, hex'01')))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Deployer } from './Deployer.sol';
import { Create3 } from './Create3.sol';

/**
 * @title Create3Deployer Contract
 * @notice This contract is responsible for deploying and initializing new contracts using the `CREATE3` method
 * which computes the deployed contract address based on the deployer address and deployment salt.
 */
contract Create3Deployer is Create3, Deployer {
    function _deploy(bytes memory bytecode, bytes32 deploySalt) internal override returns (address) {
        return _create3(bytecode, deploySalt);
    }

    function _deployedAddress(
        bytes memory, /* bytecode */
        bytes32 deploySalt
    ) internal view override returns (address) {
        return _create3Address(deploySalt);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title CreateDeploy Contract
 * @notice This contract deploys new contracts using the `CREATE` opcode and is used as part of
 * the `CREATE3` deployment method.
 */
contract CreateDeploy {
    /**
     * @dev Deploys a new contract with the specified bytecode using the `CREATE` opcode.
     * @param bytecode The bytecode of the contract to be deployed
     */
    // slither-disable-next-line locked-ether
    function deploy(bytes memory bytecode) external payable {
        assembly {
            if iszero(create(0, add(bytecode, 32), mload(bytecode))) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDeployer } from '../interfaces/IDeployer.sol';
import { SafeNativeTransfer } from '../libs/SafeTransfer.sol';

/**
 * @title Deployer Contract
 * @notice This contract is responsible for deploying and initializing new contracts using
 * a deployment method, such as `CREATE2` or `CREATE3`.
 */
abstract contract Deployer is IDeployer {
    using SafeNativeTransfer for address;

    /**
     * @notice Deploys a contract using a deployment method defined by derived contracts.
     * @dev The address where the contract will be deployed can be known in
     * advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already by the same `msg.sender`.
     *
     * @param bytecode The bytecode of the contract to be deployed
     * @param salt A salt to influence the contract address
     * @return deployedAddress_ The address of the deployed contract
     */
    function deploy(bytes memory bytecode, bytes32 salt) external payable returns (address deployedAddress_) {
        bytes32 deploySalt = keccak256(abi.encode(msg.sender, salt));
        deployedAddress_ = _deploy(bytecode, deploySalt);

        emit Deployed(deployedAddress_, msg.sender, salt, keccak256(bytecode));
    }

    /**
     * @notice Deploys a contract using a deployment method defined by derived contracts and initializes it.
     * @dev The address where the contract will be deployed can be known in advance
     * via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already by the same `msg.sender`.
     * - `init` is used to initialize the deployed contract as an option to not have the
     *    constructor args affect the address derived by `CREATE2`.
     *
     * @param bytecode The bytecode of the contract to be deployed
     * @param salt A salt to influence the contract address
     * @param init Init data used to initialize the deployed contract
     * @return deployedAddress_ The address of the deployed contract
     */
    function deployAndInit(
        bytes memory bytecode,
        bytes32 salt,
        bytes calldata init
    ) external payable returns (address deployedAddress_) {
        bytes32 deploySalt = keccak256(abi.encode(msg.sender, salt));
        deployedAddress_ = _deploy(bytecode, deploySalt);

        emit Deployed(deployedAddress_, msg.sender, salt, keccak256(bytecode));

        (bool success, ) = deployedAddress_.call(init);
        if (!success) revert DeployInitFailed();
    }

    /**
     * @notice Returns the address where a contract will be stored if deployed via {deploy} or {deployAndInit} by `sender`.
     * @dev Any change in the `bytecode` (except for `CREATE3`), `sender`, or `salt` will result in a new deployed address.
     * @param bytecode The bytecode of the contract to be deployed
     * @param sender The address that will deploy the contract via the deployment method
     * @param salt The salt that will be used to influence the contract address
     * @return deployedAddress_ The address that the contract will be deployed to
     */
    function deployedAddress(
        bytes memory bytecode,
        address sender,
        bytes32 salt
    ) public view returns (address) {
        bytes32 deploySalt = keccak256(abi.encode(sender, salt));
        return _deployedAddress(bytecode, deploySalt);
    }

    function _deploy(bytes memory bytecode, bytes32 deploySalt) internal virtual returns (address);

    function _deployedAddress(bytes memory bytecode, bytes32 deploySalt) internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from '../interfaces/IAxelarExecutable.sol';

contract AxelarExecutable is IAxelarExecutable {
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

        _execute(sourceChain, sourceAddress, payload);
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

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
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

/**
 * @title IDeploy Interface
 * @notice This interface defines the errors for a contract that is responsible for deploying new contracts.
 */
interface IDeploy {
    error EmptyBytecode();
    error AlreadyDeployed();
    error DeployFailed();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDeploy } from './IDeploy.sol';

/**
 * @title IDeployer Interface
 * @notice This interface defines the contract responsible for deploying and optionally initializing new contracts
 *  via a specified deployment method.
 */
interface IDeployer is IDeploy {
    error DeployInitFailed();

    event Deployed(address indexed deployedAddress, address indexed sender, bytes32 indexed salt, bytes32 bytecodeHash);

    /**
     * @notice Deploys a contract using a deployment method defined by derived contracts.
     * @param bytecode The bytecode of the contract to be deployed
     * @param salt A salt to influence the contract address
     * @return deployedAddress_ The address of the deployed contract
     */
    function deploy(bytes memory bytecode, bytes32 salt) external payable returns (address deployedAddress_);

    /**
     * @notice Deploys a contract using a deployment method defined by derived contracts and initializes it.
     * @param bytecode The bytecode of the contract to be deployed
     * @param salt A salt to influence the contract address
     * @param init Init data used to initialize the deployed contract
     * @return deployedAddress_ The address of the deployed contract
     */
    function deployAndInit(
        bytes memory bytecode,
        bytes32 salt,
        bytes calldata init
    ) external payable returns (address deployedAddress_);

    /**
     * @notice Returns the address where a contract will be stored if deployed via {deploy} or {deployAndInit} by `sender`.
     * @param bytecode The bytecode of the contract
     * @param sender The address that will deploy the contract
     * @param salt The salt that will be used to influence the contract address
     * @return deployedAddress_ The address that the contract will be deployed to
     */
    function deployedAddress(
        bytes calldata bytecode,
        address sender,
        bytes32 salt
    ) external view returns (address deployedAddress_);
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

library StringToAddress {
    error InvalidAddressString();

    function toAddress(string memory addressString) internal pure returns (address) {
        bytes memory stringBytes = bytes(addressString);
        uint160 addressNumber = 0;
        uint8 stringByte;

        if (stringBytes.length != 42 || stringBytes[0] != '0' || stringBytes[1] != 'x') revert InvalidAddressString();

        for (uint256 i = 2; i < 42; ++i) {
            stringByte = uint8(stringBytes[i]);

            if ((stringByte >= 97) && (stringByte <= 102)) stringByte -= 87;
            else if ((stringByte >= 65) && (stringByte <= 70)) stringByte -= 55;
            else if ((stringByte >= 48) && (stringByte <= 57)) stringByte -= 48;
            else revert InvalidAddressString();

            addressNumber |= uint160(uint256(stringByte) << ((41 - i) << 2));
        }

        return address(addressNumber);
    }
}

library AddressToString {
    function toString(address address_) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(address_);
        bytes memory characters = '0123456789abcdef';
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint256 i; i < 20; ++i) {
            stringBytes[2 + i * 2] = characters[uint8(addressBytes[i] >> 4)];
            stringBytes[3 + i * 2] = characters[uint8(addressBytes[i] & 0x0f)];
        }

        return string(stringBytes);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ContractAddress {
    function isContract(address contractAddress) internal view returns (bool) {
        bytes32 existingCodeHash = contractAddress.codehash;

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

pragma solidity ^0.8.0;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

// Note: import the `Create3Deployer` here so that the hardhat scripts can access it, especially for the `00-deploy-deployer.sol` script

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Ownable.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IInterchainProposalExecutor } from './interfaces/IInterchainProposalExecutor.sol';
import { InterchainCalls } from './lib/InterchainCalls.sol';

/**
 * @title InterchainProposalExecutor
 * @dev This contract is intended to be the destination contract for `InterchainProposalSender` contract.
 * The proposal will be finally executed from this contract on the destination chain.
 *
 * The contract maintains whitelists for proposal senders and proposal callers. Proposal senders
 * are InterchainProposalSender contracts at the source chain and proposal callers are contracts
 * that call the InterchainProposalSender at the source chain.
 * For most governance system, the proposal caller should be the Timelock contract.
 *
 * Some functions need to be implemented in a derived contract.
 */
contract InterchainProposalExecutor is IInterchainProposalExecutor, AxelarExecutable, Ownable {
    // Whitelisted proposal callers. The proposal caller is the contract that calls the `InterchainProposalSender` at the source chain.
    mapping(string => mapping(bytes => bool)) public whitelistedCallers;

    // Whitelisted proposal senders. The proposal sender is the `InterchainProposalSender` contract address at the source chain.
    mapping(string => mapping(string => bool)) public whitelistedSenders;

    constructor(address _gateway, address _owner) AxelarExecutable(_gateway) Ownable(_owner) {}

    /**
     * @dev Executes the proposal. The source address must be a whitelisted sender.
     * @param sourceAddress The source address
     * @param payload The payload. It is ABI encoded of the caller and calls.
     * Where:
     * - `caller` is the address that calls the `InterchainProposalSender` at the source chain.
     * - `calls` is the array of `InterchainCalls.Call` to execute. Each call contains the target, value, signature and data.
     */
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        // Check that the source address is whitelisted
        if (!whitelistedSenders[sourceChain][sourceAddress]) {
            revert NotWhitelistedSourceAddress();
        }

        // Decode the payload
        (bytes memory sourceCaller, InterchainCalls.Call[] memory calls) = abi.decode(
            payload,
            (bytes, InterchainCalls.Call[])
        );

        // Check that the caller is whitelisted
        if (!whitelistedCallers[sourceChain][sourceCaller]) {
            revert NotWhitelistedCaller();
        }

        _beforeProposalExecuted(sourceChain, sourceAddress, sourceCaller, calls);

        // Execute the proposal with the given arguments
        _executeProposal(calls);

        _onProposalExecuted(sourceChain, sourceAddress, sourceCaller, payload);

        emit ProposalExecuted(keccak256(abi.encode(sourceChain, sourceAddress, sourceCaller, payload)));
    }

    /**
     * @dev Executes the proposal. Calls each target with the respective value, signature, and data.
     * @param calls The calls to execute.
     */
    function _executeProposal(InterchainCalls.Call[] memory calls) internal {
        uint256 length = calls.length;

        for (uint256 i = 0; i < length; i++) {
            InterchainCalls.Call memory call = calls[i];
            (bool success, bytes memory result) = call.target.call{ value: call.value }(call.callData);

            if (!success) {
                _onTargetExecutionFailed(call, result);
            } else {
                _onTargetExecuted(call, result);
            }
        }
    }

    /**
     * @dev Set the proposal caller whitelist status
     * @param sourceChain The source chain
     * @param sourceCaller The source caller
     * @param whitelisted The whitelist status
     */
    function setWhitelistedProposalCaller(
        string calldata sourceChain,
        bytes memory sourceCaller,
        bool whitelisted
    ) external override onlyOwner {
        whitelistedCallers[sourceChain][sourceCaller] = whitelisted;
        emit WhitelistedProposalCallerSet(sourceChain, sourceCaller, whitelisted);
    }

    /**
     * @dev Set the proposal sender whitelist status
     * @param sourceChain The source chain
     * @param sourceSender The source sender
     * @param whitelisted The whitelist status
     */
    function setWhitelistedProposalSender(
        string calldata sourceChain,
        string calldata sourceSender,
        bool whitelisted
    ) external override onlyOwner {
        whitelistedSenders[sourceChain][sourceSender] = whitelisted;
        emit WhitelistedProposalSenderSet(sourceChain, sourceSender, whitelisted);
    }

    /**
     * @dev Receive native tokens for the proposal that requires native tokens.
     */
    receive() external payable {}

    /**
     * @dev A callback function that is called before the proposal is executed.
     * This function can be used to handle the payload before the proposal is executed.
     * @param sourceChain The source chain from where the proposal was sent.
     * @param sourceAddress The source address that sent the proposal. The source address should be the `InterchainProposalSender` contract address at the source chain.
     * @param caller The caller that calls the `InterchainProposalSender` at the source chain.
     * @param calls The array of `InterchainCalls.Call` to execute. Each call contains the target, value, and callData.
     */
    function _beforeProposalExecuted(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes memory caller,
        InterchainCalls.Call[] memory calls
    ) internal virtual {
        // You can add your own logic here to handle the payload before the proposal is executed.
    }

    /**
     * @dev A callback function that is called after the proposal is executed.
     * This function emits an event containing the hash of the payload to signify successful execution.
     * @param payload The payload. It is ABI encoded of the caller and calls.
     * Where:
     * - `caller` is the address that calls the `InterchainProposalSender` at the source chain.
     * - `calls` is the array of `InterchainCalls.Call` to execute. Each call contains the target, value, signature and data.
     */
    function _onProposalExecuted(
        string calldata /* sourceChain */,
        string calldata /* sourceAddress */,
        bytes memory /* caller */,
        bytes calldata payload
    ) internal virtual {
        // You can add your own logic here to handle the payload after the proposal is executed.
    }

    /**
     * @dev A callback function that is called when the execution of a target contract within a proposal fails.
     * This function will revert the transaction providing the failure reason if present in the failure data.
     * @param result The return data from the failed call to the target contract.
     */
    function _onTargetExecutionFailed(InterchainCalls.Call memory /* call */, bytes memory result) internal virtual {
        // You can add your own logic here to handle the failure of the target contract execution. The code below is just an example.
        if (result.length > 0) {
            // The failure data is a revert reason string.
            assembly {
                revert(add(32, result), mload(result))
            }
        } else {
            // There is no failure data, just revert with no reason.
            revert ProposalExecuteFailed();
        }
    }

    /**
     * @dev Called after a target is successfully executed. The derived contract should implement this function.
     * This function should do some post-execution work, such as emitting events.
     * @param call The call that has been executed.
     * @param result The result of the call.
     */
    function _onTargetExecuted(InterchainCalls.Call memory call, bytes memory result) internal virtual {
        // You can add your own logic here to handle the success of each target contract execution.
    }
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

interface IInterchainProposalExecutor {
    // An event emitted when the proposal caller is whitelisted
    event WhitelistedProposalCallerSet(string indexed sourceChain, bytes indexed sourceCaller, bool whitelisted);

    // An event emitted when the proposal sender is whitelisted
    event WhitelistedProposalSenderSet(string indexed sourceChain, string sourceSender, bool whitelisted);

    // An event emitted when the proposal is executed
    event ProposalExecuted(bytes32 indexed payloadHash);

    // An error emitted when the proposal execution failed
    error ProposalExecuteFailed();

    // An error emitted when the proposal caller is not whitelisted
    error NotWhitelistedCaller();

    // An error emitted when the proposal sender is not whitelisted
    error NotWhitelistedSourceAddress();

    /**
     * @notice set the whitelisted status of a proposal sender which is the `InterchainProposalSender` contract address on the source chain
     * @param sourceChain The source chain
     * @param sourceSender The source interchain sender address
     * @param whitelisted The whitelisted status
     */
    function setWhitelistedProposalSender(
        string calldata sourceChain,
        string calldata sourceSender,
        bool whitelisted
    ) external;

    /**
     * @notice set the whitelisted status of a proposal caller which normally set to the `Timelock` contract address on the source chain
     * @param sourceChain The source chain
     * @param sourceCaller The source interchain caller address
     * @param whitelisted The whitelisted status
     */
    function setWhitelistedProposalCaller(
        string calldata sourceChain,
        bytes memory sourceCaller,
        bool whitelisted
    ) external;
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

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

contract Comp {
    /// @notice EIP-20 token name for this token
    string public constant name = 'Compound';

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = 'COMP';

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public constant totalSupply = 10000000e18; // 10 million Comp

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new Comp token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) {
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == type(uint).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, 'Comp::approve: amount exceeds 96 bits');
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, 'Comp::transfer: amount exceeds 96 bits');
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, 'Comp::approve: amount exceeds 96 bits');

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                'Comp::transferFrom: transfer amount exceeds spender allowance'
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'Comp::delegateBySig: invalid signature');
        require(nonce == nonces[signatory]++, 'Comp::delegateBySig: invalid nonce');
        require(block.timestamp <= expiry, 'Comp::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, 'Comp::getPriorVotes: not yet determined');

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), 'Comp::_transferTokens: cannot transfer from the zero address');
        require(dst != address(0), 'Comp::_transferTokens: cannot transfer to the zero address');

        balances[src] = sub96(balances[src], amount, 'Comp::_transferTokens: transfer amount exceeds balance');
        balances[dst] = add96(balances[dst], amount, 'Comp::_transferTokens: transfer amount overflows');
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, 'Comp::_moveVotes: vote amount underflows');
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, 'Comp::_moveVotes: vote amount overflows');
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumber = safe32(block.number, 'Comp::_writeCheckpoint: block number exceeds 32 bits');

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2 ** 96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DummyState {
    string public message;

    function setState(string calldata _message) external {
        message = _message;
    }

    function testRevert() external pure {
        revert('kaboom');
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

contract GovernorAlpha {
    /// @notice The name of this contract
    string public constant name = 'Compound Governor Alpha';

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public pure returns (uint) {
        return 400000e18;
    } // 400,000 = 4% of Comp

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public pure returns (uint) {
        return 100000e18;
    } // 100,000 = 1% of Comp

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) {
        return 10;
    } // 10 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) {
        return 1;
    } // 1 block

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure virtual returns (uint) {
        return 100;
    }

    /// @notice The address of the Compound Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the Compound governance token
    CompInterface public comp;

    /// @notice The address of the Governor Guardian
    address public guardian;

    /// @notice The total number of proposals
    uint public proposalCount;

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal
        bool support;
        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping(uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256('Ballot(uint256 proposalId,bool support)');

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint id,
        address proposer,
        address[] targets,
        uint[] values,
        string[] signatures,
        bytes[] calldatas,
        uint startBlock,
        uint endBlock,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    constructor(address timelock_, address comp_, address guardian_) {
        timelock = TimelockInterface(timelock_);
        comp = CompInterface(comp_);
        guardian = guardian_;
    }

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint) {
        require(
            comp.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(),
            'GovernorAlpha::propose: proposer votes below proposal threshold'
        );
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            'GovernorAlpha::propose: proposal function information arity mismatch'
        );
        require(targets.length != 0, 'GovernorAlpha::propose: must provide actions');
        require(targets.length <= proposalMaxOperations(), 'GovernorAlpha::propose: too many actions');

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(
                proposersLatestProposalState != ProposalState.Active,
                'GovernorAlpha::propose: one live proposal per proposer, found an already active proposal'
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                'GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal'
            );
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        uint proposalId = proposalCount;
        Proposal storage newProposal = proposals[proposalId];
        // This should never happen but add a check in case.
        require(newProposal.id == 0, 'GovernorAlpha::propose: ProposalID collsion');
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.eta = 0;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.canceled = false;
        newProposal.executed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            description
        );
        return newProposal.id;
    }

    function queue(uint proposalId) public {
        require(
            state(proposalId) == ProposalState.Succeeded,
            'GovernorAlpha::queue: proposal can only be queued if it is succeeded'
        );
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(
            !timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
            'GovernorAlpha::_queueOrRevert: proposal action already queued at eta'
        );
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint proposalId) public payable {
        require(
            state(proposalId) == ProposalState.Queued,
            'GovernorAlpha::execute: proposal can only be executed if it is queued'
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{ value: proposal.values[i] }(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        ProposalState proposalState = state(proposalId);
        require(proposalState != ProposalState.Executed, 'GovernorAlpha::cancel: cannot cancel executed proposal');

        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == guardian ||
                comp.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(),
            'GovernorAlpha::cancel: proposer above threshold'
        );

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(
        uint proposalId
    )
        public
        view
        returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas)
    {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, 'GovernorAlpha::state: invalid proposal id');
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'GovernorAlpha::castVoteBySig: invalid signature');
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, 'GovernorAlpha::_castVote: voting is closed');
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, 'GovernorAlpha::_castVote: voter already voted');
        uint96 votes = comp.getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, 'GovernorAlpha::__acceptAdmin: sender must be gov guardian');
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, 'GovernorAlpha::__abdicate: sender must be gov guardian');
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, 'GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian');
        timelock.queueTransaction(address(timelock), 0, 'setPendingAdmin(address)', abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, 'GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian');
        timelock.executeTransaction(address(timelock), 0, 'setPendingAdmin(address)', abi.encode(newPendingAdmin), eta);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, 'addition overflow');
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, 'subtraction underflow');
        return a - b;
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);

    function GRACE_PERIOD() external view returns (uint);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external;

    function executeTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external payable returns (bytes memory);
}

interface CompInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c;
        unchecked {
            c = a + b;
        }
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c;
        unchecked {
            c = a + b;
        }
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction underflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c;
        unchecked {
            c = a * b;
        }
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c;
        unchecked {
            c = a * b;
        }
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Ownable.sol';
import '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol';
import '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressString.sol';
import '../InterchainProposalExecutor.sol';
import '../lib/InterchainCalls.sol';

/**
 * @title InterchainProposalExecutor
 * @dev This contract provides a simple implementation of the `InterchainProposalExecutor` abstract contract.
 * It offers specific logic for handling proposal execution success and failures as well as emitting events
 * after proposal execution.
 */
contract TestProposalExecutor is InterchainProposalExecutor {
    event BeforeProposalExecuted(string sourceChain, string sourceAddress, bytes payload);

    event TargetExecuted(address target, uint256 value, bytes callData);

    constructor(address _gateway, address _owner) InterchainProposalExecutor(_gateway, _owner) {}

    function forceExecute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external onlyOwner {
        _execute(sourceChain, sourceAddress, payload);
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import './lib/SafeMath.sol';

contract Timelock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 1;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    constructor(address admin_, uint delay_) {
        require(delay_ >= MINIMUM_DELAY, 'Timelock::constructor: Delay must exceed minimum delay.');
        require(delay_ <= MAXIMUM_DELAY, 'Timelock::setDelay: Delay must not exceed maximum delay.');

        admin = admin_;
        delay = delay_;
    }

    fallback() external payable {}

    receive() external payable {}

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), 'Timelock::setDelay: Call must come from Timelock.');
        require(delay_ >= MINIMUM_DELAY, 'Timelock::setDelay: Delay must exceed minimum delay.');
        require(delay_ <= MAXIMUM_DELAY, 'Timelock::setDelay: Delay must not exceed maximum delay.');
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, 'Timelock::acceptAdmin: Call must come from pendingAdmin.');
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), 'Timelock::setPendingAdmin: Call must come from Timelock.');
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public returns (bytes32) {
        require(msg.sender == admin, 'Timelock::queueTransaction: Call must come from admin.');
        require(
            eta >= getBlockTimestamp().add(delay),
            'Timelock::queueTransaction: Estimated execution block must satisfy delay.'
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public {
        require(msg.sender == admin, 'Timelock::cancelTransaction: Call must come from admin.');

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, 'Timelock::executeTransaction: Call must come from admin.');

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], 'Timelock::executeTransaction: Transaction has not been queued.');
        require(getBlockTimestamp() >= eta, 'Timelock::executeTransaction: Transaction has not surpassed time lock.');
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), 'Timelock::executeTransaction: Transaction is stale.');

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{ value: value }(callData);
        require(success, 'Timelock::executeTransaction: Transaction execution reverted.');

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}