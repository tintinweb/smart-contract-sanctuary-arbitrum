// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IUpgradeLogic} from "../vault/interfaces/IUpgradeLogic.sol";

import {AccessControlLib} from "./libraries/AccessControlLib.sol";

/// @title UpgradeLogic
/// @dev Logic for upgrading the implementation of a proxy clone contract.
contract UpgradeLogic is IUpgradeLogic {
    // =========================
    // Main functions
    // =========================

    /// @inheritdoc IUpgradeLogic
    function upgrade(address newImplementation) external {
        assembly ("memory-safe") {
            sstore(not(0), newImplementation)
        }
        emit ImplementationChanged(newImplementation);
    }

    /// @inheritdoc IUpgradeLogic
    function implementation() external view returns (address impl_) {
        assembly ("memory-safe") {
            impl_ := sload(not(0))
        }
    }

    /// @inheritdoc IUpgradeLogic
    function owner() external view returns (address) {
        return AccessControlLib.getOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IUpgradeLogic - UpgradeLogicinterface
/// @dev Logic for upgrading the implementation of a proxy clone contract.
interface IUpgradeLogic {
    // =========================
    // Events
    // =========================

    /// @notice Emits when the implementation address is changed.
    /// @param newImplementation The address of the new implementation.
    event ImplementationChanged(address newImplementation);

    // =========================
    // Main functions
    // =========================

    /// @notice Setting a `newImplementation` address for delegate calls
    /// from the proxy clone.
    /// @param newImplementation Address of the new implementation.
    function upgrade(address newImplementation) external;

    /// @notice Returns the address of the current implementation to which
    /// the proxy clone delegates calls.
    /// @return impl_ Address of the current implementation.
    function implementation() external view returns (address impl_);

    /// @notice Returns the address of the current owner of the vault.
    /// @return The address of the current owner.
    function owner() external view returns (address);
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