// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

import "../BaseModule.sol";
import "./IBaseSecurityControlModule.sol";
import "../../trustedContractManager/ITrustedContractManager.sol";

// refer to: https://solidity-by-example.org/app/time-lock/

abstract contract BaseSecurityControlModule is IBaseSecurityControlModule, BaseModule {
    uint256 public constant MIN_DELAY = 1 days;
    uint256 public constant MAX_DELAY = 14 days;

    mapping(bytes32 => Tx) private queued;
    mapping(address => WalletConfig) private walletConfigs;

    uint128 private __seed;

    function _newSeed() private returns (uint128) {
        return ++__seed;
    }

    function _authorized(address _target) private view {
        address _sender = sender();
        if (_sender != _target && !ISoulWallet(_target).isOwner(_sender)) {
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
pragma solidity ^0.8.17;

interface ITrustedContractManager {
    event TrustedContractAdded(address indexed module);
    event TrustedContractRemoved(address indexed module);
    function isTrustedContract(address addr) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IModule.sol";

interface IModuleManager {
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);
    event ModuleRemovedWithError(address indexed module);

    function addModule(bytes calldata moduleAndData) external;

    function removeModule(address) external;

    function isAuthorizedModule(address module) external returns (bool);

    function listModule() external view returns (address[] memory modules, bytes4[][] memory selectors);

    function executeFromModule(address dest, uint256 value, bytes calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IPlugin.sol";

interface IPluginManager {
    event PluginAdded(address indexed plugin);
    event PluginRemoved(address indexed plugin);
    event PluginRemovedWithError(address indexed plugin);

    function addPlugin(bytes calldata pluginAndData) external;

    function removePlugin(address plugin) external;

    function isAuthorizedPlugin(address plugin) external returns (bool);

    function listPlugin(uint8 hookType) external view returns (address[] memory plugins);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/IModule.sol";
import "../interfaces/ISoulWallet.sol";
import "../interfaces/IModuleManager.sol";

abstract contract BaseModule is IModule {
    event ModuleInit(address indexed wallet);
    event ModuleDeInit(address indexed wallet);

    function inited(address wallet) internal view virtual returns (bool);

    function _init(bytes calldata data) internal virtual;

    function _deInit() internal virtual;

    function sender() internal view returns (address) {
        return msg.sender;
    }

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

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IModule).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

import "./IPluggable.sol";

interface IModule is IPluggable {
    function requiredFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "./IPluggable.sol";

interface IPlugin is IPluggable {
    /**
     * @dev
     * hookType structure:
     * GuardHook: 1<<0
     * PreHook:   1<<1
     * PostHook:  1<<2
     */
    function supportsHook() external pure returns (uint8 hookType);

    /**
     * @dev For flexibility, guardData does not participate in the userOp signature verification.
     *      Plugins must revert when they do not need guardData but guardData.length > 0(for security reasons)
     */
    function guardHook(UserOperation calldata userOp, bytes32 userOpHash, bytes calldata guardData) external;

    function preHook(address target, uint256 value, bytes calldata data) external;

    function postHook(address target, uint256 value, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IExecutionManager.sol";
import "./IModuleManager.sol";
import "./IOwnerManager.sol";
import "./IPluginManager.sol";
import "./IFallbackManager.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "./IUpgradable.sol";

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPluggable is IERC165 {
    function walletInit(bytes calldata data) external;
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
pragma solidity ^0.8.17;

interface IExecutionManager {
    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external;

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external;

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IOwnerManager {
    event OwnerCleared();
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    function isOwner(address addr) external view returns (bool);

    function resetOwner(address newOwner) external;

    function addOwner(address owner) external;

    function addOwners(address[] calldata owners) external;

    function resetOwners(address[] calldata newOwners) external;

    function removeOwner(address owner) external;

    function listOwner() external returns (address[] memory owners);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IFallbackManager {
    event FallbackChanged(address indexed fallbackContract);

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
pragma solidity ^0.8.17;

interface IUpgradable {
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);

    function upgradeTo(address newImplementation) external;
    function upgradeFrom(address oldImplementation) external;
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