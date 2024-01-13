// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin/proxy/utils/Initializable.sol";
import {IVotes} from "@openzeppelin/governance/utils/IVotes.sol";
import {IERC6372} from "@openzeppelin/interfaces/IERC6372.sol";

import {LlamaUtils} from "src/lib/LlamaUtils.sol";
import {ILlamaTokenAdapter} from "src/token-voting/interfaces/ILlamaTokenAdapter.sol";

/// @title LlamaTokenAdapterVotesTimestamp
/// @author Llama ([email protected])
/// @notice A token adapter for tokens that implement IVotes, IERC6372 and use timestamp as their clock.
contract LlamaTokenAdapterVotesTimestamp is ILlamaTokenAdapter, Initializable {
  // =========================
  // ======== Structs ========
  // =========================

  /// @dev Llama token adapter initialization configuration.
  struct Config {
    address token; // The address of the voting token.
  }

  // ========================
  // ======== Errors ========
  // ========================

  /// @dev The clock was incorrectly modified.
  error ERC6372InconsistentClock();

  // =================================================
  // ======== Constants and Storage Variables ========
  // =================================================

  /// @notice The token to be used for voting.
  address public token;

  /// @notice Machine-readable description of the clock as specified in ERC-6372.
  string public CLOCK_MODE;

  // ================================
  // ======== Initialization ========
  // ================================

  /// @dev This contract is deployed as a minimal proxy from the factory's `deploy` function. The
  /// `_disableInitializers` locks the implementation (logic) contract, preventing any future initialization of it.
  constructor() {
    _disableInitializers();
  }

  /// @inheritdoc ILlamaTokenAdapter
  /// @dev There is no token validation for this adapter, as it is assumed to be a trusted input. If the address input
  /// is not a valid token, this adapter will not work properly, and will likely revert making calls to the token.
  function initialize(bytes memory config) external initializer returns (bool) {
    Config memory adapterConfig = abi.decode(config, (Config));
    token = adapterConfig.token;
    CLOCK_MODE = "mode=timestamp";

    return true;
  }

  /// @inheritdoc ILlamaTokenAdapter
  function clock() public view returns (uint48 timepoint) {
    try IERC6372(address(token)).clock() returns (uint48 tokenTimepoint) {
      timepoint = tokenTimepoint;
    } catch {
      timepoint = LlamaUtils.toUint48(block.timestamp);
    }
  }

  /// @inheritdoc ILlamaTokenAdapter
  function checkIfInconsistentClock() external view {
    bool hasClockChanged = _hasClockChanged();
    bool hasClockModeChanged = _hasClockModeChanged();

    if (hasClockChanged || hasClockModeChanged) revert ERC6372InconsistentClock();
  }

  /// @inheritdoc ILlamaTokenAdapter
  function timestampToTimepoint(uint256 timestamp) external pure returns (uint48 timepoint) {
    return LlamaUtils.toUint48(timestamp);
  }

  /// @inheritdoc ILlamaTokenAdapter
  function getPastVotes(address account, uint48 timepoint) external view returns (uint256) {
    return IVotes(token).getPastVotes(account, timepoint);
  }

  /// @inheritdoc ILlamaTokenAdapter
  function getPastTotalSupply(uint48 timepoint) external view returns (uint256) {
    return IVotes(token).getPastTotalSupply(timepoint);
  }

  /// @dev Check to see if the token's CLOCK_MODE function is returning a different CLOCK_MODE.
  function _hasClockModeChanged() internal view returns (bool) {
    try IERC6372(token).CLOCK_MODE() returns (string memory mode) {
      return keccak256(abi.encodePacked(mode)) != keccak256(abi.encodePacked(CLOCK_MODE));
    } catch {
      return false;
    }
  }

  /// @dev Check to see if the token's clock function is no longer returning the timestamp
  function _hasClockChanged() internal view returns (bool) {
    return clock() != LlamaUtils.toUint48(block.timestamp);
  }
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
// OpenZeppelin Contracts (last updated v5.0.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.20;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 */
interface IVotes {
    /**
     * @dev The signature used has expired.
     */
    error VotesExpiredSignature(uint256 expiry);

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of voting units.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     */
    function getPastVotes(address account, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC6372.sol)

pragma solidity ^0.8.20;

interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
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