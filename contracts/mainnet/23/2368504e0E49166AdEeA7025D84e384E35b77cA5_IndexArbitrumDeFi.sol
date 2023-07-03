// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

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
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
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
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
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
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
 * ```
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IndexStrategyUpgradeable } from "../bases/IndexStrategyUpgradeable.sol";
import { IChainlinkAggregatorV3 } from "../dependencies/IChainlinkAggregatorV3.sol";
import { Constants } from "../libraries/Constants.sol";
import { Errors } from "../libraries/Errors.sol";
import { SwapAdapter } from "../libraries/SwapAdapter.sol";

/**
 * @dev Contract IndexArbitrum is an extension of IndexStrategyUpgradeable.
 */
contract IndexArbitrum is IndexStrategyUpgradeable {
    /**
     * @dev Calculates the equity valuation.
     * @param maximize Boolean value to maximize.
     * @param includeAmmPrice Boolean value to include AMM price.
     * @return The equity valuation as a uint256.
     */
    function equityValuation(bool maximize, bool includeAmmPrice)
        public
        view
        override
        returns (uint256)
    {
        uint256 totalSupply = indexToken.totalSupply();

        if (totalSupply == 0) {
            return 0;
        }

        uint256 amountWNATIVEUnit = _getAmountWNATIVEFromExactIndex(
            Constants.PRECISION
        );

        uint256 priceWNATIVE = oracle.getPrice(
            wNATIVE,
            maximize,
            includeAmmPrice
        );

        return
            (amountWNATIVEUnit * priceWNATIVE * totalSupply) /
            (Constants.DECIMALS * Constants.PRECISION);
    }

    /**
     * @dev Adds a swap route.
     * @param token The token address.
     * @param router The router address.
     * @param dex The DEX.
     * @param pair The pair address.
     */
    function addSwapRoute(
        address token,
        address router,
        SwapAdapter.DEX dex,
        address pair
    ) external onlyOwner {
        SwapAdapter.PairData memory pairData = SwapAdapter.PairData(
            pair,
            abi.encode(0)
        );

        addSwapRoute(token, router, dex, pairData);
    }

    /**
     * @dev Adds a swap route with a bin step.
     * @param token The token address.
     * @param router The router address.
     * @param dex The DEX.
     * @param pair The pair address.
     * @param binStep The bin step as a uint256.
     */
    function addSwapRoute(
        address token,
        address router,
        SwapAdapter.DEX dex,
        address pair,
        uint256 binStep
    ) external onlyOwner {
        SwapAdapter.PairData memory pairData = SwapAdapter.PairData(
            pair,
            abi.encode(binStep)
        );

        addSwapRoute(token, router, dex, pairData);
    }

    /**
     * @dev Adds a swap route with a factory.
     * @param token The token address.
     * @param router The router address.
     * @param dex The DEX.
     * @param pair The pair address.
     * @param factory The factory address.
     */
    function addSwapRoute(
        address token,
        address router,
        SwapAdapter.DEX dex,
        address pair,
        address factory
    ) external onlyOwner {
        SwapAdapter.PairData memory pairData = SwapAdapter.PairData(
            pair,
            abi.encode(factory)
        );

        addSwapRoute(token, router, dex, pairData);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { ERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import { IIndexInit } from "../interfaces/IIndexInit.sol";
import { IIndexLimits } from "../interfaces/IIndexLimits.sol";
import { IIndexOracle } from "../interfaces/IIndexOracle.sol";
import { IIndexStrategy } from "../interfaces/IIndexStrategy.sol";
import { IIndexToken } from "../interfaces/IIndexToken.sol";
import { Constants } from "../libraries/Constants.sol";
import { Errors } from "../libraries/Errors.sol";
import { SwapAdapter } from "../libraries/SwapAdapter.sol";

/**
 * @title IndexStrategyUpgradeable
 * @dev An abstract contract that implements various interfaces and extends other contracts, providing functionality for managing index strategies.
 */
abstract contract IndexStrategyUpgradeable is
    ERC165Upgradeable,
    ReentrancyGuardUpgradeable,
    ContextUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    IIndexInit,
    IIndexLimits,
    IIndexStrategy
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SwapAdapter for SwapAdapter.Setup;

    struct MintingData {
        uint256 amountIndex;
        uint256 amountWNATIVETotal;
        uint256[] amountWNATIVEs;
        address[] bestRouters;
        uint256[] amountComponents;
    }

    address public wNATIVE;

    address[] public whitelistedTokens;
    IIndexToken public indexToken;

    address[] public components;
    mapping(address => uint256) public weights; // A mapping from `component` to its `weight`.
    mapping(address => address[]) public routers; // A mapping from `token` to its list of `routers`.
    mapping(address => SwapAdapter.DEX) public dexs; // A mapping from `router` to its type of `DEX`.
    mapping(address => mapping(address => mapping(address => SwapAdapter.PairData))) // A mapping from `router`, `tokenIn` and `tokenOut` to `PairData`.
        public pairData;

    IIndexOracle public oracle;
    uint256 public equityValuationLimit;

    uint256[8] private __gap;

    /**
     * @dev Modifier to allow only whitelisted tokens to access a function.
     * @param token The address of the token to check.
     */
    modifier onlyWhitelistedToken(address token) {
        if (!isTokenWhitelisted(token)) {
            revert Errors.Index_NotWhitelistedToken(token);
        }

        _;
    }

    /**
     * @dev Modifier to check if the equity valuation limit has not been reached.
     */
    modifier whenNotReachedEquityValuationLimit() {
        _;

        if (equityValuation(true, true) > equityValuationLimit) {
            revert Errors.Index_ExceedEquityValuationLimit();
        }
    }

    /**
     * @dev Initializes the IndexStrategyUpgradeable contract.
     * @param initParams The parameters needed for initialization.
     */
    // solhint-disable-next-line
    function __IndexStrategyUpgradeable_init(
        IndexStrategyInitParams calldata initParams
    ) internal onlyInitializing {
        __ERC165_init();
        __ReentrancyGuard_init();
        __Context_init();
        __Ownable_init();
        __Pausable_init();

        wNATIVE = initParams.wNATIVE;

        indexToken = IIndexToken(initParams.indexToken);

        for (uint256 i = 0; i < initParams.components.length; i++) {
            components.push(initParams.components[i].token);

            _setWeight(
                initParams.components[i].token,
                initParams.components[i].weight
            );
        }

        for (uint256 i = 0; i < initParams.swapRoutes.length; i++) {
            addSwapRoute(
                initParams.swapRoutes[i].token,
                initParams.swapRoutes[i].router,
                initParams.swapRoutes[i].dex,
                initParams.swapRoutes[i].pairData
            );
        }

        addWhitelistedTokens(initParams.whitelistedTokens);

        setOracle(initParams.oracle);

        setEquityValuationLimit(initParams.equityValuationLimit);
    }

    /**
     * @dev Pauses the contract, preventing certain functions from being called.
     */
    function pause() external onlyOwner {
        super._pause();
    }

    /**
     * @dev Unpauses the contract, allowing the paused functions to be called.
     */
    function unpause() external onlyOwner {
        super._unpause();
    }

    /**
     * @dev Checks if a particular interface is supported by the contract.
     * @param interfaceId The interface identifier.
     * @return A boolean value indicating whether the interface is supported.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IIndexStrategy).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Mints index tokens in exchange for a specified token.
     * @param token The address of the token to be swapped.
     * @param amountTokenMax The maximum amount of the token to be swapped.
     * @param amountIndexMin The minimum amount of index tokens to be minted.
     * @param recipient The address that will receive the minted index tokens.
     * @return amountIndex The amount of index tokens minted.
     * @return amountToken The amount of tokens swapped.
     */
    function mintIndexFromToken(
        address token,
        uint256 amountTokenMax,
        uint256 amountIndexMin,
        address recipient
    )
        external
        nonReentrant
        whenNotPaused
        onlyWhitelistedToken(token)
        whenNotReachedEquityValuationLimit
        returns (uint256 amountIndex, uint256 amountToken)
    {
        if (recipient == address(0)) {
            revert Errors.Index_ZeroAddress();
        }

        address bestRouter;
        MintingData memory mintingData;

        (amountToken, bestRouter, mintingData) = _getMintingDataFromToken(
            token,
            amountTokenMax
        );

        if (amountToken > amountTokenMax) {
            revert Errors.Index_AboveMaxAmount();
        }

        if (mintingData.amountIndex < amountIndexMin) {
            revert Errors.Index_BelowMinAmount();
        }

        amountIndex = mintingData.amountIndex;

        IERC20Upgradeable(token).safeTransferFrom(
            _msgSender(),
            address(this),
            amountToken
        );

        uint256 amountTokenSpent = _swapTokenForExactToken(
            bestRouter,
            mintingData.amountWNATIVETotal,
            amountToken,
            token,
            wNATIVE
        );

        if (amountTokenSpent != amountToken) {
            revert Errors.Index_WrongSwapAmount();
        }

        uint256 amountWNATIVESpent = _mintExactIndexFromWNATIVE(
            mintingData,
            recipient
        );

        if (amountWNATIVESpent != mintingData.amountWNATIVETotal) {
            revert Errors.Index_WrongSwapAmount();
        }

        emit Mint(_msgSender(), recipient, token, amountToken, amountIndex);
    }

    /**
     * @dev Burns index tokens in exchange for a specified token.
     * @param token The address of the token to be received.
     * @param amountTokenMin The minimum amount of tokens to be received.
     * @param amountIndex The amount of index tokens to be burned.
     * @param recipient The address that will receive the tokens.
     * @return amountToken The amount of tokens received.
     */
    function burnExactIndexForToken(
        address token,
        uint256 amountTokenMin,
        uint256 amountIndex,
        address recipient
    )
        external
        nonReentrant
        whenNotPaused
        onlyWhitelistedToken(token)
        returns (uint256 amountToken)
    {
        if (recipient == address(0)) {
            revert Errors.Index_ZeroAddress();
        }

        uint256 amountWNATIVE = _burnExactIndexForWNATIVE(amountIndex);

        (uint256 amountTokenOut, address bestRouter) = _getAmountOutMax(
            routers[token],
            amountWNATIVE,
            wNATIVE,
            token
        );

        amountToken = _swapExactTokenForToken(
            bestRouter,
            amountWNATIVE,
            amountTokenOut,
            wNATIVE,
            token
        );

        if (amountToken != amountTokenOut) {
            revert Errors.Index_WrongSwapAmount();
        }

        if (amountToken < amountTokenMin) {
            revert Errors.Index_BelowMinAmount();
        }

        IERC20Upgradeable(token).safeTransfer(recipient, amountToken);

        emit Burn(_msgSender(), recipient, token, amountToken, amountIndex);
    }

    /**
     * @dev Retrieves the amount of index tokens that will be minted for a specified token.
     * @param token The address of the token to be swapped.
     * @param amountTokenMax The maximum amount of the token to be swapped.
     * @return amountIndex The amount of index tokens that will be minted.
     * @return amountToken The amount of tokens to be swapped.
     */
    function getAmountIndexFromToken(address token, uint256 amountTokenMax)
        external
        view
        onlyWhitelistedToken(token)
        returns (uint256 amountIndex, uint256 amountToken)
    {
        MintingData memory mintingData;

        (amountToken, , mintingData) = _getMintingDataFromToken(
            token,
            amountTokenMax
        );

        amountIndex = mintingData.amountIndex;
    }

    /**
     * @dev Retrieves the amount of tokens that will be received for a specified amount of index tokens.
     * @param token The address of the token to be received.
     * @param amountIndex The amount of index tokens to be burned.
     * @return amountToken The amount of tokens that will be received.
     */
    function getAmountTokenFromExactIndex(address token, uint256 amountIndex)
        external
        view
        onlyWhitelistedToken(token)
        returns (uint256 amountToken)
    {
        uint256 amountWNATIVE = _getAmountWNATIVEFromExactIndex(amountIndex);

        (amountToken, ) = _getAmountOutMax(
            routers[token],
            amountWNATIVE,
            wNATIVE,
            token
        );
    }

    /**
     * @dev Rebalances the index strategy by adjusting the weights of the components.
     * @param targetWeights The target weights for each component.
     */
    function rebalance(uint256[] calldata targetWeights) external onlyOwner {
        if (components.length != targetWeights.length) {
            revert Errors.Index_WrongTargetWeightsLength();
        }

        uint256 amountWNATIVETotal;
        uint256[] memory requiredWNATIVEs = new uint256[](components.length);
        uint256 requiredWNATIVETotal;

        uint256 indexTotalSupply = indexToken.totalSupply();

        for (uint256 i = 0; i < components.length; i++) {
            if (weights[components[i]] > targetWeights[i]) {
                // Convert component to wNATIVE.
                uint256 amountComponent;

                if (targetWeights[i] == 0) {
                    // To avoid rounding errors.
                    amountComponent = IERC20Upgradeable(components[i])
                        .balanceOf(address(this));
                } else {
                    amountComponent =
                        ((weights[components[i]] - targetWeights[i]) *
                            indexTotalSupply) /
                        Constants.PRECISION;
                }

                (
                    uint256 amountWNATIVEOut,
                    address bestRouter
                ) = _getAmountOutMax(
                        routers[components[i]],
                        amountComponent,
                        components[i],
                        wNATIVE
                    );

                uint256 balanceComponent = IERC20Upgradeable(components[i])
                    .balanceOf(address(this));

                if (amountComponent > balanceComponent) {
                    amountComponent = balanceComponent;
                }

                uint256 amountWNATIVE = _swapExactTokenForToken(
                    bestRouter,
                    amountComponent,
                    amountWNATIVEOut,
                    components[i],
                    wNATIVE
                );

                if (amountWNATIVE != amountWNATIVEOut) {
                    revert Errors.Index_WrongSwapAmount();
                }

                amountWNATIVETotal += amountWNATIVE;
            } else if (weights[components[i]] < targetWeights[i]) {
                // Calculate how much wNATIVE is required to buy component.
                uint256 amountComponent = ((targetWeights[i] -
                    weights[components[i]]) * indexTotalSupply) /
                    Constants.PRECISION;

                (uint256 amountWNATIVE, ) = _getAmountInMin(
                    routers[components[i]],
                    amountComponent,
                    wNATIVE,
                    components[i]
                );

                requiredWNATIVEs[i] = amountWNATIVE;
                requiredWNATIVETotal += amountWNATIVE;
            }
        }

        if (amountWNATIVETotal == 0) {
            revert Errors.Index_WrongTargetWeights();
        }

        // Convert wNATIVE to component.
        for (uint256 i = 0; i < components.length; i++) {
            if (requiredWNATIVEs[i] == 0) {
                continue;
            }

            uint256 amountWNATIVE = (requiredWNATIVEs[i] * amountWNATIVETotal) /
                requiredWNATIVETotal;

            (uint256 amountComponentOut, address bestRouter) = _getAmountOutMax(
                routers[components[i]],
                amountWNATIVE,
                wNATIVE,
                components[i]
            );

            uint256 amountComponent = _swapExactTokenForToken(
                bestRouter,
                amountWNATIVE,
                amountComponentOut,
                wNATIVE,
                components[i]
            );

            if (amountComponent != amountComponentOut) {
                revert Errors.Index_WrongSwapAmount();
            }
        }

        // Adjust component's weights.
        for (uint256 i = 0; i < components.length; i++) {
            uint256 componentBalance = IERC20Upgradeable(components[i])
                .balanceOf(address(this));

            weights[components[i]] =
                (componentBalance * Constants.PRECISION) /
                indexTotalSupply;
        }
    }

    /**
     * @dev Adds a component to the index strategy.
     * @param component The address of the component token.
     */
    function addComponent(address component) external onlyOwner {
        for (uint256 i = 0; i < components.length; i++) {
            if (components[i] == component) {
                revert Errors.Index_ComponentAlreadyExists(component);
            }
        }

        components.push(component);
    }

    /**
     * @dev Adds a swap route for swapping tokens.
     * @param token The address of the token to be swapped.
     * @param router The address of the router contract.
     * @param dex The type of decentralized exchange (DEX) used by the router.
     * @param _pairData The pair data for the router and tokens.
     */
    function addSwapRoute(
        address token,
        address router,
        SwapAdapter.DEX dex,
        SwapAdapter.PairData memory _pairData
    ) public onlyOwner {
        _addRouter(token, router);

        _setDEX(router, dex);

        _setPairData(router, token, wNATIVE, _pairData);
    }

    /**
     * @dev Adds multiple tokens to the whitelist.
     * @param tokens The addresses of the tokens to be added.
     */
    function addWhitelistedTokens(address[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (!isTokenWhitelisted(tokens[i])) {
                whitelistedTokens.push(tokens[i]);
            }
        }
    }

    /**
     * @dev Removes a component from the index strategy.
     * @param component The address of the component token to be removed.
     */
    function removeComponent(address component) external onlyOwner {
        for (uint256 i = 0; i < components.length; i++) {
            if (components[i] == component) {
                if (weights[component] != 0) {
                    revert Errors.Index_ComponentHasNonZeroWeight(component);
                }

                components[i] = components[components.length - 1];
                components.pop();
                break;
            }
        }
    }

    /**
     * @dev Removes a swap route for swapping tokens.
     * @param token The address of the token to be swapped.
     * @param router The address of the router contract to be removed.
     */
    function removeSwapRoute(address token, address router) external onlyOwner {
        _removeRouter(token, router);

        _setPairData(
            router,
            token,
            wNATIVE,
            SwapAdapter.PairData(address(0), abi.encode(0))
        );
    }

    /**
     * @dev Removes multiple tokens from the whitelist.
     * @param tokens The addresses of the tokens to be removed.
     */
    function removeWhitelistedTokens(address[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            for (uint256 j = 0; j < whitelistedTokens.length; j++) {
                if (whitelistedTokens[j] == tokens[i]) {
                    whitelistedTokens[j] = whitelistedTokens[
                        whitelistedTokens.length - 1
                    ];
                    whitelistedTokens.pop();
                    break;
                }
            }
        }
    }

    /**
     * @dev Sets the equity valuation limit for the index strategy.
     * @param _equityValuationLimit The new equity valuation limit.
     */
    function setEquityValuationLimit(uint256 _equityValuationLimit)
        public
        onlyOwner
    {
        equityValuationLimit = _equityValuationLimit;
    }

    /**
     * @dev Sets the oracle contract for the index strategy.
     * @param _oracle The address of the oracle contract.
     */
    function setOracle(address _oracle) public onlyOwner {
        oracle = IIndexOracle(_oracle);
    }

    /**
     * @dev Retrieves the addresses of all components in the index strategy.
     * @return An array of component addresses.
     */
    function allComponents() external view override returns (address[] memory) {
        return components;
    }

    /**
     * @dev Retrieves the addresses of all whitelisted tokens.
     * @return An array of whitelisted token addresses.
     */
    function allWhitelistedTokens() external view returns (address[] memory) {
        return whitelistedTokens;
    }

    /**
     * @dev Calculates the equity valuation of the index strategy.
     * @param maximize A boolean indicating whether to maximize the valuation.
     * @param includeAmmPrice A boolean indicating whether to include the AMM price in the valuation.
     * @return The equity valuation of the index strategy.
     */
    function equityValuation(bool maximize, bool includeAmmPrice)
        public
        view
        virtual
        returns (uint256);

    /**
     * @dev Checks if a token is whitelisted.
     * @param token The address of the token to check.
     * @return bool Returns true if the token is whitelisted, false otherwise.
     */
    function isTokenWhitelisted(address token) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedTokens.length; i++) {
            if (whitelistedTokens[i] == token) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Mints the exact index amount of the index token by swapping components with wNATIVE.
     * @param mintingData The minting data containing information about the components and routers.
     * @param recipient The address to receive the minted index tokens.
     * @return amountWNATIVESpent The amount of wNATIVE spent during the minting process.
     */
    function _mintExactIndexFromWNATIVE(
        MintingData memory mintingData,
        address recipient
    ) internal returns (uint256 amountWNATIVESpent) {
        for (uint256 i = 0; i < components.length; i++) {
            if (mintingData.amountComponents[i] == 0) {
                continue;
            }

            amountWNATIVESpent += _swapTokenForExactToken(
                mintingData.bestRouters[i],
                mintingData.amountComponents[i],
                mintingData.amountWNATIVEs[i],
                wNATIVE,
                components[i]
            );
        }

        indexToken.mint(recipient, mintingData.amountIndex);
    }

    /**
     * @dev Burns the exact index amount of the index token and swaps components for wNATIVE.
     * @param amountIndex The amount of index tokens to burn.
     * @return amountWNATIVE The amount of wNATIVE received from burning the index tokens.
     */
    function _burnExactIndexForWNATIVE(uint256 amountIndex)
        internal
        returns (uint256 amountWNATIVE)
    {
        for (uint256 i = 0; i < components.length; i++) {
            if (weights[components[i]] == 0) {
                continue;
            }

            uint256 amountComponent = (amountIndex * weights[components[i]]) /
                Constants.PRECISION;

            (uint256 amountWNATIVEOut, address bestRouter) = _getAmountOutMax(
                routers[components[i]],
                amountComponent,
                components[i],
                wNATIVE
            );

            amountWNATIVE += _swapExactTokenForToken(
                bestRouter,
                amountComponent,
                amountWNATIVEOut,
                components[i],
                wNATIVE
            );
        }

        indexToken.burnFrom(_msgSender(), amountIndex);
    }

    /**
     * @dev Calculates the minting data for the exact index amount.
     * @param amountIndex The exact index amount to mint.
     * @return mintingData The minting data containing information about the components, routers, and wNATIVE amounts.
     */
    function _getMintingDataForExactIndex(uint256 amountIndex)
        internal
        view
        returns (MintingData memory mintingData)
    {
        mintingData.amountIndex = amountIndex;
        mintingData.amountWNATIVEs = new uint256[](components.length);
        mintingData.bestRouters = new address[](components.length);
        mintingData.amountComponents = new uint256[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            if (weights[components[i]] == 0) {
                continue;
            }

            mintingData.amountComponents[i] =
                (amountIndex * weights[components[i]]) /
                Constants.PRECISION;

            (
                mintingData.amountWNATIVEs[i],
                mintingData.bestRouters[i]
            ) = _getAmountInMin(
                routers[components[i]],
                mintingData.amountComponents[i],
                wNATIVE,
                components[i]
            );

            mintingData.amountWNATIVETotal += mintingData.amountWNATIVEs[i];
        }
    }

    /**
     * @dev Calculates the minting data from the given token and maximum token amount.
     * @param token The token to mint from.
     * @param amountTokenMax The maximum token amount to use for minting.
     * @return amountToken The actual token amount used for minting.
     * @return bestRouter The best router to use for minting.
     * @return mintingData The minting data containing information about the components, routers, and wNATIVE amounts.
     */
    function _getMintingDataFromToken(address token, uint256 amountTokenMax)
        internal
        view
        returns (
            uint256 amountToken,
            address bestRouter,
            MintingData memory mintingData
        )
    {
        (uint256 amountWNATIVE, ) = _getAmountOutMax(
            routers[token],
            amountTokenMax,
            token,
            wNATIVE
        );

        mintingData = _getMintingDataFromWNATIVE(amountWNATIVE);

        (amountToken, bestRouter) = _getAmountInMin(
            routers[token],
            mintingData.amountWNATIVETotal,
            token,
            wNATIVE
        );
    }

    /**
     * @dev Calculates the minting data from the given wNATIVE amount.
     * @param amountWNATIVEMax The maximum wNATIVE amount to use for minting.
     * @return mintingData The minting data containing information about the components, routers, and wNATIVE amounts.
     */
    function _getMintingDataFromWNATIVE(uint256 amountWNATIVEMax)
        internal
        view
        returns (MintingData memory mintingData)
    {
        MintingData memory mintingDataUnit = _getMintingDataForExactIndex(
            Constants.PRECISION
        );

        uint256 amountIndex = type(uint256).max;

        for (uint256 i = 0; i < components.length; i++) {
            if (mintingDataUnit.amountWNATIVEs[i] == 0) {
                continue;
            }

            uint256 amountWNATIVE = (amountWNATIVEMax *
                mintingDataUnit.amountWNATIVEs[i]) /
                mintingDataUnit.amountWNATIVETotal;

            (uint256 amountComponent, ) = _getAmountOutMax(
                routers[components[i]],
                amountWNATIVE,
                wNATIVE,
                components[i]
            );

            amountIndex = MathUpgradeable.min(
                amountIndex,
                (amountComponent * Constants.PRECISION) / weights[components[i]]
            );
        }

        mintingData = _getMintingDataForExactIndex(amountIndex);
    }

    /**
     * @dev Calculates the amount of wNATIVE received from the exact index amount.
     * @param amountIndex The exact index amount.
     * @return amountWNATIVE The amount of wNATIVE received.
     */
    function _getAmountWNATIVEFromExactIndex(uint256 amountIndex)
        internal
        view
        returns (uint256 amountWNATIVE)
    {
        for (uint256 i = 0; i < components.length; i++) {
            if (weights[components[i]] == 0) {
                continue;
            }

            uint256 amountComponent = (amountIndex * weights[components[i]]) /
                Constants.PRECISION;

            (uint256 amountWNATIVEOut, ) = _getAmountOutMax(
                routers[components[i]],
                amountComponent,
                components[i],
                wNATIVE
            );

            amountWNATIVE += amountWNATIVEOut;
        }
    }

    /**
     * @dev Sets the weight of a token.
     * @param token The token address.
     * @param weight The weight of the token.
     */
    function _setWeight(address token, uint256 weight) internal {
        weights[token] = weight;
    }

    /**
     * @dev Adds a router for a token.
     * @param token The token address.
     * @param router The router address.
     */
    function _addRouter(address token, address router) internal {
        if (token == address(0)) {
            revert Errors.Index_ZeroAddress();
        }

        for (uint256 i = 0; i < routers[token].length; i++) {
            if (routers[token][i] == router) {
                return;
            }
        }

        routers[token].push(router);
    }

    /**
     * @dev Sets the DEX (Decentralized Exchange) for a router.
     * @param router The router address.
     * @param dex The DEX to set.
     */
    function _setDEX(address router, SwapAdapter.DEX dex) internal {
        if (router == address(0)) {
            revert Errors.Index_ZeroAddress();
        }

        if (dexs[router] != SwapAdapter.DEX.None) {
            return;
        }

        dexs[router] = dex;
    }

    /**
     * @dev Sets the pair data for a router, token0, and token1.
     * @param router The router address.
     * @param token0 The first token address.
     * @param token1 The second token address.
     * @param _pairData The pair data to set.
     */
    function _setPairData(
        address router,
        address token0,
        address token1,
        SwapAdapter.PairData memory _pairData
    ) internal {
        if (token0 == address(0) || token1 == address(0)) {
            revert Errors.Index_ZeroAddress();
        }

        if (pairData[router][token0][token1].pair != address(0)) {
            return;
        }

        pairData[router][token0][token1] = _pairData;
        pairData[router][token1][token0] = _pairData;
    }

    /**
     * @dev Removes a router for a token.
     * @param token The token address.
     * @param router The router address to remove.
     */
    function _removeRouter(address token, address router) internal {
        for (uint256 i = 0; i < routers[token].length; i++) {
            if (routers[token][i] == router) {
                routers[token][i] = routers[token][routers[token].length - 1];
                routers[token].pop();
                break;
            }
        }
    }

    /**
     * @dev Swaps exact token for token using a specific router.
     * @param router The router address to use for swapping.
     * @param amountIn The exact amount of input tokens.
     * @param amountOutMin The minimum amount of output tokens to receive.
     * @param tokenIn The input token address.
     * @param tokenOut The output token address.
     * @return amountOut The amount of output tokens received.
     */
    function _swapExactTokenForToken(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut
    ) internal returns (uint256 amountOut) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        amountOut = SwapAdapter
            .Setup(dexs[router], router, pairData[router][tokenIn][tokenOut])
            .swapExactTokensForTokens(amountIn, amountOutMin, path);
    }

    /**
     * @dev Swaps a specific amount of `tokenIn` for an exact amount of `tokenOut` using a specified router.
     * @param router The address of the router contract to use for the swap.
     * @param amountOut The exact amount of `tokenOut` tokens to receive.
     * @param amountInMax The maximum amount of `tokenIn` tokens to be used for the swap.
     * @param tokenIn The address of the token to be swapped.
     * @param tokenOut The address of the token to receive.
     * @return amountIn The actual amount of `tokenIn` tokens used for the swap.
     */
    function _swapTokenForExactToken(
        address router,
        uint256 amountOut,
        uint256 amountInMax,
        address tokenIn,
        address tokenOut
    ) internal returns (uint256 amountIn) {
        if (tokenIn == tokenOut) {
            return amountOut;
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        amountIn = SwapAdapter
            .Setup(dexs[router], router, pairData[router][tokenIn][tokenOut])
            .swapTokensForExactTokens(amountOut, amountInMax, path);
    }

    /**
     * @dev Calculates the maximum amount of `tokenOut` tokens that can be received for a given `amountIn` of `tokenIn` tokens,
     *      and identifies the best router to use for the swap among a list of routers.
     * @param _routers The list of router addresses to consider for the swap.
     * @param amountIn The amount of `tokenIn` tokens.
     * @param tokenIn The address of the token to be swapped.
     * @param tokenOut The address of the token to receive.
     * @return amountOutMax The maximum amount of `tokenOut` tokens that can be received for the given `amountIn`.
     * @return bestRouter The address of the best router to use for the swap.
     */
    function _getAmountOutMax(
        address[] memory _routers,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountOutMax, address bestRouter) {
        if (tokenIn == tokenOut) {
            return (amountIn, address(0));
        }

        if (_routers.length == 0) {
            revert Errors.Index_WrongPair(tokenIn, tokenOut);
        }

        amountOutMax = type(uint256).min;

        for (uint256 i = 0; i < _routers.length; i++) {
            address router = _routers[i];

            uint256 amountOut = SwapAdapter
                .Setup(
                    dexs[router],
                    router,
                    pairData[router][tokenIn][tokenOut]
                )
                .getAmountOut(amountIn, tokenIn, tokenOut);

            if (amountOut > amountOutMax) {
                amountOutMax = amountOut;
                bestRouter = router;
            }
        }
    }

    /**
     * @dev Calculates the minimum amount of `tokenIn` tokens required to receive a given `amountOut` of `tokenOut` tokens,
     *      and identifies the best router to use for the swap among a list of routers.
     * @param _routers The list of router addresses to consider for the swap.
     * @param amountOut The amount of `tokenOut` tokens to receive.
     * @param tokenIn The address of the token to be swapped.
     * @param tokenOut The address of the token to receive.
     * @return amountInMin The minimum amount of `tokenIn` tokens required to receive the given `amountOut`.
     * @return bestRouter The address of the best router to use for the swap.
     */
    function _getAmountInMin(
        address[] memory _routers,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountInMin, address bestRouter) {
        if (tokenIn == tokenOut) {
            return (amountOut, address(0));
        }

        if (_routers.length == 0) {
            revert Errors.Index_WrongPair(tokenIn, tokenOut);
        }

        amountInMin = type(uint256).max;

        for (uint256 i = 0; i < _routers.length; i++) {
            address router = _routers[i];

            uint256 amountIn = SwapAdapter
                .Setup(
                    dexs[router],
                    router,
                    pairData[router][tokenIn][tokenOut]
                )
                .getAmountIn(amountOut, tokenIn, tokenOut);

            if (amountIn < amountInMin) {
                amountInMin = amountIn;
                bestRouter = router;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ICamelotPair {
    function stableSwap() external view returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint16 token0FeePercent,
            uint16 token1FeePercent
        );

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ICamelotRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IChronosFactory {
    function getFee(bool isStable) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IChronosPair {
    function isStable() external view returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint256 reserve0,
            uint256 reserve1,
            uint256 blockTimestampLast
        );

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IChronosRouter {
    struct Route {
        address from;
        address to;
        bool stable;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeV2Pair {
    function tokenX() external view returns (address);

    function tokenY() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory binSteps,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory binSteps,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function getSwapIn(
        address lbPair,
        uint256 amountOut,
        bool swapForY
    ) external view returns (uint256 amountIn, uint256 feesIn);

    function getSwapOut(
        address lbPair,
        uint256 amountIn,
        bool swapForY
    ) external view returns (uint256 amountOut, uint256 feesIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { IndexArbitrum } from "../bases/IndexArbitrum.sol";
import { IChainlinkAggregatorV3 } from "../dependencies/IChainlinkAggregatorV3.sol";
import { Constants } from "../libraries/Constants.sol";
import { Errors } from "../libraries/Errors.sol";
import { SwapAdapter } from "../libraries/SwapAdapter.sol";

contract IndexArbitrumDeFi is UUPSUpgradeable, IndexArbitrum {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IndexStrategyInitParams calldata initParams)
        external
        initializer
    {
        __UUPSUpgradeable_init();
        __IndexStrategyUpgradeable_init(initParams);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IChainlinkAggregatorV3 } from "../dependencies/IChainlinkAggregatorV3.sol";
import { SwapAdapter } from "../libraries/SwapAdapter.sol";
import { IIndexStrategy } from "./IIndexStrategy.sol";

interface IIndexInit {
    struct IndexStrategyInitParams {
        address wNATIVE;
        address indexToken;
        Component[] components;
        SwapRoute[] swapRoutes;
        address[] whitelistedTokens;
        address oracle;
        uint256 equityValuationLimit;
    }

    struct Component {
        address token;
        uint256 weight;
    }

    struct SwapRoute {
        address token;
        address router;
        SwapAdapter.DEX dex;
        SwapAdapter.PairData pairData;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IIndexLimits {
    function setEquityValuationLimit(uint256 equityValuationLimit) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IIndexOracle {
    function decimals() external pure returns (uint8);

    function getPrice(
        address token,
        bool maximize,
        bool includeAmmPrice
    ) external view returns (uint256 price);

    function getPrices(
        address[] calldata tokens,
        bool maximize,
        bool includeAmmPrice
    ) external view returns (uint256[] calldata prices);

    function setPriceFeed(address token, address priceFeed) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IChainlinkAggregatorV3 } from "../dependencies/IChainlinkAggregatorV3.sol";
import { IIndexToken } from "../interfaces/IIndexToken.sol";
import { SwapAdapter } from "../libraries/SwapAdapter.sol";

interface IIndexStrategy {
    event Mint(
        address indexed sender,
        address indexed recipient,
        address token,
        uint256 amountToken,
        uint256 amountIndex
    );

    event Burn(
        address indexed sender,
        address indexed recipient,
        address token,
        uint256 amountToken,
        uint256 amountIndex
    );

    function mintIndexFromToken(
        address token,
        uint256 amountTokenMax,
        uint256 amountIndexMin,
        address recipient
    ) external returns (uint256 amountIndex, uint256 amountToken);

    function burnExactIndexForToken(
        address token,
        uint256 amountTokenMin,
        uint256 amountIndex,
        address recipient
    ) external returns (uint256 amountToken);

    function getAmountIndexFromToken(address token, uint256 amountTokenMax)
        external
        view
        returns (uint256 amountIndex, uint256 amountToken);

    function getAmountTokenFromExactIndex(address token, uint256 amountIndex)
        external
        view
        returns (uint256 amountToken);

    function setOracle(address oracle) external;

    function addSwapRoute(
        address token,
        address router,
        SwapAdapter.DEX dex,
        SwapAdapter.PairData memory pairData
    ) external;

    function addWhitelistedTokens(address[] memory tokens) external;

    function removeSwapRoute(address token, address router) external;

    function removeWhitelistedTokens(address[] memory tokens) external;

    function allComponents() external view returns (address[] memory);

    function allWhitelistedTokens() external view returns (address[] memory);

    function equityValuation(bool maximize, bool includeAmmPrice)
        external
        view
        returns (uint256);

    function indexToken() external view returns (IIndexToken);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IIndexToken is IERC20Upgradeable {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "./Errors.sol";
import { ICamelotPair } from "../dependencies/ICamelotPair.sol";
import { ICamelotRouter } from "../dependencies/ICamelotRouter.sol";

library CamelotLibrary {
    function swapExactTokensForTokens(
        ICamelotRouter router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        uint256 tokenOutBalanceBefore = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            address(0),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        uint256 tokenOutBalanceAfter = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        amountOut = tokenOutBalanceAfter - tokenOutBalanceBefore;
    }

    function swapTokensForExactTokens(
        ICamelotRouter router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        uint256 tokenOutBalanceBefore = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        // Note: In current algorithm, `swapTokensForExactTokens` is called
        // only when `amountInMax` equals to actual amount in. Under this assumption,
        // `swapExactTokensForTokens` is used instead of `swapTokensForExactTokens`
        // because Solidly forks doesn't support `swapTokensForExactTokens`.
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInMax,
            amountOut,
            path,
            address(this),
            address(0),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        uint256 tokenOutBalanceAfter = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        uint256 amountOutReceived = tokenOutBalanceAfter -
            tokenOutBalanceBefore;

        if (amountOutReceived < amountOut) {
            revert Errors.Index_WrongSwapAmount();
        }

        amountIn = amountInMax;
    }

    function getAmountOut(
        ICamelotRouter,
        ICamelotPair pair,
        uint256 amountIn,
        address tokenIn
    ) internal view returns (uint256 amountOut) {
        amountOut = pair.getAmountOut(amountIn, tokenIn);
    }

    function getAmountIn(
        ICamelotRouter,
        ICamelotPair pair,
        uint256 amountOut,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        bool isStable = pair.stableSwap();

        if (isStable) {
            revert Errors.Index_SolidlyStableSwapNotSupported();
        }

        (
            uint112 reserve0,
            uint112 reserve1,
            uint16 token0FeePercent,
            uint16 token1FeePercent
        ) = pair.getReserves();

        address token1 = pair.token1();

        (uint112 reserveIn, uint112 reserveOut) = (tokenOut == token1)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        uint16 feePercent = (tokenOut == token1)
            ? token0FeePercent
            : token1FeePercent;

        amountIn =
            (reserveIn * amountOut * 100000) /
            (reserveOut - amountOut) /
            (100000 - feePercent) +
            1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "./Errors.sol";
import { IChronosFactory } from "../dependencies/IChronosFactory.sol";
import { IChronosPair } from "../dependencies/IChronosPair.sol";
import { IChronosRouter } from "../dependencies/IChronosRouter.sol";

library ChronosLibrary {
    function swapExactTokensForTokens(
        IChronosRouter router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        IChronosRouter.Route[] memory routes = new IChronosRouter.Route[](1);
        routes[0] = IChronosRouter.Route(path[0], path[path.length - 1], false);

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            routes,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[path.length - 1];
    }

    function swapTokensForExactTokens(
        IChronosRouter router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        // Note: In current algorithm, `swapTokensForExactTokens` is called
        // only when `amountInMax` equals to actual amount in. Under this assumption,
        // `swapExactTokensForTokens` is used instead of `swapTokensForExactTokens`
        // because Solidly forks doesn't support `swapTokensForExactTokens`.
        IChronosRouter.Route[] memory routes = new IChronosRouter.Route[](1);
        routes[0] = IChronosRouter.Route(path[0], path[path.length - 1], false);

        uint256 amountOutReceived = router.swapExactTokensForTokens(
            amountInMax,
            amountOut,
            routes,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[path.length - 1];

        if (amountOutReceived < amountOut) {
            revert Errors.Index_WrongSwapAmount();
        }

        amountIn = amountInMax;
    }

    function getAmountOut(
        IChronosRouter,
        IChronosPair pair,
        uint256 amountIn,
        address tokenIn
    ) internal view returns (uint256 amountOut) {
        amountOut = pair.getAmountOut(amountIn, tokenIn);
    }

    function getAmountIn(
        IChronosRouter,
        IChronosPair pair,
        IChronosFactory factory,
        uint256 amountOut,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        bool isStable = pair.isStable();

        if (isStable) {
            revert Errors.Index_SolidlyStableSwapNotSupported();
        }

        uint256 fee = factory.getFee(isStable);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        address token1 = pair.token1();

        (uint256 reserveIn, uint256 reserveOut) = (tokenOut == token1)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        amountIn =
            (reserveIn * amountOut * 10000) /
            (reserveOut - amountOut) /
            (10000 - fee) +
            1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Constants {
    uint256 internal constant DECIMALS = 1e18;

    uint256 internal constant PRECISION = 1e18;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Errors {
    // IndexStrategyUpgradeable errors.
    error Index_ComponentAlreadyExists(address component);
    error Index_ComponentHasNonZeroWeight(address component);
    error Index_NotWhitelistedToken(address token);
    error Index_ExceedEquityValuationLimit();
    error Index_AboveMaxAmount();
    error Index_BelowMinAmount();
    error Index_ZeroAddress();
    error Index_SolidlyStableSwapNotSupported();
    error Index_WrongSwapAmount();
    error Index_WrongPair(address tokenIn, address tokenOut);
    error Index_WrongTargetWeightsLength();
    error Index_WrongTargetWeights();

    // SwapAdapter errors.
    error SwapAdapter_WrongDEX(uint8 dex);
    error SwapAdapter_WrongPair(address tokenIn, address tokenOut);

    // IndexOracle errors.
    error Oracle_TokenNotSupported(address token);
    error Oracle_ZeroAddress();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ICamelotPair } from "../dependencies/ICamelotPair.sol";
import { ICamelotRouter } from "../dependencies/ICamelotRouter.sol";
import { IChronosFactory } from "../dependencies/IChronosFactory.sol";
import { IChronosPair } from "../dependencies/IChronosPair.sol";
import { IChronosRouter } from "../dependencies/IChronosRouter.sol";
import { ITraderJoeV2Pair } from "../dependencies/ITraderJoeV2Pair.sol";
import { ITraderJoeV2Router } from "../dependencies/ITraderJoeV2Router.sol";
import { IUniswapV2Pair } from "../dependencies/IUniswapV2Pair.sol";
import { IUniswapV2Router } from "../dependencies/IUniswapV2Router.sol";
import { CamelotLibrary } from "./CamelotLibrary.sol";
import { ChronosLibrary } from "./ChronosLibrary.sol";
import { TraderJoeV2Library } from "./TraderJoeV2Library.sol";
import { UniswapV2Library } from "./UniswapV2Library.sol";

import { Errors } from "./Errors.sol";

library SwapAdapter {
    using CamelotLibrary for ICamelotRouter;
    using ChronosLibrary for IChronosRouter;
    using UniswapV2Library for IUniswapV2Router;
    using TraderJoeV2Library for ITraderJoeV2Router;

    enum DEX {
        None,
        UniswapV2,
        TraderJoeV2,
        Camelot,
        Chronos
    }

    struct PairData {
        address pair;
        bytes data; // Pair specific data such as bin step of TraderJoeV2, pool fee of Uniswap V3, etc.
    }

    struct Setup {
        DEX dex;
        address router;
        PairData pairData;
    }

    function swapExactTokensForTokens(
        Setup memory setup,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) external returns (uint256 amountOut) {
        if (path[0] == path[path.length - 1]) {
            return amountIn;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            uint256[] memory binSteps = new uint256[](1);
            binSteps[0] = abi.decode(setup.pairData.data, (uint256));

            return
                ITraderJoeV2Router(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    binSteps,
                    path
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path
                );
        }

        if (setup.dex == DEX.Chronos) {
            return
                IChronosRouter(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }

    function swapTokensForExactTokens(
        Setup memory setup,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) external returns (uint256 amountIn) {
        if (path[0] == path[path.length - 1]) {
            return amountOut;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    path
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            uint256[] memory binSteps = new uint256[](1);
            binSteps[0] = abi.decode(setup.pairData.data, (uint256));

            return
                ITraderJoeV2Router(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    binSteps,
                    path
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    path
                );
        }

        if (setup.dex == DEX.Chronos) {
            return
                IChronosRouter(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    path
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }

    function getAmountOut(
        Setup memory setup,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).getAmountOut(
                    IUniswapV2Pair(setup.pairData.pair),
                    amountIn,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            return
                ITraderJoeV2Router(setup.router).getAmountOut(
                    ITraderJoeV2Pair(setup.pairData.pair),
                    amountIn,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).getAmountOut(
                    ICamelotPair(setup.pairData.pair),
                    amountIn,
                    tokenIn
                );
        }

        if (setup.dex == DEX.Chronos) {
            return
                IChronosRouter(setup.router).getAmountOut(
                    IChronosPair(setup.pairData.pair),
                    amountIn,
                    tokenIn
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }

    function getAmountIn(
        Setup memory setup,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn) {
        if (tokenIn == tokenOut) {
            return amountOut;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).getAmountIn(
                    IUniswapV2Pair(setup.pairData.pair),
                    amountOut,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            return
                ITraderJoeV2Router(setup.router).getAmountIn(
                    ITraderJoeV2Pair(setup.pairData.pair),
                    amountOut,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).getAmountIn(
                    ICamelotPair(setup.pairData.pair),
                    amountOut,
                    tokenOut
                );
        }

        if (setup.dex == DEX.Chronos) {
            address factory = abi.decode(setup.pairData.data, (address));

            return
                IChronosRouter(setup.router).getAmountIn(
                    IChronosPair(setup.pairData.pair),
                    IChronosFactory(factory),
                    amountOut,
                    tokenOut
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { ITraderJoeV2Pair } from "../dependencies/ITraderJoeV2Pair.sol";
import { ITraderJoeV2Router } from "../dependencies/ITraderJoeV2Router.sol";

library TraderJoeV2Library {
    function swapExactTokensForTokens(
        ITraderJoeV2Router router,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory binSteps,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            binSteps,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    function swapTokensForExactTokens(
        ITraderJoeV2Router router,
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory binSteps,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        amountIn = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            binSteps,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[0];
    }

    function getAmountOut(
        ITraderJoeV2Router router,
        ITraderJoeV2Pair pair,
        uint256 amountIn,
        address,
        address tokenOut
    ) internal view returns (uint256 amountOut) {
        (amountOut, ) = router.getSwapOut(
            address(pair),
            amountIn,
            tokenOut == address(pair.tokenY())
        );
    }

    function getAmountIn(
        ITraderJoeV2Router router,
        ITraderJoeV2Pair pair,
        uint256 amountOut,
        address,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        (amountIn, ) = router.getSwapIn(
            address(pair),
            amountOut,
            tokenOut == address(pair.tokenY())
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "./Errors.sol";
import { IUniswapV2Pair } from "../dependencies/IUniswapV2Pair.sol";
import { IUniswapV2Router } from "../dependencies/IUniswapV2Router.sol";

library UniswapV2Library {
    function swapExactTokensForTokens(
        IUniswapV2Router router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[path.length - 1];
    }

    function swapTokensForExactTokens(
        IUniswapV2Router router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        amountIn = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[0];
    }

    function getAmountOut(
        IUniswapV2Router router,
        IUniswapV2Pair pair,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = _getReserveInAndOut(
            pair,
            tokenIn,
            tokenOut
        );

        amountOut = router.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        IUniswapV2Router router,
        IUniswapV2Pair pair,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        (uint256 reserveIn, uint256 reserveOut) = _getReserveInAndOut(
            pair,
            tokenIn,
            tokenOut
        );

        amountIn = router.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function _getReserveInAndOut(
        IUniswapV2Pair pair,
        address tokenIn,
        address tokenOut
    ) private view returns (uint256 reserveIn, uint256 reserveOut) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        (address token0, address token1) = (pair.token0(), pair.token1());

        if (tokenIn == token0 && tokenOut == token1) {
            (reserveIn, reserveOut) = (reserve0, reserve1);
        } else if (tokenIn == token1 && tokenOut == token0) {
            (reserveIn, reserveOut) = (reserve1, reserve0);
        } else {
            revert Errors.SwapAdapter_WrongPair(tokenIn, tokenOut);
        }
    }
}