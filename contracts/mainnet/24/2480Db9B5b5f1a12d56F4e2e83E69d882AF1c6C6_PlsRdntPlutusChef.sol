// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

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
import "./Initializable.sol";

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
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IChefIncentivesController {
  function claimAll(address _user) external;

  function allPendingRewards(address _user) external view returns (uint256 pending);
}

interface ILendingPool {
  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  function depositWithAutoDLP(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(
    address user
  )
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
}

interface ISharedStruct {
  struct LockedBalance {
    uint256 amount;
    uint256 unlockTime;
    uint256 multiplier;
    uint256 duration;
  }
}

interface IChefIncentivesHandler is ISharedStruct {
  struct EarnedBalance {
    uint256 amount;
    uint256 unlockTime;
    uint256 penalty;
  }

  /**
   * @notice Withdraw individual unlocked balance and earnings, optionally claim pending rewards.
   */
  function individualEarlyExit(bool claimRewards, uint256 unlockTime) external;

  /**
   * @notice Withdraw tokens from earnings and unlocked.
   * @dev First withdraws unlocked tokens, then earned tokens. Withdrawing earned tokens
   *  incurs a 50% penalty which is distributed based on locked balances.
   */
  function withdraw(uint256 amount) external;

  /**
   * @notice Withdraw full unlocked balance and earnings, optionally claim pending rewards.
   */
  function exit(bool claimRewards) external;

  /**
   * @notice Earnings which is locked yet
   * @dev Earned balances may be withdrawn immediately for a 50% penalty.
   * @return total earnings
   * @return unlocked earnings
   * @return earningsData which is an array of all infos
   */

  function earnedBalances(
    address user
  ) external view returns (uint256 total, uint256 unlocked, EarnedBalance[] memory earningsData);

  /**
   * @notice Final balance received and penalty balance paid by user upon calling exit.
   * @dev This is earnings, not locks.
   */
  function withdrawableBalance(
    address user
  ) external view returns (uint256 amount, uint256 penaltyAmount, uint256 burnAmount);
}

interface IProtocolRewardsHandler is ISharedStruct {
  struct RewardData {
    address token;
    uint256 amount;
  }

  function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external;

  function setRelock(bool _status) external;

  function setDefaultRelockTypeIndex(uint256 _index) external;

  function withdrawExpiredLocksFor(address _address) external returns (uint256);

  function withdrawExpiredLocksForWithOptions(
    address _address,
    uint256 _limit,
    bool _ignoreRelock
  ) external returns (uint256);

  function getReward(address[] memory _rewardTokens) external;

  /** VIEWS */
  function claimableRewards(address account) external view returns (RewardData[] memory rewardsData);

  /**
   * @notice Returns all locks of a user.
   */
  function lockInfo(address user) external view returns (LockedBalance[] memory);

  /**
   * @notice Information on a user's lockings
   * @return total balance of locks
   * @return unlockable balance
   * @return locked balance
   * @return lockedWithMultiplier
   * @return lockData which is an array of locks
   */
  function lockedBalances(
    address user
  )
    external
    view
    returns (
      uint256 total,
      uint256 unlockable,
      uint256 locked,
      uint256 lockedWithMultiplier,
      LockedBalance[] memory lockData
    );
}

// MultiFeeDistribution does 2 things: handle protocol fee distro + handle chef rewards distro
interface IMultiFeeDistribution is IChefIncentivesHandler, IProtocolRewardsHandler {
  struct Reward {
    uint256 periodFinish;
    uint256 rewardPerSecond;
    uint256 lastUpdateTime;
    uint256 rewardPerTokenStored;
    // tracks already-added balances to handle accrued interest in aToken rewards
    // for the stakingToken this value is unused and will always be 0
    uint256 balance;
  }

  function rewardPerToken(address _rewardToken) external view returns (uint256 rptStored);

  function rewardData(address _rewardToken) external view returns (Reward memory);

  function userRewardPerTokenPaid(address _user, address _rewardToken) external view returns (uint256 _rpt);

  function rewards(address _user, address _rewardToken) external view returns (uint256 _amount);

  ///@dev BUGGY
  /**
   * @notice Total balance of an account, including unlocked, locked and earned tokens.
   */
  function totalBalance(address user) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';

interface IWhitelist {
  function isWhitelisted(address) external view returns (bool);
}

contract Whitelist is IWhitelist, Ownable {
  mapping(address => bool) public isWhitelisted;

  constructor(address _gov) {
    transferOwnership(_gov);
  }

  function whitelistAdd(address _addr) external onlyOwner {
    isWhitelisted[_addr] = true;
    emit AddedToWhitelist(_addr);
  }

  function whitelistRemove(address _addr) external onlyOwner {
    isWhitelisted[_addr] = false;
    emit RemovedFromWhitelist(_addr);
  }

  event RemovedFromWhitelist(address indexed _addr);
  event AddedToWhitelist(address indexed _addr);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IProtocolRewardsHandler } from '../interfaces/Radiant.sol';

interface IPlsRdntRewardsDistro {
  function sendRewards(address _to, IProtocolRewardsHandler.RewardData[] memory _pendingRewardAmounts) external;

  function record() external returns (IProtocolRewardsHandler.RewardData[] memory _pendingRewards);

  function hasBufferedRewards() external view returns (bool);

  function pendingRewards() external view returns (IProtocolRewardsHandler.RewardData[] memory _pendingRewards);

  event FeeChanged(uint256 indexed _new, uint256 _old);
  event HandleClaim(IProtocolRewardsHandler.RewardData[] _rewardsData);

  error UNAUTHORIZED();
  error INVALID_FEE();
}

interface IPlsRdntRewardsDistroV2 is IPlsRdntRewardsDistro {
  function handleUnwrap(address[] memory _tokens) external;

  function handleClaimAndUnwrap() external;
}

interface IPlsRdntUtils {
  function mfdClaimableRewards(
    address _account,
    address[] memory _tokens
  ) external view returns (IProtocolRewardsHandler.RewardData[] memory _rewardsData);

  function pendingRewardsLessFee(
    address _user,
    uint _feeInBp,
    bool _inUnderlyingAsset
  ) external view returns (IProtocolRewardsHandler.RewardData[] memory _pendingRewardsLessFee);
}

interface IRdntLpStaker {
  function stake(uint256) external;

  function getRewardTokens() external view returns (address[] memory);

  function getRewardTokenCount() external view returns (uint);

  function claimRadiantProtocolFees(
    address _to
  ) external returns (IProtocolRewardsHandler.RewardData[] memory _rewardsData);

  function claimProtocolFees(address[] calldata _tokens) external;

  function unwrapATokens(
    address _to,
    address[] memory _tokens
  ) external returns (IProtocolRewardsHandler.RewardData[] memory _rewardsData);
}

interface IAToken is IERC20 {
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

interface IPlutusChef {
  function depositFor(address _user, uint96 _amount) external;
}

interface ITokenMinter {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

interface IDelegation {
  function setDelegate(bytes32 id, address delegate) external;
}

interface IPlsRdntPlutusChef is IPlutusChef {
  error DEPOSIT_ERROR(string);
  error WITHDRAW_ERROR();
  error UNAUTHORIZED();
  error FAILED(string);

  event HandlerUpdated(address indexed _handler, bool _isActive);
  event Deposit(address indexed _user, uint256 _amount);
  event Withdraw(address indexed _user, uint256 _amount);
  event EmergencyWithdraw(address indexed _user, uint256 _amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IWhitelist } from '../misc/Whitelist.sol';
import { IPlsRdntPlutusChef, IRdntLpStaker, IPlsRdntRewardsDistro } from './Interfaces.sol';
import { IProtocolRewardsHandler } from '../interfaces/Radiant.sol';

contract PlsRdntPlutusChef is
  IPlsRdntPlutusChef,
  Initializable,
  PausableUpgradeable,
  Ownable2StepUpgradeable,
  UUPSUpgradeable
{
  struct UserInfo {
    uint96 amount;
    int128 plsRewardDebt;
    int128 wethRewardDebt;
    int128 wbtcRewardDebt;
    int128 usdcRewardDebt;
    int128 usdtRewardDebt;
    int128 daiRewardDebt;
    int128 arbRewardDebt;
    int128 wstethRewardDebt;
  }

  struct RewardTokens {
    uint128 pls;
    uint128 wbtc;
    uint128 usdt;
    uint128 usdc;
    uint128 dai;
    uint128 weth;
    uint128 arb;
    uint128 wsteth;
  }

  uint256 private constant MUL_CONSTANT = 1e24;
  address public constant PLS = 0x51318B7D00db7ACc4026C88c3952B66278B6A67F;
  IERC20 public constant STAKING_TOKEN = IERC20(0x1605bbDAB3b38d10fA23A7Ed0d0e8F4FEa5bFF59);
  uint public constant REWARD_COUNT = 8;

  uint128 public acc_pls_PerShare;
  uint128 public acc_wbtc_PerShare;
  uint128 public acc_usdt_PerShare;
  uint128 public acc_usdc_PerShare;
  uint128 public acc_dai_PerShare;
  uint128 public acc_weth_PerShare;

  uint128 public plsPerSecond;
  uint96 public shares;
  uint32 public lastRewardSecond;

  IWhitelist public whitelist;
  IPlsRdntRewardsDistro public distro;
  mapping(address => UserInfo) public userInfo;
  mapping(address => bool) private handlers;

  uint128 public acc_arb_PerShare;
  uint128 public acc_wsteth_PerShare;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(uint32 _rewardEmissionStart) public initializer {
    __Pausable_init();
    __Ownable2Step_init();
    __UUPSUpgradeable_init();
    lastRewardSecond = _rewardEmissionStart;
  }

  function deposit(uint96 _amount) external {
    revert FAILED('PlutusChef: Deprecated');
    _isEligibleSender();
    _deposit(msg.sender, msg.sender, _amount);
  }

  function withdraw(uint96 _amount) external {
    _isEligibleSender();
    _withdraw(msg.sender, _amount);
  }

  function harvest() external {
    _isEligibleSender();
    _harvest(msg.sender);
  }

  function emergencyWithdraw() external {
    _isEligibleSender();
    UserInfo storage user = userInfo[msg.sender];

    uint96 _amount = user.amount;

    user.amount = 0;
    user.plsRewardDebt = 0;
    user.wethRewardDebt = 0;
    user.wbtcRewardDebt = 0;
    user.usdcRewardDebt = 0;
    user.usdtRewardDebt = 0;
    user.daiRewardDebt = 0;
    user.arbRewardDebt = 0;
    user.wstethRewardDebt = 0;

    if (shares >= _amount) {
      shares -= _amount;
    } else {
      shares = 0;
    }

    STAKING_TOKEN.transfer(msg.sender, _amount);
    emit EmergencyWithdraw(msg.sender, _amount);
  }

  function updateShares() public whenNotPaused {
    if (block.timestamp <= lastRewardSecond) {
      return;
    }

    if (shares == 0) {
      lastRewardSecond = uint32(block.timestamp);
      return;
    }

    if (distro.hasBufferedRewards()) {
      IProtocolRewardsHandler.RewardData[] memory _rewards = distro.record();
      _incrementRewardsAccPerShare(_rewards);
    }

    unchecked {
      acc_pls_PerShare += rewardPerShare(plsPerSecond);
    }

    lastRewardSecond = uint32(block.timestamp);
  }

  /** VIEWS */
  /**
    Calculates the reward per share since `lastRewardSecond` was updated
  */
  function rewardPerShare(uint _rewardRatePerSecond) public view returns (uint128) {
    unchecked {
      uint _pendingRewards = (block.timestamp - lastRewardSecond) * _rewardRatePerSecond;
      return uint128((_pendingRewards * MUL_CONSTANT) / shares);
    }
  }

  function pendingRewards(address _user) external view returns (RewardTokens memory _pendingRewards) {
    IProtocolRewardsHandler.RewardData[] memory _rewards = distro.pendingRewards();
    uint _len = _rewards.length;
    uint _shares = shares;

    RewardTokens memory _accPerShare = RewardTokens({
      pls: acc_pls_PerShare,
      wbtc: acc_wbtc_PerShare,
      usdt: acc_usdt_PerShare,
      usdc: acc_usdc_PerShare,
      dai: acc_dai_PerShare,
      weth: acc_weth_PerShare,
      arb: acc_arb_PerShare,
      wsteth: acc_wsteth_PerShare
    });

    if (_shares != 0) {
      if (block.timestamp > lastRewardSecond) {
        _accPerShare.pls += rewardPerShare(plsPerSecond);
      }

      // update reward tokens acc per share
      for (uint i; i < _len; i = _unsafeInc(i)) {
        address _rewardToken = _rewards[i].token;
        if (_rewardToken == address(0) || _rewards[i].amount == 0) continue;
        uint128 _rewardPerShare = uint128((_rewards[i].amount * MUL_CONSTANT) / _shares);

        if (_rewardToken == 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f) {
          _accPerShare.wbtc += _rewardPerShare; // WBTC
        } else if (_rewardToken == 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9) {
          _accPerShare.usdt += _rewardPerShare; // USDT
        } else if (_rewardToken == 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8) {
          _accPerShare.usdc += _rewardPerShare; // USDC
        } else if (_rewardToken == 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1) {
          _accPerShare.dai += _rewardPerShare; // DAI
        } else if (_rewardToken == 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1) {
          _accPerShare.weth += _rewardPerShare; // WETH
        } else if (_rewardToken == 0x912CE59144191C1204E64559FE8253a0e49E6548) {
          _accPerShare.arb += _rewardPerShare; // ARB
        } else if (_rewardToken == 0x5979D7b546E38E414F7E9822514be443A4800529) {
          _accPerShare.wsteth += _rewardPerShare; // WSTETH
        } else {
          revert FAILED('Unreachable');
        }
      }
    }

    UserInfo memory user = userInfo[_user];
    uint96 _userDepositAmount = user.amount;

    _pendingRewards = RewardTokens({
      pls: _calculatePending(user.plsRewardDebt, _accPerShare.pls, _userDepositAmount),
      wbtc: _calculatePending(user.wbtcRewardDebt, _accPerShare.wbtc, _userDepositAmount),
      usdt: _calculatePending(user.usdtRewardDebt, _accPerShare.usdt, _userDepositAmount),
      usdc: _calculatePending(user.usdcRewardDebt, _accPerShare.usdc, _userDepositAmount),
      dai: _calculatePending(user.daiRewardDebt, _accPerShare.dai, _userDepositAmount),
      weth: _calculatePending(user.wethRewardDebt, _accPerShare.weth, _userDepositAmount),
      arb: _calculatePending(user.arbRewardDebt, _accPerShare.arb, _userDepositAmount),
      wsteth: _calculatePending(user.wstethRewardDebt, _accPerShare.wsteth, _userDepositAmount)
    });
  }

  /** PRIVATE */
  function _isEligibleSender() private view {
    if (msg.sender != tx.origin && whitelist.isWhitelisted(msg.sender) == false) revert UNAUTHORIZED();
  }

  function _calculatePending(
    int128 _rewardDebt,
    uint256 _accTokenPerShare, // Stay 256;
    uint96 _amount
  ) private pure returns (uint128) {
    if (_rewardDebt < 0) {
      return uint128(_calculateRewardDebt(_accTokenPerShare, _amount)) + uint128(-_rewardDebt);
    } else {
      return uint128(_calculateRewardDebt(_accTokenPerShare, _amount)) - uint128(_rewardDebt);
    }
  }

  function _deposit(address _from, address _user, uint96 _amount) private {
    UserInfo storage user = userInfo[_user];
    if (_amount < 1 ether) revert DEPOSIT_ERROR('min deposit: 1 plsRDNT');
    updateShares();

    uint256 _prev = STAKING_TOKEN.balanceOf(address(this));

    unchecked {
      user.amount += _amount;
      shares += _amount;
    }

    _incrementDebt(user, _amount);
    STAKING_TOKEN.transferFrom(_from, address(this), _amount);

    unchecked {
      if (_prev + _amount != STAKING_TOKEN.balanceOf(address(this))) revert DEPOSIT_ERROR('invariant violation');
    }

    emit Deposit(_user, _amount);
  }

  function _withdraw(address _user, uint96 _amount) private {
    UserInfo storage user = userInfo[_user];
    if (user.amount < _amount || _amount == 0) revert WITHDRAW_ERROR();
    updateShares();

    unchecked {
      user.amount -= _amount;
      shares -= _amount;
    }

    _decrementDebt(user, _amount);
    STAKING_TOKEN.transfer(_user, _amount);
    emit Withdraw(_user, _amount);
  }

  function _getTransferrableRewards(
    UserInfo storage user
  ) private view returns (IProtocolRewardsHandler.RewardData[] memory _transferrableRewards) {
    uint96 _userDepositAmount = user.amount;

    _transferrableRewards = new IProtocolRewardsHandler.RewardData[](REWARD_COUNT);
    _transferrableRewards[0] = IProtocolRewardsHandler.RewardData({
      token: PLS,
      amount: _calculatePending(user.plsRewardDebt, acc_pls_PerShare, _userDepositAmount)
    });
    _transferrableRewards[1] = IProtocolRewardsHandler.RewardData({
      token: 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f, // WBTC
      amount: _calculatePending(user.wbtcRewardDebt, acc_wbtc_PerShare, _userDepositAmount)
    });
    _transferrableRewards[2] = IProtocolRewardsHandler.RewardData({
      token: 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, // USDT
      amount: _calculatePending(user.usdtRewardDebt, acc_usdt_PerShare, _userDepositAmount)
    });
    _transferrableRewards[3] = IProtocolRewardsHandler.RewardData({
      token: 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, // USDC
      amount: _calculatePending(user.usdcRewardDebt, acc_usdc_PerShare, _userDepositAmount)
    });
    _transferrableRewards[4] = IProtocolRewardsHandler.RewardData({
      token: 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1, // DAI
      amount: _calculatePending(user.daiRewardDebt, acc_dai_PerShare, _userDepositAmount)
    });
    _transferrableRewards[5] = IProtocolRewardsHandler.RewardData({
      token: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, // WETH
      amount: _calculatePending(user.wethRewardDebt, acc_weth_PerShare, _userDepositAmount)
    });
    _transferrableRewards[6] = IProtocolRewardsHandler.RewardData({
      token: 0x912CE59144191C1204E64559FE8253a0e49E6548, // ARB
      amount: _calculatePending(user.arbRewardDebt, acc_arb_PerShare, _userDepositAmount)
    });
    _transferrableRewards[7] = IProtocolRewardsHandler.RewardData({
      token: 0x5979D7b546E38E414F7E9822514be443A4800529, // WSTETH
      amount: _calculatePending(user.wstethRewardDebt, acc_wsteth_PerShare, _userDepositAmount)
    });
  }

  function _harvest(address _user) private {
    updateShares();
    UserInfo storage user = userInfo[_user];
    IProtocolRewardsHandler.RewardData[] memory _transferrableRewards = _getTransferrableRewards(user);

    _setDebt(user); // needs to be AFTER _getTransferrableRewards
    distro.sendRewards(_user, _transferrableRewards);
  }

  function _calculateRewardDebt(uint256 _accTokenPerShare, uint256 _amount) private pure returns (uint256) {
    unchecked {
      return (_amount * _accTokenPerShare) / MUL_CONSTANT;
    }
  }

  function _incrementRewardsAccPerShare(IProtocolRewardsHandler.RewardData[] memory rewards) private {
    uint _rewardsCount = rewards.length;
    uint _shares = shares;

    for (uint i; i < _rewardsCount; i = _unsafeInc(i)) {
      address _rewardToken = rewards[i].token;
      if (_rewardToken == address(0) || rewards[i].amount == 0) continue;

      uint128 _rewardPerShare = uint128((rewards[i].amount * MUL_CONSTANT) / _shares);

      if (_rewardToken == 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f) {
        acc_wbtc_PerShare += _rewardPerShare; // WBTC
      } else if (_rewardToken == 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9) {
        acc_usdt_PerShare += _rewardPerShare; // USDT
      } else if (_rewardToken == 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8) {
        acc_usdc_PerShare += _rewardPerShare; // USDC
      } else if (_rewardToken == 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1) {
        acc_dai_PerShare += _rewardPerShare; // DAI
      } else if (_rewardToken == 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1) {
        acc_weth_PerShare += _rewardPerShare; // WETH
      } else if (_rewardToken == 0x912CE59144191C1204E64559FE8253a0e49E6548) {
        acc_arb_PerShare += _rewardPerShare; // ARB
      } else if (_rewardToken == 0x5979D7b546E38E414F7E9822514be443A4800529) {
        acc_wsteth_PerShare += _rewardPerShare; // WSTETH
      } else {
        revert FAILED('Unreachable');
      }
    }
  }

  function _unsafeInc(uint x) private pure returns (uint) {
    unchecked {
      return x + 1;
    }
  }

  function _incrementDebt(UserInfo storage user, uint _amount) private {
    user.plsRewardDebt += int128(uint128(_calculateRewardDebt(acc_pls_PerShare, _amount)));
    user.wethRewardDebt += int128(uint128(_calculateRewardDebt(acc_weth_PerShare, _amount)));
    user.wbtcRewardDebt += int128(uint128(_calculateRewardDebt(acc_wbtc_PerShare, _amount)));
    user.daiRewardDebt += int128(uint128(_calculateRewardDebt(acc_dai_PerShare, _amount)));
    user.usdcRewardDebt += int128(uint128(_calculateRewardDebt(acc_usdc_PerShare, _amount)));
    user.usdtRewardDebt += int128(uint128(_calculateRewardDebt(acc_usdt_PerShare, _amount)));
    user.arbRewardDebt += int128(uint128(_calculateRewardDebt(acc_arb_PerShare, _amount)));
    user.wstethRewardDebt += int128(uint128(_calculateRewardDebt(acc_wsteth_PerShare, _amount)));
  }

  function _decrementDebt(UserInfo storage user, uint _amount) private {
    user.plsRewardDebt -= int128(uint128(_calculateRewardDebt(acc_pls_PerShare, _amount)));
    user.wethRewardDebt -= int128(uint128(_calculateRewardDebt(acc_weth_PerShare, _amount)));
    user.wbtcRewardDebt -= int128(uint128(_calculateRewardDebt(acc_wbtc_PerShare, _amount)));
    user.daiRewardDebt -= int128(uint128(_calculateRewardDebt(acc_dai_PerShare, _amount)));
    user.usdcRewardDebt -= int128(uint128(_calculateRewardDebt(acc_usdc_PerShare, _amount)));
    user.usdtRewardDebt -= int128(uint128(_calculateRewardDebt(acc_usdt_PerShare, _amount)));
    user.arbRewardDebt -= int128(uint128(_calculateRewardDebt(acc_arb_PerShare, _amount)));
    user.wstethRewardDebt -= int128(uint128(_calculateRewardDebt(acc_wsteth_PerShare, _amount)));
  }

  function _setDebt(UserInfo storage user) private {
    user.plsRewardDebt = int128(uint128(_calculateRewardDebt(acc_pls_PerShare, user.amount)));
    user.wethRewardDebt = int128(uint128(_calculateRewardDebt(acc_weth_PerShare, user.amount)));
    user.wbtcRewardDebt = int128(uint128(_calculateRewardDebt(acc_wbtc_PerShare, user.amount)));
    user.daiRewardDebt = int128(uint128(_calculateRewardDebt(acc_dai_PerShare, user.amount)));
    user.usdcRewardDebt = int128(uint128(_calculateRewardDebt(acc_usdc_PerShare, user.amount)));
    user.usdtRewardDebt = int128(uint128(_calculateRewardDebt(acc_usdt_PerShare, user.amount)));
    user.arbRewardDebt = int128(uint128(_calculateRewardDebt(acc_arb_PerShare, user.amount)));
    user.wstethRewardDebt = int128(uint128(_calculateRewardDebt(acc_wsteth_PerShare, user.amount)));
  }

  /** HANDLER */
  function depositFor(address _user, uint96 _amount) external {
    if (handlers[msg.sender] == false) revert UNAUTHORIZED();
    _deposit(msg.sender, _user, _amount);
  }

  function withdrawFor(address _user, uint96 _amount) external {
    if (handlers[msg.sender] == false) revert UNAUTHORIZED();
    _withdraw(_user, _amount);
  }

  function harvestFor(address _user) external {
    if (handlers[msg.sender] == false) revert UNAUTHORIZED();
    _harvest(_user);
  }

  /** OWNER FUNCTIONS */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function setWhitelist(address _whitelist) external onlyOwner {
    whitelist = IWhitelist(_whitelist);
  }

  function updateHandler(address _handler, bool _isActive) external onlyOwner {
    handlers[_handler] = _isActive;
    emit HandlerUpdated(_handler, _isActive);
  }

  function setEmission(uint128 _plsPerSecond) external onlyOwner {
    plsPerSecond = _plsPerSecond;
  }

  function setDistro(address _distro) external onlyOwner {
    distro = IPlsRdntRewardsDistro(_distro);
  }

  function setStartTime(uint32 _startTime) external onlyOwner {
    lastRewardSecond = _startTime;
  }

  function setPaused(bool _pauseContract) external onlyOwner {
    if (_pauseContract) {
      _pause();
    } else {
      _unpause();
    }
  }
}