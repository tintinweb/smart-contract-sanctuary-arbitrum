// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PackedUserOperation} from "./interfaces/PackedUserOperation.sol";
import {IAccount, ValidationData, ValidAfter, ValidUntil, parseValidationData} from "./interfaces/IAccount.sol";
import {IEntryPoint} from "./interfaces/IEntryPoint.sol";
import {IAccountExecute} from "./interfaces/IAccountExecute.sol";
import {IERC7579Account} from "./interfaces/IERC7579Account.sol";
import {ModuleLib} from "./utils/ModuleLib.sol";
import {
    ValidationManager,
    ValidationMode,
    ValidationId,
    ValidatorLib,
    ValidationType,
    PermissionId,
    PassFlag,
    SKIP_SIGNATURE
} from "./core/ValidationManager.sol";
import {HookManager} from "./core/HookManager.sol";
import {ExecutorManager} from "./core/ExecutorManager.sol";
import {SelectorManager} from "./core/SelectorManager.sol";
import {IModule, IValidator, IHook, IExecutor, IFallback, IPolicy, ISigner} from "./interfaces/IERC7579Modules.sol";
import {EIP712} from "solady/utils/EIP712.sol";
import {ExecLib, ExecMode, CallType, ExecType, ExecModeSelector, ExecModePayload} from "./utils/ExecLib.sol";
import {
    CALLTYPE_SINGLE,
    CALLTYPE_DELEGATECALL,
    ERC1967_IMPLEMENTATION_SLOT,
    VALIDATION_TYPE_ROOT,
    VALIDATION_TYPE_VALIDATOR,
    VALIDATION_TYPE_PERMISSION,
    MODULE_TYPE_VALIDATOR,
    MODULE_TYPE_EXECUTOR,
    MODULE_TYPE_FALLBACK,
    MODULE_TYPE_HOOK,
    MODULE_TYPE_POLICY,
    MODULE_TYPE_SIGNER,
    EXECTYPE_TRY,
    EXECTYPE_DEFAULT,
    EXEC_MODE_DEFAULT,
    CALLTYPE_DELEGATECALL,
    CALLTYPE_SINGLE,
    CALLTYPE_BATCH,
    CALLTYPE_STATIC
} from "./types/Constants.sol";

contract Kernel is IAccount, IAccountExecute, IERC7579Account, ValidationManager {
    error ExecutionReverted();
    error InvalidExecutor();
    error InvalidFallback();
    error InvalidCallType();
    error OnlyExecuteUserOp();
    error InvalidModuleType();
    error InvalidCaller();
    error InvalidSelector();

    event Received(address sender, uint256 amount);
    event Upgraded(address indexed implementation);

    IEntryPoint public immutable entrypoint;

    // NOTE : when eip 1153 has been enabled, this can be transient storage
    mapping(bytes32 userOpHash => IHook) internal executionHook;

    constructor(IEntryPoint _entrypoint) {
        entrypoint = _entrypoint;
        _validationStorage().rootValidator = ValidationId.wrap(bytes21(abi.encodePacked(hex"deadbeef")));
    }

    modifier onlyEntryPoint() {
        if (msg.sender != address(entrypoint)) {
            revert InvalidCaller();
        }
        _;
    }

    modifier onlyEntryPointOrSelfOrRoot() {
        IValidator validator = ValidatorLib.getValidator(_validationStorage().rootValidator);
        if (
            msg.sender != address(entrypoint) && msg.sender != address(this) // do rootValidator hook
        ) {
            if (validator.isModuleType(4)) {
                bytes memory ret = IHook(address(validator)).preCheck(msg.sender, msg.value, msg.data);
                _;
                IHook(address(validator)).postCheck(ret);
            } else {
                revert InvalidCaller();
            }
        } else {
            _;
        }
    }

    function initialize(ValidationId _rootValidator, IHook hook, bytes calldata validatorData, bytes calldata hookData)
        external
    {
        ValidationStorage storage vs = _validationStorage();
        require(ValidationId.unwrap(vs.rootValidator) == bytes21(0), "already initialized");
        if (ValidationId.unwrap(_rootValidator) == bytes21(0)) {
            revert InvalidValidator();
        }
        ValidationType vType = ValidatorLib.getType(_rootValidator);
        if (vType != VALIDATION_TYPE_VALIDATOR && vType != VALIDATION_TYPE_PERMISSION) {
            revert InvalidValidationType();
        }
        _setRootValidator(_rootValidator);
        ValidationConfig memory config = ValidationConfig({nonce: uint32(1), hook: hook});
        vs.currentNonce = 1;
        _installValidation(_rootValidator, config, validatorData, hookData);
    }

    function changeRootValidator(
        ValidationId _rootValidator,
        IHook hook,
        bytes calldata validatorData,
        bytes calldata hookData
    ) external payable onlyEntryPointOrSelfOrRoot {
        ValidationStorage storage vs = _validationStorage();
        if (ValidationId.unwrap(_rootValidator) == bytes21(0)) {
            revert InvalidValidator();
        }
        ValidationType vType = ValidatorLib.getType(_rootValidator);
        if (vType != VALIDATION_TYPE_VALIDATOR && vType != VALIDATION_TYPE_PERMISSION) {
            revert InvalidValidationType();
        }
        _setRootValidator(_rootValidator);
        if (_validationStorage().validationConfig[_rootValidator].hook == IHook(address(0))) {
            // when new rootValidator is not installed yet
            ValidationConfig memory config = ValidationConfig({nonce: uint32(vs.currentNonce), hook: hook});
            _installValidation(_rootValidator, config, validatorData, hookData);
        }
    }

    function upgradeTo(address _newImplementation) external payable onlyEntryPointOrSelfOrRoot {
        assembly {
            sstore(ERC1967_IMPLEMENTATION_SLOT, _newImplementation)
        }
        emit Upgraded(_newImplementation);
    }

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "Kernel";
        version = "0.3.1";
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    fallback() external payable {
        SelectorConfig memory config = _selectorConfig(msg.sig);
        bool success;
        bytes memory result;
        if (address(config.hook) == address(0)) {
            revert InvalidSelector();
        } else {
            // action installed
            bytes memory context;
            if (
                address(config.hook) != address(1) && address(config.hook) != 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF
            ) {
                context = _doPreHook(config.hook, msg.value, msg.data);
            } else if (address(config.hook) == 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF) {
                // for selector manager, address(0) for the hook will default to type(address).max,
                // and this will only allow entrypoints to interact
                if (msg.sender != address(entrypoint)) {
                    revert InvalidCaller();
                }
            }
            // execute action
            if (config.callType == CALLTYPE_SINGLE) {
                (success, result) = ExecLib.doFallback2771Call(config.target);
            } else if (config.callType == CALLTYPE_DELEGATECALL) {
                (success, result) = ExecLib.executeDelegatecall(config.target, msg.data);
            } else {
                revert NotSupportedCallType();
            }
            if (
                address(config.hook) != address(1) && address(config.hook) != 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF
            ) {
                _doPostHook(config.hook, context);
            }
        }
        if (!success) {
            assembly {
                revert(add(result, 0x20), mload(result))
            }
        } else {
            assembly {
                return(add(result, 0x20), mload(result))
            }
        }
    }

    // validation part
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        payable
        override
        onlyEntryPoint
        returns (ValidationData validationData)
    {
        ValidationStorage storage vs = _validationStorage();
        // ONLY ENTRYPOINT
        // Major change for v2 => v3
        // 1. instead of packing 4 bytes prefix to userOp.signature to determine the mode, v3 uses userOp.nonce's first 2 bytes to check the mode
        // 2. instead of packing 20 bytes in userOp.signature for enable mode to provide the validator address, v3 uses userOp.nonce[2:22]
        // 3. In v2, only 1 plugin validator(aside from root validator) can access the selector.
        //    In v3, you can use more than 1 plugin to use the exact selector, you need to specify the validator address in userOp.nonce[2:22] to use the validator

        (ValidationMode vMode, ValidationType vType, ValidationId vId) = ValidatorLib.decodeNonce(userOp.nonce);
        if (vType == VALIDATION_TYPE_ROOT) {
            vId = vs.rootValidator;
        }
        validationData = _doValidation(vMode, vId, userOp, userOpHash);
        ValidationConfig memory vc = vs.validationConfig[vId];
        // allow when nonce is not revoked or vType is sudo
        if (vType != VALIDATION_TYPE_ROOT && vc.nonce < vs.validNonceFrom) {
            revert InvalidNonce();
        }
        IHook execHook = vc.hook;
        if (address(execHook) == address(0)) {
            revert InvalidValidator();
        }
        executionHook[userOpHash] = execHook;

        if (address(execHook) == address(1)) {
            // does not require hook
            if (vType != VALIDATION_TYPE_ROOT && !vs.allowedSelectors[vId][bytes4(userOp.callData[0:4])]) {
                revert InvalidValidator();
            }
        } else {
            // requires hook
            if (vType != VALIDATION_TYPE_ROOT && !vs.allowedSelectors[vId][bytes4(userOp.callData[4:8])]) {
                revert InvalidValidator();
            }
            if (bytes4(userOp.callData[0:4]) != this.executeUserOp.selector) {
                revert OnlyExecuteUserOp();
            }
        }

        assembly {
            if missingAccountFunds {
                pop(call(gas(), caller(), missingAccountFunds, callvalue(), callvalue(), callvalue(), callvalue()))
                //ignore failure (its EntryPoint's job to verify, not account.)
            }
        }
    }

    // --- Execution ---
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
        external
        payable
        override
        onlyEntryPoint
    {
        bytes memory context;
        IHook hook = executionHook[userOpHash];
        if (address(hook) != address(1)) {
            // removed 4bytes selector
            context = _doPreHook(hook, msg.value, userOp.callData[4:]);
        }
        (bool success, bytes memory ret) = ExecLib.executeDelegatecall(address(this), userOp.callData[4:]);
        if (address(hook) != address(1)) {
            _doPostHook(hook, context);
        } else if (!success) {
            revert ExecutionReverted();
        }
    }

    function executeFromExecutor(ExecMode execMode, bytes calldata executionCalldata)
        external
        payable
        returns (bytes[] memory returnData)
    {
        // no modifier needed, checking if msg.sender is registered executor will replace the modifier
        IHook hook = _executorConfig(IExecutor(msg.sender)).hook;
        if (address(hook) == address(0)) {
            revert InvalidExecutor();
        }
        bytes memory context;
        if (address(hook) != address(1)) {
            context = _doPreHook(hook, msg.value, msg.data);
        }
        returnData = ExecLib.execute(execMode, executionCalldata);
        if (address(hook) != address(1)) {
            _doPostHook(hook, context);
        }
    }

    function execute(ExecMode execMode, bytes calldata executionCalldata) external payable onlyEntryPointOrSelfOrRoot {
        ExecLib.execute(execMode, executionCalldata);
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view override returns (bytes4) {
        ValidationStorage storage vs = _validationStorage();
        (ValidationId vId, bytes calldata sig) = ValidatorLib.decodeSignature(signature);
        if (ValidatorLib.getType(vId) == VALIDATION_TYPE_ROOT) {
            vId = vs.rootValidator;
        }
        if (address(vs.validationConfig[vId].hook) == address(0)) {
            revert InvalidValidator();
        }
        if (ValidatorLib.getType(vId) == VALIDATION_TYPE_VALIDATOR) {
            IValidator validator = ValidatorLib.getValidator(vId);
            return validator.isValidSignatureWithSender(msg.sender, _toWrappedHash(hash), sig);
        } else {
            PermissionId pId = ValidatorLib.getPermissionId(vId);
            PassFlag permissionFlag = vs.permissionConfig[pId].permissionFlag;
            if (PassFlag.unwrap(permissionFlag) & PassFlag.unwrap(SKIP_SIGNATURE) != 0) {
                revert PermissionNotAlllowedForSignature();
            }
            return _checkPermissionSignature(pId, msg.sender, hash, sig);
        }
    }

    function installModule(uint256 moduleType, address module, bytes calldata initData)
        external
        payable
        override
        onlyEntryPointOrSelfOrRoot
    {
        if (moduleType == MODULE_TYPE_VALIDATOR) {
            ValidationStorage storage vs = _validationStorage();
            ValidationId vId = ValidatorLib.validatorToIdentifier(IValidator(module));
            ValidationConfig memory config =
                ValidationConfig({nonce: vs.currentNonce, hook: IHook(address(bytes20(initData[0:20])))});
            bytes calldata validatorData;
            bytes calldata hookData;
            bytes calldata selectorData;
            assembly {
                validatorData.offset := add(add(initData.offset, 52), calldataload(add(initData.offset, 20)))
                validatorData.length := calldataload(sub(validatorData.offset, 32))
                hookData.offset := add(add(initData.offset, 52), calldataload(add(initData.offset, 52)))
                hookData.length := calldataload(sub(hookData.offset, 32))
                selectorData.offset := add(add(initData.offset, 52), calldataload(add(initData.offset, 84)))
                selectorData.length := calldataload(sub(selectorData.offset, 32))
            }
            _installValidation(vId, config, validatorData, hookData);
            // NOTE: we don't allow configure on selector data on v3.1, but using bytes instead of bytes4 for selector data to make sure we are future proof
            _setSelector(vId, bytes4(selectorData[0:4]), true);
        } else if (moduleType == MODULE_TYPE_EXECUTOR) {
            bytes calldata executorData;
            bytes calldata hookData;
            assembly {
                executorData.offset := add(add(initData.offset, 52), calldataload(add(initData.offset, 20)))
                executorData.length := calldataload(sub(executorData.offset, 32))
                hookData.offset := add(add(initData.offset, 52), calldataload(add(initData.offset, 52)))
                hookData.length := calldataload(sub(hookData.offset, 32))
            }
            IHook hook = IHook(address(bytes20(initData[0:20])));
            _installExecutor(IExecutor(module), executorData, hook);
            _installHook(hook, hookData);
        } else if (moduleType == MODULE_TYPE_FALLBACK) {
            bytes calldata selectorData;
            bytes calldata hookData;
            assembly {
                selectorData.offset := add(add(initData.offset, 56), calldataload(add(initData.offset, 24)))
                selectorData.length := calldataload(sub(selectorData.offset, 32))
                hookData.offset := add(add(initData.offset, 56), calldataload(add(initData.offset, 56)))
                hookData.length := calldataload(sub(hookData.offset, 32))
            }
            _installSelector(bytes4(initData[0:4]), module, IHook(address(bytes20(initData[4:24]))), selectorData);
            _installHook(IHook(address(bytes20(initData[4:24]))), hookData);
        } else if (moduleType == MODULE_TYPE_HOOK) {
            // force call onInstall for hook
            // NOTE: for hook, kernel does not support independent hook install,
            // hook is expected to be paired with proper validator/executor/selector
            IHook(module).onInstall(initData);
        } else if (moduleType == MODULE_TYPE_POLICY) {
            // force call onInstall for policy
            // NOTE: for policy, kernel does not support independent policy install,
            // policy is expected to be paired with proper permissionId
            // to "ADD" permission, use "installValidations()" function
            IPolicy(module).onInstall(initData);
        } else if (moduleType == MODULE_TYPE_SIGNER) {
            // force call onInstall for signer
            // NOTE: for signer, kernel does not support independent signer install,
            // signer is expected to be paired with proper permissionId
            // to "ADD" permission, use "installValidations()" function
            ISigner(module).onInstall(initData);
        } else {
            revert InvalidModuleType();
        }
    }

    function installValidations(
        ValidationId[] calldata vIds,
        ValidationConfig[] memory configs,
        bytes[] calldata validationData,
        bytes[] calldata hookData
    ) external payable onlyEntryPointOrSelfOrRoot {
        _installValidations(vIds, configs, validationData, hookData);
    }

    function uninstallValidation(ValidationId vId, bytes calldata deinitData, bytes calldata hookDeinitData)
        external
        payable
        onlyEntryPointOrSelfOrRoot
    {
        IHook hook = _uninstallValidation(vId, deinitData);
        _uninstallHook(hook, hookDeinitData);
    }

    function invalidateNonce(uint32 nonce) external payable onlyEntryPointOrSelfOrRoot {
        _invalidateNonce(nonce);
    }

    function uninstallModule(uint256 moduleType, address module, bytes calldata deInitData)
        external
        payable
        override
        onlyEntryPointOrSelfOrRoot
    {
        if (moduleType == 1) {
            ValidationId vId = ValidatorLib.validatorToIdentifier(IValidator(module));
            _uninstallValidation(vId, deInitData);
        } else if (moduleType == 2) {
            _uninstallExecutor(IExecutor(module), deInitData);
        } else if (moduleType == 3) {
            bytes4 selector = bytes4(deInitData[0:4]);
            _uninstallSelector(selector, deInitData[4:]);
        } else if (moduleType == 4) {
            ValidationId vId = _validationStorage().rootValidator;
            if (_validationStorage().validationConfig[vId].hook == IHook(module)) {
                // when root validator hook is being removed
                // remove hook on root validator to prevent kernel from being locked
                _validationStorage().validationConfig[vId].hook = IHook(address(1));
            }
            // force call onInstall for hook
            // NOTE: for hook, kernel does not support independent hook install,
            // hook is expected to be paired with proper validator/executor/selector
            ModuleLib.uninstallModule(module, deInitData);
        } else if (moduleType == 5) {
            ValidationId rootValidator = _validationStorage().rootValidator;
            bytes32 permissionId = bytes32(deInitData[0:32]);
            if (ValidatorLib.getType(rootValidator) == VALIDATION_TYPE_PERMISSION) {
                if (permissionId == bytes32(PermissionId.unwrap(ValidatorLib.getPermissionId(rootValidator)))) {
                    revert RootValidatorCannotBeRemoved();
                }
            }
            // force call onInstall for policy
            // NOTE: for policy, kernel does not support independent policy install,
            // policy is expected to be paired with proper permissionId
            // to "REMOVE" permission, use "uninstallValidation()" function
            ModuleLib.uninstallModule(module, deInitData);
        } else if (moduleType == 6) {
            ValidationId rootValidator = _validationStorage().rootValidator;
            bytes32 permissionId = bytes32(deInitData[0:32]);
            if (ValidatorLib.getType(rootValidator) == VALIDATION_TYPE_PERMISSION) {
                if (permissionId == bytes32(PermissionId.unwrap(ValidatorLib.getPermissionId(rootValidator)))) {
                    revert RootValidatorCannotBeRemoved();
                }
            }
            // force call onInstall for signer
            // NOTE: for signer, kernel does not support independent signer install,
            // signer is expected to be paired with proper permissionId
            // to "REMOVE" permission, use "uninstallValidation()" function
            ModuleLib.uninstallModule(module, deInitData);
        } else {
            revert InvalidModuleType();
        }
    }

    function supportsModule(uint256 moduleTypeId) external pure override returns (bool) {
        if (moduleTypeId < 7) {
            return true;
        } else {
            return false;
        }
    }

    function isModuleInstalled(uint256 moduleType, address module, bytes calldata additionalContext)
        external
        view
        override
        returns (bool)
    {
        if (moduleType == MODULE_TYPE_VALIDATOR) {
            return _validationStorage().validationConfig[ValidatorLib.validatorToIdentifier(IValidator(module))].hook
                != IHook(address(0));
        } else if (moduleType == MODULE_TYPE_EXECUTOR) {
            return address(_executorConfig(IExecutor(module)).hook) != address(0);
        } else if (moduleType == MODULE_TYPE_FALLBACK) {
            return _selectorConfig(bytes4(additionalContext[0:4])).target == module;
        } else {
            return false;
        }
    }

    function accountId() external pure override returns (string memory accountImplementationId) {
        return "kernel.advanced.v0.3.1";
    }

    function supportsExecutionMode(ExecMode mode) external pure override returns (bool) {
        (CallType callType, ExecType execType, ExecModeSelector selector, ExecModePayload payload) =
            ExecLib.decode(mode);
        if (
            callType != CALLTYPE_BATCH && callType != CALLTYPE_SINGLE && callType != CALLTYPE_DELEGATECALL
                && callType != CALLTYPE_STATIC
        ) {
            return false;
        }

        if (
            ExecType.unwrap(execType) != ExecType.unwrap(EXECTYPE_TRY)
                && ExecType.unwrap(execType) != ExecType.unwrap(EXECTYPE_DEFAULT)
        ) {
            return false;
        }

        if (ExecModeSelector.unwrap(selector) != ExecModeSelector.unwrap(EXEC_MODE_DEFAULT)) {
            return false;
        }

        if (ExecModePayload.unwrap(payload) != bytes22(0)) {
            return false;
        }
        return true;
    }
}

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "./PackedUserOperation.sol";
import "../types/Types.sol";

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
     * @param userOp              - The operation that is about to be executed.
     * @param userOpHash          - Hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds - Missing funds on the account's deposit in the entrypoint.
     *                              This is the minimum amount to transfer to the sender(entryPoint) to be
     *                              able to make the call. The excess is left as a deposit in the entrypoint
     *                              for future calls. Can be withdrawn anytime using "entryPoint.withdrawTo()".
     *                              In case there is a paymaster in the request (or the current deposit is high
     *                              enough), this value will be zero.
     * @return validationData       - Packaged ValidationData structure. use `_packValidationData` and
     *                              `_unpackValidationData` to encode and decode.
     *                              <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *                                 otherwise, an address of an "authorizer" contract.
     *                              <6-byte> validUntil - Last timestamp this operation is valid. 0 for "indefinite"
     *                              <6-byte> validAfter - First timestamp this operation is valid
     *                                                    If an account doesn't use time-range, it is enough to
     *                                                    return SIG_VALIDATION_FAILED value (1) for signature failure.
     *                              Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        payable
        returns (ValidationData validationData);
}

// SPDX-License-Identifier: GPL-3.0
/**
 * Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 * Only one instance required on each chain.
 *
 */
pragma solidity >=0.7.5;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./PackedUserOperation.sol";
import "./IStakeManager.sol";
import "./IAggregator.sol";
import "./INonceManager.sol";

interface IEntryPoint is IStakeManager, INonceManager {
    /**
     *
     * An event emitted after each successful request.
     * @param userOpHash    - Unique identifier for the request (hash its entire content, except signature).
     * @param sender        - The account that generates this request.
     * @param paymaster     - If non-null, the paymaster that pays for this request.
     * @param nonce         - The nonce value from the request.
     * @param success       - True if the sender transaction succeeded, false if reverted.
     * @param actualGasCost - Actual amount paid (by account or paymaster) for this UserOperation.
     * @param actualGasUsed - Total gas used by this UserOperation (including preVerification, creation,
     *                        validation and execution).
     */
    event UserOperationEvent(
        bytes32 indexed userOpHash,
        address indexed sender,
        address indexed paymaster,
        uint256 nonce,
        bool success,
        uint256 actualGasCost,
        uint256 actualGasUsed
    );

    /**
     * Account "sender" was deployed.
     * @param userOpHash - The userOp that deployed this account. UserOperationEvent will follow.
     * @param sender     - The account that is deployed
     * @param factory    - The factory used to deploy this account (in the initCode)
     * @param paymaster  - The paymaster used by this UserOp
     */
    event AccountDeployed(bytes32 indexed userOpHash, address indexed sender, address factory, address paymaster);

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length.
     * @param userOpHash   - The request unique identifier.
     * @param sender       - The sender of this request.
     * @param nonce        - The nonce used in the request.
     * @param revertReason - The return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(
        bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason
    );

    /**
     * An event emitted if the UserOperation Paymaster's "postOp" call reverted with non-zero length.
     * @param userOpHash   - The request unique identifier.
     * @param sender       - The sender of this request.
     * @param nonce        - The nonce used in the request.
     * @param revertReason - The return bytes from the (reverted) call to "callData".
     */
    event PostOpRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

    /**
     * An event emitted by handleOps(), before starting the execution loop.
     * Any event emitted before this event, is part of the validation.
     */
    event BeforeExecution();

    /**
     * Signature aggregator used by the following UserOperationEvents within this bundle.
     * @param aggregator - The aggregator used for the following UserOperationEvents.
     */
    event SignatureAggregatorChanged(address indexed aggregator);

    /**
     * A custom revert error of handleOps, to identify the offending op.
     * Should be caught in off-chain handleOps simulation and not happen on-chain.
     * Useful for mitigating DoS attempts against batchers or for troubleshooting of factory/account/paymaster reverts.
     * NOTE: If simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     * @param opIndex - Index into the array of ops to the failed one (in simulateValidation, this is always zero).
     * @param reason  - Revert reason. The string starts with a unique code "AAmn",
     *                  where "m" is "1" for factory, "2" for account and "3" for paymaster issues,
     *                  so a failure can be attributed to the correct entity.
     */
    error FailedOp(uint256 opIndex, string reason);

    /**
     * A custom revert error of handleOps, to report a revert by account or paymaster.
     * @param opIndex - Index into the array of ops to the failed one (in simulateValidation, this is always zero).
     * @param reason  - Revert reason. see FailedOp(uint256,string), above
     * @param inner   - data from inner caught revert reason
     * @dev note that inner is truncated to 2048 bytes
     */
    error FailedOpWithRevert(uint256 opIndex, string reason, bytes inner);

    error PostOpReverted(bytes returnData);

    /**
     * Error case when a signature aggregator fails to verify the aggregated signature it had created.
     * @param aggregator The aggregator that failed to verify the signature
     */
    error SignatureValidationFailed(address aggregator);

    // Return value of getSenderAddress.
    error SenderAddressResult(address sender);

    // UserOps handled, per aggregator.
    struct UserOpsPerAggregator {
        PackedUserOperation[] userOps;
        // Aggregator address
        IAggregator aggregator;
        // Aggregated signature
        bytes signature;
    }

    /**
     * Execute a batch of UserOperations.
     * No signature aggregator is used.
     * If any account requires an aggregator (that is, it returned an aggregator when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops         - The operations to execute.
     * @param beneficiary - The address to receive the fees.
     */
    function handleOps(PackedUserOperation[] calldata ops, address payable beneficiary) external;

    /**
     * Execute a batch of UserOperation with Aggregators
     * @param opsPerAggregator - The operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts).
     * @param beneficiary      - The address to receive the fees.
     */
    function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary)
        external;

    /**
     * Generate a request Id - unique identifier for this request.
     * The request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     * @param userOp - The user operation to generate the request ID for.
     * @return hash the hash of this UserOperation
     */
    function getUserOpHash(PackedUserOperation calldata userOp) external view returns (bytes32);

    /**
     * Gas and return values during simulation.
     * @param preOpGas         - The gas used for validation (including preValidationGas)
     * @param prefund          - The required prefund for this operation
     * @param accountValidationData   - returned validationData from account.
     * @param paymasterValidationData - return validationData from paymaster.
     * @param paymasterContext - Returned by validatePaymasterUserOp (to be passed into postOp)
     */
    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        uint256 accountValidationData;
        uint256 paymasterValidationData;
        bytes paymasterContext;
    }

    /**
     * Returned aggregated signature info:
     * The aggregator returned by the account, and its current stake.
     */
    struct AggregatorStakeInfo {
        address aggregator;
        StakeInfo stakeInfo;
    }

    /**
     * Get counterfactual sender address.
     * Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
     * This method always revert, and returns the address in SenderAddressResult error
     * @param initCode - The constructor code to be passed into the UserOperation.
     */
    function getSenderAddress(bytes memory initCode) external;

    error DelegateAndRevert(bool success, bytes ret);

    /**
     * Helper method for dry-run testing.
     * @dev calling this method, the EntryPoint will make a delegatecall to the given data, and report (via revert) the result.
     *  The method always revert, so is only useful off-chain for dry run calls, in cases where state-override to replace
     *  actual EntryPoint code is less convenient.
     * @param target a target contract to make a delegatecall from entrypoint
     * @param data data to pass to target in a delegatecall
     */
    function delegateAndRevert(address target, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "./PackedUserOperation.sol";

interface IAccountExecute {
    /**
     * Account may implement this execute method.
     * passing this methodSig at the beginning of callData will cause the entryPoint to pass the full UserOp (and hash)
     * to the account.
     * The account should skip the methodSig, and use the callData (and optionally, other UserOp fields)
     *
     * @param userOp              - The operation that was just validated.
     * @param userOpHash          - Hash of the user's request data.
     */
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable;
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
     * @dev Implement Authorization control of your choosing
     * @param moduleTypeId the module type ID according the ERC-7579 spec
     * @param module the module address
     * @param initData arbitrary data that may be required on the module during `onInstall`
     * initialization.
     */
    function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable;

    /**
     * @dev uninstalls a Module of a certain type on the smart account
     * @dev Implement Authorization control of your choosing
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
     *                          identify conditions under which the module is installed.
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

pragma solidity ^0.8.0;

import {ExcessivelySafeCall} from "ExcessivelySafeCall/ExcessivelySafeCall.sol";
import {IModule} from "../interfaces/IERC7579Modules.sol";

library ModuleLib {
    event ModuleUninstallResult(address module, bool result);

    function uninstallModule(address module, bytes memory deinitData) internal returns (bool result) {
        (result,) = ExcessivelySafeCall.excessivelySafeCall(
            module, gasleft(), 0, 0, abi.encodeWithSelector(IModule.onUninstall.selector, deinitData)
        );
        emit ModuleUninstallResult(module, result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IValidator, IModule, IExecutor, IHook, IPolicy, ISigner, IFallback} from "../interfaces/IERC7579Modules.sol";
import {PackedUserOperation} from "../interfaces/PackedUserOperation.sol";
import {SelectorManager} from "./SelectorManager.sol";
import {HookManager} from "./HookManager.sol";
import {ExecutorManager} from "./ExecutorManager.sol";
import {ValidationData, ValidAfter, ValidUntil, parseValidationData} from "../interfaces/IAccount.sol";
import {IAccountExecute} from "../interfaces/IAccountExecute.sol";
import {EIP712} from "solady/utils/EIP712.sol";
import {ModuleLib} from "../utils/ModuleLib.sol";
import {
    ValidationId,
    PolicyData,
    ValidationMode,
    ValidationType,
    ValidatorLib,
    PassFlag
} from "../utils/ValidationTypeLib.sol";

import {CallType} from "../utils/ExecLib.sol";
import {CALLTYPE_SINGLE} from "../types/Constants.sol";

import {PermissionId, getValidationResult} from "../types/Types.sol";
import {_intersectValidationData} from "../utils/KernelValidationResult.sol";

import {
    VALIDATION_MODE_DEFAULT,
    VALIDATION_MODE_ENABLE,
    VALIDATION_TYPE_ROOT,
    VALIDATION_TYPE_VALIDATOR,
    VALIDATION_TYPE_PERMISSION,
    SKIP_USEROP,
    SKIP_SIGNATURE,
    VALIDATION_MANAGER_STORAGE_SLOT,
    MAX_NONCE_INCREMENT_SIZE,
    ENABLE_TYPE_HASH,
    KERNEL_WRAPPER_TYPE_HASH
} from "../types/Constants.sol";

abstract contract ValidationManager is EIP712, SelectorManager, HookManager, ExecutorManager {
    event RootValidatorUpdated(ValidationId rootValidator);
    event ValidatorInstalled(IValidator validator, uint32 nonce);
    event PermissionInstalled(PermissionId permission, uint32 nonce);
    event NonceInvalidated(uint32 nonce);
    event ValidatorUninstalled(IValidator validator);
    event PermissionUninstalled(PermissionId permission);
    event SelectorSet(bytes4 selector, ValidationId vId, bool allowed);

    error InvalidMode();
    error InvalidValidator();
    error InvalidSignature();
    error EnableNotApproved();
    error PolicySignatureOrderError();
    error SignerPrefixNotPresent();
    error PolicyDataTooLarge();
    error InvalidValidationType();
    error InvalidNonce();
    error PolicyFailed(uint256 i);
    error PermissionNotAlllowedForUserOp();
    error PermissionNotAlllowedForSignature();
    error PermissionDataLengthMismatch();
    error NonceInvalidationError();
    error RootValidatorCannotBeRemoved();

    // erc7579 plugins
    struct ValidationConfig {
        uint32 nonce; // 4 bytes
        IHook hook; // 20 bytes address(1) : hook not required, address(0) : validator not installed
    }

    struct PermissionConfig {
        PassFlag permissionFlag;
        ISigner signer;
        PolicyData[] policyData;
    }

    struct ValidationStorage {
        ValidationId rootValidator;
        uint32 currentNonce;
        uint32 validNonceFrom;
        mapping(ValidationId => ValidationConfig) validationConfig;
        mapping(ValidationId => mapping(bytes4 => bool)) allowedSelectors;
        // validation = validator | permission
        // validator == 1 validator
        // permission == 1 signer + N policies
        mapping(PermissionId => PermissionConfig) permissionConfig;
    }

    function rootValidator() external view returns (ValidationId) {
        return _validationStorage().rootValidator;
    }

    function currentNonce() external view returns (uint32) {
        return _validationStorage().currentNonce;
    }

    function validNonceFrom() external view returns (uint32) {
        return _validationStorage().validNonceFrom;
    }

    function isAllowedSelector(ValidationId vId, bytes4 selector) external view returns (bool) {
        return _validationStorage().allowedSelectors[vId][selector];
    }

    function validationConfig(ValidationId vId) external view returns (ValidationConfig memory) {
        return _validationStorage().validationConfig[vId];
    }

    function permissionConfig(PermissionId pId) external view returns (PermissionConfig memory) {
        return (_validationStorage().permissionConfig[pId]);
    }

    function _validationStorage() internal pure returns (ValidationStorage storage state) {
        assembly {
            state.slot := VALIDATION_MANAGER_STORAGE_SLOT
        }
    }

    function _setRootValidator(ValidationId _rootValidator) internal {
        ValidationStorage storage vs = _validationStorage();
        vs.rootValidator = _rootValidator;
        emit RootValidatorUpdated(_rootValidator);
    }

    function _invalidateNonce(uint32 nonce) internal {
        ValidationStorage storage state = _validationStorage();
        if (state.currentNonce + MAX_NONCE_INCREMENT_SIZE < nonce) {
            revert NonceInvalidationError();
        }
        if (nonce <= state.validNonceFrom) {
            revert InvalidNonce();
        }
        state.validNonceFrom = nonce;
        if (state.currentNonce < state.validNonceFrom) {
            state.currentNonce = state.validNonceFrom;
        }
    }

    // allow installing multiple validators with same nonce
    function _installValidations(
        ValidationId[] calldata validators,
        ValidationConfig[] memory configs,
        bytes[] calldata validatorData,
        bytes[] calldata hookData
    ) internal {
        unchecked {
            for (uint256 i = 0; i < validators.length; i++) {
                _installValidation(validators[i], configs[i], validatorData[i], hookData[i]);
            }
        }
    }

    function _setSelector(ValidationId vId, bytes4 selector, bool allowed) internal {
        ValidationStorage storage state = _validationStorage();
        state.allowedSelectors[vId][selector] = allowed;
        emit SelectorSet(selector, vId, allowed);
    }

    // for uninstall, we support uninstall for validator mode by calling onUninstall
    // but for permission mode, we do it naively by setting hook to address(0).
    // it is more recommended to use a nonce revoke to make sure the validator has been revoked
    // also, we are not calling hook.onInstall here
    function _uninstallValidation(ValidationId vId, bytes calldata validatorData) internal returns (IHook hook) {
        ValidationStorage storage state = _validationStorage();
        if (vId == state.rootValidator) {
            revert RootValidatorCannotBeRemoved();
        }
        hook = state.validationConfig[vId].hook;
        state.validationConfig[vId].hook = IHook(address(0));
        ValidationType vType = ValidatorLib.getType(vId);
        if (vType == VALIDATION_TYPE_VALIDATOR) {
            IValidator validator = ValidatorLib.getValidator(vId);
            ModuleLib.uninstallModule(address(validator), validatorData);
        } else if (vType == VALIDATION_TYPE_PERMISSION) {
            PermissionId permission = ValidatorLib.getPermissionId(vId);
            _uninstallPermission(permission, validatorData);
        } else {
            revert InvalidValidationType();
        }
    }

    function _uninstallPermission(PermissionId pId, bytes calldata data) internal {
        bytes[] calldata permissionDisableData;
        assembly {
            permissionDisableData.offset := add(add(data.offset, 32), calldataload(data.offset))
            permissionDisableData.length := calldataload(sub(permissionDisableData.offset, 32))
        }
        PermissionConfig storage config = _validationStorage().permissionConfig[pId];
        unchecked {
            if (permissionDisableData.length != config.policyData.length + 1) {
                revert PermissionDataLengthMismatch();
            }
            PolicyData[] storage policyData = config.policyData;
            for (uint256 i = 0; i < policyData.length; i++) {
                (, IPolicy policy) = ValidatorLib.decodePolicyData(policyData[i]);
                ModuleLib.uninstallModule(
                    address(policy), abi.encodePacked(bytes32(PermissionId.unwrap(pId)), permissionDisableData[i])
                );
            }
            delete _validationStorage().permissionConfig[pId].policyData;
            ModuleLib.uninstallModule(
                address(config.signer),
                abi.encodePacked(
                    bytes32(PermissionId.unwrap(pId)), permissionDisableData[permissionDisableData.length - 1]
                )
            );
        }
        config.signer = ISigner(address(0));
        config.permissionFlag = PassFlag.wrap(bytes2(0));
    }

    function _installValidation(
        ValidationId vId,
        ValidationConfig memory config,
        bytes calldata validatorData,
        bytes calldata hookData
    ) internal {
        ValidationStorage storage state = _validationStorage();
        if (state.validationConfig[vId].nonce == state.currentNonce) {
            // only increase currentNonce when vId's currentNonce is same
            unchecked {
                state.currentNonce++;
            }
        }
        if (config.hook == IHook(address(0))) {
            config.hook = IHook(address(1));
        }
        if (state.currentNonce != config.nonce || state.validationConfig[vId].nonce >= config.nonce) {
            revert InvalidNonce();
        }
        state.validationConfig[vId] = config;
        if (config.hook != IHook(address(1))) {
            _installHook(config.hook, hookData);
        }
        ValidationType vType = ValidatorLib.getType(vId);
        if (vType == VALIDATION_TYPE_VALIDATOR) {
            IValidator validator = ValidatorLib.getValidator(vId);
            validator.onInstall(validatorData);
        } else if (vType == VALIDATION_TYPE_PERMISSION) {
            PermissionId permission = ValidatorLib.getPermissionId(vId);
            _installPermission(permission, validatorData);
        } else {
            revert InvalidValidationType();
        }
    }

    function _installPermission(PermissionId permission, bytes calldata data) internal {
        ValidationStorage storage state = _validationStorage();
        bytes[] calldata permissionEnableData;
        assembly {
            permissionEnableData.offset := add(add(data.offset, 32), calldataload(data.offset))
            permissionEnableData.length := calldataload(sub(permissionEnableData.offset, 32))
        }
        // allow up to 0xfe, 0xff is dedicated for signer
        if (permissionEnableData.length > 254 || permissionEnableData.length == 0) {
            revert PolicyDataTooLarge();
        }

        // clean up the policyData
        if (state.permissionConfig[permission].policyData.length > 0) {
            delete state.permissionConfig[permission].policyData;
        }
        unchecked {
            for (uint256 i = 0; i < permissionEnableData.length - 1; i++) {
                state.permissionConfig[permission].policyData.push(
                    PolicyData.wrap(bytes22(permissionEnableData[i][0:22]))
                );
                IPolicy(address(bytes20(permissionEnableData[i][2:22]))).onInstall(
                    abi.encodePacked(bytes32(PermissionId.unwrap(permission)), permissionEnableData[i][22:])
                );
            }
            // last permission data will be signer
            ISigner signer = ISigner(address(bytes20(permissionEnableData[permissionEnableData.length - 1][2:22])));
            state.permissionConfig[permission].signer = signer;
            state.permissionConfig[permission].permissionFlag =
                PassFlag.wrap(bytes2(permissionEnableData[permissionEnableData.length - 1][0:2]));
            signer.onInstall(
                abi.encodePacked(
                    bytes32(PermissionId.unwrap(permission)), permissionEnableData[permissionEnableData.length - 1][22:]
                )
            );
        }
    }

    function _doValidation(ValidationMode vMode, ValidationId vId, PackedUserOperation calldata op, bytes32 userOpHash)
        internal
        returns (ValidationData validationData)
    {
        ValidationStorage storage state = _validationStorage();
        PackedUserOperation memory userOp = op;
        bytes calldata userOpSig = op.signature;
        unchecked {
            if (vMode == VALIDATION_MODE_ENABLE) {
                (validationData, userOpSig) = _enableMode(vId, op.signature);
                userOp.signature = userOpSig;
            }

            ValidationType vType = ValidatorLib.getType(vId);
            if (vType == VALIDATION_TYPE_VALIDATOR) {
                validationData = _intersectValidationData(
                    validationData,
                    ValidationData.wrap(ValidatorLib.getValidator(vId).validateUserOp(userOp, userOpHash))
                );
            } else {
                PermissionId pId = ValidatorLib.getPermissionId(vId);
                if (PassFlag.unwrap(state.permissionConfig[pId].permissionFlag) & PassFlag.unwrap(SKIP_USEROP) != 0) {
                    revert PermissionNotAlllowedForUserOp();
                }
                (ValidationData policyCheck, ISigner signer) = _checkUserOpPolicy(pId, userOp, userOpSig);
                validationData = _intersectValidationData(validationData, policyCheck);
                validationData = _intersectValidationData(
                    validationData,
                    ValidationData.wrap(
                        signer.checkUserOpSignature(bytes32(PermissionId.unwrap(pId)), userOp, userOpHash)
                    )
                );
            }
        }
    }

    function _enableMode(ValidationId vId, bytes calldata packedData)
        internal
        returns (ValidationData validationData, bytes calldata userOpSig)
    {
        validationData = _enableValidationWithSig(vId, packedData);

        assembly {
            userOpSig.offset := add(add(packedData.offset, 52), calldataload(add(packedData.offset, 148)))
            userOpSig.length := calldataload(sub(userOpSig.offset, 32))
        }

        return (validationData, userOpSig);
    }

    function _enableValidationWithSig(ValidationId vId, bytes calldata packedData)
        internal
        returns (ValidationData validationData)
    {
        bytes calldata enableSig;
        (
            ValidationConfig memory config,
            bytes calldata validatorData,
            bytes calldata hookData,
            bytes calldata selectorData,
            bytes32 digest
        ) = _enableDigest(vId, packedData);
        assembly {
            enableSig.offset := add(add(packedData.offset, 52), calldataload(add(packedData.offset, 116)))
            enableSig.length := calldataload(sub(enableSig.offset, 32))
        }
        validationData = _checkEnableSig(digest, enableSig);
        _installValidation(vId, config, validatorData, hookData);
        _configureSelector(selectorData);
        _setSelector(vId, bytes4(selectorData[0:4]), true);
    }

    function _checkEnableSig(bytes32 digest, bytes calldata enableSig)
        internal
        view
        returns (ValidationData validationData)
    {
        ValidationStorage storage state = _validationStorage();
        ValidationType vType = ValidatorLib.getType(state.rootValidator);
        bytes4 result;
        if (vType == VALIDATION_TYPE_VALIDATOR) {
            IValidator validator = ValidatorLib.getValidator(state.rootValidator);
            result = validator.isValidSignatureWithSender(address(this), digest, enableSig);
        } else if (vType == VALIDATION_TYPE_PERMISSION) {
            PermissionId pId = ValidatorLib.getPermissionId(state.rootValidator);
            ISigner signer;
            (signer, validationData, enableSig) = _checkSignaturePolicy(pId, address(this), digest, enableSig);
            result = signer.checkSignature(bytes32(PermissionId.unwrap(pId)), address(this), digest, enableSig);
        } else {
            revert InvalidValidationType();
        }
        if (result != 0x1626ba7e) {
            revert EnableNotApproved();
        }
    }

    function _configureSelector(bytes calldata selectorData) internal {
        bytes4 selector = bytes4(selectorData[0:4]);
        if (selectorData.length >= 4) {
            if (selectorData.length >= 44) {
                // install selector with hook and target contract
                bytes calldata selectorInitData;
                bytes calldata hookInitData;
                IModule selectorModule = IModule(address(bytes20(selectorData[4:24])));
                assembly {
                    selectorInitData.offset :=
                        add(add(selectorData.offset, 76), calldataload(add(selectorData.offset, 44)))
                    selectorInitData.length := calldataload(sub(selectorInitData.offset, 32))
                    hookInitData.offset := add(add(selectorData.offset, 76), calldataload(add(selectorData.offset, 76)))
                    hookInitData.length := calldataload(sub(hookInitData.offset, 32))
                }
                if (CallType.wrap(bytes1(selectorInitData[0])) == CALLTYPE_SINGLE && selectorModule.isModuleType(2)) {
                    // also adds as executor when fallback module is also a executor
                    bytes calldata executorHookData;
                    assembly {
                        executorHookData.offset :=
                            add(add(selectorData.offset, 76), calldataload(add(selectorData.offset, 108)))
                        executorHookData.length := calldataload(sub(executorHookData.offset, 32))
                    }
                    IHook executorHook = IHook(address(bytes20(executorHookData[0:20])));
                    // if module is also executor, install as executor
                    _installExecutorWithoutInit(IExecutor(address(selectorModule)), executorHook);
                    _installHook(executorHook, executorHookData[20:]);
                }
                _installSelector(
                    selector, address(selectorModule), IHook(address(bytes20(selectorData[24:44]))), selectorInitData
                );
                _installHook(IHook(address(bytes20(selectorData[24:44]))), hookInitData);
            } else {
                // set without install
                require(selectorData.length == 4, "Invalid selectorData");
            }
        }
    }

    function _enableDigest(ValidationId vId, bytes calldata packedData)
        internal
        view
        returns (
            ValidationConfig memory config,
            bytes calldata validatorData,
            bytes calldata hookData,
            bytes calldata selectorData,
            bytes32 digest
        )
    {
        ValidationStorage storage state = _validationStorage();
        config.hook = IHook(address(bytes20(packedData[0:20])));
        config.nonce = state.currentNonce;

        assembly {
            validatorData.offset := add(add(packedData.offset, 52), calldataload(add(packedData.offset, 20)))
            validatorData.length := calldataload(sub(validatorData.offset, 32))
            hookData.offset := add(add(packedData.offset, 52), calldataload(add(packedData.offset, 52)))
            hookData.length := calldataload(sub(hookData.offset, 32))
            selectorData.offset := add(add(packedData.offset, 52), calldataload(add(packedData.offset, 84)))
            selectorData.length := calldataload(sub(selectorData.offset, 32))
        }
        digest = _hashTypedData(
            keccak256(
                abi.encode(
                    ENABLE_TYPE_HASH,
                    ValidationId.unwrap(vId),
                    state.currentNonce,
                    config.hook,
                    keccak256(validatorData),
                    keccak256(hookData),
                    keccak256(selectorData)
                )
            )
        );
    }

    struct PermissionSigMemory {
        uint8 idx;
        uint256 length;
        ValidationData validationData;
        PermissionId permission;
        PassFlag flag;
        IPolicy policy;
        bytes permSig;
        address caller;
        bytes32 digest;
    }

    function _checkUserOpPolicy(PermissionId pId, PackedUserOperation memory userOp, bytes calldata userOpSig)
        internal
        returns (ValidationData validationData, ISigner signer)
    {
        ValidationStorage storage state = _validationStorage();
        PolicyData[] storage policyData = state.permissionConfig[pId].policyData;
        unchecked {
            for (uint256 i = 0; i < policyData.length; i++) {
                (PassFlag flag, IPolicy policy) = ValidatorLib.decodePolicyData(policyData[i]);
                uint8 idx = uint8(bytes1(userOpSig[0]));
                if (idx == i) {
                    // we are using uint64 length
                    uint256 length = uint64(bytes8(userOpSig[1:9]));
                    userOp.signature = userOpSig[9:9 + length];
                    userOpSig = userOpSig[9 + length:];
                } else if (idx < i) {
                    // signature is not in order
                    revert PolicySignatureOrderError();
                } else {
                    userOp.signature = "";
                }
                if (PassFlag.unwrap(flag) & PassFlag.unwrap(SKIP_USEROP) == 0) {
                    ValidationData vd =
                        ValidationData.wrap(policy.checkUserOpPolicy(bytes32(PermissionId.unwrap(pId)), userOp));
                    address result = getValidationResult(vd);
                    if (result != address(0)) {
                        revert PolicyFailed(i);
                    }
                    validationData = _intersectValidationData(validationData, vd);
                }
            }
            if (uint8(bytes1(userOpSig[0])) != 255) {
                revert SignerPrefixNotPresent();
            }
            userOp.signature = userOpSig[1:];
            return (validationData, state.permissionConfig[pId].signer);
        }
    }

    function _checkSignaturePolicy(PermissionId pId, address caller, bytes32 digest, bytes calldata sig)
        internal
        view
        returns (ISigner, ValidationData, bytes calldata)
    {
        ValidationStorage storage state = _validationStorage();
        PermissionSigMemory memory mSig;
        mSig.permission = pId;
        mSig.caller = caller;
        mSig.digest = digest;
        _checkPermissionPolicy(mSig, state, sig);
        if (uint8(bytes1(sig[0])) != 255) {
            revert SignerPrefixNotPresent();
        }
        sig = sig[1:];
        return (state.permissionConfig[mSig.permission].signer, mSig.validationData, sig);
    }

    function _checkPermissionPolicy(
        PermissionSigMemory memory mSig,
        ValidationStorage storage state,
        bytes calldata sig
    ) internal view {
        PolicyData[] storage policyData = state.permissionConfig[mSig.permission].policyData;
        unchecked {
            for (uint256 i = 0; i < policyData.length; i++) {
                (mSig.flag, mSig.policy) = ValidatorLib.decodePolicyData(policyData[i]);
                mSig.idx = uint8(bytes1(sig[0]));
                if (mSig.idx == i) {
                    // we are using uint64 length
                    mSig.length = uint64(bytes8(sig[1:9]));
                    mSig.permSig = sig[9:9 + mSig.length];
                    sig = sig[9 + mSig.length:];
                } else if (mSig.idx < i) {
                    // signature is not in order
                    revert PolicySignatureOrderError();
                } else {
                    mSig.permSig = sig[0:0];
                }

                if (PassFlag.unwrap(mSig.flag) & PassFlag.unwrap(SKIP_SIGNATURE) == 0) {
                    ValidationData vd = ValidationData.wrap(
                        mSig.policy.checkSignaturePolicy(
                            bytes32(PermissionId.unwrap(mSig.permission)), mSig.caller, mSig.digest, mSig.permSig
                        )
                    );
                    address result = getValidationResult(vd);
                    if (result != address(0)) {
                        revert PolicyFailed(i);
                    }

                    mSig.validationData = _intersectValidationData(mSig.validationData, vd);
                }
            }
        }
    }

    function _checkPermissionSignature(PermissionId pId, address caller, bytes32 hash, bytes calldata sig)
        internal
        view
        returns (bytes4)
    {
        (ISigner signer, ValidationData valdiationData, bytes calldata validatorSig) =
            _checkSignaturePolicy(pId, caller, hash, sig);
        (ValidAfter validAfter, ValidUntil validUntil,) = parseValidationData(ValidationData.unwrap(valdiationData));
        if (block.timestamp < ValidAfter.unwrap(validAfter) || block.timestamp > ValidUntil.unwrap(validUntil)) {
            return 0xffffffff;
        }
        return signer.checkSignature(bytes32(PermissionId.unwrap(pId)), caller, _toWrappedHash(hash), validatorSig);
    }

    function _toWrappedHash(bytes32 hash) internal view returns (bytes32) {
        return _hashTypedData(keccak256(abi.encode(KERNEL_WRAPPER_TYPE_HASH, hash)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IHook} from "../interfaces/IERC7579Modules.sol";
import {ModuleLib} from "../utils/ModuleLib.sol";

abstract contract HookManager {
    // NOTE: currently, all install/uninstall calls onInstall/onUninstall
    // I assume this does not pose any security risks, but there should be a way to branch if hook needs call to onInstall/onUninstall
    // --- Hook ---
    // Hook is activated on these scenarios
    // - on 4337 flow, userOp.calldata starts with executeUserOp.selector && validator requires hook
    // - executeFromExecutor() is invoked and executor requires hook
    // - when fallback function has been invoked and fallback requires hook => native functions will not invoke hook
    function _doPreHook(IHook hook, uint256 value, bytes calldata callData) internal returns (bytes memory context) {
        context = hook.preCheck(msg.sender, value, callData);
    }

    function _doPostHook(IHook hook, bytes memory context) internal {
        // bool success,
        // bytes memory result
        hook.postCheck(context);
    }

    // @notice if hook is not initialized before, kernel will call hook.onInstall no matter what flag it shows, with hookData[1:]
    // @param hookData is encoded into (1bytes flag + actual hookdata) flag is for identifying if the hook has to be initialized or not
    function _installHook(IHook hook, bytes calldata hookData) internal {
        if (address(hook) == address(0) || address(hook) == address(1)) {
            return;
        }
        if (!hook.isInitialized(address(this))) {
            // if hook is not installed, it should call onInstall
            hook.onInstall(hookData[1:]);
            return;
        }
        if (bytes1(hookData[0]) == bytes1(0xff)) {
            // 0xff means you want to explicitly call install hook
            hook.onInstall(hookData[1:]);
        }
    }

    // @param hookData encoded as (1bytes flag + actual hookdata) flag is for identifying if the hook has to be initialized or not
    function _uninstallHook(IHook hook, bytes calldata hookData) internal {
        if (address(hook) == address(0) || address(hook) == address(1)) {
            return;
        }
        if (bytes1(hookData[0]) == bytes1(0xff)) {
            // 0xff means you want to call uninstall hook
            ModuleLib.uninstallModule(address(hook), hookData[1:]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IHook, IExecutor} from "../interfaces/IERC7579Modules.sol";
import {ModuleLib} from "../utils/ModuleLib.sol";
import {EXECUTOR_MANAGER_STORAGE_SLOT} from "../types/Constants.sol";

abstract contract ExecutorManager {
    struct ExecutorConfig {
        IHook hook; // address(1) : hook not required, address(0) : validator not installed
    }

    struct ExecutorStorage {
        mapping(IExecutor => ExecutorConfig) executorConfig;
    }

    function executorConfig(IExecutor executor) external view returns (ExecutorConfig memory) {
        return _executorConfig(executor);
    }

    function _executorConfig(IExecutor executor) internal view returns (ExecutorConfig storage config) {
        ExecutorStorage storage es;
        bytes32 slot = EXECUTOR_MANAGER_STORAGE_SLOT;
        assembly {
            es.slot := slot
        }
        config = es.executorConfig[executor];
    }

    function _installExecutor(IExecutor executor, bytes calldata executorData, IHook hook) internal {
        if (address(hook) == address(0)) {
            hook = IHook(address(1));
        }
        ExecutorConfig storage config = _executorConfig(executor);
        config.hook = hook;
        executor.onInstall(executorData);
    }

    function _installExecutorWithoutInit(IExecutor executor, IHook hook) internal {
        if (address(hook) == address(0)) {
            hook = IHook(address(1));
        }
        ExecutorConfig storage config = _executorConfig(executor);
        config.hook = hook;
    }

    function _uninstallExecutor(IExecutor executor, bytes calldata executorData) internal returns (IHook hook) {
        ExecutorConfig storage config = _executorConfig(executor);
        hook = config.hook;
        config.hook = IHook(address(0));
        ModuleLib.uninstallModule(address(executor), executorData);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IHook, IFallback, IModule} from "../interfaces/IERC7579Modules.sol";
import {CallType} from "../utils/ExecLib.sol";
import {SELECTOR_MANAGER_STORAGE_SLOT, CALLTYPE_DELEGATECALL, CALLTYPE_SINGLE} from "../types/Constants.sol";
import {ModuleLib} from "../utils/ModuleLib.sol";

abstract contract SelectorManager {
    error NotSupportedCallType();

    struct SelectorConfig {
        IHook hook; // 20 bytes for hook address
        address target; // 20 bytes target will be fallback module, called with call
        CallType callType;
    }

    struct SelectorStorage {
        mapping(bytes4 => SelectorConfig) selectorConfig;
    }

    function selectorConfig(bytes4 selector) external view returns (SelectorConfig memory) {
        return _selectorConfig(selector);
    }

    function _selectorConfig(bytes4 selector) internal view returns (SelectorConfig storage config) {
        config = _selectorStorage().selectorConfig[selector];
    }

    function _selectorStorage() internal pure returns (SelectorStorage storage ss) {
        bytes32 slot = SELECTOR_MANAGER_STORAGE_SLOT;
        assembly {
            ss.slot := slot
        }
    }

    function _installSelector(bytes4 selector, address target, IHook hook, bytes calldata selectorData) internal {
        if (address(hook) == address(0)) {
            hook = IHook(address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        }
        SelectorConfig storage ss = _selectorConfig(selector);
        // we are going to install only through call/delegatecall
        CallType callType = CallType.wrap(bytes1(selectorData[0]));
        if (callType == CALLTYPE_SINGLE) {
            IModule(target).onInstall(selectorData[1:]);
        } else if (callType != CALLTYPE_DELEGATECALL) {
            // NOTE : we are not going to call onInstall for delegatecall, and we support only CALL & DELEGATECALL
            revert NotSupportedCallType();
        }
        ss.hook = hook;
        ss.target = target;
        ss.callType = callType;
    }

    function _uninstallSelector(bytes4 selector, bytes calldata selectorDeinitData) internal returns (IHook hook) {
        SelectorConfig storage ss = _selectorConfig(selector);
        hook = ss.hook;
        ss.hook = IHook(address(0));
        ModuleLib.uninstallModule(ss.target, selectorDeinitData);
        ss.target = address(0);
        ss.callType = CallType.wrap(bytes1(0xff));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PackedUserOperation} from "./PackedUserOperation.sol";

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
     *         Note: solely relying on bytes32 hash and signature is not sufficient for some
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
    function preCheck(address msgSender, uint256 msgValue, bytes calldata msgData)
        external
        payable
        returns (bytes memory hookData);

    function postCheck(bytes calldata hookData) external payable;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract for EIP-712 typed structured data hashing and signing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
/// @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
///
/// @dev Note, this implementation:
/// - Uses `address(this)` for the `verifyingContract` field.
/// - Does NOT use the optional EIP-712 salt.
/// - Does NOT use any EIP-712 extensions.
/// This is for simplicity and to save gas.
/// If you need to customize, please fork / modify accordingly.
abstract contract EIP712 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  CONSTANTS AND IMMUTABLES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    uint256 private immutable _cachedThis;
    uint256 private immutable _cachedChainId;
    bytes32 private immutable _cachedNameHash;
    bytes32 private immutable _cachedVersionHash;
    bytes32 private immutable _cachedDomainSeparator;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cache the hashes for cheaper runtime gas costs.
    /// In the case of upgradeable contracts (i.e. proxies),
    /// or if the chain id changes due to a hard fork,
    /// the domain separator will be seamlessly calculated on-the-fly.
    constructor() {
        _cachedThis = uint256(uint160(address(this)));
        _cachedChainId = block.chainid;

        string memory name;
        string memory version;
        if (!_domainNameAndVersionMayChange()) (name, version) = _domainNameAndVersion();
        bytes32 nameHash = _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(name));
        bytes32 versionHash =
            _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(version));
        _cachedNameHash = nameHash;
        _cachedVersionHash = versionHash;

        bytes32 separator;
        if (!_domainNameAndVersionMayChange()) {
            /// @solidity memory-safe-assembly
            assembly {
                let m := mload(0x40) // Load the free memory pointer.
                mstore(m, _DOMAIN_TYPEHASH)
                mstore(add(m, 0x20), nameHash)
                mstore(add(m, 0x40), versionHash)
                mstore(add(m, 0x60), chainid())
                mstore(add(m, 0x80), address())
                separator := keccak256(m, 0xa0)
            }
        }
        _cachedDomainSeparator = separator;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   FUNCTIONS TO OVERRIDE                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Please override this function to return the domain name and version.
    /// ```
    ///     function _domainNameAndVersion()
    ///         internal
    ///         pure
    ///         virtual
    ///         returns (string memory name, string memory version)
    ///     {
    ///         name = "Solady";
    ///         version = "1";
    ///     }
    /// ```
    ///
    /// Note: If the returned result may change after the contract has been deployed,
    /// you must override `_domainNameAndVersionMayChange()` to return true.
    function _domainNameAndVersion()
        internal
        view
        virtual
        returns (string memory name, string memory version);

    /// @dev Returns if `_domainNameAndVersion()` may change
    /// after the contract has been deployed (i.e. after the constructor).
    /// Default: false.
    function _domainNameAndVersionMayChange() internal pure virtual returns (bool result) {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _domainSeparator() internal view virtual returns (bytes32 separator) {
        if (_domainNameAndVersionMayChange()) {
            separator = _buildDomainSeparator();
        } else {
            separator = _cachedDomainSeparator;
            if (_cachedDomainSeparatorInvalidated()) separator = _buildDomainSeparator();
        }
    }

    /// @dev Returns the hash of the fully encoded EIP-712 message for this domain,
    /// given `structHash`, as defined in
    /// https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    ///
    /// The hash can be used together with {ECDSA-recover} to obtain the signer of a message:
    /// ```
    ///     bytes32 digest = _hashTypedData(keccak256(abi.encode(
    ///         keccak256("Mail(address to,string contents)"),
    ///         mailTo,
    ///         keccak256(bytes(mailContents))
    ///     )));
    ///     address signer = ECDSA.recover(digest, signature);
    /// ```
    function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
        // We will use `digest` to store the domain separator to save a bit of gas.
        if (_domainNameAndVersionMayChange()) {
            digest = _buildDomainSeparator();
        } else {
            digest = _cachedDomainSeparator;
            if (_cachedDomainSeparatorInvalidated()) digest = _buildDomainSeparator();
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EIP-5267 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev See: https://eips.ethereum.org/EIPS/eip-5267
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        fields = hex"0f"; // `0b01111`.
        (name, version) = _domainNameAndVersion();
        chainId = block.chainid;
        verifyingContract = address(this);
        salt = salt; // `bytes32(0)`.
        extensions = extensions; // `new uint256[](0)`.
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _buildDomainSeparator() private view returns (bytes32 separator) {
        // We will use `separator` to store the name hash to save a bit of gas.
        bytes32 versionHash;
        if (_domainNameAndVersionMayChange()) {
            (string memory name, string memory version) = _domainNameAndVersion();
            separator = keccak256(bytes(name));
            versionHash = keccak256(bytes(version));
        } else {
            separator = _cachedNameHash;
            versionHash = _cachedVersionHash;
        }
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), separator) // Name hash.
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            separator := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns if the cached domain separator has been invalidated.
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        uint256 cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }
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

    function execute(ExecMode execMode, bytes calldata executionCalldata)
        internal
        returns (bytes[] memory returnData)
    {
        (CallType callType, ExecType execType,,) = decode(execMode);

        // check if calltype is batch or single
        if (callType == CALLTYPE_BATCH) {
            // destructure executionCallData according to batched exec
            Execution[] calldata executions = decodeBatch(executionCalldata);
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) returnData = execute(executions);
            else if (execType == EXECTYPE_TRY) returnData = tryExecute(executions);
            else revert("Unsupported");
        } else if (callType == CALLTYPE_SINGLE) {
            // destructure executionCallData according to single exec
            (address target, uint256 value, bytes calldata callData) = decodeSingle(executionCalldata);
            returnData = new bytes[](1);
            bool success;
            // check if execType is revert or try
            if (execType == EXECTYPE_DEFAULT) {
                returnData[0] = execute(target, value, callData);
            } else if (execType == EXECTYPE_TRY) {
                (success, returnData[0]) = tryExecute(target, value, callData);
                if (!success) emit TryExecuteUnsuccessful(0, returnData[0]);
            } else {
                revert("Unsupported");
            }
        } else if (callType == CALLTYPE_DELEGATECALL) {
            returnData = new bytes[](1);
            address delegate = address(bytes20(executionCalldata[0:20]));
            bytes calldata callData = executionCalldata[20:];
            bool success;
            (success, returnData[0]) = executeDelegatecall(delegate, callData);
            if (execType == EXECTYPE_TRY) {
                if (!success) emit TryExecuteUnsuccessful(0, returnData[0]);
            } else if (execType == EXECTYPE_DEFAULT) {
                if (!success) revert("Delegatecall failed");
            } else {
                revert("Unsupported");
            }
        } else {
            revert("Unsupported");
        }
    }

    function execute(Execution[] calldata executions) internal returns (bytes[] memory result) {
        uint256 length = executions.length;
        result = new bytes[](length);

        for (uint256 i; i < length; i++) {
            Execution calldata _exec = executions[i];
            result[i] = execute(_exec.target, _exec.value, _exec.callData);
        }
    }

    function tryExecute(Execution[] calldata executions) internal returns (bytes[] memory result) {
        uint256 length = executions.length;
        result = new bytes[](length);

        for (uint256 i; i < length; i++) {
            Execution calldata _exec = executions[i];
            bool success;
            (success, result[i]) = tryExecute(_exec.target, _exec.value, _exec.callData);
            if (!success) emit TryExecuteUnsuccessful(i, result[i]);
        }
    }

    function execute(address target, uint256 value, bytes calldata callData) internal returns (bytes memory result) {
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

    function tryExecute(address target, uint256 value, bytes calldata callData)
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
    function executeDelegatecall(address delegate, bytes calldata callData)
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

    function doFallback2771Static(address fallbackHandler) internal view returns (bool success, bytes memory result) {
        assembly {
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            let calldataPtr := allocate(calldatasize())
            calldatacopy(calldataPtr, 0, calldatasize())

            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            let senderPtr := allocate(20)
            mstore(senderPtr, shl(96, caller()))

            // Add 20 bytes for the address appended add the end
            success := staticcall(gas(), fallbackHandler, calldataPtr, add(calldatasize(), 20), 0, 0)

            result := mload(0x40)
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    function doFallback2771Call(address target) internal returns (bool success, bytes memory result) {
        assembly {
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            let calldataPtr := allocate(calldatasize())
            calldatacopy(calldataPtr, 0, calldatasize())

            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            let senderPtr := allocate(20)
            mstore(senderPtr, shl(96, caller()))

            // Add 20 bytes for the address appended add the end
            success := call(gas(), target, 0, calldataPtr, add(calldatasize(), 20), 0, 0)

            result := mload(0x40)
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {CallType, ExecType, ExecModeSelector} from "./Types.sol";
import {PassFlag, ValidationMode, ValidationType} from "./Types.sol";
import {ValidationData} from "./Types.sol";

// --- ERC7579 calltypes ---
// Default CallType
CallType constant CALLTYPE_SINGLE = CallType.wrap(0x00);
// Batched CallType
CallType constant CALLTYPE_BATCH = CallType.wrap(0x01);
CallType constant CALLTYPE_STATIC = CallType.wrap(0xFE);
// @dev Implementing delegatecall is OPTIONAL!
// implement delegatecall with extreme care.
CallType constant CALLTYPE_DELEGATECALL = CallType.wrap(0xFF);

// --- ERC7579 exectypes ---
// @dev default behavior is to revert on failure
// To allow very simple accounts to use mode encoding, the default behavior is to revert on failure
// Since this is value 0x00, no additional encoding is required for simple accounts
ExecType constant EXECTYPE_DEFAULT = ExecType.wrap(0x00);
// @dev account may elect to change execution behavior. For example "try exec" / "allow fail"
ExecType constant EXECTYPE_TRY = ExecType.wrap(0x01);

// --- ERC7579 mode selector ---
ExecModeSelector constant EXEC_MODE_DEFAULT = ExecModeSelector.wrap(bytes4(0x00000000));

// --- Kernel permission skip flags ---
PassFlag constant SKIP_USEROP = PassFlag.wrap(0x0001);
PassFlag constant SKIP_SIGNATURE = PassFlag.wrap(0x0002);

// --- Kernel validation modes ---
ValidationMode constant VALIDATION_MODE_DEFAULT = ValidationMode.wrap(0x00);
ValidationMode constant VALIDATION_MODE_ENABLE = ValidationMode.wrap(0x01);
ValidationMode constant VALIDATION_MODE_INSTALL = ValidationMode.wrap(0x02);

// --- Kernel validation types ---
ValidationType constant VALIDATION_TYPE_ROOT = ValidationType.wrap(0x00);
ValidationType constant VALIDATION_TYPE_VALIDATOR = ValidationType.wrap(0x01);
ValidationType constant VALIDATION_TYPE_PERMISSION = ValidationType.wrap(0x02);

// --- storage slots ---
// bytes32(uint256(keccak256('kernel.v3.selector')) - 1)
bytes32 constant SELECTOR_MANAGER_STORAGE_SLOT = 0x7c341349a4360fdd5d5bc07e69f325dc6aaea3eb018b3e0ea7e53cc0bb0d6f3b;
// bytes32(uint256(keccak256('kernel.v3.executor')) - 1)
bytes32 constant EXECUTOR_MANAGER_STORAGE_SLOT = 0x1bbee3173dbdc223633258c9f337a0fff8115f206d302bea0ed3eac003b68b86;
// bytes32(uint256(keccak256('kernel.v3.hook')) - 1)
bytes32 constant HOOK_MANAGER_STORAGE_SLOT = 0x4605d5f70bb605094b2e761eccdc27bed9a362d8612792676bf3fb9b12832ffc;
// bytes32(uint256(keccak256('kernel.v3.validation')) - 1)
bytes32 constant VALIDATION_MANAGER_STORAGE_SLOT = 0x7bcaa2ced2a71450ed5a9a1b4848e8e5206dbc3f06011e595f7f55428cc6f84f;
bytes32 constant ERC1967_IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

// --- Kernel validation nonce incremental size limit ---
uint32 constant MAX_NONCE_INCREMENT_SIZE = 10;

// -- EIP712 type hash ---
bytes32 constant ENABLE_TYPE_HASH = 0xb17ab1224aca0d4255ef8161acaf2ac121b8faa32a4b2258c912cc5f8308c505;
bytes32 constant KERNEL_WRAPPER_TYPE_HASH = 0x1547321c374afde8a591d972a084b071c594c275e36724931ff96c25f2999c83;

// --- ERC constants ---
// ERC4337 constants
uint256 constant SIG_VALIDATION_FAILED_UINT = 1;
uint256 constant SIG_VALIDATION_SUCCESS_UINT = 0;
ValidationData constant SIG_VALIDATION_FAILED = ValidationData.wrap(SIG_VALIDATION_FAILED_UINT);

// ERC-1271 constants
bytes4 constant ERC1271_MAGICVALUE = 0x1626ba7e;
bytes4 constant ERC1271_INVALID = 0xffffffff;

uint256 constant MODULE_TYPE_VALIDATOR = 1;
uint256 constant MODULE_TYPE_EXECUTOR = 2;
uint256 constant MODULE_TYPE_FALLBACK = 3;
uint256 constant MODULE_TYPE_HOOK = 4;
uint256 constant MODULE_TYPE_POLICY = 5;
uint256 constant MODULE_TYPE_SIGNER = 6;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

// Custom type for improved developer experience
type ExecMode is bytes32;

type CallType is bytes1;

type ExecType is bytes1;

type ExecModeSelector is bytes4;

type ExecModePayload is bytes22;

using {eqModeSelector as ==} for ExecModeSelector global;
using {eqCallType as ==} for CallType global;
using {notEqCallType as !=} for CallType global;
using {eqExecType as ==} for ExecType global;

function eqCallType(CallType a, CallType b) pure returns (bool) {
    return CallType.unwrap(a) == CallType.unwrap(b);
}

function notEqCallType(CallType a, CallType b) pure returns (bool) {
    return CallType.unwrap(a) != CallType.unwrap(b);
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

/**
 * Manage deposits and stakes.
 * Deposit is just a balance used to pay for UserOperations (either by a paymaster or an account).
 * Stake is value locked for at least "unstakeDelay" by the staked entity.
 */
interface IStakeManager {
    event Deposited(address indexed account, uint256 totalDeposit);

    event Withdrawn(address indexed account, address withdrawAddress, uint256 amount);

    // Emitted when stake or unstake delay are modified.
    event StakeLocked(address indexed account, uint256 totalStaked, uint256 unstakeDelaySec);

    // Emitted once a stake is scheduled for withdrawal.
    event StakeUnlocked(address indexed account, uint256 withdrawTime);

    event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 amount);

    /**
     * @param deposit         - The entity's deposit.
     * @param staked          - True if this entity is staked.
     * @param stake           - Actual amount of ether staked for this entity.
     * @param unstakeDelaySec - Minimum delay to withdraw the stake.
     * @param withdrawTime    - First block timestamp where 'withdrawStake' will be callable, or zero if already locked.
     * @dev Sizes were chosen so that deposit fits into one cell (used during handleOp)
     *      and the rest fit into a 2nd cell (used during stake/unstake)
     *      - 112 bit allows for 10^15 eth
     *      - 48 bit for full timestamp
     *      - 32 bit allows 150 years for unstake delay
     */
    struct DepositInfo {
        uint256 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint48 withdrawTime;
    }

    // API struct used by getStakeInfo and simulateValidation.
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    /**
     * Get deposit info.
     * @param account - The account to query.
     * @return info   - Full deposit information of given account.
     */
    function getDepositInfo(address account) external view returns (DepositInfo memory info);

    /**
     * Get account balance.
     * @param account - The account to query.
     * @return        - The deposit (for gas payment) of the account.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * Add to the deposit of the given account.
     * @param account - The account to add to.
     */
    function depositTo(address account) external payable;

    /**
     * Add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param _unstakeDelaySec - The new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 _unstakeDelaySec) external payable;

    /**
     * Attempt to unlock the stake.
     * The value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external;

    /**
     * Withdraw from the (unlocked) stake.
     * Must first call unlockStake and wait for the unstakeDelay to pass.
     * @param withdrawAddress - The address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external;

    /**
     * Withdraw from the deposit.
     * @param withdrawAddress - The address to send withdrawn value.
     * @param withdrawAmount  - The amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "./PackedUserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {
    /**
     * Validate aggregated signature.
     * Revert if the aggregated signature does not match the given list of operations.
     * @param userOps   - Array of UserOperations to validate the signature for.
     * @param signature - The aggregated signature.
     */
    function validateSignatures(PackedUserOperation[] calldata userOps, bytes calldata signature) external view;

    /**
     * Validate signature of a single userOp.
     * This method should be called by bundler after EntryPointSimulation.simulateValidation() returns
     * the aggregator this account uses.
     * First it validates the signature over the userOp. Then it returns data to be used when creating the handleOps.
     * @param userOp        - The userOperation received from the user.
     * @return sigForUserOp - The value to put into the signature field of the userOp when calling handleOps.
     *                        (usually empty, unless account and aggregator support some kind of "multisig".
     */
    function validateUserOpSignature(PackedUserOperation calldata userOp)
        external
        view
        returns (bytes memory sigForUserOp);

    /**
     * Aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation.
     * @param userOps              - Array of UserOperations to collect the signatures from.
     * @return aggregatedSignature - The aggregated signature.
     */
    function aggregateSignatures(PackedUserOperation[] calldata userOps)
        external
        view
        returns (bytes memory aggregatedSignature);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

interface INonceManager {
    /**
     * Return the next nonce for this sender.
     * Within a given key, the nonce values are sequenced (starting with zero, and incremented by one on each userop)
     * But UserOp with different keys can come with arbitrary order.
     *
     * @param sender the account address
     * @param key the high 192 bit of the nonce
     * @return nonce a full nonce to pass for next UserOp with this sender.
     */
    function getNonce(address sender, uint192 key) external view returns (uint256 nonce);

    /**
     * Manually increment the nonce of the sender.
     * This method is exposed just for completeness..
     * Account does NOT need to call it, neither during validation, nor elsewhere,
     * as the EntryPoint will update the nonce regardless.
     * Possible use-case is call it with various keys to "initialize" their nonces to one, so that future
     * UserOperations will not pay extra for the first transaction with a given key.
     */
    function incrementNonce(uint192 key) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _value The value in wei to send to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint256 _value,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
        internal
        pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IValidator, IPolicy} from "../interfaces/IERC7579Modules.sol";
import {PassFlag, ValidationType, ValidationId, ValidationMode, PolicyData, PermissionId} from "../types/Types.sol";
import {VALIDATION_TYPE_PERMISSION} from "../types/Constants.sol";

library ValidatorLib {
    function encodeFlag(bool skipUserOp, bool skipSignature) internal pure returns (PassFlag flag) {
        assembly {
            if skipUserOp { flag := 0x0001000000000000000000000000000000000000000000000000000000000000 }
            if skipSignature { flag := or(flag, 0x0002000000000000000000000000000000000000000000000000000000000000) }
        }
    }

    function encodePolicyData(bool skipUserOp, bool skipSig, address policy) internal pure returns (PolicyData data) {
        assembly {
            if skipUserOp { data := 0x0001000000000000000000000000000000000000000000000000000000000000 }
            if skipSig { data := or(data, 0x0002000000000000000000000000000000000000000000000000000000000000) }
            data := or(data, shl(80, policy))
        }
    }

    function encodePermissionAsNonce(bytes1 mode, bytes4 permissionId, uint16 nonceKey, uint64 nonce)
        internal
        pure
        returns (uint256 res)
    {
        return encodeAsNonce(
            mode, ValidationType.unwrap(VALIDATION_TYPE_PERMISSION), bytes20(permissionId), nonceKey, nonce
        );
    }

    function encodeAsNonce(bytes1 mode, bytes1 vType, bytes20 ValidationIdWithoutType, uint16 nonceKey, uint64 nonce)
        internal
        pure
        returns (uint256 res)
    {
        assembly {
            res := nonce
            res := or(res, shl(64, nonceKey))
            res := or(res, shr(16, ValidationIdWithoutType))
            res := or(res, shr(8, vType))
            res := or(res, mode)
        }
    }

    function encodeAsNonceKey(bytes1 mode, bytes1 vType, bytes20 ValidationIdWithoutType, uint16 nonceKey)
        internal
        pure
        returns (uint192 res)
    {
        assembly {
            res := or(nonceKey, shr(80, ValidationIdWithoutType))
            res := or(res, shr(72, vType))
            res := or(res, shr(64, mode))
        }
    }

    function decodeNonce(uint256 nonce)
        internal
        pure
        returns (ValidationMode mode, ValidationType vType, ValidationId identifier)
    {
        // 2bytes mode (1byte currentMode, 1byte type)
        // 21bytes identifier
        // 1byte mode  | 1byte type | 20bytes identifierWithoutType | 2byte nonceKey | 8byte nonce == 32bytes
        assembly {
            mode := nonce
            vType := shl(8, nonce)
            identifier := shl(8, nonce)
            switch shr(248, identifier)
            case 0x0000000000000000000000000000000000000000000000000000000000000002 {
                identifier := and(identifier, 0xffffffffff000000000000000000000000000000000000000000000000000000)
            }
        }
    }

    function decodeSignature(bytes calldata signature) internal pure returns (ValidationId vId, bytes calldata sig) {
        assembly {
            vId := calldataload(signature.offset)
            switch shr(248, vId)
            case 0 {
                // sudo mode
                vId := 0x00
                sig.offset := add(signature.offset, 1)
                sig.length := sub(signature.length, 1)
            }
            case 1 {
                // validator mode
                sig.offset := add(signature.offset, 21)
                sig.length := sub(signature.length, 21)
            }
            case 2 {
                vId := and(vId, 0xffffffffff000000000000000000000000000000000000000000000000000000)
                sig.offset := add(signature.offset, 5)
                sig.length := sub(signature.length, 5)
            }
            default { revert(0x00, 0x00) }
        }
    }

    function decodePolicyData(PolicyData data) internal pure returns (PassFlag flag, IPolicy policy) {
        assembly {
            flag := data
            policy := shr(80, data)
        }
    }

    function validatorToIdentifier(IValidator validator) internal pure returns (ValidationId vId) {
        assembly {
            vId := 0x0100000000000000000000000000000000000000000000000000000000000000
            vId := or(vId, shl(88, validator))
        }
    }

    function getType(ValidationId validator) internal pure returns (ValidationType vType) {
        assembly {
            vType := validator
        }
    }

    function getValidator(ValidationId validator) internal pure returns (IValidator v) {
        assembly {
            v := shr(88, validator)
        }
    }

    function getPermissionId(ValidationId validator) internal pure returns (PermissionId id) {
        assembly {
            id := shl(8, validator)
        }
    }

    function permissionToIdentifier(PermissionId permissionId) internal pure returns (ValidationId vId) {
        assembly {
            vId := 0x0200000000000000000000000000000000000000000000000000000000000000
            vId := or(vId, shr(8, permissionId))
        }
    }

    function getPolicy(PolicyData data) internal pure returns (IPolicy vId) {
        assembly {
            vId := shr(80, data)
        }
    }

    function getPermissionSkip(PolicyData data) internal pure returns (PassFlag flag) {
        assembly {
            flag := data
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SIG_VALIDATION_FAILED_UINT} from "../types/Constants.sol";
import {ValidationData, getValidationResult} from "../types/Types.sol";

function _intersectValidationData(ValidationData a, ValidationData b) pure returns (ValidationData validationData) {
    assembly {
        // xor(a,b) == shows only matching bits
        // and(xor(a,b), 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff) == filters out the validAfter and validUntil bits
        // if the result is not zero, then aggregator part is not matching
        // validCase :
        // a == 0 || b == 0 || xor(a,b) == 0
        // invalidCase :
        // a mul b != 0 && xor(a,b) != 0
        let sum := shl(96, add(a, b))
        switch or(
            iszero(and(xor(a, b), 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)),
            or(eq(sum, shl(96, a)), eq(sum, shl(96, b)))
        )
        case 1 {
            validationData := and(or(a, b), 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
            // validAfter
            let a_vd := and(0xffffffffffff0000000000000000000000000000000000000000000000000000, a)
            let b_vd := and(0xffffffffffff0000000000000000000000000000000000000000000000000000, b)
            validationData := or(validationData, xor(a_vd, mul(xor(a_vd, b_vd), gt(b_vd, a_vd))))
            // validUntil
            a_vd := and(0x000000000000ffffffffffff0000000000000000000000000000000000000000, a)
            if iszero(a_vd) { a_vd := 0x000000000000ffffffffffff0000000000000000000000000000000000000000 }
            b_vd := and(0x000000000000ffffffffffff0000000000000000000000000000000000000000, b)
            if iszero(b_vd) { b_vd := 0x000000000000ffffffffffff0000000000000000000000000000000000000000 }
            let until := xor(a_vd, mul(xor(a_vd, b_vd), lt(b_vd, a_vd)))
            if iszero(until) { until := 0x000000000000ffffffffffff0000000000000000000000000000000000000000 }
            validationData := or(validationData, until)
        }
        default { validationData := SIG_VALIDATION_FAILED_UINT }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

struct Execution {
    address target;
    uint256 value;
    bytes callData;
}