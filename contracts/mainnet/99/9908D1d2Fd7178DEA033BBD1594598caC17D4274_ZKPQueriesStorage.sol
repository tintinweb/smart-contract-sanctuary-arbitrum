// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface ICircuitValidator {
    function verify(
        uint256[] memory inputs,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        bytes calldata data
    ) external view;

    function getSupportedCircuitIds() external view returns (string[] memory ids);

    function inputIndexOf(string memory name) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

uint256 constant MAX_SMT_DEPTH = 64;

interface IState {
    /**
     * @dev Struct for public interfaces to represent a state information.
     * @param id An identity.
     * @param state A state.
     * @param replacedByState A state, which replaced this state for the identity.
     * @param createdAtTimestamp A time when the state was created.
     * @param replacedAtTimestamp A time when the state was replaced by the next identity state.
     * @param createdAtBlock A block number when the state was created.
     * @param replacedAtBlock A block number when the state was replaced by the next identity state.
     */
    struct StateInfo {
        uint256 id;
        uint256 state;
        uint256 replacedByState;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct for public interfaces to represent GIST root information.
     * @param root This GIST root.
     * @param replacedByRoot A root, which replaced this root.
     * @param createdAtTimestamp A time, when the root was saved to blockchain.
     * @param replacedAtTimestamp A time, when the root was replaced by the next root in blockchain.
     * @param createdAtBlock A number of block, when the root was saved to blockchain.
     * @param replacedAtBlock A number of block, when the root was replaced by the next root in blockchain.
     */
    struct GistRootInfo {
        uint256 root;
        uint256 replacedByRoot;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct for public interfaces to represent GIST proof information.
     * @param root This GIST root.
     * @param existence A flag, which shows if the leaf index exists in the GIST.
     * @param siblings An array of GIST sibling node hashes.
     * @param index An index of the leaf in the GIST.
     * @param value A value of the leaf in the GIST.
     * @param auxExistence A flag, which shows if the auxiliary leaf exists in the GIST.
     * @param auxIndex An index of the auxiliary leaf in the GIST.
     * @param auxValue An value of the auxiliary leaf in the GIST.
     */
    struct GistProof {
        uint256 root;
        bool existence;
        uint256[MAX_SMT_DEPTH] siblings;
        uint256 index;
        uint256 value;
        bool auxExistence;
        uint256 auxIndex;
        uint256 auxValue;
    }

    /**
     * @dev Retrieve last state information of specific id.
     * @param id An identity.
     * @return The state info.
     */
    function getStateInfoById(uint256 id) external view returns (StateInfo memory);

    /**
     * @dev Retrieve state information by id and state.
     * @param id An identity.
     * @param state A state.
     * @return The state info.
     */
    function getStateInfoByIdAndState(
        uint256 id,
        uint256 state
    ) external view returns (StateInfo memory);

    /**
     * @dev Retrieve the specific GIST root information.
     * @param root GIST root.
     * @return The GIST root info.
     */
    function getGISTRootInfo(uint256 root) external view returns (GistRootInfo memory);

    /**
     * @dev Get defaultIdType
     * @return defaultIdType
     */
    function getDefaultIdType() external view returns (bytes2);

    /**
     * @dev Performs state transition
     * @param id Identifier of the identity
     * @param oldState Previous state of the identity
     * @param newState New state of the identity
     * @param isOldStateGenesis Flag if previous identity state is genesis
     * @param a Proof.A
     * @param b Proof.B
     * @param c Proof.C
     */
    function transitState(
        uint256 id,
        uint256 oldState,
        uint256 newState,
        bool isOldStateGenesis,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) external;

    /**
     * @dev Performs state transition
     * @param id Identity
     * @param oldState Previous identity state
     * @param newState New identity state
     * @param isOldStateGenesis Is the previous state genesis?
     * @param methodId State transition method id
     * @param methodParams State transition method-specific params
     */
    function transitStateGeneric(
        uint256 id,
        uint256 oldState,
        uint256 newState,
        bool isOldStateGenesis,
        uint256 methodId,
        bytes calldata methodParams
    ) external;

    /**
     * @dev Check if identity exists.
     * @param id Identity
     * @return True if the identity exists
     */
    function idExists(uint256 id) external view returns (bool);

    /**
     * @dev Check if state exists.
     * @param id Identity
     * @param state State
     * @return True if the state exists
     */
    function stateExists(uint256 id, uint256 state) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

library PoseidonUnit1L {
    function poseidon(uint256[1] calldata) public pure returns (uint256) {}
}

library PoseidonUnit2L {
    function poseidon(uint256[2] calldata) public pure returns (uint256) {}
}

library PoseidonUnit3L {
    function poseidon(uint256[3] calldata) public pure returns (uint256) {}
}

library PoseidonUnit4L {
    function poseidon(uint256[4] calldata) public pure returns (uint256) {}
}

library PoseidonUnit5L {
    function poseidon(uint256[5] calldata) public pure returns (uint256) {}
}

library PoseidonUnit6L {
    function poseidon(uint256[6] calldata) public pure returns (uint256) {}
}

library SpongePoseidon {
    uint32 internal constant BATCH_SIZE = 6;

    function hash(uint256[] calldata values) public pure returns (uint256) {
        uint256[BATCH_SIZE] memory frame = [uint256(0), 0, 0, 0, 0, 0];
        bool dirty = false;
        uint256 fullHash = 0;
        uint32 k = 0;
        for (uint32 i = 0; i < values.length; i++) {
            dirty = true;
            frame[k] = values[i];
            if (k == BATCH_SIZE - 1) {
                fullHash = PoseidonUnit6L.poseidon(frame);
                dirty = false;
                frame = [uint256(0), 0, 0, 0, 0, 0];
                frame[0] = fullHash;
                k = 1;
            } else {
                k++;
            }
        }
        if (dirty) {
            // we haven't hashed something in the main sponge loop and need to do hash here
            fullHash = PoseidonUnit6L.poseidon(frame);
        }
        return fullHash;
    }
}

library PoseidonFacade {
    function poseidon1(uint256[1] calldata el) public pure returns (uint256) {
        return PoseidonUnit1L.poseidon(el);
    }

    function poseidon2(uint256[2] calldata el) public pure returns (uint256) {
        return PoseidonUnit2L.poseidon(el);
    }

    function poseidon3(uint256[3] calldata el) public pure returns (uint256) {
        return PoseidonUnit3L.poseidon(el);
    }

    function poseidon4(uint256[4] calldata el) public pure returns (uint256) {
        return PoseidonUnit4L.poseidon(el);
    }

    function poseidon5(uint256[5] calldata el) public pure returns (uint256) {
        return PoseidonUnit5L.poseidon(el);
    }

    function poseidon6(uint256[6] calldata el) public pure returns (uint256) {
        return PoseidonUnit6L.poseidon(el);
    }

    function poseidonSponge(uint256[] calldata el) public pure returns (uint256) {
        return SpongePoseidon.hash(el);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import {Initializable} from "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import {Initializable} from "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice The string extension to Openzeppelin sets
 *
 * ## Usage example:
 *
 * ```
 * using StringSet for StringSet.Set;
 *
 * StringSet.Set internal set;
 * ```
 */
library StringSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     * @notice The function add value to set
     * @param set the set object
     * @param value_ the value to add
     */
    function add(Set storage set, string memory value_) internal returns (bool) {
        if (!contains(set, value_)) {
            set._values.push(value_);
            set._indexes[value_] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function remove value to set
     * @param set the set object
     * @param value_ the value to remove
     */
    function remove(Set storage set, string memory value_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[value_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                string memory lastValue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastValue_;
                set._indexes[lastValue_] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[value_];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function returns true if value in the set
     * @param set the set object
     * @param value_ the value to search in set
     * @return true if value is in the set, false otherwise
     */
    function contains(Set storage set, string memory value_) internal view returns (bool) {
        return set._indexes[value_] != 0;
    }

    /**
     * @notice The function returns length of set
     * @param set the set object
     * @return the the number of elements in the set
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @notice The function returns value from set by index
     * @param set the set object
     * @param index_ the index of slot in set
     * @return the value at index
     */
    function at(Set storage set, uint256 index_) internal view returns (string memory) {
        return set._values[index_];
    }

    /**
     * @notice The function that returns values the set stores, can be very expensive to call
     * @param set the set object
     * @return the memory array of values
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice This library simplifies non-obvious type castings.
 *
 * Conversions from static to dynamic arrays, singleton arrays, and arrays of different types are supported.
 */
library TypeCaster {
    /**
     * @notice The function that casts the bytes32 array to the uint256 array
     * @param from_ the bytes32 array
     * @return array_ the uint256 array
     */
    function asUint256Array(
        bytes32[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the address array to the uint256 array
     */
    function asUint256Array(
        address[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the bytes32 array to the address array
     * @param from_ the bytes32 array
     * @return array_ the list of addresses
     */
    function asAddressArray(
        bytes32[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the uint256 array to the address array
     */
    function asAddressArray(
        uint256[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the uint256 array to the bytes32 array
     * @param from_ the bytes32 array
     * @return array_ the list of addresses
     */
    function asBytes32Array(
        uint256[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the address array to the bytes32 array
     */
    function asBytes32Array(
        address[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function to transform a uint256 element into an array
     * @param from_ the element
     * @return array_ the element as an array
     */
    function asSingletonArray(uint256 from_) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform an address element into an array
     */
    function asSingletonArray(address from_) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform a bool element into an array
     */
    function asSingletonArray(bool from_) internal pure returns (bool[] memory array_) {
        array_ = new bool[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform a string element into an array
     */
    function asSingletonArray(string memory from_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to transform a bytes32 element into an array
     */
    function asSingletonArray(bytes32 from_) internal pure returns (bytes32[] memory array_) {
        array_ = new bytes32[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to convert static uint256[1] array to dynamic
     * @param static_ the static array to convert
     * @return dynamic_ the converted dynamic array
     */
    function asDynamic(
        uint256[1] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static uint256[2] array to dynamic
     */
    function asDynamic(
        uint256[2] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static uint256[3] array to dynamic
     */
    function asDynamic(
        uint256[3] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static uint256[4] array to dynamic
     */
    function asDynamic(
        uint256[4] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static uint256[5] array to dynamic
     */
    function asDynamic(
        uint256[5] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static address[1] array to dynamic
     */
    function asDynamic(
        address[1] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static address[2] array to dynamic
     */
    function asDynamic(
        address[2] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static address[3] array to dynamic
     */
    function asDynamic(
        address[3] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static address[4] array to dynamic
     */
    function asDynamic(
        address[4] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static address[5] array to dynamic
     */
    function asDynamic(
        address[5] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static bool[1] array to dynamic
     */
    function asDynamic(bool[1] memory static_) internal pure returns (bool[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static bool[2] array to dynamic
     */
    function asDynamic(bool[2] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static bool[3] array to dynamic
     */
    function asDynamic(bool[3] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static bool[4] array to dynamic
     */
    function asDynamic(bool[4] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static bool[5] array to dynamic
     */
    function asDynamic(bool[5] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static string[1] array to dynamic
     */
    function asDynamic(string[1] memory static_) internal pure returns (string[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static string[2] array to dynamic
     */
    function asDynamic(string[2] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static string[3] array to dynamic
     */
    function asDynamic(string[3] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static string[4] array to dynamic
     */
    function asDynamic(string[4] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static string[5] array to dynamic
     */
    function asDynamic(string[5] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice The function to convert static bytes32[1] array to dynamic
     */
    function asDynamic(
        bytes32[1] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    /**
     * @notice The function to convert static bytes32[2] array to dynamic
     */
    function asDynamic(
        bytes32[2] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    /**
     * @notice The function to convert static bytes32[3] array to dynamic
     */
    function asDynamic(
        bytes32[3] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    /**
     * @notice The function to convert static bytes32[4] array to dynamic
     */
    function asDynamic(
        bytes32[4] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    /**
     * @notice The function to convert static bytes32[5] array to dynamic
     */
    function asDynamic(
        bytes32[5] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    /**
     * @notice private function to copy memory
     */
    function _copy(uint256 locationS_, uint256 locationD_, uint256 length_) private pure {
        assembly {
            for {
                let i := 0
            } lt(i, length_) {
                i := add(i, 1)
            } {
                locationD_ := add(locationD_, 0x20)

                mstore(locationD_, mload(locationS_))

                locationS_ := add(locationS_, 0x20)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {StringSet} from "@solarity/solidity-lib/libs/data-structures/StringSet.sol";
import {TypeCaster} from "@solarity/solidity-lib/libs/utils/TypeCaster.sol";

import {ICircuitValidator} from "@iden3/contracts/interfaces/ICircuitValidator.sol";
import {PoseidonFacade} from "@iden3/contracts/lib/Poseidon.sol";

import {ILightweightState} from "../interfaces/iden3/ILightweightState.sol";
import {IZKPQueriesStorage} from "../interfaces/iden3/IZKPQueriesStorage.sol";

/**
 * @dev This contract is a copy of the ZKPQueriesStorage contract from Rarimo [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).
 */
contract ZKPQueriesStorage is IZKPQueriesStorage, OwnableUpgradeable, UUPSUpgradeable {
    using StringSet for StringSet.Set;
    using TypeCaster for uint256;

    ILightweightState public override lightweightState;

    mapping(string => QueryInfo) internal _queriesInfo;

    StringSet.Set internal _supportedQueryIds;

    constructor() {
        _disableInitializers();
    }

    function __ZKPQueriesStorage_init(address lightweightStateAddr_) external initializer {
        __Ownable_init();

        require(
            lightweightStateAddr_ != address(0),
            "ZKPQueriesStorage: Zero lightweightState address."
        );

        lightweightState = ILightweightState(lightweightStateAddr_);
    }

    function setZKPQuery(
        string memory queryId_,
        QueryInfo memory queryInfo_
    ) external override onlyOwner {
        require(
            address(queryInfo_.queryValidator) != address(0),
            "ZKPQueriesStorage: Zero queryValidator address."
        );

        _queriesInfo[queryId_] = queryInfo_;

        _supportedQueryIds.add(queryId_);

        emit ZKPQuerySet(queryId_, address(queryInfo_.queryValidator), queryInfo_.circuitQuery);
    }

    function removeZKPQuery(string memory queryId_) external override onlyOwner {
        require(isQueryExists(queryId_), "ZKPQueriesStorage: ZKP Query does not exist.");

        _supportedQueryIds.remove(queryId_);

        delete _queriesInfo[queryId_];

        emit ZKPQueryRemoved(queryId_);
    }

    function getSupportedQueryIDs() external view override returns (string[] memory) {
        return _supportedQueryIds.values();
    }

    function getQueryInfo(
        string memory queryId_
    ) external view override returns (QueryInfo memory) {
        return _queriesInfo[queryId_];
    }

    function getQueryValidator(string memory queryId_) external view override returns (address) {
        return _queriesInfo[queryId_].queryValidator;
    }

    function getStoredCircuitQuery(
        string memory queryId_
    ) external view override returns (CircuitQuery memory) {
        return _queriesInfo[queryId_].circuitQuery;
    }

    function getStoredQueryHash(string memory queryId_) external view override returns (uint256) {
        return getQueryHash(_queriesInfo[queryId_].circuitQuery);
    }

    function getStoredSchema(string memory queryId_) external view override returns (uint256) {
        return _queriesInfo[queryId_].circuitQuery.schema;
    }

    function isQueryExists(string memory queryId_) public view override returns (bool) {
        return _supportedQueryIds.contains(queryId_);
    }

    function getQueryHash(
        CircuitQuery memory circuitQuery_
    ) public pure override returns (uint256) {
        return
            getQueryHashRaw(
                circuitQuery_.schema,
                circuitQuery_.slotIndex,
                circuitQuery_.operator,
                circuitQuery_.claimPathKey,
                circuitQuery_.claimPathNotExists,
                circuitQuery_.values
            );
    }

    function getQueryHashRaw(
        uint256 schema_,
        uint256 slotIndex_,
        uint256 operator_,
        uint256 claimPathKey_,
        uint256 claimPathNotExists_,
        uint256[] memory values_
    ) public pure override returns (uint256) {
        uint256 valueHash_ = PoseidonFacade.poseidonSponge(values_);

        return
            PoseidonFacade.poseidon6(
                [schema_, slotIndex_, operator_, claimPathKey_, claimPathNotExists_, valueHash_]
            );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IState} from "@iden3/contracts/interfaces/IState.sol";

/**
 * @dev This contract is a copy of the ILightweightState contract from Rarimo [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).
 */
interface ILightweightState {
    enum MethodId {
        None,
        AuthorizeUpgrade,
        ChangeSourceStateContract
    }

    struct GistRootData {
        uint256 root;
        uint256 createdAtTimestamp;
    }

    struct IdentitiesStatesRootData {
        bytes32 root;
        uint256 setTimestamp;
    }

    struct StatesMerkleData {
        uint256 issuerId;
        uint256 issuerState;
        uint256 createdAtTimestamp;
        bytes32[] merkleProof;
    }

    event SignedStateTransited(uint256 newGistRoot, bytes32 newIdentitesStatesRoot);

    function changeSourceStateContract(
        address newSourceStateContract_,
        bytes calldata signature_
    ) external;

    function changeSigner(bytes calldata newSignerPubKey_, bytes calldata signature_) external;

    function signedTransitState(
        bytes32 newIdentitiesStatesRoot_,
        GistRootData calldata gistData_,
        bytes calldata proof_
    ) external;

    function sourceStateContract() external view returns (address);

    function sourceChainName() external view returns (string memory);

    function identitiesStatesRoot() external view returns (bytes32);

    function isIdentitiesStatesRootExists(bytes32 root_) external view returns (bool);

    function getIdentitiesStatesRootData(
        bytes32 root_
    ) external view returns (IdentitiesStatesRootData memory);

    function getGISTRoot() external view returns (uint256);

    function getCurrentGISTRootInfo() external view returns (GistRootData memory);

    function geGISTRootData(uint256 root_) external view returns (GistRootData memory);

    function verifyStatesMerkleData(
        StatesMerkleData calldata statesMerkleData_
    ) external view returns (bool, bytes32);
}

// This contract is a copy of the IZKPQueriesStorage contract from Rarimo
// [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ILightweightState} from "./ILightweightState.sol";

/**
 * @title IZKPQueriesStorage
 * @notice The IZKPQueriesStorage interface represents a contract that is responsible for storing and managing zero-knowledge proof (ZKP) queries.
 * It provides functions to set, retrieve, and remove ZKP queries from the storage.
 */
interface IZKPQueriesStorage {
    struct CircuitQuery {
        uint256 schema;
        uint8 slotIndex;
        uint8 operator;
        uint256 claimPathKey;
        uint256 claimPathNotExists;
        uint256[] values;
    }

    /**
     * @notice Contains the query information, including the circuit query and query validator
     * @param circuitQuery The circuit query
     * @param queryValidator The query validator
     * @param circuitId The circuit ID
     */
    struct QueryInfo {
        CircuitQuery circuitQuery;
        address queryValidator;
        string circuitId;
    }

    /**
     * @notice Event emitted when a ZKP query is set
     * @param queryId The ID of the query
     * @param queryValidator The address of the query validator
     * @param newCircuitQuery The new circuit query
     */
    event ZKPQuerySet(
        string indexed queryId,
        address queryValidator,
        CircuitQuery newCircuitQuery
    );

    /**
     * @notice Event emitted when a ZKP query is removed
     * @param queryId The ID of the query
     */
    event ZKPQueryRemoved(string indexed queryId);

    /**
     * @notice Function that set a ZKP query with the provided query ID and query information
     * @param queryId_ The query ID
     * @param queryInfo_ The query information
     */
    function setZKPQuery(string memory queryId_, QueryInfo memory queryInfo_) external;

    /**
     * @notice Function that remove a ZKP query with the specified query ID
     * @param queryId_ The query ID
     */
    function removeZKPQuery(string memory queryId_) external;

    function lightweightState() external view returns (ILightweightState);

    /**
     * @notice Function to get the supported query IDs
     * @return The array of supported query IDs
     */
    function getSupportedQueryIDs() external view returns (string[] memory);

    /**
     * @notice Function to get the query information for a given query ID
     * @param queryId_ The query ID
     * @return The QueryInfo structure with query information
     */
    function getQueryInfo(string memory queryId_) external view returns (QueryInfo memory);

    /**
     * @notice Function to get the query validator for a given query ID
     * @param queryId_ The query ID
     * @return The query validator contract address
     */
    function getQueryValidator(string memory queryId_) external view returns (address);

    /**
     * @notice Function to get the stored circuit query for a given query ID
     * @param queryId_ The query ID
     * @return The stored CircuitQuery structure
     */
    function getStoredCircuitQuery(
        string memory queryId_
    ) external view returns (CircuitQuery memory);

    /**
     * @notice Function to get the stored query hash for a given query ID
     * @param queryId_ The query ID
     * @return The stored query hash
     */
    function getStoredQueryHash(string memory queryId_) external view returns (uint256);

    /**
     * @notice Function to get the stored schema for a given query ID
     * @param queryId_ The query ID
     * @return The stored schema id
     */
    function getStoredSchema(string memory queryId_) external view returns (uint256);

    /**
     * @notice Function to check if a query exists for the given query ID
     * @param queryId_ The query ID
     * @return A boolean indicating whether the query exists
     */
    function isQueryExists(string memory queryId_) external view returns (bool);

    /**
     * @notice Function to get the query hash for the provided circuit query
     * @param circuitQuery_ The circuit query
     * @return The query hash
     */
    function getQueryHash(CircuitQuery memory circuitQuery_) external view returns (uint256);

    /**
     * @notice Function to get the query hash for the raw values
     * @param schema_ The schema id
     * @param slotIndex_ The slot index
     * @param operator_ The query operator
     * @param claimPathKey_ The claim path key
     * @param claimPathNotExists_ The claim path not exists
     * @param values_ The values array
     * @return The query hash
     */
    function getQueryHashRaw(
        uint256 schema_,
        uint256 slotIndex_,
        uint256 operator_,
        uint256 claimPathKey_,
        uint256 claimPathNotExists_,
        uint256[] memory values_
    ) external view returns (uint256);
}