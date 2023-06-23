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
import "./Addresses.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Interfaces/ISortedVessels.sol";
import "./Interfaces/IVesselManager.sol";

/*
 * A sorted doubly linked list with nodes sorted in descending order.
 *
 * Nodes map to active Vessels in the system - the ID property is the address of a Vessel owner.
 * Nodes are ordered according to their current nominal individual collateral ratio (NICR),
 * which is like the ICR but without the price, i.e., just collateral / debt.
 *
 * The list optionally accepts insert position hints.
 *
 * NICRs are computed dynamically at runtime, and not stored on the Node. This is because NICRs of active Vessels
 * change dynamically as liquidation events occur.
 *
 * The list relies on the fact that liquidation events preserve ordering: a liquidation decreases the NICRs of all active Vessels,
 * but maintains their order. A node inserted based on current NICR will maintain the correct position,
 * relative to it's peers, as rewards accumulate, as long as it's raw collateral and debt have not changed.
 * Thus, Nodes remain sorted by current NICR.
 *
 * Nodes need only be re-inserted upon a Vessel operation - when the owner adds or removes collateral or debt
 * to their position.
 *
 * The list is a modification of the following audited SortedDoublyLinkedList:
 * https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
 *
 *
 * Changes made in the Gravita implementation:
 *
 * - Keys have been removed from nodes
 *
 * - Ordering checks for insertion are performed by comparing an NICR argument to the current NICR, calculated at runtime.
 *   The list relies on the property that ordering by ICR is maintained as the ETH:USD price varies.
 *
 * - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
 */
contract SortedVessels is OwnableUpgradeable, UUPSUpgradeable, ISortedVessels, Addresses {
	string public constant NAME = "SortedVessels";

	// Information for a node in the list
	struct Node {
		bool exists;
		address nextId; // Id of next node (smaller NICR) in the list
		address prevId; // Id of previous node (larger NICR) in the list
	}

	// Information for the list
	struct Data {
		address head; // Head of the list. Also the node in the list with the largest NICR
		address tail; // Tail of the list. Also the node in the list with the smallest NICR
		uint256 size; // Current size of the list
		// Depositor address => node
		mapping(address => Node) nodes; // Track the corresponding ids for each node in the list
	}

	// Collateral type address => ordered list
	mapping(address => Data) public data;

	// --- Initializer ---

	function initialize() public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
	}

	/*
	 * @dev Add a node to the list
	 * @param _id Node's id
	 * @param _NICR Node's NICR
	 * @param _prevId Id of previous node for the insert position
	 * @param _nextId Id of next node for the insert position
	 */

	function insert(address _asset, address _id, uint256 _NICR, address _prevId, address _nextId) external override {
		_requireCallerIsBOorVesselM();
		_insert(_asset, _id, _NICR, _prevId, _nextId);
	}

	function _insert(address _asset, address _id, uint256 _NICR, address _prevId, address _nextId) internal {
		Data storage assetData = data[_asset];

		// List must not already contain node
		require(!_contains(assetData, _id), "SortedVessels: List already contains the node");
		// Node id must not be null
		require(_id != address(0), "SortedVessels: Id cannot be zero");
		// NICR must be non-zero
		require(_NICR != 0, "SortedVessels: NICR must be positive");

		address prevId = _prevId;
		address nextId = _nextId;

		if (!_validInsertPosition(_asset, _NICR, prevId, nextId)) {
			// Sender's hint was not a valid insert position
			// Use sender's hint to find a valid insert position
			(prevId, nextId) = _findInsertPosition(_asset, _NICR, prevId, nextId);
		}

		Node storage node = assetData.nodes[_id];
		node.exists = true;

		if (prevId == address(0) && nextId == address(0)) {
			// Insert as head and tail
			assetData.head = _id;
			assetData.tail = _id;
		} else if (prevId == address(0)) {
			// Insert before `prevId` as the head
			node.nextId = assetData.head;
			assetData.nodes[assetData.head].prevId = _id;
			assetData.head = _id;
		} else if (nextId == address(0)) {
			// Insert after `nextId` as the tail
			node.prevId = assetData.tail;
			assetData.nodes[assetData.tail].nextId = _id;
			assetData.tail = _id;
		} else {
			// Insert at insert position between `prevId` and `nextId`
			node.nextId = nextId;
			node.prevId = prevId;
			assetData.nodes[prevId].nextId = _id;
			assetData.nodes[nextId].prevId = _id;
		}

		assetData.size = assetData.size + 1;
		emit NodeAdded(_asset, _id, _NICR);
	}

	function remove(address _asset, address _id) external override {
		_requireCallerIsVesselManager();
		_remove(_asset, _id);
	}

	/*
	 * @dev Remove a node from the list
	 * @param _id Node's id
	 */
	function _remove(address _asset, address _id) internal {
		Data storage assetData = data[_asset];

		// List must contain the node
		require(_contains(assetData, _id), "SortedVessels: List does not contain the id");

		Node storage node = assetData.nodes[_id];
		if (assetData.size > 1) {
			// List contains more than a single node
			if (_id == assetData.head) {
				// The removed node is the head
				// Set head to next node
				assetData.head = node.nextId;
				// Set prev pointer of new head to null
				assetData.nodes[assetData.head].prevId = address(0);
			} else if (_id == assetData.tail) {
				// The removed node is the tail
				// Set tail to previous node
				assetData.tail = node.prevId;
				// Set next pointer of new tail to null
				assetData.nodes[assetData.tail].nextId = address(0);
			} else {
				// The removed node is neither the head nor the tail
				// Set next pointer of previous node to the next node
				assetData.nodes[node.prevId].nextId = node.nextId;
				// Set prev pointer of next node to the previous node
				assetData.nodes[node.nextId].prevId = node.prevId;
			}
		} else {
			// List contains a single node
			// Set the head and tail to null
			assetData.head = address(0);
			assetData.tail = address(0);
		}

		delete assetData.nodes[_id];
		assetData.size = assetData.size - 1;
		emit NodeRemoved(_asset, _id);
	}

	/*
	 * @dev Re-insert the node at a new position, based on its new NICR
	 * @param _id Node's id
	 * @param _newNICR Node's new NICR
	 * @param _prevId Id of previous node for the new insert position
	 * @param _nextId Id of next node for the new insert position
	 */
	function reInsert(address _asset, address _id, uint256 _newNICR, address _prevId, address _nextId) external override {
		_requireCallerIsBOorVesselM();
		// List must contain the node
		require(contains(_asset, _id), "SortedVessels: List does not contain the id");
		// NICR must be non-zero
		require(_newNICR != 0, "SortedVessels: NICR must be positive");

		// Remove node from the list
		_remove(_asset, _id);

		_insert(_asset, _id, _newNICR, _prevId, _nextId);
	}

	/*
	 * @dev Checks if the list contains a node
	 */
	function contains(address _asset, address _id) public view override returns (bool) {
		return data[_asset].nodes[_id].exists;
	}

	function _contains(Data storage _dataAsset, address _id) internal view returns (bool) {
		return _dataAsset.nodes[_id].exists;
	}

	/*
	 * @dev Checks if the list is empty
	 */
	function isEmpty(address _asset) public view override returns (bool) {
		return data[_asset].size == 0;
	}

	/*
	 * @dev Returns the current size of the list
	 */
	function getSize(address _asset) external view override returns (uint256) {
		return data[_asset].size;
	}

	/*
	 * @dev Returns the first node in the list (node with the largest NICR)
	 */
	function getFirst(address _asset) external view override returns (address) {
		return data[_asset].head;
	}

	/*
	 * @dev Returns the last node in the list (node with the smallest NICR)
	 */
	function getLast(address _asset) external view override returns (address) {
		return data[_asset].tail;
	}

	/*
	 * @dev Returns the next node (with a smaller NICR) in the list for a given node
	 * @param _id Node's id
	 */
	function getNext(address _asset, address _id) external view override returns (address) {
		return data[_asset].nodes[_id].nextId;
	}

	/*
	 * @dev Returns the previous node (with a larger NICR) in the list for a given node
	 * @param _id Node's id
	 */
	function getPrev(address _asset, address _id) external view override returns (address) {
		return data[_asset].nodes[_id].prevId;
	}

	/*
	 * @dev Check if a pair of nodes is a valid insertion point for a new node with the given NICR
	 * @param _NICR Node's NICR
	 * @param _prevId Id of previous node for the insert position
	 * @param _nextId Id of next node for the insert position
	 */
	function validInsertPosition(
		address _asset,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) external view override returns (bool) {
		return _validInsertPosition(_asset, _NICR, _prevId, _nextId);
	}

	function _validInsertPosition(
		address _asset,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) internal view returns (bool) {
		if (_prevId == address(0) && _nextId == address(0)) {
			// `(null, null)` is a valid insert position if the list is empty
			return isEmpty(_asset);
		} else if (_prevId == address(0)) {
			// `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
			return data[_asset].head == _nextId && _NICR >= IVesselManager(vesselManager).getNominalICR(_asset, _nextId);
		} else if (_nextId == address(0)) {
			// `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
			return data[_asset].tail == _prevId && _NICR <= IVesselManager(vesselManager).getNominalICR(_asset, _prevId);
		} else {
			// `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_NICR` falls between the two nodes' NICRs
			return
				data[_asset].nodes[_prevId].nextId == _nextId &&
				IVesselManager(vesselManager).getNominalICR(_asset, _prevId) >= _NICR &&
				_NICR >= IVesselManager(vesselManager).getNominalICR(_asset, _nextId);
		}
	}

	/*
	 * @dev Descend the list (larger NICRs to smaller NICRs) to find a valid insert position
	 * @param _vesselManager VesselManager contract, passed in as param to save SLOAD’s
	 * @param _NICR Node's NICR
	 * @param _startId Id of node to start descending the list from
	 */
	function _descendList(address _asset, uint256 _NICR, address _startId) internal view returns (address, address) {
		Data storage assetData = data[_asset];

		// If `_startId` is the head, check if the insert position is before the head
		if (assetData.head == _startId && _NICR >= IVesselManager(vesselManager).getNominalICR(_asset, _startId)) {
			return (address(0), _startId);
		}

		address prevId = _startId;
		address nextId = assetData.nodes[prevId].nextId;

		// Descend the list until we reach the end or until we find a valid insert position
		while (prevId != address(0) && !_validInsertPosition(_asset, _NICR, prevId, nextId)) {
			prevId = assetData.nodes[prevId].nextId;
			nextId = assetData.nodes[prevId].nextId;
		}

		return (prevId, nextId);
	}

	/*
	 * @dev Ascend the list (smaller NICRs to larger NICRs) to find a valid insert position
	 * @param _vesselManager VesselManager contract, passed in as param to save SLOAD’s
	 * @param _NICR Node's NICR
	 * @param _startId Id of node to start ascending the list from
	 */
	function _ascendList(address _asset, uint256 _NICR, address _startId) internal view returns (address, address) {
		Data storage assetData = data[_asset];

		// If `_startId` is the tail, check if the insert position is after the tail
		if (assetData.tail == _startId && _NICR <= IVesselManager(vesselManager).getNominalICR(_asset, _startId)) {
			return (_startId, address(0));
		}

		address nextId = _startId;
		address prevId = assetData.nodes[nextId].prevId;

		// Ascend the list until we reach the end or until we find a valid insertion point
		while (nextId != address(0) && !_validInsertPosition(_asset, _NICR, prevId, nextId)) {
			nextId = assetData.nodes[nextId].prevId;
			prevId = assetData.nodes[nextId].prevId;
		}

		return (prevId, nextId);
	}

	/*
	 * @dev Find the insert position for a new node with the given NICR
	 * @param _NICR Node's NICR
	 * @param _prevId Id of previous node for the insert position
	 * @param _nextId Id of next node for the insert position
	 */
	function findInsertPosition(
		address _asset,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) external view override returns (address, address) {
		return _findInsertPosition(_asset, _NICR, _prevId, _nextId);
	}

	function _findInsertPosition(
		address _asset,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) internal view returns (address, address) {
		address prevId = _prevId;
		address nextId = _nextId;

		if (prevId != address(0)) {
			if (!contains(_asset, prevId) || _NICR > IVesselManager(vesselManager).getNominalICR(_asset, prevId)) {
				// `prevId` does not exist anymore or now has a smaller NICR than the given NICR
				prevId = address(0);
			}
		}

		if (nextId != address(0)) {
			if (!contains(_asset, nextId) || _NICR < IVesselManager(vesselManager).getNominalICR(_asset, nextId)) {
				// `nextId` does not exist anymore or now has a larger NICR than the given NICR
				nextId = address(0);
			}
		}

		if (prevId == address(0) && nextId == address(0)) {
			// No hint - descend list starting from head
			return _descendList(_asset, _NICR, data[_asset].head);
		} else if (prevId == address(0)) {
			// No `prevId` for hint - ascend list starting from `nextId`
			return _ascendList(_asset, _NICR, nextId);
		} else if (nextId == address(0)) {
			// No `nextId` for hint - descend list starting from `prevId`
			return _descendList(_asset, _NICR, prevId);
		} else {
			// Descend list starting from `prevId`
			return _descendList(_asset, _NICR, prevId);
		}
	}

	// --- 'require' functions ---

	function _requireCallerIsVesselManager() internal view {
		require(msg.sender == vesselManager, "SortedVessels: Caller is not the VesselManager");
	}

	function _requireCallerIsBOorVesselM() internal view {
		require(
			msg.sender == borrowerOperations || msg.sender == vesselManager,
			"SortedVessels: Caller is neither BO nor VesselM"
		);
	}

	function authorizeUpgrade(address newImplementation) public {
		_authorizeUpgrade(newImplementation);
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}
}