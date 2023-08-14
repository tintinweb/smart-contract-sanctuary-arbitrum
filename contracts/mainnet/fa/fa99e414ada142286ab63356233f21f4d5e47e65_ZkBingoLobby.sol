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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
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
abstract contract ERC1967UpgradeUpgradeable is Initializable {
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
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

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
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

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
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ZKGame/IBingoCard.sol";
import "./ZKGame/IBingoRoom.sol";
import "./ZKGame/ICashman.sol";
import "./ZKGame/IGameLineup.sol";
import "./ZKGame/IUserCenter.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBingoCard {
    event Revealed(
        uint256 indexed cardId,
        address indexed revealer,
        address indexed signer,
        uint8[][] numbers
    );

    /** @notice Number of rows of the card */
    function rows() external view returns (uint8);

    /** @notice Number of columns of the card */
    function columns() external view returns (uint8);

    /**
     * @notice Number picking-restrictions of each space
     * @dev row -> col -> [min,max] (0: no restrictions)
     */
    function restrictions() external view returns (uint8[2][][] memory);

    /** @dev Line: [rowIndex, colIndex][] (uint8[2][]) */
    function lines() external view returns (uint8[2][][] memory);

    /** @dev [rowIndex, colIndex][] */
    function freeSpaces() external view returns (uint8[2][] memory);

    function getCardGame(
        uint256 cardId
    ) external view returns (
        address gameContract,
        uint256 gameId
    );

    function getCardNumbers(
        uint256 cardId
    ) external view returns(uint8[][] memory cardNumbers);

    function matchedLines(
        uint256 cardId
    ) external view returns (uint8 lineCount);

    function calculateMatchedLineCounts(
        uint8[][] memory cardNumbers,
        uint256 encodedSelectNumbers
    ) external view returns  (uint8 lineCount);

    function estimateMatchedLines(
        uint8[][] memory cardNumbers,
        uint8[] memory selectedNumbers
    ) external view returns (uint8 lineCounts);

    function reveal(
        uint256 cardId,
        bytes calldata gameLabel,
        bytes calldata signedGameLabel,
        uint8[][] calldata cardNumbers
    ) external;

    /*
    ██    ██ ████████ ██ ██      ███████
    ██    ██    ██    ██ ██      ██      - encode/decode card numbers
    ██    ██    ██    ██ ██      ███████ - encode/decode marked spaces
    ██    ██    ██    ██ ██           ██ - verify signer tester
     ██████     ██    ██ ███████ ███████ - encode selected numbers helper
    */

    function encodeCardNumbers(
        uint8[][] calldata cardNumbers
    ) external view returns (bytes memory encodedCardNumbers);

    function decodeCardNumbers(
        bytes memory encodedCardNumbers
    ) external view returns (uint8[][] memory cardNumbers);

    /** @dev [rowIndex, colIndex][] */
    function encodeMarkedSpaces(
        uint8[2][] calldata markedSpaces
    ) external view returns (uint256 encodedMarkedSpaces);

    function decodeMarkedSpaces(
        uint256 encodedMarkedSpaces
    ) external view returns (uint8[2][] memory markedSpaces);

    function verifySigner(
        uint256 cardId,
        bytes memory salt,
        uint8[][] memory cardNumbers,
        address signer
    ) external view returns (bool);

    function encodeSelectedNumbers(
        uint8[] calldata selectedNumbers
    ) external pure returns (uint256 encodedSelectedNumbers);

    function decodeSelectedNumbers(
        uint256 encodedSelectedNumbers
    ) external pure returns (uint8[] memory selectedNumbers);

    /*
     █████  ██████  ███    ███ ██ ███    ██
    ██   ██ ██   ██ ████  ████ ██ ████   ██
    ███████ ██   ██ ██ ████ ██ ██ ██ ██  ██ - bind card to game
    ██   ██ ██   ██ ██  ██  ██ ██ ██  ██ ██ - set valid lines
    ██   ██ ██████  ██      ██ ██ ██   ████ - set free spaces
    */

    function mint(
        address to,
        uint256 gameId,
        bytes calldata encryptedContent
    ) external returns (uint256 cardId);

    function editUnplayedCard(
        uint256 cardId,
        bytes calldata encryptedContent
    ) external;

    function bindCardGame(
        uint256 cardId,
        address gameContract,
        uint256 gameId
    ) external;

    /*
     ██████  ██     ██ ███    ██ ███████ ██████
    ██    ██ ██     ██ ████   ██ ██      ██   ██
    ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
    ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
     ██████   ███ ███  ██   ████ ███████ ██   ██
    */

    function setRestrictions(uint8[2][][] calldata spaceNumberRestrictions) external;
    function setLines(uint8[2][][] calldata validLines) external;
    function setFreeSpaces(uint8[2][] calldata freeSpacePositions) external;
    function setBindingGame(address gameAddress) external;
    function addMinter(address minter) external;
    function removeMinter(address minter) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBingoRoom {
    struct Participant {
        address user;
        uint256 cardId;
    }

    struct GameRound {
        uint32 round;
        uint8 number;
        uint32 timestamp;
        address player;
    }

    enum RecentGameFilter {
        // 0
        ALL,
        // 1
        LIVE,
        // 2
        FINISHED
    }

    event GameStarted(
        uint256 indexed gameId,
        address cardContract,
        address[] players
    );

    event GameParticipated(
        uint256 indexed gameId,
        address indexed player,
        uint256 indexed cardId,
        uint8 position
    );

    event NumberSelected(
        uint256 indexed gameId,
        uint32 round,
        address indexed player,
        uint8 number
    );

    event Bingo(
        uint256 indexed gameId,
        address indexed player,
        uint8[][] playerCardNumbers
    );

    event RewardChanged(
        address indexed newReward,
        address indexed oldReward
    );

    event GameHalted(
        uint256 indexed gameId,
        address indexed user,
        bool isOvertime
    );

    function gameCard() external view returns (address);

    function expectedLines() external view returns (uint8);

    function fee() external view returns (uint256 value, uint256 deno);

    function getGameInfo(
        uint256 gameId
    ) external view returns (
        uint32 startedAt,
        uint32 endedAt,
        address winner,
        Participant[] memory players,
        GameRound[] memory rounds,
        string memory status
    );

    function getCurrentRound(uint256 gameId) external view returns (
        uint32 round,
        address player,
        uint32 remain,
        string memory status
    );

    function getSelectedNumbers(
        uint256 gameId
    ) external view returns (uint8[] memory);

    function selectNumber(
        uint256 gameId,
        uint8 number
    ) external;

    function bingo(
        uint256 gameId,
        uint8[][] calldata cardNumbers,
        bytes calldata signedLabel
    ) external;

    function selectAndBingo(
        uint256 gameId,
        uint8 number,
        uint8[][] calldata cardNumbers,
        bytes calldata signedLabel
    ) external;

    /**
     * @dev Call this function by callStatic to check if a game is ongoing and
     *      check if cached card content is available
     */
    function restoreGame(
        address player,
        uint8[][] memory cardNumbers,
        bytes memory signedGameLabel
    ) external returns (
        uint256 playingGameId,
        uint32 autoEndTime,
        bool isCardContentMatched
    );

    /*
    ██       ██████   ██████  ███████
    ██      ██    ██ ██       ██
    ██      ██    ██ ██   ███ ███████ - recentGames: all games
    ██      ██    ██ ██    ██      ██ - playedGames: player's games
    ███████  ██████   ██████  ███████ - summary: total games, players, rewards
    */

    struct RecentGame {
        uint256 gameId;
        string status;
        address winner;
        uint8[][] cardNumbers;
        uint8[] selectedNumbers;
        Participant[] players;
    }

    function recentGames(RecentGameFilter filter) external view returns (
        RecentGame[] memory games
    );

    function playedGames(address player, uint256 skip) external view returns (
        RecentGame[] memory games
    );

   /**
    * @return totalGameStarted - total games started
    * @return totalPlayersJoined - total players joined
    * @return totalRewardDistributed - total reward(NFTs) distributed
    */
    function summary() external view returns (
        uint256 totalGameStarted,
        uint256 totalPlayersJoined,
        uint256 totalRewardDistributed
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICashman {
    function addMintable(address token) external;
    function removeMintable(address token) external;
    function isMintable(address token) external view returns (bool);

    function transferTo(
        address token,
        address to,
        uint256 amount
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** @dev Deal with line-ups */
interface IGameLineup {
    event LineupJoined(
        address indexed player
    );

    event LineupLeft(
        address indexed player
    );

    function join(bytes calldata zkCard) external;

    function leave() external;

    function start() external;

    function lineupUsers() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserCenter {
    struct GameSeason {
        string title;
        uint256 startedAt;
    }

    struct PlayerStatistics {
        uint256 wins;
        uint256 joined;
    }

    /**
     * @return current - current season statistics
     * @return overall - overall statistics
     */
    function userRecords(address user) external view returns (
        PlayerStatistics memory current,
        PlayerStatistics memory overall
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IBingoCard } from "../interfaces/ZKGame/IBingoCard.sol";
import { IBingoRoom } from "../interfaces/ZKGame/IBingoRoom.sol";

string constant GAME_INVALID = "invalid";
string constant GAME_BINGOED = "end";
string constant GAME_OVERTIME = "overtime";
string constant GAME_ONGOING = "live";

interface Rewardable {
    function mint(address to) external;
}

abstract contract BingoGameRoom is IBingoRoom {
    struct Game {
        uint256 selectedNumbers;
        uint256 winnerCardId;
        address winner;
        uint32 startedAt;
        uint32 endedAt;
    }

    /**
     * @dev
     *   Game Started | startTimeour | boostRounds x roundTimeout | roundGap + roundTimeout | ...
     */
    struct GameTimeout {
        uint32 startTimeout;
        uint8 boostRounds; // no gap between rounds for first N rounds

        uint32 roundGap;
        uint32 roundTimeout;

        uint32 maxDuration;
        // uint120 __gap;
    }
    GameTimeout internal _timer;

    uint8 public constant RECENT_GAME_COUNTS = 20;

    IBingoCard private _gameCard;
    uint8 private _expectedLines;
    uint8 private _minNumber;
    uint8 private _maxNumber;

    /** @dev gameId <= _firstGameId are all ended */
    uint256 private _firstGameId;
    /** @dev game counts that already created */
    uint256 private _lastGameId;
    mapping(uint256 => Game) private _games;
    mapping(uint256 => GameRound[]) private _gameRounds;
    mapping(uint256 => Participant[]) private _gameParticipants;
    mapping(address => uint256[]) private _gamePlayed;


    struct RewardInfo {
        address token; // 20 bytes
        uint32 maxDistribution;
        // uint64 __gap;
    }
    RewardInfo private _reward;
    mapping(address => uint256) private _rewardDistributed;
    uint256 private _totalPlayers;

    /** @dev Update _firstGameId to the closest point of ongoing games */
    modifier autoStopOvertimeGames() {
        bool found = false;
        uint32 autoStopTime = _overtimeGameStart();

        while (_firstGameId < _lastGameId) {
            Game storage firstGame = _games[_firstGameId];

            if (firstGame.endedAt == 0) {
                // Current game not yet marked as ended:

                // 1. Not over the time limit, skip it and stop the loop.
                if (firstGame.startedAt > autoStopTime) break;

                // 2. Over the time limit, but we already change 1 game, stop the loop.
                //    (we should not change too many storage in one transaction)
                if (found) break;
            }

            // Possible firstGame state:
            // 1. Already ended
            // 2. Not ended but overtime

            if (
                firstGame.endedAt == 0 &&
                firstGame.startedAt < autoStopTime
            ) {
                firstGame.endedAt = uint32(block.timestamp);
                found = true;

                emit GameHalted(_firstGameId, msg.sender, true);
            }

            _firstGameId++;
        }

        _;
    }

    modifier onlyOngoingGame(uint256 gameId) {
        require(_isGameOngoing(gameId), "BingoGameRoom: !playing");
        _;
    }

    function initBingoGameRoom(
        address cardContract,
        uint8 expectedLines_,
        uint8 minNumber_,
        uint8 maxNumber_,

        uint32 startTimeout,
        uint8 boostRounds,
        uint32 roundGap,
        uint32 roundTimeout,
        uint32 maxDuration
    ) internal {
        _gameCard = IBingoCard(cardContract);
        _expectedLines = expectedLines_;
        _minNumber = minNumber_;
        _maxNumber = maxNumber_;

        _setGameTimer(
            startTimeout,
            boostRounds,
            roundGap,
            roundTimeout,
            maxDuration
        );
    }

    function gameCard() public view override returns (address) {
        return address(_gameCard);
    }

    function expectedLines() public view override returns (uint8) {
        return _expectedLines;
    }

    function _newGame(address[] memory players) internal autoStopOvertimeGames returns (uint256 gameId) {
        gameId = ++_lastGameId;
        _games[gameId].startedAt = uint32(block.timestamp);

        emit GameStarted(gameId, address(_gameCard), players);
    }

    function _playerLastGameId(address user) internal view returns (uint256 gameId) {
        if (_gamePlayed[user].length > 0) {
            gameId = _gamePlayed[user][_gamePlayed[user].length - 1];
        }
    }

    function _joinGame(uint256 gameId, address user, bytes memory entryptedCard) internal {
        uint256 cardId = _gameCard.mint(user, gameId, entryptedCard);

        _gameParticipants[gameId].push(Participant(user, cardId));
        _gamePlayed[user].push(gameId);
        _totalPlayers++;

        emit GameParticipated(
            gameId,
            user,
            cardId,
            uint8(_gameParticipants[gameId].length)
        );
    }

    function getGameInfo(uint256 gameId) public view override returns (
        uint32 startedAt,
        uint32 endedAt,
        address winner,
        Participant[] memory players,
        GameRound[] memory rounds,
        string memory status
    ) {
        status = GAME_INVALID;
        if (_hasGameRecord(gameId)) {
            startedAt = _games[gameId].startedAt;
            endedAt = _games[gameId].endedAt;

            players = _gameParticipants[gameId];
            rounds = _gameRounds[gameId];

            if (_games[gameId].winner != address(0)) {
                winner = _games[gameId].winner;
                status = GAME_BINGOED;
            } else if (_games[gameId].endedAt > 0 || _games[gameId].startedAt < _overtimeGameStart()) {
                status = GAME_OVERTIME;
            } else {
                status = GAME_ONGOING;
            }
        }
    }

    /**
     * @dev
     *   last round (R0) | Timeout to sync |     R0 + 1      |     R0 + 2      | ...
     *      <lastTime>   |  +ROUND_TIMEOUT | +ROUND_DURATION | +ROUND_DURATION | ...
     */
    function getCurrentRound(
        uint256 gameId
    ) public view override returns (
        uint32 round,
        address player,
        uint32 remain,
        string memory status
    ) {
        require(_hasGameRecord(gameId), "!exists");

        GameRound memory lastRound = getLatestRound(gameId);

        // Game ended, return the last round, and no player can select number.
        if (_games[gameId].winner != address(0)) return (lastRound.round, address(0), 0, GAME_BINGOED);
        if (
            _games[gameId].endedAt > 0 ||
            _games[gameId].startedAt < _overtimeGameStart()
        ) return (lastRound.round, address(0), 0, GAME_OVERTIME);

        // Before 1 round
        if (
            lastRound.round == 0 &&
            _games[gameId].startedAt + _timer.startTimeout > block.timestamp
        ) return (
            0,
            address(0),
            _games[gameId].startedAt + _timer.startTimeout - uint32(block.timestamp),
            GAME_ONGOING
        );

        uint32 r0 = lastRound.round + 1;

        uint256 lastTime = r0 > 1
            ? uint256(lastRound.timestamp)
            : uint256(_games[gameId].startedAt + _timer.startTimeout);

        uint256 timePassed = block.timestamp - lastTime;

        // Selected numbers more than boostRounds, then gap between rounds for Bingo players.
        uint32 gapTime = _gameRounds[gameId].length > _timer.boostRounds
            ? _timer.roundGap
            : 0;

        // Not over the gap time, new round, but no player can select number.
        if (timePassed < gapTime) {
            return (
                r0,
                address(0),
                uint32(gapTime - timePassed) + _timer.roundTimeout,
                GAME_ONGOING
            );
        }

        round = r0 + uint32((timePassed - gapTime) / _timer.roundTimeout);
        remain = _timer.roundTimeout - uint32((timePassed - gapTime) % _timer.roundTimeout);

        player = _getRoundPlayer(gameId, round);

        return (round, player, remain, GAME_ONGOING);
    }

    function getSelectedNumbers(
        uint256 gameId
    ) external view returns (uint8[] memory numbers) {
        if (_hasGameRecord(gameId)) {
            return _gameCard.decodeSelectedNumbers(
                _games[gameId].selectedNumbers
            );
        }
    }

    function getLatestRound(uint256 gameId) public view returns (GameRound memory last) {
        uint256 counts = _gameRounds[gameId].length;

        if (counts > 0) {
            last = _gameRounds[gameId][counts - 1];
        }
    }

    function _getRoundPlayer(uint256 gameId, uint32 round) internal view returns (address) {
        return _getRoundPlayerInOrder(gameId, round);
    }

    function _getRoundPlayerInOrder(uint256 gameId, uint32 round) internal view returns (address) {
        uint256 playerCounts = _gameParticipants[gameId].length;
        return _gameParticipants[gameId][(round - 1) % playerCounts].user;
    }

    /**
     * @dev players.length = N (counts)
     *
     *   player 0 |  player 1 |  ...  |  player N-1
     *   #1 (r=0) -> #2       -> ...  -> #N   (r = N - 1)
     *   #2N                     ... <-  #N+1 (r = N)
     */
    function _getRoundPlayerInZ(uint256 gameId, uint32 round) internal view returns (address) {
        uint256 playerCounts = _gameParticipants[gameId].length;
        uint256 r = (round - 1) % (2 * playerCounts);

        return r >= playerCounts
            ? _gameParticipants[gameId][playerCounts * 2 - r - 1].user
            : _gameParticipants[gameId][r].user;
    }

    function _selectNumber(
        uint256 gameId,
        address player,
        uint8 number
    ) internal {
        require(_isGameOngoing(gameId), "BingoGameRoom: not playing");
        uint8 order = uint8(_gameRounds[gameId].length + 1);
        require(_isSelectableNumber(number, order), "BingoGameRoom: unselectable");

        (
            uint32 round,
            address roundPlayer,
            /* uint32 remain */,
            /* string memory status */
        ) = getCurrentRound(gameId);
        require(player == roundPlayer, "BingoGameRoom: not your turn");

        uint256 selected = _games[gameId].selectedNumbers;

        uint8[] memory nums = new uint8[](1);
        nums[0] = number;

        uint256 toSelect = _gameCard.encodeSelectedNumbers(nums);
        require(selected & toSelect == 0, "BingoGameRoom: already selected");

        _games[gameId].selectedNumbers = selected | toSelect;
        _gameRounds[gameId].push(
            GameRound(
                round,
                number,
                uint32(block.timestamp),
                player
            )
        );
        emit NumberSelected(gameId, round, player, number);
    }

    function _bingo(
        uint256 gameId,
        address player,
        uint8[][] memory numbers,
        bytes memory gameLabel,
        bytes memory signedGameLabel
    ) internal {
        require(_isGameOngoing(gameId), "BingoGameRoom: not playing");

        Participant memory winner;
        for (uint256 i = 0; i < _gameParticipants[gameId].length; i++) {
            if (_gameParticipants[gameId][i].user == player) {
                winner = _gameParticipants[gameId][i];
                break;
            }
        }

        _gameCard.reveal(
            winner.cardId,
            gameLabel,
            signedGameLabel,
            numbers
        );

        require(
            _gameCard.calculateMatchedLineCounts(
                _gameCard.getCardNumbers(winner.cardId),
                _games[gameId].selectedNumbers
            ) >= expectedLines(),
            "BingoGameRoom: Not enough lines"
        );

        _games[gameId].endedAt = uint32(block.timestamp);
        _games[gameId].winner = player;
        _games[gameId].winnerCardId = winner.cardId;

        emit Bingo(gameId, player, numbers);
        _distributeReward(player);
    }

    function _isGameOngoing(uint256 gameId) internal view returns (bool) {
        Game storage game = _games[gameId];
        return game.startedAt > 0
            && game.endedAt == 0
            && game.startedAt > _overtimeGameStart();
    }

    /** @dev game.startedAt > _overtimeGameStart() is suppose to be stopped by the system */
    function _overtimeGameStart() internal view returns (uint32) {
        return uint32(block.timestamp - _timer.maxDuration);
    }

    /**
     * @dev In some Bingo rules, selectable numbers are restricted by the order.
     *      For these rules, please override this function.
     */
    function _isSelectableNumber(
        uint8 number,
        uint8 order
    ) internal view virtual returns (bool) {
        return order > 0 && number >= _minNumber && number <= _maxNumber;
    }

    function _hasGameRecord(uint256 gameId) internal view returns (bool) {
        return gameId <= _lastGameId && _games[gameId].startedAt > 0;
    }

    function _gamePlayerCounts(uint256 gameId) internal view returns (uint8) {
        return uint8(_gameParticipants[gameId].length);
    }

    function _gamePlayers(uint256 gameId) internal view returns (address[] memory) {
        uint8 counts = _gamePlayerCounts(gameId);
        address[] memory players = new address[](counts);

        for (uint8 i = 0; i < counts; i++) {
            players[i] = _gameParticipants[gameId][i].user;
        }

        return players;
    }

    function summary() external view returns (
        uint256 totalGameStarted,
        uint256 totalPlayersJoined,
        uint256 totalRewardDistributed
    ) {
        return (
            _lastGameId,
            _totalPlayers,
            _rewardDistributed[_reward.token]
        );
    }

    function _setReward(address newReward, uint32 maxAmounts) internal {
        _reward = RewardInfo({
            token: newReward,
            maxDistribution: maxAmounts
        });
        emit RewardChanged(newReward, _reward.token);
    }

    function _distributeReward(address to) internal returns (bool) {
        if (
            _reward.token != address(0) &&
            _rewardDistributed[_reward.token] < _reward.maxDistribution
        ) {
            Rewardable(_reward.token).mint(to);
            _rewardDistributed[_reward.token] += 1;

            return true;
        }

        return false;
    }

    function playedGames(address user, uint256 skip) external view override returns (RecentGame[] memory games) {
        uint256 total = _gamePlayed[user].length;
        uint256 endIndex = skip > total
            ? 0
            : total - skip;
        uint256 startIndex = endIndex >= RECENT_GAME_COUNTS
            ? endIndex - RECENT_GAME_COUNTS
            : 0;

        uint256 counts = endIndex - startIndex;

        games = new RecentGame[](endIndex - startIndex);
        for (uint256 i = 0; i < counts; i++) {
            uint256 id = _gamePlayed[user][startIndex + i];
            games[i] = _isGameOngoing(id)
                ? _formatLiveGame(id)
                : _formatEndedGame(id);
        }
    }

    function recentGames(RecentGameFilter filter) public view override returns(
        RecentGame[] memory games
    ) {
        if (filter == RecentGameFilter.LIVE) return _recentLiveGames(RECENT_GAME_COUNTS);
        if (filter == RecentGameFilter.FINISHED) return _recentEndGames(RECENT_GAME_COUNTS);

        return _recentGames(RECENT_GAME_COUNTS);
    }

    function _recentLiveGames(uint8 maxCounts) internal view returns (RecentGame[] memory games) {
        uint256[] memory gameIds = new uint256[](maxCounts);
        uint8 matched = 0;

        for (
            uint256 id = _lastGameId;
            id > _firstGameId && matched < maxCounts;
            id--
        ) {
            if (!_isGameOngoing(id)) continue;
            gameIds[matched++] = id;
        }

        games = new RecentGame[](matched);
        for (uint8 i = 0; i < matched; i++) {
            games[i] = _formatLiveGame(gameIds[i]);
        }
    }

    function _recentEndGames(uint8 maxCounts) internal view returns (RecentGame[] memory games) {
        uint256[] memory gameIds = new uint256[](maxCounts);
        uint8 matched = 0;

        for (
            uint256 id = _lastGameId;
            matched < maxCounts && id > 0;
            id--
        ) {
            if (_isGameOngoing(id)) continue;
            gameIds[matched++] = id;
        }

        games = new RecentGame[](matched);
        for (uint8 i = 0; i < matched; i++) {
            games[i] = _formatEndedGame(gameIds[i]);
        }
    }

    function _recentGames(uint8 maxCounts) internal view returns (RecentGame[] memory games) {
        games = new RecentGame[](_lastGameId > maxCounts ? maxCounts : _lastGameId);

        for (uint256 i = 0; i < games.length; i++) {
            uint256 id = _lastGameId - i;
            games[i] = _isGameOngoing(id)
                ? _formatLiveGame(id)
                : _formatEndedGame(id);
        }
    }

    function _formatEndedGame(uint256 gameId) internal view returns (RecentGame memory game) {
        return RecentGame(
            gameId,
            _games[gameId].winner == address(0) ? "overtime" : "end",
            _games[gameId].winner,
            _games[gameId].winnerCardId > 0
                ? _gameCard.getCardNumbers(_games[gameId].winnerCardId)
                : new uint8[][](0),
            _gameCard.decodeSelectedNumbers(_games[gameId].selectedNumbers),
            _gameParticipants[gameId]
        );
    }

    function _formatLiveGame(uint256 gameId) internal view returns (RecentGame memory game) {
        return RecentGame(
            gameId,
            "live",
            address(0),
            new uint8[][](0),
            _gameCard.decodeSelectedNumbers(_games[gameId].selectedNumbers),
            _gameParticipants[gameId]
        );
    }

    function _setGameTimer(
        uint32 startTimeout,
        uint8 boostRounds,
        uint32 roundGap,
        uint32 roundTimeout,
        uint32 maxDuration
    ) internal {
        require(
            maxDuration >= 10 seconds &&
            maxDuration < 30 days,
            "BingoGameRoom: invalid duration"
        );

        _timer = GameTimeout({
            startTimeout: startTimeout,
            boostRounds: boostRounds,
            roundGap: roundGap,
            roundTimeout: roundTimeout,
            maxDuration: maxDuration
        });
    }

    /**
     * @dev forceStop(false) => stop last game if it's over-time
     */
    function _haltPlayerLastGame(address user, bool forceStop) internal returns (bool stoped) {
        uint256 lastGameId = _playerLastGameId(user);

        if (lastGameId == 0) return false;

        if (lastGameId == 0 || _games[lastGameId].endedAt > 0) return false;

        bool isOvertime = _games[lastGameId].startedAt < _overtimeGameStart();

        if (isOvertime || forceStop) {
            _games[lastGameId].endedAt = uint32(block.timestamp);
            emit GameHalted(lastGameId, user, isOvertime);
            return true;
        }
    }

    function timer() external view returns (GameTimeout memory) {
        return _timer;
    }

    function _gameAutoEndTime(uint256 gameId) internal view returns (uint32) {
        return _games[gameId].startedAt + _timer.maxDuration;
    }

    function _playerCardId(uint256 gameId, address user) internal view returns (uint256) {
        for (uint256 i = 0; i < _gameParticipants[gameId].length; i++) {
            if (_gameParticipants[gameId][i].user == user) {
                return _gameParticipants[gameId][i].cardId;
            }
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ZKGame/IGameLineup.sol";

abstract contract GameLineup is IGameLineup {
    struct UserRecord {
        uint256 currentLineup;
        uint128 joined;
        uint128 completed;
    }

    struct Lineup {
        address user;
        bytes zkContent;
    }

    uint256 private totalLineupIndex;
    uint256 private endedLineupIndex;
    mapping(uint256 => Lineup) private _lineups;

    mapping(address => UserRecord) private _userRecords;

    // solhint-disable-next-line no-empty-blocks
    function initGameLineup() internal {}

    function lineupUsers() external view override returns(address[] memory list) {
        (
            uint8 counts,
            uint256 from,
            uint256 to
        ) = _lineupCounts();

        list = new address[](counts);

        uint256 cursor = from;
        for (uint256 i = 0; i < counts && cursor <= to; cursor++) {
            if (_lineups[cursor].user != address(0)) list[i++] = _lineups[cursor].user;
        }
    }

    function _lineupCounts() internal view returns (
        uint8 counts,
        uint256 fromIndex,
        uint256 toIndex
    ) {
        fromIndex = endedLineupIndex + 1;

        for (toIndex = fromIndex; toIndex <= totalLineupIndex; toIndex++) {
            if (_lineups[toIndex].user != address(0)) counts++;
        }
    }

    function _userJoinedCounts(address user) internal view returns (uint256) {
        return _userRecords[user].joined;
    }

    function _userInLineup(address user) internal view returns (bool) {
        return _userRecords[user].currentLineup != 0;
    }

    function _joinLineup(
        address user,
        bytes memory zkCard
    ) internal {
        require(!_userInLineup(user), "GameLineup: !allowed");

        Lineup storage lineup = _lineups[++totalLineupIndex];
        lineup.user = user;
        lineup.zkContent = zkCard;

        _userRecords[user].joined++;
        _userRecords[user].currentLineup = totalLineupIndex;

        emit LineupJoined(user);
    }

    function _leaveLineup(address user) internal {
        UserRecord storage userRecord = _userRecords[user];
        require(userRecord.currentLineup != 0, "GameLineUp: !inLineup");

        delete _lineups[userRecord.currentLineup];

        if (endedLineupIndex == userRecord.currentLineup - 1) {
            endedLineupIndex++;
        }

        userRecord.currentLineup = 0;

        emit LineupLeft(user);
    }

    function _completeLineup(uint8 counts) internal returns (Lineup[] memory list) {
        list = new Lineup[](counts);

        for (uint8 completed = 0; completed < counts && endedLineupIndex < totalLineupIndex; ) {
            Lineup storage lineup = _lineups[++endedLineupIndex];

            if (lineup.user != address(0)) {
                list[completed] = lineup;
                _userRecords[lineup.user].completed++;
                _userRecords[lineup.user].currentLineup = 0;

                delete _lineups[endedLineupIndex];

                completed++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IZKGame.sol";

abstract contract UserCenter is IUserCenter {
    uint256 private _seasonId;

    uint256 private constant OVERALL_RECORDS_ID = type(uint256).max;

    /** @dev seasonId -> info */
    mapping(uint256 => GameSeason) private _seasons;

    /** @dev seasonId -> user -> statistics */
    mapping(uint256 => mapping(address => PlayerStatistics)) public _seasonLogs;

    function initUserCenter(string memory seasonName) internal {
        _newSeason(seasonName);
    }

    function _newSeason(string memory title) internal {
        _seasons[++_seasonId] = GameSeason(title, block.timestamp);
    }

    function _logGamePlayed(address user) internal {
        _seasonLogs[_seasonId][user].joined++;
        _seasonLogs[OVERALL_RECORDS_ID][user].joined++;
    }

    function _logGameWon(address user) internal {
        _seasonLogs[_seasonId][user].wins++;
        _seasonLogs[OVERALL_RECORDS_ID][user].wins++;
    }

    function userRecords(address user) public view override returns (
        PlayerStatistics memory current,
        PlayerStatistics memory overall
    ) {
        current = _seasonLogs[_seasonId][user];
        overall = _seasonLogs[OVERALL_RECORDS_ID][user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// solhint-disable max-line-length
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
// solhint-enable max-line-length

import { BingoGameRoom, IBingoCard } from "./intermediates/BingoGameRoom.sol";
import { GameLineup } from "./intermediates/GameLineup.sol";
import { UserCenter } from "./intermediates/UserCenter.sol";

/**
 * @dev Lobby -> Games -> Bingo Cards
 */
contract ZkBingoLobby is
    GameLineup,
    BingoGameRoom,
    UserCenter,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    string public constant NAME = "zBingo";

    uint256 public constant GAME_REWARD_FEE = 0.1 ether; // 10%

    uint32 public version;

    uint8 public minPlayers;
    uint8 public maxPlayers;

    function initialize(
        address _gameCard,
        uint8 _expectedLines,
        uint8 _minPlayers,
        uint8 _maxPlayers,
        uint8 minCardNumber,
        uint8 maxCardNumber
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        initBingoGameRoom(
            _gameCard,
            _expectedLines,
            minCardNumber,
            maxCardNumber,

            10 seconds, // game start timeout
            9, // boost first N rounds (no gap times)
            10 seconds, // round gap time
            30 seconds, // round timeout
            30 minutes // Max game duration
        );
        initGameLineup();
        initUserCenter("Early Access");

        version = 1;

        minPlayers = _minPlayers;
        maxPlayers = _maxPlayers;
    }

    function join(bytes memory zkCard) external override nonReentrant {
        _joinLineup(_msgSender(), zkCard);
        _haltPlayerLastGame(_msgSender(), false);

        require(
            !_isGameOngoing(_playerLastGameId(_msgSender())),
            "Lobby: last game is ongoing"
        );

        (
            uint8 waitings,
            /* uint256 fromIndex */,
            /* uint256 toIndex */
        ) = _lineupCounts();

        if (waitings >= maxPlayers) {
            Lineup[] memory roomUsers = _completeLineup(maxPlayers);
            uint256 gameId = _startGame(roomUsers);
            _afterGameStarted(gameId, _msgSender());
        }
    }

    function leave() external override nonReentrant {
        _leaveLineup(_msgSender());
    }

    function start() external override nonReentrant {
        require(_userInLineup(_msgSender()), "Lobby: only lineup user can start");

        (
            uint8 waitings,
            /* uint256 fromIndex */,
            /* uint256 toIndex */
        ) = _lineupCounts();

        require(waitings >= minPlayers, "Not enough players");

        Lineup[] memory roomUsers = _completeLineup(waitings);
        uint256 gameId = _startGame(roomUsers);
        _afterGameStarted(gameId, _msgSender());
    }

    function selectNumber(
        uint256 gameId,
        uint8 number
    ) external override nonReentrant onlyOngoingGame(gameId) {
        _selectNumber(gameId, _msgSender(), number);
    }

    function bingo(
        uint256 gameId,
        uint8[][] memory cardNumbers,
        bytes memory signedGameLabel
    ) external override nonReentrant onlyOngoingGame(gameId) {
        _bingo(
            gameId,
            _msgSender(),
            cardNumbers,
            bytes(keyLabel(_userJoinedCounts(_msgSender()))),
            signedGameLabel
        );

        _afterGameWon(gameId);
        _logGameWon(_msgSender());
    }

    function selectAndBingo(
        uint256 gameId,
        uint8 number,
        uint8[][] calldata cardNumbers,
        bytes calldata signedGameLabel
    ) external override onlyOngoingGame(gameId) {
        _selectNumber(gameId, _msgSender(), number);

        _bingo(
            gameId,
            _msgSender(),
            cardNumbers,
            bytes(keyLabel(_userJoinedCounts(_msgSender()))),
            signedGameLabel
        );

        _afterGameWon(gameId);
        _logGameWon(_msgSender());
    }

    function getNextKeyLabel(address user) public view returns (string memory) {
        return keyLabel(_userJoinedCounts(user) + 1);
    }

    function keyLabel(uint256 nonce) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    NAME,
                    "@",
                    StringsUpgradeable.toHexString(address(this)),
                    "#",
                    StringsUpgradeable.toString(nonce)
                )
            );
    }

    function fee() external view returns (uint256 value, uint256 deno) {
        version; // avoid warning this function is pure
        return (GAME_REWARD_FEE, 1 ether);
    }

    function _startGame(Lineup[] memory joiners) internal returns (uint256 gameId) {
        address[] memory players = new address[](joiners.length);
        for (uint256 i = 0; i < joiners.length; i++) {
            players[i] = joiners[i].user;
        }
        gameId = _newGame(players);

        for (uint256 i = 0; i < joiners.length; i++) {
            _joinGame(gameId, joiners[i].user, joiners[i].zkContent);
            _logGamePlayed(joiners[i].user);
        }
    }

    function _afterGameWon(uint256 gameId) internal {
        // TODO: Notice external contract
    }

    // solhint-disable-next-line no-empty-blocks
    function _afterGameStarted(uint256 gameId, address starter) internal virtual {}

    function setReward(
        address newReward,
        uint32 amount
    ) external onlyOwner {
        _setReward(newReward, amount);
    }

    function newSeason(string memory title) external onlyOwner {
        _newSeason(title);
    }

    function setGameTimers(
        uint32 startTimeout,
        uint8 boostRounds,
        uint32 roundGap,
        uint32 roundTimeout,
        uint32 maxDuration
    ) external onlyOwner {
        _setGameTimer(
            startTimeout,
            boostRounds,
            roundGap,
            roundTimeout,
            maxDuration
        );
    }

    function _authorizeUpgrade(address /* newImplementation */) internal override onlyOwner {
        version++;
    }

    /**
     * @dev Call this function by callStatic to check if a game is ongoing and
     *      check if cached card content is available
     */
    function restoreGame(
        address player,
        uint8[][] memory cardNumbers,
        bytes memory signedGameLabel
    ) external override returns (
        uint256 playingGameId,
        uint32 autoEndTime,
        bool isCardContentMatched
    ) {
        playingGameId = _playerLastGameId(player);

        if (!_isGameOngoing(playingGameId)) {
            return (0, 0, false);
        }

        autoEndTime = _gameAutoEndTime(playingGameId);

        uint256 cardId = _playerCardId(playingGameId, player);

        try IBingoCard(gameCard()).reveal(
            cardId,
            bytes(keyLabel(_userJoinedCounts(player))),
            signedGameLabel,
            cardNumbers
        ) {
            // Do nothing
        } catch {
            // Invalid params
            return (playingGameId, autoEndTime, false);
        }

        try IBingoCard(gameCard()).getCardNumbers(cardId) returns (uint8[][] memory) {
            return (playingGameId, autoEndTime, true);
        } catch {
            // Not revealed
            return (playingGameId, autoEndTime, false);
        }
    }
}