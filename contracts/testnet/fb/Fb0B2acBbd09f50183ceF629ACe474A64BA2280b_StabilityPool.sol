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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Dependencies/AddressesConfigurable.sol";

contract Addresses is AddressesConfigurable {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract AddressesConfigurable is OwnableUpgradeable {
	address public activePool;
	address public adminContract;
	address public borrowerOperations;
	address public collSurplusPool;
	address public communityIssuance;
	address public debtToken;
	address public defaultPool;
	address public feeCollector;
	address public gasPoolAddress;
	address public grvtStaking;
	address public priceFeed;
	address public sortedVessels;
	address public stabilityPool;
	address public timelockAddress;
	address public treasuryAddress;
	address public vesselManager;
	address public vesselManagerOperations;

	bool public isAddressSetupInitialized;

	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[47] private __gap;

	// Dependency setters -----------------------------------------------------------------------------------------------

	function setAddresses(address[] calldata _addresses) external onlyOwner {
		require(!isAddressSetupInitialized, "Setup is already initialized");
		require(_addresses.length == 15, "Expected 15 addresses at setup");

		activePool = _addresses[0];
		adminContract = _addresses[1];
		borrowerOperations = _addresses[2];
		collSurplusPool = _addresses[3];
		debtToken = _addresses[4];
		defaultPool = _addresses[5];
		feeCollector = _addresses[6];
		gasPoolAddress = _addresses[7];
		priceFeed = _addresses[8];
		sortedVessels = _addresses[9];
		stabilityPool = _addresses[10];
		timelockAddress = _addresses[11];
		treasuryAddress = _addresses[12];
		vesselManager = _addresses[13];
		vesselManagerOperations = _addresses[14];

		isAddressSetupInitialized = true;
	}

	function setCommunityIssuance(address _communityIssuance) public onlyOwner {
		communityIssuance = _communityIssuance;
	}

	function setGRVTStaking(address _grvtStaking) public onlyOwner {
		grvtStaking = _grvtStaking;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract BaseMath {
	uint256 public constant DECIMAL_PRECISION = 1 ether;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./BaseMath.sol";
import "./GravitaMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IGravitaBase.sol";
import "../Interfaces/IAdminContract.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Addresses.sol";

/*
 * Base contract for VesselManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
abstract contract GravitaBase is IGravitaBase, BaseMath, OwnableUpgradeable, Addresses {
	// --- Gas compensation functions ---

	// Returns the composite debt (drawn debt + gas compensation) of a vessel, for the purpose of ICR calculation
	function _getCompositeDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt + IAdminContract(adminContract).getDebtTokenGasCompensation(_asset);
	}

	function _getNetDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt - IAdminContract(adminContract).getDebtTokenGasCompensation(_asset);
	}

	// Return the amount of ETH to be drawn from a vessel's collateral and sent as gas compensation.
	function _getCollGasCompensation(address _asset, uint256 _entireColl) internal view returns (uint256) {
		return _entireColl / IAdminContract(adminContract).getPercentDivisor(_asset);
	}

	function getEntireSystemColl(address _asset) public view returns (uint256 entireSystemColl) {
		uint256 activeColl = IActivePool(activePool).getAssetBalance(_asset);
		uint256 liquidatedColl = IDefaultPool(defaultPool).getAssetBalance(_asset);
		return activeColl + liquidatedColl;
	}

	function getEntireSystemDebt(address _asset) public view returns (uint256 entireSystemDebt) {
		uint256 activeDebt = IActivePool(activePool).getDebtTokenBalance(_asset);
		uint256 closedDebt = IDefaultPool(defaultPool).getDebtTokenBalance(_asset);
		return activeDebt + closedDebt;
	}

	function _getTCR(address _asset, uint256 _price) internal view returns (uint256 TCR) {
		uint256 entireSystemColl = getEntireSystemColl(_asset);
		uint256 entireSystemDebt = getEntireSystemDebt(_asset);
		TCR = GravitaMath._computeCR(entireSystemColl, entireSystemDebt, _price);
	}

	function _checkRecoveryMode(address _asset, uint256 _price) internal view returns (bool) {
		uint256 TCR = _getTCR(_asset, _price);
		return TCR < IAdminContract(adminContract).getCcr(_asset);
	}

	function _requireUserAcceptsFee(uint256 _fee, uint256 _amount, uint256 _maxFeePercentage) internal view {
		uint256 feePercentage = (_fee * IAdminContract(adminContract).DECIMAL_PRECISION()) / _amount;
		require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library GravitaMath {
	uint256 internal constant DECIMAL_PRECISION = 1 ether;

	uint256 internal constant EXPONENT_CAP = 525_600_000;

	/* Precision for Nominal ICR (independent of price). Rationale for the value:
	 *
	 * - Making it “too high” could lead to overflows.
	 * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
	 *
	 * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
	 * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
	 *
	 */
	uint256 internal constant NICR_PRECISION = 1e20;

	function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a < _b) ? _a : _b;
	}

	function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a : _b;
	}

	/*
	 * Multiply two decimal numbers and use normal rounding rules:
	 * -round product up if 19'th mantissa digit >= 5
	 * -round product down if 19'th mantissa digit < 5
	 *
	 * Used only inside the exponentiation, _decPow().
	 */
	function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
		uint256 prod_xy = x * y;

		decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
	}

	/*
	 * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
	 *
	 * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
	 *
	 * Called by two functions that represent time in units of minutes:
	 * 1) VesselManager._calcDecayedBaseRate
	 * 2) CommunityIssuance._getCumulativeIssuanceFraction
	 *
	 * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
	 * "minutes in 1000 years": 60 * 24 * 365 * 1000
	 *
	 * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
	 * negligibly different from just passing the cap, since:
	 *
	 * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
	 * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
	 */
	function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
		if (_minutes > EXPONENT_CAP) {
			_minutes = EXPONENT_CAP;
		} // cap to avoid overflow

		if (_minutes == 0) {
			return DECIMAL_PRECISION;
		}

		uint256 y = DECIMAL_PRECISION;
		uint256 x = _base;
		uint256 n = _minutes;

		// Exponentiation-by-squaring
		while (n > 1) {
			if (n % 2 == 0) {
				x = decMul(x, x);
				n = n / 2;
			} else {
				// if (n % 2 != 0)
				y = decMul(x, y);
				x = decMul(x, x);
				n = (n - 1) / 2;
			}
		}

		return decMul(x, y);
	}

	function _getAbsoluteDifference(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a - _b : _b - _a;
	}

	function _computeNominalCR(uint256 _coll, uint256 _debt) internal pure returns (uint256) {
		if (_debt != 0) {
			return _coll * NICR_PRECISION / _debt;
		}
		// Return the maximal value for uint256 if the Vessel has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return type(uint256).max;
		}
	}

	function _computeCR(
		uint256 _coll,
		uint256 _debt,
		uint256 _price
	) internal pure returns (uint256) {
		if (_debt != 0) {
			uint256 newCollRatio = _coll * _price / _debt;

			return newCollRatio;
		}
		// Return the maximal value for uint256 if the Vessel has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return type(uint256).max;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../Interfaces/IERC20Decimals.sol";

library SafetyTransfer {

	error EthUnsupportedError();
	error InvalidAmountError();

	//_amount is in ether (1e18) and we want to convert it to the token decimal
	function decimalsCorrection(address _token, uint256 _amount) internal view returns (uint256) {
		if (_token == address(0)) {
			revert EthUnsupportedError();
		}
		if (_amount == 0) {
			return 0;
		}
		uint8 decimals = IERC20Decimals(_token).decimals();
		if (decimals < 18) {
			uint256 divisor = 10**(18 - decimals);
			if (_amount % divisor != 0) {
				revert InvalidAmountError();
			}
			return _amount / divisor;
		} else if (decimals > 18) {
			uint256 multiplier = 10**(decimals - 18);
			return _amount * multiplier;
		}
		return _amount;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./IPool.sol";

interface IActivePool is IPool {

	// --- Events ---

	event ActivePoolDebtUpdated(address _asset, uint256 _debtTokenAmount);
	event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---

	function sendAsset(
		address _asset,
		address _account,
		uint256 _amount
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";

interface IAdminContract {
	// Structs ----------------------------------------------------------------------------------------------------------

	struct CollateralParams {
		uint256 decimals;
		uint256 index; // Maps to token address in validCollateral[]
		bool active;
		uint256 borrowingFee;
		uint256 ccr;
		uint256 mcr;
		uint256 debtTokenGasCompensation; // Amount of debtToken to be locked in gas pool on opening vessels
		uint256 minNetDebt; // Minimum amount of net debtToken a vessel must have
		uint256 mintCap;
		uint256 percentDivisor;
		uint256 redemptionFeeFloor;
		uint256 redemptionBlockTimestamp;
	}

	// Custom Errors ----------------------------------------------------------------------------------------------------

	error SafeCheckError(string parameter, uint256 valueEntered, uint256 minValue, uint256 maxValue);
	error AdminContract__OnlyOwner();
	error AdminContract__OnlyTimelock();
	error AdminContract__CollateralAlreadyInitialized();

	// Events -----------------------------------------------------------------------------------------------------------

	event CollateralAdded(address _collateral);
	event MCRChanged(uint256 oldMCR, uint256 newMCR);
	event CCRChanged(uint256 oldCCR, uint256 newCCR);
	event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
	event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
	event BorrowingFeeChanged(uint256 oldBorrowingFee, uint256 newBorrowingFee);
	event RedemptionFeeFloorChanged(uint256 oldRedemptionFeeFloor, uint256 newRedemptionFeeFloor);
	event MintCapChanged(uint256 oldMintCap, uint256 newMintCap);
	event RedemptionBlockTimestampChanged(address _collateral, uint256 _blockTimestamp);

	// Functions --------------------------------------------------------------------------------------------------------

	function DECIMAL_PRECISION() external view returns (uint256);

	function _100pct() external view returns (uint256);

	function addNewCollateral(address _collateral, uint256 _debtTokenGasCompensation, uint256 _decimals) external;

	function setCollateralParameters(
		address _collateral,
		uint256 borrowingFee,
		uint256 ccr,
		uint256 mcr,
		uint256 minNetDebt,
		uint256 mintCap,
		uint256 percentDivisor,
		uint256 redemptionFeeFloor
	) external;

	function setMCR(address _collateral, uint256 newMCR) external;

	function setCCR(address _collateral, uint256 newCCR) external;

	function setMinNetDebt(address _collateral, uint256 minNetDebt) external;

	function setPercentDivisor(address _collateral, uint256 precentDivisor) external;

	function setBorrowingFee(address _collateral, uint256 borrowingFee) external;

	function setRedemptionFeeFloor(address _collateral, uint256 redemptionFeeFloor) external;

	function setMintCap(address _collateral, uint256 mintCap) external;

	function setRedemptionBlockTimestamp(address _collateral, uint256 _blockTimestamp) external;

	function getIndex(address _collateral) external view returns (uint256);

	function getIsActive(address _collateral) external view returns (bool);

	function getValidCollateral() external view returns (address[] memory);

	function getMcr(address _collateral) external view returns (uint256);

	function getCcr(address _collateral) external view returns (uint256);

	function getDebtTokenGasCompensation(address _collateral) external view returns (uint256);

	function getMinNetDebt(address _collateral) external view returns (uint256);

	function getPercentDivisor(address _collateral) external view returns (uint256);

	function getBorrowingFee(address _collateral) external view returns (uint256);

	function getRedemptionFeeFloor(address _collateral) external view returns (uint256);

	function getRedemptionBlockTimestamp(address _collateral) external view returns (uint256);

	function getMintCap(address _collateral) external view returns (uint256);

	function getTotalAssetDebt(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IDeposit.sol";

interface ICollSurplusPool is IDeposit {

	// --- Events ---

	event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
	event AssetSent(address _to, uint256 _amount);

	// --- Functions ---

	function getAssetBalance(address _asset) external view returns (uint256);

	function getCollateral(address _asset, address _account) external view returns (uint256);

	function accountSurplus(
		address _asset,
		address _account,
		uint256 _amount
	) external;

	function claimColl(address _asset, address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ICommunityIssuance {
	// --- Events ---

	event TotalGRVTIssuedUpdated(uint256 _totalGRVTIssued);

	// --- Functions ---

	function issueGRVT() external returns (uint256);

	function sendGRVT(address _account, uint256 _GRVTamount) external;

	function addFundToStabilityPool(uint256 _assignedSupply) external;

	function addFundToStabilityPoolFrom(uint256 _assignedSupply, address _spender) external;

	function setWeeklyGrvtDistribution(uint256 _weeklyReward) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStabilityPool.sol";

interface IDebtToken is IERC20 {
	// --- Events ---

	event TokenBalanceUpdated(address _user, uint256 _amount);
	event EmergencyStopMintingCollateral(address _asset, bool state);
	event WhitelistChanged(address _whitelisted, bool whitelisted);

	function emergencyStopMinting(address _asset, bool status) external;

	function mint(address _asset, address _account, uint256 _amount) external;

	function mintFromWhitelistedContract(uint256 _amount) external;

	function burnFromWhitelistedContract(uint256 _amount) external;

	function burn(address _account, uint256 _amount) external;

	function sendToPool(address _sender, address poolAddress, uint256 _amount) external;

	function returnFromPool(address poolAddress, address user, uint256 _amount) external;

	function addWhitelist(address _address) external;

	function removeWhitelist(address _address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./IPool.sol";

interface IDefaultPool is IPool {
	// --- Events ---
	event DefaultPoolDebtUpdated(address _asset, uint256 _debt);
	event DefaultPoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAssetToActivePool(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IDeposit {
	function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20Decimals {
	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IAdminContract.sol";

interface IGravitaBase {
	struct Colls {
		// tokens and amounts should be the same length
		address[] tokens;
		uint256[] amounts;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IDeposit.sol";

interface IPool is IDeposit {

	// --- Events ---

	event AssetSent(address _to, address indexed _asset, uint256 _amount);

	// --- Functions ---

	function getAssetBalance(address _asset) external view returns (uint256);

	function getDebtTokenBalance(address _asset) external view returns (uint256);

	function increaseDebt(address _asset, uint256 _amount) external;

	function decreaseDebt(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/*
 * @dev from https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
 */
interface ChainlinkAggregatorV3Interface {
	function decimals() external view returns (uint8);

	function latestRoundData()
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface IPriceFeed {
	// Enums ----------------------------------------------------------------------------------------------------------

	enum ProviderType {
		Chainlink
	}

	// Structs --------------------------------------------------------------------------------------------------------

	struct OracleRecordV2 {
		address oracleAddress;
		ProviderType providerType;
		uint256 timeoutMinutes;
		uint256 decimals;
		bool isEthIndexed;
	}

	/// @dev Deprecated, but retained for upgradeability
	struct OracleRecord {
		address chainLinkOracle;
		uint256 maxDeviationBetweenRounds;
		bool exists;
		bool isFeedWorking;
		bool isEthIndexed;
	}

	/// @dev Deprecated, but retained for upgradeability
	struct PriceRecord {
		uint256 scaledPrice;
		uint256 timestamp;
	}

	/// @dev Deprecated, but retained for upgradeability
	struct FeedResponse {
		uint80 roundId;
		int256 answer;
		uint256 timestamp;
		bool success;
		uint8 decimals;
	}

	// Custom Errors --------------------------------------------------------------------------------------------------

	error PriceFeed__ExistingOracleRequired();
	error PriceFeed__InvalidDecimalsError();
	error PriceFeed__InvalidOracleResponseError(address token);
	error PriceFeed__TimelockOnlyError();
	error PriceFeed__UnknownAssetError();

	// Events ---------------------------------------------------------------------------------------------------------

	event NewOracleRegistered(address token, address oracleAddress, bool isEthIndexed, bool isFallback);

	// Functions ------------------------------------------------------------------------------------------------------

	function fetchPrice(address _token) external view returns (uint256);

	function setOracle(
		address _token,
		address _oracle,
		ProviderType _type,
		uint256 _timeoutMinutes,
		bool _isEthIndexed,
		bool _isFallback
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ISortedVessels {
	// --- Events ---

	event NodeAdded(address indexed _asset, address _id, uint256 _NICR);
	event NodeRemoved(address indexed _asset, address _id);

	// --- Functions ---

	function insert(
		address _asset,
		address _id,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external;

	function remove(address _asset, address _id) external;

	function reInsert(
		address _asset,
		address _id,
		uint256 _newICR,
		address _prevId,
		address _nextId
	) external;

	function contains(address _asset, address _id) external view returns (bool);

	function isEmpty(address _asset) external view returns (bool);

	function getSize(address _asset) external view returns (uint256);

	function getFirst(address _asset) external view returns (address);

	function getLast(address _asset) external view returns (address);

	function getNext(address _asset, address _id) external view returns (address);

	function getPrev(address _asset, address _id) external view returns (address);

	function validInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (bool);

	function findInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IDeposit.sol";

interface IStabilityPool is IDeposit {
	// --- Structs ---

	struct Snapshots {
		mapping(address => uint256) S;
		uint256 P;
		uint256 G;
		uint128 scale;
		uint128 epoch;
	}

	// --- Events ---

	event CommunityIssuanceAddressChanged(address newAddress);
	event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _G);
	event SystemSnapshotUpdated(uint256 _P, uint256 _G);

	event AssetSent(address _asset, address _to, uint256 _amount);
	event GainsWithdrawn(address indexed _depositor, address[] _collaterals, uint256[] _amounts, uint256 _debtTokenLoss);
	event GRVTPaidToDepositor(address indexed _depositor, uint256 _GRVT);
	event StabilityPoolAssetBalanceUpdated(address _asset, uint256 _newBalance);
	event StabilityPoolDebtTokenBalanceUpdated(uint256 _newBalance);
	event StakeChanged(uint256 _newSystemStake, address _depositor);
	event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);

	event P_Updated(uint256 _P);
	event S_Updated(address _asset, uint256 _S, uint128 _epoch, uint128 _scale);
	event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
	event EpochUpdated(uint128 _currentEpoch);
	event ScaleUpdated(uint128 _currentScale);

	// --- Errors ---

	error StabilityPool__ActivePoolOnly(address sender, address expected);
	error StabilityPool__AdminContractOnly(address sender, address expected);
	error StabilityPool__VesselManagerOnly(address sender, address expected);
	error StabilityPool__DuplicateElementOnArray();

	// --- Functions ---

	function addCollateralType(address _collateral) external;

	/*
	 * Initial checks:
	 * - _amount is not zero
	 * ---
	 * - Triggers a GRVT issuance, based on time passed since the last issuance. The GRVT issuance is shared between *all* depositors.
	 * - Sends depositor's accumulated gains (GRVT, assets) to depositor
	 */
	function provideToSP(uint256 _amount, address[] calldata _assets) external;

	/*
	 * Initial checks:
	 * - _amount is zero or there are no under collateralized vessels left in the system
	 * - User has a non zero deposit
	 * ---
	 * - Triggers a GRVT issuance, based on time passed since the last issuance. The GRVT issuance is shared between *all* depositors.
	 * - Sends all depositor's accumulated gains (GRVT, assets) to depositor
	 * - Decreases deposit's stake, and takes new snapshots.
	 *
	 * If _amount > userDeposit, the user withdraws all of their compounded deposit.
	 */
	function withdrawFromSP(uint256 _amount, address[] calldata _assets) external;

	/*
	Initial checks:
	 * - Caller is VesselManager
	 * ---
	 * Cancels out the specified debt against the debt token contained in the Stability Pool (as far as possible)
	 * and transfers the Vessel's collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the VesselManager.
	 */
	function offset(uint256 _debt, address _asset, uint256 _coll) external;

	/*
	 * Returns debt tokens held in the pool. Changes when users deposit/withdraw, and when Vessel debt is offset.
	 */
	function getTotalDebtTokenDeposits() external view returns (uint256);

	/*
	 * Calculates the asset gains earned by the deposit since its last snapshots were taken.
	 */
	function getDepositorGains(
		address _depositor,
		address[] calldata _assets
	) external view returns (address[] memory, uint256[] memory);

	/*
	 * Calculate the GRVT gain earned by a deposit since its last snapshots were taken.
	 */
	function getDepositorGRVTGain(address _depositor) external view returns (uint256);

	/*
	 * Return the user's compounded deposits.
	 */
	function getCompoundedDebtTokenDeposits(address _depositor) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IActivePool.sol";
import "./ICollSurplusPool.sol";
import "./IDebtToken.sol";
import "./IDefaultPool.sol";
import "./IGravitaBase.sol";
import "./ISortedVessels.sol";
import "./IStabilityPool.sol";

interface IVesselManager is IGravitaBase {
	// Enums ------------------------------------------------------------------------------------------------------------

	enum Status {
		nonExistent,
		active,
		closedByOwner,
		closedByLiquidation,
		closedByRedemption
	}

	enum VesselManagerOperation {
		applyPendingRewards,
		liquidateInNormalMode,
		liquidateInRecoveryMode,
		redeemCollateral
	}

	// Events -----------------------------------------------------------------------------------------------------------

	event BaseRateUpdated(address indexed _asset, uint256 _baseRate);
	event LastFeeOpTimeUpdated(address indexed _asset, uint256 _lastFeeOpTime);
	event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
	event SystemSnapshotsUpdated(address indexed _asset, uint256 _totalStakesSnapshot, uint256 _totalCollateralSnapshot);
	event LTermsUpdated(address indexed _asset, uint256 _L_Coll, uint256 _L_Debt);
	event VesselSnapshotsUpdated(address indexed _asset, uint256 _L_Coll, uint256 _L_Debt);
	event VesselIndexUpdated(address indexed _asset, address _borrower, uint256 _newIndex);

	event VesselUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 _stake,
		VesselManagerOperation _operation
	);

	// Custom Errors ----------------------------------------------------------------------------------------------------

	error VesselManager__FeeBiggerThanAssetDraw();
	error VesselManager__OnlyOneVessel();

	error VesselManager__OnlyVesselManagerOperations();
	error VesselManager__OnlyBorrowerOperations();
	error VesselManager__OnlyVesselManagerOperationsOrBorrowerOperations();

	// Structs ----------------------------------------------------------------------------------------------------------

	struct Vessel {
		uint256 debt;
		uint256 coll;
		uint256 stake;
		Status status;
		uint128 arrayIndex;
	}

	// Functions --------------------------------------------------------------------------------------------------------

	function executeFullRedemption(
		address _asset,
		address _borrower,
		uint256 _newColl
	) external;

	function executePartialRedemption(
		address _asset,
		address _borrower,
		uint256 _newDebt,
		uint256 _newColl,
		uint256 _newNICR,
		address _upperPartialRedemptionHint,
		address _lowerPartialRedemptionHint
	) external;

	function getVesselOwnersCount(address _asset) external view returns (uint256);

	function getVesselFromVesselOwnersArray(address _asset, uint256 _index) external view returns (address);

	function getNominalICR(address _asset, address _borrower) external view returns (uint256);

	function getCurrentICR(
		address _asset,
		address _borrower,
		uint256 _price
	) external view returns (uint256);

	function updateStakeAndTotalStakes(address _asset, address _borrower) external returns (uint256);

	function updateVesselRewardSnapshots(address _asset, address _borrower) external;

	function addVesselOwnerToArray(address _asset, address _borrower) external returns (uint256 index);

	function applyPendingRewards(address _asset, address _borrower) external;

	function getPendingAssetReward(address _asset, address _borrower) external view returns (uint256);

	function getPendingDebtTokenReward(address _asset, address _borrower) external view returns (uint256);

	function hasPendingRewards(address _asset, address _borrower) external view returns (bool);

	function getEntireDebtAndColl(address _asset, address _borrower)
		external
		view
		returns (
			uint256 debt,
			uint256 coll,
			uint256 pendingDebtTokenReward,
			uint256 pendingAssetReward
		);

	function closeVessel(address _asset, address _borrower) external;

	function closeVesselLiquidation(address _asset, address _borrower) external;

	function removeStake(address _asset, address _borrower) external;

	function getRedemptionRate(address _asset) external view returns (uint256);

	function getRedemptionRateWithDecay(address _asset) external view returns (uint256);

	function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw) external view returns (uint256);

	function getBorrowingRate(address _asset) external view returns (uint256);

	function getBorrowingFee(address _asset, uint256 _debtTokenAmount) external view returns (uint256);

	function getVesselStatus(address _asset, address _borrower) external view returns (uint256);

	function getVesselStake(address _asset, address _borrower) external view returns (uint256);

	function getVesselDebt(address _asset, address _borrower) external view returns (uint256);

	function getVesselColl(address _asset, address _borrower) external view returns (uint256);

	function setVesselStatus(
		address _asset,
		address _borrower,
		uint256 num
	) external;

	function increaseVesselColl(
		address _asset,
		address _borrower,
		uint256 _collIncrease
	) external returns (uint256);

	function decreaseVesselColl(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function increaseVesselDebt(
		address _asset,
		address _borrower,
		uint256 _debtIncrease
	) external returns (uint256);

	function decreaseVesselDebt(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function getTCR(address _asset, uint256 _price) external view returns (uint256);

	function checkRecoveryMode(address _asset, uint256 _price) external returns (bool);

	function isValidFirstRedemptionHint(
		address _asset,
		address _firstRedemptionHint,
		uint256 _price
	) external returns (bool);

	function updateBaseRateFromRedemption(
		address _asset,
		uint256 _assetDrawn,
		uint256 _price,
		uint256 _totalDebtTokenSupply
	) external returns (uint256);

	function getRedemptionFee(address _asset, uint256 _assetDraw) external view returns (uint256);

	function finalizeRedemption(
		address _asset,
		address _receiver,
		uint256 _debtToRedeem,
		uint256 _fee,
		uint256 _totalRedemptionRewards
	) external;

	function redistributeDebtAndColl(
		address _asset,
		uint256 _debt,
		uint256 _coll,
		uint256 _debtToOffset,
		uint256 _collToSendToStabilityPool
	) external;

	function updateSystemSnapshots_excludeCollRemainder(address _asset, uint256 _collRemainder) external;

	function movePendingVesselRewardsToActivePool(
		address _asset,
		uint256 _debtTokenAmount,
		uint256 _assetAmount
	) external;

	function isVesselActive(address _asset, address _borrower) external view returns (bool);

	function sendGasCompensation(
		address _asset,
		address _liquidator,
		uint256 _debtTokenAmount,
		uint256 _assetAmount
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Dependencies/GravitaBase.sol";
import "./Dependencies/SafetyTransfer.sol";
import "./Interfaces/IStabilityPool.sol";
import "./Interfaces/IDebtToken.sol";
import "./Interfaces/IVesselManager.sol";
import "./Interfaces/ICommunityIssuance.sol";

/**
 * @title The Stability Pool holds debt tokens deposited by Stability Pool depositors.
 * @dev When a vessel is liquidated, then depending on system conditions, some of its debt tokens debt gets offset with
 * debt tokens in the Stability Pool: that is, the offset debt evaporates, and an equal amount of debt tokens tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a debt tokens loss, in proportion to their deposit as a share of total deposits.
 * They also receive an Collateral gain, as the amount of collateral of the liquidated vessel is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total debt tokens in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 *
 * --- IMPLEMENTATION ---
 *
 * We use a highly scalable method of tracking deposits and Collateral gains that has O(1) complexity.
 *
 * When a liquidation occurs, rather than updating each depositor's deposit and Collateral gain, we simply update two state variables:
 * a product P, and a sum S. These are kept track for each type of collateral.
 *
 * A mathematical manipulation allows us to factor out the initial deposit, and accurately track all depositors' compounded deposits
 * and accumulated Collateral amount gains over time, as liquidations occur, using just these two variables P and S. When depositors join the
 * Stability Pool, they get a snapshot of the latest P and S: P_t and S_t, respectively.
 *
 * The formula for a depositor's accumulated Collateral amount gain is derived here:
 * https://github.com/liquity/dev/blob/main/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * For a given deposit d_t, the ratio P/P_t tells us the factor by which a deposit has decreased since it joined the Stability Pool,
 * and the term d_t * (S - S_t)/P_t gives us the deposit's total accumulated Collateral amount gain.
 *
 * Each liquidation updates the product P and sum S. After a series of liquidations, a compounded deposit and corresponding Collateral amount gain
 * can be calculated using the initial deposit, the depositor’s snapshots of P and S, and the latest values of P and S.
 *
 * Any time a depositor updates their deposit (withdrawal, top-up) their accumulated Collateral amount gain is paid out, their new deposit is recorded
 * (based on their latest compounded deposit and modified by the withdrawal/top-up), and they receive new snapshots of the latest P and S.
 * Essentially, they make a fresh deposit that overwrites the old one.
 *
 *
 * --- SCALE FACTOR ---
 *
 * Since P is a running product in range ]0,1] that is always-decreasing, it should never reach 0 when multiplied by a number in range ]0,1[.
 * Unfortunately, Solidity floor division always reaches 0, sooner or later.
 *
 * A series of liquidations that nearly empty the Pool (and thus each multiply P by a very small number in range ]0,1[ ) may push P
 * to its 18 digit decimal limit, and round it to 0, when in fact the Pool hasn't been emptied: this would break deposit tracking.
 *
 * So, to track P accurately, we use a scale factor: if a liquidation would cause P to decrease to <1e-9 (and be rounded to 0 by Solidity),
 * we first multiply P by 1e9, and increment a currentScale factor by 1.
 *
 * The added benefit of using 1e9 for the scale factor (rather than 1e18) is that it ensures negligible precision loss close to the
 * scale boundary: when P is at its minimum value of 1e9, the relative precision loss in P due to floor division is only on the
 * order of 1e-9.
 *
 * --- EPOCHS ---
 *
 * Whenever a liquidation fully empties the Stability Pool, all deposits should become 0. However, setting P to 0 would make P be 0
 * forever, and break all future reward calculations.
 *
 * So, every time the Stability Pool is emptied by a liquidation, we reset P = 1 and currentScale = 0, and increment the currentEpoch by 1.
 *
 * --- TRACKING DEPOSIT OVER SCALE CHANGES AND EPOCHS ---
 *
 * When a deposit is made, it gets snapshots of the currentEpoch and the currentScale.
 *
 * When calculating a compounded deposit, we compare the current epoch to the deposit's epoch snapshot. If the current epoch is newer,
 * then the deposit was present during a pool-emptying liquidation, and necessarily has been depleted to 0.
 *
 * Otherwise, we then compare the current scale to the deposit's scale snapshot. If they're equal, the compounded deposit is given by d_t * P/P_t.
 * If it spans one scale change, it is given by d_t * P/(P_t * 1e9). If it spans more than one scale change, we define the compounded deposit
 * as 0, since it is now less than 1e-9'th of its initial value (e.g. a deposit of 1 billion debt tokens has depleted to < 1 debt token).
 *
 *
 *  --- TRACKING DEPOSITOR'S COLLATERAL AMOUNT GAIN OVER SCALE CHANGES AND EPOCHS ---
 *
 * In the current epoch, the latest value of S is stored upon each scale change, and the mapping (scale -> S) is stored for each epoch.
 *
 * This allows us to calculate a deposit's accumulated Collateral amount gain, during the epoch in which the deposit was non-zero and earned Collateral amount.
 *
 * We calculate the depositor's accumulated Collateral amount gain for the scale at which they made the deposit, using the Collateral amount gain formula:
 * e_1 = d_t * (S - S_t) / P_t
 *
 * and also for scale after, taking care to divide the latter by a factor of 1e9:
 * e_2 = d_t * S / (P_t * 1e9)
 *
 * The gain in the second scale will be full, as the starting point was in the previous scale, thus no need to subtract anything.
 * The deposit therefore was present for reward events from the beginning of that second scale.
 *
 *        S_i-S_t + S_{i+1}
 *      .<--------.------------>
 *      .         .
 *      . S_i     .   S_{i+1}
 *   <--.-------->.<----------->
 *   S_t.         .
 *   <->.         .
 *      t         .
 *  |---+---------|-------------|-----...
 *         i            i+1
 *
 * The sum of (e_1 + e_2) captures the depositor's total accumulated Collateral amount gain, handling the case where their
 * deposit spanned one scale change. We only care about gains across one scale change, since the compounded
 * deposit is defined as being 0 once it has spanned more than one scale change.
 *
 *
 * --- UPDATING P WHEN A LIQUIDATION OCCURS ---
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / Collateral amount gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 *
 * --- Gravita ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An Gravita issuance event occurs at every deposit operation, and every liquidation.
 *
 * All deposits earn a share of the issued Gravita in proportion to the deposit as a share of total deposits.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#lqty-issuance-to-stability-providers
 *
 * We use the same mathematical product-sum approach to track Gravita gains for depositors, where 'G' is the sum corresponding to Gravita gains.
 * The product P (and snapshot P_t) is re-used, as the ratio P/P_t tracks a deposit's depletion due to liquidations.
 *
 */
contract StabilityPool is ReentrancyGuardUpgradeable, UUPSUpgradeable, GravitaBase, IStabilityPool {
	using SafeERC20Upgradeable for IERC20Upgradeable;

	string public constant NAME = "StabilityPool";

	// Tracker for debtToken held in the pool. Changes when users deposit/withdraw, and when Vessel debt is offset.
	uint256 internal totalDebtTokenDeposits;

	// totalColl.tokens and totalColl.amounts should be the same length and
	// always be the same length as IAdminContract(adminContract).validCollaterals().
	// Anytime a new collateral is added to AdminContract, both lists are lengthened
	Colls internal totalColl;

	mapping(address => uint256) public deposits; // depositor address -> deposit amount

	/*
	 * depositSnapshots maintains an entry for each depositor
	 * that tracks P, S, G, scale, and epoch.
	 * depositor's snapshot is updated only when they
	 * deposit or withdraw from stability pool
	 * depositSnapshots are used to allocate GRVT rewards, calculate compoundedDepositAmount
	 * and to calculate how much Collateral amount the depositor is entitled to
	 */
	mapping(address => Snapshots) public depositSnapshots; // depositor address -> snapshots struct

	/*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
	 * after a series of liquidations have occurred, each of which cancel some debt tokens debt with the deposit.
	 *
	 * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
	 * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
	 */
	uint256 public P;

	uint256 public constant SCALE_FACTOR = 1e9;

	// Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
	uint128 public currentScale;

	// With each offset that fully empties the Pool, the epoch is incremented by 1
	uint128 public currentEpoch;

	/* Collateral amount Gain sum 'S': During its lifetime, each deposit d_t earns an Collateral amount gain of ( d_t * [S - S_t] )/P_t,
	 * where S_t is the depositor's snapshot of S taken at the time t when the deposit was made.
	 *
	 * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
	 *
	 * - The inner mapping records the (scale => sum)
	 * - The middle mapping records (epoch => (scale => sum))
	 * - The outer mapping records (collateralType => (epoch => (scale => sum)))
	 */
	mapping(address => mapping(uint128 => mapping(uint128 => uint256))) public epochToScaleToSum;

	/*
	 * Similarly, the sum 'G' is used to calculate GRVT gains. During it's lifetime, each deposit d_t earns a GRVT gain of
	 *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
	 *
	 *  GRVT reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
	 *  In each case, the GRVT reward is issued (i.e. G is updated), before other state changes are made.
	 */
	mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;

	// Error tracker for the error correction in the GRVT issuance calculation
	uint256 public lastGRVTError;
	// Error trackers for the error correction in the offset calculation
	uint256[] public lastAssetError_Offset;
	uint256 public lastDebtTokenLossError_Offset;

	// --- Initializer ---

	function initialize() public initializer {
		__Ownable_init();
		__ReentrancyGuard_init();
		__UUPSUpgradeable_init();
		P = DECIMAL_PRECISION;
	}

	/**
	 * @notice add a collateral
	 * @dev should be called anytime a collateral is added to controller
	 * keeps all arrays the correct length
	 * @param _collateral address of collateral to add
	 */
	function addCollateralType(address _collateral) external onlyAdminContract {
		lastAssetError_Offset.push(0);
		totalColl.tokens.push(_collateral);
		totalColl.amounts.push(0);
	}

	/**
	 * @notice get collateral balance in the SP for a given collateral type
	 * @dev Not necessarily this contract's actual collateral balance;
	 * just what is stored in state
	 * @param _collateral address of the collateral to get amount of
	 * @return amount of this specific collateral
	 */
	function getCollateral(address _collateral) external view returns (uint256) {
		uint256 collateralIndex = IAdminContract(adminContract).getIndex(_collateral);
		return totalColl.amounts[collateralIndex];
	}

	/**
	 * @notice getter function
	 * @dev gets collateral from totalColl
	 * This is not necessarily the contract's actual collateral balance;
	 * just what is stored in state
	 * @return tokens and amounts
	 */
	function getAllCollateral() external view returns (address[] memory, uint256[] memory) {
		return (totalColl.tokens, totalColl.amounts);
	}

	/**
	 * @notice getter function
	 * @dev gets total debtToken from deposits
	 * @return totalDebtTokenDeposits
	 */
	function getTotalDebtTokenDeposits() external view override returns (uint256) {
		return totalDebtTokenDeposits;
	}

	// --- External Depositor Functions ---

	/**
	 * @notice Used to provide debt tokens to the stability Pool
	 * @dev Triggers a GRVT issuance, based on time passed since the last issuance.
	 * The GRVT issuance is shared between *all* depositors
	 * - Sends depositor's accumulated gains (GRVT, collateral assets) to depositor
	 * - Increases deposit stake, and takes new snapshots for each.
	 * @param _amount amount of debtToken provided
	 * @param _assets an array of collaterals to be claimed. 
	 * Skipping a collateral forfeits the available rewards (can be useful for gas optimizations)
	 */
	function provideToSP(uint256 _amount, address[] calldata _assets) external override nonReentrant {
		_requireNonZeroAmount(_amount);

		uint256 initialDeposit = deposits[msg.sender];

		_triggerGRVTIssuance();

		(address[] memory gainAssets, uint256[] memory gainAmounts) = getDepositorGains(msg.sender, _assets);
		uint256 compoundedDeposit = getCompoundedDebtTokenDeposits(msg.sender);
		uint256 loss = initialDeposit - compoundedDeposit; // Needed only for event log

		// First pay out any GRVT gains
		_payOutGRVTGains(msg.sender);

		// just pulls debtTokens into the pool, updates totalDeposits variable for the stability pool and throws an event
		_sendToStabilityPool(msg.sender, _amount);

		uint256 newDeposit = compoundedDeposit + _amount;
		_updateDepositAndSnapshots(msg.sender, newDeposit);
		emit UserDepositChanged(msg.sender, newDeposit);

		emit GainsWithdrawn(msg.sender, gainAssets, gainAmounts, loss); // loss required for event log

		// send any collateral gains accrued to the depositor
		_sendGainsToDepositor(msg.sender, gainAssets, gainAmounts);
	}
	/** 
	* @param _amount amount of debtToken to withdraw
	* @param _assets an array of collaterals to be claimed. 
	*/

	function withdrawFromSP(uint256 _amount, address[] calldata _assets) external {
		(address[] memory assets, uint256[] memory amounts) = _withdrawFromSP(_amount, _assets);
		_sendGainsToDepositor(msg.sender, assets, amounts);
	}

	/**
	 * @notice withdraw from the stability pool
	 * @param _amount debtToken amount to withdraw
	 * @param _assets an array of collaterals to be claimed. 
	 * @return assets address of assets withdrawn, amount of asset withdrawn
	 */
	function _withdrawFromSP(
		uint256 _amount,
		address[] calldata _assets
	) internal returns (address[] memory assets, uint256[] memory amounts) {
		uint256 initialDeposit = deposits[msg.sender];
		_requireUserHasDeposit(initialDeposit);

		_triggerGRVTIssuance();

		(assets, amounts) = getDepositorGains(msg.sender, _assets);

		uint256 compoundedDeposit = getCompoundedDebtTokenDeposits(msg.sender);

		uint256 debtTokensToWithdraw = GravitaMath._min(_amount, compoundedDeposit);
		uint256 loss = initialDeposit - compoundedDeposit; // Needed only for event log

		// First pay out any GRVT gains
		_payOutGRVTGains(msg.sender);
		_sendToDepositor(msg.sender, debtTokensToWithdraw);

		// Update deposit
		uint256 newDeposit = compoundedDeposit - debtTokensToWithdraw;
		_updateDepositAndSnapshots(msg.sender, newDeposit);
		emit UserDepositChanged(msg.sender, newDeposit);

		emit GainsWithdrawn(msg.sender, assets, amounts, loss); // loss required for event log
	}

	// --- GRVT issuance functions ---

	function _triggerGRVTIssuance() internal {
		if (communityIssuance != address(0)) {
			uint256 GRVTIssuance = ICommunityIssuance(communityIssuance).issueGRVT();
			_updateG(GRVTIssuance);
		}
	}

	function _updateG(uint256 _GRVTIssuance) internal {
		uint256 cachedTotalDebtTokenDeposits = totalDebtTokenDeposits; // cached to save an SLOAD
		/*
		 * When total deposits is 0, G is not updated. In this case, the GRVT issued can not be obtained by later
		 * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
		 *
		 */
		if (cachedTotalDebtTokenDeposits == 0 || _GRVTIssuance == 0) {
			return;
		}
		uint256 GRVTPerUnitStaked = _computeGRVTPerUnitStaked(_GRVTIssuance, cachedTotalDebtTokenDeposits);
		uint256 marginalGRVTGain = GRVTPerUnitStaked * P;
		uint256 newEpochToScaleToG = epochToScaleToG[currentEpoch][currentScale];
		newEpochToScaleToG += marginalGRVTGain;
		epochToScaleToG[currentEpoch][currentScale] = newEpochToScaleToG;
		emit G_Updated(newEpochToScaleToG, currentEpoch, currentScale);
	}

	function _computeGRVTPerUnitStaked(uint256 _GRVTIssuance, uint256 _totalDeposits) internal returns (uint256) {
		/*
		 * Calculate the GRVT-per-unit staked.  Division uses a "feedback" error correction, to keep the
		 * cumulative error low in the running total G:
		 *
		 * 1) Form a numerator which compensates for the floor division error that occurred the last time this
		 * function was called.
		 * 2) Calculate "per-unit-staked" ratio.
		 * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
		 * 4) Store this error for use in the next correction when this function is called.
		 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
		 */
		uint256 GRVTNumerator = (_GRVTIssuance * DECIMAL_PRECISION) + lastGRVTError;
		uint256 GRVTPerUnitStaked = GRVTNumerator / _totalDeposits;
		lastGRVTError = GRVTNumerator - (GRVTPerUnitStaked * _totalDeposits);
		return GRVTPerUnitStaked;
	}

	// --- Liquidation functions ---

	/**
	 * @notice sets the offset for liquidation
	 * @dev Cancels out the specified debt against the debtTokens contained in the Stability Pool (as far as possible)
	 * and transfers the Vessel's collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the VesselManager.
	 * @param _debtToOffset how much debt to offset
	 * @param _asset token address
	 * @param _amountAdded token amount as uint256
	 */
	function offset(uint256 _debtToOffset, address _asset, uint256 _amountAdded) external onlyVesselManager {
		uint256 cachedTotalDebtTokenDeposits = totalDebtTokenDeposits; // cached to save an SLOAD
		if (cachedTotalDebtTokenDeposits == 0 || _debtToOffset == 0) {
			return;
		}
		_triggerGRVTIssuance();
		(uint256 collGainPerUnitStaked, uint256 debtLossPerUnitStaked) = _computeRewardsPerUnitStaked(
			_asset,
			_amountAdded,
			_debtToOffset,
			cachedTotalDebtTokenDeposits
		);

		_updateRewardSumAndProduct(_asset, collGainPerUnitStaked, debtLossPerUnitStaked); // updates S and P
		_moveOffsetCollAndDebt(_asset, _amountAdded, _debtToOffset);
	}

	// --- Offset helper functions ---

	/**
	 * @notice Compute the debtToken and Collateral amount rewards. Uses a "feedback" error correction, to keep
	 * the cumulative error in the P and S state variables low:
	 *
	 * @dev 1) Form numerators which compensate for the floor division errors that occurred the last time this
	 * function was called.
	 * 2) Calculate "per-unit-staked" ratios.
	 * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
	 * 4) Store these errors for use in the next correction when this function is called.
	 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
	 * @param _asset Address of token
	 * @param _amountAdded amount as uint256
	 * @param _debtToOffset amount of debt to offset
	 * @param _totalDeposits How much user has deposited
	 */
	function _computeRewardsPerUnitStaked(
		address _asset,
		uint256 _amountAdded,
		uint256 _debtToOffset,
		uint256 _totalDeposits
	) internal returns (uint256 collGainPerUnitStaked, uint256 debtLossPerUnitStaked) {
		uint256 assetIndex = IAdminContract(adminContract).getIndex(_asset);
		uint256 collateralNumerator = (_amountAdded * DECIMAL_PRECISION) + lastAssetError_Offset[assetIndex];
		require(_debtToOffset <= _totalDeposits, "StabilityPool: Debt is larger than totalDeposits");
		if (_debtToOffset == _totalDeposits) {
			debtLossPerUnitStaked = DECIMAL_PRECISION; // When the Pool depletes to 0, so does each deposit
			lastDebtTokenLossError_Offset = 0;
		} else {
			uint256 lossNumerator = (_debtToOffset * DECIMAL_PRECISION) - lastDebtTokenLossError_Offset;
			/*
			 * Add 1 to make error in quotient positive. We want "slightly too much" loss,
			 * which ensures the error in any given compoundedDeposit favors the Stability Pool.
			 */
			debtLossPerUnitStaked = (lossNumerator / _totalDeposits) + 1;
			lastDebtTokenLossError_Offset = (debtLossPerUnitStaked * _totalDeposits) - lossNumerator;
		}
		collGainPerUnitStaked = collateralNumerator / _totalDeposits;
		lastAssetError_Offset[assetIndex] = collateralNumerator - (collGainPerUnitStaked * _totalDeposits);
	}

	function _updateRewardSumAndProduct(
		address _asset,
		uint256 _collGainPerUnitStaked,
		uint256 _debtLossPerUnitStaked
	) internal {
		require(_debtLossPerUnitStaked <= DECIMAL_PRECISION, "StabilityPool: Loss < 1");
		uint256 currentP = P;
		uint256 newP;

		/*
		 * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool debt tokens in the liquidation.
		 * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - _debtLossPerUnitStaked)
		 */
		uint256 newProductFactor = DECIMAL_PRECISION - _debtLossPerUnitStaked;
		uint128 currentScaleCached = currentScale;
		uint128 currentEpochCached = currentEpoch;
		uint256 currentS = epochToScaleToSum[_asset][currentEpochCached][currentScaleCached];

		/*
		 * Calculate the new S first, before we update P.
		 * The asset gain for any given depositor from a liquidation depends on the value of their deposit
		 * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
		 *
		 * Since S corresponds to asset gain, and P to deposit loss, we update S first.
		 */
		uint256 marginalAssetGain = _collGainPerUnitStaked * currentP;
		uint256 newS = currentS + marginalAssetGain;
		epochToScaleToSum[_asset][currentEpochCached][currentScaleCached] = newS;
		emit S_Updated(_asset, newS, currentEpochCached, currentScaleCached);

		// If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
		if (newProductFactor == 0) {
			currentEpochCached += 1;
			currentEpoch = currentEpochCached;
			emit EpochUpdated(currentEpochCached);
			currentScale = 0;
			emit ScaleUpdated(0);
			newP = DECIMAL_PRECISION;

			// If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
		} else {
			uint256 mulCached = currentP * newProductFactor;
			uint256 mulDivCached = mulCached / DECIMAL_PRECISION;

			if (mulDivCached < SCALE_FACTOR) {
				newP = (mulCached * SCALE_FACTOR) / DECIMAL_PRECISION;
				currentScaleCached += 1;
				currentScale = currentScaleCached;
				emit ScaleUpdated(currentScaleCached);
			} else {
				newP = mulDivCached;
			}
		}

		require(newP != 0, "StabilityPool: P = 0");
		P = newP;
		emit P_Updated(newP);
	}

	/**
	 * @notice Internal function to move offset collateral and debt between pools.
	 * @dev Cancel the liquidated debtToken debt with the debtTokens in the stability pool,
	 * Burn the debt that was successfully offset. Collateral is moved from
	 * the ActivePool to this contract.
	 * @param _asset collateral address
	 * @param _amount amount as uint256
	 * @param _debtToOffset uint256
	 */
	function _moveOffsetCollAndDebt(address _asset, uint256 _amount, uint256 _debtToOffset) internal {
		IActivePool(activePool).decreaseDebt(_asset, _debtToOffset);
		_decreaseDebtTokens(_debtToOffset);
		IDebtToken(debtToken).burn(address(this), _debtToOffset);
		IActivePool(activePool).sendAsset(_asset, address(this), _amount);
	}

	function _decreaseDebtTokens(uint256 _amount) internal {
		uint256 newTotalDeposits = totalDebtTokenDeposits - _amount;
		totalDebtTokenDeposits = newTotalDeposits;
		emit StabilityPoolDebtTokenBalanceUpdated(newTotalDeposits);
	}

	// --- Reward calculator functions for depositor ---

	/**
	 * @notice Calculates the gains earned by the deposit since its last snapshots were taken for selected assets.
	 * @dev Given by the formula:  E = d0 * (S - S(0))/P(0)
	 * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
	 * d0 is the last recorded deposit value.
	 * @param _depositor address of depositor in question
	 * @param _assets array of assets to check gains for
	 * @return assets, amounts
	 */
	function getDepositorGains(
		address _depositor,
		address[] memory _assets
	) public view returns (address[] memory, uint256[] memory) {
		uint256 initialDeposit = deposits[_depositor];

		if (initialDeposit == 0) {
			address[] memory emptyAddress = new address[](0);
			uint256[] memory emptyUint = new uint256[](0);
			return (emptyAddress, emptyUint);
		}

		Snapshots storage snapshots = depositSnapshots[_depositor];

		uint256[] memory amountsFromNewGains = _calculateNewGains(initialDeposit, snapshots, _assets);
		return (_assets, amountsFromNewGains);
	}

	/**
	 * @notice Calculates all the gains earned by the deposit since its last snapshots were taken.
	 * @param _depositor address of depositor in question
	 * @return assets, amounts
	 */
	function getDepositorGains(address _depositor) internal view returns (address[] memory, uint256[] memory) {
		return getDepositorGains(_depositor, IAdminContract(adminContract).getValidCollateral());
	}

	/**
	 * @notice get gains on each possible asset by looping through
	 * @dev assets with _getGainFromSnapshots function
	 * @param initialDeposit Amount of initial deposit
	 * @param snapshots struct snapshots
	 */
	function _calculateNewGains(
		uint256 initialDeposit,
		Snapshots storage snapshots,
		address[] memory _assets
	) internal view returns (uint256[] memory amounts) {
		uint256 assetsLen = _assets.length;
		// revert if there is a duplicate on the array
		unchecked {
			for (uint256 i = 0; i < assetsLen; i++) {
				for (uint256 j = i + 1; j < assetsLen; j++) {
					if (_assets[i] == _assets[j]) {
						revert StabilityPool__DuplicateElementOnArray();
					}
				}
			}
		}
		amounts = new uint256[](assetsLen);
		for (uint256 i = 0; i < assetsLen; ) {
			amounts[i] = _getGainFromSnapshots(initialDeposit, snapshots, _assets[i]);
			unchecked {
				i++;
			}
		}
	}

	/**
	 * @notice gets the gain in S for a given asset
	 * @dev for a user who deposited initialDeposit
	 * @param initialDeposit Amount of initialDeposit
	 * @param snapshots struct snapshots
	 * @param asset asset to gain snapshot
	 * @return uint256 the gain
	 */
	function _getGainFromSnapshots(
		uint256 initialDeposit,
		Snapshots storage snapshots,
		address asset
	) internal view returns (uint256) {
		/*
		 * Grab the sum 'S' from the epoch at which the stake was made. The Collateral amount gain may span up to one scale change.
		 * If it does, the second portion of the Collateral amount gain is scaled by 1e9.
		 * If the gain spans no scale change, the second portion will be 0.
		 */
		uint256 S_Snapshot = snapshots.S[asset];
		uint256 P_Snapshot = snapshots.P;

		mapping(uint128 => uint256) storage scaleToSum = epochToScaleToSum[asset][snapshots.epoch];
		uint256 firstPortion = scaleToSum[snapshots.scale] - S_Snapshot;
		uint256 secondPortion = scaleToSum[snapshots.scale + 1] / SCALE_FACTOR;

		uint256 assetGain = (initialDeposit * (firstPortion + secondPortion)) / P_Snapshot / DECIMAL_PRECISION;

		return assetGain;
	}

	/*
	 * Calculate the GRVT gain earned by a deposit since its last snapshots were taken.
	 * Given by the formula:  GRVT = d0 * (G - G(0))/P(0)
	 * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
	 * d0 is the last recorded deposit value.
	 */
	function getDepositorGRVTGain(address _depositor) public view override returns (uint256) {
		uint256 initialDeposit = deposits[_depositor];
		if (initialDeposit == 0) {
			return 0;
		}

		Snapshots storage snapshots = depositSnapshots[_depositor];
		return _getGRVTGainFromSnapshots(initialDeposit, snapshots);
	}

	function _getGRVTGainFromSnapshots(
		uint256 initialStake,
		Snapshots storage snapshots
	) internal view returns (uint256) {
		/*
		 * Grab the sum 'G' from the epoch at which the stake was made. The GRVT gain may span up to one scale change.
		 * If it does, the second portion of the GRVT gain is scaled by 1e9.
		 * If the gain spans no scale change, the second portion will be 0.
		 */
		uint128 epochSnapshot = snapshots.epoch;
		uint128 scaleSnapshot = snapshots.scale;
		uint256 G_Snapshot = snapshots.G;
		uint256 P_Snapshot = snapshots.P;

		uint256 firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot] - G_Snapshot;
		uint256 secondPortion = epochToScaleToG[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

		uint256 GRVTGain = (initialStake * (firstPortion + secondPortion)) / P_Snapshot / DECIMAL_PRECISION;

		return GRVTGain;
	}

	// --- Compounded deposit and compounded System stake ---

	/*
	 * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
	 * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
	 */
	function getCompoundedDebtTokenDeposits(address _depositor) public view override returns (uint256) {
		uint256 initialDeposit = deposits[_depositor];
		if (initialDeposit == 0) {
			return 0;
		}

		return _getCompoundedStakeFromSnapshots(initialDeposit, depositSnapshots[_depositor]);
	}

	// Internal function, used to calculate compounded deposits and compounded stakes.
	function _getCompoundedStakeFromSnapshots(
		uint256 initialStake,
		Snapshots storage snapshots
	) internal view returns (uint256) {
		uint256 snapshot_P = snapshots.P;
		uint128 scaleSnapshot = snapshots.scale;
		uint128 epochSnapshot = snapshots.epoch;

		// If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
		if (epochSnapshot < currentEpoch) {
			return 0;
		}

		uint256 compoundedStake;
		uint128 scaleDiff = currentScale - scaleSnapshot;

		/* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
		 * account for it. If more than one scale change was made, then the stake has decreased by a factor of
		 * at least 1e-9 -- so return 0.
		 */
		if (scaleDiff == 0) {
			compoundedStake = (initialStake * P) / snapshot_P;
		} else if (scaleDiff == 1) {
			compoundedStake = (initialStake * P) / snapshot_P / SCALE_FACTOR;
		} else {
			compoundedStake = 0;
		}

		/*
		 * If compounded deposit is less than a billionth of the initial deposit, return 0.
		 *
		 * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
		 * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
		 * than it's theoretical value.
		 *
		 * Thus it's unclear whether this line is still really needed.
		 */
		if (compoundedStake < initialStake / 1e9) {
			return 0;
		}

		return compoundedStake;
	}

	// --- Sender functions for debtToken deposits

	// Transfer the tokens from the user to the Stability Pool's address, and update its recorded deposits
	function _sendToStabilityPool(address _address, uint256 _amount) internal {
		IDebtToken(debtToken).sendToPool(_address, address(this), _amount);
		uint256 newTotalDeposits = totalDebtTokenDeposits + _amount;
		totalDebtTokenDeposits = newTotalDeposits;
		emit StabilityPoolDebtTokenBalanceUpdated(newTotalDeposits);
	}

	/**
	 * @notice transfer collateral gains to the depositor
	 * @dev this function also unwraps wrapped assets
	 * before sending to depositor
	 * @param _to address
	 * @param assets array of address
	 * @param amounts array of uint256. Includes pending collaterals since that was added in previous steps
	 */
	function _sendGainsToDepositor(address _to, address[] memory assets, uint256[] memory amounts) internal {
		uint256 assetsLen = assets.length;
		require(assetsLen == amounts.length, "StabilityPool: Length mismatch");
		for (uint256 i = 0; i < assetsLen; ) {
			uint256 amount = amounts[i];
			if (amount == 0) {
				unchecked {
					i++;
				}
				continue;
			}
			address asset = assets[i];
			// Assumes we're internally working only with the wrapped version of ERC20 tokens
			IERC20Upgradeable(asset).safeTransfer(_to, amount);
			unchecked {
				i++;
			}
		}
		totalColl.amounts = _leftSubColls(totalColl, assets, amounts);
	}

	// Send debt tokens to user and decrease deposits in Pool
	function _sendToDepositor(address _depositor, uint256 debtTokenWithdrawal) internal {
		if (debtTokenWithdrawal == 0) {
			return;
		}
		IDebtToken(debtToken).returnFromPool(address(this), _depositor, debtTokenWithdrawal);
		_decreaseDebtTokens(debtTokenWithdrawal);
	}

	// --- Stability Pool Deposit Functionality ---

	/**
	 * @notice updates deposit and snapshots internally
	 * @dev if _newValue is zero, delete snapshot for given _depositor and emit event
	 * otherwise, add an entry or update existing entry for _depositor in the depositSnapshots
	 * with current values for P, S, G, scale and epoch and then emit event.
	 * @param _depositor address
	 * @param _newValue uint256
	 */
	function _updateDepositAndSnapshots(address _depositor, uint256 _newValue) internal {
		deposits[_depositor] = _newValue;
		address[] memory colls = IAdminContract(adminContract).getValidCollateral();
		uint256 collsLen = colls.length;

		Snapshots storage depositorSnapshots = depositSnapshots[_depositor];
		if (_newValue == 0) {
			for (uint256 i = 0; i < collsLen; ) {
				depositSnapshots[_depositor].S[colls[i]] = 0;
				unchecked {
					i++;
				}
			}
			depositorSnapshots.P = 0;
			depositorSnapshots.G = 0;
			depositorSnapshots.epoch = 0;
			depositorSnapshots.scale = 0;
			emit DepositSnapshotUpdated(_depositor, 0, 0);
			return;
		}
		uint128 currentScaleCached = currentScale;
		uint128 currentEpochCached = currentEpoch;
		uint256 currentP = P;

		for (uint256 i = 0; i < collsLen; ) {
			address asset = colls[i];
			uint256 currentS = epochToScaleToSum[asset][currentEpochCached][currentScaleCached];
			depositSnapshots[_depositor].S[asset] = currentS;
			unchecked {
				i++;
			}
		}

		uint256 currentG = epochToScaleToG[currentEpochCached][currentScaleCached];
		depositorSnapshots.P = currentP;
		depositorSnapshots.G = currentG;
		depositorSnapshots.scale = currentScaleCached;
		depositorSnapshots.epoch = currentEpochCached;

		emit DepositSnapshotUpdated(_depositor, currentP, currentG);
	}

	function S(address _depositor, address _asset) external view returns (uint256) {
		return depositSnapshots[_depositor].S[_asset];
	}

	function _payOutGRVTGains(address _depositor) internal {
		if (address(communityIssuance) != address(0)) {
			uint256 depositorGRVTGain = getDepositorGRVTGain(_depositor);
			ICommunityIssuance(communityIssuance).sendGRVT(_depositor, depositorGRVTGain);
			emit GRVTPaidToDepositor(_depositor, depositorGRVTGain);
		}
	}

	function _leftSubColls(
		Colls memory _coll1,
		address[] memory _tokens,
		uint256[] memory _amounts
	) internal pure returns (uint256[] memory) {
		uint256 coll1Len = _coll1.amounts.length;
		uint256 tokensLen = _tokens.length;

		for (uint256 i = 0; i < coll1Len; ) {
			for (uint256 j = 0; j < tokensLen; ) {
				if (_coll1.tokens[i] == _tokens[j]) {
					_coll1.amounts[i] -= _amounts[j];
				}
				unchecked {
					j++;
				}
			}
			unchecked {
				i++;
			}
		}

		return _coll1.amounts;
	}

	function _requireUserHasDeposit(uint256 _initialDeposit) internal pure {
		require(_initialDeposit != 0, "StabilityPool: User must have a non-zero deposit");
	}

	function _requireNonZeroAmount(uint256 _amount) internal pure {
		require(_amount != 0, "StabilityPool: Amount must be non-zero");
	}

	// --- Modifiers ---

	modifier onlyAdminContract() {
		if (msg.sender != adminContract) {
			revert StabilityPool__AdminContractOnly(msg.sender, adminContract);
		}
		_;
	}

	modifier onlyActivePool() {
		if (msg.sender != activePool) {
			revert StabilityPool__ActivePoolOnly(msg.sender, activePool);
		}
		_;
	}

	modifier onlyVesselManager() {
		if (msg.sender != vesselManager) {
			revert StabilityPool__VesselManagerOnly(msg.sender, vesselManager);
		}
		_;
	}

	// --- Fallback function ---

	function receivedERC20(address _asset, uint256 _amount) external override onlyActivePool {
		uint256 collateralIndex = IAdminContract(adminContract).getIndex(_asset);
		uint256 newAssetBalance = totalColl.amounts[collateralIndex] + _amount;
		totalColl.amounts[collateralIndex] = newAssetBalance;
		emit StabilityPoolAssetBalanceUpdated(_asset, newAssetBalance);
	}

	function authorizeUpgrade(address newImplementation) public {
		_authorizeUpgrade(newImplementation);
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}
}