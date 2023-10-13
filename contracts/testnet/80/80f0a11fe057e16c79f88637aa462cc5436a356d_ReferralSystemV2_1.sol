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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract BaseConstants {
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals

    uint256 public constant DEFAULT_ROLP_PRICE = 100000; //1 USDC

    uint256 public constant ROLP_DECIMALS = 18;
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

interface IMintable {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function setMinter(address _minter) external;

    function revokeMinter(address _minter) external;

    function isMinter(address _account) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IReferralSystemV2 {
    //Referrer, discount, rebate
    function getDiscountable(address _account) external returns(address, uint256, uint256, uint256);

    function getDiscountableInternal(address _account, uint256 _fee) external returns(address, uint256, uint256, uint256);

    function increaseCodeStat(address _account, uint256 _discountshareAmount, uint256 _rebateAmount, uint256 _esRebateAmount) external;
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

interface IVaultV2Simplify {
    function takeAssetOut(
        bytes32 _key,
        address _account, 
        uint256 _fee, 
        uint256 _usdOut, 
        address _token, 
        uint256 _tokenPrice
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../../constants/BaseConstants.sol";
import "../../tokens/interfaces/IMintable.sol";
import "../../core/interfaces/IPriceManager.sol";

import "./interfaces/IReferralSystemV2.sol";
import "./interfaces/ISettingsManagerV2.sol";
import "./interfaces/IVaultV2Simplify.sol";

contract ReferralSystemV2_1 is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, IReferralSystemV2, BaseConstants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    //Standard tier
    struct StandardTier {
        uint256 rebatePercentage;
        uint256 discountSharePercentage;
        bool isActivate;
    }

    //Premium tier
    struct PremiumTier {
        uint256 rebatePercentage;
        uint256 esRebatePercentage;
        uint256 discountSharePercentage;
        bool isActivate;
    }

    struct ReferralCodeStat {
        uint256 totalRebate;
        uint256 totalDiscountshare;
        uint256 totalEsRebate;
        uint256 totalEsROSXRebate;
    }

    struct ConvertHistory {
        uint256 amount;
        uint256 timestamp;
    }

    EnumerableSetUpgradeable.UintSet private tiersType;
    ISettingsManagerV2 public settingsManager;
    IPriceManager public priceManager;
    IVaultV2Simplify public vault;
    address public rUSD;
    address public ROSX;
    address public esROSX;

    mapping(address => mapping(uint256 => uint256)) public refTiers;
    mapping(uint256 => StandardTier) public standardTiers;
    mapping(uint256 => PremiumTier) public premiumTiers;

    mapping(bytes32 => address) public codeOwners;
    mapping(address => bytes32) public traderReferralCode;
    mapping(bytes32 => ReferralCodeStat) public codeStats;

    mapping(address => bool) public isHandler;
    mapping(bytes32 => bool) public blacklistCodes;
    mapping(address => bool) public blacklistOwners;

    uint256 public maxCodePerOwner;
    bool public isAllowOverrideCode;
    uint256 public nonStableMaxPriceUpdatedDelay;
    mapping(address => TIER_TYPE) public tierOwners;
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) private codeUsage;
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private codeLink;

    event FinalInitialize(
        address rUSD,
        address ROSX,
        address esROSX, 
        address settingsManager, 
        address priceManager, 
        address vault
    );
    event SetHandler(address handler, bool isActive);
    event SetTraderReferralCode(address account, bytes32 code);
    event SetStandardTier(uint256 tierId, uint256 rebatePercentage, uint256 discountSharePercentage);
    event SetPremiumTier(uint256 tierId, uint256 rebatePercentages, uint256 esRebatePercentages, uint256 discountSharePercentage);
    event SetReferrerTier(address referrer, TIER_TYPE tierType, uint256 tierId);
    event RemoveReferrerTier(address referrer);
    event RegisterCode(address account, bytes32 code);
    event ChangeCodeOwner(address account, address newAccount, bytes32 code);

    event DeactivateTier(TIER_TYPE tierType, uint256 tierId);
    event SetCodeBlacklist(bytes32[] codes, bool[] isBlacklist);
    event SetOwnerBlacklist(address[] owners, bool[] isBlacklist);
    event SetMaxCodePerOwner(uint256 maxCodePerOwner);
    event SetAllowOverrideCode(bool isAllowOverrideCode);
    event SetNonStableMaxPriceUpdatedDelay(uint256 _nonStableMaxPriceUpdatedDelay);
    event IncreaseCodeStat(bytes32 code, uint256 discountshareAmount, uint256 rebateAmount, uint256 esROSXRebateAmount);
    event FixCodeStat(bytes32 code, uint256 newTotalDiscountshare, uint256 newTotalRebate, uint256 newTotalEsROSXRebate);
    event ConvertRUSD(address recipient, address tokenOut, uint256 rUSD, uint256 amountOut);
    event ReferralDelievered(address _account, bytes32 code, address referrer, uint256 amount);
    event EscrowRebateDelivered(
        address referrer,
        uint256 esRebateAmount,
        uint256 price,
        uint256 esROSXAmount,
        bool isSuccess, 
        string err)
    ;

    enum TIER_TYPE {
        NONE,
        STANDARD,
        PREMIUM
    }

    modifier onlyHandler() {
        require(isHandler[msg.sender], "Forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(isHandler[msg.sender] || msg.sender == owner(), "Forbidden");
        _;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        address _rUSD,
        address _ROSX,
        address _esROSX, 
        address _settingsManager, 
        address _priceManager, 
        address _vault
    ) public reinitializer(1) {
        __Ownable_init();
        _initTiersType();

        //Should check all tiers type must have been initialized
        require(tiersType.length() > 0 
            && tiersType.length() == uint256(type(TIER_TYPE).max) + 1, "Invalid tiers type");
        initializeTiers();
        finalInitialize(_rUSD, _ROSX, _esROSX, _settingsManager, _priceManager, _vault);
    }

    function finalInitialize(address _rUSD, address _ROSX, address _esROSX, address _settingsManager, address _priceManager, address _vault) internal {
        _validateInternalContracts(_rUSD, _settingsManager, _priceManager, _vault);
        rUSD = _rUSD;
        ROSX = _ROSX;
        esROSX = _esROSX;
        settingsManager = ISettingsManagerV2(_settingsManager);
        priceManager = IPriceManager(_priceManager);
        vault = IVaultV2Simplify(_vault);
        emit FinalInitialize(_rUSD, ROSX, esROSX, _settingsManager, _priceManager, _vault);
    }

    /*
    @dev: Declarer all tiers type for initialization or upgrade. 
    * If upgrade, the position of 2 value must not change:
    *   [0] must be TIER_TYPE.NONE
    *   [1] must be TIER_TYPE.STANDARD
    *   [2] must be TIER_TYPE.PREMIUM
    */
    function _initTiersType() internal {
        TIER_TYPE[] memory initTiers = new TIER_TYPE[](3);
        initTiers[0] = TIER_TYPE.NONE;
        initTiers[1] = TIER_TYPE.STANDARD;
        initTiers[2] = TIER_TYPE.PREMIUM;

        for (uint256 i = 0; i < initTiers.length; i++) {
            tiersType.add(uint256(initTiers[i]));
        }
    }

    function setHandler(address _handler, bool _isActive) external onlyOwner {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setStandardTier(uint256 _tierId, uint256 _rebatePercentage, uint256 _discountSharePercentage) external onlyOwner {
        _valdiateTierAttr(TIER_TYPE.STANDARD, _tierId, _rebatePercentage, _discountSharePercentage);
        StandardTier memory tier = standardTiers[_tierId];
        tier.rebatePercentage = _rebatePercentage;
        tier.discountSharePercentage = _discountSharePercentage;
        tier.isActivate = true;
        standardTiers[_tierId] = tier;
        emit SetStandardTier(_tierId, _rebatePercentage, _discountSharePercentage);
    }

    function setPremiumTier(
        uint256 _tierId, 
        uint256 _rebatePercentage, 
        uint256 _esRebatePercentage, 
        uint256 _discountSharePercentage
    ) external onlyOwner {
        _valdiateTierAttr(TIER_TYPE.PREMIUM, _tierId, _rebatePercentage + _esRebatePercentage, _discountSharePercentage);
        PremiumTier memory tier = premiumTiers[_tierId];
        tier.rebatePercentage = _rebatePercentage;
        tier.esRebatePercentage = _esRebatePercentage;
        tier.discountSharePercentage = _discountSharePercentage;
        tier.isActivate = true;
        premiumTiers[_tierId] = tier;
        emit SetPremiumTier(_tierId, _rebatePercentage, _esRebatePercentage, _discountSharePercentage);
    }

    function deactivateTier(TIER_TYPE _tierType, uint256 _tierId) external onlyAdmin {
        _validateTier(_tierType, _tierId);
        
        if (_tierType == TIER_TYPE.PREMIUM) {
            premiumTiers[_tierId].isActivate = false;
        } else if (_tierType == TIER_TYPE.STANDARD) {
            standardTiers[_tierId].isActivate = false;
        } else {
            //Reserve
            revert("Invalid tierType");
        }

        emit DeactivateTier(_tierType, _tierId);
    }

    function setCodeBlacklist(bytes32[] memory _codes, bool[] memory _isBlacklist) external onlyAdmin {
        require(_codes.length + _isBlacklist.length > 0, "Zero length");
        require(_codes.length == _isBlacklist.length || (_codes.length > 0 && _isBlacklist.length == 1), "Invalid length");

        for (uint256 i = 0; i < _codes.length; i++) {
            blacklistCodes[_codes[i]] = _isBlacklist.length == 1 ? _isBlacklist[0] : _isBlacklist[i];
        }

        emit SetCodeBlacklist(_codes, _isBlacklist);
    }

    function setOwnerBlacklist(address[] memory _owners, bool[] memory _isBlacklist) external onlyAdmin {
        require(_owners.length + _isBlacklist.length > 0, "Zero length");
        require(_owners.length == _isBlacklist.length || (_owners.length > 0 && _isBlacklist.length == 1), "Invalid length");

        for (uint256 i = 0; i < _owners.length; i++) {
            blacklistOwners[_owners[i]] = _isBlacklist.length == 1 ? _isBlacklist[0] : _isBlacklist[i];
        }

        emit SetOwnerBlacklist(_owners, _isBlacklist);
    }

    function setMaxCodePerOwner(uint256 _maxCodePerOwner) external onlyOwner {
        require(_maxCodePerOwner > 0, "Invalid maxCodePerOwner");
        maxCodePerOwner = _maxCodePerOwner;
        emit SetMaxCodePerOwner(_maxCodePerOwner);
    }

    function setAllowOverrideCode(bool _isAllowOverrideCode) external onlyOwner {
        isAllowOverrideCode = _isAllowOverrideCode;
        emit SetAllowOverrideCode(_isAllowOverrideCode);
    }

    function setNonStableMaxPriceUpdatedDelay(uint256 _nonStableMaxPriceUpdatedDelay) external onlyOwner {
        require(_nonStableMaxPriceUpdatedDelay <= settingsManager.maxPriceUpdatedDelay(), "Should smaller than settingsManager value");
        nonStableMaxPriceUpdatedDelay = _nonStableMaxPriceUpdatedDelay;
        emit SetNonStableMaxPriceUpdatedDelay(_nonStableMaxPriceUpdatedDelay);
    }

    function _valdiateTierAttr(
        TIER_TYPE _tierType, 
        uint256 _tierId, 
        uint256 _rebatePercentage, 
        uint256 _discountSharePercentage
    ) internal pure {
        _validateTier(_tierType, _tierId);
        require(_rebatePercentage < BASIS_POINTS_DIVISOR, "Invalid rebatePercentage");
        require(_discountSharePercentage < BASIS_POINTS_DIVISOR, "Invalid discountSharePercentage");
    }

    function _validateTier(TIER_TYPE _tierType, uint256 _tierId) internal pure {
        require(_tierId > 0, "Invalid tierId");
        require(uint256(_tierType) > uint256(TIER_TYPE.NONE) && uint256(_tierType) < uint256(type(TIER_TYPE).max) + 1, "Invalid tierType");
    }

    /*
    @dev: Set referrer tier, revert if exist any other tiers.
    */
    function setReferrerTier(address _referrer, TIER_TYPE _tierType, uint256 _tierId) external onlyAdmin {
        _validateTier(_tierType, _tierId);

        for (uint256 tier = 0 ; tier < uint256(type(TIER_TYPE).max); tier++) {
            if (uint256(_tierType) != tier) {
                require(refTiers[_referrer][tier] == 0, "Existed, remove first");
            }
        }

        _setReferrerTier(_referrer, _tierType, _tierId);
    }

    /*
    @dev: Force set referrer tier, remove all other tiers if existed.
    */
    function forceSetReferrerTier(address _referrer, TIER_TYPE _tierType, uint256 _tierId) external onlyAdmin {
        _validateTier(_tierType, _tierId);
        _removeReferrerTier(_referrer);
        _setReferrerTier(_referrer, _tierType, _tierId);
    }

    function _setReferrerTier(address _referrer, TIER_TYPE _tierType, uint256 _tierId) internal {
        refTiers[_referrer][uint256(_tierType)] = _tierId;
        tierOwners[_referrer] = _tierType;
        emit SetReferrerTier(_referrer, _tierType, _tierId);
    }

    function removeReferrerTier(address _referrer) external onlyAdmin {
        _removeReferrerTier(_referrer);
    }

    function _removeReferrerTier(address _referrer) internal {
        for (uint256 tier = 0 ; tier < uint256(type(TIER_TYPE).max) + 1; tier++) {
            delete refTiers[_referrer][tier];
        }

        emit RemoveReferrerTier(_referrer);
    }

    function setTraderReferralCodeByHandler(address _account, bytes32 refCode) external onlyHandler {
        _setTraderReferralCode(_account, refCode, true);
    }

    function setTraderReferralCode(bytes32 refCode) external {
        _setTraderReferralCode(msg.sender, refCode, isAllowOverrideCode);
    }

    function registerCode(bytes32 refCode) external nonReentrant {
        require(refCode != bytes32(0), "Invalid refCode");
        require(codeOwners[refCode] == address(0), "Code registered");
        
        if (maxCodePerOwner > 0) {
            require(codeUsage[msg.sender].length() < maxCodePerOwner, "Max code number reached");
        }

        codeOwners[refCode] = msg.sender;
        codeUsage[msg.sender].add(refCode);
        emit RegisterCode(msg.sender, refCode);
    }

    function changeCodeOwnerByHandler(bytes32 _refCode, address _newOwner) external onlyHandler {
        _changeCodeOwner(_refCode, codeOwners[_refCode], _newOwner);
    }

    function changeCodeOwner(bytes32 _refCode, address _newOwner) external nonReentrant {
        require(msg.sender == codeOwners[_refCode], "Forbidden");
        _changeCodeOwner(_refCode, msg.sender, _newOwner);
    }

    function _changeCodeOwner(bytes32 _refCode, address _prevOwner, address _newOwner) internal {
        require(_refCode != bytes32(0), "Invalid refCode");
        require(_prevOwner != _newOwner, "Prev and current owner are same");

        if (maxCodePerOwner > 0) {
            require(codeUsage[_newOwner].length() < maxCodePerOwner - 1, "Max code number reached");
        }

        codeOwners[_refCode] = _newOwner;
        codeUsage[_prevOwner].remove(_refCode);
        codeUsage[_newOwner].add(_refCode);
        emit ChangeCodeOwner(msg.sender, _newOwner, _refCode);
    }

    function getTraderReferralInfo(address _account) external view returns (bytes32, address) {
        bytes32 code = traderReferralCode[_account];
        address referrer;

        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }

        return (code, referrer);
    }

    function _setTraderReferralCode(address _account, bytes32 _refCode, bool _isAllowOverrideCode) private {
        bytes32 prevCode = traderReferralCode[_account];
        require(prevCode != _refCode, "Prev and current refCode are same");

        if (!_isAllowOverrideCode && prevCode != bytes32(0)) {
            revert("Can not change refCode");
        }

        address codeOwner = codeOwners[_refCode];
        require(codeOwner != address(0) && !blacklistOwners[codeOwner] 
            && !blacklistCodes[_refCode], "RefCode not existed or deactivated");
        traderReferralCode[_account] = _refCode;
        codeLink[_refCode].add(_account);
        emit SetTraderReferralCode(_account, _refCode);
    }

    function getDiscountable(address _account) external view override returns(address, uint256, uint256, uint256) {
        address codeOwner;
        uint256 discountPercentage;
        uint256 rebatePercentage;
        uint256 esRebatePercentage;
        (
             , //Not need refCode
            codeOwner, 
            , //Not need tierType 
            , //Not need tierId
            discountPercentage, 
            rebatePercentage, 
            esRebatePercentage
        ) = _getDiscountable(_account);
        return (codeOwner, discountPercentage, rebatePercentage, esRebatePercentage);
    }

    function getDiscountableInternal(address _account, uint256 _fee) external returns(address, uint256, uint256, uint256) {
        return _getDiscountableInternal(_account, _fee);
    }

    function _getDiscountable(address _account) internal view returns(
        bytes32, //refCode
        address, //referrer
        TIER_TYPE, //tierType
        uint256, //tierId
        uint256, //discountPercentage
        uint256, //rebatePercentage
        uint256 //esRebatePercentage
    ) {
        bytes32 refCode = traderReferralCode[_account];

        if (traderReferralCode[_account] == bytes32(0) || blacklistCodes[refCode]) {
            return (bytes32(0), address(0), TIER_TYPE.NONE, 0, 0, 0, 0);
        }

        address referrer = codeOwners[refCode];

        if (referrer == address(0) || blacklistOwners[referrer]) {
            return (bytes32(0), address(0), TIER_TYPE.NONE, 0, 0, 0, 0);
        }

        TIER_TYPE tierType;
        uint256 tierId;
        
        {
            (tierType, tierId) = _getTier(referrer);
        }

        if (tierId == 0 
                || tierType == TIER_TYPE.NONE
                || (tierType == TIER_TYPE.PREMIUM && !premiumTiers[tierId].isActivate) 
                || (tierType == TIER_TYPE.STANDARD && !standardTiers[tierId].isActivate)) {
            return (bytes32(0), address(0), TIER_TYPE.NONE, 0, 0, 0, 0);
        }

        uint256 discountPercentage;

        {
            discountPercentage = _getDiscountPercentage(tierType, tierId);
        }

        return tierType == TIER_TYPE.PREMIUM 
            ? (refCode, referrer, tierType, tierId, discountPercentage, premiumTiers[tierId].rebatePercentage, premiumTiers[tierId].esRebatePercentage)
            : (refCode, referrer, tierType, tierId, discountPercentage, standardTiers[tierId].rebatePercentage, 0); 
    }

    function _getDiscountableInternal(
        address _account,
        uint256 _fee
    ) internal returns(address, uint256, uint256, uint256) {
        require(msg.sender == address(vault), "Forbidden");
        bytes32 refCode;
        address referrer;
        TIER_TYPE tierType;
        uint256 tierId;
        uint256 discountPercentage;
        uint256 rebatePercentage;
        uint256 esRebatePercentage;

        {
            (
                refCode,
                referrer,
                tierType,
                tierId,
                discountPercentage,
                rebatePercentage,
                esRebatePercentage
            ) = _getDiscountable(_account);
        }

        if (refCode == bytes32(0)) {
            return (referrer, discountPercentage, rebatePercentage, esRebatePercentage); 
        }

        _collectRebateAndIncreaseCodeStat(
            _account,
            refCode,
            referrer,
            _fee,
            discountPercentage,
            tierType,
            tierId
        );
        return (referrer, discountPercentage, rebatePercentage, esRebatePercentage);
    }

    function _collectRebateAndIncreaseCodeStat(
        address _account,
        bytes32 _refCode,
        address _referrer,
        uint256 _fee,
        uint256 _discountFeePercentage,
        TIER_TYPE _tierType,
        uint256 _tierId
    ) internal {
        uint256 feeAfterDiscount;
        uint256 discountFee;
        
        {
            discountFee = _fee * _discountFeePercentage / BASIS_POINTS_DIVISOR;
            feeAfterDiscount = discountFee >= _fee ? 0 : _fee - discountFee;
        }

        uint256 rebateAmount;
        uint256 mintEsROSXAmount;

        {
            (rebateAmount, mintEsROSXAmount) = _collectRebate(
                _account,
                _refCode,
                _referrer,
                feeAfterDiscount,
                _tierType,
                _tierId
            );
        }

        _increaseCodeStat(
            _refCode,
            discountFee,
            rebateAmount,
            mintEsROSXAmount
        );
    }

    function _collectRebate(
        address _account,
        bytes32 _code,
        address _referrer,
        uint256 _feeAfterDiscount, 
        TIER_TYPE _tierType,
        uint256 _tier
    ) internal returns (uint256, uint256) {
        require(address(rUSD) != address(0), "Invalid init rUSD");
        require(address(esROSX) != address(0), "Invalid init esROSX");
        address recipient = _referrer == address(0) ? settingsManager.getFeeManager() : _referrer;
        require(recipient != address(0), "Invalid recipient");
        uint256 rebatePercentage = _getRebatePercentage(_tierType, _tier);
        uint256 rebateAmount = _feeAfterDiscount == 0 ? 0 : _feeAfterDiscount * rebatePercentage / BASIS_POINTS_DIVISOR;

        if (rebateAmount > 0) {
            IMintable(rUSD).mint(recipient, rebateAmount);
            emit ReferralDelievered(_account, _code, recipient, rebateAmount);
        }

        uint256 mintEsROSXAmount;

        if (_tierType == TIER_TYPE.PREMIUM) {
            uint256 esRebateAmount = _feeAfterDiscount == 0 ? 0 : _feeAfterDiscount * premiumTiers[_tier].esRebatePercentage / BASIS_POINTS_DIVISOR;

            if (esRebateAmount > 0) {
                uint256 rosxPrice = priceManager.getLastPrice(ROSX);
                mintEsROSXAmount = priceManager.fromUSDToToken(ROSX, esRebateAmount, rosxPrice);

                if (mintEsROSXAmount > 0) {
                    try IMintable(esROSX).mint(recipient, mintEsROSXAmount) {
                        emit EscrowRebateDelivered(recipient, esRebateAmount, rosxPrice, mintEsROSXAmount, true, string(new bytes(0)));
                    } catch (bytes memory err) {
                        emit EscrowRebateDelivered(recipient, esRebateAmount, rosxPrice, mintEsROSXAmount, false, string(err));
                    }
                }
            }
        }

        return (rebateAmount, mintEsROSXAmount);
    }

    function getTier(address _referrer) external view returns (TIER_TYPE, uint256) {
        return _getTier(_referrer);
    }

    function getCodeTier(bytes32 _refCode) external view returns (address, TIER_TYPE, uint256) {
        address referrer = codeOwners[_refCode];
        (TIER_TYPE tierType, uint256 tierId) = _getTier(referrer);
        return (referrer, tierType, tierId);
    }

    function _getTier(address _referrer) internal view returns (TIER_TYPE, uint256) {
        TIER_TYPE tierType = tierOwners[_referrer];
        return (tierType, refTiers[_referrer][uint256(tierType)]);
    }

    function _getDiscountPercentage(TIER_TYPE _tierType, uint256 _tier) internal view returns (uint256) {
        if (_tierType == TIER_TYPE.PREMIUM) {
            return premiumTiers[_tier].discountSharePercentage;
        } else if (_tierType == TIER_TYPE.STANDARD) {
            return standardTiers[_tier].discountSharePercentage;
        } else {
            //Reverse
            revert("Invalid tierType");
        }
    }

    function _getRebatePercentage(TIER_TYPE _tierType, uint256 _tier) internal view returns (uint256) {
        if (_tierType == TIER_TYPE.PREMIUM) {
            return premiumTiers[_tier].rebatePercentage;
        } else if (_tierType == TIER_TYPE.STANDARD) {
            return standardTiers[_tier].rebatePercentage;
        } else {
            //Reverse
            revert("Invalid tierType");
        }
    }

    function increaseCodeStat(address _account, uint256 _discountshareAmount, uint256 _rebateAmount, uint256 _esROSXRebateAmount) external onlyHandler {
        _increaseCodeStat(
            traderReferralCode[_account],
            _discountshareAmount,
            _rebateAmount,
            _esROSXRebateAmount
        );
    }

    function _increaseCodeStat(bytes32 _code, uint256 _discountshareAmount, uint256 _rebateAmount, uint256 _esROSXRebateAmount) internal {
        if (_code != bytes32(0)) {
            ReferralCodeStat storage statistic = codeStats[_code];
            statistic.totalDiscountshare += _discountshareAmount;
            statistic.totalRebate += _rebateAmount;
            statistic.totalEsROSXRebate += _esROSXRebateAmount;
            emit IncreaseCodeStat(_code, _discountshareAmount, _rebateAmount, _esROSXRebateAmount);
        }
    }

    function fixCodeStat(bytes32 _code, uint256 _totalDiscountshare, uint256 _totalRebate, uint256 _totalEsROSXRebate) external onlyAdmin {
        ReferralCodeStat storage statistic = codeStats[_code];
        statistic.totalDiscountshare = _totalDiscountshare;
        statistic.totalRebate = _totalRebate;
        statistic.totalEsROSXRebate = _totalEsROSXRebate;
        emit FixCodeStat(_code, _totalDiscountshare, _totalRebate, _totalEsROSXRebate);
    }

    function getCodeStat(bytes32[] memory code) external view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        require(code.length > 0, "Invalid length");
        uint256[] memory totalRebateArr = new uint256[](code.length);
        uint256[] memory totalDiscountshareArr = new uint256[](code.length);
        uint256[] memory totalEsRebateArr = new uint256[](code.length);

        for (uint256 i = 0; i < code.length; i++) {
            totalRebateArr[i] = codeStats[code[i]].totalRebate;
            totalDiscountshareArr[i] = codeStats[code[i]].totalDiscountshare;
            totalEsRebateArr[i] = codeStats[code[i]].totalEsRebate;
        }

        return (totalRebateArr, totalDiscountshareArr, totalEsRebateArr);
    }
    
    function convertRUSD(
        address _recipient, 
        address _tokenOut, 
        uint256 _amount
    ) external nonReentrant {
        _validateInternalContracts(rUSD, address(settingsManager), address(priceManager), address(vault));
        require(settingsManager.isApprovalCollateralToken(_tokenOut) == true, "Invalid tokenOut");
        require(settingsManager.isEnableConvertRUSD(), "Disabled");
        require(IERC20Upgradeable(rUSD).balanceOf(msg.sender) > 0, "Insufficient");
        IMintable(rUSD).burn(msg.sender, _amount);
        bool isStable = settingsManager.isStable(_tokenOut);
        uint256 tokenPrice;
        uint256 amountOut;

        if (isStable) {
            //Force 1-1 if tokenOut is stable
            tokenPrice = PRICE_PRECISION;
            amountOut = priceManager.fromUSDToToken(_tokenOut, _amount, PRICE_PRECISION);
        } else {
            uint256 lastUpdateAt;
            bool isLatestPrice;
            (tokenPrice, lastUpdateAt, isLatestPrice) = priceManager.getLatestSynchronizedPrice(_tokenOut);
            bool isAcceptablePrice = nonStableMaxPriceUpdatedDelay == 0 
                ? isLatestPrice : (block.timestamp - lastUpdateAt) <= nonStableMaxPriceUpdatedDelay;
            require(isAcceptablePrice, "Price oudated, try again");
            amountOut = priceManager.fromUSDToToken(_tokenOut, _amount, tokenPrice);
        }

        require(amountOut > 0, "Zero amountOut");
        vault.takeAssetOut(
            bytes32(0),
            _recipient,
            0,
            _amount,
            _tokenOut,
            tokenPrice
        );
        emit ConvertRUSD(_recipient, _tokenOut, _amount, amountOut);
    }

    function _validateInternalContracts(address _rUSD, address _settingsManager, address _priceManager, address _vault) internal pure {
        require(_rUSD != address(0) 
            && _settingsManager != address(0) 
            && _priceManager != address(0)
            && _vault != address(0), 
            "Zero impl address"
        );
    }

    /*
    @dev Initialize 3 standard tiers and 5 premium tiers
    */
    function initializeTiers() internal {
        uint256[] memory initStandardTiers = new uint256[](3);
        uint256[] memory initPremiumTiers = new uint256[](5);
        
        for (uint256 i = 0; i < initStandardTiers.length; i++) {
            StandardTier storage tier = standardTiers[i + 1];
            tier.discountSharePercentage = (i + 1) * 5 * BASIS_POINTS_DIVISOR / 100;
            tier.rebatePercentage = (i + 1) * 5 * BASIS_POINTS_DIVISOR / 100;
            tier.isActivate = true;
        }

        for (uint256 i = 0; i < initPremiumTiers.length; i++) {
            PremiumTier storage tier = premiumTiers[i + 1];
            tier.discountSharePercentage = 15 * BASIS_POINTS_DIVISOR / 100;

            if (i == 0) {
                tier.rebatePercentage = 20 * BASIS_POINTS_DIVISOR / 100;
            } else if (i == 1) {
                tier.rebatePercentage = 30 * BASIS_POINTS_DIVISOR / 100;
            } else if (i >= 2) {
                tier.rebatePercentage = 40 * BASIS_POINTS_DIVISOR / 100;
            }

            if (i == 3) {
                tier.esRebatePercentage = 10 * BASIS_POINTS_DIVISOR / 100;
            } else if (i == 4) {
                tier.esRebatePercentage = 20 * BASIS_POINTS_DIVISOR / 100;
            }

            tier.isActivate = true;
        }
    }

    function getCodeUsageLength(address _account) external view returns (uint256) {
        return codeUsage[_account].length();
    }

    function getCodeUsage(address _account) external view returns (bytes32[] memory) {
        return _iteratorCodeUsage(_account);
    }

    function _iteratorCodeUsage(address _account) internal view returns (bytes32[] memory) {
        uint256 length = codeUsage[_account].length();

        if (length == 0) {
            return new bytes32[](0);
        }

        bytes32[] memory codeArr = new bytes32[](length);

        for (uint256 i = 0; i < length; i++) {
            codeArr[i] = codeUsage[_account].at(i);
        }

        return codeArr;
    }

    function getCodeLinkLength(bytes32 _code) external view returns (uint256) {
        return codeLink[_code].length();
    }

    function getCodeLink(bytes32 _code) external view returns (address[] memory) {
        return _iteratorCodeLink(_code);
    }

    function _iteratorCodeLink(bytes32 _code) internal view returns (address[] memory) {
        uint256 length = codeLink[_code].length();

        if (length == 0) {
            return new address[](0);
        }

        address[] memory accountArr = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            accountArr[i] = codeLink[_code].at(i);
        }

        return accountArr;
    }
}