// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SoulWalletCore} from "@soulwallet-core/contracts/SoulWalletCore.sol";
import {IAccount, UserOperation} from "@soulwallet-core/contracts/interface/IAccount.sol";
import {EntryPointManager} from "@soulwallet-core/contracts/base/EntryPointManager.sol";
import {FallbackManager} from "@soulwallet-core/contracts/base/FallbackManager.sol";
import {StandardExecutor} from "@soulwallet-core/contracts/base/StandardExecutor.sol";
import {ValidatorManager} from "@soulwallet-core/contracts/base/ValidatorManager.sol";
import {SignatureDecoder} from "@soulwallet-core/contracts/utils/SignatureDecoder.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Errors} from "./libraries/Errors.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./abstract/ERC1271Handler.sol";
import {SoulWalletOwnerManager} from "./abstract/SoulWalletOwnerManager.sol";
import {SoulWalletModuleManager} from "./abstract/SoulWalletModuleManager.sol";
import {SoulWalletHookManager} from "./abstract/SoulWalletHookManager.sol";
import {SoulWalletUpgradeManager} from "./abstract/SoulWalletUpgradeManager.sol";

contract SoulWallet is
    Initializable,
    IAccount,
    IERC1271,
    EntryPointManager,
    SoulWalletOwnerManager,
    SoulWalletModuleManager,
    SoulWalletHookManager,
    StandardExecutor,
    ValidatorManager,
    FallbackManager,
    SoulWalletUpgradeManager,
    ERC1271Handler
{
    address internal immutable _DEFAULT_VALIDATOR;

    constructor(address _entryPoint, address defaultValidator) EntryPointManager(_entryPoint) {
        _DEFAULT_VALIDATOR = defaultValidator;
        _disableInitializers();
    }

    function initialize(
        bytes32[] calldata owners,
        address defalutCallbackHandler,
        bytes[] calldata modules,
        bytes[] calldata hooks
    ) external initializer {
        _addOwners(owners);
        _setFallbackHandler(defalutCallbackHandler);
        _installValidator(_DEFAULT_VALIDATOR);
        for (uint256 i = 0; i < modules.length;) {
            _addModule(modules[i]);
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < hooks.length;) {
            _installHook(hooks[i]);
            unchecked {
                i++;
            }
        }
    }

    function _uninstallValidator(address validator) internal override {
        require(validator != _DEFAULT_VALIDATOR, "can't uninstall default validator");
        super._uninstallValidator(validator);
    }

    function _resetValidator(address validator) internal override {
        require(validator == _DEFAULT_VALIDATOR, "can't uninstall default validator");
        super._resetValidator(validator);
    }

    function isValidSignature(bytes32 _hash, bytes calldata signature)
        public
        view
        override
        returns (bytes4 magicValue)
    {
        bytes32 datahash = _encodeRawHash(_hash);

        (address validator, bytes calldata validatorSignature, bytes calldata hookSignature) =
            SignatureDecoder.signatureSplit(signature);
        _preIsValidSignatureHook(datahash, hookSignature);
        return _isValidSignature(datahash, validator, validatorSignature);
    }

    function _decodeSignature(bytes calldata signature)
        internal
        pure
        virtual
        returns (address validator, bytes calldata validatorSignature, bytes calldata hookSignature)
    {
        return SignatureDecoder.signatureSplit(signature);
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        public
        payable
        virtual
        override
        returns (uint256 validationData)
    {
        _onlyEntryPoint();

        assembly ("memory-safe") {
            if missingAccountFunds {
                // ignore failure (its EntryPoint's job to verify, not account.)
                pop(call(gas(), caller(), missingAccountFunds, 0x00, 0x00, 0x00, 0x00))
            }
        }
        (address validator, bytes calldata validatorSignature, bytes calldata hookSignature) =
            _decodeSignature(userOp.signature);

        /*
            Warning!!!
                This function uses `return` to terminate the execution of the entire contract.
                If any `Hook` fails, this function will stop the contract's execution and
                return `SIG_VALIDATION_FAILED`, skipping all the subsequent unexecuted code.
        */
        _preUserOpValidationHook(userOp, userOpHash, missingAccountFunds, hookSignature);

        /*
            When any hook execution fails, this line will not be executed.
         */
        return _validateUserOp(userOp, userOpHash, validator, validatorSignature);
    }

    /**
     * Only authorized modules can manage hooks and modules.
     */
    function pluginManagementAccess() internal view override {
        _onlyModule();
    }

    /**
     * Only authorized modules can manage validators
     */
    function validatorManagementAccess() internal view override {
        _onlyModule();
    }

    function upgradeTo(address newImplementation) external override {
        _onlyModule();
        _upgradeTo(newImplementation);
    }

    /// @notice Handles the upgrade from an old implementation
    /// @param oldImplementation Address of the old implementation
    function upgradeFrom(address oldImplementation) external pure override {
        (oldImplementation);
        revert Errors.NOT_IMPLEMENTED(); //Initial version no need data migration
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAccount, UserOperation} from "./interface/IAccount.sol";
import {EntryPointManager} from "./base/EntryPointManager.sol";
import {FallbackManager} from "./base/FallbackManager.sol";
import {ModuleManager} from "./base/ModuleManager.sol";
import {OwnerManager} from "./base/OwnerManager.sol";
import {StandardExecutor} from "./base/StandardExecutor.sol";
import {ValidatorManager} from "./base/ValidatorManager.sol";
import {HookManager} from "./base/HookManager.sol";
import {SignatureDecoder} from "./utils/SignatureDecoder.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract SoulWalletCore is
    IAccount,
    IERC1271,
    EntryPointManager,
    OwnerManager,
    ModuleManager,
    HookManager,
    StandardExecutor,
    ValidatorManager,
    FallbackManager
{
    constructor(address _entryPoint) EntryPointManager(_entryPoint) {}

    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        virtual
        override
        returns (bytes4 magicValue)
    {
        (address validator, bytes calldata validatorSignature, bytes calldata hookSignature) =
            SignatureDecoder.signatureSplit(signature);

        /*
            Warning!!!
                This function uses `return` to terminate the execution of the entire contract.
                If any `Hook` fails, this function will stop the contract's execution and
                return `bytes4(0)`, skipping all the subsequent unexecuted code.
        */
        _preIsValidSignatureHook(hash, hookSignature);

        /*
            When any hook execution fails, this line will not be executed.
         */
        return _isValidSignature(hash, validator, validatorSignature);
    }

    /**
     * @dev If you need to redefine the signatures structure, please override this function.
     */
    function _decodeSignature(bytes calldata signature)
        internal
        view
        virtual
        returns (address validator, bytes calldata validatorSignature, bytes calldata hookSignature)
    {
        return SignatureDecoder.signatureSplit(signature);
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        public
        payable
        virtual
        override
        returns (uint256 validationData)
    {
        _onlyEntryPoint();

        assembly ("memory-safe") {
            if missingAccountFunds {
                // ignore failure (its EntryPoint's job to verify, not account.)
                pop(call(gas(), caller(), missingAccountFunds, 0x00, 0x00, 0x00, 0x00))
            }
        }
        (address validator, bytes calldata validatorSignature, bytes calldata hookSignature) =
            _decodeSignature(userOp.signature);

        /*
            Warning!!!
                This function uses `return` to terminate the execution of the entire contract.
                If any `Hook` fails, this function will stop the contract's execution and
                return `SIG_VALIDATION_FAILED`, skipping all the subsequent unexecuted code.
        */
        _preUserOpValidationHook(userOp, userOpHash, missingAccountFunds, hookSignature);

        /*
            When any hook execution fails, this line will not be executed.
         */
        return _validateUserOp(userOp, userOpHash, validator, validatorSignature);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";

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
        external
        payable
        returns (uint256 validationData);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Authority} from "./Authority.sol";

abstract contract EntryPointManager is Authority {
    /**
     * @dev use immutable to save gas
     */
    address internal immutable _ENTRY_POINT;

    /**
     * a custom error for caller must be entry point
     */
    error CALLER_MUST_BE_ENTRY_POINT();

    constructor(address _entryPoint) {
        _ENTRY_POINT = _entryPoint;
    }

    function entryPoint() external view returns (address) {
        return _ENTRY_POINT;
    }

    /**
     * @notice Ensures the calling contract is the entrypoint
     */
    function _onlyEntryPoint() internal view override {
        if (msg.sender != _ENTRY_POINT) {
            revert CALLER_MUST_BE_ENTRY_POINT();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Authority} from "./Authority.sol";
import {IFallbackManager} from "../interface/IFallbackManager.sol";
import {AccountStorage} from "../utils/AccountStorage.sol";
import {FallbackManagerBase} from "../snippets/FallbackManager.sol";

abstract contract FallbackManager is IFallbackManager, Authority, FallbackManagerBase {
    receive() external payable virtual {}

    /**
     * @dev Sets the address of the fallback handler contract
     * @param fallbackContract The address of the new fallback handler contract
     */
    function _setFallbackHandler(address fallbackContract) internal virtual override {
        AccountStorage.layout().defaultFallbackContract = fallbackContract;
    }

    /**
     * @notice Fallback function that forwards all requests to the fallback handler contract
     * @dev The request is forwarded using a STATICCALL
     * It ensures that the state of the contract doesn't change even if the fallback function has state-changing operations
     */
    fallback() external payable virtual {
        address fallbackContract = AccountStorage.layout().defaultFallbackContract;
        assembly ("memory-safe") {
            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            if iszero(fallbackContract) { return(0, 0) }
            let calldataPtr := allocate(calldatasize())
            calldatacopy(calldataPtr, 0, calldatasize())

            let result := staticcall(gas(), fallbackContract, calldataPtr, calldatasize(), 0, 0)

            let returndataPtr := allocate(returndatasize())
            returndatacopy(returndataPtr, 0, returndatasize())

            if iszero(result) { revert(returndataPtr, returndatasize()) }
            return(returndataPtr, returndatasize())
        }
    }

    /**
     * @notice Sets the address of the fallback handler and emits the FallbackChanged event
     * @param fallbackContract The address of the new fallback handler
     */
    function setFallbackHandler(address fallbackContract) external virtual override {
        fallbackManagementAccess();
        _setFallbackHandler(fallbackContract);
        emit FallbackChanged(fallbackContract);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Authority} from "./Authority.sol";
import {IStandardExecutor, Execution} from "../interface/IStandardExecutor.sol";
import {EntryPointManager} from "./EntryPointManager.sol";

abstract contract StandardExecutor is Authority, IStandardExecutor, EntryPointManager {
    /**
     * @dev execute method
     * only entrypoint can call this method
     * @param target the target address
     * @param value the value
     * @param data the data
     */
    function execute(address target, uint256 value, bytes calldata data) external payable virtual override {
        executorAccess();

        assembly ("memory-safe") {
            // memorySafe: Memory allocated by yourself using a mechanism like the allocate function described above.

            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            let calldataPtr := allocate(data.length)
            calldatacopy(calldataPtr, data.offset, data.length)

            let result := call(gas(), target, value, calldataPtr, data.length, 0, 0)

            // note: return data is ignored
            if iszero(result) {
                let returndataPtr := allocate(returndatasize())
                returndatacopy(returndataPtr, 0, returndatasize())
                revert(returndataPtr, returndatasize())
            }
        }
    }

    /**
     * @dev execute batch method
     * only entrypoint can call this method
     * @param executions the executions
     */
    function executeBatch(Execution[] calldata executions) external payable virtual override {
        executorAccess();

        for (uint256 i = 0; i < executions.length; i++) {
            Execution calldata execution = executions[i];
            address target = execution.target;
            uint256 value = execution.value;
            bytes calldata data = execution.data;

            assembly ("memory-safe") {
                // memorySafe: Memory allocated by yourself using a mechanism like the allocate function described above.

                function allocate(length) -> pos {
                    pos := mload(0x40)
                    mstore(0x40, add(pos, length))
                }

                let calldataPtr := allocate(data.length)
                calldatacopy(calldataPtr, data.offset, data.length)

                let result := call(gas(), target, value, calldataPtr, data.length, 0, 0)

                // note: return data is ignored
                if iszero(result) {
                    let returndataPtr := allocate(returndatasize())
                    returndatacopy(returndataPtr, 0, returndatasize())
                    revert(returndataPtr, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Authority} from "./Authority.sol";
import {IValidatorManager} from "../interface/IValidatorManager.sol";
import {IValidator} from "../interface/IValidator.sol";
import {UserOperation} from "../interface/IAccount.sol";
import {AccountStorage} from "../utils/AccountStorage.sol";
import {AddressLinkedList} from "../utils/AddressLinkedList.sol";
import {SIG_VALIDATION_FAILED} from "../utils/Constants.sol";
import {ValidatorManagerBase} from "../snippets/ValidatorManager.sol";

abstract contract ValidatorManager is Authority, IValidatorManager, ValidatorManagerBase {
    using AddressLinkedList for mapping(address => address);

    error INVALID_VALIDATOR();

    bytes4 private constant INTERFACE_ID_VALIDATOR = type(IValidator).interfaceId;

    /**
     * @dev checks whether a address is a installed validator
     */
    function _isInstalledValidator(address validator) internal view virtual override returns (bool) {
        return AccountStorage.layout().validators.isExist(validator);
    }

    /**
     * @dev install a validator
     */
    function _installValidator(address validator) internal virtual override {
        try IValidator(validator).supportsInterface(INTERFACE_ID_VALIDATOR) returns (bool supported) {
            if (supported == false) {
                revert INVALID_VALIDATOR();
            } else {
                AccountStorage.layout().validators.add(address(validator));
            }
        } catch {
            revert INVALID_VALIDATOR();
        }
    }

    /**
     * @dev uninstall a validator
     */
    function _uninstallValidator(address validator) internal virtual override {
        AccountStorage.layout().validators.remove(address(validator));
    }

    /**
     * @dev reset validator
     */
    function _resetValidator(address validator) internal virtual override {
        AccountStorage.layout().validators.clear();
        _installValidator(validator);
    }

    /**
     * @dev install a validator
     */
    function installValidator(address validator) external virtual override {
        validatorManagementAccess();
        _installValidator(validator);
    }

    /**
     * @dev uninstall a validator
     */
    function uninstallValidator(address validator) external virtual override {
        validatorManagementAccess();
        _uninstallValidator(validator);
    }

    /**
     * @dev list validators
     */
    function listValidator() external view virtual override returns (address[] memory validators) {
        mapping(address => address) storage validator = AccountStorage.layout().validators;
        validators = validator.list(AddressLinkedList.SENTINEL_ADDRESS, validator.size());
    }

    /**
     * @dev EIP-1271
     * @param hash hash of the data to be signed
     * @param validator validator address
     * @param validatorSignature Signature byte array associated with _data
     * @return magicValue Magic value 0x1626ba7e if the validator is registered and signature is valid
     */
    function _isValidSignature(bytes32 hash, address validator, bytes calldata validatorSignature)
        internal
        view
        virtual
        override
        returns (bytes4 magicValue)
    {
        if (_isInstalledValidator(validator) == false) {
            return bytes4(0);
        }
        bytes memory callData = abi.encodeWithSelector(IValidator.validateSignature.selector, hash, validatorSignature);
        assembly ("memory-safe") {
            // memorySafe: The scratch space between memory offset 0 and 64.

            let result := staticcall(gas(), validator, add(callData, 0x20), mload(callData), 0x00, 0x20)
            if result { magicValue := mload(0x00) }
        }
    }

    /**
     * @dev validate UserOperation
     * @param userOp UserOperation
     * @param userOpHash UserOperation hash
     * @param validator validator address
     * @param validatorSignature validator signature
     * @return validationData refer to https://github.com/eth-infinitism/account-abstraction/blob/v0.6.0/contracts/interfaces/IAccount.sol#L24-L30
     */
    function _validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        address validator,
        bytes calldata validatorSignature
    ) internal virtual override returns (uint256 validationData) {
        if (_isInstalledValidator(validator) == false) {
            return SIG_VALIDATION_FAILED;
        }
        bytes memory callData =
            abi.encodeWithSelector(IValidator.validateUserOp.selector, userOp, userOpHash, validatorSignature);

        assembly ("memory-safe") {
            // memorySafe: The scratch space between memory offset 0 and 64.

            let result := call(gas(), validator, 0, add(callData, 0x20), mload(callData), 0x00, 0x20)
            if iszero(result) { mstore(0x00, SIG_VALIDATION_FAILED) }
            validationData := mload(0x00)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SignatureDecoder {
    /*

        Signature:
            [0:20]: `validator address`
            [20:24]: n = `validator signature length`, bytes4 max to 16777215 bytes
            [24:24+n]: `validator signature`
            [24+n:]: `hook signature` [optional]

        `hook signature`:
            [0:20]: `first hook address`
            [20:24]: n1 = `first hook signature length`, bytes4 max to 16777215 bytes
            [24:24+n1]: `first hook signature`

            `[optional]`
            [24+n1:24+n1+20]: `second hook signature` 
            [24+n1+20:24+n1+24]: n2 = `second hook signature length`, bytes4 max to 16777215 bytes
            [24+n1+24:24+n1+24+n2]: `second hook signature`

            ...
     */
    function signatureSplit(bytes calldata self)
        internal
        pure
        returns (address validator, bytes calldata validatorSignature, bytes calldata hookSignature)
    {
        validator = address(bytes20(self[0:20]));
        uint32 validatorSignatureLength = uint32(bytes4(self[20:24]));
        uint256 hookSignatureStartAt;
        unchecked {
            hookSignatureStartAt = 24 + validatorSignatureLength;
        }
        validatorSignature = self[24:hookSignatureStartAt];
        hookSignature = self[hookSignatureStartAt:];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC1271.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

library Errors {
    error ADDRESS_ALREADY_EXISTS();
    error ADDRESS_NOT_EXISTS();
    error DATA_ALREADY_EXISTS();
    error DATA_NOT_EXISTS();
    error CALLER_MUST_BE_ENTRYPOINT();
    error CALLER_MUST_BE_SELF_OR_MODULE();
    error CALLER_MUST_BE_MODULE();
    error HASH_ALREADY_APPROVED();
    error HASH_ALREADY_REJECTED();
    error INVALID_ADDRESS();
    error INVALID_GUARD_HOOK_DATA();
    error INVALID_SELECTOR();
    error INVALID_SIGNTYPE();
    error MODULE_ADDRESS_EMPTY();
    error MODULE_NOT_SUPPORT_INTERFACE();
    error MODULE_SELECTOR_UNAUTHORIZED();
    error MODULE_SELECTORS_EMPTY();
    error MODULE_EXECUTE_FROM_MODULE_RECURSIVE();
    error NO_OWNER();
    error SELECTOR_ALREADY_EXISTS();
    error SELECTOR_NOT_EXISTS();
    error UNSUPPORTED_SIGNTYPE();
    error INVALID_LOGIC_ADDRESS();
    error SAME_LOGIC_ADDRESS();
    error UPGRADE_FAILED();
    error NOT_IMPLEMENTED();
    error INVALID_SIGNATURE();
    error ALERADY_INITIALIZED();
    error INVALID_KEY();
    error NOT_INITIALIZED();
    error INVALID_TIME_RANGE();
    error UNAUTHORIZED();
    error INVALID_DATA();
    error GUARDIAN_SIGNATURE_INVALID();
    error UNTRUSTED_KEYSTORE_LOGIC();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Errors.sol";
import {Authority} from "@soulwallet-core/contracts/base/Authority.sol";

abstract contract ERC1271Handler is Authority {
    // Magic value indicating a valid signature for ERC-1271 contracts
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
    // Constants indicating different invalid states
    bytes4 internal constant INVALID_ID = 0xffffffff;

    bytes32 private constant SOUL_WALLET_MSG_TYPEHASH = keccak256("SoulWalletMessage(bytes32 message)");

    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    function _encodeRawHash(bytes32 rawHash) internal view returns (bytes32) {
        bytes32 encode1271MessageHash = keccak256(abi.encode(SOUL_WALLET_MSG_TYPEHASH, rawHash));
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(msg.sender)));
        return keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, encode1271MessageHash));
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnerManager} from "@soulwallet-core/contracts/base/OwnerManager.sol";
import {ISoulWalletOwnerManager} from "../interfaces/ISoulWalletOwnerManager.sol";

abstract contract SoulWalletOwnerManager is
    ISoulWalletOwnerManager,
    OwnerManager
{
    function _addOwners(bytes32[] calldata owners) internal {
        for (uint256 i = 0; i < owners.length; ) {
            _addOwner(owners[i]);
            unchecked {
                i++;
            }
        }
    }

    function addOwners(bytes32[] calldata owners) external override {
        _onlySelfOrModule();
        _addOwners(owners);
    }

    function resetOwners(bytes32[] calldata newOwners) external override {
        _onlySelfOrModule();
        _clearOwner();
        _addOwners(newOwners);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ModuleManager} from "@soulwallet-core/contracts/base/ModuleManager.sol";
import {ISoulWalletModuleManager} from "../interfaces/ISoulWalletModuleManager.sol";
import {ISoulWalletModule} from "../modules/interfaces/ISoulWalletModule.sol";
import {Errors} from "../libraries/Errors.sol";

abstract contract SoulWalletModuleManager is
    ISoulWalletModuleManager,
    ModuleManager
{
    function installModule(bytes calldata moduleAndData) external override {
        _onlyModule();
        _addModule(moduleAndData);
    }

    function _addModule(bytes calldata moduleAndData) internal {
         address moduleAddress = address(bytes20(moduleAndData[:20]));
        ISoulWalletModule aModule = ISoulWalletModule(moduleAddress);
        if (!aModule.supportsInterface(type(ISoulWalletModule).interfaceId)) {
            revert Errors.MODULE_NOT_SUPPORT_INTERFACE();
        }
        bytes4[] memory requiredFunctions = aModule.requiredFunctions();
        if (requiredFunctions.length == 0) {
            revert Errors.MODULE_SELECTORS_EMPTY();
        }
        _installModule(
            address(bytes20(moduleAndData[:20])),
            moduleAndData[20:],
            requiredFunctions
        );

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookManager} from "@soulwallet-core/contracts/base/HookManager.sol";
import {ISoulWalletHookManager} from "../interfaces/ISoulWalletHookManager.sol";
import {Errors} from "../libraries/Errors.sol";

abstract contract SoulWalletHookManager is ISoulWalletHookManager, HookManager {
    function _installHook(bytes calldata hookAndDataWithFlag) internal virtual {
        _installHook(
            address(bytes20(hookAndDataWithFlag[:20])),
            hookAndDataWithFlag[20:hookAndDataWithFlag.length - 1],
            uint8(bytes1((hookAndDataWithFlag[hookAndDataWithFlag.length -
                1:hookAndDataWithFlag.length])))
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../interfaces/IUpgradable.sol";
import "../libraries/Errors.sol";
/**
 * @title SoulWalletUpgradeManager
 * @dev This contract allows for the logic of a proxy to be upgraded
 */

abstract contract SoulWalletUpgradeManager is IUpgradable {
    /**
     * @dev Storage slot with the address of the current implementation
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    /**
     * @dev Upgrades the logic to a new implementation
     * @param newImplementation Address of the new implementation
     */

    function _upgradeTo(address newImplementation) internal {
        bool isContract;
        assembly ("memory-safe") {
            isContract := gt(extcodesize(newImplementation), 0)
        }
        if (!isContract) {
            revert Errors.INVALID_LOGIC_ADDRESS();
        }
        address oldImplementation;
        assembly ("memory-safe") {
            oldImplementation := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        if (oldImplementation == newImplementation) {
            revert Errors.SAME_LOGIC_ADDRESS();
        }
        assembly ("memory-safe") {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }

        // delegatecall to new implementation
        (bool success,) =
            newImplementation.delegatecall(abi.encodeWithSelector(IUpgradable.upgradeFrom.selector, oldImplementation));
        if (!success) {
            revert Errors.UPGRADE_FAILED();
        }
        emit Upgraded(oldImplementation, newImplementation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IModule} from "../interface/IModule.sol";
import {IPluggable} from "../interface/IPluggable.sol";
import {IModuleManager} from "../interface/IModuleManager.sol";
import {AccountStorage} from "../utils/AccountStorage.sol";
import {Authority} from "./Authority.sol";
import {AddressLinkedList} from "../utils/AddressLinkedList.sol";
import {SelectorLinkedList} from "../utils/SelectorLinkedList.sol";
import {ModuleManagerBase} from "../snippets/ModuleManager.sol";

abstract contract ModuleManager is IModuleManager, Authority, ModuleManagerBase {
    using AddressLinkedList for mapping(address => address);
    using SelectorLinkedList for mapping(bytes4 => bytes4);

    error MODULE_EXECUTE_FROM_MODULE_RECURSIVE();
    error INVALID_MODULE();

    event MODULE_UNINSTALL_WITHERROR(address indexed moduleAddress);

    bytes4 private constant INTERFACE_ID_MODULE = type(IModule).interfaceId;

    function _moduleMapping() internal view returns (mapping(address => address) storage modules) {
        modules = AccountStorage.layout().modules;
    }

    /**
     * @dev checks whether the caller is a authorized module
     *  caller: msg.sender
     *  method: msg.sig
     * @return bool
     */
    function _isAuthorizedModule() internal view override returns (bool) {
        return AccountStorage.layout().moduleSelectors[msg.sender].isExist(msg.sig);
    }

    /**
     * @dev checks whether a address is a authorized module
     */
    function _isInstalledModule(address module) internal view virtual override returns (bool) {
        return _moduleMapping().isExist(module);
    }

    /**
     * @dev checks whether a address is a installed module
     */
    function isInstalledModule(address module) external view override returns (bool) {
        return _isInstalledModule(module);
    }

    /**
     * @dev install a module
     * @param moduleAddress module address
     * @param initData module init data
     * @param selectors function selectors that the module is allowed to call
     */
    function _installModule(address moduleAddress, bytes memory initData, bytes4[] memory selectors)
        internal
        virtual
        override
    {
        try IModule(moduleAddress).supportsInterface(INTERFACE_ID_MODULE) returns (bool supported) {
            if (supported == false) {
                revert INVALID_MODULE();
            }
        } catch {
            revert INVALID_MODULE();
        }

        mapping(address => address) storage modules = _moduleMapping();
        modules.add(moduleAddress);
        mapping(bytes4 => bytes4) storage moduleSelectors = AccountStorage.layout().moduleSelectors[moduleAddress];
        for (uint256 i = 0; i < selectors.length; i++) {
            moduleSelectors.add(selectors[i]);
        }
        bytes memory callData = abi.encodeWithSelector(IPluggable.Init.selector, initData);
        bytes4 invalidModuleSelector = INVALID_MODULE.selector;
        assembly ("memory-safe") {
            // memorySafe: The scratch space between memory offset 0 and 64.

            let result := call(gas(), moduleAddress, 0, add(callData, 0x20), mload(callData), 0x00, 0x00)
            if iszero(result) {
                mstore(0x00, invalidModuleSelector)
                revert(0x00, 4)
            }
        }
    }

    /**
     * @dev install a module
     * @param moduleAndData [0:20]: module address, [20:]: module init data
     * @param selectors function selectors that the module is allowed to call
     */
    function installModule(bytes calldata moduleAndData, bytes4[] calldata selectors) external virtual override {
        pluginManagementAccess();
        _installModule(address(bytes20(moduleAndData[:20])), moduleAndData[20:], selectors);
    }

    /**
     * @dev uninstall a module
     * @param moduleAddress module address
     */
    function _uninstallModule(address moduleAddress) internal virtual override {
        mapping(address => address) storage modules = _moduleMapping();
        modules.remove(moduleAddress);
        AccountStorage.layout().moduleSelectors[moduleAddress].clear();

        (bool success,) =
            moduleAddress.call{gas: 100000 /* max to 100k gas */ }(abi.encodeWithSelector(IPluggable.DeInit.selector));
        if (!success) {
            emit MODULE_UNINSTALL_WITHERROR(moduleAddress);
        }
    }

    /**
     * @dev uninstall a module
     * @param moduleAddress module address
     */
    function uninstallModule(address moduleAddress) external virtual override {
        pluginManagementAccess();
        _uninstallModule(moduleAddress);
    }

    /**
     * @dev Provides a list of all added modules and their respective authorized function selectors
     * @return modules An array of the addresses of all added modules
     * @return selectors A 2D array where each inner array represents the function selectors
     * that the corresponding module in the 'modules' array is allowed to call
     */
    function listModule()
        external
        view
        virtual
        override
        returns (address[] memory modules, bytes4[][] memory selectors)
    {
        mapping(address => address) storage _modules = _moduleMapping();
        uint256 moduleSize = _moduleMapping().size();
        modules = new address[](moduleSize);
        mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors = AccountStorage.layout().moduleSelectors;
        selectors = new bytes4[][](moduleSize);

        uint256 i = 0;
        address addr = _modules[AddressLinkedList.SENTINEL_ADDRESS];
        while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
            {
                modules[i] = addr;
                mapping(bytes4 => bytes4) storage moduleSelector = moduleSelectors[addr];

                {
                    uint256 selectorSize = moduleSelector.size();
                    bytes4[] memory _selectors = new bytes4[](selectorSize);
                    uint256 j = 0;
                    bytes4 selector = moduleSelector[SelectorLinkedList.SENTINEL_SELECTOR];
                    while (uint32(selector) > SelectorLinkedList.SENTINEL_UINT) {
                        _selectors[j] = selector;

                        selector = moduleSelector[selector];
                        unchecked {
                            j++;
                        }
                    }
                    selectors[i] = _selectors;
                }
            }

            addr = _modules[addr];
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Allows a module to execute a function within the system. This ensures that the
     * module can only call functions it is permitted to.
     * @param dest The address of the destination contract where the function will be executed
     * @param value The amount of ether (in wei) to be sent with the function call
     * @param func The function data to be executed
     */
    function executeFromModule(address dest, uint256 value, bytes memory func) external virtual override {
        require(_isAuthorizedModule());

        if (dest == address(this)) revert MODULE_EXECUTE_FROM_MODULE_RECURSIVE();
        assembly ("memory-safe") {
            // memorySafe: Memory allocated by yourself using a mechanism like the allocate function described above.

            function allocate(length) -> pos {
                pos := mload(0x40)
                mstore(0x40, add(pos, length))
            }

            let result := call(gas(), dest, value, add(func, 0x20), mload(func), 0, 0)

            let returndataPtr := allocate(returndatasize())
            returndatacopy(returndataPtr, 0, returndatasize())

            if iszero(result) { revert(returndataPtr, returndatasize()) }
            return(returndataPtr, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Authority} from "./Authority.sol";
import {IOwnerManager} from "../interface/IOwnerManager.sol";
import {AccountStorage} from "../utils/AccountStorage.sol";
import {Bytes32LinkedList} from "../utils/Bytes32LinkedList.sol";
import {OwnerManagerBase} from "../snippets/OwnerManager.sol";

abstract contract OwnerManager is IOwnerManager, Authority, OwnerManagerBase {
    using Bytes32LinkedList for mapping(bytes32 => bytes32);

    /**
     * @notice Helper function to get the owner mapping from account storage
     * @return owners Mapping of current owners
     */
    function _ownerMapping() internal view override returns (mapping(bytes32 => bytes32) storage owners) {
        owners = AccountStorage.layout().owners;
    }

    /**
     * @notice Checks if the provided owner is a current owner
     * @param owner Address in bytes32 format to check
     * @return true if provided owner is a current owner, false otherwise
     */
    function _isOwner(bytes32 owner) internal view virtual override returns (bool) {
        return _ownerMapping().isExist(owner);
    }

    /**
     * @notice External function to check if the provided owner is a current owner
     * @param owner Address in bytes32 format to check
     * @return true if provided owner is a current owner, false otherwise
     */
    function isOwner(bytes32 owner) external view virtual override returns (bool) {
        return _isOwner(owner);
    }

    /**
     * @notice Internal function to add an owner
     * @param owner Address in bytes32 format to add
     */
    function _addOwner(bytes32 owner) internal virtual override {
        _ownerMapping().add(owner);
    }

    /**
     * @notice add an owner
     * @param owner Address in bytes32 format to add
     */
    function addOwner(bytes32 owner) external virtual override {
        ownerManagementAccess();
        _addOwner(owner);
    }

    /**
     * @notice Internal function to remove an owner
     * @param owner Address in bytes32 format to remove
     */
    function _removeOwner(bytes32 owner) internal virtual override {
        _ownerMapping().remove(owner);
    }

    /**
     * @notice remove an owner
     * @param owner Address in bytes32 format to remove
     */
    function removeOwner(bytes32 owner) external virtual override {
        ownerManagementAccess();
        _removeOwner(owner);
    }

    function _resetOwner(bytes32 newOwner) internal virtual override {
        _ownerMapping().clear();
        _ownerMapping().add(newOwner);
    }

    function _clearOwner() internal virtual override {
        _ownerMapping().clear();
    }

    function resetOwner(bytes32 newOwner) external virtual override {
        ownerManagementAccess();
        _resetOwner(newOwner);
    }

    function listOwner() external view virtual override returns (bytes32[] memory owners) {
        mapping(bytes32 => bytes32) storage _owners = _ownerMapping();
        owners = _owners.list(Bytes32LinkedList.SENTINEL_BYTES32, _owners.size());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Authority} from "./Authority.sol";
import {IHookManager} from "../interface/IHookManager.sol";
import {IHook} from "../interface/IHook.sol";
import {IPluggable} from "../interface/IPluggable.sol";
import {IAccount, UserOperation} from "../interface/IAccount.sol";
import {AccountStorage} from "../utils/AccountStorage.sol";
import {AddressLinkedList} from "../utils/AddressLinkedList.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SIG_VALIDATION_FAILED} from "../utils/Constants.sol";
import {HookManagerBase} from "../snippets/HookManager.sol";

abstract contract HookManager is Authority, IHookManager, HookManagerBase {
    using AddressLinkedList for mapping(address => address);

    error INVALID_HOOK();
    error INVALID_HOOK_TYPE();
    error HOOK_NOT_EXISTS();
    error INVALID_HOOK_SIGNATURE();

    event HOOK_UNINSTALL_WITHERROR(address indexed hookAddress);

    bytes4 private constant INTERFACE_ID_HOOK = type(IHook).interfaceId;

    /*
        Capability flags for the hook:
            0x01: preIsValidSignatureHook: execute before isValidSignature
            0x02: preUserOpValidationHook: execute before validateUserOp
     */

    uint8 internal constant PRE_IS_VALID_SIGNATURE_HOOK = 1 << 0;
    uint8 internal constant PRE_USER_OP_VALIDATION_HOOK = 1 << 1;

    /**
     * @dev Check if the hook is installed
     * @param hook The address of the hook
     */
    function isInstalledHook(address hook) external view override returns (bool) {
        return AccountStorage.layout().preUserOpValidationHook.isExist(hook)
            || AccountStorage.layout().preIsValidSignatureHook.isExist(hook);
    }

    /**
     * @dev Install a hook
     * @param hookAddress The address of the hook
     * @param initData The init data of the hook
     * @param capabilityFlags Capability flags for the hook
     */
    function _installHook(address hookAddress, bytes memory initData, uint8 capabilityFlags)
        internal
        virtual
        override
    {
        bytes memory callData = abi.encodeWithSelector(IERC165.supportsInterface.selector, INTERFACE_ID_HOOK);
        bytes4 invalidHookSelector = INVALID_HOOK.selector;
        assembly ("memory-safe") {
            // memorySafe: The scratch space between memory offset 0 and 64.

            // IHook(hookAddress).supportsInterface(INTERFACE_ID_HOOK)
            let result := staticcall(gas(), hookAddress, add(callData, 0x20), mload(callData), 0x00, 0x20)
            if iszero(result) {
                mstore(0x00, invalidHookSelector)
                revert(0x00, 4)
            }
            // return true
            let supported := mload(0x00)
            if iszero(supported) {
                mstore(0x00, invalidHookSelector)
                revert(0x00, 4)
            }
        }

        if (capabilityFlags & (PRE_USER_OP_VALIDATION_HOOK | PRE_IS_VALID_SIGNATURE_HOOK) == 0) {
            revert INVALID_HOOK_TYPE();
        }
        if (capabilityFlags & PRE_IS_VALID_SIGNATURE_HOOK == PRE_IS_VALID_SIGNATURE_HOOK) {
            AccountStorage.layout().preIsValidSignatureHook.add(hookAddress);
        }
        if (capabilityFlags & PRE_USER_OP_VALIDATION_HOOK == PRE_USER_OP_VALIDATION_HOOK) {
            AccountStorage.layout().preUserOpValidationHook.add(hookAddress);
        }

        callData = abi.encodeWithSelector(IPluggable.Init.selector, initData);
        assembly ("memory-safe") {
            // memorySafe: The scratch space between memory offset 0 and 64.

            let result := call(gas(), hookAddress, 0, add(callData, 0x20), mload(callData), 0x00, 0x00)
            if iszero(result) {
                mstore(0x00, invalidHookSelector)
                revert(0x00, 4)
            }
        }
    }

    /**
     * @dev Uninstall a hook
     *      1. revert if the hook is not installed
     *      2. call hook.deInit() with 100k gas, emit HOOK_UNINSTALL_WITHERROR if the call failed
     * @param hookAddress The address of the hook
     */
    function _uninstallHook(address hookAddress) internal virtual override {
        bool removed1 = AccountStorage.layout().preIsValidSignatureHook.tryRemove(hookAddress);
        bool removed2 = AccountStorage.layout().preUserOpValidationHook.tryRemove(hookAddress);
        if (removed1 == false && removed2 == false) {
            revert HOOK_NOT_EXISTS();
        }

        (bool success,) =
            hookAddress.call{gas: 100000 /* max to 100k gas */ }(abi.encodeWithSelector(IPluggable.DeInit.selector));
        if (!success) {
            emit HOOK_UNINSTALL_WITHERROR(hookAddress);
        }
    }

    /**
     * @dev Install a hook
     * @param hookAndData [0:20]: hook address, [20:]: hook data
     * @param capabilityFlags Capability flags for the hook
     */
    function installHook(bytes calldata hookAndData, uint8 capabilityFlags) external virtual override {
        pluginManagementAccess();
        _installHook(address(bytes20(hookAndData[:20])), hookAndData[20:], capabilityFlags);
    }

    /**
     * @dev Uninstall a hook
     * @param hookAddress The address of the hook
     */
    function uninstallHook(address hookAddress) external virtual override {
        pluginManagementAccess();
        _uninstallHook(hookAddress);
    }

    /**
     * @dev List all installed hooks
     */
    function listHook()
        external
        view
        virtual
        override
        returns (address[] memory preIsValidSignatureHooks, address[] memory preUserOpValidationHooks)
    {
        mapping(address => address) storage preIsValidSignatureHook = AccountStorage.layout().preIsValidSignatureHook;
        preIsValidSignatureHooks =
            preIsValidSignatureHook.list(AddressLinkedList.SENTINEL_ADDRESS, preIsValidSignatureHook.size());
        mapping(address => address) storage preUserOpValidationHook = AccountStorage.layout().preUserOpValidationHook;
        preUserOpValidationHooks =
            preUserOpValidationHook.list(AddressLinkedList.SENTINEL_ADDRESS, preUserOpValidationHook.size());
    }

    /**
     * @dev Get the next hook signature
     * @param hookSignatures The hook signatures
     * @param cursor The cursor of the hook signatures
     */
    function _nextHookSignature(bytes calldata hookSignatures, uint256 cursor)
        private
        pure
        returns (address _hookAddr, uint256 _cursorFrom, uint256 _cursorEnd)
    {
        /* 
            +--------------------------------------------------------------------------------+  
            |                            multi-hookSignature                                 |  
            +--------------------------------------------------------------------------------+  
            |     hookSignature     |    hookSignature      |   ...  |    hookSignature      |
            +-----------------------+--------------------------------------------------------+  
            |     dynamic data      |     dynamic data      |   ...  |     dynamic data      |
            +--------------------------------------------------------------------------------+

            +----------------------------------------------------------------------+  
            |                                 hookSignature                        |  
            +----------------------------------------------------------------------+  
            |      Hook address    | hookSignature length  |     hookSignature     |
            +----------------------+-----------------------------------------------+  
            |        20bytes       |     4bytes(uint32)    |         bytes         |
            +----------------------------------------------------------------------+
         */
        uint256 dataLen = hookSignatures.length;

        if (dataLen > cursor) {
            assembly ("memory-safe") {
                let ptr := add(hookSignatures.offset, cursor)
                _hookAddr := shr(0x60, calldataload(ptr))
                if iszero(_hookAddr) { revert(0, 0) }
                _cursorFrom := add(cursor, 24) //20+4
                let guardSigLen := shr(0xe0, calldataload(add(ptr, 20)))
                _cursorEnd := add(_cursorFrom, guardSigLen)
            }
        }
    }

    /**
     * @dev Call preIsValidSignatureHook for all installed hooks
     * @param hash The hash of the data to be signed
     * @param hookSignatures The hook signatures
     */
    function _preIsValidSignatureHook(bytes32 hash, bytes calldata hookSignatures) internal view virtual {
        address _hookAddr;
        uint256 _cursorFrom;
        uint256 _cursorEnd;
        (_hookAddr, _cursorFrom, _cursorEnd) = _nextHookSignature(hookSignatures, _cursorEnd);

        mapping(address => address) storage preIsValidSignatureHook = AccountStorage.layout().preIsValidSignatureHook;
        address addr = preIsValidSignatureHook[AddressLinkedList.SENTINEL_ADDRESS];
        while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
            bytes calldata currentHookSignature;
            address hookAddress = addr;
            if (hookAddress == _hookAddr) {
                currentHookSignature = hookSignatures[_cursorFrom:_cursorEnd];
                // next
                _hookAddr = address(0);
                if (_cursorEnd > 0) {
                    (_hookAddr, _cursorFrom, _cursorEnd) = _nextHookSignature(hookSignatures, _cursorEnd);
                }
            } else {
                currentHookSignature = hookSignatures[0:0];
            }

            bytes memory callData =
                abi.encodeWithSelector(IHook.preIsValidSignatureHook.selector, hash, currentHookSignature);
            assembly ("memory-safe") {
                // memorySafe: The scratch space between memory offset 0 and 64.

                let result := staticcall(gas(), addr, add(callData, 0x20), mload(callData), 0x00, 0x00)
                if iszero(result) {
                    /*
                        Warning!!!
                            This function uses `return` to terminate the execution of the entire contract.
                            If any `Hook` fails, this function will stop the contract's execution and
                            return `bytes4(0)`, skipping all the subsequent unexecuted code.
                     */
                    mstore(0x00, 0x00000000)
                    return(0x00, 0x20)
                }
            }

            addr = preIsValidSignatureHook[addr];
        }

        if (_hookAddr != address(0)) {
            revert INVALID_HOOK_SIGNATURE();
        }
    }

    /**
     * @dev Call preUserOpValidationHook for all installed hooks
     *
     * Warning!!!
     *  This function uses `return` to terminate the execution of the entire contract.
     *  If any `Hook` fails, this function will stop the contract's execution and
     *  return `SIG_VALIDATION_FAILED`, skipping all the subsequent unexecuted code.
     *
     *
     *
     * @param userOp The UserOperation
     * @param userOpHash The hash of the UserOperation
     * @param missingAccountFunds The missing account funds
     * @param hookSignatures The hook signatures
     */
    function _preUserOpValidationHook(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds,
        bytes calldata hookSignatures
    ) internal virtual {
        address _hookAddr;
        uint256 _cursorFrom;
        uint256 _cursorEnd;
        (_hookAddr, _cursorFrom, _cursorEnd) = _nextHookSignature(hookSignatures, _cursorEnd);

        mapping(address => address) storage preUserOpValidationHook = AccountStorage.layout().preUserOpValidationHook;
        address addr = preUserOpValidationHook[AddressLinkedList.SENTINEL_ADDRESS];
        while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
            bytes calldata currentHookSignature;
            address hookAddress = addr;
            if (hookAddress == _hookAddr) {
                currentHookSignature = hookSignatures[_cursorFrom:_cursorEnd];
                // next
                _hookAddr = address(0);
                if (_cursorEnd > 0) {
                    (_hookAddr, _cursorFrom, _cursorEnd) = _nextHookSignature(hookSignatures, _cursorEnd);
                }
            } else {
                currentHookSignature = hookSignatures[0:0];
            }

            bytes memory callData = abi.encodeWithSelector(
                IHook.preUserOpValidationHook.selector, userOp, userOpHash, missingAccountFunds, currentHookSignature
            );
            assembly ("memory-safe") {
                // memorySafe: The scratch space between memory offset 0 and 64.

                let result := call(gas(), addr, 0, add(callData, 0x20), mload(callData), 0x00, 0x00)
                if iszero(result) {
                    /*
                        Warning!!!
                            This function uses `return` to terminate the execution of the entire contract.
                            If any `Hook` fails, this function will stop the contract's execution and
                            return `SIG_VALIDATION_FAILED`, skipping all the subsequent unexecuted code.
                     */
                    mstore(0x00, SIG_VALIDATION_FAILED)
                    return(0x00, 0x20)
                }
            }

            addr = preUserOpValidationHook[addr];
        }

        if (_hookAddr != address(0)) {
            revert INVALID_HOOK_SIGNATURE();
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AuthorityBase} from "../snippets/Authority.sol";

abstract contract Authority is AuthorityBase {
    /**
     * a custom error for caller must be self or module
     */
    error CALLER_MUST_BE_SELF_OR_MODULE();

    /**
     * a custom error for caller must be module
     */
    error CALLER_MUST_BE_MODULE();

    /**
     * @notice Ensures the calling contract is an authorized module
     */
    function _onlyModule() internal view override {
        if (!_isAuthorizedModule()) {
            revert CALLER_MUST_BE_MODULE();
        }
    }

    /**
     * @notice Ensures the calling contract is either the Authority contract itself or an authorized module
     * @dev Uses the inherited `_isAuthorizedModule()` from ModuleAuth for module-based authentication
     */
    function _onlySelfOrModule() internal view override {
        if (msg.sender != address(this) && !_isAuthorizedModule()) {
            revert CALLER_MUST_BE_SELF_OR_MODULE();
        }
    }

    /**
     * @dev Check if access to the following functions:
     *      1. setFallbackHandler
     */
    function fallbackManagementAccess() internal view virtual override {
        _onlySelfOrModule();
    }

    /**
     * @dev Check if access to the following functions:
     *      1. installHook
     *      2. uninstallHook
     *      3. installModule
     *      4. uninstallModule
     */
    function pluginManagementAccess() internal view virtual override {
        _onlySelfOrModule();
    }

    /**
     * @dev Check if access to the following functions:
     *      1. addOwner
     *      2. removeOwner
     *      3. resetOwner
     */
    function ownerManagementAccess() internal view virtual override {
        _onlySelfOrModule();
    }

    /**
     * @dev Check if access to the following functions:
     *      1. execute
     *      2. executeBatch
     */
    function executorAccess() internal view virtual override {
        _onlyEntryPoint();
    }

    /**
     * @dev Check if access to the following functions:
     *      1. installValidator
     *      2. uninstallValidator
     */
    function validatorManagementAccess() internal view virtual override {
        _onlySelfOrModule();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AccountStorage
 * @notice A library that defines the storage layout for the SoulWallet account or contract.
 */
library AccountStorage {
    bytes32 internal constant _ACCOUNT_SLOT = keccak256("soulwallet.contracts.AccountStorage");

    struct Layout {
        // base data
        mapping(bytes32 => bytes32) owners;
        address defaultFallbackContract;
        // validators
        mapping(address => address) validators;
        // hooks
        mapping(address => address) preIsValidSignatureHook;
        mapping(address => address) preUserOpValidationHook;
        // modules
        mapping(address => address) modules;
        mapping(address => mapping(bytes4 => bytes4)) moduleSelectors;
    }

    /**
     * @notice Returns the layout of the storage for the account or contract.
     * @return l The layout of the storage.
     */
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = _ACCOUNT_SLOT;
        assembly ("memory-safe") {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract FallbackManagerBase {
    /**
     * @dev Sets the address of the fallback handler contract
     * @param fallbackContract The address of the new fallback handler contract
     */
    function _setFallbackHandler(address fallbackContract) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Execution {
    // The target contract for account to execute.
    address target;
    // The value for the execution.
    uint256 value;
    // The call data for the execution.
    bytes data;
}

interface IStandardExecutor {
    /// @dev Standard execute method.
    /// @param target The target contract for account to execute.
    /// @param value The value for the execution.
    /// @param data The call data for the execution.
    function execute(address target, uint256 value, bytes calldata data) external payable;

    /// @dev Standard executeBatch method.
    /// @param executions The array of executions.
    function executeBatch(Execution[] calldata executions) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IValidator} from "./IValidator.sol";

interface IValidatorManager {
    function installValidator(address validator) external;

    function uninstallValidator(address validator) external;

    function listValidator() external view returns (address[] memory validators);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UserOperation} from "../interface/IAccount.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IValidator is IERC165 {
    /**
     * @dev EIP-1271 Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param validatorSignature Signature byte array associated with _data
     */
    function validateSignature(bytes32 hash, bytes memory validatorSignature)
        external
        view
        returns (bytes4 magicValue);

    /**
     * @dev EIP-4337
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param validatorSignature Signature
     * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, bytes calldata validatorSignature)
        external
        returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Address Linked List
 * @notice This library provides utility functions to manage a linked list of addresses
 */
library AddressLinkedList {
    error INVALID_ADDRESS();
    error ADDRESS_ALREADY_EXISTS();
    error ADDRESS_NOT_EXISTS();

    address internal constant SENTINEL_ADDRESS = address(1);
    uint160 internal constant SENTINEL_UINT = 1;

    /**
     * @dev Modifier that checks if an address is valid.
     */
    modifier onlyAddress(address addr) {
        if (uint160(addr) <= SENTINEL_UINT) {
            revert INVALID_ADDRESS();
        }
        _;
    }
    /**
     * @notice Adds an address to the linked list.
     * @param self The linked list mapping.
     * @param addr The address to be added.
     */

    function add(mapping(address => address) storage self, address addr) internal onlyAddress(addr) {
        if (self[addr] != address(0)) {
            revert ADDRESS_ALREADY_EXISTS();
        }
        address _prev = self[SENTINEL_ADDRESS];
        if (_prev == address(0)) {
            self[SENTINEL_ADDRESS] = addr;
            self[addr] = SENTINEL_ADDRESS;
        } else {
            self[SENTINEL_ADDRESS] = addr;
            self[addr] = _prev;
        }
    }

    /**
     * @notice Removes an address from the linked list.
     * @param self The linked list mapping.
     * @param addr The address to be removed.
     */

    function remove(mapping(address => address) storage self, address addr) internal {
        if (!tryRemove(self, addr)) {
            revert ADDRESS_NOT_EXISTS();
        }
    }
    /**
     * @notice Tries to remove an address from the linked list.
     * @param self The linked list mapping.
     * @param addr The address to be removed.
     * @return Returns true if removal is successful, false otherwise.
     */

    function tryRemove(mapping(address => address) storage self, address addr) internal returns (bool) {
        if (isExist(self, addr)) {
            address cursor = SENTINEL_ADDRESS;
            while (true) {
                address _addr = self[cursor];
                if (_addr == addr) {
                    address next = self[_addr];
                    self[cursor] = next;
                    self[_addr] = address(0);
                    return true;
                }
                cursor = _addr;
            }
        }
        return false;
    }
    /**
     * @notice Clears all addresses from the linked list.
     * @param self The linked list mapping.
     */

    function clear(mapping(address => address) storage self) internal {
        for (address addr = self[SENTINEL_ADDRESS]; uint160(addr) > SENTINEL_UINT; addr = self[addr]) {
            self[addr] = address(0);
        }
        self[SENTINEL_ADDRESS] = address(0);
    }
    /**
     * @notice Checks if an address exists in the linked list.
     * @param self The linked list mapping.
     * @param addr The address to check.
     * @return Returns true if the address exists, false otherwise.
     */

    function isExist(mapping(address => address) storage self, address addr)
        internal
        view
        onlyAddress(addr)
        returns (bool)
    {
        return self[addr] != address(0);
    }
    /**
     * @notice Returns the size of the linked list.
     * @param self The linked list mapping.
     * @return Returns the size of the linked list.
     */

    function size(mapping(address => address) storage self) internal view returns (uint256) {
        uint256 result = 0;
        address addr = self[SENTINEL_ADDRESS];
        while (uint160(addr) > SENTINEL_UINT) {
            addr = self[addr];
            unchecked {
                result++;
            }
        }
        return result;
    }
    /**
     * @notice Checks if the linked list is empty.
     * @param self The linked list mapping.
     * @return Returns true if the linked list is empty, false otherwise.
     */

    function isEmpty(mapping(address => address) storage self) internal view returns (bool) {
        return self[SENTINEL_ADDRESS] == address(0);
    }

    /**
     * @notice Returns a list of addresses from the linked list.
     * @param self The linked list mapping.
     * @param from The starting address.
     * @param limit The number of addresses to return.
     * @return Returns an array of addresses.
     */
    function list(mapping(address => address) storage self, address from, uint256 limit)
        internal
        view
        returns (address[] memory)
    {
        address[] memory result = new address[](limit);
        uint256 i = 0;
        address addr = self[from];
        while (uint160(addr) > SENTINEL_UINT && i < limit) {
            result[i] = addr;
            addr = self[addr];
            unchecked {
                i++;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//return value in case of signature failure, with no time-range.
// equivalent to _packValidationData(true,0,0);
uint256 constant SIG_VALIDATION_FAILED = 1;

uint256 constant SIG_VALIDATION_SUCCESS = 0;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UserOperation} from "../interface/IAccount.sol";

abstract contract ValidatorManagerBase {
    /**
     * @dev checks whether a address is a installed validator
     */
    function _isInstalledValidator(address validator) internal view virtual returns (bool);

    /**
     * @dev install a validator
     */
    function _installValidator(address validator) internal virtual;

    /**
     * @dev uninstall a validator
     */
    function _uninstallValidator(address validator) internal virtual;

    /**
     * @dev reset validator
     */
    function _resetValidator(address validator) internal virtual;

    /**
     * @dev EIP-1271
     * @param hash hash of the data to be signed
     * @param validator validator address
     * @param validatorSignature Signature byte array associated with _data
     * @return magicValue Magic value 0x1626ba7e if the validator is registered and signature is valid
     */
    function _isValidSignature(bytes32 hash, address validator, bytes calldata validatorSignature)
        internal
        view
        virtual
        returns (bytes4 magicValue);

    /**
     * @dev validate UserOperation
     * @param userOp UserOperation
     * @param userOpHash UserOperation hash
     * @param validator validator address
     * @param validatorSignature validator signature
     * @return validationData refer to https://github.com/eth-infinitism/account-abstraction/blob/v0.6.0/contracts/interfaces/IAccount.sol#L24-L30
     */
    function _validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        address validator,
        bytes calldata validatorSignature
    ) internal virtual returns (uint256 validationData);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IOwnerManager} from "@soulwallet-core/contracts/interface/IOwnerManager.sol";
interface ISoulWalletOwnerManager is IOwnerManager {
    function addOwners(bytes32[] calldata owners) external;
    function resetOwners(bytes32[] calldata newOwners) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IModuleManager} from "@soulwallet-core/contracts/interface/IModuleManager.sol";
interface ISoulWalletModuleManager is IModuleManager {
     function installModule(bytes calldata moduleAndData) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
import {IModule} from "@soulwallet-core/contracts/interface/IModule.sol";

interface ISoulWalletModule is IModule {
    function requiredFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IHookManager} from "@soulwallet-core/contracts/interface/IHookManager.sol";
interface ISoulWalletHookManager is IHookManager {
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
pragma solidity ^0.8.20;

import {IPluggable} from "./IPluggable.sol";

interface IModule is IPluggable {}

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
    function Init(bytes calldata data) external;

    /**
     * @notice Deinitializes a specific module or plugin from the wallet
     */
    function DeInit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IModuleManager {
    function installModule(bytes calldata moduleAndData, bytes4[] calldata selectors) external;
    function uninstallModule(address moduleAddress) external;

    function isInstalledModule(address module) external view returns (bool);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SelectorLinkedList {
    error INVALID_SELECTOR();
    error SELECTOR_ALREADY_EXISTS();
    error SELECTOR_NOT_EXISTS();

    bytes4 internal constant SENTINEL_SELECTOR = 0x00000001;
    uint32 internal constant SENTINEL_UINT = 1;

    modifier onlySelector(bytes4 selector) {
        if (uint32(selector) <= SENTINEL_UINT) {
            revert INVALID_SELECTOR();
        }
        _;
    }

    function add(mapping(bytes4 => bytes4) storage self, bytes4 selector) internal onlySelector(selector) {
        if (self[selector] != 0) {
            revert SELECTOR_ALREADY_EXISTS();
        }
        bytes4 _prev = self[SENTINEL_SELECTOR];
        if (_prev == 0) {
            self[SENTINEL_SELECTOR] = selector;
            self[selector] = SENTINEL_SELECTOR;
        } else {
            self[SENTINEL_SELECTOR] = selector;
            self[selector] = _prev;
        }
    }

    function add(mapping(bytes4 => bytes4) storage self, bytes4[] memory selectors) internal {
        for (uint256 i = 0; i < selectors.length;) {
            add(self, selectors[i]);
            unchecked {
                i++;
            }
        }
    }

    function remove(mapping(bytes4 => bytes4) storage self, bytes4 selector) internal {
        if (!isExist(self, selector)) {
            revert SELECTOR_NOT_EXISTS();
        }

        bytes4 cursor = SENTINEL_SELECTOR;
        while (true) {
            bytes4 _selector = self[cursor];
            if (_selector == selector) {
                bytes4 next = self[_selector];
                if (next == SENTINEL_SELECTOR && cursor == SENTINEL_SELECTOR) {
                    self[SENTINEL_SELECTOR] = 0;
                } else {
                    self[cursor] = next;
                }
                self[_selector] = 0;
                return;
            }
            cursor = _selector;
        }
    }

    function clear(mapping(bytes4 => bytes4) storage self) internal {
        for (bytes4 selector = self[SENTINEL_SELECTOR]; uint32(selector) > SENTINEL_UINT; selector = self[selector]) {
            self[selector] = 0;
        }
        self[SENTINEL_SELECTOR] = 0;
    }

    function isExist(mapping(bytes4 => bytes4) storage self, bytes4 selector)
        internal
        view
        onlySelector(selector)
        returns (bool)
    {
        return self[selector] != 0;
    }

    function size(mapping(bytes4 => bytes4) storage self) internal view returns (uint256) {
        uint256 result = 0;
        bytes4 selector = self[SENTINEL_SELECTOR];
        while (uint32(selector) > SENTINEL_UINT) {
            selector = self[selector];
            unchecked {
                result++;
            }
        }
        return result;
    }

    function isEmpty(mapping(bytes4 => bytes4) storage self) internal view returns (bool) {
        return self[SENTINEL_SELECTOR] == 0;
    }

    function list(mapping(bytes4 => bytes4) storage self, bytes4 from, uint256 limit)
        internal
        view
        returns (bytes4[] memory)
    {
        bytes4[] memory result = new bytes4[](limit);
        uint256 i = 0;
        bytes4 selector = self[from];
        while (uint32(selector) > SENTINEL_UINT && i < limit) {
            result[i] = selector;
            selector = self[selector];
            unchecked {
                i++;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ModuleManagerBase {
    /**
     * @dev checks whether a address is a authorized module
     */
    function _isInstalledModule(address module) internal view virtual returns (bool);

    /**
     * @dev install a module
     * @param moduleAddress module address
     * @param initData module init data
     * @param selectors function selectors that the module is allowed to call
     */
    function _installModule(address moduleAddress, bytes memory initData, bytes4[] memory selectors) internal virtual;

    /**
     * @dev uninstall a module
     * @param moduleAddress module address
     */
    function _uninstallModule(address moduleAddress) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IOwnable} from "./IOwnable.sol";

interface IOwnerManager is IOwnable {
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
     * @notice Provides a list of all added owners
     * @return owners An array of bytes32 IDs representing the owners
     */
    function listOwner() external view returns (bytes32[] memory owners);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Bytes32LinkedList {
    error INVALID_DATA();
    error DATA_ALREADY_EXISTS();
    error DATA_NOT_EXISTS();

    bytes32 internal constant SENTINEL_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000001;

    modifier onlyBytes32(bytes32 data) {
        if (data <= SENTINEL_BYTES32) {
            revert INVALID_DATA();
        }
        _;
    }

    function add(mapping(bytes32 => bytes32) storage self, bytes32 data) internal onlyBytes32(data) {
        if (self[data] != bytes32(0)) {
            revert DATA_ALREADY_EXISTS();
        }
        bytes32 _prev = self[SENTINEL_BYTES32];
        if (_prev == bytes32(0)) {
            self[SENTINEL_BYTES32] = data;
            self[data] = SENTINEL_BYTES32;
        } else {
            self[SENTINEL_BYTES32] = data;
            self[data] = _prev;
        }
    }

    function remove(mapping(bytes32 => bytes32) storage self, bytes32 data) internal {
        if (!tryRemove(self, data)) {
            revert DATA_NOT_EXISTS();
        }
    }

    function tryRemove(mapping(bytes32 => bytes32) storage self, bytes32 data) internal returns (bool) {
        if (isExist(self, data)) {
            bytes32 cursor = SENTINEL_BYTES32;
            while (true) {
                bytes32 _data = self[cursor];
                if (_data == data) {
                    bytes32 next = self[_data];
                    self[cursor] = next;
                    self[_data] = bytes32(0);
                    return true;
                }
                cursor = _data;
            }
        }
        return false;
    }

    function clear(mapping(bytes32 => bytes32) storage self) internal {
        for (bytes32 data = self[SENTINEL_BYTES32]; data > SENTINEL_BYTES32; data = self[data]) {
            self[data] = bytes32(0);
        }
        self[SENTINEL_BYTES32] = bytes32(0);
    }

    function isExist(mapping(bytes32 => bytes32) storage self, bytes32 data)
        internal
        view
        onlyBytes32(data)
        returns (bool)
    {
        return self[data] != bytes32(0);
    }

    function size(mapping(bytes32 => bytes32) storage self) internal view returns (uint256) {
        uint256 result = 0;
        bytes32 data = self[SENTINEL_BYTES32];
        while (data > SENTINEL_BYTES32) {
            data = self[data];
            unchecked {
                result++;
            }
        }
        return result;
    }

    function isEmpty(mapping(bytes32 => bytes32) storage self) internal view returns (bool) {
        return self[SENTINEL_BYTES32] == bytes32(0);
    }

    function list(mapping(bytes32 => bytes32) storage self, bytes32 from, uint256 limit)
        internal
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory result = new bytes32[](limit);
        uint256 i = 0;
        bytes32 data = self[from];
        while (data > SENTINEL_BYTES32 && i < limit) {
            result[i] = data;
            data = self[data];
            unchecked {
                i++;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract OwnerManagerBase {
    /**
     * @notice Helper function to get the owner mapping from account storage
     * @return owners Mapping of current owners
     */
    function _ownerMapping() internal view virtual returns (mapping(bytes32 => bytes32) storage owners);

    /**
     * @notice Checks if the provided owner is a current owner
     * @param owner Address in bytes32 format to check
     * @return true if provided owner is a current owner, false otherwise
     */
    function _isOwner(bytes32 owner) internal view virtual returns (bool);

    /**
     * @notice Internal function to add an owner
     * @param owner Address in bytes32 format to add
     */
    function _addOwner(bytes32 owner) internal virtual;

    /**
     * @notice Internal function to remove an owner
     * @param owner Address in bytes32 format to remove
     */
    function _removeOwner(bytes32 owner) internal virtual;

    function _resetOwner(bytes32 newOwner) internal virtual;

    function _clearOwner() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IHookManager {
    function installHook(bytes calldata hookAndData, uint8 capabilityFlags) external;
    function uninstallHook(address hookAddress) external;

    function isInstalledHook(address hook) external view returns (bool);

    function listHook()
        external
        view
        returns (address[] memory preIsValidSignatureHooks, address[] memory preUserOpValidationHooks);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UserOperation} from "../interface/IAccount.sol";
import {IPluggable} from "./IPluggable.sol";

interface IHook is IPluggable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param hookSignature Signature byte array associated with _data
     */
    function preIsValidSignatureHook(bytes32 hash, bytes calldata hookSignature) external view;

    /**
     * @dev Hook that is called before any userOp is executed.
     * must revert if the userOp is invalid.
     */
    function preUserOpValidationHook(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds,
        bytes calldata hookSignature
    ) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract HookManagerBase {
    /**
     * @dev Install a hook
     * @param hookAddress The address of the hook
     * @param initData The init data of the hook
     * @param capabilityFlags Capability flags for the hook
     */
    function _installHook(address hookAddress, bytes memory initData, uint8 capabilityFlags) internal virtual;

    /**
     * @dev Uninstall a hook
     *      1. revert if the hook is not installed
     *      2. call hook.deInit() with 100k gas, emit HOOK_UNINSTALL_WITHERROR if the call failed
     * @param hookAddress The address of the hook
     */
    function _uninstallHook(address hookAddress) internal virtual;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract AuthorityBase {
    /**
     * @dev checks whether the caller is a authorized module
     *  caller: msg.sender
     *  method: msg.sig
     * @return bool
     */
    function _isAuthorizedModule() internal view virtual returns (bool);

    /**
     * @notice Ensures the calling contract is the entrypoint
     */
    function _onlyEntryPoint() internal view virtual;

    /**
     * @notice Ensures the calling contract is an authorized module
     */
    function _onlyModule() internal view virtual;

    /**
     * @notice Ensures the calling contract is either the Authority contract itself or an authorized module
     * @dev Uses the inherited `_isAuthorizedModule()` from ModuleAuth for module-based authentication
     */
    function _onlySelfOrModule() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. setFallbackHandler
     */
    function fallbackManagementAccess() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. installHook
     *      2. uninstallHook
     *      3. installModule
     *      4. uninstallModule
     */
    function pluginManagementAccess() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. addOwner
     *      2. removeOwner
     *      3. resetOwner
     */
    function ownerManagementAccess() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. execute
     *      2. executeBatch
     */
    function executorAccess() internal view virtual;

    /**
     * @dev Check if access to the following functions:
     *      1. installValidator
     *      2. uninstallValidator
     */
    function validatorManagementAccess() internal view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOwnable {
    /**
     * @notice Checks if a given bytes32 ID corresponds to an owner within the system
     * @param owner The bytes32 ID to check
     * @return True if the ID corresponds to an owner, false otherwise
     */

    function isOwner(bytes32 owner) external view returns (bool);
}