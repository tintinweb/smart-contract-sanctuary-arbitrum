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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
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
pragma solidity 0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {GlobalOwnableUpgradeable} from "./abstracts/GlobalOwnableUpgradeable.sol";

/**
 * @title GlobalBlacklist
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice Holds a global mapping of blacklisted accounts shared by all contracts of the
 * Ledgity Yield codebase.
 *
 * @dev Specifically, some contracts within the codebase inherit from the
 * GlobalRestrictableUpgradeable abstract contract. This provides them with modifiers
 * and getter functions to easily check against this global blacklist.
 *
 * @dev For further details, see "GlobalBlacklist" section of whitepaper.
 * @custom:security-contact [email protected]
 */
contract GlobalBlacklist is Initializable, UUPSUpgradeable, GlobalOwnableUpgradeable {
    /**
     * @notice Mapping of accounts to their blacklist status.
     * @dev This mapping is made private and isBlacklisted() should be used instead.This
     * helps saving gas in some scenario. See isBlacklisted() documentation for more details.
     */
    mapping(address => bool) private _list;

    /// @dev Emitted when `account` is blacklisted.
    event Blacklisted(address account);

    /// @dev Emitted when `account` is unblacklisted.
    event Unblacklisted(address account);

    /**
     * @notice Prevents implementation contract from being initialized as recommended by
     * OpenZeppelin.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializer function of the contract. It replaces the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalOwner_ The address of the GlobalOwner contract.
     */
    function initialize(address globalOwner_) public initializer {
        __GlobalOwnable_init(globalOwner_);
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Override of UUPSUpgradeable._authorizeUpgrade() function restricted to
     * global owner. It is called by the proxy contract during an upgrade.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Adds a given account to the blacklist.
     * @param account The account's address to be blacklisted.
     */
    function blacklist(address account) external onlyOwner {
        require(account != address(0), "L20");
        _list[account] = true;
        emit Blacklisted(account);
    }

    /**
     * @notice Removes a given account from the blacklist.
     * @param account The account's address to be un-blacklisted.
     */
    function unBlacklist(address account) external onlyOwner {
        _list[account] = false;
        emit Unblacklisted(account);
    }

    /**
     * @notice Checks whether a given account is blacklisted.
     * @param account Address of the account to check.
     * @return 'true' if the account is blacklisted, 'false' otherwise
     */
    function isBlacklisted(address account) external view returns (bool) {
        // Gas optimization: Avoid accessing storage if account is the zero address
        // (e.g, during a mint or a burn of tokens)
        if (account == address(0)) return false;

        // Else, return current account's blacklist status
        return _list[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

/**
 * @title GlobalOwner
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice Holds the address of a global owner account shared by all contracts of the
 * Ledgity Yield's codebase.
 *
 * @dev Specifically, some contracts within the codebase inherit from the
 * GlobalOwnableUpgradeable abstract contract. This provides them with an overriden
 * owner() function that retrieves the owner's address from this contract instead.
 *
 * @dev For further details, see "GlobalOwner" section of whitepaper.
 * @custom:security-contact [email protected]
 */
contract GlobalOwner is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {
    /**
     * @notice Prevents implementation contract from being initialized as recommended by
     * OpenZeppelin.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializer function of the contract. It replaces the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     */
    function initialize() public initializer {
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Override of UUPSUpgradeable._authorizeUpgrade() function restricted to
     * global owner. It is called by the proxy contract during an upgrade.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {GlobalOwnableUpgradeable} from "./abstracts/GlobalOwnableUpgradeable.sol";

/**
 * @title GlobalPause
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice Holds a global pause state shared by all contracts of the Ledgity Yield
 * codebase.
 *
 * @dev Specifically, some contracts within the codebase inherit from the
 * GlobalPausableUpgradeable abstract contract. This provides them with an overriden
 * paused() function that retrieves the pause state from this contract instead.
 *
 * @dev For further details, see "GlobalPause" section of whitepaper.
 * @custom:security-contact [email protected]
 */
contract GlobalPause is
    Initializable,
    UUPSUpgradeable,
    GlobalOwnableUpgradeable,
    PausableUpgradeable
{
    /**
     * @notice Prevents implementation contract from being initialized as recommended by
     * OpenZeppelin.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializer function of the contract. It replaces the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalOwner_ The address of the GlobalOwner contract.
     */
    function initialize(address globalOwner_) public initializer {
        __GlobalOwnable_init(globalOwner_);
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Override of UUPSUpgradeable._authorizeUpgrade() function restricted to
     * global owner. It is called by the proxy contract during an upgrade.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Public implementation of PausableUpgradeable's pausing and unpausing functions
     * but restricted to contract's owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Contracts
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {BaseUpgradeable} from "./abstracts/base/BaseUpgradeable.sol";

// Libraries
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// Interfaces
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title LDYStaking
 * @custom:security-contact [email protected]
 *
 * @dev This contract implements tierOf() function from LDYStaking as it's the only
 * one the LToken contract relies on.
 *
 * @custom:security-contact [email protected]
 */
contract LDYStaking is BaseUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Represents a user staking info in array.
     * @param stakedAmount Amount of the stake.
     * @param unStakeAt Unstake at.
     * @param duration Staking period in seconds.
     * @param rewardPerTokenPaid Reward per token paid.
     * @param rewards Rewards to be claimed.
     */
    struct StakingInfo {
        uint256 stakedAmount;
        uint256 unStakeAt;
        uint256 duration;
        uint256 rewardPerTokenPaid;
        uint256 rewards;
    }

    /**
     * @notice Represent duration and multiplier per each stake option.
     * @param duration Staking period in seconds.
     * @param multiplier Token weight
     */
    struct StakeDurationInfo {
        uint256 duration;
        uint256 multiplier;
    }

    /// @notice Decimals of multiplier
    uint256 public constant MULTIPLIER_BASIS = 1e4;

    /// @notice Stake and Reward token.
    IERC20Upgradeable public stakeRewardToken;

    /// @notice Minimal stake duration for perks.
    uint256 public stakeDurationForPerks;

    /// @notice Minimal stake amount for perks.
    uint256 public stakeAmountForPerks;

    /// @notice Stake durations info array.
    StakeDurationInfo[] public stakeDurationInfos;

    /// @notice Duration of the rewards (in seconds).
    uint256 public rewardsDuration;

    /// @notice Timestamp of when the rewards finish.
    uint256 public finishAt;

    /// @notice Timestamp of the reward updated.
    uint256 public lastUpdateTime;

    /// @notice Reward per second(total rewards / duration).
    uint256 public rewardRatePerSec;

    /// @notice Reward per token stored, sum of (reward rate * dt * 1e18 / total supply).
    uint256 public rewardPerTokenStored;

    /// @notice Total staked amounts.
    uint256 public totalStaked;

    // Total staked amounts with multiplier applied
    uint256 public totalWeightedStake;

    /// @notice User stakingInfo map, user address => array of the staking info
    mapping(address => StakingInfo[]) public userStakingInfo;

    /// @notice Total rewards amount.
    uint256 public totalRewards;

    /**
     * @notice Emitted when users stake token
     * @param user User address
     * @param stakeIndex Latest index of user staking pool
     * @param amount Staked amount
     */
    event Staked(address indexed user, uint256 stakeIndex, uint256 amount);

    /**
     * @notice Emitted when users unstake token
     * @param user User address
     * @param stakeIndex User staking pool index
     * @param amount Staked amount
     */
    event Unstaked(address indexed user, uint256 stakeIndex, uint256 amount);

    /**
     * @notice Emitted when users claim rewards
     * @param user User address
     * @param stakeIndex User staking pool index
     * @param reward Reward token amount
     */
    event RewardPaid(address indexed user, uint256 stakeIndex, uint256 reward);

    /**
     * @notice Emitted when admin add rewards.
     * @param rewardAmount Reward amount added by admin.
     * @param rewardPerSec RewardRatePerSec updated.
     */
    event NotifiedRewardAmount(uint256 rewardAmount, uint256 rewardPerSec);

    /**
     * @notice Holds a mapping of addresses that default to the highest staking tier.
     * @dev This is notably used to allow PreMining contracts to benefit from 0%
     * withdrawal fees in L-Tokens contracts, when accounts unlock their funds.
     */
    mapping(address => bool) public highTierAccounts;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract and sets the initial state variables. This is called by the proxy and should only be called once.
     * @dev This function is intended for setting initial values for the contract's state variables.
     * @param globalOwner_ The address of the GlobalOwner contract.
     * @param globalPause_ The address of the GlobalPause contract.
     * @param globalBlacklist_ The address of the GlobalBlacklist contract.
     * @param stakeRewardToken_ The address of stake and reward token(LDY token).
     * @param stakeDurationInfos_ Available Staking Durations.
     * @param stakeDurationForPerks_ Minimal staking duration for perks.
     * @param stakeAmountForPerks_ Minimal staking amount for perks.
     */
    function initialize(
        address globalOwner_,
        address globalPause_,
        address globalBlacklist_,
        address stakeRewardToken_,
        StakeDurationInfo[] memory stakeDurationInfos_,
        uint256 stakeDurationForPerks_,
        uint256 stakeAmountForPerks_
    ) public initializer {
        __Base_init(globalOwner_, globalPause_, globalBlacklist_);
        stakeRewardToken = IERC20Upgradeable(stakeRewardToken_);
        uint stakeDurationInfosLength = stakeDurationInfos_.length;
        for (uint256 i = 0; i < stakeDurationInfosLength; i++) {
            stakeDurationInfos.push(stakeDurationInfos_[i]);
        }
        stakeDurationForPerks = stakeDurationForPerks_;
        stakeAmountForPerks = stakeAmountForPerks_;
    }

    // --------------------
    //  MUTATIVE FUNCTIONS
    // --------------------

    /**
     * @notice Staked tokens cannot be withdrawn during the stakeDuration period and are eligible to claim rewards.
     * @dev Emits a `Staked` event upon successful staking.
     * @param amount The amount of tokens to stake.
     * @param stakeDurationIndex The Index of stakeDurationInfos array.
     */
    function stake(
        uint256 amount,
        uint8 stakeDurationIndex
    ) external nonReentrant whenNotPaused notBlacklisted(_msgSender()) {
        require(amount > 0, "amount = 0");
        require(stakeDurationIndex <= stakeDurationInfos.length - 1, "Invalid staking period");

        _updateReward(address(0), 0);
        StakeDurationInfo memory stakeDurationInfo = stakeDurationInfos[stakeDurationIndex];
        StakingInfo memory stakingInfo = StakingInfo({
            stakedAmount: amount,
            unStakeAt: block.timestamp + stakeDurationInfo.duration,
            duration: stakeDurationInfo.duration,
            rewardPerTokenPaid: rewardPerTokenStored,
            rewards: 0
        });

        // check whether account is eligible for benefit from the protocol
        if (stakeDurationInfo.duration >= stakeDurationForPerks && amount >= stakeAmountForPerks) {
            highTierAccounts[_msgSender()] = true;
        }

        userStakingInfo[_msgSender()].push(stakingInfo);

        uint256 stakeIndex = userStakingInfo[_msgSender()].length - 1;
        uint256 weightedStake = (amount * stakeDurationInfo.multiplier) / MULTIPLIER_BASIS;
        totalWeightedStake += weightedStake;
        totalStaked += amount;

        stakeRewardToken.safeTransferFrom(_msgSender(), address(this), amount);

        emit Staked(_msgSender(), stakeIndex, amount);
    }

    /**
     * @notice Withdraw staked tokens after stakeDuration has passed.
     * @dev Emits a `Unstaked` event upon successful withdrawal.
     * On full withdrawal, userStakingInfo removes stake pool for stakeIndex.
     * @param amount The amount of tokens to withdraw.
     * @param stakeIndex The index of user staking pool
     */
    function unstake(
        uint256 amount,
        uint256 stakeIndex
    ) external nonReentrant notBlacklisted(_msgSender()) {
        require(amount > 0, "amount = 0");
        require(userStakingInfo[_msgSender()].length >= stakeIndex + 1, "Invalid stakeIndex");
        require(
            block.timestamp >= userStakingInfo[_msgSender()][stakeIndex].unStakeAt,
            "Cannot unstake during staking period"
        );
        require(
            amount <= userStakingInfo[_msgSender()][stakeIndex].stakedAmount,
            "Insufficient unstake amount"
        );

        _updateReward(_msgSender(), stakeIndex);

        uint256 multiplier = _getMultiplier(userStakingInfo[_msgSender()][stakeIndex].duration);

        uint256 currentWeightedStake = (amount * multiplier) / MULTIPLIER_BASIS;
        totalWeightedStake -= currentWeightedStake;

        totalStaked -= amount;
        userStakingInfo[_msgSender()][stakeIndex].stakedAmount -= amount;

        // check whether account is eligible for benefit from the protocol
        if (
            userStakingInfo[_msgSender()][stakeIndex].duration >= stakeDurationForPerks &&
            userStakingInfo[_msgSender()][stakeIndex].stakedAmount < stakeAmountForPerks
        ) {
            highTierAccounts[_msgSender()] = false;
        }

        // remove staking info from array on full withdrawal
        if (userStakingInfo[_msgSender()][stakeIndex].stakedAmount == 0) {
            _claimReward(_msgSender(), stakeIndex);

            userStakingInfo[_msgSender()][stakeIndex] = userStakingInfo[_msgSender()][
                userStakingInfo[_msgSender()].length - 1
            ];
            userStakingInfo[_msgSender()].pop();
        }
        stakeRewardToken.safeTransfer(_msgSender(), amount);

        emit Unstaked(_msgSender(), stakeIndex, amount);
    }

    /**
     * @notice Claim pending rewards.
     * @dev Emits a `RewardPaid` event upon successful reward claim.
     * @param stakeIndex The index of user staking pool.
     */
    function getReward(uint256 stakeIndex) external nonReentrant notBlacklisted(_msgSender()) {
        require(userStakingInfo[_msgSender()].length >= stakeIndex + 1, "Invalid stakeIndex");
        _updateReward(_msgSender(), stakeIndex);
        _claimReward(_msgSender(), stakeIndex);
    }

    // --------------------
    // ADMIN CONFIGURATION
    // --------------------

    /**
     * @notice Update Rewards Duration.
     * @dev Only callable by owner, and setting available only after rewards period.
     * @param duration New reward duration in seconds.
     */
    function setRewardsDuration(uint256 duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration is not finished");
        rewardsDuration = duration;
    }

    /**
     * @notice Update stakeDurationForPerks
     * @dev Only callable by owner.
     * @param stakeDurationForPerks_ New stakeDurationForPerks.
     */
    function setStakeDurationForPerks(uint256 stakeDurationForPerks_) external onlyOwner {
        stakeDurationForPerks = stakeDurationForPerks_;
    }

    /**
     * @notice Update stakeAmountForPerks
     * @dev Only callable by owner.
     * @param stakeAmountForPerks_ New stakeDurationForPerks.
     */
    function setStakeAmountForPerks(uint256 stakeAmountForPerks_) external onlyOwner {
        stakeAmountForPerks = stakeAmountForPerks_;
    }

    /**
     * @notice Push stakeDurationInfo
     * @dev Only callable by owner.
     */
    function pushStakeDurationInfo(StakeDurationInfo memory durationInfo) external onlyOwner {
        stakeDurationInfos.push(durationInfo);
    }

    /**
     * @notice Notify the contract about the amount of rewards to be distributed and update reward parameters.
     * @dev Only callable by owner.
     * @param amount The amount of reward to be distributed.
     */
    function notifyRewardAmount(uint256 amount) external onlyOwner {
        require(rewardsDuration > 0, "rewards duration is not set");
        require(amount > 0, "amount = 0");

        _updateReward(address(0), 0);

        if (block.timestamp >= finishAt) {
            rewardRatePerSec = amount / rewardsDuration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRatePerSec;
            rewardRatePerSec = (amount + remainingRewards) / rewardsDuration;
        }

        require(rewardRatePerSec > 0, "reward rate = 0");
        require(
            rewardRatePerSec <=
                (stakeRewardToken.balanceOf(address(this)) + amount - totalStaked) /
                    rewardsDuration,
            "reward amount > balance"
        );

        finishAt = block.timestamp + rewardsDuration;
        lastUpdateTime = block.timestamp;

        totalRewards += amount;
        stakeRewardToken.safeTransferFrom(_msgSender(), address(this), amount);

        emit NotifiedRewardAmount(amount, rewardRatePerSec);
    }

    // --------------------
    //    VIEW FUNCTIONS
    // --------------------

    /**
     * @notice Get the last time when rewards were applicable for the specified reward token.
     * @return Timestamp of the most recent rewards calculation.
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    /**
     * @notice Calculate the reward per token for a given reward token.
     * @return Current reward per token.
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((rewardRatePerSec * (lastTimeRewardApplicable() - lastUpdateTime) * 1e18) /
                totalWeightedStake);
    }

    /**
     * @notice Calculate the user's stake pool earnings
     * @param account Address of the user.
     * @param stakeIndex Index of the stakePool
     * @return Return earned amounts
     */
    function earned(address account, uint256 stakeIndex) public view returns (uint256) {
        StakingInfo memory userInfo = userStakingInfo[account][stakeIndex];
        uint256 multiplier = _getMultiplier(userInfo.duration);
        uint256 weightedAmount = (userInfo.stakedAmount * multiplier) / MULTIPLIER_BASIS;
        uint256 rewardsSinceLastUpdate = ((weightedAmount *
            (rewardPerToken() - userInfo.rewardPerTokenPaid)) / 1e18);
        return rewardsSinceLastUpdate + userInfo.rewards;
    }

    /**
     * @notice Get the earned rewards array for a user.
     * @param account Address of the user.
     * @return Return earned rewards array for a user.
     */
    function getEarnedUser(address account) public view returns (uint256[] memory) {
        uint256 numberOfPools = userStakingInfo[account].length;
        uint256[] memory earnedArray = new uint256[](numberOfPools);
        for (uint256 index; index < numberOfPools; index++) {
            earnedArray[index] = earned(account, index);
        }
        return earnedArray;
    }

    /**
     * @dev tierOf() function that always return that the given account is not
     * elligible to any LDY staking tier, except if the account is in the
     * highTierAccounts mapping.
     * @param account The account to check the tier of.
     */
    function tierOf(address account) public view returns (uint256 tier) {
        if (highTierAccounts[account]) return 3;
        return 0;
    }

    /**
     * @notice Get User Stake Data.
     * @param account The address of user.
     * @return StakingInfo array.
     */
    function getUserStakes(address account) external view returns (StakingInfo[] memory) {
        return userStakingInfo[account];
    }

    /**
     * @notice Get StakeDurationInfo.
     * @param index Index of StakeDurationInfos.
     * @return StakeDurationInfo.
     */
    function getStakeDurationInfo(uint256 index) external view returns (StakeDurationInfo memory) {
        require(stakeDurationInfos.length - 1 >= index, "wrong index");
        return stakeDurationInfos[index];
    }

    /**
     * @notice Send rewards to user.
     * @dev This is private function, called by getReward function.
     * @param account The address of user.
     * @param stakeIndex The index of user staking pool.
     */
    function _claimReward(address account, uint256 stakeIndex) private {
        uint256 reward = userStakingInfo[account][stakeIndex].rewards;

        if (reward > 0) {
            userStakingInfo[account][stakeIndex].rewards = 0;
            totalRewards -= reward;
            stakeRewardToken.safeTransfer(account, reward);
            emit RewardPaid(account, stakeIndex, reward);
        }
    }

    /**
     * @notice Calculate and update user rewards per stakeIndex.
     * @dev this is private function, called by stake, unstake, getRewards, and notifyRewardAmount functions.
     * @param account The address of user.
     * @param stakeIndex The index of user staking pool.
     */
    function _updateReward(address account, uint256 stakeIndex) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            userStakingInfo[account][stakeIndex].rewards = earned(account, stakeIndex);
            userStakingInfo[account][stakeIndex].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    /**
     * @notice Get multiplier from stakeDurationInfo based on duration
     * @param duration Stake Duration
     */
    function _getMultiplier(uint256 duration) private view returns (uint256) {
        uint256 stakeDurationInfosLength = stakeDurationInfos.length;
        for (uint256 i = 0; i < stakeDurationInfosLength; i++) {
            StakeDurationInfo memory stakeDurationInfo = stakeDurationInfos[i];
            if (duration == stakeDurationInfo.duration) {
                return stakeDurationInfo.multiplier;
            }
        }
        return 0;
    }

    /**
     * @notice Take minimum value between x and y.
     */
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {GlobalOwner} from "../GlobalOwner.sol";

/**
 * @title GlobalOwnableUpgradeable
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice Derived contracts will inherit ownership from the specified GlobalOwner
 * contract (see GlobalOwner.sol). This design facilitates centralized management
 * of ownership for all the Ledgity Yield contracts.
 *
 * @dev Security measure:
 * The _globalOwner state must be set at initialization time and, for evident security
 * reasons, cannot be changed afterward.
 *
 * @dev For further details, see "GlobalOwnableUpgradeable" section of whitepaper.
 * @custom:security-contact [email protected]
 */
abstract contract GlobalOwnableUpgradeable is Initializable, OwnableUpgradeable {
    /**
     * @notice The GlobalOwner contract the ownership will be inherited from.
     * @dev This state is private so derived contracts cannot change its value.
     */
    GlobalOwner private _globalOwner;

    /**
     * @notice Initializer functions of the contract. They replace the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalOwner_ The address of the GlobalOwner contract.
     */
    function __GlobalOwnable_init(address globalOwner_) internal onlyInitializing {
        __GlobalOwnable_init_unchained(globalOwner_);
        // Note: __Ownable_init() doesn't have to be called as the overriden owner()
        // function no longer rely on the _owner state. Since __Ownable_init() only sets
        // the initial _owner value, calling it would have no effect.
    }

    function __GlobalOwnable_init_unchained(address globalOwner_) internal onlyInitializing {
        _globalOwner = GlobalOwner(globalOwner_);
    }

    /**
     * @notice Retrieves the address of GlobalOwner contract.
     * @return The address of the GlobalOwner contract.
     */
    function globalOwner() public view returns (address) {
        return address(_globalOwner);
    }

    /**
     * @notice Override of OwnableUpgradeable.owner() that retrieves the owner's address
     * from the GlobalOwner contract instead.
     * @return The address of the owner
     */
    function owner() public view override returns (address) {
        return _globalOwner.owner();
    }

    /**
     * @notice Override of OwnableUpgradeable.transferOwnership() that always reverts.
     * Ownership is managed by the GlobalOwner contract and must be modified there.
     */
    function transferOwnership(address newOwner) public view override onlyOwner {
        newOwner; // Silence unused variable compiler warning
        revert("L8");
    }

    /**
     * @notice Override of OwnableUpgradeable.renounceOwnership() that always reverts.
     * Ownership is managed by the GlobalOwner contract and must be modified there.
     */
    function renounceOwnership() public view override onlyOwner {
        revert("L65");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add
     * new variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {GlobalPause} from "../GlobalPause.sol";

/**
 * @title GlobalPausableUpgradeable
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice Derived contracts will inherit a pause state from the specified GlobalPause
 * contract (see GlobalPause.sol). This design facilitates centralized management of
 * pause state for all the Ledgity Yield contracts.
 *
 * @dev Security measure
 * The _globalPause state must be set at initialization time and, for evident security
 * reasons, cannot be changed afterward.
 *
 * @dev For further details, see "GlobalPausableUpgradeable" section of whitepaper.
 * @custom:security-contact [email protected]
 */
abstract contract GlobalPausableUpgradeable is Initializable, PausableUpgradeable {
    /**
     * @notice The GlobalPause contract the pause state will be inherited from.
     * @dev This state is private so derived contracts cannot change its value.
     */
    GlobalPause private _globalPause;

    /**
     * @notice Initializer functions of the contract. They replace the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalPause_ The address of the GlobalPause contract.
     */
    function __GlobalPausable_init(address globalPause_) internal onlyInitializing {
        __Pausable_init();
        __GlobalPausable_init_unchained(globalPause_);
    }

    function __GlobalPausable_init_unchained(address globalPause_) internal onlyInitializing {
        _globalPause = GlobalPause(globalPause_);
    }

    /**
     * @notice Retrieves the address of GlobalPause contract.
     * @return The address of the GlobalPause contract.
     */
    function globalPause() public view returns (address) {
        return address(_globalPause);
    }

    /**
     * @notice Override of PausableUpgradeable.pause() that retrieves the pause state
     * from the GlobalPause contract instead.
     * @return Whether the contract is paused or not.
     */
    function paused() public view virtual override returns (bool) {
        return _globalPause.paused();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add
     * new variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {GlobalBlacklist} from "../GlobalBlacklist.sol";

/**
 * @title GlobalRestrictableUpgradeable
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice Derived contracts will inherit a blacklist state from the specified
 * GlobalBlacklist contract (see GlobalBlacklist.sol). This design facilitates
 * centralized management of a blacklist for all the Ledgity Yield contracts.
 *
 * @dev Security measure:
 * The _globalBlacklist state must be set at initialization time and, for evident
 * security reasons, cannot be changed afterward.
 *
 * @dev For further details, see "GlobalRestrictableUpgradeable" section of whitepaper.
 * @custom:security-contact [email protected]
 */
abstract contract GlobalRestrictableUpgradeable is Initializable {
    /**
     * @notice The GlobalBlacklist contract the blacklist state will be inherited from.
     * @dev This state is private so derived contracts cannot change its value.
     */
    GlobalBlacklist private _globalBlacklist;

    /**
     * @notice Initializer functions of the contract. They replace the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalBlacklist_ The address of the GlobalBlacklist contract.
     */
    function __GlobalRestrictable_init(address globalBlacklist_) internal onlyInitializing {
        __GlobalRestrictable_init_unchained(globalBlacklist_);
    }

    function __GlobalRestrictable_init_unchained(
        address globalBlacklist_
    ) internal onlyInitializing {
        _globalBlacklist = GlobalBlacklist(globalBlacklist_);
    }

    /**
     * @notice Retrieves the address of GlobalBlacklist contract.
     * @return The address of the GlobalBlacklist contract.
     */
    function globalBlacklist() public view returns (address) {
        return address(_globalBlacklist);
    }

    /**
     * @notice Reverts if the given account is blacklisted by the GlobalBlacklist contract.
     * @param account Address to verify.
     */
    modifier notBlacklisted(address account) {
        require(isBlacklisted(account) == false, "L9");
        _;
    }

    /**
     * @notice Checks if the given account is blacklisted by the GlobalBlacklist contract.
     * @param account Address to verify.
     * @return Whether the account is blacklisted.
     */
    function isBlacklisted(address account) internal view returns (bool) {
        return _globalBlacklist.isBlacklisted(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add
     * new variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Conracts
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {GlobalOwnableUpgradeable} from "./GlobalOwnableUpgradeable.sol";

// Libraries
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// Interfaces
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title RecoverableUpgradeable
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice Derived contracts are provided with helper functions allowing the recovery of
 * assets accidentally sent to them.
 *
 * @dev Where are utilities Ether, ERC721, etc.?
 * This abstract contract currently supports only ERC20 tokens. Derived contracts
 * in this codebase currently do not implement the necessary functions to receive Ether
 * or ERC721/ERC1155 tokens, so no recovery functions are provided for these assets.
 *
 * @dev For further details, see "RecoverableUpgradeable" section of whitepaper.
 * @custom:security-contact [email protected]
 */
abstract contract RecoverableUpgradeable is Initializable, GlobalOwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Initializer functions of the contract. They replace the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalOwner_ The address of the GlobalOwner contract.
     */
    function __Recoverable_init(address globalOwner_) internal onlyInitializing {
        __GlobalOwnable_init(globalOwner_);
        __Recoverable_init_unchained();
    }

    function __Recoverable_init_unchained() internal onlyInitializing {}

    /**
     * @notice Recovers a specified amount of a given token address. Will fail if the
     * contract doesn't hold enough tokens.
     * @param tokenAddress The address of the token to recover.
     * @param amount The amount of token to recover.
     */
    function recoverERC20(address tokenAddress, uint256 amount) public virtual onlyOwner {
        // Ensure the specified amount is not zero
        require(amount > 0, "L10");

        // Create a reference to token's contract
        IERC20Upgradeable tokenContract = IERC20Upgradeable(tokenAddress);

        // Ensure there is enough token to recover
        require(tokenContract.balanceOf(address(this)) >= amount, "L11");

        // Transfer the recovered token amount to the sender
        tokenContract.safeTransfer(_msgSender(), amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add
     * new variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {GlobalPausableUpgradeable} from "../GlobalPausableUpgradeable.sol";
import {GlobalOwnableUpgradeable} from "../GlobalOwnableUpgradeable.sol";
import {GlobalRestrictableUpgradeable} from "../GlobalRestrictableUpgradeable.sol";
import {RecoverableUpgradeable} from "../RecoverableUpgradeable.sol";

/**
 * @title BaseUpgradeable
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice This abstract contract acts as a base for numerous contracts in this codebase,
 * minimizing code repetition and enhancing readability and maintainability.
 *
 * @dev For further details, see "Base" section of whitepaper.
 * @custom:security-contact [email protected]
 */
abstract contract BaseUpgradeable is
    Initializable,
    UUPSUpgradeable,
    GlobalOwnableUpgradeable,
    GlobalPausableUpgradeable,
    GlobalRestrictableUpgradeable,
    RecoverableUpgradeable
{
    /**
     * @notice Prevents implementation contract from being initialized as recommended by
     * OpenZeppelin.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializer functions of the contract. They replace the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalOwner_ The address of the GlobalOwner contract.
     * @param globalPause_ The address of the GlobalPause contract.
     * @param globalBlacklist_ The address of the GlobalBlacklist contract.
     */
    function __Base_init(
        address globalOwner_,
        address globalPause_,
        address globalBlacklist_
    ) internal onlyInitializing {
        __UUPSUpgradeable_init();
        __GlobalOwnable_init(globalOwner_);
        __Pausable_init();
        __GlobalPausable_init_unchained(globalPause_);
        __GlobalRestrictable_init_unchained(globalBlacklist_);
        __Recoverable_init_unchained();
    }

    function __Base_init_unchained() internal onlyInitializing {}

    /**
     * @notice Override of UUPSUpgradeable._authorizeUpgrade() function restricted to
     * global owner. It is called by the proxy contract during an upgrade.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add
     * new variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}