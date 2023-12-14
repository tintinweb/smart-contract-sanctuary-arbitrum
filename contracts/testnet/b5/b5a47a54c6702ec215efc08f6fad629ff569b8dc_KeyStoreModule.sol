pragma solidity ^0.8.17;

import "../BaseModule.sol";
import "./interfaces/IKeyStoreModule.sol";
import "../../libraries/KeyStoreSlotLib.sol";
import {IKeyStoreProof} from "../../keystore/interfaces/IKeyStoreProof.sol";

contract KeyStoreModule is IKeyStoreModule, BaseModule {
    bytes4 private constant _FUNC_RESET_OWNER = bytes4(keccak256("resetOwner(bytes32)"));
    bytes4 private constant _FUNC_RESET_OWNERS = bytes4(keccak256("resetOwners(bytes32[])"));

    IKeyStoreProof public immutable keyStoreProof;

    mapping(address => bytes32) public l1Slot;
    mapping(address => bytes32) public lastKeyStoreSyncSignKey;

    mapping(address => bool) walletInited;

    constructor(address _keyStoreProof) {
        keyStoreProof = IKeyStoreProof(_keyStoreProof);
    }

    function _deInit() internal override {
        address _sender = sender();
        delete l1Slot[_sender];
        delete lastKeyStoreSyncSignKey[_sender];
        walletInited[_sender] = false;
    }

    function _init(bytes calldata _data) internal override {
        address _sender = sender();
        (bytes32 initialKeyHash, bytes32 initialGuardianHash, uint64 guardianSafePeriod) =
            abi.decode(_data, (bytes32, bytes32, uint64));
        bytes32 walletKeyStoreSlot = KeyStoreSlotLib.getSlot(initialKeyHash, initialGuardianHash, guardianSafePeriod);
        require(walletKeyStoreSlot != bytes32(0), "wallet slot needs to set");
        l1Slot[_sender] = walletKeyStoreSlot;

        bytes32 keystoreSignKey = keyStoreProof.keyStoreBySlot(walletKeyStoreSlot);
        // if keystore already sync, change to keystore signer
        if (keystoreSignKey != bytes32(0)) {
            bytes memory rawOwners = keyStoreProof.rawOwnersBySlot(walletKeyStoreSlot);
            bytes32[] memory owners = abi.decode(rawOwners, (bytes32[]));
            ISoulWallet soulwallet = ISoulWallet(payable(_sender));
            // sync keystore signing key
            soulwallet.resetOwners(owners);
            lastKeyStoreSyncSignKey[_sender] = keystoreSignKey;
            emit KeyStoreSyncd(_sender, keystoreSignKey);
        }
        walletInited[_sender] = true;
        emit KeyStoreInited(_sender, initialKeyHash, initialGuardianHash, guardianSafePeriod);
    }

    function inited(address wallet) internal view override returns (bool) {
        return walletInited[wallet];
    }

    function requiredFunctions() external pure override returns (bytes4[] memory) {
        bytes4[] memory functions = new bytes4[](2);
        functions[0] = _FUNC_RESET_OWNER;
        functions[1] = _FUNC_RESET_OWNERS;
        return functions;
    }

    function syncL1Keystore(address wallet) external override {
        bytes32 slotInfo = l1Slot[wallet];
        require(slotInfo != bytes32(0), "wallet slot not set");
        bytes32 keystoreSignKey = keyStoreProof.keyStoreBySlot(slotInfo);
        require(keystoreSignKey != bytes32(0), "keystore proof not sync");
        bytes32 lastSyncKeyStore = lastKeyStoreSyncSignKey[wallet];
        if (lastSyncKeyStore != bytes32(0) && lastSyncKeyStore == keystoreSignKey) {
            revert("keystore already synced");
        }
        ISoulWallet soulwallet = ISoulWallet(payable(wallet));
        bytes memory rawOwners = keyStoreProof.rawOwnersBySlot(slotInfo);
        bytes32[] memory owners = abi.decode(rawOwners, (bytes32[]));
        soulwallet.resetOwners(owners);
        lastKeyStoreSyncSignKey[wallet] = keystoreSignKey;
        emit KeyStoreSyncd(wallet, keystoreSignKey);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./interfaces/ISoulWalletModule.sol";
import "./../interfaces/ISoulWallet.sol";

/**
 * @title BaseModule
 * @notice An abstract base contract that provides a foundation for other modules.
 * It ensures the initialization, de-initialization, and proper authorization of modules.
 */
abstract contract BaseModule is ISoulWalletModule {
    event ModuleInit(address indexed wallet);
    event ModuleDeInit(address indexed wallet);
    /**
     * @notice Checks if the module is initialized for a particular wallet.
     * @param wallet Address of the wallet.
     * @return True if the module is initialized, false otherwise.
     */

    function inited(address wallet) internal view virtual returns (bool);
    /**
     * @notice Initialization logic for the module.
     * @param data Initialization data for the module.
     */
    function _init(bytes calldata data) internal virtual;
    /**
     * @notice De-initialization logic for the module.
     */
    function _deInit() internal virtual;
    /**
     * @notice Helper function to get the sender of the transaction.
     * @return Address of the transaction sender.
     */

    function sender() internal view returns (address) {
        return msg.sender;
    }
    /**
     * @notice Initializes the module for a wallet.
     * @param data Initialization data for the module.
     */

    function Init(bytes calldata data) external {
        address _sender = sender();
        if (!inited(_sender)) {
            if (!ISoulWallet(_sender).isInstalledModule(address(this))) {
                revert("not authorized module");
            }
            _init(data);
            emit ModuleInit(_sender);
        }
    }
    /**
     * @notice De-initializes the module for a wallet.
     */

    function DeInit() external {
        address _sender = sender();
        if (inited(_sender)) {
            if (ISoulWallet(_sender).isInstalledModule(address(this))) {
                revert("authorized module");
            }
            _deInit();
            emit ModuleDeInit(_sender);
        }
    }
    /**
     * @notice Verifies if the module supports a specific interface.
     * @param interfaceId ID of the interface to be checked.
     * @return True if the module supports the given interface, false otherwise.
     */

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(ISoulWalletModule).interfaceId || interfaceId == type(IModule).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IKeyStoreModule {
    event KeyStoreSyncd(address indexed _wallet, bytes32 indexed _newOwners);
    event KeyStoreInited(
        address indexed _wallet, bytes32 _initialKey, bytes32 initialGuardianHash, uint64 guardianSafePeriod
    );

    function syncL1Keystore(address wallet) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title KeyStoreSlotLib
 * @notice A library to compute a keystore slot based on input parameters
 */
library KeyStoreSlotLib {
    /**
     * @notice Calculates a slot using the initial key hash, initial guardian hash, and guardian safe period
     * @param initialKeyHash The initial key hash used for calculating the slot
     * @param initialGuardianHash The initial guardian hash used for calculating the slot
     * @param guardianSafePeriod The guardian safe period used for calculating the slot
     * @return slot The resulting keystore slot derived from the input parameters
     */
    function getSlot(bytes32 initialKeyHash, bytes32 initialGuardianHash, uint256 guardianSafePeriod)
        internal
        pure
        returns (bytes32 slot)
    {
        return keccak256(abi.encode(initialKeyHash, initialGuardianHash, guardianSafePeriod));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Key Store Proof Interface
 * @dev This interface provides methods to retrieve the keystore signing key hash and raw owners based on a slot.
 */
interface IKeyStoreProof {
    /**
     * @dev Returns the signing key hash associated with a given L1 slot.
     * @param l1Slot The L1 slot
     * @return signingKeyHash The hash of the signing key associated with the L1 slot
     */
    function keyStoreBySlot(bytes32 l1Slot) external view returns (bytes32 signingKeyHash);

    /**
     * @dev Returns the raw owners associated with a given L1 slot.
     * @param l1Slot The L1 slot
     * @return owners The raw owner data associated with the L1 slot
     */
    function rawOwnersBySlot(bytes32 l1Slot) external view returns (bytes memory owners);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
import {IModule} from "@soulwallet-core/contracts/interface/IModule.sol";

interface ISoulWalletModule is IModule {
    function requiredFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISoulWalletHookManager} from "../interfaces/ISoulWalletHookManager.sol";
import {ISoulWalletModuleManager} from "../interfaces/ISoulWalletModuleManager.sol";
import {ISoulWalletOwnerManager} from "../interfaces/ISoulWalletOwnerManager.sol";
import {ISoulWalletOwnerManager} from "../interfaces/ISoulWalletOwnerManager.sol";
import {IUpgradable} from "../interfaces/IUpgradable.sol";
import {IStandardExecutor} from "@soulwallet-core/contracts/interface/IStandardExecutor.sol";

interface ISoulWallet is
    ISoulWalletHookManager,
    ISoulWalletModuleManager,
    ISoulWalletOwnerManager,
    IStandardExecutor,
    IUpgradable
{
    function initialize(
        bytes32[] calldata owners,
        address defalutCallbackHandler,
        bytes[] calldata modules,
        bytes[] calldata hooks
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPluggable} from "./IPluggable.sol";

interface IModule is IPluggable {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IHookManager} from "@soulwallet-core/contracts/interface/IHookManager.sol";
interface ISoulWalletHookManager is IHookManager {
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IModuleManager} from "@soulwallet-core/contracts/interface/IModuleManager.sol";
interface ISoulWalletModuleManager is IModuleManager {
     function installModule(bytes calldata moduleAndData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IOwnerManager} from "@soulwallet-core/contracts/interface/IOwnerManager.sol";
interface ISoulWalletOwnerManager is IOwnerManager {
    function addOwners(bytes32[] calldata owners) external;
    function resetOwners(bytes32[] calldata newOwners) external;
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

interface IOwnable {
    /**
     * @notice Checks if a given bytes32 ID corresponds to an owner within the system
     * @param owner The bytes32 ID to check
     * @return True if the ID corresponds to an owner, false otherwise
     */

    function isOwner(bytes32 owner) external view returns (bool);
}