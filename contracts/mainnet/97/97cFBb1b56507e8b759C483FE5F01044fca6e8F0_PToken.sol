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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../master/MasterStorage.sol";

interface IHelper {
    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 externalExchangeRate;
        uint256 depositAmount;
    }

    struct MWithdraw {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.MASTER_WITHDRAW
        address pToken;
        address user;
        uint256 withdrawAmount;
        uint256 targetChainId;
    }

    struct FBWithdraw {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.FB_WITHDRAW
        address pToken;
        address user;
        uint256 withdrawAmount;
        uint256 externalExchangeRate;
    }

    struct MRepay {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
        address loanAsset;
    }

    struct MBorrow {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.MASTER_BORROW
        address user;
        uint256 borrowAmount;
        address loanAsset;
        uint256 targetChainId;
    }

    struct FBBorrow {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
        address loanAsset;
    }

    struct SLiquidateBorrow {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pToken;
        uint256 externalExchangeRate;
    }

    struct SRefundLiquidator {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.SATELLITE_REFUND_LIQUIDATOR
        address liquidator;
        uint256 refundAmount;
        address loanAsset;
    }

    struct MLiquidateBorrow {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.MASTER_LIQUIDATE_BORROW
        address liquidator;
        address borrower;
        address seizeToken;
        uint256 seizeTokenChainId;
        address loanAsset;
        uint256 repayAmount;
    }

    struct LoanAssetBridge {
        uint256 metadata; // LEAVE ZERO
        bytes4 selector; // = Selector.LOAN_ASSET_BRIDGE
        address minter;
        bytes32 loanAssetNameHash;
        uint256 amount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface ICRMRouter {
    function getRiskPremium(
        address loanAsset,
        uint256 loanAssetChainId
    ) external view returns (uint256, uint256);

    function getLoanMarketPremium(
        address loanAsset,
        uint256 loanAssetChainId,
        address loanMarketUnderlying,
        uint256 loanMarketUnderlyingChainId
    ) external view returns (uint256 ratio, uint8 decimals);

    function getMaintenanceCollateralFactor(
        uint256 chainId,
        address asset
    ) external view returns (uint256 ratio, uint8 decimals);

    function getCollateralFactor(
        uint256 chainId,
        address asset
    ) external view returns (uint256 ratio, uint8 decimals);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../../interfaces/IHelper.sol";

abstract contract IMasterMessageHandler {
    function _satelliteLiquidateBorrow(
        address seizeToken,
        uint256 seizeTokenChainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens
    ) internal virtual;

    function _satelliteRefundLiquidator(
        uint256 chainId,
        address liquidator,
        uint256 refundAmount,
        address pToken,
        uint256 seizeAmount
    ) internal virtual;

    function masterLiquidationRequest(
        IHelper.MLiquidateBorrow memory params,
        uint256 chainId
    ) external virtual payable;

    function masterDeposit(
        IHelper.MDeposit memory params,
        uint256 chainId,
        uint256 exchangeRateTimestamp
    ) external virtual payable;

    function masterBorrow(
        IHelper.MBorrow memory params
    ) external virtual payable;

    function masterRepay(
        IHelper.MRepay memory params,
        uint256 chainId
    ) external virtual payable;

    function masterWithdraw(
        IHelper.MWithdraw memory params,
        uint256 exchangeRateTimestamp
    ) external payable virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

abstract contract IIRM {
    function setBorrowRate() external virtual /* OnlyRouter() */ returns (uint256 rate);
    function borrowInterestRatePerBlock() external view virtual returns (uint256);
    function borrowInterestRateDecimals() external view virtual returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IIRMRouter {
    function setBorrowRate(
        address loanAsset,
        uint256 loanAssetChainId
    ) external /* onlyMaster() */ returns (uint256 rate);

    function borrowInterestRatePerBlock(
        address loanAsset,
        uint256 loanAssetChainId
    ) external view returns (uint256);

    function borrowInterestRateDecimals(
        address loanAsset,
        uint256 loanAssetChainId
    ) external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../util/Selector.sol";
import "../util/AdminControl.sol";
import "../master/oracle/interfaces/IPrimeOracle.sol";
import "../middleLayer/interfaces/IMiddleLayer.sol";
import "../master/irm/router/interfaces/IIRMRouter.sol";
import "../master/crm/router/interfaces/ICRMRouter.sol";

abstract contract MasterStorage is Selector, AdminControl {

    /// @notice The address of MasterInternals
    address public masterInternals;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    // slither-disable-next-line unused-state
    IIRMRouter public interestRateModel;
    ICRMRouter public collateralRatioModel;
    IPrimeOracle public oracle;

    uint8 public immutable FACTOR_DECIMALS = 8;
    uint8 public immutable FEE_PRECISION = 18;
    uint8 public immutable EXCHANGE_RATE_DECIMALS = 18;
    uint256 public totalUsdCollateralBalance;

    struct MarketIndex {
        uint256 chainId;  /// @notice The chainId on which the market exists
        address pToken; /// @notice The asset for which this market exists, e.g. e.g. USP, pBTC, pETH.
    }

    /// @notice Represents one of the collateral available on a given satellite chain. Key: <chainId, token>
    struct Market {
        uint256 externalExchangeRate;
        uint256 lastExchangeRateTimestamp;
        uint256 totalCollateralValue;
        uint256 totalSupply;
        uint256 liquidityIncentive;
        uint256 protocolSeizeShare;
        address underlying;
        uint8 decimals;
        bool isListed;
        bool isRebase;
    }

    struct MarketMetadata {
        uint256 chainId;
        address asset;
    }

    /// @notice Array of all collateral market indices, lazily in descending order of totalCollateralValue.
    MarketIndex[] public collateralValueIndex;

    /// @notice Mapping of account addresses to pToken collateral balances
    mapping(uint256 /* chainId */ => mapping(address /* user */ => mapping(address /* token */ => uint256 /* collateralBalance */))) public pTokenCollateralBalances;

    /// @notice Mapping of tokens -> max acceptable percentage risk by the protocol; precision of 8; 1e8 = 100%
    /// @notice Set to 1 if you want to disable this asset
    mapping(uint256 /* chainId */ => mapping(address /* token */ => uint256)) public maxCollateralPercentages;

    /// @notice Mapping of all depositors currently using this collateral market.
    mapping(address /* user */ => mapping(uint256 /* chainId */ => mapping(address /* token */ => bool /* isMember */))) public accountMembership;

    /// @notice Official mapping of tokens -> Market metadata.
    mapping(uint256 /* chainId */ => mapping(address /* token */ => Market)) public markets;

    /// @notice All collateral markets in use by a particular user.
    mapping(address /* user */ => MarketIndex[]) public accountCollateralMarkets;

    /// @notice Container for borrow balance information
    struct BorrowSnapshot {
        uint256 principal; /// @notice Total balance (with accrued interest), after applying the most recent balance-changing action
        uint256 interestIndex; /// @notice Global borrowIndex as of the most recent balance-changing action
    }

    /// @notice Represents one of the loan markets available by all satellite loan agents. Key: <chainId, loanMarketAsset>
    struct LoanMarket {
        uint256 accrualBlockNumber; /// @notice Block number that interest was last accrued at
        uint256 totalReserves; /// @notice Total amount of protocol owned reserves of the underlying held in this market.
        uint256 totalBorrows; /// @notice Total amount of outstanding borrows of the underlying in this market.
		uint256 borrowIndex; /// @notice Accumulator of the total earned interest rate since the opening of the market.
        uint256 underlyingChainId; /// @notice The chainId on which the underlying asset exists.
        address underlying; /// @notice The underlying asset for which this loan market exists, e.g. USP, BTC, ETH.
        uint8 decimals; /// @notice The decimals of the underlying asset, e.g. 18.
        bool isListed;  /// @notice Whether or not this market is listed.

        // Ptoken specific assets
        uint256 totalSupplied;
        uint256 adminFee;
    }

    /// @notice Mapping of account addresses to outstanding borrow balance.
    mapping(address /* borrower */ => mapping(address /* loanAsset */ => mapping(uint256 /* chainId */ => BorrowSnapshot))) public accountLoanMarketBorrows;

    mapping(address /* borrower */ => mapping(address /* loanAsset */ => mapping(uint256 /* chainId */ => uint256))) public repayCredit;

    /// @notice Mapping of all borrowers currently using this loan market.
    mapping(address /* borrower */ => mapping(address /* loanAsset */ => mapping(uint256 /* chainId */ => bool /* isMember */))) public isLoanMarketMember;

    /// @notice All currently supported loan market assets, e.g. USP, pBTC, pETH.
    mapping(address /* loanAsset */ => mapping(uint256 /* chainId */ => LoanMarket)) public loanMarkets;

    struct LoanMarketMetadata {
        uint256 chainId;
        address loanAsset;
    }

    /// @notice Map satellite chainId + satellite loanMarketAsset to the mapped loanAsset
    mapping(uint256 /* chainId */ => mapping(address /* satelliteLoanMarketAsset */ => LoanMarketMetadata /* LoanMarketMetadata */)) public mappedLoanAssets;

    /// @notice All loan markets in use by a particular borrower.
    mapping(address /* borrower */ => LoanMarketMetadata[] /* loanAsset */) public accountLoanMarkets;

    struct liqBorrowParams {
        address seizeToken;
        uint256 seizeTokenChainId;
        address borrower;
        address liquidator;
        uint256 repayAmount; // this is the repay amount, denominated in pToken underlying
        LoanMarketMetadata loanMarket;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./IPrimeOracleGetter.sol";
import "./PrimeOracleStorage.sol";

/**
 * @title IPrimeOracle
 * @author Prime
 * @notice The core interface for the Prime Oracle
 */
abstract contract IPrimeOracle is PrimeOracleStorage {

    /**
     * @dev Emitted after the price data feed of an asset is set/updated
     * @param asset The address of the asset
     * @param chainId The chainId of the asset
     * @param feed The price feed of the asset
     */
    event SetPrimaryFeed(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @dev Emitted after the price data feed of an asset is set/updated
     * @param asset The address of the asset
     * @param feed The price feed of the asset
     */
    event SetSecondaryFeed(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @dev Emitted after the exchange rate data feed of a loan market asset is set/updated
     * @param asset The address of the asset
     * @param chainId The chainId of the asset
     * @param feed The price feed of the asset
     */
    event SetExchangRatePrimaryFeed(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @dev Emitted after the exchange rate data feed of a loan market asset is set/updated
     * @param asset The address of the asset
     * @param feed The price feed of the asset
     */
    event SetExchangeRateSecondaryFeed(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @notice Get the underlying price of a cToken asset
     * @param collateralMarketUnderlying The PToken collateral to get the sasset price of
     * @param chainId the chainId to get an asset price for
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(uint256 chainId, address collateralMarketUnderlying) external view virtual returns (uint256, uint8);

    /**
     * @notice Get the underlying borrow price of loanMarketAsset
     * @return The underlying borrow price
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPriceBorrow(
        uint256 chainId,
        address loanMarketUnderlying
    ) external view virtual returns (uint256, uint8);

    /**
     * @notice Get the exchange rate of loanMarketAsset to basis
     * @return The underlying exchange rate of loanMarketAsset to basis
     *  Zero means the price is unavailable.
     */
    function getBorrowAssetExchangeRate(
        address loanMarketOverlying,
        uint256 loanMarketOverlyingChainId,
        address loanMarketUnderlying,
        uint256 loanMarketUnderlyingChainId
    ) external view virtual returns (uint256 /* ratio */, uint8 /* decimals */);

    /*** Admin Functions ***/

    /**
     * @notice Sets or replaces price feeds of assets
     * @param asset The addresses of the assets
     * @param feed The addresses of the price feeds
     */
    function setPrimaryFeed(uint256 chainId, address asset, IPrimeOracleGetter feed) external virtual;

    /**
     * @notice Sets or replaces price feeds of assets
     * @param asset The addresses of the assets
     * @param feed The addresses of the price feeds
     */
    function setSecondaryFeed(uint256 chainId, address asset, IPrimeOracleGetter feed) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

/**
 * @title IPrimeOracleGetter
 * @author Prime
 * @notice Interface for the Prime price oracle.
 **/
interface IPrimeOracleGetter {

    /**
     * @dev Emitted after the price data feed of an asset is updated
     * @param asset The address of the asset
     * @param feed The price feed of the asset
     */
    event AssetFeedUpdated(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @notice Gets the price feed of an asset
     * @param asset The addresses of the asset
     * @return address of asset feed
     */
    function getAssetFeed(uint256 chainId, address asset) external view returns (address);

    /**
     * @notice Sets or replaces price feeds of assets
     * @param asset The addresses of the assets
     * @param feed The addresses of the price feeds
     */
    function setAssetFeed(uint256 chainId, address asset, address feed) external;

    /**
     * @notice Returns the price data in the denom currency
     * @param quoteToken A token to return price data for
     * @param denomToken A token to price quoteToken against
     * @param price of the asset from the oracle
     * @param decimals of the asset from the oracle
     **/
    function getAssetPrice(
        uint256 chainId,
        address quoteToken,
        address denomToken
    ) external view returns (uint256 price, uint8 decimals);

    /**
     * @notice Returns the price data in the denom currency
     * @param quoteToken A token to return price data for
     * @return return price of the asset from the oracle
     **/
    function getPriceDecimals(
        uint256 chainId,
        address quoteToken
    ) external view returns (uint256);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./IPrimeOracleGetter.sol";

/**
 * @title PrimeOracleStorage
 * @author Prime
 * @notice The core interface for the Prime Oracle storage variables
 */
abstract contract PrimeOracleStorage {
    address public uspAddress;
    // Map of asset price feeds (chainasset => priceSource)
    mapping(uint256 => mapping(address => IPrimeOracleGetter)) public primaryFeeds;
    mapping(uint256 => mapping(address => IPrimeOracleGetter)) public secondaryFeeds;
    uint8 public immutable RATIO_DECIMALS = 18;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    // Function reserved for sending messages that could be fallbacks, or are indirectly created by the user ie FB_BORROW
    function msend(
        uint256 dstChainId,
        bytes memory payload,
        address payable refundAddress,
        bool shouldForward
    ) external payable virtual;

    // Function reserved for sending messages that are directly created by a user ie MASTER_DEPOSIT
    function msend(
        uint256 dstChainId,
        bytes memory payload,
        address payable refundAddress,
        address route,
        bool shouldForward
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory _payload
    ) external virtual returns (bool success);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface ILendable {
    function receiveBorrow(
        address borrower,
        uint256 borrowAmount
    ) external;

    function processRepay(
        address repayer,
        uint256 repayAmount
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../../../interfaces/IHelper.sol";

interface ILoanAssetMessageHandler {
    function mintFromChain(
        IHelper.LoanAssetBridge memory params,
        uint256 srcChain
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../../PTokenBase.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PToken is
    PTokenBase,
    Initializable,
    UUPSUpgradeable
{

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() AdminControl(msg.sender) {}

    function initialize(
        address _underlying,
        address _middleLayer,
        uint256 _masterCID
    ) external payable initializer() {
        __UUPSUpgradeable_init();

        initializeBase(_underlying, _middleLayer, _masterCID);
    }

    function _authorizeUpgrade(address) internal override onlyAdmin() {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../../interfaces/ILendable.sol";

abstract contract IPToken is ILendable {

    /*** User Functions ***/

    function deposit(address route, uint256 amount) external virtual payable;

    function depositBehalf(address route, address user, uint256 amount) external virtual payable;

    /*** Admin Functions ***/

    function setMidLayer(address newMiddleLayer) external virtual;

    function deprecateMarket(
        bool deprecatedStatus
    ) external virtual;

    function freezeMarket(
        bool freezeStatus
    ) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../PTokenStorage.sol";

abstract contract IPTokenInternals is PTokenStorage {//is IERC20 {

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    // function _getCashPrior() internal virtual view returns (uint256);

    /**
     * @notice Retrieves the exchange rate for a given token.
     * @dev Will always be 1 for non-IB/Rebase tokens.
     */
    function _getExternalExchangeRate() internal virtual returns (uint256 externalExchangeRate);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../../../interfaces/IHelper.sol";

abstract contract IPTokenMessageHandler {

    function _sendDeposit(
        address route,
        address user,
        uint256 gas,
        uint256 depositAmount,
        uint256 externalExchangeRate
    ) internal virtual;

    function completeWithdraw(
        IHelper.FBWithdraw memory params
    ) external payable virtual;

    function seize(
        IHelper.SLiquidateBorrow memory params
    ) external payable virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./interfaces/IPToken.sol";
import "./PTokenModifiers.sol";
import "./PTokenEvents.sol";
import "../../util/CommonConsts.sol";

abstract contract PTokenAdmin is IPToken, PTokenModifiers, PTokenEvents, CommonConsts {
    function deprecateMarket(
        bool deprecatedStatus
    ) external override onlyAdmin() {
        emit MarketDeprecationChanged(isdeprecated, deprecatedStatus);

        isdeprecated = deprecatedStatus;
    }

    function freezeMarket(
        bool freezeStatus
    ) external override onlyAdmin() {
        emit MarketFreezeChanged(isFrozen, freezeStatus);

        isFrozen = freezeStatus;
    }

    function setMidLayer(
        address newMiddleLayer
    ) external override onlyAdmin() isContractIdentifier(newMiddleLayer, MIDDLE_LAYER_IDENTIFIER) {
        emit SetMiddleLayer(address(middleLayer), newMiddleLayer);

        middleLayer = IMiddleLayer(newMiddleLayer);
    }

    function changeRequestController(
        address newRequestController
    ) external onlyAdmin() {
        if (newRequestController == address(0)) revert AddressExpected();

        emit RequestControllerChanged(requestController, newRequestController);

        requestController = newRequestController;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PTokenInternals.sol";
import "./PTokenEvents.sol";
import "./PTokenMessageHandler.sol";
import "./PTokenAdmin.sol";

abstract contract PTokenBase is
    IPTokenInternals,
    PTokenInternals,
    PTokenEvents,
    PTokenMessageHandler,
    PTokenAdmin
{
    function initializeBase(
        address _underlying,
        address _middleLayer,
        uint256 _masterCID
    ) internal {
        setContractIdentifier(PTOKEN_IDENTIFIER);

        if (address(_middleLayer) == address(0)) revert AddressExpected();

        if (_masterCID == 0) revert ParamOutOfBounds();

        underlying = _underlying;
        middleLayer = IMiddleLayer(_middleLayer);
        masterCID = _masterCID;
        if (_underlying != address(0)) decimals = PTokenStorage(_underlying).decimals();
        else decimals = 18;

        admin = payable(msg.sender);
    }

    /**
    * @notice Deposits underlying asset into the protocol
    * @param amount The amount of underlying to deposit
    * @param route Route through which to send deposit
    */
    function deposit(
        address route,
        uint256 amount
    ) external virtual override payable sanityDeposit(amount, msg.sender) {
        uint256 externalExchangeRate = _getExternalExchangeRate();
        uint256 actualTransferAmount = _doTransferIn(underlying, msg.sender, amount);

        _sendDeposit(
            route,
            msg.sender,
            underlying == address(0)
                ? msg.value - actualTransferAmount
                : msg.value,
            actualTransferAmount,
            externalExchangeRate
        );
    }

    /**
    * @notice Deposits underlying asset into the protocol
    * @param route Route through which to send deposit
    * @param user The address of the user that is depositing funds
    * @param amount The amount of underlying to deposit
    */
    function depositBehalf(
        address route,
        address user,
        uint256 amount
    ) external virtual override payable onlyRequestController() sanityDeposit(amount, user) {
        uint256 externalExchangeRate = _getExternalExchangeRate();
        uint256 actualTransferAmount = _doTransferIn(underlying, user, amount);

        _sendDeposit(
            route,
            user,
            underlying == address(0)
                ? msg.value - actualTransferAmount
                : msg.value,
            actualTransferAmount,
            externalExchangeRate
        );
    }

    function receiveBorrow(
        address borrower,
        uint256 borrowAmount
    ) external /* override */ onlyRequestController() {
        if (borrowAmount == 0) revert AmountIsZero();

        _doTransferOut(borrower, underlying, borrowAmount);
    }

    function processRepay(
        address repayer,
        uint256 repayAmount
    ) external payable /* override */ onlyRequestController() {
        if (repayAmount == 0) revert AmountIsZero();

        _doTransferIn(underlying, repayer, repayAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../../master/irm/interfaces/IIRM.sol";

abstract contract PTokenEvents {

    /*** User Events ***/

    event DepositSent(
        address indexed user,
        address indexed pToken,
        uint256 amount
    );

    event WithdrawApproved(
        address indexed user,
        address indexed pToken,
        uint256 withdrawAmount,
        bool isWithdrawAllowed
    );

    /*** Admin Events ***/

    event SetMiddleLayer(
        address oldMiddleLayer,
        address newMiddleLayer
    );

    event MarketDeprecationChanged(
        bool previousStatus,
        bool newStatus
    );

    event MarketFreezeChanged(
        bool previousStatus,
        bool newStatus
    );

    event RequestControllerChanged(
        address oldRequestController,
        address newRequestController
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./interfaces/IPTokenInternals.sol";
import "../../util/dependency/compound/CTokenInterfaces.sol";

abstract contract PTokenInternals is IPTokenInternals {

    function _getExternalExchangeRate() internal virtual override returns (uint256 externalExchangeRate) {
        externalExchangeRate = 10**EXCHANGE_RATE_DECIMALS;
        if (currentExchangeRate != externalExchangeRate) currentExchangeRate = externalExchangeRate;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./PTokenStorage.sol";
import "./PTokenInternals.sol";
import "./PTokenModifiers.sol";
import "./PTokenEvents.sol";
import "../../interfaces/IHelper.sol";
import "./interfaces/IPTokenMessageHandler.sol";
import "../../util/SafeTransfers.sol";

abstract contract PTokenMessageHandler is
    IPTokenInternals,
    IPTokenMessageHandler,
    PTokenModifiers,
    PTokenEvents,
    SafeTransfers
{

    // slither-disable-next-line assembly
    function _sendDeposit(
        address route,
        address user,
        uint256 gas,
        uint256 depositAmount,
        uint256 externalExchangeRate
    ) internal virtual override {

        bytes memory payload = abi.encode(
            IHelper.MDeposit({
                metadata: uint256(0),
                selector: MASTER_DEPOSIT,
                user: user,
                pToken: address(this),
                externalExchangeRate: externalExchangeRate,
                depositAmount: depositAmount
            })
        );

        middleLayer.msend{ value: gas }(
            masterCID,
            payload,
            payable(user),
            route,
            true
        );

        emit DepositSent(user, address(this), depositAmount);
    }

    /**
     * @notice Transfers tokens to the withdrawer.
     */
    function completeWithdraw(
        IHelper.FBWithdraw memory params
    ) external payable virtual override onlyMid() {
        if (isFrozen) revert MarketIsFrozen(address(this));

        emit WithdrawApproved(
            params.user,
            address(this),
            params.withdrawAmount,
            true
        );

        _doTransferOut(params.user, underlying, params.withdrawAmount);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another PToken.
     *  Its absolutely critical to use msg.sender as the seizer pToken and not a parameter.
     */
    function seize(
        IHelper.SLiquidateBorrow memory params
    ) external payable virtual override onlyMid() {
        if (isFrozen) revert MarketIsFrozen(address(this));

        _doTransferOut(params.liquidator, underlying, params.seizeTokens);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./PTokenStorage.sol";
import "../../util/CommonModifiers.sol";

abstract contract PTokenModifiers is PTokenStorage, CommonModifiers {

    modifier onlyMid() {
        if (msg.sender != address(middleLayer)) {
            revert OnlyMiddleLayer();
        }
        _;
    }

    modifier onlyRequestController() {
        if (msg.sender != requestController) revert OnlyRequestController();
        _;
    }

    modifier sanityDeposit(uint256 amount, address user) {
        if (amount == 0) revert ExpectedDepositAmount();
        if (user == address(0)) revert AddressExpected();
        if (isFrozen) revert MarketIsFrozen(address(this));
        if (isdeprecated) revert MarketIsdeprecated(address(this));

        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../../util/Selector.sol";
import "../../util/AdminControl.sol";
import "../../middleLayer/interfaces/IMiddleLayer.sol";

abstract contract PTokenStorage is Selector, AdminControl {

    /**
     * @notice EIP-20 token for this PToken
     */
    address public underlying;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public constant EXCHANGE_RATE_DECIMALS = 18;

    /**
     * @notice Master ChainId
     */
    // slither-disable-next-line unused-state
    uint256 public masterCID;

    /**
    * @notice Indicates whether the market is accepting deposits
    */
    bool public isdeprecated;

    /**
     * @notice Indicates whether the market is frozen
     */
    bool public isFrozen;

    /**
     * @notice The decimals of the underlying asset of this pToken's underlying, e.g. ETH of CETH of PCETH.
     */
    uint8 public underlyingDecimalsOfUnderlying;

    /**
     * @notice The current exchange rate between pToken deposits and underlying
     */
    uint256 public currentExchangeRate;

    /**
     * @notice MiddleLayer Interface
     */
    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    address internal requestController;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../../../interfaces/IHelper.sol";

abstract contract IRequestController {

    /*** User Functions ***/

    function deposit(
        address route,
        address user,
        uint256 amount,
        address pTokenAddress
    ) external payable virtual;

    function withdraw(
        address route,
        uint256 withdrawAmount,
        address pToken,
        uint256 targetChainId
    ) external virtual payable;

    function borrow(
        address route,
        address loanMarketAsset,
        uint256 borrowAmount,
        uint256 targetChainId
    ) external payable virtual;

    function repayBorrow(
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) external payable virtual returns (uint256);

    function repayBorrowBehalf(
        address borrower,
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) external payable virtual returns (uint256);

    function borrowApproved(
        IHelper.FBBorrow memory params
    ) external payable virtual;

    function unlockLiquidationRefund(
        IHelper.SRefundLiquidator memory params
    ) external payable virtual;

    /*** Admin Functions ***/

    function setMidLayer(address newMiddleLayer) external virtual;

    function deprecateMarket(address loanMarketAsset, bool deprictedStatus) external virtual;

    function freezeLoanMarket(address loanMarketAsset, bool freezeStatus) external virtual;

    function freezePToken(address pToken, bool freezeStatus) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./CommonErrors.sol";

abstract contract AdminControl is CommonErrors {

    address public admin; /// @notice The administrator for this contract.
    address public adminCandidate; /// @notice A proposed administrator candidate for this contract.

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _admin) {
        if (_admin == address(0)) revert AddressExpected();

        admin = _admin;
    }

    /**
     * @dev Emitted after an admin proposal is submitted.
     * @param currentAdmin The address of the previous admin
     * @param adminCandidate The address of the new admin
     */
    event ProposeAdmin(
        address currentAdmin,
        address adminCandidate
    );

    /**
     * @dev Emitted after the admin is updated.
     * @param oldAdmin The address of the previous admin
     * @param newAdmin The address of the new admin
     */
    event ChangeAdmin(
        address oldAdmin,
        address newAdmin
    );

    /**
     * @dev Verifies the current message sender is admin.
     */
    modifier onlyAdmin() {
        if(msg.sender != admin) revert OnlyAdmin();
        _;
    }

    /**
     * @dev Verifies the current message sender is admin.
     */
    modifier onlyAdminCandidate() {
        if(msg.sender != adminCandidate) revert OnlyAdminCandidate();
        _;
    }

    /**
     * @notice Proposese a new admin.
     * @param _adminCandidate The new admin being proposed.
     */
    function proposeAdmin(
        address _adminCandidate
    ) external onlyAdmin() {
        if (_adminCandidate == address(0)) revert AddressExpected();

        adminCandidate = _adminCandidate;

        emit ProposeAdmin(admin, _adminCandidate);
    }

    /**
     * @notice Revokes the proposed admin candidate.
     */
    function revokeCandidate() external onlyAdmin() {
        delete adminCandidate;
    }

    /**
     * @notice Called by the candidate to accept the role of admin.
     */
    function acceptAdministration() external onlyAdminCandidate() {
        emit ChangeAdmin(admin, adminCandidate);

        admin = adminCandidate;

        delete adminCandidate;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./CommonErrors.sol";

abstract contract CommonConsts is CommonErrors {
    function setContractIdentifier(bytes32 identifier) internal {
        _CONTRACT_ID = identifier;
    }

    function CONTRACT_ID() external view returns (bytes32) {return _CONTRACT_ID;}

    modifier isContractIdentifier(address target, bytes32 identifier) {
        (bool success, bytes memory ret) = target.staticcall(
            abi.encodeWithSelector(
                CommonConsts.CONTRACT_ID.selector
            )
        );

        if (!success) revert ContractNoIdentifier(target);

        (bytes32 data) = abi.decode(ret, (bytes32));

        if (data != identifier) revert UnexpectedIdentifier(data, identifier);

        _;
    }

    bytes32 private _CONTRACT_ID;

    bytes32 internal constant MIDDLE_LAYER_IDENTIFIER = keccak256("contracts/middleLayer/MiddleLayer.sol");
    bytes32 internal constant ECC_IDENTIFIER = keccak256("contracts/ecc/ECC.sol");
    bytes32 internal constant LOAN_ASSET_IDENTIFIER = keccak256("contracts/satellite/loanAsset/LoanAsset.sol");
    bytes32 internal constant PTOKEN_IDENTIFIER = keccak256("contracts/satellite/pToken/PTokenBase.sol");
    bytes32 internal constant REQUEST_CONTROLLER_IDENTIFIER = keccak256("contracts/satellite/requestController/RequestController.sol");
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

// NOTE: When adding error messages, make sure to sort lines ascending
abstract contract CommonErrors {
    error AccountNoAssets(address account);
    error AddressExpected();
    error AlreadyInitialized();
    error AmountIsZero();
    error BorrowTooMuch();
    error ChainIdExpected();
    error ClaimerDenylisted();
    error ContractNoIdentifier(address);
    error EccMessageAlreadyProcessed();
    error EnterCollMarketFailed();
    error EnterLoanMarketFailed();
    error ExitCollMarketFailed();
    error ExitLoanMarketFailed();
    error ExpectedBorrowAmount();
    error ExpectedBridgeAmount();
    error ExpectedDepositAmount();
    error ExpectedMintAmount();
    error ExpectedRepayAmount();
    error ExpectedTradeAmount();
    error ExpectedTransferAmount();
    error ExpectedValue();
    error ExpectedWithdrawAmount();
    error ExpectedNewZroPaymentAddress();
    error GasAmountExpected();
    error IncorrectTargetAddress(address receivedAddress, address expectedAddress);
    error IncorrectTargetChainId(uint256 receivedChainId, uint256 expectedChainId);
    error InsufficientLiquidity();
    error InsufficientReserves();
    error InsufficientRewards();
    error InvalidExchangeRate();
    error InvalidLiquidityIncentive();
    error InvalidProtocolSeizeShare();
    error InvalidPayload();
    error InvalidPrecision();
    error InvalidPrice();
    error InvalidRatio();
    error InvalidRiskPremium();
    error InvalidSelector();
    error LiquidateDisallowed();
    error LoanMarketIsListed(bool status);
    error MarketExists();
    error MarketDoesNotExist();
    error MarketIsdeprecated(address market);
    error MarketIsFrozen(address market);
    error MarketIsUnlisted();
    error MarketNotListed();
    error MaxMarketsEntered();
    error MiddleLayerExpected();
    error MiddleLayerPaused();
    error MissingParameter();
    error MsgDataExpected();
    error MsgValueTooLow();
    error MultiCallFailed(uint256 index, bytes data, bytes reason);
    error MultiStaticCallFailed(uint256 index, bytes data);
    error NameExpected();
    error NotEnoughBalance(address token, address who);
    error NothingToWithdraw();
    error NotInMarket(uint256 chainId, address token);
    error OnlyAccount();
    error OnlyAdmin();
    error OnlyAdminCandidate();
    error OnlyAuth();
    error OnlyGateway();
    error OnlyRequestController();
    error OnlyLayerZeroEndpoint();
    error OnlyMasterState();
    error OnlyMiddleLayer();
    error OnlyMintAuth();
    error OnlyPToken();
    error OnlyRelayer();
    error OnlyRoute();
    error OnlyRouter();
    error PairNotSupported(address loanAsset, address tradeAsset);
    error ParamOutOfBounds();
    error PTokenIsFrozen(address pToken);
    error RebasingTokensUnableToBeLoanable();
    error Reentrancy();
    error RepayTooMuch(uint256 repayAmount, uint256 maxAmount);
    error RewardDoesNotExist();
    error RewardExists();
    error RewardNotListed();
    error RouteExists();
    error RouteNotSupported(address route);
    error RsmNotFound();
    error SeizeTooMuch();
    error SymbolExpected();
    error TradeAssetNotSupported();
    error TransferFailed(address from, address dest, uint256 amount);
    error TransferFromFailed(address from, address dest, uint256 amount);
    error TransferPaused();
    error UnexpectedDelta();
    error UnexpectedIdentifier(bytes32 got, bytes32 expected);
    error UnexpectedSelector(bytes4 selector);
    error UnexpectedValueDelta();
    error UnknownRevert();
    error UnstakeTooMuch();
    error UspAddressZero();
    error WithdrawTooMuch();
    error GasLimitTooLow(uint256 gasLimit);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./CommonErrors.sol";
import "../middleLayer/interfaces/IMiddleLayer.sol";

abstract contract CommonModifiers is CommonErrors {

    /**
    * @dev Guard variable for re-entrancy checks
    */
    bool internal entered;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    */
    modifier nonReentrant() {
        if (entered) revert Reentrancy();
        entered = true;
        _;
        entered = false; // get a gas-refund post-Istanbul
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    // Maximum borrow rate that can ever be applied (.0005% / block)
    uint internal immutable borrowRateMaxMantissa = 0.0005e16;

    // Maximum fraction of interest that can be set aside for reserves
    uint internal immutable reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    // Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    // Official record of token balances for each account
    mapping (address => uint) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint public immutable protocolSeizeShareMantissa = 2.8e16; //2.8%
}

abstract contract CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public immutable isCToken = true;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Deposit(address minter, uint mintAmount, uint depositAmount);

    /**
     * @notice Event emitted when tokens are withdrawed
     */
    event Withdraw(address withdrawer, uint withdrawAmount, uint withdrawTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);
    function approve(address spender, uint amount) virtual external returns (bool);
    function allowance(address owner, address spender) virtual external view returns (uint);
    function balanceOf(address owner) virtual external view returns (uint);
    function balanceOfUnderlying(address owner) virtual external returns (uint);
    function getAccountSnapshot(address account) virtual external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() virtual external view returns (uint);
    function supplyRatePerBlock() virtual external view returns (uint);
    function totalBorrowsCurrent() virtual external returns (uint);
    function borrowBalanceCurrent(address account) virtual external returns (uint);
    function borrowBalanceStored(address account) virtual external view returns (uint);
    function exchangeRateCurrent() virtual external returns (uint);
    function exchangeRateStored() virtual external view returns (uint);
    function getCash() virtual external view returns (uint);
    function accrueInterest() virtual external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) virtual external returns (uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) virtual external returns (uint);
    function _acceptAdmin() virtual external returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) virtual external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) virtual external returns (uint);
    function _reduceReserves(uint reduceAmount) virtual external returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) virtual external returns (uint);
}

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public immutable isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual external view returns (uint);
}

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public immutable isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) virtual external returns (uint[] memory);
    function exitMarket(address cToken) virtual external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) virtual external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint depositAmount) virtual external;

    function withdrawAllowed(address cToken, address withdrawer, uint withdrawTokens) virtual external returns (uint);
    function withdrawVerify(address cToken, address withdrawer, uint withdrawAmount, uint withdrawTokens) virtual external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) virtual external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) virtual external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) virtual external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) virtual external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) virtual external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) virtual external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) virtual external view returns (uint, uint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./CommonErrors.sol";

abstract contract SafeTransfers is CommonErrors {

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    // slither-disable-next-line assembly
    function _doTransferIn(
        address underlying,
        address user,
        uint256 amount
    ) internal virtual returns (uint256) {
        if (amount == 0) revert TransferFailed(msg.sender, address(this), amount);

        if (underlying == address(0)) {
            if (msg.value < amount) revert TransferFailed(user, address(this), amount);
            return amount;
        }

        IERC20 token = IERC20(underlying);
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));

        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transferFrom(user, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(user, address(this), amount);

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
    * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
    *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
    *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
    *      it is >= amount, this should not revert in normal conditions.
    *
    *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    */
    // slither-disable-next-line assembly
    function _doTransferOut(
        address to,
        address underlying,
        uint256 amount
    ) internal virtual {
        if (amount == 0) revert TransferFailed(address(this), to, amount);
        if (underlying == address(0)) {
            if (address(this).balance < amount) revert TransferFailed(address(this), to, amount);
            payable(to).transfer(amount);
            return;
        }
        IERC20 token = IERC20(underlying);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(address(this), msg.sender, amount);
    }

    function _doTransferFrom(
        address from,
        address to,
        address underlying,
        uint256 amount
    ) internal virtual returns (uint256) {
        if (from == address(this)) {
            revert("Use _doTransferOut()");
        }
        if (underlying == address(0)) {
            revert("Requires manual impl");
        }
        IERC20 token = IERC20(underlying);
        uint256 balanceBefore = token.balanceOf(to);

        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transferFrom(from, to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(msg.sender, address(this), amount);

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../master/interfaces/IMasterMessageHandler.sol";
import "../satellite/requestController/interfaces/IRequestController.sol";
import "../satellite/pToken/interfaces/IPTokenMessageHandler.sol";
import "../satellite/loanAsset/interfaces/ILoanAssetMessageHandler.sol";

abstract contract Selector {
    bytes4 constant MASTER_REPAY = IMasterMessageHandler.masterRepay.selector;
    bytes4 constant MASTER_BORROW = IMasterMessageHandler.masterBorrow.selector;
    bytes4 constant MASTER_DEPOSIT = IMasterMessageHandler.masterDeposit.selector;
    bytes4 constant MASTER_WITHDRAW = IMasterMessageHandler.masterWithdraw.selector;
    bytes4 constant MASTER_LIQUIDATE_BORROW = IMasterMessageHandler.masterLiquidationRequest.selector;

    bytes4 constant FB_BORROW = IRequestController.borrowApproved.selector;
    bytes4 constant SATELLITE_REFUND_LIQUIDATOR = IRequestController.unlockLiquidationRefund.selector;

    bytes4 constant FB_WITHDRAW = IPTokenMessageHandler.completeWithdraw.selector;
    bytes4 constant SATELLITE_LIQUIDATE_BORROW = IPTokenMessageHandler.seize.selector;

    bytes4 constant LOAN_ASSET_BRIDGE = ILoanAssetMessageHandler.mintFromChain.selector;
}