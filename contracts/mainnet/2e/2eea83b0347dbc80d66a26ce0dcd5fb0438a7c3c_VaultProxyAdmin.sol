// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IUpgradeLogic} from "./vault/interfaces/IUpgradeLogic.sol";

import {IVaultFactory} from "./IVaultFactory.sol";
import {IVaultProxyAdmin} from "./IVaultProxyAdmin.sol";

/// @title VaultProxyAdmin
/// @notice This contract is a common proxy admin for all vaults deployed via factory.
/// @dev Through this contract, all vaults can be updated to a new implementation.
contract VaultProxyAdmin is IVaultProxyAdmin {
    // =========================
    // Storage
    // =========================

    IVaultFactory public immutable vaultFactory;

    constructor(address _vaultFactory) {
        vaultFactory = IVaultFactory(_vaultFactory);
    }

    // =========================
    // Vault implementation logic
    // =========================

    /// @inheritdoc IVaultProxyAdmin
    function initializeImplementation(
        address vault,
        address implementation
    ) external {
        if (msg.sender != address(vaultFactory)) {
            revert VaultProxyAdmin_CallerIsNotFactory();
        }

        IUpgradeLogic(vault).upgrade(implementation);
    }

    /// @inheritdoc IVaultProxyAdmin
    function upgrade(address vault, uint256 version) external {
        if (IUpgradeLogic(vault).owner() != msg.sender) {
            revert VaultProxyAdmin_SenderIsNotVaultOwner();
        }

        if (version > vaultFactory.versions() || version == 0) {
            revert VaultProxyAdmin_VersionDoesNotExist();
        }

        address currentImplementation = IUpgradeLogic(vault).implementation();
        address implementation = vaultFactory.implementation(version);

        if (currentImplementation == implementation) {
            revert VaultProxyAdmin_CannotUpdateToCurrentVersion();
        }

        IUpgradeLogic(vault).upgrade(implementation);
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
pragma solidity 0.8.19;

import {IOwnable} from "./external/IOwnable.sol";

/// @title IVaultFactory - VaultFactory Interface
/// @notice This contract is a vault factory that implements methods for creating new vaults
/// and updating them via the UpgradeLogic contract.
interface IVaultFactory is IOwnable {
    // =========================
    // Storage
    // =========================

    /// @notice The address of the immutable contract to which the `vault` call will be
    /// delegated if the call is made from `ProxyAdmin's` address.
    function upgradeLogic() external view returns (address);

    /// @notice The address from which the call to `vault` will delegate it to the `updateLogic`.
    function vaultProxyAdmin() external view returns (address);

    // =========================
    // Events
    // =========================

    /// @notice Emits when the new `vault` has been created.
    /// @param creator The creator of the created vault
    /// @param vault The address of the created vault
    /// @param vaultId The unique identifier for the vault (for `creator` address)
    event VaultCreated(
        address indexed creator,
        address indexed vault,
        uint16 vaultId
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown if an attempt is made to initialize the contract a second time.
    error VaultFactory_AlreadyInitialized();

    /// @notice Thrown when a `creator` attempts to create a vault using
    /// a version of the implementation that doesn't exist.
    error VaultFactory_VersionDoesNotExist();

    /// @notice Thrown when a `creator` tries to create a vault with an `vaultId`
    /// that's already in use.
    /// @param creator The address which tries to create the vault.
    /// @param vaultId The id that is already used.
    error VaultFactory_IdAlreadyUsed(address creator, uint16 vaultId);

    /// @notice Thrown when a `creator` attempts to create a vault with an vaultId == `0`
    /// or when the `creator` address is the same as the `proxyAdmin`.
    error VaultFactory_InvalidDeployArguments();

    /// @dev Error to be thrown when an unauthorized operation is attempted.
    error VaultFactory_NotAuthorized();

    // =========================
    // Admin methods
    // =========================

    /// @notice Sets the address of the Ditto Bridge Receiver contract.
    /// @dev This function can only be called by an authorized admin.
    /// @param _dittoBridgeReceiver The address of the new Ditto Bridge Receiver contract.
    function setBridgeReceiverContract(address _dittoBridgeReceiver) external;

    // =========================
    // Vault implementation logic
    // =========================

    /// @notice Adds a `newImplemetation` address to the list of implementations.
    /// @param newImplemetation The address of the new implementation to be added.
    ///
    /// @dev Only callable by the owner of the contract.
    /// @dev After adding, the new implementation will be at the last index
    /// (i.e., version is `_implementations.length`).
    function addNewImplementation(address newImplemetation) external;

    /// @notice Retrieves the implementation address for a given `version`.
    /// @param version The version number of the desired implementation.
    /// @return impl_ The address of the specified implementation version.
    ///
    /// @dev If the `version` number is greater than the length of the `_implementations` array
    /// or the array is empty, `VaultFactory_VersionDoesNotExist` error is thrown.
    function implementation(uint256 version) external view returns (address);

    /// @notice Returns the total number of available implementation versions.
    /// @return The total count of versions in the `_implementations` array.
    function versions() external view returns (uint256);

    // =========================
    // Main functions
    // =========================

    /// @notice Computes the address of a `vault` deployed using `deploy` method.
    /// @param creator The address of the creator of the vault.
    /// @param vaultId The id of the vault.
    /// @dev `creator` and `id` are part of the salt for the `create2` opcode.
    function predictDeterministicVaultAddress(
        address creator,
        uint16 vaultId
    ) external view returns (address predicted);

    /// @notice Deploys a new `vault` based on a specified `version`.
    /// @param version The version number of the vault implementation to which
    ///        the new vault will delegate.
    /// @param vaultId A unique identifier for deterministic vault creation.
    ///        Used in combination with `msg.sender` for `create2` salt.
    /// @return The address of the newly deployed `vault`.
    ///
    /// @dev Uses the `create2` opcode for deterministic address generation based on a salt that
    /// combines the `msg.sender` and `vaultId`.
    /// @dev If the given `version` number is greater than the length of  the `_implementations`
    /// array or if the array is empty, it reverts with `VaultFactory_VersionDoesNotExist`.
    /// @dev If `vaultId` is zero, it reverts with`VaultFactory_InvalidDeployArguments`.
    /// @dev If the `vaultId` has already been used for the `msg.sender`, it reverts with
    /// `VaultFactory_IdAlreadyUsed`.
    function deploy(uint256 version, uint16 vaultId) external returns (address);

    function crossChainDeploy(
        address creator,
        uint256 version,
        uint16 vaultId
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IVaultFactory} from "./IVaultFactory.sol";

/// @title IVaultProxyAdmin - VaultProxyAdmin interface.
/// @notice This contract is a common proxy admin for all vaults deployed via factory.
/// @dev Through this contract, all vaults can be updated to a new implementation.
interface IVaultProxyAdmin {
    // =========================
    // Storage
    // =========================

    function vaultFactory() external view returns (IVaultFactory);

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when an anyone other than the address of the factory tries calling the method.
    error VaultProxyAdmin_CallerIsNotFactory();

    /// @notice Thrown when a non-owner of the vault tries to update its implementation.
    error VaultProxyAdmin_SenderIsNotVaultOwner();

    /// @notice Thrown when an `owner` attempts to update a vault using
    /// a version of the implementation that doesn't exist.
    error VaultProxyAdmin_VersionDoesNotExist();

    /// @notice Thrown when there's an attempt to update the vault to its
    /// current implementation address.
    error VaultProxyAdmin_CannotUpdateToCurrentVersion();

    // =========================
    // Vault implementation logic
    // =========================

    /// @notice Sets the `vault` implementation to an address from the factory.
    /// @param vault Address of the vault to be upgraded.
    /// @param implementation The new implementation from the factory.
    /// @dev Can only be called from the vault factory.
    function initializeImplementation(
        address vault,
        address implementation
    ) external;

    /// @notice Updates the `vault` implementation to an address from the factory.
    /// @param vault Address of the vault to be upgraded.
    /// @param version The version number of the new implementation from the `_implementations` array.
    ///
    /// @dev This function can only be called by the owner of the vault.
    /// @dev The version specified should be an existing version in the factory
    /// and must not be the current implementation of the vault.
    /// @dev If the function caller is not the owner of the vault, it reverts with
    /// `VaultProxyAdmin_SenderIsNotVaultOwner`.
    /// @dev If the specified `version` number is outside the valid range of the implementations
    /// or is zero, it reverts with `VaultProxyAdmin_VersionDoesNotExist`.
    /// @dev If the specified version  is the current implementation, it reverts
    /// with `VaultProxyAdmin_CannotUpdateToCurrentVersion`.
    function upgrade(address vault, uint256 version) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IOwnable - Ownable Interface
/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
interface IOwnable {
    // =========================
    // Events
    // =========================

    /// @notice Emits when ownership of the contract is transferred from `previousOwner`
    /// to `newOwner`.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when the caller is not authorized to perform an operation.
    /// @param sender The address of the sender trying to access a restricted function.
    error Ownable_SenderIsNotOwner(address sender);

    /// @notice Thrown when the new owner is not a valid owner account.
    error Ownable_NewOwnerCannotBeAddressZero();

    // =========================
    // Main functions
    // =========================

    /// @notice Returns the address of the current owner.
    /// @return The address of the current owner.
    function owner() external view returns (address);

    /// @notice Leaves the contract without an owner. It will not be possible to call
    /// `onlyOwner` functions anymore.
    /// @dev Can only be called by the current owner.
    function renounceOwnership() external;

    /// @notice Transfers ownership of the contract to a new account (`newOwner`).
    /// @param newOwner The address of the new owner.
    /// @dev Can only be called by the current owner.
    function transferOwnership(address newOwner) external;
}