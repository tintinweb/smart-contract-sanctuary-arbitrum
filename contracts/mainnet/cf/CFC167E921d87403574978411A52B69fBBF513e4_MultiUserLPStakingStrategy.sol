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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { StorageSlotUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";
import { IBaseMultiUserFeesUpgradeableV1 } from "./IBaseMultiUserFeesUpgradeableV1.sol";
import { InvalidInputs } from "../../../core/libraries/DefinitiveErrors.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { DefinitiveAssets, IERC20 } from "../../../core/libraries/DefinitiveAssets.sol";

abstract contract BaseMultiUserFeesUpgradeable is IBaseMultiUserFeesUpgradeableV1, Initializable, ContextUpgradeable {
    using DefinitiveAssets for IERC20;

    uint256 private constant _MAX_FEE_PERCENTAGE = 10_000;

    /* solhint-disable max-line-length */
    /**
     * @dev Storage slot with the current fee charged upon redemption.
     * This is the keccak-256 hash of "Definitive.BaseMultiUserFeesUpgradeableV1._REDEMPTION_FEE_PERCENTAGE_SLOT" subtracted by 1
     * bytes32(uint256(keccak256("Definitive.BaseMultiUserFeesUpgradeableV1._REDEMPTION_FEE_PERCENTAGE_SLOT")) - 1)
     */
    /* solhint-enable max-line-length */
    bytes32 internal constant _REDEMPTION_FEE_PERCENTAGE_SLOT =
        0x14aa58a89d3f94ea99187ab98e735eb8f742cc801507b0f8968576d3fdc3c8cc;

    /**
     * @dev Storage slot with the current fee charged upon redemption.
     * This is the keccak-256 hash of "Definitive.BaseMultiUserFeesUpgradeableV1._FEES_ACCOUNT_SLOT" subtracted by 1
     * bytes32(uint256(keccak256("Definitive.BaseMultiUserFeesUpgradeableV1._FEES_ACCOUNT_SLOT")) - 1)
     */
    bytes32 internal constant _FEES_ACCOUNT_SLOT = 0x68433f9d83ac21ac7a279e7d087229a9129597a360563c499bb398b5664b27c1;

    function __BaseMultiUserFees_init(address _feesAccount) internal initializer {
        __BaseMultiUserFees_init_unchained(_feesAccount);
    }

    function __BaseMultiUserFees_init_unchained(address _feesAccount) internal initializer {
        _setFeesAccount(_feesAccount);
    }

    function getFeesAccount() public view returns (address) {
        return address(StorageSlotUpgradeable.getAddressSlot(_FEES_ACCOUNT_SLOT).value);
    }

    function getRedemptionFee() public view returns (uint256) {
        return uint256(StorageSlotUpgradeable.getUint256Slot(_REDEMPTION_FEE_PERCENTAGE_SLOT).value);
    }

    function getRedemptionFeeAmount(uint256 amount) public view returns (uint256 feeAmount) {
        feeAmount = _getFeeAmount(amount, getRedemptionFee());
    }

    function _getFeeAmount(uint256 amount, uint256 fee) private pure returns (uint256) {
        return (amount * fee) / _MAX_FEE_PERCENTAGE;
    }

    function _handleRedemptionFeesOnShares(
        address owner,
        address asset,
        uint256 amount,
        uint256 additionalFeePct
    ) internal returns (uint256 feeAmount) {
        uint256 baseFee = getRedemptionFee();
        if ((baseFee + additionalFeePct) > _MAX_FEE_PERCENTAGE) {
            revert InvalidInputs();
        }

        address feesAccount = getFeesAccount();
        uint256 baseFeeAmount = _getFeeAmount(amount, baseFee);
        uint256 additionalFeeAmount = _getFeeAmount(amount, additionalFeePct);
        feeAmount = baseFeeAmount + additionalFeeAmount;

        if (feeAmount > 0 && feesAccount != address(0)) {
            _transferShares(owner, feesAccount, feeAmount);
            emit RedemptionFee(_msgSender(), asset, amount, baseFeeAmount, additionalFeeAmount);
        }
    }

    function _setFeesAccount(address value) internal {
        if (value == address(0)) {
            revert InvalidInputs();
        }

        StorageSlotUpgradeable.getAddressSlot(_FEES_ACCOUNT_SLOT).value = value;
        emit FeeAccountUpdated(_msgSender(), value);
    }

    function _setRedemptionFee(uint256 value) internal {
        if (value >= _MAX_FEE_PERCENTAGE) {
            revert InvalidInputs();
        }
        StorageSlotUpgradeable.getUint256Slot(_REDEMPTION_FEE_PERCENTAGE_SLOT).value = value;
        emit RedemptionFeeUpdated(_msgSender(), value);
    }

    function _transferShares(address from, address to, uint256 amount) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface IBaseMultiUserFeesUpgradeableV1 {
    event FeeAccountUpdated(address actor, address feeAccount);

    event RedemptionFee(address actor, address asset, uint256 amount, uint256 feeAmount, uint256 additionalFeeAmount);

    event RedemptionFeeUpdated(address actor, uint256 redemptionFee);

    function getFeesAccount() external view returns (address);

    function getRedemptionFeeAmount(uint256 amount) external view returns (uint256 feeAmount);

    function getRedemptionFee() external view returns (uint256 percent4);

    function setFeesAccount(address) external;

    function setRedemptionFee(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IBaseMultiUserStrategyV1 } from "./IBaseMultiUserStrategyV1.sol";
import { ICoreAccessControlV1 } from "../../core/CoreAccessControl/v1/ICoreAccessControlV1.sol";
import { AccountNotAdmin, SafeHarborModeEnabled } from "../../core/libraries/DefinitiveErrors.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { CoreMulticall } from "../../core/CoreMulticall/v1/CoreMulticall.sol";
import { BaseMultiUserFeesUpgradeable } from "../../base/BaseMultiUserFees/v1/BaseMultiUserFeesUpgradeable.sol";
import { CoreTransfersNativeUpgradeable } from "../../core/CoreTransfersNative/v1/CoreTransfersNativeUpgradeable.sol";
import { BaseNativeWrapperUpgradeable } from "../../base/BaseNativeWrapperUpgradeable/BaseNativeWrapperUpgradeable.sol";
import { IBaseSafeHarborMode } from "../../base/BaseSafeHarborMode/IBaseSafeHarborMode.sol";
import { StorageSlotUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";

interface IDefinitiveVault is ICoreAccessControlV1, IBaseSafeHarborMode {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
}

abstract contract BaseMultiUserStrategyV1 is
    IBaseMultiUserStrategyV1,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    CoreMulticall,
    BaseMultiUserFeesUpgradeable,
    CoreTransfersNativeUpgradeable,
    BaseNativeWrapperUpgradeable
{
    address payable public VAULT;

    /* solhint-disable max-line-length */
    /**
     * @dev Storage slot with flag allowing redemptions during safe harbor.
     * This is the keccak-256 hash of "Definitive.BaseMultiUserStrategyV1._ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT" subtracted by 1
     * bytes32(uint256(keccak256("Definitive.BaseMultiUserStrategyV1._ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT")) - 1)
     */
    /* solhint-enable max-line-length */
    bytes32 internal constant _ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT =
        0xd8e383845db7ecbb6065c22cc5d1320931e4ef39a73fc10e0587d5257ff50379;

    modifier onlyDefinitiveVaultAdmins() {
        _validateOnlyDefinitiveVaultAdmins();

        _;
    }

    /// @notice Revert if safe harbor mode is enabled
    modifier revertIfSafeHarborModeEnabled() {
        if (getSafeHarborModeEnabled()) {
            revert SafeHarborModeEnabled();
        }
        _;
    }

    function __BaseMultiUserStrategy_init(
        address _vault,
        string memory _name,
        string memory _symbol,
        address _feesAccount
    ) internal onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC20_init(_name, _symbol);
        __BaseMultiUserFees_init(_feesAccount);
        __BaseMultiUserStrategy_init_unchained(_vault);
    }

    function __BaseMultiUserStrategy_init_unchained(address _vault) internal onlyInitializing {
        VAULT = payable(_vault);
        StorageSlotUpgradeable.getBooleanSlot(_ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT).value = false;
    }

    function getVersion() external view returns (uint256) {
        return _getInitializedVersion();
    }

    function setFeesAccount(address _value) external onlyDefinitiveVaultAdmins {
        _setFeesAccount(_value);
    }

    function setRedemptionFee(uint256 _value) external onlyDefinitiveVaultAdmins {
        _setRedemptionFee(_value);
    }

    function setSafeHarborRedemptions(bool allow) external onlyDefinitiveVaultAdmins {
        StorageSlotUpgradeable.getBooleanSlot(_ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT).value = allow;
    }

    function getSafeHarborModeEnabled() public view returns (bool) {
        return IDefinitiveVault(VAULT).SAFE_HARBOR_MODE_ENABLED();
    }

    /// @dev Required by UUPSUpgradeable, used by `upgradeTo()` and `upgradeToAndCall()`
    /// @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Revert if caller is not definitive admin on underlying vault
    function _validateOnlyDefinitiveVaultAdmins() private {
        IDefinitiveVault mVault = IDefinitiveVault(VAULT);

        if (
            !mVault.hasRole(mVault.ROLE_DEFINITIVE_ADMIN(), _msgSender()) &&
            !mVault.hasRole(mVault.DEFAULT_ADMIN_ROLE(), _msgSender())
        ) {
            revert AccountNotAdmin(_msgSender());
        }
    }

    function _transferShares(address from, address to, uint256 amount) internal override {
        return _transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ICoreUUPS_ABIVersionAware } from "../../core_upgradeable/ICoreUUPS_ABIVersionAware.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {
    IERC20MetadataUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IBaseMultiUserStrategyV1 is IERC20Upgradeable, IERC20MetadataUpgradeable, ICoreUUPS_ABIVersionAware {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { DefinitiveAssets } from "../../core/libraries/DefinitiveAssets.sol";
import { IWETH9 } from "../../vendor/interfaces/IWETH9.sol";

abstract contract BaseNativeWrapperUpgradeable is Initializable {
    address payable public WRAPPED_NATIVE_ASSET_ADDRESS;

    function __BaseNativeWrapper_init(address wrappedNativeAssetAddress) internal onlyInitializing {
        __BaseNativeWrapper_init_unchained(wrappedNativeAssetAddress);
    }

    function __BaseNativeWrapper_init_unchained(address wrappedNativeAssetAddress) internal onlyInitializing {
        WRAPPED_NATIVE_ASSET_ADDRESS = payable(wrappedNativeAssetAddress);
    }

    function _wrap(uint256 amount) internal {
        // slither-disable-next-line arbitrary-send-eth
        IWETH9(WRAPPED_NATIVE_ASSET_ADDRESS).deposit{ value: amount }();
    }

    function _unwrap(uint256 amount) internal {
        IWETH9(WRAPPED_NATIVE_ASSET_ADDRESS).withdraw(amount);
    }

    function _wrapAll() internal {
        return _wrap(address(this).balance);
    }

    function _unwrapAll() internal {
        return _unwrap(DefinitiveAssets.getBalance(WRAPPED_NATIVE_ASSET_ADDRESS));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ICoreAccessControlV1 } from "../../core/CoreAccessControl/v1/ICoreAccessControlV1.sol";

interface IBasePermissionedExecution is ICoreAccessControlV1 {
    function executeOperation(address target, bytes calldata payload) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

// solhint-disable-next-line contract-name-camelcase
interface IBaseSafeHarborMode {
    event SafeHarborModeUpdate(address indexed actor, bool indexed isEnabled);

    function SAFE_HARBOR_MODE_ENABLED() external view returns (bool);

    function enableSafeHarborMode() external;

    function disableSafeHarborMode() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ICoreAccessControlV1 } from "../../../core/CoreAccessControl/v1/ICoreAccessControlV1.sol";
import { ICoreDepositV1 } from "../../../core/CoreDeposit/v1/ICoreDepositV1.sol";
import { ICoreStopGuardianV1 } from "../../../core/CoreStopGuardian/v1/ICoreStopGuardianV1.sol";
import { ICoreWithdrawV1 } from "../../../core/CoreWithdraw/v1/CoreWithdraw.sol";

// This interface cannot be implemented on BaseTransfers.sol, but it's accurate
// since BaseTransfers.sol only inherits and overrides methods, and does not define
// additional public/external methods.

interface IBaseTransfersV1 is ICoreDepositV1, ICoreWithdrawV1, ICoreAccessControlV1, ICoreStopGuardianV1 {

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ICoreTransfersNativeV1 } from "../../../core/CoreTransfersNative/v1/ICoreTransfersNativeV1.sol";
import { IBaseTransfersV1 } from "../../BaseTransfers/v1/IBaseTransfersV1.sol";

// This interface cannot be implemented on BaseTransfers.sol, but it's accurate
// since BaseTransfers.sol only inherits and overrides methods, and does not define
// additional public/external methods.
interface IBaseTransfersNativeV1 is ICoreTransfersNativeV1, IBaseTransfersV1 {

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

// solhint-disable-next-line contract-name-camelcase
interface ICoreUUPS_ABIVersionAware {
    /// @notice Define this with a `constant`
    /// @dev EG: `uint256 public constant ABI_VERSION = 1;`
    function ABI_VERSION() external view returns (uint256);

    /// @notice This method should return `Initializable._getInitializedVersion()`
    function getVersion() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

interface ICoreAccessControlV1 is IAccessControl {
    function ROLE_CLIENT() external returns (bytes32);

    function ROLE_DEFINITIVE() external returns (bytes32);

    function ROLE_DEFINITIVE_ADMIN() external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICoreDepositV1 {
    event Deposit(address indexed actor, address[] assetAddresses, uint256[] amounts);

    function deposit(uint256[] calldata amounts, address[] calldata assetAddresses) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ICoreMulticallV1 } from "./ICoreMulticallV1.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DefinitiveAssets } from "../../libraries/DefinitiveAssets.sol";

/* solhint-disable max-line-length */
/**
 * @notice Implements openzeppelin/contracts/utils/Multicall.sol
 * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/5b027e517e6aee69f4b4b2f5e78274ac8ee53513/contracts/utils/Multicall.sol solhint-disable max-line-length
 */
/* solhint-enable max-line-length */
abstract contract CoreMulticall is ICoreMulticallV1 {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        uint256 dataLength = data.length;
        results = new bytes[](dataLength);
        for (uint256 i; i < dataLength; ) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getBalance(address assetAddress) public view returns (uint256) {
        return DefinitiveAssets.getBalance(assetAddress);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICoreMulticallV1 {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    function getBalance(address assetAddress) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICoreStopGuardianV1 {
    event StopGuardianUpdate(address indexed actor, bool indexed isEnabled);

    function STOP_GUARDIAN_ENABLED() external view returns (bool);

    function enableStopGuardian() external;

    function disableStopGuardian() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { ICoreTransfersNativeV1 } from "./ICoreTransfersNativeV1.sol";

import { DefinitiveAssets, IERC20 } from "../../libraries/DefinitiveAssets.sol";
import { DefinitiveConstants } from "../../libraries/DefinitiveConstants.sol";
import { InvalidInputs, InvalidMsgValue } from "../../libraries/DefinitiveErrors.sol";

/// @notice Copied from CoreTransfersNative/v1/CoreTransfersNative.sol
abstract contract CoreTransfersNativeUpgradeable is ICoreTransfersNativeV1, ContextUpgradeable {
    using DefinitiveAssets for IERC20;

    /**
     * @notice Allows contract to receive native assets
     */
    receive() external payable virtual {}

    /**
     * @notice This function is executed if none of the other functions
     * match the call data.  `bytes calldata` will contain the full data sent
     * to the contract (equal to msg.data) and can return data in output.
     * The returned data will not be ABI-encoded, and will be returned without
     * modifications (not even padding).
     * https://docs.soliditylang.org/en/v0.8.17/contracts.html#fallback-function
     */
    fallback(bytes calldata) external payable virtual returns (bytes memory) {}

    function __CoreTransfersNative_init() internal onlyInitializing {
        __Context_init();
        __CoreTransfersNative_init_unchained();
    }

    function __CoreTransfersNative_init_unchained() internal onlyInitializing {}

    function _depositNativeAndERC20(DefinitiveConstants.Assets memory depositAssets) internal virtual {
        uint256 assetAddressesLength = depositAssets.addresses.length;
        if (depositAssets.amounts.length != assetAddressesLength) {
            revert InvalidInputs();
        }

        uint256 nativeAssetIndex = type(uint256).max;

        for (uint256 i; i < assetAddressesLength; ) {
            if (depositAssets.addresses[i] == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
                nativeAssetIndex = i;
                unchecked {
                    ++i;
                }
                continue;
            }
            // ERC20 tokens
            IERC20(depositAssets.addresses[i]).safeTransferFrom(_msgSender(), address(this), depositAssets.amounts[i]);
            unchecked {
                ++i;
            }
        }
        // Revert if NATIVE_ASSET_ADDRESS is not in assetAddresses and msg.value is not zero
        if (nativeAssetIndex == type(uint256).max && msg.value != 0) {
            revert InvalidMsgValue();
        }

        // Revert if depositing native asset and amount != msg.value
        if (nativeAssetIndex != type(uint256).max && msg.value != depositAssets.amounts[nativeAssetIndex]) {
            revert InvalidMsgValue();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICoreTransfersNativeV1 {
    receive() external payable;

    fallback(bytes calldata) external payable returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ICoreWithdrawV1 } from "./ICoreWithdrawV1.sol";
import { DefinitiveAssets, IERC20 } from "../../libraries/DefinitiveAssets.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { DefinitiveConstants } from "../../libraries/DefinitiveConstants.sol";

abstract contract CoreWithdraw is ICoreWithdrawV1, Context {
    using DefinitiveAssets for IERC20;

    function supportsNativeAssets() public pure virtual returns (bool);

    function withdraw(uint256 amount, address erc20Token) public virtual returns (bool);

    function withdrawTo(uint256 amount, address erc20Token, address to) public virtual returns (bool);

    function _withdraw(uint256 amount, address erc20Token) internal returns (bool) {
        return _withdrawTo(amount, erc20Token, _msgSender());
    }

    function _withdrawTo(uint256 amount, address erc20Token, address to) internal returns (bool success) {
        if (erc20Token == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            DefinitiveAssets.safeTransferETH(payable(to), amount);
        } else {
            IERC20(erc20Token).safeTransfer(to, amount);
        }

        emit Withdrawal(erc20Token, amount, to);

        success = true;
    }

    function withdrawAll(address[] calldata tokens) public virtual returns (bool);

    function withdrawAllTo(address[] calldata tokens, address to) public virtual returns (bool);

    function _withdrawAll(address[] calldata tokens) internal returns (bool) {
        return _withdrawAllTo(tokens, _msgSender());
    }

    function _withdrawAllTo(address[] calldata tokens, address to) internal returns (bool success) {
        uint256 tokenLength = tokens.length;
        for (uint256 i; i < tokenLength; ) {
            uint256 tokenBalance = DefinitiveAssets.getBalance(tokens[i]);
            if (tokenBalance > 0) {
                _withdrawTo(tokenBalance, tokens[i], to);
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICoreWithdrawV1 {
    event Withdrawal(address indexed erc20Token, uint256 amount, address indexed recipient);

    function withdrawAll(address[] calldata tokens) external returns (bool);

    function withdrawAllTo(address[] calldata tokens, address to) external returns (bool);

    function supportsNativeAssets() external pure returns (bool);

    function withdraw(uint256 amount, address erc20Token) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { DefinitiveConstants } from "./DefinitiveConstants.sol";

import { InsufficientBalance, InvalidAmount, InvalidAmounts, InvalidERC20Address } from "./DefinitiveErrors.sol";

/**
 * @notice Contains methods used throughout the Definitive contracts
 * @dev This file should only be used as an internal library.
 */
library DefinitiveAssets {
    /**
     * @dev Checks if an address is a valid ERC20 token
     */
    modifier onlyValidERC20(address erc20Token) {
        if (address(erc20Token) == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            revert InvalidERC20Address();
        }
        _;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    // ↓ ERC20 and Native Asset Methods ↓
    //////////////////////////////////////////////////

    /**
     * @dev Gets the balance of an ERC20 token or native asset
     */
    function getBalance(address assetAddress) internal view returns (uint256) {
        if (assetAddress == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            return address(this).balance;
        } else {
            return IERC20(assetAddress).balanceOf(address(this));
        }
    }

    /**
     * @dev internal function to validate balance is higher than a given amount for ERC20 and native assets
     */
    function validateBalance(address token, uint256 amount) internal view {
        if (token == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            validateNativeBalance(amount);
        } else {
            validateERC20Balance(token, amount);
        }
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    // ↓ Native Asset Methods ↓
    //////////////////////////////////////////////////

    /**
     * @dev validates amount and balance, then uses SafeTransferLib to transfer native asset
     */
    function safeTransferETH(address recipient, uint256 amount) internal {
        if (amount > 0) {
            SafeTransferLib.safeTransferETH(payable(recipient), amount);
        }
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    // ↓ ERC20 Methods ↓
    //////////////////////////////////////////////////

    /**
     * @dev Resets and increases the allowance of a spender for an ERC20 token
     */
    function resetAndSafeIncreaseAllowance(
        IERC20 token,
        address owner,
        address spender,
        uint256 amount
    ) internal onlyValidERC20(address(token)) {
        if (token.allowance(owner, spender) > 0) {
            SafeERC20.safeApprove(token, spender, 0);
        }

        return SafeERC20.safeIncreaseAllowance(token, spender, amount);
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal onlyValidERC20(address(token)) {
        if (amount > 0) {
            SafeERC20.safeTransfer(token, to, amount);
        }
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal onlyValidERC20(address(token)) {
        if (amount > 0) {
            //slither-disable-next-line arbitrary-send-erc20
            SafeERC20.safeTransferFrom(token, from, to, amount);
        }
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    // ↓ Asset Amount Helper Methods ↓
    //////////////////////////////////////////////////

    /**
     * @dev internal function to validate that amounts contains a value greater than zero
     */
    function validateAmounts(uint256[] calldata amounts) internal pure {
        bool hasValidAmounts;
        uint256 amountsLength = amounts.length;
        for (uint256 i; i < amountsLength; ) {
            if (amounts[i] > 0) {
                hasValidAmounts = true;
                break;
            }
            unchecked {
                ++i;
            }
        }

        if (!hasValidAmounts) {
            revert InvalidAmounts();
        }
    }

    /**
     * @dev internal function to validate if native asset balance is higher than the amount requested
     */
    function validateNativeBalance(uint256 amount) internal view {
        if (getBalance(DefinitiveConstants.NATIVE_ASSET_ADDRESS) < amount) {
            revert InsufficientBalance();
        }
    }

    /**
     * @dev internal function to validate balance is higher than the amount requested for a token
     */
    function validateERC20Balance(address token, uint256 amount) internal view onlyValidERC20(token) {
        if (getBalance(token) < amount) {
            revert InsufficientBalance();
        }
    }

    function validateAmount(uint256 _amount) internal pure {
        if (_amount == 0) {
            revert InvalidAmount();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

/**
 * @notice Contains constants used throughout the Definitive contracts
 * @dev This file should only be used as an internal library.
 */
library DefinitiveConstants {
    /**
     * @notice Maximum fee percentage
     */
    uint256 internal constant MAX_FEE_PCT = 10000;

    /**
     * @notice Address to signify native assets
     */
    address internal constant NATIVE_ASSET_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice Maximum number of swaps allowed per block
     */
    uint8 internal constant MAX_SWAPS_PER_BLOCK = 25;

    struct Assets {
        uint256[] amounts;
        address[] addresses;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

/**
 * @notice Contains all errors used throughout the Definitive contracts
 * @dev This file should only be used as an internal library.
 * @dev When adding a new error, add alphabetically
 */

error AccountMissingRole(address _account, bytes32 _role);
error AccountNotAdmin(address);
error AccountNotWhitelisted(address);
error AddLiquidityFailed();
error DeadlineExceeded();
error BorrowFailed(uint256 errorCode);
error DecollateralizeFailed(uint256 errorCode);
error DepositMoreThanMax();
error EnterAllFailed();
error EnforcedSafeLTV(uint256 invalidLTV);
error ExceededMaxDelta();
error ExceededMaxLTV();
error ExceededShareToAssetRatioDeltaThreshold();
error ExitAllFailed();
error ExitOneCoinFailed();
error InitializeMarketsFailed();
error InputGreaterThanStaked();
error InsufficientBalance();
error InsufficientSwapTokenBalance();
error InvalidAddress();
error InvalidAmount();
error InvalidAmounts();
error InvalidCalldata();
error InvalidDestinationSwapper();
error InvalidERC20Address();
error InvalidExecutedOutputAmount();
error InvalidFeePercent();
error InvalidHandler();
error InvalidInputs();
error InvalidMsgValue();
error InvalidSingleHopSwap();
error InvalidMultiHopSwap();
error InvalidOutputToken();
error InvalidRedemptionRecipient(); // Used in cross-chain redeptions
error InvalidReportedOutputAmount();
error InvalidRewardsClaim();
error InvalidSignature();
error InvalidSignatureLength();
error InvalidSwapHandler();
error InvalidSwapInputAmount();
error InvalidSwapOutputToken();
error InvalidSwapPath();
error InvalidSwapPayload();
error InvalidSwapToken();
error MintMoreThanMax();
error NativeAssetWrapFailed(bool wrappingToNative);
error NoSignatureVerificationSignerSet();
error RedeemMoreThanMax();
error RemoveLiquidityFailed();
error RepayDebtFailed();
error SafeHarborModeEnabled();
error SafeHarborRedemptionDisabled();
error SlippageExceeded(uint256 _outputAmount, uint256 _outputAmountMin);
error StakeFailed();
error SupplyFailed();
error StopGuardianEnabled();
error SwapDeadlineExceeded();
error SwapLimitExceeded();
error SwapTokenIsOutputToken();
error TransfersLimitExceeded();
error UnstakeFailed();
error UnauthenticatedFlashloan();
error UntrustedFlashLoanSender(address);
error WithdrawMoreThanMax();
error ZeroShares();

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ICoreMulticallV1 } from "../../../core/CoreMulticall/v1/ICoreMulticallV1.sol";
import { IBasePermissionedExecution } from "../../../base/BasePermissionedExecution/IBasePermissionedExecution.sol";

interface ILPStakingStrategyV1 is ICoreMulticallV1, IBasePermissionedExecution {
    event AddLiquidity(uint256[] amounts, uint256 lpTokenAmount);
    event RemoveLiquidity(uint256 lpTokenAmount, uint256[] amounts);
    event Stake(uint256 amount);
    event Unstake(uint256 amount);

    event Enter(uint256[] amounts, uint256 stakedAmount);
    event Exit(uint256 unstakedAmount, uint256[] amounts);
    event ExitOne(uint256 unstakedAmount, address erc20Token, uint256 amount);

    function LP_UNDERLYING_TOKENS(uint256 arg_0) external returns (address);

    function LP_UNDERLYING_TOKENS_COUNT() external returns (uint256);

    function LP_DEPOSIT_POOL() external returns (address);

    function LP_STAKING() external returns (address);

    function LP_TOKEN() external returns (address);

    function addLiquidity(uint256[] calldata amounts, uint256 minAmount) external returns (uint256);

    function removeLiquidity(uint256 lpTokenAmount, uint256[] calldata minAmounts) external returns (uint256[] memory);

    function removeLiquidityOneCoin(
        uint256 lpTokenAmount,
        uint256 minAmount,
        uint8 index
    ) external returns (uint256[] memory);

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function getAmountStaked() external view returns (uint256 amount);

    function enter(uint256[] calldata amounts, uint256 minAmount) external returns (uint256 stakedAmount);

    function exitOne(uint256 lpTokenAmount, uint256 minAmount, uint8 index) external returns (uint256 amount);

    function exit(uint256 lpTokenAmount, uint256[] calldata minAmounts) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { IBaseMultiUserStrategyV1 } from "../../../base/BaseMultiUserStrategy/IBaseMultiUserStrategyV1.sol";

interface IMultiUserLPStakingStrategyV1 is IBaseMultiUserStrategyV1 {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event DepositUnderlying(address indexed caller, address indexed _owner, uint256[] amounts, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event WithdrawUnderlying(
        address indexed caller,
        address indexed receiver,
        address indexed _owner,
        uint256[] amounts,
        address[] assetAddresses,
        uint256 shares
    );

    event WithdrawOneUnderlying(
        address indexed caller,
        address indexed receiver,
        address indexed _owner,
        uint256 amount,
        uint256 index,
        uint256 shares
    );

    event SafeAssetsUpdated(address account, address[] safeAssets);

    function depositUnderlying(
        uint256[] calldata amounts,
        uint256 minAmount,
        address receiver
    ) external payable returns (uint256 shares);

    function redeemUnderlying(
        uint256 shares,
        uint256[] calldata minAmounts,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) external returns (address[] memory assetAddresses, uint256[] memory amounts);

    function redeemOneUnderlying(
        uint256 shares,
        uint8 index,
        uint256 minAmount,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) external returns (address assetAddress, uint256 amount);

    function asset() external view returns (address assetTokenAddress);

    function totalAssets() external view returns (uint256 totalManagedAssets);

    function convertToShares(uint256 assets) external view returns (uint256 shares);

    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function maxMint(address receiver) external view returns (uint256 maxShares);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 additionalFeePct
    ) external returns (uint256 shares);

    function maxRedeem(address owner) external view returns (uint256 maxShares);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 additionalFeePct
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {
    DepositMoreThanMax,
    MintMoreThanMax,
    WithdrawMoreThanMax,
    InvalidInputs,
    InvalidMsgValue,
    RedeemMoreThanMax,
    SafeHarborRedemptionDisabled,
    ZeroShares
} from "../../../core/libraries/DefinitiveErrors.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { DefinitiveConstants } from "../../../core/libraries/DefinitiveConstants.sol";
import { DefinitiveAssets } from "../../../core/libraries/DefinitiveAssets.sol";
import { ILPStakingStrategyV1 } from "./ILPStakingStrategyV1.sol";
import { IBaseTransfersNativeV1 } from "../../../base/BaseTransfersNative/v1/IBaseTransfersNativeV1.sol";
import { IBaseSafeHarborMode } from "../../../base/BaseSafeHarborMode/IBaseSafeHarborMode.sol";
import { BaseMultiUserStrategyV1 } from "../../../base/BaseMultiUserStrategy/BaseMultiUserStrategyV1.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    IERC20MetadataUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { IMultiUserLPStakingStrategyV1 } from "./IMultiUserLPStakingStrategyV1.sol";
import { StorageSlotUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";

interface ILPStakingStrategy is ILPStakingStrategyV1, IBaseTransfersNativeV1, IBaseSafeHarborMode {
    function DEFAULT_ADMIN_ROLE() external returns (bytes32);
}

contract MultiUserLPStakingStrategy is IMultiUserLPStakingStrategyV1, BaseMultiUserStrategyV1 {
    using DefinitiveAssets for IERC20;
    using MathUpgradeable for uint256;

    /// @dev If a BaseMultiUserShares is created, move these items to that class and inherit from it
    /// @dev Doing so will preserve the storage locations and clean up this contract
    IERC20Upgradeable private _asset;
    uint8 private _underlyingDecimals;
    uint256[49] private __gap;

    address[] public UNDERLYING_ASSETS;
    uint256 public UNDERLYING_ASSETS_COUNT;
    address[] public SAFE_ASSETS;
    uint256 public SAFE_ASSETS_COUNT;

    /// @notice Defines the ABI version of MultiUserLPStakingStrategy
    uint256 public constant ABI_VERSION = 1;

    /// @notice Constructor on the implementation contract should call _disableInitializers()
    /// @dev https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/2
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev ALWAYS INCLUDE VAULT: To maintain MU_* and Vault relationship during upgrades
    function initialize(
        address payable _vault,
        string memory _name,
        string memory _symbol,
        address _feeAccount
    ) public initializer {
        __BaseMultiUserStrategy_init(address(_vault), _name, _symbol, _feeAccount);

        IERC20Upgradeable mAsset = IERC20Upgradeable(ILPStakingStrategy(_vault).LP_TOKEN());
        _asset = mAsset;
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(mAsset);
        _underlyingDecimals = success ? assetDecimals : 18;

        uint256 mUNDERLYING_ASSETS_COUNT = ILPStakingStrategy(VAULT).LP_UNDERLYING_TOKENS_COUNT();
        UNDERLYING_ASSETS_COUNT = mUNDERLYING_ASSETS_COUNT;
        UNDERLYING_ASSETS = new address[](mUNDERLYING_ASSETS_COUNT);

        uint256 i;
        while (i < mUNDERLYING_ASSETS_COUNT) {
            UNDERLYING_ASSETS[i] = ILPStakingStrategy(_vault).LP_UNDERLYING_TOKENS(i);
            unchecked {
                i++;
            }
        }

        SAFE_ASSETS = UNDERLYING_ASSETS;
        SAFE_ASSETS_COUNT = mUNDERLYING_ASSETS_COUNT;
    }

    // OZ:4626 Start
    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     */
    function decimals() public view virtual override(IERC20MetadataUpgradeable, ERC20Upgradeable) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address _owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(_owner), MathUpgradeable.Rounding.Down);
    }

    function maxRedeem(address _owner) public view virtual override returns (uint256) {
        return balanceOf(_owner);
    }

    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function _convertToShares(
        uint256 assets,
        MathUpgradeable.Rounding rounding
    ) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    function _convertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding rounding
    ) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }

    function _tryGetAssetDecimals(IERC20Upgradeable asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20MetadataUpgradeable.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    // OZ:4626 End

    function setSafeAssets(address[] calldata _safeAssets) external onlyDefinitiveVaultAdmins {
        {
            uint256 i;
            uint256 length = _safeAssets.length;
            if (length == 0) {
                revert InvalidInputs();
            }

            while (i < length) {
                if (_safeAssets[i] == address(0)) {
                    revert InvalidInputs();
                }
                unchecked {
                    ++i;
                }
            }
        }

        SAFE_ASSETS = _safeAssets;
        SAFE_ASSETS_COUNT = _safeAssets.length;

        emit SafeAssetsUpdated(_msgSender(), _safeAssets);
    }

    function deposit(uint256 assets, address receiver) public revertIfSafeHarborModeEnabled returns (uint256 shares) {
        if (assets > maxDeposit(receiver)) {
            revert DepositMoreThanMax();
        }

        shares = previewDeposit(assets);
        if (shares == 0) {
            revert ZeroShares();
        }

        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    function mint(uint256 shares, address receiver) public revertIfSafeHarborModeEnabled returns (uint256 assets) {
        if (shares > maxMint(receiver)) {
            revert MintMoreThanMax();
        }

        if (shares == 0) {
            revert ZeroShares();
        }

        assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) public revertIfSafeHarborModeEnabled returns (uint256 shares) {
        if (assets > maxWithdraw(_owner)) {
            revert WithdrawMoreThanMax();
        }

        shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, _owner, assets, shares, additionalFeePct);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) public revertIfSafeHarborModeEnabled returns (uint256 assets) {
        if (shares > maxRedeem(_owner)) {
            revert RedeemMoreThanMax();
        }

        assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, _owner, assets, shares, additionalFeePct);
    }

    function totalAssets() public view virtual returns (uint256) {
        return ILPStakingStrategy(VAULT).getAmountStaked();
    }

    function depositUnderlying(
        uint256[] calldata amounts,
        uint256 minAmount,
        address receiver
    ) public payable virtual nonReentrant revertIfSafeHarborModeEnabled returns (uint256 shares) {
        _transferUnderlyingAssetsFrom(amounts);
        _approveUnderlyingForDeposit(amounts);

        // Deposit to vault
        ILPStakingStrategy(VAULT).deposit{ value: msg.value }(amounts, UNDERLYING_ASSETS);

        // Add liquidity to vault
        uint256 assets = ILPStakingStrategy(VAULT).addLiquidity(amounts, minAmount);

        /// @notice Calculate shares AFTER adding liquidity and BEFORE minting
        /// @dev `previewDeposit` calculates using the amount staked before additional liquidity is added
        shares = previewDeposit(assets);

        if (shares == 0) {
            revert ZeroShares();
        }

        ILPStakingStrategy(VAULT).stake(assets);

        _mint(receiver, shares);

        emit DepositUnderlying(_msgSender(), receiver, amounts, shares);
    }

    /**
     * Redeem shares for underlying assets
     * @param shares Total shares to redeem; Should include fees (Redeemed Shares + Fee Shares)
     * @param minAmounts minAmounts for each asset; Should exclude fees
     *          (`removeLiquidity` will be called with `shares - feeShares`)
     * @param receiver address
     * @param _owner address
     * @return assetAddresses
     * @return amounts
     */
    function redeemUnderlying(
        uint256 shares,
        uint256[] calldata minAmounts,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) public nonReentrant returns (address[] memory assetAddresses, uint256[] memory amounts) {
        if (shares > maxRedeem(_owner)) {
            revert RedeemMoreThanMax();
        }

        uint256 assets = previewRedeem(shares);

        (assetAddresses, amounts) = _withdrawUnderlying(
            _msgSender(),
            receiver,
            _owner,
            assets,
            minAmounts,
            shares,
            additionalFeePct
        );
    }

    /**
     *
     * @param shares Total shares to redeem; Should include fees (Redeemed Shares + Fee Shares)
     * @param index uint8
     * @param minAmount minAmount for selected asset; Should exclude fees
     *          (`removeLiquidity` will be called with `shares - feeShares`)
     * @param receiver address
     * @param _owner address
     * @return assetAddress
     * @return amount
     */
    function redeemOneUnderlying(
        uint256 shares,
        uint8 index,
        uint256 minAmount,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) public nonReentrant revertIfSafeHarborModeEnabled returns (address assetAddress, uint256 amount) {
        if (shares > maxRedeem(_owner)) {
            revert RedeemMoreThanMax();
        }

        uint256 assets = previewRedeem(shares);

        (assetAddress, amount) = _withdrawOneUnderlying(
            _msgSender(),
            receiver,
            _owner,
            assets,
            index,
            minAmount,
            shares,
            additionalFeePct
        );
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        IERC20(asset()).safeTransferFrom(caller, address(this), assets);

        (uint256[] memory assetAmounts, address[] memory assetAddresses) = (new uint256[](1), new address[](1));
        (assetAmounts[0], assetAddresses[0]) = (assets, asset());

        IERC20(asset()).resetAndSafeIncreaseAllowance(address(this), address(VAULT), assets);

        ILPStakingStrategy(VAULT).deposit(assetAmounts, assetAddresses);

        // `previewDeposit`/`previewMint` calculates using the amount staked before additional liquidity is added
        // Shares must be calculated BEFORE staking
        ILPStakingStrategy(VAULT).stake(assets);

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address _owner,
        uint256 assets,
        uint256 shares,
        uint256 additionalFeePct
    ) internal {
        if (caller != _owner) {
            _spendAllowance(_owner, caller, shares);
        }

        /// @dev If fees are enabled, handle fees then recalculate shares and assets
        (shares, assets) = _handleRedemptionFees(_owner, shares, additionalFeePct);

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(_owner, shares);

        ILPStakingStrategy(VAULT).unstake(assets);
        ILPStakingStrategy(VAULT).withdraw(assets, asset());

        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, _owner, assets, shares);
    }

    function _withdrawUnderlying(
        address caller,
        address receiver,
        address _owner,
        uint256 assets,
        uint256[] calldata minAmounts,
        uint256 shares,
        uint256 additionalFeePct
    ) internal returns (address[] memory assetAddresses, uint256[] memory amounts) {
        if (caller != _owner) {
            _spendAllowance(_owner, caller, shares);
        }

        /// @dev If fees are enabled, handle fees then recalculate shares and assets
        (shares, assets) = _handleRedemptionFees(_owner, shares, additionalFeePct);

        // Get total supply before burning shares
        uint256 mPreviousTotalSupply = totalSupply();

        _burn(_owner, shares);

        if (ILPStakingStrategy(VAULT).SAFE_HARBOR_MODE_ENABLED()) {
            if (!bool(StorageSlotUpgradeable.getBooleanSlot(_ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT).value)) {
                revert SafeHarborRedemptionDisabled();
            }
            assetAddresses = SAFE_ASSETS;
            amounts = new uint256[](assetAddresses.length);
            uint256 length = amounts.length;
            uint256 i;
            while (i < length) {
                uint256 balance = ILPStakingStrategy(VAULT).getBalance(assetAddresses[i]);
                amounts[i] = ((balance * shares) / mPreviousTotalSupply);
                unchecked {
                    i++;
                }
            }
        } else {
            assetAddresses = UNDERLYING_ASSETS;
            amounts = ILPStakingStrategy(VAULT).exit(assets, minAmounts);
        }

        {
            uint256 i;
            while (i < assetAddresses.length) {
                if (amounts[i] > 0) {
                    // Withdraw from vault to this contract
                    ILPStakingStrategy(VAULT).withdraw(amounts[i], assetAddresses[i]);

                    // Send to receiver
                    _transferAsset(receiver, assetAddresses[i], amounts[i]);
                }

                unchecked {
                    i++;
                }
            }
        }

        emit WithdrawUnderlying(caller, receiver, _owner, amounts, assetAddresses, shares);
    }

    function _withdrawOneUnderlying(
        address caller,
        address receiver,
        address _owner,
        uint256 assets,
        uint8 index,
        uint256 minAmount,
        uint256 shares,
        uint256 additionalFeePct
    ) internal returns (address assetAddress, uint256 amount) {
        if (caller != _owner) {
            _spendAllowance(_owner, caller, shares);
        }

        /// @dev If fees are enabled, handle fees then recalculate shares and assets
        (shares, assets) = _handleRedemptionFees(_owner, shares, additionalFeePct);

        _burn(_owner, shares);

        amount = ILPStakingStrategy(VAULT).exitOne(assets, minAmount, index);

        assetAddress = UNDERLYING_ASSETS[index];

        // Withdraw from vault to this contract
        ILPStakingStrategy(VAULT).withdraw(amount, assetAddress);

        _transferAsset(receiver, assetAddress, amount);

        emit WithdrawOneUnderlying(_msgSender(), receiver, _owner, amount, index, assets);
    }

    function _transferAsset(address recipient, address assetAddress, uint256 amount) internal {
        if (assetAddress == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            DefinitiveAssets.safeTransferETH(payable(recipient), amount);
        } else {
            IERC20(assetAddress).safeTransfer(recipient, amount);
        }
    }

    function _transferUnderlyingAssetsFrom(uint256[] memory amounts) internal {
        address[] memory assetAddresses = UNDERLYING_ASSETS;
        uint256 assetAddressesLength = assetAddresses.length;
        if (amounts.length != assetAddressesLength) {
            revert InvalidInputs();
        }
        bool hasNativeAsset;
        uint256 nativeAssetIndex;

        for (uint256 i; i < assetAddressesLength; ) {
            if (UNDERLYING_ASSETS[i] == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
                nativeAssetIndex = i;
                hasNativeAsset = true;
                unchecked {
                    ++i;
                }
                continue;
            }
            // ERC20 tokens
            if (amounts[i] > 0) {
                IERC20(UNDERLYING_ASSETS[i]).safeTransferFrom(_msgSender(), address(this), amounts[i]);
            }
            unchecked {
                ++i;
            }
        }
        // Revert if NATIVE_ASSET_ADDRESS is not in assetAddresses and msg.value is not zero
        if (!hasNativeAsset && msg.value != 0) {
            revert InvalidMsgValue();
        }

        // Revert if depositing native asset and amount != msg.value
        if (hasNativeAsset && msg.value != amounts[nativeAssetIndex]) {
            revert InvalidMsgValue();
        }
    }

    function _approveUnderlyingForDeposit(uint256[] memory amounts) internal {
        (
            uint256 mUNDERLYING_ASSETS_COUNT,
            address[] memory mUNDERLYING_ASSETS,
            address mNATIVE_ASSET_ADDRESS,
            address mVAULT
        ) = (UNDERLYING_ASSETS_COUNT, UNDERLYING_ASSETS, DefinitiveConstants.NATIVE_ASSET_ADDRESS, VAULT);

        uint256 i;
        while (i < mUNDERLYING_ASSETS_COUNT) {
            if (amounts[i] > 0 && mUNDERLYING_ASSETS[i] != mNATIVE_ASSET_ADDRESS) {
                IERC20(mUNDERLYING_ASSETS[i]).resetAndSafeIncreaseAllowance(address(this), mVAULT, amounts[i]);
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates the shares and recalculates assets after handling fees
     * @param _owner address
     * @param shares uint256
     * @return shares uint256
     * @return assets uint256
     */
    function _handleRedemptionFees(
        address _owner,
        uint256 shares,
        uint256 additionalFeePct
    ) internal returns (uint256, uint256) {
        shares -= _handleRedemptionFeesOnShares(_owner, address(this), shares, additionalFeePct);

        return (shares, previewRedeem(shares));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IWETH9 {
    function balanceOf(address) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}