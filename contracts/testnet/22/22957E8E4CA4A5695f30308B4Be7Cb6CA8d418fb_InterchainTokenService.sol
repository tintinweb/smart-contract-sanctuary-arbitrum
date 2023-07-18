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

import { IOwnable } from './IOwnable.sol';

// General interface for upgradable contracts
interface IUpgradable is IOwnable {
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

    function contractId() external pure returns (bytes32);
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
     * on the implementation contract itself
     */
    constructor() {
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

        if (params.length > 0) {
            (bool success, ) = newImplementation.delegatecall(abi.encodeWithSelector(this.setup.selector, params));

            if (!success) revert SetupFailed();
        }

        emit Upgraded(newImplementation);

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

library StringToBytes32 {
    error InvalidStringLength();

    function toBytes32(string memory str) internal pure returns (bytes32) {
        // Converting a string to bytes32 for immutable storage
        bytes memory stringBytes = bytes(str);

        // We can store up to 31 bytes of data as 1 byte is for encoding length
        if (stringBytes.length == 0 || stringBytes.length > 31) revert InvalidStringLength();

        uint256 stringNumber = uint256(bytes32(stringBytes));

        // Storing string length as the last byte of the data
        stringNumber |= 0xff & stringBytes.length;
        return bytes32(stringNumber);
    }
}

library Bytes32ToString {
    function toTrimmedString(bytes32 stringData) internal pure returns (string memory converted) {
        // recovering string length as the last byte of the data
        uint256 length = 0xff & uint256(stringData);

        // restoring the string with the correct length
        assembly {
            converted := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(converted, 0x40))
            // store length in memory
            mstore(converted, length)
            // write actual data
            mstore(add(converted, 0x20), stringData)
        }
    }
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
        emit OwnershipTransferred(newOwner);

        assembly {
            sstore(_OWNER_SLOT, newOwner)
            sstore(_OWNERSHIP_TRANSFER_SLOT, 0)
        }
    }

    /**
     * @notice Propose to transfer ownership of the contract to a new account `newOwner`.
     * @dev Can only be called by the current owner. The ownership does not change
     * until the new owner accepts the ownership transfer.
     * @param newOwner The address to transfer ownership to
     */
    function proposeOwnership(address newOwner) external virtual onlyOwner {
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

        emit OwnershipTransferred(newOwner);

        assembly {
            sstore(_OWNERSHIP_TRANSFER_SLOT, 0)
            sstore(_OWNER_SLOT, newOwner)
        }
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

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerDeployer } from '../interfaces/ITokenManagerDeployer.sol';
import { IStandardizedTokenDeployer } from '../interfaces/IStandardizedTokenDeployer.sol';
import { IRemoteAddressValidator } from '../interfaces/IRemoteAddressValidator.sol';
import { IInterchainTokenExpressExecutable } from '../interfaces/IInterchainTokenExpressExecutable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { ExpressCallHandler } from '../utils/ExpressCallHandler.sol';
import { Pausable } from '../utils/Pausable.sol';
import { Operatable } from '../utils/Operatable.sol';
import { Multicall } from '../utils/Multicall.sol';

/**
 * @title The Interchain Token Service
 * @notice This contract is responsible for facilitating cross chain token transfers.
 * It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for cross chain transfers to happen.
 * @dev The only storage used here is for ExpressCalls
 */
contract InterchainTokenService is
    IInterchainTokenService,
    AxelarExecutable,
    Upgradable,
    Operatable,
    ExpressCallHandler,
    Pausable,
    Multicall
{
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using AddressBytesUtils for bytes;
    using AddressBytesUtils for address;

    address internal immutable implementationLockUnlock;
    address internal immutable implementationMintBurn;
    address internal immutable implementationLiquidityPool;
    IAxelarGasService public immutable gasService;
    IRemoteAddressValidator public immutable remoteAddressValidator;
    address public immutable tokenManagerDeployer;
    address public immutable standardizedTokenDeployer;
    Create3Deployer internal immutable deployer;
    bytes32 internal immutable chainNameHash;
    bytes32 internal immutable chainName;

    bytes32 internal constant PREFIX_CUSTOM_TOKEN_ID = keccak256('its-custom-token-id');
    bytes32 internal constant PREFIX_STANDARDIZED_TOKEN_ID = keccak256('its-standardized-token-id');
    bytes32 internal constant PREFIX_STANDARDIZED_TOKEN_SALT = keccak256('its-standardized-token-salt');

    uint256 private constant SELECTOR_SEND_TOKEN = 1;
    uint256 private constant SELECTOR_SEND_TOKEN_WITH_DATA = 2;
    uint256 private constant SELECTOR_DEPLOY_TOKEN_MANAGER = 3;
    uint256 private constant SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN = 4;

    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-service');

    /**
     * @dev All of the varaibles passed here are stored as immutable variables.
     * @param tokenManagerDeployer_ the address of the TokenManagerDeployer.
     * @param standardizedTokenDeployer_ the address of the StandardizedTokenDeployer.
     * @param gateway_ the address of the AxelarGateway.
     * @param gasService_ the address of the AxelarGasService.
     * @param remoteAddressValidator_ the address of the RemoteAddressValidator.
     * @param tokenManagerImplementations this need to have exactly 3 implementations in the following order: Lock/Unlock, mint/burn and then liquidity pool.
     * @param chainName_ the name of the current chain.
     */
    constructor(
        address tokenManagerDeployer_,
        address standardizedTokenDeployer_,
        address gateway_,
        address gasService_,
        address remoteAddressValidator_,
        address[] memory tokenManagerImplementations,
        string memory chainName_
    ) AxelarExecutable(gateway_) {
        if (
            remoteAddressValidator_ == address(0) ||
            gasService_ == address(0) ||
            tokenManagerDeployer_ == address(0) ||
            standardizedTokenDeployer_ == address(0)
        ) revert ZeroAddress();
        remoteAddressValidator = IRemoteAddressValidator(remoteAddressValidator_);
        gasService = IAxelarGasService(gasService_);
        tokenManagerDeployer = tokenManagerDeployer_;
        standardizedTokenDeployer = standardizedTokenDeployer_;
        deployer = ITokenManagerDeployer(tokenManagerDeployer_).deployer();

        if (tokenManagerImplementations.length != uint256(type(TokenManagerType).max) + 1) revert LengthMismatch();

        implementationLockUnlock = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LOCK_UNLOCK);
        implementationMintBurn = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.MINT_BURN);
        implementationLiquidityPool = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LIQUIDITY_POOL);

        chainName = chainName_.toBytes32();
        chainNameHash = keccak256(bytes(chainName_));
    }

    /*******\
    MODIFIERS
    \*******/

    /**
     * @notice This modifier is used to ensure that only a remote InterchainTokenService can _execute this one.
     * @param sourceChain the source of the contract call.
     * @param sourceAddress the address that the call came from.
     */
    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!remoteAddressValidator.validateSender(sourceChain, sourceAddress)) revert NotRemoteService();
        _;
    }

    /**
     * @notice This modifier is used to ensure certain functions can only be called by TokenManagers.
     * @param tokenId the `tokenId` of the TokenManager trying to perform the call.
     */
    modifier onlyTokenManager(bytes32 tokenId) {
        if (msg.sender != getTokenManagerAddress(tokenId)) revert NotTokenManager();
        _;
    }

    /*****\
    GETTERS
    \*****/

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Getter for the chain name.
     * @return name the name of the chain
     */
    function getChainName() public view returns (string memory name) {
        name = chainName.toTrimmedString();
    }

    /**
     * @notice Calculates the address of a TokenManager from a specific tokenId. The TokenManager does not need to exist already.
     * @param tokenId the tokenId.
     * @return tokenManagerAddress deployement address of the TokenManager.
     */
    function getTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = deployer.deployedAddress(address(this), tokenId);
    }

    /**
     * @notice Returns the address of a TokenManager from a specific tokenId. The TokenManager needs to exist already.
     * @param tokenId the tokenId.
     * @return tokenManagerAddress deployment address of the TokenManager.
     */
    function getValidTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = getTokenManagerAddress(tokenId);
        if (ITokenManagerProxy(tokenManagerAddress).tokenId() != tokenId) revert TokenManagerDoesNotExist(tokenId);
    }

    /**
     * @notice Returns the address of the token that an existing tokenManager points to.
     * @param tokenId the tokenId.
     * @return tokenAddress the address of the token.
     */
    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress) {
        address tokenManagerAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenManagerAddress).tokenAddress();
    }

    /**
     * @notice Returns the address of the standardized token that would be deployed with a given tokenId.
     * The token does not need to exist.
     * @param tokenId the tokenId.
     * @return tokenAddress the address of the standardized token.
     */
    function getStandardizedTokenAddress(bytes32 tokenId) public view returns (address tokenAddress) {
        tokenId = _getStandardizedTokenSalt(tokenId);
        tokenAddress = deployer.deployedAddress(address(this), tokenId);
    }

    /**
     * @notice Calculates the tokenId that would correspond to a canonical link for a given token.
     * This will depend on what chain it is called from, unlike custom tokenIds.
     * @param tokenAddress the address of the token.
     * @return tokenId the tokenId that the canonical TokenManager would get (or has gotten) for the token.
     */
    function getCanonicalTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_STANDARDIZED_TOKEN_ID, chainNameHash, tokenAddress));
    }

    /**
     * @notice Calculates the tokenId that would correspond to a custom link for a given deployer with a specified salt.
     * This will not depend on what chain it is called from, unlike canonical tokenIds.
     * @param sender the address of the TokenManager deployer.
     * @param salt the salt that the deployer uses for the deployment.
     * @return tokenId the tokenId that the custom TokenManager would get (or has gotten).
     */
    function getCustomTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_CUSTOM_TOKEN_ID, sender, salt));
    }

    /**
     * @notice Getter function for TokenManager implementations. This will mainly be called by TokenManagerProxies
     * to figure out their implementations
     * @param tokenManagerType the type of the TokenManager.
     * @return tokenManagerAddress the address of the TokenManagerImplementation.
     */
    function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress) {
        // There could be a way to rewrite the following using assembly switch statements, which would be more gas efficient,
        // but accessing immutable variables and/or enum values seems to be tricky, and would reduce code readability.
        if (TokenManagerType(tokenManagerType) == TokenManagerType.LOCK_UNLOCK) {
            return implementationLockUnlock;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.MINT_BURN) {
            return implementationMintBurn;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.LIQUIDITY_POOL) {
            return implementationLiquidityPool;
        }
    }

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsLockUnlock(bytes memory operator, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress);
    }

    /**
     * @notice Getter function for the parameters of a mint/burn TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsMintBurn(bytes memory operator, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress);
    }

    /**
     * @notice Getter function for the parameters of a liquidity pool TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @param liquidityPoolAddress the liquidity pool to be used to store the bridged tokens.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsLiquidityPool(
        bytes memory operator,
        address tokenAddress,
        address liquidityPoolAddress
    ) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress, liquidityPoolAddress);
    }

    /**
     * @notice Getter function for the flow limit of an existing token manager with a give token ID.
     * @param tokenId the token ID of the TokenManager.
     * @return flowLimit the flow limit.
     */
    function getFlowLimit(bytes32 tokenId) external view returns (uint256 flowLimit) {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        flowLimit = tokenManager.getFlowLimit();
    }

    /**
     * @notice Getter function for the flow out amount of an existing token manager with a give token ID.
     * @param tokenId the token ID of the TokenManager.
     * @return flowOutAmount the flow out amount.
     */
    function getFlowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount) {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        flowOutAmount = tokenManager.getFlowOutAmount();
    }

    /**
     * @notice Getter function for the flow in amount of an existing token manager with a give token ID.
     * @param tokenId the token ID of the TokenManager.
     * @return flowInAmount the flow in amount.
     */
    function getFlowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount) {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        flowInAmount = tokenManager.getFlowInAmount();
    }

    /************\
    USER FUNCTIONS
    \************/

    /**
     * @notice Used to register canonical tokens. Caller does not matter.
     * @param tokenAddress the token to be bridged.
     * @return tokenId the tokenId that was used for this canonical token.
     */
    function registerCanonicalToken(address tokenAddress) external payable notPaused returns (bytes32 tokenId) {
        (, string memory tokenSymbol, ) = _validateToken(tokenAddress);
        if (gateway.tokenAddresses(tokenSymbol) == tokenAddress) revert GatewayToken();
        tokenId = getCanonicalTokenId(tokenAddress);
        _deployTokenManager(tokenId, TokenManagerType.LOCK_UNLOCK, abi.encode(address(this).toBytes(), tokenAddress));
    }

    /**
     * @notice Used to deploy remote TokenManagers and standardized tokens for a canonical token. This needs to be
     * called from the chain that registered the canonical token, and anyone can call it.
     * @param tokenId the tokenId of the canonical token.
     * @param destinationChain the name of the chain to deploy the TokenManager and standardized token to.
     * @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment.
     * At least the amount specified needs to be passed to the call
     * @dev `gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls.
     */
    function deployRemoteCanonicalToken(bytes32 tokenId, string calldata destinationChain, uint256 gasValue) public payable notPaused {
        address tokenAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenAddress).tokenAddress();
        if (getCanonicalTokenId(tokenAddress) != tokenId) revert NotCanonicalTokenManager();
        (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) = _validateToken(tokenAddress);
        _deployRemoteStandardizedToken(tokenId, tokenName, tokenSymbol, tokenDecimals, '', '', destinationChain, gasValue);
    }

    /**
     * @notice Used to deploy custom TokenManagers with the specified salt. Different callers would result in different tokenIds.
     * @param salt the salt to be used.
     * @param tokenManagerType the type of TokenManager to be deployed.
     * @param params the params that will be used to initialize the TokenManager.
     */
    function deployCustomTokenManager(
        bytes32 salt,
        TokenManagerType tokenManagerType,
        bytes memory params
    ) public payable notPaused returns (bytes32 tokenId) {
        address deployer_ = msg.sender;
        tokenId = getCustomTokenId(deployer_, salt);
        _deployTokenManager(tokenId, tokenManagerType, params);
        emit CustomTokenIdClaimed(tokenId, deployer_, salt);
    }

    /**
     * @notice Used to deploy remote custom TokenManagers.
     * @param salt the salt to be used.
     * @param destinationChain the name of the chain to deploy the TokenManager and standardized token to.
     * @param tokenManagerType the type of TokenManager to be deployed.
     * @param params the params that will be used to initialize the TokenManager.
     * @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment. At least
     * the amount specified needs to be passed to the call
     * @dev `gasValue` exists because this function can be part of a multicall involving multiple functions
     * that could make remote contract calls.
     */
    function deployRemoteCustomTokenManager(
        bytes32 salt,
        string calldata destinationChain,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        uint256 gasValue
    ) external payable notPaused returns (bytes32 tokenId) {
        address deployer_ = msg.sender;
        tokenId = getCustomTokenId(deployer_, salt);
        _deployRemoteTokenManager(tokenId, destinationChain, gasValue, tokenManagerType, params);
        emit CustomTokenIdClaimed(tokenId, deployer_, salt);
    }

    /**
     * @notice Used to deploy a standardized token alongside a TokenManager. If the `distributor` is the address of the TokenManager (which
     * can be calculated ahead of time) then a mint/burn TokenManager is used. Otherwise a lock/unlcok TokenManager is used.
     * @param salt the salt to be used.
     * @param name the name of the token to be deployed.
     * @param symbol the symbol of the token to be deployed.
     * @param decimals the decimals of the token to be deployed.
     * @param mintAmount the amount of token to be mint during deployment to msg.sender.
     * @param distributor the address that will be able to mint and burn the deployed token.
     */
    function deployAndRegisterStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) external payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployStandardizedToken(tokenId, distributor, name, symbol, decimals, mintAmount, msg.sender);
        address tokenManagerAddress = getTokenManagerAddress(tokenId);
        TokenManagerType tokenManagerType = distributor == tokenManagerAddress ? TokenManagerType.MINT_BURN : TokenManagerType.LOCK_UNLOCK;
        address tokenAddress = getStandardizedTokenAddress(tokenId);
        _deployTokenManager(tokenId, tokenManagerType, abi.encode(msg.sender.toBytes(), tokenAddress));
    }

    /**
     * @notice Used to deploy a standardized token alongside a TokenManager in another chain. If the `distributor` is empty
     * bytes then a mint/burn TokenManager is used. Otherwise a lock/unlcok TokenManager is used.
     * @param salt the salt to be used.
     * @param name the name of the token to be deployed.
     * @param symbol the symbol of the token to be deployed.
     * @param decimals the decimals of the token to be deployed.
     * @param distributor the address that will be able to mint and burn the deployed token.
     * @param destinationChain the name of the destination chain to deploy to.
     * @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount
     * specified needs to be passed to the call
     * @dev `gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls.
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
    ) external payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployRemoteStandardizedToken(tokenId, name, symbol, decimals, distributor, operator, destinationChain, gasValue);
    }

    /**
     * @notice Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing
     * sendToken that matches the parameters passed here.
     * @param tokenId the tokenId of the TokenManager used.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param commandId the sendHash detected at the sourceChain.
     */
    function expressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) external {
        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted(commandId);

        address caller = msg.sender;
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        IERC20 token = IERC20(tokenManager.tokenAddress());

        SafeTokenTransferFrom.safeTransferFrom(token, caller, destinationAddress, amount);

        _setExpressReceiveToken(tokenId, destinationAddress, amount, commandId, caller);
    }

    /**
     * @notice Uses the caller's tokens to fullfill a callContractWithInterchainToken ahead of time. Use this only if you have
     * detected an outgoing sendToken that matches the parameters passed here.
     * @param tokenId the tokenId of the TokenManager used.
     * @param sourceChain the name of the chain where the call came from.
     * @param sourceAddress the caller of callContractWithInterchainToken.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param data the data to be passed to destinationAddress after giving them the tokens specified.
     * @param commandId the sendHash detected at the sourceChain.
     */
    function expressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 commandId
    ) external {
        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted(commandId);

        address caller = msg.sender;
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        IERC20 token = IERC20(tokenManager.tokenAddress());

        SafeTokenTransferFrom.safeTransferFrom(token, caller, destinationAddress, amount);

        _expressExecuteWithInterchainTokenToken(tokenId, destinationAddress, sourceChain, sourceAddress, data, amount);

        _setExpressReceiveTokenWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId, caller);
    }

    /*********************\
    TOKEN MANAGER FUNCTIONS
    \*********************/

    /**
     * @notice Transmit a sendTokenWithData for the given tokenId. Only callable by a token manager.
     * @param tokenId the tokenId of the TokenManager (which must be the msg.sender).
     * @param sourceAddress the address where the token is coming from, which will also be used for reimburment of gas.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param metadata the data to be passed to the destiantion.
     */
    function transmitSendToken(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable onlyTokenManager(tokenId) notPaused {
        bytes memory payload;
        if (metadata.length < 4) {
            payload = abi.encode(SELECTOR_SEND_TOKEN, tokenId, destinationAddress, amount);
            _callContract(destinationChain, payload, msg.value, sourceAddress);
            emit TokenSent(tokenId, destinationChain, destinationAddress, amount);
            return;
        }
        uint32 version;
        (version, metadata) = _decodeMetadata(metadata);
        if (version > 0) revert InvalidMetadataVersion(version);
        payload = abi.encode(SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destinationAddress, amount, sourceAddress.toBytes(), metadata);
        _callContract(destinationChain, payload, msg.value, sourceAddress);
        emit TokenSentWithData(tokenId, destinationChain, destinationAddress, amount, sourceAddress, metadata);
    }

    /*************\
    OWNER FUNCTIONS
    \*************/

    /**
     * @notice Used to set a flow limit for a token manager that has the service as its operator.
     * @param tokenIds an array of the token Ids of the tokenManagers to set the flow limit of.
     * @param flowLimits the flowLimits to set
     */
    function setFlowLimit(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external onlyOperator {
        uint256 length = tokenIds.length;
        if (length != flowLimits.length) revert LengthMismatch();
        for (uint256 i; i < length; ++i) {
            ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenIds[i]));
            tokenManager.setFlowLimit(flowLimits[i]);
        }
    }

    /**
     * @notice Used to pause the entire service.
     * @param paused what value to set paused to.
     */
    function setPaused(bool paused) external onlyOwner {
        _setPaused(paused);
    }

    /****************\
    INTERNAL FUNCTIONS
    \****************/

    function _setup(bytes calldata params) internal override {
        _setOperator(params.toAddress());
    }

    function _sanitizeTokenManagerImplementation(
        address[] memory implementaions,
        TokenManagerType tokenManagerType
    ) internal pure returns (address implementation) {
        implementation = implementaions[uint256(tokenManagerType)];
        if (implementation == address(0)) revert ZeroAddress();
        if (ITokenManager(implementation).implementationType() != uint256(tokenManagerType)) revert InvalidTokenManagerImplementation();
    }

    /**
     * @notice Executes operations based on the payload and selector.
     * @param sourceChain The chain where the transaction originates from
     * @param sourceAddress The address where the transaction originates from
     * @param payload The encoded data payload for the transaction
     */
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override onlyRemoteService(sourceChain, sourceAddress) notPaused {
        uint256 selector = abi.decode(payload, (uint256));
        if (selector == SELECTOR_SEND_TOKEN) {
            _processSendTokenPayload(sourceChain, payload);
        } else if (selector == SELECTOR_SEND_TOKEN_WITH_DATA) {
            _processSendTokenWithDataPayload(sourceChain, payload);
        } else if (selector == SELECTOR_DEPLOY_TOKEN_MANAGER) {
            _processDeployTokenManagerPayload(payload);
        } else if (selector == SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN) {
            _processDeployStandardizedTokenAndManagerPayload(payload);
        } else {
            revert SelectorUnknown();
        }
    }

    /**
     * @notice Processes the payload data for a send token call
     * @param sourceChain The chain where the transaction originates from
     * @param payload The encoded data payload to be processed
     */
    function _processSendTokenPayload(string calldata sourceChain, bytes calldata payload) internal {
        (, bytes32 tokenId, bytes memory destinationAddressBytes, uint256 amount) = abi.decode(payload, (uint256, bytes32, bytes, uint256));
        bytes32 commandId;

        assembly {
            commandId := calldataload(4)
        }
        address destinationAddress = destinationAddressBytes.toAddress();
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        address expressCaller = _popExpressReceiveToken(tokenId, destinationAddress, amount, commandId);
        if (expressCaller == address(0)) {
            amount = tokenManager.giveToken(destinationAddress, amount);
            emit TokenReceived(tokenId, sourceChain, destinationAddress, amount);
        } else {
            amount = tokenManager.giveToken(expressCaller, amount);
        }
    }

    /**
     * @notice Processes a send token with data payload.
     * @param sourceChain The chain where the transaction originates from
     * @param payload The encoded data payload to be processed
     */
    function _processSendTokenWithDataPayload(string calldata sourceChain, bytes calldata payload) internal {
        bytes32 tokenId;
        uint256 amount;
        bytes memory sourceAddress;
        bytes memory data;
        address destinationAddress;
        bytes32 commandId;

        assembly {
            commandId := calldataload(4)
        }
        {
            bytes memory destinationAddressBytes;
            (, tokenId, destinationAddressBytes, amount, sourceAddress, data) = abi.decode(
                payload,
                (uint256, bytes32, bytes, uint256, bytes, bytes)
            );
            destinationAddress = destinationAddressBytes.toAddress();
        }
        ITokenManager tokenManager = ITokenManager(getTokenManagerAddress(tokenId));
        {
            address expressCaller = _popExpressReceiveTokenWithData(
                tokenId,
                sourceChain,
                sourceAddress,
                destinationAddress,
                amount,
                data,
                commandId
            );
            if (expressCaller != address(0)) {
                amount = tokenManager.giveToken(expressCaller, amount);
                return;
            }
        }
        amount = tokenManager.giveToken(destinationAddress, amount);
        IInterchainTokenExpressExecutable(destinationAddress).executeWithInterchainToken(sourceChain, sourceAddress, data, tokenId, amount);
        emit TokenReceivedWithData(tokenId, sourceChain, destinationAddress, amount, sourceAddress, data);
    }

    /**
     * @notice Processes a deploy token manager payload.
     * @param payload The encoded data payload to be processed
     */
    function _processDeployTokenManagerPayload(bytes calldata payload) internal {
        (, bytes32 tokenId, TokenManagerType tokenManagerType, bytes memory params) = abi.decode(
            payload,
            (uint256, bytes32, TokenManagerType, bytes)
        );
        _deployTokenManager(tokenId, tokenManagerType, params);
    }

    /**
     * @notice Process a deploy standardized token and manager payload.
     * @param payload The encoded data payload to be processed
     */
    function _processDeployStandardizedTokenAndManagerPayload(bytes calldata payload) internal {
        (
            ,
            bytes32 tokenId,
            string memory name,
            string memory symbol,
            uint8 decimals,
            bytes memory distributorBytes,
            bytes memory operatorBytes
        ) = abi.decode(payload, (uint256, bytes32, string, string, uint8, bytes, bytes));
        address tokenAddress = getStandardizedTokenAddress(tokenId);
        address tokenManagerAddress = getTokenManagerAddress(tokenId);
        address distributor = distributorBytes.length > 0 ? distributorBytes.toAddress() : tokenManagerAddress;
        _deployStandardizedToken(tokenId, distributor, name, symbol, decimals, 0, distributor);
        TokenManagerType tokenManagerType = distributor == tokenManagerAddress ? TokenManagerType.MINT_BURN : TokenManagerType.LOCK_UNLOCK;
        _deployTokenManager(
            tokenId,
            tokenManagerType,
            abi.encode(operatorBytes.length == 0 ? address(this).toBytes() : operatorBytes, tokenAddress)
        );
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called
     * @param payload The data payload for the transaction
     * @param gasValue The amount of gas to be paid for the transaction
     * @param refundTo The address where the unused gas amount should be refunded to
     */
    function _callContract(string calldata destinationChain, bytes memory payload, uint256 gasValue, address refundTo) internal {
        string memory destinationAddress = remoteAddressValidator.getRemoteAddress(destinationChain);
        if (gasValue > 0) {
            gasService.payNativeGasForContractCall{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                refundTo
            );
        }
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    function _validateToken(address tokenAddress) internal returns (string memory name, string memory symbol, uint8 decimals) {
        IERC20Named token = IERC20Named(tokenAddress);
        name = token.name();
        symbol = token.symbol();
        decimals = token.decimals();
    }

    /**
     * @notice Deploys a token manager on a destination chain.
     * @param tokenId The ID of the token
     * @param destinationChain The chain where the token manager will be deployed
     * @param gasValue The amount of gas to be paid for the transaction
     * @param tokenManagerType The type of token manager to be deployed
     * @param params Additional parameters for the token manager deployment
     */
    function _deployRemoteTokenManager(
        bytes32 tokenId,
        string calldata destinationChain,
        uint256 gasValue,
        TokenManagerType tokenManagerType,
        bytes memory params
    ) internal {
        bytes memory payload = abi.encode(SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, tokenManagerType, params);
        _callContract(destinationChain, payload, gasValue, msg.sender);
        emit RemoteTokenManagerDeploymentInitialized(tokenId, destinationChain, gasValue, tokenManagerType, params);
    }

    /**
     * @notice Deploys a standardized token on a destination chain.
     * @param tokenId The ID of the token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     * @param distributor The distributor address for the token
     * @param destinationChain The destination chain where the token will be deployed
     * @param gasValue The amount of gas to be paid for the transaction
     */
    function _deployRemoteStandardizedToken(
        bytes32 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory operator,
        string calldata destinationChain,
        uint256 gasValue
    ) internal {
        bytes memory payload = abi.encode(
            SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
            tokenId,
            name,
            symbol,
            decimals,
            distributor,
            operator
        );
        _callContract(destinationChain, payload, gasValue, msg.sender);
        emit RemoteStandardizedTokenAndManagerDeploymentInitialized(
            tokenId,
            name,
            symbol,
            decimals,
            distributor,
            operator,
            destinationChain,
            gasValue
        );
    }

    /**
     * @notice Deploys a token manager
     * @param tokenId The ID of the token
     * @param tokenManagerType The type of the token manager to be deployed
     * @param params Additional parameters for the token manager deployment
     */
    function _deployTokenManager(bytes32 tokenId, TokenManagerType tokenManagerType, bytes memory params) internal {
        (bool success, ) = tokenManagerDeployer.delegatecall(
            abi.encodeWithSelector(ITokenManagerDeployer.deployTokenManager.selector, tokenId, tokenManagerType, params)
        );
        if (!success) {
            revert TokenManagerDeploymentFailed();
        }
        emit TokenManagerDeployed(tokenId, tokenManagerType, params);
    }

    /**
     * @notice Compute the salt for a standardized token deployment.
     * @param tokenId The ID of the token
     * @return salt The computed salt for the token deployment
     */
    function _getStandardizedTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt) {
        return keccak256(abi.encode(PREFIX_STANDARDIZED_TOKEN_SALT, tokenId));
    }

    /**
     * @notice Deploys a standardized token.
     * @param tokenId The ID of the token
     * @param distributor The distributor address for the token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     * @param mintAmount The amount of tokens to be minted upon deployment
     * @param mintTo The address where the minted tokens will be sent upon deployment
     */
    function _deployStandardizedToken(
        bytes32 tokenId,
        address distributor,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 mintAmount,
        address mintTo
    ) internal {
        bytes32 salt = _getStandardizedTokenSalt(tokenId);
        address tokenManagerAddress = getTokenManagerAddress(tokenId);

        (bool success, ) = standardizedTokenDeployer.delegatecall(
            abi.encodeWithSelector(
                IStandardizedTokenDeployer.deployStandardizedToken.selector,
                salt,
                tokenManagerAddress,
                distributor,
                name,
                symbol,
                decimals,
                mintAmount,
                mintTo
            )
        );
        if (!success) {
            revert StandardizedTokenDeploymentFailed();
        }
        emit StandardizedTokenDeployed(tokenId, name, symbol, decimals, mintAmount, mintTo);
    }

    function _decodeMetadata(bytes calldata metadata) internal pure returns (uint32 version, bytes calldata data) {
        assembly {
            data.length := sub(metadata.length, 4)
            data.offset := add(metadata.offset, 4)
            version := calldataload(sub(metadata.offset, 28))
        }
    }

    function _expressExecuteWithInterchainTokenToken(
        bytes32 tokenId,
        address destinationAddress,
        string memory sourceChain,
        bytes memory sourceAddress,
        bytes calldata data,
        uint256 amount
    ) internal {
        IInterchainTokenExpressExecutable(destinationAddress).expressExecuteWithInterchainToken(
            sourceChain,
            sourceAddress,
            data,
            tokenId,
            amount
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Named is IERC20 {
    /**
     * @notice Getter for the name of the token
     */
    function name() external returns (string memory);

    /**
     * @notice Getter for the symbol of the token
     */
    function symbol() external returns (string memory);

    /**
     * @notice Getter for the decimals of the token
     */
    function decimals() external returns (uint8);
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

/**
 * @title IInterchainTokenExecutable
 * @notice Implement this to accept calls from the InterchainTokenService.
 */
interface IInterchainTokenExecutable {
    /**
     * @notice This will be called after the tokens arrive to this contract
     * @dev You are revert unless the msg.sender is the InterchainTokenService
     * @param sourceChain the name of the source chain
     * @param sourceAddress the address that sent the contract call
     * @param data the data to be proccessed
     * @param tokenId the tokenId of the token manager managing the token. You can access it's address by querrying the service
     * @param amount the amount of token that was sent
     */
    function executeWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenExecutable } from './IInterchainTokenExecutable.sol';

/**
 * @title IInterchainTokenExpressExecutable
 * @notice Implement this to accept express calls from the InterchainTokenService.
 */
interface IInterchainTokenExpressExecutable is IInterchainTokenExecutable {
    /**
     * @notice This will be called after the tokens arrive to this contract
     * @dev You are revert unless the msg.sender is the InterchainTokenService
     * @param sourceChain the name of the source chain
     * @param sourceAddress the address that sent the contract call
     * @param data the data to be proccessed
     * @param tokenId the tokenId of the token manager managing the token. You can access it's address by querrying the service
     * @param amount the amount of token that was sent
     */
    function expressExecuteWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) external;
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

/**
 * @title IRemoteAddressValidator
 * @dev Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract
 */
interface IRemoteAddressValidator {
    error ZeroAddress();
    error LengthMismatch();
    error ZeroStringLength();

    event TrustedAddressAdded(string souceChain, string sourceAddress);
    event TrustedAddressRemoved(string souceChain);
    event GatewaySupportedChainAdded(string chain);
    event GatewaySupportedChainRemoved(string chain);

    /**
     * @dev Validates that the sender is a valid interchain token service address
     * @param sourceChain Source chain of the transaction
     * @param sourceAddress Source address of the transaction
     * @return bool true if the sender is validated, false otherwise
     */
    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool);

    /**
     * @dev Adds a trusted interchain token service address for the specified chain
     * @param sourceChain Chain name of the interchain token service
     * @param sourceAddress Interchain token service address to be added
     */
    function addTrustedAddress(string memory sourceChain, string memory sourceAddress) external;

    /**
     * @dev Removes a trusted interchain token service address
     * @param sourceChain Chain name of the interchain token service to be removed
     */
    function removeTrustedAddress(string calldata sourceChain) external;

    /**
     * @dev Fetches the interchain token service address for the specified chain
     * @param chainName Name of the chain
     * @return remoteAddress Interchain token service address for the specified chain
     */
    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress);

    /**
     * @notice Returns true if the gateway delivers token to this chain.
     * @param chainName Name of the chain
     */
    function supportedByGateway(string calldata chainName) external view returns (bool);

    /**
     * @dev Adds chains that are supported by the Axelar gateway
     * @param chainNames List of chain names to be added as supported
     */
    function addGatewaySupportedChains(string[] calldata chainNames) external;

    /**
     * @dev Removes chains that are no longer supported by the Axelar gateway
     * @param chainNames List of chain names to be removed as supported
     */
    function removeGatewaySupportedChains(string[] calldata chainNames) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

/**
 * @title IStandardizedTokenDeployer
 * @notice This contract is used to deploy new instances of the StandardizedTokenProxy contract.
 */
interface IStandardizedTokenDeployer {
    error AddressZero();
    error TokenDeploymentFailed();

    /**
     * @notice Getter for the Create3Deployer.
     */
    function deployer() external view returns (Create3Deployer);

    /**
     * @notice Deploys a new instance of the StandardizedTokenProxy contract
     * @param salt The salt used by Create3Deployer
     * @param tokenManager Address of the token manager
     * @param distributor Address of the distributor
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param decimals Decimals of the token
     * @param mintAmount Amount of tokens to mint initially
     * @param mintTo Address to mint initial tokens to
     */
    function deployStandardizedToken(
        bytes32 salt,
        address tokenManager,
        address distributor,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address mintTo
    ) external payable;
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

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

/**
 * @title ExpressCallHandler
 * @dev Integrates the interchain token service with the GMP express service by providing methods to handle express calls for
 * token transfers and token transfers with contract calls between chains. Implements the IExpressCallHandler interface.
 */
contract ExpressCallHandler is IExpressCallHandler {
    // uint256(keccak256('prefix-express-give-token'));
    uint256 internal constant PREFIX_EXPRESS_RECEIVE_TOKEN = 0x67c7b41c1cb0375e36084c4ec399d005168e83425fa471b9224f6115af865619;
    // uint256(keccak256('prefix-express-give-token-with-data'));
    uint256 internal constant PREFIX_EXPRESS_RECEIVE_TOKEN_WITH_DATA = 0x3e607cc12a253b1d9f677a03d298ad869a90a8ba4bd0fb5739e7d79db7cdeaad;

    /**
     * @notice Calculates the unique slot for a given express token transfer.
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param commandId The unique hash for this token transfer
     * @return slot The calculated slot for this token transfer
     */
    function _getExpressReceiveTokenSlot(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId
    ) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_EXPRESS_RECEIVE_TOKEN, tokenId, destinationAddress, amount, commandId)));
    }

    /**
     * @notice Calculates the unique slot for a given token transfer with data
     * @param tokenId The ID of the token being sent
     * @param sourceChain The chain from which the token will be sent
     * @param sourceAddress The originating address of the token on the source chain
     * @param destinationAddress The address of the recipient on the destination chain
     * @param amount The amount of tokens to be sent
     * @param data The data associated with the token transfer
     * @param commandId The unique hash for this token transfer
     * @return slot The calculated slot for this token transfer
     */
    function _getExpressReceiveTokenWithDataSlot(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 commandId
    ) internal pure returns (uint256 slot) {
        slot = uint256(
            keccak256(
                abi.encode(
                    PREFIX_EXPRESS_RECEIVE_TOKEN_WITH_DATA,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationAddress,
                    amount,
                    data,
                    commandId
                )
            )
        );
    }

    /**
     * @notice Stores the address of the express caller at the storage slot determined by _getExpressSendTokenSlot
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param commandId The unique hash for this token transfer
     * @param expressCaller The address of the express caller
     */
    function _setExpressReceiveToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId,
        address expressCaller
    ) internal {
        uint256 slot = _getExpressReceiveTokenSlot(tokenId, destinationAddress, amount, commandId);
        address prevExpressCaller;
        assembly {
            prevExpressCaller := sload(slot)
        }
        if (prevExpressCaller != address(0)) revert AlreadyExpressCalled();
        assembly {
            sstore(slot, expressCaller)
        }
        emit ExpressReceive(tokenId, destinationAddress, amount, commandId, expressCaller);
    }

    /**
     * @notice Stores the address of the express caller for a given token transfer with data at
     * the storage slot determined by _getExpressSendTokenWithDataSlot
     * @param tokenId The ID of the token being sent
     * @param sourceChain The chain from which the token will be sent
     * @param sourceAddress The originating address of the token on the source chain
     * @param destinationAddress The address of the recipient on the destination chain
     * @param amount The amount of tokens to be sent
     * @param data The data associated with the token transfer
     * @param commandId The unique hash for this token transfer
     * @param expressCaller The address of the express caller
     */
    function _setExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 commandId,
        address expressCaller
    ) internal {
        uint256 slot = _getExpressReceiveTokenWithDataSlot(
            tokenId,
            sourceChain,
            sourceAddress,
            destinationAddress,
            amount,
            data,
            commandId
        );
        address prevExpressCaller;
        assembly {
            prevExpressCaller := sload(slot)
        }
        if (prevExpressCaller != address(0)) revert AlreadyExpressCalled();
        assembly {
            sstore(slot, expressCaller)
        }
        emit ExpressReceiveWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId, expressCaller);
    }

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
    ) public view returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenSlot(tokenId, destinationAddress, amount, commandId);
        assembly {
            expressCaller := sload(slot)
        }
    }

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
    ) public view returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenWithDataSlot(
            tokenId,
            sourceChain,
            sourceAddress,
            destinationAddress,
            amount,
            data,
            commandId
        );
        assembly {
            expressCaller := sload(slot)
        }
    }

    /**
     * @notice Removes the express caller from storage for a specific token transfer, if it exists.
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function _popExpressReceiveToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId
    ) internal returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenSlot(tokenId, destinationAddress, amount, commandId);
        assembly {
            expressCaller := sload(slot)
        }
        if (expressCaller != address(0)) {
            assembly {
                sstore(slot, 0)
            }
            emit ExpressExecutionFulfilled(tokenId, destinationAddress, amount, commandId, expressCaller);
        }
    }

    /**
     * @notice Removes the express caller from storage for a specific token transfer with data, if it exists.
     * @param tokenId The ID of the token being sent
     * @param sourceChain The chain from which the token will be sent
     * @param sourceAddress The originating address of the token on the source chain
     * @param destinationAddress The address of the recipient on the destination chain
     * @param amount The amount of tokens to be sent
     * @param data The data associated with the token transfer
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function _popExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 commandId
    ) internal returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenWithDataSlot(
            tokenId,
            sourceChain,
            sourceAddress,
            destinationAddress,
            amount,
            data,
            commandId
        );
        assembly {
            expressCaller := sload(slot)
        }
        if (expressCaller != address(0)) {
            assembly {
                sstore(slot, 0)
            }
            emit ExpressExecutionWithDataFulfilled(
                tokenId,
                sourceChain,
                sourceAddress,
                destinationAddress,
                amount,
                data,
                commandId,
                expressCaller
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMulticall } from '../interfaces/IMulticall.sol';

/**
 * @title Multicall
 * @notice This contract is a multi-functional smart contract which allows for multiple
 * contract calls in a single transaction.
 */
contract Multicall is IMulticall {
    error MulticallFailed(bytes err);

    /**
     * @notice Performs multiple delegate calls and returns the results of all calls as an array
     * @dev This function requires that the contract has sufficient balance for the delegate calls.
     * If any of the calls fail, the function will revert with the failure message.
     * @param data An array of encoded function calls
     * @return results An bytes array with the return data of each function call
     */
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; ++i) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                revert(string(result));
            }

            results[i] = result;
        }
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IPausable } from '../interfaces/IPausable.sol';

/**
 * @title Pausable
 * @notice This contract provides a mechanism to halt the execution of specific functions
 * if a pause condition is activated.
 */
contract Pausable is IPausable {
    // uint256(keccak256('paused')) - 1
    uint256 internal constant PAUSE_SLOT = 0xee35723ac350a69d2a92d3703f17439cbaadf2f093a21ba5bf5f1a53eb2a14d8;

    /**
     * @notice A modifier that throws a Paused custom error if the contract is paused
     * @dev This modifier should be used with functions that can be paused
     */
    modifier notPaused() {
        if (isPaused()) revert Paused();
        _;
    }

    /**
     * @notice Check if the contract is paused
     * @return paused A boolean representing the pause status. True if paused, false otherwise.
     */
    function isPaused() public view returns (bool paused) {
        assembly {
            paused := sload(PAUSE_SLOT)
        }
    }

    /**
     * @notice Sets the pause status of the contract
     * @dev This is an internal function, meaning it can only be called from within the contract itself
     * or from derived contracts.
     * @param paused The new pause status
     */
    function _setPaused(bool paused) internal {
        assembly {
            sstore(PAUSE_SLOT, paused)
        }

        emit PausedSet(paused);
    }
}