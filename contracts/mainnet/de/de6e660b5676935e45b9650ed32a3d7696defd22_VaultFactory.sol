// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "./external/Ownable.sol";

import {IAccessControlLogic} from "./vault/interfaces/IAccessControlLogic.sol";
import {IVaultProxyAdmin} from "./IVaultProxyAdmin.sol";

import {IVaultFactory} from "./IVaultFactory.sol";

/// @title VaultFactory
/// @notice This contract is a vault factory that implements methods for creating new vaults
/// and updating them via the UpgradeLogic contract.
contract VaultFactory is IVaultFactory, Ownable {
    // =========================
    // Storage
    // =========================

    /// @inheritdoc IVaultFactory
    address public immutable upgradeLogic;

    /// @inheritdoc IVaultFactory
    address public immutable vaultProxyAdmin;

    /// @dev Array of `Vault` implementations to which
    /// the vault-proxy can delegate to.
    address[] private _implementations;

    /// @dev Indicates that the contract has been initialized.
    bool private _initialized;

    /// @dev Bridge receiver address
    address private dittoBridgeReceiver;

    // =========================
    // Initializer
    // =========================

    /// @dev Blocks any actions with the original implementation by setting
    /// the `_initialized` flag.
    /// @param _upgradeLogic The address of the `UpgradeLogic` contract.
    constructor(address _upgradeLogic, address _vaultProxyAdmin) {
        // set the address of the UpgradeLogic contract during deployment
        upgradeLogic = _upgradeLogic;
        vaultProxyAdmin = _vaultProxyAdmin;
    }

    /// @notice Initializing VaultFactory as a transparent upgradeable proxy.
    /// @dev Sets the owner of the factory as msg.sender.
    /// @dev If vaultFactory is already initialized - throws `VaultFactory_AlreadyInitialized` error.
    function initialize(address newOwner) external {
        // if vaultFactory is already initialized -> revert
        if (_initialized) {
            revert VaultFactory_AlreadyInitialized();
        }
        _initialized = true;

        // set the owner of the factory contract.
        _transferOwnership(newOwner);
    }

    // =========================
    // Admin methods
    // =========================

    /// @inheritdoc IVaultFactory
    function setBridgeReceiverContract(
        address _dittoBridgeReceiver
    ) external onlyOwner {
        dittoBridgeReceiver = _dittoBridgeReceiver;
    }

    // =========================
    // Vault implementation logic
    // =========================

    /// @inheritdoc IVaultFactory
    function addNewImplementation(address newImplemetation) external onlyOwner {
        _implementations.push(newImplemetation);
    }

    /// @inheritdoc IVaultFactory
    function implementation(
        uint256 version
    ) external view returns (address impl_) {
        _validateVersion(version);

        impl_ = _implementations[version - 1];
    }

    /// @inheritdoc IVaultFactory
    function versions() external view returns (uint256 versions_) {
        versions_ = _implementations.length;
    }

    // =========================
    // Main functions
    // =========================

    /// @inheritdoc IVaultFactory
    function predictDeterministicVaultAddress(
        address creator,
        uint16 vaultId
    ) external view returns (address predicted) {
        bytes memory initcode = _getVaultInitcode();
        bytes32 initcodeHash;
        bytes32 salt;

        assembly ("memory-safe") {
            // compute the hash of the initcode
            initcodeHash := keccak256(add(initcode, 32), mload(initcode))

            // compute the salt
            mstore(0, creator)
            mstore(32, vaultId)
            salt := keccak256(0, 64)

            // rewrite memory -> future allocation will be from beginning of the memory
            mstore(64, 128)
        }

        // compute the address of the vault proxy
        bytes32 _predicted = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, initcodeHash)
        );

        assembly ("memory-safe") {
            // casting bytes32 value to address size (20 bytes)
            predicted := _predicted
        }
    }

    /// @inheritdoc IVaultFactory
    function deploy(
        uint256 version,
        uint16 vaultId
    ) external returns (address) {
        return _deploy(msg.sender, version, vaultId);
    }

    /// @inheritdoc IVaultFactory
    function crossChainDeploy(
        address creator,
        uint256 version,
        uint16 vaultId
    ) external returns (address) {
        if (msg.sender != dittoBridgeReceiver) {
            revert VaultFactory_NotAuthorized();
        }

        return _deploy(creator, version, vaultId);
    }

    // =========================
    // Private functions
    // =========================

    function _deploy(
        address creator,
        uint256 version,
        uint16 vaultId
    ) private returns (address) {
        if (vaultId == 0) {
            revert VaultFactory_InvalidDeployArguments();
        }

        uint256 latestVersion = _validateVersion(version);

        // if `version` == 0, the latest version of vault is deployed
        if (version == 0) {
            version = latestVersion;
        }

        // The following section of code is used to create a new contract instance using create2 opcode.
        bytes memory vaultInitcode = _getVaultInitcode();

        address vault;

        assembly ("memory-safe") {
            // salt = keccak256(creator, vaultId)
            mstore(0, creator)
            mstore(32, vaultId)

            vault := create2(
                0,
                add(vaultInitcode, 32),
                mload(vaultInitcode),
                keccak256(0, 64)
            )
        }

        // create2 success check:
        // if the newly created `vault` has codesize == 0 ->
        // salt has already been used -> revert
        if (vault.code.length == 0) {
            revert VaultFactory_IdAlreadyUsed(creator, vaultId);
        }

        // stores the address of the `implementation` contract in the `vault` proxy
        IVaultProxyAdmin(vaultProxyAdmin).initializeImplementation(
            vault,
            _implementations[version - 1]
        );

        // sets the `creator` as the first `vault` owner and stores immutable `vaultId`
        IAccessControlLogic(vault).initializeCreatorAndId(creator, vaultId);

        emit VaultCreated(creator, vault, vaultId);

        return vault;
    }

    /// @dev Helper function to validate the `version`.
    function _validateVersion(
        uint256 version
    ) private view returns (uint256 latestVersion) {
        latestVersion = _implementations.length;

        // if the `version` number is greater than the length of the `_implementations` array
        // or the array is empty -> revert
        if (version > latestVersion || latestVersion == 0) {
            revert VaultFactory_VersionDoesNotExist();
        }
    }

    /// @dev Helper function to get the initcode of the vault proxy.
    function _getVaultInitcode() private view returns (bytes memory bytecode) {
        // playground:
        // https://www.evm.codes/playground?fork=shanghai&unit=Wei&callData=0x12345678&codeType=Mnemonic&code='zconstructor_zy00Fy50Fqzy0bFh4FCODEgzX1Fp~Fruntime_y00~.qkKgqq.kERjw~EQ~y2alI~qNOT~SLOAD~y40lfj11223344556677889900f~GAS~DELEGATEk*vh3~qpKgX1*vX2~y4elI~REVERTf*'~%5Cnz%2F%2F%20y-1B00998877665544332211vKSIZE~qh1*RETURNl~JUMPkCALLj~-20BhDUPgCOPY~flDEST_%20code~XSWAPKDATAF~zB%200xw.kvh2~-PUSH*~p%01*-.BFKX_fghjklpqvwyz~_
        //------------------------------------------------------------------------------//
        // Opcode  | Opcode + Arguments | Description    | Stack View                   //
        //------------------------------------------------------------------------------//
        // constructor code:                                                            //
        // 0x60    | 0x60 0x00          | PUSH1 0        | 0                            //
        // 0x60    | 0x60 0x50          | PUSH1 80       | 80 0                         //
        // 0x80    | 0x80               | DUP1           | 80 80 0                      //
        // 0x60    | 0x60 0x0b          | PUSH1 11       | 11 80 80 0                   //
        // 0x83    | 0x83               | DUP4           | 0 11 80 80 0                 //
        // 0x39    | 0x39               | CODECOPY       | 80 0                         //
        // 0x90    | 0x90               | SWAP1          | 0 80                         //
        // 0xf3    | 0xf3               | RETURN         |                              //
        //------------------------------------------------------------------------------//
        // deployed code (if caller != vaultProxyAdmin)                                 //
        // 0x60    | 0x60 0x00          | PUSH1 0        | 0                            //
        // 0x36    | 0x36               | CALLDATASIZE   | csize 0                      //
        // 0x81    | 0x81               | DUP2           | 0 csize 0                    //
        // 0x80    | 0x80               | DUP1           | 0 0 csize 0                  //
        // 0x37    | 0x37               | CALLDATACOPY   | 0                            //
        // 0x80    | 0x80               | DUP1           | 0 0                          //
        // 0x80    | 0x80               | DUP1           | 0 0 0                        //
        // 0x36    | 0x36               | CALLDATASIZE   | csize 0 0 0                  //
        // 0x81    | 0x81               | DUP2           | 0 csize 0 0 0                //
        // 0x33    | 0x33               | CALLER         | caller 0 csize 0 0 0         //
        // 0x73    | 0x73 proxyAdmin    | PUSH20 pAdmin  | pAdmin caller 0 csize 0 0 0  //
        // 0x14    | 0x14               | EQ             | false 0 csize 0 0 0          //
        // 0x60    | 0x60 0x2a          | PUSH1 42       | 42 false 0 csize 0 0 0       //
        // 0x57    | 0x57               | JUMPI          | 0 csize 0 0 0                //
        // 0x80    | 0x80               | DUP1           | 0 0 csize 0 0 0              //
        // 0x19    | 0x19               | NOT            | 0xffff..ffff 0 csize 0 0 0   //
        // 0x54    | 0x54               | SLOAD          | impl 0 csize 0 0 0           //
        // 0x60    | 0x60 0x40          | PUSH1 64       | 64 impl 0 csize 0 0 0        //
        // 0x56    | 0x56               | JUMP           | impl 0 csize 0 0 0           //
        // 0x5b    | 0x5b               | JUMPDEST       | impl 0 csize 0 0 0           //
        // 0x5a    | 0x5a               | GAS            | gas impl 0 csize 0 0 0       //
        // 0xf4    | 0xf4               | DELEGATECALL   | success 0                    //
        // 0x3d    | 0x3d               | RETURNDATASIZE | rsize success 0              //
        // 0x82    | 0x82               | DUP3           | 0 rsize success 0            //
        // 0x80    | 0x80               | DUP1           | 0 0 rsize success 0          //
        // 0x3e    | 0x3e               | RETURNDATACOPY | success 0                    //
        // 0x90    | 0x90               | SWAP1          | 0 success                    //
        // 0x3d    | 0x3d               | RETURNDATASIZE | rsize 0 success              //
        // 0x91    | 0x91               | SWAP2          | success 0 rsize              //
        // 0x60    | 0x60 0x4e          | PUSH1 78       | 78 success 0 rsize           //
        // 0x57    | 0x57               | JUMPI          | 0 rsize                      //
        // 0x5b    | 0x5b               | JUMPDEST       | 0 rsize                      //
        // 0xf3    | 0xf3               | RETURN         |                              //
        //------------------------------------------------------------------------------//

        // constructor returns runtime code
        //
        // runtime code:
        //   validate caller:
        //     1. If the caller is anyone other than `proxyAdmin` -> delegates call to`vaultImplementation`.
        //     2. If the caller is the `proxyAdmin` -> delegates call to `upgradeLogic`.
        return
            abi.encodePacked(
                hex"6000_6050_80_600b_83_39_90_f3_6000_36_81_80_37_80_80_36_81_33_73",
                vaultProxyAdmin,
                hex"14_602a_57_80_19_54_6040_56_5b_73",
                upgradeLogic,
                hex"5b_5a_f4_3d_82_80_3e_3d_82_82_604e_57_fd_5b_f3"
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IOwnable} from "./IOwnable.sol";

/// @title Ownable
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
abstract contract Ownable is IOwnable {
    // =========================
    // Storage
    // =========================

    /// @dev Private variable to store the owner's address.
    address private _owner;

    // =========================
    // Main functions
    // =========================

    /// @notice Initializes the contract, setting the deployer as the initial owner.
    constructor() {
        _transferOwnership(msg.sender);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /// @inheritdoc IOwnable
    function owner() external view returns (address) {
        return _owner;
    }

    /// @inheritdoc IOwnable
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    /// @inheritdoc IOwnable
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert Ownable_NewOwnerCannotBeAddressZero();
        }

        _transferOwnership(newOwner);
    }

    // =========================
    // Internal functions
    // =========================

    /// @dev Internal function to verify if the caller is the owner of the contract.
    /// Errors:
    /// - Thrown `Ownable_SenderIsNotOwner` if the caller is not the owner.
    function _checkOwner() internal view {
        if (_owner != msg.sender) {
            revert Ownable_SenderIsNotOwner(msg.sender);
        }
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// @dev Emits an {OwnershipTransferred} event.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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