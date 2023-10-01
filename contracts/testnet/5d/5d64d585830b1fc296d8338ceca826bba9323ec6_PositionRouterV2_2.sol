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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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

pragma solidity ^0.8.12;

contract BasePositionConstants {
    //Constant params
    // uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals
    // uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint256 public constant POSITION_MARKET = 0;
    uint256 public constant POSITION_LIMIT = 1;
    uint256 public constant POSITION_STOP_MARKET = 2;
    uint256 public constant POSITION_STOP_LIMIT = 3;
    uint256 public constant POSITION_TRAILING_STOP = 4;

    //Change these constants or must notice on login of PositionRouter
    uint256 public constant CREATE_POSITION_MARKET = 1;
    uint256 public constant CREATE_POSITION_LIMIT = 2;
    uint256 public constant CREATE_POSITION_STOP_MARKET = 3;
    uint256 public constant CREATE_POSITION_STOP_LIMIT = 4;

    uint256 public constant ADD_COLLATERAL = 5;
    uint256 public constant REMOVE_COLLATERAL = 6;
    uint256 public constant ADD_POSITION = 7;
    uint256 public constant CONFIRM_POSITION = 8;
    uint256 public constant ADD_TRAILING_STOP = 9;
    uint256 public constant UPDATE_TRAILING_STOP = 10;
    uint256 public constant TRIGGER_POSITION = 11;
    uint256 public constant UPDATE_TRIGGER_POSITION = 12;
    uint256 public constant CANCEL_PENDING_ORDER = 13;
    uint256 public constant CLOSE_POSITION = 14;
    uint256 public constant LIQUIDATE_POSITION = 15;
    uint256 public constant REVERT_EXECUTE = 16;
    //uint public constant STORAGE_PATH = 99; //Internal usage for router only

    uint256 public constant TRANSACTION_STATUS_NONE = 0;
    uint256 public constant TRANSACTION_STATUS_PENDING = 1;
    uint256 public constant TRANSACTION_STATUS_EXECUTED = 2;
    uint256 public constant TRANSACTION_STATUS_EXECUTE_REVERTED = 3;
    //End constant params

    function _getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong, _posId));
    }

    function _getTxTypeFromPositionType(uint256 _positionType) internal pure returns (uint256) {
        if (_positionType == POSITION_LIMIT) {
            return CREATE_POSITION_LIMIT;
        } else if (_positionType == POSITION_STOP_MARKET) {
            return CREATE_POSITION_STOP_MARKET;
        } else if (_positionType == POSITION_STOP_LIMIT) {
            return CREATE_POSITION_STOP_LIMIT;
        } else {
            revert("IVLPST"); //Invalid positionType
        }
    } 

    function _isDelayPosition(uint256 _txType) internal pure returns (bool) {
        return _txType == CREATE_POSITION_STOP_LIMIT
            || _txType == CREATE_POSITION_STOP_MARKET
            || _txType == CREATE_POSITION_LIMIT;
    }

    function _isOpenPosition(uint256 _txType) internal pure returns (bool) {
        return _txType == CREATE_POSITION_MARKET 
            || _isDelayPosition(_txType);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./BasePositionConstants.sol";

contract PositionConstants is BasePositionConstants {
    //Constant params
    uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint8 public constant ORDER_FILLED = 1;

    uint256 public constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 public constant TRAILING_STOP_TYPE_PERCENT = 1;

    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;

    // function checkSlippage(
    //     bool isLong,
    //     uint256 expectedMarketPrice,
    //     uint256 slippageBasisPoints,
    //     uint256 actualMarketPrice
    // ) internal pure returns (bool) {
    //     return isLong 
    //         ? (actualMarketPrice <=
    //                 (expectedMarketPrice * (BASIS_POINTS_DIVISOR + slippageBasisPoints)) / BASIS_POINTS_DIVISOR)
    //         : ((expectedMarketPrice * (BASIS_POINTS_DIVISOR - slippageBasisPoints)) / BASIS_POINTS_DIVISOR <=
    //                 actualMarketPrice);
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT,
    TRAILING_STOP
}

enum OrderStatus {
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    OPEN,
    TRIGGERED,
    CANCELLED
}

enum DataType {
    POSITION,
    ORDER
}

struct OrderInfo {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 pendingSize;
    uint256 pendingCollateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
    address collateralToken;
}

struct Position {
    address owner;
    address indexToken;
    bool isLong;
    int256 realisedPnl;
    uint256 averagePrice;
    uint256 collateral;
    int256 entryFunding;
    uint256 lastIncreasedTime;
    uint256 lastPrice;
    uint256 reserveAmount;
    uint256 size;
    uint256 posId;
    uint256 previousFee;
}

struct TriggerOrder {
    bytes32 key;
    bool isLong;
    uint256[] slPrices;
    uint256[] slAmountPercents;
    uint256[] slTriggeredAmounts;
    uint256[] tpPrices;
    uint256[] tpAmountPercents;
    uint256[] tpTriggeredAmounts;
    TriggerStatus status;
}

struct ConvertOrder {
    uint256 index;
    address indexToken;
    address sender;
    address recipient;
    uint256 amountIn;
    uint256 amountOut;
    uint256 state;
}

struct SwapPath {
    address pairAddress;
    uint256 fee;
}

struct SwapRequest {
    bytes32 orderKey;
    address tokenIn;
    address pool;
    uint256 amountIn;
}

struct PrepareTransaction {
    uint256 txType;
    uint256 startTime;

    /*
    uint256 public constant TRANSACTION_STATUS_NONE = 0;
    uint256 public constant TRANSACTION_STATUS_PENDING = 1;
    uint256 public constant TRANSACTION_STATUS_EXECUTED = 2;
    uint256 public constant TRANSACTION_STATUS_EXECUTE_REVERTED = 3;
    */
    uint256 status;
}

struct TxDetail {
    uint256[] params;
    address[] path;
}

struct VaultBond {
    address owner;
    address token; //Collateral token
    uint256 amount; //Collateral amount
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IPriceManager {
    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _indexPrice
    ) external view returns (bool, uint256);

    function getLastPrice(address _token) external view returns (uint256);

    function getLatestSynchronizedPrice(address _token) external view returns (uint256, uint256, bool);

    function getLatestSynchronizedPrices(address[] memory _tokens) external view returns (uint256[] memory, bool);

    function setLatestPrice(address _token, uint256 _latestPrice) external;

    function setLatestPrices(address[] memory _tokens, uint256[] memory _prices) external;

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _nextPrice
    ) external view returns (uint256);

    function isForex(address _token) external view returns (bool);

    function maxLeverage(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function fromUSDToToken(address _token, uint256 _usdAmount) external view returns (uint256);

    function fromUSDToToken(address _token, uint256 _tokenAmount, uint256 _tokenPrice) external view returns (uint256);

    function fromTokenToUSD(address _token, uint256 _tokenAmount) external view returns (uint256);

    function fromTokenToUSD(address _token, uint256 _tokenAmount, uint256 _tokenPrice) external view returns (uint256);

    function getTokenDecimals(address _token) external view returns(uint256);

    function floorTokenAmount(uint256 _amount, address _token) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ISwapRouter {
    function swapFromInternal(
        address _account,
        bytes32 _key,
        uint256 _txType,
        uint256 _amountIn, 
        uint256 _amountOutMin,
        address[] memory _path
    ) external returns (address, uint256);

    function swap(
        address _account,
        address _receiver,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract BaseExecutorV2 is OwnableUpgradeable {
    mapping(address => bool) public executors;

    event SetExecutor(address indexed account, bool hasAccess);

    function initialize() internal virtual {
        if (owner() == address(0)) {
            __Ownable_init();
        }
    }

    function setExecutor(address _account, bool _hasAccess) onlyOwner external {
        executors[_account] = _hasAccess;
        emit SetExecutor(_account, _hasAccess);
    }

    function _isExecutor(address _account) internal view returns (bool) {
        return executors[_account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../core/interfaces/IPriceManager.sol";
import "../../constants/PositionConstants.sol";

import "../core/interfaces/ISettingsManagerV2.sol";
import "../core/interfaces/IPositionHandlerV2.sol";
import "../core/interfaces/IPositionKeeperV2.sol";
import "./BaseExecutorV2.sol";

abstract contract BasePositionV2 is PositionConstants, BaseExecutorV2 {
    IPriceManager public priceManager;
    ISettingsManagerV2 public settingsManager;
    IPositionHandlerV2 public positionHandler;
    IPositionKeeperV2 public positionKeeper;

    function _initialize(
        address _priceManager,
        address _settingsManager,
        address _positionHandler,
        address _positionKeeper
    ) internal {
        super.initialize();
        _baseInitialize(
            _priceManager,
            _settingsManager,
            _positionHandler,
            _positionKeeper
        );
    }
    
    function _baseInitialize(
        address _priceManager,
        address _settingsManager, 
        address _positionHandler,
        address _positionKeeper
    ) internal {
        require(AddressUpgradeable.isContract(_priceManager)
            && AddressUpgradeable.isContract(_settingsManager)
            && AddressUpgradeable.isContract(_positionHandler)
            && AddressUpgradeable.isContract(_positionKeeper), "IVLCA"); //Invalid contract
        priceManager  = IPriceManager(_priceManager);
        settingsManager = ISettingsManagerV2(_settingsManager);
        positionHandler = IPositionHandlerV2(_positionHandler);
        positionKeeper = IPositionKeeperV2(_positionKeeper);
    }

    function _prevalidate(address _indexToken) internal view {
        require(settingsManager.marketOrderEnabled() 
            && settingsManager.isTradable(_indexToken), "SM/PF"); //SettingsManager: Prevalidate failed
    }

    function _getPriceAndCheckFastExecute(address _indexToken) internal view returns (bool, uint256) {
        (uint256 price, , bool isFastExecute) = priceManager.getLatestSynchronizedPrice(_indexToken);
        return (isFastExecute, price);
    }

    function _getPricesAndCheckFastExecute(address[] memory _path) internal view returns (bool, uint256[] memory) {
        require(_path.length >= 1, "IVLPTL"); //Invalid path length
        bool isFastExecute;
        uint256[] memory prices;
        (prices, isFastExecute) = priceManager.getLatestSynchronizedPrices(_path);

        return (isFastExecute, prices);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IPositionHandlerV2 {
    function modifyPosition(
        bytes32 _key,
        uint256 _txType, 
        address[] memory _path,
        uint256[] memory _prices,
        bytes memory _data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {
    Position, 
    OrderInfo, 
    OrderType, 
    DataType, 
    OrderStatus
} from "../../../constants/Structs.sol";

interface IPositionKeeperV2 {
    function leverages(bytes32 _key) external returns (uint256);

    function globalAmounts(address _token, bool _isLong) external view returns (uint256);

    function openNewPosition(
        bytes32 _key,
        bool _isLong, 
        uint256 _posId,
        address[] memory _path,
        uint256[] memory _params,
        bytes memory _data
    ) external;

    function unpackAndStorage(bytes32 _key, bytes memory _data, DataType _dataType) external;

    function deletePosition(bytes32 _key) external;

    function deleteOrder(bytes32 _key) external;

    function deletePositions(bytes32 _key) external;

    //Emit event functions
    function emitAddPositionEvent(
        bytes32 key, 
        bool confirmDelayStatus, 
        uint256 collateral, 
        uint256 size
    ) external;

    function emitAddOrRemoveCollateralEvent(
        bytes32 _key,
        bool _isPlus,
        uint256 _amount,
        uint256 _amountInUSD,
        uint256 _reserveAmount,
        uint256 _collateral,
        uint256 _size
    ) external;

    function emitAddTrailingStopEvent(bytes32 _key, uint256[] memory data) external;

    function emitUpdateTrailingStopEvent(bytes32 _key, uint256 _stpPrice) external;

    function emitUpdateOrderEvent(bytes32 _key, uint256 _positionType, OrderStatus _orderStatus) external;

    function emitConfirmDelayTransactionEvent(
        bytes32 _key,
        bool _confirmDelayStatus,
        uint256 _collateral,
        uint256 _size,
        uint256 _feeUsd
    ) external;

    function emitPositionExecutedEvent(
        bytes32 _key,
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _prices
    ) external;

    function emitIncreasePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external;

    function emitDecreasePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 tradingFee,
        int256 _fundingFee,
        bool _isPartialClose
    ) external ;

    function emitLiquidatePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _fee
    ) external;

    function updateGlobalShortData(
        uint256 _sizeDelta,
        uint256 _indexPrice,
        bool _isIncrease,
        bytes memory _data
    ) external;

    //View functions
    function getPositions(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view returns (Position memory, OrderInfo memory);

    function getPositions(bytes32 _key) external view returns (Position memory, OrderInfo memory);

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view returns (Position memory);

    function getPosition(bytes32 _key) external view returns (Position memory);

    function getOrder(bytes32 _key) external view returns (OrderInfo memory);

    function getPositionPreviousFee(bytes32 _key) external view returns (uint256);

    function getPositionSize(bytes32 _key) external view returns (uint256);

    function getPositionOwner(bytes32 _key) external view returns (address);

    function getPositionIndexToken(bytes32 _key) external view returns (address);

    function getPositionCollateralToken(bytes32 _key) external view returns (address);

    function getPositionFinalPath(bytes32 _key) external view returns (address[] memory);

    function lastPositionIndex(address _account) external view returns (uint256);

    function getBasePosition(bytes32 _key) external view returns (address, address, bool, uint256);

    function getPositionType(bytes32 _key) external view returns (bool);

    function getGlobalShortDelta(address _token) external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {PrepareTransaction, TxDetail, OrderType} from "../../../constants/Structs.sol";

interface IPositionRouterV2 {
    /*
    @dev: Open new position.
    Path length must between 2 to 3 which:
        path[0] is approval tradable (isTradable)
        If enableNonStableCollateral is true:
            + Path lengths must be 2, which path[1] is approval stable (isStable) or approval collateral (isCollateral)
        Else: 
            + Path lengths must be 2, which path[1] isStable
            + Path length must be 3, which path[1] isCollateral and path[2] isStable
    Params length must be 8.
        param[0] is mark price (for market type only, other type use 0)
        param[1] is slippage (for market type only, other type use 0)
        param[2] is limit price (for limit/stop/stop_limit type only, market use 0)
        param[3] is stop price (for limit/stop/stop_limit type only, market use 0)
        param[4] is collateral amount
        param[5] is size (collateral * leverage)
        param[6] is deadline (for market type only, other type use 0)
        param[7] is min stable received if swap is required
    */
    function openNewPosition(
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address[] memory _path
    ) external payable;

    /*
    @dev: Add or remove collateral.
    + AddCollateral: _isPlus is true, 
        Params length must be 1, which params[0] is collateral token amount
    + RemoveCollateral: _isPlus is false,
        Params length must be 2, which params[0] is sizeDelta in USD, params[1] is deadline
    Path is same as openNewPosition
    */
    function addOrRemoveCollateral(
        bool _isLong,
        uint256 _posId,
        bool _isPlus,
        uint256[] memory _params,
        address[] memory _path
    ) external;

    /*
    @dev: Add to exist position.
    Params length must be 3, which:
        params[0] is collateral token amount,
        params[1] is collateral size (params[0] x leverage)
    path is same as openNewPosition
    */
    function addPosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external payable;

    /*
    @dev: Add trailing stop.
    Params length must be 5, which:
        [0] is pending collateral,
        [1] is pending size,
        [2] is step type,
        [3] is stop price,
        [4] is step amount
    */
    function addTrailingStop(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external payable;

    /*
    @dev: Update trailing stop.
    */
    function updateTrailingStop(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _indexPrice
    ) external;

    /*
    @dev: Cancel pending order, not allow to cancel market order
    */
    function cancelPendingOrder(
        address _indexToken, 
        bool _isLong, 
        uint256 _posId
    ) external;

    /*
    @dev: Close position
    Params length must be 2, which: 
        [0] is closing size delta in USD,
        [1] is deadline
    Path length must between 2 or 3, which: 
        [0] is indexToken, 
        [1] or [2] must be isStable or isCollateral (same logic enableNonStableCollateral)
    */
    function closePosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external;

    function triggerPosition(
        bytes32 _key,
        bool _isFastExecute,
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices
    ) external;

    /*
    @dev: Execute delay transaction, can only call by executor/positionHandler
    */
    function execute(
        bytes32 _key, 
        uint256 _txType,
        uint256[] memory _prices
    ) external;

    /*
    @dev: Revert execution when trying to execute transaction not success, can only call by executor/positionHandler
    */
    function revertExecution(
        bytes32 _key, 
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices, 
        string memory err
    ) external;

    function clearPrepareTransaction(bytes32 _key, uint256 _txType) external;

    //View functions
    function getExecutePath(bytes32 _key, uint256 _txType) external view returns (address[] memory);

    function getPath(bytes32 _key, uint256 _txType) external view returns (address[] memory);

    function getParams(bytes32 _key, uint256 _txType) external view returns (uint256[] memory);

    function getTransaction(bytes32 _key) external view returns (PrepareTransaction memory);

    function getTxDetail(bytes32 _key, uint256 _txType) external view returns (TxDetail memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Position} from "../../../constants/Structs.sol";

interface ISettingsManagerV2 {
    function decreaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function openInterestPerAsset(address _token) external view returns (uint256);

    function openInterestPerSide(bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function closeDeltaTime() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function cumulativeFundingRates(address _token, bool _isLong) external view returns (uint256);

    function delayDeltaTime() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function feeManager() external view returns (address);

    function getFeeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function getPositionFee(address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isCollateral(address _token) external view returns (bool);

    function isTradable(address _token) external view returns (bool);

    function isStable(address _token) external view returns (bool);

    function isStaking(address _token) external view returns (bool);

    function lastFundingTimes(address _token) external view returns (uint256);

    function maxPriceUpdatedDelay() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function liquidateThreshold(address) external view returns (uint256);

    function marginFeeBasisPoints(address _token, bool _isLong) external view returns (uint256);

    function marketOrderEnabled() external view returns (bool);
    
    function pauseForexForCloseTime() external view returns (bool);

    function priceMovementPercent() external view returns (uint256);

    function referEnabled() external view returns (bool);

    function stakingFee() external view returns (uint256);

    function unstakingFee() external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function positionDefaultSlippage() external view returns (uint256);

    function setPositionDefaultSlippage(uint256 _slippage) external;

    function isEnableNonStableCollateral() external view returns (bool);

    function isEnableConvertRUSD() external view returns (bool);

    function isEnableUnstaking() external view returns (bool);

    function validatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _collateral
    ) external view;

    function isApprovalCollateralToken(address _token) external view returns (bool);

    function isApprovalCollateralToken(address _token, bool _raise) external view returns (bool);

    function isEmergencyStop() external view returns (bool);

    function validateCollateralPathAndCheckSwap(address[] memory _collateralPath) external view returns (bool);

    function maxProfitPercent() external view returns (uint256);

    function basisFundingRateFactor() external view returns (uint256);

    function maxFundingRate() external view returns (uint256);

    function fundingRateFactor(address _token) external view returns (uint256);

    function fundingIndex(address _token) external view returns (int256);

    function getFundingRate(address _indexToken, address _collateralToken) external view returns (int256);

    function defaultBorrowFeeFactor() external view returns (uint256);

    function borrowFeeFactor(address token) external view returns (uint256);

    function getFundingFee(
        address _indexToken,
        bool _isLong,
        uint256 _size,
        int256 _fundingIndex
    ) external view returns (int256);

    function getBorrowFee(
        address _indexToken,
        uint256 _borrowedSize,
        uint256 _lastIncreasedTime
    ) external view returns (uint256);

    function getFeesV2(
        bytes32 _key,
        uint256 _sizeDelta,
        uint256 _loanDelta,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee
    ) external view returns (uint256, int256);

    function getFees(
        uint256 _sizeDelta,
        uint256 _loanDelta,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee,
        Position memory _position
    ) external view returns (uint256, int256);

    function getDiscountFee(address _account, uint256 _fee) external view returns (uint256);

    function updateFunding(address _indexToken, address _collateralToken) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Position, OrderInfo, OrderType} from "../../../constants/Structs.sol";

interface IVaultUtilsV2 {
    function validateConfirmDelay(
        bytes32 _key,
        bool _raise
    ) external view returns (bool);

    function validateDecreasePosition(
        bool _raise, 
        uint256 _indexPrice,
        Position memory _position
    ) external view returns (bool);

    function validateLiquidation(
        bytes32 _key,
        bool _raise,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee,
        uint256 _indexPrice
    ) external view returns (uint256, uint256);

    function validateLiquidation(
        bool _raise,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee,
        uint256 _indexPrice,
        Position memory _position
    ) external view returns (uint256, uint256);

    function validatePositionData(
        bool _isLong,
        address _indexToken,
        OrderType _orderType,
        uint256 _latestTokenPrice,
        uint256[] memory _params,
        bool _raise,
        bool _isLatestPrice
    ) external view returns (bool);

    function validateSizeCollateralAmount(uint256 _size, uint256 _collateral) external view;

    function validateTrailingStopInputData(
        bytes32 _key,
        bool _isLong,
        uint256[] memory _params,
        uint256 _indexPrice
    ) external view returns (bool);

    function validateTrailingStopPrice(
        bool _isLong,
        bytes32 _key,
        bool _raise,
        uint256 _indexPrice
    ) external view returns (bool);

    function validateTrigger(
        bool _isLong,
        uint256 _indexPrice,
        OrderInfo memory _order
    ) external pure returns (uint8);

    function validateTrigger(
        bytes32 _key,
        uint256 _indexPrice
    ) external view returns (uint8);

    function validateAddOrRemoveCollateral(
        bytes32 _key,
        uint256 _amountIn,
        bool _isPlus,
        address _collateralToken,
        uint256 _indexPrice,
        uint256 _collateralPrice
    ) external returns (uint256, Position memory);

    function validateAddOrRemoveCollateral(
        uint256 _amountIn,
        bool _isPlus,
        address _collateralToken,
        uint256 _indexPrice,
        uint256 _collateralPrice,
        Position memory _position
    ) external returns (uint256, Position memory);

    function beforeDecreasePositionV2(
        bytes32 _key,
        uint256 _sizeDelta,
        uint256 _indexPrice
    ) external view returns (bool, int256, uint256[4] memory, Position memory);

    function beforeDecreasePosition(
        uint256 _sizeDelta,
        uint256 _indexPrice,
        Position memory _position
    ) external view returns (bool, int256, bytes memory);

    function calculatePnl(
        bytes32 _key,
        uint256 _sizeDelta,
        uint256 _loanDelta,
        uint256 _indexPrice,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee,
        bool _isLiquidated
    ) external view returns (bool, uint256, uint256, int256);

    function calculatePnl(
        uint256 _sizeDelta,
        uint256 _loanDelta,
        uint256 _indexPrice,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee,
        bool _isLiquidated,
        Position memory _position
    ) external view returns (bool, uint256, uint256, int256);

    function reCalculatePosition(
        uint256 _sizeDelta,
        uint256 _loanDelta,
        uint256 _indexPrice, 
        Position memory _position
    ) external view returns (uint256, int256);

    function increasePosition(
        address _collateralToken,
        uint256 _amountIn,
        uint256 _sizeDelta,
        uint256 _indexPrice,
        Position memory _position
    ) external returns (uint256, Position memory);

   function decreasePosition(
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _indexPrice,
        Position memory _position
    ) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {VaultBond} from "../../../constants/Structs.sol";

interface IVaultV2 {
    function stakeAmounts(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function increasePoolAmount(address _indexToken, uint256 _amount) external;
    function decreasePoolAmount(address _indexToken, uint256 _amount) external;

    function reservedAmounts(address _token) external view returns (uint256);
    function increaseReservedAmount(address _token, uint256 _amount) external;
    function decreaseReservedAmount(address _token, uint256 _amount) external;

    function guaranteedAmounts(address _token) external view returns (uint256);
    function increaseGuaranteedAmount(address _indexToken, uint256 _amount) external;
    function decreaseGuaranteedAmount(address _indexToken, uint256 _amount) external;

    function distributeFee(
        bytes32 _key, 
        address _account, 
        uint256 _fee
    ) external;

    function takeAssetIn(
        address _account, 
        uint256 _amount, 
        address _token,
        bytes32 _key,
        uint256 _txType
    ) external;

    function takeAssetOut(
        bytes32 _key,
        address _account, 
        uint256 _fee, 
        uint256 _usdOut, 
        address _token, 
        uint256 _tokenPrice
    ) external;

    function takeAssetBack(
        address _account, 
        bytes32 _key,
        uint256 _txType
    ) external;

    function decreaseBond(bytes32 _key, address _account, uint256 _txType) external;

    function transferBounty(address _account, uint256 _amount) external;

    function ROLP() external view returns(address);

    function RUSD() external view returns(address);

    function totalROLP() external view returns(uint256);

    function updateBalance(address _token) external;

    //function updateBalances() external;

    function getTokenBalance(address _token) external view returns (uint256);

    //function getTokenBalances() external view returns (address[] memory, uint256[] memory);

    function convertRUSD(
        address _account,
        address _recipient, 
        address _tokenOut, 
        uint256 _amount
    ) external;

    function stake(address _account, address _token, uint256 _amount) external;

    function unstake(address _tokenOut, uint256 _rolpAmount, address _receiver) external;

    function getBond(bytes32 _key, uint256 _txType) external view returns (VaultBond memory);

    // function getBondOwner(bytes32 _key, uint256 _txType) external view returns (address);

    // function getBondToken(bytes32 _key, uint256 _txType) external view returns (address);

    // function getBondAmount(bytes32 _key, uint256 _txType) external view returns (uint256);

    function getTotalUSD() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../base/BasePositionV2.sol";
import "../../swap/interfaces/ISwapRouter.sol";
import "./interfaces/IPositionRouterV2.sol";
import "./interfaces/IVaultV2.sol";
import "./interfaces/IVaultUtilsV2.sol";

import {Position, OrderInfo, VaultBond, OrderStatus} from "../../constants/Structs.sol";

contract PositionRouterV2_2 is BasePositionV2, IPositionRouterV2, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    mapping(bytes32 => PrepareTransaction) private txns;
    mapping(bytes32 => mapping(uint256 => TxDetail)) private txnDetails;

    IVaultV2 public vault;
    IVaultUtilsV2 public vaultUtils; 
    address public triggerOrderManager;

    //Implement later
    ISwapRouter public swapRouter; 
    
    event FinalInitialized(
        address priceManager,
        address settingsManager,
        address positionHandler,
        address positionKeeper,
        address vault, 
        address vaultUtils,
        address triggerOrderManager
    );
    event SetSwapRouter(address swapRouter);
    event CreatePrepareTransaction(
        address indexed account,
        bool isLong,
        uint256 posId,
        uint256 txType,
        uint256[] params,
        address[] path,
        bytes32 indexed key,
        bool isFastExecute
    );
    event ExecutionReverted(
        bytes32 key, 
        address account, 
        bool isLong, 
        uint256 posId, 
        uint256[] params, 
        uint256[] prices,
        address[] collateralPath,
        uint256 txType,
        string err
    );

    function initialize (
        address _priceManager,
        address _settingsManager,
        address _positionHandler, 
        address _positionKeeper,
        address _vault, 
        address _vaultUtils,
        address _triggerOrderManager
    ) public reinitializer(2) {
        require(AddressUpgradeable.isContract(_vault) 
            && AddressUpgradeable.isContract(_vaultUtils)
            && AddressUpgradeable.isContract(_triggerOrderManager), "IVLCA"); //Invalid contract address
        _initialize(
            _priceManager,
            _settingsManager,
            _positionHandler, 
            _positionKeeper
        );
        vault = IVaultV2(_vault);
        vaultUtils = IVaultUtilsV2(_vaultUtils);
        triggerOrderManager = _triggerOrderManager;
        emit FinalInitialized(
            _priceManager,
            _settingsManager,
            _positionHandler, 
            _positionKeeper,
            _vault, 
            _vaultUtils, 
            _triggerOrderManager
        );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {
        
    }

    function setSwapRouter(address _swapRouter) external onlyOwner {
        require(AddressUpgradeable.isContract(_swapRouter), "IVLCA"); //Invalid contract address
        swapRouter = ISwapRouter(_swapRouter);
        emit SetSwapRouter(_swapRouter);
    }
    
    function openNewPosition(
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address[] memory _path
    ) external payable nonReentrant {
        require(!settingsManager.isEmergencyStop(), "EMSTP"); //Emergency stopped
        bool shouldSwap = _prevalidateAndCheckSwapAndAom(_path, _getLastParams(_params));

        if (_orderType != OrderType.MARKET) {
            require(msg.value == settingsManager.triggerGasFee(), "IVLTGF"); //Invalid triggerGasFee
            payable(settingsManager.getFeeManager()).transfer(msg.value);
        }

        uint256 txType;

        //Scope to avoid stack too deep error
        {
            txType = _getTransactionTypeFromOrder(_orderType);
            _verifyParamsLength(txType, _params);
        }

        bool isFastExecute;
        uint256[] memory prices;

        {
            (isFastExecute, prices) = _getPricesAndCheckFastExecute(_path);
            vaultUtils.validatePositionData(
                _isLong, 
                _getFirstPath(_path), 
                _orderType, 
                _getFirstParams(prices), 
                _params, 
                true,
                isFastExecute
            );
        }

        (bytes32 key, Position memory position, OrderInfo memory order) = _createPosition(
            msg.sender,
            _isLong,
            _orderType,
            txType,
            _path,
            _params
        );

        _modifyPosition(
            key,
            txType,
            true, //isTakeAssetRequired = true for openNewPosition
            shouldSwap,
            isFastExecute = txType != CREATE_POSITION_MARKET ? false : isFastExecute, //Only fast execute for market type
            _path,
            prices,
            abi.encode(position, order)
        );
    }

    function _createPosition(
        address _account,
        bool _isLong,
        OrderType _orderType,
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _params
    ) internal returns (bytes32, Position memory, OrderInfo memory) {
        uint256 posId = positionKeeper.lastPositionIndex(_account);
        bytes32 key = _getPositionKey(_account, _path[0], _isLong, posId);
        require(txnDetails[key][_txType].params.length == 0, "InP");
        txnDetails[key][_txType].params = _params;

        Position memory position;
        OrderInfo memory order;

        //Scope to avoid stack too deep error
        {
            (position, order) = positionKeeper.getPositions(key);
            require(position.owner == address(0), "IVLPO/E"); //Invalid positionOwner/existed
            position.owner = msg.sender;
            position.indexToken = _path[0];
            position.posId = posId;
            position.isLong = _isLong;

            order.pendingCollateral = _params[4];
            order.pendingSize = _params[5];
            order.collateralToken = _path[1];
            order.status = OrderStatus.PENDING;
        }

        if (_orderType == OrderType.MARKET) {
            order.positionType = POSITION_MARKET;
        } else if (_orderType == OrderType.LIMIT) {
            order.positionType = POSITION_LIMIT;
            order.lmtPrice = _params[2];
        } else if (_orderType == OrderType.STOP) {
            order.positionType = POSITION_STOP_MARKET;
            order.stpPrice = _params[3];
        } else if (_orderType == OrderType.STOP_LIMIT) {
            order.positionType = POSITION_STOP_LIMIT;
            order.lmtPrice = _params[2];
            order.stpPrice = _params[3];
        } else {
            revert("IVLOT"); //Invalid order type
        }

        return (key, position, order);
    }

    function _revertExecute(
        bytes32 _key, 
        uint256 _txType,
        uint256[] memory _params, 
        uint256[] memory _prices, 
        address[] memory _path,
        string memory err
    ) internal {
        if (_isTakeAssetBackRequired(_txType)) {
            _takeAssetBack(_key, _txType);
        }

        Position memory position = positionKeeper.getPosition(_key);

        if (_txType == CREATE_POSITION_MARKET || 
            _txType == ADD_TRAILING_STOP || 
            _txType == ADD_COLLATERAL ||
            _isDelayPosition(_txType)) {
                positionHandler.modifyPosition(
                    _key,
                    REVERT_EXECUTE,
                    _path,
                    _prices,
                    abi.encode(_txType, position)
                );
        }

        _clearPrepareTransaction(_key, _txType);

        emit ExecutionReverted(
            _key,
            position.owner,
            position.isLong,
            position.posId,
            _params,
            _prices,
            _path,
            _txType, 
            err
        );
    }

    function addOrRemoveCollateral(
        bool _isLong,
        uint256 _posId,
        bool _isPlus,
        uint256[] memory _params,
        address[] memory _path
    ) external override nonReentrant {
        bool shouldSwap;

        if (_isPlus) {
            _verifyParamsLength(ADD_COLLATERAL, _params);
            shouldSwap = _prevalidateAndCheckSwapAndAom(_path, _getLastParams(_params));
        } else {
            _verifyParamsLength(REMOVE_COLLATERAL, _params);
            shouldSwap = _prevalidateAndCheckSwap(_path, 0, false);
        }

        bytes32 key;
        bool isFastExecute; 
        uint256[] memory prices;

        //Scope to avoid stack too deep error
        {
            key = _getPositionKeyV2(msg.sender, _getFirstPath(_path), _isLong, _posId);
            (isFastExecute, prices) = _getPricesAndCheckFastExecute(_path);
        }

        vaultUtils.validateAddOrRemoveCollateral(
            key,
            _getFirstParams(_params),
            _isPlus,
            _getLastPath(_path), //collateralToken
            _getFirstParams(prices), //indexPrice
            _getLastParams(prices) //collateralPrice
        );

        _modifyPosition(
            _getPositionKeyV2(msg.sender, _getFirstPath(_path), _isLong, _posId),
            _isPlus ? ADD_COLLATERAL : REMOVE_COLLATERAL,
            _isPlus ? true : false, //isTakeAssetRequired = true for addCollateral
            _isPlus ? shouldSwap : false,
            isFastExecute,
            _path,
            prices,
            abi.encode(_params)
        );
    }

    function addPosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external payable override nonReentrant {
        require(msg.value == settingsManager.triggerGasFee(), "IVLTGF");
        _verifyParamsLength(ADD_POSITION, _params);
        bool shouldSwap = _prevalidateAndCheckSwapAndAom(_path, _getLastParams(_params));
        payable(settingsManager.getFeeManager()).transfer(msg.value);
        (, uint256[] memory prices) = _getPricesAndCheckFastExecute(_path);
        _modifyPosition(
            _getPositionKeyV2(msg.sender, _getFirstPath(_path), _isLong, _posId),
            ADD_POSITION,
            true, //isTakeAssetRequired = true for addPosition
            shouldSwap,
            false, //isFastExecute disabled for addPosition
            _path,
            prices,
            abi.encode(_params)
        );
    }

    function addTrailingStop(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external payable override nonReentrant {
        _prevalidate(_indexToken);
        _verifyParamsLength(ADD_TRAILING_STOP, _params);
        require(msg.value == settingsManager.triggerGasFee(), "IVLTGF"); //Invalid triggerFasFee
        payable(settingsManager.getFeeManager()).transfer(msg.value);

        (, address[] memory path, uint256[] memory prices) = _getSingleIndexTokenPathAndPrice(_indexToken);

       //Fast execute for adding trailing stop
        _modifyPosition(
            _getPositionKeyV2(msg.sender, _indexToken, _isLong, _posId),
            ADD_TRAILING_STOP,
            false, //isTakeAssetRequired = false for addTrailingStop
            false, //shouldSwap = false for addTrailingStop
            true, //isFastExecute = true for addTrailingStop
            path,
            prices,
            abi.encode(_params)
        );
    }

    function updateTrailingStop(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _indexPrice
    ) external override nonReentrant {
        _prevalidate(_indexToken);
        require(_isExecutor(msg.sender) || msg.sender == _account, "IVLPO"); //Invalid positionOwner
        uint256[] memory prices = new uint256[](1);
        bool isFastExecute;

        if (!_isExecutor(msg.sender)) {
            uint256 indexPrice;
            (isFastExecute, indexPrice) = _getPriceAndCheckFastExecute(_indexToken);
            prices[0] = indexPrice;
        } else {
            prices[0] = _indexPrice;
        }
        
        _modifyPosition(
            _getPositionKeyV2(msg.sender, _indexToken, _isLong, _posId),
            UPDATE_TRAILING_STOP,
            false, //isTakeAssetRequired = false for updateTrailingStop
            false, //shouldSwap = false for updateTrailingStop
            _isExecutor(msg.sender) ? true : isFastExecute,
            _getSingleIndexTokenPath(_indexToken),
            prices,
            new bytes(0)
        );
    }

    function cancelPendingOrder(
        address _indexToken, 
        bool _isLong, 
        uint256 _posId
    ) external override nonReentrant {
        _prevalidate(_indexToken);
        (, uint256 indexPrice) = _getPriceAndCheckFastExecute(_indexToken);
        address[] memory path = new address[](1);
        path[0] = _indexToken;
        uint256[] memory prices = new uint256[](1);
        prices[0] = indexPrice;
        _modifyPosition(
            _getPositionKeyV2(msg.sender, _indexToken, _isLong, _posId),
            CANCEL_PENDING_ORDER,
            false, //isTakeAssetRequired = false for cancelPendingOrder
            false, //shouldSwap = false for cancelPendingOrder
            true, //isFastExecute = true for cancelPendingOrder
            path,
            prices,
            new bytes(0)
        );
    }

    /*
    @dev: Trigger position from triggerOrderManager
    */
    function triggerPosition(
        bytes32 _key,
        bool _isFastExecute,
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices
    ) external override {
        require(msg.sender == address(triggerOrderManager), "FBD"); //Forbidden
        require(positionKeeper.getPositionOwner(_key) != address(0), "Position notExist");
        _modifyPosition(
            _key,
            _txType,
            false, //isTakeAssetRequired = false for triggerPosition
            false, //shouldSwap = false for triggerPosition
            msg.sender == address(triggerOrderManager) ? true : _isFastExecute,
            _path,
            _prices,
            abi.encode(_getParams(_key, _txType))
        );
    }

    function closePosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external override nonReentrant {
        _prevalidateAndCheckSwap(_path, 0, false);
        _verifyParamsLength(CLOSE_POSITION, _params);
        (bool isFastExecute, uint256[] memory prices) = _getPricesAndCheckFastExecute(_path);
        _modifyPosition(
            _getPositionKeyV2(msg.sender, _path[0], _isLong, _posId),
            CLOSE_POSITION,
            false, //isTakeAssetRequired = false for closePosition
            false, //shouldSwap = false for closePosition
            isFastExecute,
            _path,
            prices,
            abi.encode(_params)
        );
    }

    function execute(bytes32 _key, uint256 _txType, uint256[] memory _prices) external {
        require(_isExecutor(msg.sender) || msg.sender == address(positionHandler), "FBD"); //Forbidden
        address[] memory path = getExecutePath(_key, _txType);
        require(path.length > 0 && path.length == _prices.length, "IVLAL"); //Invalid array length
        _execute(_key, _txType, path, _prices);
    }

    function revertExecution(
        bytes32 _key, 
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices, 
        string memory err
    ) external override {
        require(_isExecutor(msg.sender) || msg.sender == address(positionHandler), "FBD"); //Forbidden

        if (_txType != TRIGGER_POSITION) {
            //Invalid preapre transaction status, must pending
            require(txns[_key].status == TRANSACTION_STATUS_PENDING, "IVLPTS/NPND");
        }

        require(_path.length > 0 && _prices.length == _path.length, "IVLAL"); //Invalid array length
        txns[_key].status == TRANSACTION_STATUS_EXECUTE_REVERTED;

        _revertExecute(
            _key, 
            _txType,
            _getParams(_key, _txType), 
            _prices, 
            _path,
            err
        );
    }

    function _isTakeAssetBackRequired(uint256 _txType) internal pure returns (bool) {
        return _isOpenPosition(_txType) ||
            _txType == ADD_COLLATERAL || 
            _txType == ADD_POSITION;
    }

    function _modifyPosition(
        bytes32 _key,
        uint256 _txType,
        bool _isTakeAssetRequired,
        bool _shouldSwap,
        bool _isFastExecute,
        address[] memory _path,
        uint256[] memory _prices,
        bytes memory _data
    ) internal {
        require(!settingsManager.isEmergencyStop(), "EMS"); //Emergency stopped

        if (_txType == LIQUIDATE_POSITION) {
            positionHandler.modifyPosition(
                _key,
                LIQUIDATE_POSITION,
                _path,
                _prices,
                abi.encode(positionKeeper.getPosition(_key))
            );

            return;
        } 

        Position memory position;
        OrderInfo memory order;
        uint256[] memory params;
        uint256 amountIn;

        if (_isOpenPosition(_txType) && _isOpenPositionData(_data)) {
            (position, order) = abi.decode(_data, ((Position), (OrderInfo)));
            params = txnDetails[_key][_txType].params;
            amountIn = order.pendingCollateral;
        } else {
            params = _data.length == 0 ? new uint256[](0) : abi.decode(_data, (uint256[]));
            (position, order) = positionKeeper.getPositions(_key);
            amountIn = params.length == 0 ? 0 
                : (_isOpenPosition(_txType) && params.length > 5 ? params[4] : _getFirstParams(params));
        }

        //Transfer collateral to vault if required
        if (_isTakeAssetRequired) {
            require(amountIn > 0 && _path.length > 1, "IVLCA/P"); //Invalid collateral amount/path
            _transferAssetToVault(
                position.owner,
                _path[1],
                amountIn,
                _key,
                _txType
            );
        }

        if (_shouldSwap && _isFastExecute) {
            bool isSwapSuccess;
            address collateralToken;
            
            {
                (isSwapSuccess, collateralToken, amountIn) = _processSwap(
                    _key,
                    position.owner,
                    _txType,
                    amountIn,
                    _path,
                    _prices,
                    params.length > 0 ? _getLastParams(params) : 0
                );

                if (!isSwapSuccess) {
                    _revertExecute(
                        _key,
                        _txType,
                        params,
                        _prices,
                        _path,
                        "SWF" //Swap failed
                    );
                    
                    return;
                }
            }

            if (_isOpenPosition(_txType) && _isOpenPositionData(_data)) {
                order.collateralToken = collateralToken;
                uint256 leverage = order.pendingSize * BASIS_POINTS_DIVISOR / order.pendingCollateral;
                order.pendingCollateral = amountIn;
                order.pendingSize = amountIn * leverage / BASIS_POINTS_DIVISOR;
            }
        }

        if (!_isFastExecute) {
            _createPrepareTransaction(
                position.owner,
                position.isLong,
                position.posId,
                _txType,
                params,
                _path,
                _isFastExecute
            );
        }

        if (!_isFastExecute && !_isOpenPosition(_txType)) {
            return;
        }

        if (_txType == ADD_POSITION || 
            _txType == ADD_COLLATERAL ||
            _txType == REMOVE_COLLATERAL ||
            _txType == ADD_TRAILING_STOP ||
            _txType == UPDATE_TRAILING_STOP || 
            _txType == CLOSE_POSITION) {
            require(position.owner != address(0) && position.size > 0, "IVLPS/NI"); //Invalid position, not initialized
        }

        bytes memory data;

        if (_isOpenPosition(_txType) && (_isOpenPositionData(_data) || _txType == CREATE_POSITION_MARKET)) {
            data = abi.encode(_isFastExecute, _isOpenPositionData(_data), params, position, order);
        } else if (_txType == ADD_COLLATERAL || _txType == REMOVE_COLLATERAL) {
            data = abi.encode(amountIn, position);
        } else if (_txType == ADD_TRAILING_STOP) {
            data = abi.encode(position.owner, position.isLong, params, order);
        } else if (_txType == UPDATE_TRAILING_STOP) {
            data = abi.encode(position.owner, position.isLong, order);
        }  else if (_txType == CANCEL_PENDING_ORDER) {
            data = abi.encode(position.owner, order);
        } else if (_txType == CLOSE_POSITION) {
            data = abi.encode(_getFirstParams(params), position);
        } else if (_txType == ADD_POSITION) {
            uint256 leverage = positionKeeper.leverages(_key);
            require(amountIn > 0 && leverage > 0, "IVLCA/L"); //Invalid collateralAmount/Leverage
            data = abi.encode(
                amountIn, 
                amountIn * leverage / BASIS_POINTS_DIVISOR, 
                position
            );
        } else if (_txType == TRIGGER_POSITION || _isDelayPosition(_txType)) {
            data = abi.encode(position, order);
        } else {
            revert("IVLETXT"); //Invalid execute txType
        }

        positionHandler.modifyPosition(
            _key,
            _isDelayPosition(_txType) && !_isOpenPositionData(_data) ? TRIGGER_POSITION : _txType,
            _path,
            _prices,
            data
        );

        if (_isFastExecute) {
            _clearPrepareTransaction(_key, _txType);
        }
    }

    function clearPrepareTransaction(bytes32 _key, uint256 _txType) external {
        require(msg.sender == address(positionHandler), "FBD");
        _clearPrepareTransaction(_key, _txType);
    }

    function _clearPrepareTransaction(bytes32 _key, uint256 _txType) internal {
        if (txns[_key].txType == _txType) {
            delete txns[_key];
            delete txnDetails[_key][_txType];
        }
    }

    function _createPrepareTransaction(
        address _account,
        bool _isLong,
        uint256 _posId,
        uint256 _txType,
        uint256[] memory _params,
        address[] memory _path,
        bool isFastExecute
    ) internal {
        bytes32 key = _getPositionKeyAndCheck(_account, _getFirstPath(_path), _isLong, _posId, false);
        PrepareTransaction storage transaction = txns[key];
        require(transaction.status != TRANSACTION_STATUS_PENDING, "IVLPTS/IP"); //Invalid prepare transaction status, in processing
        transaction.txType = _txType;
        transaction.startTime = block.timestamp;
        transaction.status = TRANSACTION_STATUS_PENDING;
        txnDetails[key][_txType].path = _path;
        txnDetails[key][_txType].params = _params;
        (, uint256 amountOutMin) = _extractDeadlineAndAmountOutMin(_txType, _params, true);
        
        if (_isSwapRequired(_path) && _isRequiredAmountOutMin(_txType)) {
            require(amountOutMin > 0, "IVLAOM");
        }

        emit CreatePrepareTransaction(
            _account,
            _isLong,
            _posId,
            _txType,
            _params,
            _path,
            key,
            isFastExecute
        );
    }

    function _extractDeadlineAndAmountOutMin(uint256 _txType, uint256[] memory _params, bool _isRaise) internal view returns(uint256, uint256) {
        uint256 deadline;
        uint256 amountOutMin;

        if (_isOpenPosition(_txType)) {
            deadline = _txType == CREATE_POSITION_MARKET ? _params[6] : 0;

            if (_txType == CREATE_POSITION_MARKET && _isRaise) {
                require(deadline > 0 && deadline > block.timestamp, "IVLDL"); //Invalid deadline
            }

            amountOutMin = _params[7];
        } else if (_txType == REMOVE_COLLATERAL) {
            deadline = _params[1];

            if (_isRaise) {
                require(deadline > 0 && deadline > block.timestamp, "IVLDL"); //Invalid deadline
            }
        } else if (_txType == ADD_COLLATERAL) {
            deadline = _params[1];

            if (_isRaise) {
                require(deadline > 0 && deadline > block.timestamp, "IVLDL"); //Invalid deadline
            }

            amountOutMin = _params[2];
        } else if (_txType == ADD_POSITION) {
            deadline = _params[2];

            if (_isRaise) {
                require(deadline > 0 && deadline > block.timestamp, "IVLDL"); //Invalid deadline
            }

            amountOutMin = _params[3];
        }

        return (deadline, amountOutMin);
    }

    function _verifyParamsLength(uint256 _type, uint256[] memory _params) internal pure {
        bool isValid;

        if (_type == CREATE_POSITION_MARKET
            || _type == CREATE_POSITION_LIMIT
            || _type == CREATE_POSITION_STOP_MARKET
            || _type == CREATE_POSITION_STOP_LIMIT) {
            isValid = _params.length == 8;
        } else if (_type == ADD_COLLATERAL) {
            isValid = _params.length == 3;
        } else if (_type == REMOVE_COLLATERAL) {
            isValid = _params.length == 2;
        } else if (_type == ADD_POSITION) {
            isValid = _params.length == 4;
        } else if (_type == CLOSE_POSITION) {
            isValid = _params.length == 2;
        } else if (_type == ADD_TRAILING_STOP) {
            isValid = _params.length == 5;
        }

        require(isValid, "IVLPL"); //Invalid params length
    }

    function _execute(
        bytes32 _key, 
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices
    ) internal {
        require(_path.length > 0 && _path.length == _prices.length, "IVLAL"); //Invalid array length
        require(positionKeeper.getPositionOwner(_key) != address(0), "Position notExist"); //Not exist
        
        if (_txType == LIQUIDATE_POSITION) {
            _modifyPosition(
                _key,
                LIQUIDATE_POSITION,
                false, //isTakeAssetRequired = false for executing,
                false, //shouldSwap = false for executing
                true, //isFastExecute = true for executing
                _path,
                _prices,
                new bytes(0)
            );
            txns[_key].status = TRANSACTION_STATUS_EXECUTED;
            return;
        }

        //Check deadline
        (uint256 deadline, ) = _extractDeadlineAndAmountOutMin(_txType, _getParams(_key, _txType), false);

        if (deadline > 0 && deadline <= block.timestamp) {
            _revertExecute(
                _key,
                _txType,
                _getParams(_key, _txType),
                _prices,
                _path,
                "DLR" //Deadline reached
            );
            return;
        }
        
        PrepareTransaction storage txn = txns[_key];

        if (!_isTriggerType(_txType)) {
            require(_txType == txn.txType, "IVLPT/ICRT"); //Invalid prepare transaction, not correct txType
            require(txn.status == TRANSACTION_STATUS_PENDING, "IVLPTS/NP"); //Invalid prepare transaction status, not pending
        }

        txn.status = TRANSACTION_STATUS_EXECUTED;
        _modifyPosition(
            _key,
            _txType,
            false, //isTakeAssetRequired = false for executing
            false, //shouldSwap = false for executing
            true, //isFastExecute = true for executing
            _path,
            _prices,
            abi.encode(_getParams(_key, _txType))
        );
    }

    function _isTriggerType(uint256 _txType) internal pure returns (bool) {
        return _isDelayPosition(_txType) || _txType == ADD_TRAILING_STOP || _txType == TRIGGER_POSITION;
    }

    /*
    @dev: Pre-validate check path and amountOutMin (if swap required)
    */
    function _prevalidateAndCheckSwapAndAom(
        address[] memory _path, 
        uint256 _amountOutMin
    ) internal view returns (bool) {
        return _prevalidateAndCheckSwap(_path, _amountOutMin, true);
    }

    function _prevalidateAndCheckSwap(
        address[] memory _path, 
        uint256 _amountOutMin,
        bool _isVerifyAmountOutMin
    ) internal view returns (bool) {
        require(_path.length >= 2, "IVLPTL"); //Invalid path length
        _prevalidate(_getFirstPath(_path));
        bool shouldSwap = settingsManager.validateCollateralPathAndCheckSwap(_path);

        if (shouldSwap && _path.length > 2 && _isVerifyAmountOutMin) {
            //Invalid amountOutMin/swapRouter
            require(_amountOutMin > 0 && address(swapRouter) != address(0), "IVLAOM/SR"); 
        }

        return shouldSwap;
    }

    function _getFirstPath(address[] memory _path) internal pure returns (address) {
        return _path[0];
    }

    function _getLastPath(address[] memory _path) internal pure returns (address) {
        return _path[_path.length - 1];
    }

    function _getFirstParams(uint256[] memory _params) internal pure returns (uint256) {
        return _params[0];
    }

    function _getLastParams(uint256[] memory _params) internal pure returns (uint256) {
        return _params[_params.length - 1];
    }

    function _transferAssetToVault(
        address _account, 
        address _token,
        uint256 _amountIn,
        bytes32 _key,
        uint256 _txType
    ) internal {
        require(_amountIn > 0, "IVLAM"); //Invalid amount
        vault.takeAssetIn(_account, _amountIn, _token, _key, _txType);
    }

    function _isSwapRequired(address[] memory _path) internal pure returns (bool) {
        return _path.length > 2;
    }

    function _processSwap(
        bytes32 _key,
        address _account,
        uint256 _txType,
        uint256 _pendingCollateral,
        address[] memory _path,
        uint256[] memory _prices,
        uint256 _amountOutMin 
    ) internal returns (bool, address, uint256) {
        uint256 tokenOutPrice = _prices.length == 0 ? 0 : _getLastParams(_prices);
        require(tokenOutPrice > 0, "IVLTP"); //Invalid token price

        try swapRouter.swapFromInternal(
            _account,
            _key,
            _txType,
            _pendingCollateral,
            _amountOutMin,
            _path
        ) returns (address tokenOut, uint256 swapAmountOut) {
            uint256 swapAmountOutInUSD = priceManager.fromTokenToUSD(tokenOut, swapAmountOut, tokenOutPrice);
            require(swapAmountOutInUSD > 0, "IVLSAP"); //Invalid swap amount price
            return (true, tokenOut, swapAmountOutInUSD);
        } catch {
            return (false, _path[1], _pendingCollateral);
        }
    }

    function _takeAssetBack(bytes32 _key, uint256 _txType) internal {
        vault.takeAssetBack(
            positionKeeper.getPositionOwner(_key), 
            _key,
            _txType
        );
    }
    
    //
    function getTransaction(bytes32 _key) external view returns (PrepareTransaction memory) {
        return txns[_key];
    }

    function getTxDetail(bytes32 _key, uint256 _txType) external view returns (TxDetail memory) {
        return txnDetails[_key][_txType];
    }

    function getPath(bytes32 _key, uint256 _txType) external view returns (address[] memory) {
        return _getPath(_key, _txType);
    }

    function getParams(bytes32 _key, uint256 _txType) external view returns (uint256[] memory) {
        return _getParams(_key, _txType);
    }
    
    function _getPath(bytes32 _key, uint256 _txType) internal view returns (address[] memory) {
        return txnDetails[_key][_txType].path;
    }

    function getExecutePath(bytes32 _key, uint256 _txType) public view returns (address[] memory) {
        if (_isNotRequirePreparePath(_txType)) {
            return positionKeeper.getPositionFinalPath(_key);
        } else {
            return _getPath(_key, _txType);
        }
    }

    function _isNotRequirePreparePath(uint256 _txType) internal pure returns (bool) {
        return _txType == TRIGGER_POSITION 
            || _txType == REMOVE_COLLATERAL 
            || _txType == LIQUIDATE_POSITION;
    }

    function _getParams(bytes32 _key, uint256 _txType) internal view returns (uint256[] memory) {
        return txnDetails[_key][_txType].params; 
    }

    function _getTransactionTypeFromOrder(OrderType _orderType) internal pure returns (uint256) {
        if (_orderType == OrderType.MARKET) {
            return CREATE_POSITION_MARKET;
        } else if (_orderType == OrderType.LIMIT) {
            return CREATE_POSITION_LIMIT;
        } else if (_orderType == OrderType.STOP) {
            return CREATE_POSITION_STOP_MARKET;
        } else if (_orderType == OrderType.STOP_LIMIT) {
            return CREATE_POSITION_STOP_LIMIT;
        } else {
            revert("IVLOT"); //Invalid order type
        }
    }

    function _isRequiredAmountOutMin(uint256 _txType) internal pure returns (bool) {
        return _isOpenPosition(_txType) || 
            _txType == ADD_COLLATERAL ||
            _txType == ADD_POSITION;
    }

    function _getSingleIndexTokenPath(address _indexToken) internal pure returns (address[] memory) {
        address[] memory path = new address[](1);
        path[0] = _indexToken;
        return path;
    }

    function _getSingleIndexTokenPathAndPrice(address _indexToken) internal view returns (bool, address[] memory, uint256[] memory) {
        address[] memory path = new address[](1);
        uint256[] memory prices = new uint256[](1);
        path[0] = _indexToken;
        (bool isFastExecute, uint256 price) = _getPriceAndCheckFastExecute(_indexToken);
        prices[0] = price;
        return (isFastExecute, path, prices);
    }

    function _getPositionKeyV2(
        address _account, 
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) internal view returns (bytes32) {
        return _getPositionKeyAndCheck(
            _account,
            _indexToken,
            _isLong,
            _posId,
            true
        );
    }

    function _getPositionKeyAndCheck(
        address _account, 
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) internal view returns (bytes32) {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);

        if (_raise) {
            require(_account == positionKeeper.getPositionOwner(key), "FBD: Invalid pOwner");
        }

        return key;
    }

    /*
    @dev: Min encode data length for position 13 struct and order 9 struct are 22 * 32 = 704
    */
    function _isOpenPositionData(bytes memory _data) internal pure returns (bool) {
        return _data.length == 704;     
    }
}