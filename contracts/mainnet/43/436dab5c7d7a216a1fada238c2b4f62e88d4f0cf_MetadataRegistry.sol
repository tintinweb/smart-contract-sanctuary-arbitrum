// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ITrigger} from "./interfaces/ITrigger.sol";
import {ISafetyModule} from "./interfaces/ISafetyModule.sol";

/**
 * @notice Emits metadata about a safety module or trigger so it can be retrieved off-chain.
 * @dev Metadata can be fetched by querying logs or configuring a subgraph to index the events.
 */
contract MetadataRegistry {
  /// @notice The CozyRouter address used by this MetadataRegistry.
  address public cozyRouter;

  /// @notice The owner of this MetadataRegistry.
  address public owner;

  struct Metadata {
    string name;
    string description;
    string logoURI;
    string extraData;
  }

  /// @dev Emitted when the CozyRouter is updated.
  event CozyRouterUpdated(address indexed cozyRouter);

  /// @dev Emitted when the owner is updated.
  event OwnerUpdated(address indexed owner);

  /// @dev Emitted when a safety module's metadata is updated.
  event SafetyModuleMetadataUpdated(address indexed safetyModule, Metadata metadata);

  /// @dev Emitted when a trigger's metadata is updated.
  event TriggerMetadataUpdated(address indexed trigger, Metadata metadata);

  /// @dev Thrown when the caller is not authorized to perform the action.
  error Unauthorized();

  /// @dev Thrown when there is a length mismatch in the provided metadata.
  error InvalidConfiguration();

  constructor(address owner_, address cozyRouter_) {
    owner = owner_;
    cozyRouter = cozyRouter_;
  }

  /// @notice Update metadata for safety modules.
  /// @param safetyModules_ An array of safety modules to be updated.
  /// @param metadata_ An array of new metadata, mapping 1:1 with the addresses in the safetyModules_ array.
  function updateSafetyModuleMetadata(address[] calldata safetyModules_, Metadata[] calldata metadata_) external {
    if (safetyModules_.length != metadata_.length) revert InvalidConfiguration();
    for (uint256 i = 0; i < safetyModules_.length; i++) {
      updateSafetyModuleMetadata(safetyModules_[i], metadata_[i]);
    }
  }

  /// @notice Update metadata for a safety module.
  /// @param safetyModule_ The address of the safety module.
  /// @param metadata_ The new metadata for the safety module.
  function updateSafetyModuleMetadata(address safetyModule_, Metadata calldata metadata_) public {
    if (msg.sender != ISafetyModule(safetyModule_).owner()) revert Unauthorized();
    emit SafetyModuleMetadataUpdated(safetyModule_, metadata_);
  }

  /// @notice Update metadata for a safety module. This function can be called by the CozyRouter.
  /// @param safetyModule_ The address of the safety module.
  /// @param metadata_ The new metadata for the safety module.
  /// @param caller_ The address of the CozyRouter caller.
  function updateSafetyModuleMetadata(address safetyModule_, Metadata calldata metadata_, address caller_) public {
    if (msg.sender != cozyRouter || caller_ != ISafetyModule(safetyModule_).owner()) revert Unauthorized();
    emit SafetyModuleMetadataUpdated(safetyModule_, metadata_);
  }

  /// @notice Update metadata for triggers.
  /// @param triggers_ An array of triggers to be updated.
  /// @param metadata_ An array of new metadata, mapping 1:1 with the addresses in the triggers_ array.
  function updateTriggerMetadata(address[] calldata triggers_, Metadata[] calldata metadata_) external {
    if (triggers_.length != metadata_.length) revert InvalidConfiguration();
    for (uint256 i = 0; i < triggers_.length; i++) {
      updateTriggerMetadata(triggers_[i], metadata_[i]);
    }
  }

  /// @notice Update metadata for a trigger.
  /// @param trigger_ The address of the trigger.
  /// @param metadata_ The new metadata for the trigger.
  function updateTriggerMetadata(address trigger_, Metadata calldata metadata_) public {
    address boss_ = address(0);
    address owner_ = address(0);

    try ITrigger(trigger_).boss() returns (address result_) {
      boss_ = result_;
    } catch {}

    try ITrigger(trigger_).owner() returns (address result_) {
      owner_ = result_;
    } catch {}

    if (msg.sender != boss_ && msg.sender != owner_) revert Unauthorized();
    emit TriggerMetadataUpdated(address(trigger_), metadata_);
  }

  /// @notice Update the CozyRouter address used by this MetadataRegistry.
  /// @param cozyRouter_ The new CozyRouter address.
  function updateCozyRouter(address cozyRouter_) external onlyOwner {
    cozyRouter = cozyRouter_;
    emit CozyRouterUpdated(cozyRouter_);
  }

  function updateOwner(address owner_) external onlyOwner {
    owner = owner_;
    emit OwnerUpdated(owner_);
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized();
    _;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

/**
 * @dev Interface for interacting with triggers that might have privileged users.
 * This is not a comprehensive interface for triggers, and only contains signatures for privileged
 * roles that may exist.
 */
interface ITrigger {
  function boss() external view returns (address);
  function owner() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

interface ISafetyModule {
  /// @notice Returns the SafetyModule contract owner address.
  function owner() external view returns (address);
}