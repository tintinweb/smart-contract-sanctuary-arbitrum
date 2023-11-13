// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlLib} from "../libraries/AccessControlLib.sol";
import {BaseContract} from "../libraries/BaseContract.sol";

import {IAccessControlLogic} from "../interfaces/IAccessControlLogic.sol";

/// @title AccessControlLogic.
/// @title Logic for managing roles and permissions.
contract AccessControlLogic is IAccessControlLogic, BaseContract {
    // =========================
    // Main functions
    // =========================

    /// @inheritdoc IAccessControlLogic
    function initializeCreatorAndId(address creator, uint16 vaultId) external {
        AccessControlLib.initializeCreatorAndId(creator, vaultId);
    }

    /// @inheritdoc IAccessControlLogic
    function creatorAndId() external view returns (address, uint16) {
        return AccessControlLib.getCreatorAndId();
    }

    /// @inheritdoc IAccessControlLogic
    function owner() external view returns (address) {
        return AccessControlLib.getOwner();
    }

    /// @inheritdoc IAccessControlLogic
    function getVaultProxyAdminAddress()
        external
        view
        returns (address proxyAdminAddress)
    {
        bytes memory bytecode = address(this).code;

        assembly ("memory-safe") {
            proxyAdminAddress := mload(add(bytecode, 32))
        }
    }

    /// @inheritdoc IAccessControlLogic
    function transferOwnership(address newOwner) external onlyOwner {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        address oldOwner;
        if (!s.useOwner) {
            s.useOwner = true;
            oldOwner = s.creator;
        } else {
            oldOwner = s.owner;
        }

        s.owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @inheritdoc IAccessControlLogic
    function setCrossChainLogicInactiveStatus(
        bool newValue
    ) external onlyOwnerOrVaultItself {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        s.crossChainLogicInactive = newValue;

        emit CrossChainLogicInactiveFlagSet(newValue);
    }

    /// @inheritdoc IAccessControlLogic
    function crossChainLogicIsActive() external view returns (bool) {
        return AccessControlLib.crossChainLogicIsActive();
    }

    /// @inheritdoc IAccessControlLogic
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();
        return _hasRole(s, role, account);
    }

    /// @inheritdoc IAccessControlLogic
    function grantRole(
        bytes32 role,
        address account
    ) external onlyOwnerOrVaultItself {
        _grantRole(role, account);
    }

    /// @inheritdoc IAccessControlLogic
    function revokeRole(bytes32 role, address account) external onlyOwner {
        _revokeRole(role, account);
    }

    /// @inheritdoc IAccessControlLogic
    function renounceRole(bytes32 role) external {
        _revokeRole(role, msg.sender);
    }

    // =========================
    // Private functions
    // =========================

    /// @dev Grants a `role` to an `account` internally.
    /// @param role Role identifier to grant.
    /// @param account Address of the account to grant the role to.
    function _grantRole(bytes32 role, address account) private {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();
        if (!_hasRole(s, role, account)) {
            s.roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /// @dev Revokes a `role` from an `account` internally.
    /// @param role Role identifier to revoke.
    /// @param account Address of the account to revoke the role from.
    function _revokeRole(bytes32 role, address account) private {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();
        if (_hasRole(s, role, account)) {
            s.roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
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

/// @title Constants
/// @dev These constants can be imported and used by other contracts for consistency.
library Constants {
    /// @dev A keccak256 hash representing the executor role.
    bytes32 internal constant EXECUTOR_ROLE =
        keccak256("DITTO_WORKFLOW_EXECUTOR_ROLE");

    /// @dev A constant representing the native token in any network.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}