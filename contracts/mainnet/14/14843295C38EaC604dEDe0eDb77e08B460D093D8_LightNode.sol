// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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
interface IERC1967 {
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
interface IBeacon {
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

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade is IERC1967 {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
library StorageSlot {
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

pragma solidity 0.8.20;

library BGLS {
    struct G1 {
        uint256 x;
        uint256 y;
    }
    struct G2 {
        uint256 xr;
        uint256 xi;
        uint256 yr;
        uint256 yi;
    }

    struct G1Bytes {
        bytes32 x;
        bytes32 y;
    }

    struct G2Bytes {
        bytes32 xr;
        bytes32 xi;
        bytes32 yr;
        bytes32 yi;
    }

    /* give the constant value for library
    G1 constant g1 = G1(1, 2);
    G2 constant g2 =
        G2(
            0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed,
            0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
            0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa,
            0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b
        );
    */
    uint256 constant g1x = 1;
    uint256 constant g1y = 2;
    uint256 constant g2xr = 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 constant g2xi = 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 constant g2yr = 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;
    uint256 constant g2yi = 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;

    //

    function bytesToUint(bytes32 b) internal pure returns (uint256) {
        return uint256(b);
    }

    function uintToBytes(uint256 x) internal pure returns (bytes memory) {
        return abi.encodePacked(x);
    }

    function decodeG1Bytes(bytes memory g1Bytes) internal pure returns (G1Bytes memory) {
        bytes32 x;
        bytes32 y;
        assembly {
            x := mload(add(g1Bytes, 32))
            y := mload(add(g1Bytes, 64))
        }
        return G1Bytes(x, y);
    }

    function decodeG1(bytes memory g1Bytes) internal pure returns (G1 memory) {
        G1Bytes memory g1b = decodeG1Bytes(g1Bytes);
        return G1(bytesToUint(g1b.x), bytesToUint(g1b.y));
    }

    function decodeG2Bytes(bytes memory g1Bytes) internal pure returns (G2Bytes memory) {
        bytes32 xr;
        bytes32 xi;
        bytes32 yr;
        bytes32 yi;
        assembly {
            xi := mload(add(g1Bytes, 32))
            xr := mload(add(g1Bytes, 64))
            yi := mload(add(g1Bytes, 96))
            yr := mload(add(g1Bytes, 128))
        }
        return G2Bytes(xr, xi, yr, yi);
    }

    function decodeG2(bytes memory g2Bytes) internal pure returns (G2 memory) {
        G2Bytes memory g2b = decodeG2Bytes(g2Bytes);
        return G2(bytesToUint(g2b.xi), bytesToUint(g2b.xr), bytesToUint(g2b.yi), bytesToUint(g2b.yr));
    }

    function encodeG1(G1 memory _g1) internal pure returns (bytes memory) {
        return abi.encodePacked(_g1.x, _g1.y);
    }

    function encodeG2(G2 memory _g2) internal pure returns (bytes memory) {
        return abi.encodePacked(_g2.xi, _g2.xr, _g2.yi, _g2.yr);
    }

    //

    function expMod(uint256 base, uint256 e, uint256 m) private view returns (uint256 result) {
        bool success;
        assembly {
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), e) // Exponent
            mstore(add(p, 0xa0), m) // Modulus
            // 0x05           id of precompiled modular exponentiation contract
            // 0xc0 == 192    size of call parameters
            // 0x20 ==  32    size of result
            success := staticcall(gas(), 0x05, p, 0xc0, p, 0x20)
            // data
            result := mload(p)
        }
        require(success, "modular exponentiation failed");
    }

    function addPoints(G1 memory a, G1 memory b) internal view returns (G1 memory) {
        uint256[4] memory input = [a.x, a.y, b.x, b.y];
        uint256[2] memory result;
        bool success = false;
        assembly {
            // 0x06     id of precompiled bn256Add contract
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value,
            //              i.e. 64 bytes / 512 bit for a BN256 curve point
            success := staticcall(gas(), 6, input, 0x80, result, 0x40)
        }
        require(success, "add points fail");
        return G1(result[0], result[1]);
    }

    // kP
    function scalarMultiply(G1 memory point, uint256 scalar) internal returns (G1 memory) {
        uint256[3] memory input = [point.x, point.y, scalar];
        uint256[2] memory result;
        assembly {
            if iszero(call(not(0), 0x07, 0, input, 0x60, result, 0x40)) {
                revert(0, 0)
            }
        }
        return G1(result[0], result[1]);
    }

    //returns e(a,x) == e(b,y)
    function pairingCheck(G1 memory a, G2 memory x, G1 memory b, G2 memory y) internal view returns (bool) {
        uint256[12] memory input = [a.x, a.y, x.xi, x.xr, x.yi, x.yr, b.x, prime - b.y, y.xi, y.xr, y.yi, y.yr];
        uint256[1] memory result;
        bool success = false;
        assembly {
            success := staticcall(gas(), 8, input, 0x180, result, 0x20)
        }
        require(success, "pairing check fail");
        return result[0] == 1;
    }

    function chkBit(bytes memory b, uint256 x) internal pure returns (bool) {
        return uint256(uint8(b[31 - x / 8])) & (uint256(1) << (x % 8)) != 0;
    }

    function sumPoints(
        uint256[] memory points,
        bytes memory indices
    ) internal view returns (G1 memory, uint256) {
        G1 memory acc = G1(0, 0);
        uint256 weight = 0;
        uint256 pointLen = points.length / 2;
        for (uint256 i = 0; i < pointLen; i++) {
            if (chkBit(indices, i)) {
                G1 memory point = G1(points[2 * i], points[2 * i + 1]);
                acc = addPoints(acc, point);
                weight += 1;
            }
        }
        return (G1(acc.x, acc.y), weight);
    }

    function checkAggPk(
        bytes memory bits,
        G2 memory aggPk,
        uint256[] memory pairKeys,
        uint256 threshold
    ) internal view returns (bool) {
        G1 memory g1 = G1(g1x, g1y);
        G2 memory g2 = G2(g2xr, g2xi, g2yr, g2yi);

        (G1 memory sumPoint, uint256 weight) = sumPoints(pairKeys, bits);

        if (weight < threshold) {
            return false;
        }

        return pairingCheck(sumPoint, g2, g1, aggPk);
    }

    // compatible with https://github.com/dusk-network/dusk-crypto/blob/master/bls/bls.go#L138-L148
    // which is used in github.com/mapprotocol/atlas
    // https://github.com/mapprotocol/atlas/blob/main/helper/bls/bn256.go#L84-L94

    uint256 constant order = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    uint256 constant prime = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // try-and-increment is an acceptable way to hash to G1, although not ideal
    // todo by long: eip-3068 is a much better way, should explore the implementation
    //    function hashToG1(bytes memory message) public view returns (G1 memory) {
    //        uint x = 0;
    //        G1 memory res;
    //        while (true) {
    //            uint hx = uint(keccak256(abi.encodePacked(message, x))) % prime;
    //            uint px = (expMod(hx, 3, prime) + 3) % prime;
    //            // y^2 = x^3 % p + 3
    //
    //            // determine if px is a quadratic residue, 1 means yes
    //            if (expMod(px, (prime - 1) / 2, prime) == 1) {
    //                // refer to https://mathworld.wolfram.com/QuadraticResidue.html
    //                // prime is a special form of 4k+3,
    //                // then x satisfying x^2 = q (mod p) can be solved by calculating x = q^(k+1) mod p,
    //                // where k = (p - 3) / 4, k + 1 = (p + 1) / 4, then x = q^((p+1)/4) mod p
    //                uint py = expMod(px, (prime + 1) / 4, prime);
    //
    //                res = py <= (prime / 2) ? G1(hx, py) : G1(hx, prime - py);
    //                break;
    //            } else {
    //                x++;
    //            }
    //        }
    //        return res;
    //    }

    function checkSignature(bytes memory message, bytes memory sigBytes, G2 memory aggKey) internal view returns (bool) {
        G1 memory sig = decodeG1(sigBytes);
        G2 memory g2 = G2(g2xr, g2xi, g2yr, g2yi);
        return pairingCheck(sig, g2, hashToG1(message), aggKey);
    }

    // adapted from https://github.com/MadBase/MadNet/blob/v0.5.0/crypto/bn256/solidity/contract/crypto.sol

    // curveB is the constant of the elliptic curve for G1: y^2 == x^3 + curveB, with curveB == 3.
    uint256 constant curveB = 3;

    // baseToG1 constants
    //
    // These are precomputed constants which are independent of t.
    // All of these constants are computed modulo prime.
    //
    // (-1 + sqrt(-3))/2
    uint256 constant HashConst1 = 2203960485148121921418603742825762020974279258880205651966;
    // sqrt(-3)
    uint256 constant HashConst2 = 4407920970296243842837207485651524041948558517760411303933;
    // 1/3
    uint256 constant HashConst3 = 14592161914559516814830937163504850059130874104865215775126025263096817472389;
    // 1 + curveB (curveB == 3)
    uint256 constant HashConst4 = 4;

    // Two256ModP == 2^256 mod prime, used in hashToBase to obtain a more uniform hash value.
    uint256 constant Two256ModP = 6350874878119819312338956282401532409788428879151445726012394534686998597021;

    // pMinus1 == -1 mod prime;
    // this is used in sign0 and all ``negative'' values have this sign value.
    uint256 constant pMinus1 = 21888242871839275222246405745257275088696311157297823662689037894645226208582;

    // pMinus2 == prime - 2, this is the exponent used in finite field inversion.
    uint256 constant pMinus2 = 21888242871839275222246405745257275088696311157297823662689037894645226208581;

    // pMinus1Over2 == (prime - 1) / 2;
    // this is the exponent used in computing the Legendre symbol and
    // is also used in sign0 as the cutoff point between ``positive'' and ``negative'' numbers.
    uint256 constant pMinus1Over2 = 10944121435919637611123202872628637544348155578648911831344518947322613104291;

    // pPlus1Over4 == (prime + 1) / 4, this is the exponent used in computing finite field square roots.
    uint256 constant pPlus1Over4 = 5472060717959818805561601436314318772174077789324455915672259473661306552146;

    /*
    // bn256G1Add performs elliptic curve addition on the bn256 curve of Ethereum.
    function bn256G1Add(uint256[4] memory input) private view returns (G1 memory res) {
        // computes P + Q
        // input: 4 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) x-coordinate of point Q
        //  *) y-coordinate of point Q

        bool success;
        uint256[2] memory result;
        assembly {
            // 0x06     id of precompiled bn256Add contract
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value,
            //              i.e. 64 bytes / 512 bit for a BN256 curve point
            success := staticcall(gas(), 0x06, input, 128, result, 64)
        }
        require(success, "elliptic curve addition failed");

        res.x = result[0];
        res.y = result[1];
    } */

    function bn256G1IsOnCurve(G1 memory point) private pure returns (bool) {
        // check if the provided point is on the bn256 curve (y**2 = x**3 + curveB)
        return
            mulmod(point.y, point.y, prime) ==
            addmod(mulmod(point.x, mulmod(point.x, point.x, prime), prime), curveB, prime);
    }

    // safeSigningPoint ensures that the HashToG1 point we are returning
    // is safe to sign; in particular, it is not Infinity (the group identity
    // element) or the standard curve generator (curveGen) or its negation.
    function safeSigningPoint(G1 memory input) public pure returns (bool) {
        return (input.x == 0 || input.x == 1) ? false : true;
    }

    function hashToG1(bytes memory message) public view returns (G1 memory h) {
        uint256 t0 = hashToBase(message, 0x00, 0x01);
        uint256 t1 = hashToBase(message, 0x02, 0x03);

        G1 memory h0 = baseToG1(t0);
        G1 memory h1 = baseToG1(t1);

        // Each BaseToG1 call involves a check that we have a valid curve point.
        // Here, we check that we have a valid curve point after the addition.
        // Again, this is to ensure that even if something strange happens, we
        // will not return an invalid curvepoint.
        h = addPoints(h0, h1);
        //h = bn256G1Add([h0.x, h0.y, h1.x, h1.y]);
        require(bn256G1IsOnCurve(h), "Invalid hash point: not on elliptic curve");
        require(safeSigningPoint(h), "Dangerous hash point: not safe for signing");
    }

    // invert computes the multiplicative inverse of t modulo prime.
    // When t == 0, s == 0.
    function invert(uint256 t) private view returns (uint256 s) {
        s = expMod(t, pMinus2, prime);
    }

    // sqrt computes the multiplicative square root of t modulo prime.
    // sqrt does not check that a square root is possible; see legendre.
    function sqrt(uint256 t) private view returns (uint256 s) {
        s = expMod(t, pPlus1Over4, prime);
    }

    // legendre computes the legendre symbol of t with respect to prime.
    // That is, legendre(t) == 1 when a square root of t exists modulo
    // prime, legendre(t) == -1 when a square root of t does not exist
    // modulo prime, and legendre(t) == 0 when t == 0 mod prime.
    function legendre(uint256 t) private view returns (int256 chi) {
        uint256 s = expMod(t, pMinus1Over2, prime);
        chi = s != 0 ? (2 * int256(s & 1) - 1) : int256(0);
    }

    // neg computes the additive inverse (the negative) modulo prime.
    function neg(uint256 t) private pure returns (uint256 s) {
        s = t == 0 ? 0 : prime - t;
    }

    // sign0 computes the sign of a finite field element.
    // sign0 is used instead of legendre in baseToG1 from the suggestion of WB 2019.
    function sign0(uint256 t) public pure returns (uint256 s) {
        s = 1;
        if (t > pMinus1Over2) {
            s = pMinus1;
        }
    }

    // hashToBase takes in a byte slice message and bytes c0 and c1 for
    // domain separation. The idea is that we treat keccak256 as a random
    // oracle which outputs uint256. The problem is that we want to hash modulo
    // prime (p, a prime number). Just using uint256 mod p will lead
    // to bias in the distribution. In particular, there is bias towards the
    // lower 5% of the numbers in [0, prime). The 1-norm error between
    // s0 mod p and a uniform distribution is ~ 1/4. By itself, this 1-norm
    // error is not too enlightening, but continue reading, as we will compare
    // it with another distribution that has much smaller 1-norm error.
    //
    // To obtain a better distribution with less bias, we take 2 uint256 hash
    // outputs (using c0 and c1 for domain separation so the hashes are
    // independent) and concatenate them to form a ``uint512''. Of course,
    // this is not possible in practice, so we view the combined output as
    //
    //      x == s0*2^256 + s1.
    //
    // This implies that x (combined from s0 and s1 in this way) is a
    // 512-bit uint. If s0 and s1 are uniformly distributed modulo 2^256,
    // then x is uniformly distributed modulo 2^512. We now want to reduce
    // this modulo prime (p). This is done as follows:
    //
    //      x mod p == [(s0 mod p)*(2^256 mod p)] + s1 mod p.
    //
    // This allows us easily compute the result without needing to implement
    // higher precision. The 1-norm error between x mod p and a uniform
    // distribution is ~1e-77. This is a *significant* improvement from s0 mod p.
    // For all practical purposes, there is no difference from a
    // uniform distribution
    function hashToBase(bytes memory message, bytes1 c0, bytes1 c1) internal pure returns (uint256 t) {
        uint256 s0 = uint256(keccak256(abi.encodePacked(c0, message)));
        uint256 s1 = uint256(keccak256(abi.encodePacked(c1, message)));
        t = addmod(mulmod(s0, Two256ModP, prime), s1, prime);
    }

    function baseToG1(uint256 t) internal view returns (G1 memory h) {
        // ap1 and ap2 are temporary variables, originally named to represent
        // alpha part 1 and alpha part 2. Now they are somewhat general purpose
        // variables due to using too many variables on stack.
        uint256 ap1;
        uint256 ap2;

        // One of the main constants variables to form x1, x2, and x3
        // is alpha, which has the following definition:
        //
        //      alpha == (ap1*ap2)^(-1)
        //            == [t^2*(t^2 + h4)]^(-1)
        //
        //      ap1 == t^2
        //      ap2 == t^2 + h4
        //      h4  == HashConst4
        //
        // Defining alpha helps decrease the calls to expMod,
        // which is the most expensive operation we do.
        uint256 alpha;
        ap1 = mulmod(t, t, prime);
        ap2 = addmod(ap1, HashConst4, prime);
        alpha = mulmod(ap1, ap2, prime);
        alpha = invert(alpha);

        // Another important constant which is used when computing x3 is tmp,
        // which has the following definition:
        //
        //      tmp == (t^2 + h4)^3
        //          == ap2^3
        //
        //      h4  == HashConst4
        //
        // This is cheap to compute because ap2 has not changed
        uint256 tmp;
        tmp = mulmod(ap2, ap2, prime);
        tmp = mulmod(tmp, ap2, prime);

        // When computing x1, we need to compute t^4. ap1 will be the
        // temporary variable which stores this value now:
        //
        // Previous definition:
        //      ap1 == t^2
        //
        // Current definition:
        //      ap1 == t^4
        ap1 = mulmod(ap1, ap1, prime);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x1 == h1 - h2*t^4*alpha
        //         == h1 - h2*ap1*alpha
        //
        //      ap1 == t^4 (note previous assignment)
        //      h1  == HashConst1
        //      h2  == HashConst2
        //
        // When t == 0, x1 is a valid x-coordinate of a point on the elliptic
        // curve, so we need no exceptions; this is different than the original
        // Fouque and Tibouchi 2012 paper. This comes from the fact that
        // 0^(-1) == 0 mod p, as we use expMod for inversion.
        uint256 x1;
        x1 = mulmod(HashConst2, ap1, prime);
        x1 = mulmod(x1, alpha, prime);
        x1 = neg(x1);
        x1 = addmod(x1, HashConst1, prime);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x2 == -1 - x1
        uint256 x2;
        x2 = addmod(x1, 1, prime);
        x2 = neg(x2);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x3 == 1 - h3*tmp*alpha
        //
        //      h3 == HashConst3
        uint256 x3;
        x3 = mulmod(HashConst3, tmp, prime);
        x3 = mulmod(x3, alpha, prime);
        x3 = neg(x3);
        x3 = addmod(x3, 1, prime);

        // We now focus on determining residue1; if residue1 == 1,
        // then x1 is a valid x-coordinate for a point on E(F_p).
        //
        // When computing residues, the original FT 2012 paper suggests
        // blinding for security. We do not use that suggestion here
        // because of the possibility of a random integer being returned
        // which is 0, which would completely destroy the output.
        // Additionally, computing random numbers on Ethereum is difficult.
        uint256 y;
        y = mulmod(x1, x1, prime);
        y = mulmod(y, x1, prime);
        y = addmod(y, curveB, prime);
        int256 residue1 = legendre(y);

        // We now focus on determining residue2; if residue2 == 1,
        // then x2 is a valid x-coordinate for a point on E(F_p).
        y = mulmod(x2, x2, prime);
        y = mulmod(y, x2, prime);
        y = addmod(y, curveB, prime);
        int256 residue2 = legendre(y);

        // i is the index which gives us the correct x value (x1, x2, or x3)
        int256 i = ((residue1 - 1) * (residue2 - 3)) / 4 + 1;

        // This is the simplest way to determine which x value is correct
        // but is not secure. If possible, we should improve this.
        uint256 x;
        if (i == 1) {
            x = x1;
        } else if (i == 2) {
            x = x2;
        } else {
            x = x3;
        }

        // Now that we know x, we compute y
        y = mulmod(x, x, prime);
        y = mulmod(y, x, prime);
        y = addmod(y, curveB, prime);
        y = sqrt(y);

        // We now determine the sign of y based on t; this is a change from
        // the original FT 2012 paper and uses the suggestion from WB 2019.
        //
        // This is done to save computation, as using sign0 reduces the
        // number of calls to expMod from 5 to 4; currently, we call expMod
        // for inversion (alpha), two legendre calls (for residue1 and
        // residue2), and one sqrt call.
        // This change nullifies the proof in FT 2012 that we have a valid
        // hash function. Whether the proof could be slightly modified to
        // compensate for this change is possible but not currently known.
        //
        // (CHG: At the least, I am not sure that the proof holds, nor am I
        // able to see how the proof could potentially be fixed in order
        // for the hash function to be admissible. This is something I plan
        // to look at in the future.)
        //
        // If this is included as a precompile, it may be worth it to ignore
        // the cost savings in order to ensure uniformity of the hash function.
        // Also, we would need to change legendre so that legendre(0) == 1,
        // or else things would fail when t == 0. We could also have a separate
        // function for the sign determination.
        uint256 ySign;
        ySign = sign0(t);
        y = mulmod(y, ySign, prime);

        h.x = x;
        h.y = y;

        // Before returning the value, we check to make sure we have a valid
        // curve point. This ensures we will always have a valid point.
        // From Fouque-Tibouchi 2012, the only way to get an invalid point is
        // when t == 0, but we have already taken care of that to ensure that
        // when t == 0, we still return a valid curve point.
        require(bn256G1IsOnCurve(h), "Invalid point: not on elliptic curve");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IVerifyTool.sol";

interface ILightNode {
    event UpdateBlockHeader(address indexed account, uint256 indexed blockHeight);

    event ClientNotifySend(address indexed sender, uint256 indexed blockHeight, bytes notifyData);

    function verifyProofDataWithCache(
        bytes memory _receiptProofBytes
    ) external returns (bool success, string memory message, bytes memory logs);

    // @notice Notify light client to relay the block
    // @param _data - notify data, if no data set it to empty
    function notifyLightClient(address _from, bytes memory _data) external;

    //Validate headers and update validation members
    //function updateBlockHeader(blockHeader memory bh, istanbulExtra memory ist, G2 memory aggPk) external;

    //Verify the validity of the transaction according to the header, receipt, and aggPk
    //The interface will be updated later to return logs
    function verifyProofData(
        bytes memory _receiptProof
    ) external returns (bool success, string memory message, bytes memory logsHash);

    function verifiableHeaderRange() external view returns (uint256, uint256);

    // @notice Check whether the block can be verified
    // @return
    function isVerifiable(uint256 _blockHeight, bytes32 _hash) external view returns (bool);

    // @notice Get the light client type
    // @return - 1 default light client
    //           2 zk light client
    //           3 oracle client
    function nodeType() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVerifyTool {
    //Map chain block header
    struct blockHeader {
        bytes parentHash;
        address coinbase;
        bytes root;
        bytes txHash;
        bytes receiptHash;
        bytes bloom;
        uint256 number;
        uint256 gasLimit;
        uint256 gasUsed;
        uint256 time;
        //extraData: Expand the information field to store information suchas committee member changes and voting.
        bytes extraData;
        bytes mixDigest;
        bytes nonce;
        uint256 baseFee;
    }

    struct txReceipt {
        bytes postStateOrStatus;
        uint256 cumulativeGasUsed;
        bytes bloom;
        bytes logRlp;
    }

    struct txLog {
        address addr;
        bytes[] topics;
        bytes data;
    }

    struct istanbulAggregatedSeal {
        uint256 bitmap;
        bytes signature;
        uint256 round;
    }

    //Committee change information corresponds to extraData in blockheader
    struct istanbulExtra {
        //Addresses of added committee members
        address[] validators;
        //The public key of the added committee member
        bytes[] addedPubKey;
        //G1 public key of the added committee member
        bytes[] addedG1PubKey;
        //Members removed from the previous committee are removed by bit 1 after binary encoding
        uint256 removeList;
        //The signature of the previous committee on the current header
        //Reference for specific signature and encoding rules
        //https://docs.maplabs.io/develop/map-relay-chain/consensus/epoch-and-block/aggregatedseal#calculate-the-hash-of-the-block-header
        bytes seal;
        //Information on current committees
        istanbulAggregatedSeal aggregatedSeal;
        //Information on the previous committee
        istanbulAggregatedSeal parentAggregatedSeal;
    }

    function getVerifyTrieProof(
        bytes32 _receiptHash,
        bytes memory _keyIndex,
        bytes[] memory _proof,
        bytes memory _receiptRlp,
        uint256 _receiptType
    ) external pure returns (bool success, string memory message);

    function decodeHeader(bytes memory rlpBytes) external view returns (blockHeader memory bh);

    function encodeHeader(
        blockHeader memory _bh,
        bytes memory _deleteAggBytes,
        bytes memory _deleteSealAndAggBytes
    ) external view returns (bytes memory deleteAggHeaderBytes, bytes memory deleteSealAndAggHeaderBytes);

    function manageAgg(
        istanbulExtra memory ist
    ) external pure returns (bytes memory deleteAggBytes, bytes memory deleteSealAndAggBytes);

    function encodeTxLog(txLog[] memory _txLogs) external view returns (bytes memory output);

    function decodeTxLog(bytes memory logsHash) external view returns (txLog[] memory _txLogs);

    function decodeTxReceipt(bytes memory receiptRlp) external pure returns (bytes memory logHash);

    function verifyHeader(
        address _coinbase,
        bytes memory _seal,
        bytes memory _headerWithoutSealAndAgg
    ) external view returns (bool ret, bytes32 headerHash);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interface/ILightNode.sol";
import "./bls/BGLS.sol";
import "./interface/IVerifyTool.sol";

contract LightNode is UUPSUpgradeable, Initializable, ILightNode {
    address private _pendingAdmin;

    uint256 public maxEpochs; // max epoch number
    uint256 public epochSize; // every epoch block number

    uint256 public startHeight;     // init epoch start block number
    uint256 public headerHeight;    // last update block number
    // address[] public validatorAddress;
    Epoch[] public epochs;
    IVerifyTool public verifyTool;

    mapping(uint256 => bytes32) private cachedReceiptRoot;

    struct TxReceiptRlp {
        uint256 receiptType;
        bytes receiptRlp;
    }

    struct ReceiptProof {
        IVerifyTool.blockHeader header;
        IVerifyTool.istanbulExtra ist;
        BGLS.G2 aggPk;
        TxReceiptRlp txReceiptRlp;
        bytes keyIndex;
        bytes[] proof;
    }

    struct Epoch {
        uint256 epoch;
        uint256 threshold; // bft, > 2/3,  if  \sum weights = 100, threshold = 67
        uint256[2] aggKey;  // agg G1 key, not used now
        uint256[] pairKeys; // <-- validators, pubkey G1,   (s, s * g2)   s * g1
        uint256[] weights; // voting power, not used now
    }

    event MapInitializeValidators(uint256 _threshold, BGLS.G1[] _pairKeys, uint256[] _weights, uint256 epoch);
    event MapUpdateValidators(bytes[] _pairKeysAdd, uint256 epoch, bytes bits);
    event ChangePendingAdmin(address indexed previousPending, address indexed newPending);
    event AdminTransferred(address indexed previous, address indexed newAdmin);
    event NewVerifyTool(address newVerifyTool);

    modifier onlyOwner() {
        require(msg.sender == _getAdmin(), "Lightnode only admin");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    /** initialize  **********************************************************/
    function initialize(
        uint256 _threshold,
        address[] memory _validatorAddress,
        BGLS.G1[] memory _pairKeys,
        uint256[] memory _weights,
        uint256 _epoch,
        uint256 _epochSize,
        address _verifyTool,
        address _owner
    ) external initializer {
        require(_epoch > 1, "Error initializing epoch");
        _changeAdmin(_owner);
        maxEpochs = 1500000 / _epochSize;
        headerHeight = (_epoch - 1) * _epochSize;
        startHeight = headerHeight;
        epochSize = _epochSize;
        // validatorAddress = _validatorAddress;
        // init all epochs
        for (uint256 i = 0; i < maxEpochs; i++) {
            epochs.push(
                Epoch({
                    pairKeys: new uint256[](0),
                    weights: new uint256[](0),
                    aggKey: [uint256(0), uint256(0)],
                    threshold: 0,
                    epoch: 0
                })
            );
        }
        setStateInternal(_threshold, _pairKeys, _weights, _epoch);
        verifyTool = IVerifyTool(_verifyTool);

        emit MapInitializeValidators(_threshold, _pairKeys, _weights, _epoch);
    }

    function setVerifyTool(address _verifyTool) external onlyOwner {
        verifyTool = IVerifyTool(_verifyTool);
        emit NewVerifyTool(_verifyTool);
    }

    function updateBlockHeader(
        IVerifyTool.blockHeader memory bh,
        IVerifyTool.istanbulExtra memory ist,
        BGLS.G2 memory aggPk
    ) external {
        require(bh.number % epochSize == 0, "Header number is error");
        require(bh.number - epochSize == headerHeight, "Header is have");
        headerHeight = bh.number;
        if (startHeight == 0) {
            startHeight = headerHeight - epochSize;
        }

        uint256 epoch = _getEpochByNumber(bh.number);
        uint256 id = _getEpochId(epoch);
        //Epoch memory v = epochs[id];
        Epoch memory v;
        v.epoch = epochs[id].epoch;
        // v.threshold = epochs[id].threshold;
        v.pairKeys = epochs[id].pairKeys;

        uint256 weight = v.pairKeys.length / 2;
        v.threshold = weight - weight / 3;

        bool success = _verifyHeaderSig(v, bh, ist, aggPk);
        require(success, "CheckSig error");

        _updateValidators(v, ist);

        emit UpdateBlockHeader(msg.sender, bh.number);
    }

    function verifyProofDataWithCache(
        bytes memory _receiptProofBytes
    ) external override returns (bool success, string memory message, bytes memory logsHash) {
        ReceiptProof memory _receiptProof = abi.decode(_receiptProofBytes, (ReceiptProof));

        if (cachedReceiptRoot[_receiptProof.header.number] != bytes32("")) {
            return _verifyMptProof(cachedReceiptRoot[_receiptProof.header.number], _receiptProof);
        } else {
            (success, message, logsHash) = _verifyProofData(_receiptProof);
            if (success) {
                cachedReceiptRoot[_receiptProof.header.number] = bytes32(_receiptProof.header.receiptHash);
            }
        }
    }

    function notifyLightClient(address _from, bytes memory _data) external override {
        emit ClientNotifySend(_from, block.number, _data);
    }

    /** view *********************************************************/

    function verifyProofData(
        bytes memory _receiptProofBytes
    ) external view override returns (bool success, string memory message, bytes memory logsHash) {
        ReceiptProof memory _receiptProof = abi.decode(_receiptProofBytes, (ReceiptProof));

        return _verifyProofData(_receiptProof);
    }

    function getData(bytes memory _receiptProofBytes) external view returns (ReceiptProof memory) {
        ReceiptProof memory _receiptProof = abi.decode(_receiptProofBytes, (ReceiptProof));

        return _receiptProof;
    }

    function getValidators(uint256 id) public view returns (uint256[] memory) {
        return epochs[id].pairKeys;
    }

    function getBytes(ReceiptProof memory _receiptProof) public pure returns (bytes memory) {
        return abi.encode(_receiptProof);
    }

    function verifiableHeaderRange() public view override returns (uint256, uint256) {
        uint256 start;
        if (headerHeight > maxEpochs * epochSize) {
            start = headerHeight - (maxEpochs * epochSize);
        }

        if (startHeight > 0 && startHeight > start) {
            start = startHeight;
        }
        return (start, headerHeight + epochSize);
    }

    function isVerifiable(uint256 _blockHeight, bytes32) external view override returns (bool) {
        (uint256 start, uint256 end) = verifiableHeaderRange();
        return start <= _blockHeight && _blockHeight <= end;
    }

    function nodeType() external view override returns (uint256) {
        return 1;
    }

    /** internal *********************************************************/

    function setStateInternal(
        uint256 _threshold,
        BGLS.G1[] memory _pairKeys,
        uint256[] memory _weights,
        uint256 _epoch
    ) internal {
        require(_pairKeys.length == _weights.length, "Mismatch arg");
        uint256 id = _getEpochId(_epoch);
        Epoch storage v = epochs[id];

        for (uint256 i = 0; i < _pairKeys.length; i++) {
            v.pairKeys.push(_pairKeys[i].x);
            v.pairKeys.push(_pairKeys[i].y);
            // v.weights.push(_weights[i]);
        }

        v.threshold = _threshold;
        v.epoch = _epoch;
    }

    function _updateValidators(Epoch memory _preEpoch, IVerifyTool.istanbulExtra memory _ist) internal {
        bytes memory bits = abi.encodePacked(_ist.removeList);

        uint256 epoch = _preEpoch.epoch + 1;
        //uint256 idPre = _getPreEpochId(epoch);
        //Epoch memory vPre = epochs[idPre];
        uint256 id = _getEpochId(epoch);
        Epoch storage v = epochs[id];
        v.epoch = epoch;

        if (v.pairKeys.length > 0) {
            delete (v.pairKeys);
        }

        uint256 weight = 0;
        uint256 keyLen = _preEpoch.pairKeys.length / 2;
        for (uint256 i = 0; i < keyLen; i++) {
            if (!BGLS.chkBit(bits, i)) {
                v.pairKeys.push(_preEpoch.pairKeys[2 * i]);
                v.pairKeys.push(_preEpoch.pairKeys[2 * i + 1]);
                //v.weights.push(_preEpoch.weights[i]);
                weight = weight + 1;
            }
        }

        keyLen = _ist.addedG1PubKey.length;
        if (keyLen > 0) {
            bytes32 x;
            bytes32 y;
            for (uint256 i = 0; i < keyLen; i++) {
                bytes memory g1 = _ist.addedG1PubKey[i];
                assembly {
                    x := mload(add(g1, 32))
                    y := mload(add(g1, 64))
                }

                v.pairKeys.push(uint256(x));
                v.pairKeys.push(uint256(y));
                //v.weights.push(1);
                weight = weight + 1;
            }
        }
        v.threshold = weight - weight / 3;

        emit MapUpdateValidators(_ist.addedG1PubKey, epoch, bits);
    }

    /** internal view *********************************************************/

    function _verifyMptProof(
        bytes32 receiptHash,
        ReceiptProof memory _receiptProof
    ) internal view returns (bool success, string memory message, bytes memory logsHash) {
        logsHash = verifyTool.decodeTxReceipt(_receiptProof.txReceiptRlp.receiptRlp);
        (success, message) = verifyTool.getVerifyTrieProof(
            receiptHash,
            _receiptProof.keyIndex,
            _receiptProof.proof,
            _receiptProof.txReceiptRlp.receiptRlp,
            _receiptProof.txReceiptRlp.receiptType
        );
        if (!success) {
            message = "Mpt verification failed";
            return (success, message, "");
        }
    }

    function _verifyProofData(
        ReceiptProof memory _receiptProof
    ) internal view returns (bool success, string memory message, bytes memory logsHash) {
        (uint256 min, uint256 max) = verifiableHeaderRange();
        uint256 height = _receiptProof.header.number;
        if (height <= min || height >= max) {
            message = "Out of verify range";
            return (false, message, logsHash);
        }

        (success, message, logsHash) = _verifyMptProof(bytes32(_receiptProof.header.receiptHash), _receiptProof);
        if (!success) {
            return (success, message, "");
        }

        uint256 epoch = _getEpochByNumber(height);
        uint256 id = _getEpochId(epoch);
        //Epoch memory v = epochs[id];
        Epoch memory v;
        // v.threshold = epochs[id].threshold;
        v.pairKeys = epochs[id].pairKeys;
        uint256 weight = v.pairKeys.length / 2;
        v.threshold = weight - weight / 3;

        success = _verifyHeaderSig(v, _receiptProof.header, _receiptProof.ist, _receiptProof.aggPk);
        if (!success) {
            message = "VerifyHeaderSig failed";
            return (success, message, logsHash);
        }
        return (success, message, logsHash);
    }

    function _verifyHeaderSig(
        Epoch memory _epoch,
        IVerifyTool.blockHeader memory _bh,
        IVerifyTool.istanbulExtra memory ist,
        BGLS.G2 memory _aggPk
    ) internal view returns (bool success) {
        bytes32 extraDataPre = bytes32(_bh.extraData);
        (bytes memory deleteAggBytes, bytes memory deleteSealAndAggBytes) = verifyTool.manageAgg(ist);
        deleteAggBytes = abi.encodePacked(extraDataPre, deleteAggBytes);
        deleteSealAndAggBytes = abi.encodePacked(extraDataPre, deleteSealAndAggBytes);

        (bytes memory deleteAggHeaderBytes, bytes memory deleteSealAndAggHeaderBytes) = verifyTool.encodeHeader(
            _bh,
            deleteAggBytes,
            deleteSealAndAggBytes
        );

        (success, ) = verifyTool.verifyHeader(_bh.coinbase, ist.seal, deleteSealAndAggHeaderBytes);
        if (!success) return success;

        return checkSig(_epoch, ist, _aggPk, deleteAggHeaderBytes);
    }

    // aggPk2, sig1 --> in contract: check aggPk2 is valid with bits by summing points in G2
    // how to check aggPk2 is valid --> via checkAggPk
    function checkSig(
        Epoch memory _epoch,
        IVerifyTool.istanbulExtra memory _ist,
        BGLS.G2 memory _aggPk,
        bytes memory _headerWithoutAgg
    ) internal view returns (bool) {
        bytes memory message = getPrepareCommittedSeal(_headerWithoutAgg, _ist.aggregatedSeal.round);
        bytes memory bits = abi.encodePacked(_ist.aggregatedSeal.bitmap);

        return
            BGLS.checkAggPk(bits, _aggPk, _epoch.pairKeys, _epoch.threshold) &&
            BGLS.checkSignature(message, _ist.aggregatedSeal.signature, _aggPk);
    }

    function _getEpochId(uint256 epoch) internal view returns (uint256) {
        return epoch % maxEpochs;
    }

    function _getPreEpochId(uint256 epoch) internal view returns (uint256) {
        uint256 id = _getEpochId(epoch);
        if (id == 0) {
            return maxEpochs - 1;
        } else {
            return id - 1;
        }
    }

    function getPrepareCommittedSeal(
        bytes memory _headerWithoutAgg,
        uint256 _round
    ) internal pure returns (bytes memory result) {
        bytes32 hash = keccak256(_headerWithoutAgg);
        if (_round == 0) {
            result = abi.encodePacked(hash, uint8(2));
        } else {
            result = abi.encodePacked(hash, getLengthInBytes(_round), uint8(2));
        }
    }

    function getLengthInBytes(uint256 num) internal pure returns (bytes memory) {
        require(num < 2 ** 24, "Num is too large");
        bytes memory result;
        if (num < 256) {
            result = abi.encodePacked(uint8(num));
        } else if (num < 65536) {
            result = abi.encodePacked(uint16(num));
        } else {
            result = abi.encodePacked(uint24(num));
        }
        return result;
    }

    function _getEpochByNumber(uint256 blockNumber) internal view returns (uint256) {
        if (blockNumber % epochSize == 0) {
            return blockNumber / epochSize;
        }
        return blockNumber / epochSize + 1;
    }

    /** UUPS *********************************************************/
    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == _getAdmin(), "LightNode only Admin can upgrade");
    }

    function changeAdmin() public {
        require(_pendingAdmin == msg.sender, "Only pendingAdmin");
        emit AdminTransferred(_getAdmin(), _pendingAdmin);
        _changeAdmin(_pendingAdmin);
        _pendingAdmin = address(0);
    }

    function pendingAdmin() external view returns (address) {
        return _pendingAdmin;
    }

    function setPendingAdmin(address pendingAdmin_) public onlyOwner {
        require(pendingAdmin_ != address(0), "pendingAdmin is the zero address");
        emit ChangePendingAdmin(_pendingAdmin, pendingAdmin_);
        _pendingAdmin = pendingAdmin_;
    }

    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}