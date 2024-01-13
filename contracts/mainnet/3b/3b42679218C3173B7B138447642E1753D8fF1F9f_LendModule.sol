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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface INonfungiblePositionManager {
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId; 
        uint128 liquidity;
        uint256 amount0Min; 
        uint256 amount1Min;
        uint256 deadline; 
    }
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ILendFacet {
    enum CollateralNftType {
        UnUsed,
        UniswapV3
    }

    struct PutOrder {
        uint256 orderId;
        address lender;
        address borrower;
        address recipient;
        /**
          if collateralAssetType==0  collateralAsset is Token
          if collateralAssetType==1  collateralAsset  is nft
         */
        address collateralAsset;
        /**
          if collateralAssetType==0  collateralAmount is Token amount
          if collateralAssetType==1  collateralAsset  is liquidity
         */
        uint256 collateralAmount;
        address borrowAsset;
        uint256 borrowMinAmount;
        uint256 borrowAmount;
        uint256 expirationDate;
        uint256 platformFee;
        uint256 index;
        uint256 interestAmount;
        uint256 collateralAssetType;
        uint256 collateralNftId;
    }
    struct CallOrder {
        uint256 orderId;
        address borrower;
        address lender;
        address recipient;
        address collateralAsset;
        uint256 collateralAmount;
        address borrowAsset;
        uint256 borrowNowAmount;
        uint256 borrowNowMinAmount;
        uint256 interestAmount;
        uint256 borrowLaterMinAmount;
        uint256 borrowLaterAmount;
        uint256 expirationDate;
        uint256 platformFee;
        uint256 index;
        uint256 collateralAssetType;
        uint256 collateralNftId;
    }
    event SetCollateralNft(address _nft, CollateralNftType _type);
    event SetLendFeePlatformRecipient(address _recipient);
    event SetDomainHash(bytes32 _domainHash);

    function setBorrowerPutOrder(
        address _borrower,
        PutOrder memory _putOrder
    ) external;

    function deleteBorrowerPutOrder(address _borrower) external;

    function getBorrowerPutOrder(
        address _borrower
    ) external view returns (PutOrder memory);

    function setLenderPutOrder(address _lender, address _borrower) external;

    function getLenderPutOrder(
        address _lender
    ) external view returns (address[] memory);

    function getLenderPutOrderLength(
        address _lender
    ) external view returns (uint256);

    function deleteLenderPutOrder(address _lender, uint256 _index) external;

    function setBorrowerPutOrderNftInfo(
        address _borrower,
        uint256 _collateralNftId,
        uint256 _newLiquidity
    ) external;

    //----
    function setDomainHash(bytes32 _domainHash) external;

    function getDomainHash() external view returns (bytes32);

    function setLendFeePlatformRecipient(
        address _lendFeePlatformRecipient
    ) external;

    function getLendFeePlatformRecipient() external view returns (address);

    //-----
    function setLenderCallOrder(
        address _lender,
        CallOrder memory _callOrder
    ) external;

    function deleteLenderCallOrder(address _lender) external;

    function getLenderCallOrder(
        address _lender
    ) external view returns (CallOrder memory);

    function setBorrowerCallOrder(address _borrower, address _lender) external;

    function getBorrowerCallOrderLength(
        address _borrower
    ) external view returns (uint256);

    function getBorrowerCallOrder(
        address _borrower
    ) external view returns (address[] memory);

    function deleteLenderCallOrder(address _borrower, uint256 _index) external;

    function setLenderCallOrderNftInfo(
        address _lender,
        uint256 _collateralNftId,
        uint256 _newLiquidity
    ) external;

    //----
    function setCollateralNft(address _nft, CollateralNftType _type) external;

    function getCollateralNft(
        address _nft
    ) external view returns (CollateralNftType);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {ILendFacet} from "./ILendFacet.sol";
interface ILendModule {
    event SubmitPutOrder(address indexed submitor, ILendFacet.PutOrder putOrder);
    event LiquidatePutOrder(address indexed liquidator, ILendFacet.PutOrder putOrder);

    event SubmitCallOrder(address indexed submitor, ILendFacet.CallOrder callOrder);
    event LiquidateCallOrder(address indexed liquidator, ILendFacet.CallOrder callOrder);
    function submitPutOrder(
        ILendFacet.PutOrder memory _putOrder,
        bytes calldata _borrowerSignature,
        bytes calldata _lenderSignature
    ) external;
    function liquidatePutOrder(address _borrower,bool _type) external payable;
    function submitCallOrder(ILendFacet.CallOrder memory _callOrder,bytes calldata _borrowerSignature,bytes calldata _lenderSignature) external;
    function liquidateCallOrder(address _lender,bool _type) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IOwnable{
    function owner() external view returns(address);
    function transferOwnership(address _newOwner) external;
    function setDBControlWhitelist(address[] memory _modules,bool[] memory _status)  external;
    function getDBControlWhitelist(address _module) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IPlatformFacet{
    struct ProtocolAndA{
        address addr;
        address module;
        string  protocol;      
    }
    event SetModules(address[]  _modules,bool[]  _status);
    event SetProtocols(address _module,string[]  _protocols,address[]  _protocolAddrs);
    event SetTokens(address[]  _tokens,uint256[]  _tokenTypes);
    event AddWalletToVault(address _wallet,address _vault,uint256 _salt);
    event RemoveWalletToVault(address _wallet,address[]  _vaults);
    event SetWeth(address _weth);
    event SetEth(address _eth);
    event SetVaultImplementation(address _implementation);
    event SetProxyCodeHash(address _proxy,bool _option);

    function setModules(address[] memory _modules,bool[] memory _status)  external;
    function getAllModules()  external view returns(address[] memory);
    function getModuleStatus(address _module) external view returns(bool);   


    function setProtocols(address _module,string[] memory _protocols,address[] memory _protocolAddrs) external;
    function getProtocols()  external view returns(ProtocolAndA[] memory);
    function getModuleToProtocolA(address _module,string memory _protocol) external view returns(address);


    function setTokens(address[] memory _tokens,uint256[] memory _tokenTypes)  external;
    function getTokens()  external view returns(address[] memory);  
    function getTokenType(address _token) external view returns(uint256);


    function addWalletToVault(address _wallet,address _vault,uint256 _salt) external;
    function removeWalletToVault(address _wallet,address[] memory _vaults) external;
    function getAllVaultByWallet(address _wallet) external view returns(address[] memory);
    function getVaultToSalt(address _vault) external view returns(uint256);
    function getIsVault(address _vault) external view returns(bool);

    function setWeth(address _weth) external;
    function getWeth() external view returns(address);

    function setEth(address _eth) external;
    function getEth() external view returns(address);

    function getVaultImplementation() external view returns(address);
    function setVaultImplementation(address _implementation) external; 
    function setProxyCodeHash(address _proxy,bool _option) external;  
    function getProxyCodeHash(address _proxy) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IVault{
    function owner() external view returns(address);
    function getImplementation() external view returns(address);
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
    function execute(address dest, uint256 value, bytes calldata func) external returns(bytes memory);
    function executeBatch(address[] calldata dest, bytes[] calldata func) external returns(bytes[] memory);   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IVaultFacet{
      struct Position{  
           uint16  positionType;  //1 normal 2 aave asset 3 compound asset 4gmx  asset  5 lido asset  6 nft asset
           uint16  debtType;   // 0 normal    1  debt           
           uint16 ableUse;   // 0 unused   1 used
           address component; 
           uint256 balance;
           bytes data; 
      }
     event SetVaultType(address _vault,uint256 _vaultType);
     event SetSourceType(address _vault,uint256 _sourceType);
     event SetVaultMasterToken(address _vault,address _masterToken);
     event SetVaultLock(address _vault,bool _lock);
     event SetVaultTime(address _vault,uint256 _time);
     event SetVaultModules(address _vault,address[]  _modules,bool[]  _status);
     event SetVaultTokens(address _vault,address[] _tokens,uint256[]  _types);
     event SetVaultProtocol(address _vault,address[]  _protocols,bool[]  _status);
     event SetVaultPosition(address _vault,address _component,uint16[3]  _append);
     event SetVaultPositionData(address _vault,address _component,uint256 _positionType,bytes  _data);
     event SetVaultPositionBalance(address _vault,address _component,uint256 _positionType,uint256 _balance);  
    
     event SetFuncWhiteList(address _vault,bytes4 _func,bool _type);
     event SetFuncBlackList(address _vault,bytes4 _func,bool _type);



     function setVaultType(address _vault,uint256 _vaultType) external;
     function getVaultType(address _vault) external view returns(uint256);
     function setSourceType(address _vault,uint256 _sourceType) external;
     function getSourceType(address _vault) external view returns(uint256);
     
     function setVaultMasterToken(address _vault,address _masterToken) external;
     function getVaultMasterToken(address _vault) external view returns(address);
     
     function setVaultLock(address _vault,bool _lock) external;
     function getVaultLock(address _vault) external view returns(bool);
     function setVaultTime(address _vault,uint256 _time) external;
     function getVaulTime(address _vault) external view returns(uint256);


     function setVaultModules(address _vault,address[] memory _modules,bool[] memory _status) external; 
     function getVaultAllModules(address _vault) external view returns(address[] memory);
     function getVaultModuleStatus(address _vault,address _module) external view returns(bool);

     function setVaultTokens(address _vault,address[] memory _tokens,uint256[] memory _status) external;
     function getVaultAllTokens(address _vault) external view returns(address[] memory);
     function getVaultTokenType(address _vault,address _token) external view returns(uint256);

     function setVaultProtocol(address _vault,address[] memory _protocols,bool[] memory _status) external;
     function getVaultAllProtocol(address _vault) external view returns(address[] memory);
     function getVaultProtocolStatus(address _vault,address  _protocol) external view returns(bool);

     function setVaultPosition(address _vault,address _component,uint16[3] memory _append) external;
     function setVaultPositionData(address _vault,address _component,uint256 _positionType,bytes memory _data) external;
     function getVaultAllPosition(address _vault,uint16[] memory _positionTypes) external view returns(Position[] memory positions);
     function getVaultProtocolPosition(address _vault,uint16 _positionType) external view returns(Position[] memory positions);
     function getVaultPosition(address _vault,address _component, uint256 _positionType) external view returns(Position memory position);
    
     function setFuncWhiteList(address _vault,bytes4 _func,bool _type) external;
     function getFuncWhiteList(address _vault,bytes4 _func) external view returns(bool);
     function setFuncBlackList(address _vault,bytes4 _func,bool _type) external;
     function getFuncBlackList(address _vault,bytes4 _func) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {IVault} from  "../interfaces/internal/IVault.sol";

library Invoke {
    // using SafeMath for uint256;
    function invokeApprove(IVault _vault,address _token,address _spender,uint256 _amount) internal {
         bytes memory _calldata = abi.encodeWithSignature("approve(address,uint256)", _spender, _amount);
         _vault.execute(_token, 0, _calldata);
    }

    function invokeApproveNft(IVault _vault,address _nft,address _to, uint256 _tokenId) internal{
        bytes memory _calldata = abi.encodeWithSignature("approve(address,uint256)", _to, _tokenId);
        _vault.execute(_nft, 0, _calldata);
    }

    function invokeTransferNft(IVault _vault,address _nft,address _to, uint256 _tokenId) internal {
        bytes memory _calldata = abi.encodeWithSignature("transferFrom(address,address,uint256)",address(_vault),_to, _tokenId);
        _vault.execute(_nft, 0, _calldata);       
    }
    function invokeTransfer(IVault _vault,address _token,address _to,uint256 _amount) internal{
        if(_amount>0){
          bytes memory _calldata = abi.encodeWithSignature("transfer(address,uint256)", _to, _amount);
          _vault.execute(_token, 0, _calldata);
        }
    }
    function invokeTransferFrom(IVault _vault,address _token, address from, address _to,uint256 _amount) internal{
        if(_amount>0){
          bytes memory _calldata = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, _to, _amount);
          _vault.execute(_token, 0, _calldata);
        }
    }
    
    function invokeUnwrapWETH(IVault _vault,address _weth,uint256 _amount) internal {
        bytes memory  _calldata = abi.encodeWithSignature("withdraw(uint256)", _amount);
        _vault.execute(_weth, 0, _calldata);
    }

    function invokeWrapWETH(IVault _vault,address _weth,uint256 _amount) internal{
        bytes memory  _calldata = abi.encodeWithSignature("deposit()");
        _vault.execute(_weth, _amount, _calldata);
    }

    function invokeTransferEth(IVault _vault,address _to, uint256 _amount) internal {
        // invokeWrapWETH(_vault,_weth,_amount);       
        // invokeTransfer(_vault,_weth,address(this),_amount);
        //  bytes memory  _calldata = abi.encodeWithSignature("withdraw(uint256)", _amount);
        //  (bool success, )=address(this).call(_calldata);
        //  require(success,"vault:withdraw eth fail");
        //  (success,)= _to.call{value:_amount}("");
        //  require(success,"vault:tranfer eth fail");
        bytes memory func;
        _vault.execute(_to,_amount, func);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IVault} from "../interfaces/internal/IVault.sol";
import {IPlatformFacet} from "../interfaces/internal/IPlatformFacet.sol";
import {IVaultFacet} from "../interfaces/internal/IVaultFacet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ModuleBase {
    address public diamond;
    modifier onlyVault(address _vault) {
        require(
            msg.sender == address(_vault),
            "ModuleBase:caller must be vault"
        );
        require(
            IPlatformFacet(diamond).getIsVault(_vault),
            "ModuleBase:vault must in platform"
        );

        _;
    }

    modifier onlyVaultManager(address _vault) {
        require(
            msg.sender == IVault(_vault).owner(),
            "ModuleBase:caller must be vault manager"
        );
        require(
            IPlatformFacet(diamond).getIsVault(_vault),
            "ModuleBase:vault must in platform"
        );
        _;
    }

    function updatePosition(
        address _vault,
        address _component,
        uint16 _debtType
    ) internal {
        updatePositionInternal(_vault, _component, 0, _debtType);
    }

    function updatePosition(
        address _vault,
        address _component,
        uint256 _positionType,
        uint16 _debtType
    ) internal {
        updatePositionInternal(_vault, _component, _positionType, _debtType);
    }

    function updatePositionInternal(
        address _vault,
        address _component,
        uint256 _positionType,
        uint16 _debtType
    ) internal {
        uint256 balance;
        IPlatformFacet platformFacet = IPlatformFacet(diamond);
        if (_component == platformFacet.getEth()) {
            balance = _vault.balance;
            if (_positionType == 0) {
                _positionType = 1;
            }
        } else {
            balance = IERC20(_component).balanceOf(_vault);
            if (_positionType == 0) {
                _positionType = platformFacet.getTokenType(_component);
            }
        }
        require(_positionType != 0, "ModuleBase:positionType error");
        uint16 option = balance > 0 ? 1 : 0;
        uint16[3] memory sendAssetAppend = [
            uint16(_positionType),
            _debtType,
            option
        ];
        IVaultFacet(diamond).setVaultPosition(
            _vault,
            _component,
            sendAssetAppend
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../lib/ModuleBase.sol";
import {IOwnable} from "../interfaces/internal/IOwnable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Invoke} from "../lib/Invoke.sol";
import {ILendFacet} from "../interfaces/internal/ILendFacet.sol";
import {ILendModule} from "../interfaces/internal/ILendModule.sol";
import {INonfungiblePositionManager} from "../interfaces/external/INonfungiblePositionManager.sol";
contract LendModule is ModuleBase,ILendModule,Initializable,UUPSUpgradeable,ReentrancyGuardUpgradeable{ 
    using Invoke for IVault;
    using SafeERC20 for IERC20;
    mapping(uint256=> bool)  public usedOrderCall;
    mapping(uint256 => bool)  public  usedOrderPut;
    modifier onlyOwner() {
        require(
            msg.sender == IOwnable(diamond).owner(),
            "TradeModule:only owner"
        );
        _;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _diamond) public initializer {
        __UUPSUpgradeable_init();
        diamond=_diamond;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function verifyPutOrder(ILendFacet.PutOrder memory _putOrder)  internal view{
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          require(!usedOrderPut[_putOrder.orderId],"LendModule:orderId is Used"); 
          require(!vaultFacet.getVaultLock(_putOrder.borrower),"LendModule:borrower is locked");
          require(!vaultFacet.getVaultLock(_putOrder.lender),"LendModule:lender is locked");
          require(vaultFacet.getVaultType(_putOrder.borrower) == 3,"LendModule:borrower vaultType error");
          require(vaultFacet.getVaultType(_putOrder.lender) == 2,"LendModule:lender vaultType error");
          require(_putOrder.recipient != address(0) && _putOrder.recipient != _putOrder.borrower,"LendModule:recipient error");
          require(_putOrder.lender != _putOrder.borrower,"LendModule:lender error");
          require(_putOrder.expirationDate > block.timestamp,"LendModule:invalid expirationDate");
          require(_putOrder.borrowAmount>=_putOrder.borrowMinAmount,"LendModule:borrowAmount error");
          IPlatformFacet platformFacet=  IPlatformFacet(diamond);
          ILendFacet  lendFacet=ILendFacet(diamond);
          address eth=platformFacet.getEth();
          //verify collateralAsset
          if(_putOrder.collateralAsset == eth){
             require(_putOrder.borrower.balance >= _putOrder.collateralAmount,"LendModule:collateralAmount not enough");
          }else{
             if(_putOrder.collateralAssetType == 0){
                //verify token amount
                require(IERC20(_putOrder.collateralAsset).balanceOf(_putOrder.borrower) >= _putOrder.collateralAmount,"LendModule:collateralAmount not enough");
             }else if(_putOrder.collateralAssetType == 1){
                //verify uniswapv3 nft liquidity
                if(lendFacet.getCollateralNft(_putOrder.collateralAsset) == ILendFacet.CollateralNftType.UniswapV3){
                   (,,address token0,address token1,,,,uint128 liquidity,,,,) =INonfungiblePositionManager(_putOrder.collateralAsset).positions(_putOrder.collateralNftId);
                   require(platformFacet.getTokenType(token0) !=0 && platformFacet.getTokenType(token1) != 0,"LendModule:nft assets error");
                   require(uint256(liquidity) >= _putOrder.collateralAmount,"LendModule:collateralAmount not enough"); 
                }else{
                   revert("LendModule:invalid Nft");  
                }
             }else{
                revert("LendModule:collateralAssetType error"); 
             }     
          }
            //verify borrowAsset
         if(_putOrder.borrowAsset == eth){
              require(_putOrder.lender.balance >= _putOrder.borrowAmount,"LendModule:borrowAmount not enough");
          }else{
              require(IERC20(_putOrder.borrowAsset).balanceOf(_putOrder.lender) >= _putOrder.borrowAmount,"LendModule:borrowAmount not enough");
          }   
    } 

    function handlePutOrder(address _signer,ILendFacet.PutOrder memory _putOrder,bytes memory _signature) internal  view{
        ILendFacet.PutOrder memory tempInfo= ILendFacet.PutOrder({
            orderId:_putOrder.orderId,
            lender:_putOrder.lender,
            borrower:_putOrder.borrower,
            recipient:_putOrder.recipient,
            collateralAsset:_putOrder.collateralAsset,
            collateralAmount:_putOrder.collateralAmount,
            borrowAsset:_putOrder.borrowAsset,
            borrowMinAmount:_putOrder.borrowMinAmount,
            borrowAmount:_putOrder.borrowAmount,
            expirationDate:_putOrder.expirationDate,
            platformFee:_putOrder.platformFee,
            index:_putOrder.index,
            interestAmount:_putOrder.interestAmount,
            collateralAssetType:_putOrder.collateralAssetType,
            collateralNftId:_putOrder.collateralNftId
        });
        if(_signer == tempInfo.borrower){
            tempInfo.borrowAmount=0;
            tempInfo.lender=address(0);
        }
        bytes32  infoTypeHash = keccak256("PutOrder(uint256 orderId,address lender,address borrower,address recipient,address collateralAsset,uint256 collateralAmount,address borrowAsset,uint256 borrowMinAmount,uint256 borrowAmount,uint256 expirationDate,uint256 platformFee,uint256 index,uint256 interestAmount,uint256 collateralAssetType,uint256 collateralNftId)");
        bytes32  _hashInfo= keccak256(abi.encode(
            infoTypeHash,
            tempInfo
        ));
        verifySigbature(_signer,_hashInfo,_signature);
    }


    function submitPutOrder(ILendFacet.PutOrder memory _putOrder,bytes calldata _borrowerSignature,bytes calldata _lenderSignature) external nonReentrant {
          //verify data
          verifyPutOrder(_putOrder);   

          handlePutOrder(_putOrder.borrower,_putOrder,_borrowerSignature);
          handlePutOrder(_putOrder.lender,_putOrder,_lenderSignature);  
          //storage data 
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          address eth=IPlatformFacet(diamond).getEth();
         
          vaultFacet.setVaultLock(_putOrder.borrower,true);
          ILendFacet  lendFacet=ILendFacet(diamond);
        
          _putOrder.index=lendFacet.getLenderPutOrderLength(_putOrder.lender);
          lendFacet.setBorrowerPutOrder(_putOrder.borrower,_putOrder);
          lendFacet.setLenderPutOrder(_putOrder.lender,_putOrder.borrower);
          //tranfer lendFeePlatformRecipient
          address lendFeePlatformRecipient=lendFacet.getLendFeePlatformRecipient();
          usedOrderPut[_putOrder.orderId]=true;
          
          if(_putOrder.borrowAsset == eth){
            if(lendFeePlatformRecipient != address(0)){
                IVault(_putOrder.lender).invokeTransferEth(lendFeePlatformRecipient,_putOrder.platformFee);
             }     
             IVault(_putOrder.lender).invokeTransferEth(_putOrder.recipient,_putOrder.borrowAmount-_putOrder.platformFee-_putOrder.interestAmount);
          }else{
            if(lendFeePlatformRecipient != address(0)){
                 IVault(_putOrder.lender).invokeTransfer(_putOrder.borrowAsset,lendFeePlatformRecipient,_putOrder.platformFee);
            }   
            //tranfer metamask
            IVault(_putOrder.lender).invokeTransfer(_putOrder.borrowAsset,_putOrder.recipient,_putOrder.borrowAmount-_putOrder.platformFee-_putOrder.interestAmount);
          }
          updatePosition(_putOrder.lender,_putOrder.borrowAsset,0);
          //set CurrentVaultModule
          setFuncBlackAndWhiteList(1,_putOrder.lender,_putOrder.borrower,true);
        //   vaultFacet.setFuncBlackList(_lendInfo.loaner,bytes4(keccak256("setVaultType(address,uint256)")),true);
        //   vaultFacet.setFuncWhiteList(_lendInfo.debtor,bytes4(keccak256("replacementLiquidity(address,uint8,uint24,int24,int24)")),true);
          emit SubmitPutOrder(msg.sender,_putOrder);      
    }

    function verifySigbature(address _signer,bytes32 _hash,bytes memory _signature) internal  view{
        bytes32 domainHash= ILendFacet(diamond).getDomainHash();
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domainHash,
            _hash
        ));
        address signer=IVault(_signer).owner();
        address recoverAddress=ECDSA.recover(digest,_signature);
        require(recoverAddress == signer,"LendModule:signature error");
    }
    //liquidate
    /**
     -debtor  borrow
      _type=true:liqudate collateralAsset
      _type=false:liqudate borrowAsset

     -loaner lender 
        liqudate collateralAsset
     */
    function liquidatePutOrder(address _borrower,bool _type) external payable nonReentrant {
          ILendFacet  lendFacet=ILendFacet(diamond);
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          ILendFacet.PutOrder memory putOrder = ILendFacet(diamond).getBorrowerPutOrder(_borrower);
          require(putOrder.borrower != address(0),"LendModule:putOrder not exist");
          lendFacet.deleteBorrowerPutOrder(putOrder.borrower);
          vaultFacet.setVaultLock(putOrder.borrower,false);
          address owner=IVault(putOrder.borrower).owner();  
          if(owner == msg.sender ||  (IPlatformFacet(diamond).getIsVault(msg.sender) && IOwnable(msg.sender).owner() == owner) ){
               if(_type){
                   liquidate(putOrder,1);            
               }else{
                   liquidate(putOrder,2);   
               }   
          } else if( putOrder.expirationDate <= block.timestamp){    
                 liquidate(putOrder,1);
          }else{
              revert("LendModule:liquidate time not yet");
          }
          lendFacet.deleteLenderPutOrder(putOrder.lender,putOrder.index);
          setFuncBlackAndWhiteList(1,putOrder.lender,putOrder.borrower,false);
        //   vaultFacet.setFuncBlackList(putOrder.loaner,bytes4(keccak256("setVaultType(address,uint256)")),false);
        //   vaultFacet.setFuncWhiteList(putOrder.debtor,bytes4(keccak256("replacementLiquidity(address,uint8,uint24,int24,int24)")),false);
          emit LiquidatePutOrder(msg.sender,putOrder);
    }
    function liquidate(ILendFacet.PutOrder memory _putOrder,uint256 _liquidateWay) internal  {   
        address eth=IPlatformFacet(diamond).getEth();     
         if(_liquidateWay==1){
            if(_putOrder.collateralAsset == eth){
                IVault(_putOrder.borrower).invokeTransferEth(_putOrder.lender,_putOrder.collateralAmount);
            }else{
                if(_putOrder.collateralAssetType ==0){
                    //transfer token
                    // IVault(_putOrder.debtor).invokeTransfer(_putOrder.collateralAsset,_putOrder.loaner,_putOrder.collateralAmount);
                    uint256 balance=IERC20(_putOrder.collateralAsset).balanceOf(_putOrder.borrower);
                    require(balance>=_putOrder.collateralAmount,"LendModule:balance error");
                    IVault(_putOrder.borrower).invokeTransfer(_putOrder.collateralAsset,_putOrder.lender,balance);
                }else if(_putOrder.collateralAssetType ==1){
                    //transfer nft  
                    IVault(_putOrder.borrower).invokeTransferNft(_putOrder.collateralAsset,_putOrder.lender,_putOrder.collateralNftId); 
                }else{
                    revert("LendModule:collateralAssetType error"); 
                } 
            }  
            updatePosition(_putOrder.borrower,_putOrder.collateralAsset,0);
            updatePosition(_putOrder.lender,_putOrder.collateralAsset,0);
          }else if(_liquidateWay==2){
                  //if borrowAsset == eth  repay asset is weth
                   if( _putOrder.borrowAsset == eth  && msg.value >= _putOrder.borrowAmount){
                      (bool success,)=_putOrder.lender.call{value:_putOrder.borrowAmount}("");
                      require(success,"LendModule:trafer eth fail");
                   }else{
                        if(_putOrder.borrowAsset == eth){
                            _putOrder.borrowAsset=IPlatformFacet(diamond).getWeth();
                        }
                        IERC20(_putOrder.borrowAsset).safeTransferFrom(_putOrder.recipient,_putOrder.lender,_putOrder.borrowAmount); 
                   }             
                   updatePosition(_putOrder.lender,_putOrder.borrowAsset,1,0);
          }else{
                revert("LendModule:liquidateWay error"); 
          }
    }
    //--------------
    function verifyCallOrder(ILendFacet.CallOrder memory _callOrder) internal view{
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          require(!usedOrderCall[_callOrder.orderId],"LendModule:orderId is Used"); 
          require(!vaultFacet.getVaultLock(_callOrder.borrower),"LendModule:borrower is locked");
          require(!vaultFacet.getVaultLock(_callOrder.lender),"LendModule:lender is locked");
          require(vaultFacet.getVaultType(_callOrder.borrower) == 7,"LendModule:borrower vaultType error");
          require(vaultFacet.getVaultType(_callOrder.lender) == 6,"LendModule:lender vaultType error");
          require(_callOrder.recipient != address(0) && _callOrder.recipient != _callOrder.borrower,"LendModule:recipient error");
          require(_callOrder.borrower != _callOrder.lender,"LendModule:borrower error");
          require(_callOrder.expirationDate > block.timestamp,"LendModule:invalid expirationDate");
          require(_callOrder.borrowNowAmount>=_callOrder.borrowNowMinAmount,"LendModule:borrowNowAmount error");
          require(_callOrder.borrowLaterAmount>=_callOrder.borrowLaterMinAmount,"LendModule:borrowLaterAmount error");
          IPlatformFacet platformFacet=  IPlatformFacet(diamond);
          ILendFacet  lendFacet=ILendFacet(diamond);
          address eth=platformFacet.getEth();
          //verify collateralAsset
          if(_callOrder.collateralAsset == eth){
               require(_callOrder.lender.balance >= _callOrder.collateralAmount,"LendModule:collateralAmount not enough");
          }else{
               if(_callOrder.collateralAssetType == 0){
                   require(IERC20(_callOrder.collateralAsset).balanceOf(_callOrder.lender) >= _callOrder.collateralAmount,"LendModule:collateralAmount not enough");
               }else if(_callOrder.collateralAssetType == 1){
                 //verify uniswapv3 nft liquidity
                if(lendFacet.getCollateralNft(_callOrder.collateralAsset) == ILendFacet.CollateralNftType.UniswapV3){
                   (,,address token0,address token1,,,,uint128 liquidity,,,,) =INonfungiblePositionManager(_callOrder.collateralAsset).positions(_callOrder.collateralNftId);
                   require(platformFacet.getTokenType(token0) !=0 && platformFacet.getTokenType(token1) != 0,"LendModule:nft assets error");
                   require(uint256(liquidity) >= _callOrder.collateralAmount,"LendModule:collateralAmount not enough"); 
                }else{
                   revert("LendModule:invalid Nft");  
                }  
               }else{
                  revert("LendModule:collateralAssetType error"); 
               }
          }
           //verify lendAsset
          if(_callOrder.borrowAsset == eth){
              require(_callOrder.borrower.balance >= (_callOrder.borrowNowAmount+_callOrder.interestAmount+_callOrder.platformFee),"LendModule:borrowAmount not enough");
          }else{
              require(IERC20(_callOrder.borrowAsset).balanceOf(_callOrder.borrower) >=(_callOrder.borrowNowAmount+_callOrder.interestAmount+_callOrder.platformFee),"LendModule:borrowAmount not enough");
          }     
    }

    function handleCallOrderr(address _signer,ILendFacet.CallOrder memory _callOrder,bytes memory _signature) internal view{
          ILendFacet.CallOrder memory tempInfo= ILendFacet.CallOrder({
            orderId:_callOrder.orderId,
            borrower:_callOrder.borrower,
            lender:_callOrder.lender,
            recipient:_callOrder.recipient,
            collateralAsset:_callOrder.collateralAsset,
            collateralAmount:_callOrder.collateralAmount,
            borrowAsset:_callOrder.borrowAsset,
            borrowNowAmount:_callOrder.borrowNowAmount,
            borrowNowMinAmount:_callOrder.borrowNowMinAmount,
            interestAmount:_callOrder.interestAmount,
            borrowLaterMinAmount:_callOrder.borrowLaterMinAmount,
            borrowLaterAmount:_callOrder.borrowLaterAmount,
            expirationDate:_callOrder.expirationDate,
            platformFee:_callOrder.platformFee,
            index:_callOrder.index,
            collateralAssetType:_callOrder.collateralAssetType,
            collateralNftId:_callOrder.collateralNftId
          });    
        if(_signer == tempInfo.borrower){
            tempInfo.borrowNowAmount=0;
            tempInfo.borrowLaterAmount=0;
            tempInfo.lender=address(0);
        }
        bytes32  infoTypeHash = keccak256("CallOrder(uint256 orderId,address borrower,address lender,address recipient,address collateralAsset,uint256 collateralAmount,address borrowAsset,uint256 borrowNowAmount,uint256 borrowNowMinAmount,uint256 interestAmount,uint256 borrowLaterMinAmount,uint256 borrowLaterAmount,uint256 expirationDate,uint256 platformFee,uint256 index,uint256 collateralAssetType,uint256 collateralNftId)");
        bytes32  _hashInfo= keccak256(abi.encode(
            infoTypeHash,
            tempInfo
        ));
        verifySigbature(_signer,_hashInfo,_signature);
    }


    function submitCallOrder(ILendFacet.CallOrder memory _callOrder,bytes calldata _borrowerSignature,bytes calldata _lenderSignature) external nonReentrant{
          verifyCallOrder(_callOrder);
          IVaultFacet vaultFacet= IVaultFacet(diamond);    
          handleCallOrderr(_callOrder.lender,_callOrder,_lenderSignature);
          handleCallOrderr(_callOrder.borrower,_callOrder,_borrowerSignature);       
          ILendFacet  lendFacet=ILendFacet(diamond);
          //store data
          _callOrder.index= lendFacet.getBorrowerCallOrderLength(_callOrder.borrower);
          lendFacet.setLenderCallOrder(_callOrder.lender,_callOrder);
          lendFacet.setBorrowerCallOrder(_callOrder.borrower,_callOrder.lender);
          usedOrderCall[_callOrder.orderId]=true;
          //tranfer lendFeePlatformRecipient
          address lendFeePlatformRecipient=lendFacet.getLendFeePlatformRecipient();
          IPlatformFacet platformFacet= IPlatformFacet(diamond);
          address eth=platformFacet.getEth();
          if(_callOrder.borrowAsset ==eth){
               if(lendFeePlatformRecipient !=address(0)){
                   IVault(_callOrder.borrower).invokeTransferEth(lendFeePlatformRecipient,_callOrder.platformFee);
               }  
               IVault(_callOrder.borrower).invokeTransferEth(_callOrder.recipient,(_callOrder.borrowNowAmount+_callOrder.interestAmount));
          }else{
                if(lendFeePlatformRecipient !=address(0)){
                    IVault(_callOrder.borrower).invokeTransfer(_callOrder.borrowAsset,lendFeePlatformRecipient,_callOrder.platformFee);
                }         
                 //tranfer metamask
                IVault(_callOrder.borrower).invokeTransfer(_callOrder.borrowAsset,_callOrder.recipient,(_callOrder.borrowNowAmount+_callOrder.interestAmount));
          } 
          //update position
          updatePosition(_callOrder.borrower,_callOrder.borrowAsset,1,0);
          //set CurrentVaultModule
          setFuncBlackAndWhiteList(2,_callOrder.borrower,_callOrder.lender,true);
          vaultFacet.setVaultLock(_callOrder.lender,true);
          emit   SubmitCallOrder(msg.sender,_callOrder);
    }



    function liquidateCallOrder(address _lender,bool _type) external payable nonReentrant{
            ILendFacet  lendFacet=ILendFacet(diamond);
            IVaultFacet vaultFacet= IVaultFacet(diamond);
            ILendFacet.CallOrder memory callOrder = ILendFacet(diamond).getLenderCallOrder(_lender);
            require(callOrder.lender != address(0),"LendModule:callOrder not exist");

            lendFacet.deleteLenderCallOrder(callOrder.lender);
            vaultFacet.setVaultLock(callOrder.lender,false);
            IPlatformFacet platformFacet= IPlatformFacet(diamond);
            address owner=IVault(callOrder.borrower).owner();
            address eth=platformFacet.getEth();
            if(msg.sender == owner || (IPlatformFacet(diamond).getIsVault(msg.sender) && IOwnable(msg.sender).owner() == owner)){
                if(_type){
                    //payLater time
                    //traferFrom borrowAsset to lender
                    if(callOrder.borrowAsset == eth){
                        IVault(callOrder.borrower).invokeTransferEth(callOrder.recipient,callOrder.borrowLaterAmount);
                    }else{
                        IERC20(callOrder.borrowAsset).safeTransferFrom(callOrder.borrower,callOrder.recipient,callOrder.borrowLaterAmount);
                    }                   
                    //tanferFrom collateralAsset to borrower
                    if(callOrder.collateralAssetType == 0){
                        if(callOrder.collateralAsset == eth){
                           IVault(callOrder.lender).invokeTransferEth(callOrder.borrower,callOrder.collateralAmount);
                        }else{
                           uint256 balance= IERC20(callOrder.collateralAsset).balanceOf(callOrder.lender);  
                           IVault(callOrder.lender).invokeTransfer(callOrder.collateralAsset,callOrder.borrower,balance);
                        }                   
                    }else if(callOrder.collateralAssetType == 1){
                         IVault(callOrder.lender).invokeTransferNft(callOrder.collateralAsset,callOrder.borrower,callOrder.collateralNftId);   
                    }else{
                        revert("LendModule:collateralAssetType error");
                    }  
                    updatePosition(callOrder.borrower,callOrder.borrowAsset,0);
                    updatePosition(callOrder.lender,callOrder.collateralAsset,0);
                    updatePosition(callOrder.borrower,callOrder.collateralAsset,0);
                }
            }else if(block.timestamp>callOrder.expirationDate){
                //unlock
            }else{
                revert("LendModule:liquidate time not yet");
            }
            setFuncBlackAndWhiteList(2,callOrder.borrower,callOrder.lender,false);
            emit LiquidateCallOrder(msg.sender,callOrder);
    }
    function setFuncBlackAndWhiteList(uint256 _orderType,address _blacker,address _whiter,bool _type) internal{
         IVaultFacet vaultFacet= IVaultFacet(diamond);
         ILendFacet  lendFacet=ILendFacet(diamond);
         if((_orderType==1 && lendFacet.getLenderPutOrderLength(_blacker)==0) || (_orderType==2 && lendFacet.getBorrowerCallOrderLength(_blacker)==0)){        
              vaultFacet.setFuncBlackList(_blacker,bytes4(keccak256("setVaultType(address,uint256)")),_type);
         }    
         vaultFacet.setFuncWhiteList(_whiter,bytes4(keccak256("replacementLiquidity(address,uint8,uint24,int24,int24)")),_type);
         vaultFacet.setFuncWhiteList(_whiter,bytes4(keccak256("liquidateStakeOrder(address,bool)")),_type);
    }                
}