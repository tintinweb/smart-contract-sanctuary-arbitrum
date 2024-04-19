// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {LlamaUtils} from "src/lib/LlamaUtils.sol";

/// @title Llama Account Multicall Storage
/// @author Llama ([email protected])
/// @notice The storage contract for the `LlamaAccountMulticallExtension` contract.
/// @dev This is a separate storage contract to prevent storage collisions with the Llama account.
contract LlamaAccountMulticallStorage {
  // =========================
  // ======== Structs ========
  // =========================

  /// @dev Struct to hold authorized target-selectors.
  struct TargetSelectorAuthorization {
    address target; // The target contract.
    bytes4 selector; // The selector of the function being called.
    bool isAuthorized; // Is the target-selector authorized.
  }

  // ========================
  // ======== Errors ========
  // ========================

  /// @dev Thrown if `initializeAuthorizedTargetSelectors` is called again.
  error AlreadyInitialized();

  /// @dev Only callable by a Llama instance's executor.
  error OnlyLlama();

  // ========================
  // ======== Events ========
  // ========================

  /// @notice Emitted when a target-selector is authorized.
  event TargetSelectorAuthorized(address indexed target, bytes4 indexed selector, bool isAuthorized);

  // ===================================
  // ======== Storage Variables ========
  // ===================================

  /// @notice The Llama instance's executor.
  address public immutable LLAMA_EXECUTOR;

  /// @dev Whether the contract is initialized.
  bool internal initialized;

  /// @notice Mapping of all authorized target-selectors.
  mapping(address target => mapping(bytes4 selector => bool isAuthorized)) public authorizedTargetSelectors;

  // ======================================================
  // ======== Contract Creation and Initialization ========
  // ======================================================

  /// @dev Sets the Llama executor.
  constructor(address llamaExecutor) {
    LLAMA_EXECUTOR = llamaExecutor;
  }

  /// @notice Initializes the authorized target-selectors.
  /// @dev This function can only be called once. It should be called as part of the contract deployment.
  /// @param data The target-selectors to authorize.
  function initializeAuthorizedTargetSelectors(TargetSelectorAuthorization[] memory data) external {
    if (initialized) revert AlreadyInitialized();
    initialized = true;
    _setAuthorizedTargetSelectors(data);
  }

  // ================================
  // ======== External Logic ========
  // ================================

  /// @notice Sets the authorized target-selectors.
  /// @param data The target-selectors to authorize.
  function setAuthorizedTargetSelectors(TargetSelectorAuthorization[] memory data) external {
    if (msg.sender != LLAMA_EXECUTOR) revert OnlyLlama();
    _setAuthorizedTargetSelectors(data);
  }

  // ================================
  // ======== Internal Logic ========
  // ================================

  /// @dev Sets the authorized target-selectors.
  function _setAuthorizedTargetSelectors(TargetSelectorAuthorization[] memory data) internal {
    uint256 length = data.length;
    for (uint256 i = 0; i < length; i = LlamaUtils.uncheckedIncrement(i)) {
      authorizedTargetSelectors[data[i].target][data[i].selector] = data[i].isAuthorized;
      emit TargetSelectorAuthorized(data[i].target, data[i].selector, data[i].isAuthorized);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {PermissionData} from "src/lib/Structs.sol";

/// @dev Shared helper methods for Llama's contracts.
library LlamaUtils {
  /// @dev Thrown when a value cannot be safely casted to a smaller type.
  error UnsafeCast(uint256 n);

  /// @dev Reverts if `n` does not fit in a `uint16`.
  function toUint16(uint256 n) internal pure returns (uint16) {
    if (n > type(uint16).max) revert UnsafeCast(n);
    return uint16(n);
  }

  /// @dev Reverts if `n` does not fit in a `uint48`.
  function toUint48(uint256 n) internal pure returns (uint48) {
    if (n > type(uint48).max) revert UnsafeCast(n);
    return uint48(n);
  }

  /// @dev Reverts if `n` does not fit in a `uint64`.
  function toUint64(uint256 n) internal pure returns (uint64) {
    if (n > type(uint64).max) revert UnsafeCast(n);
    return uint64(n);
  }

  /// @dev Reverts if `n` does not fit in a `uint96`.
  function toUint96(uint256 n) internal pure returns (uint96) {
    if (n > type(uint96).max) revert UnsafeCast(n);
    return uint96(n);
  }

  /// @dev Reverts if `n` does not fit in a `uint128`.
  function toUint128(uint256 n) internal pure returns (uint128) {
    if (n > type(uint128).max) revert UnsafeCast(n);
    return uint128(n);
  }

  /// @dev Increments a `uint256` without checking for overflow.
  function uncheckedIncrement(uint256 i) internal pure returns (uint256) {
    unchecked {
      return i + 1;
    }
  }

  /// @dev Hashes a permission to return the corresponding permission ID.
  function computePermissionId(PermissionData memory permission) internal pure returns (bytes32) {
    return keccak256(abi.encode(permission));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ILlamaAccount} from "src/interfaces/ILlamaAccount.sol";
import {ILlamaCore} from "src/interfaces/ILlamaCore.sol";
import {ILlamaActionGuard} from "src/interfaces/ILlamaActionGuard.sol";
import {ILlamaStrategy} from "src/interfaces/ILlamaStrategy.sol";
import {ILlamaTokenAdapter} from "src/token-voting/interfaces/ILlamaTokenAdapter.sol";
import {RoleDescription} from "src/lib/UDVTs.sol";

/// @dev Data required to create an action.
struct ActionInfo {
  uint256 id; // ID of the action.
  address creator; // Address that created the action.
  uint8 creatorRole; // The role that created the action.
  ILlamaStrategy strategy; // Strategy used to govern the action.
  address target; // Contract being called by an action.
  uint256 value; // Value in wei to be sent when the action is executed.
  bytes data; // Data to be called on the target when the action is executed.
}

/// @dev Data that represents an action.
struct Action {
  // Instead of storing all data required to execute an action in storage, we only save the hash to
  // make action creation cheaper. The hash is computed by taking the keccak256 hash of the concatenation of each
  // field in the `ActionInfo` struct.
  bytes32 infoHash;
  bool executed; // Has action executed.
  bool canceled; // Is action canceled.
  bool isScript; // Is the action's target a script.
  ILlamaActionGuard guard; // The action's guard. This is the address(0) if no guard is set on the action's target and
    // selector pair.
  uint64 creationTime; // The timestamp when action was created (used for policy snapshots).
  uint64 minExecutionTime; // Only set when an action is queued. The timestamp when action execution can begin.
  uint96 totalApprovals; // The total quantity of policyholder approvals.
  uint96 totalDisapprovals; // The total quantity of policyholder disapprovals.
}

/// @dev Data that represents a permission.
struct PermissionData {
  address target; // Contract being called by an action.
  bytes4 selector; // Selector of the function being called by an action.
  ILlamaStrategy strategy; // Strategy used to govern the action.
}

/// @dev Data required to assign/revoke a role to/from a policyholder.
struct RoleHolderData {
  uint8 role; // ID of the role to set (uint8 ensures onchain enumerability when burning policies).
  address policyholder; // Policyholder to assign the role to.
  uint96 quantity; // Quantity of the role to assign to the policyholder, i.e. their (dis)approval quantity.
  uint64 expiration; // When the role expires.
}

/// @dev Data required to assign/revoke a permission to/from a role.
struct RolePermissionData {
  uint8 role; // ID of the role to set (uint8 ensures onchain enumerability when burning policies).
  PermissionData permissionData; // The `(target, selector, strategy)` tuple that will be keccak256 hashed to
    // generate the permission ID to assign or unassign to the role
  bool hasPermission; // Whether to assign the permission or remove the permission.
}

/// @dev Configuration of a new Llama instance.
struct LlamaInstanceConfig {
  string name; // The name of the Llama instance.
  ILlamaStrategy strategyLogic; // The initial strategy implementation (logic) contract.
  ILlamaAccount accountLogic; // The initial account implementation (logic) contract.
  bytes[] initialStrategies; // Array of initial strategy configurations.
  bytes[] initialAccounts; // Array of initial account configurations.
  LlamaPolicyConfig policyConfig; // Configuration of the instance's policy.
}

/// @dev Configuration of a new Llama policy.
struct LlamaPolicyConfig {
  RoleDescription[] roleDescriptions; // The initial role descriptions.
  RoleHolderData[] roleHolders; // The `role`, `policyholder`, `quantity` and `expiration` of the initial role holders.
  RolePermissionData[] rolePermissions; // The `role`, `permissionData`, and  the `hasPermission` boolean.
  string color; // The primary color of the SVG representation of the instance's policy (e.g. #00FF00).
  string logo; // The SVG string representing the logo for the deployed Llama instance's NFT.
}

/// @dev Configuration of a new Llama token voting module.
struct LlamaTokenVotingConfig {
  ILlamaCore llamaCore; // The address of the Llama core.
  ILlamaTokenAdapter tokenAdapterLogic; // The logic contract of the token adapter.
  bytes adapterConfig; // The configuration of the token adapter.
  uint256 nonce; // The nonce to be used in the salt of the deterministic deployment.
  uint256 creationThreshold; // The number of tokens required to create an action.
  CasterConfig casterConfig; // The quorum and period data for the `LlamaTokenGovernor`.
}

/// @dev Quorum and period data for token voting caster contracts.
struct CasterConfig {
  uint16 voteQuorumPct; // The minimum % of total supply that must be casted as `For` votes.
  uint16 vetoQuorumPct; // The minimum % of total supply that must be casted as `For` vetoes.
  uint16 delayPeriodPct; // The % of the total approval or queuing period used as a delay.
  uint16 castingPeriodPct; // The % of the total approval or queuing period used to cast votes or vetoes
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Llama Account Logic Interface
/// @author Llama ([email protected])
/// @notice This is the interface for Llama accounts which can be used to hold assets for a Llama instance.
interface ILlamaAccount {
  /// @dev External call failed.
  /// @param result Data returned by the called function.
  error FailedExecution(bytes result);

  // -------- For Inspection --------

  /// @notice Returns the address of the Llama instance's executor.
  function llamaExecutor() external view returns (address);

  // -------- At Account Creation --------

  /// @notice Initializes a new clone of the account.
  /// @dev This function is called by the `_deployAccounts` function in the `LlamaCore` contract. The `initializer`
  /// modifier ensures that this function can be invoked at most once.
  /// @param config The account configuration, encoded as bytes to support differing constructor arguments in
  /// different account logic contracts.
  /// @return This return statement must be hardcoded to `true` to ensure that initializing an EOA
  /// (like the zero address) will revert.
  function initialize(bytes memory config) external returns (bool);

  // -------- Generic Execution --------

  /// @notice Execute arbitrary calls from the Llama Account.
  /// @dev Be careful and intentional while assigning permissions to a policyholder that can create an action to call
  /// this function, especially while using the delegatecall functionality as it can lead to arbitrary code execution in
  /// the context of this Llama account.
  /// @param target The address of the contract to call.
  /// @param withDelegatecall Whether to use delegatecall or call.
  /// @param value The amount of ETH to send with the call, taken from the Llama Account.
  /// @param callData The calldata to pass to the contract.
  /// @return The result of the call.
  function execute(address target, bool withDelegatecall, uint256 value, bytes calldata callData)
    external
    returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// TODO This interface was generated from `cast interface`, so some types are not as strong as they
// could be. For example, the existing `ILlamaStrategy` were all `address` until they were manually
// changed. So there are probably other types that need to be updated also.
pragma solidity ^0.8.23;

import {ILlamaPolicy} from "src/interfaces/ILlamaPolicy.sol";
import {ILlamaStrategy} from "src/interfaces/ILlamaStrategy.sol";
import {ActionState} from "src/lib/Enums.sol";
import {
  Action,
  ActionInfo,
  LlamaInstanceConfig,
  LlamaPolicyConfig,
  PermissionData,
  RoleHolderData,
  RolePermissionData
} from "src/lib/Structs.sol";

/// @title LlamaCore Interface
/// @author Llama ([email protected])
/// @notice This is the interface for LlamaCore.
interface ILlamaCore {
  error InvalidSignature();

  error PolicyholderDoesNotHavePermission();

  /// @dev The action is not in the expected state.
  /// @param current The current state of the action.
  error InvalidActionState(ActionState current);

  /// @dev Action execution failed.
  /// @param reason Data returned by the function called by the action.
  error FailedActionExecution(bytes reason);

  function actionGuard(address target, bytes4 selector) external view returns (address guard);

  function actionsCount() external view returns (uint256);

  function approvals(uint256 actionId, address policyholder) external view returns (bool hasApproved);

  function authorizedAccountLogics(address accountLogic) external view returns (bool isAuthorized);

  function authorizedScripts(address script) external view returns (bool isAuthorized);

  function authorizedStrategyLogics(ILlamaStrategy strategyLogic) external view returns (bool isAuthorized);

  function cancelAction(ActionInfo memory actionInfo) external;

  function cancelActionBySig(address policyholder, ActionInfo memory actionInfo, uint8 v, bytes32 r, bytes32 s)
    external;

  function castApproval(uint8 role, ActionInfo memory actionInfo, string memory reason) external returns (uint96);

  function castApprovalBySig(
    address policyholder,
    uint8 role,
    ActionInfo memory actionInfo,
    string memory reason,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint96);

  function castDisapproval(uint8 role, ActionInfo memory actionInfo, string memory reason) external returns (uint96);

  function castDisapprovalBySig(
    address policyholder,
    uint8 role,
    ActionInfo memory actionInfo,
    string memory reason,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint96);

  function createAccounts(address llamaAccountLogic, bytes[] memory accountConfigs) external;

  function createAction(
    uint8 role,
    ILlamaStrategy strategy,
    address target,
    uint256 value,
    bytes memory data,
    string memory description
  ) external returns (uint256 actionId);

  function createActionBySig(
    address policyholder,
    uint8 role,
    ILlamaStrategy strategy,
    address target,
    uint256 value,
    bytes memory data,
    string memory description,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 actionId);

  function createStrategies(address llamaStrategyLogic, bytes[] memory strategyConfigs) external;

  function disapprovals(uint256 actionId, address policyholder) external view returns (bool hasDisapproved);

  function executeAction(ActionInfo memory actionInfo) external payable;

  function executor() external view returns (address);

  function getAction(uint256 actionId) external view returns (Action memory);

  function getActionState(ActionInfo memory actionInfo) external view returns (uint8);

  function incrementNonce(bytes4 selector) external;

  function initialize(LlamaInstanceConfig memory config, address policyLogic, address policyMetadataLogic) external;

  function name() external view returns (string memory);

  function nonces(address policyholder, bytes4 selector) external view returns (uint256 currentNonce);

  function policy() external view returns (ILlamaPolicy);

  function queueAction(ActionInfo memory actionInfo) external;

  function setAccountLogicAuthorization(address accountLogic, bool authorized) external;

  function setGuard(address target, bytes4 selector, address guard) external;

  function setScriptAuthorization(address script, bool authorized) external;

  function setStrategyAuthorization(ILlamaStrategy strategy, bool authorized) external;

  function setStrategyLogicAuthorization(ILlamaStrategy strategyLogic, bool authorized) external;

  function strategies(ILlamaStrategy strategy) external view returns (bool deployed, bool authorized);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ActionInfo} from "src/lib/Structs.sol";

/// @title Llama Action Guard Interface
/// @author Llama ([email protected])
/// @notice Executes checks on action creation and execution to verify that the action is allowed.
/// @dev Methods are not `view` because (1) an action guard may write to it's own storage, and (2)
/// Having `view` methods that can revert isn't great UX. Allowing guards to write to their own
/// storage is useful to persist state between calls to the various guard methods. For example, a
/// guard may:
///   - Store the USD price of a token during action creation in `validateActionCreation`.
///   - Verify the price has not changed by more than a given amount during `validatePreActionExecution`
///     and save off the current USD value of an account.
///   - Verify the USD value of an account has not decreased by more than a certain amount during
///     execution, i.e. between `validatePreActionExecution` and `validatePostActionExecution`.
interface ILlamaActionGuard {
  /// @notice Reverts if action creation is not allowed.
  /// @param actionInfo Data required to create an action.
  function validateActionCreation(ActionInfo calldata actionInfo) external;

  /// @notice Called immediately before action execution, and reverts if the action is not allowed
  /// to be executed.
  /// @param actionInfo Data required to create an action.
  function validatePreActionExecution(ActionInfo calldata actionInfo) external;

  /// @notice Called immediately after action execution, and reverts if the just-executed
  /// action should not have been allowed to execute.
  /// @param actionInfo Data required to create an action.
  function validatePostActionExecution(ActionInfo calldata actionInfo) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ActionInfo} from "src/lib/Structs.sol";
import {ILlamaCore} from "src/interfaces/ILlamaCore.sol";
import {ILlamaPolicy} from "src/interfaces/ILlamaPolicy.sol";

/// @title Llama Strategy Interface
/// @author Llama ([email protected])
/// @notice This is the interface for Llama strategies which determine the rules of an action's process.
/// @dev The interface is sorted by the stage of the action's lifecycle in which the method's are used.
interface ILlamaStrategy {
  // -------- For Inspection --------
  // These are not strictly required by the core, but are useful for inspecting a strategy contract.

  /// @notice Returns the address of the Llama core that this strategy is registered to.
  function llamaCore() external view returns (ILlamaCore);

  /// @notice Returns the name of the Llama policy that this strategy is registered to.
  function policy() external view returns (ILlamaPolicy);

  // -------- Required for Strategies used with LlamaTokenGovernor --------

  /// @notice Returns the approval period of the strategy in seconds.
  function approvalPeriod() external view returns (uint64);

  /// @notice Returns the queuing period of the strategy in seconds.
  function queuingPeriod() external view returns (uint64);

  /// @notice The role that can approve an action.
  function approvalRole() external view returns (uint8);

  /// @notice The role that can disapprove an action.
  function disapprovalRole() external view returns (uint8);

  /// @notice Returns true if an action can force an action to be approved and false otherwise.
  function forceApprovalRole(uint8 role) external view returns (bool isForceApproval);

  /// @notice Returns true if an action can force an action to be disapproved and false otherwise.
  function forceDisapprovalRole(uint8 role) external view returns (bool isForceDisapproval);

  // -------- At Strategy Creation --------

  /// @notice Initializes a new clone of the strategy.
  /// @dev This function is called by the `_deployStrategies` function in the `LlamaCore` contract. The `initializer`
  /// modifier ensures that this function can be invoked at most once.
  /// @param config The strategy configuration, encoded as bytes to support differing constructor arguments in
  /// different strategies.
  /// @return This return statement must be hardcoded to `true` to ensure that initializing an EOA
  /// (like the zero address) will revert.
  function initialize(bytes memory config) external returns (bool);

  // -------- At Action Creation --------

  /// @notice Reverts if action creation is not allowed.
  /// @param actionInfo Data required to create an action.
  function validateActionCreation(ActionInfo calldata actionInfo) external view;

  // -------- When Casting Approval --------

  /// @notice Reverts if approvals are not allowed with this strategy for the given policyholder when approving with
  /// role.
  /// @param actionInfo Data required to create an action.
  /// @param policyholder Address of the policyholder.
  /// @param role The role of the policyholder being used to cast approval.
  function checkIfApprovalEnabled(ActionInfo calldata actionInfo, address policyholder, uint8 role) external view;

  /// @notice Get the quantity of an approval of a policyholder at a specific timestamp.
  /// @param policyholder Address of the policyholder.
  /// @param role The role to check quantity for.
  /// @param timestamp The timestamp at which to get the approval quantity.
  /// @return The quantity of the policyholder's approval.
  function getApprovalQuantityAt(address policyholder, uint8 role, uint256 timestamp) external view returns (uint96);

  // -------- When Casting Disapproval --------

  /// @notice Reverts if disapprovals are not allowed with this strategy for the given policyholder when disapproving
  /// with role.
  /// @param actionInfo Data required to create an action.
  /// @param policyholder Address of the policyholder.
  /// @param role The role of the policyholder being used to cast disapproval.
  function checkIfDisapprovalEnabled(ActionInfo calldata actionInfo, address policyholder, uint8 role) external view;

  /// @notice Get the quantity of a disapproval of a policyholder at a specific timestamp.
  /// @param policyholder Address of the policyholder.
  /// @param role The role to check quantity for.
  /// @param timestamp The timestamp at which to get the disapproval quantity.
  /// @return The quantity of the policyholder's disapproval.
  function getDisapprovalQuantityAt(address policyholder, uint8 role, uint256 timestamp) external view returns (uint96);

  // -------- When Queueing --------

  /// @notice Returns the earliest timestamp, in seconds, at which an action can be executed.
  /// @param actionInfo Data required to create an action.
  /// @return The earliest timestamp at which an action can be executed.
  function minExecutionTime(ActionInfo calldata actionInfo) external view returns (uint64);

  // -------- When Canceling --------

  /// @notice Reverts if the action cannot be canceled.
  /// @param actionInfo Data required to create an action.
  /// @param caller Policyholder initiating the cancelation.
  function validateActionCancelation(ActionInfo calldata actionInfo, address caller) external view;

  // -------- When Determining Action State --------
  // These are used during casting of approvals and disapprovals, when queueing, and when executing.

  /// @notice Get whether an action is currently active.
  /// @param actionInfo Data required to create an action.
  /// @return Boolean value that is `true` if the action is currently active, `false` otherwise.
  function isActionActive(ActionInfo calldata actionInfo) external view returns (bool);

  /// @notice Get whether an action has passed the approval process.
  /// @param actionInfo Data required to create an action.
  /// @return Boolean value that is `true` if the action has passed the approval process.
  function isActionApproved(ActionInfo calldata actionInfo) external view returns (bool);

  /// @notice Get whether an action has been vetoed during the disapproval process.
  /// @param actionInfo Data required to create an action.
  /// @return Boolean value that is `true` if the action has been vetoed during the disapproval process.
  function isActionDisapproved(ActionInfo calldata actionInfo) external view returns (bool);

  /// @notice Returns `true` if the action is expired, `false` otherwise.
  /// @param actionInfo Data required to create an action.
  /// @return Boolean value that is `true` if the action is expired.
  function isActionExpired(ActionInfo calldata actionInfo) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title ILlamaTokenAdapter
/// @author Llama ([email protected])
/// @notice This contract provides an interface for voting token adapters.
interface ILlamaTokenAdapter {
  /// @notice Initializes a new clone of the token adapter.
  /// @dev This function is called by the `deploy` function in the `LlamaTokenVotingFactory` contract. The `initializer`
  /// modifier ensures that this function can be invoked at most once.
  /// @param config The token adapter configuration, encoded as bytes to support differing constructor arguments in
  /// different token adapters.
  /// @return This return statement must be hardcoded to `true` to ensure that initializing an EOA
  /// (like the zero address) will revert.
  function initialize(bytes memory config) external returns (bool);

  /// @notice Returns the token voting module's voting token address.
  /// @return token The voting token.
  function token() external view returns (address token);

  /// @notice Returns the current timepoint according to the token's clock.
  /// @return timepoint the current timepoint
  function clock() external view returns (uint48 timepoint);

  /// @notice Reverts if the token's CLOCK_MODE changes from what's in the adapter or if the clock() function doesn't
  function checkIfInconsistentClock() external view;

  /// @notice Converts a timestamp to timepoint units.
  /// @param timestamp The timestamp to convert.
  /// @return timepoint the current timepoint
  function timestampToTimepoint(uint256 timestamp) external view returns (uint48 timepoint);

  /// @notice Get the voting balance of a token holder at a specified past timepoint.
  /// @param account The token holder's address.
  /// @param timepoint The timepoint at which to get the voting balance.
  /// @return The number of votes the account had at timepoint.
  function getPastVotes(address account, uint48 timepoint) external view returns (uint256);

  /// @notice Get the total supply of a token at a specified past timepoint.
  /// @param timepoint The timepoint at which to get the total supply.
  /// @return The total supply of the token at timepoint.
  function getPastTotalSupply(uint48 timepoint) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// @dev We use this UDVT for stronger typing of the Role Description.
type RoleDescription is bytes32;

// SPDX-License-Identifier: MIT
// TODO This interface was generated from `cast interface`, so some types are not as strong as they
// could be.
pragma solidity ^0.8.23;

import {RoleDescription} from "../lib/UDVTs.sol";

/// @title LlamaPolicy Interface
/// @author Llama ([email protected])
/// @notice This is the interface for LlamaPolicy.
interface ILlamaPolicy {
  event Approval(address indexed owner, address indexed spender, uint256 indexed id);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event ExpiredRoleRevoked(address indexed caller, address indexed policyholder, uint8 indexed role);
  event Initialized(uint8 version);
  event PolicyMetadataSet(address policyMetadata, address indexed policyMetadataLogic, bytes initializationData);
  event RoleAssigned(address indexed policyholder, uint8 indexed role, uint64 expiration, uint96 quantity);
  event RoleInitialized(uint8 indexed role, bytes32 description);
  event RolePermissionAssigned(
    uint8 indexed role, bytes32 indexed permissionId, PermissionData permissionData, bool hasPermission
  );
  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  struct LlamaPolicyConfig {
    RoleDescription[] roleDescriptions;
    RoleHolderData[] roleHolders;
    RolePermissionData[] rolePermissions;
    string color;
    string logo;
  }

  struct PermissionData {
    address target;
    bytes4 selector;
    address strategy;
  }

  struct Checkpoint {
    uint64 timestamp;
    uint64 expiration;
    uint96 quantity;
  }

  struct History {
    Checkpoint[] _checkpoints;
  }

  struct RoleHolderData {
    uint8 role;
    address policyholder;
    uint96 quantity;
    uint64 expiration;
  }

  struct RolePermissionData {
    uint8 role;
    PermissionData permissionData;
    bool hasPermission;
  }

  function approve(address, uint256) external pure;
  function balanceOf(address owner) external view returns (uint256);
  function canCreateAction(uint8 role, bytes32 permissionId) external view returns (bool hasPermission);
  function contractURI() external view returns (string memory);
  function getApproved(uint256) external view returns (address);
  function getPastQuantity(address policyholder, uint8 role, uint256 timestamp) external view returns (uint96);
  function getPastRoleSupplyAsNumberOfHolders(uint8 role, uint256 timestamp)
    external
    view
    returns (uint96 numberOfHolders);
  function getPastRoleSupplyAsQuantitySum(uint8 role, uint256 timestamp) external view returns (uint96 totalQuantity);
  function getQuantity(address policyholder, uint8 role) external view returns (uint96);
  function getRoleSupplyAsNumberOfHolders(uint8 role) external view returns (uint96 numberOfHolders);
  function getRoleSupplyAsQuantitySum(uint8 role) external view returns (uint96 totalQuantity);
  function hasPermissionId(address policyholder, uint8 role, bytes32 permissionId) external view returns (bool);
  function hasRole(address policyholder, uint8 role) external view returns (bool);
  function hasRole(address policyholder, uint8 role, uint256 timestamp) external view returns (bool);
  function initialize(
    string memory _name,
    LlamaPolicyConfig memory config,
    address policyMetadataLogic,
    address executor,
    PermissionData memory bootstrapPermissionData
  ) external;
  function initializeRole(RoleDescription description) external;
  function isApprovedForAll(address, address) external view returns (bool);
  function isRoleExpired(address policyholder, uint8 role) external view returns (bool);
  function llamaExecutor() external view returns (address);
  function llamaPolicyMetadata() external view returns (address);
  function name() external view returns (string memory);
  function numRoles() external view returns (uint8);
  function ownerOf(uint256 id) external view returns (address owner);
  function revokeExpiredRole(uint8 role, address policyholder) external;
  function revokePolicy(address policyholder) external;
  function roleBalanceCheckpoints(address policyholder, uint8 role, uint256 start, uint256 end)
    external
    view
    returns (History memory);
  function roleBalanceCheckpoints(address policyholder, uint8 role) external view returns (History memory);
  function roleBalanceCheckpointsLength(address policyholder, uint8 role) external view returns (uint256);
  function roleExpiration(address policyholder, uint8 role) external view returns (uint64);
  function roleSupplyCheckpoints(uint8 role, uint256 start, uint256 end) external view returns (History memory);
  function roleSupplyCheckpoints(uint8 role) external view returns (History memory);
  function roleSupplyCheckpointsLength(uint8 role) external view returns (uint256);
  function safeTransferFrom(address, address, uint256) external pure;
  function safeTransferFrom(address, address, uint256, bytes memory) external pure;
  function setAndInitializePolicyMetadata(address llamaPolicyMetadataLogic, bytes memory config) external;
  function setApprovalForAll(address, bool) external pure;
  function setRoleHolder(uint8 role, address policyholder, uint96 quantity, uint64 expiration) external;
  function setRolePermission(uint8 role, PermissionData memory permissionData, bool hasPermission) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function transferFrom(address, address, uint256) external pure;
  function updateRoleDescription(uint8 role, RoleDescription description) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @dev Possible states of an action during its lifecycle.
enum ActionState {
  Active, // Action created and approval period begins.
  Canceled, // Action canceled by creator.
  Failed, // Action approval failed.
  Approved, // Action approval succeeded and ready to be queued.
  Queued, // Action queued for queueing duration and disapproval period begins.
  Expired, // block.timestamp is greater than Action's executionTime + expirationDelay.
  Executed // Action has executed successfully.

}

/// @dev Possible states of a user cast vote.
enum VoteType {
  Against,
  For,
  Abstain
}