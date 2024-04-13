pragma solidity ^0.8.0;

import "kernel/sdk/moduleBase/PolicyBase.sol";
import "kernel/utils/ExecLib.sol";
import {IERC7579Account} from "kernel/interfaces/IERC7579Account.sol";

struct Permission {
    CallType callType; // calltype can be CALLTYPE_SINGLE/CALLTYPE_DELEGATECALL
    address target;
    bytes4 selector;
    uint256 valueLimit;
    ParamRule[] rules;
}

struct ParamRule {
    ParamCondition condition;
    uint64 offset;
    bytes32 param;
}

enum ParamCondition {
    EQUAL,
    GREATER_THAN,
    LESS_THAN,
    GREATER_THAN_OR_EQUAL,
    LESS_THAN_OR_EQUAL,
    NOT_EQUAL
}

enum Status {
    NA,
    Live,
    Deprecated
}

contract CallPolicy is PolicyBase {
    error InvalidCallType();
    error CallViolatesParamRule();
    error CallViolatesValueRule();
    mapping(address => uint256) public usedIds;
    mapping(bytes32 id => mapping(address => Status)) public status;
    mapping(bytes32 id => mapping(bytes32 permissionHash => mapping(address => bytes))) public encodedPermissions;

    function isInitialized(address wallet) external view override returns (bool) {
        return usedIds[wallet] > 0;
    }

    function checkUserOpPolicy(bytes32 id, PackedUserOperation calldata userOp)
        external
        payable
        override
        returns (uint256)
    {
        require(bytes4(userOp.callData[0:4]) == IERC7579Account.execute.selector);
        ExecMode mode = ExecMode.wrap(bytes32(userOp.callData[4:36]));
        (CallType callType, ExecType execType,,) = ExecLib.decode(mode);
        bytes calldata executionCallData = userOp.callData; // Cache calldata here
        assembly {
            executionCallData.offset := add(add(executionCallData.offset, 0x24), calldataload(add(executionCallData.offset, 0x24)))
            executionCallData.length := calldataload(sub(executionCallData.offset, 0x20))
        }
        if(callType == CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes calldata callData) = ExecLib.decodeSingle(executionCallData);
            bool permissionPass = _checkPermission(msg.sender, id, CALLTYPE_SINGLE, target, callData, value);
            if(!permissionPass) {
                revert CallViolatesParamRule();
            }
        } else if(callType == CALLTYPE_BATCH) {
            Execution[] calldata exec = ExecLib.decodeBatch(executionCallData);
            for(uint256 i = 0; i < exec.length; i++) {
                bool permissionPass = _checkPermission(msg.sender, id, CALLTYPE_SINGLE, exec[i].target, exec[i].callData, exec[i].value);
                if(!permissionPass) {
                    revert CallViolatesParamRule();
                }
            }
        } else if(callType == CALLTYPE_DELEGATECALL) {
            (address target, uint256 value, bytes calldata callData) = ExecLib.decodeSingle(executionCallData);
            bool permissionPass = _checkPermission(msg.sender, id, CALLTYPE_DELEGATECALL, target, callData, value);
            if(!permissionPass) {
                revert CallViolatesParamRule();
            }
        } else {
            revert InvalidCallType();
        }
    }

    function _checkPermission(address wallet, bytes32 id, CallType callType, address target, bytes calldata data, uint256 value) internal returns(bool){
        bytes32 permissionHash = keccak256(abi.encodePacked(callType, target, bytes4(data[0:4])));
        (uint256 allowedValue, ParamRule[] memory rules) = abi.decode(encodedPermissions[id][permissionHash][wallet], (uint256, ParamRule[]));
        if(value > allowedValue) {
            revert CallViolatesValueRule();
        }
        for (uint256 i = 0; i < rules.length; i++) {
            ParamRule memory rule = rules[i];
            bytes32 param = bytes32(data[4 + rule.offset:4 + rule.offset + 32]);
            if (rule.condition == ParamCondition.EQUAL && param != rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.GREATER_THAN && param <= rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.LESS_THAN && param >= rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.GREATER_THAN_OR_EQUAL && param < rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.LESS_THAN_OR_EQUAL && param > rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.NOT_EQUAL && param == rule.param) {
                return false;
            }
        }
        return true;
    }

    function checkSignaturePolicy(bytes32 id, address sender, bytes32 hash, bytes calldata sig)
        external
        view
        override
        returns (uint256)
    {
        require(status[id][msg.sender] == Status.Live);
        return 0;
    }

    function _parsePermission(bytes calldata _sig) internal pure returns(Permission[] calldata permissions) {
        assembly {
            permissions.offset := add(add(_sig.offset,32), calldataload(_sig.offset))
            permissions.length := calldataload(sub(permissions.offset, 32))
        }
    }


    function _policyOninstall(bytes32 id, bytes calldata _data) internal override {
        require(status[id][msg.sender] == Status.NA);
        Permission[] calldata permissions = _parsePermission(_data);
        for(uint256 i = 0; i<permissions.length; i++) {
            bytes32 permissionHash = keccak256(abi.encodePacked(permissions[i].callType, permissions[i].target, permissions[i].selector));
            require(encodedPermissions[id][permissionHash][msg.sender].length == 0, "duplicate permissionHash");
            encodedPermissions[id][permissionHash][msg.sender] = abi.encode(permissions[i].valueLimit, permissions[i].rules);
        }
        status[id][msg.sender] = Status.Live;
        usedIds[msg.sender]++;
    }

    function _policyOnUninstall(bytes32 id, bytes calldata _data) internal override {
        require(status[id][msg.sender] == Status.Live);
        //delete encodedPermissions[id][msg.sender];
        status[id][msg.sender] = Status.Deprecated;
        usedIds[msg.sender]--;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPolicy} from "../../interfaces/IERC7579Modules.sol";
import {PackedUserOperation} from "../../interfaces/PackedUserOperation.sol";

abstract contract PolicyBase is IPolicy {
    function onInstall(bytes calldata data) external payable {
        bytes32 id = bytes32(data[0:32]);
        bytes calldata _data = data[32:];
        _policyOninstall(id, _data);
    }

    function onUninstall(bytes calldata data) external payable {
        bytes32 id = bytes32(data[0:32]);
        bytes calldata _data = data[32:];
        _policyOnUninstall(id, _data);
    }

    function isModuleType(uint256 id) external pure returns (bool) {
        return id == 5;
    }

    function isInitialized(address) external view virtual returns (bool); // TODO : not sure if this is the right way to do it
    function checkUserOpPolicy(bytes32 id, PackedUserOperation calldata userOp)
        external
        payable
        virtual
        returns (uint256);
    function checkSignaturePolicy(bytes32 id, address sender, bytes32 hash, bytes calldata sig)
        external
        view
        virtual
        returns (uint256);

    function _policyOninstall(bytes32 id, bytes calldata _data) internal virtual;
    function _policyOnUninstall(bytes32 id, bytes calldata _data) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ExecMode, CallType, ExecType, ExecModeSelector, ExecModePayload} from "../types/Types.sol";
import {
    CALLTYPE_SINGLE,
    CALLTYPE_BATCH,
    EXECTYPE_DEFAULT,
    EXEC_MODE_DEFAULT,
    EXECTYPE_TRY,
    CALLTYPE_DELEGATECALL
} from "../types/Constants.sol";
import {Execution} from "../types/Structs.sol";

/**
 * @dev ExecLib is a helper library for execution
 */
library ExecLib {
    error ExecutionFailed();

    event TryExecuteUnsuccessful(uint256 batchExecutionindex, bytes result);

    function _execute(ExecMode execMode, bytes calldata executionCalldata)
        internal
        returns (bytes[] memory returnData)
    {
        (CallType callType, ExecType execType,,) = decode(execMode);

        // check if calltype is batch or single
        if (callType == CALLTYPE_BATCH) {
            // destructure executionCallData according to batched exec
            Execution[] calldata executions = decodeBatch(executionCalldata);
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) returnData = _execute(executions);
            else if (execType == EXECTYPE_TRY) returnData = _tryExecute(executions);
            else revert("Unsupported");
        } else if (callType == CALLTYPE_SINGLE) {
            // destructure executionCallData according to single exec
            (address target, uint256 value, bytes calldata callData) = decodeSingle(executionCalldata);
            returnData = new bytes[](1);
            bool success;
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) {
                returnData[0] = _execute(target, value, callData);
            } else if (execType == EXECTYPE_TRY) {
                (success, returnData[0]) = _tryExecute(target, value, callData);
                if (!success) emit TryExecuteUnsuccessful(0, returnData[0]);
            } else {
                revert("Unsupported");
            }
        } else if (callType == CALLTYPE_DELEGATECALL) {
            address delegate = address(bytes20(executionCalldata[0:20]));
            bytes calldata callData = executionCalldata[20:];
            _executeDelegatecall(delegate, callData);
        } else {
            revert("Unsupported");
        }
    }

    function _execute(Execution[] calldata executions) internal returns (bytes[] memory result) {
        uint256 length = executions.length;
        result = new bytes[](length);

        for (uint256 i; i < length; i++) {
            Execution calldata _exec = executions[i];
            result[i] = _execute(_exec.target, _exec.value, _exec.callData);
        }
    }

    function _tryExecute(Execution[] calldata executions) internal returns (bytes[] memory result) {
        uint256 length = executions.length;
        result = new bytes[](length);

        for (uint256 i; i < length; i++) {
            Execution calldata _exec = executions[i];
            bool success;
            (success, result[i]) = _tryExecute(_exec.target, _exec.value, _exec.callData);
            if (!success) emit TryExecuteUnsuccessful(i, result[i]);
        }
    }

    function _execute(address target, uint256 value, bytes calldata callData) internal returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            if iszero(call(gas(), target, value, result, callData.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    function _tryExecute(address target, uint256 value, bytes calldata callData)
        internal
        returns (bool success, bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            success := call(gas(), target, value, result, callData.length, codesize(), 0x00)
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @dev Execute a delegatecall with `delegate` on this account.
    function _executeDelegatecall(address delegate, bytes calldata callData)
        internal
        returns (bool success, bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, callData.offset, callData.length)
            // Forwards the `data` to `delegate` via delegatecall.
            success := delegatecall(gas(), delegate, result, callData.length, codesize(), 0x00)
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    function decode(ExecMode mode)
        internal
        pure
        returns (CallType _calltype, ExecType _execType, ExecModeSelector _modeSelector, ExecModePayload _modePayload)
    {
        assembly {
            _calltype := mode
            _execType := shl(8, mode)
            _modeSelector := shl(48, mode)
            _modePayload := shl(80, mode)
        }
    }

    function encode(CallType callType, ExecType execType, ExecModeSelector mode, ExecModePayload payload)
        internal
        pure
        returns (ExecMode)
    {
        return ExecMode.wrap(
            bytes32(abi.encodePacked(callType, execType, bytes4(0), ExecModeSelector.unwrap(mode), payload))
        );
    }

    function encodeSimpleBatch() internal pure returns (ExecMode mode) {
        mode = encode(CALLTYPE_BATCH, EXECTYPE_DEFAULT, EXEC_MODE_DEFAULT, ExecModePayload.wrap(0x00));
    }

    function encodeSimpleSingle() internal pure returns (ExecMode mode) {
        mode = encode(CALLTYPE_SINGLE, EXECTYPE_DEFAULT, EXEC_MODE_DEFAULT, ExecModePayload.wrap(0x00));
    }

    function getCallType(ExecMode mode) internal pure returns (CallType calltype) {
        assembly {
            calltype := mode
        }
    }

    function decodeBatch(bytes calldata callData) internal pure returns (Execution[] calldata executionBatch) {
        /*
         * Batch Call Calldata Layout
         * Offset (in bytes)    | Length (in bytes) | Contents
         * 0x0                  | 0x4               | bytes4 function selector
        *  0x4                  | -                 |
        abi.encode(IERC7579Execution.Execution[])
         */
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            let dataPointer := add(callData.offset, calldataload(callData.offset))

            // Extract the ERC7579 Executions
            executionBatch.offset := add(dataPointer, 32)
            executionBatch.length := calldataload(dataPointer)
        }
    }

    function encodeBatch(Execution[] memory executions) internal pure returns (bytes memory callData) {
        callData = abi.encode(executions);
    }

    function decodeSingle(bytes calldata executionCalldata)
        internal
        pure
        returns (address target, uint256 value, bytes calldata callData)
    {
        target = address(bytes20(executionCalldata[0:20]));
        value = uint256(bytes32(executionCalldata[20:52]));
        callData = executionCalldata[52:];
    }

    function encodeSingle(address target, uint256 value, bytes memory callData)
        internal
        pure
        returns (bytes memory userOpCalldata)
    {
        userOpCalldata = abi.encodePacked(target, value, callData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {CallType, ExecType, ExecMode} from "../utils/ExecLib.sol";
import {PackedUserOperation} from "./PackedUserOperation.sol";

struct Execution {
    address target;
    uint256 value;
    bytes callData;
}

interface IERC7579Account {
    event ModuleInstalled(uint256 moduleTypeId, address module);
    event ModuleUninstalled(uint256 moduleTypeId, address module);

    /**
     * @dev Executes a transaction on behalf of the account.
     *         This function is intended to be called by ERC-4337 EntryPoint.sol
     * @dev Ensure adequate authorization control: i.e. onlyEntryPointOrSelf
     *
     * @dev MSA MUST implement this function signature.
     * If a mode is requested that is not supported by the Account, it MUST revert
     * @param mode The encoded execution mode of the transaction. See ModeLib.sol for details
     * @param executionCalldata The encoded execution call data
     */
    function execute(ExecMode mode, bytes calldata executionCalldata) external payable;

    /**
     * @dev Executes a transaction on behalf of the account.
     *         This function is intended to be called by Executor Modules
     * @dev Ensure adequate authorization control: i.e. onlyExecutorModule
     *
     * @dev MSA MUST implement this function signature.
     * If a mode is requested that is not supported by the Account, it MUST revert
     * @param mode The encoded execution mode of the transaction. See ModeLib.sol for details
     * @param executionCalldata The encoded execution call data
     */
    function executeFromExecutor(ExecMode mode, bytes calldata executionCalldata)
        external
        payable
        returns (bytes[] memory returnData);

    /**
     * @dev ERC-1271 isValidSignature
     *         This function is intended to be used to validate a smart account signature
     * and may forward the call to a validator module
     *
     * @param hash The hash of the data that is signed
     * @param data The data that is signed
     */
    function isValidSignature(bytes32 hash, bytes calldata data) external view returns (bytes4);

    /**
     * @dev installs a Module of a certain type on the smart account
     * @dev Implement Authorization control of your chosing
     * @param moduleTypeId the module type ID according the ERC-7579 spec
     * @param module the module address
     * @param initData arbitrary data that may be required on the module during `onInstall`
     * initialization.
     */
    function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable;

    /**
     * @dev uninstalls a Module of a certain type on the smart account
     * @dev Implement Authorization control of your chosing
     * @param moduleTypeId the module type ID according the ERC-7579 spec
     * @param module the module address
     * @param deInitData arbitrary data that may be required on the module during `onUninstall`
     * de-initialization.
     */
    function uninstallModule(uint256 moduleTypeId, address module, bytes calldata deInitData) external payable;

    /**
     * Function to check if the account supports a certain CallType or ExecType (see ModeLib.sol)
     * @param encodedMode the encoded mode
     */
    function supportsExecutionMode(ExecMode encodedMode) external view returns (bool);

    /**
     * Function to check if the account supports installation of a certain module type Id
     * @param moduleTypeId the module type ID according the ERC-7579 spec
     */
    function supportsModule(uint256 moduleTypeId) external view returns (bool);

    /**
     * Function to check if the account has a certain module installed
     * @param moduleTypeId the module type ID according the ERC-7579 spec
     *      Note: keep in mind that some contracts can be multiple module types at the same time. It
     *            thus may be necessary to query multiple module types
     * @param module the module address
     * @param additionalContext additional context data that the smart account may interpret to
     *                          identifiy conditions under which the module is installed.
     *                          usually this is not necessary, but for some special hooks that
     *                          are stored in mappings, this param might be needed
     */
    function isModuleInstalled(uint256 moduleTypeId, address module, bytes calldata additionalContext)
        external
        view
        returns (bool);

    /**
     * @dev Returns the account id of the smart account
     * @return accountImplementationId the account id of the smart account
     * the accountId should be structured like so:
     *        "vendorname.accountname.semver"
     */
    function accountId() external view returns (string memory accountImplementationId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PackedUserOperation} from "./PackedUserOperation.sol";

uint256 constant VALIDATION_SUCCESS = 0;
uint256 constant VALIDATION_FAILED = 1;

uint256 constant MODULE_TYPE_VALIDATOR = 1;
uint256 constant MODULE_TYPE_EXECUTOR = 2;
uint256 constant MODULE_TYPE_FALLBACK = 3;
uint256 constant MODULE_TYPE_HOOK = 4;
uint256 constant MODULE_TYPE_POLICY = 5;
uint256 constant MODULE_TYPE_SIGNER = 6;
uint256 constant MODULE_TYPE_ACTION = 7;

interface IModule {
    error AlreadyInitialized(address smartAccount);
    error NotInitialized(address smartAccount);

    /**
     * @dev This function is called by the smart account during installation of the module
     * @param data arbitrary data that may be required on the module during `onInstall`
     * initialization
     *
     * MUST revert on error (i.e. if module is already enabled)
     */
    function onInstall(bytes calldata data) external payable;

    /**
     * @dev This function is called by the smart account during uninstallation of the module
     * @param data arbitrary data that may be required on the module during `onUninstall`
     * de-initialization
     *
     * MUST revert on error
     */
    function onUninstall(bytes calldata data) external payable;

    /**
     * @dev Returns boolean value if module is a certain type
     * @param moduleTypeId the module type ID according the ERC-7579 spec
     *
     * MUST return true if the module is of the given type and false otherwise
     */
    function isModuleType(uint256 moduleTypeId) external view returns (bool);

    /**
     * @dev Returns if the module was already initialized for a provided smartaccount
     */
    function isInitialized(address smartAccount) external view returns (bool);
}

interface IValidator is IModule {
    error InvalidTargetAddress(address target);

    /**
     * @dev Validates a transaction on behalf of the account.
     *         This function is intended to be called by the MSA during the ERC-4337 validaton phase
     *         Note: solely relying on bytes32 hash and signature is not suffcient for some
     * validation implementations (i.e. SessionKeys often need access to userOp.calldata)
     * @param userOp The user operation to be validated. The userOp MUST NOT contain any metadata.
     * The MSA MUST clean up the userOp before sending it to the validator.
     * @param userOpHash The hash of the user operation to be validated
     * @return return value according to ERC-4337
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
        external
        payable
        returns (uint256);

    /**
     * Validator can be used for ERC-1271 validation
     */
    function isValidSignatureWithSender(address sender, bytes32 hash, bytes calldata data)
        external
        view
        returns (bytes4);
}

interface IExecutor is IModule {}

interface IHook is IModule {
    function preCheck(address msgSender, bytes calldata msgData) external payable returns (bytes memory hookData);
    function postCheck(bytes calldata hookData) external payable returns (bool success);
}

interface IFallback is IModule {}

interface IPolicy is IModule {
    function checkUserOpPolicy(bytes32 id, PackedUserOperation calldata userOp) external payable returns (uint256);
    function checkSignaturePolicy(bytes32 id, address sender, bytes32 hash, bytes calldata sig)
        external
        view
        returns (uint256);
}

interface ISigner is IModule {
    function checkUserOpSignature(bytes32 id, PackedUserOperation calldata userOp, bytes32 userOpHash)
        external
        payable
        returns (uint256);
    function checkSignature(bytes32 id, address sender, bytes32 hash, bytes calldata sig)
        external
        view
        returns (bytes4);
}

interface IAction is IModule {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

/**
 * User Operation struct
 * @param sender                - The sender account of this request.
 * @param nonce                 - Unique value the sender uses to verify it is not a replay.
 * @param initCode              - If set, the account contract will be created by this constructor/
 * @param callData              - The method call to execute on this account.
 * @param accountGasLimits      - Packed gas limits for validateUserOp and gas limit passed to the callData method call.
 * @param preVerificationGas    - Gas not calculated by the handleOps method, but added to the gas paid.
 *                                Covers batch overhead.
 * @param gasFees                - packed gas fields maxFeePerGas and maxPriorityFeePerGas - Same as EIP-1559 gas parameter.
 * @param paymasterAndData      - If set, this field holds the paymaster address, verification gas limit, postOp gas limit and paymaster-specific extra data
 *                                The paymaster will pay for the transaction instead of the sender.
 * @param signature             - Sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees; //maxPriorityFee and maxFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

pragma solidity ^0.8.23;

// Custom type for improved developer experience
type ExecMode is bytes32;

type CallType is bytes1;

type ExecType is bytes1;

type ExecModeSelector is bytes4;

type ExecModePayload is bytes22;

using {eqModeSelector as ==} for ExecModeSelector global;
using {eqCallType as ==} for CallType global;
using {eqExecType as ==} for ExecType global;

function eqCallType(CallType a, CallType b) pure returns (bool) {
    return CallType.unwrap(a) == CallType.unwrap(b);
}

function eqExecType(ExecType a, ExecType b) pure returns (bool) {
    return ExecType.unwrap(a) == ExecType.unwrap(b);
}

function eqModeSelector(ExecModeSelector a, ExecModeSelector b) pure returns (bool) {
    return ExecModeSelector.unwrap(a) == ExecModeSelector.unwrap(b);
}

type ValidationMode is bytes1;

type ValidationId is bytes21;

type ValidationType is bytes1;

type PermissionId is bytes4;

type PolicyData is bytes22; // 2bytes for flag on skip, 20 bytes for validator address

type PassFlag is bytes2;

using {vModeEqual as ==} for ValidationMode global;
using {vTypeEqual as ==} for ValidationType global;
using {vIdentifierEqual as ==} for ValidationId global;
using {vModeNotEqual as !=} for ValidationMode global;
using {vTypeNotEqual as !=} for ValidationType global;
using {vIdentifierNotEqual as !=} for ValidationId global;

// nonce = uint192(key) + nonce
// key = mode + (vtype + validationDataWithoutType) + 2bytes parallelNonceKey
// key = 0x00 + 0x00 + 0x000 .. 00 + 0x0000
// key = 0x00 + 0x01 + 0x1234...ff + 0x0000
// key = 0x00 + 0x02 + ( ) + 0x000

function vModeEqual(ValidationMode a, ValidationMode b) pure returns (bool) {
    return ValidationMode.unwrap(a) == ValidationMode.unwrap(b);
}

function vModeNotEqual(ValidationMode a, ValidationMode b) pure returns (bool) {
    return ValidationMode.unwrap(a) != ValidationMode.unwrap(b);
}

function vTypeEqual(ValidationType a, ValidationType b) pure returns (bool) {
    return ValidationType.unwrap(a) == ValidationType.unwrap(b);
}

function vTypeNotEqual(ValidationType a, ValidationType b) pure returns (bool) {
    return ValidationType.unwrap(a) != ValidationType.unwrap(b);
}

function vIdentifierEqual(ValidationId a, ValidationId b) pure returns (bool) {
    return ValidationId.unwrap(a) == ValidationId.unwrap(b);
}

function vIdentifierNotEqual(ValidationId a, ValidationId b) pure returns (bool) {
    return ValidationId.unwrap(a) != ValidationId.unwrap(b);
}

type ValidationData is uint256;

type ValidAfter is uint48;

type ValidUntil is uint48;

function getValidationResult(ValidationData validationData) pure returns (address result) {
    assembly {
        result := validationData
    }
}

function packValidationData(ValidAfter validAfter, ValidUntil validUntil) pure returns (uint256) {
    return uint256(ValidAfter.unwrap(validAfter)) << 208 | uint256(ValidUntil.unwrap(validUntil)) << 160;
}

function parseValidationData(uint256 validationData)
    pure
    returns (ValidAfter validAfter, ValidUntil validUntil, address result)
{
    assembly {
        result := validationData
        validUntil := and(shr(160, validationData), 0xffffffffffff)
        switch iszero(validUntil)
        case 1 { validUntil := 0xffffffffffff }
        validAfter := shr(208, validationData)
    }
}

pragma solidity ^0.8.0;

import {CallType, ExecType, ExecModeSelector} from "./Types.sol";
import {PassFlag, ValidationMode, ValidationType} from "./Types.sol";
import {ValidationData} from "./Types.sol";
// Default CallType

CallType constant CALLTYPE_SINGLE = CallType.wrap(0x00);
// Batched CallType
CallType constant CALLTYPE_BATCH = CallType.wrap(0x01);
// @dev Implementing delegatecall is OPTIONAL!
// implement delegatecall with extreme care.
CallType constant CALLTYPE_DELEGATECALL = CallType.wrap(0xFF);

// @dev default behavior is to revert on failure
// To allow very simple accounts to use mode encoding, the default behavior is to revert on failure
// Since this is value 0x00, no additional encoding is required for simple accounts
ExecType constant EXECTYPE_DEFAULT = ExecType.wrap(0x00);
// @dev account may elect to change execution behavior. For example "try exec" / "allow fail"
ExecType constant EXECTYPE_TRY = ExecType.wrap(0x01);

ExecModeSelector constant EXEC_MODE_DEFAULT = ExecModeSelector.wrap(bytes4(0x00000000));

PassFlag constant SKIP_USEROP = PassFlag.wrap(0x0001);
PassFlag constant SKIP_SIGNATURE = PassFlag.wrap(0x0002);

// FLAG
ValidationMode constant VALIDATION_MODE_DEFAULT = ValidationMode.wrap(0x00);
ValidationMode constant VALIDATION_MODE_ENABLE = ValidationMode.wrap(0x01);
ValidationMode constant VALIDATION_MODE_INSTALL = ValidationMode.wrap(0x02);

// TYPES, ENUM
ValidationType constant VALIDATION_TYPE_SUDO = ValidationType.wrap(0x00);
ValidationType constant VALIDATION_TYPE_VALIDATOR = ValidationType.wrap(0x01);
ValidationType constant VALIDATION_TYPE_PERMISSION = ValidationType.wrap(0x02);

// ERC4337 constants
uint256 constant SIG_VALIDATION_FAILED_UINT = 1;
ValidationData constant SIG_VALIDATION_FAILED = ValidationData.wrap(SIG_VALIDATION_FAILED_UINT);

// ERC-1271 constants
bytes4 constant ERC1271_MAGICVALUE = 0x1626ba7e;
bytes4 constant ERC1271_INVALID = 0xffffffff;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

struct Execution {
    address target;
    uint256 value;
    bytes callData;
}