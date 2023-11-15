// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./BaseSecurityControlModule.sol";
import "../../trustedContractManager/ITrustedContractManager.sol";
import "../../interfaces/IModuleManager.sol";
import "../../interfaces/IPluginManager.sol";

contract SecurityControlModule is BaseSecurityControlModule {
    error UnsupportedSelectorError(bytes4 selector);
    error RemoveSelfError();

    ITrustedContractManager public immutable trustedModuleManager;
    ITrustedContractManager public immutable trustedPluginManager;

    constructor(ITrustedContractManager _trustedModuleManager, ITrustedContractManager _trustedPluginManager) {
        trustedModuleManager = _trustedModuleManager;
        trustedPluginManager = _trustedPluginManager;
    }

    function _preExecute(address _target, bytes calldata _data, bytes32 _txId) internal override {
        bytes4 _func = bytes4(_data[0:4]);
        if (_func == IModuleManager.addModule.selector) {
            address _module = address(bytes20(_data[68:88])); // 4 sig + 32 bytes + 32 bytes
            if (!trustedModuleManager.isTrustedContract(_module)) {
                super._preExecute(_target, _data, _txId);
            }
        } else if (_func == IPluginManager.addPlugin.selector) {
            address _plugin = address(bytes20(_data[68:88])); // 4 sig + 32 bytes + 32 bytes
            if (!trustedPluginManager.isTrustedContract(_plugin)) {
                super._preExecute(_target, _data, _txId);
            }
        } else if (_func == IModuleManager.removeModule.selector) {
            (address _module) = abi.decode(_data[4:], (address));
            if (_module == address(this)) {
                revert RemoveSelfError();
            }
            super._preExecute(_target, _data, _txId);
        } else if (_func == IPluginManager.removePlugin.selector) {
            super._preExecute(_target, _data, _txId);
        } else {
            revert UnsupportedSelectorError(_func);
        }
    }

    function requiredFunctions() external pure override returns (bytes4[] memory) {
        bytes4[] memory _funcs = new bytes4[](4);
        _funcs[0] = IModuleManager.addModule.selector;
        _funcs[1] = IPluginManager.addPlugin.selector;
        _funcs[2] = IModuleManager.removeModule.selector;
        _funcs[3] = IPluginManager.removePlugin.selector;
        return _funcs;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../BaseModule.sol";
import "./IBaseSecurityControlModule.sol";
import "../../trustedContractManager/ITrustedContractManager.sol";
import "../../libraries/TypeConversion.sol";

// refer to: https://solidity-by-example.org/app/time-lock/

abstract contract BaseSecurityControlModule is IBaseSecurityControlModule, BaseModule {
    uint256 public constant MIN_DELAY = 1 seconds;
    uint256 public constant MAX_DELAY = 14 days;

    using TypeConversion for address;

    mapping(bytes32 => Tx) private queued;
    mapping(address => WalletConfig) private walletConfigs;

    uint128 private __seed;

    function _newSeed() private returns (uint128) {
        return ++__seed;
    }

    function _authorized(address _target) private view {
        address _sender = sender();
        if (_sender != _target && !ISoulWallet(_target).isOwner(_sender.toBytes32())) {
            revert NotOwnerError();
        }
        if (walletConfigs[_target].seed == 0) {
            revert NotInitializedError();
        }
    }

    function inited(address _target) internal view override returns (bool) {
        return walletConfigs[_target].seed != 0;
    }

    function _init(bytes calldata data) internal override {
        uint64 _delay = abi.decode(data, (uint64));
        require(_delay >= MIN_DELAY && _delay <= MAX_DELAY);
        address _target = sender();
        walletConfigs[_target] = WalletConfig(_newSeed(), _delay);
    }

    function _deInit() internal override {
        address _target = sender();
        walletConfigs[_target] = WalletConfig(0, 0);
    }

    function _getTxId(uint128 _seed, address _target, bytes calldata _data) private view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this), _seed, _target, _data));
    }

    function getTxId(uint128 _seed, address _target, bytes calldata _data) public view override returns (bytes32) {
        return _getTxId(_seed, _target, _data);
    }

    function getWalletConfig(address _target) external view override returns (WalletConfig memory) {
        return walletConfigs[_target];
    }

    function queue(address _target, bytes calldata _data) external virtual override returns (bytes32 txId) {
        _authorized(_target);
        WalletConfig memory walletConfig = walletConfigs[_target];
        txId = _getTxId(walletConfig.seed, _target, _data);
        if (queued[txId].target != address(0)) {
            revert AlreadyQueuedError(txId);
        }
        uint256 _timestamp = block.timestamp + walletConfig.delay;
        queued[txId] = Tx(_target, uint128(_timestamp));
        emit Queue(txId, _target, sender(), _data, _timestamp);
    }

    function cancel(bytes32 _txId) external virtual override {
        Tx memory _tx = queued[_txId];
        if (_tx.target == address(0)) {
            revert NotQueuedError(_txId);
        }
        _authorized(_tx.target);

        queued[_txId] = Tx(address(0), 0);
        emit Cancel(_txId, sender());
    }

    function cancelAll(address target) external virtual override {
        _authorized(target);
        address _sender = sender();
        walletConfigs[target].seed = _newSeed();
        emit CancelAll(target, _sender);
    }

    function _preExecute(address _target, bytes calldata _data, bytes32 _txId) internal virtual {
        (_target, _data);
        Tx memory _tx = queued[_txId];
        uint256 validAfter = _tx.validAfter;
        if (validAfter == 0) {
            revert NotQueuedError(_txId);
        }
        if (block.timestamp < validAfter) {
            revert TimestampNotPassedError(block.timestamp, validAfter);
        }
        queued[_txId] = Tx(address(0), 0);
    }

    function execute(address _target, bytes calldata _data) external virtual override {
        _authorized(_target);
        WalletConfig memory walletConfig = walletConfigs[_target];
        bytes32 txId = _getTxId(walletConfig.seed, _target, _data);
        _preExecute(_target, _data, txId);
        (bool succ, bytes memory ret) = _target.call{value: 0}(_data);
        if (succ) {
            emit Execute(txId, _target, sender(), _data);
        } else {
            revert ExecuteError(txId, _target, sender(), _data, ret);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title ITrustedContractManager Interface
 * @dev This interface defines methods and events for managing trusted contracts
 */
interface ITrustedContractManager {
    /**
     * @dev Emitted when a new trusted contract (module) is added
     * @param module Address of the trusted contract added
     */
    event TrustedContractAdded(address indexed module);
    /**
     * @dev Emitted when a trusted contract (module) is removed
     * @param module Address of the trusted contract removed
     */
    event TrustedContractRemoved(address indexed module);
    /**
     * @notice Checks if the specified address is a trusted contract
     * @param addr Address to check
     * @return Returns true if the address is a trusted contract, false otherwise
     */

    function isTrustedContract(address addr) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IModule.sol";

/**
 * @title Module Manager Interface
 * @dev This interface defines the management functionalities for handling modules
 * within the system. Modules are components that can be added to or removed from the
 * smart contract to extend its functionalities. The manager ensures that only authorized
 * modules can execute certain functionalities
 */
interface IModuleManager {
    /**
     * @notice Emitted when a new module is successfully added
     * @param module The address of the newly added module
     */
    event ModuleAdded(address indexed module);
    /**
     * @notice Emitted when a module is successfully removed
     * @param module The address of the removed module
     */
    event ModuleRemoved(address indexed module);
    /**
     * @notice Emitted when there's an error while removing a module
     * @param module The address of the module that was attempted to be removed
     */
    event ModuleRemovedWithError(address indexed module);

    /**
     * @notice Adds a new module to the system
     * @param moduleAndData The module to be added and its associated initialization data
     */
    function addModule(bytes calldata moduleAndData) external;
    /**
     * @notice Removes a module from the system
     * @param  module The address of the module to be removed
     */
    function removeModule(address module) external;

    /**
     * @notice Checks if a module is authorized within the system
     * @param module The address of the module to check
     * @return True if the module is authorized, false otherwise
     */
    function isAuthorizedModule(address module) external returns (bool);
    /**
     * @notice Provides a list of all added modules and their respective authorized function selectors
     * @return modules An array of the addresses of all added modules
     * @return selectors A 2D array where each inner array represents the function selectors
     * that the corresponding module in the 'modules' array is allowed to call
     */
    function listModule() external view returns (address[] memory modules, bytes4[][] memory selectors);
    /**
     * @notice Allows a module to execute a function within the system. This ensures that the
     * module can only call functions it is permitted to, based on its declared `requiredFunctions`
     * @param dest The address of the destination contract where the function will be executed
     * @param value The amount of ether (in wei) to be sent with the function call
     * @param func The function data to be executed
     */
    function executeFromModule(address dest, uint256 value, bytes calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IPlugin.sol";

/**
 * @title Plugin Manager Interface
 * @dev This interface provides functionalities for adding, removing, and querying plugins
 */
interface IPluginManager {
    event PluginAdded(address indexed plugin);
    event PluginRemoved(address indexed plugin);
    event PluginRemovedWithError(address indexed plugin);

    /**
     * @notice Add a new plugin along with its initialization data
     * @param pluginAndData The plugin address concatenated with its initialization data
     */
    function addPlugin(bytes calldata pluginAndData) external;

    /**
     * @notice Remove a plugin from the system
     * @param plugin The address of the plugin to be removed
     */
    function removePlugin(address plugin) external;

    /**
     * @notice Checks if a plugin is authorized
     * @param plugin The address of the plugin to check
     * @return True if the plugin is authorized, otherwise false
     */
    function isAuthorizedPlugin(address plugin) external returns (bool);

    /**
     * @notice List all plugins of a specific hook type
     * @param hookType The type of the hook for which to list plugins
     * @return plugins An array of plugin addresses corresponding to the hookType
     */
    function listPlugin(uint8 hookType) external view returns (address[] memory plugins);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../interfaces/IModule.sol";
import "../interfaces/ISoulWallet.sol";
import "../interfaces/IModuleManager.sol";

/**
 * @title BaseModule
 * @notice An abstract base contract that provides a foundation for other modules.
 * It ensures the initialization, de-initialization, and proper authorization of modules.
 */
abstract contract BaseModule is IModule {
    event ModuleInit(address indexed wallet);
    event ModuleDeInit(address indexed wallet);
    /**
     * @notice Checks if the module is initialized for a particular wallet.
     * @param wallet Address of the wallet.
     * @return True if the module is initialized, false otherwise.
     */

    function inited(address wallet) internal view virtual returns (bool);
    /**
     * @notice Initialization logic for the module.
     * @param data Initialization data for the module.
     */
    function _init(bytes calldata data) internal virtual;
    /**
     * @notice De-initialization logic for the module.
     */
    function _deInit() internal virtual;
    /**
     * @notice Helper function to get the sender of the transaction.
     * @return Address of the transaction sender.
     */

    function sender() internal view returns (address) {
        return msg.sender;
    }
    /**
     * @notice Initializes the module for a wallet.
     * @param data Initialization data for the module.
     */

    function walletInit(bytes calldata data) external {
        address _sender = sender();
        if (!inited(_sender)) {
            if (!ISoulWallet(_sender).isAuthorizedModule(address(this))) {
                revert("not authorized module");
            }
            _init(data);
            emit ModuleInit(_sender);
        }
    }
    /**
     * @notice De-initializes the module for a wallet.
     */

    function walletDeInit() external {
        address _sender = sender();
        if (inited(_sender)) {
            if (ISoulWallet(_sender).isAuthorizedModule(address(this))) {
                revert("authorized module");
            }
            _deInit();
            emit ModuleDeInit(_sender);
        }
    }
    /**
     * @notice Verifies if the module supports a specific interface.
     * @param interfaceId ID of the interface to be checked.
     * @return True if the module supports the given interface, false otherwise.
     */

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IModule).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IBaseSecurityControlModule {
    error NotInitializedError();
    error NotOwnerError();
    error AlreadyQueuedError(bytes32 txId);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint256 blockTimestmap, uint256 timestamp);
    error ExecuteError(bytes32 txId, address target, address sender, bytes data, bytes returnData);

    event Queue(bytes32 indexed txId, address indexed target, address sender, bytes data, uint256 timestamp);
    event Cancel(bytes32 indexed txId, address sender);
    event CancelAll(address indexed target, address sender);
    event Execute(bytes32 indexed txId, address indexed target, address sender, bytes data);

    struct Tx {
        address target;
        uint128 validAfter;
    }

    struct WalletConfig {
        uint128 seed;
        uint64 delay;
    }

    function getTxId(uint128 _seed, address _target, bytes calldata _data) external view returns (bytes32);

    function getWalletConfig(address _target) external view returns (WalletConfig memory);

    function queue(address _target, bytes calldata _data) external returns (bytes32);

    function cancel(bytes32 _txId) external;

    function cancelAll(address _target) external;

    function execute(address _target, bytes calldata _data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
/**
 * @title TypeConversion
 * @notice A library to facilitate address to bytes32 conversions
 */

library TypeConversion {
    /**
     * @notice Converts an address to bytes32
     * @param addr The address to be converted
     * @return Resulting bytes32 representation of the input address
     */
    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
    /**
     * @notice Converts an array of addresses to an array of bytes32
     * @param addresses Array of addresses to be converted
     * @return Array of bytes32 representations of the input addresses
     */

    function addressesToBytes32Array(address[] memory addresses) internal pure returns (bytes32[] memory) {
        bytes32[] memory result = new bytes32[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            result[i] = toBytes32(addresses[i]);
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IPluggable.sol";

/**
 * @title Module Interface
 * @dev This interface defines the funcations that a module needed access in the smart contract wallet
 * Modules are key components that can be plugged into the main contract to enhance its functionalities
 * For security reasons, a module can only call functions in the smart contract that it has explicitly
 * listed via the `requiredFunctions` method
 */
interface IModule is IPluggable {
    /**
     * @notice Provides a list of function selectors that the module is allowed to call
     * within the smart contract. When a module is added to the smart contract, it's restricted
     * to only call these functions. This ensures that modules have explicit and limited permissions,
     * enhancing the security of the smart contract (e.g., a "Daily Limit" module shouldn't be able to
     * change the owner)
     *
     * @return An array of function selectors that this module is permitted to call
     */
    function requiredFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "./IPluggable.sol";

/**
 * @title Plugin Interface
 * @dev This interface provides functionalities for hooks and interactions of plugins within a wallet or contract
 */
interface IPlugin is IPluggable {
    /**
     * @notice Specifies the types of hooks a plugin supports
     * @return hookType An 8-bit value where:
     *         - GuardHook is represented by 1<<0
     *         - PreHook is represented by 1<<1
     *         - PostHook is represented by 1<<2
     */
    function supportsHook() external pure returns (uint8 hookType);

    /**
     * @notice A hook that guards the user operation
     * @dev For security, plugins should revert when they do not need guardData but guardData.length > 0
     * @param userOp The user operation being performed
     * @param userOpHash The hash of the user operation
     * @param guardData Additional data for the guard
     */
    function guardHook(UserOperation calldata userOp, bytes32 userOpHash, bytes calldata guardData) external;

    /**
     * @notice A hook that's executed before the actual operation
     * @param target The target address of the operation
     * @param value The amount of ether (in wei) involved in the operation
     * @param data The calldata for the operation
     */
    function preHook(address target, uint256 value, bytes calldata data) external;

    /**
     * @notice A hook that's executed after the actual operation
     * @param target The target address of the operation
     * @param value The amount of ether (in wei) involved in the operation
     * @param data The calldata for the operation
     */
    function postHook(address target, uint256 value, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IExecutionManager.sol";
import "./IModuleManager.sol";
import "./IOwnerManager.sol";
import "./IPluginManager.sol";
import "./IFallbackManager.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "./IUpgradable.sol";

/**
 * @title SoulWallet Interface
 * @dev This interface aggregates multiple sub-interfaces to represent the functionalities of the SoulWallet
 * It encompasses account management, execution management, module management, owner management, plugin management,
 * fallback management, and upgradeability
 */
interface ISoulWallet is
    IAccount,
    IExecutionManager,
    IModuleManager,
    IOwnerManager,
    IPluginManager,
    IFallbackManager,
    IUpgradable
{}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Pluggable Interface
 * @dev This interface provides functionalities for initializing and deinitializing wallet-related plugins or modules
 */
interface IPluggable is IERC165 {
    /**
     * @notice Initializes a specific module or plugin for the wallet with the provided data
     * @param data Initialization data required for the module or plugin
     */
    function walletInit(bytes calldata data) external;

    /**
     * @notice Deinitializes a specific module or plugin from the wallet
     */
    function walletDeInit() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import {calldataKeccak} from "../core/Helpers.sol";

/**
 * User Operation struct
 * @param sender the sender account of this request.
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor/
     * @param callData the method call to execute on this account.
     * @param callGasLimit the gas limit passed to the callData method call.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter.
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
     * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = calldataKeccak(userOp.initCode);
        bytes32 hashCallData = calldataKeccak(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        uint256 preVerificationGas = userOp.preVerificationGas;
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

        return abi.encode(
            sender, nonce,
            hashInitCode, hashCallData,
            callGasLimit, verificationGasLimit, preVerificationGas,
            maxFeePerGas, maxPriorityFeePerGas,
            hashPaymasterAndData
        );
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IExecutionManager
 * @dev Interface for executing transactions or batch of transactions
 * The execution can be a single transaction or multiple transactions in sequence
 */
interface IExecutionManager {
    /**
     * @notice Executes a single transaction
     * @dev This can be invoked directly by the owner or by an entry point
     *
     * @param dest The destination address for the transaction
     * @param value The amount of Ether (in wei) to transfer along with the transaction. Can be 0 for non-ETH transfers
     * @param func The function call data to be executed
     */
    function execute(address dest, uint256 value, bytes calldata func) external;

    /**
     * @notice Executes a sequence of transactions with the same Ether value for each
     * @dev All transactions in the batch will carry 0 Ether value
     * @param dest An array of destination addresses for each transaction in the batch
     * @param func An array of function call data for each transaction in the batch
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external;

    /**
     * @notice Executes a sequence of transactions with specified Ether values for each
     * @dev The values for Ether transfer are specified for each transaction
     * @param dest An array of destination addresses for each transaction in the batch
     * @param value An array of amounts of Ether (in wei) to transfer for each transaction in the batch
     * @param func An array of function call data for each transaction in the batch
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Owner Manager Interface
 * @dev This interface defines the management functionalities for handling owners within the system.
 * Owners are identified by a unique bytes32 ID. This design allows for a flexible representation
 * of ownership – whether it be an Ethereum address, a hash of an off-chain public key, or any other
 * unique identifier.
 */
interface IOwnerManager {
    /**
     * @notice Emitted when a new owner is successfully added
     * @param owner The bytes32 ID of the newly added owner
     */
    event OwnerAdded(bytes32 indexed owner);

    /**
     * @notice Emitted when an owner is successfully removed
     * @param owner The bytes32 ID of the removed owner
     */
    event OwnerRemoved(bytes32 indexed owner);

    /**
     * @notice Emitted when all owners are cleared from the system
     */
    event OwnerCleared();

    /**
     * @notice Checks if a given bytes32 ID corresponds to an owner within the system
     * @param owner The bytes32 ID to check
     * @return True if the ID corresponds to an owner, false otherwise
     */
    function isOwner(bytes32 owner) external view returns (bool);

    /**
     * @notice Adds a new owner to the system
     * @param owner The bytes32 ID of the owner to be added
     */
    function addOwner(bytes32 owner) external;

    /**
     * @notice Removes an existing owner from the system
     * @param owner The bytes32 ID of the owner to be removed
     */
    function removeOwner(bytes32 owner) external;

    /**
     * @notice Resets the entire owner set, replacing it with a single new owner
     * @param newOwner The bytes32 ID of the new owner
     */
    function resetOwner(bytes32 newOwner) external;

    /**
     * @notice Adds multiple new owners to the system
     * @param owners An array of bytes32 IDs representing the owners to be added
     */
    function addOwners(bytes32[] calldata owners) external;

    /**
     * @notice Resets the entire owner set, replacing it with a new set of owners
     * @param newOwners An array of bytes32 IDs representing the new set of owners
     */
    function resetOwners(bytes32[] calldata newOwners) external;

    /**
     * @notice Provides a list of all added owners
     * @return owners An array of bytes32 IDs representing the owners
     */
    function listOwner() external view returns (bytes32[] memory owners);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IFallbackManager
 * @dev Interface for setting and managing the fallback contract.
 * The fallback contract is called when no other function matches the provided function signature.
 */
interface IFallbackManager {
    /**
     * @notice Emitted when the fallback contract is changed
     * @param fallbackContract The address of the newly set fallback contract
     */
    event FallbackChanged(address indexed fallbackContract);
    /**
     * @notice Set a new fallback contract
     * @dev This function allows setting a new address as the fallback contract. The fallback contract will receive
     * all calls made to this contract that do not match any other function
     * @param fallbackContract The address of the fallback contract to be set
     */

    function setFallbackHandler(address fallbackContract) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

interface IAccount {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
     * This allows making a "simulation call" without a valid signature
     * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Upgradable Interface
 * @dev This interface provides functionalities to upgrade the implementation of a contract
 * It emits an event when the implementation is changed, either to a new version or from an old version
 */
interface IUpgradable {
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);

    /**
     * @dev Upgrade the current implementation to the provided new implementation address
     * @param newImplementation The address of the new contract implementation
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @dev Upgrade from the current implementation, given the old implementation address
     * @param oldImplementation The address of the old contract implementation that is being replaced
     */
    function upgradeFrom(address oldImplementation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`
 * @param aggregator - address(0) - the account validated the signature by itself.
 *              address(1) - the account failed to validate the signature.
 *              otherwise - this is an address of a signature aggregator that must be used to validate the signature.
 * @param validAfter - this UserOp is valid only after this timestamp.
 * @param validaUntil - this UserOp is valid only up to this timestamp.
 */
    struct ValidationData {
        address aggregator;
        uint48 validAfter;
        uint48 validUntil;
    }

//extract sigFailed, validAfter, validUntil.
// also convert zero validUntil to type(uint48).max
    function _parseValidationData(uint validationData) pure returns (ValidationData memory data) {
        address aggregator = address(uint160(validationData));
        uint48 validUntil = uint48(validationData >> 160);
        if (validUntil == 0) {
            validUntil = type(uint48).max;
        }
        uint48 validAfter = uint48(validationData >> (48 + 160));
        return ValidationData(aggregator, validAfter, validUntil);
    }

// intersect account and paymaster ranges.
    function _intersectTimeRange(uint256 validationData, uint256 paymasterValidationData) pure returns (ValidationData memory) {
        ValidationData memory accountValidationData = _parseValidationData(validationData);
        ValidationData memory pmValidationData = _parseValidationData(paymasterValidationData);
        address aggregator = accountValidationData.aggregator;
        if (aggregator == address(0)) {
            aggregator = pmValidationData.aggregator;
        }
        uint48 validAfter = accountValidationData.validAfter;
        uint48 validUntil = accountValidationData.validUntil;
        uint48 pmValidAfter = pmValidationData.validAfter;
        uint48 pmValidUntil = pmValidationData.validUntil;

        if (validAfter < pmValidAfter) validAfter = pmValidAfter;
        if (validUntil > pmValidUntil) validUntil = pmValidUntil;
        return ValidationData(aggregator, validAfter, validUntil);
    }

/**
 * helper to pack the return value for validateUserOp
 * @param data - the ValidationData to pack
 */
    function _packValidationData(ValidationData memory data) pure returns (uint256) {
        return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
    }

/**
 * helper to pack the return value for validateUserOp, when not using an aggregator
 * @param sigFailed - true for signature failure, false for success
 * @param validUntil last timestamp this UserOperation is valid (or zero for infinite)
 * @param validAfter first timestamp this UserOperation is valid
 */
    function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256) {
        return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48));
    }

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
    function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }