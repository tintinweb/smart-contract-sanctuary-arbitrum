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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * IMPORTANT: This contract does not include public pause and unpause functions. In
 * addition to inheriting this contract, you must define both functions, invoking the
 * {Pausable-_pause} and {Pausable-_unpause} internal functions, with appropriate
 * access control, e.g. using {AccessControl} or {Ownable}. Not doing so will
 * make the contract unpausable.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC20Wrapper.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../utils/SafeERC20Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of the ERC20 token contract to support token wrapping.
 *
 * Users can deposit and withdraw "underlying tokens" and receive a matching number of "wrapped tokens". This is useful
 * in conjunction with other modules. For example, combining this wrapping mechanism with {ERC20Votes} will allow the
 * wrapping of an existing "basic" ERC20 into a governance token.
 *
 * _Available since v4.2._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20WrapperUpgradeable is Initializable, ERC20Upgradeable {
    IERC20Upgradeable private _underlying;

    function __ERC20Wrapper_init(IERC20Upgradeable underlyingToken) internal onlyInitializing {
        __ERC20Wrapper_init_unchained(underlyingToken);
    }

    function __ERC20Wrapper_init_unchained(IERC20Upgradeable underlyingToken) internal onlyInitializing {
        require(underlyingToken != this, "ERC20Wrapper: cannot self wrap");
        _underlying = underlyingToken;
    }

    /**
     * @dev See {ERC20-decimals}.
     */
    function decimals() public view virtual override returns (uint8) {
        try IERC20MetadataUpgradeable(address(_underlying)).decimals() returns (uint8 value) {
            return value;
        } catch {
            return super.decimals();
        }
    }

    /**
     * @dev Returns the address of the underlying ERC-20 token that is being wrapped.
     */
    function underlying() public view returns (IERC20Upgradeable) {
        return _underlying;
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account, uint256 amount) public virtual returns (bool) {
        address sender = _msgSender();
        require(sender != address(this), "ERC20Wrapper: wrapper can't deposit");
        SafeERC20Upgradeable.safeTransferFrom(_underlying, sender, address(this), amount);
        _mint(account, amount);
        return true;
    }

    /**
     * @dev Allow a user to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.
     */
    function withdrawTo(address account, uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        SafeERC20Upgradeable.safeTransfer(_underlying, account, amount);
        return true;
    }

    /**
     * @dev Mint wrapped token to cover any underlyingTokens that would have been transferred by mistake. Internal
     * function that can be exposed with access control if desired.
     */
    function _recover(address account) internal virtual returns (uint256) {
        uint256 value = _underlying.balanceOf(address(this)) - totalSupply();
        _mint(account, value);
        return value;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./BaseUpgradeable.sol";
import {GlobalPausableUpgradeable} from "../GlobalPausableUpgradeable.sol";

/**
 * @title ERC20BaseUpgradeable
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice This abstract contract is an extension of BaseUpgradeable intended to be used
 * as a base for ERC20 tokens contracts.
 *
 * @dev For further details, see "ERC20BaseUpgradeable" section of whitepaper.
 * @custom:security-contact [email protected]
 */
abstract contract ERC20BaseUpgradeable is
    ERC20Upgradeable,
    BaseUpgradeable,
    ERC20PausableUpgradeable
{
    /**
     * @notice Initializer functions of the contract. They replace the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalOwner_ The address of the GlobalOwner contract.
     * @param globalPause_ The address of the GlobalPause contract.
     * @param globalBlacklist_ The address of the GlobalBlacklist contract.
     * @param name_ The display name of the token.
     * @param symbol_ The symbol of the token.
     */
    function __ERC20Base_init(
        address globalOwner_,
        address globalPause_,
        address globalBlacklist_,
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __Base_init(globalOwner_, globalPause_, globalBlacklist_);
        __ERC20_init(name_, symbol_);
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Base_init_unchained() internal onlyInitializing {}

    /**
     * @notice Required override of paused() which is implemented by both
     * GlobalPausableUpgradeable and PausableUpgradeable parent contracts.
     * The GlobalPausableUpgradeable version is preferred because it checks the pause
     * state from the GlobalPause contract.
     * @inheritdoc GlobalPausableUpgradeable
     */
    function paused()
        public
        view
        virtual
        override(GlobalPausableUpgradeable, PausableUpgradeable)
        returns (bool)
    {
        return GlobalPausableUpgradeable.paused();
    }

    /**
     * @dev Required override of _beforeTokenTransfer() which is implemented by both
     * ERC20PausableUpgradeable and ERC20Upgradeable parent contracts.
     * The ERC20PausableUpgradeable version is preferred because it also checks that
     * the contract is not paused before allowing the transfer.
     * @inheritdoc ERC20PausableUpgradeable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override(ERC20PausableUpgradeable, ERC20Upgradeable)
        whenNotPaused
        notBlacklisted(from)
        notBlacklisted(to)
    {
        ERC20PausableUpgradeable._beforeTokenTransfer(from, to, amount);
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

// Contracts
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {GlobalOwnableUpgradeable} from "./GlobalOwnableUpgradeable.sol";
import {GlobalPausableUpgradeable} from "./GlobalPausableUpgradeable.sol";
import {GlobalRestrictableUpgradeable} from "./GlobalRestrictableUpgradeable.sol";
import "./base/BaseUpgradeable.sol";
import {RecoverableUpgradeable} from "../abstracts/RecoverableUpgradeable.sol";

// Libraries
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {APRHistory as APRH} from "../libs/APRHistory.sol";
import {SUD} from "../libs/SUD.sol";

// Interfaces
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title InvestUpgradeable
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice Derived contracts are provided with utilities to manage an invested token,
 * users' investment periods, rewards calculations, virtual balances, and auto-compounding.
 *
 * @dev Intuition:
 * This contract primarily exists for code splitting and reusability. It unburdens the
 * LToken contract code, making it easier to understand and maintain.
 *
 * This contract is generic because it may be used in the LDYStaking contract in the future.
 *
 * @dev Definitions:
 * - Investment: The act of depositing or investing tokens into the contract.
 * - Investment period: Time between the last invested amount change and the present.
 * - Virtual balance: Temporary storage for account rewards, used when those can't be
 *                    distributed between investment periods.
 * - Rewards redirection: Mechanism allowing an account to redirect its rewards to another.
 *
 * @dev Derived contract must:
 *  - Set invested token during initialization
 *  - Implement _investmentOf() function
 *  - (optionally) Implement _distributeRewards() function
 *
 * @dev For further details, see "InvestmentUpgradeable" section of whitepaper.
 * @custom:security-contact [email protected]
 */
abstract contract InvestUpgradeable is BaseUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using APRH for APRH.Pack[];

    /**
     * @notice Represents an account's investment period.
     * @param timestamp The timestamp of the most recent rewards distribution.
     * @param ref The reference of the last APR checkpoint at that timestamp.
     */
    struct InvestmentPeriod {
        uint40 timestamp; // Supports dates up to 20/02/36812
        APRH.Reference ref;
    }

    /**
     * @notice Represents the investment details of an account.
     * @param period The current investment period of the account.
     * @param virtualBalance May hold a part of account rewards until they are claimed.
     */
    struct AccountDetails {
        InvestmentPeriod period;
        uint256 virtualBalance;
    }

    /// @notice Holds a reference to the invested token's contract.
    IERC20Upgradeable private _invested;

    /// @notice Holds investment details of each account.
    mapping(address => AccountDetails) internal accountsDetails;

    /// @notice Holds an history of the APR value over time (see APRHistory.sol).
    APRH.Pack[] private _aprHistory;

    /// @notice Holds active rewards redirections in both from->to and to->from[] ways.
    mapping(address => address) public rewardsRedirectsFromTo;
    mapping(address => address[]) public rewardsRedirectsToFrom;

    /// @notice Is used to prevent infinite loop in _beforeInvestmentChange().
    bool private _isClaiming;

    /**
     * @notice Emitted to inform listeners about a change in the APR's value.
     * @param newAPRUD7x3 The new APR in UD7x3 format.
     */
    event APRChangeEvent(uint16 newAPRUD7x3);

    /**
     * @notice Initializer functions of the contract. They replace the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalOwner_ The address of the GlobalOwner contract.
     * @param globalPause_ The address of the GlobalPause contract.
     * @param globalBlacklist_ The address of the GlobalBlacklist contract.
     * @param invested_ The address of the invested token contract.
     */
    function __Invest_init(
        address globalOwner_,
        address globalPause_,
        address globalBlacklist_,
        address invested_
    ) internal onlyInitializing {
        __Base_init(globalOwner_, globalPause_, globalBlacklist_);
        __Invest_init_unchained(invested_);
    }

    function __Invest_init_unchained(address invested_) internal onlyInitializing {
        // Set invested token
        _invested = IERC20Upgradeable(invested_);

        // Define initial APR to 0%. This would prevent getAPR() from reverting because
        // of an empty APR history
        _aprHistory.setAPR(0);
    }

    /**
     * @notice Retrieves the reference to the invested token contract.
     * @return The reference to the invested token contract.
     */
    function invested() public view returns (IERC20Upgradeable) {
        return _invested;
    }

    /**
     * @notice Updates the investment APR. Restricted to owner.
     * @param aprUD7x3 The new APR in UD7x3 format.
     */
    function setAPR(uint16 aprUD7x3) public onlyOwner {
        _aprHistory.setAPR(aprUD7x3);
        emit APRChangeEvent(aprUD7x3);
    }

    /**
     * @notice Retrieves the most recently set APR.
     * @return The current APR in UD7x3 format.
     */
    function getAPR() public view returns (uint16) {
        return _aprHistory.getAPR();
    }

    /**
     * @notice Enables redirection of rewards from one account to another.
     * @param from The address of the account to redirect rewards from.
     * @param to The address of the account to redirect rewards to.
     */
    function startRewardsRedirection(
        address from,
        address to
    ) public whenNotPaused notBlacklisted(from) notBlacklisted(to) {
        // Ensure the address is not already redirecting rewards
        require(rewardsRedirectsFromTo[from] == address(0), "L62");

        // Ensure neither 'from' nor 'to' are the zero address
        require(from != address(0), "L12");
        require(to != address(0), "L13");

        // Ensure 'from' and 'to' addresses are distinct
        require(from != to, "L14");

        // Ensure function caller is either the owner or the 'from' address
        require(_msgSender() == owner() || _msgSender() == from, "L15");

        // Distribute current rewards and reset investment periods of both accounts
        _beforeInvestmentChange(from, true);
        _beforeInvestmentChange(to, true);

        // Activate rewards redirection
        rewardsRedirectsFromTo[from] = to;
        rewardsRedirectsToFrom[to].push(from);
    }

    /**
     * @notice Disable an active rewards redirection.
     * @param from The address of the account to stop redirecting rewards from.
     * @param to The address of the account to stop redirecting rewards to.
     */
    function stopRewardsRedirection(
        address from,
        address to
    ) public whenNotPaused notBlacklisted(from) notBlacklisted(to) {
        // Ensure neither 'from' nor 'to' are the zero address
        require(from != address(0), "L16");
        require(to != address(0), "L17");

        // Ensure function caller is either the owner or the 'from' address
        require(_msgSender() == owner() || _msgSender() == from, "L18");

        // Ensure a rewards redirection was active
        require(rewardsRedirectsFromTo[from] == to, "L19");

        // Distribute current rewards and reset investment periods of both accounts
        _beforeInvestmentChange(from, true);
        _beforeInvestmentChange(to, true);

        // Retrieve 'from' index in the redirection array of 'to'
        int256 fromIndex = -1;
        for (uint256 i = 0; i < rewardsRedirectsToFrom[to].length; i++) {
            if (rewardsRedirectsToFrom[to][i] == from) {
                fromIndex = int256(i);
                break;
            }
        }

        // fromIndex should never be -1 at this point
        assert(fromIndex >= 0);

        // Deactivate rewards redirection
        rewardsRedirectsFromTo[from] = address(0);
        rewardsRedirectsToFrom[to][uint256(fromIndex)] = rewardsRedirectsToFrom[to][
            rewardsRedirectsToFrom[to].length - 1
        ];
        rewardsRedirectsToFrom[to].pop();
    }

    /**
     * @notice Retrieves the total amount of tokens invested by the given account.
     * @dev Derived contracts must implement this function.
     * @param account The account to get the investment of.
     * @return The total amount of tokens invested by the given account.
     */
    function _investmentOf(address account) internal view virtual returns (uint256);

    /**
     * @notice Distributes a specified amount of rewards to a given account.
     * @dev Derived contracts may optionally implement this function.
     * @dev Implementations must return true to indicate a successful distribution, and
     * false otherwise. If it returns false, the rewards will be added to the account's
     * virtual balance, in order to be claimed later.
     * @param account The account to claim the rewards of.
     * @param amount The amount of rewards to claim.
     * @return Whether the rewards distribution was successfull.
     */
    function _distributeRewards(address account, uint256 amount) internal virtual returns (bool) {
        account; // Silence unused variables warning
        amount;
        return false;
    }

    /**
     * @notice Computes the rewards accrued over a specified period of time, based on a
     * given APR and amount of invested tokens.
     * @dev For further details, see "InvestUpgradeable > Rewards calculation" section of
     * the whitepaper.
     * @param beginTimestamp The moment the period commenced.
     * @param endTimestamp The moment the period concluded.
     * @param aprUD7x3 The APR during this period, in UD7x3 format.
     * @param investedAmount The amount of tokens deposited/invested during the period.
     * @return The amount of rewards generated during the period.
     */
    function _calculatePeriodRewards(
        uint40 beginTimestamp,
        uint40 endTimestamp,
        uint16 aprUD7x3,
        uint256 investedAmount
    ) internal view returns (uint256) {
        // Cache invested token's decimals number
        uint256 d = SUD.decimalsOf(address(invested()));

        // Compute the number of elapsed years
        uint256 elapsedTimeSUD = SUD.fromInt(endTimestamp - beginTimestamp, d);
        uint256 elapsedYearsSUD = (elapsedTimeSUD * SUD.fromInt(1, d)) / SUD.fromInt(365 days, d);

        // Compute the growth in invested amount (thanks to rewards)
        uint256 aprSUD = SUD.fromRate(aprUD7x3, d);
        uint256 growthSUD = (elapsedYearsSUD * aprSUD) / SUD.fromInt(1, d);

        // Compute and return the rewards
        uint256 investedAmountSUD = SUD.fromAmount(investedAmount, d);
        uint256 rewardsSUD = (investedAmountSUD * growthSUD) / SUD.fromInt(100, d);
        return SUD.toAmount(rewardsSUD, d);
    }

    /**
     * @notice Computes the sum of given account's invested amount, plus invested amount
     * of all accounts that recursively redirect rewards to this account.
     * @param account The account to calculate the deep investment of.
     * @return deepInvestedAmount The deep invested amount.
     */
    function _deepInvestmentOf(address account) internal view returns (uint256 deepInvestedAmount) {
        // Consider account's direct investment
        deepInvestedAmount += _investmentOf(account);

        // But also the deep investments of all accounts redirecting rewards to this account
        for (uint256 i = 0; i < rewardsRedirectsToFrom[account].length; i++) {
            deepInvestedAmount += _deepInvestmentOf(rewardsRedirectsToFrom[account][i]);
        }
    }

    /**
     * @notice Computes the amount of unclaimed/undistributed rewards of a given account.
     * @dev For further details, see "InvestUpgradeable > Rewards calculation" section of
     * the whitepaper.
     * @param account The account to calculate the unclaimed rewards of.
     * @param autocompound Whether to autocompound the rewards between APR checkpoints.
     * @return rewards The amount of unclaimed/undistributed rewards of the given account.
     */
    function _rewardsOf(
        address account,
        bool autocompound
    ) internal view returns (uint256 rewards) {
        // Retrieve account's investment details
        AccountDetails memory details = accountsDetails[account];

        // Retrieve account's deep invested amount
        uint256 investedAmount = _deepInvestmentOf(account);

        // Return 0 if the account has never invested or has no invested amount
        if (details.period.timestamp == 0 || investedAmount == 0) return 0;

        // Retrieve reference and data of APR checkpoint at which started investment period
        APRH.Reference memory currRef = details.period.ref;
        APRH.CheckpointData memory currCheckpoint = _aprHistory.getDataFromReference(currRef);

        // Retrieve reference of latest APR checkpoint
        APRH.Reference memory latestRef = _aprHistory.getLatestReference();

        // 1) Fill rewards with virtual balance (rewards not claimed/distributed yet)
        // See "InvestUpgradeable > Yield calculation > 1)" section of the whitepaper
        rewards = details.virtualBalance;

        // If start checkpoint is not the latest one
        if (!APRH.eq(currRef, latestRef)) {
            // Retrieve reference and data of APR checkpoint that comes after start checkpoint
            APRH.Reference memory nextRef = APRH.incrementReference(currRef);
            APRH.CheckpointData memory nextCheckpoint = _aprHistory.getDataFromReference(nextRef);

            // 2) Calculate rewards from investment period start to next checkpoint
            // See "InvestUpgradeable > Yield calculation > 2)" section of the whitepaper
            rewards += _calculatePeriodRewards(
                details.period.timestamp,
                nextCheckpoint.timestamp,
                currCheckpoint.aprUD7x3,
                investedAmount + (autocompound ? rewards : 0)
            );

            // 3) Calculate rewards for each crossed pair of checkpoints
            // See "InvestUpgradeable > Yield calculation > 3)" section of the whitepaper
            while (true) {
                // Set next checkpoint as the current one
                currRef = nextRef;
                currCheckpoint = nextCheckpoint;

                // Break if current checkpoint is the latest one
                if (APRH.eq(currRef, latestRef)) break;

                // Else, retrieve the new next checkpoint
                nextRef = APRH.incrementReference(currRef);
                nextCheckpoint = _aprHistory.getDataFromReference(nextRef);

                // Calculate rewards between the current pair of checkpoints
                rewards += _calculatePeriodRewards(
                    currCheckpoint.timestamp,
                    nextCheckpoint.timestamp,
                    currCheckpoint.aprUD7x3,
                    investedAmount + (autocompound ? rewards : 0)
                );
            }

            // 4) Calculate rewards from the latest checkpoint to now
            // See "InvestUpgradeable > Yield calculation > 4)" section of the whitepaper
            rewards += _calculatePeriodRewards(
                currCheckpoint.timestamp,
                uint40(block.timestamp),
                currCheckpoint.aprUD7x3,
                investedAmount + (autocompound ? rewards : 0)
            );
        } else {
            // 2.bis) Calculate rewards from investment period start to now
            // See "InvestUpgradeable > Yield calculation > 2.bis)" section of the whitepaper
            rewards += _calculatePeriodRewards(
                details.period.timestamp,
                uint40(block.timestamp),
                currCheckpoint.aprUD7x3,
                investedAmount + (autocompound ? rewards : 0)
            );
        }
    }

    /**
     * @notice Recursively resets the investment period of the specified account and of
     * all accounts that directly or indirectly redirect rewards to this account.
     * @param account The account to deeply reset the investment period of.
     */
    function _deepResetInvestmentPeriodOf(address account) internal {
        // Reset account investment period timestamp and APR checkpoint to latest ones
        accountsDetails[account].period.timestamp = uint40(block.timestamp);
        accountsDetails[account].period.ref = _aprHistory.getLatestReference();

        // Also reset the ones of all accounts that recursively redirect rewards to this account
        for (uint256 i = 0; i < rewardsRedirectsToFrom[account].length; i++) {
            _deepResetInvestmentPeriodOf(rewardsRedirectsToFrom[account][i]);
        }
    }

    /**
     * @notice Hook to be invoked before the invested amount of an account changes. It
     * ensures that rewards are distributed and that account's investment period is reset.
     * @param account The account whose invested amount is going to change.
     * @param autocompound Whether to autocompound the rewards between APR checkpoints.
     */
    function _beforeInvestmentChange(address account, bool autocompound) internal {
        // This hook is called inside LToken._beforeTokenTransfer() and as new tokens are
        // minted in LToken._distributeRewards(), this guards against infinite loop.
        if (_isClaiming) return;

        // LToken._beforeTokenTransfer() calls this hook for both involved addresses.
        // As first call will treat both addresses, the second call would be redundant.
        // Therefore, we skip accounts already processed in this block to save up some gas.
        if (accountsDetails[account].period.timestamp == uint40(block.timestamp)) return;

        // If account redirects its rewards
        address redirectRewardsTo = rewardsRedirectsFromTo[account];
        if (redirectRewardsTo != address(0)) {
            // Call hook on redirection target (this will indirectly reset the investment
            // of this source account) and return
            _beforeInvestmentChange(redirectRewardsTo, autocompound);
            return;
        }

        // Else, compute account's undistributed/unclaimed rewards
        uint256 rewards = _rewardsOf(account, autocompound);

        // If there are some rewards
        if (rewards > 0) {
            // Try to distribute rewards to account
            _isClaiming = true;
            bool distributed = _distributeRewards(account, rewards);
            _isClaiming = false;

            // If rewards have not been distributed, accumulate them in account's virtual balance
            if (!distributed) accountsDetails[account].virtualBalance = rewards;
        }

        // Finally, deeply reset investment period of the account
        _deepResetInvestmentPeriodOf(account);
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

interface ITransfersListener {
    function onLTokenTransfer(address from, address to, uint256 amount) external;
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

/**
 * @title APRHistory
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice This library offers utilities to efficiently maintain the history of an
 * on-chain APR (Annual Percentage Rate) state. Each entry in this history is called
 * a "checkpoint".
 *
 * @dev Intuition:
 * Each checkpoint in an APR history consists of two data:
 * - the creation timestamp
 * - the APR at that time
 *
 * Given that reading and writing to storage slots are among the most costly operations
 * in Solidity, this library provides a way to store those data in a way that minimizes
 * the number of used storage slots.
 *
 * Instead of storing each checkpoint in a separate storage slot, this library
 * facilitates the packing of up to 4 checkpoints in a single storage slot.
 *
 * @dev Definitions:
 * - Checkpoint: A record of an APR change
 * - Pack: A collection of 4 checkpoints stored in a single storage slot
 * - History: A dynamic array of packs
 * - Reference: A storage pointer to a checkpoint in the APR history
 * - CheckpointData: An in-memory representation of a checkpoint data
 *
 * @dev Value limitation:
 * This library can accommodate APRs only up to 65.536%. This is however sufficient for
 * APR in LToken contract, which is expected to remain below 10%.
 *
 * @dev For further details, see "APRHistory" section of whitepaper.
 * @custom:security-contact [email protected]
 */
library APRHistory {
    /**
     * @notice Represents data of a checkpoint extracted from the on-chain history.
     * For on-chain representation see "Pack" struct.
     * @param aprUD7x3 APR in UD7x3 format (e.g., 12345 = 12.345%).
     * @param timestamp Timestamp of the checkpoint's creation.
     */
    struct CheckpointData {
        uint16 aprUD7x3; // Allows up to 65.536%
        uint40 timestamp; // Supports dates up to 20/02/36812
    }

    /**
     * @notice Represents how APR checkpoints are stored on chain. Each pack can contain
     * the data 4 checkpoints. Packs are then stored in a dynamic array (the history).
     * @param aprsUD7x3 Array of checkpoints' APRs.
     * @param timestamps Array of checkpoints' timestamps.
     * @param cursor Index of the next checkpoint to be written.
     */
    struct Pack {
        uint16[4] aprsUD7x3;
        uint40[4] timestamps;
        uint32 cursor;
    }

    /**
     * @notice Represents a storage pointer to a specific checkpoint in the history.
     * @param packIndex Index of the pack the checkpoint belongs to.
     * @param cursorIndex Index of the checkpoint in this pack (between 0 and 3).
     */
    struct Reference {
        uint256 packIndex;
        uint32 cursorIndex;
    }

    /**
     * @notice Compares two checkpoints references.
     * @param ref1 The first reference to compare.
     * @param ref2 The second reference to compare.
     * @return Whether the two references points to the same checkpoint.
     */
    function eq(Reference memory ref1, Reference memory ref2) external pure returns (bool) {
        return ref1.packIndex == ref2.packIndex && ref1.cursorIndex == ref2.cursorIndex;
    }

    /**
     * @notice Returns the reference of the checkpoint that should come right after the
     * referenced checkpoint in the APR history.
     * @param ref The reference to be incremented.
     * @return The incremented reference.
     */
    function incrementReference(Reference memory ref) public pure returns (Reference memory) {
        // Ensure cursor index of the given ref is within valid range [0, 3]
        require(ref.cursorIndex <= 3, "L1");

        // If the given ref is the last slot in its pack, return ref of next pack's first slot
        if (ref.cursorIndex == 3) return Reference(ref.packIndex + 1, 0);
        //
        // Else, return ref of next slot in current pack
        else return Reference(ref.packIndex, ref.cursorIndex + 1);
    }

    /**
     * @notice Extracts checkpoint data from a given reference and in APR history.
     * @param self The APR history to extract the checkpoint from.
     * @param ref The reference of the checkpoint data to extract.
     * @return The extracted checkpoint's data.
     */
    function getDataFromReference(
        Pack[] storage self,
        Reference memory ref
    ) public view returns (CheckpointData memory) {
        // Ensure cursor index of the given ref is within valid range [0, 3]
        require(ref.cursorIndex <= 3, "L2");

        // Ensure pack index of the given ref exists in history
        require(ref.packIndex < self.length, "L3");

        // Retrieve pack data from history
        Pack memory pack = self[ref.packIndex];

        // Ensure cursor index of the given ref has been written
        require(ref.cursorIndex < pack.cursor, "L4");

        // Build and return the checkpoint data
        return
            CheckpointData({
                aprUD7x3: pack.aprsUD7x3[ref.cursorIndex],
                timestamp: pack.timestamps[ref.cursorIndex]
            });
    }

    /**
     * @notice Retrieves the reference to the most recently added checkpoint in the APR history.
     * @param self The history to extract the reference from.
     * @return The reference of the latest checkpoint.
     */
    function getLatestReference(Pack[] storage self) public view returns (Reference memory) {
        // Ensure the given history is not empty
        require(self.length != 0, "L5");

        // Retrieve latest pack's index and cursor
        uint256 packIndex = self.length - 1;
        uint32 packCursor = self[packIndex].cursor;

        // If this is the first pack ever, ensure it is not empty
        if (packIndex == 0) require(packCursor != 0, "L6");

        // If the pack is empty, return ref of previous pack's latest slot
        if (packCursor == 0) return Reference(packIndex - 1, 3);
        //
        // Else, return ref of previous slot in current pack
        else return Reference(packIndex, packCursor - 1);
    }

    /**
     * @notice Appends a new empty pack to the end of the given APR history array.
     * @param self The APR history to append an empty to.
     */
    function newBlankPack(Pack[] storage self) internal {
        // If history is not empty, ensure the latest pack is full
        require(self.length == 0 || getLatestReference(self).cursorIndex == 3, "L7");

        // Push a new blank pack to the history array
        self.push(
            Pack({
                aprsUD7x3: [uint16(0), uint16(0), uint16(0), uint16(0)],
                timestamps: [uint40(0), uint40(0), uint40(0), uint40(0)],
                cursor: 0
            })
        );
    }

    /**
     * @notice Write a new APR checkpoint at the end of the given history array.
     * @param self The array of packs to write the new checkpoint to.
     * @param aprUD7x3 The new APR in UD7x3 format.
     */
    function setAPR(Pack[] storage self, uint16 aprUD7x3) external {
        // Determine the reference where the new checkpoint should be written
        Reference memory newRef = self.length == 0
            ? Reference(0, 0)
            : incrementReference(getLatestReference(self));

        // If pack to be written doesn't exist yet, push a new blank pack in history
        if (newRef.packIndex >= self.length) newBlankPack(self);

        // Retrieve the pack where the new checkpoint will be stored
        Pack memory pack = self[newRef.packIndex];

        // Add new checkpoint's data to the pack
        pack.aprsUD7x3[newRef.cursorIndex] = aprUD7x3;
        pack.timestamps[newRef.cursorIndex] = uint40(block.timestamp);

        // Increment the pack's cursor
        pack.cursor++;

        // Write the updated pack in storage
        self[newRef.packIndex] = pack;
    }

    /**
     * @notice Retrieves the APR of the latest checkpoint written in the APR history.
     * @param self The history array to read APR from.
     * @return The latest checkpoint's APR.
     */
    function getAPR(Pack[] storage self) public view returns (uint16) {
        // Retrieve the latest checkpoint data
        Reference memory ref = getLatestReference(self);
        CheckpointData memory data = getDataFromReference(self, ref);

        // Return the latest checkpoint's APR
        return data.aprUD7x3;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title SUD
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice SUD serves as an intermediary number format for calculations within this
 * codebase. It ensures consistency and reduces precision losses. This library
 * facilitates conversions between various number formats and the SUD format.
 *
 * @dev Intuition:
 * This codebase employs the UD (unsigned decimal fixed-point numbers) format to
 * represent both percentage rates and tokens amounts.
 *
 * Rates are expressed in UD7x3 format, whereas the format for tokens amounts depends on
 * the decimals() value of the involved tokens.
 *
 * Three challenges arise from this:
 *   1) To compute values together, it's essential that they are in the same format
 *   2) Calculations involving consecutive divisions on UD numbers lead to accumulated
 *      precision loss (because division shrinks). A common approach is to scale up and
 *      down values by a few decimals before and after performing calculations.
 *   3) Given that rates use the UD7x3 format, if we decided to scale them to and from
 *      the number of decimals of the involved token, 1 to 3 of the rates' decimals would
 *      be shrunk in case token's decimals number is in [0, 2].
 *
 * To address these challenges, this library provides the SUD format, which acts as a
 * consistent and scaled intermediate format to perform calculations.
 *
 * SUD is an acronym for either "Scaled UD" or "Safe UD".
 *
 * @dev Definitions:
 * - Integer: A number without fractional part, e.g., block.timestamp
 * - UD: A decimal unsigned fixed-point number. The "UD" notation is inspired from
 *       libraries like [prb-math](https://github.com/PaulRBerg/prb-math/)
 * - Amount: A token amount. A UD with an unknown repartition of digits between integral
 *           and fractional parts (as token amounts have variable decimal numbers)
 * - Rate: A percentage rate. An UD with 7 integral digits and 3 fractional ones (= UD7x3)
 * - SUD: An intermediate format to perform calculations involving Rates and Amounts. A UD
 *        with 3 more decimals than the involved UD with the highest decimals number. As
 *        rates are represented by UD7x3, a SUD number has at least 6 decimals (3+3) and
 *        so ranges from UD71x6 to UD0x77 formats.
 *
 * @dev A conversion library:
 * This library provides utilities to perform the following conversions:
 * - Amount       <--> SUD
 * - Rate (UD7x3) <--> SUD
 * - Integer      <--> SUD
 *
 * @dev Why scaling by 3 decimals?
 * - It provides an adequate degree of precision for this codebase,
 * - It enables the conversion of a UD7x3 rate to SUD format by merely scaling it up by
 *   the involved token's decimal number, so is gas efficient.
 *
 * @dev Why internal functions?
 * The functions of this library are not set to external because incorporating them
 * directly into contracts is more gas-efficient. Given their minimal size and frequent
 * usage in the InvestUpgradeable, LDYStaking, and LToken contracts, any bytecode savings
 * from making them external are negated by the additional bytecode required for external
 * calls to this library. This can be observed by comparing the output of `bun cc:size`
 * when those functions's visibility is set to external or internal.
 *
 * @dev Precision warning:
 * While this library mitigates precision loss during calculations on UD numbers, it's
 * important to note that tokens with lower decimal counts and supply inherently suffer
 * more from precision loss. Conversely, tokens with higher decimal counts and supply
 * will experience less precision loss.
 *
 * @dev For further details, see "SUD" section of whitepaper.
 * @custom:security-contact [email protected]
 */
library SUD {
    /**
     * @notice Retrieves decimals number of the given ERC20 contract address.
     * @param tokenAddress The address to retrieve decimals number from.
     * @return decimals The decimals number of the given ERC20 contract address.
     */
    function decimalsOf(address tokenAddress) internal view returns (uint256 decimals) {
        return IERC20MetadataUpgradeable(tokenAddress).decimals();
    }

    /**
     * @notice Convert a given token amount into SUD format.
     * @param nAmount The token amount to convert.
     * @param decimals The decimals number of the involved ERC20 token.
     * @return nSUD The amount in SUD format
     */
    function fromAmount(uint256 nAmount, uint256 decimals) internal pure returns (uint256 nSUD) {
        // If token decimals < 3, return a UD71x6 number
        if (decimals < 3) return nAmount * 10 ** (6 - decimals);

        // Else return a number with decimals+3 fractional digits
        return nAmount * 10 ** 3;
    }

    /**
     * @notice Convert a given SUD number into token amount format.
     * @param nSUD The SUD number to convert.
     * @param decimals The decimals number of the involved ERC20 token.
     * @return nAmount The number in amount format
     */
    function toAmount(uint256 nSUD, uint256 decimals) internal pure returns (uint256 nAmount) {
        // If token decimals < 3, convert from a UD71x6 number
        if (decimals < 3) return nSUD / 10 ** (6 - decimals);

        // Else, convert from a number with decimals+3 fractional digits
        return nSUD / 10 ** 3;
    }

    /**
     * @notice Converts a given UD7x3 rate into SUD format.
     * @param nUD7x3 The UD7x3 rate to convert.
     * @param decimals The decimals number of the involved ERC20 token.
     * @return nSUD The rate in SUD format.
     */
    function fromRate(uint256 nUD7x3, uint256 decimals) internal pure returns (uint256 nSUD) {
        // If token decimals < 3, return a UD71x6 number
        if (decimals < 3) return nUD7x3 * 10 ** 3;

        // Else, return a number with decimals+3 fractional digits
        return nUD7x3 * 10 ** decimals;
    }

    /**
     * @notice Converts a given SUD number into a UD7x3 rate.
     * @param nSUD The SUD number to convert.
     * @param decimals The decimals number of the involved ERC20 token.
     * @return nUD7x3 The number in UD7x3 rate format.
     */
    function toRate(uint256 nSUD, uint256 decimals) internal pure returns (uint256 nUD7x3) {
        // If token decimals < 3, convert from a UD71x6 number
        if (decimals < 3) return nSUD / 10 ** 3;

        // Else, convert from a number with decimals+3 fractional digits
        return nSUD / 10 ** decimals;
    }

    /**
     * @notice Converts a given integer into SUD format.
     * @param n The integer to convert.
     * @param decimals The decimals number of the involved ERC20 token.
     * @return nSUD The integer in SUD format.
     */
    function fromInt(uint256 n, uint256 decimals) internal pure returns (uint256 nSUD) {
        // If token decimals < 3, return a UD71x6 number
        if (decimals < 3) return n * 10 ** 6;

        // Else, return a number with decimals+3 fractional digits
        return n * 10 ** (decimals + 3);
    }

    /**
     * @notice Converts a given SUD number as an integer (all decimals shrinked).
     * @param nSUD The SUD number to convert.
     * @param decimals The decimals number of the involved ERC20 token.
     * @return n The SUD number as an integer.
     */
    function toInt(uint256 nSUD, uint256 decimals) internal pure returns (uint256 n) {
        // If token decimals < 3, convert from a UD71x6 number
        if (decimals < 3) return nSUD / 10 ** 6;

        // Else, convert from a number with decimals+3 fractional digits
        return nSUD / 10 ** (decimals + 3);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Contracts
import {ERC20WrapperUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20WrapperUpgradeable.sol";
import "./abstracts/base/ERC20BaseUpgradeable.sol";
import {InvestUpgradeable} from "./abstracts/InvestUpgradeable.sol";
import {LDYStaking} from "./LDYStaking.sol";

// Libraries
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SUD} from "./libs/SUD.sol";

// Interfaces
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {ITransfersListener} from "./interfaces/ITransfersListener.sol";

/**
 * @title LToken
 * @author Lila Rest (https://lila.rest)
 * @custom:security-contact [email protected]
 *
 * @notice Main contract of the Ledgity Yield protocol. It powers every L-Token (i.e.,
 * investment pools backed by RWA). An L-Token is an ERC20 wrapper around a stablecoin.
 * As soon as a wallet holds some L-Tokens, it starts receiving rewards in
 * the form of additional L-Tokens, which are auto-compounded over time.
 *
 * @dev Definitions:
 * - Deposit: Swap of underlying tokens for L-Tokens (1:1 ratio).
 * - Withdrawal: Swap of L-Tokens for underlying tokens (1:1 ratio, minus applicable fees).
 *   - Instant: Processed immediately.
 *   - Request: Queued for later processing.
 *   - Big Request: A requested withdrawal exceeding half of the retention rate.
 * - (Withdrawal) queue: A list of all requested withdrawals sorted by priority.
 * - Request ID: The index of a withdrawal request in the queue array.
 * - Retention rate: Maximum fraction of underlying tokens TVL the contract can retain.
 * - Fees Rate: Percentage of fees applied to successful withdrawals.
 * - Usable underlyings: Amount of underlying tokens that have been deposited through
 *                       expected ways and are so considered safe to use by the contract.
 * - Transfers listeners: External contracts listening on L-Tokens transfers.
 * - Fund wallet: Wallet managed by the Ledgity's financial team.
 * - Withdrawer wallet: Managed by an off-chain server to automate withdrawal request
 *                      processing.
 *
 * Note that words between parenthesis are sometimes omitted for brevity.
 *
 * @dev Deployment notice:
 * This contract can safely receive funds immediately after initialization. (i.e., there
 * is no way for funds to be sent to non-owned addresses). It is, however, recommended to
 * replace ASAP owner and fund wallets with multi-sig wallets.
 *
 * @dev For further details, see "LToken" section of whitepaper.
 * @custom:oz-upgrades-unsafe-allow external-library-linking
 * @custom:security-contact [email protected]
 */
contract LToken is ERC20BaseUpgradeable, InvestUpgradeable, ERC20WrapperUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Represents type of actions triggering ActivityEvent events.
    enum Action {
        Deposit,
        Withdraw
    }

    /// @dev Represents different status of actions triggering ActivityEvent events.
    enum Status {
        Queued,
        Cancelled,
        Success,
        Moved
    }

    /**
     * @notice Represents a withdrawal request in the queue.
     * @dev A request fits in a single storage slot (32 bytes).
     * @param account The account that initiated the request.
     * @param amount The amount of underlying tokens requested.
     */
    struct WithdrawalRequest {
        address account; // 20 bytes
        uint96 amount; // 12 bytes
    }

    /// @notice Upper limit of retention rate.
    uint32 private constant MAX_RETENTION_RATE_UD7x3 = 10 * 10 ** 3; // 10%

    /// @notice Upper limit of fees rate.
    uint32 private constant MAX_FEES_RATE_UD7x3 = 20 * 10 ** 3; // 20%

    /// @notice Used in activity events to represent the absence of request ID.
    int256 private constant NO_ID = -1;

    /// @notice Holds a reference to the LDYStaking contract.
    LDYStaking public ldyStaking;

    /// @notice Holds address of withdrawer wallet (managed by withdrawal server).
    address payable public withdrawer;

    /// @notice Holds address of fund wallet (managed by Ledgity financial team).
    address public fund;

    /// @notice Holds the withdrawal fees rate in UD7x3 format (e.g., 350 = 0.350%).
    uint32 public feesRateUD7x3;

    /// @notice Holds the retention rate in UD7x3 format.
    uint32 public retentionRateUD7x3;

    /// @notice Holds the amount of withdrawal fees not yet claimed by contract's owner.
    uint256 public unclaimedFees;

    /// @notice Holds the amount of L-Tokens currently in the withdrawal queue.
    uint256 public totalQueued;

    /**
     * @notice Holds the amount of underlying tokens considered as usable by the contract.
     * @dev Are usable, only underlying tokens deposit through deposit() or fund() functions.
     */
    uint256 public usableUnderlyings;

    /// @notice Holds an ordered list of active withdrawal requests.
    WithdrawalRequest[] public withdrawalQueue;

    /// @notice Holds the index of the next withdrawal request to process in the queue.
    uint256 public withdrawalQueueCursor;

    /**
     * @notice Holds a list of all currently frozen withdrawal requests.
     * @dev If a request emitter as been blacklisted, its request is moved here to prevent
     * it from blocking the queue.
     */
    WithdrawalRequest[] public frozenRequests;

    /**
     * @notice Holds a list of contracts' references that are listening to L-Tokens transfers.
     * @dev onLTokenTransfer() functions of those contracts will be called on each transfer.
     */
    ITransfersListener[] public transfersListeners;

    /**
     * @notice Holds the withdrwalFee amount in ETH that will be sent to withdrawer wallet.
     */
    uint256 public withdrwalFeeInEth;

    /**
     * @notice Emitted to inform listeners about a change in the contract's TVL.
     * @dev TVL = realTotalSupply()
     * @param newTVL The new TVL of the contract.
     */
    event TVLChangeEvent(uint256 newTVL);

    /**
     * @notice Emitted to inform listerners about an activity related to deposits and withdrawals.
     * @param id ID of the involved withdrawal request or NO_ID (-1) if not applicable.
     * @param account The account involved in the activity.
     * @param action The type of activity.
     * @param amount The amount of underlying tokens involved in the activity.
     * @param newStatus The new status of the activity.
     * @param newId The new ID of the request if it has been moved in the queue.
     */
    event ActivityEvent(
        int256 indexed id,
        address indexed account,
        Action indexed action,
        uint256 amount,
        uint256 amountAfterFees,
        Status newStatus,
        int256 newId
    );

    /**
     * @notice Emitted to inform listeners that some rewards have been minted.
     * @param account The account that received the rewards.
     * @param balanceBefore The balance of the account before the minting.
     * @param rewards The amount of minted rewards.
     */
    event MintedRewardsEvent(address indexed account, uint256 balanceBefore, uint256 rewards);

    /// @notice Reverts if the function caller is not the withdrawer wallet.
    modifier onlyWithdrawer() {
        require(_msgSender() == withdrawer, "L39");
        _;
    }

    /// @notice Reverts if the function caller is not the fund wallet.
    modifier onlyFund() {
        require(_msgSender() == fund, "L40");
        _;
    }

    /**
     * @notice Initializer function of the contract. It replaces the constructor()
     * function in the context of upgradeable contracts.
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
     * @param globalOwner_ The address of the GlobalOwner contract.
     * @param globalPause_ The address of the GlobalPause contract.
     * @param globalBlacklist_ The address of the GlobalBlacklist contract.
     * @param underlyingToken The address of the underlying stablecoin ERC20 token.
     */
    function initialize(
        address globalOwner_,
        address globalPause_,
        address globalBlacklist_,
        address ldyStaking_,
        address underlyingToken
    ) public initializer {
        // Initialize ERC20 base.
        string memory underlyingSymbol = IERC20MetadataUpgradeable(underlyingToken).symbol();
        __ERC20Base_init(
            globalOwner_,
            globalPause_,
            globalBlacklist_,
            string(abi.encodePacked("Ledgity ", underlyingSymbol)),
            string(abi.encodePacked("L", underlyingSymbol))
        );

        // IMPORTANT: Below calls must not be restricted to owner at any point.
        // This is because the GlobalOwner contract may not be a fresh one, and so
        // the contract deployer may not be the owner anymore after ERC20Base init.

        // Initialize other parents contracts.
        __ERC20Wrapper_init(IERC20Upgradeable(underlyingToken));
        __Invest_init_unchained(address(this));

        // Set LDYStaking contract
        ldyStaking = LDYStaking(ldyStaking_);

        // Set initial withdrawal fees rate to 0.3%
        feesRateUD7x3 = 300;

        // Set initial retention rate to 10%
        retentionRateUD7x3 = 10_000;

        // Default withdrawer and fund wallet to contract owner address. This prevents
        // any loss of funds if a deposit/withdrawal is made before those are manually set.
        withdrawer = payable(owner());
        fund = payable(owner());

        // Set initial withdrwalFeeInEth
        withdrwalFeeInEth = 0.00075 * 1e18;
    }

    /**
     * @notice Required override of decimals() which is implemented by both
     * ERC20Upgradeable and ERC20WrapperUpgradeable parent contracts.
     * @dev The ERC20WrapperUpgradeable version is preferred because it mirrors the
     * decimals amount of the underlying stablecoin token.
     * @inheritdoc ERC20WrapperUpgradeable
     */
    function decimals()
        public
        view
        override(ERC20Upgradeable, ERC20WrapperUpgradeable)
        returns (uint8)
    {
        return ERC20WrapperUpgradeable.decimals();
    }

    /**
     * @notice Required override of paused() which is implemented by both
     * GlobalPausableUpgradeable and ERC20BaseUpgradeable parent contracts.
     * @dev Both version are the same as ERC20BaseUpgradeable.paused() mirrors
     * GlobalPausableUpgradeable.paused(), so a random one is chosen.
     * @inheritdoc GlobalPausableUpgradeable
     */
    function paused()
        public
        view
        virtual
        override(GlobalPausableUpgradeable, ERC20BaseUpgradeable)
        returns (bool)
    {
        return GlobalPausableUpgradeable.paused();
    }

    /**
     * @notice Updates the current withdrawal fee rate.
     * @param feesRateUD7x3_ The new withdrawal fee rate in UD7x3 format.
     */
    function setFeesRate(uint32 feesRateUD7x3_) public onlyOwner {
        require(feesRateUD7x3_ <= MAX_FEES_RATE_UD7x3, "L88");
        feesRateUD7x3 = feesRateUD7x3_;
    }

    /**
     * @notice Updates the current withdrawalFeeInETH.
     * @param withdrwalFeeInEth_ The new withdrawalFee in ETH.
     */
    function setWithdrwalFeeInEth(uint256 withdrwalFeeInEth_) public onlyOwner {
        require(withdrwalFeeInEth <= MAX_FEES_RATE_UD7x3, "L88");
        withdrwalFeeInEth = withdrwalFeeInEth_;
    }

    /**
     * @notice Updates the current underlying token retention rate.
     * @dev The retention rate is capped at 10%, which ensures that no more than 10% of
     * deposited assets will ever be exposed in this contract (reduces attack surface).
     * @param retentionRateUD7x3_ The new retention rate in UD7x3 format.
     */
    function setRetentionRate(uint32 retentionRateUD7x3_) public onlyOwner {
        require(retentionRateUD7x3_ <= MAX_RETENTION_RATE_UD7x3, "L41");
        retentionRateUD7x3 = retentionRateUD7x3_;
    }

    /**
     * @notice Updates the address of LDYStaking contract.
     * @param ldyStakingAddress The address of the new LDYStaking contract.
     */
    function setLDYStaking(address ldyStakingAddress) public onlyOwner {
        ldyStaking = LDYStaking(ldyStakingAddress);
    }

    /**
     * @notice Updates the address of the withdrawer wallet.
     * @param withdrawer_ The address of the new withdrawer wallet.
     */
    function setWithdrawer(address payable withdrawer_) public onlyOwner {
        // Ensure address is not the zero address (pre-processing fees would be lost else)
        require(withdrawer_ != address(0), "L63");

        // Set new withdrawer wallet's address
        withdrawer = withdrawer_;
    }

    /**
     * @notice Updates the address of the fund wallet.
     * @param fund_ The address of the new fund wallet.
     */
    function setFund(address payable fund_) public onlyOwner {
        // Ensure address is not the zero address (deposited tokens would be lost else)
        require(fund_ != address(0), "L64");

        // Set new fund wallet's address
        fund = fund_;
    }

    /**
     * @notice Adds a new contract to the L-Token transfers list.
     * @dev Each time a transfer occurs, the onLTokenTransfer() function of the
     * specified contract will be called.
     * @dev IMPORTANT SECURITY NOTE: This method is not intended to be used with
     * contracts that are not owned by the Ledgity team.
     * @param listenerContract The address of the new transfers listener contract.
     */
    function listenToTransfers(address listenerContract) public onlyOwner {
        transfersListeners.push(ITransfersListener(listenerContract));
    }

    /**
     * @notice Removes a contract from the L-Token transfers list.
     * @dev The onLTokenTransfer() function of the specified contract will not be called
     * anymore each time a L-Token transfer occurs.
     * @param listenerContract The address of the listener contract.
     */
    function unlistenToTransfers(address listenerContract) public onlyOwner {
        // Find index of listener contract in transferListeners array
        int256 index = -1;
        uint256 transfersListenersLength = transfersListeners.length;
        for (uint256 i = 0; i < transfersListenersLength; i++) {
            if (address(transfersListeners[i]) == listenerContract) {
                index = int256(i);
                break;
            }
        }

        // Revert if given contract wasn't listening to transfers
        require(index > -1, "L42");

        // Else, remove transfers listener contract from listeners array
        transfersListeners[uint256(index)] = transfersListeners[transfersListenersLength - 1];
        transfersListeners.pop();
    }

    /**
     * @notice Retrieves the amount of given account's not yet minted rewards.
     * @dev This is a public implementation of InvestUpgradeable_rewardsOf(). In the
     * context of LToken, this function returns the amount of rewards that have not been
     * distributed/minted yet to the specified account.
     * @dev This is particularly useful for off-chain services to display charts and
     * statistics, as seen in the Ledgity Yield's frontend.
     * @param account The account to check the unminted rewards of.
     * @return The amount of account's unminted rewards.
     */
    function unmintedRewardsOf(address account) public view returns (uint256) {
        return _rewardsOf(account, true);
    }

    /**
     * @notice Retrieves the "real" balance of an account, i.e., excluding its not yet
     * minted/distributed rewards.
     * @param account The account to check the real balance of.
     * @return The real balance of the account.
     */
    function realBalanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    /**
     * @notice Retrieves the total balance of L-Tokens that belong to the account.
     * @dev This is an oOverride of ERC20Upgradeable.balanceOf() that rewards that have
     * not been yet minted to the specified account.
     * @param account The account to check the total balance of.
     * @return The total balance of the account.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return realBalanceOf(account) + unmintedRewardsOf(account);
    }

    /**
     * @notice Returns the "real" amount of existing L-Tokens, i.e., excluding not yet
     * minted withdrawal fees and L-Tokens currently in the withdrawal queue.
     * @return The real total supply of L-Tokens.
     */
    function realTotalSupply() public view returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @notice Retrives the total supply of L-Tokens, including not yet minted withdrawal
     * fees and L-Tokens currently in the withdrawal queue.
     * @return The total supply of L-Tokens.
     */
    function totalSupply() public view override returns (uint256) {
        return realTotalSupply() + totalQueued + unclaimedFees;
    }

    /**
     * @notice Recovers a specified amount of a given token address.
     * @dev This override of RecoverableUpgradeable.recoverERC20() prevents the recovered
     * token from being the underlying token.
     * @inheritdoc RecoverableUpgradeable
     */
    function recoverERC20(address tokenAddress, uint256 amount) public override onlyOwner {
        // Ensure the token is not the underlying token
        require(tokenAddress != address(underlying()), "L43");

        // Proceed to recovery
        super.recoverERC20(tokenAddress, amount);
    }

    /**
     * @notice Recovers underlying tokens accidentally sent to the contract.
     * @dev To prevent owner from being able to drain the contract, this function only
     * allows recovering "unusable" underlying tokens, i.e., tokens that have not been
     * sent through fund() or deposit() functions.
     */
    function recoverUnderlying() external onlyOwner {
        // Compute the recoverable amount by taking the difference between the contract's
        // balance and the amount of usable underlying tokens
        uint256 recoverableAmount = underlying().balanceOf(address(this)) - usableUnderlyings;

        // Revert if there is nothing to recover
        require(recoverableAmount > 0, "L44");

        // Else, proceed to underlying tokens recovery
        super.recoverERC20(address(underlying()), recoverableAmount);
    }

    /**
     * @notice Retrieves the amount of underlying tokens invested by the given account.
     * @dev Implementing this function is required by the InvestUpgradeable contract. In
     * LToken contract, the investment of an account is equal to its real balance.
     * @inheritdoc InvestUpgradeable
     */
    function _investmentOf(address account) internal view override returns (uint256) {
        return realBalanceOf(account);
    }

    /**
     * @notice Distributes a specified amount of rewards (in L-Tokens) to a given account.
     * @dev Implementing this function is required by the InvestUpgradeable contract so
     * it can distribute rewards to accounts before each period reset.
     * @dev InvestUpgradeable contract already ensure that amount > 0.
     * @inheritdoc InvestUpgradeable
     */
    function _distributeRewards(address account, uint256 amount) internal override returns (bool) {
        // Inform listeners of the rewards minting
        emit MintedRewardsEvent(account, realBalanceOf(account), amount);

        // Mint L-Tokens rewards to account
        _mint(account, amount);

        // Return true indicating to InvestUpgradeable that the rewards have been distributed
        return true;
    }

    /**
     * @notice Override of ERC20._beforeTokenTransfer() to integrate with InvestUpgradeable.
     * @dev This overriden version ensure that _beforeInvestmentChange() hook is properly
     * called each time an account's balance is going to change.
     * @dev Note: whenNotPaused and notBlacklisted modifiers are not set as they are
     * already included in ERC20BaseUpgradeable._beforeTokenTransfer().
     * @inheritdoc ERC20BaseUpgradeable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20BaseUpgradeable) {
        ERC20BaseUpgradeable._beforeTokenTransfer(from, to, amount);

        // Invoke _beforeInvestmentChange() hook for non-zero accounts
        if (from != address(0)) _beforeInvestmentChange(from, true);
        if (to != address(0)) _beforeInvestmentChange(to, true);
    }

    /**
     * @notice Override of ERC20._afterTokenTransfer() to notify all transfers listeners.
     * @dev This overriden version will trigger onLTokenTransfer() functions of all
     * transfers listeners.
     * @dev Note: whenNotPaused and notBlacklisted modifiers are not set as they are
     * already checked in _beforeTokenTransfer().
     * @inheritdoc ERC20Upgradeable
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        super._afterTokenTransfer(from, to, amount);

        // If some L-Token have been burned/minted, inform listeners of a TVL change
        if (from == address(0) || to == address(0)) emit TVLChangeEvent(totalSupply());

        // Trigger onLTokenTransfer() functions of all the transfers listeners
        for (uint256 i = 0; i < transfersListeners.length; i++) {
            transfersListeners[i].onLTokenTransfer(from, to, amount);
        }
    }

    /**
     * @notice Computes the maximum amount of underlying tokens that should be retained
     * by the contract (based on retention rate).
     * @return amount The expected amount of retained underlying tokens.
     */
    function getExpectedRetained() public view returns (uint256 amount) {
        // Cache invested token's decimals number
        uint256 d = SUD.decimalsOf(address(invested()));

        // Convert totalSupply and retentionRate to SUD
        uint256 totalSupplySUD = SUD.fromAmount(totalSupply(), d);
        uint256 retentionRateSUD = SUD.fromRate(retentionRateUD7x3, d);

        // Compute and return expected retained amount
        uint256 expectedRetainedSUD = (totalSupplySUD * retentionRateSUD) / SUD.fromInt(100, d);
        return SUD.toAmount(expectedRetainedSUD, d);
    }

    /// @notice Transfers underlying tokens exceeding the retention rate to the fund wallet.
    function _transferExceedingToFund() internal {
        // Retrieve the expected amount retained
        uint256 expectedRetained = getExpectedRetained();

        // If usable underlyings are less than or equal to expected retained, return
        if (usableUnderlyings <= expectedRetained) return;

        // Else, exceeding amount is equal to difference between those values
        uint256 exceedingAmount = usableUnderlyings - expectedRetained;

        // Decrease usable underlyings amount accordingly
        usableUnderlyings -= exceedingAmount;

        // Transfer the exceeding amount to the fund wallet
        underlying().safeTransfer(fund, exceedingAmount);
    }

    /**
     * @notice Override of ERC20WrapperUpgradeable.withdrawTo() that reverts.
     * Use instantWithdrawal() or requestWithdrawal() functions instead.
     * @inheritdoc ERC20WrapperUpgradeable
     */
    function withdrawTo(address account, uint256 amount) public pure override returns (bool) {
        account; // Silence unused variable compiler warning
        amount;
        revert("L45");
    }

    /**
     * @notice Override of ERC20WrapperUpgradeable.depositFor() that reverts.
     * Use deposit() function instead.
     * @inheritdoc ERC20WrapperUpgradeable
     */
    function depositFor(address account, uint256 amount) public pure override returns (bool) {
        account; // Silence unused variable compiler warning
        amount;
        revert("L46");
    }

    /**
     * @notice Allows exchanging some underlying tokens for the same amount of L-Tokens.
     * @param amount The amount of underlying tokens to deposit.
     */
    function deposit(uint256 amount) public whenNotPaused notBlacklisted(_msgSender()) {
        // Ensure the account has enough underlying tokens to deposit
        require(underlying().balanceOf(_msgSender()) >= amount, "L47");

        // Update usable underlyings balance accordingly
        usableUnderlyings += amount;

        // Inform listeners of the deposit activity event
        emit ActivityEvent(
            NO_ID,
            _msgSender(),
            Action.Deposit,
            amount,
            amount,
            Status.Success,
            NO_ID
        );

        // Receive underlying tokens and mint L-Tokens to the account in a 1:1 ratio
        super.depositFor(_msgSender(), amount);

        // Transfer exceeding underlying tokens to the fund wallet
        _transferExceedingToFund();
    }

    /**
     * @notice Computes fees and net withdrawn amount for a given account withdrawing a
     * given amount.
     * @param account The account initiating the withdrawal.
     * @param amount The amount of the withdrawal.
     */
    function getWithdrawnAmountAndFees(
        address account,
        uint256 amount
    ) public view returns (uint256 withdrawnAmount, uint256 fees) {
        // If the account is eligible to staking tier 2, no fees are applied
        if (ldyStaking.tierOf(account) >= 2) return (amount, 0);

        // Cache invested token's decimals number
        uint256 d = SUD.decimalsOf(address(invested()));

        // Convert amount and fees rate to SUD
        uint256 amountSUD = SUD.fromAmount(amount, d);
        uint256 feesRateSUD = SUD.fromRate(feesRateUD7x3, d);

        // Compute fees and withdrawn amount (initial amount minus fees)
        uint256 feesSUD = (amountSUD * feesRateSUD) / SUD.fromInt(100, d);
        fees = SUD.toAmount(feesSUD, d);
        withdrawnAmount = amount - fees;
    }

    /**
     * @notice Allows instaneously exchanging a given amount of L-Tokens for the same
     * amount of underlying tokens. It will fail if the contract currently doesn't hold
     * enough underlying tokens to cover the withdrawal.
     * @dev In order to save some gas and time to users, frontends should propose this
     * function to users only when it has been verified that it will not revert. They
     * should propose the requestWithdrawal() function otherwise.
     * @param amount The amount L-Tokens to withdraw.
     */
    function instantWithdrawal(uint256 amount) external whenNotPaused notBlacklisted(_msgSender()) {
        // Ensure the account has enough L-Tokens to withdraw
        require(amount <= balanceOf(_msgSender()), "L48");

        // Can the contract cover this withdrawal plus all already queued requests?
        bool cond1 = totalQueued + amount <= usableUnderlyings;

        // Is caller eligible to staking tier 2 and the contract can cover this withdrawal?
        bool cond2 = ldyStaking.tierOf(_msgSender()) >= 2 && amount <= usableUnderlyings;

        // Revert if conditions are not met for the withdrawal to be processed instantaneously
        if (!(cond1 || cond2)) revert("L49");

        // Else, retrieve withdrawal fees and net withdrawn amount
        (uint256 withdrawnAmount, uint256 fees) = getWithdrawnAmountAndFees(_msgSender(), amount);

        // Increase unclaimed fees amount accordingly
        unclaimedFees += fees;

        // Decrease usable underlyings balance accordingly
        usableUnderlyings -= withdrawnAmount;

        // Inform listeners of this instant withdrawal activity event
        emit ActivityEvent(
            NO_ID,
            _msgSender(),
            Action.Withdraw,
            amount,
            withdrawnAmount,
            Status.Success,
            NO_ID
        );

        // Burn withdrawal fees from the account
        _burn(_msgSender(), fees);

        // Burn account's withdrawn L-Tokens and transfer to it underlying tokens in a 1:1 ratio
        super.withdrawTo(_msgSender(), withdrawnAmount);
    }

    /**
     * @notice Allows requesting the exchange of a given amount of L-Tokens for the same
     * amount of underlying tokens. The request will be automatically processed later.
     * @dev The sender must attach withdrwalFeeInETH to pre-pay the future processing gas fees
     * paid by the withdrawer wallet.
     * @param amount The amount L-Tokens to withdraw.
     */
    function requestWithdrawal(
        uint256 amount
    ) public payable whenNotPaused notBlacklisted(_msgSender()) {
        // Ensure the account has enough L-Tokens to withdraw
        require(amount <= balanceOf(_msgSender()), "L53");

        // Ensure the requested amount doesn't overflow uint96
        require(amount <= type(uint96).max, "L54");

        // Ensure the sender attached the pre-paid processing gas fees
        require(msg.value == withdrwalFeeInEth, "L55");

        // Create withdrawal request data
        WithdrawalRequest memory request = WithdrawalRequest({
            account: _msgSender(),
            amount: uint96(amount)
        });

        // Will hold the request ID
        uint256 requestId;

        // Append request to the withdrawal queue:
        // - At the beginning, if account is eligible to staking tier 2 and cursor is not 0
        if (ldyStaking.tierOf(_msgSender()) >= 2 && withdrawalQueueCursor > 0) {
            withdrawalQueueCursor--;
            requestId = withdrawalQueueCursor;
            withdrawalQueue[requestId] = request;
        }
        // - At the end else
        else {
            withdrawalQueue.push(request);
            requestId = withdrawalQueue.length - 1;
        }

        // Increase total amount queued accordingly
        totalQueued += amount;

        // Inform listeners of this new queued withdrawal activity event
        emit ActivityEvent(
            int256(requestId),
            _msgSender(),
            Action.Withdraw,
            amount,
            amount,
            Status.Queued,
            NO_ID
        );

        // Burn withdrawal L-Tokens amount from account's balance
        _burn(_msgSender(), amount);

        // Forward pre-paid processing gas fees to the withdrawer wallet
        (bool sent, ) = withdrawer.call{value: msg.value}("");
        require(sent, "L56");
    }

    /**
     * @notice Processes queued withdrawal requests until there is else no more requests,
     * else not enough underlying tokens to continue.
     * @dev For further details, see "LToken  > Withdrawals" section of whitepaper.
     */
    function processQueuedRequests() external onlyWithdrawer whenNotPaused {
        // Accumulators variables, will be written on-chain after the loop
        uint256 cumulatedFees = 0;
        uint256 cumulatedWithdrawnAmount = 0;
        uint256 nextRequestId = withdrawalQueueCursor;

        // Cache queue length to avoid multiple SLOADs and avoid infinite loop as big
        // requests are increasing the queue length when moved at the end of the queue.
        uint256 queueLength = withdrawalQueue.length;

        // Iterate over requests to be processed
        while (nextRequestId < queueLength) {
            // Stop processing requests if there is not enough gas left to continue the
            // loop and properly end the function call. This prevents an attacker from
            // blocking the withdrawal processing by creating a ton of tiny requests so
            // this function call cannot fit anymore in block gas limit.
            if (gasleft() < 45000) break;

            // Retrieve request data
            WithdrawalRequest memory request = withdrawalQueue[nextRequestId];

            // Skip empty request (processed big requests or cancelled requests)
            if (request.account == address(0)) {}
            //
            // If account has been blacklisted since request emission
            else if (isBlacklisted(request.account)) {
                // Remove request from queue
                delete withdrawalQueue[nextRequestId];

                // Append request in the frozen requests list
                frozenRequests.push(request);
            }
            //
            // Or if request is a big request, move it at the end of the queue for now.
            // This request will be processed manually later using processBigQueuedRequest()
            else if (request.amount > getExpectedRetained() / 2) {
                // Inform listeners of this queued request being moved at the end of the queue
                emit ActivityEvent(
                    int256(nextRequestId),
                    _msgSender(),
                    Action.Withdraw,
                    request.amount,
                    request.amount,
                    Status.Moved,
                    int256(withdrawalQueue.length)
                );

                // Remove request from queue
                delete withdrawalQueue[nextRequestId];

                // Append request at the end of the queue
                withdrawalQueue.push(request);
            }
            //
            // Else, continue request processing
            else {
                // Retrieve withdrawal fees and net withdrawn amount
                (uint256 withdrawnAmount, uint256 fees) = getWithdrawnAmountAndFees(
                    request.account,
                    request.amount
                );

                // Break if the contract doesn't hold enough funds to cover the request
                if (withdrawnAmount > usableUnderlyings - cumulatedWithdrawnAmount) break;

                // Accumulate fees and withdrawn amount
                cumulatedFees += fees;
                cumulatedWithdrawnAmount += withdrawnAmount;

                // Inform listeners of this queued withdrawal processing activity event
                emit ActivityEvent(
                    int256(nextRequestId),
                    request.account,
                    Action.Withdraw,
                    request.amount,
                    withdrawnAmount,
                    Status.Success,
                    NO_ID
                );

                // Remove request from queue
                delete withdrawalQueue[nextRequestId];

                // Transfer underlying tokens to account. Burning L-Tokens is not required
                // as equestWithdrawal() already did it.
                // Security note: Re-entrancy warning are disabled as the request has
                // just been deleted from the queue, it will so be skipped if trying to
                // process it again.
                // slither-disable-next-line reentrancy-no-eth
                underlying().safeTransfer(request.account, withdrawnAmount);
            }

            // Increment next request ID
            nextRequestId++;
        }

        // Increase unclaimed fees by the amount of cumulated fees
        unclaimedFees += cumulatedFees;

        // Decrease usable underlyings by the cumulated amount of withdrawn underlyings
        usableUnderlyings -= cumulatedWithdrawnAmount;

        // Decrease total amount queued by the cumulated amount requested
        totalQueued -= cumulatedWithdrawnAmount + cumulatedFees;

        // Update new queue cursor
        withdrawalQueueCursor = nextRequestId;

        // Retention rate cannot exceeds as the withdrawal decreases both usable
        // underlyings and expected retained amounts by the same number and as the
        // expected retained amount is a subset of usable underlyings amount.
    }

    /**
     * @notice Processes a given queued big withdrawal request (one that exceeds half of
     * the retention rate).
     * @dev In contrast to non-big requests processing, this function will uses to fund
     * wallet's balance to fill the request. This allows processing requests that are
     * greater than retention rate without having to exceed this rate on the contract.
     * @param requestId The ID of the big request to process.
     */
    function processBigQueuedRequest(uint256 requestId) external onlyFund whenNotPaused {
        // Retrieve request data
        WithdrawalRequest memory request = withdrawalQueue[requestId];

        // Ensure the request is active
        require(request.account != address(0), "L66");

        // Ensure the request emitter has not been blacklisted since request emission
        require(!isBlacklisted(request.account), "L50");

        // Ensure this is indeed a big request
        require(request.amount > getExpectedRetained() / 2, "L51");

        // Retrieve withdrawal fees and net withdrawn amount
        (uint256 withdrawnAmount, uint256 fees) = getWithdrawnAmountAndFees(
            request.account,
            request.amount
        );

        // Ensure withdrawn amount can be covered by contract + fund wallet balances
        uint256 fundBalance = underlying().balanceOf(fund);
        require(withdrawnAmount <= usableUnderlyings + fundBalance, "L52");

        // Increase amount of unclaimed fees accordingly
        unclaimedFees += fees;

        // Decrease total queued amount by request amount
        totalQueued -= request.amount;

        // Increment queue cursor if request was the next request to be processed
        if (requestId == withdrawalQueueCursor) withdrawalQueueCursor++;

        // Inform listeners of this queued withdrawal processing activity event
        emit ActivityEvent(
            int256(requestId),
            request.account,
            Action.Withdraw,
            request.amount,
            withdrawnAmount,
            Status.Success,
            NO_ID
        );

        // Remove request from queue
        delete withdrawalQueue[requestId];

        // If fund wallet's balance can cover request, rely on it only
        if (withdrawnAmount <= fundBalance) {
            underlying().safeTransferFrom(_msgSender(), request.account, withdrawnAmount);
        }
        // Else, cover request from both fund wallet and contract balances
        else {
            // Compute amount missing from fund wallet to cover request
            uint256 missingAmount = withdrawnAmount - fundBalance;

            // Decrease usable amount of underlying tokens accordingly
            usableUnderlyings -= missingAmount;

            // Transfer entire fund balance to request's emitter
            underlying().safeTransferFrom(_msgSender(), request.account, fundBalance);

            // Transfer missing amount from contract balance to request emitter
            underlying().safeTransfer(request.account, missingAmount);
        }

        // Transfer exceeding underlying tokens to the fund wallet
        _transferExceedingToFund();
    }

    /**
     * @notice Cancels a given withdrawal request. The request emitter receive back its
     * L-Tokens and no fees will be charged.
     * @param requestId The ID of the withdrawal request to cancel.
     */
    function cancelWithdrawalRequest(
        uint256 requestId
    ) public whenNotPaused notBlacklisted(_msgSender()) {
        // Retrieve request data
        WithdrawalRequest memory request = withdrawalQueue[requestId];

        // Ensure request belongs to caller
        require(_msgSender() == request.account, "L57");

        // Decrease total amount queued accordingly
        totalQueued -= request.amount;

        // Delete the withdrawal request from queue
        delete withdrawalQueue[requestId];

        // Inform listeners of this cancelled withdrawal request activity event
        emit ActivityEvent(
            int256(requestId),
            request.account,
            Action.Withdraw,
            request.amount,
            request.amount,
            Status.Cancelled,
            NO_ID
        );

        // Mint back L-Tokens to account
        _mint(request.account, uint256(request.amount));
    }

    /**
     * @notice Used by the fund wallet to repatriate underlying tokens on the contract
     * whenever those are required to fulfill some withdrawal requests.
     * @dev The function will revert if repatriated amount makes the contract exceeding
     * the retention rate.
     * @param amount The amount of underlying tokens to repatriate.
     */
    function repatriate(uint256 amount) external onlyFund whenNotPaused {
        // Ensure the fund wallet has enough funds to repatriate
        require(amount <= underlying().balanceOf(fund), "L58");

        // Calculate new contract usable balance
        uint256 newBalance = usableUnderlyings + amount;

        // Ensure the new balance doesn't exceed the retention rate
        require(newBalance <= getExpectedRetained(), "L59");

        // Increase usable underlyings amount by repatriated amount
        usableUnderlyings += amount;

        // Transfer amount from fund wallet to contract
        underlying().safeTransferFrom(_msgSender(), address(this), amount);
    }

    /// @notice Used by owner to claim fees generated from successful withdrawals.
    function claimFees() external onlyOwner {
        // Ensure there are some fees to claim
        require(unclaimedFees > 0, "L60");

        // Ensure the contract holds enough underlying tokens to cover fees
        require(usableUnderlyings >= unclaimedFees, "L61");

        // Decrease usable underlyings amount accordingly
        usableUnderlyings -= unclaimedFees;

        // Store fees amount in memory and reset unclaimed fees amount
        uint256 fees = unclaimedFees;
        unclaimedFees = 0;

        // Transfer unclaimed fees to owner
        underlying().safeTransfer(owner(), fees);
    }
}