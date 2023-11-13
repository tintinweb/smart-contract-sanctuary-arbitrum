// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {BaseContract} from "../../libraries/BaseContract.sol";

import {ITimeCheckerLogic} from "../../interfaces/checkers/ITimeCheckerLogic.sol";

/// @title TimeCheckerLogic
contract TimeCheckerLogic is ITimeCheckerLogic, BaseContract {
    // =========================
    // Storage
    // =========================

    /// @dev Fetches the checker storage without initialization check.
    /// @dev Uses inline assembly to point to the specific storage slot.
    /// Be cautious while using this.
    /// @param pointer Pointer to the strategy's storage location.
    /// @return s The storage slot for TimeCheckerStorage structure.
    function _getStorageUnsafe(
        bytes32 pointer
    ) internal pure returns (TimeCheckerStorage storage s) {
        assembly ("memory-safe") {
            s.slot := pointer
        }
    }

    /// @dev Fetches the checker storage after checking initialization.
    /// @dev Reverts if the strategy is not initialized.
    /// @param pointer Pointer to the strategy's storage location.
    /// @return s The storage slot for TimeCheckerStorage structure.
    function _getStorage(
        bytes32 pointer
    ) internal view returns (TimeCheckerStorage storage s) {
        s = _getStorageUnsafe(pointer);

        if (!s.initialized) {
            revert TimeChecker_NotInitialized();
        }
    }

    // =========================
    // Initializer
    // =========================

    /// @inheritdoc ITimeCheckerLogic
    function timeCheckerInitialize(
        uint64 lastActionTime,
        uint64 timePeriod,
        bytes32 pointer
    ) external onlyVaultItself {
        TimeCheckerStorage storage s = _getStorageUnsafe(pointer);

        if (s.initialized) {
            revert TimeChecker_AlreadyInitialized();
        }
        s.initialized = true;

        s.lastActionTime = lastActionTime;
        s.timePeriod = timePeriod;

        emit TimeCheckerInitialized();
    }

    // =========================
    // Main functions
    // =========================

    /// @inheritdoc ITimeCheckerLogic
    function checkTime(
        bytes32 pointer
    ) external onlyVaultItself returns (bool) {
        TimeCheckerStorage storage s = _getStorage(pointer);

        bool enoughTimePassed = _enoughTimePassed(
            s.lastActionTime,
            s.timePeriod
        );

        if (enoughTimePassed) {
            s.lastActionTime = uint64(block.timestamp);
        }

        return enoughTimePassed;
    }

    /// @inheritdoc ITimeCheckerLogic
    function checkTimeView(bytes32 pointer) external view returns (bool) {
        TimeCheckerStorage storage s = _getStorage(pointer);
        return _enoughTimePassed(s.lastActionTime, s.timePeriod);
    }

    // =========================
    // Setters
    // =========================

    /// @inheritdoc ITimeCheckerLogic
    function setTimePeriod(
        uint64 timePeriod,
        bytes32 pointer
    ) external onlyOwnerOrVaultItself {
        _getStorage(pointer).timePeriod = timePeriod;
        emit TimeCheckerSetNewPeriod(timePeriod);
    }

    // =========================
    // Getters
    // =========================

    /// @inheritdoc ITimeCheckerLogic
    function getLocalTimeCheckerStorage(
        bytes32 pointer
    )
        external
        view
        returns (uint256 lastActionTime, uint256 timePeriod, bool initialized)
    {
        TimeCheckerStorage storage s = _getStorageUnsafe(pointer);

        return (s.lastActionTime, s.timePeriod, s.initialized);
    }

    // =========================
    // Internal functions
    // =========================

    /// @dev Checks if enough time has passed since the last action.
    /// @param startTime The start time of the last action.
    /// @param period The time period.
    /// @return True if enough time has passed.
    function _enoughTimePassed(
        uint256 startTime,
        uint256 period
    ) internal view returns (bool) {
        return block.timestamp >= (startTime + period);
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

/// @title ITimeCheckerLogic - TimeCheckerLogic interface.
interface ITimeCheckerLogic {
    // =========================
    // Storage
    // =========================

    /// @dev Storage structure for the Time Checker
    struct TimeCheckerStorage {
        uint64 lastActionTime;
        uint64 timePeriod;
        bool initialized;
    }

    // =========================
    // Events
    // =========================

    /// @notice Thrown when a new period is set for the TimeChecker.
    /// @param newPeriod The new period that was set.
    event TimeCheckerSetNewPeriod(uint256 newPeriod);

    /// @notice Thrown when the TimeChecker is initialized.
    event TimeCheckerInitialized();

    /// @notice Thrown when trying to initialize an already initialized Time Checker
    error TimeChecker_AlreadyInitialized();

    /// @notice Thrown when trying to perform an action on a not initialized Time Checker
    error TimeChecker_NotInitialized();

    // =========================
    // Initializer
    // =========================

    /// @notice Initializes the time checker with the given parameters.
    /// @param lastActionTime Start time from which calculations will be started.
    /// @param timePeriod Delay between available call in seconds.
    /// @param pointer The bytes32 pointer value.
    function timeCheckerInitialize(
        uint64 lastActionTime,
        uint64 timePeriod,
        bytes32 pointer
    ) external;

    // =========================
    // Main functions
    // =========================

    /// @notice Check if enough time has elapsed since the last action.
    /// @dev Updates the `lastActionTime` in state if enough time has elapsed.
    /// @param pointer The bytes32 pointer value.
    /// @return A boolean indicating whether enough time has elapsed.
    function checkTime(bytes32 pointer) external returns (bool);

    /// @notice Check if enough time has elapsed since the last action.
    /// @param pointer The bytes32 pointer value.
    /// @return A boolean indicating whether enough time has elapsed.
    function checkTimeView(bytes32 pointer) external view returns (bool);

    // =========================
    // Setters
    // =========================

    /// @dev Sets the time period before checks.
    /// @param timePeriod The time period to set in seconds.
    /// @param pointer The bytes32 pointer value.
    function setTimePeriod(uint64 timePeriod, bytes32 pointer) external;

    // =========================
    // Getters
    // =========================

    /// @notice Retrieves the local time checker storage values.
    /// @param pointer The bytes32 pointer value.
    /// @return lastActionTime The last recorded action time.
    /// @return timePeriod The set time period in seconds.
    /// @return initialized A boolean indicating if the contract has been initialized or not.
    function getLocalTimeCheckerStorage(
        bytes32 pointer
    )
        external
        view
        returns (uint256 lastActionTime, uint256 timePeriod, bool initialized);
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