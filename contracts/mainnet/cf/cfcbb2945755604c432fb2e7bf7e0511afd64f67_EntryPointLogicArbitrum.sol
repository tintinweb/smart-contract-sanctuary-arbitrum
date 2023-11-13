// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ArbGasInfo} from "./ArbGasInfo.sol";

import {EntryPointLogic, IEntryPointLogic, IAutomate, IProtocolFees, Constants} from "../EntryPointLogic.sol";

/// @title EntryPointLogicArbitrum
contract EntryPointLogicArbitrum is EntryPointLogic {
    /// @dev A special arbitrum contract used to calculate the gas that
    /// will be sent to the L1 network
    ArbGasInfo private constant ARB_GAS_ORACLE =
        ArbGasInfo(0x000000000000000000000000000000000000006C);

    /// @notice Sets the addresses of the `automate` and `gelato` upon deployment.
    /// @param automate The instance of GelatoAutomate contract.
    /// @param gelato The address of the Gelato main contract.
    constructor(
        IAutomate automate,
        address gelato,
        IProtocolFees protocolFees
    ) EntryPointLogic(automate, gelato, protocolFees) {}

    /// @inheritdoc IEntryPointLogic
    function run(
        uint256 workflowKey
    ) external override onlyRoleOrOwner(Constants.EXECUTOR_ROLE) {
        uint256 gasUsed = gasleft();

        _run(workflowKey);
        emit EntryPointRun(msg.sender, workflowKey);

        uint256 l1GasFees = ARB_GAS_ORACLE.getCurrentTxL1GasFees();

        unchecked {
            gasUsed = (gasUsed - gasleft()) * tx.gasprice;
        }

        _transferDittoFee(gasUsed, l1GasFees, false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Provides insight into the cost of using the chain.
/// @notice These methods have been adjusted to account for Nitro's heavy use of calldata compression.
/// Of note to end-users, we no longer make a distinction between non-zero and zero-valued calldata bytes.
/// Precompiled contract that exists in every Arbitrum chain at 0x000000000000000000000000000000000000006c.
interface ArbGasInfo {
    /// @notice Get L1 gas fees paid by the current transaction
    function getCurrentTxL1GasFees() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAutomate, ModuleData, Module, IOpsProxyFactory} from "@gelato/contracts/integrations/Types.sol";

import {DittoFeeBase, IProtocolFees} from "../libraries/DittoFeeBase.sol";
import {BaseContract, Constants} from "../libraries/BaseContract.sol";
import {TransferHelper} from "../libraries/utils/TransferHelper.sol";

import {IAccessControlLogic} from "../interfaces/IAccessControlLogic.sol";
import {IEntryPointLogic} from "../interfaces/IEntryPointLogic.sol";

/// @title EntryPointLogic
contract EntryPointLogic is IEntryPointLogic, BaseContract, DittoFeeBase {
    // =========================
    // Constructor
    // =========================

    /// @dev The instance of the GelatoAutomate contract.
    IAutomate internal immutable _automate;

    /// @dev The address of the Gelato main contract.
    address private immutable _gelato;

    /// @dev A constant address pointing to the OpsProxyFactory contract
    /// for Gelato proxy deployment.
    IOpsProxyFactory private constant OPS_PROXY_FACTORY =
        IOpsProxyFactory(0xC815dB16D4be6ddf2685C201937905aBf338F5D7);

    /// @notice Sets the addresses of the `automate` and `gelato` upon deployment.
    /// @param automate The instance of GelatoAutomate contract.
    /// @param gelato The address of the Gelato main contract.
    constructor(
        IAutomate automate,
        address gelato,
        IProtocolFees protocolFees
    ) DittoFeeBase(protocolFees) {
        _automate = automate;
        _gelato = gelato;
    }

    // =========================
    // Storage
    // =========================

    /// @dev Storage position for the entry point logic, to avoid collisions in storage.
    /// @dev Uses the "magic" constant to find a unique storage slot.
    bytes32 private immutable ENTRY_POINT_LOGIC_STORAGE_POSITION =
        keccak256("vault.workflow.entrypointlogic.storage");

    /// @dev Returns the storage slot for the entry point logic.
    /// @dev This function utilizes inline assembly to directly access the desired storage position.
    ///
    /// @return eps The storage slot pointer for the entry point logic.
    function _getLocalStorage()
        internal
        view
        returns (EntryPointStorage storage eps)
    {
        bytes32 position = ENTRY_POINT_LOGIC_STORAGE_POSITION;
        assembly ("memory-safe") {
            eps.slot := position
        }
    }

    // =========================
    // Status methods
    // =========================

    /// @inheritdoc IEntryPointLogic
    function activateVault(
        bytes[] calldata callbacks
    ) external onlyOwnerOrVaultItself {
        EntryPointStorage storage eps = _getLocalStorage();
        if (!eps.inactive) {
            revert EntryPoint_AlreadyActive();
        }

        eps.inactive = false;
        _callback(callbacks);

        emit EntryPointVaultStatusActivated();
    }

    /// @inheritdoc IEntryPointLogic
    function deactivateVault(
        bytes[] calldata callbacks
    ) external onlyOwnerOrVaultItself {
        EntryPointStorage storage eps = _getLocalStorage();
        if (eps.inactive) {
            revert EntryPoint_AlreadyInactive();
        }

        eps.inactive = true;
        _callback(callbacks);

        emit EntryPointVaultStatusDeactivated();
    }

    /// @inheritdoc IEntryPointLogic
    function activateWorkflow(
        uint256 workflowKey
    ) external onlyOwnerOrVaultItself {
        EntryPointStorage storage eps = _getLocalStorage();
        _verifyWorkflowKey(eps, workflowKey);

        Workflow storage workflow = eps.workflows[workflowKey];
        if (!workflow.inactive) {
            revert EntryPoint_AlreadyActive();
        }

        workflow.inactive = false;

        emit EntryPointWorkflowStatusActivated(workflowKey);
    }

    /// @inheritdoc IEntryPointLogic
    function deactivateWorkflow(
        uint256 workflowKey
    ) external onlyOwnerOrVaultItself {
        EntryPointStorage storage eps = _getLocalStorage();
        _verifyWorkflowKey(eps, workflowKey);

        Workflow storage workflow = eps.workflows[workflowKey];
        if (workflow.inactive) {
            revert EntryPoint_AlreadyInactive();
        }

        _deactivateWorkflow(workflowKey, workflow);
    }

    /// @inheritdoc IEntryPointLogic
    function isActive() external view returns (bool active) {
        return !_getLocalStorage().inactive;
    }

    // =========================
    // Actions with workflows
    // =========================

    /// @inheritdoc IEntryPointLogic
    function addWorkflowAndGelatoTask(
        Checker[] calldata checkers,
        Action[] calldata actions,
        address executor,
        uint88 count
    ) external onlyVaultItself {
        EntryPointStorage storage eps = _getLocalStorage();

        // starts from zero
        uint128 workflowKey;
        unchecked {
            workflowKey = eps.workflowKeys++;
        }

        _addWorkflow(checkers, actions, executor, count, workflowKey, eps);

        _createTask(eps, workflowKey);
    }

    /// @inheritdoc IEntryPointLogic
    function addWorkflow(
        Checker[] calldata checkers,
        Action[] calldata actions,
        address executor,
        uint88 count
    ) external onlyVaultItself {
        EntryPointStorage storage eps = _getLocalStorage();

        // starts from zero
        uint128 workflowKey;
        unchecked {
            workflowKey = eps.workflowKeys++;
        }

        _addWorkflow(checkers, actions, executor, count, workflowKey, eps);
    }

    /// @inheritdoc IEntryPointLogic
    function getWorkflow(
        uint256 workflowKey
    ) external view returns (Workflow memory) {
        return _getLocalStorage().workflows[workflowKey];
    }

    /// @inheritdoc IEntryPointLogic
    function getNextWorkflowKey() external view returns (uint256) {
        return _getLocalStorage().workflowKeys;
    }

    // =========================
    // Main Logic
    // =========================

    /// @inheritdoc IEntryPointLogic
    function canExecWorkflowCheck(
        uint256 workflowKey
    ) external view returns (bool, bytes memory) {
        // no check for inactive, not necessary
        Workflow storage workflow = _getLocalStorage().workflows[workflowKey];

        uint256 length = workflow.checkers.length;
        for (uint256 checkerId; checkerId < length; ) {
            Checker storage checker = workflow.checkers[checkerId];

            bytes memory data = checker.viewData;
            if (checker.storageRef.length > 0) {
                data = abi.encodePacked(data, keccak256(checker.storageRef));
            }

            (bool success, bytes memory returnData) = address(this).staticcall(
                data
            );

            // on successful call - check the return value from the checker
            if (success) {
                success = abi.decode(returnData, (bool));
                if (!success) {
                    return (false, bytes(""));
                }
            }

            unchecked {
                // increment loop counter
                ++checkerId;
            }
        }
        return (true, abi.encodeCall(this.runGelato, (workflowKey)));
    }

    /// @inheritdoc IEntryPointLogic
    function run(
        uint256 workflowKey
    ) external virtual onlyRoleOrOwner(Constants.EXECUTOR_ROLE) {
        uint256 gasUsed = gasleft();

        _run(workflowKey);

        emit EntryPointRun(msg.sender, workflowKey);

        unchecked {
            gasUsed = (gasUsed - gasleft()) * tx.gasprice;
        }

        _transferDittoFee(gasUsed, 0, false);
    }

    /// @inheritdoc IEntryPointLogic
    function runGelato(uint256 workflowKey) external {
        _onlyDedicatedMsgSender();

        _run(workflowKey);

        // Fetches the fee details from _automate during gelato automation process.
        (uint256 fee, ) = _automate.getFeeDetails();

        // feeToken is always Native currency
        // send fee to gelato
        TransferHelper.safeTransferNative(_gelato, fee);

        _transferDittoFee(fee, 0, false);

        emit EntryPointRunGelato(workflowKey);
    }

    // =========================
    // Gelato logic
    // =========================

    /// @inheritdoc IEntryPointLogic
    function dedicatedMessageSender() public view returns (address) {
        (address dedicatedMsgSender, ) = OPS_PROXY_FACTORY.getProxyOf(
            address(this)
        );
        return dedicatedMsgSender;
    }

    /// @inheritdoc IEntryPointLogic
    function createTask(
        uint256 workflowKey
    ) external payable onlyVaultItself returns (bytes32) {
        EntryPointStorage storage eps = _getLocalStorage();

        _verifyWorkflowKey(eps, workflowKey);

        if (eps.tasks[workflowKey] != bytes32(0)) {
            revert Gelato_TaskAlreadyStarted();
        }

        return _createTask(eps, workflowKey);
    }

    /// @inheritdoc IEntryPointLogic
    function cancelTask(uint256 workflowKey) external onlyOwnerOrVaultItself {
        EntryPointStorage storage eps = _getLocalStorage();

        if (eps.tasks[workflowKey] == bytes32(0)) {
            revert Gelato_CannotCancelTaskWhichNotExists();
        }

        _cancelTask(workflowKey, eps);
    }

    /// @inheritdoc IEntryPointLogic
    function getTaskId(uint256 workflowKey) external view returns (bytes32) {
        return _getLocalStorage().tasks[workflowKey];
    }

    // =========================
    // Private function
    // =========================

    /// @dev Executes the main logic of the workflow by provided `workflowKey`.
    /// @param workflowKey Identifier of the workflow to be executed.
    function _run(uint256 workflowKey) internal {
        EntryPointStorage storage eps = _getLocalStorage();

        _verifyWorkflowKey(eps, workflowKey);

        if (eps.inactive) {
            revert EntryPoint_VaultIsInactive();
        }

        Workflow storage workflow = eps.workflows[workflowKey];
        if (workflow.inactive) {
            revert EntryPoint_WorkflowIsInactive();
        }

        uint256 length = workflow.checkers.length;

        for (uint256 checkerId; checkerId < length; ) {
            Checker storage checker = workflow.checkers[checkerId];

            bytes memory data = checker.data;
            if (checker.storageRef.length > 0) {
                data = abi.encodePacked(data, keccak256(checker.storageRef));
            }

            (bool success, bytes memory returnData) = address(this).call(data);

            // on successful call - check the return value from the checker
            if (success) {
                success = abi.decode(returnData, (bool));
            }

            if (!success) {
                revert EntryPoint_TriggerVerificationFailed();
            }

            unchecked {
                // increment loop counter
                ++checkerId;
            }
        }

        length = workflow.actions.length;
        for (uint256 actionId; actionId < length; ) {
            Action storage action = workflow.actions[actionId];
            bytes memory data = action.data;
            if (action.storageRef.length > 0) {
                data = abi.encodePacked(data, keccak256(action.storageRef));
            }

            // call from address(this)
            (bool success, ) = address(this).call(data);

            if (!success) {
                // if call fails -> revert with original error message
                assembly ("memory-safe") {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            unchecked {
                // increment loop counter
                ++actionId;
            }
        }

        if (workflow.counter > 0) {
            uint256 counter;
            unchecked {
                counter = --workflow.counter;
            }

            if (counter == 0) {
                _deactivateWorkflow(workflowKey, workflow);

                if (eps.tasks[workflowKey] != bytes32(0)) {
                    _cancelTask(workflowKey, eps);
                }
            }
        }
    }

    /// @dev Internal callback function that iterates through and calls the provided `datas`.
    /// @param datas Array of data elements for callback.
    function _callback(bytes[] memory datas) private {
        if (datas.length > 0) {
            uint256 datasNumber = datas.length;
            for (uint256 callbackId; callbackId < datasNumber; ) {
                // delegatecall only from OWNER
                _call(datas[callbackId]);

                unchecked {
                    // increment loop counter
                    ++callbackId;
                }
            }
        }
    }

    /// @dev Calls initialization logic based on the provided `data` and `storageRef`.
    /// @param data Data to be used in the initialization.
    /// @param storageRef Storage reference associated with the data.
    function _initCall(bytes memory data, bytes memory storageRef) private {
        if (data.length > 0) {
            if (storageRef.length > 0) {
                data = abi.encodePacked(data, keccak256(storageRef));
            }

            _call(data);
        }
    }

    /// @dev Executes a delegate call with the given `data`.
    /// @param data Data to be used in the delegate call.
    function _call(bytes memory data) private {
        (bool success, bytes memory returnData) = address(this).call(data);
        if (!success) {
            // If call fails -> revert with original error message
            assembly ("memory-safe") {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }

    /// @dev Verifies if a given `workflowKey` exists in the EntryPoint storage.
    /// @param eps Reference to the EntryPoint storage structure.
    /// @param workflowKey Workflow key to verify.
    function _verifyWorkflowKey(
        EntryPointStorage storage eps,
        uint256 workflowKey
    ) private view {
        if (!(workflowKey < eps.workflowKeys)) {
            revert EntryPoint_WorkflowDoesNotExist();
        }
    }

    /// @dev Ensures that the current `msg.sender` is the dedicated sender from the Gelato.
    function _onlyDedicatedMsgSender() internal view {
        if (msg.sender != dedicatedMessageSender()) {
            revert Gelato_MsgSenderIsNotDedicated();
        }
    }

    /// @dev Returns a concatenated byte representation of the `resolverAddress` and `resolverData`.
    /// @param resolverAddress Address of the resolver.
    /// @param resolverData Associated data of the resolver.
    /// @return Returns a bytes memory combining the resolver address and data.
    function _resolverModuleArg(
        address resolverAddress,
        bytes memory resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(resolverAddress, resolverData);
    }

    /// @notice Adds a new workflow to the EntryPoint storage.
    /// @dev This function initializes checkers and actions, sets the executor and workflow counter,
    /// and grants the executor role.
    /// @param checkers Array of Checker structs to be added to the workflow.
    /// @param actions Array of Action structs to be added to the workflow.
    /// @param executor Address of the executor for the workflow.
    /// @param count The counter for the workflow.
    /// @param workflowKey Unique identifier for the workflow.
    /// @param eps Reference to EntryPointStorage where the workflow is to be added.
    function _addWorkflow(
        Checker[] calldata checkers,
        Action[] calldata actions,
        address executor,
        uint88 count,
        uint128 workflowKey,
        EntryPointStorage storage eps
    ) private {
        Workflow storage workflow = eps.workflows[workflowKey];

        uint256 length = checkers.length;
        for (uint i; i < length; ) {
            workflow.checkers.push();
            Checker storage checker = workflow.checkers[i];

            _initCall(checkers[i].initData, checkers[i].storageRef);
            checker.data = checkers[i].data;
            checker.viewData = checkers[i].viewData;
            if (checkers[i].storageRef.length > 0) {
                checker.storageRef = checkers[i].storageRef;
            }

            unchecked {
                // increment loop counter
                ++i;
            }
        }

        length = actions.length;
        for (uint i; i < length; ) {
            workflow.actions.push();
            Action storage action = workflow.actions[i];

            _initCall(actions[i].initData, actions[i].storageRef);
            action.data = actions[i].data;
            if (actions[i].storageRef.length > 0) {
                action.storageRef = actions[i].storageRef;
            }

            unchecked {
                // increment loop counter
                ++i;
            }
        }

        workflow.executor = executor;
        if (count > 0) {
            workflow.counter = count;
        }

        _call(
            abi.encodeCall(
                IAccessControlLogic.grantRole,
                (Constants.EXECUTOR_ROLE, executor)
            )
        );

        emit EntryPointAddWorkflow(workflowKey);
    }

    /// @notice Creates a new task in the EntryPoint storage.
    /// @dev This function sets up the modules and arguments for the task,
    /// then calls the automation logic to create the task.
    /// @param eps Reference to EntryPointStorage where the task data to be stored.
    /// @param workflowKey Unique identifier for the associated workflow.
    /// @return taskId The unique identifier for the created task.
    function _createTask(
        EntryPointStorage storage eps,
        uint256 workflowKey
    ) private returns (bytes32) {
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeWithSelector(
                this.canExecWorkflowCheck.selector,
                workflowKey
            )
        );

        bytes memory execData = abi.encodeWithSelector(
            this.runGelato.selector,
            workflowKey
        );

        bytes32 taskId = _automate.createTask(
            address(this),
            execData,
            moduleData,
            Constants.ETH
        );

        // Set storage
        eps.tasks[workflowKey] = taskId;

        emit GelatoTaskCreated(workflowKey, taskId);

        return taskId;
    }

    /// @notice Cancels an existing task in the EntryPoint storage.
    /// @dev This function deletes the task from storage and then calls the automation logic to cancel the task.
    /// @param workflowKey Unique identifier for the associated workflow.
    /// @param eps Reference to EntryPointStorage where the task is stored.
    function _cancelTask(
        uint256 workflowKey,
        EntryPointStorage storage eps
    ) private {
        bytes32 taskId = eps.tasks[workflowKey];

        delete eps.tasks[workflowKey];

        _automate.cancelTask(taskId);

        emit GelatoTaskCancelled(workflowKey, taskId);
    }

    /// @notice Deactivates a workflow in the EntryPoint storage.
    /// @dev This function sets the inactive flag for a workflow to true.
    /// @param workflowKey Unique identifier for the workflow to be deactivated.
    /// @param workflow Reference to the Workflow storage to be deactivated.
    function _deactivateWorkflow(
        uint256 workflowKey,
        Workflow storage workflow
    ) private {
        workflow.inactive = true;

        emit EntryPointWorkflowStatusDeactivated(workflowKey);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

enum Module {
    RESOLVER,
    TIME,
    PROXY,
    SINGLE_EXEC
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IAutomate {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IGelato {
    function feeCollector() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IProtocolFees} from "../../IProtocolFees.sol";
import {TransferHelper} from "./utils/TransferHelper.sol";

/// @title DittoFeeBase
contract DittoFeeBase {
    // =========================
    // Constructor
    // =========================

    IProtocolFees internal immutable _protocolFees;

    uint256 internal constant E18 = 1e18;

    /// @notice Sets the addresses of the `automate` and `gelato` upon deployment.
    /// @param protocolFees:
    constructor(IProtocolFees protocolFees) {
        _protocolFees = protocolFees;
    }

    // =========================
    // Events
    // =========================

    /// @notice Emits when ditto fee is transferred.
    /// @param dittoFee The amount of Ditto fee transferred.
    event DittoFeeTransfer(uint256 dittoFee);

    // =========================
    // Helpers
    // =========================

    /// @dev Transfers the specified `dittoFee` amount to the `treasury`.
    /// @param dittoFee Amount of value to transfer.
    /// @param rollupFee Amount of roll up fee.
    /// @param isInstant Bool to indicate if the fee to be paid for instant action:
    function _transferDittoFee(
        uint256 dittoFee,
        uint256 rollupFee,
        bool isInstant
    ) internal {
        address treasury;
        uint256 feeGasBps;
        uint256 feeFix;

        if (isInstant) {
            (treasury, feeGasBps, feeFix) = _protocolFees
                .getInstantFeesAndTreasury();
        } else {
            (treasury, feeGasBps, feeFix) = _protocolFees
                .getAutomationFeesAndTreasury();
        }

        // if treasury is setted
        if (treasury != address(0)) {
            unchecked {
                // take percent of gasUsed + fixed fee
                dittoFee =
                    (((dittoFee + rollupFee) * feeGasBps) / E18) +
                    feeFix;
            }

            if (dittoFee > 0) {
                TransferHelper.safeTransferNative(treasury, dittoFee);

                emit DittoFeeTransfer(dittoFee);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlLib} from "./AccessControlLib.sol";
import {Constants} from "./Constants.sol";

/// @title BaseContract
/// @notice A base contract that provides common access control features.
/// @dev This contract integrates with AccessControlLib to provide role-based access
/// control and ownership checks. Contracts inheriting from this can use its modifiers
/// for common access restrictions.
contract BaseContract {
    // =========================
    // Error
    // =========================

    /// @notice Thrown when an account is not authorized to perform a specific action.
    error UnauthorizedAccount(address account);

    // =========================
    // Modifiers
    // =========================

    /// @dev Modifier that checks if an account has a specific `role`
    /// or is the owner of the contract.
    /// @dev Reverts with `UnauthorizedAccount` error if the conditions are not met.
    modifier onlyRoleOrOwner(bytes32 role) {
        _checkRole(role, msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's owner.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyOwner() {
        _checkOnlyOwner(msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyVaultItself() {
        _checkOnlyVaultItself(msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's owner
    /// or the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyOwnerOrVaultItself() {
        _checkOnlyOwnerOrVaultItself(msg.sender);

        _;
    }

    // =========================
    // Internal function
    // =========================

    /// @dev Checks if the given `account` possesses the specified `role` or is the owner.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param role The role to check against the account.
    /// @param account The account to check.
    function _checkRole(bytes32 role, address account) internal view virtual {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        if (
            !((msg.sender == AccessControlLib.getOwner()) ||
                _hasRole(s, role, account))
        ) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyVaultItself(address account) internal view virtual {
        if (account != address(this)) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyOwnerOrVaultItself(
        address account
    ) internal view virtual {
        if (account == address(this)) {
            return;
        }

        if (account != AccessControlLib.getOwner()) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the owner of the contract.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyOwner(address account) internal view virtual {
        if (account != AccessControlLib.getOwner()) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Returns `true` if `account` has been granted `role`.
    /// @param s The storage reference for roles from AccessControlLib.
    /// @param role The role to check against the account.
    /// @param account The account to check.
    /// @return True if the account possesses the role, false otherwise.
    function _hasRole(
        AccessControlLib.RolesStorage storage s,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return s.roles[role][account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TransferHelper
/// @notice A helper library for safe transfers, approvals, and balance checks.
/// @dev Provides safe functions for ERC20 token and native currency transfers.
library TransferHelper {
    // =========================
    // Event
    // =========================

    /// @notice Emits when a transfer is successfully executed.
    /// @param token The address of the token (address(0) for native currency).
    /// @param from The address of the sender.
    /// @param to The address of the recipient.
    /// @param value The number of tokens (or native currency) transferred.
    event TransferHelperTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 value
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when `safeTransferFrom` fails.
    error TransferHelper_SafeTransferFromError();

    /// @notice Thrown when `safeTransfer` fails.
    error TransferHelper_SafeTransferError();

    /// @notice Thrown when `safeApprove` fails.
    error TransferHelper_SafeApproveError();

    /// @notice Thrown when `safeGetBalance` fails.
    error TransferHelper_SafeGetBalanceError();

    /// @notice Thrown when `safeTransferNative` fails.
    error TransferHelper_SafeTransferNativeError();

    // =========================
    // Functions
    // =========================

    /// @notice Executes a safe transfer from one address to another.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param from Address of the sender.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (
            !_makeCall(
                token,
                abi.encodeCall(IERC20.transferFrom, (from, to, value))
            )
        ) {
            revert TransferHelper_SafeTransferFromError();
        }

        emit TransferHelperTransfer(token, from, to, value);
    }

    /// @notice Executes a safe transfer.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransfer(address token, address to, uint256 value) internal {
        if (!_makeCall(token, abi.encodeCall(IERC20.transfer, (to, value)))) {
            revert TransferHelper_SafeTransferError();
        }

        emit TransferHelperTransfer(token, address(this), to, value);
    }

    /// @notice Executes a safe approval.
    /// @dev Uses low-level calls to handle cases where allowance is not zero
    /// and tokens which are not supports approve with non-zero allowance.
    /// @param token Address of the ERC20 token to approve.
    /// @param spender Address of the account that gets the approval.
    /// @param value Amount to approve.
    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeCall(
            IERC20.approve,
            (spender, value)
        );

        if (!_makeCall(token, approvalCall)) {
            if (
                !_makeCall(
                    token,
                    abi.encodeCall(IERC20.approve, (spender, 0))
                ) || !_makeCall(token, approvalCall)
            ) {
                revert TransferHelper_SafeApproveError();
            }
        }
    }

    /// @notice Retrieves the balance of an account safely.
    /// @dev Uses low-level staticcall to ensure proper error handling.
    /// @param token Address of the ERC20 token.
    /// @param account Address of the account to fetch balance for.
    /// @return The balance of the account.
    function safeGetBalance(
        address token,
        address account
    ) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, account)
        );
        if (!success || data.length == 0) {
            revert TransferHelper_SafeGetBalanceError();
        }
        return abi.decode(data, (uint256));
    }

    /// @notice Executes a safe transfer of native currency (e.g., ETH).
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            revert TransferHelper_SafeTransferNativeError();
        }

        emit TransferHelperTransfer(address(0), address(this), to, value);
    }

    // =========================
    // Private function
    // =========================

    /// @dev Helper function to make a low-level call for token methods.
    /// @dev Ensures correct return value and decodes it.
    ///
    /// @param token Address to make the call on.
    /// @param data Calldata for the low-level call.
    /// @return True if the call succeeded, false otherwise.
    function _makeCall(
        address token,
        bytes memory data
    ) private returns (bool) {
        (bool success, bytes memory returndata) = token.call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IAccessControlLogic - AccessControlLogic interface
interface IAccessControlLogic {
    // =========================
    // Events
    // =========================

    /// @dev Emitted when ownership of a vault is transferred.
    /// @param oldOwner Address of the previous owner.
    /// @param newOwner Address of the new owner.
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    /// @dev Emitted when a new `role` is granted to an `account`.
    /// @param role Identifier for the role.
    /// @param account Address of the account.
    /// @param sender Address of the sender granting the role.
    event RoleGranted(bytes32 role, address account, address sender);

    /// @dev Emitted when a `role` is revoked from an `account`.
    /// @param role Identifier for the role.
    /// @param account Address of the account.
    /// @param sender Address of the sender revoking the role.
    event RoleRevoked(bytes32 role, address account, address sender);

    /// @dev Emitted when a cross chain logic flag is setted.
    /// @param flag Cross chain flag new value.
    event CrossChainLogicInactiveFlagSet(bool flag);

    // =========================
    // Main functions
    // =========================

    /// @notice Initializes the `creator` and `vaultId`.
    /// @param creator Address of the vault creator.
    /// @param vaultId ID of the vault.
    function initializeCreatorAndId(address creator, uint16 vaultId) external;

    /// @notice Returns the address of the creator of the vault and its ID.
    /// @return The creator's address and the vault ID.
    function creatorAndId() external view returns (address, uint16);

    /// @notice Returns the owner's address of the vault.
    /// @return Address of the vault owner.
    function owner() external view returns (address);

    /// @notice Retrieves the address of the Vault proxyAdmin.
    /// @return Address of the Vault proxyAdmin.
    function getVaultProxyAdminAddress() external view returns (address);

    /// @notice Transfers ownership of the proxy vault to a `newOwner`.
    /// @param newOwner Address of the new owner.
    function transferOwnership(address newOwner) external;

    /// @notice Updates the activation status of the cross-chain logic.
    /// @dev Can only be called by an authorized admin to enable or disable the cross-chain logic.
    /// @param newValue The new activation status to be set; `true` to activate, `false` to deactivate.
    function setCrossChainLogicInactiveStatus(bool newValue) external;

    /// @notice Checks whether the cross-chain logic is currently active.
    /// @dev Returns true if the cross-chain logic is active, false otherwise.
    /// @return isActive The current activation status of the cross-chain logic.
    function crossChainLogicIsActive() external view returns (bool isActive);

    /// @notice Checks if an `account` has been granted a particular `role`.
    /// @param role Role identifier to check.
    /// @param account Address of the account to check against.
    /// @return True if the account has the role, otherwise false.
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /// @notice Grants a specified `role` to an `account`.
    /// @dev The caller must be the owner of the vault.
    /// @dev Emits a {RoleGranted} event if the account hadn't been granted the role.
    /// @param role Role identifier to grant.
    /// @param account Address of the account to grant the role to.
    function grantRole(bytes32 role, address account) external;

    /// @notice Revokes a specified `role` from an `account`.
    /// @dev The caller must be the owner of the vault.
    /// @dev Emits a {RoleRevoked} event if the account had the role.
    /// @param role Role identifier to revoke.
    /// @param account Address of the account to revoke the role from.
    function revokeRole(bytes32 role, address account) external;

    /// @notice An account can use this to renounce a `role`, effectively losing its privileges.
    /// @dev Useful in scenarios where an account might be compromised.
    /// @dev Emits a {RoleRevoked} event if the account had the role.
    /// @param role Role identifier to renounce.
    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEntryPointLogic - EntryPointLogic Interface
/// @dev This contract provides functions for adding automation workflows,
/// interacting with Gelato logic, activating and deactivating vaults
/// and workflows and checking vault status.
interface IEntryPointLogic {
    // =========================
    // Storage
    // =========================

    /// @notice Data structure representing EntryPoint storage elements.
    struct EntryPointStorage {
        mapping(uint256 => Workflow) workflows;
        mapping(uint256 => bytes32) tasks;
        // a counter for generating unique keys for workflows.
        uint128 workflowKeys;
        // a boolean that indicates if the entire `EntryPoint` logic is inactive.
        bool inactive;
    }

    /// @notice Data structure representing Checker elements.
    struct Checker {
        // the data which is used to check the condition and rewrite storage (if necessary).
        bytes data;
        // the data which only is used to check the condition.
        bytes viewData;
        // the data from which a unique storage pointer for the checker is derived.
        // pointer = keccak256(storageRef).
        bytes storageRef;
        // Initial data, which is called during workflow adding.
        // Not stored in the storage.
        bytes initData;
    }

    /// @notice Data structure representing Action elements.
    struct Action {
        // the data which is used to perform the action.
        bytes data;
        // the data from which a unique storage pointer for the action is derived.
        // pointer = keccak256(storageRef).
        bytes storageRef;
        // Initial data, which is called during workflow adding.
        // Not stored in the storage.
        bytes initData;
    }

    /// @notice Data structure representing Workflow elements.
    struct Workflow {
        Checker[] checkers;
        Action[] actions;
        address executor;
        uint88 counter;
        bool inactive;
    }

    // =========================
    // Events
    // =========================

    /// @notice Emits when EntryPoint is run.
    /// @param executor Address of the executor.
    event EntryPointRun(address indexed executor, uint256 workflowKey);

    /// @notice Emits when EntryPoint is run via Gelato.
    event EntryPointRunGelato(uint256 workflowKey);

    /// @notice Emits when EntryPoint vault is activated.
    event EntryPointVaultStatusActivated();

    /// @notice Emits when EntryPoint vault is deactivated.
    event EntryPointVaultStatusDeactivated();

    /// @notice Emits when a workflow is activated.
    /// @param workflowKey Key of the activated workflow.
    event EntryPointWorkflowStatusActivated(uint256 workflowKey);

    /// @notice Emits when a workflow is deactivated.
    /// @param workflowKey Key of the deactivated workflow.
    event EntryPointWorkflowStatusDeactivated(uint256 workflowKey);

    /// @notice Emits when a workflow is added.
    /// @param workflowKey Key of the added workflow.
    event EntryPointAddWorkflow(uint256 workflowKey);

    /// @notice Emits when a Gelato task is created.
    /// @param workflowKey Key of the associated workflow.
    /// @param id Identifier of the created task.
    event GelatoTaskCreated(uint256 workflowKey, bytes32 id);

    /// @notice Emits when a Gelato task is cancelled.
    /// @param workflowKey Key of the associated workflow.
    /// @param id Identifier of the cancelled task.
    event GelatoTaskCancelled(uint256 workflowKey, bytes32 id);

    // =========================
    // Errors
    // =========================

    /// @dev Thrown when trying to activate vault or workflow that is already active.
    error EntryPoint_AlreadyActive();

    /// @dev Thrown when trying to deactivate vault or workflow that is already inactive.
    error EntryPoint_AlreadyInactive();

    /// @dev Thrown when attempting an operation that requires the vault to be active.
    error EntryPoint_VaultIsInactive();

    /// @dev Thrown when attempting an operation that requires the workflow to be active.
    error EntryPoint_WorkflowIsInactive();

    /// @dev Thrown when trigger verification fails during the workflow execution.
    error EntryPoint_TriggerVerificationFailed();

    /// @dev Thrown when trying to access a workflow that doesn't exist.
    error EntryPoint_WorkflowDoesNotExist();

    /// @dev Thrown when attempting to start a Gelato task that has already been started.
    error Gelato_TaskAlreadyStarted();

    /// @dev Thrown when attempting to cancel a Gelato task that doesn't exist.
    error Gelato_CannotCancelTaskWhichNotExists();

    /// @dev Thrown when the message sender is not the dedicated Gelato address.
    error Gelato_MsgSenderIsNotDedicated();

    // =========================
    // Status methods
    // =========================

    /// @notice Activates the vault.
    /// @param callbacks An array of callbacks to be executed during activation.
    /// @dev Callbacks can be used for various tasks like adding workflows or adding native balance to the vault.
    function activateVault(bytes[] calldata callbacks) external;

    /// @notice Deactivates the vault.
    /// @param callbacks An array of callbacks to be executed during deactivation.
    /// @dev Callbacks can be used for various tasks like cancel task or removing native balance from the vault.
    function deactivateVault(bytes[] calldata callbacks) external;

    /// @notice Activates a specific workflow.
    /// @param workflowKey The identifier of the workflow to be activated.
    function activateWorkflow(uint256 workflowKey) external;

    /// @notice Deactivates a specific workflow.
    /// @param workflowKey The identifier of the workflow to be deactivated.
    function deactivateWorkflow(uint256 workflowKey) external;

    /// @notice Checks if the vault is active.
    /// @return active Returns true if the vault is active, otherwise false.
    function isActive() external view returns (bool active);

    // =========================
    // Actions with workflows
    // =========================

    /// @notice Adds a new workflow to the EntryPoint and creates a Gelato task for it.
    /// @param checkers An array of Checker structures to define the conditions.
    /// @param actions An array of Action structures to define the actions.
    /// @param executor The address of the executor.
    /// @param count The number of times the workflow should be executed.
    function addWorkflowAndGelatoTask(
        Checker[] calldata checkers,
        Action[] calldata actions,
        address executor,
        uint88 count
    ) external;

    /// @notice Adds a new workflow to the EntryPoint.
    /// @param checkers An array of Checker structures to define the conditions.
    /// @param actions An array of Action structures to define the actions.
    /// @param executor The address of the executor.
    /// @param count The number of times the workflow should be executed.
    function addWorkflow(
        Checker[] calldata checkers,
        Action[] calldata actions,
        address executor,
        uint88 count
    ) external;

    /// @notice Fetches the details of a specific workflow.
    /// @param workflowKey The identifier of the workflow.
    /// @return Workflow structure containing the details of the workflow.
    function getWorkflow(
        uint256 workflowKey
    ) external view returns (Workflow memory);

    /// @notice Retrieves the next available workflow key.
    /// @return The next available workflow key.
    function getNextWorkflowKey() external view returns (uint256);

    // =========================
    // Main Logic
    // =========================

    /// @notice Checks if a workflow can be executed.
    /// @param workflowKey The identifier of the workflow.
    /// @return A boolean indicating if the workflow can be executed,
    /// and the encoded data to run the workflow on Gelato.
    function canExecWorkflowCheck(
        uint256 workflowKey
    ) external view returns (bool, bytes memory);

    /// @notice Executes a specific workflow and compensates the `feeReceiver` for gas costs.
    /// @param workflowKey Unique identifier for the workflow to be executed.
    function run(uint256 workflowKey) external;

    /// @notice Executes the logic of a workflow via Gelato.
    /// @param workflowKey The identifier of the workflow to be executed.
    /// @dev Only a dedicated message sender from Gelato can call this function.
    function runGelato(uint256 workflowKey) external;

    // =========================
    // Gelato logic
    // =========================

    /// @notice Fetches the dedicated message sender for Gelato.
    /// @return The address of the dedicated message sender.
    function dedicatedMessageSender() external view returns (address);

    /// @notice Creates a task in Gelato associated with a specific workflow.
    /// @param workflowKey The identifier of the workflow for which the task is created.
    /// @return Identifier of the created task.
    function createTask(uint256 workflowKey) external payable returns (bytes32);

    /// @notice Cancels an existing Gelato task.
    /// @param workflowKey Unique identifier for the workflow associated with the task.
    /// @dev Reverts if the task is not existent.
    function cancelTask(uint256 workflowKey) external;

    /// @notice Retrieves the `taskId` for a specific workflow.
    /// @param workflowKey Unique identifier for the workflow.
    /// @return The taskId associated with the workflow.
    function getTaskId(uint256 workflowKey) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IProtocolFees - ProtocolFees interface
interface IProtocolFees {
    // =========================
    // Events
    // =========================

    /// @notice Emits when instant fees are changed.
    event InstantFeesChanged(uint64 instantFeeGasBps, uint192 instantFeeFix);

    /// @notice Emits when automation fees are changed.
    event AutomationFeesChanged(
        uint64 automationFeeGasBps,
        uint192 automationFeeFix
    );

    /// @notice Emits when treasury address are changed.
    event TreasuryChanged(address treasury);

    // =========================
    // Getters
    // =========================

    /// @notice Gets instant fees.
    /// @return treasury address of the ditto treasury
    /// @return instantFeeGasBps instant fee in gas bps
    /// @return instantFeeFix fixed fee for instant calls
    function getInstantFeesAndTreasury()
        external
        view
        returns (
            address treasury,
            uint256 instantFeeGasBps,
            uint256 instantFeeFix
        );

    /// @notice Gets automation fees.
    /// @return treasury address of the ditto treasury
    /// @return automationFeeGasBps automation fee in gas bps
    /// @return automationFeeFix fixed fee for automation calls
    function getAutomationFeesAndTreasury()
        external
        view
        returns (
            address treasury,
            uint256 automationFeeGasBps,
            uint256 automationFeeFix
        );

    // =========================
    // Setters
    // =========================

    /// @notice Sets instant fees.
    /// @param instantFeeGasBps: instant fee in gas bps
    /// @param instantFeeFix: fixed fee for instant calls
    function setInstantFees(
        uint64 instantFeeGasBps,
        uint192 instantFeeFix
    ) external;

    /// @notice Sets automation fees.
    /// @param automationFeeGasBps: automation fee in gas bps
    /// @param automationFeeFix: fixed fee for automation calls
    function setAutomationFee(
        uint64 automationFeeGasBps,
        uint192 automationFeeFix
    ) external;

    /// @notice Sets the ditto treasury address.
    /// @param treasury: address of the ditto treasury
    function setTreasury(address treasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title AccessControlLib
/// @notice A library for managing access controls with roles and ownership.
/// @dev Provides the structures and functions needed to manage roles and determine ownership.
library AccessControlLib {
    // =========================
    // Errors
    // =========================

    /// @notice Thrown when attempting to initialize an already initialized vault.
    error AccessControlLib_AlreadyInitialized();

    // =========================
    // Storage
    // =========================

    /// @dev Storage position for the access control struct, to avoid collisions in storage.
    /// @dev Uses the "magic" constant to find a unique storage slot.
    bytes32 constant ROLES_STORAGE_POSITION = keccak256("vault.roles.storage");

    /// @notice Struct to store roles and ownership details.
    struct RolesStorage {
        // Role-based access mapping
        mapping(bytes32 role => mapping(address account => bool)) roles;
        // Address that created the entity
        address creator;
        // Identifier for the vault
        uint16 vaultId;
        // Flag to decide if cross chain logic is not allowed
        bool crossChainLogicInactive;
        // Owner address
        address owner;
        // Flag to decide if `owner` or `creator` is used
        bool useOwner;
    }

    // =========================
    // Main library logic
    // =========================

    /// @dev Retrieve the storage location for roles.
    /// @return s Reference to the roles storage struct in the storage.
    function rolesStorage() internal pure returns (RolesStorage storage s) {
        bytes32 position = ROLES_STORAGE_POSITION;
        assembly ("memory-safe") {
            s.slot := position
        }
    }

    /// @dev Fetch the owner of the vault.
    /// @dev Determines whether to use the `creator` or the `owner` based on the `useOwner` flag.
    /// @return Address of the owner.
    function getOwner() internal view returns (address) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        if (s.useOwner) {
            return s.owner;
        } else {
            return s.creator;
        }
    }

    /// @dev Returns the address of the creator of the vault and its ID.
    /// @return The creator's address and the vault ID.
    function getCreatorAndId() internal view returns (address, uint16) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();
        return (s.creator, s.vaultId);
    }

    /// @dev Initializes the `creator` and `vaultId` for a new vault.
    /// @dev Should only be used once. Reverts if already set.
    /// @param creator Address of the vault creator.
    /// @param vaultId Identifier for the vault.
    function initializeCreatorAndId(address creator, uint16 vaultId) internal {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        // check if vault never existed before
        if (s.vaultId != 0) {
            revert AccessControlLib_AlreadyInitialized();
        }

        s.creator = creator;
        s.vaultId = vaultId;
    }

    /// @dev Fetches cross chain logic flag.
    /// @return True if cross chain logic is active.
    function crossChainLogicIsActive() internal view returns (bool) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        return !s.crossChainLogicInactive;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Constants
/// @dev These constants can be imported and used by other contracts for consistency.
library Constants {
    /// @dev A keccak256 hash representing the executor role.
    bytes32 internal constant EXECUTOR_ROLE =
        keccak256("DITTO_WORKFLOW_EXECUTOR_ROLE");

    /// @dev A constant representing the native token in any network.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}